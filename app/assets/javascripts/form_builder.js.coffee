window.FormBuilder = {
	modules: [],

	init: (options) ->
		@options = options
		@fieldsContainer = $('#fields')
		@fieldAttrbituesContainer = $('#attributes')
		@formWrapper = $('#form-wrapper')
		@modulesList = $('<div>').appendTo @fieldsContainer
		@customKpisList = $('<div id="custom-kpi-list">').appendTo @fieldsContainer
		@genericFieldsList = $('<div>').appendTo @fieldsContainer

		@attributesPanel = $('<div class="field-attributes-panel">').css({position: 'absolute', display: 'none'}).appendTo($('body'))

		@attributesPanel.on 'click', (e) =>
			e.stopPropagation()
			true

		@formWrapper.sortable {
			cancel: '.module .field, .empty-form-legend ',
			connectWith: '.section-fields',
			update: ( event, ui ) =>
				@saveOrdering()
		}


		$(document).on 'kpis:create', (e, kpi) =>
			@_addFieldToForm @_kpiToField(kpi)
			@kpis.push kpi

		@_loadForm options

		$('#form-field-tabs a').click (e) ->
			e.preventDefault()
			$(this).tab 'show'

		@formWrapper.on 'click', '.field, .section', (e) =>
			e.preventDefault()
			e.stopPropagation()
			$field = $(e.target)
			if not $field.hasClass('field') and not $field.hasClass('section')
				$field = $($field.closest('.field, .section')[0])
			@_showFieldAttributes $field
			false

		@formWrapper.on 'click', '.delete-module', (e) =>
			bootbox.confirm "Deleting the module will deactivate all the KPIs associated to it<br/>&nbsp;<p>Do you want to remove it?</p>", (result) =>
				if result
					module = $($(e.target).closest('.module')[0])
					@removeModule module

		@formWrapper.on 'click', '.delete-field', (e) =>
			e.stopPropagation()
			e.preventDefault()
			element = $(e.target).closest('.field')
			field = element.data('field')
			if field.options.kpi_id? 
				bootbox.confirm "Deleting this field will deactivate the KPI associated to it<br/>&nbsp;<p>Do you want to remove it?</p>", (result) =>
					if result
						if field.options.module == 'custom'
							element.appendTo @customKpisList
						else
							module = element.closest('.module')
							element.remove()
							# Remove the module if this was the last field on it
							if module.length == 1 && module.find('.field').length == 0
								@removeModule(module)
						$(document).trigger 'form-builder:kpi-removed', [field.options.kpi_id]
			else
				element.remove()

			false

		true

	_loadForm: (options) ->
		$.getJSON "#{@options.url}/post_event_form", (response) =>
			@kpis = response.kpis
			@renderModules @fieldsContainer

			for field in response.fields
				@_addFieldToForm field

	_addFieldToForm: (field) ->
		if field.module? and @modules[field.module]
			if !@modules[field.module]._loaded
				@modules[field.module]._loaded = true
				@formWrapper.append @modules[field.module].render()
				@modules[field.module].clearFields()
			@modules[field.module].addField @buildField(field)
		else if field.module? and field.module is 'custom'
			fields = $.grep @customKpisList.find('.field'), (aField, index) =>
				$(aField).data('field').options.kpi_id is field.kpi_id
			f.remove() for f in fields
			@formWrapper.append @buildField(field)
		else
			@formWrapper.append @buildField(field)

		if field.kpi_id?
			$(document).trigger 'form-builder:kpi-added', [field.kpi_id]

		@formWrapper.sortable "refresh"

		field

	buildField: (options) ->
		className = options.type;
		className = 'FormBuilder.' + className.charAt(0).toUpperCase() + className.substring(1).toLowerCase() + 'Field'
		eval "var field = new #{className}(options)"
		field

	deactivateKpi: (kpi_id) ->
		$.ajax "#{@options.url}/kpi", {
			method: 'DELETE',
			data: {kpi_id: kpi_id},
			dataType: 'json',
			success: (reponse) =>
				if field = @_findFieldByKpi(kpi_id)
					$(field).remove()
		}

	activateKpi: (kpi_id) ->
		$.ajax "#{@options.url}/kpi", {
			method: 'POST',
			data: {kpi_id: kpi_id},
			dataType: 'json',
			success: (reponse) =>
				@_addFieldToForm reponse.field
		}


	_findFieldByKpi: (kpi_id) ->
		$.grep @formWrapper.find('.field'), (element, index) =>
			field = $(element).data('field')
			field.options.kpi_id == kpi_id

	_kpiToField: (kpi) ->
		{module: kpi.module, type: kpi.type, kpi_id: kpi.id, name: kpi.name, segments: kpi.segments}


	saveFields: (fields) ->
		data = $.map fields, (fieldDiv, index) =>
			$(fieldDiv).data('field').getSaveAttributes()
		@saveForm data

	saveOrdering: ->
		fields = $('> div.field, > div.section, .module div.field', @formWrapper)
		data = $.map fields, (fieldDiv, index) =>
			{id:  $(fieldDiv).data('field').getId(), ordering: index }
		@saveForm data


	saveForm: (data) ->
		$.post "#{@options.url}/update_post_event_form", {fields: data}, (response) =>
			if response isnt 'OK'
				bootbox.alert response


	renderModules: (container) ->
		# Build the modules list
		for kpi in @kpis
			if kpi.module? and kpi.module != ''
				field_options = @_kpiToField(kpi)
				if kpi.module != 'custom'
					if not @modules[kpi.module]?
						module = @modules[kpi.module] = $.extend({}, FormModule, {id: kpi.module, icon: kpi.module, label: kpi.module_name})


		@

	formFields: () ->
		$.map @formWrapper.find('.field'), (element, index) =>
			$(element).data('field')

	_showFieldAttributes: (field) ->
		@formWrapper.find('.selected').removeClass('selected')
		field.addClass('selected')
		$('#form-field-tabs a[href="#attributes"]').tab('show')
		$field = field.data('field')
		@attributesPanel.html('').append $('<div class="arrow-left">'), $field.attributesForm()
		@attributesPanel.find('select').chosen()
		$("input:checkbox, input:radio, input:file").uniform()

		# Store the value of each text field to compare against on the blur event
		$.each $('input[type=text]'), (index, elm) =>
			$(elm).data 'saved-value', $(elm).val()


		position = field.offset()
		@attributesPanel.css {top: position.top + 'px', left: (position.left + field.outerWidth())+'px', display: 'block'}

		$(document).on 'click.fbuidler', (e) => 
			$(document).off 'click.fbuidler'
			@attributesPanel.hide()

		if typeof $field.onAttributesShow != 'undefined'
			$field.onAttributesShow @attributesPanel

		# Apply events to fields for autosave
		$('select', @attributesPanel).on 'change', =>
			@saveFields [field]

		$('input[type=text]', @attributesPanel).on 'blur', (e) =>
			input = $(e.target)
			if input.data('saved-value') != input.val()
				input.data 'saved-value', input.val()
				@saveFields [field]

		$('input.select2-field', @attributesPanel).on 'change', (e) =>
			input = $(e.target)
			if input.data('saved-value') != input.val()
				input.data 'saved-value', input.val()
				@saveFields [field]

		$('input[type=checkbox]', @attributesPanel).on 'click', =>
			@saveFields [field]

}

