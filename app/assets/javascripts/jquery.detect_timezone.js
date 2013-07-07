/**
 * jQuery Detect Timezone plugin
 *
 * Copyright (c) 2011 Scott Watermasysk (scottwater@gmail.com)
 * Provided under the Do Whatever You Want With This Code License. (same as detect_timezone).
 *
 */

(function( $ ){

  var tzmappings = {"Pacific/Midway":"Midway Island","Pacific/Pago_Pago":"American Samoa","Pacific/Honolulu":"Hawaii","America/Juneau":"Alaska","America/Los_Angeles":"Pacific Time (US & Canada)","America/Tijuana":"Tijuana","America/Denver":"Mountain Time (US & Canada)","America/Phoenix":"Arizona","America/Chihuahua":"Chihuahua","America/Mazatlan":"Mazatlan","America/Chicago":"Central Time (US & Canada)","America/Regina":"Saskatchewan","America/Mexico_City":"Mexico City","America/Monterrey":"Monterrey","America/Guatemala":"Central America","America/New_York":"Eastern Time (US & Canada)","America/Indiana/Indianapolis":"Indiana (East)","America/Bogota":"Bogota","America/Lima":"Quito","America/Halifax":"Atlantic Time (Canada)","America/Caracas":"Caracas","America/La_Paz":"La Paz","America/Santiago":"Santiago","America/St_Johns":"Newfoundland","America/Sao_Paulo":"Brasilia","America/Argentina/Buenos_Aires":"Buenos Aires","America/Guyana":"Georgetown","America/Godthab":"Greenland","Atlantic/South_Georgia":"Mid-Atlantic","Atlantic/Azores":"Azores","Atlantic/Cape_Verde":"Cape Verde Is.","Europe/Dublin":"Dublin","Europe/London":"London","Europe/Lisbon":"Lisbon","Africa/Casablanca":"Casablanca","Africa/Monrovia":"Monrovia","Etc/UTC":"UTC","Europe/Belgrade":"Belgrade","Europe/Bratislava":"Bratislava","Europe/Budapest":"Budapest","Europe/Ljubljana":"Ljubljana","Europe/Prague":"Prague","Europe/Sarajevo":"Sarajevo","Europe/Skopje":"Skopje","Europe/Warsaw":"Warsaw","Europe/Zagreb":"Zagreb","Europe/Brussels":"Brussels","Europe/Copenhagen":"Copenhagen","Europe/Madrid":"Madrid","Europe/Paris":"Paris","Europe/Amsterdam":"Amsterdam","Europe/Berlin":"Bern","Europe/Rome":"Rome","Europe/Stockholm":"Stockholm","Europe/Vienna":"Vienna","Africa/Algiers":"West Central Africa","Europe/Bucharest":"Bucharest","Africa/Cairo":"Cairo","Europe/Helsinki":"Helsinki","Europe/Kiev":"Kyiv","Europe/Riga":"Riga","Europe/Sofia":"Sofia","Europe/Tallinn":"Tallinn","Europe/Vilnius":"Vilnius","Europe/Athens":"Athens","Europe/Istanbul":"Istanbul","Europe/Minsk":"Minsk","Asia/Jerusalem":"Jerusalem","Africa/Harare":"Harare","Africa/Johannesburg":"Pretoria","Europe/Moscow":"Volgograd","Asia/Kuwait":"Kuwait","Asia/Riyadh":"Riyadh","Africa/Nairobi":"Nairobi","Asia/Baghdad":"Baghdad","Asia/Tehran":"Tehran","Asia/Muscat":"Muscat","Asia/Baku":"Baku","Asia/Tbilisi":"Tbilisi","Asia/Yerevan":"Yerevan","Asia/Kabul":"Kabul","Asia/Yekaterinburg":"Ekaterinburg","Asia/Karachi":"Karachi","Asia/Tashkent":"Tashkent","Asia/Kolkata":"New Delhi","Asia/Kathmandu":"Kathmandu","Asia/Dhaka":"Dhaka","Asia/Colombo":"Sri Jayawardenepura","Asia/Almaty":"Almaty","Asia/Novosibirsk":"Novosibirsk","Asia/Rangoon":"Rangoon","Asia/Bangkok":"Hanoi","Asia/Jakarta":"Jakarta","Asia/Krasnoyarsk":"Krasnoyarsk","Asia/Shanghai":"Beijing","Asia/Chongqing":"Chongqing","Asia/Hong_Kong":"Hong Kong","Asia/Urumqi":"Urumqi","Asia/Kuala_Lumpur":"Kuala Lumpur","Asia/Singapore":"Singapore","Asia/Taipei":"Taipei","Australia/Perth":"Perth","Asia/Irkutsk":"Irkutsk","Asia/Ulaanbaatar":"Ulaan Bataar","Asia/Seoul":"Seoul","Asia/Tokyo":"Tokyo","Asia/Yakutsk":"Yakutsk","Australia/Darwin":"Darwin","Australia/Adelaide":"Adelaide","Australia/Melbourne":"Melbourne","Australia/Sydney":"Sydney","Australia/Brisbane":"Brisbane","Australia/Hobart":"Hobart","Asia/Vladivostok":"Vladivostok","Pacific/Guam":"Guam","Pacific/Port_Moresby":"Port Moresby","Asia/Magadan":"Solomon Is.","Pacific/Noumea":"New Caledonia","Pacific/Fiji":"Fiji","Asia/Kamchatka":"Kamchatka","Pacific/Majuro":"Marshall Is.","Pacific/Auckland":"Wellington","Pacific/Tongatapu":"Nuku'alofa","Pacific/Fakaofo":"Tokelau Is.","Pacific/Apia":"Samoa"}

  $.fn.set_timezone = function(options) {

      this.val(this.get_timezone(options));
      return this;
  };

  $.fn.get_timezone = function(options) {

    var settings = {
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
      ///timezone.ambiguity_check();
      timezone_text = tzmappings[timezone.olson_tz];
    }
    return timezone_text;

  };

})( jQuery );
