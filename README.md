# note-to-self-bot

NTSB is a reddit bot that scans comments for 'note to self' and replies with a reminder one day later.

The bot uses [reddit-stream](https://github.com/anaphase/reddit-stream) to scan comments and [MongoDB](https://www.mongodb.org/) to save them locally. The bot uses [socket.io](http://socket.io/) to communicate with the frontend dashboard and [Pushover](https://pushover.net/) to notify your phone when it picks up a comment. NTSB runs forever using [Forever](https://github.com/nodejitsu/forever).

## Bot
`ntsb-bot.coffee` performs the scanning and database operations.

## API
`ntsb-api.coffee` provides a REST-ful API for CRUD operations against the comment database.

## Dashboard
`dashboard/` contains a [Brunch](http://brunch.io/) project that provides a front-end web application for easy comment monitoring and manipulation (via the API.) Here are some screenshots:

![NTSB Dashboard Screenshot- Comment List](http://i.imgur.com/lFTNLZB.png)
![NTSB Dashboard Screenshot - Edit Comment Modal](http://i.imgur.com/xTxE0Uh.png)

## Usage
To run the bot, you'll need to install [Brunch](http://brunch.io/), [Bower](http://bower.io/), and [MongoDB](https://www.mongodb.org/). Then follow these steps:

1. Start a [MongoDB](https://www.mongodb.org/) database:
  ```bash
  $ mongod --config mongodb.conf
  ```

  Here's a good mongodb.conf:

  ```
  fork = true
  bind_ip = 127.0.0.1
  port = 27017
  quiet = true
  dbpath = /data/db
  logpath = /var/log/mongodb/mongod.log
  logappend = true
  journal = true
  ```

2. Install NPM packages for the backend:
  ```bash
  $ cd note-to-self-bot
  $ npm install
  ```

3. Create `lib/auth.coffee` and supply your reddit and [Pushover](https://pushover.net/) credentials:
  ```coffee
  module.exports =
    reddit:
      username: 'your-bot-name'
      password: 'your-password'
    pushover:
      user: 'pushover-user'
      token: 'pushover-token'
  ```

4. Install NPM & Bower packages for the frontend:
  ```bash
  $ cd dashboard
  $ npm install && bower install
  ```

5. Build the frontend:
  ```bash
  $ brunch build -P
  ```

6. Start the API server and bot:
  ```bash
  $ cd ..
  $ chmod +x backend.sh
  $ ./backend.sh start api
  $ ./backend.sh start bot
  ```

7. Load the frontend by pointing your browser to the dashboard's `public` folder (probably `http://localhost/note-to-self-bot/dashboard/public/`)
  
  Comments will appear in this list as the bot picks them up. You're free to edit the responses before the bot comments.
