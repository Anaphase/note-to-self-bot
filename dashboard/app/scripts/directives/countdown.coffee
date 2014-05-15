angular.module('App.directives')

.directive('countdown', [
  
  '$timeout'
  
  ($timeout) ->
    restrict: 'E'
    scope:
      end: '@'
    link: (scope, element, attrs) ->
      
      delay = (60*60*24)
      update_timeout = null
      
      update = ->
        
        now = Date.now() // 1000
        seconds_left = scope.end - (now - delay)
        
        if seconds_left <= 0
          element.text '?'
          return $timeout.cancel update_timeout
        else if seconds_left <= 60
          time_left = seconds_left
          interval = 1
          unit = 's'
        else if seconds_left <= 3600
          time_left = seconds_left // 60
          interval = seconds_left %% 60
          unit = 'm'
        else
          time_left = seconds_left // 3600
          interval = seconds_left % 3600
          unit = 'h'
        
        element.text "#{time_left}#{unit}"
        update_timeout = $timeout update, 1000*interval
      
      update()
      
      element.on '$destroy', ->
        $timeout.cancel update_timeout
  
])
