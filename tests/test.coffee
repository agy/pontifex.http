# Pontifex.http unit tests
#
# © 2014 Andrew Khoury <drew@wot.io>
# © 2014 WoT.io, Inc


assert = require 'assert'
request = require 'request'
chai = require '/usr/local/lib/node_modules/chai'
chai.should()

describe 'Pontifex HTTP', () ->
	self = this
	connopts =
		proto: 'http'
		user: 'uesr'
		password: 'pass'
		host: 'Chicken Little'
		domain: 'Gary Coleman'
	Amqpurl = 'amqp://0.0.0.0:1234/domain/exchange1/key/queue1/exchange2/queue2'
	Url = 'http://0.0.0.0:1234/domain'
	args = [ Url, Amqpurl ]
	log = () ->
	route = (exchange,key,queue,cont) ->
	read = () ->
	send = () ->

	pontifex_http = require 'pontifex.http'
	pontifex_http?.apply(pontifex_http, [self,Url].concat(args))

	chai.expect(pontifex_http).to.be.a('function')