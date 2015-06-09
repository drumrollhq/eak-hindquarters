require! {
  'fs'
  'bluebird': Promise
  'path'
}

setup-service = (service, name, args) ->
  if service.setup
    Promise.resolve service.setup args
  else
    Promise.reject "Service #name has no setup function"

services = exports

export setup = ({config, store, models, log}, base-path) ->
  names = fs.readdir-sync base-path
    .filter ( .0 isnt '.' )
    .map ( .replace /\.[a-z]+$/, '' )

  Promise
    .map names, (name) ->
      service-log = log.create "service:#name"
      service-path = path.join base-path, name
      service = require service-path
      console.log name, service
      setup-service service, name, {config, store, models, services, log: service-log}
        .then ->
          services[name] = service
          service-log.debug 'Registered service'

    .then -> services

