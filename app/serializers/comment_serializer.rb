class CommentSerializer < ActiveModel::Serializer
  attributes :id, :content, :created_at, :created_by

  def created_by
    return unless object.user.present?
    { id: object.user.id, full_name: object.user.full_name  }
  end
end
