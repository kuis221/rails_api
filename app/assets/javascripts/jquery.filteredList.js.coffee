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
		defaultParams: '',
		customFilters: [],
		userFilters: {},
		selectDefaultDate: false,
		selectedDate: new Date(),
		selectDefaultDateRange: false,
		ytdDatesRange: '1',
		calendarHighlights: null,
		scope: null,
		applyTo: null,
		fixListHeight: true,
		allowCustomizeFilters: true
	},

	_create: () ->
		@sliders = {}
		query = window.location.search.replace(/^\?/,"")
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">')
			.appendTo(@element).submit (e) ->
				e.preventDefault()
				e.stopPropagation()
				false
		@form.data('serializedData', null)

		if @options.includeAutoComplete and @options.filtersUrl
			@_addAutocompleteBox()

		@_addSavedFilters()

		if @options.includeCalendars
			@_addCalendars()

		@storageScope = @options.scope
		if not @storageScope
			@storageScope = window.location.pathname.replace('/','_')


		@element.parent().append $('<a class="list-filter-btn" href="#" data-toggle="filterbar" title="Filter">').append('<i class="icon-gear">')

		expanded = @_getFilterSectionState('_filters', 'true') == 'true'
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
		@formFilters.hide() unless expanded


		@formFilters.appendTo(@form)

		@toggleFiltersLink = $('<div class="text-right show-hide-filters-link"><a href="#"></a></div>').appendTo(@form).find('a')
			.text(if expanded then 'Hide filters' else 'Show filters')
			.on 'click', () =>
				if @formFilters.css('display') is 'none'
					@_setFilterSectionState('_filters', true)
					@formFilters.slideDown 400, () =>
						@toggleFiltersLink.text('Hide filters')
						for name, slider of @sliders
							$(slider).rangeSlider('resize');
				else
					@_setFilterSectionState('_filters', false)
					@formFilters.slideUp 400, () =>
						@toggleFiltersLink.text('Show filters')
				false

		if @options.filters
			@setFilters @options.filters

		@form.append(
			$('<input class="btn btn-primary" id="save-filters-btn" type="submit" value="Save">').on 'click', (e) =>
				@_saveFilters()

			$('<input class="btn btn-cancel" id="cancel-save-filters" type="reset" value="Reset">').on 'click', (e) =>
				@_resetFilters()
		)

		if @options.allowCustomizeFilters
			@form.append $('<a class="settings-for-filters" title="Filter Settings" href="#"><span class="icon-gear"></span></a>').on 'click', (e) =>
					e.preventDefault()
					e.stopPropagation()
					$.get '/filter_settings/new.js', {apply_to: @options.applyTo}

		$(document).on 'click', '.collection-list-description .filter-item .icon-close', (e) =>
			e.stopPropagation();
			e.preventDefault();
			return unless @doneLoading
			$(e.currentTarget).closest('.filter-item').fadeTo(1000, 0.3)
			filterParts = $(e.currentTarget).data('filter').split(':')
			if filterParts[0] == 'date'
				@_deselectDates()
			else if @sliders[filterParts[0]]
				@setParams "#{filterParts[0]}[min]=&#{filterParts[0]}[max]="
			else
				@_removeParams encodeURIComponent("#{filterParts[0]}[]") + '=' + encodeURIComponent(filterParts[1])
			false


		$(document).on 'filter-box:change', (e) =>
			@reloadFilters()

		@filtersPopup = false

		@listContainer = $(@options.listContainer)

		if window.location.search
			@_parseQueryString window.location.search
		else
			@_parseQueryString @options.defaultParams

		@loadFacets = true
		firstTime = true
		$(window).on 'popstate', =>
			if firstTime
				firstTime = false
			else
				@_paramsQueryString = document.location.search.replace(/^\?/, '')
				@_filtersChanged(false)


		@infiniteScroller = false

		@doneLoading = true
		if @options.autoLoad
			@_loadPage(1)

		@_loadFilters() if @options.filtersUrl

		@initialized = true
		@dateRange = false

		$(window).on 'resize ready', () =>
			@marginFilterResize()

		@marginFilterResize()

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

	getFilters: () ->
		@_deparam @paramsQueryString()

	setFilters: (filters) ->
		$.loadingContent += 1
		@formFilters.html('')
		for filter in filters
			if filter.type is 'rating'
				@addStarRating filter
			else if filter.items? and (filter.items.length > 0 or (filter.top_items? and filter.top_items.length))
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

	addStarRating: (filter) ->
		items = filter.items
		expanded = @_getFilterSectionState(filter.label.replace(/\s+/g, '-')) == 'true'
		$list = $('<ul>')
		$filter = $('<div class="accordion-group">').append(
			$('<div class="filter-wrapper accordion-heading">').data('name', filter.name).append(
				$('<a>',{href: "#toogle-"+filter.label.replace(/\s+/g, '-').toLowerCase(), class:'accordion-toggle filter-title', 'data-toggle': 'collapse'})
					.text(filter.label).addClass(if expanded then '' else 'collapsed').append(
						$('<span class="icon pull-left" title="Expand">').addClass(if expanded then 'icon-arrow-down' else 'icon-arrow-right')
					)
			),
			$('<div id="toogle-'+filter.label.replace(/\s+/g, '-').toLowerCase()+'" class="accordion-body">').addClass(if expanded then 'in' else ' collapse').append(
				$('<div class="accordion-inner">').append($list)
			).on 'show', () =>
				@_setFilterSectionState(filter.label.replace(/\s+/g, '-'), true)
				true
			.on 'hide',  () =>
				@_setFilterSectionState(filter.label.replace(/\s+/g, '-'), false)
				true
		)
		for item in filter.items
			item.label = @_buildFilterStarRating item
			$list.append @_buildFilterOption(item)

		@formFilters.append $filter
		$filter.data('filter', filter)

	_buildFilterStarRating: (option) ->
		i = 0
		html = ""
		while i < 5
			if option.label > i
				html += "<i class='icon-star full'></i>"
			else
				html += "<i class='icon-star empty'></i>"
			i++
		html

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

		@sliders[filter.name] = $slider.rangeSlider({
			bounds: {min: filter.min, max: filter.max},
			defaultValues:{ min: min_value, max: max_value }
			arrows: false,
			enabled: (max_value > min_value)
		}).on "userValuesChanged", (e, data) =>
			bounds = $(data.label).rangeSlider("bounds")
			if data.values.min != bounds.min || data.values.max != bounds.max
				@setParams "#{filter.name}[min]=#{Math.round(data.values.min)}&#{filter.name}[max]=#{Math.round(data.values.max)}"
			else
				@setParams "#{filter.name}[min]=&#{filter.name}[max]="
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

	_addSavedFilters: () ->
		@savedFilters = $('<div class="user-saved-filters filter-wrapper">').appendTo(@form)
						.append(
							$('<label for="user-saved-filter" class="filter-title">').append(@options.userFilters.label),
							@savedFiltersDropdown = $('<select id="user-saved-filter" name="user-saved-filter" class="chosen-enabled"></select>'))
						.find('select').chosen().end()
						.on 'change', () =>
							option = @savedFiltersDropdown.find('option:selected')[0]
							@_setQueryString option.value.split('&id')[0]
		@setSavedFilters(@options.userFilters)

	setSavedFilters: (userFilters, selected=@savedFiltersDropdown.val()) ->
		if not userFilters.items or userFilters.items.length is 0
			@savedFilters.hide()
		else
			@savedFilters.show()
			@savedFiltersDropdown.html('').append('<option value=""></option>')
			for item in userFilters.items
				@savedFiltersDropdown.append($('<option value="'+item.id+'">'+item.label+'</option>').attr('selected', (item.id == selected || item.id.match(new RegExp("id=#{@_escapeRegExp(selected)}$")) isnt null)))
			@savedFiltersDropdown.trigger('liszt:updated')


	addCustomFilter: (name, value, reload=true) ->
		@addParams(encodeURIComponent(name) + '=' + encodeURIComponent(value))
		@

	cleanCustomFilters: (name, value) ->
		@options.customFilters = []
		@

	_supportsHtml5Storage: () ->
		try
			window.hasOwnProperty('localStorage') && window['localStorage'] isnt null
		catch e
			false

	_getFilterSectionState: (name, defaultValue='false') ->
		if @_supportsHtml5Storage()
			localStorage["filter_#{@options.applyTo}_#{name}"] or defaultValue
		else
			false

	_setFilterSectionState: (name, value) ->
		if @_supportsHtml5Storage()
			localStorage["filter_#{@options.applyTo}_#{name}"] = value


	addFilterSection: (filter) ->
		items = filter.items
		top5 = filter.top_items
		expanded = @_getFilterSectionState(filter.label.replace(/\s+/g, '-')) == 'true'
		$list = $('<ul>')
		$filter = $('<div class="accordion-group">').append(
			$('<div class="filter-wrapper accordion-heading">').data('name', filter.name).append(
				$('<a>',{href: "#toogle-"+filter.label.replace(/\s+/g, '-').toLowerCase(), class:'accordion-toggle filter-title', 'data-toggle': 'collapse'})
					.text(filter.label).addClass(if expanded then '' else 'collapsed').append(
						$('<span class="icon pull-left" title="Expand">').addClass(if expanded then 'icon-arrow-down' else 'icon-arrow-right')
					)
			),
			$('<div id="toogle-'+filter.label.replace(/\s+/g, '-').toLowerCase()+'" class="accordion-body">').addClass(if expanded then 'in' else ' collapse').append(
				$('<div class="accordion-inner">').append($list)
			).on 'show', () =>
				@_setFilterSectionState(filter.label.replace(/\s+/g, '-'), true)
				true
			.on 'hide',  () =>
				@_setFilterSectionState(filter.label.replace(/\s+/g, '-'), false)
				true
		)
		i = 0
		if not top5
			optionsCount = items.length
			top5 = []
			while i < optionsCount
				option = items[i]
				if (i < 15 or option.selected)
					top5.push option
				i++
		else
			optionsCount = top5.length + items.length

		for option in @_sortOptionsAlpha(top5)
			$list.append @_buildFilterOption(option)

		@formFilters.append $filter
		if optionsCount > 15
			filterListResizer = =>
				container = $trigger.next()
				container.show()
				maxHeight = @element.outerHeight() + @element.offset().top - container.offset().top;

			$trigger = $('<a>', {href: '#', class:'more-options-link'}).text('More')
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

	_escapeRegExp: (s) ->
		if s then s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&') else s


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
		checked = @paramsQueryString().indexOf(encodeURIComponent("#{option.name}[]") + '=' + encodeURIComponent(option.id)) > -1
		@form.find('input:hidden[name="'+option.name+'[]"][value="'+option.id+'"]').remove() if checked
		$('<li>', style: (if checked then 'display: none;' else ''))
			.append $('<label>').append(
				$('<input>', {type:'checkbox', value: option.id, name: "#{option.name}[]", checked: checked}), option.label
			).on 'change', (e) =>
				if $(e.target).attr('name') == 'custom_filter[]'
					if not $(e.target).prop('checked')
						@_removeParams(option.id)
					else
						@addParams option.id.split('&id')[0]
				else
					params = encodeURIComponent("#{option.name}[]") + '=' + encodeURIComponent(option.id)
					if $(e.target).prop('checked')
						#$(e.target).closest('li').slideUp()
						@addParams params
					else
						#$(e.target).closest('li').show()
						@_removeParams params
				return true unless @initialized
				true

	_clickCheckbox: (elm) ->
		e = $.Event( "click" );
		elm.trigger(e);

	_addAutocompleteBox: () ->
		previousValue = '';
		@acInput = $('<input type="text" name="ac" class="search-query no-validate" placeholder="Search" id="search-box-filter">')
			.appendTo(@form)
		@acInput.bucket_complete {
			position: { my: "left top", at: "left bottom+3", collision: "none" }
			source: @_getAutocompleteResults,
			sourcePath: @options.autoCompletePath,
			select: (event, ui) =>
				#@reloadFilters()
				@_autoCompleteItemSelected(ui.item)
			minLength: 2
		}

	_getAutocompleteResults: (request, response) ->
		params = {q: request.term}
		path = @options.sourcePath
		if document.location.search?
			path = if path.indexOf('?') >= -1 then path + '&' + document.location.search else path + '?' + document.localtion.search
		$.get path, params, (data) ->
			response data
		, "json"

	_autoCompleteItemSelected: (item) ->
		checkbox = @element.find("input[name=\"#{item.type}[]\"][value=\"#{item.value}\"]")
		if checkbox.length
			checkbox.click() unless checkbox.prop('checked')
		else
			@addParams encodeURIComponent("#{item.type}[]") + '=' + encodeURIComponent(item.value)
		@acInput.val ''
		@_filtersChanged()
		false

	# Resets the filter to its initial state
	_resetFilters: () ->
		@form.find('input:checkbox[name^="custom_filter"]').prop('checked', false)
		@savedFiltersDropdown.val('').trigger('liszt:updated')
		@_setQueryString @options.defaultParams
		false

	_removeParams: (params) ->
		@savedFiltersDropdown.val('').chosen('liszt:updated')
		searchString = @paramsQueryString()
		for param in @_deparam(params)
			searchString = searchString.replace(new RegExp('(&)?'+ encodeURIComponent(param.name)+'='+@_escapeRegExp(encodeURIComponent(param.value))+'(&|$)', "g"), '$2')
		@_setQueryString searchString

	addParams: (params) ->
		@savedFiltersDropdown.val('').trigger('liszt:updated')
		qs = @paramsQueryString()
		for param in @_deparam(params)
			paramValue = encodeURIComponent(param.name)+'='+encodeURIComponent(param.value)
			paramValue = '' if param.value is '' or param.value is null
			continue if qs.indexOf(paramValue) >= 0
			if param.name.indexOf('[]') is -1 && qs.indexOf(encodeURIComponent(param.name)) >= 0
				qs = qs.replace(new RegExp("(#{encodeURIComponent(param.name)}=[^&]*)"), paramValue)
			else
				qs = qs + '&' + paramValue
		@_setQueryString qs.replace(/^&/, '')

	setParams: (params) ->
		return if @_settingQueryString
		@savedFiltersDropdown.val('').trigger('liszt:updated')
		qs =  @paramsQueryString()
		for param in @_deparam(params)
			paramValue = encodeURIComponent(param.name)+'='+encodeURIComponent(param.value)
			paramValue = '' if param.value is '' or param.value is null
			match = qs.match(new RegExp("(#{encodeURIComponent(param.name)}=[^&]*)"))
			if match && match.length >= 2
				qs = qs.replace(match[1], paramValue)
			else
				qs += '&' + paramValue if paramValue
		@_setQueryString qs.replace(/&+/g, '&').replace('&$', '')

	_setQueryString: (qs) ->
		@_settingQueryString = true
		@_paramsQueryString = qs
		history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' + qs)
		@_filtersChanged(false)
		@_settingQueryString = false

	paramsQueryString: () ->
		@_paramsQueryString ||=
			if document.location.search
				document.location.search.replace(/^\?/, '')
			else if not @initialized && @options.defaultParams
				@options.defaultParams
			else
				''

	_saveFilters: () ->
		data = @paramsQueryString()
		if data
			$.get '/custom_filters/new.js', { custom_filter: { apply_to: @options.applyTo, filters: data } }
		false

	setCalendarHighlights: (highlights) ->
		@form.find('.dates-range-filter').datepick('setOption', 'daysHighlighted', highlights)
		@form.find('.dates-range-filter').datepick('update')

	_addCalendars: () ->
		@_previousDates = []

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
				dates[0] = if dates[0] then dates[0] else dates[1]
				if @initialized is true
					if @dateRange is false
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
						@_setCalendarDatesFromCalendar()
				else
					@calendar.find('.datepick-selected:first').addClass('first-selected')
					@calendar.find('.datepick-selected:last').addClass('last-selected')
				true
		}

		@customDatesFilter = $('<div class="custom-dates-inputs">').appendTo(@form).append(
			$('<div class="start-date">').append(
				$('<label for="custom_start_date">').text('Start date'),
				$('<input type="text" class="input-calendar date_picker disabled" id="custom_start_date" name="custom_start_date">').val('mm/dd/yyyy').datepicker
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
				$('<input type="text" class="input-calendar date_picker disabled" id="custom_end_date" name="custom_end_date">').val('mm/dd/yyyy').datepicker
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

		$('#custom_start_date, #custom_end_date').on 'input', (e) =>
			input = $(e.target)
			if input.val() == ''
				input.val('mm/dd/yyyy')
				input.addClass('disabled')
			else
				input.removeClass('disabled')

		$('#custom_start_date, #custom_end_date').on 'blur', (e) =>
			startDateInput = @customDatesFilter.find("[name=custom_start_date]")
			endDateInput = @customDatesFilter.find("[name=custom_end_date]")
			applyButton = @customDatesPanel.find("#apply-ranges-btn")
			if startDateInput.val() != 'mm/dd/yyyy' && endDateInput.val() != 'mm/dd/yyyy' && startDateInput.val() != '' && endDateInput.val() != ''
				applyButton.attr('disabled', false)
			else
				applyButton.attr('disabled', true)

		# So the custom date picker is not closed when chosing dates
		$('#ui-datepicker-div').on 'click', (e) =>
			if $('.select-ranges.open').length
				e.stopPropagation();

		@customDatesPanel = $('<div class="dates-pref">').appendTo(@form).append(
			$('<div class="dropdown select-ranges">').append(
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
		currentDates = @calendar.datepick('getDate')
		if currentDates.length < 2 ||
		   @_formatDate(currentDates[0]) != @_formatDate(startDate) ||
		   @_formatDate(endDate || startDate) != @_formatDate(currentDates[1])
			@calendar.datepick('setDate', [startDate, endDate || startDate])
		@

	setDates: (dates) ->
		dates[0] = @_parseDate(dates[0]) if dates.length > 0 && typeof dates[0] == 'string'
		dates[1] = @_parseDate(dates[1]) if dates.length > 0 && typeof dates[1] == 'string'

		if dates.length > 0 && dates[0]
			params = "start_date=#{@_formatDate(dates[0])}"
			if dates[0].toLocaleString() != dates[1].toLocaleString()
				params += "&end_date=#{@_formatDate(dates[1])}"
			else
				params += "&end_date="

		else
			params = 'start_date=&end_date='
		@setParams params
		@

	_deselectDates: ->
		matches = @paramsQueryString().match(/((start_date|end_date)=[^&]*)/g)
		if matches && matches.length > 0
			@_removeParams matches.join('&')

	_setCalendarDatesFromCalendar: () ->
		@setDates @calendar.datepick('getDate')


	_datesToString: (dates) ->
		if dates.length > 0 && dates[0]
			@_formatDate(dates[0]) + @_formatDate(dates[1])
		else
			''

	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],12,0,0)

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
		if @options.ytdDatesRange == '1'
			# Default YTD
			[new Date(new Date().getFullYear(), 0, 1), new Date()]
		else if @options.ytdDatesRange == '2'
			# Alternative YTD from July 1 to June 30
			date = new Date()
			y = date.getFullYear()
			if date.getMonth() > 5
				startDate = new Date(y, 6, 1)
				endDate = new Date(y + 1, 5, 30)
			else
				startDate = new Date(y - 1, 6, 1)
				endDate = new Date(y, 5, 30)

			[startDate, endDate]


	_filtersChanged: (updateState=true) ->
		return if @updatingFilters
		@updatingFilters = true
		data = @paramsQueryString()
		if @form.data('serializedData') != data
			@form.data('serializedData', data)
			if updateState
				history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' +@form.data('serializedData'));

			@_parseQueryString(data)

			@_loadPage(1)

			@element.trigger('filters:changed')
			if @options.onChange
				@options.onChange(@)

		data = null
		@updatingFilters = false
		@

	_getCustomFilters: () ->
		data = @form.serializeArray()
		p = ''
		custom_filter = $.grep(data, (p) ->
		  p.name is "custom_filter[]"
		)
		p = custom_filter[0].value.split('&id')[0] if custom_filter.length > 0

	buildParams: (params=[]) ->
		data = @_deparam(@paramsQueryString())
		for param in data
			params.push(param)
		params

	_deparam: (queryString) ->
		params = []
		if typeof queryString != 'undefined' and queryString
			queryString = queryString.substring(queryString.indexOf("?") + 1).split("&")
			pair = null
			decode = decodeURIComponent
			i = queryString.length
			while i > 0
				pair = queryString[--i].split("=")
				params.push {'name': decode(pair[0]), 'value': decode(pair[1])}
		params

	_loadingSpinner: () ->
		if @options.spinnerElement?
			@options.spinnerElement()
		else
			$('<li class="loading-spinner">').appendTo @listContainer


	_placeholderEmptyState: () ->
		message = '<p>There are no results matching the filtering criteria you selected.<br />Please select different filtering criteria.</p>'
		if @options.placeholderMessage?
			message = @options.placeholderMessage()
		if @options.placeholderElement?
			@options.placeholderElement(message)
		else
			$('<div class="placeholder-empty-state">').html(message).appendTo @listContainer

	reloadData: () ->
		@_loadPage 1
		@

	_loadPage: (page) ->
		return unless @doneLoading
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

		@jqxhr = $.ajax
			url: @options.source
			data: params,
			type: 'GET'
			success: (response, textStatus, jqXHR) =>
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

					if $response.find('div[data-content="filters-description"]').length > 0
						$('.collection-list-description .filter-label').html(
							$response.find('div[data-content="filters-description"]')
						).append(
							$('<a id="clear-filters" href="#" title="Reset">').text('Reset').on 'click', (e) =>
								@_resetFilters()
						);
					@marginFilterResize()

					$response.remove()
					$items.remove()
					$items = $response = null


				if @options.onPageLoaded
					@options.onPageLoaded page, resultsCount

				$.loadingContent -= 1
				true
			complete: () =>
				@spinner.remove()
				@spinner = null
				@doneLoading = true

		params = null
		true

	_pageLoaded: (page, response) ->
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
		dates = []
		selectedOptions = []

		for param in @_deparam(query)
			name = param.name
			value = param.value
			sliderMatch = name.match /(.+)\[(max|min)\]$/
			if @options.includeCalendars and value and name in ['start_date', 'end_date']
				if name is 'start_date' and value
					dates[0] = @_parseDate(value)
				else
					dates[1] = @_parseDate(value)
			else if sliderMatch && @sliders[sliderMatch[1]]
				if sliderMatch[2] is 'min'
					@sliders[sliderMatch[1]].rangeSlider 'values', parseInt(value, 10), @sliders[sliderMatch[1]].rangeSlider('values').max
				else
					@sliders[sliderMatch[1]].rangeSlider 'values', @sliders[sliderMatch[1]].rangeSlider('values').min, parseInt(value, 10)
			else
				checkbox = @form.find("input[name=\"#{param.name}\"][value=\"#{param.value}\"]:checkbox")
				if checkbox.length
					selectedOptions.push checkbox[0]
					$(checkbox).prop('checked', true).closest('li').slideUp()
				else
					field = @form.find("input[name=\"#{name}\"]:not(:checkbox)")
					if field.length > 0
						field.val(value)

		for name, slider of @sliders
			unless query.indexOf(encodeURIComponent("#{name}[min]")) > -1 || query.indexOf(encodeURIComponent("#{name}[max]")) > -1
				bounds = slider.rangeSlider("bounds")
				slider.rangeSlider 'values', bounds.min, bounds.max


		for checkbox in @form.find("input:checkbox:hidden").not(selectedOptions)
			$(checkbox).prop('checked', false).closest('li').show()


		if dates.length > 0
			@selectCalendarDates dates[0], dates[1]
		else
			@_deselectDates()
		dates = null

		query = null

	reloadFilters: () ->
		@loadFacets = true
		@_loadFilters()

	marginFilterResize: () ->
		marginTopFilter = $('.collection-list-description').outerHeight()
		extra = 0
		if $(".main-nav-collapse").is(":visible")
			marginTopFilter += $('.main-nav-collapse').outerHeight() + 8
			extra = 8
		$('#application-content').css('margin-top', marginTopFilter + 'px')
		$('#resource-close-details').css('top', marginTopFilter + 43 - extra)

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