# Pontifex.Http.coffee
#
# (c) 2013 Dave Goehrig <dave@dloh.org>
# (c) 2014 wot.io LLC
#
http = require 'http'
uuid = require 'uuid'
Http = (Bridge,Url) =>
	self = this
	[ proto, host, port, domain ] = Url.match(///([^:]+)://([^:]+):(\d+)/([^\/]*)///)[1...]	# "http", "dloh.org", "80", //
	sessionUUID = uuid.v4()
	accountName= domain
	monitoringExchange='monitoring'
	peer=host
	self.server = http.createServer (req,res) ->
		Bridge.connect domain, () ->
			try
				self[req.method.toLowerCase()]?.apply(self,[ req,res ])
			catch error
				console.log "Error #{error}"
				
	self.server.listen port
	self.post = (req,res) ->
		[ exchange, key, queue ] = req.url.replace("%23","#").replace("%2a","*").match(////[^\/]*/([^\/]+)/([^\/]+)/([^\/]+)///)[1...]
		Bridge.route exchange, key, queue
		data = JSON.stringify [ "ok", "/#{queue}" ]
		
		self.createConnection(exchange, req.url , key)
		self.readConnection(exchange,req.url , key , data.length)
		self.wroteConnection(exchange,req.url , key , data.length)
		self.closeConnection(exchange, req.url, key)
		
		res.writeHead 201, { "Location": "/#{queue}", "Content-Type": "application/json", "Content-Length" : data.length }
		res.end data
	self.get = (req,res) ->
		[ queue ] = req.url.match(///[^\/]*/([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			if data
				self.createConnection(exchange, req.url , key)
				self.readConnection(exchange,req.url , key , data.length)
				self.wroteConnection(exchange,req.url , key , data.length)
				self.closeConnection(exchange, req.url, key)
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
				res.end()
	self.put = (req,res) ->
		resource = req.url.replace("%23","#").replace("%2a","*")
		[ exchange, key ] = resource.match(////[^\/]*/([^\/]+)/([^\/]+)///)[1...]
		req.on 'data', (data) ->
			Bridge.send exchange, key, data.toString()
			self.createConnection(exchange, req.url , key)
			self.readConnection(exchange,req.url , key , data.toString())
			self.wroteConnection(exchange,req.url , key , data.toString())
			self.closeConnection(exchange, req.url, key)
			
			data = JSON.stringify [ "ok", resource ]
			res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
			res.end data
	self.delete = (req,res) ->
		[ queue ] = req.url.match(////[^\/]*/([^\/]+)///)[1...]
		Bridge.delete queue
		data = JSON.stringify [ "ok", req.url ]
		self.createConnection(exchange, req.url , key)
		self.readConnection(exchange,req.url , key , data.toString())
		self.wroteConnection(exchange,req.url , key , data.toString())
		self.closeConnection(exchange, req.url, key)
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self.createConnection = (exchange ,  _url , _key) ->
	    data = '["created_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+peer+'" ,"'+new Date().getTime()+'"]'
	    Bridge.send exchange, _key, data
	self.readConnection = (exchange, _url , _key , messageLength)->
	   data = '["read_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+messageLength+'" ,"'+new Date().getTime()+'"]'
	   Bridge.send exchange, _key, data
	self.wroteConnection = (exchange, _url , _key , messageLength)->
	   data = '["wrote_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+messageLength+'" ,"'+new Date().getTime()+'"]'
	   Bridge.send exchange, _key, data
	self.closeConnection = (exchange , _url , _key )->
	    data = '["closed_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+new Date().getTime()+'" ,"'+false+'"]'
	    Bridge.send exchange, _key, data
	self

module.exports = Http
