do ($ = window.jQuery, window) ->
  # Define the plugin class
  class chardinJs
    constructor: (el) ->
      @$el = $(el)
      $(window).on 'resize scroll', () =>
        @.refresh()

    start: ->
      return false if @._overlay_visible()
      @._add_overlay_layer()
      @._show_element(el) for el in @$el.find('*[data-intro]')

      @$el.trigger 'chardinJs:start'

    toggle: () ->
      if not @._overlay_visible()
        @.start()
      else
        @.stop()

    refresh: ()->
      if @._overlay_visible()
        for el in @$el.find('*[data-intro]')
          $element = $(el)
          target = if el.getAttribute('data-target') then $(el.getAttribute('data-target')).get()[0] else el
          position = el.getAttribute('data-helper-position')
          if target
            @._position_helper_layer target, position
      else
        return this

    stop: () ->
      @$el.find(".chardinjs-overlay").fadeOut -> $(this).remove()

      @$el.find('.chardinjs-helper-layer').remove()

      @$el.find('.chardinjs-show-element').removeClass('chardinjs-show-element chardinjs-keep-back')
      @$el.find('.chardinjs-relative-position').removeClass('chardinjs-relative-position')

      if window.removeEventListener
        window.removeEventListener "keydown", @_onKeyDown, true
      #IE
      else document.detachEvent "onkeydown", @_onKeyDown  if document.detachEvent

      @$el.trigger 'chardinJs:stop'

    _overlay_visible: ->
      @$el.find('.chardinjs-overlay').length != 0

    _add_overlay_layer: () ->
      return false if @._overlay_visible()
      overlay_layer = document.createElement("div")
      styleText = ""

      overlay_layer.className = "chardinjs-overlay"

      #check if the target element is body, we should calculate the size of overlay layer in a better way
      if @$el.prop('tagName') is "BODY"
        styleText += "top: 0;bottom: 0; left: 0;right: 0;position: fixed;"
        overlay_layer.setAttribute "style", styleText
      else
        element_position = @._get_offset(@$el.get()[0])
        if element_position
          styleText += "width: " + element_position.width + "px; height:" + element_position.height + "px; top:" + element_position.top + "px;left: " + element_position.left + "px;"
          overlay_layer.setAttribute "style", styleText
      @$el.get()[0].appendChild overlay_layer

      overlay_layer.onclick = => @.stop()

      $(document).keyup (e) =>
        @.stop() if e.keyCode is 27

      setTimeout ->
        styleText += "opacity: .8;opacity: .8;-ms-filter: 'progid:DXImageTransform.Microsoft.Alpha(Opacity=80)';filter: alpha(opacity=80);"
        overlay_layer.setAttribute "style", styleText
      , 10

    _get_position: (element) -> element.getAttribute('data-position') or 'bottom'

    _place_tooltip: (element, style) ->
      tooltip_layer = $(element).data('tooltip_layer')
      tooltip_layer_position = @._get_offset(tooltip_layer)

      target_element_position  = @._get_offset(element)
      if target_element_position.width == 0
        tooltip_layer.style.display = 'none'
        return true
      else
        tooltip_layer.style.display = ''

      if style
        tooltip_layer.setAttribute('style',  style)
      else
        #reset the old style
        tooltip_layer.style.top = null
        tooltip_layer.style.right = null
        tooltip_layer.style.bottom = null
        tooltip_layer.style.left = null

        switch @._get_position(element)
          when "top", "bottom", "inner-top", "inner-bottom"
            target_width             = target_element_position.width
            my_width                 = $(tooltip_layer).width()
            tooltip_layer.style.left = "#{(target_width/2)-(tooltip_layer_position.width/2)}px"
          when "left", "right"
            target_height           = target_element_position.height
            my_height               = $(tooltip_layer).height()
            tooltip_layer.style.top = "#{(target_height/2)-(tooltip_layer_position.height/2)}px"

        switch @._get_position(element)
          when "left" then tooltip_layer.style.left = "-" + (tooltip_layer_position.width - 34) + "px"
          when "right" then tooltip_layer.style.right = "-" + (tooltip_layer_position.width - 34) + "px"
          when "bottom" then tooltip_layer.style.bottom = "-" + (tooltip_layer_position.height) + "px"
          when "inner-top" then tooltip_layer.style.top = tooltip_layer_position.height + "px"
          when "top" then tooltip_layer.style.top = "-" + (tooltip_layer_position.height) + "px"


    _position_helper_layer: (element) ->
      custom_position = {}
      helper_layer = $(element).data('helper_layer')

      element_position = @._get_offset(element)
      helper_layer.setAttribute "style", "width: #{element_position.width}px; height:#{element_position.height}px; top:#{element_position.top}px; left: #{element_position.left}px;"

    _show_element: (element) ->
      target = if element.getAttribute('data-target') then $(element.getAttribute('data-target')).get()[0] else element
      helper_class = element.getAttribute('data-helper-class')
      element_class = element.getAttribute('data-element-class')
      if not target
        return false
      target.setAttribute('data-position', element.getAttribute('data-position'))

      helper_layer     = document.createElement("div")
      tooltip_layer    = document.createElement("div")

      $(target)
        .data('helper_layer', helper_layer)
        .data('tooltip_layer',tooltip_layer)

      helper_layer.setAttribute "data-id", target.id if target.id
      helper_layer.className = "chardinjs-helper-layer chardinjs-#{@._get_position(element)} #{helper_class}"

      helper_layer.onclick = => @.stop()

      @._position_helper_layer target
      @$el.get()[0].appendChild helper_layer
      tooltip_layer.className = "chardinjs-tooltip chardinjs-#{@._get_position(element)}"
      tooltip_layer.innerHTML = "<div class='chardinjs-tooltiptext'>#{element.getAttribute('data-intro')}</div>"
      helper_layer.appendChild tooltip_layer

      tooltip_style = element.getAttribute('data-tooltip-style')
      @._place_tooltip target, tooltip_style

      if element_class
        target.className += " #{element_class}"
      else
        target.className += " chardinjs-show-element"

      current_element_position = ""
      if target.currentStyle #IE
        current_element_position = target.currentStyle["position"]
      #Firefox
      else current_element_position = document.defaultView.getComputedStyle(target, null).getPropertyValue("position")  if document.defaultView and document.defaultView.getComputedStyle

      current_element_position = current_element_position.toLowerCase()

      target.className += " chardinjs-relative-position"  if current_element_position isnt "absolute" and current_element_position isnt "relative"

    _get_offset: (element) ->
      element_position =
        width: element.offsetWidth
        height: element.offsetHeight

      _x = 0
      _y = 0
      while element and not isNaN(element.offsetLeft) and not isNaN(element.offsetTop)
        _x += element.offsetLeft
        _y += element.offsetTop
        element = element.offsetParent

      element_position.top = _y
      element_position.left = _x
      element_position

  $.fn.extend chardinJs: (option, args...) ->
    $this = $(this[0])
    data = $this.data('chardinJs')
    if !data
      $this.data 'chardinJs', (data = new chardinJs(this, option))
    if typeof option == 'string'
      data[option].apply(data, args)
    data
