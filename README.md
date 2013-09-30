pontifex.http
============

A HTTP to AMQP Bridge

Getting Started
---------------

	pontifex 'http://localhost:8088/' 'amqp://guest:guest@localhost:5672/'

This will create a HTTP to AMQP bridge and direct all messages to '/' vhost

	curl -X POST 'http://localhost:8088/test-exchange/%23/test-queue'

Will create an exchange called test-exchange, with a routing key of #, that directs all messages to test-queue.

	curl -X PUT 'http://localhost:8088/test-exchange/foobar' -d '[ "run", "ls", "-al" ]'

Will send the JSON message to the test-exchange exchange with a routing key of foobar

	curl 'http://localhost:8088/test-queue'

Will read a message off of the test-queue and

	curl -X DELETE 'http://localhost:8088/test-queue'

Will delete the test-queue.

