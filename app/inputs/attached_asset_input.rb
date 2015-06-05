class AttachedAssetInput < SimpleForm::Inputs::Base
  def input
    options[:field_id] ||= rand(9999)
    options[:file_types] ||= ''
    options[:hidden_field_name] ||= attribute_name
    options[:browse_legend] ||= 'inputs.attached_asset.select_file.attachment'
    uploader = S3DirectUpload::UploadHelper::S3Uploader.new({})
    output_html = '<div class="attached_asset_upload_form" data-accept-file-types="' + options[:file_types] + '" data-max-file-size="' + max_file_size.to_s + '" data-field-type="' + form_field_class + '"><div class="s3fields" style="margin:0;padding:0;display:inline">'
    uploader.fields.map do |name, value|
      output_html << @builder.hidden_field(nil, value: value, name: name, id: "#{name}_#{options[:field_id]}")
    end
    output_html << '</div>'
    output_html << @builder.hidden_field(nil, value: uploader.url, name: 'url', id: "url_#{options[:field_id]}")
    output_html << @builder.hidden_field(nil, value: options[:field_id], name: 'field-id', id: 'field-id')
    output_html << @builder.hidden_field(options[:hidden_field_name], class: 'direct_upload_url')
    output_html << @builder.hidden_field('_destroy', value: '')
    output_html << drop_zone

    output_html.html_safe
  end

  protected

  def max_file_size
    10 * 1024 * 1024
  end

  def attached_asset
    object.is_a?(AttachedAsset) ? object : object.attached_asset
  end

  def required_attribute
    options[:required] ? 'class="required-file"' : ''
  end

  def panel_classes
    [
      options[:panel_class],
      (attached_asset? ? 'has-attachment' : nil),
      (thumbnable? ? 'thumbnable' : nil)
    ].compact.join(' ')
  end

  def attached_asset?
    attached_asset.present? && attached_asset.persisted?
  end

  def thumbnable?
    attached_asset? && attached_asset.processed? && attached_asset.is_thumbnable?
  end

  def form_field_class
    if object.is_a?(FormFieldResult)
      object.form_field.class.name.partition('::').last.downcase
    else
      ''
    end
  end

  def drop_zone
    (form_field_class.blank? ? default_drop_zone : form_field_drop_zone)
  end

  def default_drop_zone
    '<div class="attachment-panel ' + panel_classes + '" data-id="' + (attached_asset? ? attached_asset.id.to_s : '') + '" >
        <div class="attachment-select-file-view"' + (attached_asset? ? 'style="display: none"' : '') + '>
          <div class="drag-box">
            <i class="icon-upload"></i>
            <div class="drag-box-text">
              <h5>DRAG &amp; DROP</h5>
              <p>' + I18n.translate(options[:browse_legend], browse: '<span class="file-browse">browse<input id="fileupload" type="file" ' + required_attribute + ' name="file" data-accept-file-types="(\.|\/)(gif|jpe?g|png)$" data-max-file-size="' + max_file_size.to_s + '" /></span>') + '</p>
              <a href="#" class="cancel-upload"' + (attached_asset? ? '' : 'style="display: none"') + '>Cancel</a>
            </div>
          </div>
        </div>
        <div class="attachment-uploading-view" style="display: none">
          Uploading <span class="file-name"></span>.... (<span class="upload-progress"></span>)<br />
          <a href="#" class="cancel-upload">Cancel</a>
        </div>' +
      thumbnail_view_panel +
      file_view_panel +
      '</div>
    </div>'
  end

  def form_field_drop_zone
    '<div id="panel-' + options[:field_id].to_s + '" class="attachment-panel drag-drop-zone attach-field ' + panel_classes + '" data-id="' + (attached_asset? ? attached_asset.id.to_s : '') + '" ' + (attached_asset? ? 'style="display: none"' : '') + '>
      <div class="attachment-select-file-view"' + (attached_asset? ? 'style="display: none"' : '') + '>
        <div class="drag-box">
          <i class="icon-upload"></i>
          <div class="drag-box-text">
            <h5>DRAG &amp; DROP</h5>
            <p>' + I18n.translate(options[:browse_legend], browse: '<span class="file-browse">browse<input id="fileupload" type="file" ' + required_attribute + ' name="file" data-accept-file-types="(\.|\/)(gif|jpe?g|png)$" data-max-file-size="' + max_file_size.to_s + '" /></span>') + '</p>
          </div>
        </div>
      </div>
      <div class="attachment-upload-progress-info attachment-uploading-view">
        <div class="upload-file-info">
          <div class="documents-counter"></div>
          <div class="document-info">
            <span class="document-name"></span>
            &nbsp;&nbsp;
            <span class="document-size"></span>
          </div>
        </div>
        <div class="upload-file-progress">
          <div class="progress">
            <div class="bar" style="width: 0%"></div>
          </div>
          <i class="icon-remove-circle" id="upload-file-cancel"></i>
        </div>
      </div>
    </div>' +
      (form_field_class == 'photo' ? photo_view_panel : document_view_panel)
  end

  def thumbnail_view_panel
    hidden = thumbnable? ? '' : 'style="display: none;"'
    '<div id="view-' + options[:field_id].to_s + '" class="attachment-attached-view asset-thumbnail"' + hidden + '>
        <i class="remove-attachment icon icon-remove-circle"></i>
        <img id="image-attached" src="' + attached_asset.file.url(:medium) + '">
    </div>'
  end

  def file_view_panel
    hidden = attached_asset? && thumbnable? ? '' : 'style="display: none"'
    '<div class="attachment-attached-view asset-text-mode"' + hidden + '>
      File attached: <span class="file-name">' + attached_asset.try(:file_file_name).to_s + '</span>
      <a href="#" class="remove-attachment">Remove</a>
      <a href="#" class="change-attachment">Change</a>
    </div>'
  end

  def photo_view_panel
    '<div id="view-' + options[:field_id].to_s + '" class="attachment-attached-view photo"' + (attached_asset? ? '' : 'style="display: none"') + '>
        <div class="image">
            <a href="' + (attached_asset.present? && attached_asset.processed? ? attached_asset.file.url(:original) : '' ) + '" id="image-link" data-toggle="gallery">
              <img id="image-attached" src="' + (attached_asset.present? && attached_asset.processed? ? attached_asset.file.url(:thumbnail) : '' ) + '" data-info="' + (attached_asset.present? && attached_asset.processed? ? '{&quot;image_id&quot;:' + attached_asset.id.to_s + ', &quot;permissions&quot;:[]}' : '' ) + '">
            </a>
        </div>
        <div class="image-toolbar">
          <a class="icon-trash remove-attachment" title="Remove" href=""></a>' + (attached_asset.present? && attached_asset.processed? ? '<a class="icon-download download-attachment" title="Download" href="' + attached_asset.download_url + '"></a>' : '' ) + '
        </div>
      </div>
    </div>'
  end

  def document_view_panel
    '<div id="view-' + options[:field_id].to_s + '" class="attachment-attached-view"' + (attached_asset? ? '' : 'style="display: none"') + '>
        <div class="document">
          <span class="document-icon pull-left ' + attached_asset.try(:file_extension).to_s + '">.' + attached_asset.try(:file_extension).to_s + '</span>
          <div class="file-name pull-left">' + attached_asset.try(:file_file_name).to_s + '</div>
          <a class="icon-trash remove-attachment" title="Remove" href=""></a>
        </div>
      </div>
    </div>'
  end
end
