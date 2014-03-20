photoGalleryCounter = 0
$.widget 'nmk.photoGallery', {
	options: {
		month: null,
		year: null,
		eventsUrl: null,
		renderMonthDay: null,
		includeTags: false
	},

	_create: () ->
		@element.addClass('photoGallery')
		@_createGalleryModal()

		$(document).on 'attached_asset:activated', (e, id) =>
			@image.data('status', true)
			@gallery.find('a.photo-deactivate-link').replaceWith($('<a class="icon-remove-circle photo-deactivate-link" title="Deactivate" data-remote="true" data-confirm="Are you sure you want to deactivate this photo?"></a>').attr('href', @image.data('urls').deactivate))
			true

		$(document).on 'attached_asset:deactivated', (e, id) =>
			@photoToolbar.html ''
			$('.carousel', @gallery).carousel('next')
			@gallery.find('[data-photo-id='+id+']').remove()
			true

		$(document).on 'click', '.photoGallery a[data-toggle="gallery"]', (e) =>
			image = if e.target.tagName is 'A' then $(e.target).find('img')[0] else e.target
			e.stopPropagation()
			e.preventDefault()
			@gallery.modal 'show'
			@buildCarousels image
			@fillPhotoData image
			false
		@

	fillPhotoData: (currentImage) ->
		$image = $(currentImage)
		@image = $image
		@setTitle $image.data('title'), @image.data('urls').event
		@setDate $image.data('date')
		@setAddress $image.data('address')
		@setRating $image.data('rating'), $image.data('id')
		if @options.includeTags
			@setTags ['2013', 'jameson', 'jaskot', 'whiskey', 'chicago-team']

	setTitle: (title, url) ->
		@title.html $('<a>').attr('href', url).text(title)

	setRating: (rating, asset_id) ->
		if 'view_rate' in @image.data('permissions')
			can_rate = (if 'rate' in @image.data('permissions') then true else false)
			$stars = new Array(5)
			$i = 0
			while $i < rating
				$stars[$i] = @_createStar($i+1,true, asset_id, can_rate)
				$i++
			while $i < 5
				$stars[$i] = @_createStar($i+1,false, asset_id, can_rate)
				$i++

			@rating.html ''
			@rating.append $stars
			@rating.show()
		else
			@rating.hide()

	setDate: (date) ->
		if date
			@date.html(date).show()
		else
			@date.html('').hide()

	setAddress: (address) ->
		@address.html address

	setTags: (tags) ->
		@tags.html ''
		@tags.append($('<div class="tag">').text(tag).prepend($('<span class="close">'))) for tag in tags

	buildCarousels: (currentImage) ->
		i = index = 0
		active = false
		row = null

		miniCarousel = @miniCarousel.find('.carousel-inner')
		carousel = @carousel.find('.carousel-inner')
		miniCarousel.html('')
		carousel.html('')
		for link in @element.find('a[data-toggle=gallery]')
			image = $(link).find('img')[0]
			if i % 3 is 0
				if row?
					miniCarousel.append($('<div class="item">').append(row).addClass(if active then 'active' else null))
				row = $('<div class="row">')
				active = false

			if currentImage == image
				active = true

			row.append($('<img>').attr('src', image.src).data('image',image).attr('data-photo-id', $(image).data('id')).data('index', index))
			carousel.append $('<div class="item">').
				attr('data-photo-id', $(image).data('id')).
				append($('<div class="row">').append($('<img>').attr('src', '').data('src',link.href))).
				data('image',image).
				data('index', index).
				addClass(if currentImage == image then 'active' else '')
			i+=1
			index+=1

		miniCarousel.append($('<div class="item">').append(row).addClass(if active then 'active' else null))


		@miniCarousel.off('click.thumb').on 'click.thumb', 'img', (e) =>
			index = $(e.target).data('index')
			@carousel.carousel index

		@miniCarousel.appendTo @gallery.find('.mini-slider')

		@miniCarousel.carousel 'pause'

	_createStar: ($i,$is_full, $asset_id, can_rate) ->
		$klass = ""
		if $is_full
			$klass = "icon-star full"
		else
			$klass = "icon-star empty"
		star = $('<span class="'+$klass+'" value="'+$i+'"/>')
		if can_rate
			star.click (e) =>
				@image.data('rating', $i)
				$.ajax "/attached_assets/"+$asset_id+'/rate', {
					method: 'PUT',
					data: { rating: $i},
					dataType: 'json'
				}
			.mouseover (e) =>
				@rating.find('span').removeClass('empty').addClass('empty').css('cursor','pointer')
				@rating.find('span').slice(0,$i).addClass('full').removeClass('empty')

		star

	_createGalleryModal: () ->
		@title = $('<h3>')
		@address = $('<div class="place-data">')
		@date = $('<div class="calendar-data">')
		@rating = $('<div class="rating">')
			.mouseleave (e) =>
				@rating.find('span').removeClass('full').addClass('empty')
				@rating.find('span').slice(0,@image.data('rating')).addClass('full').removeClass('empty')

		if @gallery
			@gallery.remove();
			@gallery.off('shown')

		if @carousel
			@carousel.off('slid').remove()

		@gallery = $('<div class="gallery-modal modal hide fade">').append(
			$('<div class="gallery-modal-inner">').append(
				$('<div class="panel">').
					append('<button class="close" data-dismiss="modal" aria-hidden="true" title="Close"></button>').
					append(
						$('<div class="description">').append( @title ).append( @date ).append( @address ),
						$('<div class="mini-slider">').append( @miniCarousel = @_createCarousel('small') ),
						@rating,
						(if @options.includeTags then $('<div class="tags">').append( @tags = $('<div class="list">') , $('<input class="typeahead">')) else null)
					),
				$('<div class="slider">').append( $('<div class="slider-inner">').append( @carousel = @_createCarousel() ) ).append( @photoToolbar = $('<div class="photo-toolbar">') )
			).append($('<div class="clearfix">'))
			)


		@gallery.insertAfter @element

		@gallery.on 'shown', () =>
			@_showImage()
			$(window).on 'resize.gallery', =>
				@_updateSizes()
			$(document).on 'keyup.gallery', (e) =>
				if e.which is 39
					$('.carousel').carousel('next');
					e.preventDefault();
					false
				else if e.which is 37
					$('.carousel').carousel('prev');
					e.preventDefault();
					false
				else if e.which is 27
					@gallery.modal 'hide'
					e.preventDefault();
					false
			.on 'hidden', () =>
				$(window).off 'resize.gallery'
				$(document).off 'keyup.gallery'


		# Just some shortcuts
		@slider = @gallery.find('.slider')
		@sliderInner = @gallery.find('.slider-inner')
		@panel = @gallery.find('.panel')


		@miniCarousel.carousel({interval: false})
		@carousel.carousel({interval: false})

		@carousel.on 'slid', (e) =>
			item = $('.item.active', e.target)
			image = item.data('image')
			@fillPhotoData image
			@_showImage()
			@miniCarousel.carousel parseInt(item.data('index')/3)

		@gallery

	_showImage: () ->
		item = $('.item.active', @slider)
		image = item.find('img')
		if typeof image.attr('src') == 'undefined' || image.attr('src') == ''
			image.css({opacity: 0}).attr('src', image.data('src')).on 'load', (e) =>
				$(e.target).css({opacity: 1})
				@_updateSizes()
		else
			@_updateSizes()

		@_createPhotoToolbar()

		# Preload the next image
		nextItem = item.next('.item')
		if nextItem.length
			img = new Image()
			img.src = nextItem.find('img').data('src')


	_createPhotoToolbar: () ->
		@photoToolbar.html ''
		@photoToolbar.append(
			urls = @image.data('urls')
			(if 'deactivate_photo' in @image.data('permissions')
				if @image.data('status') == true
					$('<a class="icon-remove-circle photo-deactivate-link" title="Deactivate" data-remote="true" data-confirm="Are you sure you want to deactivate this photo?"></a>').attr('href', urls.deactivate)
				else
					$('<a class="icon-ok-circle photo-deactivate-link" title="Activate" data-remote="true"></a>').attr('href', urls.activate)
			else
				null
			),
			(if 'index_photo_results' in @image.data('permissions')
				$('<a class="icon-plus photo-download-link" title="Select Photo"></a>').attr('href', urls.download)
			else
				null
			)
		)

	_createCarousel: (carouselClass='') ->
		id = "gallery-#{@_generateUid()}"
		$('<div id="'+id+'" class="gallery-carousel carousel">').addClass(carouselClass).append(
			$('<div class="carousel-inner">'),
			$('<a class="carousel-control left" data-slide="prev" href="#'+id+'"><span></span></a>'),
			$('<a class="carousel-control right" data-slide="next" href="#'+id+'"><span></span></a>')
		)

	_updateSizes: () ->
		# If the current image's height is greater than the carousel's height then
		# changes the carousel's height to that height but only if it's not higher than
		# the windows height, in that case the image is resized to that
		image = @carousel.find('.active img')

		# Get image natural size
		imageNatural = @getNatural(image[0])

		# Set the slider/images widths based on the  available space and image dimensions
		minSliderWidth = parseInt(@slider.css('min-width')) or 400
		minSliderHeight = parseInt(@slider.css('min-height')) or 470
		maxSliderHeight = windowHeight-20
		windowWidth = $(window).width()
		windowHeight = $(window).height()
		maxSliderWidth = windowWidth-@panel.outerWidth()-20
		maxSliderHeight = windowHeight-20
		sliderWidth = @slider.width()
		sliderHeight = @slider.height()

		imageWidth = Math.min(maxSliderWidth, imageNatural.width)
		imageHeight = Math.min(maxSliderHeight, imageNatural.height)

		if imageWidth < minSliderWidth && imageNatural.width > minSliderWidth
			imageWidth = minSliderWidth

		if imageHeight < minSliderHeight && imageNatural.height > minSliderHeight
			imageHeight = minSliderHeight

		if imageWidth < imageNatural.width
			proportion = imageWidth/imageNatural.width
			newHeight = parseInt(imageNatural.height*proportion)
			imageHeight = newHeight

		if imageHeight < imageNatural.height
			proportion = imageHeight/imageNatural.height
			imageWidth = parseInt(imageNatural.width*proportion)

		sliderWidth = Math.max(minSliderWidth, Math.min(maxSliderWidth, Math.max(sliderWidth, imageWidth)))
		sliderHeight = Math.max(minSliderHeight, Math.min(maxSliderHeight, Math.max(sliderHeight, imageHeight)))


		modalWidth = Math.min(@panel.outerWidth()+sliderWidth, windowWidth-10)

		@gallery.css({
			top: Math.max(10, parseInt(($(window).height()-Math.max(@panel.outerHeight(), sliderHeight))/2) )+'px',
			width: modalWidth+'px',
			'margin-left': -parseInt(modalWidth/2)+'px'
		})
		@slider.css({width: sliderWidth+'px', height: sliderHeight+'px'})
		image.css({width: imageWidth+'px', height: imageHeight+'px'})

		@sliderInner.css({height: imageHeight+'px'})

		@panel.css({height: (@slider.outerHeight()-parseInt(@panel.css('padding-top'))-parseInt(@panel.css('padding-bottom')))+'px'})

		@

	_generateUid: () ->
		d = new Date()
		m = d.getMilliseconds() + ""
		++d + m + (if ++photoGalleryCounter == 10000 then (photoGalleryCounter = 1) else photoGalleryCounter)

	getNatural: (element) ->
		if typeof element.naturalWidth == 'undefined'
			img = new Image()
			img.src = element.src
			{ width: img.width, height: img.height }
		else
			{ width: element.naturalWidth, height: element.naturalHeight }
}