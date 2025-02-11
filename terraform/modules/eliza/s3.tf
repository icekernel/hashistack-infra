resource "aws_s3_bucket" "eliza_agents" {
  bucket = "${data.aws_caller_identity.current.account_id}-eliza-agents"
  # force_destroy = true
}
