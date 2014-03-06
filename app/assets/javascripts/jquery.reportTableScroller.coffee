$.widget 'nmk.reportTableScroller',
	options: {
	},

	_create: () ->
		@offset = 1
		@count = 0
		@cols = $('thead tr:first-child', @element).find('td,th')
		@leftMargin

		# Store the initial widths for each cell
		@element.css({width: 'auto'}) # Make the cells to take their "natural/minimun" width
		$.each @cols, (i, cell) =>
			$(cell).data 'width', $(cell).width()
			$(cell).data 'outer-width', $(cell).outerWidth()

		$('.report-arrows a').on 'click.reportTableScroller', (e) =>
			@adjustColumnsSize $(e.target).data('direction')
			false

		@adjustColumnsSize()
		@element.css({'table-layout': 'fixed'})

		$(window).off('resize.reportTableScroller').on 'resize.reportTableScroller', (e) =>
			@adjustColumnsSize()
			true

	_destroy: () ->
		$('.report-arrows a').off 'click.reportTableScroller'
		$(window).on 'resize.reportTableScroller', @adjustColumnsSize

	adjustColumnsSize: (direction=false) ->
		availableWidth = @element.parent().width()
		if direction is 'right' and (@offset+@count) >= @cols.length
			@offset = @cols.length
			direction = 'left'

		if direction is 'right'
			@offset = @offset+@count
			cols = @cols.get().slice(@offset)
		else if direction is 'left'
			return if this.offset is 1
			cols = @cols.get().slice(0, @offset).reverse()
		else
			cols = @cols.get().slice(@offset)

		width = @count = 0

		for cell in cols
			$cell = $(cell)
			if (availableWidth > width + $cell.data('outer-width')) and (this.offset > 1 or direction isnt 'left')
				width += $cell.data('outer-width')
				@count += 1
				@offset = if direction is 'left' then @offset-1 else @offset
			else
				break

		# If we got to the first cell, check if there are more cells that can fit
		if @offset is 1 and direction is 'left'
			for cell in @cols.get().slice(@offset+@count)
				$cell = $(cell)
				if availableWidth > width + $cell.data('outer-width')
					width += $cell.data('outer-width')
					@count += 1
				else
					break

		if @offset >= @cols.length-1
			for cell in @cols.get().slice(0, @offset).reverse()
				$cell = $(cell)
				if availableWidth > width + $cell.data('outer-width')
					width += $cell.data('outer-width')
					@count += 1
					@offset -= 1
				else
					break

		marginLeft = 0
		for cell in @cols.slice(1, @offset)
			marginLeft -= $(cell).outerWidth()

		@element.css {marginLeft: marginLeft+'px'}

		adjust = (availableWidth-width)/@count
		for cell in @cols.slice(@offset, (@offset+@count))
			$cell = $(cell)
			$cell.css({width: ($cell.data('width')+adjust)+ 'px'})

		if @offset is 1
			$('.report-arrows a[data-direction=left]').addClass 'disabled'
		else
			$('.report-arrows a[data-direction=left]').removeClass 'disabled'

		if (@offset+@count) is @cols.length
			$('.report-arrows a[data-direction=right]').addClass 'disabled'
		else
			$('.report-arrows a[data-direction=right]').removeClass 'disabled'

		true

