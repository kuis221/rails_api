$(document).ready ->
	$('input.datepicker').datepicker()
	$('.chosen-enabled').chosen();
	$("input:checkbox, input:radio, input:file").not('[data-no-uniform="true"],#uniform-is-ajax').uniform();