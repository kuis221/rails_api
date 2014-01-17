$.widget 'nmk.placesAutocomplete', {
	options: {
		select: false
	},

	_create: () ->
		@value = @element.val()
		@element.places_autocomplete({
				source: '/places/search.json',
				appendTo: @element.parent(),
				select: ( event, ui ) =>
					$(@element.data('hidden')).val ui.item.id
					@value = ui.item.label
					if typeof @options.select is 'function'
						@options.select();
		})


		@element.blur (e) =>
			@element.val @value
		# @element.select2({
		# 	minimumInputLength: 1,
		# 	dropdownCssClass: 'ui-dialog',
		# 	query: (query) =>
		# 		$.get '/places/search.json',{term: query.term}, (results) =>
		# 			query.callback {results: results}
		# });
}

$.widget "custom.places_autocomplete", $.ui.autocomplete, {
	_renderItem: ( ul, item ) ->
		newText = String(item.value).replace(
			new RegExp(this.term, "gi"),
			"<strong>$&</strong>");

		$("<li></li>")
			.addClass('ui-menu-item')
			.data("item.autocomplete", item)
			.append("<a>" + newText + "</a>")
			.appendTo(ul)
}