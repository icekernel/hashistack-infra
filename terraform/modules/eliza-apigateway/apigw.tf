# Create a REST API Gateway
resource "aws_api_gateway_rest_api" "gateway" {
  name        = "${var.env}-eliza-gateway"
  description = "Eliza API Gateway"
}

resource "aws_cloudwatch_log_group" "api_gw_gateway" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.gateway.name}"
  retention_in_days = 5
}

# Create an API Gateway deployment
resource "aws_api_gateway_deployment" "gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  # Force new deployment when routes change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.testauth_resource.id,
      aws_api_gateway_method.test_auth_method.id,
      aws_api_gateway_method.login_method.id,
      aws_api_gateway_integration.test_integration.id,
      aws_api_gateway_integration.login_integration.id,

      # Authorizer changes
      aws_api_gateway_authorizer.eliza_authorizer.id,
      aws_api_gateway_authorizer.eliza_authorizer.identity_source,
      aws_api_gateway_authorizer.eliza_authorizer.authorizer_uri,

      # Proxy resources to trigger redeployment when they change
      aws_api_gateway_resource.proxy_resource.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.proxy_integration.id,

      # uncomment to force redeploy every apply; use sparingly!
      # timestamp(),
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a stage
resource "aws_api_gateway_stage" "gateway_stage" {
  deployment_id = aws_api_gateway_deployment.gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  stage_name    = var.env

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_gateway.arn
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
      responseLength = "$context.responseLength",
    })
  }

}

# Create API Gateway authorizer
resource "aws_api_gateway_authorizer" "eliza_authorizer" {
  name                   = "eliza-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.gateway.id
  authorizer_uri         = module.eliza_auth_authorizer.lambda_function_invoke_arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.cookie"
  authorizer_result_ttl_in_seconds = 0
}

# Create /testAuth resource path
resource "aws_api_gateway_resource" "testauth_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part   = "testAuth"
}

# Create /login resource path
resource "aws_api_gateway_resource" "login_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part   = "login"
}

# Method for /testAuth (GET)
resource "aws_api_gateway_method" "test_auth_method" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.testauth_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.eliza_authorizer.id
}

# Method for /login (POST)
resource "aws_api_gateway_method" "login_method" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.login_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration for /testAuth
resource "aws_api_gateway_integration" "test_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.testauth_resource.id
  http_method             = aws_api_gateway_method.test_auth_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.eliza_auth_test.lambda_function_invoke_arn
}

# Integration for /login
resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.login_resource.id
  http_method             = aws_api_gateway_method.login_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.eliza_auth_login.lambda_function_invoke_arn
}

# Catch-all proxy resource
resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part   = "{proxy+}"
}

# Method for the catch-all proxy (ANY)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.eliza_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
    "method.request.header.cookie" = false
  }
}

# Integration for the proxy route
resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  passthrough_behavior   = "WHEN_NO_MATCH"

  # For an HTTP integration with public ALB:
  uri                     = "https://${var.env}-nginx.prism1.click/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
    "integration.request.header.cookie" = "method.request.header.cookie"
  }
}

# Update the deployment to include information about route priority
resource "aws_api_gateway_method_settings" "path_specific_settings" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  stage_name  = aws_api_gateway_stage.gateway_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    # This helps ensure proper route evaluation
    data_trace_enabled = true
  }
}