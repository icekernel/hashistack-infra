resource "aws_apigatewayv2_api" "webhook_api" {
  name          = "eliza-webhook"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "webhook_integration" {
  api_id                 = aws_apigatewayv2_api.webhook_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.instance_provisioner.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "webhook_route" {
  api_id    = aws_apigatewayv2_api.webhook_api.id
  route_key = "POST /launch"
  target    = "integrations/${aws_apigatewayv2_integration.webhook_integration.id}"
}

resource "aws_apigatewayv2_stage" "webhook_stage" {
  api_id      = aws_apigatewayv2_api.webhook_api.id
  name        = "prod"
  auto_deploy = true
}