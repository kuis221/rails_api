$.widget 'nmk.notifications', {
	options: {
		counterSelector: '.dropdown-toggle',
		listSelector: '.dropdown-menu'
	},

	_create: () ->
		@counter = @element.find(@options.counterSelector)
		@list = @element.find(@options.listSelector)
		@list.removeClass('dropdown-menu')
		$('<div class="dropdown-menu">').insertAfter(@counter).append(@list)

		$.get '/notifications.json', (response) =>
			$('<h5>').text('Notifications').insertBefore @list
			@_updateNotifications response

	_updateNotifications: (alerts) ->
		@counter.text(alerts.length)
		if alerts.length > 0
			@element.addClass('has-notifications')
		@list.html('')
		hasCritical = false
		hasInfo = false
		hasWarning = false
		for alert in alerts
			if alert.level is 'critical' then hasCritical = true
			if alert.level is 'info' then hasInfo = true
			if alert.level is 'warning' then hasWarning = true

			@list.append(
				$('<li>').addClass(alert.level + (if alert.unread then ' new' else '')).append(
					$('<a>').attr('href', alert.url).append([
						$('<i class="alert-icon">').addClass(alert.icon),
						$('<span>').addClass('alert-message').html(alert.message),
						$('<i class="icon-angle-right">')
					])
				)
			)

		if hasCritical then @element.addClass('has-critical-notifications')
		if hasCritical then @element.addClass('has-info-notifications')
		if hasCritical then @element.addClass('has-warning-notifications')
}