$.widget 'nmk.filterBox', {
	options: {
		onChange: false,
		includeCalendars: true
	},
	_create: () ->
		@form = $('<form action="#" method="get">').appendTo(@element);
		@form.data('serializedData', null)
		if @options.includeCalendars
			@_addCalendars()

	getFilters: () ->
		@form.serializeArray()

	describeFilters: () ->
		description = @_describeDateRange()

	_addCalendars: () ->
		@startDateInput = $('<input type="hidden" name="by_period[start_date]">').appendTo @form
		@endDateInput = $('<input type="hidden" name="by_period[end_date]">').appendTo @form
		container = $('<div class="dates-range-filter">').appendTo @element
		container.datepick {
			rangeSelect: true,
			monthsToShow: 2,
			changeMonth: false,
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
