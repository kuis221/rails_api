$.widget 'nmk.formBuilder', {
	options: {
		resourceName: null
	},
	_create: () ->
		@modified = false
		@_updateSaveButtonState()

		@wrapper = @element.find('.form-wrapper')
		if @options.canEdit
			@wrapper.append $('<div class="form-actions" data-spy="affix" data-offset-top="340">')
							 .append('<button id="save-report" class="btn btn-primary">Save</button>')
							 .append('<div data-placement="left" title="Adding a new item<br />at the bottom..." class="invisible pull-right field-tooltip-trigger"></div>')

			@fieldTooltip = @wrapper.find('.field-tooltip-trigger').tooltip placement: 'left', html: true
		@wrapper.append(
			@formWrapper = $('<div class="form-fields clearfix form-section">')
		)

		@wrapper.find('form-actions').affix 
			offset: () => @formWrapper.offset().top - ($('#resource-close-details').offset().top + $('#resource-close-details').height())

		$(window).on 'resize scroll', () =>
			@wrapper.find('.form-actions:not(.affix)').each (index, bar) =>
				$(bar).css 
					width: (@formWrapper.outerWidth() - parseInt($(bar).css('padding-left')) - parseInt($(bar).css('padding-right'))),
					top: '0'

			@wrapper.find('.form-actions.affix').each (index, bar) =>
				$(bar).css 
					width: (@formWrapper.outerWidth() - parseInt($(bar).css('padding-left')) - parseInt($(bar).css('padding-right'))),
					top: (parseInt($('#resource-close-details').css('top')) + $('#resource-close-details').height())+'px'


		@fieldsWrapper = @element.find('.fields-wrapper')

		@fieldsWrapper.find('.field[data-title]').tooltip
			html: true, container: @element, delay: 0, animation: false
			title: (a, b) ->
				$(this).data('title')
			placement: (tooltip, field) ->
				window.setTimeout ->
					$(tooltip).css
						left: (parseInt($(tooltip).css('left'))-15)+'px'
				10

				return 'left';

		@wrapper.droppable
			accept: ".field.module"
			drop: (event, ui) =>
				options = {type: ui.draggable.data('type')}
				@_addModuleToForm options
				true

		@element.find('.scrollable-list').jScrollPane verticalDragMinHeight: 10

		@element.find('.field-search-input').on 'keyup', (e) =>
			@searchFieldList $(e.target).val().toLowerCase()

		@attributesPanel = $('<div class="field-attributes-panel">').
			css({position: 'absolute', display: 'none'}).
			appendTo($('body')).
			on 'click', (e) =>
				e.stopPropagation()
				true

		if @options.canEdit
			@formWrapper.sortable
				items: "> div.field"
				cancel: '.empty-form-legend, .module'
				revert: true,
				stop: (e, ui) =>
					if ui.item.hasClass('ui-draggable')
						options = {type: ui.item.data('type')}
						options = ui.item.data('options') if ui.item.data('options')
						fieldHtml = @buildField(options)
						ui.item.replaceWith fieldHtml
						applyFormUiFormatsTo fieldHtml

					@_updateOrdering();

					@setModified()
					@formWrapper.find('.clearfix').appendTo(@formWrapper)
				over: (event, ui) =>
					@formWrapper.addClass 'sorting'
					@element.find('.empty-form-legend').hide()

				out: (event, ui) =>
					@formWrapper.removeClass 'sorting'

				receive: (event, ui) =>
					if ui.item.hasClass('module')
						@formWrapper.sortable 'cancel'
					else
						@element.find('.empty-form-legend').hide()

		if @options.canEdit
			@fieldsWrapper.find('.field:not(.module)').draggable
				connectToSortable: ".form-fields"
				revert: "invalid"
				appendTo: @fieldsWrapper
				helper: (a, b) =>
					$target = $(a.target)
					options = {type: $target.data('type')}
					if $target.data('options')
						options = $target.data('options');
					@buildField options
				start: (e, ui) =>
					ui.helper.css({width: ui.helper.outerWidth(), height: ui.helper.outerHeight()})
					applyFormUiFormatsTo(ui.helper)
			.on 'click', (e) =>
				return if e.target.adding
				e.target.adding = setTimeout () -> 
					e.target.adding = false
				, 1000
				target = $(e.target)
				options = {type: target.data('type')}
				options = target.data('options') if target.data('options')
				@_addFieldToForm options
				@setModified()
				@_updateOrdering()
				@fieldTooltip.tooltip 'show'
				clearTimeout @_toolTipTimeout if @_toolTipTimeout
				@_toolTipTimeout = setTimeout =>
					@fieldTooltip.tooltip 'hide'
				, 1000

			@fieldsWrapper.find('.field.module').draggable
				revert: "invalid"
				appendTo: @fieldsWrapper
				helper: (a, b) =>
					$target = $(a.target)
					options = {type: $target.data('type')}
					if $target.data('options')
						options = $target.data('options')
					@buildField options
				start: (e, ui) =>
					ui.helper.css({width: ui.helper.outerWidth(), height: ui.helper.outerHeight()})
					applyFormUiFormatsTo(ui.helper)

			# Display Field Attributes Dialog
			@formWrapper.on 'click', '.field', (e) =>
				e.stopPropagation()
				$field = $(e.target)
				if not $field.hasClass('field')
					$field = $field.closest('.field')
				@_showFieldAttributes $field
				false

		@_loadForm()

		if @options.canEdit
			@element.on 'click', '#save-report', (e) =>
				@saveFields()
				false
			$(window).on 'beforeunload.formBuilder', =>
				if @modified
					'You are leaving the activity type details page without saving your work.'

		true

	searchFieldList: (value) ->
		$list = @element.find('.searchable-field-list')
		for field in $list.find(".field:not(.hidden)")
			if $(field).text().toLowerCase().search(value) > -1
				$(field).show()
			else
				$(field).hide()

		$list.find('.group-name').show()
		for group in $('.group-name').get()
			group_name = $(group).text()
			if $list.find('.field[data-group="'+group_name+'"]:visible').length is 0
				$(group).hide()
				$list.find('.field[data-group="'+group_name+'"]').hide()
			else
				$(group).show()
		scrollerApi = $('.searchable-field-list .scrollable-list').data('jsp')
		scrollerApi.reinitialise()
		true

	_updateOrdering: () ->
		$.map @formWrapper.find("> div.field"), (field, index) =>
			$(field).data('field').attributes.ordering = index

	_loadForm: () ->
		@element.find('.empty-form-legend').hide()
		$.getJSON "#{@options.url}", (response) =>
			@formWrapper.find('.field').remove()
			@modified = false
			@_updateSaveButtonState()
			if response.form_fields.length > 0 || response.enabled_modules.length > 0
				if response.form_fields.length > 0
					for field in response.form_fields
						@_addFieldToForm field
				if response.enabled_modules && response.enabled_modules.length > 0
					for moduleName in response.enabled_modules
						@_addModuleToForm {type: @_capitalize(moduleName.replace(/_/g, ' '))}
						
			else
				@element.find('.empty-form-legend').show()

	_addFieldToForm: (field) ->
		fieldHtml = @buildField(field)
		@formWrapper.append fieldHtml
		@formWrapper.sortable "refresh" if @options.canEdit
		applyFormUiFormatsTo fieldHtml

		field

	_addModuleToForm: (field) ->
		moduleHtml = @buildField(field)
		@wrapper.append moduleHtml
		@fieldsWrapper.find('.module[data-type='+field.type+']').hide()

		field

	buildField: (options) ->
		className = options.type.replace('FormField::', '');
		className = className+'Field'
		eval "var field = new #{className}(this, options)"
		field.render()

	saveFields: () ->
		data = {
			form_fields_attributes: $.map(@formFields(), (field) => field.getSaveAttributes())
			enabled_modules: $.map(@formModules(), (field) => field.getSaveAttributes().name)
		}
		@saveForm data

	saveForm: (data) ->
		$('#save-report').data('text', $('#save-report').text()) unless $('#save-report').data('text')?
		$('#save-report').text('Saving...').attr 'disabled', true
		params = {}
		params[@options.resourceName] = data
		$.ajax {
			url: "#{@options.url}",
			method: 'put',
			data: params,
			success: (response) =>
				if response.result isnt 'OK'
					bootbox.alert response.message
				else
					@modified = false
					@_loadForm()
			error: (jqXHR, textStatus, errorThrown) =>
				bootbox.alert jqXHR.responseText
				$('#save-report').attr 'disabled', false
			complete: ( jqXHR, textStatus) =>
				$('#save-report').text($('#save-report').data('text'))
		}

	setModified: () ->
		@modified = true
		@_updateSaveButtonState()

	formFields: () ->
		$.map @formWrapper.find('.field'), (element, index) =>
			$(element).data('field')

	formModules: () ->
		$.map @wrapper.find('.module'), (element, index) =>
			$(element).data('field')

	placeFieldAttributes: (field) ->
		position = field.offset()
		@attributesPanel.removeClass('on-bottom on-left')
		if field.data('type') is 'LikertScale'
			left = position.left + ((field.outerWidth()-@attributesPanel.outerWidth())/2)
			left = Math.max(left, position.left)
			@attributesPanel.removeClass('on-left').addClass('on-bottom').css
				top: (position.top + field.outerHeight()+10) + 'px'
				left: left+'px'
				display: 'block'
		else
			@attributesPanel.addClass('on-left').removeClass('on-bottom').css
				top: position.top + 'px'
				left: (position.left + field.outerWidth())+'px'
				display: 'block'
		@

	_showFieldAttributes: (field) ->
		$field = field.data('field')
		if form = $field.attributesForm()
			@formWrapper.find('.selected').removeClass('selected')
			field.addClass('selected')
			$('#form-field-tabs a[href="#attributes"]').tab('show')
			@attributesPanel.html('').append $('<div class="arrow">'), form
			applyFormUiFormatsTo @attributesPanel

			@placeFieldAttributes field

			field.on 'change.attrFrm', () =>
				@placeFieldAttributes field

			# Store the value of each text field to compare against on the blur event
			$.each $('input[type=text]'), (index, elm) =>
				$(elm).data 'saved-value', $(elm).val()

			$(document).on 'click.fbuidler', '.modal', (e) =>
				e.ignoreClose = true

			$(document).on 'click.fbuidler', (e) =>
				if $('.modal.in:visible').length is 0 and not e.ignoreClose?
					@_hideFieldAttributes field
		else
			@_hideFieldAttributes field

	_hideFieldAttributes: (field) ->
		$(document).off 'click.fbuidler'
		@formWrapper.find('.selected').removeClass('selected')
		field.off 'change.attrFrm'
		@attributesPanel.hide()

	_updateSaveButtonState: () ->
		$('#save-report').attr('disabled', not @modified)

	_capitalize: (string) ->
		string.replace /(?:^|\s)\S/g, (a) -> a.toUpperCase()
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
		else if @attributes.kpi_id 
			{id: @attributes.id, name: @attributes.name, ordering: @attributes.ordering, required: @attributes.required, kpi_id: @attributes.kpi_id, field_type: @fieldType()}
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
					@form.setModified()
					@refresh()
					true
		])

	requiredField: () ->
		$('<div class="control-group">').append([
			$('<div class="controls">').append(
				$('<label class="control-label" for="option_required_chk">').text('Required').prepend(
					$('<input type="checkbox" id="option_required_chk" name="required"'+(if @attributes.required then ' checked="checked"' else '')+'">').on 'change', (e) =>
						@attributes.required = (if e.target.checked then 'true' else 'false')
						@form.setModified()
						true
				)
			)
		])

	optionsField: (type='option') ->
		return if @attributes.kpi_id
		list = if type is 'statement' then @attributes.statements else @attributes.options
		min_fields_allowed = if type is 'statement' then @attributes.min_statements_allowed else @attributes.min_options_allowed
		visible_items = list.filter (item) -> not item._destroy
		titles = {'option': ['Option','Options'], 'statement': ['Statement', 'Statements']}
		$('<div class="control-group field-options" data-type="'+type+'">').append($('<label class="control-label">').text(titles[type][1])).append(
			$.map list, (option, index) =>
				$('<div class="controls field-option">').data('option', option).append([
					$('<input type="hidden" name="'+type+'['+index+'][id]">').val(option.id),
					$('<input type="hidden" name="'+type+'['+index+'][_destroy]">'),
					$('<input type="text" name="'+type+'['+index+'][name]">').val(option.name).on 'keyup', (e) =>
						option = $(e.target).closest('.field-option').data('option')
						option.name = $(e.target).val()
						@form.setModified()
						@refresh()
						true
					$('<div class="option-actions">').append(
						# Button for adding a new option to the field
						$('<a href="#" class="add-option-btn" title="Add option after this"><i class="icon-plus-sign"></i></a>').on 'click', (e) =>
							option = $(e.target).closest('.field-option').data('option')
							index = list.indexOf(option)+1
							list.splice(index,0, {id: null, name: titles[type][0] + ' ' + (list.length+1), ordering: index})
							item.ordering = i for item,i in list
							$('.field-options[data-type='+type+']').replaceWith @optionsField(type)
							@refresh()
							@form.setModified()
							false

						# Button for removing an option of the field
						if @form.options.canEdit && visible_items.length > min_fields_allowed 
							$('<a href="#" class="remove-option-btn" title="Remove this option"><i class="icon-minus-sign"></i></a>').on 'click', (e) =>
								option = $(e.target).closest('.field-option').data('option')
								if option.id isnt null
									bootbox.confirm "Removing this " + type + " will remove all the entered data/answers associated with it.<br/>&nbsp;<p>Are you sure you want to do this? This cannot be undone</p>", (result) =>
										if result
											option._destroy = '1'
											$('.field-options[data-type='+type+']').replaceWith @optionsField(type)
											@refresh()
											@form.setModified()
								else
									bootbox.confirm "Are you sure you want to remove this " + type + "?", (result) =>
										if result
											list.splice(list.indexOf(option),1)
											$('.field-options[data-type='+type+']').replaceWith @optionsField(type)
											@refresh()
											@form.setModified()
								false
						else
							null
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
			.append (if @form.options.canEdit then $('<a class="close" href="#" title="Remove"><i class="icon-remove-circle"></i></a>').on('click', => @remove()) else null),
					@_renderField()

	remove: () ->
		if @attributes.id # If this file already exists on the database
			bootbox.confirm @_removeConfirmationMessage(true), (result) =>
				if result
					@field.hide()
					@attributes._destroy = true
					@form.setModified()
		else
			bootbox.confirm @_removeConfirmationMessage(false), (result) =>
				if result
					@field.remove()
					@form.setModified()
					@form._hideFieldAttributes @field
		false

	_removeConfirmationMessage: (withData) ->
		if withData
			"Removing this field will remove all the entered data/answers associated with it.<br/>&nbsp;<p>Are you sure you want to do this?</p>"
		else
			"Are you sure you want to remove this field?"

	refresh: () ->
		@field.html('').append(
			$('<a class="close" href="#" title="Remove"><i class="icon-remove-circle"></i></a>').on('click', => @remove()),
			@_renderField()
		)
		applyFormUiFormatsTo @field
		@field.trigger 'change'
		@

	_renderField: ->
		''

	fieldType: ->
		"FormField::#{@__proto__.type}"
}

SectionField = FormField.extend {
	type: 'Section',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Section',
			id: null,
			required: false,
			type: 'FormField::Section',
			settings: {}
		}, attributes)

		@attributes.settings ||= {description: null}

		@

	_renderField: () ->
		[
			description = 
			$('<h3 class="section-title">').text(@attributes.name),
			(if @attributes.settings.description then $('<p class="section-description">').html(@_nl2br(@attributes.settings.description)) else null)
		]

	descriptionField: () ->
		$('<div class="control-group">').append([
			$('<label class="control-label" for="field_description">').text('Description'),
			$('<div class="controls">').append $('<textarea id="field_description" name="description">').val(@attributes.settings.description).on 'keyup', (e) =>
					input = $(e.target)
					@attributes.settings.description = input.val()
					@form.setModified()
					@refresh()
					true
		])

	_nl2br: (str) ->
		breakTag = '<br>';
		s = (str + '').replace(/</g, '&lt;').replace(/>/g, '&gt;')
		s.replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + breakTag + '$2')

	attributesForm: () ->
		[
			$('<h4>').text('Section'),
			@labelField(),
			@descriptionField()
		]
}


