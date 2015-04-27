$.widget 'brandscopic.selectListSearch', {
	options: {},

	_create: () ->
		listSelector = @element.data('list')
		return unless listSelector

		@element.on 'keyup.selectListSearch', () ->
			value = $(this).val().toLowerCase()
			$("#{listSelector} .resource-item").each () ->
				if ($(this).text().toLowerCase().search(value) > -1)
					$(this).show()
				else
					$(this).hide()

	destroy: () ->
		@element.off 'keyup.selectListSearch'
}