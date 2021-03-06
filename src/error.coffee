Response = require './response'


class RequestError extends Error
  name: 'RequestError'
  constructor: (@message) ->

  @create = (message, req) ->
    err = new RequestError message
    Response.call err, req # Make the error look like a response
    err


module.exports = RequestError
