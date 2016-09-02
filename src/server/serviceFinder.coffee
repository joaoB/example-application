consul = require('consul')();

# should be known and constant
serviceName = 'personGenerator'

getService = (cb) ->
	consul.catalog.service.nodes serviceName, (err, result) ->
		if err
			throw err;
		url = result[0].ServiceAddress + ":" + result[0].ServicePort
		cb(url)

ping = () ->
	getService (url) ->
		console.log "will ping " + url
	
	
service = {
	ping       : ping
}

		
module.exports = service