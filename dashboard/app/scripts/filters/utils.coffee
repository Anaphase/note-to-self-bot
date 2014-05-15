angular.module('App.filters')

.filter('removeQuotes', [
  
  () ->
    (string) ->
      string = string.replace '\'', ''
      string = string.replace '\"', ''
      string
  
])
