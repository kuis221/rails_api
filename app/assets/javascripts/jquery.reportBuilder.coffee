$.widget 'nmk.reportBuilder',
	options: {
		id: null,
		rows: [],
		columns: [],
		values: [],
		filters: [],
	},

	_create: () ->
		@saved = true
		@id = @options.id
		# Fields search input
		@element.find('#field-search-input').on 'keyup', (e) =>
			value = $(e.target).val().toLowerCase();
			for li in @element.find("#report-fields li:not(.hidden)")
				if $(li).text().toLowerCase().search(value) > -1
					$(li).show()
				else
					$(li).hide()

		@preview = @element.find('#report-container')
		@reportOverlay = $('<div class="report-overlay">').hide().insertAfter(@preview)

		@element.find('.sortable-list').sortable
			receive: (event, ui) =>
				if ui.helper?
					ui.item.addClass('hidden').hide()
				true
			update: (event, ui) =>
				@reportModified()
				true
			connectWith: '.sortable-list',
			containment: 'body'
		.droppable
			greedy: true

		# Allow the list items to be removed when dropped outside of the list
		$('body').droppable
			accept: ".sortable-list li"
			drop: ( event, ui ) =>
				$("#report-fields li[data-field-id=\"#{ui.draggable.data('field-id')}\"]").removeClass('hidden').show()
				ui.draggable.remove()

		@element.find(".draggable-list li").draggable
			connectToSortable: ".sortable-list",
			revert: "invalid",
			helper: "clone",
			containment: "#resource-filter-column", 
			scroll: false,
			# The next two events (start/drag) are only to fix this issue: 
			#http://stackoverflow.com/questions/5791886/jquery-draggable-shows-helper-in-wrong-place-when-scrolled-down-page
			start: () ->
				$(this).data "startingScrollTop", $(this).parent().scrollTop()
			drag: (event, ui) ->
				st = parseInt( $(this).data("startingScrollTop") )
				ui.position.top -= $(this).parent().scrollTop() - st

		@element.find('.btn-save-report').on 'click', () =>
			@saveForm()

		@_setListItems 'rows', @options.rows
		@_setListItems 'columns', @options.columns
		@_setListItems 'values', @options.values
		@_setListItems 'filters', @options.filters


	saveForm: () ->
		$.ajax
			url: "/results/reports/#{@id}.js",
			type: 'PUT',
			data: @_reportFormData(),
			success: () =>
				@element.find('.btn-save-report').attr('disabled', true)
				@saved = true

	refreshReportPreview: () ->
		# Simulate the report is updating
		@_showOverlay()
		$.ajax
			url: "/results/reports/#{@id}/preview.js",
			type: 'POST',
			data: @_reportFormData(),
			complete:
				@_hideOverlay()
		, 1000

	reportModified: () ->
		@element.find('.btn-save-report').attr('disabled', false)
		@refreshReportPreview()
		@saved = false

	_getColumns: () -> 
		$.map $('#report-columns li', @element), (column, i) =>
			@_getColumnProperties column

	_getRows: () -> 
		$.map $('#report-rows li', @element), (row, i) =>
			@_getRowProperties row

	_getFilters: () -> 
		$.map $('#report-filters li', @element), (filter, i) =>
			@_getFilterProperties filter

	_getValues: () -> 
		$.map $('#report-values li', @element), (value, i) =>
			@_getValueProperties value

	_getColumnProperties: (column) ->
		$col = $(column)
		{field: $col.data('field-id'), label: $col.text(), aggregate: 'sum' }

	_getRowProperties: (row) ->
		$row = $(row)
		{field: $row.data('field-id'), label: $row.text(), aggregate: 'sum' }

	_getFilterProperties: (filter) ->
		$filter = $(filter)
		{field: $filter.data('field-id'), label: $filter.text(), aggregate: 'sum' }

	_getValueProperties: (value) ->
		$value = $(value)
		{field: $value.data('field-id'), label: $value.text(), aggregate: 'sum' }

	_setListItems: (list_name, items) ->
		list = $("#report-#{list_name}", @element)
		for item in items
			list.append $('<li>').addClass('report-field field-in-report').data('field-id', item.field).data('field', item).text(item.label)
			$("#report-fields li[data-field-id=\"#{item.field}\"]").hide()
		true

	_showOverlay: () ->
		@preview.css opacity: 0.5
		@reportOverlay.css 
			position: 'absolute',
			top: @preview.position().top+"px",
			left: @preview.position().left+"px",
			height: @preview.outerHeight()+"px",
			width: @preview.outerWidth()+"px",
			borderColor: '#000'
		.show()

	_hideOverlay: () ->
		@preview.css opacity: 1
		@reportOverlay.hide()

	_reportFormData: () ->
		{ 
			report: {
				columns: @_getColumns(),
				rows: @_getRows(),
				filters: @_getFilters(),
				values: @_getValues()
			}
		}
