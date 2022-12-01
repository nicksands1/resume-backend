resource "aws_dynamodb_table" "resume_table" {
  name         = "visitors"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"


  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "event_test" {
  table_name = aws_dynamodb_table.resume_table.name
  hash_key   = aws_dynamodb_table.resume_table.hash_key

  lifecycle {
    ignore_changes = all
  }

  item = <<ITEM
{
  "ID": {"S": "visitors"},
  "Numbers":{"S":"0"}
}
ITEM
}