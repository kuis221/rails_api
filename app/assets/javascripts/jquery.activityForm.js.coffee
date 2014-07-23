$.widget 'nmk.activityForm', {
	options: {
		formUrl: null
	},
	_create: () ->
		@element.on "change", "#activity_activity_type_id", (e) =>
			if $(e.target).val()
				$.get "#{@options.formUrl}?activity[activity_type_id]=#{$(e.target).val()}", (result) =>
					@element.html('').append $(result).find('.activity-form')
					return

			return

		@element.on "change", "#activity_campaign_id", =>
			brands  = @element.find(".form-field-brand")
			marques = @element.find("select.form-field-marque")
			if selectedOption = @value
				$.get "/campaigns/#{selectedOption}/brands.json", (list) ->
					brands.empty()
					marques.empty()
					brands.append $("<option>",
						value: ""
						text: ""
						selected: true
					)
					marques.select2 "data", null, false
					for i of list
						brands.append $("<option>",
							value: list[i].id
							text: list[i].name
						)
					brands.trigger "liszt:updated"
					return

			return

		@element.on "change", ".form-field-brand", ->
			if selectedOption = @value
				$.get "/brands/#{selectedOption}/marques.json", (options) ->
					marques = $("select.form-field-marque")
					marques.empty().select2 "destroy"
					for i of options
						marques.append $("<option>",
							value: options[i].id
							text: options[i].name
						)
					marques.select2()
					return

			return

		@element.on "keyup.activity", "input.summation", ->
			sum = 0
			group = $(this).data("group")
			$.each $("input[data-group=\"#{group}\"][name!=\"total\"]"), (e) ->
				sum += parseFloat(@value) or 0
				return

			$("input[data-group=\"#{group}\"][name=\"total\"]").val sum
			return

		# Cancel any upload in progress if the modal is closed
		@element.parents('.modal').on 'hide', (e) =>
			@element.find('.attached_asset_upload_form').each (index, form) ->
				$(form).data("jqXHR").abort() if $(form).data("jqXHR")

}



