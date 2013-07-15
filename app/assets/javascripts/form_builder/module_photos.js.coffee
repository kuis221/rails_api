PhotosModule = $.extend {}, FormModule, {
	id: 'photos'

	label: 'Photos',

	icon: 'camera-retro',

	_renderFormFields: () ->
		[
			$('<div><i class="icon-picture"></i><i class="icon-picture"></i><i class="icon-picture"></i></div>')
			new FormBuilder.FileUploadField({label: 'Select a Photo'})
		]

}

FormBuilder.registerModule PhotosModule