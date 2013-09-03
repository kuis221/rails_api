jQuery ->

	$(document).delegate '.goalable-list a.arrow', 'click', (e) ->
		e.stopPropagation();
		e.preventDefault();
		$li = $(this).closest('li')
		$scroller = $li.find('.goals-inner')
		if $scroller.data('moving')
			return
		width = $li.find('.kpi-goal').width()
		scrollerPosition = $scroller.position()
		move = ''
		if $(this).is('.arrow-left')
			distanceToMin = scrollerPosition.left * -1
			move = if scrollerPosition.left < 0 then "+=#{Math.min(width, distanceToMin)}" else false
		else
			distanceToMax = $scroller.outerWidth() + scrollerPosition.left - $(this).position().left
			move = if ($scroller.outerWidth() + scrollerPosition.left) > $(this).position().left then "-=#{Math.min(width, distanceToMax)}" else false

		if move
			$scroller.data('moving', true)
			$scroller.animate { left: move }, 500, => 
				scrollerPosition = $scroller.position()
				if scrollerPosition.left == 0
					$li.find('.arrow-left').hide()
				else 
					$li.find('.arrow-left').show()

				$scroller.data('moving', false)
		false