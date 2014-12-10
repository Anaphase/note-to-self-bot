'use strict'

angular.module('App.filters', [])
angular.module('App.services', [])
angular.module('App.directives', [])
angular.module('App.controllers', [])

angular.module('App', [
  
  # Angular modules
  'ngRoute'
  'ngAnimate'
  'ngSanitize'
  'ngResource'
  
  # App modules
  'App.filters'
  'App.services'
  'App.directives'
  'App.controllers'
  
  # siml-angular-brunch modules
  'App.templates'
  
  # Miscellaneous modules
  'cfp.hotkeys'
  'angular-growl'
  'ui.bootstrap.tpls'
  'ui.bootstrap.modal'
  
])

.config([
  
  'growlProvider'
  '$routeProvider'
  
  (growlProvider, $routeProvider) ->
    
    growlProvider.globalTimeToLive 5000
    # growlProvider.globalDisableIcons yes
    
    $routeProvider
      
      .when '/',
        controller: 'Home'
        templateUrl: 'templates/home'
        resolve:
          Comment: [
            
            'App'
            '$resource'
            
            (App, $resource) ->
              $resource "#{App.addresses.api}/comments/:id", id: '@id'
             
          ]
          comments: [
            
            '$q'
            'App'
            'growl'
            '$resource'
            
            ($q, App, growl, $resource) ->
              
              deferred = $q.defer()
              
              Comment = $resource "#{App.addresses.api}/comments/:id", id: '@id'
              
              comments = Comment.query.apply Comment, [
                ->
                  deferred.resolve comments
                (error) ->
                  console.error error
                  deferred.resolve error
                  growl.error 'could not get comments'
              ]
              
              deferred.promise
            
          ]
          Setting: [
            
            'App'
            '$resource'
            
            (App, $resource) ->
              Setting = $resource "#{App.addresses.api}/settings/:setting/:value", setting: '@setting'
             
          ]
          settings: [
            
            '$q'
            'App'
            'growl'
            '$resource'
            
            ($q, App, growl, $resource) ->
              
              deferred = $q.defer()
              
              Setting = $resource "#{App.addresses.api}/settings/:name", name: '@name'
              
              settings = Setting.query.apply Setting, [
                ->
                  deferred.resolve settings
                (error) ->
                  console.error error
                  deferred.resolve error
                  growl.error 'could not get settings'
              ]
              
              deferred.promise
            
          ]
      
      .otherwise
        redirectTo: '/'
  
])

.run([
  
  'App'
  '$document'
  '$rootScope'
  
  (App, $document, $rootScope) ->
    
    $document[0].title = App.name
    
    $rootScope.App = App
  
])
