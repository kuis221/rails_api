$.widget 'nmk.dataExtract', {
  options: {
  },

  _create: () ->
    @_loadPreview()
    @_loadAvailableFields()

    $('.available-fields-box').on 'click', '.available-field', (e) =>
        e.preventDefault()
        @_addColumn($(e.currentTarget).data('name'))

    @element.on 'click', '.btn-remove-column', (e) =>
        e.preventDefault()
        @_hideColumn($(e.currentTarget).data('column'))

  _hideColumn:(column) ->
    @element.find('form').find('[name="data_extract[columns][]"][value="' + column + '"]').remove()
    @_loadPreview()
    @_loadAvailableFields()

  _addColumn:(column) ->
    $('<input>', { type: 'hidden', name: 'data_extract[columns][]', value: column }).insertAfter(
        @element.find('form').find('[name="data_extract[columns][]"]:last'))
    @_loadPreview()
    @_loadAvailableFields()

  _loadPreview: () ->
    form = @element.find('form')
    @element.find('.data-extract-table').load '/results/data_extracts/preview?' + form.serialize()

  _loadAvailableFields: () ->
    form = @element.find('form')
    $('.available-fields-box').load '/results/data_extracts/available_fields?' + form.serialize()


}