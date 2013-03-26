jQuery ->
	$('#calendar').fullCalendar {

		editable: false,

		header: {
			left: 'title',
			right: 'prev,next today,month,agendaWeek,agendaDay'
		},

		events:{ url: "/activities.json", cache: true }

		loading: (bool) ->
			if bool
				$('#loading').show()
			else
				$('#loading').hide()

	}