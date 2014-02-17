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

		$(document).on 'click', '.photoGallery a[data-toggle="gallery"]', (e) =>
			e.stopPropagation()
			e.preventDefault()
			@gallery.modal 'show'
			@buildCarousels e.target
			@fillPhotoData e.target
			@_updateSizes()
			false
		@

	fillPhotoData: (currentImage) ->
		$image = $(currentImage)
		@setTitle $image.data('title')
		@setDate $image.data('date')
		@setAddress $image.data('address')
		if @options.includeTags
			@setTags ['2013', 'jameson', 'jaskot', 'whiskey', 'chicago-team']

	setTitle: (title) ->
		@title.html title

	setDate: (date) ->
		@date.html date

	setAddress: (address) ->
		@address.html address

	setTags: (tags) ->
		@tags.html ''
		@tags.append($('<div class="tag">').text(tag).prepend($('<span class="close">'))) for tag in tags

	buildCarousels: (currentImage) ->
		i = index = 0
		active = false
		row = null
		if @miniCarousel
			@miniCarousel.remove()

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

			row.append($('<img>').attr('src', image.src).data('image',image).data('index', index))
			carousel.append $('<div class="item">').
					 append($('<div class="row">').append($('<img>').attr('src', link.href))).
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


	_createGalleryModal: () ->
		@title = $('<h3>')
		@address = $('<div class="place-data">')
		@date = $('<div class="calendar-data">')

		if @gallery
			@gallery.remove();
			@gallery.off('shown')

		if @carousel
			@carousel.off('slid').remove()

		@gallery = $('<div class="gallery-modal modal hide fade">').append(
						$('<div class="gallery-modal-inner">').append(
							$('<div class="panel">').
								append('<button class="close" data-dismiss="modal" aria-hidden="true"></button>').
								append(
									$('<div class="description">').append( @title ).append( @date ).append( @address ),
									$('<div class="mini-slider">').append( @miniCarousel = @_createCarousel('small') )
									(if @options.includeTags then $('<div class="tags">').append( @tags = $('<div class="list">') , $('<input class="typeahead">')) else null)
								),
							$('<div class="slider">').append( $('<div class="slider-inner">').append( @carousel = @_createCarousel() ) )
						).append($('<div class="clearfix">'))
					)


		@gallery.insertAfter @element

		@gallery.on 'shown', () =>
				@_updateSizes()
				$(window).on 'resize.gallery', =>
					@_updateSizes()
			.on 'hidden', () =>
				$(window).off 'resize.gallery'


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
			@miniCarousel.carousel parseInt(item.data('index')/3)
			@_updateSizes()

		@gallery


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
		imageHeight = image.height()

		# Get image natural size
		imageNatural = @getNatural(image[0])

		# Set the slider/images widths based on the  available space and image dimensions
		windowWidth = $(window).width()
		maxSliderWidth = windowWidth-@panel.outerWidth()-20
		if imageNatural.width > image.width()
			sliderWidth = Math.min(maxSliderWidth, imageNatural.width)
			@slider.css({width: sliderWidth+'px'})
			#image.css({width: Math.min(sliderWidth, imageNatural.width)+'px'})
		else if @slider.width() > maxSliderWidth 
			@slider.css({width: maxSliderWidth+'px'})


		if $(window).height() < imageHeight
			image.css({height: @slider.height()+'px'})
		else
			image.css({height: 'auto'})

		@slider.css({height: Math.max(imageHeight, @slider.height())+'px'})
		@panel.css({height: (@slider.outerHeight()-parseInt(@panel.css('padding-top'))-parseInt(@panel.css('padding-bottom')))+'px'})

		@sliderInner.css({height: imageHeight+'px'})

		modalWidth = Math.min(@panel.outerWidth()+@slider.outerWidth(), windowWidth-20)

		@gallery.css({
			top: Math.max(10, parseInt(($(window).height()-@gallery.outerHeight())/2) )+'px',
			width: modalWidth+'px',
			left: parseInt((windowWidth-modalWidth)/2)+'px'
		})

		@

	_generateUid: () ->
		d = new Date()
		m = d.getMilliseconds() + ""
		++d + m + (if ++photoGalleryCounter == 10000 then (photoGalleryCounter = 1) else photoGalleryCounter)

	getNatural: (element) ->
		img = new Image()
		img.src = element.src
		{ width: img.width, height: img.height }
}