photoGalleryCounter = 0
$.widget 'nmk.photoGallery', {
	options: {
		month: null,
		year: null,
		eventsUrl: null,
		renderMonthDay: null
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
			false
		@

	fillPhotoData: (currentImage) ->
		$image = $(currentImage)
		@setTitle $image.data('title')
		@setDate $image.data('date')
		@setAddress $image.data('address')
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

		@gallery = $('<div class="gallery-modal modal hide fade">').append(
						$('<div class="panel">').
							append('<button class="close" data-dismiss="modal" aria-hidden="true"></button>').
							append(
								$('<div class="description">').append( @title ).append( @date ).append( @address ),
								$('<div class="mini-slider">').append( @miniCarousel = @_createCarousel('small') )
								$('<div class="tags">').append( @tags = $('<div class="list">') , $('<input class="typeahead">'))
							),
						$('<div class="slider">').append( @carousel = @_createCarousel() )
					)

		@gallery.insertAfter @element

		@miniCarousel.carousel({interval: false})
		@carousel.carousel({interval: false})

		@carousel.on 'slid', (e) =>
			item = $('.item.active', e.target)
			image = item.data('image')
			@fillPhotoData(image)
			@miniCarousel.carousel(parseInt(item.data('index')/3))

		@gallery


	_createCarousel: (carouselClass='') ->
		id = "gallery-#{@_generateUid()}"
		$('<div id="'+id+'" class="gallery-carousel carousel slide">').addClass(carouselClass).append(
			$('<div class="carousel-inner">'),
			$('<a class="carousel-control left" data-slide="prev" href="#'+id+'">'),
			$('<a class="carousel-control right" data-slide="next" href="#'+id+'">')
		)



	_generateUid: () ->
		d = new Date()
		m = d.getMilliseconds() + ""
		++d + m + (if ++photoGalleryCounter == 10000 then (photoGalleryCounter = 1) else photoGalleryCounter)
}