
# these are the days of the week for each month, in order
cal_days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
cal_months_labels = ['January', 'February', 'March', 'April',
                     'May', 'June', 'July', 'August', 'September',
                     'October', 'November', 'December']
cal_days_labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

$.widget 'nmk.eventsCalendar', {
	options: {
		month: null,
		year: null,
		events: null
	},

	_create: () ->
		@element.addClass('eventsCalendar')

		cal_current_date = new Date()
		@month = if (isNaN(@options.month) || @options.month == null) then cal_current_date.getMonth() else @options.month
		@year  = if (isNaN(@options.year) || @options.year == null) then cal_current_date.getFullYear() else @options.year

		@_drawCalendar()

	_drawCalendar: () ->
		# get first day of the calendar
		firstDay = new Date(@year, @month, 1)
		startingDay = firstDay.getDay()
		diff = if startingDay == 0 then 0 else startingDay * -1
		currentDay = new Date(firstDay.setDate(diff))

		# find number of days in month
		monthLength = cal_days_in_month[@month]

		# compensate for leap year
		if (@month == 1) # February only!
			if((@year % 4 == 0 && @year % 100 != 0) || @year % 400 == 0)
				monthLength = 29;

		# do the header
		monthName = cal_months_labels[@month]
		html = '<table class="calendar-table">'
		html += '<tr><th colspan="7">';
		html +=  monthName + "&nbsp;" + @year
		html += '</th></tr>'
		html += '<tr class="calendar-header">'
		for i in [0..6]
			html += '<td class="calendar-header-day">'
			html += cal_days_labels[i]
			html += '</td>'
		html += '</tr><tr>'

		# fill in the days
		# this loop is for is weeks (rows)
		for i in [0..8]
			# this loop is for weekdays (cells)
			for j in [0..6]
				html += '<td class="calendar-day">';
				html += currentDay.getDate()
				currentDay = new Date(currentDay.getFullYear(), currentDay.getMonth(), currentDay.getDate()+1)
				html += '</td>'

			if currentDay.getMonth() != @month
				break
			else
				html += '</tr><tr>'

		html += '</tr></table>'

		@element.html html

		# if @options.events
		# 	@_loadEvents()

		@

	# _loadEvents: () ->
	# 	$.get(@options.events, {start: , end: })

}
