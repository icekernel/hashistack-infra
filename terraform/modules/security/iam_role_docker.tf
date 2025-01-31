resource "aws_iam_role" "docker" {
  name               = "${var.environment}-docker"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "docker" {
  name = "${var.environment}-docker"
  role = aws_iam_role.docker.name
}

resource "aws_iam_role_policy_attachment" "ec2_describe_instances_docker" {
  policy_arn = aws_iam_policy.ec2_describe_instances.arn
  role       = aws_iam_role.docker.name
}

resource "aws_cloudwatch_log_group" "docker" {
  name              = "${var.environment}-docker"
  retention_in_days = 5
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_docker" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.docker.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_docker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.docker.name
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read_docker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.docker.name
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logging_docker" {
  policy_arn = aws_iam_policy.cloudwatch_instance_logging.arn
  role       = aws_iam_role.docker.name
}

resource "aws_iam_role_policy_attachment" "ec2_dynamodb_full_access_docker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role = aws_iam_role.docker.name
}