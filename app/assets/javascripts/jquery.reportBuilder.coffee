$.widget 'nmk.reportBuilder',
	options: {},

	_create: () ->
		# Fields search input
		@element.find('#field-search-input').on 'keyup', (e) =>
			value = $(e.target).val();
			for li in @element.find("#report-fields-list li:not(.hidden)")
				if $(li).text().toLowerCase().search(value) > -1
					$(li).show()
				else
					$(li).hide()

		@element.find('.sortable-list').sortable
			receive: (event, ui) =>
				if ui.helper?
					ui.item.addClass('hidden').hide()
			connectWith: '.sortable-list',
			containment: 'body'

		@element.find(".draggable-list li").draggable
			connectToSortable: ".sortable-list",
			revert: "invalid",
			helper: "clone",
			containment: "#resource-filter-column", 
			scroll: false
