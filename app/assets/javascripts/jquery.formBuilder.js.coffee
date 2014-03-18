$.widget 'nmk.formBuilder', {
	options: {
	},
	_create: () ->
		@formWrapper = @element.find('.form-wrapper')
		@fieldsWrapper = @element.find('.fields-wrapper')

		@attributesPanel = $('<div class="field-attributes-panel">').
			css({position: 'absolute', display: 'none'}).
			appendTo($('body')).
			on 'click', (e) =>
				e.stopPropagation()
				true

		@formWrapper.sortable {
			items: "> div.field",
			cancel: '.empty-form-legend ',
			revert: true,
			stop: (e, ui) =>
				if ui.item.hasClass('ui-draggable')
					ui.item.replaceWith @buildField({type: ui.item.data('type')})
					@formWrapper.sortable "refresh"
		}

		@fieldsWrapper.find('.field').draggable {
			connectToSortable: ".form-wrapper",
			helper: (a, b) =>
				@buildField({type: $(a.target).data('type')})
			revert: "invalid"
		}

		@_loadForm()

		# Display Field Attributes Dialog
		@formWrapper.on 'click', '.field', (e) =>
			e.stopPropagation()
			$field = $(e.target)
			if not $field.hasClass('field')
				$field = $($field.closest('.field, .section')[0])
			@_showFieldAttributes $field
			false

		@formWrapper.on 'click', '.delete-field', (e) =>
			e.stopPropagation()
			e.preventDefault()
			element = $(e.target).closest('.field')
			field = element.data('field')
			bootbox.confirm "Deleting this field will also delete all the associated data<br/>&nbsp;<p>Do you want to delete it?</p>", (result) =>
				element.remove()

			false

		true

	_loadForm: () ->
		$.getJSON "#{@options.url}", (response) =>
			for field in response.form_fields
				@_addFieldToForm field

	_addFieldToForm: (field) ->
		@formWrapper.append @buildField(field)
		@formWrapper.sortable "refresh"

		field

	buildField: (options) ->
		className = options.type.replace('FormField::', '');
		className = 'FormField.' + className
		eval "var field = new #{className}(options)"
		field

	saveFields: (fields) ->
		data = $.map fields, (fieldDiv, index) =>
			$(fieldDiv).data('field').getSaveAttributes()
		@saveForm data

	saveForm: (data) ->
		$.post "#{@options.url}/update_post_event_form", {fields: data}, (response) =>
			if response isnt 'OK'
				bootbox.alert response

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
		@attributesPanel.find("input:checkbox, input:radio, input:file").uniform()

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

		$('input[type=checkbox]', @attributesPanel).on 'change', =>
			@saveFields [field]

		$('.remove-option-btn', @attributesPanel).on 'click', (e) =>
			option = $(e.target).closest('.controls')
			option.find('input[type=hidden][name*="[_destroy]"]').val('1')
			option.hide()
			false

		$('.add-option-btn', @attributesPanel).on 'click', (e) =>
			option = $(e.target).closest('.controls')
			newOption = $(e.target).closest('.controls').clone()
			newOption.find('input[type=hidden][name*="[_destroy]"]').val('')
			newOption.find('input[type=text][name*="[name]"]').val('')
			newOption.find('input[type=hidden][name*="[id]"]').val('')
			newOption.insertAfter(option)
			false

}
FormField = {}

FormField.TextArea = (attributes) ->
	@attributes = $.extend({
		name: 'Paragraph',
		id: null,
		required: false,
		type: 'FormField::TextArea',
		settings: {}
	}, attributes)

	@field =  $('<div class="field control-group" data-type="TextArea">').data('field', @).append [
		$('<label class="control-label">').text(@attributes.name),
		$('<div class="controls">').append($('<textarea readonly="readonly"></textarea>'))
	]

	@attributes.settings ||= {}

	@attributesForm = () ->
		[
			$('<h4>').text('Paragraph'),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@attributes.name).on 'keyup', (e) =>
						input = $(e.target)
						@attributes.name = input.val()
						@field.find('.control-label').text @attributes.name
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append(
					$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
						$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required == 'true' then ' checked="checked"' else '')+'">').on 'change', (e) =>
							@attributes.required = (if e.target.checked then 'true' else 'false')
					)
				)
			])
		]

	@getSaveAttributes = () ->
		{id: @attributes.id, name: @attributes.name, field_type: 'text', attributes: @attributes.options}

	@getId = () ->
		@attributes.id

	@field


