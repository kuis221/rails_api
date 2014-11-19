module ExportableFormHelper
  module InstanceMethods
    def form
      respond_to do |format|
        format.pdf do
          render pdf: file_name,
                 template: 'shared/fieldable.html.slim',
                 layout: 'application.pdf',
                 disposition: 'attachment',
                 show_as_html: params[:debug].present?
        end
      end
    end

    private

    def file_name
      "#{controller_name.underscore}-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{resource.id}"
    end
  end

  def self.extended(receiver)
    receiver.send(:include, InstanceMethods)
  end
end
