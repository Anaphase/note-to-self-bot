# use express to serve a RESTful API form CRUD operations against comments
bodyParser = require 'body-parser'
mongoose = require 'mongoose'
express = require 'express'
app = express()

# use mongoose to interface with MongoDB
db = mongoose.connection
mongoose.connect 'mongodb://localhost/ntsb'
db.on 'error', console.error.bind(console, 'connection error:')

# load mongoose schemas
Comment = require './lib/schemas/Comment'

now = new Date

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
  
  server = app.listen 8080, -> console.log 'API is listening on port', server.address().port
