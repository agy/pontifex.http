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
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.create exchange, key, queue
		res.writeHead 201, { "Location": "#{req.url}" }
		res.end()
	self.get = (req,res) ->
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			if data
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
				res.end()
	self.put = (req,res) ->
		[ exchange, key ] = req.url.match(////([^\/]+)/([^\/]+)///)[1...]
		Bridge.update exchange, key, req.body
		data = '[ "ok" ]'
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self.delete = (req,res) ->
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.delete queue
		data = '[ "ok" ]'
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self

module.exports = PontifexHttp
