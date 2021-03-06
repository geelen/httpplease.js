cleanURL = require './plugins/cleanurl'
XHR = require './xhr'
delay = require './delay'
{create: createError} = require './error'
Response = require './response'
Request = require './request'
extend = require 'xtend'
once = require 'once'


factory = (defaults = {}, plugins = []) ->
  http = (req, cb) ->
    req = new Request extend defaults, req

    # Give the plugins a chance to create the XHR object
    for plugin in plugins
      if xhr = plugin?.createXHR? req then break # First come, first serve
    xhr ?= new XHR

    # Because XHR can be an XMLHttpRequest or an XDomainRequest, we add
    # `onreadystatechange`, `onload`, and `onerror` callbacks. We use the
    # `once` util to make sure that only one is called (and it's only called
    # one time).
    done = once delay (err) ->
      xhr.onload = xhr.onerror = xhr.onreadystatechange = xhr.ontimeout = xhr.onprogress = null
      res = if err?.isHttpError then err else new Response req
      for plugin in plugins
        plugin.processResponse? res
      cb err, res

    # When the request completes, continue.
    xhr.onreadystatechange = ->
      if xhr.readyState is 4
        switch Math.floor xhr.status / 100
          when 2 then done()
          when 4
            if xhr.status is 404 and not req.errorOn404 then done()
            else done createError 'Client Error', req
          when 5 then done createError 'Server Error', req
          else done createError 'HTTP Error', req

    # `onload` is only called on success and, in IE, will be called without
    # `xhr.status` having been set, so we don't check it.
    xhr.onload = -> done()
    xhr.onerror = -> done createError 'Internal XHR Error', req

    # IE sometimes fails if you don't specify every handler.
    # See http://social.msdn.microsoft.com/Forums/ie/en-US/30ef3add-767c-4436-b8a9-f1ca19b4812e/ie9-rtm-xdomainrequest-issued-requests-may-abort-if-all-event-handlers-not-specified?forum=iewebdevelopment
    xhr.ontimeout = ->
    xhr.onprogress = ->

    req.xhr = xhr

    for plugin in plugins
      plugin.processRequest? req

    xhr.open req.method, req.url

    for own k, v of req.headers
      xhr.setRequestHeader k, v

    xhr.send req.body

    req

  for method in ['get', 'post', 'put', 'head', 'patch', 'delete']
    do (http, method) ->
      http[method] = (req, cb) ->
        req = new Request req
        req.method = method
        http req, cb

  http.plugins = -> plugins

  http.defaults = (newValues) ->
    if newValues then factory extend(defaults, newValues), plugins
    else defaults

  http.use = (newPlugins...) -> factory defaults, plugins.concat newPlugins

  http.bare = -> factory()

  http

module.exports = factory {}, [cleanURL]
