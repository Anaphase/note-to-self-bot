angular.module('App.services')

.factory('App', [
  
  ->
    
    name: 'note to self bot'
    version: '1.1.0'
    
    addresses:
      api: 'http://localhost:8080'
  
])
