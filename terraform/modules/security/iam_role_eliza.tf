resource "aws_iam_role" "eliza" {
  name               = "${var.environment}-eliza"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "eliza" {
  name = "${var.environment}-eliza"
  role = aws_iam_role.eliza.name
}

resource "aws_iam_role_policy_attachment" "ec2_describe_instances_eliza" {
  policy_arn = aws_iam_policy.ec2_describe_instances.arn
  role       = aws_iam_role.eliza.name
}

resource "aws_cloudwatch_log_group" "eliza" {
  name              = "${var.environment}-eliza"
  retention_in_days = 5
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_eliza" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eliza.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_eliza" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eliza.name
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logging_eliza" {
  policy_arn = aws_iam_policy.cloudwatch_instance_logging.arn
  role       = aws_iam_role.eliza.name
}