FormField.Dropdown = (attributes) ->
	@attributes = $.extend({
		name: 'Dropdown',
		id: null,
		required: false,
		type: 'FormField::Dropdown',
		settings: {},
		options: []
	}, attributes)

	if @attributes.options.length is 0
		@attributes.options = [{id: null, name: 'Option 1'}]

	@field =  $('<div class="field control-group" data-type="Dropdown">').data('field', @).append [
		$('<label class="control-label">').text(@attributes.name),
		$('<div class="controls">').append($('<select>').append(
			$.map @attributes.options, (option, index) =>
				$('<option>').attr('value', option.id).text(option.name)
		))
	]

	@attributes.settings ||= {}

	@attributesForm = () ->
		[
			$('<h4>').text('Dropdown'),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field label'),
				$('<div class="controls">').append $('<input type="text" name="label">').val(@attributes.name).on 'keyup', (e) =>
						input = $(e.target)
						@attributes.name = input.val()
						@field.find('.control-label').text @attributes.name
			]),

			$('<div class="control-group">').append([
				$('<div class="controls">').append(
					$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
						$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required == 'true' then ' checked="checked"' else '')+'">').on 'change', (e) =>
							@attributes.required = (if e.target.checked then 'true' else 'false')
					)
				)
			])
		]

	@getSaveAttributes = () ->
		{id: @attributes.id, name: @attributes.name, field_type: 'text', attributes: @attributes.options}

	@getId = () ->
		@attributes.id

	@field


FormField.Radio = (attributes) ->
	@attributes = $.extend({
		name: 'Single Choice',
		id: null,
		required: false,
		type: 'FormField::Radio',
		settings: {},
		options: []
	}, attributes)

	if @attributes.options.length is 0
		@attributes.options = [{id: null, name: 'Option 1'}]

	@field =  $('<div class="field control-group" data-type="Radio">').data('field', @).append [
		$('<label class="control-label">').text(@attributes.name),
		$('<div class="controls">').append(
			$.map @attributes.options, (option, index) =>
				$('<label>').addClass('radio').append(
					$('<input>').attr('type', 'radio').attr('value', option.id)
				).append(' '+ option.name)
		)
	]

	@attributes.settings ||= {}

	@attributesForm = () ->
		[
			$('<h4>').text('Single Choice'),
			$('<div class="control-group">').append([
				$('<label class="control-label">').text('Field label'),
				$('<div class="controls">').append $('<input type="text" name="name">').val(@attributes.name).on 'keyup', (e) =>
						input = $(e.target)
						@attributes.name = input.val()
						@field.find('.control-label').text @attributes.name
			]),

			$('<div class="control-group">').append($('<label class="control-label">').text('Options')).append(
				$.map @attributes.options, (option, index) =>
					$('<div class="controls field-options">').append([
						$('<input type="hidden" name="option['+index+'][id]">').val(option.id),
						$('<input type="hidden" name="option['+index+'][_destroy]">'),
						$('<input type="text" name="option['+index+'][name]">').val(option.name).on 'keyup', (e) =>
							input = $(e.target)
							@attributes.name = input.val()
							@field.find('.control-label').text @attributes.name
						$('<div class="option-actions">').append(
							$('<a href="#" class="add-option-btn"><i class="icon-plus-sign"></i></a>'),
							$('<a href="#" class="remove-option-btn"><i class="icon-minus-sign"></i></a>')
						)
					])
			),

			$('<div class="control-group">').append([
				$('<div class="controls">').append(
					$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
						$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required == 'true' then ' checked="checked"' else '')+'">').on 'change', (e) =>
							@attributes.required = (if e.target.checked then 'true' else 'false')
					)
				)
			])
		]

	@getSaveAttributes = () ->
		{id: @attributes.id, name: @attributes.name, field_type: 'text', attributes: @attributes.options}

	@getId = () ->
		@attributes.id

	@field
