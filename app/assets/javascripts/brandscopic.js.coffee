jQuery ->
	attachPluginsToElements = () ->
		$('input.datepicker').datepicker({showOtherMonths:true,selectOtherMonths:true})
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

		$(".fancybox").fancybox {
			padding : 0,
			helpers : { title: { type: 'inside' } },
			beforeLoad: () ->
				this.title = $(this.element).attr('caption')
		}

		true

	validateForm = (e) ->
		$(this).validate {
			errorClass: 'help-inline',
			errorElement: 'span',
			ignore: '.no-validate',
			highlight: (element) ->
				$(element).removeClass('valid').closest('.control-group').removeClass('success').addClass('error')
			,
			errorPlacement: (error, element) ->
				label = element.closest(".control-group").find("label.control-label")
				if label.length > 0
					error.insertAfter label 
				else
					error.insertAfter element 

			success: (element) ->
				element
					.addClass('valid').text('OK!')
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



	$('[data-sparkline]').each (index, elm) ->
		$elm = $(elm)
		values = $elm.data('values').split(",")
		console.log((values.length * 3)+'px')
		$elm.sparkline values, { type: $elm.data('sparkline'), barWidth: 1, barSpacing: 1, barColor: '#3E9CCF', height: '20px' }


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

	$(".totop").hide()

	# TimeZone change detection methods
	window.checkUserTimeZoneChanges = (userTimeZone, lastDetectedTimeZone) ->
		browserTimeZone = $window.get_timezone()
		if browserTimeZone? and browserTimeZone != ''
			if userTimeZone != browserTimeZone && browserTimeZone != lastDetectedTimeZone
				askForTimeZoneChange(browserTimeZone)

	askForTimeZoneChange = (browserTimeZone) ->
		$.get('/users/time_zone_change.js', {time_zone: browserTimeZone})


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
		$filterSidebar.positioning = false
		$window.bind("scroll resize DOMSubtreeModified", () ->
			if $filterSidebar.positioning
				return true
			$filterSidebar.positioning = true
			sidebarBottom = $filterSidebar.outerHeight()+$filterSidebar.originalTop;
			bottomPosition = $window.scrollTop()+$window.height()
			footerHeight = $('footer').outerHeight()

			if sidebarBottom < $window.height()
				$filterSidebar.css({
					position: 'fixed',
					top: "#{$filterSidebar.originalTop}px",
					right: "10px",
					bottom: 'auto'
				})
			else if (bottomPosition > (sidebarBottom + footerHeight)) and ($(document).height() > (sidebarBottom+$filterSidebar.originalTop + footerHeight + 5))
				$filterSidebar.css({
					position: 'fixed',
					bottom: footerHeight+"px",
					top: 'auto',
					right: "10px"
				})
			else
				$filterSidebar.css({
					position: 'static'
				})
			$filterSidebar.positioning = false
			true
		).trigger('scroll')

	$('.totop a').click (e) ->
	  e.preventDefault()
	  $('body,html').animate {scrollTop: 0}, 500

	$.validator.addMethod("oneupperletter",  (value, element) ->
		return this.optional(element) || /[A-Z]/.test(value);
	, "Should have at least one upper case letter");

	$.validator.addMethod("onedigit", (value, element) ->
		return this.optional(element) || /[0-9]/.test(value);
	, "Should have at least one digit");

	$.validator.addMethod("integer", (value, element) ->
		return this.optional(element) || /^[0-9]+$/.test(value);
	, "Please enter an integer number");

	$.validator.addMethod("segment-total", (value, element) ->
		return (this.optional(element) && (value == '0' || value == '')) || value == '100';
	, "The sum of the segments should be 100%");

	$.validator.addMethod("matchconfirmation", (value, element) ->
		return value == $("#user_password").val();
	, "Doesn't match confirmation");


	$('.google-map[data-latitude]').each (index, container) ->
		$container = $(container)
		content = $container.html()
		placeLocation = new google.maps.LatLng($container.data('latitude'), $container.data('longitude'));

		mapOptions = {
			zoom: 13,
			center: placeLocation,
			scrollwheel: false,
			mapTypeId: google.maps.MapTypeId.ROADMAP
		};

		map = new google.maps.Map(container, mapOptions)

		styles = [
			{
				stylers: [
					{ hue: "#00ffe6" },
					{ saturation: -20 }
				]
			},{
				featureType: "road",
				elementType: "geometry",
				stylers: [
					{ lightness: 100 },
					{ visibility: "simplified" }
				]
			},{
				featureType: "road",
				elementType: "labels",
				stylers: [
					{ visibility: "off" }
				]
			}
		]

		map.setOptions {styles: styles}

		marker = new google.maps.Marker({
			map:map,
			draggable:false,
			animation: google.maps.Animation.DROP,
			position: placeLocation
		})

		theInfowindow = new google.maps.InfoWindow({
			content: content
		});

		google.maps.event.addListener marker, 'click',  ->
			theInfowindow.open(map, this)


# Hack to use bootsbox confirm dialog
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