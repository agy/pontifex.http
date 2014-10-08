# Pontifex.Http.coffee
#
# © 2013 Dave Goehrig <dave@dloh.org>
# © 2014 wot.io LLC
# © 2014 WoT.io Inc

http = require 'http'
uuid = require 'uuid'
request = require 'request'
EventEmitter = (require 'events').EventEmitter

Http = (Bridge,Url) =>
	auth = process.env['AUTH']
	self = this

	# http :// wot.io : 80 / wot
	[ proto, host, port, domain ] = Url.match(///([^:]+)://([^:]+):([^/]+)/(.*)///)[1...]

	# HTTP server interface
	self.server = http.createServer (req,res) ->
		try
			# parse the path
			source = unescape(req.url).match(////[^\/]*/([^\/]+)/([^\/]*)/*([^\/]*).*///)[1...].join("/")
			sink = unescape(req.url).match(////[^\/]*/([^\/]+)/([^\/]*).*///)[1...].join("/")

			emitter = new EventEmitter()
			# generate a session id
			req.session = uuid.v4()
			token = req.headers.authorization.match(/bearer (.*)/i)[1]

			# unauthorized handler
			emitter.on 'unauthorized', () ->
				emitter.emit 'response', 401, ""	

			# dynamically dispatch to the correct REST handler
			emitter.on 'authorized', () ->
				# Log the connection
				self.server.stats.push [ 'created_connection', domain, req.url, req.session, "#{req.connection.remoteAddress}:#{req.connection.remotePort}", new Date().getTime()]
				self.server.stats.push [ 'read_connection', domain, req.url, req.session, req.socket.bytesRead, new Date().getTime()]
				self[req.method.toLowerCase()]?.apply(self,[ req, res, source, sink, emitter ])

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
				self.server.stats.push [ 'wrote_connection', domain, req.url, req.session, req.socket.bytesWritten, new Date().getTime()]
				self.server.stats.push [ 'closed_connection', domain, req.url, req.session, "#{req.connection.remoteAddress}:#{req.connection.remotePort}", new Date().getTime()]
	
			# authenticate the endpoint
			switch req.method.toLowerCase()
				when "get" then self.authorize token,'read',source,emitter
				when "post" then self.authorize token,'create',source,emitter
				when "put" then self.authorize token,'write',sink,emitter
				when "delete" then self.authorize token,'delete',source,emitter

		catch error
			console.log "[pontifex.http] Error #{error}"
			res.end()
	
	# Authorize via the auth server
	# OAuth2-like Authentication *Temporary, until full OAuth2 support is added*
	# As specified in: http://tools.ietf.org/html/rfc6749
	#                  http://tools.ietf.org/html/rfc6750
	self.authorize = (token,operation,path,emitter) ->
		if not token
			emitter.emit 'unauthorized'
		request "http://#{auth}/authenticate_token/#{token}/#{operation}/#{escape(path).replace(///////g,"%2f")}", (error,resp,body) ->   #/)}" << Syntax Highlighting Fix
			if error
				console.log error
				emitter.emit 'unauthorized'
			if JSON.parse(body).authenticate_token
				emitter.emit 'authorized'
			else
				emitter.emit 'unauthorized'

	# POST /exchange/key/queue   - creates a bus address for a source
	self.post = (req,res,source,sink,emitter) ->
		[ exchange, key, queue ] = source.split("/")
		Bridge.route exchange, key, queue, () ->
			emitter.emit 'response', 201, JSON.stringify([ "ok", "/#{domain}/#{exchange}/#{key}/#{queue}" ]), { "Location": "/#{domain}/#{source}" }

	# GET /exchange/key/queue   - reads a message off of the queue
	self.get = (req,res,source,sink,emitter) ->
		[ exchange, key, queue ] = source.split("/")
		Bridge.read queue, (data) ->
			emitter.emit 'response', 200, data

	# PUT exchange/key   - write a message to a sink
	self.put = (req,res,source,sink,emitter) ->
		req.on 'data', (data) ->
			message = ''
			try
				message = JSON.parse(data)
				if message[0] == 'ping' then data = JSON.stringify ['pong']
			catch
				message = data
			if data != JSON.stringify ['pong']
				[ exchange, key ] = sink.split("/")
				Bridge.send exchange, key, JSON.stringify(message)
				data = JSON.stringify [ "ok", sink ]
			emitter.emit 'response', 200, data
		# If the client doesn't send any data, then the server does nothing. We should then timeout the connection.
		setTimeout ( () ->
			if !res.finished then emitter.emit 'response', 400
		), 5000

	# DELETE /exchange/key/queue   - removes a queue & binding
	self.delete = (req,res,source,sink,emitter) ->
		[ exchange, key, queue ] = source.split("/")
		Bridge.delete queue
		emitter.emit 'response', 200, JSON.stringify [ "ok", req.url ]

	# Primary Listening Platform
	self.server.listen port
	self.server.stats = []
	self.server.flush_stats = () ->
		self.server.stats.map (x) ->
			Bridge.log x[1], x
		self.server.stats = []

	setInterval self.server.flush_stats, 60000	# flush stats once a minute

module.exports = Http
