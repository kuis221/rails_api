# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default(TRUE)
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

class DataExtract::Task < DataExtract
  define_columns title: 'title',
                 task_statuses: "CASE WHEN tasks.active='t' THEN 'Active' ELSE 'Inactive' END
                                || ', ' || CASE WHEN tasks.company_user_id is null THEN 'Unassigned' ELSE 'Assigned' END
                                || ', ' || CASE WHEN tasks.completed='t' THEN 'Complete' ELSE 'Incomplete' END
                                || '' || CASE WHEN (tasks.due_at is not null AND due_at < '#{Date.today.to_s(:db)}' AND completed = 'f')
                                THEN ', Late' ELSE '' END || '' || CASE WHEN (tasks.due_at is not null AND
                                  tasks.due_at = '#{Date.today.to_s(:db)}') THEN ', Due' ELSE '' END",
                 due_at: proc { "to_char(tasks.due_at, 'MM/DD/YYYY')" },
                 created_by: 'trim(users.first_name || \' \' || users.last_name)',
                 created_at: proc { "to_char(tasks.created_at, 'MM/DD/YYYY')" },
                 assigned_to: 'trim(cu.first_name || \' \' || cu.last_name)',
                 comment1: '(SELECT content FROM comments WHERE commentable_type = \'Task\' AND commentable_id=tasks.id ORDER BY created_at LIMIT 1 OFFSET 0) AS column1',
                 comment2: '(SELECT content FROM comments WHERE commentable_type = \'Task\' AND commentable_id=tasks.id ORDER BY created_at LIMIT 1 OFFSET 1) AS column2',
                 comment3: '(SELECT content FROM comments WHERE commentable_type = \'Task\' AND commentable_id=tasks.id ORDER BY created_at LIMIT 1 OFFSET 2) AS column3',
                 comment4: '(SELECT content FROM comments WHERE commentable_type = \'Task\' AND commentable_id=tasks.id ORDER BY created_at LIMIT 1 OFFSET 3) AS column4',
                 comment5: '(SELECT content FROM comments WHERE commentable_type = \'Task\' AND commentable_id=tasks.id ORDER BY created_at LIMIT 1 OFFSET 4) AS column5',
                 active_state: 'CASE WHEN tasks.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON tasks.created_by_id=users.id')
    end
    if columns.include?('assigned_to') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN company_users ON company_users.id=company_user_id')
           .joins('LEFT JOIN users AS cu ON company_users.user_id=cu.id')
    end
    s
  end

  def total_results
    Task.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.joins(:event).where(events: { campaign_id: filters[:campaign] } ) if filters.present? && filters['campaign'].present?
    s = s.where(active: filters['status'].map { |f| f.downcase == 'active' ? true : false }) if filters['status'].present?
    s = s.filters_between_dates(filters['start_date'].to_s, filters['end_date'].to_s) if filters['start_date'].present? && filters['end_date'].present?
    s = add_filter_task_status(s)
    s
  end

  def add_filter_task_status(s)
    filters[:task_status].each do |status|
      s = s.where(completed: status.downcase == 'complete' ? true : false) if status.downcase == 'complete' || status.downcase == 'incomplete'
      s = s.where("tasks.due_at is not null AND due_at < '#{Date.today.to_s(:db)}' AND completed = 'f'") if status.downcase == 'late'
    end if filters[:task_status].present?
    s
  end

  def base_scope
    add_filter_conditions_to_scope add_joins_to_scope(model)
  end

  def filters_scope
    'user_tasks'
  end

  def filters_include_calendar
    true
  end

  def sort_by_column(col)
    case col
    when 'created_at'
      'tasks.created_at'
    when 'due_at'
      'tasks.due_at'
    else
      super
    end
  end
end
