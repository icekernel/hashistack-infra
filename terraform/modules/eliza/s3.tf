resource "aws_s3_bucket" "eliza_agents" {
  bucket = "${data.aws_caller_identity.current.account_id}-eliza-agents"
  # force_destroy = true
}

# resource "aws_s3_bucket_policy" "eliza_agents_policy" {
#   bucket = aws_s3_bucket.eliza_agents.id

#   policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [
#       {
#         Sid       = "AllowElizaInstanceRead",
#         Effect    = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/prod1-eliza"
#         },
#         Action = [
#           "s3:GetObject",
#           "s3:GetBucketLocation",
#           "s3:ListBucket"
#         ],
#         Resource = [
#           "arn:aws:s3:::${aws_s3_bucket.eliza_agents.id}",
#           "arn:aws:s3:::${aws_s3_bucket.eliza_agents.id}/*"
#         ]
#       }
#     ]
#   })
# }