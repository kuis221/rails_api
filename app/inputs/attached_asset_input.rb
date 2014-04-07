class AttachedAssetInput < SimpleForm::Inputs::Base
  def input
    max_file_size = 10*1024*1024
    uploader = S3DirectUpload::UploadHelper::S3Uploader.new({})
    output_html = '<div class="attached_asset_upload_form" data-accept-file-types="'+options[:file_types]+'" data-max-file-size="'+max_file_size.to_s+'"><div class="s3fields" style="margin:0;padding:0;display:inline">'
    uploader.fields.map do |name, value|
      output_html << @builder.hidden_field(nil, {value: value, name: name, id: "#{name}_#{options[:field_id]}"})
    end
    output_html << '</div>'
    output_html << @builder.hidden_field(nil, {value: uploader.url, name: 'url', id: "url_#{options[:field_id]}"})
    output_html << @builder.hidden_field(attribute_name, {class: 'direct_upload_url'})
    output_html << @builder.hidden_field('_destroy', {value: ''})

    output_html << '<div class="attachment-panel" data-id="'+(object.attached_asset.present? ? object.attached_asset.id.to_s : '')+'" >
                      <div class="attachment-select-file-view"'+ (object.attached_asset.present? ? 'style="display: none"' : '') + '>
                        <p>'+I18n.translate('inputs.attached_asset.select_file.'+object.form_field.class.name.split('::').last.downcase, browse: '<a href="#" class="file-browse">Browse<input id="fileupload" type="file" name="file" data-accept-file-types="(\.|\/)(gif|jpe?g|png)$" data-max-file-size="'+max_file_size.to_s+'" /></a>')+'</p>
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