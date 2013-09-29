# Pontifex.Http.coffee
#
# (c) 2013 Dave Goehrig <dave@dloh.org>
#

http = require 'http'

PontifexHttp = (Bridge,Url) ->
	console.log("connecting to #{Url}")
	[ proto, host, port ] = Url.match(///([^:]+)://([^:]+):(\d+)///)[1...]	# "http", "dloh.org", "80" 
	self = () ->
		self.server = http.createServer (req,res) ->
			self[req.method.toLowerCase()]?.apply(self,req,res)
		self.server.listen port, host
	self.post = (req,res) ->
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.create exchange, key, queue
		res.writeHead 201, { "Location": "#{req.url}" }
		res.end()
	self.get = (req,res) ->
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
			res.end data
	self.put = (req,res) ->
		[ exchange, key ] = req.url.match(////([^\/]+)/([^\/]+)///)[1...]
		Pons.update exchange, key, req.body
		data = '[ "ok" ]'
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self.delete = (req,res) ->
		[ exchange, key, queue ] = req.url.match(////([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Pons.delete queue
		data = '[ "ok" ]'
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data

module.exports = PontifexHttp
