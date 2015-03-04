require 'active_support/concern'

module ExportableController
  extend ActiveSupport::Concern

  included do
    around_action :enqueue_export, only: [:index]

    helper_method :each_collection_item
  end

  def export_list(export)
    @_export = export
    search_params.merge!(per_page: 100) if respond_to?(:search_params, true) && resource_class.respond_to?(:do_search)
    collection

    Slim::Engine.with_options(pretty: true, sort_attrs: false, streaming: false) do
      render_to_string :index,
                       handlers: [:slim],
                       formats: export.export_format.to_sym,
                       layout: 'application'
    end
  end

  def list_exportable?
    return true if request.format.xls?
    @export_errors = []
    @export_errors = ['PDF exports are limited to 200 pages. Please narrow your results and try exporting again.'] if total_export_pages > 200
    @export_errors.empty?
  end

  def total_export_pages
    if resource_class.respond_to?(:do_search)
      resource_class.do_search(search_params).total / 11.0
    else
      collection.count / 11.0
    end
  end

  def each_collection_item(&block)
    if respond_to?(:resource_class, true) && resource_class.respond_to?(:do_search)
      each_collection_item_solr(&block)
    elsif collection.is_a?(Array)
      each_collection_item_array(&block)
    else
      each_collection_item_database(&block)
    end
  end

  def each_collection_item_database
    items_per_page = 100
    total_pages = (collection.count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      collection.limit(items_per_page).offset(items_per_page * (page - 1)).each do |result|
        yield result
      end
    end
  end

  def each_collection_item_array
    items_per_page = 100
    total_pages = (collection.count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      collection.slice(items_per_page * (page - 1), items_per_page).each do |result|
        yield result
      end
    end
  end

  def each_collection_item_solr
    (1..@total_pages).each do |page|
      search = resource_class.do_search(@search_params.merge!(page: page))
      search.results.each { |result| yield result }
      @_export.update_column(
        :progress, (page * 100 / @total_pages).round) unless @_export.nil?
    end
  end

  def export_file_name
    "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  # Create and enqueue a ListExport for the current request
  def enqueue_export
    if request.format.xls? || request.format.pdf?
      if list_exportable?
        @export = ListExport.create(
          controller: self.class.name,
          params: params,
          url_options: url_options,
          export_format: params[:format],
          company_user: current_company_user
        )

        @export.queue! if @export.new?
      end
      render action: :new_export, formats: [:js]
    else
      yield
    end
  end
end
