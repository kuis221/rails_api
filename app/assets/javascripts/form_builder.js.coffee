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

		@formWrapper.sortable {
			cancel: '.module .field, .empty-form-legend ',
			connectWith: '.section-fields',
			update: ( event, ui ) ->
				if not ui.item.data('field')
					ui.item.replaceWith(eval("new FormBuilder.#{ui.item.data('class')}({})"))
			receive: ( event, ui ) ->
				if ui.item.hasClass('field')
					field = ui.item.data('field')
					if field.options.kpi_id?
						$(document).trigger 'form-builder:kpi-added', [field.options.kpi_id]
				else if ui.item.hasClass('module')
					for element in ui.item.find('.field')
						field = $(element).data('field')
						if field.options.kpi_id?
							$(document).trigger 'form-builder:kpi-added', [field.options.kpi_id]
		}

		# Add generic fields to the fields picker
		@genericFieldsList.append new FormBuilder.TextField({})
		@genericFieldsList.append new FormBuilder.TextareaField({})
		@genericFieldsList.append new FormBuilder.SectionField({})


		$(document).on 'kpis:create', (e, kpi) =>
			#field_options = @_kpiToField(kpi)
			#@customKpisList.append @buildField(field_options)
			@_addFieldToForm @_kpiToField(kpi)

		@_loadForm options

		@genericFieldsList.find('.field').draggable {
			connectToSortable: "#form-wrapper, .section-fields",
			helper: 'clone',
			revert: true
		}

		@genericFieldsList.find('.section').draggable {
			connectToSortable: "#form-wrapper",
			helper: 'clone',
			revert: true
		}

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
				bootbox.confirm "Deleting this fiel will deactivate the KPI associated to it<br/>&nbsp;<p>Do you want to remove it?</p>", (result) =>
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
				

		$('#save-post-event-form').click (e) =>
			@saveForm()

		true

	_loadForm: (options) ->
		$.getJSON options.url, (response) =>
			@kpis = response.kpis
			@renderModules @fieldsContainer

			for field in response.fields
				@_addFieldToForm field

	_addFieldToForm: (field) ->
		if field.module? and @modules[field.module]
			if !@modules[field.module]._loaded
				@modules[field.module]._loaded = true
				@formWrapper.append @modules[field.module].element
				@modules[field.module].clearFields()
			@modules[field.module].addField @buildField(field)
		else if field.module? and field.module is 'custom'
			fields = $.grep @customKpisList.find('.field'), (aField, index) =>
				$(aField).data('field').options.kpi_id is field.kpi_id
			f.remove() for f in fields
			@formWrapper.append @buildField(field)
		else if field.type is 'comments'
			@modules['comments']._loaded = true
			@formWrapper.append @modules['comments'].element
			@modules['comments'].clearFields()
			@modules['comments'].addField @buildField(field)
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
		if field = FormBuilder._findFieldByKpi(kpi_id)
			$(field).remove()
			$(document).trigger 'form-builder:kpi-removed', [kpi_id]

	activateKpi: (kpi_id) ->
		kpis  = $.grep(@kpis, (kpi, index) ->  kpi.id == kpi_id )
		if kpis.length > 0
			kpi = kpis[0]
			@_addFieldToForm @_kpiToField(kpi)
	
	removeModule: (module) ->
		module.appendTo @modulesList
		for element in module.find('.field')
			field = $(element).data('field')
			if field.options.kpi_id?
				$(document).trigger 'form-builder:kpi-removed', [field.options.kpi_id]

		moduleObject = module.data('module')
		moduleObject.clearFields()
		for kpi in @kpis
			if kpi.module == moduleObject.id
				moduleObject.addField @buildField(@_kpiToField(kpi))


	_findFieldByKpi: (kpi_id) ->
		$.grep @formWrapper.find('.field'), (element, index) =>
			field = $(element).data('field')
			field.options.kpi_id == kpi_id

	_kpiToField: (kpi) ->
		{module: kpi.module, type: kpi.type, kpi_id: kpi.id, name: kpi.name, segments: kpi.segments}

	saveForm: () ->
		data = $.map $('> div.field, > div.section, .module div.field', @formWrapper), (fieldDiv, index) =>
			$.extend {ordering: index}, $(fieldDiv).data('field').getSaveAttributes()
		$.post @options.saveUrl, {fields: data}, (response) =>
			alert response


	renderModules: (container) ->
		@modules = {comments: $.extend({}, FormModule, {id: 'comments', icon: 'comments', label: 'Comments'})}

		# Build the modules list
		for kpi in @kpis
			if kpi.module? and kpi.module != ''
				field_options = @_kpiToField(kpi)
				if kpi.module != 'custom'
					if not @modules[kpi.module]?
						module = @modules[kpi.module] = $.extend({}, FormModule, {id: kpi.module, icon: kpi.module, label: kpi.module_name})
						@modulesList.append module.render().data('field', module)
					@modules[kpi.module].addField @buildField(field_options)
				else
					# @modules[kpi.module] = $.extend({}, FormModule, {id: "custom-#{kpi.id}", icon: kpi.module})
					@customKpisList.append @buildField(field_options)
				

		@modulesList.append @modules['comments'].render().data('field', module)

		@modulesList.sortable({
			connectWith: "#form-wrapper",
			items: '> div',
			helper: ( event, element ) ->
				$(element).data('field').draggableHelper().css({width: '400px'})
		}).disableSelection()

		@customKpisList.sortable({
			connectWith: "#form-wrapper",
			items: '> div'
		}).disableSelection()

		@

	_showFieldAttributes: (field) ->
		@formWrapper.find('.selected').removeClass('selected')
		field.addClass('selected')
		$('#form-field-tabs a[href="#attributes"]').tab('show')
		$('#field-attributes-form').html(field.data('field').attributesForm())

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
			.append(
				$('<div class="icon-view">')
					.append($('<i>',{class: "icon-#{@icon}"}))
					.append($('<label>').text(@label))
			)
			.append @_formView()

		@element.sortable {items: '.field'}
		@element.data 'module', @
		@element

	_formView:() ->
		$('<div class="form-view">').append(
			$('<fieldset>').append("<legend>#{@label}</legend>"),
			$('<div class="action-buttons">').append($('<i class="icon-remove-sign delete-module"></i>'))
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
		predefined_value: '',
		kpi_id: null,
		id: null,
		capture_mechanism: 'text',
		remove: null,
		type: 'text',
	}, options)

	if options.options?
		@options.capture_mechanism = options.options.capture_mechanism
		@options.predefined_value = options.options.predefined_value

	@field =  $('<div class="field control-group" data-class="TextField">').append [
		$('<div class="action-buttons"><i class="icon-remove-sign delete-field"></div>'),
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append($('<input type="text" value="'+@options.predefined_value+'" readonly="readonly">'))
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			],

			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="text">Text</option>'),
					$('<option value="integer">Number</option>'),
					$('<option value="decimal">Decimal</option>')
					$('<option value="currency">Money</option>')
				]).val(@options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
			],

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Predefined Value'),
				$('<div class="controls">').append $('<input type="text" name="predefined_value" value="'+@options.predefined_value+'">')
			]).val(@options.predefined_value).on 'keyup', (e) =>
						input = $(e.target)
						@options.predefined_value = input.val()
						@field.find('input').val @options.predefined_value
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'text', kpi_id: @options.kpi_id, options: {capture_mechanism: @options.capture_mechanism, predefined_value: @options.predefined_value}}

	@field


