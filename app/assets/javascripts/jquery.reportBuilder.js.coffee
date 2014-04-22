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
			@searchFieldList $(e.target).val().toLowerCase()

		@preview = @element.find('#report-container')
		@reportOverlay = $('<div class="report-overlay">').hide().insertAfter(@preview)

		@element.find('.sortable-list').sortable
			forcePlaceholderSize: false
			helper: 'clone'
			appendTo: @element.find('.sidebar')
			receive: (event, ui) =>
				if ui.item.data('field-id') is 'values'
					$(ui.placeholder).addClass('ui-state-error')
					$(ui.sender).sortable('cancel')
					event.stopPropagation()

				# when it comes directly from the fields list
				if ui.helper?
					@addFieldToList ui.item, $(event.target)
				@resetScrollers()
				true
			over: (event, ui) =>
				if ui.item.data('field-id') is 'values'
					ui.placeholder.hide()
			update: (event, ui) =>
				@reportModified()
				true
			connectWith: '.sortable-list'
			containment: 'body'
		.droppable
			greedy: true


		# Allow the list items to be removed when dropped outside of the list
		$('body').droppable
			accept: ".sortable-list li"
			drop: ( event, ui ) =>
				@removeField ui.draggable

		@element.find(".draggable-list li").draggable
			connectToSortable: ".sortable-list"
			revert: "invalid"
			helper: "clone"
			appendTo: @element.find('.sidebar')
			containment: "#resource-filter-column"
			scroll: false
			# The next two events (start/drag) are only to fix this issue:
			#http://stackoverflow.com/questions/5791886/jquery-draggable-shows-helper-in-wrong-place-when-scrolled-down-page
			start: () ->
				$(this).data "startingScrollTop", $(this).parent().scrollTop()
			drag: (event, ui) ->
				st = parseInt( $(this).data("startingScrollTop") )
				ui.position.top -= $(this).parent().scrollTop() - st

		@element.find('.btn-save-report').on 'click', () =>
			@saveForm()

		$(window).on 'beforeunload.reportBuilder', =>
			if not @saved
				'All changes will be lost. Are you sure you want to exit?'

		@_setListItems 'rows', @options.rows
		@_setListItems 'values', @options.values
		@_setListItems 'columns', @options.columns
		@_setListItems 'filters', @options.filters
		@_addValuesToColumns()
		@element.find('.scrollable-list').jScrollPane verticalDragMinHeight: 10

		$('#report-fields .report-field').tooltip
			html: true, container: @element, delay: 0, animation: false
			title: (a, b) ->
				$(this).data('title')
			placement: (tooltip, field) ->
				window.setTimeout ->
					$(tooltip).css
						left: (parseInt($(tooltip).css('left'))-15)+'px'
				10

				return 'left';

		@element.on 'click', '.field-remove-btn', (e) =>
			e.stopPropagation()
			@removeField $(e.target).closest('.report-field')
			@reportModified()
			false

		@element.on 'click', '.report-field', (e) =>
			field = if $(e.target).hasClass('report-field') then $(e.target) else $(e.target).closest('.report-field')
			if field.data('field-id') isnt 'values'
				if field.closest('.field-list').attr('id') is 'report-fields'
					@showFieldContextMenu field
				else
					@showFieldSettings field
				e.stopPropagation()
			false

		@element.find('#report-values').on 'sortreceive', (event, ui) =>
			if ui.item.data('field-id') isnt 'values'
				@_addValuesToColumns()

		@refreshReportPreview()

		$(window).bind "scroll.reportBuilder resize.reportBuilder", () =>
			clearTimeout window.reportBuilderTimeout if window.reportBuilderTimeout?
			window.reportBuilderTimeout = window.setTimeout =>
				@_resizeSideBar()
			, 50

		$(window).bind "resize.reportBuilder", () =>
			@resetScrollers()
			true

		@_resizeSideBar()
		@element

	destroy: ->
		$(window).unbind "scroll.reportBuilder"
		$(window).unbind "resize.reportBuilder"
		$(window).off 'beforeunload.reportBuilder'

	searchFieldList: (value) ->
		for li in @element.find("#report-fields li:not(.hidden)")
			if "#{$(li).data('group')} #{$(li).text()}".toLowerCase().search(value) > -1
				$(li).show()
			else
				$(li).hide()
		$('#report-fields ul.draggable-list').show()
		for group in $('.group-name').get()
			group_name = $(group).text()
			if $('#report-fields .report-field[data-group="'+group_name+'"]:visible').length is 0
				$(group).hide()
				$('#report-fields ul.draggable-list[data-group="'+group_name+'"]').hide()
			else
				$(group).show()
		scrollerApi = $('#report-fields .scrollable-list').data('jsp')
		scrollerApi.reinitialise()
		true

	saveForm: () ->
		button = @element.find('button.btn-save-report')
		button.data('ujs:enable-with', button.text()).text(button.data('disable-with')).attr('disabled', true)
		$.ajax
			url: "/results/reports/#{@id}.js",
			type: 'PUT',
			data: @_reportFormData(),
			success: () =>
				@element.find('.btn-save-report').attr('disabled', true)
				@saved = true
			complete: () =>
				button.text(button.data('ujs:enable-with'))

	refreshReportPreview: () ->
		$('#report-container').html('')
		@_showOverlay()
		$.ajax
			url: "/results/reports/#{@id}/preview.js",
			type: 'POST',
			data: @_reportFormData(),
			complete: () =>
				@_hideOverlay()
				$('#report-table').reportTableScroller('adjustTableSize');

		, 1000

	resetScrollers: () ->
		for list in @element.find('.scrollable-list')
			scrollerApi = $(list).data('jsp')
			scrollerApi.reinitialise()

	removeField: (field) ->
		@closeFieldSettings()
		elements = field
		if field.data('field-id') is 'values'
			elements = $('#report-values').find('li')
			field.remove()

		for element in elements.get()
			$("#report-fields li[data-field-id=\"#{$(element).data('field-id')}\"]").removeClass('hidden').show()
			$(element).remove()

		if $('#report-values').find('li:not(.ui-sortable-placeholder)').length == 0
			$('#report-columns').find('li[data-field-id=values]').remove()

	reportModified: () ->
		@element.find('.btn-save-report').attr('disabled', false)
		@refreshReportPreview()
		@saved = false

	showFieldContextMenu: (fieldElement) ->
		if @fieldSettings?
			if @fieldSettings.fieldElement[0] is fieldElement[0]
				return @closeFieldSettings()
			else
				@closeFieldSettings()

		fieldElement.addClass 'settings-open'

		options = [
			$('<a href="#" class="option">Add to Filters</a>').on 'click', () =>
				$('#report-filters').append fieldElement.clone().removeClass('settings-open')
				@addFieldToList fieldElement, $('#report-filters')
				@reportModified()
				@closeFieldSettings()

			$('<a href="#" class="option">Add to Columns</a>').on 'click', () =>
				$('#report-columns').append fieldElement.clone().removeClass('settings-open')
				@addFieldToList fieldElement, $('#report-columns')
				@reportModified()
				@closeFieldSettings()

			$('<a href="#" class="option">Add to Rows</a>').on 'click', () =>
				$('#report-rows').append fieldElement.clone().removeClass('settings-open')
				@addFieldToList fieldElement, $('#report-rows')
				@reportModified()
				@closeFieldSettings()

			$('<a href="#" class="option">Add to Values</a>').on 'click', () =>
				$('#report-values').append fieldElement.clone().removeClass('settings-open')
				@addFieldToList fieldElement, $('#report-values')
				@reportModified()
				@closeFieldSettings()
		]

		@fieldSettings = $('<div class="report-field-settings"><div class="arrow-up"></div></div>').hide()
			.append($('<div class="report-field-settings-inner">').append(options))
			.appendTo(@element)
		@fieldSettings.fieldElement = fieldElement
		@fieldSettings.changed = false
		@_placeFieldSettings()
		@fieldSettings.show()

		$(document).on 'click.reportFieldSettings', =>
			@closeFieldSettings()

		@fieldSettings.on 'click', -> false


	showFieldSettings: (fieldElement) ->
		if @fieldSettings?
			if @fieldSettings.fieldElement[0] is fieldElement[0]
				return @closeFieldSettings()
			else
				@closeFieldSettings()

		fieldElement.addClass 'settings-open'

		field = fieldElement.data('field')
		listName = fieldElement.closest('ul').attr('id')

		formFields = []
		formFields.push $('<div class="control-group">').
							append($('<label class="control-label" for="report-field-label">').text('Label:'),
								$('<div class="controls">').append(
									$('<input type="text" name="report-field-label" id="report-field-label">').val(field.label).
										on 'keyup', (e) =>
											field.label = e.target.value
											fieldElement.find('.field-label').text(e.target.value)
											@fieldSettings.changed = true
								)
							)

		if listName in ['report-values', 'report-rows']
			formFields.push $('<div class="control-group">').
								append(	$('<label class="control-label" for="report-field-aggregate">').text('Summarize by:'),
										$('<div class="controls">').append(
											$('<select name="report-field-aggregate" id="report-field-aggregate">').append([
													$('<option value="count">Count</option>').attr('selected', field.aggregate is 'count'),
													$('<option value="sum">Sum</option>').attr('selected', field.aggregate is 'sum'),
													$('<option value="avg">Average</option>').attr('selected', field.aggregate is 'avg'),
													$('<option value="max">Max</option>').attr('selected', field.aggregate is 'max'),
													$('<option value="min">Min</option>').attr('selected', field.aggregate is 'min')
												])
												.on 'change', (e) =>
													$select = if e.target.tagName is 'OPTION' then  $(e.target).parent() else $(e.target)
													field.aggregate = $select.val()
													@fieldSettings.changed = true
													if listName is 'report-values'
														label_field = @fieldSettings.find('input[name="report-field-label"]')
														label = label_field.val()
														label = label.replace(/(sum|count|average|max|min) of/i, $('option[value='+$select.val()+']', $select).text() + " of")
														label_field.val(label).trigger('keyup')
										)
								)
		if listName in ['report-values']
			formFields.push $('<div class="control-group">').
								append(	$('<label class="control-label" for="report-field-precision">').text('Decimal places:'),
										$('<div class="controls">').append(
											$('<select name="report-field-precision" id="report-field-precision">').append([
													$('<option value="0">0</option>').attr('selected', field.precision is '0'),
													$('<option value="1">1</option>').attr('selected', field.precision is '1'),
													$('<option value="2">2</option>').attr('selected', field.precision is '2' or field.precision is '' or !field.precision?),
													$('<option value="3">3</option>').attr('selected', field.precision is '3'),
													$('<option value="4">4</option>').attr('selected', field.precision is '4')
												])
												.on 'change', (e) =>
													$select = if e.target.tagName is 'OPTION' then  $(e.target).parent() else $(e.target)
													field.precision = $select.val()
													@fieldSettings.changed = true
										)
								)


		if listName in ['report-values']
			formFields.push $('<div class="control-group">').
								append(	$('<label class="control-label" for="report-field-display">').text('Display as:'),
										$('<div class="controls">').append(
											$('<select name="report-field-display" id="report-field-display">').append([
													$('<option value="">No Calculation</option>').attr('selected', field.display is ''),
													$('<option value="perc_of_column">% of Column</option>').attr('selected', field.display is 'perc_of_column'),
													$('<option value="perc_of_row">% of Row</option>').attr('selected', field.display is 'perc_of_row'),
													$('<option value="perc_of_total">% of Total</option>').attr('selected', field.display is 'perc_of_total')
												])
												.on 'change', (e) =>
													$select = if e.target.tagName is 'OPTION' then  $(e.target).parent() else $(e.target)
													field.display = $select.val()
													@fieldSettings.changed = true
										)
								)

		@fieldSettings = $('<div class="report-field-settings"><div class="arrow-up"></div></div>').hide()
			.append($('<div class="report-field-settings-inner">').append(formFields)).append($('<div class="arrow-down"></div>'))
			.appendTo(@element)
		@fieldSettings.fieldElement = fieldElement
		@fieldSettings.changed = false
		@_placeFieldSettings()
		@fieldSettings.find('select').chosen()
		@fieldSettings.show()

		$(document).on 'click.reportFieldSettings', =>
			@closeFieldSettings()

		@fieldSettings.on 'click', -> false

	closeFieldSettings: () ->
		return if not @fieldSettings?
		if @fieldSettings.changed is true
			@reportModified()
		@fieldSettings.fieldElement.removeClass 'settings-open'
		$(document).off 'click.reportFieldSettings'
		@fieldSettings.remove()
		@fieldSettings = null


	addFieldToList: (item, list) ->
		item.addClass('hidden').hide()
		label = item.find('.field-label').text()
		if item.data('group') isnt 'KPIs'
			label = "#{item.data('group')} #{label}"
		if list.attr('id') is 'report-values'
			label = "Sum of #{label}"
			@_addValuesToColumns()
		field = {field: item.data('field-id'), label: label, aggregate: 'sum', precision: '2'}
		list.find('li[data-field-id="'+item.data('field-id')+'"]').data('field', field).find('.field-label').text(label)

	_placeFieldSettings: () ->
		element = @fieldSettings.fieldElement
		@fieldSettings.css({width: @fieldSettings.fieldElement.outerWidth()+'px'})
		sidebar = @element.find('.sidebar')
		leftFix = -parseInt((@fieldSettings.outerWidth()-element.outerWidth())/2)
		left = element.position().left
		if sidebar.css('position') is 'fixed'
			top = element.offset().top+element.outerHeight() - $(window).scrollTop()
			if top+@fieldSettings.outerHeight()+100 > $(window).height()
				top = element.offset().top - @fieldSettings.outerHeight() - $(window).scrollTop() + 5
				@fieldSettings.removeClass('on-bottom').addClass('on-top')
			else
				@fieldSettings.addClass('on-bottom').removeClass('on-top')
			@fieldSettings.css({
				position: 'fixed',
				top: top+'px',
				left: (element.offset().left+leftFix)+'px'
			})
		else
			@fieldSettings.css({
				position: 'absolute',
				top: (element.position().top+element.outerHeight()+10)+'px',
				left: (element.position().left+leftFix)+'px'
			})

	_getColumns: () ->
		items =  $.map $('#report-columns li', @element), (column, i) =>
			@_getColumnProperties column
		if items.length then items else null

	_getRows: () ->
		items = $.map $('#report-rows li', @element), (row, i) =>
			@_getRowProperties row
		if items.length then items else null

	_getFilters: () ->
		items = $.map $('#report-filters li', @element), (filter, i) =>
			@_getFilterProperties filter
		if items.length then items else null

	_getValues: () ->
		items = $.map $('#report-values li', @element), (value, i) =>
			@_getValueProperties value
		if items.length then items else null

	_getColumnProperties: (column) ->
		$col = $(column)
		field = $col.data('field')
		{field: $col.data('field-id'), label: field.label }

	_getRowProperties: (row) ->
		$row = $(row)
		field = $row.data('field')
		{
			field: $row.data('field-id'), label: field.label,
			aggregate: if field.aggregate? then field.aggregate else 'sum',
			precision: if field.precision? then field.precision else '2'
		}

	_getFilterProperties: (filter) ->
		$filter = $(filter)
		field = $filter.data('field')
		{field: $filter.data('field-id'), label: field.label }

	_getValueProperties: (value) ->
		$value = $(value)
		field = $value.data('field')
		{
			field: $value.data('field-id'),
			label: field.label,
			aggregate: if field.aggregate? then field.aggregate else 'sum',
			display: if field.display? then field.display else '',
			precision: if field.precision? then field.precision else '2'
		}

	_setListItems: (list_name, items) ->
		list = $("#report-#{list_name}", @element)
		for item in items
			if item.field == 'values'
				@_addValuesToColumns()
			else
				li = $("#report-fields li[data-field-id=\"#{item.field}\"]").clone()
				li.find('.field-label').text(item.label)
				list.append li.data('field-id', item.field).data('field', item)
				$("#report-fields li[data-field-id=\"#{item.field}\"]").addClass('hidden').hide()
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

	_resizeSideBar: () ->
		sidebar = @element.find('.sidebar')
		initial = sidebar.outerHeight()
		padding = parseInt(sidebar.css('padding-top')) + parseInt(sidebar.css('padding-bottom'))
		footerHeight = $('footer').outerHeight() + parseInt($('footer').css('margin-top')) + parseInt($('footer').css('margin-bottom')) + parseInt($('footer').css('padding-top')) + parseInt($('footer').css('padding-bottom'))
		sidebarHeight = Math.max(479, ($(window).height() - sidebar.position().top - padding - footerHeight))
		sidebar.css
			height: sidebarHeight+'px'
			position: 'fixed'
			right: '10px'

		sidebarFixedHeight = sidebar.find('.fixed-height-lists').outerHeight() + parseInt(sidebar.css('padding-bottom'))
		fieldsHeight = Math.max((sidebarHeight - sidebarFixedHeight), parseInt(sidebar.find('#report-fields').css('min-height')))
		if sidebarHeight < (fieldsHeight + sidebarFixedHeight)
			sidebar.css height: (fieldsHeight + sidebarFixedHeight)+'px'

		sidebar.find('#report-fields').css height: fieldsHeight
		sidebar.find('.fields-group').css height: (fieldsHeight - sidebar.find('.search-fields').outerHeight() - 8)

		sidebar.find('ul.sortable-list').each (index, list) ->
			$(list).css height: $(list).closest('.scrollable-list').height() - 5

		if initial != sidebar.outerHeight()
			@resetScrollers()
			$(window).trigger('form_builder_sidebar:resize')
		@

	_addValuesToColumns: () ->
		if $('#report-values li', @element).length > 0
			values = (@_getColumns() || []).filter (field) -> field.field == 'values'

			if values.length is 0
				field = {label: 'Values'}
				li = $('<li class="report-field" data-field-id="values">').append(
					$('<a href="#" class="field-remove-btn icon-remove" title="Remove">'),
					$('<div class="field-label">').text('Values'),
					$('<div class="clearfix">')
				).data('field', field)
				@element.find('#report-columns').append li
