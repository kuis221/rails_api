$.loadingContent = 0

$.widget 'nmk.filteredList', {
	options: {
		source: false,
		filtersUrl: false,
		autoLoad: true,
		filters: false,
		onChange: false,
		onPageLoaded: false,
		onFiltersLoaded: false,
		includeCalendars: false,
		includeAutoComplete: false,
		autoCompletePath: '',
		defaultParams: [],
		customFilters: [],
		selectDefaultDate: false,
		selectedDate: new Date(),
		selectDefaultDateRange: false,
		calendarHighlights: null,
		scope: null,
		applyTo: null,
		fixListHeight: true
	},

	_create: () ->
		query = window.location.search.replace(/^\?/,"")
		if query != ''
			@options.defaultParams = @options.clearFilterParams
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">')
			.appendTo(@element).submit (e) ->
				e.preventDefault()
				e.stopPropagation()
				false
		@form.data('serializedData', null)

		if @options.includeAutoComplete and @options.filtersUrl
			@_addAutocompleteBox()

		if @options.includeCalendars
			@_addCalendars()

		@storageScope = @options.scope
		if not @storageScope
			@storageScope = window.location.pathname.replace('/','_')


		@element.parent().append $('<a class="list-filter-btn" href="#" data-toggle="filterbar" title="Filter">').append('<i class="icon-gear">')

		@formFilters = $('<div class="form-facet-filters accordion">')
							.on "show", (e) ->
								$(e.target).closest(".accordion-group").find(".icon-arrow-right").removeClass("icon-arrow-right").addClass("icon-arrow-down").prop "title", "Collapse"
								return
							.on "shown", (e) ->
								$(e.target).closest(".accordion-group").find('.accordion-body').removeClass('collapse')
								return
							.on "hide", (e) ->
								$(e.target).closest(".accordion-group").find(".icon-arrow-down").removeClass("icon-arrow-down").addClass("icon-arrow-right").prop "title", "Expand"
								return

		@formFilters.appendTo(@form)

		if @options.filters
			@setFilters @options.filters

		@form.append(
			$('<input class="btn btn-primary" id="save-filters-btn" type="submit" value="Save">').on 'click', (e) =>
				@_saveFilters()

			$('<input class="btn btn-cancel" id="cancel-save-filters" type="reset" value="Reset">').on 'click', (e) =>
				@_cleanFilters()

			$('<a class="settings-for-filters" title="Filter Settings" href="#"><span class="icon-gear"></span></a>')
				.on 'click', (e) =>
					e.preventDefault()
					e.stopPropagation()
					$.get '/filter_settings/new.js', {apply_to: @options.applyTo, filters_labels: @filtersLabels}
		)

		$(document).on 'filter-box:change', (e) =>
			@reloadFilters()

		@filtersLabels = []

		@filtersPopup = false

		@listContainer = $(@options.listContainer)

		@defaultParams = @options.defaultParams
		@_parseQueryString(window.location.search)
		@loadFacets = true
		firstTime = true
		$(window).on 'popstate', =>
			if firstTime
				firstTime = false
			else
				#@reloadFilters()
				@_parseQueryString(window.location.search)
				@_filtersChanged(false)

		$(window).on 'resize scroll', () =>
			if @filtersPopup
				@_positionFiltersOptions()

		@infiniteScroller = false

		if @options.autoLoad
			@_loadPage(1)

		@_loadFilters() if @options.filtersUrl

		@defaultParams = []
		@initialized = true
		@dateRange = false
		@_serializeFilters()

		$(document).on 'click', (e) ->
			$('.more-options-container').hide()
		.on 'change', '.more-options-container input[type=checkbox]', (e) =>
			$checkbox = $(e.target)
			listItem = $($(e.target).parents('li')[0])
			listItem.find('ul').remove()
			listItem.find('.checker').show()
			$checkbox.change (e) => @_filtersChanged()
			@_filtersChanged()
			$checkbox.attr('checked', true)
			parentList = $(listItem.parents('ul')[0])
			listItem.closest('.accordion-inner').find('>ul').append listItem
			if parentList.find('li').length == 0
				parentList.remove()
			true


	destroy: ->
		@_closeFilterOptions()
		if @infiniteScroller
			@listContainer.infiniteScrollHelper 'destroy'

	_findDefaultParam: (paramName) ->
		$.grep @options.defaultParams, (n, i) ->
			n.name is paramName

	disableScrolling: ->
		if @infiniteScroller
			@listContainer.infiniteScrollHelper 'disableScrolling'

	enableScrolling: ->
		if @infiniteScroller
			@listContainer.infiniteScrollHelper 'enableScrolling'

	_loadFilters: ->
		params = @buildParams()
		$.getJSON @options.filtersUrl, params, (json) =>
			@setFilters json.filters

	_deselectDates: ->
		if @calendar
			@calendar.datepick('clear')
			@calendar.datepick('update')

	getFilters: () ->
		data = @form.serializeArray()
		p = []
		for param in data
			if param.name isnt 'custom_start_date' and param.name isnt 'custom_end_date'
				p.push param if param.value != '' && param.name != 'custom_filter[]'

		for param in @defaultParams
			p.push param

		for param in @options.customFilters
			p.push param

		if @loadFacets
			p.push {'name': 'facets', 'value': true}
			@loadFacets = false
		p

	setFilters: (filters) ->
		$.loadingContent += 1
		@formFilters.html('')
		@filtersLabels = []
		for filter in filters
			if filter.label is 'People'
				@filtersLabels.push 'Users'
				@filtersLabels.push 'Teams'
			else
				@filtersLabels.push filter.label

			if filter.items? and (filter.items.length > 0 or (filter.top_items? and filter.top_items.length))
				@addFilterSection filter
			else if filter.max? and filter.min?
				@addSlider filter
			else if filter.type is 'calendar'
				@addCalendar filter
			else if filter.type is 'time'
				@addTimeFilter filter

		if @options.onFiltersLoaded
			@options.onFiltersLoaded()

		$.loadingContent -= 1
		@


	addSlider: (filter) ->
		min_value = if filter.selected_min? then filter.selected_min else filter.min
		max_value = if filter.selected_max? then filter.selected_max else filter.max
		min_value = Math.min(min_value, filter.max)
		max_value = Math.min(max_value, filter.max)
		$slider = $('<div class="slider-range">')
		$filter = $('<div class="filter-wrapper slider-filter">').data('name', filter.name).append(
			$('<span class="slider-label">').text(filter.label),
			$slider,
			$('<input type="hidden" class="min" name="'+filter.name+'[min]" value="" />'),
			$('<input type="hidden" class="max" name="'+filter.name+'[max]" value="" />')
		)

		$slider.rangeSlider({
			bounds: {min: filter.min, max: filter.max},
			defaultValues:{ min: min_value, max: max_value }
			arrows: false,
			enabled: (max_value > min_value)
		}).on "userValuesChanged", (e, data) =>
			bounds = $(data.label).rangeSlider("bounds")
			if data.values.min != bounds.min || data.values.max != bounds.max
				$filter.find('input.min').val Math.round(data.values.min)
				$filter.find('input.max').val Math.round(data.values.max)
			else
				$filter.find('input.min').val ''
				$filter.find('input.max').val ''
			@_filtersChanged()

		if max_value == min_value
			$filter.find('input.min').val min_value


		@formFilters.append($filter)

	addTimeFilter: (filter) ->
		$filter = $('<div class="filter-wrapper time-filter">').data('name', filter.name).append(
			$('<h3>').text(filter.label),
			$('<div class="row-fluid">').append(
				$('<div class="span6">').append(
					$('<label class="time-start">From <input type="text" class="time-start timepicker-filter" name="'+filter.name+'[start]" value="" /></label>')
				),
				$('<div class="span6">').append(
					$('<label class="time-end">To <input type="text" class="time-end timepicker-filter" name="'+filter.name+'[end]" value="" /></label>')
				)
			)
		)

		@formFilters.append($filter)

		$filter.find('.timepicker-filter').on 'change', () =>
			@_filtersChanged()
		.timepicker className: 'timepicker-filter', timeFormat: 'g:i A'


	addCalendar: (filter) ->
		@formFilters.append(
			$('<input type="hidden" name="'+filter.name+'[start]" class="no-validate">'),
			$('<input type="hidden" name="'+filter.name+'[end]" class="no-validate">')
		)

		$('<div class="dates-range-filter">').data('filter', filter).appendTo(@formFilters).datepick
			rangeSelect: true,
			monthsToShow: 1,
			changeMonth: false,
			prevText: '',
			nextText: '',
			prevJumpText: '',
			nextJumpText: '',
			onDate: true,
			showOtherMonths: true,
			selectOtherMonths: true,
			highlightClass: 'datepick-event',
			daysHighlighted: @options.calendarHighlights,
			renderer: $.extend(
						{}, $.datepick.defaultRenderer,
						{picker: '<div class="datepick">' +
								'<div class="datepick-nav">{link:prev}{link:next}</div>{months}' +
								'{popup:start}<div class="datepick-ctrl">{link:clear}{link:close}</div>{popup:end}' +
								'<div class="datepick-clear-fix"></div></div>'})
			onSelect: (dates, e) =>
				@formFilters.find('input[name="'+filter.name+'[start]"]').val @_formatDate(dates[0])
				@formFilters.find('input[name="'+filter.name+'[end]"]').val @_formatDate(dates[1])
				@_filtersChanged()


	addCustomFilter: (name, value, reload=true) ->
		@options.customFilters.push {'name': name, 'value': value}
		if reload
			@_filtersChanged()
		@

	cleanCustomFilters: (name, value) ->
		@options.customFilters = []
		@

	addFilterSection: (filter) ->
		items = filter.items
		top5 = filter.top_items
		$list = $('<ul>')
		$filter = $('<div class="accordion-group">').append(
			$('<div class="filter-wrapper accordion-heading">').data('name', filter.name).append(
				$('<a>',{href: "#toogle-"+filter.label.replace(/\s+/g, '-').toLowerCase(), class:'accordion-toggle filter-title', 'data-toggle': 'collapse'}).text(filter.label).append(
					$('<span class="icon icon-arrow-down pull-left" title="Collapse">')
				)
			),
			$('<div id="toogle-'+filter.label.replace(/\s+/g, '-').toLowerCase()+'" class="accordion-body in">').append(
				$('<div class="accordion-inner">').append(
					$list
				)
			)
		)
		i = 0
		if not top5
			optionsCount = items.length
			top5 = []
			while i < optionsCount
				option = items[i]
				if (i < 5 or option.selected)
					top5.push option
				i++
		else
			optionsCount = top5.length + items.length

		for option in @_sortOptionsAlpha(top5)
			$list.append @_buildFilterOption(option)

		@formFilters.append $filter
		if optionsCount > 5
			filterListResizer = =>
				container = $trigger.next()
				container.show()
				maxHeight = @element.outerHeight() + @element.offset().top - container.offset().top;

			$trigger = $('<a>',{href: '#', class:'more-options-link'}).text('Show More')
				.on 'click', (e) =>
					container = $trigger.next()
					if container.css('display') == "none"
						$('.more-options-link').next().hide()
						filterListResizer()
					else
						$('.more-options-link').next().hide()
					false
				.on 'click.firstime', (e)=>
					$(e.target).off('click.firstime')
					list = @_buildFilterOptionsList(filter, $filter)
					list.insertAfter($trigger)
					filterListResizer()
					setTimeout () ->
						list.find("input:checkbox").uniform()
					, 100
					false

			$trigger.insertAfter($list)

			$filter
		items = @_sortOptionsAlpha(items)
		$filter.data('filter', filter)

	_sortOptionsAlpha: (options) ->
		options.sort (a, b) ->
			if a.ordering? or b.ordering?
				if not a.ordering
					return 1

				if not b.ordering
					return -1

				if a.ordering == b.ordering
					return 0
				return  if a.ordering > b.ordering then 1 else -1

			if a.label == b.label
				return 0

			return if a.label > b.label then 1 else  -1

	# Display the popout list of options after the user clicks
	# on the "More" button
	_showFilterOptions: (filterWrapper) ->
		if @filtersPopup
			@_closeFilterOptions()

		filter = filterWrapper.data('filter')
		items = @_buildFilterOptionsList(filter, filterWrapper)

		if items? and items.find('li').length > 0
			@filtersPopup = $('<div class="filter-box more-options-popup">').append(items).insertBefore filterWrapper
			bootbox.modalClasses = 'modal-med'
			@filtersPopup.data('wrapper', filterWrapper)

			$(document).on 'click.filteredList', ()  => @_closeFilterOptions()

			@_positionFiltersOptions()

	_positionFiltersOptions: () ->
		reference = @filtersPopup.data('wrapper')
		maxHeight = $(window).height() - 200
		@filtersPopup.css({'max-height': $(window).height()-200})
		if (@filtersPopup.offset().top + @filtersPopup.height() > $(window).scrollTop()+$(window).height())
			@filtersPopup.css({'position': 'fixed', 'bottom': '0px'})
		else if $(window).scrollTop()+200 >= @filtersPopup.offset().top
			@filtersPopup.css({'position': 'fixed', 'top': '200px'})


		@filtersPopup.css {
			'max-height': ($(window).height()-200) + 'px'
		}

	_closeFilterOptions: () ->
		if @filtersPopup
			@filtersPopup.remove()
		$(document).off 'click.filteredList'

	_buildFilterOptionsList: (list, filterWrapper) ->
		$list = null
		if list? and list.items? and list.items.length
			items = {}
			for option in list.items
				if filterWrapper.find('input:checkbox[name^="'+option.name+'"][value="'+option.id+'"]').length == 0
					$option = @_buildFilterOption(option)
					group = if option.group then option.group else '__default__'
					items[group] ||= []
					items[group].push $option

			$list = $('<ul class="filter_vertical_box">')
			for group, children of items
				if children.length > 0
					if group isnt '__default__'
						$list_group = $('<li class="options-list-group">')
							.on 'click', (e) =>
								$current_div = $list_group.parent().parent()

						$list.append $list_group.text(group)
					$list.append children

				$div = $('<div class="more-options-container">').append($list).on 'click', (e) ->
					e.stopPropagation()
		$div

	_buildFilterOption: (option) ->
		$('<li>')
			.append $('<label>').append(
				$('<input>',{type:'checkbox', value: option.id, name: "#{option.name}[]", checked: (option.selected is true or option.selected is 'true')}), option.label
			).on 'change', () =>
				@_updateCustomFiltersCheckboxes(option)
				@_filtersChanged()

	_addAutocompleteBox: () ->
		previousValue = '';
		@acInput = $('<input type="text" name="ac" class="search-query no-validate" placeholder="Search" id="search-box-filter">')
			.appendTo(@form)
			.on 'blur', () =>
				if @searchHidden.val()
					@acInput.hide()
					@searchLabel.show()
		@acInput.bucket_complete {
			position: { my: "left top", at: "left bottom+3", collision: "none" }
			source: @_getAutocompleteResults,
			sourcePath: @options.autoCompletePath,
			select: (event, ui) =>
				#@reloadFilters()
				@_autoCompleteItemSelected(ui.item)
			minLength: 2
		}
		@searchHiddenLabel = $('<input type="hidden" name="ql">').appendTo(@form).val('')
		@searchHidden = $('<input type="hidden" name="q">').appendTo(@form).val('')
		@searchLabel = $('<div class="search-filter-label">')
			.append($('<span class="term">'))
			.append($('<span class="close">').append(
				$('<i class="icon-remove">').click =>
					@_cleanSearchFilter()
					@_filtersChanged()
				))
			.css('width', @acInput.width()+'px').appendTo(@form).hide()
			.click =>
				@searchLabel.hide()
				@acInput.show()
				@acInput.focus()

	_getAutocompleteResults: (request, response) ->
		params = {q: request.term}
		$.get @options.sourcePath, params, (data) ->
			response data
		, "json"

	_autoCompleteItemSelected: (item) ->
		#@_cleanFilters()
		@searchHidden.val "#{item.type},#{item.value}"
		cleanedLabel = item.label.replace(/(<([^>]+)>)/ig, "");
		@searchHiddenLabel.val cleanedLabel
		@acInput.hide().val ''
		@searchLabel.show().find('span.term').html cleanedLabel
		@_filtersChanged()
		false

	_cleanFilters: () ->
		@initialized = false
		@defaultParams = []
		@_cleanSearchFilter()
		@_deselectDates()
		defaultParams = if typeof @options.clearFilterParams != 'undefined' then @options.clearFilterParams else @options.defaultParams
		defaultParams ||= []
		@element.find('input[type=checkbox]').attr('checked', false)
		for param in defaultParams
			@element.find('input[name="'+param.name+'"][value="'+param.value+'"]').attr('checked', true)
		@_filtersChanged()
		@initialized = true
		defaultParams = null
		false

	_cleanSearchFilter: () ->
		if @searchHidden
			@searchHidden.val ""
			@searchHiddenLabel.val ""
			@acInput.show().val ""
			@searchLabel.hide().find('span.term').text ''

		false

	_saveFilters: () ->
		data = @_serializeFilters()
		if data
			$.get '/custom_filters/new.js', {apply_to: @options.applyTo, filters: data}
		false

	setCalendarHighlights: (highlights) ->
		@form.find('.dates-range-filter').datepick('setOption', 'daysHighlighted', highlights)
		@form.find('.dates-range-filter').datepick('update')

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="start_date" class="no-validate">').appendTo @form
		@endDateInput = $('<input type="hidden" name="end_date" class="no-validate">').appendTo @form
		@_previousDates = []

		if @options.defaultParams
			for param in @options.defaultParams
				if param.name is 'start_date'
					@startDateInput.val param.value
				if param.name is 'end_date'
					@endDateInput.val param.value

		@calendar = $('<div class="dates-range-filter">').appendTo(@form).datepick {
			rangeSelect: true,
			monthsToShow: 1,
			changeMonth: false,
			defaultDate: (if @options.selectDefaultDate then @options.selectedDate else null),
			selectDefaultDate: @options.selectDefaultDate,
			prevText: '',
			nextText: '',
			prevJumpText: '',
			nextJumpText: '',
			onDate: true,
			showOtherMonths: true,
			selectOtherMonths: true,
			highlightClass: 'datepick-event',
			daysHighlighted: @options.calendarHighlights,
			dayNamesMin: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
			renderer: $.extend(
						{}, $.datepick.defaultRenderer,
						{picker: '<div class="datepick">' +
								'<div class="datepick-nav">{link:prev}{link:next}</div>{months}' +
								'{popup:start}<div class="datepick-ctrl">{link:clear}{link:close}</div>{popup:end}' +
								'<div class="datepick-clear-fix"></div></div>'}),
			onSelect: (dates) =>
				if @initialized == true
					if @dateRange == false
						@customDatesPanel.find('ul .active').removeClass('active')
						@_updateDateRangeInput()
					@dateRange = false

					if @_previousDates != @_datesToString(dates)
						@calendar.find('.datepick-month a').removeClass('first-selected last-selected')
						@calendar.find('.datepick-selected:first').addClass('first-selected')
						@calendar.find('.datepick-selected:last').addClass('last-selected')
						@_previousDates = @_datesToString(dates)
						@customDatesFilter.find('input[name=custom_start_date]').datepicker('setDate', dates[0])
						@customDatesFilter.find('input[name=custom_end_date]').datepicker('setDate', dates[1])
						@_filtersChanged()
				else
					@calendar.find('.datepick-selected:first').addClass('first-selected')
					@calendar.find('.datepick-selected:last').addClass('last-selected')
		}

		@customDatesFilter = $('<div class="custom-dates-inputs">').appendTo(@form).append(
			$('<div class="start-date">').append(
				$('<label for="custom_start_date">').text('Start date'),
				$('<input type="text" class="input-calendar date_picker disabled" id="custom_start_date" name="custom_start_date" readonly="readonly">').val('mm/dd/yyyy').datepicker
					showOtherMonths: true
					selectOtherMonths: true
					dateFormat: "mm/dd/yy"
					onSelect: () =>
						startDateInput = @customDatesFilter.find("[name=custom_start_date]")
						endDateInput = @customDatesFilter.find("[name=custom_end_date]")
						applyButton = @customDatesPanel.find("#apply-ranges-btn")
						if startDateInput.val() != 'mm/dd/yyyy' && endDateInput.val() != 'mm/dd/yyyy' && startDateInput.val() != '' && endDateInput.val() != ''
							applyButton.attr('disabled', false)
						else
							applyButton.attr('disabled', true)

						startDateInput.removeClass('disabled')
					onClose: ( selectedDate ) =>
						@customDatesFilter.find("[name=custom_end_date]").datepicker "option", "minDate", selectedDate
			),
			$('<div class="separate">').text('-'),
			$('<div class="end-date">').append(
				$('<label for="custom_end_date">').text('End date'),
				$('<input type="text" class="input-calendar date_picker disabled" id="custom_end_date" name="custom_end_date" readonly="readonly">').val('mm/dd/yyyy').datepicker
					showOtherMonths: true
					selectOtherMonths: true
					dateFormat: "mm/dd/yy"
					onSelect: () =>
						startDateInput = @customDatesFilter.find("[name=custom_start_date]")
						endDateInput = @customDatesFilter.find("[name=custom_end_date]")
						applyButton = @customDatesPanel.find("#apply-ranges-btn")
						if startDateInput.val() != 'mm/dd/yyyy' && endDateInput.val() != 'mm/dd/yyyy' && startDateInput.val() != '' && endDateInput.val() != ''
							applyButton.attr('disabled', false)
						else
							applyButton.attr('disabled', true)

						endDateInput.removeClass('disabled')
					onClose: ( selectedDate ) =>
						@customDatesFilter.find("[name=custom_start_date]").datepicker "option", "maxDate", selectedDate
			)
		)

		@customDatesPanel = $('<div class="dates-pref">').appendTo(@form).append(
			$('<div class="dropdown select-ranges">').append(
				$('<label>').text('Date ranges'),
				$('<a class="dropdown-toggle off" data-toggle="dropdown" href="#" title="Date ranges">')
					.append(
						$('<span class="date-range-label">').html('Choose a date range'),
						$('<i class="icon-arrow-down pull-right"></i><i class="icon-arrow-up pull-right"></i>')
					),
				$('<ul aria-labelledby="dLabel" class="dropdown-menu" role="menu">').append(
					$('<li class="default-ranges">').append(
						$('<div class="row-fluid">').append(
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'cw').text('Current week')
							),
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'cm').text('Current month')
							),
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'today').text('Today')
							)
						),
						$('<div class="row-fluid">').append(
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'pw').text('Previous week')
							),
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'pm').text('Previous month')
							),
							$('<div class="range-date">').append(
								$('<a href="#">').data('selection', 'ytd').text('YTD')
							)
						)
					).on 'click', (e) =>
						$(e.target).closest('ul').find('.active').removeClass('active')
						$(e.target).addClass('active')
						@dateRange = true
						@setCalendarRange $(e.target).data('selection')
						$('.select-ranges.open .dropdown-toggle').dropdown('toggle')
						false
					$('<li class="ranges custom-ranges">').append(
						@customDatesFilter.show()
					)
					$('<li>').append(
						$('<input class="btn btn-primary" id="apply-ranges-btn" type="submit" value="Apply">').attr('disabled', true).on 'click', (e) =>
							@dateRange = false
							@customDateSelected()
							$('.select-ranges.open .dropdown-toggle').dropdown('toggle')
					)
				).on 'click', (e) =>
					false
			)
		)

		if @options.selectDefaultDateRange
			start_date = @_findDefaultParam('start_date')
			end_date = @_findDefaultParam('end_date')
			if start_date.length > 0 && end_date.length > 0
				@selectCalendarDates start_date[0].value, end_date[0].value

	customDateSelected: () ->
		date1 = @customDatesFilter.find("[name=custom_start_date]").datepicker('getDate')
		date2 = @customDatesFilter.find("[name=custom_end_date]").datepicker('getDate')
		if date1 and date2
			@selectCalendarDates date1, date2
			@_updateDateRangeInput date1, date2
			#@calendar.datepick('setDate', [date1, date2])

	setCalendarRange: (range) ->
		dates = switch range
			when "today" then [new Date(), new Date()]
			when "cw" then @getWeekRange(1)
			when "cm" then @getMonthRange(1)
			when "pw" then @getWeekRange(-1)
			when "pm" then @getMonthRange(-1)
			when "ytd" then @getYearTodayRange()
			else []

		if dates.length > 0
			@selectCalendarDates dates[0], dates[1]
			@_updateDateRangeInput dates[0], dates[1]

	_updateDateRangeInput: (startDate, endDate) ->
		dropdown = @customDatesPanel.find('a.dropdown-toggle')
		if startDate and endDate
			dropdown.removeClass('off').find('.date-range-label').text @_formatDate(startDate) + ' - ' + @_formatDate(endDate)
		else
			dropdown.addClass('off').find('.date-range-label').text 'Choose a date range'

	selectCalendarDates: (startDate, endDate) ->
		@calendar.datepick('setDate', [startDate, endDate])
		@_setCalendarDatesFromCalendar()
		@

	_setCalendarDatesFromCalendar: () ->
		dates = @calendar.datepick('getDate')
		if dates.length > 0
			startDate = @_formatDate(dates[0])
			@startDateInput.val startDate

			@endDateInput.val ''
			if dates[0].toLocaleString() != dates[1].toLocaleString()
				endDate = @_formatDate(dates[1])
				@endDateInput.val endDate
		else
			@startDateInput.val ''
			@endDateInput.val ''
		dates = null
		true

	_datesToString: (dates) ->
		if dates.length > 0
			@_formatDate(dates[0]) + @_formatDate(dates[1])
		else
			''

	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],0,0,0)

	getWeekRange: (weeks=1) ->
		today = new Date();
		today.setHours(0, 0, 0, 0);

		# Grabbing Start/End Dates
		if (weeks >= 0)
			startDate = new Date(today.setDate(today.getDate() - today.getDay()));
			endDate = new Date(today.setDate(today.getDate() - today.getDay() + (weeks*6)));
		else
			endDate = new Date(today.setDate(today.getDate() - today.getDay() - 1));
			startDate = new Date(today.setDate((today.getDate() - today.getDay()) + ((weeks+1)*6) + (weeks+1)));

		[startDate, endDate]

	getMonthRange: (months=1) ->
		date = new Date()
		y = date.getFullYear()
		m = date.getMonth()
		if (months >= 0)
			[new Date(y, m, 1), new Date(y, m + months, 0)]
		else
			[new Date(y, m + months, 1), new Date(y, m, 0)]

	getYearTodayRange: () ->
		[new Date(new Date().getFullYear(), 0, 1), new Date()]

	_filtersChanged: (updateState=true) ->
		if @options.includeCalendars
			@_setCalendarDatesFromCalendar()

		if @options.source
			@reloadData

		data = @_getCustomFilters()
		data = @_serializeFilters() if !data
		if @form.data('serializedData') != data
			@form.data('serializedData', data)
			@_storeFilters data
			@_loadPage(1)
			if updateState
				history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' +@form.data('serializedData'));

			@element.trigger('filters:changed')
			if @options.onChange
				@options.onChange(@)

		data = null
		@

	_storeFilters: (data) ->
		if typeof(Storage) isnt "undefined"
			sessionStorage["filters#{@storageScope}"] = data
		@

	_loadStoredFilters: () ->
		if typeof(Storage) isnt "undefined"
			sessionStorage["filters#{@storageScope}"]

	_getCustomFilters: () ->
		data = @form.serializeArray()
		p = ''
		custom_filter = $.grep(data, (p) ->
		  p.name is "custom_filter[]"
		)
		p = custom_filter[0].value.split('&id')[0] if custom_filter.length > 0

	_serializeFilters: () ->
		data = @_deparam(@_getCustomFilters())
		data = @getFilters() if !data.length
		jQuery.param( data )

	buildParams: (params=[]) ->
		data = @_deparam(@_getCustomFilters())
		data = @getFilters() if !data.length
		for param in data
			params.push(param)
		params

	_deparam: (queryString) ->
		params = []
		if queryString
			queryString = queryString.substring(queryString.indexOf("?") + 1).split("&")
			pair = null
			decode = decodeURIComponent
			i = queryString.length
			while i > 0
				pair = queryString[--i].split("=")
				params.push {'name': decode(pair[0]), 'value': decode(pair[1])}
		params

	paramsQueryString: () ->
		@_serializeFilters()

	_updateCustomFiltersCheckboxes: (option=null) ->
		e = @element.find('input[name="custom_filter\\[\\]"][value="'+option.id+'"]')
		@element.find('input[name="custom_filter\\[\\]"]:checked').not(e).prop 'checked', false
		if e.length
			if e.prop('checked') == true
				@element.find('input[type="checkbox"]:checked').not(e).prop 'checked', false
				@_parseQueryString(option.id.split('&id')[0])
			else
				@_cleanFilters()
		false

	_loadingSpinner: () ->
		if @options.spinnerElement?
			@options.spinnerElement()
		else
			$('<li class="loading-spinner">').appendTo @listContainer


	_placeholderEmptyState: () ->
		message = '<p>There are no results matching the filtering criteria you selected.<br />Please select different filtering criteria.</p>'
		if @options.placeholderElement?
			@options.placeholderElement(message)
		else
			$('<div class="placeholder-empty-state">').html(message).appendTo @listContainer

	reloadData: () ->
		@_loadPage 1
		@

	_loadPage: (page) ->
		params = [
			{'name': 'page', 'value': page},
			{'name':'sorting','value': @options.sorting},
			{'name':'sorting_dir','value': @options.sorting_dir}
		]
		params = @buildParams(params)

		if @jqxhr
			@jqxhr.abort()
			@jqxhr = null

		if @options.onBeforePageLoad
			@options.onBeforePageLoad page

		@doneLoading = false
		if page is 1
			if @infiniteScroller
				@listContainer.infiniteScrollHelper 'resetPageCount'

			if @options.fixListHeight
				$('.main').css {'min-height': $('#resource-filter-column').outerHeight(), '-moz-box-sizing': 'border-box'}
				@listContainer.css {height: @listContainer.outerHeight()}
			@listContainer.html ''

		@emptyState.remove() if @emptyState
		@spinner.remove() if @spinner

		@spinner = @_loadingSpinner()

		@jqxhr = $.get @options.source, params, (response, textStatus, jqXHR) =>
			$.loadingContent += 1
			@spinner.remove();
			resultsCount = 0
			if typeof response is 'object'
				if @options.onItemsLoad
					@options.onItemsLoad response, page

				@listContainer.css height: ''

				resultsCount = response.length
			else
				$response = $('<div>').append(response)
				$items = $response.find('[data-content="items"]')
				if @options.onItemsLoad
					@options.onItemsLoad $response, page

				@listContainer.append $items.html()
				@_pageLoaded page, $items
				@listContainer.css height: ''

				resultsCount = $items.find('>*').length

				if page is 1 and resultsCount is 0
					@emptyState = @_placeholderEmptyState()

				$response.remove()
				$items.remove()
				$items = $response = null


			if @options.onPageLoaded
				@options.onPageLoaded page, resultsCount

			$.loadingContent -= 1
			true

		params = null

		true

	_pageLoaded: (page, response) ->
		@doneLoading = true
		if @options.onItemsChange
			@options.onItemsChange(response)

		if page == 1
			@totalPages = response.data('pages')

			if (@totalPages is undefined or @totalPages > 1) and !@infiniteScroller
				@infiniteScroller = @listContainer.infiniteScrollHelper {
					loadMore: (page) =>
						if (@totalPages is undefined or page <= @totalPages) && @doneLoading
							@_loadPage(page)
						else
							false

					doneLoading: =>
						@doneLoading
				}
			else if (@totalPages <= page || response.find('>*').length is 0) and @infiniteScroller
				@listContainer.infiniteScrollHelper 'destroy'
				@infiniteScroller = false
		else if @totalPages is undefined and response.find('>*').length is 0
			# If the first page didn't provided a number of pages and the last request retorned not rows,
			# then assume we reached the end and stop the infiniteScrollHelper
			@listContainer.infiniteScrollHelper 'destroy'
			@infiniteScroller = false

	_parseQueryString: (query) ->
		@initialized = false
		@_cleanSearchFilter()
		query = query.replace(/^\?/,"")
		if query != ''
			if query.match(/_stored=true/)
				query = @_loadStoredFilters()
				if not query
					query = ''
				else
					history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' +query);

			@defaultParams = []
			vars = query.split('&')
			dates = []
			for qvar in vars
				pair = qvar.split('=')
				name = decodeURIComponent(pair[0])
				value = decodeURIComponent((if pair.length>=2 then pair[1] else '').replace(/\+/g, '%20')).replace(/\+/g, ' ')
				if @options.includeCalendars and value and name in ['start_date', 'end_date']
					if name is 'start_date' and value
						dates[0] = @_parseDate(value)
					else
						dates[1] = @_parseDate(value)
				else
					field = @form.find("[name=\"#{name}\"]")
					if field.length
						if field.attr('type') == 'checkbox'
							for element in field
								if element.value == value
									element.checked = true
						else
							field.val(value)
					else
						@defaultParams.push {'name': name, 'value': value}

			if dates.length > 0
				@selectCalendarDates dates[0], dates[1]
			else
				@_deselectDates()
			dates = vars = null

		query = null
		if @searchHidden and @searchHidden.val()
			@acInput.hide()
			@searchLabel.show().find('.term').text @searchHiddenLabel.val()

		@initialized = true

	reloadFilters: () ->
		@loadFacets = true
		if @defaultParams.length == 0
			@defaultParams = $.map(@formFilters.find('input[name="status[]"]:checked'), (checkbox, index) -> {'name': 'status[]', 'value': checkbox.value})
		#@formFilters.html('')
		#@form.data('serializedData','')
		@_loadFilters()
}



$.widget "custom.bucket_complete", $.ui.autocomplete, {
	_renderMenu: ( ul, results ) ->
		for bucket in results
			if bucket.value.length > 0
				ul.append( "<li class='ui-autocomplete-category'>" + bucket.label + "</li>" );
				for item in bucket.value
					@_renderItemData ul, item
	_renderItem: ( ul, item ) ->
		$( "<li>", {class: item.type})
			.append( $( "<a>" ).html( item.label ) )
			.appendTo( ul )
}
