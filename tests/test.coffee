# Pontifex.http unit tests
#
# © 2014 Andrew Khoury <drew@wot.io>
# © 2014 WoT.io, Inc


assert = require 'assert'
request = require 'request'
chai = require '/usr/local/lib/node_modules/chai'
chai.expect()

describe 'Pontifex HTTP', () ->
	# We build the components of a fake pontifex module which store data
	# locally instead of sending it on the bus
	self = this
	connopts =
		proto: 'http'
		user: 'uesr'
		password: 'pass'
		host: 'Chicken Little'
		domain: 'Gary Coleman'
	Amqpurl = 'amqp://0.0.0.0:1234/wot/test-exchange/key/test-queue/test-exchange/test-queue'
	Url = 'http://127.0.0.1:8081/wot'
	authtoken = 'authorization: bearer 01Qk925hduUux13Z'
	args = [ Url, Amqpurl ]

	postURL = 'http://127.0.01:8081/wot/test-exchange/%23/test-queue'
	putURL = 'http://127.0.01:8081/wot/test-exchange/foobar'
	getURL = 'http://127.0.01:8081/wot/test-exchange/%23/test-queue'
	delURL = 'http://127.0.01:8081/wot/test-exchange/%23/test-queue'

	log = (key,msg) ->
		[ key, msg ]
	route = (exchange,key,queue,cont) ->
		[ exchange, key, queue, cont ]
	read = (queue,fun) ->
		[ queue, fun ]
	send = () ->
		[ exchange, key, msg ]

	pontifex_http = require 'pontifex.http'

	it 'should load pontifex.http', () ->
		chai.expect(pontifex_http).to.be.a('function')

	it 'pontifex.http should accept the right parameters', () ->
		pontifex_http?.apply(pontifex_http, [self,Url].concat(args))

	it 'should use POST to create a queue', (done) ->
		reqparms =
			uri: postURL,
			method: "POST",
			timeout: 1000,
			headers: { authtoken }

		request reqparms, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401);
			done()
