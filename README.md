## pontifex.http

A HTTP to AMQP Bridge

### Getting Started

#### Start the adapter process

Following the general pontifex documentation, but using 'http' as the
protocol, start up the process. The following creates a HTTP to AMQP bridge and
directs all messages to '/' vhost

	pontifex 'http://localhost:8088/' 'amqp://guest:guest@localhost:5672/'

This will create a HTTP to AMQP bridge and direct all messages to '/wot' with
some additional configuration of the source account, application,
application instance, etc.

	pontifex 'http://localhost:8088/wot' 'amqp://guest:guest@localhost:5672/wot/http-test/#/http-1/http-test/http-1'

#### Hitting the Adapter

To run some simple tests, you can send messages to the http adapter using curl.
The following creates an exchange called test-exchange, with a routing key #,
that directs all messages to test-queue.

	curl -X POST 'http://localhost:8088//test-exchange/%23/test-queue'

The same, but for the 'wot' vhost shown above:

	curl -X POST 'http://localhost:8088/wot/test-exchange/%23/test-queue'

Send a JSON message to the test-exchange exchange with a routing key of foobar:

	curl -X PUT 'http://localhost:8088/wot/test-exchange/foobar' -d '[ "run", "ls", "-al" ]'

Access the queue to read a message off of the test-queue:

	curl 'http://localhost:8088/wot/test-exchange/%23/test-queue'

And finally, delete the test-queue:

	curl -X DELETE 'http://localhost:8088/wot/test-exchange/%23/test-queue'
