# use express to serve a REST-ful API for CRUD operations against comments
bodyParser = require 'body-parser'
express = require 'express'
app = express()

# use socket.io to send & recieve notifications to web dashboard & bot
port = process.env.PORT or 8080
server = require('http').Server(app)
io = require('socket.io').listen(server)
server.listen port, -> console.log "API is listening on port #{port}"

# use mongoose to interface with MongoDB
mongoose = require 'mongoose'
mongodbUri = require 'mongodb-uri'

db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
mongoose.connect mongodbUri.formatMongoose(process.env.MONGOLAB_URI)

# load mongoose schemas
Comment = require './lib/models/Comment'
Setting = require './lib/models/Setting'

now = new Date

# braodcast any events recieved from the bot
io.on 'connection', (socket) ->
  socket.on 'removed', (comment) -> io.sockets.emit 'removed', comment
  socket.on 'reminded', (comment) -> io.sockets.emit 'reminded', comment
  socket.on 'new-comment', (comment) -> io.sockets.emit 'new-comment', comment

db.once 'open', ->

  # make sure settings exist, if not create them
  (new Setting()).checkSettings()

  # accept JSON and traditional URL-encoded POST bodies
  app.use bodyParser.json()
  app.use bodyParser.urlencoded extended: true

  # server dashboard through express
  app.use express.static 'dashboard/public'

  app.all '*', (request, response, next) ->
    response.header 'Access-Control-Allow-Origin', request.headers.origin
    response.header 'Access-Control-Allow-Methods', 'POST, GET, PUT, DELETE, OPTIONS'
    response.header 'Access-Control-Allow-Headers', 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Accept'
    next()

  app.options '*', (request, response) ->
    response.send 200

  app.get '/', (request, response) ->
    response.json
      name: 'note-to-self-bot api'
      started: now

  app.route '/settings/:name?'

    .get (request, response) ->

      query = Setting.find().select('-_id -__v')

      if request.params.name?
        query
          .limit 1
          .where 'name'
            .equals request.params.name

      query.exec (error, settings) ->
        return response.json error if error?
        return response.json undefined unless settings?
        if request.params.name?
          response.json settings[0]
        else
          response.json settings

    .post (request, response) ->

      return response.json null unless request.params.name?

      query = Setting.findOne(name: request.params.name)

      query.exec (error, setting) ->

        return response.json error if error?
        return response.json undefined unless setting?

        old_value = setting.value
        new_value = request.body.value

        unless new_value? and old_value isnt new_value
          return response.json setting

        setting.value = new_value

        setting.save (error) ->
          response.json error if error?
          io.sockets.emit 'setting-changed', request.params.name, new_value, old_value
          response.json setting

  app.route '/comments/:id?'

    .get (request, response) ->

      query = Comment.find().select('-_id -__v')

      if request.params.id?
        query
          .limit 1
          .where 'id'
            .equals request.params.id
      else
        query
          .sort 'created_utc'
          .where 'reminded'
            .equals no

      query.exec (error, comments) ->

        return response.json error if error?
        return response.json undefined unless comments?

        if request.params.id?
          response.json comments[0]
        else
          response.json comments

    .post (request, response) ->

      return response.json null unless request.params.id?

      query = Comment.findOne(id: request.params.id)

      query.exec (error, comment) ->

        return response.json error if error?
        return response.json undefined unless comment?

        comment.add_message = request.body.add_message if request.body.add_message?
        comment.note_to_self = request.body.note_to_self if request.body.add_message?

        comment.save (error) ->
          response.json error if error?
          response.json comment

    .delete (request, response) ->

      return response.json null unless request.params.id?

      query = Comment.findOne(id: request.params.id)

      query.exec (error, comment) ->

        return response.json error if error?
        return response.json undefined unless comment?

        comment.remove (error) ->
          response.json error if error?
          response.json null
