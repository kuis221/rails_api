$.loadingContent = 0

$.widget 'branscopic.splitExpenseForm', {
	options:
		expenseAmount: '0'

	_create: () ->
		@element = $('.split-expense-form form')
		@sumContainer = @element.find('.total-amount span')
		@leftContainer = @element.find('.left-amount span')
		@expenseAmount = parseFloat(@options.expenseAmount)
		@totalExpenses = 0
		@defaultDate = @element.find('input.date_picker:first').val()
		@defaultCategory = @element.find('select.category-chosen:first').val()
		@defaultBrand = @element.find('select.brand-chosen:first').val()

		@element.on 'change', 'input.amount-currency', (e) =>
			amount = parseFloat($(e.target).val()).toFixed(2)
			amount = '0.00' if isNaN(amount)
			$(this).val(amount)
			@doCalculation 'currency'

		@element.on 'change', 'input.amount-percentage', (e) =>
			percentage = parseInt($(e.target).val())
			percentage = '0' if isNaN(percentage)
			$(this).val(percentage)
			@doCalculation 'percentage'

		@element.on 'change', 'input, select', () =>
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

		$(document).on 'nested:fieldRemoved', => @doCalculation()

		@element.find('#save-expense-btn').attr 'disabled', true

		@leftContainer.html @expenseAmount

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

		@sumContainer.html @totalExpenses
		@leftContainer.html @expenseAmount - @totalExpenses

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
}