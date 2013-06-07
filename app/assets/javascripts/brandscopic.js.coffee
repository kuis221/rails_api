jQuery ->
	attachPluginsToElements = () ->
		$('input.datepicker').datepicker()
		$('input.timepicker').timepicker()
		$('.chosen-enabled').chosen()
		$("input:checkbox, input:radio, input:file").not('[data-no-uniform="true"],#uniform-is-ajax').uniform()

		$('.toggle-input .btn').click ->
			$this = $(this);
			$this.parent().find('.btn').removeClass('btn-success btn-danger active')
			if $this.hasClass('set-on-btn')
				$this.addClass('btn-success active')
			else
				$this.addClass('btn-danger active')

			$this.parent().find('.toggle-input-hidden').val($this.data('value')).trigger 'click'
			false

	validateForm = (e) ->
		$(this).validate {
			errorClass: 'help-inline',
			errorElement: 'span',
			ignore: '.no-validate',
			highlight: (element) ->
				$(element).removeClass('valid').closest('.control-group').removeClass('success').addClass('error')
			,
			success: (element) ->
				element
					.addClass('valid')
					.closest('.control-group').removeClass('error')
		}

		if not $(this).valid()
			e.preventDefault()
			e.stopPropagation()
			false

	attachPluginsToElements()

	$(document).ajaxComplete (e) ->
		attachPluginsToElements()

	$(document).on 'submit', "form", validateForm
	$(document).on 'ajax:before', "form", validateForm


	# Fix warning https://github.com/thoughtbot/capybara-webkit/issues/260
	$(document).on 'ajax:beforeSend', 'a[data-remote="true"][data-method="post"]', (event, xhr, settings) ->
		if settings.type == 'POST'
			xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')


	$(document).delegate 'input[type=checkbox][data-filter]', 'click', (e) ->
		$($(this).data('filter')).dataTable().fnDraw()

	$(document).delegate '.modal .btn-cancel', 'click', (e) ->
		e.preventDefault()
		resource_modal.modal 'hide'
		false

	$(".totop").hide();

	# Keep filter Sidebar always visible but make it scroll if it's
	# taller than the window size
	$filterSidebar = $('#resource-filter-column')
	$window = $(window)
	$window.scroll ->
		if $(this).scrollTop() > 200
			$('.totop').slideDown()
		else
			$('.totop').slideUp()

	if $filterSidebar.length
		$filterSidebar.originalTop = $filterSidebar.position().top;
		$window.bind("scroll resize", () ->
			sidebarBottom = $filterSidebar.height()+$filterSidebar.originalTop;
			bottomPosition = $window.scrollTop()+$window.height()

			if sidebarBottom < $window.height()
				$filterSidebar.css({
					position: 'fixed',
					top: "#{$filterSidebar.originalTop}px",
					bottom: ''
				})
			else if  bottomPosition > sidebarBottom and ($(document).height()> (sidebarBottom+30))
				$filterSidebar.css({
					position: 'fixed',
					bottom: "0px",
					top: ''
				})
			else
				$filterSidebar.css({
					position: 'static'
				})
		).scroll()

	$('.totop a').click (e) ->
	  e.preventDefault()
	  $('body,html').animate {scrollTop: 0}, 500

	$.validator.addMethod("oneupperletter",  (value, element) ->
		return this.optional(element) || /[A-Z]/.test(value);
	, "Should have at least one upper case letter");

	$.validator.addMethod("onedigit", (value, element) ->
		return this.optional(element) || /[0-9]/.test(value);
	, "Should have at least one digit");

	$.validator.addMethod("matchconfirmation", (value, element) ->
		return value == $("#user_password").val();
	, "Doesn't match confirmation");

$.rails.allowAction = (element) ->
	message = element.data('confirm')
	if !message
		return true

	if $.rails.fire(element, 'confirm')
			bootbox.moda
			bootbox.confirm message, (answer) ->
				if answer
					callback = $.rails.fire(element, 'confirm:complete', [answer])
					if callback
						oldAllowAction = $.rails.allowAction
						$.rails.allowAction = -> return true
						element.trigger('click')
						$.rails.allowAction = oldAllowAction
	false


$.fn.dataTableExt.afnFiltering.push (oSettings, aData, iDataIndex) ->
	if $("##{oSettings.sTableId}-filters").length
		filtersContainer = $("##{oSettings.sTableId}-filters")
		row = $(oSettings.aoData[iDataIndex].nTr)
		filters = $.map filtersContainer.find('input[type=checkbox]'), (checkbox, i) ->
			checkbox.name

		filters = $.grep filters, (el,index) ->
			index == $.inArray(el,filters);

		filterValues = {}
		for filter in filters
			filterValues[filter] = $.map filtersContainer.find("input[name=#{filter}][type=checkbox]:checked"),  (checkbox, i) ->
				if "#{parseInt(checkbox.value)}" == checkbox.value
					return parseInt(checkbox.value)
				else
					return checkbox.value

		for filter in filters
			rowValue = row.data("filter-" + filter)
			if rowValue.length == 0
				rowValue = ['']
			else if not (rowValue instanceof Array)
				rowValue = [rowValue]

			matches = $.grep(rowValue, (el,index) ->
				$.inArray(el, filterValues[filter]) >= 0
			)
			if matches.length == 0
				return false

		return true
	else
		return true


