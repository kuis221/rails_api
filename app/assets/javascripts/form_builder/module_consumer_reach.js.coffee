ConsumerReachModule = $.extend {}, FormModule, {
	id: 'consumer_reach',

	label: 'Consumer Reach',

	icon: 'smile',

	_renderFormFields: () ->
		$('<div class="module-fields">').append(
			new FormBuilder.NumberField({label: 'Impressions', kpi_id: 'impressions', capture_mechanism: 'integer'}),
			new FormBuilder.NumberField({label: '# Consumer interactions', kpi_id: 'interactions', capture_mechanism: 'integer'}),
			new FormBuilder.NumberField({label: 'Consumer Sampled', kpi_id: 'samples', capture_mechanism: 'integer'})
		)
}

FormBuilder.registerModule ConsumerReachModule