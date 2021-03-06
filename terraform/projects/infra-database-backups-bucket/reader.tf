/**
* ## Project: database-backups-bucket
*
* This is used to provide and control access to the database backup bucket located in the Production environment.
* a) We have created individual resources that can be applied to individual projects.
* b) We have also restricted wich sub object can be accessed.
* c) The bucket gives read access to accounts from all three environments, but we believe that restricting at this level is sufficient.
*
*/

resource "aws_iam_policy" "mongo_api_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-mongo-api_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.mongo_api_database_backups_reader.json}"
  description = "Allows reading the mongo-api database_backups bucket"
}

data "aws_iam_policy_document" "mongo_api_database_backups_reader" {
  statement {
    sid = "MongoAPIReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*mongo-api*",
    ]
  }
}

resource "aws_iam_policy" "mongo_router_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-mongo-router_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.mongo_router_database_backups_reader.json}"
  description = "Allows reading the mongo-router database_backups bucket"
}

data "aws_iam_policy_document" "mongo_router_database_backups_reader" {
  statement {
    sid = "MongoRouterReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*router_backend*",
    ]
  }
}

resource "aws_iam_policy" "mongodb_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-mongodb_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.mongodb_database_backups_reader.json}"
  description = "Allows reading the mongodb database_backups bucket"
}

data "aws_iam_policy_document" "mongodb_database_backups_reader" {
  statement {
    sid = "MongoDBReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*mongodb*",
    ]
  }
}

resource "aws_iam_policy" "elasticsearch_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-elasticsearch_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.elasticsearch_database_backups_reader.json}"
  description = "Allows reading the elasticsearch database_backups bucket"
}

data "aws_iam_policy_document" "elasticsearch_database_backups_reader" {
  statement {
    sid = "ElasticsearchReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*elasticsearch*",
    ]
  }
}

resource "aws_iam_policy" "dbadmin_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-dbadmin_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.dbadmin_database_backups_reader.json}"
  description = "Allows reading the dbadmin database_backups bucket"
}

data "aws_iam_policy_document" "dbadmin_database_backups_reader" {
  statement {
    sid = "DBAdminReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*mysql*",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*postgres*",
    ]
  }
}

resource "aws_iam_policy" "graphite_database_backups_reader" {
  name        = "govuk-${var.aws_environment}-graphite_database_backups-reader-policy"
  policy      = "${data.aws_iam_policy_document.graphite_database_backups_reader.json}"
  description = "Allows reading the graphite database_backups bucket"
}

data "aws_iam_policy_document" "graphite_database_backups_reader" {
  statement {
    sid = "GraphiteReadBucket"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    # Need access to the top level of the tree.
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}",
      "arn:aws:s3:::${aws_s3_bucket.database_backups.id}/*whisper*",
    ]
  }
}

output "mongo_api_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.mongo_api_database_backups_reader.arn}"
  description = "ARN of the read mongo-api database_backups-bucket policy"
}

output "mongo_router_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.mongo_router_database_backups_reader.arn}"
  description = "ARN of the read router_backend database_backups-bucket policy"
}

output "mongodb_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.mongodb_database_backups_reader.arn}"
  description = "ARN of the read mongodb database_backups-bucket policy"
}

output "elasticsearch_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.elasticsearch_database_backups_reader.arn}"
  description = "ARN of the read elasticsearch database_backups-bucket policy"
}

output "dbadmin_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.dbadmin_database_backups_reader.arn}"
  description = "ARN of the read DBAdmin database_backups-bucket policy"
}

output "graphite_read_database_backups_bucket_policy_arn" {
  value       = "${aws_iam_policy.graphite_database_backups_reader.arn}"
  description = "ARN of the read Graphite database_backups-bucket policy"
}
