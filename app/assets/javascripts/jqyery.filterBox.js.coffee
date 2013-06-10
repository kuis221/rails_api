$.widget 'nmk.filterBox', {
	options: {
		onChange: false,
		includeCalendars: false,
		includeSearchBox: true,
		includeAutoComplete: false,
		selectDefaultDate: false,
		filters: null
	},

	_create: () ->
		@element.addClass('filter-box')
		@form = $('<form action="#" method="get">')
			.appendTo(@element).submit (e)->
				e.preventDefault()
				e.stopPropagation()
				false
		@form.data('serializedData', null)


		if @options.includeSearchBox
			@_addSearchBox()

		if @options.includeAutoComplete
			@_addAutocompleteBox()

		if @options.includeCalendars
			@_addCalendars()

		@formFilters = $('<div class="form-facet-filters">').appendTo(@form)
		if @options.filters
			@setFilters(@options.filters)

		@filtersPopup = false

		@_parseHashQueryString()

		$(window).on 'resize', () =>
			if @filtersPopup
				@_positionFiltersOptions()

		@initialized = true

	destroy: ->
		@_closeFilterOptions()

	getFilters: () ->
		@form.serializeArray()

	setFilters: (filters) ->
		@formFilters.html('')
		for filter in filters
			if filter.items.length > 0
				@addFilterSection(filter.label, filter.name, filter.items)

	addFilterSection: (title, name, items) ->
		$list = $('<ul>')
		$filter = $('<div class="filter-wrapper">').data('name', name).append($('<h3>').text(title), $list)
		i = 0
		optionsCount = items.length
		first5 = []
		while i < 5 and i < optionsCount
			option = items[i]
			if option.count > 0
				first5.push option
			i++

		for option in @_sortOptionsAlpha(first5)
			$list.append(@_buildFilterOption(option).change( (e) => @_filtersChanged() ))

		if optionsCount > 5
			$filter.append($('<a>',{href: '#'}).text('More').click (e) =>
				filterWrapper = $(e.target).parents('div.filter-wrapper')
				@_showFilterOptions(filterWrapper)
				false
			)
		items = @_sortOptionsAlpha(items);
		$filter.data('items', items)
		@formFilters.append($filter)

	_sortOptionsAlpha: (options) ->
		a = options.sort (a, b) ->
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
		a

	_showFilterOptions: (filterWrapper) ->
		if @filtersPopup
			@_closeFilterOptions()

		name = filterWrapper.data('name')
		items = []
		for option in filterWrapper.data('items')
			if option.count > 0 and filterWrapper.find('input:checkbox[value='+option.id+']').length == 0
				items.push @_buildFilterOption(option)
				.bind 'click', (e) =>
					e.stopPropagation()
				.bind 'change.filter', (e) =>
					listItem = $(e.target).parents('li')
					listItem.unbind 'change.filter'
					listItem.change (e) => @_filtersChanged()
					filterWrapper.find('ul').append listItem
					listItem.find('.checker').show()
					listItem.effect 'highlight'
					listItem.trigger 'change'

		@filtersPopup = $('<div class="filter-box more-options-popup">').appendTo $('body')
		list = $('<ul>').append(items).appendTo @filtersPopup
		list.find("input:checkbox").uniform()
		bootbox.modalClasses = 'modal-med'
		@filtersPopup.data('wrapper', filterWrapper).css {
			'position': 'fixed',
			'top': '150px'
		}

		$(document).on 'click.filterbox', ()  => @_closeFilterOptions()

		@_positionFiltersOptions()

	_positionFiltersOptions: () ->
		@filtersPopup.css {
			'left': @filtersPopup.data('wrapper').offset().left - @filtersPopup.width(),
			'max-height': ($(window).height()-200) + 'px'
		}

	_closeFilterOptions: () ->
		if @filtersPopup
			@filtersPopup.remove()
		$(document).off 'click.filterbox'

	_buildFilterOption: (option) ->
		$('<li>').append($('<label>').append($('<input>',{type:'checkbox', value: option.id, name: "#{option.name}[]", checked: (option.selected is true or option.selected is 'true')}), option.label))

	_addSearchBox: () ->
		previousValue = '';
		@searcInput = $('<input type="text" name="t" class="search-query no-validate" placeholder="Search" id="search-box-filter">').appendTo @form
		@searcInput.keyup =>
			if @searchTimeout?
				clearTimeout @searchTimeout

			@searchTimeout = setTimeout =>
				if previousValue isnt @searcInput.val()
					previousValue = @searcInput.val()
					@_filtersChanged()
			, 300

	_addAutocompleteBox: () ->
		previousValue = '';
		@acInput = $('<input type="text" name="ac" class="search-query no-validate" placeholder="Search" id="search-box-filter">')
			.appendTo(@form)
			.on 'blur', () =>
				if @searchHidden.val()
					@acInput.hide()
					@searchLabel.show()
		@acInput.bucket_complete {
			source: @_getAutocompleteResults,
			select: (event, ui) =>
				@_autoCompleteItemSelected(ui.item)
			minLength: 2
		}
		@searchHiddenLabel = $('<input type="hidden" name="ql">').appendTo(@form).val('')
		@searchHidden = $('<input type="hidden" name="q">').appendTo(@form).val('')
		@searchLabel = $('<div class="search-filter-label">')
			.append($('<span class="term">'))
			.append($('<span class="close">').append($('<i class="icon-remove">').click => @_cleanSearchFilter()))
			.css('width', @acInput.width()+'px').appendTo(@form).hide()
			.click =>
				@searchLabel.hide()
				@acInput.show()
				@acInput.focus()

	_getAutocompleteResults: (request, response) ->
		params = {q: request.term}
		$.get "/events/autocomplete", params, (data) ->
			response data
		, "json"

	_autoCompleteItemSelected: (item) ->
		@searchHidden.val "#{item.type},#{item.value}"
		@searchHiddenLabel.val item.label
		@acInput.hide().val ''
		@searchLabel.show().find('span.term').text item.label
		@_filtersChanged()
		false

	_cleanSearchFilter: () ->
		@searchHidden.val ""
		@searchHiddenLabel.val ""
		@acInput.show().val ""
		@searchLabel.hide().find('span.term').text ''
		@_filtersChanged()
		false

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="start_date" class="no-validate">').appendTo @form
		@endDateInput = $('<input type="hidden" name="end_date" class="no-validate">').appendTo @form
		container = $('<div class="dates-range-filter">').appendTo @form
		container.datepick {
			rangeSelect: true,
			monthsToShow: 2,
			changeMonth: false,
			defaultDate: new Date(),
			selectDefaultDate: @options.selectDefaultDate,
			onSelect: (dates) =>
				start_date = @_formatDate(dates[0])
				@startDateInput.val start_date

				@endDateInput.val ''
				if dates[0].toLocaleString() != dates[1].toLocaleString()
					end_date = @_formatDate(dates[1])
					@endDateInput.val end_date

				if @initialized?
					@_filtersChanged()
		}


	_formatDate: (date) ->
		"#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

	_parseDate: (date) ->
		parts = date.split('/')
		new Date(parts[2], parseInt(parts[0])-1, parts[1],0,0,0)

	_filtersChanged: () ->
		if @options.onChange and @form.data('serializedData') != @form.serialize()
			@form.data('serializedData', @form.serialize())
			document.location.hash = @form.data('serializedData')
			@options.onChange(@)

	_parseHashQueryString:  () ->
		query = window.location.hash.replace(/^#/,"")
		vars = query.split('&')
		dates = [new Date()]
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
				name = name.replace(/([\[\]])/g,'\\$1')
				if field = @form.find("[name=#{name}]")
					if field.attr('type') == 'checkbox'
						console.log('checking checkboxes not implemented yet!!')
					else
						field.val(value)
		@form.find('.dates-range-filter').datepick('setDate', dates)
		if @searchHidden and @searchHidden.val()
			@acInput.hide()
			@searchLabel.show().find('.term').text @searchHiddenLabel.val()
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
			.append( $( "<a>" ).text( item.label ) )
			.appendTo( ul )
}