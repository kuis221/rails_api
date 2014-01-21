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
		displayArea = Math.floor($('.arrow-right').offset().left - $('.arrow-left').offset().left - parseInt($('.arrow-right').css('margin-left')) - parseInt($('.arrow-left').css('margin-left')))
		if $('.arrow-left').offset().left == 0
			displayArea = displayArea - Math.floor(scrollerPosition.left)
		#range =  Math.floor(displayArea/width) - 1 
		move = ''
		if $(this).is('.arrow-left')
			toReduce = Math.abs(parseInt($scroller.css('left'))) - (displayArea )
			move = if parseInt($scroller.css('left')) < 0 then "-=#{Math.max(toReduce, 1)}" else false
		else
			arrowRightLeft = $(this).offset().left
			distanceToMax = $scroller.outerWidth() + scrollerPosition.left - $(this).offset().left + parseInt($(this).css('margin-left'))
			
			if ($scroller.outerWidth() + scrollerPosition.left) > $(this).offset().left
				temp_move = Math.abs(parseInt($scroller.css('left'))) + displayArea
				if distanceToMax < (displayArea)
					move = "-=#{Math.abs(parseInt($scroller.css('left'))) + (parseInt(distanceToMax))}"
				else
					error_gap = ''
					first_element = ''
					for e in $scroller.children()
						for i in $(e).children()
						#finds what element is not fully shown
							if ($(i).offset().left + $(i).width() > arrowRightLeft)
								error_gap = $(i).width()
								first_element = $(i).offset().left
								break
							#break
								
					move = "-=#{Math.abs(parseInt($scroller.css('left'))) + (parseInt(displayArea - error_gap))}"
			else
				move = false
		if move
			move = if move is '-=1' then 0 else move
			$scroller.data('moving', true)
			$scroller.animate { left: move }, 300, => 
				scrollerPosition = $scroller.position()
				if scrollerPosition.left == 0
					$li.find('.arrow-left').hide()
				else 
					$li.find('.arrow-left').show()

				$scroller.data('moving', false)
		false