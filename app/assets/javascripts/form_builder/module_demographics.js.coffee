DemographicsModule = $.extend {}, FormModule, {
	id: 'demographics'

	label: 'Demographics',

	icon: 'group'

	_renderFormFields: () ->
		$('<div class="module-fields">').append(
			new FormBuilder.PercentageField({name: 'Age', kpi_id: 'age', capture_mechanism: 'integer', segments: ['< 5 year', '5 - 9', '10 - 14', '15 - 19', '20 - 24', '25 - 29', '30 - 34', '35 - 39', '40 - 44', '45 - 49', '50 - 54', '55 - 59', '60 - 64', '65 - 69', '70+']}),
			new FormBuilder.PercentageField({name: 'Gender', kpi_id: 'gender', capture_mechanism: 'integer', segments: ['Female', 'Male']}),
			new FormBuilder.PercentageField({name: 'Ethnicity/Race', kpi_id: 'ethnicity-race', capture_mechanism: 'integer', segments: ['Asian', 'Black / African American', 'Hispanic / Latino', 'Native American', 'White']})
		)

}

FormBuilder.registerModule DemographicsModule