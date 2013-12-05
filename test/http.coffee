
should = require 'should'
request = require 'request'

describe 'HTTP REST API', ->

  it 'get a metric', (next) ->
    request.get 'http://localhost:1234/metrics/2.json', (err, res, body) ->
          return next err if err or res.statusCode isnt 200
          res.statusCode.should.eql 200
          metrics = JSON.parse(body).values
          console.log "get result: " + body
          metrics.length.should.equal 0
          next()

  it 'post and add a metric', (next) ->
    request.post 'http://localhost:1234/metrics/2.json', 
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      metrics:[
        { timestamp:(new Date '2013-11-04 14:00 UTC').getTime(), value:3 }, 
        { timestamp:(new Date '2013-11-04 14:10 UTC').getTime() , value:4 }
      ]
    }), (err, res, body) ->
        return next err if err
        return new Error "Invalid response code: #{res.statusCode}" unless res.statusCode is 200
        request.get 'http://localhost:1234/metrics/2.json', (err, res, body) ->
          return next err if err or res.statusCode isnt 200
          #console.log body
          res.statusCode.should.eql 200
          metrics = JSON.parse(body).values
          #metrics = JSON.parse(body)
          console.log "result: " + body
          metrics.length.should.equal 2
          next()

  it 'post and add a metric again', (next) ->
    request.post 'http://localhost:1234/metrics/2.json', 
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      metrics:[
        { timestamp:(new Date '2013-11-04 15:00 UTC').getTime(), value:6 }, 
        { timestamp:(new Date '2013-11-04 15:10 UTC').getTime() , value:7 }
      ]
    }), (err, res, body) ->
        return next err if err
        return new Error "Invalid response code: #{res.statusCode}" unless res.statusCode is 200
        request.get 'http://localhost:1234/metrics/2.json', (err, res, body) ->
          return next err if err or res.statusCode isnt 200
          #console.log body
          res.statusCode.should.eql 200
          metrics = JSON.parse(body).values
          #metrics = JSON.parse(body)
          console.log "result2: " + body
          metrics.length.should.equal 4
          next()


