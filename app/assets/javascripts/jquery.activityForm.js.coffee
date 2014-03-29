$.widget 'nmk.activityForm', {
	options: {
		formUrl: null
	},
	_create: () ->
		@element.on "change", "#activity_activity_type_id", (e) =>
			if $(e.target).val()
				$.get "#{@options.formUrl}?activity[activity_type_id]=#{$(e.target).val()}", (result) =>
					@element.html('').append $(result).find('.activity-form')
					@_initializeFormElements()
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


		# Check if there are files that are being uploaded when the form is
		# submitted and wait for them to complete before submitting the form
		@element.on "ajax:beforeSend", "form", (e) ->
			button = $("#save-activity-btn")
			if $(".attached_asset_upload_form.uploading").length > 0
				e.stopPropagation()
				e.preventDefault()
				$.rails.stopEverything e
				$(button).addClass("waiting-files").attr("disabled", true).data("oldval", $(button).val()).val "Uploading file(s)..."
				activityInterval = setInterval(->
					if $(".attached_asset_upload_form.uploading").length is 0
						$(button).attr("disabled", false).removeClass("waiting-files").val $(button).data("oldval")
						clearInterval activityInterval
						button.click()
					return
				, 500)
				false
			else
				true

		# Cancel any upload in progress if the modal is closed
		@element.parents('.modal').on 'hide', (e) =>
			@element.find('.attached_asset_upload_form').each (index, form) ->
				$(form).data("jqXHR").abort() if $(form).data("jqXHR")

		@_initializeFormElements()

	_initializeFormElements: () ->
		@element.find("select.form-field-marque").select2()

		# Handle photo/attachment uploads
		for form in @element.find('.attached_asset_upload_form')
			url = $(form).find('input[name=url]').val()
			$(form).find("input[type=file]").fileupload(
				url: url
				dataType: "xml"
				autoUpload: true
				dropZone: $(form)
				start: (e) ->
					$(form).addClass("uploading").find(".attachment-attached-view, .attachment-select-file-view").hide().end().find(".attachment-uploading-view").show()
					return

				add: (e, data) ->
					return false	if e.isDefaultPrevented()
					if data.autoUpload or (data.autoUpload isnt false and $(this).fileupload("option", "autoUpload"))
						data.process().done ->
							$(form).data "jqXHR", data.submit()
							return

					return

				change: (e, data) ->
					$(".attachment-uploading-view .file-name", form).text data.files[0].name
					return

				progress: (e, data) ->
					progress = parseInt(data.loaded / data.total * 100, 10)
					$(".upload-progress", form).text progress + "%"
					return

				progressall: (e, data) ->
					progress = parseInt(data.loaded / data.total * 100, 10)
					$("input.waiting-files").val "Uploading file(s)... " + progress + "%"
					return

				done: (e, data) ->
					$(form).find("input[type=hidden].direct_upload_url").val $(data.result).find("Location").text()
					$(form).removeClass("uploading").find(".attachment-uploading-view, .attachment-select-file-view").hide().end().find(".attachment-attached-view").show().find(".file-name").text data.files[0].name
					return

				always: (f) ->
					$(form).removeClass "uploading"
					$(form).data "jqXHR", false
					return

				formData: (f) ->
					data = $.map $(form).find(".s3fields input"), (elm, index) ->
						if elm.name is "key"
							elm.value = elm.value.replace("{timestamp}", new Date().getTime()).replace("{unique_id}", Math.random().toString(36).substr(2, 16))

						{name: elm.name, value: elm.value}

					fileType = ""
					fileType = @files[0].type	if "type" of @files[0]
					data.push
						name: "content-type"
						value: fileType

					data.push
						name: "utf8"
						value: $(f).find("input[name='utf8']").val()

					data
			).prop("disabled", not $.support.fileInput).parent().addClass(if $.support.fileInput then 'undefined' else 'disabled')

			$(form).on "click", ".change-attachment", (e) ->
				$(form).find(".attachment-select-file-view .cancel-upload").show()
				$(form).find(".attachment-attached-view").hide().end().
						find(".attachment-select-file-view").show()
				false

			$(form).on "click", ".remove-attachment", (e) ->
				$(form).data('id', null).find(".attachment-attached-view").hide().end().
						find(".attachment-select-file-view").show().end().
						find("input[name*=\"[_destroy]\"]").val "1"
				false

			$(form).on "click", ".cancel-upload", (e) ->
				$(form).data("jqXHR").abort() if $(form).data("jqXHR")
				if $(form).data('id') or $(form).find("input[type=hidden].direct_upload_url").val()
					$(form).find(".attachment-attached-view").show().end().
						find(".attachment-uploading-view").hide().end().
						find(".attachment-select-file-view").hide()
				else
					$(form).find(".attachment-attached-view").hide().end().
						find(".attachment-uploading-view").hide().end().
						find(".attachment-select-file-view").show()
				false

			true

}



