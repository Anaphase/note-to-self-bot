q = require 'q'
reddit = require 'rereddit'
RedditStream = require 'reddit-stream'

module.exports =

class Bot extends RedditStream
  
  getLink: (link_id) ->
    
    deferred = q.defer()
    
    request = reddit.read(comment.data.link_id)
    
    request.end (error, response) ->
      deferred.reject error if error?
      deferred.resolve response.data.children[0]
    
    deferred.promise
  
  reply: -> @comment.apply @, arguments
  comment: (parent, text) ->
    
    deferred = q.defer()
    
    unless @user?
      deferred.reject 'You must be logged in to comment!'
    else
      request = reddit.comment parent, text
      request.as @user
      
      request.end (error, response) ->
        if error?
          deferred.reject error
        else
          deferred.resolve response
    
    deferred.promise
