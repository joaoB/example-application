# required modules
_			  = require "underscore"
async		  = require "async"
http		   = require "http"
express		= require "express"
path		   = require "path"
methodOverride = require "method-override"
bodyParser	 = require "body-parser"
socketio	   = require "socket.io"
errorHandler   = require "error-handler"
net			   = require "net"
log	   = require "./lib/log"
serviceFinder = require "./serviceFinder"

app	   = express()
server	= http.createServer app
io		= socketio.listen server

# collection of client sockets
sockets = []

serviceFinder.ping()

domain = 'localhost'
port = 9001
#are we pinging server for data?	
pinging = false
connection = null	

ping = (socket, delay) ->
	if pinging
		socket.write "Ping"
		nextPing = -> ping(socket, delay)
		setTimeout nextPing, delay

establishConnection = () ->
	connection = net.createConnection port, domain
	bindOnData()
	bindOnConnect()
	bindOnEnd()
	pinging = true
	
bindOnData = () ->
	connection.on 'data', (data) ->
		data = JSON.parse(data)
		data.timestamp = Date.now()
		socket.emit "persons:create", data for socket in sockets
		console.log "Received: #{data}"
	
bindOnConnect = () ->
	connection.on 'connect', () ->
		console.log "Opened connection to #{domain}:#{port}"
	
bindOnEnd = () ->	
	connection.on 'end', (data) ->
		console.log "Connection closed"

closeConnection = () ->
	connection.destroy()
	connection = null

	
# websocket connection logic
io.on "connection", (socket) ->
	# add socket to client sockets
	sockets.push socket
	establishConnection() unless connection
	ping connection, 4000
	log.info "Socket connected, #{sockets.length} client(s) active"

	# disconnect logic
	socket.on "disconnect", ->
		# remove socket from client sockets
		sockets.splice sockets.indexOf(socket), 1
		if sockets.length == 0
			pinging = false
			connection = null 
		log.info "Socket disconnected, #{sockets.length} client(s) active"

# express application middleware
app
	.use bodyParser.urlencoded extended: true
	.use bodyParser.json()
	.use methodOverride()
	.use express.static path.resolve __dirname, "../client"

# express application settings
app
	.set "view engine", "jade"
	.set "views", path.resolve __dirname, "./views"
	.set "trust proxy", true

# express application routess
app
	.get "/", (req, res, next) =>
		res.render "main"
	
		
# start the server
server.listen 3000
log.info "Listening on 3000"
