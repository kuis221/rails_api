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

  mapIsVisible = false
  calendarIsVisible = false
  calendarCreated = false
  # EVENTS INDEX

  $('#toggle-events-view a').on 'click', ->
    $('#toggle-events-view a').removeClass 'active'
    $(this).addClass('active').tab 'show'
    if $(this).attr('href') is '#map-view'
      mapIsVisible = true
      calendarIsVisible = false
      $('body.events.index #collection-list-filters').filteredList 'disableScrolling'
      $('.dates-range-filter').slideDown()
      initializeMap()
    else if $(this).attr('href') is '#calendar-view'
      $('.dates-range-filter').slideUp()
      calendarIsVisible = true
      mapIsVisible = false
      $('body.events.index #collection-list-filters').filteredList 'disableScrolling'
      if not calendarCreated
        calendarCreated = true
        $('#calendar-canvas').eventsCalendar({
          eventsUrl: () =>
            "/events/calendar.json#{location.search}"
          renderMonthDay: (day) => 
            date = "#{day.getMonth()+1}/#{day.getDate()}/#{day.getFullYear()}"
            "<a class=\"cal-day-link\" data-date=\"#{date}\" href=\"/events?start_date=#{date}&end_date=\">#{day.getDate()}</a>"
        })
        $('#calendar-canvas').off('click.eventsCalendar').on 'click.eventsCalendar', '.cal-day-link', (e) ->
          date = $(this).data('date')
          $('#collection-list-filters').filteredList('selectCalendarDates', date, date)
          $('#toggle-events-view a[href="#list-view"]').click()
          false

        $('#collection-list-filters').off('filters:changed.eventsCalendar').on 'filters:changed.eventsCalendar', () ->
          if calendarIsVisible
            $('#calendar-canvas').eventsCalendar 'loadEvents'
      else
        $('#calendar-canvas').eventsCalendar 'loadEvents'
    else
      $('.dates-range-filter').slideDown()
      mapIsVisible = false
      calendarIsVisible = false
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

      map.setOptions {styles: window.MAP_STYLES}
    else
      google.maps.event.trigger map, 'resize'
    fecthAndPlaceMarkers()

  $(document).on 'events-filter:changed', (e) ->
    if mapIsVisible
      fecthAndPlaceMarkers()


  fecthAndPlaceMarkers = ->
    params = $('#collection-list-filters').filteredList('getFilters');
    params.push {name: 'per_page', value: '500'}
    $.getJSON '/events.json', params, (events) ->
      placeMarkers(map, events)

  window.placeMarkers = (map, events) ->
    if map
      for marker in markersArray
        marker.setMap null

      bounds = new google.maps.LatLngBounds()

      pinImage = new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|de4d43",
        new google.maps.Size(21, 34),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 34));

      for event in events
        if event.place? and event.place.latitude? and event.place.latitude != ''
          placeLocation = new google.maps.LatLng(event.place.latitude,event.place.longitude)
          marker = new google.maps.Marker({
            draggable:false,
            icon: pinImage,
            title: event.place.name,
            animation: google.maps.Animation.DROP,
            position: placeLocation
          })
          markersArray.push marker

          marker.theInfowindow = new google.maps.InfoWindow {
              content: $('<div>')
                      .append($('<b>').append(if event.campaign? then event.campaign.name else ''))
                      .append($('<br>')).append(event.formatted_date)
                      .append($('<br>')).append(if event.place? then event.place.name + '<br>' + event.place.formatted_address else '')
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

        markerCluster = new MarkerClusterer(map, markersArray);


  if $('#map-view').hasClass('active')
    mapIsVisible = true
    initializeMap()
