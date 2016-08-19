# required modules
_              = require "underscore"
async          = require "async"
http           = require "http"
express        = require "express"
path           = require "path"
methodOverride = require "method-override"
bodyParser     = require "body-parser"
socketio       = require "socket.io"
errorHandler   = require "error-handler"
net			   = require "net"
log       = require "./lib/log"

app       = express()
server    = http.createServer app
io        = socketio.listen server

# collection of client sockets
sockets = []

domain = 'localhost'
port = 9001

ping = (socket, delay) ->
    console.log "Pinging server"
    socket.write "Ping"
    nextPing = -> ping(socket, delay)
    setTimeout nextPing, delay

connection = net.createConnection port, domain

connection.on 'connect', () ->
    console.log "Opened connection to #{domain}:#{port}"
    ping connection, 2000

connection.on 'data', (data) ->
    console.log "Received: #{data}"

connection.on 'end', (data) ->
    console.log "Connection closed"
    process.exit()



# websocket connection logic
io.on "connection", (socket) ->
	# add socket to client sockets
	sockets.push socket
	log.info "Socket connected, #{sockets.length} client(s) active"

	# disconnect logic
	socket.on "disconnect", ->
		# remove socket from client sockets
		sockets.splice sockets.indexOf(socket), 1
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
