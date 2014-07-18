class SectionInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def input
    content_tag(:h3, options[:name], class: 'section-title' ) +
    (options[:description] ? simple_format(options[:description], {class: 'section-description'}) : nil )
  end
end