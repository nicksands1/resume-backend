resource "aws_api_gateway_rest_api" "CRCAPI" {
    name = "CRCAPI"
    endpoint_configuration {
      types = ["REGIONAL"]
    }
    description = "This is the API for the cloud resume challenge"
    disable_execute_api_endpoint = true
}

resource "aws_api_gateway_resource" "CRCResource" {
    rest_api_id = aws_api_gateway_rest_api.CRCAPI.id
    parent_id = aws_api_gateway_rest_api.CRCAPI.root_resource_id
    path_part = "CRCResource"
}

resource "aws_api_gateway_method" "CRCMethod" {
    rest_api_id = aws_api_gateway_rest_api.CRCAPI.id
    resource_id = aws_api_gateway_resource.CRCResource.id
    http_method = "POST"
    authorization = "NONE"
}

resource "aws_api_gateway_method_response" "response_200" {
    rest_api_id = aws_api_gateway_rest_api.CRCAPI.id
    resource_id = aws_api_gateway_resource.CRCResource.id
    http_method = aws_api_gateway_method.CRCMethod.http_method
    status_code = "200"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.CRCMethod]
}

resource "aws_api_gateway_integration" "CRCintegration" {
    rest_api_id = aws_api_gateway_rest_api.CRCAPI.id
    resource_id = aws_api_gateway_resource.CRCResource.id
    http_method = aws_api_gateway_method.CRCMethod.http_method
    integration_http_method = "POST"
    type = "AWS_PROXY"
    uri = aws_lambda_function.CRCLambda.invoke_arn
}

resource "aws_api_gateway_domain_name" "CRCAPIDomainName" {
    domain_name = "crcapi.jcosioresume.com"
    regional_certificate_arn = aws_acm_certificate_validation.CRCACMValid.certificate_arn

    endpoint_configuration {
      types = ["REGIONAL"]
    }

}

#lines 56-95 to enable cors
resource "aws_api_gateway_resource" "cors_resource" {
  rest_api_id = aws_api_gateway_rest_api.CRCAPI.id
  parent_id   = aws_api_gateway_rest_api.CRCAPI.root_resource_id
  path_part   = "{cors+}"
}

resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
    resource_id   = aws_api_gateway_resource.cors_resource.id
    http_method   = "OPTIONS"
    authorization = "NONE"
}
resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
    resource_id   = aws_api_gateway_resource.cors_resource.id
    http_method   = aws_api_gateway_method.options_method.http_method
    status_code   = 200
    response_models = {
        "application/json" = "Empty"
    }
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }
    depends_on = [aws_api_gateway_method.options_method]
}
resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
    resource_id   = aws_api_gateway_resource.cors_resource.id
    http_method   = aws_api_gateway_method.options_method.http_method
    type          = "MOCK"
    request_templates = {
      "application/json" = jsonencode({
      statusCode=200
      })
    }
    depends_on = [aws_api_gateway_method.options_method]
}
resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
    resource_id   = aws_api_gateway_resource.cors_resource.id
    http_method   = aws_api_gateway_method.options_method.http_method
    status_code   = aws_api_gateway_method_response.options_200.status_code
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
    }
    depends_on = [aws_api_gateway_method_response.options_200]
}

resource "aws_api_gateway_gateway_response" "response_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'" 
  }
}

resource "aws_api_gateway_gateway_response" "response_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
  }
}



resource "aws_api_gateway_deployment" "CRCdeployment" {
  rest_api_id = aws_api_gateway_rest_api.CRCAPI.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.CRCResource.id,
      aws_api_gateway_method.CRCMethod.id,
      aws_api_gateway_integration.CRCintegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "CRCAPIstage" {
  deployment_id = aws_api_gateway_deployment.CRCdeployment.id
  rest_api_id   = aws_api_gateway_rest_api.CRCAPI.id
  stage_name    = "prodv3"
}

resource "aws_api_gateway_base_path_mapping" "CRCAPIdomainmapping" {
  api_id      = aws_api_gateway_rest_api.CRCAPI.id
  stage_name  = aws_api_gateway_stage.CRCAPIstage.stage_name
  domain_name = aws_api_gateway_domain_name.CRCAPIDomainName.domain_name
}