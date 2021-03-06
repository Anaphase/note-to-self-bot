angular.module('App.services')

.factory('socket', [
  
  'App'
  'growl'
  '$rootScope'
  
  (App, growl, $rootScope) ->
    
    unless io?
      growl.error 'could not load socket.io'
    else
      socket = io.connect App.addresses.api
    
    on: (event, callback) ->
      return unless socket?
      socket.on event, ->
        args = arguments
        $rootScope.$apply ->
          callback.apply socket, args
  
])
