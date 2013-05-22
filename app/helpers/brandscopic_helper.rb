module BrandscopicHelper

  module InstanceMethods

    protected
      def load_collection
        get_collection_ivar || begin
          current_page = params[:page] || 1
          c = end_of_association_chain.accessible_by(current_ability).scoped(sorting_options)
          c = controller_filters(c)
          @collection_count_scope = c
          c = c.page(current_page)
          set_collection_ivar(c.respond_to?(:scoped) ? c.scoped : c.all)
          set_collection_ivar(c.respond_to?(:scoped) ? c.scoped : c.all)
        end
      end

      def collection_count
        @collection_count ||= @collection_count_scope.count
      end


      def controller_filters(c)
        c
      end

      def sorting_options
        if params.has_key?(:sorting) && sort_options[params[:sorting]] && params[:sorting_dir]
          options = sort_options[params[:sorting]].dup
          options[:order] = options[:order] + ' ' + params[:sorting_dir] if sort_options.has_key?(params[:sorting])
          options
        end
      end

      def collection_to_json
        []
      end

  end


  def self.included(base)
    if base < ActionController::Base
      base.send :include, InstanceMethods
      base.class_eval do

        before_filter :load_collection
        helper_method :collection_count
        helper_method :collection_to_json
      end
    end
  end
end
