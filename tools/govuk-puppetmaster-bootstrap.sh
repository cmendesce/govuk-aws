#!/bin/bash
# This snippet replaces aws-push-puppet and aws-copy-puppet-config.sh
# as part of a new automated bootstrap process based on Terraform
# SSM secrets store. It is called as 30-puppetmaster-bootstrap from 
# terraform user_data as defined in govuk-aws-data 
set -x
set -u

GIT_BINARY='/usr/bin/git'
AWS_BINARY='/usr/local/bin/aws'
BUNDLE_BINARY='/usr/bin/bundle'
RAKE_BINARY='/usr/local/bin/rake'
GEM_BINARY='/usr/bin/gem'
PUPPET_BINARY='/usr/local/bin/puppet'
GPG_BINARY='/usr/bin/gpg'

GOVUK_ENVIRONMENT='staging'
GOVUK_STACKNAME='blue'

GOVUK_WORKDIR='/var/govuk'
GOVUK_LOGDIR='/var/log/govuk'

GOVUK_GIT_URL='git@github.com:alphagov'

GOVUK_SECRETS_REPO='govuk-secrets'
GOVUK_PUPPET_REPO='govuk-puppet'

AWS_REGION='eu-west-1'

GPG_KEYSTORE='/root/.gnupg'
GPG_KEYNAME='gpgkey'

SSH_KEYSTORE='/root/.ssh'
SSH_KEYNAME='id_rsa'

# Librarian needs a HOME
[[ -v HOME ]] || export HOME=/root

# Install required packages
apt-get -y install postgresql-9.3
apt-get -y install bundler
apt-get -y install git
apt-get -y install python3-pip
pip3 install awscli

# Create required directories
mkdir -p ${GPG_KEYSTORE}
mkdir -p ${SSH_KEYSTORE}
mkdir -p ${GOVUK_LOGDIR}

cd ${GOVUK_WORKDIR}

# Function to access the AWS SSM parameter store and extract SecureString values from returned JSON
function get_ssm_parameter ()
{
set +x
    SSM_PARAMETER_NAME=$1
    SSM_PARAMETER=$(${AWS_BINARY} --region=${AWS_REGION} ssm get-parameter --name "${SSM_PARAMETER_NAME}" --with-decryption | jq .Parameter.Value | sed -e "s/^\"//;s/\"$//")
    echo ${SSM_PARAMETER}
set -x
}

# Get github.com publish SSH hostkey and write to known_hosts
set +x
get_ssm_parameter 'govuk_base64_github.com_hostkey' | base64 -d >> ${SSH_KEYSTORE}/known_hosts
set -x

# Get SSH key with ro access to all of alphagov (for govuk-secrets)
set +x
get_ssm_parameter 'govuk_base64_github.com_ssh_readonly' | base64 -d > ${SSH_KEYSTORE}/${SSH_KEYNAME}
chmod 600 ${SSH_KEYSTORE}/${SSH_KEYNAME}
set -x

# Get GPG key to decrypt
set +x
echo -n "$(get_ssm_parameter 'govuk_base64_staging_gpg_1_of_3')$(get_ssm_parameter 'govuk_base64_staging_gpg_2_of_3')$(get_ssm_parameter 'govuk_base64_staging_gpg_3_of_3')" | base64 -d > ${GPG_KEYSTORE}/${GPG_KEYNAME}
chmod 600 ${GPG_KEYSTORE}/${GPG_KEYNAME}
set -x

# Clone Puppet repo
${GIT_BINARY} clone --branch puppetdb-puppetserver-refactor-and-ordering-fixes ${GOVUK_GIT_URL}/${GOVUK_PUPPET_REPO}

# Clone secrets repo
${GIT_BINARY} clone ${GOVUK_GIT_URL}/${GOVUK_SECRETS_REPO}

# Add secrets to puppet repository
cp -r ${GOVUK_WORKDIR}/${GOVUK_SECRETS_REPO}/puppet_aws/hieradata/* ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/

RELEASENAME=$(date +%Y%m%d%H%M%S)

# If not in production and/or on a (different) stack, shift around respective config yaml
if [[ "${GOVUK_ENVIRONMENT}" != "production" ]]
then
  cp ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/${GOVUK_ENVIRONMENT}.yaml ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/production.yaml
  cp ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/${GOVUK_ENVIRONMENT}_credentials.yaml ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/production_credentials.yaml

  if [[ -d "${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/${GOVUK_STACKNAME}" ]]
  then
    cp ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/${GOVUK_STACKNAME}/${GOVUK_ENVIRONMENT}_credentials.yaml ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO}/hieradata_aws/${GOVUK_STACKNAME}/production_credentials.yaml
  fi
fi

# Move puppet release to the expected location
mkdir -p /usr/share/puppet/production/releases
mv ${GOVUK_WORKDIR}/${GOVUK_PUPPET_REPO} /usr/share/puppet/production/releases/${RELEASENAME}
rm -f /usr/share/puppet/production/current
ln -s /usr/share/puppet/production/releases/${RELEASENAME} /usr/share/puppet/production/current
# We only want the permissions applied to the deepest directory, so is correct
# behaviour.
# shellcheck disable=SC2174
mkdir -p -m 0700 /etc/puppet/gpg
${GPG_BINARY} --homedir /etc/puppet/gpg --allow-secret-key-import --import ${GPG_KEYSTORE}/${GPG_KEYNAME}
chown -R puppet: /etc/puppet/gpg

# Install Ruby dependencies for first puppet apply
${GEM_BINARY} install --no-ri --no-rdoc hiera-eyaml-gpg gpgme

cd /usr/share/puppet/production/current/

# Installing Puppet dependencies
${BUNDLE_BINARY} install
${BUNDLE_BINARY} exec ${RAKE_BINARY} librarian:install

cd ${GOVUK_WORKDIR}

# Self-configure puppet
${PUPPET_BINARY} apply --verbose --trusted_node_data --hiera_config=/usr/share/puppet/production/current/hiera_aws.yml --modulepath=/usr/share/puppet/production/current/modules:/usr/share/puppet/production/current/vendor/modules/ --manifestdir=/usr/share/puppet/production/current/manifests /usr/share/puppet/production/current/manifests/site.pp >> ${GOVUK_LOGDIR}/govuk_puppet_apply.log 2>&1
chown -R deploy:deploy /usr/share/puppet/production/releases/${RELEASENAME}
