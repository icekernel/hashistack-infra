resource "aws_iam_role" "nginx" {
  name               = "${var.environment}-nginx"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "nginx" {
  name = "${var.environment}-nginx"
  role = aws_iam_role.nginx.name
}

resource "aws_iam_role_policy_attachment" "ec2_describe_instances_nginx" {
  policy_arn = aws_iam_policy.ec2_describe_instances.arn
  role       = aws_iam_role.nginx.name
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "${var.environment}-nginx"
  retention_in_days = 5
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent_nginx" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.nginx.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_nginx" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nginx.name
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read_nginx" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nginx.name
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_logging_nginx" {
  policy_arn = aws_iam_policy.cloudwatch_instance_logging.arn
  role       = aws_iam_role.nginx.name
}

resource "aws_iam_role_policy_attachment" "ec2_dynamodb_full_access_nginx" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role = aws_iam_role.nginx.name
}