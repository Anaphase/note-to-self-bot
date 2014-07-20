mongoose = require 'mongoose'

module.exports = mongoose.model 'Comment',
  id: String
  body: String
  name: String
  author: String
  link_url: String
  body_html: String
  subreddit: String
  permalink: String
  link_title: String
  link_author: String
  note_to_self: String
  reminded: type: Boolean, default: no
  created_utc: type: Number, index: yes
  add_message: type: Boolean, default: yes
