jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()

  $(document).on 'click', (e) ->
    $('.has-popover').each () ->
        if !$(this).is(e.target) && $(this).has(e.target).length is 0 && $('.popover').has(e.target).length is 0
            $(this).popover('hide')