TextAreaField = FormField.extend {
	type: 'TextArea',

	init: (form, attributes) ->
		@form = form
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

UserDateField = FormField.extend {
	type: 'UserDate',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'UserDate',
			id: null,
			required: false,
			type: 'FormField::UserDate',
			settings: {}
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		'<div class="row-fluid">'+
			'<div class="span7"><div class="control-group select required activity_company_user_id"><label class="select required control-label" for="activity_company_user_id">User</label><div class="controls"><select class="select" id="activity_company_user_id" name="activity[company_user_id]" disabled="disabled"></select></div></div></div>'+
			'<div class="span5"><div class="control-group date_picker required activity_activity_date"><label class="date_picker required control-label" for="activity_activity_date">Date</label><div class="controls"><input class="date_picker required field-type-date datepicker hasDatepicker" id="activity_activity_date" readonly="readonly" name="activity[activity_date]" size="30" type="date" value=""></div></div></div>' +
		'</div>'

	attributesForm: () ->
		false
}

TextField = FormField.extend {
	type: 'Text',

	init: (form, attributes) ->
		@form = form
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

	init: (form, attributes) ->
		@form = form
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

	init: (form, attributes) ->
		@form = form
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Dropdown',
			id: null,
			min_options_allowed:1,
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Multiple Choice',
			id: null,
			min_options_allowed:1,
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
			$('<label class="control-label control-group-label">').text(@attributes.name),
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Percent',
			id: null,
			min_options_allowed:2,
			required: false,
			type: 'FormField::Percentage',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [
				{id: null, name: 'Option 1', ordering: 0},
				{id: null, name: 'Option 2', ordering: 1},
				{id: null, name: 'Option 3', ordering: 2}]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label control-group-label">').text(@attributes.name),
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

	init: (form, attributes) ->
		@form = form
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
			$('<label class="control-label control-group-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$('<div class="attachment-panel">').append(
					$('<div class="drag-box icon-drag">').append(
						$('<h4>').text('DRAG & DROP'),
						$('<p>').append('your image or ', $('<a href="#" class="file-browse">browse</a>'))
					)
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

	init: (form, attributes) ->
		@form = form
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Summation',
			id: null,
			min_options_allowed: 2,
			required: false,
			type: 'FormField::Summation',
			settings: {},
			options: []
		}, attributes)

		if @attributes.options.length is 0
			@attributes.options = [
				{id: null, name: 'Option 1', ordering: 0},
				{id: null, name: 'Option 2', ordering: 1}
			]
		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label control-group-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$.map @attributes.options, (option, index) =>
					if option._destroy isnt '1'
						$('<div class="field-option">').append(
							$('<label>').addClass('summation').text(option.name+ ' '),
							$('<input type="number" readonly="readonly">')
						)
			).append(
				$('<div class="field-option summation-total-field">').append(
					$('<label>').addClass('summation').text('TOTAL: '),
					$('<input type="number" readonly="readonly">')
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Likert scale',
			id: null,
			min_options_allowed:4,
			min_statements_allowed:4,
			required: false,
			type: 'FormField::LikertScale',
			settings: {},
			options: [],
			statements: []
		}, attributes)

		if @attributes.id is null
			@attributes.options = [
				{id: null, name: 'Strongly Disagree', ordering: 0},
				{id: null, name: 'Disagree', ordering: 1},
				{id: null, name: 'Agree', ordering: 2},
				{id: null, name: 'Strongly Agree', ordering: 3}
			]

		if @attributes.id is null
			@attributes.statements = [
				{id: null, name: 'Statement 1', ordering: 0},
				{id: null, name: 'Statement 2', ordering: 1},
				{id: null, name: 'Statement 3', ordering: 2}
			]

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<label class="control-label control-group-label">').text(@attributes.name),
			$('<div class="controls">').append(
				$('<table class="table likert-scale-table">').append(
					$('<thead>').append(
						$('<tr>').append($('<th>')).append($.map(@attributes.options, (option)-> $('<th>').text(option.name)))
					)
				).append(
					$('<tbody>').append(
						$.map @attributes.statements, (statement, index) =>
							$('<tr>').append($('<td>').text(statement.name)).append(
								$.map @attributes.options, (option, index) =>
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Checkboxes',
			id: null,
			min_options_allowed:1,
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Brand',
			id: null,
			min_options_allowed:1,
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

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Marque',
			id: null,
			min_options_allowed:1,
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

	init: (form, attributes) ->
		@form = form
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
			$('<div class="controls">').append($('<input type="text" class="date_picker" readonly="readonly">'))
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

	init: (form, attributes) ->
		@form = form
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
			$('<div class="controls">').append($('<input type="text" class="time_picker" value="hh:mm" readonly="readonly">'))
		]

	attributesForm: () ->
		[
			$('<h4>').text('Time'),
			@labelField(),
			@requiredField()
		]
}

Module =  FormField.extend {
	getSaveAttributes: () ->
		{field_type: 'module', name: @fieldType()}

	fieldType: ->
		@__proto__.type

	render: () ->
		@field ||= $('<div class="form-section module" data-type="' + @__proto__.type + '">')
			.data('field', @)
			.append (if @form.options.canEdit then $('<a class="close" href="#" title="Remove"><i class="icon-remove-circle"></i></a>').on('click', => @remove()) else null),
					@_renderField()

	_removeConfirmationMessage: (withData) ->
		if withData
			"Removing this module will remove all the entered data associated with it.<br/>&nbsp;<p>Are you sure you want to do this?</p>"
		else
			"Are you sure you want to remove this module?"
}

SurveysField = Module.extend {
	type: 'surveys',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Surves'
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<h2>Surveys Module</h2>'),
			$('<img src="/assets/surveys.png" width="363" height="237" />')
		]

	attributesForm: () ->
		false
}

CommentsField = Module.extend {
	type: 'comments',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Surveys'
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<h2>Comments Module</h2>'),
			$('<img src="/assets/comments.png" width="363" height="337" />')
		]

	attributesForm: () ->
		false
}

PhotosField = Module.extend {
	type: 'photos',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Photos'
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<h2>Gallery Module</h2>'),
			$('<img src="/assets/photos.png" width="363" height="337" />')
		]

	attributesForm: () ->
		false
}

ExpensesField = Module.extend {
	type: 'expenses',

	init: (form, attributes) ->
		@form = form
		@attributes = $.extend({
			name: 'Expenses'
		}, attributes)

		@attributes.settings ||= {}

		@

	_renderField: () ->
		[
			$('<h2>Expenses Module</h2>'),
			$('<img src="/assets/expenses.png" width="363" height="337" />')
		]

	attributesForm: () ->
		false
}

applyFormUiFormatsTo = (element) ->
	element.find('select').chosen()
	element.find("input:checkbox, input:radio, input:file").uniform()
