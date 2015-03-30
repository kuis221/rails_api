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

    @element.on 'click', '.btn-sort-table', (e) =>
        e.preventDefault()
        btn = $(e.currentTarget)
        @_sortTable btn.data('column'), btn.data('dir')

  _hideColumn:(column) ->
    @element.find('form').find('[name="data_extract[columns][]"][value="' + column + '"]').remove()
    @_loadPreview()
    @_loadAvailableFields()

  _sortTable: (column, dir) ->
    @element.find('form').find('[name="data_extract[default_sort_by]"]').val(column)
    @element.find('form').find('[name="data_extract[default_sort_dir]"]').val(dir)
    @_loadPreview()

  _addColumn:(column) ->
    $('<input>', { type: 'hidden', name: 'data_extract[columns][]', value: column }).insertAfter(
        @element.find('form').find('[name="data_extract[columns][]"]:last'))
    @_loadPreview()
    @_loadAvailableFields()

  _loadPreview: () ->
    form = @element.find('form')
    @element.find('.data-extract-table').css(cursor: 'wait').fadeTo('slow', 0.5).load '/results/data_extracts/preview?' + form.serialize(), =>
        @element.find('.data-extract-table').css(cursor: 'auto').fadeTo('fast', 1)

  _loadAvailableFields: () ->
    form = @element.find('form')
    $('.available-fields-box').load '/results/data_extracts/available_fields?' + form.serialize()


}