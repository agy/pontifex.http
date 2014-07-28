# Pontifex.Http.coffee
#
# © 2013 Dave Goehrig <dave@dloh.org>
# © 2014 wot.io LLC
# © 2014 WoT.io Inc

http = require 'http'
uuid = require 'uuid'
request = require 'request'

Http = (Bridge,Url) =>
	self = this

	# http :// wot.io : 80 / wot
	[ proto, host, port, domain ] = Url.match(///([^:]+)://([^:]+):(\d+)/([^\/]*)///)[1...]

	wot_authenticate = (token, command, path, callback) ->
		auth_req =
			url: "http://auth.wot.io/authenticate_token/#{token}/#{command}/#{path}"
			json: true
		console.log auth_req.url
		try
			request auth_req, (error, response, body) ->
				if !error and response.statusCode == 200
					console.log body
					if body.authenticate_token
						callback()
					else
						console.log 'Failed authentication'
		catch error
			console.log "[pontifex.http] #{error}"

	# HTTP server interface
	self.server = http.createServer (req,res) ->
		try
		# dynamically dispatch to the correct REST handler
			req.session = uuid.v4()
			self.server.stats.push [ 'created_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()]
			self.server.stats.push [ 'read_connection', req.url, req.session, domain, req.socket.bytesRead, new Date().getTime()]
			self[req.method.toLowerCase()]?.apply(self,[ req,res ])
		catch error
			console.log "[pontifex.http] Error #{error}"

	self.server.listen port
	self.server.stats = []

	self.server.flush_stats = () ->
		self.server.stats.map (x) ->
			Bridge.log x[1], x
		self.server.stats = []

	setInterval self.server.flush_stats, 60000	# flush stats once a minute

	# POST /exchange/key/queue	- creates a bus address for a source
	self.post = (req,res) ->
		[ token, exchange, key, queue ] = req.url.replace("%23","#").replace("%2a","*").match(////[^\/]*/([^\/]+)/([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		console.log [ token, exchange, key, queue ]
		wot_authenticate(token, 'create', "#{exchange}%2F#{key}%2F#{queue}", () ->
			Bridge.route exchange, key, queue, () ->
				data = JSON.stringify [ "ok", "/#{domain}/#{exchange}/#{key}/#{queue}" ]
				res.writeHead 201, { "Location": "/#{domain}/#{exchange}/#{key}/#{queue}", "Content-Type": "application/json", "Content-Length" : data.length }
				res.end data
				self.server.stats.push [ 'wrote_connection', req.url, req.session, domain, req.socket.bytesWritten, new Date().getTime()]
				self.server.stats.push [ 'closed_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()])


	# GET /exchange/key/queue	 - reads a message off of the queue
	self.get = (req,res) ->
		[ token, exchange, key, queue ] = req.url.replace("%23","#").replace("%2a","*").match(////[^\/]*/([^\/]+)/([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		console.log [ token, exchange, key, queue ]
		wot_authenticate(token, 'create', "#{exchange}%2F#{key}%2F#{queue}", () ->
			Bridge.read queue, (data) ->
				if data
					res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
					res.end data
					self.server.stats.push [ 'wrote_connection', req.url, req.session, domain, req.socket.bytesWritten, new Date().getTime()]
					self.server.stats.push [ 'closed_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()]
				else
					res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
					res.end()
					self.server.stats.push [ 'wrote_connection', req.url, req.session, domain, req.socket.bytesWritten, new Date().getTime()]
					self.server.stats.push [ 'closed_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()]

	# PUT exchange/key		- write a message to a sink
	self.put = (req,res) ->
		sink = req.url.replace("%23","#").replace("%2a","*")
		[ exchange, key ] = sink.match(////[^\/]*/([^\/]+)/([^\/]+)///)[1...]
		req.on 'data', (data) ->
			try
				message = JSON.parse(data)
				if message[0] == 'ping'
					data = JSON.stringify ['pong']
				else
					Bridge.send exchange, key, JSON.stringify(message)
					data = JSON.stringify [ "ok", sink ]

				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
				self.server.stats.push [ 'wrote_connection', req.url, req.session, domain, req.socket.bytesWritten, new Date().getTime()]
				self.server.stats.push [ 'closed_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()]
			catch error
				console.log "[pontifex.http] #{error}"

	# DELETE /exchange/key/queue		- removes a queue & binding
	self.delete = (req,res) ->
		[ exchange, key, queue ] = req.url.replace("%23","#").replace("%2a","*").match(////[^\/]*/([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.delete queue
		data = JSON.stringify [ "ok", req.url ]
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
		self.server.stats.push [ 'wrote_connection', req.url, req.session, domain, req.socket.bytesWritten, new Date().getTime()]
		self.server.stats.push [ 'closed_connection', req.url, req.session, domain, "#{req.socket.remoteAddress}:#{req.socket.remotePort}", new Date().getTime()]

	module.exports = Http