window.FormBuilder.SectionField = (options) ->
	@options = $.extend({
		name: 'Section',
		predefined_value: '',
		kpi_id: null,
		id: null,
		capture_mechanism: '',
		remove: null,
		type: 'section',
		fields: []
	}, options)

	if options.options?
		@options.capture_mechanism = options.options.capture_mechanism
		@options.predefined_value  = options.options.predefined_value

	@field =  $('<div class="section" data-class="SectionField">').append $('<fieldset>').append([
		$('<legend>').html(@options.name),
		$('<div class="action-buttons"><i class="icon-remove-sign delete-field"></div>'),
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
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Section name'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('legend').text @options.name
			]
		]

	@_getFieldsAttributes = () ->
		$.map @field.find('div.field'), (fieldDiv, index) =>
			$.extend {ordering: index}, $(fieldDiv).data('field').getSaveAttributes()

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'section', kpi_id: null, options: {}, fields_attributes: @_getFieldsAttributes()}

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
	}, options)

	if options.options?
		@options.capture_mechanism = options.options.capture_mechanism
		@options.predefined_value = options.options.predefined_value

	@field =  $('<div class="field control-group" data-class="NumberField">').append [
		$('<div class="action-buttons"><i class="icon-remove-sign delete-field"></div>'),
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append($('<input type="text" value="'+@options.predefined_value+'" readonly="readonly">'))
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			],

			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="integer">Whole Number</option>'),
					$('<option value="decimal">Decimal</option>')
					$('<option value="currency">Money</option>')
				]).val(@options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
			],

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Predefined Value'),
				$('<div class="controls">').append $('<input type="text" name="predefined_value" value="'+@options.predefined_value+'">')
			]).val(@options.predefined_value).on 'keyup', (e) =>
						input = $(e.target)
						@options.predefined_value = input.val()
						@field.find('input').val @options.predefined_value
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: @options.type, kpi_id: @options.kpi_id, options: {capture_mechanism: @options.capture_mechanism, predefined_value: @options.predefined_value}}

	@field


