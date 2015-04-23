$.widget 'nmk.dataExtract', {
  options: {
  },

  _create: () ->
    @table = @element.find('.data-extract-table').addClass('dragtable-sortable')
    @_buildDragtable()
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
      
    $('#available-field-list .available-field').tooltip
      html: true, container: @element, delay: 0, animation: false
      title: (a, b) ->
        $(this).data('title')
      placement: (tooltip, field) ->
        window.setTimeout ->
          $(tooltip).css
            left: (parseInt($(tooltip).css('left'))-15)+'px'
        10

        return 'left';


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
    scrollerApi = $('.data-extract-box').data('jsp');
    form = @element.find('form')
    @table.dragtable('destroy')
    @element.find('.data-extract-table')
      .css(cursor: 'wait')
      .fadeTo('slow', 0.5)
      .load '/results/data_extracts/preview?' + form.serialize(), =>
        @_buildDragtable()
        if scrollerApi
          scrollerApi.destroy()
        @element.find('.data-extract-table').css(cursor: 'auto').fadeTo('fast', 1)
        $('.data-extract-box').jScrollPane();

  _loadAvailableFields: () ->
    form = @element.find('form')
    $('.available-fields-box').load '/results/data_extracts/available_fields?' + form.serialize()

  _buildDragtable: () ->
    @table.dragtable()
}