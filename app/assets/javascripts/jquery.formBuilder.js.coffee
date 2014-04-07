$.widget 'nmk.formBuilder', {
	options: {
	},
	_create: () ->
		@element.find('.form-wrapper').append(
			@formWrapper = $('<div class="form-fields clearfix">'),
			$('<div class="form-actions">').append('<button id="save-report" class="btn btn-primary">Save</button>')
		)
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

				$.map @formWrapper.find("> div.field"), (field, index) =>
					$(field).data('field').attributes.ordering = index

				@formWrapper.find('.clearfix').appendTo(@formWrapper)
		}

		@fieldsWrapper.find('.field').draggable {
			connectToSortable: ".form-fields",
			helper: (a, b) =>
				@buildField({type: $(a.target).data('type')})
			start: (e, ui) =>
				ui.helper.css({width: ui.helper.outerWidth(), height: ui.helper.outerHeight()})
				applyFormUiFormatsTo(ui.helper)
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
			@formWrapper.find('.field').remove()
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
				if response.result isnt 'OK'
					bootbox.alert response.message
				else
					@_loadForm()
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
			@formWrapper.find('.selected').removeClass('selected')
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
		if @attributes._destroy? && @attributes._destroy is true
			{id: @attributes.id, _destroy: true }
		else
			{id: @attributes.id, name: @attributes.name, ordering: @attributes.ordering, required: @attributes.required, field_type: @fieldType(), settings: @attributes.settings, options_attributes: @getOptionsAttributes(), statements_attributes: @getStatementsAttributes() }

	getId: () ->
		@attributes.id

	labelField: () ->
		$('<div class="control-group">').append([
			$('<label class="control-label" for="field_name">').text('Field label'),
			$('<div class="controls">').append $('<input type="text" id="field_name" name="name">').val(@attributes.name).on 'keyup', (e) =>
					input = $(e.target)
					@attributes.name = input.val()
					@refresh()
		])

	requiredField: () ->
		$('<div class="control-group">').append([
			$('<div class="controls">').append(
				$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
					$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required then ' checked="checked"' else '')+'">').on 'change', (e) =>
						@attributes.required = (if e.target.checked then 'true' else 'false')
				)
			)
		])

	optionsField: (type='option') ->
		list = if type is 'statement' then @attributes.statements else @attributes.options
		titles = {'option': 'Options', 'statement': 'Statements'}
		$('<div class="control-group field-options" data-type="'+type+'">').append($('<label class="control-label">').text(titles[type])).append(
			$.map list, (option, index) =>
				$('<div class="controls field-option">').data('option', option).append([
					$('<input type="hidden" name="'+type+'['+index+'][id]">').val(option.id),
					$('<input type="hidden" name="'+type+'['+index+'][_destroy]">'),
					$('<input type="text" name="'+type+'['+index+'][name]">').val(option.name).on 'keyup', (e) =>
						option = $(e.target).closest('.field-option').data('option')
						option.name = $(e.target).val()
						@refresh()
					$('<div class="option-actions">').append(
						# Button for adding a new option to the field
						$('<a href="#" class="add-option-btn" title="Add option after this"><i class="icon-plus-sign"></i></a>').on 'click', (e) =>
							option = $(e.target).closest('.field-option').data('option')
							index = list.indexOf(option)+1
							list.splice(index,0, {id: '', name: '', ordering: index})
							$('.field-options[data-type='+type+']').replaceWith @optionsField(type)
							@refresh()
							false

						# Button for removing an option of the field
						if index is 0 then '' else $('<a href="#" class="remove-option-btn" title="Remove this option"><i class="icon-minus-sign"></i></a>').on 'click', (e) =>
							option = $(e.target).closest('.field-option').data('option')
							if option.id isnt ''
								option._destroy = '1'
							else
								list.splice(list.indexOf(option),1)
							$('.field-options[data-type='+type+']').replaceWith @optionsField(type)
							@refresh()
							false
					)
				]).css(display: (if option._destroy is '1' then 'none' else ''))
		)

	getOptionsAttributes: () ->
		@attributes.options

	getStatementsAttributes: () ->
		@attributes.statements

	render: () ->
		@field ||= $('<div class="field control-group" data-type="' + @__proto__.type + '">')
			.data('field', @)
			.append $('<a class="close" href="#" title="Remove"><i class="icon-remove-circle"></i></a>').on('click', => @remove()),
					@_renderField()

	remove: () ->
		if @attributes.id
			@field.hide()
			@attributes._destroy = true
		else
			@field.remove()

	refresh: () ->
		@field.html('').append(@_renderField())
		applyFormUiFormatsTo @field
		@

	_renderField: ->
		''

	fieldType: ->
		"FormField::#{@__proto__.type}"
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

TextField = FormField.extend {
	type: 'Text',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Single line text',
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
			$('<div class="controls">').append($('<input type="text" readonly="readonly">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Single line text'),
			@labelField(),
			@requiredField()
		]
}

NumberField = FormField.extend {
	type: 'Number',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Number',
			id: null,
			required: false,
			type: 'FormField::Number',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<input type="number" readonly="readonly">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Number'),
			@labelField(),
			@requiredField()
		]
}

CurrencyField = FormField.extend {
	type: 'Currency',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Price',
			id: null,
			required: false,
			type: 'FormField::Number',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<div class="input-prepend"><span class="add-on">$</span><input type="number" readonly="readonly"></div>'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Price'),
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
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<select disabled="disabled">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy is '1'
						''
					else
						$('<option>').attr('value', option.id).text(option.name)
			))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Dropdown'),
			@labelField(),
			@optionsField('option'),
			@requiredField()
		]

}

