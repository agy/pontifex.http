# Pontifex.http unit tests
#
# © 2014 Andrew Khoury <drew@wot.io>
# © 2014 WoT.io, Inc


assert = require 'assert'
request = require 'request'
chai = require '/usr/local/lib/node_modules/chai'
chai.expect()

describe 'Pontifex HTTP', () ->
	# Override console.log for cleaner output
	console.log = () ->
		return

	# Define some parameters
	postURL = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'
	putURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key'
	getURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'
	delURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'
	valid_token = ''
	invalid_token = 'bearer x'

	do_tests = () ->
		# We build the components of a fake pontifex module which store data
		# locally instead of sending it on the bus
		self = this
		Amqpurl = 'amqp://0.0.0.0:1234/wottest/test-exchange/key/test-queue/test-exchange/test-queue'
		Url = 'http://127.0.0.1:8081/wot'
		args = [ Url, Amqpurl ]

		self.log = (key,msg) ->
			return
		self.route = (exchange,key,queue,cont) ->
			cont()
			return
		self.read = (queue,fun) ->
			fun ('[ "test", "array" ]')
			return
		self.send = (exchange, key, msg) ->
			return
		self.delete = (queue) ->
			return

		pontifex_http = require 'pontifex.http'

		##
		## TESTS BEGIN HERE
		##

		# Loading & defining module
		it 'should load pontifex.http', () ->
			chai.expect(pontifex_http).to.be.a('function')
		it 'pontifex.http should accept the right parameters', () ->
			pontifex_http?.apply(pontifex_http, [self,Url].concat(args))

		# Fail auth on bad token
		it "should fail auth on POST", (done) ->
			reqparams = {uri: postURL, method: "POST", timeout: 1000, headers: { authorization: invalid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on PUT", (done) ->
			reqparams = {uri: putURL, method: "PUT", timeout: 1000, headers: { authorization: invalid_token }, form: '["foo"]'}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on GET", (done) ->
			reqparams = {uri: getURL, method: "GET", timeout: 1000, headers: { authorization: invalid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on DELETE", (done) ->
			reqparams = {uri: delURL, method: "DELETE", timeout: 1000, headers: { authorization: invalid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()

		# Succeed and return valid data
		it "should accept POST", (done) ->
			reqparams = {uri: postURL, method: "POST", timeout: 1000, headers: { authorization: valid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(201);
				done()
		it "should accept PUT", (done) ->
			reqparams = {uri: putURL, method: "PUT", timeout: 1000, headers: { authorization: valid_token }, form: '["foo"]'}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				done()
		it "should accept GET", (done) ->
			reqparams = {uri: getURL, method: "GET", timeout: 1000, headers: { authorization: valid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				chai.expect(body).to.equal('[ "test", "array" ]')
				done()
		it "should accept DELETE", (done) ->
			reqparams = {uri: delURL, method: "DELETE", timeout: 1000, headers: { authorization: valid_token }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				done()
	do_tests()

	##
	## Prepare a user and token with full permissions in order to test.
	## Make sure to revoke when done.
	##
	before () ->
		auth_requests =
			grant_create:
				url: 'http://auth.wot.io/grant_acl/wottest/wottest/create/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
			grant_read:
				url: 'http://auth.wot.io/grant_acl/wottest/wottest/read/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
			grant_write:
				url: 'http://auth.wot.io/grant_acl/wottest/wottest/write/test-exchange%2Ftest-key'
				json: true
			grant_delete:
				url: 'http://auth.wot.io/grant_acl/wottest/wottest/delete/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
		for req of auth_requests
			request auth_requests[req], (error, response, body) ->
				return

		create_token_req =
			url: 'http://auth.wot.io/create_token/wottest/wottest/wottest/20140723/21000723'
			json: true
		request create_token_req, (error, response, body) ->
			valid_token = "bearer #{body.create_token}"


	##
	## Revoke ACLs and tokens when done.
	##
	after () ->
		auth_requests =
			revoke_create:
				url: 'http://auth.wot.io/revoke_acl/wottest/wottest/create/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
			revoke_read:
				url: 'http://auth.wot.io/revoke_acl/wottest/wottest/read/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
			revoke_write:
				url: 'http://auth.wot.io/revoke_acl/wottest/wottest/write/test-exchange%2Ftest-key'
				json: true
			revoke_delete:
				url: 'http://auth.wot.io/revoke_acl/wottest/wottest/delete/test-exchange%2Ftest-key%2Ftest-queue'
				json: true
			revoke_token:
				url: "http://auth.wot.io/deactivate_token/#{valid_token}"
				json: true
		for req of auth_requests
			request auth_requests[req], (error, response, body) ->
				return