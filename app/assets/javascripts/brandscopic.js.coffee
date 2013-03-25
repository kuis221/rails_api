jQuery ->
	$('input.datepicker').datepicker()
	$('input.timepicker').timepicker()
	$('.chosen-enabled').chosen();
	$("input:checkbox, input:radio, input:file").not('[data-no-uniform="true"],#uniform-is-ajax').uniform();