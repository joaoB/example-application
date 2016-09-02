consul = require('consul')();

# should be known and constant
serviceName = 'personGenerator'

getService = (cb) ->
	consul.catalog.service.nodes serviceName, (err, result) ->
		if err
			throw err;
		url = result[0].ServiceAddress + ":" + result[0].ServicePort
		cb({domain : result[0].ServiceAddress, port : result[0].ServicePort})

service = {
	getService       : getService
}

		
module.exports = service