resource "aws_dynamodb_table" "visit_table" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "visit_id"
  name         = "visit_table"

  attribute {
    name = "visit_id"
    type = "S"
  }

}