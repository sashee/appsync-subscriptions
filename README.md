# Example code for AppSync Subscriptions

## Requirements

* terraform
* AWS account
* AWS CLI configured

## Deploy

* ```terraform init```
* ```terraform apply```

## Use

### Basic filtering

Go to the AWS Management Console and subscribe to new Todo items:

```graphql
subscription MySubscription {
  newTodo(name: "todo1") {
    checked
    created
    name
    id
  }
}
```

On a separate tab, create a new Todo:

```graphql
mutation MyMutation {
  addTodo(name: "todo1", userId: "user1") {
    id
    name
    created
    checked
  }
}
```

There is an event on the first tab. Try again with a different name:

```graphql
mutation MyMutation {
  addTodo(name: "todo5", userId: "user1") {
    id
    name
    created
    checked
  }
}
```

No event this time.

### Advanced filtering

Subscribe to the other subscription field:

```graphql
subscription MySubscription {
  todo(userId: "user1") {
    todo {
      checked
      created
      id
      name
    }
  }
}
```

Create a Todo item:

```graphql
mutation MyMutation {
  addTodo(name: "todo5", userId: "user1") {
    id
  }
}
```

There is an event. Notice that the Mutation has fewer fields than the Subscription.

## Cleanup

* ```terraform destroy```
