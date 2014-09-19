class FolderSelectInput < SimpleForm::Inputs::Base
  def input
    children = options[:root_folder].document_folders.root_children.active
    document_folder_tree(options[:root_folder], children) if children.any?
  end

  def document_folder_tree(folder, children, list_class=nil)
    template.content_tag(:ul, id: "folder-#{folder.class.name.underscore}-#{folder.id}", class: "folder-contents #{list_class}") do
      children.map do |sub_folder|
        has_children = sub_folder.document_folders.any?
        template.content_tag(:li, class: 'subfolder '+(has_children ? 'with-children' : ''.html_safe)) do
          (has_children ? template.tag(:i, class: 'icon icon-arrow-right folder-arrow-indicator', data: {toggle: 'collapse', target: "#folder-#{sub_folder.class.name.underscore}-#{sub_folder.id}"}) : '').html_safe +
          template.content_tag(:label, class: 'radio') do
            template.tag(:i, class: 'icon-folder') +
            @builder.radio_button(attribute_name, sub_folder.id, input_html_options) +
            sub_folder.name
          end +
          (has_children ? document_folder_tree(sub_folder, sub_folder.document_folders.active, 'collapse') : '')
        end
      end.join.html_safe
    end
  end
end