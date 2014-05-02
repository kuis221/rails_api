$.widget 'nmk.notifications', {
	options: {
		counterSelector: '.dropdown-toggle',
		listSelector: '.dropdown-menu',
		notifications: false
	},

	_create: () ->
		@counter = @element.find(@options.counterSelector)
		@list = @element.find(@options.listSelector)
		@list.removeClass('dropdown-menu')
		$('<div class="dropdown-menu">').insertAfter(@counter).append(@list)


		if @options.notifications
			$('<h5>').text('Notifications').insertBefore @list
			@_updateNotifications @options.notifications
		else
			$.get '/notifications.json', (response) =>
				$('<h5>').text('Notifications').insertBefore @list
				$('<div class="notifications-container">').insertBefore(@list).append @list
				@_updateNotifications response

	_updateNotifications: (alerts) ->
		@counter.text(alerts.length)
		if alerts.length > 0
			@element.addClass('has-notifications')
		@list.html('')
		hasRed = false
		hasBlue = false
		hasGrey = false
		for alert in alerts
			if alert.level is 'red' then hasRed = true
			if alert.level is 'blue' then hasBlue = true
			if alert.level is 'grey' then hasGrey = true

			@list.append(
				$('<li>').addClass(alert.level + (if alert.unread then ' new' else '')).append(
					$('<a>').attr('href', alert.url).append([
						$('<i class="alert-icon">').addClass(alert.icon),
						$('<div>').addClass('alert-message').html(alert.message)
					])
				)
			)

		if hasRed then @element.addClass('has-red-notifications')
		if hasBlue then @element.addClass('has-blue-notifications')
		if hasGrey then @element.addClass('has-grey-notifications')
}