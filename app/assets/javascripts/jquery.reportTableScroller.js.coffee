$.widget 'nmk.reportTableScroller',
	options: {
	},

	_create: () ->
		@offset = 1
		@count = 0
		@leftMargin

		@scroller = @element.closest('.report-inner')
		@header = $('<table>').attr('class', @element.attr('class')+' cloned').append(@element.find('thead').clone(true, true).css({position: 'absolute'})).css({
			position: 'absolute',
			top: @element.position().top,
			left: @element.position().left
		}).insertAfter(@scroller)

		@element.css marginTop: -@header.find('thead').outerHeight()
		@scroller.css marginTop: @header.find('thead').outerHeight()

		@element.on 'click', '.report-collapse-button', (e) =>
			$(e.target).toggleClass('icon-expand').toggleClass('icon-collapse')
			collapsed = $(e.target).hasClass('icon-expand')
			row = $(e.target).closest('tr')
			level = row.data('level')
			next = row.next('tr')
			while next.data('level') > level
				if collapsed
					next.hide().find('.icon-collapse').removeClass('icon-collapse').addClass('icon-expand')
				else if next.data('level') == level+1  # Only show/hide the inmediate children elements
					next.show()
				next = next.next('tr')
			@adjustHeader()
			false

		@header.find('.expand-all').tooltip('destroy').tooltip container: '#report-container'
		@header.on 'click', '.expand-all', (e) =>
			$(e.target).toggleClass('icon-expand').toggleClass('icon-collapse')
			if $(e.target).hasClass('icon-collapse') # Expand all
				$(e.target).attr('title', 'Collapse All').tooltip('destroy').tooltip container: 'body'
				@element.find('tbody tr[data-level]').show()
				@element.find('tbody tr[data-level] .icon-expand').removeClass('icon-expand').addClass('icon-collapse')
			else
				$(e.target).attr('title', 'Expand All').tooltip('destroy').tooltip container: 'body'
				@element.find('tbody tr[data-level!=0]').hide()
				@element.find('tbody tr[data-level] .icon-collapse').removeClass('icon-collapse').addClass('icon-expand')
			@adjustHeader()
			false


		@scroller.on 'scroll', (e) =>
			tablePosition = @header.position()
			inner = $(e.target)
			@header.find('thead').css({left: -inner.scrollLeft()})
			$(window).trigger 'scroll'
			true

		$(window).on 'resize.reportTableScroller', (e) =>
			@adjustTableSize()
			@adjustHeader()
			true

		@adjustTableSize()
		@adjustHeader()

		@

	_destroy: () ->
		window.off 'resize.reportTableScroller'

	adjustHeader: () ->
		headerCols = @header.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		tableCols = @element.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		for num in [0..tableCols.length]
			$(headerCols[num]).css width: $(tableCols[num]).width()
		@

	adjustTableSize: () ->
		maxHeight = $(window).height() - @scroller.offset().top - parseInt($('footer').css('margin-top')) - 30 - parseInt($('body').css('margin-top')) - $('footer').outerHeight()
		@scroller.css height: maxHeight

		difference =  ($('.sidebar').position().top+$('.sidebar').outerHeight()) - ($('.main').position().top+$('.main').outerHeight())

		if difference > 0
			@scroller.css height: maxHeight + difference
