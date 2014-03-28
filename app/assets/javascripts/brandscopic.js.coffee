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

	$("a[rel=popover]").popover()
	$(".tooltip").tooltip()
	$("a[rel=tooltip]").tooltip()
	$("div.gallery").photoGallery()

	$(document).on 'click', (e) ->
		$('.has-popover').each () ->
			if !$(this).is(e.target) && $(this).has(e.target).length is 0 && $('.popover').has(e.target).length is 0
				$(this).popover('hide')

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

		# Check if we should automatically activate a tab on the app
		if window.location.hash
			smoothScrollTo $(".nav-tabs a[href=#{window.location.hash}]").tab('show')

	attachPluginsToElements = () ->
		$('input.datepicker').datepicker({showOtherMonths:true,selectOtherMonths:true,dateFormat:"mm/dd/yy" })
		$('input.timepicker').timepicker()
		$('.chosen-enabled').chosen()
		$('.has-tooltip').tooltip({html: true})
		$('.has-popover').popover({html: true})
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

		$('form[data-watch-changes]').watchChanges();

	window.smoothScrollTo = (element) ->
		$('html, body').animate({ scrollTop: element.offset().top - ($('#resource-close-details').outerHeight() || 0) - ($('header').outerHeight() || 0) - 20 }, 300)


	window.makeFormValidatable = (e) ->
		e.validate {
			errorClass: 'help-inline',
			errorElement: 'span',
			ignore: '.no-validate',
			onfocusout: ( element, event ) ->
				if !this.checkable(element)
					this.element(element)
			highlight: (element) ->
				$(element).removeClass('valid').closest('.control-group').removeClass('success').addClass('error')

			errorPlacement: (error, element) ->
				label = element.closest(".control-group").find("label.control-label[for=\"#{element.attr('id')}\"]")
				label.addClass('with_message')
				if label.length > 0
					if typeof element.data('segmentFieldId') isnt "undefined"
						error.addClass('segment-title-label').insertBefore label
					else
						error.insertAfter label
				else
					error.addClass('segment-title-label').insertAfter element

			focusInvalid: false,
			invalidHandler: (form, validator) ->
				return unless validator.numberOfInvalids()
				element = $(validator.errorList[0].element)
				while element.is(":hidden")
					element = element.parent()

				$("html, body").animate
					scrollTop: element.offset().top - 200
				, 1000
			success: (element) ->
				element.addClass('valid').append('<span class="ok-message"><span>OK!</span></span>')
					.closest('.control-group').removeClass('error')
		}

	validateForm = (e) ->
		if e.target.tagName is 'A'
			return true

		makeFormValidatable($(this))

		if not $(this).valid()

			e.preventDefault()
			e.stopPropagation()
			false

	attachPluginsToElements()


	$(document).ajaxComplete (e) ->
		attachPluginsToElements()


	$(window).on 'beforeunload', ->
		unSavedForms = $('form[data-watch-changes]').filter((index) -> $(this).hasChanged(); )
		if unSavedForms.length
			unSavedForms.data('prompt-message') || "Your form data has not been saved."

	$(document).on 'submit', "form", validateForm
	$(document).on 'ajax:before', "form", validateForm

	$(document).on 'click', '.xlsx-download-link', () ->
		url = $(this).data('url') + '?'+ $('#collection-list-filters').filteredList('paramsQueryString')
		$.ajax url, {
			method: "GET"
			dataType: "script"
		}
		false

	# Fix warning https://github.com/thoughtbot/capybara-webkit/issues/260
	$(document).on 'ajax:beforeSend', 'a[data-remote="true"][data-method="post"]', (event, xhr, settings) ->
		if settings.type == 'POST'
			xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')


	$(document).delegate '.modal .btn-cancel', 'click', (e) ->
		e.preventDefault()
		bootbox.hideAll()
		false

	$(document).on 'click', 'a[data-submit-link]', (e) ->
		e.preventDefault()
		$(this).closest('form').submit()
		false

	$(document).delegate 'input.kpi-goal-field, input.activity-type-goal-field', 'blur', (e) ->
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
						activity_type_id: $this.data('activity-type-id'),
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

		placePreviewInPosition = (elm, preview) ->
			position = $(elm).offset()
			img = new Image()
			img.src = preview.find('img').attr('src')
			size = {width: img.width, height: img.height}
			preview
				.css("top",  (position.top - (size.height/2) - 10) + "px")
				.css("left", (position.left - size.width - 10) + "px")

		if e.type is 'mouseenter'
			this.t = this.title
			this.title = ""
			c = if this.t != "" then "<br/>" + this.t else ""
			preview = $("<p id='imgpreview'><img src='#{this.getAttribute('data-preview-url')}' width=100 height=100 alt='Image preview' />#{c}</p>")
			$("body").append(preview)
			preview.find('img').load (e) =>
				img = e.target
				$(img).attr('width', "")
				$(img).attr('height', "")
				placePreviewInPosition this, preview

			placePreviewInPosition this, preview
			preview.fadeIn "fast", => placePreviewInPosition this, preview

		else
			this.title = this.t
			$("#imgpreview").remove()
	)

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


	# Keep filter Sidebar always visible but make it scroll if it's
	# taller than the window size
	$filterSidebar = $('#resource-filter-column')
	if $filterSidebar.length
		$filterSidebar.originalTop = $filterSidebar.position().top;
		$filterSidebar.originalWidth = $filterSidebar.width();
		$filterSidebar.positioning = false
		$window.bind("scroll resize DOMSubtreeModified", () ->
			if $window.width() >= 979 # For the responsive design
				if $filterSidebar.positioning or $('.chardinjs-overlay').length != 0
					return true
				$filterSidebar.positioning = true
				$filterSidebar.removeClass('responsive-mode')
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
			else # On small screens, leave it static
				$filterSidebar.css({position: ''}).addClass('responsive-mode')
		).trigger('scroll')

	$(document).on 'click', '[data-toggle="filterbar"]', (e) ->
		e.preventDefault()
		if $filterSidebar.hasClass('collapsed')
			$filterSidebar.removeClass('collapsed').addClass('expanded').css('width','')
			$('.list-filter-btn').css({right: $filterSidebar.outerWidth()+'px', zIndex: 9999});
			$filterSidebar.find('.slider-range').rangeSlider('resize')
			# $filterSidebar.animate { "width": "#{$filterSidebar.originalWidth}px" }, "slow", () ->
			# 	$(this).removeClass('collapsed').addClass('expanded').css('width','')
			# 	$('.list-filter-btn').css({right: $filterSidebar.outerWidth()+'px', zIndex: 9999});
		else
			$('.list-filter-btn').css({right: '0px', zIndex: 1});
			# $filterSidebar.animate { "width": 0 }, "slow", () ->
			# 	$(this).removeClass('expanded').addClass('collapsed').css('width','')
			$filterSidebar.removeClass('expanded').addClass('collapsed').css('width','')

	$('.totop a').click (e) ->
		e.preventDefault()
		$('body,html').animate {scrollTop: 0}, 500

	$.validator.addMethod("oneupperletter",  (value, element) ->
		return $.trim(value) == '' || /[A-Z]/.test(value);
	, "Should have at least one upper case letter");

	$.validator.addMethod("onedigit", (value, element) ->
		return $.trim(value) == '' || /[0-9]/.test(value);
	, "Should have at least one digit");

	$.validator.addMethod("integer", (value, element) ->
		return $.trim(value) == '' || /^[0-9]+$/.test(value);
	, "Please enter an integer number");

	$.validator.addMethod("segmentTotalRequired", (value, element) ->
		return ($(element).hasClass('optional') && ($.trim(value) == '' || $.trim(value) == '0')) || value == '100';
	, "Field should sum 100%");

	$.validator.addMethod("segmentTotalMax", (value, element) ->
		intVal = parseInt(value);
		return ($.trim(value) == '' || intVal <= 100);
	, "Field cannot exceed 100%");

	$.validator.addClassRules("segment-total", { segmentTotalMax: true, segmentTotalRequired: true });

	$.validator.addMethod("segment-field", (value, element) ->
		return (value == '' || (/^[0-9]+$/.test(value) && parseInt(value) <= 100));
	, " ");

	$.validator.addMethod("optional", (value, element) ->
		return true;
	, "");

	$.validator.addMethod("matchconfirmation", (value, element) ->
		return value == $("#user_password").val();
	, "Doesn't match confirmation");

	$.validator.addMethod("datepicker", (value, element) ->
		return this.optional(element) || /^[0-1]?[0-9]\/[0-3]?[0-9]\/[0-2]0[0-9][0-9]$/.test(value);
	, "MM/DD/YYYY");


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

# Hack to use bootbox's confirm dialog
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

