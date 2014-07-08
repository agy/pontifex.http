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
	monitoringExchange='monitoring-in'
	monitoringHashKey='#'
	peer=host
	oldRead = 0 
	oldWritten = 0 
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
		connection = req.connection
		data = JSON.stringify [ "ok", "/#{queue}" ]
		self.createConnection(monitoringExchange, req.url , key)
	
		self.readConnection(monitoringExchange,req.url , key , req.socket.bytesRead - oldRead)
		self.wroteConnection(monitoringExchange,req.url , key , req.socket.bytesWritten - oldWritten)
		self.closeConnection(monitoringExchange, req.url, key)
		oldRead = req.socket.bytesRead
		oldWritten = req.socket.bytesWritten
		res.writeHead 201, { "Location": "/#{queue}", "Content-Type": "application/json", "Content-Length" : data.length }
		res.end data
	self.get = (req,res) ->
		[ queue ] = req.url.match(///[^\/]*/([^\/]+)///)[1...]
		Bridge.read queue, (data) ->
			self.createConnection(monitoringExchange, req.url , key)
			self.readConnection(monitoringExchange,req.url , key , req.socket.bytesRead - oldRead)
			self.wroteConnection(monitoringExchange,req.url , key , req.socket.bytesWritten - oldWritten)
			self.closeConnection(monitoringExchange, req.url, key)
			oldRead = req.socket.bytesRead
			oldWritten = req.socket.bytesWritten
			if data
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				res.writeHead 404, { "Content-Type": "application/json", "Content-Length": 0 }
				res.end()
	self.put = (req,res) ->
		resource = req.url.replace("%23","#").replace("%2a","*")
		[ exchange, key ] = resource.match(////[^\/]*/([^\/]+)/([^\/]+)///)[1...]
		req.on 'data', (data) ->
			if data.toString().replace(/\s/g, '') == '[ping]'
				data = '["pong"]' 
				res.writeHead 200, { "Content-Type": "application/json", "Content-Length": data.length }
				res.end data
			else
				console.log(req.socket.bytesRead)
				Bridge.send exchange, key, data.toString()
				readSize = req.socket.bytesRead
				writtenSize = req.socket.bytesWritten
				self.createConnection(monitoringExchange, req.url , key)
				self.readConnection(monitoringExchange,req.url , key ,req.socket.bytesRead - oldRead)
				self.wroteConnection(monitoringExchange,req.url , key , req.socket.bytesWritten - oldWritten)
				self.closeConnection(monitoringExchange, req.url, key)
				oldRead = req.socket.bytesRead
				oldWritten = req.socket.bytesWritten
				data = JSON.stringify [ "ok", resource ]
				res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
				res.end data
	self.delete = (req,res) ->
		[ queue ] = req.url.match(////[^\/]*/([^\/]+)///)[1...]
		Bridge.delete queue
		data = JSON.stringify [ "ok", req.url ]
		readSize = req.socket.bytesRead
		writtenSize = req.socket.bytesWritten
		self.createConnection(monitoringExchange, req.url , key)
		self.readConnection(monitoringExchange,req.url , key , req.socket.bytesRead - oldRead)
		self.wroteConnection(monitoringExchange,req.url , key , req.socket.bytesWritten - oldWritten)
		self.closeConnection(monitoringExchange, req.url, key)
		oldRead = req.socket.bytesRead
		oldWritten = req.socket.bytesWritten
		res.writeHead 200, { "Content-Type" : "application/json", "Content-Length" :  data.length }
		res.end data
	self.createConnection = (_exchange , _url , _key) ->
	    data = '["created_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+peer+'" ,"'+self.getDate()+'"]'
	    Bridge.send _exchange, monitoringHashKey, data
	self.readConnection = (_exchange, _url , _key , _messageLength)->
	   data = '["read_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+_messageLength+'" ,"'+self.getDate()+'"]'
	   Bridge.send _exchange, monitoringHashKey, data
	self.wroteConnection = (_exchange, _url , _key , _messageLength)->
	   data = '["wrote_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+_messageLength+'" ,"'+self.getDate()+'"]'
	   Bridge.send _exchange, monitoringHashKey, data
	self.closeConnection = (_exchange , _url , _key )->
	    data = '["closed_connection" , "'+_url+'" , "'+sessionUUID+'" , "' + accountName + '", "'+self.getDate()+'" ,"'+false+'"]'
	    Bridge.send _exchange, monitoringHashKey, data
	self.getDate = () ->
        date = new Date()
        year = date.getFullYear()
        month = ("0" + (date.getMonth() + 1).toString()).substr(-2)
        day = ("0" + date.getDate().toString()).substr(-2)
        hour = ("0" + date.getHours().toString()).substr(-2)
        minute = ("0" + date.getMinutes().toString()).substr(-2)
        second = ("0" + date.getSeconds().toString()).substr(-2)
        formatedDate = "#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}"
        return formatedDate
	self

module.exports = Http
