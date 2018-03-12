{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*"
   },
   {
     "Effect": "Allow",
     "Action": [
       "s3:GetObject"
     ],
     "Resource": [
       "arn:aws:s3:::govuk-${artefact_source}-artefact/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "s3:PutObject"
     ],
     "Resource": [
       "arn:aws:s3:::govuk-${aws_environment}-artefact/*"
     ]
   }
 ]

}
