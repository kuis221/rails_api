class ApplicationController < ActionController::Base
  protect_from_forgery

  include DatatablesHelper

  before_filter :authenticate_user!
end
