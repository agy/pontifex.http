# Pontifex.Http.coffee
#
# (c) 2013 Dave Goehrig <dave@dloh.org>
#

http = require 'http'

PontifexHttp = (Bridge,Url) =>
	self = this
	[ proto, host, port ] = Url.match(///([^:]+)://([^:]+):(\d+)///)[1...]	# "http", "dloh.org", "80" 
	self.server = http.createServer (req,res) ->
		self[req.method.toLowerCase()]?.apply(self,[ req,res ])
	self.server.listen port
	self.post = (req,res) ->
		[ exchange, key, queue ] = req.url.replace("%23","#").match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.create exchange, key, queue
		data = JSON.stringify [ "ok", "/#{queue}" ]
		res.writeHead 201, { "Location": "/#{queue}", "Content-Type": "application/json", "Content-Length" : data.length }
		res.end data
	self.get = (req,res) ->
		[ queue ] = req.url.match(////([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			if data
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
				res.end()
	self.put = (req,res) ->
		resource = req.url.replace("%23","#").replace("%2a","*")
		[ exchange, key ] = resource.match(////([^\/]+)/([^\/]+)///)[1...]
		req.on 'data', (data) ->
			Bridge.update exchange, key, data.toString()
			data = JSON.stringify [ "ok", resource ]
			res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
			res.end data
	self.delete = (req,res) ->
		[ queue ] = req.url.match(////([^\/]+)///)[1...]
		Bridge.delete queue
		data = JSON.stringify [ "ok", req.url ]
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self

module.exports = PontifexHttp
