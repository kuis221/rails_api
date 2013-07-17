PhotosModule = $.extend {}, FormModule, {
	id: 'photos'

	label: 'Photos',

	icon: 'camera-retro',

	_renderFormFields: () ->
		[
			$('<div><i class="icon-picture"></i><i class="icon-picture"></i><i class="icon-picture"></i></div>'),
			$('<div class="module-fields">').append(
				new FormBuilder.PhotosField({name: 'Select a Photo', kpi_id: 'photos'})
			)
		]

}

FormBuilder.registerModule PhotosModule