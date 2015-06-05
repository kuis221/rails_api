$.loadingContent = 0

$.widget 'branscopic.splitExpenseForm', {
	options:
		expenseAmount: '0'

	_create: () ->
		@element = $('.split-expense-form form')
		@sumContainer = @element.find('.total-amount')
		@leftContainer = @element.find('.left-amount')
		@expenseAmount = parseFloat(@options.expenseAmount)
		@totalExpenses = 0
		@defaultDate = @element.find('input.date_picker:first').val()
		@defaultCategory = @element.find('select.category-chosen:first').val()
		@defaultBrand = @element.find('select.brand-chosen:first').val()

		@element.on 'change', 'input.amount-currency', (e) =>
			@doCalculation 'currency'
		.on 'blur', 'input.amount-currency', (e) =>
			amount = parseFloat($(e.target).val()).toFixed(2)
			amount = '0.00' if isNaN(amount)
			$(e.target).val(amount)
			@checkValid()

		@element.on 'change', 'input.amount-percentage', (e) =>
			percentage = parseInt($(e.target).val())
			percentage = '0' if isNaN(percentage)
			$(this).val(percentage)
			@doCalculation 'percentage'

		@element.on 'change', 'input, select', () =>
			@checkValid()

		# @element.find('.expense-item:last .remove-expense').append(
		# 	@element.find('.add_nested_fields'))

		$(document).on 'nested:fieldAdded', (e) =>
			row = @element.find('.expense-item:last')
			row.find('input.datepicker').datepicker
				showOtherMonths: true,
				selectOtherMonths: true,
				dateFormat: "mm/dd/yy",
				onClose: (selectedDate) -> $(this).valid()
			row.find('select.category-chosen').chosen()
			row.find('select.brand-chosen').chosen()
			row.find('input.amount-currency').val('0.00')
			#row.find('.remove-expense').append @element.find('.add_nested_fields')
			@element.validate()
			@checkValid()

		$(document).on 'nested:fieldRemoved', (e) =>
			e.field.remove()
			@doCalculation()
			@checkValid()

		@element.find('#save-expense-btn').attr 'disabled', true

		@doCalculation()

	doCalculation: (inputType) ->
		@totalExpenses = 0
		summands = @element.find('.fields:visible input.amount-currency')

		@element.find('.fields:visible').each (index, row) =>
			if inputType is 'currency'
				amountValue = $(row).find('.amount-currency').val()
				percentageValue = (amountValue * 100) / @expenseAmount
				$(row).find('.amount-percentage').val percentageValue
			else
				percentageValue = $(row).find('.amount-percentage').val()
				amountValue = parseFloat((@expenseAmount * percentageValue) / 100).toFixed(2)
				$(row).find('.amount-currency').val amountValue
			@totalExpenses += Number(amountValue) if !isNaN(amountValue)

		@sumContainer.find('span').html @totalExpenses.toFixed(2).replace(/\.00$/, '')
		@leftContainer.html @amountLeftOverLabel(@expenseAmount - @totalExpenses)
		if @totalExpenses > @expenseAmount
			@sumContainer.removeClass('text-success').addClass('text-error')
			@leftContainer.show()
		else
			@sumContainer.removeClass('text-error text-success')
			if @totalExpenses is @expenseAmount
				@sumContainer.addClass('text-success')
				@leftContainer.hide()
			else
				@leftContainer.show()

	checkValid: () ->
		if @formValid() && @totalExpenses == @expenseAmount
			@element.find('#save-expense-btn').attr 'disabled', false
		else
			@element.find('#save-expense-btn').attr 'disabled', true

	formValid: () ->
		validate = @element.validate()
		valid = validate.checkForm()
		validate.submitted = {}
		valid

	amountLeftOverLabel: (amount) ->
		if amount < 0
			"$<span>#{Math.abs(amount)}</span> over"
		else
			"$<span>#{amount}</span> left"

}