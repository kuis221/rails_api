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
    def datatable_resource_values(resource)
      self.class.datatable.columns.map{|column| resource.try(column[:attr].to_sym)}
    end

    def end_of_association_chain
      if params.has_key?(:sEcho)
        per_page = params[:iDisplayLength]
        current_page = (params[:iDisplayStart].to_i/per_page.to_i rescue 0)+1
        super.paginate(:page => current_page, :per_page => per_page, :conditions =>  search_conditions, :order => "#{self.class.datatable.column_sort(params[:iSortCol_0])} #{params[:sSortDir_0] || "DESC"}")
      else
        super.paginate(:page => 1, :per_page => 10)
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
      Rails.logger.debug values.inspect
      [conditions.join(' OR '), values]
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