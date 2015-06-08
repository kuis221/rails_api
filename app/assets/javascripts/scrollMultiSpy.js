!function ($) {

  "use strict"; // jshint ;_;


 /* SCROLLSPY CLASS DEFINITION
  * ========================== */

  function ScrollMultiSpy(element, options) {
    var process = $.proxy(this.process, this)
      , $element = $(element).is('body') ? $(window) : $(element)
      , href
    this.originalElement = element
    this.options = $.extend({}, $.fn.scrollmultispy.defaults, options)
    this.$scrollElement = $element.on('scroll.scroll-spy.data-api', process)
    this.navs = $(this.options.target)
    this.selector = 'a[data-spytarget]'
    this.$body = $('body')
    this.refresh()
    this.process()
  }

  ScrollMultiSpy.prototype = {

      constructor: ScrollMultiSpy

    , refresh: function () {
        var self = this
          , $targets

        this.offsets = $([]);
        this.targets = $([]);

        this.navs.each(function(i, nav){
          self.offsets[i] = $([]);
          self.targets[i] = $([]);
          $targets = $(nav)
            .find(self.selector)
            .map(function () {
              var $el = $(this)
                , href = $el.data('spytarget') || $el.data('target') || $el.attr('href')
                , $href = /^#\w/.test(href) && $(href)
              return ( $href
                && $href.length
                && [[ $href.position().top + (!$.isWindow(self.$scrollElement.get(0)) && self.$scrollElement.scrollTop()), href ]] ) || null
            })
            .sort(function (a, b) { return a[0] - b[0] })
            .each(function () {
              self.offsets[i].push(this[0]);
              self.targets[i].push(this[1]);
            })
        })
      }

    , process: function () {
        var self = this;
        this.navs.each(function(index, nav){
          var scrollTop = self.$scrollElement.scrollTop() + self.options.offset
            , scrollHeight = self.$scrollElement[0].scrollHeight || self.$body[0].scrollHeight
            , maxScroll = scrollHeight - self.$scrollElement.height()
            , offsets = self.offsets[index]
            , targets = self.targets[index]
            , activeTarget = nav.activeTarget
            , i

          // if (scrollTop >= maxScroll) {
          //   return activeTarget != (i = targets.last()[0])
          //     && self.activate ( i, nav )
          // }

          // for (i = offsets.length; i--;) {
          //   activeTarget != targets[i]
          //     && scrollTop >= offsets[i]
          //     && (!offsets[i + 1] || scrollTop <= offsets[i + 1])
          //     && self.activate( targets[i], nav )
          // }

          for (i = 0; i < offsets.length; i++) {
            activeTarget != targets[i]
              && scrollTop >= offsets[i]
              && (!offsets[i + 1] || scrollTop <= offsets[i + 1])
              && self.activate( targets[i], nav )
          }
        });
      }

    , activate: function (target, nav) {
        var active
          , selector

        // if (nav.activeTarget == target) {
        //   return true;
        // }

        nav.activeTarget = target

        $(nav).find(this.selector+'.active').removeClass('active scrollmultispy')
        $(nav).find(this.selector)
          .parent('.active.scrollmultispy')
          .removeClass('active')
          .trigger('deactivate')

        selector = this.selector
          + '[data-spytarget="' + target + '"],'
          + '[data-target="' + target + '"],'
          + this.selector + '[href="' + target + '"]'

        $(nav).find(selector).addClass('active scrollmultispy')
        active = $(nav).find(selector)
          .parent('li')
          .addClass('active scrollmultispy')

        if (active.parent('.dropdown-menu').length)  {
          active = active.closest('li.dropdown').addClass('active scrollmultispy')
        }

        active.trigger('activate')
      }
    , destroy: function () {
      this.$scrollElement.off('scroll.scroll-spy.data-api')
      $(this.originalElement).removeData('scrollmultispy', null)
    }

  }


 /* SCROLLSPY PLUGIN DEFINITION
  * =========================== */

  var old = $.fn.scrollmultispy

  $.fn.scrollmultispy = function (option, args) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('scrollmultispy')
        , options = typeof option == 'object' && option
      if (!data) $this.data('scrollmultispy', (data = new ScrollMultiSpy(this, options)))
      if (typeof option == 'string') data[option].apply(data, args)
    })
  }

  $.fn.scrollmultispy.Constructor = ScrollMultiSpy

  $.fn.scrollmultispy.defaults = {
    offset: 10
  }

}(window.jQuery);