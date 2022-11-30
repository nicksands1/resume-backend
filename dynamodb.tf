resource "aws_dynamodb_table" "visit_table" {
  name           = "visit_table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "record_id"

  attribute {
    name = "record_id"
    type = "S"
  }
}



resource "aws_dynamodb_table_item" "visitors" {

  table_name = aws_dynamodb_table.visit_table.name
  hash_key = aws_dynamodb_table.visit_table.hash_key
  item = <<ITEM
  {
      "record_id": {"S": "visitors"},
      "visitor_count": {"N": "1"}
  }  
  ITEM
}