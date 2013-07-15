ConsumerReachModule = $.extend {}, FormModule, {
	id: 'consumer_reach',

	label: 'Consumer Reach',

	icon: 'smile',

	_renderFormFields: () ->
		$('<div class="module-fields">').append(
			new FormBuilder.TextField({label: 'Impressions', kpi: 'impressions'}),
			new FormBuilder.TextField({label: '# Consumer interactions', kpi: 'interactions'}),
			new FormBuilder.TextField({label: 'Consumer Sampled', kpi: 'samples'})
		)
}

FormBuilder.registerModule ConsumerReachModule