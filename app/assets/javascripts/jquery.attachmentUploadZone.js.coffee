$.widget 'nmk.attachmentUploadZone', {
	options: {
	},
	_create: () ->
		# Handle photo/attachment uploads
		# $.each @element.find('.attached_asset_upload_form'), (index, form) ->
		form = @element;
		url = form.find('input[name=url]').val()
		form.find("input[type=file]").fileupload(
			url: url
			dataType: "xml"
			autoUpload: true
			dropZone: form
			start: (e) ->
				form.addClass("uploading").find(".attachment-attached-view, .attachment-select-file-view").hide().end().find(".attachment-uploading-view").show()
				return

			add: (e, data) ->
				group = form.closest('.control-group').removeClass('error')
				group.find('.help-inline').remove()
				return false	if e.isDefaultPrevented()
				uploadErrors = [];
				acceptFileTypes  = RegExp(form.data('accept-file-types'), "i") if form.data('accept-file-types')?
				if acceptFileTypes && data.originalFiles[0]['type'].length && not acceptFileTypes.test(data.originalFiles[0]['type'])
					uploadErrors.push('is not a valid file');

				maxFileSize = form.data('max-file-size') if form.data('max-file-size')?
				if maxFileSize && data.originalFiles[0]['size'] && data.originalFiles[0]['size'] > maxFileSize
					uploadErrors.push('Filesize is too big');

				if uploadErrors.length > 0
					$('<span class="help-inline"></span>').text(uploadErrors[0]).insertAfter(group.find('label.control-label')[0])
					group.addClass('error')
				else if data.autoUpload or (data.autoUpload isnt false and $(this).fileupload("option", "autoUpload"))
					data.process().done ->
						form.data "jqXHR", data.submit()
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
				form.find("input[type=hidden].direct_upload_url").val $(data.result).find("Location").text()
				form.removeClass("uploading").find(".attachment-uploading-view, .attachment-select-file-view").hide().end().find(".attachment-attached-view").show().find(".file-name").text data.files[0].name
				return

			always: (f) ->
				form.removeClass "uploading"
				form.data "jqXHR", false
				return

			formData: (f) ->
				data = $.map form.find(".s3fields input"), (elm, index) ->
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

		form.on "click", ".change-attachment", (e) ->
			form.find(".attachment-select-file-view .cancel-upload").show()
			form.find(".attachment-attached-view").hide().end().
					find(".attachment-select-file-view").show()
			false

		form.on "click", ".remove-attachment", (e) ->
			form.data('id', null).find(".attachment-attached-view").hide().end().
					find(".attachment-select-file-view").show().end().
					find("input[name*=\"[_destroy]\"]").val "1"
			false

		form.on "click", ".cancel-upload", (e) ->
			form.data("jqXHR").abort() if form.data("jqXHR")
			if form.data('id') or form.find("input[type=hidden].direct_upload_url").val()
				form.find(".attachment-attached-view").show().end().
					find(".attachment-uploading-view").hide().end().
					find(".attachment-select-file-view").hide()
			else
				form.find(".attachment-attached-view").hide().end().
					find(".attachment-uploading-view").hide().end().
					find(".attachment-select-file-view").show()
			false


}