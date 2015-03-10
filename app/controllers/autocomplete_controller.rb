class AutocompleteController < ApplicationController
  before_action :sanitize_id

  def show
    render json: autocomplete.search
  end

  protected

  def autocomplete
    @autocomplete ||= Autocomplete.new(params[:id], current_company_user, params)
  end

  def sanitize_id
    fail ActiveRecord::RecordNotFound unless params[:id] =~ /\A[a-z_]+\z/
  end
end