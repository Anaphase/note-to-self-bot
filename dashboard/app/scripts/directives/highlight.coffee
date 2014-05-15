angular.module('App.directives')

.directive('highlight', [
  
  '$timeout'
  
  ($timeout) ->
    restrict: 'A'
    scope:
      highlight: '='
      highlight_after: '@highlightAfter'
    link: (scope, element, attrs) ->
      
      scope.$watch 'highlight', ->
        
        offset = 0
        string = scope.highlight
        subject = element.text()
        
        if scope.highlight_after?
          offset = subject.toLowerCase().indexOf(scope.highlight_after) + scope.highlight_after.length
        
        start = subject.toLowerCase().indexOf string.toLowerCase(), offset
        end = start + string.length
        
        if start is -1
          element.text subject
        else
          element.empty()
          element.append angular.element('<span/>').text(subject.substr(0, start))
          element.append angular.element('<span/>').text(subject.substr(start, string.length)).addClass('highlight')
          element.append angular.element('<span/>').text(subject.substr(end))
  
])
