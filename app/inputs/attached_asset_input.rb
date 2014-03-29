class AttachedAssetInput < SimpleForm::Inputs::Base
  def input
    uploader = S3DirectUpload::UploadHelper::S3Uploader.new({})
    output_html = '<div class="attached_asset_upload_form"><div class="s3fields" style="margin:0;padding:0;display:inline">'
    uploader.fields.map do |name, value|
      output_html << @builder.hidden_field(nil, {value: value, name: name, id: "#{name}_#{options[:field_id]}"})
    end
    output_html << '</div>'
    output_html << @builder.hidden_field(nil, {value: uploader.url, name: 'url', id: "url_#{options[:field_id]}"})
    output_html << @builder.hidden_field(attribute_name, {class: 'direct_upload_url'})
    output_html << @builder.hidden_field('_destroy', {value: ''})

    output_html << '<div class="attachment-panel" data-id="'+(object.attached_asset.present? ? object.attached_asset.id.to_s : '')+'">
                      <div class="attachment-select-file-view"'+ (object.attached_asset.present? ? 'style="display: none"' : '') + '>
                        <p><a href="#" class="file-browse">Browse<input id="fileupload" type="file" name="file" /></a> for an image located on your computer</p>
                        <p class="divider">OR</p>
                        <p>Drag and drop file here to upload</p>
                        <p class="small">Maximun upload file size: 10MB</p>
                        <a href="#" class="cancel-upload"'+ (object.attached_asset.present? ? '' : 'style="display: none"') + '>Cancel</a>
                      </div>
                      <div class="attachment-uploading-view" style="display: none">
                        Uploading <span class="file-name"></span>.... (<span class="upload-progress"></span>)<br />
                        <a href="#" class="cancel-upload">Cancel</a>
                      </div>
                      <div class="attachment-attached-view"'+ (object.attached_asset.present? ? '' : 'style="display: none"' ) + '>
                        File attached: <span class="file-name">'+object.attached_asset.try(:file_file_name).to_s+'</span>
                        <a href="#" class="remove-attachment">Remove</a>
                        <a href="#" class="change-attachment">Change</a>
                      </div>
                    </div>
                  </div>'.html_safe
    output_html.html_safe
  end
end