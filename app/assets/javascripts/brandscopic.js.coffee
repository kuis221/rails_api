jQuery ->
	window.MAP_STYLES = [
		{
			stylers: [
				{ hue: "#00ffe6" },
				{ saturation: -100 },
				{ gamma: 0.8 }
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
		},{
			featureType: "road.arterial",
			elementType: "geometry",
			stylers: [
				{ color: "#BABABA" }
			]
		}
	]

	bootbox.setBtnClasses {CANCEL: 'btn-cancel', OK: 'btn-primary', CONFIRM: 'btn-primary'}

	$('header .nav #notifications').notifications();

	$(window).load () =>
		if ($.browser.webkit)
			$('html').addClass('webkit')
		else if ($.browser.opera)
			$('html').addClass('opera')
		else if $.browser.msie
			$('html').addClass('msie')
		else if $.browser.mozilla
			$('html').addClass('mozilla')

	attachPluginsToElements = () ->
		$('input.datepicker').datepicker({showOtherMonths:true,selectOtherMonths:true})
		$('input.timepicker').timepicker()
		$('.chosen-enabled').chosen()
		$('.has-tooltip').tooltip()
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

		$("a.smooth-scroll[href^='#']").off('click.branscopic').on 'click.branscopic', (e) ->
			e.preventDefault()
			e.stopPropagation()
			smoothScrollTo($(this.hash))

	window.smoothScrollTo = (element) ->
		$('html, body').animate({ scrollTop: element.offset().top - ($('#resource-close-details').outerHeight() || 0) - ($('header').outerHeight() || 0) - 20 }, 300)


	validateForm = (e) ->
		if e.target.tagName is 'A'
			return true

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
		$elm.sparkline values, { type: $elm.data('sparkline'), barWidth: 1, barSpacing: 1, barColor: '#3E9CCF', height: '20px' }


	# Fix warning https://github.com/thoughtbot/capybara-webkit/issues/260
	$(document).on 'ajax:beforeSend', 'a[data-remote="true"][data-method="post"]', (event, xhr, settings) ->
		if settings.type == 'POST'
			xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')


	$(document).delegate 'input[type=checkbox][data-filter]', 'click', (e) ->
		$($(this).data('filter')).dataTable().fnDraw()

	$(document).delegate '.modal .btn-cancel', 'click', (e) ->
		e.preventDefault()
		bootbox.hideAll()
		false

	$(document).delegate 'input.kpi-goal-field', 'blur', (e) ->
		$this = $(this)



		id = $this.data('id')
		# then check if the value is valid
		if isValidGoal($this)

			# Get the value without formatting (only with the decimals)
			value = cleanGoalValue($this)

			# Format the value
			$this.val(formatGoalValue($this))

			# First, check if the data have not changed since the last save and return false if it hasn't
			if value == $this.data('value')
				return true

			$this.parents('.error').removeClass('error')

			# disable changes on the field while it's being saved
			$this.attr('disabed', true)

			# and save the value
			$.ajax("/goals#{if id then '/'+id else ''}.json", {
				method: "#{if id then "PUT" else "POST"}",
				data: {
					goal: {
						kpi_id: $this.data('kpi-id'),
						kpis_segment_id: $this.data('segment-kpi-id'),
						value: value,
						goalable_id: $this.data('goalable-id'),
						goalable_type: $this.data('goalable-type'),
						parent_id: $this.data('parent-id'),
						parent_type: $this.data('parent-type')
					}
				},
				dataType: 'json',
				success: (response) ->
					$this.data('value', value)
					$this.data('id', response.id)
				complete: (response) ->
					$this.attr('disabed', true)
			})
		else
			# mark the field or segment groups as invalid
			$this.closest('.kpi-segment-group').addClass('error')
			$this.closest('label').addClass('error')

	isValidGoal = (field) ->
		value = cleanGoalValue(field)
		field.val(value)
		if value == ''
			true
		else if !/^[0-9]+(\.[0-9]+)?$/.test(value)
			false
		else if field.hasClass('percentage')
			$li = field.closest('li')
			total = 0
			for segment in $li.find("input[data-kpi-id=#{field.data('kpi-id')}]")
				total += if segment.value then parseInt(segment.value) else 0
			valid = if total <= 100 then true else false
			error_id = "error-kpi-#{field.data('kpi-id')}"
			if !valid
				if $('.goalable-errors').find("##{error_id}").length == 0
					$('.goalable-errors').append($('<div class="alert-danger" id="'+error_id+'">').text("The combined goals for #{field.data('kpi-name')} should not exceed 100%"))
			else
				$('.goalable-errors').find("##{error_id}").remove()
			valid
		else
			true

	window.formatGoalValue = (field) ->
		val = cleanGoalValue(field)
		if val isnt ''
			if field.hasClass('decimal') or field.hasClass('currency')
				val = $.number(val, 2)
			else if field.hasClass('integer')
				val = $.number(val, 0)

			if field.hasClass('currency')
				val = "$#{val}"

			if field.hasClass('percentage')
				val = "#{val}%"

		val

	cleanGoalValue = (field) ->
		field.val().replace(/[^0-9\.]/g,'')

	$(".totop").hide()

	# TimeZone change detection methods
	window.checkUserTimeZoneChanges = (userTimeZone, lastDetectedTimeZone) ->
		browserTimeZone = $window.get_timezone()
		if browserTimeZone? and browserTimeZone != ''
			if userTimeZone != browserTimeZone && browserTimeZone != lastDetectedTimeZone
				askForTimeZoneChange(browserTimeZone)

	askForTimeZoneChange = (browserTimeZone) ->
		$.get '/users/time_zone_change.js', {time_zone: browserTimeZone}


	# For images previews on hover
	$(document).delegate("a[data-preview-url]", 'mouseenter mouseleave', (e) ->
		xOffset = 10
		yOffset = 30
		if e.type is 'mouseenter'
			this.t = this.title
			this.title = ""
			c = if this.t != "" then "<br/>" + this.t else ""
			$("body").append("<p id='imgpreview'><img src='#{this.getAttribute('data-preview-url')}' alt='Image preview' />#{c}</p>")
			$("#imgpreview")
				.css("top",  (e.pageY - xOffset) + "px")
				.css("left", (e.pageX + yOffset) + "px")
				.fadeIn("fast")
		else
			this.title = this.t
			$("#imgpreview").remove()
	)


	# Keep filter Sidebar always visible but make it scroll if it's
	# taller than the window size
	$filterSidebar = $('#resource-filter-column')
	$window = $(window)
	$window.scroll ->
		if $(this).scrollTop() > 200
			$('.totop').slideDown()
		else
			$('.totop').slideUp()

		$detailsBar = $('#resource-close-details')
		if $detailsBar.length > 0
			$alternateInfo = $('.details-bar-info').get().reverse()
			if $alternateInfo.length > 0
				$link = $detailsBar.find('a.close-details')
				found = false
				for div in $alternateInfo
					$div = $(div)
					if $div.offset().top  < ($detailsBar.offset().top + $detailsBar.height())
						if not $link.data('default-content')
							$link.data 'default-content', $link.html()
						$link.html $div.html()
						found = true
						break
				if not found and $link.data('default-content')
					$link.html $link.data('default-content')
					$link.data 'default-content', null


	if $filterSidebar.length
		$filterSidebar.originalTop = $filterSidebar.position().top;
		$filterSidebar.positioning = false
		$window.bind("scroll resize DOMSubtreeModified", () ->
			if $filterSidebar.positioning or $('.chardinjs-overlay').length != 0
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

	$.validator.addMethod("segment-field", (value, element) ->
		return (value == '' || (/^[0-9]+$/.test(value) && parseInt(value) <= 100));
	, "Should not exceed 100%");

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

		map.setOptions {styles: window.MAP_STYLES}

		pinImage = new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|de4d43",
			new google.maps.Size(21, 34),
			new google.maps.Point(0,0),
			new google.maps.Point(10, 34));

		marker = new google.maps.Marker({
			map:map,
			draggable:false,
			icon: pinImage,
			animation: google.maps.Animation.DROP,
			position: placeLocation
		})

		theInfowindow = new google.maps.InfoWindow({
			content: content
		});

		google.maps.event.addListener marker, 'click',  ->
			theInfowindow.open(map, this)

	pfx = ["webkit", "moz", "ms", "o", ""]

	checkFullscreenSupport = ->
		# check for native support
		supported = false
		unless typeof document.cancelFullScreen is "undefined"
			supported = true
		else
			# check for fullscreen support by vendor prefix
			p = 0
			while p < pfx.length
				fullScreenApi.prefix = pfx[p]
				unless typeof document[fullScreenApi.prefix + "CancelFullScreen"] is "undefined"
					supported = true
					break
				p++
		supported

	runPrefixMethod = (obj, method) ->
		p = 0
		m = undefined
		t = undefined
		while p < pfx.length and not obj[m]
			m = method
			m = m.substr(0, 1).toLowerCase() + m.substr(1)  if pfx[p] is ""
			m = pfx[p] + m
			t = typeof obj[m]
			unless t is "undefined"
				pfx = [pfx[p]]
				return ((if t is "function" then obj[m]() else obj[m]))
			p++

	goFullscreen = (id) ->
		if (checkFullscreenSupport)
			e = document.getElementById(id)
			if runPrefixMethod(document, "FullScreen") or runPrefixMethod(document, "IsFullScreen")
				runPrefixMethod document, "CancelFullScreen"
			else
				runPrefixMethod e, "RequestFullScreen"
		else
			bootbox.alert("Your browser don't support fullcreen mode")

	$(document).delegate '.fullscreen-link', 'click', ->
		goFullscreen $(this).data("fullscreen-element")
		false

	$(".reject-post-event").click (e) ->
		e.preventDefault()
		$link = $(this)
		bootbox.classes('modal-med rejection-prompt')
		bootbox.prompt "Why is the post event being rejected?",'Cancel', 'Submit', (result) ->
			if result isnt null and result isnt ""
				$.ajax $link.attr("href"),
					method: "PUT"
					dataType: "script"
					data:
						reason: result
			else if result isnt null
				bootbox.alert "You must enter a reason for the rejection", ->
					$link.click()

		false

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