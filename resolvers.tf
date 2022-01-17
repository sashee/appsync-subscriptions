resource "aws_appsync_resolver" "Query_allGroups" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.groups.name
  type        = "Query"
  field       = "allGroups"

  request_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "Scan"
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result.items)
EOF
}

resource "aws_appsync_function" "Mutation_addTodo_1" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_addTodo_1"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "PutItem",
	"key" : {
		"id": {"S": $util.toJson($util.autoId())}
	},
	"attributeValues": {
		"userid": {"S": $util.toJson($ctx.arguments.userId)},
		"checked": {"BOOL": false},
		"created": {"S": $util.toJson($util.time.nowISO8601())},
		"name": {"S": $util.toJson($ctx.arguments.name)}
	}
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_function" "Mutation_addTodo_2" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_addTodo_2"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.prev.result.id)}
	}
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_function" "Mutation_addTodo_3" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.notifyTodo.name
	name = "Mutation_addTodo_3"
  request_mapping_template = <<EOF
{
    "version": "2018-05-29",
    "method": "POST",
    "params": {
        "query": {},
        "headers": {
					"Content-Type" : "application/json"
				},
				"body": $util.toJson({
					"query": "mutation notifyTodo($id: ID!) {
						notifyTodo(id: $id) {
							userId
							groupId
							todo {
								id
								name
								checked
								created
							}
						}
					}",
					"operationName": 'notifyTodo',
					"variables": {"id": $ctx.prev.result.id}
				})
    },
    "resourcePath": "/graphql"
}
EOF

  response_mapping_template = <<EOF
#set($result = $util.parseJson($ctx.result.body))
#if ($result.errors)
	$util.error($result.errors[0].message)
#end
$util.toJson($ctx.prev.result)
EOF
}

resource "aws_appsync_resolver" "Mutation_addTodo" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "addTodo"

  request_template = "{}"
  response_template = <<EOF
$util.toJson($ctx.result)
EOF
  kind              = "PIPELINE"
  pipeline_config {
    functions = [
      aws_appsync_function.Mutation_addTodo_1.function_id,
      aws_appsync_function.Mutation_addTodo_2.function_id,
      aws_appsync_function.Mutation_addTodo_3.function_id,
    ]
  }
}

resource "aws_appsync_function" "Mutation_notifyTodo_1" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_notifyTodo_1"

  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.args.id)}
	},
	"consistentRead" : true
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_function" "Mutation_notifyTodo_2" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.users.name
	name = "Mutation_notifyTodo_2"

  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.prev.result.userid)}
	},
	"consistentRead" : true
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson({"userId": $ctx.prev.result.userid, "groupId": $ctx.result.groupid, "todo": $ctx.prev.result})
EOF
}

resource "aws_appsync_resolver" "Mutation_notifyTodo" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "notifyTodo"

  request_template = "{}"
  response_template = <<EOF
$util.toJson($ctx.result)
EOF
  kind              = "PIPELINE"
  pipeline_config {
    functions = [
      aws_appsync_function.Mutation_notifyTodo_1.function_id,
      aws_appsync_function.Mutation_notifyTodo_2.function_id,
    ]
  }
}

resource "aws_appsync_resolver" "Group_users" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.users.name
  type        = "Group"
  field       = "users"

  request_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "Query",
	"query" : {
		"expression": "groupid = :groupid",
		"expressionValues" : {
			":groupid" : $util.dynamodb.toDynamoDBJson($ctx.source.id)
		}
	},
	"index": "groupid"
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result.items)
EOF
}

resource "aws_appsync_resolver" "User_todos" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
  type        = "User"
  field       = "todos"

  request_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "Query",
	"query" : {
		"expression": "userid = :userid",
		"expressionValues" : {
			":userid" : $util.dynamodb.toDynamoDBJson($ctx.source.id)
		}
	},
	"index": "userid"
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result.items)
EOF
}

resource "aws_appsync_resolver" "Todo_user" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.users.name
  type        = "Todo"
  field       = "user"

  request_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key": {
		"id": $util.dynamodb.toDynamoDBJson($ctx.source.userid)
	},
	"consistentRead" : true
}
EOF
  response_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

