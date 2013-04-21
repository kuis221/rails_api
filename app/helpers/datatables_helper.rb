module DatatablesHelper
  module ClassMethods
    attr_accessor :datatable

    def respond_to_datatables(&block)
      self.send :include, InstanceMethods
      self.respond_to :table, only: :index
      self.before_filter :set_datatables_vars, only: :index

      @datatable = DataTable::Base.new(self)
      @datatable.instance_eval(&block) if block
      @datatable
    end
  end

  module InstanceMethods


    def end_of_association_chain
      if params.has_key?(:sEcho)
        per_page = params[:iDisplayLength]
        current_page = (params[:iDisplayStart].to_i/per_page.to_i rescue 0)+1
        super.paginate(:page => current_page, :per_page => per_page, :order => "#{self.class.datatable.column_sort(params[:iSortCol_0])} #{params[:sSortDir_0] || "DESC"}")
      else
        super.paginate(:page => 1, :per_page => 10)
      end
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

    def columns(columns)
      @columns = columns
    end

    def column(index)
      @columns[index.to_i]
    end

    def column_sort(index)
      @columns[index.to_i][:sort]
    end
  end
end