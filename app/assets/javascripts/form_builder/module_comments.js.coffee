CommentsModule = $.extend {}, FormModule, {
	id: 'comments',

	label: 'Comments',

	icon: 'comments',

	_renderFormFields: () ->
		$('<div class="module-fields">').append(
			new FormBuilder.CommentsField({label: 'Your Comment', kpi_id: ''})
		)
}

FormBuilder.registerModule CommentsModule