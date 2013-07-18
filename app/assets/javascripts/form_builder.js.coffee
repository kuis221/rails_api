window.FormBuilder = {
	modules: [],

	init: (options) ->
		@options = options
		@fieldsContainer = $('#fields')
		@fieldAttrbituesContainer = $('#attributes')
		@formWrapper = $('#form-wrapper')
		@modulesList = $('<div>').appendTo @fieldsContainer
		@genericFieldsList = $('<div>').appendTo @fieldsContainer

		@formWrapper.sortable {
			cancel: '.module .field, .empty-form-legend ',
			update: ( event, ui ) ->
				if not ui.item.data('field')
					ui.item.replaceWith(eval("new FormBuilder.#{ui.item.data('class')}({})"))

		}

		# Add generic fields
		@genericFieldsList.append new FormBuilder.TextField({})
		@genericFieldsList.append new FormBuilder.TextareaField({})

		@_loadForm options

		@genericFieldsList.find('.field').draggable {
			connectToSortable: "#form-wrapper",
			helper: 'clone',
			revert: true
		}

		$('#form-field-tabs a').click (e) ->
		 	e.preventDefault()
			$(this).tab 'show'

		@formWrapper.on 'click', '.field', (e) =>
			e.preventDefault()
			e.stopPropagation()
			$field = $(e.target)
			if not $field.hasClass('field')
				$field = $($field.parents('.field')[0])
			@_showFieldAttributes $field
			false

		@formWrapper.on 'click', '.delete-module', (e) =>
			module = $($(e.target).parents('.module')[0])
			module.appendTo @modulesList
		@formWrapper.on 'click', '.delete-field', (e) =>
			$(e.target).parents('.field').remove()

		$('#save-post-event-form').click (e) =>
			@saveForm()

		true

	_loadForm: (options) ->
		$.getJSON options.url, (response) =>
			@renderModules response.modules, @fieldsContainer

			for field in response.fields
				if field.module? and @modules[field.module]
					if !@modules[field.module]._loaded
						@modules[field.module]._loaded = true
						@formWrapper.append @modules[field.module].element
						@modules[field.module].clearFields()
					@modules[field.module].addField @buildField(field)
				else if field.type is 'comments'
					@modules['comments']._loaded = true
					@formWrapper.append @modules['comments'].element
					@modules['comments'].clearFields()
					@modules['comments'].addField @buildField(field)
				else
					@formWrapper.append @buildField(field)

				


			@formWrapper.sortable "refresh"

	buildField: (options) ->
		className = options.type;
		className = 'FormBuilder.' + className.charAt(0).toUpperCase() + className.substring(1).toLowerCase() + 'Field'
		eval "var field = new #{className}(options)"
		field


	saveForm: () ->
		data = $.map $('div.field', @formWrapper), (fieldDiv, index) =>
			$.extend {ordering: index}, $(fieldDiv).data('field').getSaveAttributes()
		$.post @options.saveUrl, {fields: data}, (response) =>
			alert response


	registerModule: (module) ->
		@modules[module.id] = module

	renderModules: (enabledModules, container) ->
		# for enabledModule, moduleFields of enabledModules
		# 	module = @modules[enabledModule]
		# 	if module?
		# 		@modules.container.append module.render().data('field', module)
		for moduleName, module of @modules
			@modulesList.append module.render().data('field', module)

		@modulesList.sortable({
			connectWith: "#form-wrapper",
			items: '> div',
			helper: ( event, element ) ->
				$(element).data('field').draggableHelper().css({width: '400px'})
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

	_renderFormFields: () ->
		$('<div class="module-fields">').append(
			new FormBuilder.TextField({label: @label})
		)

	render: () ->
		@element = $('<div class="module module-'+@id+'">')
			.append(
				$('<div class="icon-view">')
					.append($('<i>',{class: "icon-#{@icon}"}))
					.append($('<label>').text(@label))
			)
			.append @_formView()

		@element.sortable {items: '.field'}
		@element

	_formView:() ->
		$('<div class="form-view">').append(
			$('<fieldset>').append("<legend>#{@label}</legend>"),
			$('<div class="action-buttons">').append($('<i class="icon-remove-sign delete-module"></i>'))
		).append(@_renderFormFields())

	draggableHelper: () ->
		$('<div class="draggable-helper">').append @_formView()


	clearFields: () ->
		@element.find('.module-fields').html ''

	addField: (field) ->
		@element.find('.module-fields').append field

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
