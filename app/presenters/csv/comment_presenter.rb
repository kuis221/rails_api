class Csv::CommentPresenter < BasePresenter
  def created_at
    datetime @model.created_at if @model.created_at.present?
  end

  def created_by
    if (created_by = @model.created_by).present?
      created_by.full_name
    end
  end

  def last_modified
    datetime @model.updated_at if @model.updated_at.present?
  end

  def modified_by
    if (updated_by = @model.updated_by).present?
      updated_by.full_name
    end
  end
end