window.FormModule = {
	icon: 'circle-blank',
	label: 'Default',

	id: '',

	_fields: [],

	element: null,

	_renderFormFields: () ->
		wrapper = $('<div class="module-fields">')
		for field in @_fields
			wrapper.append field
		wrapper

	addField: (field) ->
		@_fields.push field

	render: () ->
		@element = $('<div class="module module-'+@id+'">')
			.append @_formView()

		# @element.sortable {
		# 	items: '.field',
		# }
		@element.data 'module', @
		@element

	_formView: () ->
		$('<div class="form-view">').append(
			$('<fieldset>').append("<legend>#{@label}</legend>")
		).append(@_renderFormFields())

	draggableHelper: () ->
		$('<div class="draggable-helper">').append @_formView()


	clearFields: () ->
		@_fields = []
		@element.find('.module-fields').html ''
		@

	addField: (field) ->
		@element.find('.module-fields').append field
		@

}


window.FormBuilder.TextField = (options) ->
	@options = $.extend({
		name: 'Text Field',
		kpi_id: null,
		id: null,
		remove: null,
		type: 'text',
		options: {capture_mechanism: 'text', predefined_value: '', required: 'false'}
	}, options)

	@field =  $('<div class="field control-group" data-class="TextField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append($('<input type="text" value="'+@options.options.predefined_value+'" readonly="readonly">'))
	]

	@options.options ||= {}
	@options.options.capture_mechanism ||= ''
	@options.options.predefined_value ||= ''

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]),

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="text">Text</option>'),
					$('<option value="integer">Number</option>'),
					$('<option value="decimal">Decimal</option>')
					$('<option value="currency">Money</option>')
				]).val(@options.options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.options.capture_mechanism = input.val()
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append $('<input type="checkbox" name="required"'+(if @options.options.required == 'true' then ' checked="checked"' else '')+'">'),
				$('<label class="control-label">').text('Required')
			]).on 'change', (e) =>
						@options.options.required = e.target.checked

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Predefined Value'),
				$('<div class="controls">').append $('<input type="text" name="predefined_value">')
					.val(@options.options.predefined_value).on 'keyup', (e) =>
						input = $(e.target)
						@options.options.predefined_value = input.val()
						@field.find('input').val @options.options.predefined_value
				])
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'text', kpi_id: @options.kpi_id, options: @options.options}

	@getId = () ->
		@options.id

	@field


