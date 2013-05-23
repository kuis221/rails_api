$.widget 'nmk.tableScroller', {
	options: {
		source: null,
		buildParams: null,
		onItemsChange: null,
		fixedHeader: false,
		headerOffset: 0,
		onClick: null,
		actionButtons: ['editable', 'activable'],
		includeActionButtons: true
	},
	_create: () ->
		@loadedItems = 0
		@items = []
		@window = $(window)  # Cache
		@element.addClass('tableScroller')

		@element.find('th[data-sort]').addClass('sorting').on 'tableScroller.click', (e) =>
			@sortBy(e.target)

		if @options.onClick
			@element.on 'tableScroller.click', 'a', (e) =>
				e.preventDefault();
				row = $(e.target).parents('tr')[0]
				@options.onClick(row, $(row).data('item'))

		@sortBy @element.find('thead th:first-child')[0], false


		@element.infiniteScrollHelper {
			loadMore: (page) =>
				if @totalItems > @loadedItems
					@_loadPage(page)
				else
					false

			doneLoading: =>
				@doneLoading
		}

		if @options.fixedHeader
			@buildFixedHeader()

		@_loadPage(1)
		@

	buildFixedHeader: ->
		@info = $('<div>').css({position: 'absolute', 'top':'0', 'left':0, 'z-index': 9999}).appendTo($('body'))
		@fixedHeader = @element.clone(true, true).addClass('table-cloned-fixed-header').appendTo($('body')) #.affix({y: 50})
		@fixedHeader.css {'visibility': 'hidden','margin': '0', 'position':'fixed'}
		@_synchHeaderWidths()
		@window.resize =>
			@_synchHeaderWidths()
		.scroll =>
			@_placeHeaderPosition()


	disableScrolling: ->
		@element.infiniteScrollHelper 'disableScrolling'

	enableScrolling: ->
		@element.infiniteScrollHelper 'enableScrolling'

	destroy: ->
		@element.infiniteScrollHelper 'destroy'
		@element.on 'tableScroller.click'

		@element.find('th[data-sort]').removeClass('sorting sorting_asc sorting_desc' ).on 'tableScroller.click'

		if @options.fixedHeader
			@fixedHeader.remove()

	_synchHeaderWidths: ->
		@_placeHeaderPosition()
		@fixedHeader.css {'width':@element.outerWidth()+'px'}
		originalHead = @element.find('th')
		copyHead = @fixedHeader.find('th')
		for i in [0..originalHead.length]
			$h = $(originalHead[i])
			$(copyHead[i]).width($h.width())

	_placeHeaderPosition: ->
		offset = @element.offset()
		if @window.scrollTop() + @options.headerOffset > offset.top
			offset.top = @window.scrollTop() + @options.headerOffset
			@fixedHeader.css({'visibility': 'visible', 'top': "#{@options.headerOffset}px", 'left': offset.left+'px'})
		else
			@fixedHeader.css({'visibility': 'hidden'})

	sortBy: (cell, loadData=true) ->
		position = 0
		for aTh in $(cell).parents('tr').find('th')
			if aTh is cell
				break;
			position+=1

		@element.find('thead th[data-sort]').removeClass('sorting_asc sorting_desc').addClass('sorting')
		if (@sortedBy == position)
			@sorting_dir = if @sorting_dir == 'desc' then 'asc' else 'desc'
		else
			@sorting_dir = 'asc'
		@sortedBy = position
		@sorting = @element.find('thead th:nth-child('+(position+1)+')').removeClass('sorting').addClass('sorting_'+@sorting_dir).data('sort')

		if @fixedHeader
			originalHead = @element.find('th')
			copyHead = @fixedHeader.find('th')
			for i in [0..originalHead.length-1]
				copyHead[i].className = originalHead[i].className

		if loadData
			@reloadData()

	reloadData: () ->
		@loadedItems = 0
		@items = []
		@element.find('tbody').html ''
		@element.infiniteScrollHelper 'resetPageCount'
		@_loadPage 1
		@

	_loadPage: (page) ->
		params = [{'name': 'page', 'value': page}, {'name':'sorting','value':@sorting},{'name':'sorting_dir','value':@sorting_dir}]
		if @options.buildParams
			params = @options.buildParams(params)

		@doneLoading = false
		$.getJSON @options.source, params,  (json) =>
			@totalItems = json.total
			@loadedItems += json.items.length
			for row in json.items

				values = @_getRowValues(row)

				$row = $('<tr>', {id: @_rowId(row)})
				$row.data 'item', row

				link = if @options.onClick? then '#' else row.links.show
				for val in values
					val = if val? then val else ''
					if typeof val == 'string'
						if link?
							$row.append $('<td>').append($('<a>', {href:link}).html val)
						else
							$row.append $('<td>').html(val)
					else
						$row.append $('<td>').append(val)

				if @options.actionButtons? and @options.actionButtons != false
					actionButtons = $('<td>');
					# Edit Button
					if $.inArray('editable' ,@options.actionButtons) >= 0
						actionButtons.append($('<a>', {'href': row.links.edit,'title':'Edit', 'data-remote': true}).text('Edit'))
						separator = ' '

					# Remove Button
					if $.inArray('removable' ,@options.actionButtons) >= 0
						actionButtons.append(separator)
						separator = ' '
						actionButtons.append($('<a>', {'href': row.links.delete,'title':'Remove', 'data-remote': true}).text('Remove'))

					# Activate/Deactivate Button
					if $.inArray('activable' ,@options.actionButtons) >= 0
						actionButtons.append(separator)
						if row.active
							actionButtons.append $('<a>', {'href': row.links.deactivate, 'title':'Deactivate', 'data-remote': true}).text('Deactivate')
						else
							actionButtons.append $('<a>', {'href': row.links.activate, 'title':'Activate', 'data-remote': true}).text('Activate')

					$row.append actionButtons

				@element.find('tbody').append $row
				@items.push row
				true
			if @options.fixedHeader
				@_synchHeaderWidths()
			@doneLoading = true
			if @options.onItemsChange
				@options.onItemsChange(@items)
		true

	_rowId: (row) ->
		if @options.rowId?
			@options.rowId(row)
	_getRowValues: (row) ->
		if @options.rowValues?
			@options.rowValues(row)

}