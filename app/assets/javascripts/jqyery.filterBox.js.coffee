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

		$(window).on 'resize scroll', () =>
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
			if filter.items.length > 0 or (filter.top_items? and filter.top_items.length)
				@addFilterSection filter

	addFilterSection: (filter) ->
		items = filter.items
		top5 = filter.top_items
		$list = $('<ul>')
		$filter = $('<div class="filter-wrapper">').data('name', filter.name).append($('<h3>').text(filter.label), $list)
		i = 0
		if not top5
			optionsCount = items.length
			top5 = []
			while i < 5 and i < optionsCount
				option = items[i]
				if option.count > 0
					top5.push option
				i++
		else
			optionsCount = top5.length + items.length

		for option in @_sortOptionsAlpha(top5)
			$list.append(@_buildFilterOption(option).change( (e) => @_filtersChanged() ))

		if optionsCount > 5
			$filter.append($('<a>',{href: '#', class:'more-options-link'}).text('More').click (e) =>
				e.preventDefault()
				filterWrapper = $(e.target).parents('div.filter-wrapper')
				@_showFilterOptions(filterWrapper)
				false
			)
		items = @_sortOptionsAlpha(items);
		$filter.data('filter', filter)
		@formFilters.append($filter)

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

			$(document).on 'click.filterbox', ()  => @_closeFilterOptions()

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
		$(document).off 'click.filterbox'

	_buildFilterOptionsList: (list, filterWrapper) ->
		$list = null
		if list? and list.items.length
			items = []
			for option in list.items
				if (option.count > 0 or (option.items? and option.items.length)) and
				filterWrapper.find('input:checkbox[name^="'+option.name+'"][value="'+option.id+'"]').length == 0
					$option = @_buildFilterOption(option)
					items.push $option
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
						filterWrapper.find('ul').append listItem
						listItem.effect 'highlight'
						if @filtersPopup.find('li').length == 0
							@_closeFilterOptions()
							filterWrapper.find('.more-options-link').remove()
					if child = @_buildFilterOptionsList(option, filterWrapper)
						$option.append child

			if items.length > 0
				$list = $('<ul>').append(items)
		$list


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