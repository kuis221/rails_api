class ApplicationController < ActionController::Base
  protect_from_forgery

  include DatatablesHelper

  before_filter :authenticate_user!

  layout :set_layout


  protected
    def set_layout
      signed_in? ? 'application' : 'empty'
    end
end