window.FormBuilder.TextareaField = (options) ->
	@options = $.extend({
		name: 'Paragraph',
		predefined_value: '',
		type: 'textarea',
	}, options)

	@field =  $('<div class="field control-group" data-class="TextareaField">').append [
		$('<div class="action-buttons"><i class="icon-remove-sign delete-field"></div>'),
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append $('<textarea>').val(@options.predefined_value)
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="name" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'textarea', kpi_id: @options.kpi_id, options: {}}

	@field


window.FormBuilder.PhotosField = (options) ->
	@options = $.extend({
		name: 'Select a file'
	}, options)

	@field =  $('<div class="field control-group" data-class="PhotosField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append $('<input type="file">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="name">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'photos', kpi_id: @options.kpi_id, options: {}}

	@field

window.FormBuilder.VideosField = (options) ->
	@options = $.extend({
		name: 'Select a file'
	}, options)

	@field =  $('<div class="field control-group" data-class="VideosField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append $('<input type="file">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="name">').val(@options.name).on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'videos', kpi_id: @options.kpi_id, options: {}}

	@field

window.FormBuilder.CountField = (options) ->
	@options = $.extend({
		name: 'Option Field',
		predefined_value: '',
		capture_mechanism: 'dropdown',
		type: 'count',
		segments: []
	}, options)

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
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			],

			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="radio">Radio</option>'),
					$('<option value="dropdown">DropDown</option>')
					$('<option value="checkbox">Checkbox</option>')
				]).val(@options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
						@renderInput()
			],
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'count', kpi_id: @options.kpi_id, options: {capture_mechanism: @options.capture_mechanism}}

	@field


window.FormBuilder.PercentageField = (options) ->
	@options = $.extend({
		name: 'Option Field',
		predefined_value: '',
		capture_mechanism: 'integer',
		type: 'percentage',
		segments: []
	}, options)

	@field =  $('<div class="field control-group" data-class="PercentageField">').append [
		$('<div class="action-buttons"><i class="icon-remove-sign delete-field"></div>'),
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">')
	]

	@renderInput = () ->
		@field.find('.controls').html('')
			.append($.map(@options.segments, (segment, index) => $("<label><div class=\"input-append\"><input type=text value=\"0\" class=\"input-micro\" name=\"#{@options.name}\" readonly=readonly /><span class=\"add-on\">%</span></div> #{segment}</label>")))
			.append($("<label><div class=\"input-append\"><input type=text value=\"0\" class=\"input-micro\" name=\"#{@options.name}\" readonly=readonly /><span class=\"add-on\">%</span></div> Total</label>"))

		true

	@renderInput()


	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			],

			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Capture Mechanism'),
				$('<div class="controls">').append $('<select name="capture_mechanism">').append([
					$('<option value="integer">Whole Number</option>'),
					$('<option value="decimal">Decimal</option>')
				]).val(@options.capture_mechanism).on 'change', (e) =>
						input = $(e.target)
						@options.capture_mechanism = input.val()
			],
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'percentage', kpi_id: @options.kpi_id, options: {capture_mechanism: @options.capture_mechanism}}

	@field

window.FormBuilder.CommentsField = (options) ->
	@options = $.extend({
		name: 'Your Comment',
		predefined_value: '',
		type: 'comments',
	}, options)

	@field =  $('<div class="field control-group" data-class="CommentsField">').append [
		$('<label class="control-label">').text(@options.name),
		$('<div class="controls">').append $('<textarea>').val(@options.predefined_value)
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="name" value="'+@options.name+'">').on 'keyup', (e) =>
						input = $(e.target)
						@options.name = input.val()
						@field.find('.control-label').text @options.name
			]
		]

	@getSaveAttributes = () ->
		{id: @options.id, name: @options.name, field_type: 'comments', kpi_id: @options.kpi_id, options: {}}

	@field
