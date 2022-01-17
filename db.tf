resource "aws_dynamodb_table" "groups" {
  name           = "Groups-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "users" {
  name           = "Users-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  global_secondary_index {
    name            = "groupid"
    hash_key        = "groupid"
    projection_type = "ALL"
  }

  attribute {
    name = "groupid"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "todos" {
  name           = "Todos-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  global_secondary_index {
    name            = "userid"
    hash_key        = "userid"
    projection_type = "ALL"
  }

  attribute {
    name = "userid"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}

## sample data

resource "aws_dynamodb_table_item" "group1" {
  table_name = aws_dynamodb_table.groups.name
  hash_key   = aws_dynamodb_table.groups.hash_key
  range_key   = aws_dynamodb_table.groups.range_key

  item = <<ITEM
{
  "id": {"S": "group1"},
	"name": {"S": "Group 1"}
}
ITEM
}

resource "aws_dynamodb_table_item" "group2" {
  table_name = aws_dynamodb_table.groups.name
  hash_key   = aws_dynamodb_table.groups.hash_key
  range_key   = aws_dynamodb_table.groups.range_key

  item = <<ITEM
{
  "id": {"S": "group2"},
	"name": {"S": "Group 2"}
}
ITEM
}

resource "aws_dynamodb_table_item" "user1" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key   = aws_dynamodb_table.users.range_key

  item = <<ITEM
{
  "groupid": {"S": "group1"},
  "id": {"S": "user1"},
	"name": {"S": "user 1"}
}
ITEM
}

resource "aws_dynamodb_table_item" "user2" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key
  range_key   = aws_dynamodb_table.users.range_key

  item = <<ITEM
{
  "groupid": {"S": "group2"},
  "id": {"S": "user2"},
	"name": {"S": "user 2"}
}
ITEM
}

