# reddit API wrapper
rawjs = require 'raw.js'
reddit = new rawjs('note-to-self-bot by /u/Anaphase')

# comment streamer
RedditStream = require 'reddit-stream'
stream = new RedditStream('comments', 'all', 'note-to-self-bot by /u/Anaphase')

# these hold the interval time and setInterval ID for the remind loop
remind_interval_id = null
remind_interval = 60 * 1000

# keep your authentication variables here
if process.env.NODE_ENV isnt 'heroku'
  auth = require './lib/auth'
else
  auth =
    reddit:
      username: process.env.REDDIT_USERNAME
      password: process.env.REDDIT_PASSWORD
      app:
        id: process.env.REDDIT_APP_ID
        secret: process.env.REDDIT_APP_SECRET
    pushover:
      user: process.env.PUSHOVER_USER
      token: process.env.PUSHOVER_TOKEN

# use pushover to send notifications to phones
Pushover = require 'pushover-notifications'
push = new Pushover(user: auth.pushover.user, token: auth.pushover.token)

# use socket.io to send & recieve notifications to & from dashboard (via the API)
port = process.env.PORT or 8080
socket_uri = process.env.SOCKET_IO_URI or 'http://localhost'
socket = require('socket.io-client')("#{socket_uri}:#{port}")

# use mongoose to interface with MongoDB
mongoose = require 'mongoose'
mongodbUri = require 'mongodb-uri'

db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')
mongoose.connect mongodbUri.formatMongoose(process.env.MONGOLAB_URI)

# load mongoose schemas
Comment = require './lib/models/Comment'
Setting = require './lib/models/Setting'

# load users and subreddits to skip
blacklist = require './lib/blacklist'

# initialized with DB settings below
should_scan = no
should_remind = no
should_pushover = no