window.FormBuilder.SectionField = (options) ->
	@options = $.extend({
		name: 'Section',
		kpi_id: null,
		id: null,
		remove: null,
		type: 'section',
		fields: [],
		options: {}
	}, options)

	@field =  $('<div class="section" data-class="SectionField">').append $('<fieldset>').append([
		$('<legend>').html(@options.name),
		@fields = $('<div class="section-fields">').append($('<div class="empty-form-legend">This section is empty.</div>'))
	])

	for field in @options.fields
		@fields.append FormBuilder.buildField(field)

	@field.find('.section-fields').sortable({
		update: ( event, ui ) ->
			if not ui.item.data('field')
				ui.item.replaceWith(eval("new FormBuilder.#{ui.item.data('class')}({})"))
	})

	@field.data 'field', @

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Section name'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('legend').text @options.name
			])
		]

	@_getFieldsAttributes = () ->
		$.map @field.find('div.field'), (fieldDiv, index) =>
			$.extend {ordering: index}, $(fieldDiv).data('field').getSaveAttributes()

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'section', kpi_id: null, options: {}, fields_attributes: @_getFieldsAttributes()}

	@getId = () ->
		@options.id

	@field


window.FormBuilder.NumberField = (options) ->
	@options = $.extend({
		name: 'Number Field',
		predefined_value: '',
		capture_mechanism: '',
		kpi_id: null,
		id: null,
		remove: null,
		type: 'number',
		options: {capture_mechanism: '', predefined_value: '', required: 'false'}
	}, options)

	@options.options ||= {}
	@options.options.capture_mechanism ||= ''
	@options.options.predefined_value ||= ''

	@field =  $('<div class="field control-group" data-class="NumberField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append($('<input type="text" value="'+@options.options.predefined_value+'" readonly="readonly">'))
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]),

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="integer">Whole Number</option>'),
					$('<option value="decimal">Decimal</option>')
					$('<option value="currency">Money</option>')
				]).val(@options.options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.options.capture_mechanism = input.val()
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append $('<input type="checkbox" name="required"'+(if @options.options.required == 'true' then ' checked="checked"' else '')+'">'),
				$('<label class="control-label">').text('Required')
			]).on 'change', (e) =>
						@options.options.required = e.target.checked

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Predefined Value'),
				$('<div class="controls">').append $('<input type="text" name="predefined_value">')
					.val(@options.options.predefined_value).on 'keyup', (e) =>
						input = $(e.target)
						@options.options.predefined_value = input.val()
						@field.find('input').val @options.options.predefined_value
			])
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: @options.type, kpi_id: @options.kpi_id, options: @options.options}

	@getId = () ->
		@options.id

	@field


window.FormBuilder.TextareaField = (options) ->
	@options = $.extend({
		name: 'Paragraph',
		options: {predefined_value: '', required: 'false'},
		type: 'textarea',
	}, options)

	@options.options ||= {}
	@options.options.predefined_value ||= ''

	@field =  $('<div class="field control-group" data-class="TextareaField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append $('<textarea>').val(@options.options.predefined_value)
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="name" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append $('<input type="checkbox" name="required"'+(if @options.options.required == 'true' then ' checked="checked"' else '')+'">'),
				$('<label class="control-label">').text('Required')
			]).on 'change', (e) =>
						@options.options.required = e.target.checked
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'textarea', kpi_id: @options.kpi_id, options: @options.options}

	@getId = () ->
		@options.id

	@field


