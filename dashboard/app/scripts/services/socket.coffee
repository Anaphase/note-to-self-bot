angular.module('App.services')

.factory('socket', [
  
  'growl'
  '$rootScope'
  
  (growl, $rootScope) ->
    
    unless io?
      growl.addErrorMessage 'could not load socket.io'
    else
      socket = io.connect 'http://localhost:7070'
    
    on: (event, callback) ->
      return unless socket?
      socket.on event, ->
        args = arguments
        $rootScope.$apply ->
          callback.apply socket, args
  
])
