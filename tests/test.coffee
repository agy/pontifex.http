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

	# Define test parameters
	post_URL = 'http://127.0.0.1:8080/wottest/test-exchange/test-key/test-queue'
	put_URL  = 'http://127.0.0.1:8080/wottest/test-exchange/test-key'
	get_URL  = 'http://127.0.0.1:8080/wottest/test-exchange/test-key/test-queue'
	del_URL  = 'http://127.0.0.1:8080/wottest/test-exchange/test-key/test-queue'
	unauthorized_URL = 'http://127.0.0.1:8080/wottest/Xtest-exchangeX/Xtest-keyX/Xtest-queueX'
	invalid_path_format_URL = 'http://127.0.0.1:8080/wottest/leeroyjenkins'
	valid_token = '' # Gets filled in with a generated token
	invalid_token = 'bearer x'

	# We build the components of a fake pontifex module which store data
	# locally instead of sending it on the bus
	self = this
	Amqpurl = 'amqp://0.0.0.0:1234/wottest/test-exchange/key/test-queue/test-exchange/test-queue'
	Url = '127.0.0.1/wot'
	port = '8080'

	# Callbacks used by pontifex.http
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
	## Tests written verbosely for easy reading and debugging on failure
	##

	# Loading & defining module
	#
	it 'should load pontifex.http', () ->
		chai.expect(pontifex_http).to.be.a('function')
	it 'pontifex.http should accept the right parameters', () ->
		pontifex_http?.apply(pontifex_http, [self,Url,port])

	# Fail auth on bad token
	#
	it "should fail auth on POST token", (done) ->
		reqparams = {uri: post_URL, method: "POST", timeout: 1000, headers: { authorization: invalid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on PUT token", (done) ->
		reqparams = {uri: put_URL, method: "PUT", timeout: 1000, headers: { authorization: invalid_token }, form: '["foo"]'}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on GET token", (done) ->
		reqparams = {uri: get_URL, method: "GET", timeout: 1000, headers: { authorization: invalid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on DELETE token", (done) ->
		reqparams = {uri: del_URL, method: "DELETE", timeout: 1000, headers: { authorization: invalid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()

	# Fail auth on bad path permissions
	#
	it "should fail auth on POST path", (done) ->
		reqparams = {uri: unauthorized_URL, method: "POST", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on PUT path", (done) ->
		reqparams = {uri: unauthorized_URL, method: "PUT", timeout: 1000, headers: { authorization: valid_token }, form: '["foo"]'}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on GET path", (done) ->
		reqparams = {uri: unauthorized_URL, method: "GET", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()
	it "should fail auth on DELETE path", (done) ->
		reqparams = {uri: unauthorized_URL, method: "DELETE", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(401)
			done()

	# Not respond on bad path format
	#
	it "should return 400 on bad POST path format", (done) ->
		reqparams = {uri: invalid_path_format_URL, method: "POST", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(400)
			done()
	it "should return 400 on bad PUT path format", (done) ->
		reqparams = {uri: invalid_path_format_URL, method: "PUT", timeout: 1000, headers: { authorization: valid_token }, form: '["foo"]'}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(400)
			done()
	it "should return 400 on bad GET path format", (done) ->
		reqparams = {uri: invalid_path_format_URL, method: "GET", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(400)
			done()
	it "should return 400 on bad DELETE path format", (done) ->
		reqparams = {uri: invalid_path_format_URL, method: "DELETE", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(400)
			done()

	# Succeed and return valid data
	#
	it "should respond to valid POST with proper headers and data", (done) ->
		reqparams = {uri: post_URL, method: "POST", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(201)
			done()
	it "should respond to valid PUT with proper headers and data", (done) ->
		reqparams = {uri: put_URL, method: "PUT", timeout: 1000, headers: { authorization: valid_token }, form: '["foo"]'}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(200)
			done()
	it "should respond to valid GET with proper headers and data", (done) ->
		reqparams = {uri: get_URL, method: "GET", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(200)
			chai.expect(body).to.equal('[ "test", "array" ]')
			done()
	it "should respond to valid DELETE with proper headers and data", (done) ->
		reqparams = {uri: del_URL, method: "DELETE", timeout: 1000, headers: { authorization: valid_token }}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(200)
			done()

	# Ping/Pong
	#
	it "should play Ping Pong", (done) ->
		reqparams = {uri: put_URL, method: "PUT", timeout: 1000, headers: { authorization: valid_token }, form: '["ping"]'}
		request reqparams, (error, response, body) ->
			chai.expect(response.statusCode).to.equal(200)
			chai.expect(body).to.equal('["pong"]')
			done()


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