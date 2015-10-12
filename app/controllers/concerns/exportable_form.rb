require 'active_support/concern'

module ExportableForm
  extend ActiveSupport::Concern

  included do
    helper_method :fieldable
    respond_to :pdf, only: [:export_results, :export_fieldable]
    before_action :set_cache_header, only: [:export_results, :export_fieldable]
  end

  def export_fieldable
    respond_to do |format|
      format.pdf do
        render pdf: pdf_form_file_name,
               template: 'shared/fieldable.html.slim',
               layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
    end
  end

  def export_results
    respond_to do |format|
      format.pdf do
        render pdf: pdf_form_file_name,
               template: 'shared/form_field_results.html.slim',
               locals: { form_fields: fieldable.form_fields },
               layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
      format.html do
        render template: 'shared/form_field_results.html.slim',
               locals: { form_fields: fieldable.form_fields },
               layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
    end
  end

  def fieldable
    resource
  end

  private

  def pdf_form_file_name
    "#{controller_name.underscore}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def set_cache_header
    response.headers['Cache-Control'] = 'private, max-age=0, no-cache'
  end
end
