# Pontifex.Http.coffee
#
# © 2013 Dave Goehrig <dave@dloh.org>
# © 2014 wot.io LLC
# © 2014 WoT.io Inc

http = require 'http'
uuid = require 'uuid'

Http = (Bridge,Url) =>
	self = this

	# http :// wot.io : 80 / wot
	[ proto, host, port, domain ] = Url.match(///([^:]+)://([^:]+):(\d+)/([^\/]*)///)[1...]	

	# HTTP server interface
	self.server = http.createServer (req,res) ->
		Bridge.connect domain, () ->
			try
				# dynamically dispatch to the correct REST handler
				self[req.method.toLowerCase()]?.apply(self,[ req,res ])
			catch error
				console.log "[pontifex.http] #{error}"
				
	self.server.listen port

	# POST /exchange/key/queue	- creates a bus address for a source
	self.post = (req,res) ->
		[ exchange, key, queue ] = req.url.replace("%23","#").replace("%2a","*").match(////[^\/]*/([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		console.log [ exchange, key, queue ]
		Bridge.route exchange, key, queue, () ->
			data = JSON.stringify [ "ok", "/#{queue}" ]
			res.writeHead 201, { "Location": "/#{queue}", "Content-Type": "application/json", "Content-Length" : data.length }
			res.end data

	# GET /queue	 - reads a message off of the queue
	self.get = (req,res) ->
		[ queue ] = req.url.match(///[^\/]*/([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			if data
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
				res.end()

	# PUT exchange/key		- write a message to a sink
	self.put = (req,res) ->
		sink = req.url.replace("%23","#").replace("%2a","*")
		[ exchange, key ] = sink.match(////[^\/]*/([^\/]+)/([^\/]+)///)[1...]
		req.on 'data', (data) ->
			if data.toString().replace(/\s/g, '') == '[ping]'
				data = '["pong"]' 
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				Bridge.send exchange, key, data.toString()
				data = JSON.stringify [ "ok", sink ]
				res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
				res.end data

	# DELETE /queue		- removes a queue & binding
	self.delete = (req,res) ->
		[ queue ] = req.url.match(////[^\/]*/([^\/]+)///)[1...]
		Bridge.delete queue
		data = JSON.stringify [ "ok", req.url ]
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data

module.exports = Http
