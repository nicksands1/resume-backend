resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
        
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "zip_python_code" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"

}


resource "aws_lambda_function" "test_lambda" {

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs
  ]



  filename      = "lambda_function.zip"
  function_name = "test-function"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach_dynamoDB_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}