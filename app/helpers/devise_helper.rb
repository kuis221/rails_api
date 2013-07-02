module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    flash[:error] = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe
  end
end