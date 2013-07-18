VideosModule = $.extend {}, FormModule, {
	id: 'videos',

	label: 'Videos',

	icon: 'facetime-video',

	_renderFormFields: () ->
		[
			$('<div><i class="icon-facetime-video"></i><i class="icon-facetime-video"></i><i class="icon-facetime-video"></i></div>'),
			$('<div class="module-fields">').append(
				new FormBuilder.VideosField({label: 'Select a Video', kpi_id: 'videos'})
			)
		]

}

FormBuilder.registerModule VideosModule