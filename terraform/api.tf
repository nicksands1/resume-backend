resource "aws_api_gateway_rest_api" "cloud_api" {
  name        = "cloud_api"
  description = "This is my API for demonstration purposes"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "MyDemoResource" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  parent_id   = aws_api_gateway_rest_api.cloud_api.root_resource_id
  path_part   = "MyDemoResource"
}

resource "aws_api_gateway_method" "opt" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  resource_id   = aws_api_gateway_resource.MyDemoResource.id
  http_method   = "OPTIONS"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "opt" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.opt.http_method
  type        = "MOCK"
}

resource "aws_api_gateway_integration_response" "opt" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.opt.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
  }
  depends_on = [
    aws_api_gateway_integration.opt, aws_api_gateway_method.opt
  ]
}

resource "aws_api_gateway_method_response" "opt" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.opt.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [
    aws_api_gateway_method.opt
  ]
}
resource "aws_api_gateway_method" "Method" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  resource_id   = aws_api_gateway_resource.MyDemoResource.id
  http_method   = "GET"
  authorization = "NONE"
}




resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.cloud_api.id
  resource_id             = aws_api_gateway_resource.MyDemoResource.id
  http_method             = aws_api_gateway_method.Method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn

}


resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cloud_api.execution_arn}/*/*/*"

}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.Method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true

  }

  response_models = {
    "application/json" : "Empty"
  }
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  resource_id = aws_api_gateway_resource.MyDemoResource.id
  http_method = aws_api_gateway_method.Method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
  }
  depends_on = [
    aws_api_gateway_integration.integration
  ]
}

resource "aws_api_gateway_gateway_response" "response_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'" # replace with hostname of frontend (CloudFront)
  }
}

resource "aws_api_gateway_gateway_response" "response_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'" # replace with hostname of frontend (CloudFront)
  }
}


resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.cloud_api.id
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_method.Method,
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration_response.MyDemoIntegrationResponse
  ]
}


resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.cloud_api.id
  stage_name    = "example"
}


output "crc_rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.cloud_api.execution_arn
}

output "api_gateway_stage_details" {
  value = {
    "stage_name" = "example",
    "stage_url"  = "${aws_api_gateway_stage.example.invoke_url}/${aws_api_gateway_resource.MyDemoResource.path_part}"
  }
}