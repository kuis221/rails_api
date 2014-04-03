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
				if "#{$(li).data('group')} #{$(li).text()}".toLowerCase().search(value) > -1
					$(li).show()
				else
					$(li).hide()

		@preview = @element.find('#report-container')
		@reportOverlay = $('<div class="report-overlay">').hide().insertAfter(@preview)

		@element.find('.sortable-list').sortable
			forcePlaceholderSize: false,
			receive: (event, ui) =>
				if ui.item.data('field-id') is 'values'
					$(ui.placeholder).addClass('ui-state-error')
					$(ui.sender).sortable('cancel')
					event.stopPropagation()

				# when it comes directly from the fields list
				if ui.helper?
					@addFieldToList ui.item, $(event.target)
				true
			over: (event, ui) =>
				if ui.item.data('field-id') is 'values'
					ui.placeholder.hide()
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
				@removeField ui.draggable

		@element.find(".draggable-list li").draggable
			connectToSortable: ".sortable-list"
			revert: "invalid"
			helper: "clone"
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

		$(window).on 'beforeunload', =>
			if not @saved
				'All changes will be lost. Are you sure you want to exit?'

		@_setListItems 'rows', @options.rows
		@_setListItems 'values', @options.values
		@_setListItems 'columns', @options.columns
		@_setListItems 'filters', @options.filters
		@_addValuesToColumns()

		$('#report-fields .report-field').tooltip
			html: true, container: @element, delay: 0, animation: false
			placement: (tooltip, field) ->
				window.setTimeout ->
					$(tooltip).css
						left: (parseInt($(tooltip).css('left'))-15)+'px'
				10

				return 'left';

		# for field in $('#report-fields .report-field').get()
		# 	$(field).data('tooltip').options.placement = 'left'

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

		$(window).bind "scroll resize DOMSubtreeModified", () =>
			@_resizeSideBar()

		@element

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
		@_showOverlay()
		$.ajax
			url: "/results/reports/#{@id}/preview.js",
			type: 'POST',
			data: @_reportFormData(),
			complete: () =>
				@_hideOverlay()
		, 1000

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
							append($('<label class="control-label" for="report-field-label">').text('Label'),
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
								append(	$('<label class="control-label" for="report-field-aggregate">').text('Summarize by'),
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
								append(	$('<label class="control-label" for="report-field-display">').text('Display as'),
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
		field = {field: item.data('field-id'), label: label, aggregate: 'sum'}
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
		{field: $row.data('field-id'), label: field.label, aggregate: if field.aggregate? then field.aggregate else 'sum' }

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
			display: if field.display? then field.display else ''
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
		padding = parseInt(sidebar.css('padding-top')) + parseInt(sidebar.css('padding-bottom'))
		sidebarHeight = Math.max(560, ($(window).height() - sidebar.position().top - padding - 10))
		sidebar.css({height: sidebarHeight+'px', position: 'fixed', right: '10px'})

		sidebar.find('#report-fields').css({height: sidebarHeight - sidebar.find('.fixed-height-lists').outerHeight() - parseInt(sidebar.css('padding-bottom')) })

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
