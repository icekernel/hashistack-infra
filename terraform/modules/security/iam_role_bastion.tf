resource "aws_iam_role" "bastion" {
  name               = "${var.environment}-bastion"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.environment}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "ec2_describe_instances_bastion" {
  policy_arn = aws_iam_policy.ec2_describe_instances.arn
  role       = aws_iam_role.bastion.name
}

resource "aws_cloudwatch_log_group" "bastion" {
  name              = "${var.environment}-bastion"
  retention_in_days = 120
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_bastion" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_bastion" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logging_bastion" {
  policy_arn = aws_iam_policy.cloudwatch_instance_logging.arn
  role       = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "secretsmanager_bastion" {
  policy_arn = aws_iam_policy.secretsmanager_bastion.arn
  role       = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "kms_bastion" {
  policy_arn = aws_iam_policy.kms_bastion.arn
  role       = aws_iam_role.bastion.name
}
