$.widget 'nmk.filterBox', {
	options: {
		onChange: false,
		includeCalendars: false,
		includeSearchBox: true,
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

		if @options.includeCalendars
			@_addCalendars()

		@formFilters = $('<div class="form-facet-filters">').appendTo(@form)
		if @options.filters
			@setFilters(@options.filters)

		@_parseHashQueryString()

		@initialized = true

	getFilters: () ->
		@form.serializeArray()

	setFilters: (filters) ->
		@formFilters.html('')
		for filter in filters
			if filter.items.length > 0
				@addFilterSection(filter.label, filter.name, filter.items)

	addFilterSection: (title, name, items) ->
		$list = $('<ul>')
		$filter = $('<div class="filter-wrapper">').data('items', items).data('name', name).append($('<h3>').text(title), $list)
		i = 0
		optionsCount = items.length
		while i < 5 and i < optionsCount
			option = items[i]
			if option.count > 0
				$list.append(@_buildFilterOption(option, name).change( (e) => @_filtersChanged() ))
			i++
		if optionsCount > 5
			$filter.append($('<a>',{href: '#'}).text('More').click (e) =>
				filterWrapper = $(e.target).parents('div.filter-wrapper')
				@_showFilterOptions(filterWrapper)
				false
			)
		@formFilters.append($filter)

	_showFilterOptions: (filterWrapper) ->
		name = filterWrapper.data('name')
		items = []
		for option in filterWrapper.data('items')
			if option.count > 0 and filterWrapper.find('input:checkbox[value='+option.id+']').length == 0
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
		$('<li>').append($('<label>').append($('<input>',{type:'checkbox', value: option.id, name: "#{name}[]"}), option.label))

	_addSearchBox: () ->
		previousValue = '';
		@searchInput = $('<input type="text" name="with_text" class="search-query no-validate" placeholder="Search" id="search-box-filter">')
			.appendTo(@form)
			.on 'blur', () =>
				if @searchHidden.val()
					@searchInput.hide()
					@searchLabel.show()
		@searchInput.bucket_complete {
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
			.css('width', @searchInput.width()+'px').appendTo(@form).hide()
			.click =>
				@searchLabel.hide()
				@searchInput.show()
				@searchInput.focus()

	_getAutocompleteResults: (request, response) ->
		params = {q: request.term}
		$.get "/events/autocomplete", params, (data) ->
			response data
		, "json"

	_autoCompleteItemSelected: (item) ->
		@searchHidden.val "#{item.type},#{item.value}"
		@searchHiddenLabel.val item.label
		@searchInput.hide().val ''
		@searchLabel.show().find('span.term').text item.label
		@_filtersChanged()
		false

	_cleanSearchFilter: () ->
		@searchHidden.val ""
		@searchHiddenLabel.val ""
		@searchInput.show().val ""
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
		if @searchHidden.val()
			@searchInput.hide()
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