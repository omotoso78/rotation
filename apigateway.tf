#Configure Rest API object
resource "aws_api_gateway_rest_api" "ssm_API" {
  name        = "SSM1API"
  description = "Terraform built Serverless SSM Rotation Application"
}
#Configure API resource
resource "aws_api_gateway_resource" "ssm_APIResource" {
  rest_api_id = aws_api_gateway_rest_api.ssm_API.id
  parent_id   = aws_api_gateway_rest_api.ssm_API.root_resource_id
  path_part   = "prod"
}
#REST API method
resource "aws_api_gateway_method" "ssm_APIMethod" {
  rest_api_id   = aws_api_gateway_rest_api.ssm_API.id
  resource_id   = aws_api_gateway_resource.ssm_APIResource.id
  http_method   = "GET" 
  authorization = "NONE" 
  api_key_required = true # to connect created token key to method
}
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.ssm_API.id
  resource_id = aws_api_gateway_resource.ssm_APIResource.id
  http_method = aws_api_gateway_method.ssm_APIMethod.http_method

  integration_http_method = "PUT" # while all methods can be used here Lambda function can only be invoked with post
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ssm_lambda.invoke_arn
}

#Configure API deployment

resource "aws_api_gateway_deployment" "ssm_APIdeployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.ssm_API.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.ssm_API.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Confiure API stage
resource "aws_api_gateway_stage" "ssm_APIstage" {
  deployment_id = aws_api_gateway_deployment.ssm_APIdeployment.id
  rest_api_id   = aws_api_gateway_rest_api.ssm_API.id
  stage_name    = "prod"
}

#provide API gateway usage plan
resource "aws_api_gateway_usage_plan" "ssm-usage-plan" {
  name         = "ssm-usage-plan"
  description  = "usage plan for terraform built serveless ssm rotation app"
  product_code = "MYCODE"

  api_stages {
    api_id = aws_api_gateway_rest_api.ssm_API.id
    stage  = aws_api_gateway_stage.ssm_APIstage.stage_name
  }
}
# The next set of codes Provides API Gateway Usage Plan Key.

resource "aws_api_gateway_api_key" "rotationkey" {
  name = "my_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.rotationkey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.ssm-usage-plan.id
}
