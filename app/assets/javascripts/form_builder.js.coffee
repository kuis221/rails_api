window.FormBuilder = {
	modules: [],

	init: (options) ->
		@fieldsContainer = $('#fields');
		@fieldAttrbituesContainer = $('#attributes')
		@formWrapper = $('#form-wrapper')

		@formWrapper.sortable({
			cancel: '.field, .empty-form-legend ',
			receive: ( event, ui ) =>
				ui.item
		})

		#@renderModules @fieldsContainer
		@_loadForm(options)

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

		$('#save-post-event-form').click (e) =>
			@saveForm()

		true

	_loadForm: (options) ->
		$.getJSON options.url, (response) =>
			@renderModules response.modules, @fieldsContainer

	saveForm:() ->
		$.map $('div.field', @formWrapper), (fieldDiv, index) =>
			$(fieldDiv).data('field').saveAttributes()





	registerModule: (module) ->
		@modules[module.id] = module

	renderModules: (enabledModules, container) ->
		@modulesList = $('<div>').appendTo container
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
		module = $('<div class="module module-'+@id+'">')
			.append(
				$('<div class="icon-view">')
					.append($('<i>',{class: "icon-#{@icon}"}))
					.append($('<label>').text(@label))
			)
			.append(@_formView())
		module.sortable({items: '.field'})
		module

	_formView:() ->
		$('<div class="form-view">').append(
			$('<fieldset>').append("<legend>#{@label}</legend>"),
			$('<div class="action-buttons">').append($('<i class="icon-remove-sign delete-module"></i>'))
		).append(@_renderFormFields())

	draggableHelper: () ->
		$('<div class="draggable-helper">').append(@_formView())
}


window.FormBuilder.TextField = (options) ->
	@options = $.extend({
		label: 'textField',
		predefined_value: '',
		kpi: '',
		type: 'text',
	}, options)

	@field =  $('<div class="field control-group" data-kpi="'+@options.kpi+'">').append [
		$('<label class="control-label">').text(@options.label),
		$('<div class="controls">').append $('<input type="text" value="'+@options.predefined_value+'">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.label)
			],

			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Type'),
				$('<div class="controls">').append $('<select name="type">').append([
					$('<option value="text">Text</option>'),
					$('<option value="number">Number</option>')
				]).val(@options.type)
			],

			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Predefined Value'),
				$('<div class="controls">').append $('<input type="text" name="predefined_value" value="'+@options.predefined_value+'">')
			]).val(@options.predefined_value)
		]

	@saveAttributes = () ->
		{prueba: true}

	@field



window.FormBuilder.ParagraphField = (options) ->
	@options = $.extend({
		label: 'Paragraph',
		predefined_value: '',
		type: 'textarea',
	}, options)

	@field =  $('<div class="field control-group">').append [
		$('<label class="control-label">').text(@options.label),
		$('<div class="controls">').append $('<textarea>').val(@options.predefined_value)
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label" value="'+@options.label+'">')
			]
		]

	@field


window.FormBuilder.FileUploadField = (options) ->
	@options = $.extend({
		label: 'Select a file'
	}, options)

	@field =  $('<div class="field control-group">').append [
		$('<label class="control-label">').text(@options.label),
		$('<div class="controls">').append $('<input type="file">')
	]

	@field.data('field', @)

	@attributesForm = () ->
		[
			$('<div class="control-group">').append [
				$('<label class="control-label">').text('Field Label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@options.label)
			]
		]

	@field
