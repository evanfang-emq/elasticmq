# ElasticMQ Connect to SQL Database

Persisting queue data using PostgreSQL.

## Build and Run Locally

You need `sbt` to build.

If you are using Mac:
```sh
brew install sbt
```

| The following scripts has been tested by sbt version `1.6.2`.

To build and run with debug (this will listen for a remote debugger on port 5005):
```sh
sbt -jvm-debug 5005
> project server
> run
```

To build a jar:
```sh
sbt 'project server' 'set assemblyOutputPath in assembly := new File("dist/elasticmq-server.jar")' 'assembly'

# the compiled jar file would be put into `dist` folder.
```

To run a jar:
```sh
java -jar dist/elasticmq-server.jar
```

If you would like to run with specifying a configuration file.
```sh
# copy example file and edit it
cp custom.local.conf.example custom.local.conf

# run with config file
java -Dconfig.file=custom.local.conf -jar dist/elasticmq-server.jar
```
Note that by default, the configuration file is using the database named `queuedb`.

Make sure you had prepared the database before starting ElasticMQ.

## Web UI

User interface for browsing queue information.

Browse `http://localhost:9325/` or start locally:
```sh
cd ui
yarn install
yarn start
```

## Configurations

When you run ElasticMQ server in sbt console, `rest/rest-sqs/src/main/resources/application.conf` will be loaded. By default, it is an in-memory queue.

If you want to make ElasticMQ to connect to your local PostgreSQL database, you need to enable `messages-storage` configuration, for example:
```ini
messages-storage {
  enabled = true
  uri = "jdbc:postgresql://localhost:5432/queuedb"
  driver-class = "org.postgresql.Driver"
  username = "root"
  password = "admin"
}
```

If you want to create queues while ElasticMQ starts running, you could add following configurations:
```ini
queues {
  queue1 {
    defaultVisibilityTimeout = 10 seconds
    delay = 5 seconds
    receiveMessageWait = 0 seconds
    deadLettersQueue {
      name = "queue1-dead-letters"
      maxReceiveCount = 3 // from 1 to 1000
    }
    fifo = false
    contentBasedDeduplication = false
    copyTo = "audit-queue-name"
    moveTo = "redirect-queue-name"
    tags {
      tag1 = "tagged1"
      tag2 = "tagged2"
    }
  }
  queue1-dead-letters { }
  audit-queue-name { }
  redirect-queue-name { }
}
```

## Docker

Use docker-compose to start ElasticMQ server and a PostgreSQL database.

```sh
docker-compose up --build

# or just
docker-compose up

# or run in detached mode
docker-compose up -d
```

## Test with AWS-CLI
```sh
export AWS_ACCESS_KEY_ID=x
export AWS_SECRET_ACCESS_KEY=x
export AWS_DEFAULT_REGION=us-east-1

alias awslocal="aws --endpoint-url=http://localhost:9324"

# list queue
awslocal sqs list-queues

# create queue
awslocal sqs create-queue --queue-name myqueue

# get a queue's url
awslocal sqs get-queue-url --queue-name myqueue

export QUEUE_URL=http://localhost:9324/000000000000/myqueue

# send message
awslocal sqs send-message --queue-url $QUEUE_URL --message-body hi

# get message
awslocal sqs receive-message --queue-url $QUEUE_URL
```
