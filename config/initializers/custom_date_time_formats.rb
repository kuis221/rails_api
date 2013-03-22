# Be sure to restart your server when you modify this file.

::Time::DATE_FORMATS.merge!({
  :simple => "%B %d, %Y",
  :event => "%m/%d/%Y @ %l:%M %p",
  :comment => "%m/%d/%Y @ %l:%M %p",
  :full_friendly => "%b %e, %Y @ %l:%M %p",
  :time_only => "%l:%M %p",
  :slashes => "%m/%d/%Y",
  :slashes_inverted => "%d/%m/%Y",
  :filename => "%Y-%m-%d-%k-%M"
})

::Date::DATE_FORMATS.merge!({
  :default => '%m/%d/%Y',
  :year_month => '%Y-%m'
})