# Pontifex.http unit tests
#
# © 2014 Andrew Khoury <drew@wot.io>
# © 2014 WoT.io, Inc

pontifex = require 'pontifex'
assert = require 'assert'
request = require 'request'
chai = require '/usr/local/lib/node_modules/chai'
chai.should()

# TODO: Fix asynchronous testing

reqparms =
	uri: "http://www.google.com",
	method: "GET",
	timeout: 10000,
	followRedirect: true,
	maxRedirects: 10

request reqparms, (error, response, body) ->
	console.log body

describe 'Pontifex HTTP', () ->
	pontifex("amqp://wot:wotsallthisthen!@bus.wot.io:5672/wot/test-exchange/%23/test-queue/test-exchange/test-queue")("http://localhost:8081/wot")

	it 'Should export pontifex function properly', () ->
	chai.expect(pontifex).to.be.a('function');

	it 'Should connect to the bus', () ->
		reqparms =
			uri: "http://localhost:8081/wot/test-exchange/%23/test-queue",
			method: "POST",
			timeout: 10000,
			headers: { "authorization: bearer 01Qk925hduUux13Z" }

		request reqparms, (error, response, body) ->
			console.log error
			assert(body == 'h', 'Body!!')
