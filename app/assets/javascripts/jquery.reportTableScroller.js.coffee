$.widget 'nmk.reportTableScroller',
	options: {
		useScrollerPuglin: true
	},

	_create: () ->
		@offset = 1
		@count = 0
		@leftMargin

		@scroller = @element.closest('.report-inner')

		@scroller.jScrollPane() if @options.useScrollerPuglin

		@header = $('<table>').attr('class', @element.attr('class')+' cloned').css
			position: 'absolute',
			top: @element.position().top,
			left: @element.position().left
		.insertAfter(@scroller)
		@rebuildHeader()

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


		unless @options.useScrollerPuglin
			@scroller.on 'scroll', (e) =>
				@header.find('thead').css({left: -$(e.target).scrollLeft()})
				$(window).trigger 'scroll'
				true
		else
			@scroller.on 'jsp-scroll-x', (e) =>
				@header.find('thead').css left: '-' + @scroller.data('jsp').getContentPositionX() + 'px'
				true

		$(window).on 'resize.reportTableScroller, alert:missed.reportTableScroller', (e) =>
			clearTimeout window.reportTableResizerTimeout if window.reportTableResizerTimeout?

			window.reportTableResizerTimeout = window.setTimeout =>
				if $.loadingContent is 0
					@adjustTableSize()
					@adjustHeader()
					@resetScroller()
					true
			, 20

		$(window).on 'form_builder_sidebar:resize', () =>
			@adjustTableSize()

		@adjustTableSize()
		@adjustHeader()
		@resetScroller()

		@

	destroy: () ->
		window.off 'resize.reportTableScroller, alert:missed.reportTableScroller'

	rebuildHeader: () ->
		@header.find('thead').remove().end().append(
			@element.find('thead').clone(true, true).css({position: 'absolute'})
		)

	adjustHeader: () ->
		headerCols = @header.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		tableCols = @element.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		for num in [0..tableCols.length]
			$(headerCols[num]).css width: $(tableCols[num]).width()
		@

	adjustTableSize: () ->
		if @element.height() is 0
			@scroller.css height: 'auto'
			@element.hide()
		else
			@element.show()
			maxHeight = $(window).height() + $(document).scrollTop() + parseInt(@scroller.css('margin-top')) - @scroller.offset().top - parseInt($('footer').css('margin-top')) - 85 - parseInt($('body').css('margin-top')) - $('footer').outerHeight()
			@scroller.css height: maxHeight
			difference =  ($('.sidebar').position().top+$('.sidebar').outerHeight()) - ($('.main').position().top+$('.main').outerHeight())

			difference =  ($('.sidebar').position().top+$('.sidebar').outerHeight()) - ($('.main').position().top+$('.main').outerHeight())
			@scroller.css height: maxHeight + difference if difference > 0

			difference =  ($('.main').position().top+parseInt($('.main').css('min-height'))-parseInt($('.main').css('padding-bottom'))) - (@scroller.offset().top+@scroller.outerHeight())
			@scroller.css height: @scroller.height() + difference if difference > 0


	resetScroller: () ->
		scrollerApi = @scroller.data('jsp')
		scrollerApi.reinitialise()
