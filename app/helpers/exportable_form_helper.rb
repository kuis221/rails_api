module ExportableFormHelper
  module InstanceMethods
    def export_fieldable
      respond_to do |format|
        format.pdf do
          response.headers['Cache-Control']='private, max-age=0, no-cache'
          render pdf: pdf_form_file_name,
                 template: 'shared/fieldable.html.slim',
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
  end

  def self.extended(receiver)
    receiver.send(:include, InstanceMethods)
    receiver.send(:helper_method, :fieldable)
  end
end
