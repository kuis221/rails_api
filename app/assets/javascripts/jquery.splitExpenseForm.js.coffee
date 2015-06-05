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
			amount = parseFloat($(e.target).val()).toFixed(2)
			amount = '0.00' if isNaN(amount)
			$(e.target).val(amount)
			@doCalculation 'currency'
		.on 'blur', 'input.amount-currency', (e) =>
			@checkValid()

		@element.on 'change', 'input.amount-percentage', (e) =>
			percentage = parseInt($(e.target).val())
			percentage = '0' if isNaN(percentage)
			$(this).val(percentage)
			@doCalculation 'percentage'

		@element.on 'change', 'input, select', () =>
			@checkValid()

		@element.find('.split-evenly-btn').on 'click', (e) =>
			e.preventDefault()
			@splitEvenly()
			@updateTotals()
			@checkValid()

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
		summands = @element.find('.fields:visible input.amount-currency')

		@element.find('.fields:visible').each (index, row) =>
			if inputType is 'currency'
				amountValue = $(row).find('.amount-currency').val()
				percentageValue = ((amountValue * 100) / @expenseAmount).toFixed(2).replace(/\.00$/,'')
				$(row).find('.amount-percentage').val percentageValue
			else
				percentageValue = $(row).find('.amount-percentage').val()
				amountValue = parseFloat((@expenseAmount * percentageValue) / 100).toFixed(2)
				$(row).find('.amount-currency').val amountValue
		@updateTotals()

	updateTotals: () ->
		@totalExpenses = 0
		@element.find('.fields:visible').each (index, row) =>
			if $(row).find('.amount-currency').val()
				@totalExpenses += parseFloat($(row).find('.amount-currency').val())
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

	splitEvenly: () ->
		expenses = @element.find('.expenses-list .fields')
		expensesCount = expenses.length
		rowValue = @decimalAdjust(@expenseAmount / expensesCount, -2)
		#rowPecentage = @decimalAdjust(rowValue*100/@expenseAmount, -2)
		for row in expenses
			#$(row).find('.amount-percentage').val(rowPecentage)
			$(row).find('.amount-currency').val(rowValue.toFixed(2)).change()
			@element.validate().element '#' + $(row).find('.amount-currency').attr('id')
		# $(expenses[0]).find('.amount-percentage').val(
		# 	(rowPecentage + (100 - expensesCount * rowPecentage)).toFixed(2).replace(/\.00$/,''))
		$(expenses[0]).find('.amount-currency').val(
			(rowValue + (@expenseAmount - expensesCount * rowValue)).toFixed(2)).change()
		@element.validate().element '#' + $(expenses[0]).find('.amount-currency').attr('id')

	decimalAdjust: (value, exp) ->
		# If the exp is undefined or zero...
		if typeof exp is 'undefined' || +exp is 0
		    return Math.floor(value)

		# If the value is not a number or the exp is not an integer...
		if isNaN(value) || !(typeof exp is 'number' && exp % 1 is 0)
		    return NaN
		# Shift
		value = value.toString().split('e')
		value = Math.floor(+(value[0] + 'e' + (if value[1] then (+value[1] - exp) else -exp)))
		# Shift back
		value = value.toString().split('e')
		+(value[0] + 'e' + (if value[1] then (+value[1] + exp) else exp))

}