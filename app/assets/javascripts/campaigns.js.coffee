jQuery ->
	$(document).delegate '.goalable-list a.arrow', 'click', (e) ->
		e.stopPropagation();
		e.preventDefault();
		$li = $(this).closest('li')
		$scroller = $li.find('.goals-inner')
		if $scroller.data('moving')
			return

		scrollerPosition = $scroller.offset()
		displayArea = Math.floor($('.arrow-right', $li).offset().left - $('.arrow-left', $li).offset().left - parseInt($('.arrow-right', $li).css('margin-left')) - parseInt($('.arrow-left', $li).css('margin-left')))
		if $('.arrow-left', $li).offset().left == 0
			displayArea = displayArea - Math.floor(scrollerPosition.left)

		move = ''
		if $(this).is('.arrow-left')
			scrollerLeft = parseInt($scroller.css('left'))
			toReduce = if Math.abs(scrollerLeft) < displayArea then Math.abs(scrollerLeft) else displayArea
			move = if scrollerLeft < 0 then "+=#{Math.max(toReduce, 1)}" else false
		else
			distanceToMax = $scroller.outerWidth() + scrollerPosition.left - $(this).offset().left + parseInt($(this).css('margin-left'))

			if ($scroller.outerWidth() + scrollerPosition.left) > $(this).offset().left
				if distanceToMax < (displayArea)
					move = "-=#{parseInt(distanceToMax)}"
				else
					error_gap = ''
					for e in $scroller.children()
						for i in $(e).children()
							#finds what element is not fully shown
							if ($(i).offset().left + $(i).width() > $(this).offset().left)
								error_gap = $(i).width()
								break
						if error_gap != ''
							break

					moveInt = parseInt(displayArea - error_gap)
					#calculate move for lower resolutions
					if moveInt <= 100
						moveInt = displayArea - parseInt($('.arrow-right', $li).css('margin-left')) - parseInt($('.arrow-left', $li).css('margin-left'))

					move = "-=#{moveInt}"
			else
				move = false
		if move
			move = if move is '+=1' then 0 else move
			$scroller.data('moving', true)
			$scroller.animate { left: move }, 300, =>
				scrollerPosition = $scroller.position()
				if scrollerPosition.left == 0
					$li.find('.arrow-left').hide()
				else
					$li.find('.arrow-left').show()

				$scroller.data('moving', false)
		false