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
            
            '$resource'
            
            ($resource) ->
              $resource 'http://localhost:8080/comments/:id', id: '@id'
             
          ]
          comments: [
            
            '$q'
            '$resource'
            
            ($q, $resource) ->
              
              deferred = $q.defer()
              
              Comment = $resource 'http://localhost:8080/comments/:id', id: '@id'
              
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
      
      .otherwise
        redirectTo: '/'
  
])

.run([
  
  'App'
  '$rootScope'
  
  (App, $rootScope) ->
    
    document.title = App.name
    
    $rootScope.App = App
  
])