db.once 'open', ->

  # make sure settings exist, if not create them
  # also, start the bot once we know the settings
  (new Setting()).checkSettings().then (required_settings) ->

    should_scan = (setting.value for setting in required_settings when setting.name is 'scan')[0]
    should_remind = (setting.value for setting in required_settings when setting.name is 'remind')[0]
    should_pushover = (setting.value for setting in required_settings when setting.name is 'should_pushover')[0]

    reddit.setupOAuth2 auth.reddit.app.id, auth.reddit.app.secret
    reddit.auth { username: auth.reddit.username, password: auth.reddit.password }, (error, response) ->
      if error?
        console.error 'error on', (new Date())
        console.error 'could not log in (bot):', error
        console.error ''
      else
        stream.login(auth.reddit).then(
          ->

            console.log 'logged in!'

            if should_scan is on
              console.log 'scanning...'
              stream.start()

            if should_remind is on
              console.log 'reminding...'
              remind()
              remind_interval_id = setInterval remind, remind_interval

          (error) ->
            console.error 'error on', (new Date())
            console.error 'could not log in (comment streamer):', error
            console.error ''
        )

  socket.on 'setting-changed', (setting, new_state, old_state) ->

    return if old_state is new_state

    switch setting
      when 'scan'

        if new_state is off
          stream.stop()

        if new_state is on
          stream.start()

      when 'remind'

        if new_state is off
          clearInterval remind_interval

        if new_state is on
          remind()
          clearInterval remind_interval
          remind_interval_id = setInterval remind, remind_interval

      when 'should_pushover'

        should_pushover = new_state

    console.log 'switched', setting, 'setting from', old_state, 'to', new_state, 'on', (new Date())
    console.log ''

  remind = ->

    past = (Date.now() / 1000) - (60 * 60 * 24)

    Comment
      .where 'created_utc'
        .lte past
      .where 'reminded'
        .equals no
      .sort 'created_utc'
      .exec (error, comments) ->

        if error?
          console.error 'error on', (new Date())
          console.error 'could not read comments from database:', error
          console.error ''
          return

        return if comments?.length is 0

        for comment in comments
          do (comment) ->

            if comment.add_message
              message = switch Math.floor(Math.random() * 5) + 1
                when 1 then 'Hey friend! I thought I\'d remind you:'
                when 2 then 'You should always remember:'
                when 3 then 'Just in case you forgot:'
                when 4 then 'A friendly reminder:'
                when 5 then 'Don\'t forget:'

              message += '\n\n' + comment.note_to_self
            else
              message = comment.note_to_self

            reddit.comment comment.name, message, (error) ->
              if error?
                console.error 'error on', (new Date())
                console.error "could not reply to comment #{comment.id}:", error

                if error is '403: Forbidden'
                  console.error 'detected possible newly blacklisted subreddit:', comment.subreddit
                  if should_pushover
                    push.send
                      timestamp: Math.round((new Date()).getTime() / 1000)
                      message: "detected possible newly blacklisted subreddit: #{comment.subreddit}\n\nhttp://ps.tl/ntsb/"
                      url_title: 'view on reddit'
                      url: comment.permalink
                      title: 'NTSB Alert'
                else if typeof error is 'object'
                  switch error[0]
                    when 'DELETED_COMMENT'
                      console.error "detected deleted comment #{comment.id}:", comment.permalink
                      if should_pushover
                        push.send
                          timestamp: Math.round((new Date()).getTime() / 1000)
                          message: "detected deleted comment #{comment.id}: #{comment.note_to_self}\n\nhttp://ps.tl/ntsb/"
                          url_title: 'view on reddit'
                          url: comment.permalink
                          title: 'NTSB Alert'
                else
                  return

                console.error ''

                console.log 'removed on', (new Date())
                console.log comment.permalink
                console.log message
                console.log ''

                comment.reminded = yes
                comment.save (error) ->
                  if error?
                    console.error 'error on', (new Date())
                    console.error "could not update comment #{comment.id}:", error
                    console.error ''
                  else
                    socket.emit 'removed', comment
                    # if should_pushover
                    #   push.send
                    #     timestamp: Math.round((new Date()).getTime() / 1000)
                    #     message: "#{message}\n\nhttp://ps.tl/ntsb/"
                    #     url_title: 'view on reddit'
                    #     url: comment.permalink
                    #     title: 'NTSB Removed'

              else
                console.log 'commented on', (new Date())
                console.log comment.permalink
                console.log message
                console.log ''

                comment.reminded = yes
                comment.save (error) ->
                  if error?
                    console.error 'error on', (new Date())
                    console.error "could not update comment #{comment.id}:", error
                    console.error ''
                  else
                    socket.emit 'reminded', comment
                    # if should_pushover
                    #   push.send
                    #     timestamp: Math.round((new Date()).getTime() / 1000)
                    #     message: "#{message}\n\nhttp://ps.tl/ntsb/"
                    #     url_title: 'view on reddit'
                    #     url: comment.permalink
                    #     title: 'NTSB Replied'

  stream.on 'error', (error) ->
    console.error 'error on', (new Date())
    console.error 'error retrieving comments', error
    console.error ''

  stream.on 'new', (comments) ->

    for comment in comments

      continue if comment.data.author.toLowerCase() in blacklist.users
      continue if comment.data.subreddit.toLowerCase() in blacklist.subreddits

      if (/note to self/gi).test comment.data.body

        do (comment) ->

          reddit.comments { link: comment.data.link_id[3..] }, (error, comments, link) ->

            if error?
              console.error 'error on', (new Date())
              console.error "could get link info for comment #{comment.data.id}:", error
              console.error ''
            else

              link = link.data.children[0].data
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

                note_to_self = match
                  .replace('&lt;', '<')
                  .replace('&gt;', '>')
                  .replace('&amp;', '&')
                  .replace(/\*|\~/g, '')
                  .trim()

                comment = new Comment(
                  id: comment.data.id
                  name: comment.data.name
                  body: comment.data.body
                  note_to_self: note_to_self
                  author: comment.data.author
                  thumbnail: link.thumbnail
                  link_url: comment.data.link_url
                  subreddit: comment.data.subreddit
                  body_html: comment.data.body_html
                  link_title: comment.data.link_title
                  link_author: comment.data.link_author
                  created_utc: comment.data.created_utc
                  permalink: "http://reddit.com#{link.permalink}#{comment.data.id}/?context=3"
                )

                comment.save (error, comment) ->
                  if error?
                    console.error 'error on', (new Date())
                    console.error "could not save comment #{comment.id}:", error
                    console.error ''
                  else
                    console.log 'found on', (new Date())
                    console.log comment.permalink
                    console.log comment.note_to_self
                    console.log ''

                    socket.emit 'new-comment', comment
                    if should_pushover
                      push.send
                        message: "#{comment.note_to_self}\n\nhttp://ps.tl/ntsb/"
                        timestamp: Math.round((new Date()).getTime() / 1000)
                        url_title: 'view on reddit'
                        url: comment.permalink
                        title: 'NTSB'
