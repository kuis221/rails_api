jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()

  $.validator.addMethod("oneupperletter",  (value, element) ->
    return this.optional(element) || /[A-Z]/.test(value);
  , "Should have at least one upper case letter");

  $.validator.addMethod("onedigit", (value, element) ->
    return this.optional(element) || /[0-9]/.test(value);
  , "Should have at least one digit");