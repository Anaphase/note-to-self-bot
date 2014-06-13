# keep your authentication variables here
auth = require './lib/auth'

# use pushover to send notifications to phones
Pushover = require 'pushover-notifications'
push = new Pushover user: auth.pushover.user, token: auth.pushover.token

# use socket.io to send notifications to web front-end
io = require('socket.io').listen(7070, 'log level': 1)
io.enable 'browser client minification'
io.enable 'browser client gzip'

# use mongoose to interface with MongoDB
mongoose = require 'mongoose'
db = mongoose.connection
mongoose.connect 'mongodb://localhost/ntsb'
db.on 'error', console.error.bind(console, 'connection error:')

# load mongoose schemas
Comment = require './lib/schemas/Comment'

Bot = require './lib/Bot'
bot = new Bot 'comments', 'all', 'note-to-self-bot by /u/Anaphase'

user_blacklist = ['note-to-self-bot', 'bagelhunt']
subreddit_blacklist = ['fatpeoplehate', 'askwomen', 'askreddit', 'percyjacksonrp', 'actuallesbians']

db.once 'open', ->
  
  remind = ->
    past = (Date.now()/1000) - (60*60*24)
    Comment
      .where 'created_utc'
        .lte past
      .where 'reminded'
        .equals no
      .sort 'created_utc'
      .exec (error, comments) ->
        
        return console.error 'could not read comments from database:', error if error?
        
        return if comments.length is 0
        
        for comment in comments
          do (comment) ->
            
            if comment.add_message
              message = switch Math.floor(Math.random() * 5) + 1
                when 1 then 'Hey friend! I thought I\'d remind you:'
                when 2 then 'You should always rememeber:'
                when 3 then 'Just in case you forgot:'
                when 4 then 'A friendly reminder:'
                when 5 then 'Don\'t forget:'
              
              message += '\n\n' + comment.note_to_self
            else
              message = comment.note_to_self
            
            bot.reply comment.name, message
              .then(
                  ->
                    console.log 'commented on', (new Date())
                    console.log comment.permalink
                    console.log message
                    console.log ''
                    
                    comment.reminded = yes
                    comment.save (error) ->
                      console.error 'could not update comment:', error if error?
                      io.sockets.emit 'reminded', comment
                      # push.send
                      #   timestamp: Math.round((new Date()).getTime()/1000)
                      #   title: 'NTSB Replied'
                      #   url_title: 'view on reddit'
                      #   message: "#{message}\n\nhttp://ps.tl/ntsb/"
                      #   url: comment.permalink
                ,
                  (error) ->
                    console.error 'could not reply to comment:', error
              )
  
  bot.login(auth.reddit.username, auth.reddit.password).then(
    ->
      remind()
      bot.start()
      setInterval remind, 60 * 1000
  ,
    (error) ->
      console.error 'could not log in:', error
  )
  
  bot.on 'new', (comments) ->
    
    for comment in comments
      
      continue if comment.data.author.toLowerCase() in user_blacklist
      continue if comment.data.subreddit.toLowerCase() in subreddit_blacklist
      
      if (/note to self/gi).test comment.data.body
        do (comment) ->
          bot.getPermalink(comment).then (permalink) ->
            
            matches = comment.data.body.trim().match(/note to self\s*[:|\-|,|;\.]*\s*([^.!?\n]+[.!?]*)/i)
            
            if matches?
              paren_stack = []
              match = matches[1]
              
              for character in match
                if character is '('
                  paren_stack.push character
                else if character is ')'
                  if paren_stack.length > 0
                    paren_stack.pop()
                  else
                    match = match.substr(0, match.indexOf(character))
                    break
              
              note_to_self = match.replace(/\*|\~/g, '').trim()
              
              comment = new Comment
                id: comment.data.id
                permalink: permalink
                name: comment.data.name
                body: comment.data.body
                note_to_self: note_to_self
                author: comment.data.author
                link_url: comment.data.link_url
                subreddit: comment.data.subreddit
                link_title: comment.data.link_title
                link_author: comment.data.link_author
                created_utc: comment.data.created_utc
              
              comment.save (error, comment) ->
                return console.error 'could not save comment:', error if error?
                
                console.log 'found on', (new Date())
                console.log comment.permalink
                console.log comment.note_to_self
                console.log ''
                
                io.sockets.emit 'new-comment', comment
                push.send
                  message: "#{comment.note_to_self}\n\nhttp://ps.tl/ntsb/"
                  timestamp: Math.round((new Date()).getTime()/1000)
                  url_title: 'view on reddit'
                  title: 'NTSB'
                  url: comment.permalink
