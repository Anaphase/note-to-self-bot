q = require 'q'
mongoose = require 'mongoose'

schema = new mongoose.Schema(
  name: String
  type: String
  label: String
  read_only:
    default: no
    type: Boolean
  value: mongoose.Schema.Types.Mixed
)

# makes sure certain settings exists, and creates them otherwise
schema.methods.checkSettings = ->

  Setting = @model('Setting')

  required_settings = [
    name: 'scan'
    value:
      value: on
      name: 'scan'
      type: 'boolean'
      label: 'Scan for new comments'
  ,
    name: 'remind'
    value:
      value: on
      name: 'remind'
      type: 'boolean'
      label: 'Reply to comments in queue'
  ,
    name: 'should_pushover'
    value:
      value: on
      name: 'should_pushover'
      type: 'boolean'
      label: 'Send Pushover notifications'
  ,
    name: 'api_port'
    value:
      value: process.env.PORT or 8080
      name: 'api_port'
      type: 'number'
      label: 'API Port'
      read_only: yes
  ]

  Setting.find().select('-_id -__v').exec (error, settings) ->

    if error?
      console.error 'error on', (new Date())
      console.error 'could not read settings from database:', error
      console.error ''
      return

    for required_setting in required_settings

      do (required_setting) ->

        setting = (setting for setting in settings when setting.name is required_setting.name)[0]

        if setting?
          required_setting.deferred.resolve setting
        else
          setting = new Setting(required_setting.value)
          setting.save (error) ->
            if error?
              console.error 'error on', (new Date())
              console.error 'could not save', required_name, 'setting:', error
              console.error ''
              required_setting.deferred.reject error
            else
              required_setting.deferred.resolve setting

  q.all ((required_setting.deferred = q.defer()).promise for required_setting in required_settings)

module.exports = mongoose.model 'Setting', schema
