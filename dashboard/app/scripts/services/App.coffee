angular.module('App.services')

.factory('App', [

  ->

    name: 'note to self bot'
    version: '1.1.0'

    addresses:
      api: window.location.hostname

])
