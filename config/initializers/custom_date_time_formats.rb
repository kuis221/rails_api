# Be sure to restart your server when you modify this file.

::Time::DATE_FORMATS.merge!(
  default: '%m/%d/%Y %H:%M:%S',
  simple: '%B %d, %Y',
  document: '%b %d, %Y at %l:%M %p',
  event: '%m/%d/%Y @ %l:%M %p',
  full_friendly: '%b %e, %Y %l:%M%p',
  time_only: '%l:%M %p',
  slashes: '%m/%d/%Y',
  numeric: '%Y%m%d',
  slashes_inverted: '%d/%m/%Y',
  ymd: '%Y/%m/%d',
  full_calendar: '%Y-%m-%d %H:%M:00',
  filename: '%Y-%m-%d-%k-%M')

::Date::DATE_FORMATS.merge!(
  slashes: '%m/%d/%Y',
  default: '%m/%d/%Y',
  year_month: '%Y-%m',
  ymd: '%Y/%m/%d',
  numeric: '%Y%m%d')
