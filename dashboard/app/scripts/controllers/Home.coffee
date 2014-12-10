angular.module('App.controllers')

.controller('Home', [
  
  'growl'
  '$http'
  'socket'
  '$scope'
  '$modal'
  '$filter'
  'Comment'
  'comments'
  'Setting'
  'settings'
  '$timeout'
  
  (growl, $http, socket, $scope, $modal, $filter, Comment, comments, Setting, settings, $timeout) ->
    
    $scope.settings = settings
    $scope.comments = comments
    
    getSettingIndex = (setting_to_retrieve) ->
      for setting, index in $scope.settings
        if setting.name is setting_to_retrieve.name
          return index
    
    getCommentIndex = (comment_to_retrieve) ->
      for comment, index in $scope.comments
        if comment.id is comment_to_retrieve.id
          return index
    
    removeComment = (index) ->
      $scope.comments.splice index, 1
    
    $scope.editSettings = ->
      
      $modal.open
        templateUrl: 'partials/settings-modal'
        controller: [
          
          '$scope'
          '$modalInstance'
          
          ($scope, $modalInstance) ->
            
            $scope.settings = angular.copy settings
            
            $scope.save = ->
              
              
              
              for setting in settings
                do (setting) ->
                  setting.value = $scope.settings[getSettingIndex(setting)].value
                  setting.$save.apply setting, [
                    ->
                      growl.success 'setting updated'
                      $modalInstance.close 'setting updated'
                    (error) ->
                      console.error error
                      growl.error 'could not save setting'
                      # $modalInstance.dismiss 'could not save setting'
                  ]
            
            $scope.cancel = ->
              $modalInstance.dismiss 'canceled'
          
        ]
    
    $scope.editComment = (comment) ->
      
      current_id = comments.indexOf comment
            
      $modal.open
        templateUrl: 'partials/edit-modal'
        controller: [
          
          'growl'
          '$scope'
          'hotkeys'
          '$modalInstance'
          
          (growl, $scope, hotkeys, $modalInstance) ->
            
            $scope.comment = angular.copy comments[current_id]
            
            $modalInstance.opened.then ->
              hotkeys.add
                combo: 'right'
                description: 'Edit next comment'
                callback: ->
                  $scope.nextComment()
              
              hotkeys.add
                combo: 'left'
                description: 'Edit previous comment'
                callback: -> $scope.previousComment()
              
              hotkeys.add
                combo: 'meta+s'
                description: 'Save comment'
                allowIn: ['TEXTAREA']
                callback: (event) ->
                  $scope.save()
                  event.preventDefault()
              
              hotkeys.add
                combo: 'backspace'
                description: 'Delete comment'
                callback: (event) ->
                  $scope.delete()
                  event.preventDefault()
              
              hotkeys.add
                combo: 'esc'
                description: 'Close modal'
                callback: ->
            
            $modalInstance.result.finally -> Mousetrap.reset()
            
            $scope.nextComment = ->
              current_id = 0 if ++current_id is comments.length
              $scope.comment = angular.copy comments[current_id]
            
            $scope.previousComment = ->
              current_id = comments.length - 1 if --current_id is -1
              $scope.comment = angular.copy comments[current_id]
            
            $scope.save = ->
              
              for key, value of $scope.comment
                comments[current_id][key] = value
              
              comments[current_id].$save.apply comments[current_id], [
                ->
                  growl.success 'comment updated'
                  $scope.nextComment()
                  # $modalInstance.close 'comment updated'
                (error) ->
                  console.error error
                  growl.error 'could not save comment'
                  # $modalInstance.dismiss 'could not save comment'
              ]
            
            $scope.delete = ->
              
              if confirm "Are you sure you want to delete #{$scope.comment.id}?"
                
                index = getCommentIndex comments[current_id]
                comments[current_id].$delete.apply comments[current_id], [
                  ->
                    removeComment index
                    growl.success 'comment deleted'
                    current_id = 0 if current_id is comments.length
                    $scope.comment = angular.copy comments[current_id]
                    # $modalInstance.close 'comment deleted'
                  (error) ->
                    console.error error
                    growl.error 'could not delete comment'
                    # $modalInstance.dismiss 'could not delete comment'
                ]
            
            $scope.cancel = ->
              $modalInstance.dismiss 'canceled'
          
        ]
    
    socket.on 'new-comment', (comment) ->
      new_comment = Comment.get.apply Comment, [
        id: comment.id
        
        ->
          $scope.comments.push new_comment
          
          note = new_comment.note_to_self
          note = note[...50] + '...' if note.length > 50
          timestamp = new Date().toLocaleString()
          full_note = $filter('removeQuotes')(new_comment.note_to_self)
          
          growl.info "found #{new_comment.id}<hr><a href='#{new_comment.permalink}' title='#{full_note}' target='_blank'>#{note}</a><hr>#{timestamp}", ttl: -1
        
        (error) ->
          console.error error
          growl.error 'could not get new comment'
      ]
    
    socket.on 'reminded', (old_comment) ->
      removeComment getCommentIndex old_comment
      
      note = old_comment.note_to_self
      note = note[...50] + '...' if note.length > 50
      timestamp = new Date().toLocaleString()
      full_note = $filter('removeQuotes')(old_comment.note_to_self)
      
      growl.warning "replied to #{old_comment.id}<hr><a href='#{old_comment.permalink}' title='#{full_note}' target='_blank'>#{note}</a><hr>#{timestamp}", ttl: -1
    
    socket.on 'removed', (old_comment) ->
      removeComment getCommentIndex old_comment
      
      note = old_comment.note_to_self
      note = note[...50] + '...' if note.length > 50
      timestamp = new Date().toLocaleString()
      full_note = $filter('removeQuotes')(old_comment.note_to_self)
      
      growl.error "removed #{old_comment.id}<hr><a href='#{old_comment.permalink}' title='#{full_note}' target='_blank'>#{note}</a><hr>#{timestamp}", ttl: -1
  
])