# ---------- Additional functions for data table ----------
$.fn.dataTableExt.oApi.fnPagingInfo = ( oSettings ) ->
	return {
		"iStart":		 oSettings._iDisplayStart,
		"iEnd":		   oSettings.fnDisplayEnd(),
		"iLength":		oSettings._iDisplayLength,
		"iTotal":		 oSettings.fnRecordsTotal(),
		"iFilteredTotal": oSettings.fnRecordsDisplay(),
		"iPage":		  Math.ceil( oSettings._iDisplayStart / oSettings._iDisplayLength ),
		"iTotalPages":	Math.ceil( oSettings.fnRecordsDisplay() / oSettings._iDisplayLength )
	}

$.extend $.fn.dataTableExt.oPagination, {
	"bootstrap": {
		"fnInit": ( oSettings, nPaging, fnDraw ) ->
			oLang = oSettings.oLanguage.oPaginate;
			fnClickHandler = ( e ) ->
				e.preventDefault();
				if oSettings.oApi._fnPageChange(oSettings, e.data.action)
					fnDraw oSettings

			$(nPaging).addClass('pagination').append(
				'<ul>'+
					'<li class="prev disabled"><a href="#">&larr; '+oLang.sPrevious+'</a></li>'+
					'<li class="next disabled"><a href="#">'+oLang.sNext+' &rarr; </a></li>'+
				'</ul>'
			);
			els = $('a', nPaging);
			$(els[0]).bind( 'click.DT', { action: "previous" }, fnClickHandler );
			$(els[1]).bind( 'click.DT', { action: "next" }, fnClickHandler );
		,

		"fnUpdate": ( oSettings, fnDraw ) ->
			iListLength = 5
			oPaging = oSettings.oInstance.fnPagingInfo()
			an = oSettings.aanFeatures.p
			#i, j, sClass, iStart, iEnd, iHalf=Math.floor(iListLength/2)
			iHalf=Math.floor(iListLength/2)

			if oPaging.iTotalPages < iListLength
				iStart = 1
				iEnd = oPaging.iTotalPages
			else if oPaging.iPage <= iHalf
				iStart = 1
				iEnd = iListLength
			else if oPaging.iPage >= (oPaging.iTotalPages-iHalf)
				iStart = oPaging.iTotalPages - iListLength + 1
				iEnd = oPaging.iTotalPages
			else
				iStart = oPaging.iPage - iHalf + 1
				iEnd = iStart + iListLength - 1

			#for ( i=0, iLen=an.length ; i<iLen ; i++ ) {
			for i in [0..an.length-1]
				# remove the middle elements
				$('li:gt(0)', an[i]).filter(':not(:last)').remove()

				# add the new list items and their event handlers
				#for ( j=iStart ; j<=iEnd ; j++ ) {
				for j in [iStart..iEnd]
					sClass = if j is (oPaging.iPage+1) then 'class="active"' else ''
					$('<li '+sClass+'><a href="#">'+j+'</a></li>')
						.insertBefore($('li:last', an[i])[0])
						.bind 'click', (e) ->
							e.preventDefault();
							oSettings._iDisplayStart = (parseInt($('a', this).text(),10)-1) * oPaging.iLength;
							fnDraw( oSettings );

				# add / remove disabled classes from the static elements
				if oPaging.iPage is 0
					$('li:first', an[i]).addClass 'disabled'
				else
					$('li:first', an[i]).removeClass 'disabled'

				if oPaging.iPage is oPaging.iTotalPages-1 or oPaging.iTotalPages is 0
					$('li:last', an[i]).addClass 'disabled'
				else
					$('li:last', an[i]).removeClass 'disabled'

	}
}

$.extend $.fn.dataTableExt.oStdClasses, {
	"sWrapper": "dataTables_wrapper form-inline"
}


$.fn.dataTableExt.oApi.fnReloadAjax = ( oSettings, sNewSource, fnCallback, bStandingRedraw ) ->
	if sNewSource isnt undefined && sNewSource isnt null
		oSettings.sAjaxSource = sNewSource;

	# Server-side processing should just call fnDraw
	if oSettings.oFeatures.bServerSide
		this.fnDraw()
		return

	this.oApi._fnProcessingDisplay oSettings, true
	that = this
	iStart = oSettings._iDisplayStart
	aData = []

	this.oApi._fnServerParams oSettings, aData

	oSettings.fnServerData.call( oSettings.oInstance, oSettings.sAjaxSource, aData, (json) ->
		# Clear the old information from the table
		that.oApi._fnClearTable oSettings

		# Got the data - add it to the table
		aData =  if oSettings.sAjaxDataProp isnt ""  then that.oApi._fnGetObjectDataFn( oSettings.sAjaxDataProp )( json ) else json

		i = 0
		while i < aData.length
			that.oApi._fnAddData oSettings, aData[i]
			i++

		oSettings.aiDisplay = oSettings.aiDisplayMaster.slice()

		that.fnDraw()

		if bStandingRedraw is true
			oSettings._iDisplayStart = iStart
			that.oApi._fnCalculateEnd oSettings
			that.fnDraw false

		that.oApi._fnProcessingDisplay oSettings, false

		# Callback user function - for event handlers etc
		if typeof fnCallback is 'function' && fnCallback isnt null
			fnCallback oSettings
	, oSettings )