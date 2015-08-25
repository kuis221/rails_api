class TaskSerializer < ActiveModel::Serializer
  attributes :id, :event_id, :title, :due_at, :completed, :active, :status, :user

  def status
    object.statuses
  end

  def due_at
    object.due_at.to_s(:slashes) if object.due_at
  end

  def user
    return unless object.company_user.present?
    { id: object.company_user.id, full_name: object.company_user.full_name  }
  end
end
