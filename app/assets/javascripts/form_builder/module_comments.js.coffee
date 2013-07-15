CommentsModule = $.extend {}, FormModule, {
	id: 'comments',

	label: 'Comments',

	icon: 'comments',

	_renderFormFields: () ->
		new FormBuilder.ParagraphField({label: 'Your Comment'})
}

FormBuilder.registerModule CommentsModule