# use express to serve a REST-ful API for CRUD operations against comments
bodyParser = require 'body-parser'
mongoose = require 'mongoose'
express = require 'express'
app = express()

# use socket.io to send & recieve notifications to web dashboard & bot
server = require('http').Server(app)
io = require('socket.io').listen(server)
server.listen 8080, -> console.log 'API is listening on port 8080'

# use mongoose to interface with MongoDB
db = mongoose.connection
mongoose.connect 'mongodb://localhost/ntsb'
db.on 'error', console.error.bind(console, 'connection error:')

# load mongoose schemas
Comment = require './lib/schemas/Comment'

now = new Date

# braodcast any events recieved from the bot
io.on 'connection', (socket) ->
  socket.on 'removed', (comment) -> io.sockets.emit 'removed', comment
  socket.on 'reminded', (comment) -> io.sockets.emit 'reminded', comment
  socket.on 'new-comment', (comment) -> io.sockets.emit 'new-comment', comment

db.once 'open', ->
  
  app.use bodyParser()
  
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
  
  app.get '/event/:event_name?', (request, response) ->
    
    unless request.params.event_name?
      response.json no
    
    io.sockets.emit request.params.event_name
    
    response.json yes
  
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
        if request.params.id?
          response.json comments[0]
        else
          response.json comments
    
    .post (request, response) ->
      
      return response.json null unless request.params.id?
      
      query = Comment.find()
        .limit 1
        .where 'id'
          .equals request.params.id
      
      query.exec (error, comments) ->
        
        return response.json error if error?
        
        comment = comments[0]
        
        comment.add_message = request.body.add_message
        comment.note_to_self = request.body.note_to_self
        
        comment.save (error) ->
          response.json error if error?
          response.json comment
    
    .delete (request, response) ->
      
      return response.json null unless request.params.id?
      
      query = Comment.find()
        .limit 1
        .where 'id'
          .equals request.params.id
      
      query.exec (error, comments) ->
        
        return response.json error if error?
        
        comment = comments[0]
        
        comment.remove (error) ->
          response.json error if error?
          response.json null
