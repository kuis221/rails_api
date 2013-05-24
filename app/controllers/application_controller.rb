class ApplicationController < ActionController::Base
  protect_from_forgery

  include DatatablesHelper
  include SentientController
  include CurrentCompanyHelper

  before_filter :authenticate_user!

  layout :set_layout

  helper_method :current_company

  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end


end
