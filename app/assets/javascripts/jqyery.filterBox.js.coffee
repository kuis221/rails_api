$.widget 'nmk.filterBox', {
	options: {
		onChange: false,
		includeCalendars: false,
		includeSearchBox: true,
		filters: []
	},
	_create: () ->
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">').appendTo(@element).submit (e)->
			e.preventDefault()
			e.stopPropagation()
			false
		@form.data('serializedData', null)

		if @options.includeSearchBox
			@_addSearchBox()

		if @options.includeCalendars
			@_addCalendars()

		for filter in @options.filters
			@addFilterSection.apply @, filter


	getFilters: () ->
		@form.serializeArray()

	describeFilters: () ->
		description = @_describeDateRange()
		description += @_describeSearch()

	addFilterSection: (title, name, options) ->
		$list = $('<ul>')
		$filter = $('<div class="filter-wrapper">').data('options', options).data('name', name).append($('<h3>').text(title), $list)
		i = 0
		optionsCount = options.length
		while i < 5 and i < optionsCount
			option = options[i]
			$list.append(@_buildFilterOption(option, name).change( (e) => @_filtersChanged() ))
			i++
		if optionsCount > 5
			$filter.append($('<a>',{href: '#'}).text('More').click (e) =>
				filterWrapper = $(e.target).parents('div.filter-wrapper')
				@_showFilterOptions(filterWrapper)
				false
			)
		@form.append($filter)

	_showFilterOptions: (filterWrapper) ->
		name = filterWrapper.data('name')
		items = []
		for option in filterWrapper.data('options')
			if filterWrapper.find('input:checkbox[value='+option.id+']').length == 0
				items.push @_buildFilterOption(option, name).bind 'change.filter', (e) =>
					listItem = $(e.target).parents('li')
					listItem.unbind 'change.filter'
					listItem.change (e) => @_filtersChanged()
					filterWrapper.find('ul').append listItem
					listItem.effect 'highlight'
					listItem.trigger 'change'

		container = $('<div class="row-fluid filter-box">')
		if items.length >= 10
			itemsPerColumn = Math.ceil(items.length / 2)
			i = 0
			while i < items.length
				if i is itemsPerColumn or i is 0
					list = $('<ul>')
					column = $('<div class="span6">').appendTo(container).append(list)
				list.append items[i]
				i++
			list = container

		else
			list = $('<ul>').append(items).appendTo(container)
		list.find("input:checkbox").uniform()
		bootbox.modalClasses = 'modal-med'
		filterMoreOptions = bootbox.dialog(container,[{
			    "label" : "Close",
			    "class" : "btn-primary",
			    "callback": () ->
			        filterMoreOptions.modal('hide')
			}],{'onEscape': true})

	_buildFilterOption: (option, name) ->
		$('<li>').append($('<label>').append($('<input>',{type:'checkbox', value: option.id, name: "#{name}[]"}), option.name))

	_addSearchBox: () ->
		previousValue = '';
		@searchInput = $('<input type="text" name="with_text" class="search-query no-validate" placeholder="Search" id="search-box-filter">').appendTo @form
		@searchInput.keyup =>
			if @searchTimeout?
				clearTimeout @searchTimeout

			@searchTimeout = setTimeout =>
				if previousValue isnt @searchInput.val()
					previousValue = @searchInput.val()
					@_filtersChanged()
			, 300

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="by_period[start_date]" class="no-validate">').appendTo @form
		@endDateInput = $('<input type="hidden" name="by_period[end_date]" class="no-validate">').appendTo @form
		container = $('<div class="dates-range-filter">').appendTo @form
		container.datepick {
			rangeSelect: true,
			monthsToShow: 2,
			changeMonth: false,
			defaultDate: '05/20/2013',
			onSelect: (dates) =>
				start_date = @_formatDate(dates[0])
				@startDateInput.val start_date

				@endDateInput.val ''
				if dates[0].toLocaleString() != dates[1].toLocaleString()
					end_date = @_formatDate(dates[1])
					@endDateInput.val end_date

				@_filtersChanged()
		}

	_describeDateRange: () ->
		description = ''
		startDate = @startDateInput.val()
		endDate = @endDateInput.val()
		if startDate
			currentDate = new Date()
			today = new Date(currentDate.getFullYear(), currentDate.getMonth() , currentDate.getDate(), 0, 0, 0);
			yesterday = new Date(today.getFullYear(), today.getMonth() , today.getDate()-1, 0, 0, 0);
			tomorrow = new Date(today.getFullYear(), today.getMonth() , today.getDate()+1, 0, 0, 0);
			startDateLabel = if startDate == @_formatDate(today) then 'today' else if startDate == @_formatDate(yesterday) then 'yesterday' else if startDate == @_formatDate(tomorrow) then 'tomorrow' else startDate
			endDateLabel = if endDate == @_formatDate(today) then 'today' else if endDate == @_formatDate(yesterday) then 'yesterday' else if endDate == @_formatDate(tomorrow) then 'tomorrow' else endDate

			if startDate and endDate and (startDate != endDate)
				if @_parseDate(endDate) < today
					description = "took place between #{startDateLabel} and #{endDateLabel}"
				else
					description = "taking place between #{startDateLabel} and #{endDateLabel}"
			else if startDate
				if startDate == startDateLabel
					startDateLabel = "at #{startDateLabel}"
				if startDate == @_formatDate(today)
					description = "taking place today"
				else if @_parseDate(startDate) > today
					description = "taking place #{startDateLabel}"
				else
					description = "took place #{startDateLabel}"

		description

	_describeSearch: () ->
		description = ''
		if @searchInput.val()
			description = " matching \"#{@searchInput.val()}\""
		description

	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],0,0,0)

	_filtersChanged: () ->
		if @options.onChange and @form.data('serializedData') != @form.serialize()
			@form.data('serializedData', @form.serialize())
			@options.onChange(@)
}
