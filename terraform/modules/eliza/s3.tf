resource "aws_s3_bucket" "eliza_agents" {
  bucket = "${data.aws_caller_identity.current.account_id}-eliza-agents"
  # Optionally force destroy if you want to remove a non-empty bucket on deletion.
  # force_destroy = true
}

resource "aws_s3_bucket_policy" "eliza_agents_policy" {
  bucket = aws_s3_bucket.eliza_agents.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowElizaInstanceRead",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/prod1-eliza"
        },
        Action    = [ "s3:GetObject" ],
        Resource  = "arn:aws:s3:::${aws_s3_bucket.eliza_agents.id}/*"
      }
    ]
  })
}