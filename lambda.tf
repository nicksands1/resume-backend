resource "aws_iam_role" "lambda_role" {
  name = "DynamoDBRole"

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

resource "aws_iam_policy" "lambdaPolicyIAM" {

  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM policy for managing aws lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action" : "*",
      "Resource" : "arn:aws:dynamodb:*",
      "Effect" : "Allow"
    }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambdaPolicyIAM.arn
}

data "archive_file" "zip_python_code" {
  type        = "zip"
  source_file  = "${path.module}/python/add_visits.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "viewCountIncrement" {
  filename      = "${path.module}/lambda.zip"
  function_name = "DynamoDBWrite"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}