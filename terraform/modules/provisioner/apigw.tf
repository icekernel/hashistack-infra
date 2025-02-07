resource "aws_apigatewayv2_api" "provisioner" {
  name          = "eliza-provisioner"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "provisioner_integration" {
  api_id                 = aws_apigatewayv2_api.provisioner.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.instance_provisioner.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "provisioner_route" {
  api_id    = aws_apigatewayv2_api.provisioner.id
  route_key = "POST /provisioner"
  target    = "integrations/${aws_apigatewayv2_integration.provisioner_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw_provisioner" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.provisioner.name}"
  retention_in_days = 5
}

resource "aws_apigatewayv2_stage" "provisioner_stage" {
  api_id      = aws_apigatewayv2_api.provisioner.id
  name        = var.env
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_provisioner.arn
    format          = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }
}