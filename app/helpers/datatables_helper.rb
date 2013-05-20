module DatatablesHelper
  module ClassMethods
    attr_accessor :datatable

    def respond_to_datatables(&block)
      self.send :include, InstanceMethods
      self.respond_to :table, only: :index
      self.before_filter :set_datatables_vars, only: :index
      self.helper_method :datatable_resource_values

      @datatable = DataTable::Base.new(self)
      @datatable.instance_eval(&block) if block
      @datatable
    end
  end

  module InstanceMethods
    def datatable
      self.class.datatable.controller = self
      self.class.datatable
    end
    def datatable_resource_values(resource)
      actions = []
      columns = datatable.columns.map do |column|
        value = ''
        column[:clickable] = true unless column.has_key?(:clickable)
        if column.has_key?(:value) and column[:value]
          value = column[:value].respond_to?(:call) ? column[:value].call(resource) : column[:value]
        else
          value = resource.try(column[:attr].to_sym)
        end
        if value && column[:clickable]
          view_context.link_to(value, view_context.url_for(parent? ? [parent, resource] : resource), {title: 'View Details'})
        else
          value
        end
      end

      if datatable.editable
        actions.push view_context.link_to('Edit', view_context.url_for(parent? ? [:edit, parent, resource] : [:edit, resource]), {remote: true, title: 'Edit'})
      end
      if datatable.deactivable
        if resource.active?
          actions.push view_context.link_to('Deactivate', view_context.url_for(parent? ? [:deactivate, parent, resource] : [:deactivate, resource]), {remote: true, title: 'Deactivate'})
        else
          actions.push view_context.link_to('Activate', view_context.url_for(parent? ? [:activate, parent, resource] : [:activate, resource]), {remote: true, title: 'Activate'})
        end
      end
      if datatable.deletable
        actions.push view_context.link_to('Delete', view_context.url_for(parent? ? [parent, resource] : [:resource]), {remote: true, title: 'Delete', method: :delete})
      end

      columns.push actions.join ' ' unless actions.empty?
      columns
    end

    def end_of_association_chain
      if params.has_key?(:sEcho)
        per_page = params[:iDisplayLength]
        current_page = (params[:iDisplayStart].to_i/per_page.to_i rescue 0)+1
        #super.paginate(:page => current_page, :per_page => per_page, :conditions =>  search_conditions, :order => "#{self.class.datatable.column_sort(params[:iSortCol_0])} #{params[:sSortDir_0] || "DESC"}")
        super.where(search_conditions).order("#{self.class.datatable.column_sort(params[:iSortCol_0])} #{params[:sSortDir_0] || "DESC"}")
      else
        #super.paginate(:page => 1, :per_page => 10)
        super
      end
    end

    def search_conditions
      conditions = []
      values = []

      if params[:sSearch] && !params[:sSearch].empty?
        query = "%#{params[:sSearch]}%"
        self.class.datatable.columns.each do |column|
          if column[:searchable]
            values << query
            conditions << "#{column[:column_name]} ilike ?"
          end
        end
      end
      Rails.logger.debug [conditions.join(' OR '), values].flatten
      [conditions.join(' OR '), values].flatten
    end

    def set_datatables_vars
      @total_objects = collection.count
      @resource_collection = collection
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
  end

end


module DataTable
  class Base
    attr_accessor :editable
    attr_accessor :deactivable
    attr_accessor :deletable
    attr_accessor :controller

    def initialize(klass)
      @klass = klass
    end

    def columns(columns=nil)
      @columns = columns if columns
      @columns
    end

    def column(index)
      @columns[index.to_i]
    end

    def column_sort(index)
      @columns[index.to_i][:column_name]
    end

  end
end