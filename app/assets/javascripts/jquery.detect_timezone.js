/**
 * jQuery Detect Timezone plugin
 *
 * Copyright (c) 2011 Scott Watermasysk (scottwater@gmail.com)
 * Provided under the Do Whatever You Want With This Code License. (same as detect_timezone).
 *
 */

(function( $ ){

  $.fn.set_timezone = function(options) {

      this.val(this.get_timezone(options));
      return this;
  };

  $.fn.get_timezone = function(options) {

    var settings = {
      'format' : 'olson',
      'debug' : false,
      'mappings' : false,
      'default' : 'America/New_York'
    };

    if(options) {
      $.extend( settings, options );
    }

    var tz_info = jstz.determine_timezone();
    var timezone = tz_info.timezone;
    var timezone_text = settings['default']
    if (timezone != 'undefined') {
      timezone.ambiguity_check();
      timezone_text = timezone.olson_tz
    }
    switch (settings.format) {
      case "city":
        return timezone_text.split('/')[1];
        break;
      default:
        if (settings.mappings ){
          timezone_text = settings.mappings[timezone_text];
        }
        return timezone_text;
    }
  };

})( jQuery );
