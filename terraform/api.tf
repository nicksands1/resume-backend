# gateway resource
# gateway method
# gateway integration
# gateway deployment
# gateway stage


resource "aws_api_gateway_rest_api" "cloud_api" {
  name = "cloud_api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "cloud_api" {
  parent_id   = aws_api_gateway_rest_api.cloud_api.root_resource_id
  path_part   = "cloud_api"
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
}

resource "aws_api_gateway_method" "cloud_api" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  resource_id   = aws_api_gateway_resource.cloud_api.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cloud_api" {
  rest_api_id             = aws_api_gateway_rest_api.cloud_api.id
  resource_id             = aws_api_gateway_resource.cloud_api.id
  http_method             = aws_api_gateway_method.cloud_api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "cloud_api" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.cloud_api.id,
      aws_api_gateway_method.cloud_api.id,
      aws_api_gateway_integration.cloud_api.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "cloud_api" {
  deployment_id = aws_api_gateway_deployment.cloud_api.id
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  stage_name    = "cloud_api"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.cloud_api.execution_arn}/*/*"
}

# New ^^^^ Old vvv

