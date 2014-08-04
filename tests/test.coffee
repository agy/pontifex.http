# Pontifex.http unit tests
#
# © 2014 Andrew Khoury <drew@wot.io>
# © 2014 WoT.io, Inc


assert = require 'assert'
request = require 'request'
chai = require '/usr/local/lib/node_modules/chai'
chai.expect()

describe 'Pontifex HTTP', () ->
	authtoken = 'bearer 01DuT0mz_pQAnf_T'
	call_count = 4
	do_tests = () ->
		call_count++
		if call_count != 5 then return
		# We build the components of a fake pontifex module which store data
		# locally instead of sending it on the bus
		self = this
		connopts =
			proto: 'http'
			user: 'uesr'
			password: 'pass'
			host: 'Chicken Little'
			domain: 'Gary Coleman'
		Amqpurl = 'amqp://0.0.0.0:1234/wottest/test-exchange/key/test-queue/test-exchange/test-queue'
		Url = 'http://127.0.0.1:8081/wot'
		args = [ Url, Amqpurl ]

		postURL = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'
		putURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key'
		getURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'
		delURL  = 'http://127.0.0.1:8081/wottest/test-exchange/test-key/test-queue'

		self.log = (key,msg) ->
			[ key, msg ]
		self.route = (exchange,key,queue,cont) ->
			[ exchange, key, queue, cont ]
		self.read = (queue,fun) ->
			fun ('[ "test", "array" ]')
			return
		self.send = (exchange, key, msg) ->
			[ exchange, key, msg ]
		self.delete = (queue) ->


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
			reqparams = {uri: postURL, method: "POST", timeout: 1000, headers: { authorization: "bearer invalid" }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on PUT", (done) ->
			reqparams = {uri: putURL, method: "PUT", timeout: 1000, headers: { authorization: "bearer invalid" }, data: '[ "run", "ls", "-al" ]'}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on GET", (done) ->
			reqparams = {uri: getURL, method: "GET", timeout: 1000, headers: { authorization: "bearer invalid" }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()
		it "should fail auth on DELETE", (done) ->
			reqparams = {uri: delURL, method: "DELETE", timeout: 1000, headers: { authorization: "bearer invalid" }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(401);
				done()

		# Succeed and return valid data
		it "should accept POST", (done) ->
			reqparams = {uri: postURL, method: "POST", timeout: 1000, headers: { authorization: authtoken }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(201);
				done()
		it "should accept PUT", (done) ->
			reqparams = {uri: putURL, method: "PUT", timeout: 1000, headers: { authorization: authtoken }, data: '[ "run", "ls", "-al" ]'}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				done()
		it "should accept GET", (done) ->
			reqparams = {uri: getURL, method: "GET", timeout: 1000, headers: { authorization: authtoken }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				done()
		it "should accept DELETE", (done) ->
			reqparams = {uri: delURL, method: "DELETE", timeout: 1000, headers: { authorization: authtoken }}
			request reqparams, (error, response, body) ->
				chai.expect(response.statusCode).to.equal(200);
				done()
	do_tests()

###
##
## Prepare a user and token with full permissions in order to test.
## Make sure to revoke when done.
##
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
	do_tests()

create_token_req =
	url: 'http://auth.wot.io/create_token/wottest/wottest/wottest/20140723/21000723'
	json: true
request create_token_req, (error, response, body) ->
	authtoken = "bearer #{body.create_token}"
	do_tests()


##
## Delete auth token and ACLs that were used for testing
##
unauth_for_testing = () ->
###
