provider "aws" {
}

data "aws_region" "current" {}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_iam_role" "appsync" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "appsync" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
			"dynamodb:Query",
			"dynamodb:Scan",
    ]
    resources = [
			aws_dynamodb_table.groups.arn,
			"${aws_dynamodb_table.groups.arn}/index/*",
			aws_dynamodb_table.users.arn,
			"${aws_dynamodb_table.users.arn}/index/*",
			aws_dynamodb_table.todos.arn,
			"${aws_dynamodb_table.todos.arn}/index/*",
    ]
  }
  statement {
    actions = [
      "appsync:GraphQL",
    ]
    resources = [
			"${aws_appsync_graphql_api.appsync.arn}/types/Mutation/fields/notifyTodo"
    ]
  }
}

resource "aws_iam_role_policy" "appsync" {
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync.json
}

resource "aws_appsync_graphql_api" "appsync" {
  name                = "appsync_test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_IAM"
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ALL"
  }
}

data "aws_iam_policy_document" "appsync_push_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "appsync_logs" {
  assume_role_policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [
		{
		"Effect": "Allow",
		"Principal": {
			"Service": "appsync.amazonaws.com"
		},
		"Action": "sts:AssumeRole"
		}
	]
}
POLICY
}

resource "aws_iam_role_policy" "appsync_logs" {
  role   = aws_iam_role.appsync_logs.id
  policy = data.aws_iam_policy_document.appsync_push_logs.json
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.appsync.id}"
  retention_in_days = 14
}

resource "aws_appsync_datasource" "groups" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "groups"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.groups.name
  }
}

resource "aws_appsync_datasource" "users" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "users"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.users.name
  }
}

resource "aws_appsync_datasource" "todos" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "todos"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.todos.name
  }
}

resource "aws_appsync_datasource" "notifyTodo" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "notifyTodo"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "HTTP"
	http_config {
		endpoint = regex("^[^/]+//[^/]+", aws_appsync_graphql_api.appsync.uris["GRAPHQL"])
		authorization_config {
			aws_iam_config {
				signing_region = data.aws_region.current.name
				signing_service_name = "appsync"
			}
		}
	}
}
