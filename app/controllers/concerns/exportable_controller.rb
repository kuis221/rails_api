require 'active_support/concern'

module ExportableController
  extend ActiveSupport::Concern

  included do
    before_action :enqueue_export, only: [:index]

    helper_method :each_collection_item

    define_callbacks :export

    set_callback :export, :prepare_collection_for_export
  end

  def export_list(export, path)
    @_export = export
    run_callbacks :export do
      if export.export_format == 'csv'
        File.open(path, 'w:UTF-8') { |f| f.write collection_to_csv.force_encoding(Encoding::UTF_8) }
      else
        Slim::Engine.with_options(pretty: false, sort_attrs: false, streaming: false) do
          render_to_string :index,
                           to_file: path,
                           stream: true,
                           handlers: [:slim],
                           formats: export.export_format.to_sym,
                           layout: 'application'
        end
      end
    end
  end

  def prepare_collection_for_export
    search_params.merge!(per_page: 100) if respond_to?(:search_params, true) && resource_class.respond_to?(:do_search)
    collection
  end

  def list_exportable?
    return true unless request.format.pdf?
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
    total_pages = (collection_count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      collection.limit(items_per_page).offset(items_per_page * (page - 1)).each do |result|
        yield view_context.present(result, params['format'])
      end
    end
  end

  def collection_count
    count = collection.unscope(:select).count
    return count unless count.is_a?(Hash)
    count.values.sum
  end

  def each_collection_item_array
    items_per_page = 100
    total_pages = (collection.count / items_per_page.to_f).ceil
    (1..(total_pages)).each do |page|
      collection.slice(items_per_page * (page - 1), items_per_page).each do |result|
        yield view_context.present(result, params['format'])
      end
    end
  end

  def each_collection_item_solr
    (1..@total_pages).each do |page|
      search = resource_class.do_search(@search_params.merge!(page: page))
      search.results.each { |result| yield view_context.present(result, params['format']) }
      @_export.update_column(
        :progress, (page * 100 / @total_pages).round) unless @_export.nil?
    end
  end

  def export_file_name
    "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  # Create and enqueue a ListExport for the current request
  def enqueue_export
    return unless request.format.xls? || request.format.pdf? || request.format.csv?
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
  end

  def _render_template(options) #:nodoc:
    if path = options.delete(:to_file)
      FileChunkedBody.new path, view_renderer.render_body(view_context, options)
    else
      super
    end
  end

  def _process_options(options) #:nodoc:
    super unless options[:stream] && options[:to_file]
  end

  class FileChunkedBody
    include Rack::Utils

    def initialize(path, body)
      @path = path
      @body = body
    end

    def each
      File.open @path, 'w' do |f|
        @body.each do |chunk|
          size = bytesize(chunk)
          next if size == 0

          #chunk = chunk.dup.force_encoding(Encoding::BINARY) if chunk.respond_to?(:force_encoding)
          f.write chunk
        end
      end
    end

    def close
      @body.close if @body.respond_to?(:close)
    end
  end
end
