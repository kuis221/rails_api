jQuery ->
  $(document).delegate ".task-completed-checkbox", "click", ->
    $(@form).submit()
