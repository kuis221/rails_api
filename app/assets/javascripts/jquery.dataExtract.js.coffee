$.widget 'nmk.dataExtract', {
  options: {
    step: 1,
    selectedFields: [],
    available_fields: []
  },

  _create: () ->
    
    $(document).on 'click', '.available-field-list .available-field', (e) =>
      e.stopPropagation()
      e.preventDefault()
      @options.selectedFields.push($(e.currentTarget).data("name"))
      @_addColumn($(e.currentTarget).data("name"), $(e.currentTarget).text())
      @_removeField($(e.currentTarget))

    $(document).on 'click', '.data-extract-head .data-extract-th', (e) =>
      e.stopPropagation()
      e.preventDefault()
      @options.available_fields.push($(e.currentTarget).data("name"))
      @_addField($(e.currentTarget).data("name"), $(e.currentTarget).text())
      @_removeColumn($(e.currentTarget).index() + 1)

  _addField: (field, name) ->
    $item = $(".available-field-list").append(
      $("<li class='available-field' data-name='#{field}'>").text(name)
      )
    
  _removeField: (field) ->
    field.remove()

  _addColumn: (field, name) ->
    $('.data-extract-head').append(@_formatColumnHeader(field, name))
    
  _removeColumn: (index) ->
    $('.data-extract-table thead').find("tr th:nth-child(#{index})").each ->
      $(this).remove()
    $('.data-extract-table tbody').find("tr td:nth-child(#{index})").each ->
      $(this).remove()

  _formatColumnHeader: (field, name) ->
    $column = $("<th class='data-extract-th' data-name='#{field}'>").append(
      $('<span>').text(name)).append(
        $("<a href='' title='Tool' class='icon-arrow-down pull-right dropdown-toggle' data-name='"+field+"'>")
      ) 
}