RadioField = FormField.extend {
	type: 'Radio',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Multiple Choice',
			id: null,
			required: false,
			type: 'FormField::Radio',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy isnt '1'
						$('<label>').addClass('radio').append(
							$('<input>').attr('type', 'radio').attr('value', option.id)
						).append(' '+ option.name)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Multiple Choice'),
			@labelField(),
			@optionsField('option'),
			@requiredField()
		]
}

PercentageField = FormField.extend {
	type: 'Percentage',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Percent',
			id: null,
			required: false,
			type: 'FormField::Percentage',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy isnt '1'
						$('<label>').addClass('percentage').append(
							$('<div class="input-append"><input type="number" readonly="readonly"><span class="add-on">%</span>')
						).append(' '+ option.name)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Percent'),
			@labelField(),
			@optionsField('option'),
			@requiredField()
		]
}

PhotoField = FormField.extend {
	type: 'Photo',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Photo',
			id: null,
			required: false,
			type: 'FormField::Photo',
			settings: {},
			options: []
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$('<div class="attachment-panel">').append(
					$('<p>').append($('<a href="#" class="file-browse">Browse</a>'), ' for an image located on your computer'),
					$('<p class="divider">').text('OR'),
					$('<p>').text('Drag and drop file here to upload'),
					$('<p class="small">').text('Maximum upload file size: 10MB')
				)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Photo'),
			@labelField(),
			@requiredField()
		]
}

AttachmentField = FormField.extend {
	type: 'Attachment',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Attachment',
			id: null,
			required: false,
			type: 'FormField::Attachment',
			settings: {},
			options: []
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$('<div class="attachment-panel">').append(
					$('<p>').append($('<a href="#" class="file-browse">Browse</a>'), ' for a file located on your computer'),
					$('<p class="divider">').text('OR'),
					$('<p>').text('Drag and drop file here to upload'),
					$('<p class="small">').text('Maximum upload file size: 10MB')
				)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Attachment'),
			@labelField(),
			@requiredField()
		]
}

SummationField = FormField.extend {
	type: 'Summation',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Summation',
			id: null,
			required: false,
			type: 'FormField::Summation',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy isnt '1'
						$('<div class="field-option">').append(
							$('<label>').addClass('summation').text(option.name+ ' ').append(
								$('<input type="number" readonly="readonly">')
							)
						)
			).append(
				$('<div class="field-option summation-total-field">').append(
					$('<label>').addClass('summation').text('TOTAL: ').append(
						$('<input type="number" readonly="readonly">')
					)
				)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Summation'),
			@labelField(),
			@optionsField('option')
			@requiredField()
		]
}

LikertScaleField = FormField.extend {
	type: 'LikertScale',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Likert scale',
			id: null,
			required: false,
			type: 'FormField::LikertScale',
			settings: {},
			options: [],
			statements: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		if @attributes.statements.length is 0
			@attributes.statements = [{id: null, name: 'Statement 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$('<table class="table likert-scale-table">').append(
					$('<thead>').append(
						$('<tr>').append($('<th>')).append($.map(@attributes.options, (option)-> $('<th>').text(option.name)))
					)
				).append(
					$('<tbody>').append(
						$.map @attributes.statements, (statement, index) =>
							$('<tr>').append($('<td>').text(statement.name)).append(
								$.map @attributes.statements, (statement, index) =>
									$('<td>').append($('<input type="radio">'))
							)
					)
				)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Likert scale'),
			@labelField(),
			@optionsField('statement'),
			@optionsField('option'),
			@requiredField()
		]
}

CheckboxField = FormField.extend {
	type: 'Checkbox',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Checkboxes',
			id: null,
			required: false,
			type: 'FormField::Checkbox',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [{id: null, name: 'Option 1', ordering: 0}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy isnt '1'
						$('<label>').addClass('checkbox').append(
							$('<input>').attr('type', 'checkbox').attr('value', option.id)
						).append(' '+ option.name)
			)
		]

	attributesForm: () ->
		[
			$('<h4>').text('Checkboxes'),
			@labelField(),
			@optionsField('option'),
			@requiredField()
		]
}


BrandField = FormField.extend {
	type: 'Brand',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Brand',
			id: null,
			required: false,
			type: 'FormField::Brand',
			settings: {},
			options: []
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<select disabled="disabled">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Brand'),
			@requiredField()
		]
}

MarqueField = FormField.extend {
	type: 'Marque',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Marque',
			id: null,
			required: false,
			type: 'FormField::Marque',
			settings: {},
			options: []
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<select disabled="disabled">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Marque'),
			@requiredField()
		]
}

DateField = FormField.extend {
	type: 'Date',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Date',
			id: null,
			required: false,
			type: 'FormField::Date',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<input type="date" readonly="readonly">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Date'),
			@labelField(),
			@requiredField()
		]
}

TimeField = FormField.extend {
	type: 'Time',

	init: (attributes) ->
		@attributes = $.extend({
			name: 'Time',
			id: null,
			required: false,
			type: 'FormField::Time',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label">').text(@attributes.name),
			$('<div class="controls">').append($('<input type="time" readonly="readonly">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Time'),
			@labelField(),
			@requiredField()
		]
}

applyFormUiFormatsTo = (element) ->
	element.find('select').chosen()
	element.find("input:checkbox, input:radio, input:file").uniform()