VideosModule = $.extend {}, FormModule, {
	id: 'videos',

	label: 'Videos',

	icon: 'facetime-video',

	_renderFormFields: () ->
		[
			$('<div><i class="icon-facetime-video"></i><i class="icon-facetime-video"></i><i class="icon-facetime-video"></i></div>'),
			new FormBuilder.FileUploadField({label: 'Select a Video'})
		]

}

FormBuilder.registerModule VideosModule