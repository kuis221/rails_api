$.widget 'nmk.filteredList', {
	options: {
		source: false,
		filtersUrl: false,
		autoLoad: true,
		filters: false,
		onChange: false,
		includeCalendars: false,
		includeAutoComplete: false,
		autoCompletePath: '',
		defaultParams: [],
		customFilters: [],
		selectDefaultDate: false,
		selectedDate: new Date(),
		selectDefaultDateRange: false,
		calendarHighlights: null
	},

	_create: () ->
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">')
			.appendTo(@element).submit (e)->
				e.preventDefault()
				e.stopPropagation()
				false
		@form.data('serializedData', null)

		@nextpagetoken  = false

		if @options.includeAutoComplete
			@_addAutocompleteBox()

		if @options.includeCalendars
			@_addCalendars()

		$('<div class="clear-filters">')
			.append($('<a>',{href: '#', class:''}).text('Clear filters')
				.on 'click', (e) =>
					@initialized = false
					@defaultParams = []
					@_cleanSearchFilter()
					@_deselectDates()
					@element.find('input[type=checkbox]').attr('checked', false)
					@_filtersChanged()
					@initialized = true
					false
			).appendTo(@form)


		@formFilters = $('<div class="form-facet-filters">').appendTo(@form)
		if @options.filters
			@setFilters(@options.filters)

		@filtersPopup = false

		@listContainer = $(@options.listContainer)

		@defaultParams = @options.defaultParams
		@_parseQueryString()
		@loadFacets = true
		firstTime = true
		$(window).on 'popstate', =>
			if firstTime
				firstTime = false
			else
				@reloadFilters()
				@_parseQueryString()
				@_filtersChanged(false)

		$(window).on 'resize scroll', () =>
			if @filtersPopup
				@_positionFiltersOptions()

		@infiniteScroller = false

		if @options.autoLoad
			@_loadPage(1)

		@_loadFilters()

		@defaultParams = []
		@initialized = true

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
		@form.find('.dates-range-filter').datepick('clear')
		@form.find('.dates-range-filter').datepick('update')

	getFilters: () ->
		p = @form.serializeArray()
		for param in @defaultParams
			p.push param

		for param in @options.customFilters
			p.push param

		if @loadFacets
			p.push {'name': 'facets', 'value': true}
			@loadFacets=false
		p

	setFilters: (filters) ->
		@formFilters.html('')
		for filter in filters
			if filter.items? and (filter.items.length > 0 or (filter.top_items? and filter.top_items.length))
				@addFilterSection filter
			else if filter.max? and filter.min?
				@addSlider filter


	addSlider: (filter) ->
		min_value = if filter.selected_min? then filter.selected_min else filter.min
		max_value = if filter.selected_max? then filter.selected_max else filter.max
		min_value = Math.min(min_value, filter.max)
		max_value = Math.min(max_value, filter.max)
		$slider = $('<div class="slider-range">')
		$filter = $('<div class="filter-wrapper">').data('name', filter.name).append(
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
			$filter.find('input.min').val Math.round(data.values.min)
			$filter.find('input.max').val Math.round(data.values.max)
			@_filtersChanged()

		if max_value == min_value
			$filter.find('input.min').val min_value


		@formFilters.append($filter)


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
		$filter = $('<div class="filter-wrapper">').data('name', filter.name).append($('<h3>').text(filter.label), $list)
		i = 0
		if not top5
			optionsCount = items.length
			top5 = []
			while i < optionsCount
				option = items[i]
				if option.count > 0 and (i < 5 or option.selected)
					top5.push option
				i++
		else
			optionsCount = top5.length + items.length

		for option in @_sortOptionsAlpha(top5)
			$list.append @_buildFilterOption(option).change( (e) => @_filtersChanged() )

		@formFilters.append($filter)
		if optionsCount > 5
			$ul = $('<ul class="sf-menu sf-vertical">')
			$trigger = $('<a>',{href: '#', class:'more-options-link'}).text('More')
				.on 'click', (e) =>
					false
				.on 'mouseover.firstime', (e)=>
					$(e.target).off('mouseover.firstime')
					if not $ul.hasClass('sf-js-enabled')
						list = @_buildFilterOptionsList(filter, $filter)
						$ul.find('li').append(list)
						$trigger.superfish({cssArrows: false, disableHI: true})
						$trigger.superfish('show')
					false
				.on ''
			$('<div>').append($ul.append($('<li>').append($trigger))).insertAfter($filter)

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
				if (option.count > 0 or (option.items? and option.items.length)) and
				filterWrapper.find('input:checkbox[name^="'+option.name+'"][value="'+option.id+'"]').length == 0
					$option = @_buildFilterOption(option)
					group = if option.group then option.group else '__default__'
					items[group] ||= []
					items[group].push $option
					$option.bind 'click.filter', (e) =>
						e.stopPropagation()
						true
					.find('input[type=checkbox]').bind 'change.filter', (e) =>
						$checkbox = $(e.target)
						listItem = $($(e.target).parents('li')[0])
						listItem.find('ul').remove()
						$checkbox.unbind 'change.filter'
						listItem.unbind 'click.filter'
						$checkbox.change (e) => @_filtersChanged()
						listItem.find('.checker').show()
						@_filtersChanged()
						$checkbox.attr('checked', true)
						parentList = $(listItem.parents('ul')[0])
						filterWrapper.find('ul').append listItem
						if parentList.find('li').length == 0
							parentList.remove()
						listItem.effect 'highlight'

						# if @filtersPopup.find('li').length == 0
						# 	@_closeFilterOptions()
						# 	filterWrapper.find('.more-options-link').remove()
					if child = @_buildFilterOptionsList(option, filterWrapper)
						$option.append child

			$list = $('<ul>')
			for group, children of items
				if children.length > 0
					if group isnt '__default__'
						$list.append $('<li class="options-list-group">').text(group)
					$list.append children
		$list


	_buildFilterOption: (option) ->
		$('<li>').append($('<label>').append($('<input>',{type:'checkbox', value: option.id, name: "#{option.name}[]", checked: (option.selected is true or option.selected is 'true')}), option.label))


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
				@reloadFilters()
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
		@searchHidden.val "#{item.type},#{item.value}"
		cleanedLabel = item.label.replace(/(<([^>]+)>)/ig, "");
		@searchHiddenLabel.val cleanedLabel
		@acInput.hide().val ''
		@searchLabel.show().find('span.term').html cleanedLabel
		@_filtersChanged()
		false

	_cleanSearchFilter: () ->
		if @searchHidden
			@searchHidden.val ""
			@searchHiddenLabel.val ""
			@acInput.show().val ""
			@searchLabel.hide().find('span.term').text ''

		if @initialized
			@reloadFilters()

		false

	setCalendarHighlights: (highlights) ->
		@form.find('.dates-range-filter').datepick('setOption', 'daysHighlighted', highlights)
		@form.find('.dates-range-filter').datepick('update')

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="start_date" class="no-validate">').appendTo @form
		@endDateInput = $('<input type="hidden" name="end_date" class="no-validate">').appendTo @form
		container = $('<div class="dates-range-filter">').appendTo @form
		container.datepick {
			rangeSelect: true,
			monthsToShow: 1,
			changeMonth: false,
			defaultDate: (if @options.selectDefaultDate then @options.selectedDate else null),
			selectDefaultDate: @options.selectDefaultDate,
			prevText: '<',
			nextText: '>',
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
								'<div class="datepick-clear-fix"></div></div>'}),
			onSelect: (dates) =>
				if dates.length > 0
					start_date = @_formatDate(dates[0])
					@startDateInput.val start_date

					@endDateInput.val ''
					if dates[0].toLocaleString() != dates[1].toLocaleString()
						end_date = @_formatDate(dates[1])
						@endDateInput.val end_date
				else
					@startDateInput.val ''
					@endDateInput.val ''

				if @initialized == true
					@reloadFilters()
					@_filtersChanged()
		}

		if @options.selectDefaultDateRange
			start_date = @_findDefaultParam('start_date')
			end_date = @_findDefaultParam('end_date')
			if start_date.length > 0 && end_date.length > 0
				@selectCalendarDates start_date[0].value, end_date[0].value

	selectCalendarDates: (start_date, end_date) ->
		@element.find('.dates-range-filter').datepick('setDate', [start_date, end_date])

	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],0,0,0)

	_filtersChanged: (updateState=true) ->
		@nextpagetoken = false
		if @options.source
			@reloadData
		data = @_serializeFilters()
		if @form.data('serializedData') != data
			@form.data('serializedData', data)
			@_loadPage(1)
			if updateState
				history.pushState('data', '', document.location.protocol + '//' + document.location.host + document.location.pathname + '?' +@form.data('serializedData'));

			@element.trigger('filters:changed')
			if @options.onChange
				@options.onChange(@)

	_serializeFilters: () ->
		data = @form.serialize()
		for filter in @options.customFilters
			data += "&#{filter.name}=#{escape(filter.value)}"
		data.replace(/^&/,"")

	buildParams: (params=[]) ->
		if @nextpagetoken
			params = [{name: 'page', value: @nextpagetoken }]
		else
			data = @getFilters()
			for param in data
				params.push(param)
		params

	paramsQueryString: () ->
		quertyString = join = ""
		for param in @buildParams()
			quertyString += "#{join}#{param.name}=#{escape(param.value)}"
			join = '&'

		quertyString

	reloadData: () ->
		@nextpagetoken = false
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

		@doneLoading = false
		if page is 1
			if @infiniteScroller
				@listContainer.infiniteScrollHelper 'resetPageCount'
			@listContainer.html ''
		@listContainer.append $('<li class="loading-spinner">');

		@jqxhr = $.get @options.source, params, (response) =>
			@listContainer.find('.loading-spinner').remove();
			$response = $('<div>').append(response)
			$items = $response.find('div[data-content="items"]')
			if @options.onItemsLoad
				@options.onItemsLoad($response, page)

			@listContainer.append($items.html())

			@_pageLoaded(page, $items)

		true

	_pageLoaded: (page, response) ->
		@doneLoading = true
		if @options.onItemsChange
			@options.onItemsChange(response)

		@nextpagetoken = response.data('next-page-token')
		if page == 1
			@totalPages = response.data('pages')

			if (@totalPages > 1 || @nextpagetoken)  and !@infiniteScroller
				@infiniteScroller = @listContainer.infiniteScrollHelper {
					loadMore: (page) =>
						if (page <= @totalPages || @nextpagetoken) && @doneLoading
							@_loadPage(page)
						else
							false

					doneLoading: =>
						@doneLoading
				}
			else if @totalPages <= page and @infiniteScroller
				@listContainer.infiniteScrollHelper 'destroy'
				@infiniteScroller = false

	_parseQueryString: () ->
		@initialized = false
		@_cleanSearchFilter()
		query = window.location.search.replace(/^\?/,"")
		if query != ''
			@defaultParams = []
			vars = query.split('&')
			dates = []
			for qvar in vars
				pair = qvar.split('=')
				name = decodeURIComponent(pair[0])
				value = decodeURIComponent((if pair.length>=2 then pair[1] else '').replace(/\+/g, '%20'))
				if @options.includeCalendars and value and name in ['start_date', 'end_date']
					date = @_parseDate(value)
					if name is 'start_date' and value
						dates[0] = date
					else
						dates[1] = date
				else
					field = @form.find("[name=\"#{name}\"]")
					if field.length
						if field.attr('type') == 'checkbox'
							console.log('checking checkboxes not implemented yet!!')
						else
							field.val(value)
					else
						@defaultParams.push {'name': name, 'value': value}

			if dates.length > 0
				@form.find('.dates-range-filter').datepick('setDate', dates)
			else
				@_deselectDates()
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
