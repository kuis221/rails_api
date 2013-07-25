jQuery ->
  $(document).delegate ".task-completed-checkbox", "click", ->
    $(@form).submit()

  $(document).delegate 'a.load-comments-link', 'click', (e) ->
    $row = $(this).parents('li');
    if $("##{$row.attr('id')}_comments").length > 0
      $("##{$row.attr('id')}_comments").toggle()
      e.stopImmediatePropagation()

    else
      $(this).removeAttr('data-remote')

    e.preventDefault();
    return false

  $('#event-photos-upl-form').fileupload
    dataType: "script"
    add: (e, data) ->
      types = /(\.|\/)(gif|jpe?g|png)$/i
      file = data.files[0]
      if types.test(file.type) || types.test(file.name)
        data.context = $(tmpl("template-upload", file))
        $('#event-photos-upl-form').append(data.context)
        data.submit()
      else
        bootbox.alert("#{file.name} is not a gif, jpeg, or png image file")
    progress: (e, data) ->
      if data.context
        if not data.context.moved?
          $(data.context).appendTo('#upload-progress-list')
          data.context.moved = true
        progress = parseInt(data.loaded / data.total * 100, 10)
        data.context.find('.bar').css('width', progress + '%')
        if progress >= 99
          window.setTimeout(() -> 
            data.context.slideUp(600, () => $(this).remove())
          1000)


  mapIsVisible = false
  # EVENTS INDEX
  $('#toggle-events-view a').on 'click', ->
    $('#toggle-events-view a').removeClass 'active'
    $(this).addClass('active').tab 'show'
    if $(this).attr('href') is '#map-view'
      mapIsVisible = true
      initializeMap()
      $('.table-cloned-fixed-header').hide()  
      $('body.events.index #collection-list-filters').filteredList 'disableScrolling'
    else
      mapIsVisible = false
      $('.table-cloned-fixed-header').show()
      $('body.events.index #collection-list-filters').filteredList 'enableScrolling'


  map = null
  markersArray = []
  events = null

  initializeMap = ->
    if not map
      mapOptions = {
        zoom: 5,
        mapTypeId: google.maps.MapTypeId.ROADMAP
      }
      map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions)

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
    else
      google.maps.event.trigger map, 'resize'
    placeMarkers()

  $(document).on 'events-filter:changed', (e) ->
    if mapIsVisible
      placeMarkers()


  placeMarkers = ->
    params = $('#collection-list-filters').filteredList('getFilters');
    params.push {name: 'per_page', value: '200'}
    $.getJSON '/events.json', params, (events) ->

      if map
        for marker in markersArray
          marker.setMap null

        bounds = new google.maps.LatLngBounds()

        for event in events
          if event.place? and event.place.latitude? and event.place.latitude != ''
            placeLocation = new google.maps.LatLng(event.place.latitude,event.place.longitude)
            marker = new google.maps.Marker({
              map:map,
              draggable:false,
              title: event.place.name,
              animation: google.maps.Animation.DROP,
              position: placeLocation
            })
            markersArray.push marker

            marker.theInfowindow = new google.maps.InfoWindow {
                content: $('<div>')
                        .append($('<b>').append(if event.campaign? then event.campaign.name else ''))
                        .append($('<br>')).append(event.start_at)
                        .append($('<br>')).append(if event.place? then event.place.formatted_address else '')
                        .append($('<br>')).append($('<a>', {'href': event.links.show}).text('View Details'))
                        .append('\xA0\xA0').append($('<a>', {'href': event.links.edit, 'data-remote': true}).text('Edit Event')).html()
            }

            google.maps.event.addListener marker, 'click', () ->
              for marker in markersArray
                marker.theInfowindow.close()

              this.theInfowindow.open map, this

            # Automatically center/zoom the map according to the markers :)
            bounds.extend marker.position

        if events.length > 0
          zoomChangeBoundsListener = google.maps.event.addListener(map, 'bounds_changed', (event) ->
              google.maps.event.removeListener(zoomChangeBoundsListener)
              if (this.getZoom() > 13 && this.initialZoom == true)
                this.setZoom 13
                this.initialZoom = false
          )
          map.initialZoom = true;
          map.fitBounds bounds


