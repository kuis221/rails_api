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


		@scroller.on 'scroll', (e) =>
			tablePosition = @header.position()
			inner = $(e.target)
			@header.find('thead').css({left: -inner.scrollLeft()})
			$(window).trigger 'scroll'
			true

		$(window).on 'resize.reportTableScroller', (e) =>
			@adjustTableSize()

		@adjustTableSize()

		@

	_destroy: () ->
		window.off 'resize.reportTableScroller'

	adjustHeader: () ->
		headerCols = @header.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		tableCols = @element.find('thead>tr:first-child>td, thead>tr:first-child>th').get()
		for num in [1..tableCols.length]
			$(headerCols[num]).css width: $(tableCols[num]).width()
		@

	adjustTableSize: () ->
		maxHeight = $(window).height() - @scroller.offset().top - parseInt(@scroller.css('margin-top')) - parseInt($('body').css('padding-top')) - parseInt($('body').css('margin-top')) - $('footer').outerHeight()
		@scroller.css height: maxHeight
