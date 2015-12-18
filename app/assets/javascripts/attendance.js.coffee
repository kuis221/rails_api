jQuery ->
  $(document).on 'hidden', '.has-popover.invite-editable-attribute', () ->
    $(this).data('popover').tip().find('form').submit();
  $(document).on 'click', '#invites-list .edit_invite_individual input:checkbox', () ->
    $(this.form).submit()
  $(document).on 'click', '.popover a.decrease, .popover a.increase', (e) ->
    e.preventDefault()
    operation = if $(this).hasClass('decrease') then '-' else '+'
    form = $(this).parents('.popover-content').find('form')
    input = form.find('input[type=number]')
    input.val(eval("#{input.val()} #{operation} 1"))
 
  $(document).on 'click', '#attendance-group-by a.btn', () ->
    $('#invites-list').replaceWith('<div class="loading-spinner"></div>');
