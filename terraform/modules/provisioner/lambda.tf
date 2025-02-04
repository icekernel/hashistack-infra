locals {
  fixed_path = "${path.root}/src/${var.src_path}"
  ignore_source_code_hash = false
  filename = data.external.archive_prepare[0].result.filename
  was_missing = try(data.external.archive_prepare[0].result.was_missing, false)
}
resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.lambda_full_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_lambda_function" "instance_provisioner" {
  function_name    = local.lambda_full_name
  # filename         = data.archive_file.lambda_package.output_path
  filename         = local.filename
  # source_code_hash = data.archive_file.lambda_package.output_base64sha256
  source_code_hash = local.ignore_source_code_hash ? null : (local.filename == null ? false : fileexists(local.filename)) && !local.was_missing ? filebase64sha256(local.filename) : null
  handler          = "main.lambda_handler"
  runtime          = "python${var.python_version}"
  timeout          = var.lambda_timeout
  role             = aws_iam_role.lambda_execution_role.arn
  memory_size = var.lambda_memory
  environment {
    variables = merge({
      },
      var.EXTRA_ENV_VARS
    )
  }

  depends_on = [ null_resource.archive ]
}
