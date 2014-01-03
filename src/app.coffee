http = require 'http'
stylus = require 'stylus'
express = require 'express'
metrics = require './metrics'
request = require 'request'
userdb = require('./db') "#{__dirname}/../db/userdb"


app = express()

app.set 'views', __dirname + '/../views'
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser '1234567890QWERTY'
#app.use express.session()
#app.use express.cookieSession()
app.use express.cookieSession(
  cookie:
    maxAge: 30 * 60 * 1000
)
app.use app.router
app.use stylus.middleware "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"
app.use express.errorHandler
  showStack: true
  dumpExceptions: true

app.use (req, res, next) ->
  if req.is("text/*")
    req.text = ""
    req.setEncoding "utf8"
    req.on "data", (chunk) ->
      req.text += chunk
    req.on "end", next
  else
    next()


app.get '/', (req, res) ->
  console.log "app.get /"
  if req.session.id? and req.session.id isnt "undefined"
    username = req.session.id
    console.log "if session yes " + req.session.id
    userdb.get username, (err, data) ->
      return next err if err
      if username? and username  isnt "undefined"
        metrics.get username, (err, values) ->
          return next err if err
          console.log values
          res.render 'user', title: 'Your metrics, ' + username, metrics: values
  else
    console.log "else session no " + req.session.id
    res.render 'login', title: 'login'

app.get '/login', (req, res) ->
  if req.session.id? and req.session.id isnt "undefined"
    console.log 'login:' + req.session.id
    metrics.get req.session['id'], (err, values) ->
        return next err if err
        res.render 'user', title: 'Your metrics, ' + req.session['id'], metrics: values
  else
    res.render 'login', title: 'Identification'

app.get '/quit', (req, res) ->
  if req.session.id? and req.session.id isnt "undefined"
    req.session = null
    res.render 'login', title: 'Identification'

app.get '/signup', (req, res) ->
  res.render 'signup', title: 'Create a new account'

app.post '/signup', (req, res) ->
  username = req.body.username
  password = req.body.password
  if username? and password?
    userdb.get username, (err, data) ->
      if data?
        res.render 'signup', title: 'The account already exists'
      else
        userdb.put username, password
        res.render 'login', title: 'Identification'
  else
    res.render 'signup', title: 'Create a new account'

app.post '/addmetric', (req, res) ->
  if req.session.id? and req.session.id isnt "undefined"
    value_str = req.body.value
    console.log "session: "+req.session.id 
    console.log "post value: "+value_str

    arr = [ { timestamp: (new Date()).getTime(), value: value_str  } ]
    metrics.save req.session['id'], arr, (err) ->
      return next err if err
      metrics.get req.session['id'], (err, values) ->
        return next err if err
        res.render 'user', title: 'Your metrics, ' + req.session['id'], metrics: values
  else
    res.render 'login', title: 'Does not connect or expired'



app.get '/deletemetric/timestamp=:tt', (req,res) ->
  if req.session.id? and req.session.id isnt "undefined"
    timestamp = req.params.tt
    metrics.removeone req.session['id'],timestamp, (err) ->
      return next err if err
    metrics.get req.session['id'], (err, values) ->
        return next err if err
        res.render 'user', title: 'Your metrics, ' + req.session['id'], metrics: values
  else
    res.render 'login', title: 'Does not connect or expired'

app.post '/login', (req, res, next) ->
  console.log "POST Login"

  # metrics_arr = [
  #       { timestamp:(new Date '2013-12-04 14:00 UTC').getTime(), value:3333 }, 
  #       { timestamp:(new Date '2013-12-04 14:10 UTC').getTime() , value:4444 }
  #     ]

  username = req.body.username
  password = req.body.password

  userdb.get username, (err, data) ->
    if data == password
      # remove 
      # metrics.remove username, (err) ->
      #  return next err if err
      req.session['id'] = username
      if username? and username  isnt "undefined"
        #save
        # metrics.save username, metrics_arr, (err) ->
        #   return next err if err
        #get
        metrics.get username, (err, values) ->
          return next err if err
          console.log values
          res.render 'user', title: 'Your metrics, '+ username, metrics: values
      else
        res.render 'login', title: 'Please login at first'
    else
      res.render 'login', title: 'Identification :  wrong password or no user' 

metric_get = (req, res, next) ->
  metrics.get req.params.id, (err, values) ->
    return next err if err
    res.json
      id: req.params.id
      values: values
app.get '/metrics/:id.json', metric_get
app.get '/metrics?metric=:id', metric_get

app.post '/metrics/:id.json', (req, res, next) ->
    console.log 'robin !!!'
    console.log 'id: '+ req.params.id
    console.log req.body.metrics
    console.log 'robin finish!!!'
    values = req.body.metrics
    if typeof values isnt "undefined"
      metrics.save req.params.id, values, (err) ->
        return next err if err
        res.json status: 'OK'
    else
      res.json status: 'OK'

app.del '/metrics/:id.json', (req, res, next) ->
  console.log "remove id : " + req.params.id
  metrics.remove req.params.id, (err) ->
    return next err if err
    res.json status: 'OK'

http.createServer(app).listen 1234, ->
  console.log 'http://localhost:1234'
