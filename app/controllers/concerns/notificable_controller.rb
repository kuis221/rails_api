module NotificableController
  extend ActiveSupport::Concern

  included do
    after_action :remove_resource_notifications, only: :show
    after_action :remove_collection_notifications, only: :index
  end

  module ClassMethods
    def notifications_scope(scope = nil)
      @notifications_scope = scope if scope
      @notifications_scope
    end
  end

  def notifications_scope
    return unless self.class.notifications_scope
    @notifications_scope ||= instance_exec(&self.class.notifications_scope)
  end

  def remove_resource_notifications
    return unless notifications_scope
    notifications_scope
      .where("params->'#{resource_class.name.underscore}_id'=(?)", resource.id.to_s)
      .destroy_all
  end

  # Remove the notifications that
  def remove_collection_notifications
    return unless notifications_scope && params[:new_at]
    session["filter_ids_#{params[:scope]}_#{params[:new_at]}"] ||= begin
      ids = notifications_scope.pluck("params->'#{resource_class.name.underscore}_id'").compact
      notifications_scope.destroy_all
      ids
    end
  end

  def search_params
    return super unless notifications_scope && params[:new_at]
    super.merge!(id: remove_collection_notifications)
  end
end
