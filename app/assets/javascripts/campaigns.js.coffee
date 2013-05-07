jQuery ->
	$( "#post-event-form-builder .draggable" ).draggable {
		revert: "valid",
		helper: "clone",
		appendTo: "#droppable"
	}
	$( "#post-event-form-builder #droppable" ).droppable {
		drop: ( event, ui ) ->
			$( this ).find( ".placeholder" ).remove()
			$( "<li></li>" ).text( ui.draggable.text() ).appendTo this
	}