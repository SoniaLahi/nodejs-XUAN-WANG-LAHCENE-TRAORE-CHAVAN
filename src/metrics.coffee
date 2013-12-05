
db = require('./db') "#{__dirname}/../db/metricsdb"

module.exports =
  ###
  `get(id, [options], callback)`
  ----------------------------
  Return an array of metrics.

  Parameters
  `id`        Metric id as integer
  `callback`  Contains an err as first argument 
              if any

  Options
  `start`     Timestamp
  `end`       Timestamp
  `timestamp` Step between each metrics 
              in milliseconds
  ###
  get: (id, options, callback) ->
    console.log "GET Function" 
    callback = options if arguments.length is 2
    metrics = []
    rs = db.createReadStream
      start: "metrics~" + id + "~"
      end: "metrics~" + id + "~~"
    rs.on 'data', (data) ->
      [_, id, timestamp] = data.key.split '~'
      metrics.push id: id, timestamp: parseInt(timestamp, 10), value: data.value
    rs.on 'error', callback
    rs.on 'close', ->
      callback null, metrics
  ###
  `save(id, metrics, callback)`
  ----------------------------

  Parameters
  `id`       Metric id as integer
  `metrics`  Array with timestamp as keys 
             and integer as values
  `callback` Contains an err as first argument 
             if any
  ###
  save: (id, metrics, callback) ->
    ws = db.createWriteStream()
    ws.on 'error', callback
    ws.on 'close', callback
    for metric in metrics
      {timestamp, value} = metric
      keystr = "metrics~" + id + "~" + timestamp
      console.log keystr
      ws.write key: keystr, value: value
    ws.end()

 # Parameters
#`id`       Metric id as integer
#`callback` Contains an err as first argument 
#           if any
# ###
  remove: (id, callback) ->
    rs = db.createReadStream
      start: "metrics~#{id}~"
      end: "metrics~#{id}~~"
    rs.on 'data', (data) -> 
      db.del data.key, 
    rs.on 'error', callback 
    rs.on 'close', ->
      callback()

  removeone: (id, timestamp) ->
    db.del "metrics~#{id}~#{timestamp}"














