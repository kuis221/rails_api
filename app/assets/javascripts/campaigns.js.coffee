jQuery ->

	$(document).delegate '.goalable-list a.arrow', 'click', (e) ->
		e.stopPropagation();
		e.preventDefault();
		$li = $(this).closest('li')
		$scroller = $li.find('.goals-inner')
		if $scroller.data('moving')
			return
		width = $li.find('.kpi-goal').outerWidth()
		scrollerPosition = $scroller.offset()
		distanceToMax = $('.arrow-right').offset().left - $('.arrow-left').offset().left - parseInt($('.arrow-right').css('margin-left')) - parseInt($('.arrow-left').css('margin-left'))
		
		if $('.arrow-left').offset().left == 0
			distanceToMax = distanceToMax - scrollerPosition.left
			
		range =  Math.floor(distanceToMax/width) - 1 
		move = ''
		if $(this).is('.arrow-left')
			#distanceToMin = scrollerPosition.left * -1
			toReduce = Math.abs(parseInt($scroller.css('left'))) - width*range
			move = if parseInt($scroller.css('left')) < 0 then "-=#{Math.max(toReduce, 1)}" else false
		else
			#distanceToMax = $scroller.outerWidth() + scrollerPosition.left - $(this).offset().left + parseInt($(this).css('margin-left'))
			move = if ($scroller.outerWidth() + scrollerPosition.left) > $(this).offset().left then "-=#{Math.min(Math.abs(parseInt($scroller.css('left'))) + width*range, distanceToMax)}" else false
		if move
			$scroller.data('moving', true)
			$scroller.animate { left: move }, 300, => 
				scrollerPosition = $scroller.position()
				if scrollerPosition.left == 0
					$li.find('.arrow-left').hide()
				else 
					$li.find('.arrow-left').show()

				$scroller.data('moving', false)
		false