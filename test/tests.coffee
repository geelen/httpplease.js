assert = chai.assert
request = httprequest

testServerUrl = 'http://localhost:4001'

describe 'httprequest', ->
  it 'performs a get request', (done) ->
    request.get "#{ testServerUrl }/getjson", (err, res) ->
      assert.equal res.text, JSON.stringify(hello: 'world')
      done()

  it 'sends headers', (done) ->
    req =
      url: "#{ testServerUrl }/headers"
      headers:
        hello: 'world'
    request.get req, (err, res) ->
      json = JSON.parse res.text
      assert.equal json.hello, 'world'
      done()

  describe 'use', ->
    it 'adds a plugin', ->
      assert.equal request.use({}).plugins.length, 1

    it "doesn't mutate the request function", ->
      request.use {}
      assert.equal request.plugins.length, 0