# Http.coffee
#
# © 2013 Dave Goehrig <dave@dloh.org>
# © 2014 wot.io LLC
# © 2014 WoT.io Inc

http = require 'http'
uuid = require 'uuid'
request = require 'request'
EventEmitter = (require 'events').EventEmitter
decoder = new (require('string_decoder')).StringDecoder('utf8')
url = require 'url'

Http = (Url) ->
	self = this

	# http :// wot.io : 80 / wot
	[ proto, host, port, account ] = Url.match(///([^:]+)://([^:]+):([^/]+)/(.*)///)[1...]

	# HTTP server interface
	self.server = http.createServer (req,res) ->

		# Setup an event emitter and session id for this request
		emitter = new EventEmitter()
		session = uuid.v4()
		peer = req.header?['X-Forwarded-For'] || "#{req.socket.remoteAddress}:#{req.socket.remotePort}"

		# Log new connection
		self.created_connection?( peer )

		# Health check
		if url.parse(req.url).pathname == '/health'
			response = {
				pid: process.pid,
				uptime: process.uptime(),
				memory: process.memoryUsage()
			}
			emitter.emit 'response', 200, response
			return

		# Mixin the authorization behaviors
		self.auth?(emitter,req,res)

		# GET /exchange/key/queue   - reads a message off of the queue
		emitter.on 'get', (source) ->
			[ exchange, key, queue ] = source.split("/")
			console.log "Reading #{source}"
			self.read queue, (data) ->
				emitter.emit 'response', 200, data

		# POST /exchange/pattern/queue/exchange/key   - creates a bus address for a source
		emitter.on 'post', (source,sink) ->
			[ exchange, key, queue ] = source?.split("/") || []
			if not sink
				self.route exchange, key, queue, () ->
					emitter.emit 'response', 201, JSON.stringify([ "ok", "/#{account}/#{exchange}/#{key}/#{queue}" ]), { "Location": "/#{account}/#{source}" }
			else
				subscription = {}
				self.route exchange, key, "#{queue}.#{session}" , () ->
					self.subscribe "#{queue}.#{session}", subscription, ((message,headers) ->
						if headers.session == session
							console.log "Got message #{message} with headers #{headers}"
							emitter.emit 'response', 200, message
							self.unsubscribe "#{queue}.#{session}", subscription
						), () ->
							# send data when available
							req.on 'data', (data) ->
								message = JSON.parse(data)
								[ dest, path ] = sink?.split("/") || []
								self.send dest, path, JSON.stringify(message), { session: session }
			self

		# PUT exchange/key   - write a message to a sink
		emitter.on 'put', (sink) ->
			req.on 'data', (data) ->
				message = JSON.parse(data)
				if message[0] == 'ping'
					data = JSON.stringify ['pong']
				else
					[ exchange, key ] = sink.split("/")
					self.send exchange, key, JSON.stringify(message), { session: session }
					data = JSON.stringify [ "ok", sink ]
				emitter.emit 'response', 200, data

		# DELETE /exchange/key/queue   - removes a queue & binding
		emitter.on 'delete', (source) ->
			[ exchange, key, queue ] = source.split("/")
			self.delete queue
			emitter.emit 'response', 200, JSON.stringify [ "ok", req.url ]

		# Handles when the URI is parsed
		emitter.on 'parsed', (account, source, sink, token) ->
			# Handle OAuth style request
			switch req.method.toLowerCase()
				when "get" then emitter.emit 'authorize', token,'read',source
				when "post" then emitter.emit 'authorize', token,'create',source, 'read', source, 'write', sink
				when "put" then emitter.emit 'authorize', token,'write',sink
				when "delete" then emitter.emit 'authorize', token,'delete',source

		# Handles dispatching an authorized HTTP request
		emitter.on 'authorized', (source,sink) ->
			self.authenticated_connection?(peer)
			switch req.method.toLowerCase()
				when "get" then emitter.emit 'get', source
				when "post" then emitter.emit 'post', source, sink
				when "put" then emitter.emit 'put', sink
				when "delete" then emitter.emit 'delete', source

		emitter.on 'unauthorized', () ->
			self.rejected_connection?(peer)
			emitter.emit 'response', 401, ""

		# response handler
		emitter.on 'response', (code,data,headers) ->
			headers ?= {}
			headers["Content-Type"] = "application/json"
			if data
				headers["Content-Length"] = data.length
			res.writeHead code, headers
			if data
				res.write data
			res.end()
			self.wrote_connection?(req.socket.bytesWritten)
			self.closed_connection?(false)

		# Kick off the auth process
		emitter.emit 'parse', req.url, req.headers.authorization?.match(/bearer (.*)/i)[1]

	# Primary Listening Platform
	self.server.listen port

module.exports = Http
