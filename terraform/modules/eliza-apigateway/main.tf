module "eliza_auth_test" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"
  source_path        = "../src/eliza_auth_test"
  function_name = "${var.env}-eliza_auth_test"
  runtime       = "python3.13"
  handler      = "main.lambda_handler"
  build_in_docker = true
  publish = true
  allowed_triggers = {
    APIGatewayAny = {
      service = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*/*"
    }
  }
}

module "eliza_auth_login" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"
  source_path        = "../src/eliza_auth_login"
  function_name = "${var.env}-eliza_auth_login"
  runtime       = "python3.13"
  handler      = "lambda_function.lambda_handler"
  build_in_docker = true
  publish = true
  allowed_triggers = {
    APIGatewayAny = {
      service = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*/*"
    }
  }
  attach_policies    = true
  policies           = ["arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]
  number_of_policies = 1
}

# resource "aws_cloudwatch_log_group" "authorizer_log_group" {
#   name              = "/aws/lambda/${var.env}-eliza_auth_authorizer1"
#   retention_in_days = 5
# }

module "eliza_auth_authorizer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"
  source_path        = "../src/eliza_auth_authorizer"
  function_name = "${var.env}-eliza_auth_authorizer"
  runtime       = "python3.13"
  handler      = "lambda_function.lambda_handler"
  build_in_docker = true
  publish = true
  allowed_triggers = {
    testAuth = {
      service = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*/GET/testAuth"
    }
    APIGatewayAuthIntegration = {
      service = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/authorizers/${aws_api_gateway_authorizer.eliza_authorizer.id}"
    }
  }
  attach_policies    = true
  policies           = ["arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]
  number_of_policies = 1

  # use_existing_cloudwatch_log_group = true
  # logging_log_group             = aws_cloudwatch_log_group.authorizer_log_group.name
  # logging_log_format            = "JSON"
  # logging_application_log_level = "INFO"
  # logging_system_log_level      = "DEBUG"
}
