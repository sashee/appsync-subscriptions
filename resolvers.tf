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
		"userid": {"S": $util.toJson($ctx.args.userId)},
		"checked": {"BOOL": false},
		"created": {"S": $util.toJson($util.time.nowISO8601())},
		"name": {"S": $util.toJson($ctx.args.name)},
		"severity": {"S": $util.toJson($ctx.args.severity)}
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
  data_source = aws_appsync_datasource.users.name
	name = "Mutation_addTodo_2"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.prev.result.userid)}
	}
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.qr($ctx.stash.put("user", $ctx.result))
$util.toJson($ctx.prev.result)
EOF
}

resource "aws_appsync_function" "Mutation_addTodo_3" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_addTodo_3"
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

resource "aws_appsync_function" "Mutation_addTodo_4" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.notifyTodo.name
	name = "Mutation_addTodo_4"
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
					"query": "mutation notifyTodo($userId: ID!, $groupId: ID!, $severity: Severity!, $id: ID!) {
						notifyTodo(userId: $userId, groupId: $groupId, severity: $severity, id: $id) {
							userId
							groupId
							todoId
							severity
							todo {
								id
								name
								checked
								created
								severity
							}
						}
					}",
					"operationName": 'notifyTodo',
					"variables": {
						"userId": $ctx.prev.result.userid,
						"groupId": $ctx.stash.user.groupid,
						"severity": $ctx.prev.result.severity,
						"id": $ctx.prev.result.id
					}
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
      aws_appsync_function.Mutation_addTodo_4.function_id,
    ]
  }
}

resource "aws_appsync_function" "Mutation_removeTodo_1" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_removeTodo_1"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.args.id)}
	}
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.qr($ctx.stash.put("todo", $ctx.result))
$util.toJson($ctx.result)
EOF
}

resource "aws_appsync_function" "Mutation_removeTodo_2" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.users.name
	name = "Mutation_removeTodo_2"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.prev.result.userid)}
	}
}
EOF

  response_mapping_template = <<EOF
#if ($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
$util.qr($ctx.stash.put("user", $ctx.result))
$util.toJson($ctx.result)
EOF
}
resource "aws_appsync_function" "Mutation_removeTodo_3" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_removeTodo_3"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "DeleteItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.args.id)}
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

resource "aws_appsync_function" "Mutation_removeTodo_4" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.notifyTodo.name
	name = "Mutation_removeTodo_4"
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
					"query": "mutation notifyTodo($userId: ID!, $groupId: ID!, $severity: Severity!, $id: ID!) {
						notifyTodo(userId: $userId, groupId: $groupId, severity: $severity, id: $id) {
							userId
							groupId
							todoId
							severity
							todo {
								id
								name
								checked
								created
								severity
							}
						}
					}",
					"operationName": 'notifyTodo',
					"variables": {
						"userId": $ctx.stash.user.id,
						"groupId": $ctx.stash.user.groupid,
						"severity": $ctx.stash.todo.severity,
						"id": $ctx.args.id
					}
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
$util.toJson($ctx.args.id)
EOF
}

resource "aws_appsync_resolver" "Mutation_removeTodo" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "removeTodo"

  request_template = "{}"
  response_template = <<EOF
$util.toJson($ctx.result)
EOF
  kind              = "PIPELINE"
  pipeline_config {
    functions = [
      aws_appsync_function.Mutation_removeTodo_1.function_id,
      aws_appsync_function.Mutation_removeTodo_2.function_id,
      aws_appsync_function.Mutation_removeTodo_3.function_id,
      aws_appsync_function.Mutation_removeTodo_4.function_id,
    ]
  }
}

resource "aws_appsync_function" "Mutation_notifyTodo_1" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.todos.name
	name = "Mutation_removeTodo_1"
  request_mapping_template = <<EOF
{
	"version" : "2018-05-29",
	"operation" : "GetItem",
	"key" : {
		"id": {"S": $util.toJson($ctx.args.id)}
	}
}
EOF

  response_mapping_template = <<EOF
{
	"userId": $util.toJson($ctx.args.userId),
	"groupId": $util.toJson($ctx.args.groupId),
	"todoId": $util.toJson($ctx.args.id),
	"severity": $util.toJson($ctx.args.severity),
	"todo": $util.toJson($ctx.result)
}
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

resource "aws_appsync_resolver" "Subscription_todo" {
  api_id      = aws_appsync_graphql_api.appsync.id
  data_source = aws_appsync_datasource.none.name
  type        = "Subscription"
  field       = "todo"

  request_template = <<EOF
{
	"version" : "2018-05-29",
	"payload": null
}
EOF
  response_template = <<EOF

#set($severityLevels = [])
#if($ctx.args.minSeverity == "HIGH")
	$util.qr($severityLevels.add("HIGH"))
#end
#if($ctx.args.minSeverity == "MEDIUM")
	$util.qr($severityLevels.add("MEDIUM"))
	$util.qr($severityLevels.add("HIGH"))
#end
#if($ctx.args.minSeverity == "LOW")
	$util.qr($severityLevels.add("LOW"))
	$util.qr($severityLevels.add("MEDIUM"))
	$util.qr($severityLevels.add("HIGH"))
#end

#set($nonDefinedFilters = [])
#if($util.isNull($ctx.args.userId))
	$util.qr($nonDefinedFilters.add("userId"))
#end
#if($util.isNull($ctx.args.groupId))
	$util.qr($nonDefinedFilters.add("groupId"))
#end
#if($util.isNull($ctx.args.minSeverity))
	$util.qr($nonDefinedFilters.add("severity"))
#end

$extensions.setSubscriptionFilter($util.transform.toSubscriptionFilter({
	"userId": {"eq": $ctx.args.userId},
	"groupId": {"eq": $ctx.args.groupId},
	"severity": {"in": $severityLevels}
},
$nonDefinedFilters
))

$util.toJson($ctx.result)
EOF
}

