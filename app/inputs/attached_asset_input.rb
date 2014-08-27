class AttachedAssetInput < SimpleForm::Inputs::Base
  def input
    max_file_size = 10*1024*1024
    options[:field_id] ||= rand(9999)
    options[:file_types] ||= ''
    options[:hidden_field_name] ||= attribute_name
    options[:browse_legend] ||= 'inputs.attached_asset.select_file.attachment'
    uploader = S3DirectUpload::UploadHelper::S3Uploader.new({})
    output_html = '<div class="attached_asset_upload_form" data-accept-file-types="'+options[:file_types]+'" data-max-file-size="'+max_file_size.to_s+'"><div class="s3fields" style="margin:0;padding:0;display:inline">'
    uploader.fields.map do |name, value|
      output_html << @builder.hidden_field(nil, {value: value, name: name, id: "#{name}_#{options[:field_id]}"})
    end
    attached_asset = object.is_a?(AttachedAsset) ? object : object.attached_asset
    has_attached_asset = attached_asset.present? && attached_asset.persisted?
    output_html << '</div>'
    output_html << @builder.hidden_field(nil, {value: uploader.url, name: 'url', id: "url_#{options[:field_id]}"})
    output_html << @builder.hidden_field(options[:hidden_field_name], {class: 'direct_upload_url'})
    output_html << @builder.hidden_field('_destroy', {value: ''})
    output_html << '<div class="attachment-panel" data-id="'+(has_attached_asset ? attached_asset.id.to_s : '')+'" >
                      <div class="attachment-select-file-view"'+ (has_attached_asset ? 'style="display: none"' : '') + '>
                        <div class="drag-box">
                          <i class="icon-upload"></i>
                          <h4>DRAG &amp; DROP</h4>
                          <p>'+I18n.translate(options[:browse_legend], browse: '<span class="file-browse">browse<input id="fileupload" type="file" name="file" data-accept-file-types="(\.|\/)(gif|jpe?g|png)$" data-max-file-size="'+max_file_size.to_s+'" /></span>')+'</p>
                          <a href="#" class="cancel-upload"'+ (has_attached_asset ? '' : 'style="display: none"') + '>Cancel</a>
                        </div>
                      </div>
                      <div class="attachment-uploading-view" style="display: none">
                        Uploading <span class="file-name"></span>.... (<span class="upload-progress"></span>)<br />
                        <a href="#" class="cancel-upload">Cancel</a>
                      </div>
                      <div class="attachment-attached-view"'+ (has_attached_asset ? '' : 'style="display: none"' ) + '>
                        File attached: <span class="file-name">'+attached_asset.try(:file_file_name).to_s+'</span>
                        <a href="#" class="remove-attachment">Remove</a>
                        <a href="#" class="change-attachment">Change</a>
                      </div>
                    </div>
                  </div>'.html_safe
    output_html.html_safe
  end
end