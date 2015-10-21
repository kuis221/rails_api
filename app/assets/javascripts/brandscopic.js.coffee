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

	fixMainContainerTop = () ->
		setTimeout () ->
			$('body').css(paddingTop: $('header').outerHeight())
			$('#resource-close-details').css(top: $('header').outerHeight() + 'px')
		, 1

	fixMainContainerTop()

	$('header').on 'closed', '.alert', fixMainContainerTop

	$("a[rel=popover]").popover()
	$(".tooltip").tooltip()
	$("a[rel=tooltip]").tooltip()
	$("div.gallery").photoGallery()
	$('[data-spy]').each( (index, element) ->
		$(element).affix offset: {
			top: () ->
				if $(element).css('position') isnt 'fixed'
					$(element).data('offset', $(element).offset().top - $('header').outerHeight())
				$(element).data('offset')

		}
	)

	$(document).off('click.closeMenu').on 'click.closeMenu', '.dropdown-menu li a', (e) ->
		menu = $(this).closest(".dropdown-menu")
		if menu.parent().hasClass('open')
			menu.prev().dropdown("toggle")
		true

	$(document).on 'click', (e) ->
		$('.has-popover').each () ->
			if !$(this).is(e.target) && $(this).has(e.target).length is 0 && $('.popover').has(e.target).length is 0
				$(this).popover('hide')
		return if $(e.target).closest('.tooltip').length > 0
		$('.has-tooltip').each () ->
			tooltipElement = if $(e.target).hasClass('.has-tooltip') then e.target else $(e.target).closest('.has-tooltip')
			if !$(this).is(tooltipElement)
				$(this).tooltip('hide')

	bootbox.setBtnClasses {CANCEL: 'btn-cancel', OK: 'btn-primary', CONFIRM: 'btn-primary'}

	$(document).on 'click touchend', ".btn-group .btn input:radio", (e) ->
		$(@).closest('.btn').parent().find('.btn.active').removeClass('active')
		$(@).closest('.btn').addClass('active')
		true

	$(document).on 'click', '.toggle-input .btn', () ->
		$this = $(this);
		$this.parent().find('.btn').removeClass('btn-success btn-danger active')
		if $this.hasClass('set-on-btn')
			$this.addClass('btn-success active')
		else
			$this.addClass('btn-danger active')

		$this.parent().find('.toggle-input-hidden').val($this.data('value')).trigger 'click'
		false

	updateSegmentFields = () ->
		total = 0;
		segmentFieldId = $(this).data('segment-field-id')

		for element in $('[data-segment-field-id="' + segmentFieldId + '"].segment-field')
			if $(element).val().match(/^[0-9]+$/)
				total += parseInt($(element).val(), 10)

		progressClass = (if total == 100 then 'progress-success' else (total < 100 ? 'progress-info' : 'progress-danger'))
		textClass = (if total == 100 then 'text-success' else (total < 100 ? 'text-info' : 'text-error'))
		progressBarItem = $('#progress-bar-field-' + segmentFieldId)
		progressBarError = $('#progress-error-' + segmentFieldId)

		progressBarItem
			.removeClass('text-success text-error text-info').addClass(textClass)
			.find('.progress').removeClass('progress-success progress-info progress-danger').addClass(progressClass).end()
			.find('.bar').css({width: total+'%'}).end().find('.counter').text(total+'%');

		$("#total-field-" + segmentFieldId).val(if total then total else '')
		true

	$(document).on 'keyup', '.segment-field', () ->
		updateSegmentFields.apply this
		$("#total-field-" + $(this).data('segment-field-id')).valid()

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
			link = $("a[href=#{window.location.hash}]")
			if $(".nav-tabs a[href=#{window.location.hash}]").length > 0
				smoothScrollTo $(".nav-tabs a[href=#{window.location.hash}]").tab('show')
			else if $(window.location.hash).length > 0
				smoothScrollTo $(window.location.hash), link
		true


	updateCalculationTotals = () ->
		for wrapper in $('.form_field_calculation')
			((w) ->
				$wrapper = $(w)
				$options = $wrapper.find('.field-option:not(.calculation-total-field)')
				operation   = $wrapper.find('.calculation-field').data('operation')
				$options.keyup () ->
					siblings = $('.field-option[data-field-id=' + $(this).data('field-id') + ']:not(.calculation-total-field) input')
					values =  $.map $.map(siblings, (input)-> $(input).val()).filter((v)-> v != '' && typeof v isnt 'undefined'), (v) ->
						parseFloat(v, 10) || 0
					if values.length > 0
						total = values.reduce (a, b) ->
							eval "a #{operation} b"
					else
						total = ''
					total = '' if operation in ['/', '*'] && values.length < 2
					if isNaN(total)
						total = ''
					else if total && isFinite(total)
						total = ((total) + 0.00001).toFixed(4)
					total = (total + '').replace(/\.([^0]*)0+/, '.$1').replace(/\.$/, '')
					$wrapper.find('.calculation-total-amount').text(total)
					$wrapper.find('.calculation-total').val(total).valid()
				true
			)(wrapper)

	$(document).on 'propertychange input', '.calculation-field', () ->
		$(this).val($(this).val().replace(/[^\d\.\-]+/g,''));

	attachPluginsToElements = () ->
		$('input.datepicker').datepicker
			showOtherMonths:true
			selectOtherMonths:true
			dateFormat:"mm/dd/yy"
			onClose: (selectedDate) ->
				$(@).valid();
		$('input.timepicker').timepicker()
		$('select.chosen-enabled').chosen({allow_single_deselect: true})
		$('.has-tooltip').tooltip({html: true, delay: 0, animation: false})
		$('.has-popover').popover({html: true})
		$("input:checkbox, input:radio").not('[data-no-uniform="true"], #uniform-is-ajax, .bs-checkbox').uniform()

		$('.segment-field').each (i, element) ->
			updateSegmentFields.apply element

		$(".fancybox").fancybox {
			padding : 0,
			helpers : { title: { type: 'inside' } },
			beforeLoad: () ->
				this.title = $(this.element).attr('caption')
		}
		$('.places-autocomplete').placesAutocomplete();

		$(".btn-group .btn .checked input:radio").each (i, btn) ->
			$(btn).closest('.btn').addClass('active')

		$("a.smooth-scroll[href^='#']").off('click.branscopic').on 'click.branscopic', (e) ->
			e.preventDefault()
			smoothScrollTo $(this.hash), this

		$('form[data-watch-changes]').watchChanges();

		$('.attached_asset_upload_form').attachmentUploadZone();

		$('.attachment-attached-view.photo').photoGallery({showSidebar: false});

		$('.bs-checkbox:checkbox').bootstrapSwitch
			animated: false

		$('.select-list-seach-box').selectListSearch()

		$("abbr.timeago").timeago();

		updateCalculationTotals()

	window.smoothScrollTo = (element, link) ->
		return if element.length is 0
		$('html, body').animate {
			scrollTop: element.offset().top -
						($('#resource-close-details').outerHeight() || 0) -
						($('header').outerHeight() || 0) -
						($('.details-bar').outerHeight() || 0) -
						($('.guide-bar').outerHeight() || 0) -
						20
			}, 300, () ->
				$(link).trigger('smooth-scroll:end') if link


	$.validator.setDefaults {
		errorClass: 'help-inline',
		errorElement: 'span',
		ignore: '.no-validate',
		onfocusout: ( element, event ) ->
			if !this.checkable(element)
				this.element(element)
		highlight: (element) ->
			if $(element).closest('.field-option').length > 0
				$(element).removeClass('valid').closest('.field-option').removeClass('success').addClass('error')
			else
				$(element).removeClass('valid').closest('.control-group').removeClass('success').addClass('error')
				# For percentage fields
				$('#progress-error-' + $(element).data('segment-field-id')).removeClass('success').addClass('error')
				$('#progress-error-' + $(element).data('segment-field-id')).closest('.form_field_percentage').find('.control-group-label').find('.ok-message').remove()
		errorPlacement: (error, element) ->
			if element[0].value == '' && element.closest(".control-group").find("span.help-inline").length > 0
				$.noop
			else
				container = element.closest('.control-group').find('.field-error-container')
				if container.length
					container.html('').append error
					return
				label = element.closest(".control-group").find("label.control-label[for=\"#{element.attr('id')}\"]")
				label = element.closest(".control-group").find("label.control-label") if label.length is 0
				if element.is('input[type=file]')
					label = element.closest('.attachment-select-file-view')
				label.addClass('with_message')
				if label.length
					element.closest(".control-group").find("span.help-inline").remove()
					error.insertAfter label
		focusInvalid: false,
		invalidHandler: (form, validator) ->
			return unless validator.numberOfInvalids()
			window.EventDetails.showMessage($('form.event-data-form').data('per-save-failed'), 'red');
			element = $(validator.errorList[0].element)
			while element.is(":hidden")
				element = element.parent()

			$("html, body").animate
				scrollTop: element.offset().top - 200
			, 1000
		success: (element) ->
			element.addClass('valid').append('<span class="ok-message"><span>OK!</span></span>').closest('.control-group').removeClass('error')
			element.closest('.field-option').removeClass('error')
			# For percentage fields
			if (element.attr('id') && $('.segment-error-' + element.data('segment-field-id')).not('.valid').length == 0)
				$('#progress-for-' + element.data('segment-field-id')).removeClass('error')
				element.closest('.form_field_percentage').find('.control-group-label').find('.ok-message').remove()
				element.closest('.form_field_percentage').find('.control-group-label').append('<span class="ok-message"><span>OK!</span></span>')
		onkeyup: (element, event) ->
			items = items_count(element)
			$('#item-counter-' + $(element).data('field-id')).html(items);

			if event.which == 9 and @elementValue(element) == ''
				return true
	}

	window.makeFormValidatable = (e) ->
		e.validate()

	items_count = (field) ->
		number = 0

		if $(field).data('range-format') == 'characters'
			number = field.value.length
		else if $(field).data('range-format') == 'words'
			matches = $(field).val().split(' ')
			number = matches.filter((word) ->
				word.length > 0
			).length

		number

	# Check what graph labels are colliding with others and adjust the position
	$(window).on 'resize ready load', () ->
		adjustChartsPositions()
		lazyLoadElements()

	$(document).on 'ajaxComplete', () ->
		adjustChartsPositions()

	adjustChartsPositions = () ->
		$('.chart-bar').each (index, container) ->
			labels = $(container).find('.bar-label')
			maxLevel = 0
			for label, i in labels
				$label = $(label)
				# if $(label).text() is '101'
				position = $label.offset()
				level = 0
				for o, j in labels
					if j < i
						other = $(o)
						otherPosition = other.offset()
						if otherPosition.left+other.outerWidth() > position.left
							level = other.data('level') + 1
				$label.removeClass('level-1 level-2 level-3').addClass("level-#{level}").data('level', level)
				$label = null

				maxLevel = Math.max maxLevel, level

			$(container).removeClass('level-1 level-2 level-3').addClass("level-#{maxLevel}")

	validateForm = (e) ->
		if e.target.tagName is 'A'
			return true

		makeFormValidatable($(this))
		if not $(this).valid()
			e.preventDefault()
			e.stopPropagation()
			$.rails.enableFormElements $(this)
			false
		else
			button = $(this).find('input[type=submit], button')
			if $(".attached_asset_upload_form.uploading").length > 0
				if typeof this.activityInterval == 'undefined' || this.activityInterval == null
					e.stopPropagation()
					e.preventDefault()
					$.rails.stopEverything e
					$(button).addClass("waiting-files").attr("disabled", true).data("oldval", $(button).val()).val "Uploading file(s)..."
					this.activityInterval = setInterval( =>
						if $(".attached_asset_upload_form.uploading", this).length is 0
							$(button).attr("disabled", false).removeClass("waiting-files").val $(button).data("oldval")
							clearInterval this.activityInterval
							this.activityInterval = null
							$(button[0]).click();
						return
					, 500)

				false
			else
				true

	attachPluginsToElements()


	$(document).ajaxComplete (e) ->
		attachPluginsToElements()


	$(window).on 'beforeunload', ->
		unSavedForms = $('form[data-watch-changes]').filter((index) -> $(this).hasChanged(); )
		if unSavedForms.length
			unSavedForms.data('prompt-message') || "Your form data has not been saved."

	$(document).on 'submit', "form", validateForm
	$(document).on 'ajax:before', "form", validateForm


	$(document).off('click.newFeature').on 'click.newFeature', '.new-feature .btn-dismiss-alert', () ->
		alert = $(this).closest('.new-feature')
		$.ajax
			url: '/users/dismiss_alert'
			method: 'PUT'
			data: {name: alert.data('alert'), version: alert.data('version')}

		alert.remove()
		$(window).trigger 'alert:missed', [alert]
		false

	$(document).off('click.videoFeature').on 'click.videoFeature', 'a[data-video]', (e) ->
		bootbox.classes('video-modal')
		link = if e.target.tagName is 'A' then $(e.target) else $(e.target).closest('a')
		bootbox.modal($('<iframe allowfullscreen="" frameborder="0">').attr('src', link.data('video')).attr('width', link.data('width')).attr('height', link.data('height')), '&nbsp;')
		false


	$(document).on 'click', '.xlsx-download-link', () ->
		url = $(this).data('url') + (if $(this).data('url').indexOf('?') >= 0 then '&' else '?') + $('#collection-list-filters').filteredList('paramsQueryString')
		$.ajax url, {
			method: "GET"
			dataType: "script"
		}
		false

	$(document).bind 'dragover',  (e) ->
		dropZone = $('.drag-drop-zone')
		timeout = window.dropZoneTimeout
		if !timeout
			dropZone.addClass 'in'
		else
			clearTimeout timeout

		found = false
		node = e.target

		while node != null
			if $(node).hasClass('drag-drop-zone')
				found = true
				foundDropzone = $(node)
				break

			node = node.parentNode

		dropZone.removeClass('in hover')

		if found
			foundDropzone.addClass('hover')

		window.dropZoneTimeout = setTimeout () ->
			window.dropZoneTimeout = null
			dropZone.removeClass 'in hover'
		, 100

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
	$('#admin-select-block').hide()

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
			size = {width: Math.max(img.width, 100), height: Math.max(img.height, 100)}
			preview
				.css("top",  (position.top - (size.height/2) - 20) + "px")
				.css("left", (position.left - size.width - 20) + "px")

		if e.type is 'mouseenter'
			$("#imgpreview").remove()
			clearTimeout window.previewTimeout if window.previewTimeout?
			@t = @title
			@title = ""
			img = $('<img width=100 height=100 alt="Loading..." />').attr('src', this.getAttribute('data-preview-url'))
			preview = $("<p id='imgpreview'></p>").append(img).hide()
			$("body").append(preview)

			preview.find('img').load (e) =>
				img = e.target
				$(img).attr('width', "")
				$(img).attr('height', "")
				placePreviewInPosition this, preview
				preview.show()

			placePreviewInPosition this, preview
			preview.fadeIn "fast", => placePreviewInPosition this, preview

		else
			window.previewTimeout = window.setTimeout () =>
				@title = @t
				$("#imgpreview").remove()
				true
			, 100
	)

	$window = $(window)
	$window.scroll ->
		if $(this).scrollTop() > 200
			$('.totop').slideDown()
		else
			$('.totop').slideUp()

		lazyLoadElements();

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
		true


	lazyLoadElements = () ->
		wt = $(window).scrollTop()
		wb = wt + $(window).height()

		$(".lazyloaded").each () ->
			ot = $(@).offset().top;
			ob = ot + $(@).height();
			if not $(@).attr("loaded") && wt <= ob && wb >= ot
				$(@).removeClass "lazyloaded"
				$(@).load $(@).data('content-url')


	# Keep filter Sidebar always visible but make it scroll if it's
	# taller than the window size
	$filterSidebar = $('#resource-filter-column')
	lastTimestamp  = 0
	if $filterSidebar.length
		$filterSidebar.originalTop = $filterSidebar.position().top;
		$filterSidebar.originalWidth = $filterSidebar.width();
		$filterSidebar.positioning = false
		$window.bind("scroll resize DOMSubtreeModified", () ->
			now = new Date().getTime() # Add a small delay between each execution because FF seems to
										 # trigger this too frequently drastically affecting the performance
			if $.loadingContent is 0 && lastTimestamp < (now - 50)
				lastTimestamp = now
				if $window.width() >= 979 # For the responsive design
					if $filterSidebar.positioning or $('.chardinjs-overlay').length != 0
						return true
					$filterSidebar.positioning = true
					$filterSidebar.removeClass('responsive-mode')
					sidebarBottom = $filterSidebar.outerHeight()+$filterSidebar.originalTop;
					bottomPosition = $window.scrollTop()+$window.height()
					footerHeight = $('footer').outerHeight()
					headerHeight = $('header').outerHeight() + 10

					# We need to get the natural top of the bar when it's not absolute or fixed positioned
					$filterSidebar.css position: 'static'
					$filterSidebar.originalTop = $filterSidebar.position().top;

					if sidebarBottom < $window.height()
						if $filterSidebar.originalTop > ($window.scrollTop() + headerHeight)
							$filterSidebar.css {
								position: 'relative',
								top: '',
								right: '',
								bottom: ''
							}
						else
							$filterSidebar.css {
								position: 'fixed',
								top: "#{headerHeight + 42}px",
								right: "10px",
								bottom: 'auto'
							}
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
			true
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
		$('body,html').animate { scrollTop: 0 }, 500

	percentageTimeouts = {}
	$(document).on 'blur', 'input.segment-field', () ->
		if !$(this).val()
			$(this).val(0).valid()
		fieldId = $(this).data('segment-field-id')
		percentageTimeouts[fieldId] = setTimeout () ->
			$("input.segment-total[data-segment-field-id=#{fieldId}]").valid()
		, 200

	$(document).on 'focus', 'input.segment-field', () ->
		fieldId = $(this).data('segment-field-id')
		clearTimeout percentageTimeouts[fieldId] if percentageTimeouts[fieldId]

	$(document).on 'blur', 'input.calculation-field', () ->
		if !$(this).val()
			$(this).val(0).valid()
			$(this).keyup()

	$(document).on 'change', 'select.select', () ->
		$(this).valid()

	$.validator.addMethod("oneupperletter",  (value, element) ->
		return $.trim(value) == '' || /[A-Z]/.test(value);
	, "Should have at least one upper case letter");

	$.validator.addMethod("onedigit", (value, element) ->
		return $.trim(value) == '' || /[0-9]/.test(value);
	, "Should have at least one digit");

	$.validator.addMethod("integer", (value, element) ->
		return $.trim(value) == '' || /^[0-9]+$/.test(value);
	, "Please enter an integer number");

	$.validator.addMethod("required-file", (value, element) ->
		hidden = $(element).closest('.attached_asset_upload_form').find('.direct_upload_url')
		destroy = $(element).closest('.attached_asset_upload_form').find('[name$="[_destroy]"]')
		return $.trim(hidden.val()) isnt '' && destroy.val() isnt '1';
	, "Must select a file");

	$.validator.addMethod("segmentTotalRequired", (value, element) ->
		return ($(element).hasClass('optional') && ($.trim(value) == '' || $.trim(value) == '0')) || value == '100';
	, "Field must sum to 100%");

	$.validator.addMethod("segmentTotalMax", (value, element) ->
		intVal = parseInt(value);
		return ($.trim(value) == '' || intVal <= 100);
	, "Field cannot exceed 100%");

	$.validator.addMethod('greaterthan',  (value, el, param) ->
			return value > param;
	,  jQuery.validator.format("Must be greater than {0}"));

	$.validator.addClassRules("segment-total", { segmentTotalMax: true, segmentTotalRequired: true });

	$.validator.addMethod("segment-field", (value, element) ->
		if !$(element).val()
			$(element).val(0).valid()
		return (value == '' || (/^[0-9]+$/.test(value) && parseInt(value) <= 100));
	, ' ');

	$.validator.addMethod("calculation-field-segment-divide", (value, element) ->
		index = $(element).data('index')
		return $(element).val() == '' || parseFloat($(element).val(), 10) isnt 0 || index is 0
	, ' ');

	$.validator.addMethod("calculation-field-divide", (value, element) ->
		group = $(element).data('group')
		for element, index in $('[data-group="'+group+'"]').get()
			if index > 0 && $(element).val() is '0'
				return false
		true
	, 'You must divide by a number different than 0');

	$.validator.addMethod("likert-field", (value, element) ->
		if $('.likert-scale-' + $(element).data('likert-error-id')).closest('.form_field_likert_scale').find('label').hasClass('optional')
			return true
		else
			fields = $('.likert-scale-' + $(element).data('likert-error-id')).find('.likert-fields')
			valid = true
			i = 0
			while i < fields.length
				if element.type == 'checkbox'
					if $(fields[i]).find('input:checkbox:checked').length <= 0
						valid = false
				else
					if !$(fields[i]).find('.likert-field').is(':checked')
						valid = false
				i++
			return valid;
	, 'This field is required.');

	$.validator.addMethod("optional", (value, element) ->
		return true;
	, "");

	$.validator.addMethod("matchconfirmation", (value, element) ->
		return value == $("#user_password").val();
	, "Doesn't match confirmation");

	$.validator.addMethod("datepicker", (value, element) ->
		return this.optional(element) || /^[0-1]?[0-9]\/[0-3]?[0-9]\/[0-2]0[0-9][0-9]$/.test(value);
	, "MM/DD/YYYY");

	$.validator.addMethod("elements-range", (value, element) ->
		$element = $(element)
		if value.length > 0
			val = $.trim(value)
			if $element.data('range-format') is "characters" || $element.data('range-format') is "digits"
				items = val.length
			else if $element.data('range-format') is "words"
				items = val.replace(/\s+/g, " ").split(" ").length
			else if $element.data('range-format') is "value"
				items = parseFloat(value, 10)
			else if $element.data('range-format') is "digits"
				items = val.replace(/[\s,\,\,]+/g, "").length
		else if $element.data('range-format') is "characters" || $element.data('range-format') is "words"
			items = 0

		if $.inArray($element.data('range-format'), ['value', 'characters', 'words']) > -1 && items == 0
			# Special case when format is value, chars or words and items is zero because zero is evaluated as false
			minResult = if $element.data('range-min') then items >= $element.data('range-min') else true
			maxResult = if $element.data('range-max') then items <= $element.data('range-max') else true
		else
			minResult = if $element.data('range-min') && items then items >= $element.data('range-min') else true
			maxResult = if $element.data('range-max') && items then items <= $element.data('range-max') else true

		return minResult && maxResult
	, ' ');

	$(window).load () ->
		setTimeout () ->
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
		, 100

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


	$(document).on 'click', '#select-specific-user', (e) ->
		e.stopPropagation()
		e.preventDefault()
		$('.admin-login-content').load('/users/login_as_select.html')
		false


# Hack to use bootbox's confirm dialog
$.rails.allowAction = (element) ->
	# check if
	if element.is('input[type=submit]') && !$(element[0].form).valid()
		return false

	message = element.data('confirm')
	if !message
		return true

	if $.rails.fire(element, 'confirm')
			bootbox.confirm message, (answer) ->
				if answer
					callback = $.rails.fire(element, 'confirm:complete', [answer])
					if callback
						oldAllowAction = $.rails.allowAction
						$.rails.allowAction = -> return true
						element.trigger('click')
						$.rails.allowAction = oldAllowAction
	false