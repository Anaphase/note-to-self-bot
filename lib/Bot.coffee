q = require 'q'
reddit = require 'rereddit'
RedditStream = require 'reddit-stream'

module.exports =

class Bot extends RedditStream
  
  getPermalink: (comment) ->
    
    deferred = q.defer()
    
    request = reddit.read(comment.data.link_id)
    
    request.end (error, response) ->
      
      deferred.reject error if error?
      
      unless response?.data?.children?
        return deferred.resolve "http://reddit.com/r/#{comment.data.subreddit}/comments/#{comment.data.link_id[3..]}/permalink-fail/#{comment.data.id}/?context=3"
      
      do (comment) ->
        deferred.resolve "http://reddit.com#{response.data.children[0].data.permalink}#{comment.data.id}/?context=3"
    
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
