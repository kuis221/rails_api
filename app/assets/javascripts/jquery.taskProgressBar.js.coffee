$.widget 'nmk.taskProgressBar', {
	options: {
		format: 'counter'
	},
	_create: () ->
		if @options.format == 'counter'
			@_drawCounters()
		else
			@_drawBar()

	values: (total, unassigned, assigned, completed, late) ->
		if @options.format is 'counter'
			@_updateCounters(unassigned, assigned, completed, late)
		else
			@_updateBar(total, unassigned, assigned, completed)


	_drawCounters: () ->
		@element.append(
			$('<div class="row-fluid task-counter-bar">')
				.append($('<div class="task-counter-item unassigned">').append($('<span class="count-unassigned">')).append($('<label class="unassigned">Unassigned</label>')))
				.append($('<div class="task-counter-item assigned">').append($('<span class="count-assigned">')).append($('<label class="assigned">Assigned</label>')))
				.append($('<div class="task-counter-item completed">').append($('<span class="count-completed">')).append($('<label class="completed">Completed</label>')))
				.append($('<div class="task-counter-item late">').append($('<span class="count-late">')).append($('<label class="late">Late</label>')))
		)

	_drawBar: () ->
		@element.append(
			$('<div class="progress-bar-description">'),
			$('<div class="progress">').append(
				$('<div class="bar bar-completed" title="Completed">'),
				$('<div class="bar bar-assigned" title="Assigned">'),
				$('<div class="bar-unassigned" title="Unassigned">'),
			)
		)

	_updateCounters: (unassigned, assigned, completed, late) ->
		@element.find('.count-unassigned').text(unassigned)
		@element.find('.count-assigned').text(assigned)
		@element.find('.count-completed').text(completed)
		@element.find('.count-late').text(late)

	_updateBar: (total, unassigned, assigned, completed) ->
		@element.find('.progress-bar-description').text("#{assigned} of #{total} Tasks Have Been Assigned. #{completed} are Completed.")
		if total > 0
			completed_p = parseInt(100 * completed / total)
			assigned_p = parseInt(100 * assigned / total)
			unassigned_p = 100-assigned_p
			@element.find('.bar-completed').show().css({width: "#{completed_p}%"}).text("#{completed_p}%")
			@element.find('.bar-assigned').show().css({width: "#{assigned_p-completed_p}%"}).text("#{assigned_p}%")
			@element.find('.bar-unassigned').show().css({width: "#{unassigned_p}%"}).text("#{unassigned_p}%")
		else
			@element.find('.bar-completed, .bar-assigned, .bar-unassigned').hide()
}
