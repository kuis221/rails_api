require 'active_support/concern'

module ReturnableControllerHelper
  extend ActiveSupport::Concern

  included do
    helper_method :return_path
  end

  def return_path
    url_to_return = params[:return] || request.env['HTTP_REFERER']
    url_to_return if url_valid? url_to_return
  end

  def url_valid?(url)
    URI.parse(url)
    true
  rescue URI::InvalidURIError
    false
  end
end
