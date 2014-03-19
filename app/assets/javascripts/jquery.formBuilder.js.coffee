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
					fieldHtml = @buildField({type: ui.item.data('type')})
					ui.item.replaceWith fieldHtml
					applyFormUiFormatsTo fieldHtml
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
				$field = $field.closest('.field')
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

		@element.on 'click', '#save-report', (e) =>
			@saveFields()

		true

	_loadForm: () ->
		$.getJSON "#{@options.url}", (response) =>
			for field in response.form_fields
				@_addFieldToForm field

	_addFieldToForm: (field) ->
		fieldHtml = @buildField(field)
		@formWrapper.append fieldHtml
		@formWrapper.sortable "refresh"
		applyFormUiFormatsTo fieldHtml

		field

	buildField: (options) ->
		className = options.type.replace('FormField::', '');
		className = className+'Field'
		eval "var field = new #{className}(options)"
		field.render()

	saveFields: () ->
		data = {
			form_fields_attributes: $.map @formFields(), (field, index) =>
				field.getSaveAttributes()
		}
		@saveForm data

	saveForm: (data) ->
		$.ajax {
			url: "#{@options.url}",
			method: 'put',
			data: {activity_type: data},
			success: (response) =>
				if response isnt 'OK'
					bootbox.alert response
		}

	formFields: () ->
		$.map @formWrapper.find('.field'), (element, index) =>
			$(element).data('field')

	_showFieldAttributes: (field) ->
		@formWrapper.find('.selected').removeClass('selected')
		field.addClass('selected')
		$('#form-field-tabs a[href="#attributes"]').tab('show')
		$field = field.data('field')
		@attributesPanel.html('').append $('<div class="arrow-left">'), $field.attributesForm()
		applyFormUiFormatsTo @attributesPanel

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
}


initializing = false
fnTest = if /xyz/.test(() -> xyz) then /\b_super\b/ else /.*/

Class = () ->
	@

Class.extend = (prop) ->
	_super = this.prototype;

	initializing = true;
	prototype = new this();
	initializing = false;

	for name of prop
		if typeof prop[name] == "function" && typeof _super[name] is "function" && fnTest.test(prop[name])
			prototype[name] =  ((name, fn) ->
				() ->
					tmp = this._super;

					this._super = _super[name];

					ret = fn.apply(this, arguments);		
					this._super = tmp;

					return ret;
			)(name, prop[name])
		else
			prototype[name] = prop[name]

	Class = () ->
		if !initializing && this.init
			@init.apply(this, arguments);

	Class.prototype = prototype;

	Class.prototype.constructor = Class;

	Class.extend = arguments.callee;

	Class



# Base class for all form field classes
FormField = Class.extend {
	getSaveAttributes: () ->
		{id: @attributes.id, name: @attributes.name, type: @attributes.type, settings: @attributes.settings, options_attributes: @getOptionsAttributes()}

	getId: () ->
		@attributes.id

	labelField: () ->
		$('<div class="control-group">').append([
			$('<label class="control-label">').text('Field label'),
			$('<div class="controls">').append $('<input type="text" name="label">').val(@attributes.name).on 'keyup', (e) =>
					input = $(e.target)
					@attributes.name = input.val()
					@refresh()
		])

	requiredField: () ->
		$('<div class="control-group">').append([
			$('<div class="controls">').append(
				$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
					$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required == 'true' then ' checked="checked"' else '')+'">').on 'change', (e) =>
						@attributes.required = (if e.target.checked then 'true' else 'false')
				)
			)
		])

	optionsField: () ->
		$('<div class="control-group field-options">').append($('<label class="control-label">').text('Options')).append(
			$.map @attributes.options, (option, index) =>
				$('<div class="controls field-option">').data('option', option).append([
					$('<input type="hidden" name="option['+index+'][id]">').val(option.id),
					$('<input type="hidden" name="option['+index+'][_destroy]">'),
					$('<input type="text" name="option['+index+'][name]">').val(option.name).on 'keyup', (e) =>
						option = $(e.target).closest('.field-option').data('option')
						option.name = $(e.target).val()
						@refresh()
					$('<div class="option-actions">').append(
						# Button for adding a new option to the field
						$('<a href="#" class="add-option-btn"><i class="icon-plus-sign"></i></a>').on 'click', (e) =>
							option = $(e.target).closest('.field-option').data('option')
							@attributes.options.splice(@attributes.options.indexOf(option)+1,0, {id: '', name: ''})
							$('.field-options').replaceWith @optionsField()
							@refresh()
							false
							
						# Button for removing an option of the field
						$('<a href="#" class="remove-option-btn"><i class="icon-minus-sign"></i></a>').on 'click', (e) =>
							option = $(e.target).closest('.field-option').data('option')
							option._destroy = '1'
							$('.field-options').replaceWith @optionsField()
							@refresh()
							false
					)
				]).css(display: (if option._destroy is '1' then 'none' else ''))
		)

	_readOptionsFromDom: (parent) ->
		@attributes.options = $.map parent.find('.field-option'), (option, index) ->
			{
				id: $(option).find('input[type=hidden][name*="[id]"]').val(),
				name: $(option).find('input[type=text][name*="[name]"]').val(),
				_destroy: $(option).find('input[type=hidden][name*="[_destroy]"]').val(),
				ordering: index
			}

	getOptionsAttributes: () ->
		@attributes.options

	render: () ->
		@field ||= $('<div class="field control-group" data-type="' + @__proto__.type + '">')
			.data('field', @)
			.append @_renderField()

	refresh: () ->
		@field.html('').append(@_renderField())
		applyFormUiFormatsTo @field
		@

	_renderField: () ->
		''
}

TextAreaField = FormField.extend {
	type: 'TextArea',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Paragraph',
			id: null,
			required: false,
			type: 'FormField::TextArea',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<textarea readonly="readonly"></textarea>'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Paragraph'),
			@labelField(),
			@requiredField()
		]
}

DropdownField = FormField.extend {
	type: 'Dropdown',

	init: (attributes) ->
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

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<select>').append(
				$.map @attributes.options, (option, index) =>
					$('<option>').attr('value', option.id).text(option.name)
			))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Dropdown'),
			@labelField(),
			@optionsField(),
			@requiredField()
		]

}

RadioField = FormField.extend {
	type: 'Radio',

	init: (attributes) ->
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

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					$('<label>').addClass('radio').append(
						$('<input>').attr('type', 'radio').attr('value', option.id)
					).append(' '+ option.name)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Single Choice'),
			@labelField(),
			@optionsField(),
			@requiredField()
		]
}


applyFormUiFormatsTo = (element) ->
	element.find('select').chosen()
	element.find("input:checkbox, input:radio, input:file").uniform()