window.FormBuilder.PhotosField = (options) ->
	@options = $.extend({
		name: 'Photos'
	}, options)

	@field =  $('<div class="field control-group" data-class="PhotosField">').append [
		$('<img src="/assets/photos.png">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text('Photos'),
			$('<div class="field-not-customizable-message">').text(
				'This field is not customizable'
			)
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'photos', kpi_id: @options.kpi_id, options: {}}

	@getId = () ->
		@options.id

	@field

window.FormBuilder.VideosField = (options) ->
	@options = $.extend({
		name: 'Select a file'
	}, options)

	@field =  $('<div class="field control-group" data-class="VideosField">').append [
		$('<img src="/assets/photos.png">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="field-not-customizable-message">').text(
				'This field is not customizable'
			)
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'videos', kpi_id: @options.kpi_id, options: {}}

	@getId = () ->
		@options.id

	@field

window.FormBuilder.CountField = (options) ->
	@options = $.extend({
		name: 'Option Field',
		options: {capture_mechanism: 'dropdown'},
		type: 'count',
		segments: []
	}, options)

	@options.options ||= {}
	@options.options.capture_mechanism ||= 'dropdown'

	@field =  $('<div class="field control-group" data-class="CountField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">')
	]

	@renderInput = () ->
		if @options.capture_mechanism is 'dropdown'
			@field.find('.controls').html('').append(
				$('<select>').append $.map(@options.segments, (segment, index) => $("<option>#{segment}</option>"))
			)
		else if @options.capture_mechanism is 'radio'
			@field.find('.controls').html('').append $.map(@options.segments, (segment, index) => $("<label><input type=radio name=\"#{@options.name}\" readonly=readonly />#{segment}</label>"))

		else if @options.capture_mechanism is 'checkbox'
			@field.find('.controls').html('').append $.map(@options.segments, (segment, index) => $("<label><input type=checkbox readonly=readonly />#{segment}</label>"))

		true

	@renderInput()


	@field.data 'field', @

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]),

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="radio">Radio</option>'),
					$('<option value="dropdown">DropDown</option>')
					$('<option value="checkbox">Checkbox</option>')
				]).val(@options.options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
						@renderInput()
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append $('<input type="checkbox" name="required"'+(if @options.options.required == 'true' then ' checked="checked"' else '')+'">'),
				$('<label class="control-label">').text('Required')
			]).on 'change', (e) =>
						@options.options.required = e.target.checked

		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'count', kpi_id: @options.kpi_id, options: @options.options}

	@getId = () ->
		@options.id

	@field


window.FormBuilder.PercentageField = (options) ->
	@options = $.extend({
		name: 'Option Field',
		predefined_value: '',
		capture_mechanism: 'integer',
		type: 'percentage',
		segments: []
	}, options)

	@options.options ||= {}
	@options.options.capture_mechanism ||= 'integer'
	@options.options.predefined_value ||= ''

	@field =  $('<div class="field" data-class="PercentageField">').append [
		$('<div class="control-group percentage">').append($('<label class="field-label">').text(@options.name)),
		$('<div class="control-group percentage"><div class="controls">')
	]

	@renderInput = () ->
		@field.find('.controls').html('')
			.append($.map(@options.segments, (segment, index) => $("<label><div class=\"input-append\"><input type=text value=\"0\" class=\"input-micro\" name=\"#{@options.name}\" readonly=readonly /><span class=\"add-on\">%</span></div> #{segment}</label>")))

		true

	@renderInput()


	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]),

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="integer">Whole Number</option>'),
					$('<option value="decimal">Decimal</option>')
				]).val(@options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append $('<input type="checkbox" name="required"'+(if @options.options.required == 'true' then ' checked="checked"' else '')+'">'),
				$('<label class="control-label">').text('Required')
			]).on 'change', (e) =>
						@options.options.required = e.target.checked
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'percentage', kpi_id: @options.kpi_id, options: @options.options}

	@getId = () ->
		@options.id

	@field

window.FormBuilder.CommentsField = (options) ->
	@options = $.extend({
		name: 'Comments',
		predefined_value: '',
		type: 'comments',
	}, options)

	@options.options ||= {}
	@options.options.predefined_value ||= ''

	@field =  $('<div class="field control-group" data-class="CommentsField">').append [
		$('<img src="/assets/comments.png">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text('Comments'),
			$('<div class="field-not-customizable-message">').text(
				'This field is not customizable'
			)
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'comments', kpi_id: @options.kpi_id, options: {}}

	@getId = () ->
		@options.id

	@field

window.FormBuilder.ExpensesField = (options) ->
	@options = $.extend({
		name: 'Expenses'
	}, options)

	@field =  $('<div class="field control-group" data-class="ExpensesField">').append [
		$('<img src="/assets/expenses.png">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="field-not-customizable-message">').text(
				'This field is not customizable'
			)
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'photos', kpi_id: @options.kpi_id, options: {}}

	@getId = () ->
		@options.id

	@field

window.FormBuilder.SurveysField = (options) ->
	@options = $.extend({
		name: 'Surveys',
		options: {brands: []}
	}, options)

	@field =  $('<div class="field control-group" data-class="SurveysField">').append [
		$('<img src="/assets/surveys.png">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<h4>').text(@options.name),
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Brands'),
				$('<div class="controls">').append $('<input type="text" name="brands" class="select2-field">').val(@options.options.brands).on "change", (e) =>
					input = $(e.target)
					@options.options.brands = input.select2("val")
					true
			]
		]

	@onAttributesShow = (form) ->
		$.get '/brands.json', (response) ->
			tags = []
			for result in response
				tags.push {id: result.id, text: result.name }
			form.find('input[name=brands]').select2({
				maximumSelectionSize: 5,
				tags: tags
			})

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'surveys', kpi_id: @options.kpi_id, options: {brands: @options.options.brands}}

	@getId = () ->
		@options.id

	@field

