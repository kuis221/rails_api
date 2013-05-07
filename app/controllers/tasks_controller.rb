class TasksController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :show]
  belongs_to :event

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  respond_to_datatables do
    columns [
      {:attr => :title, :value => Proc.new{|task| @controller.view_context.link_to(task.title, @controller.view_context.event_task_path(task.event, task), remote: true)}, :searchable => true},
      {:attr => :last_activity, :value => ""},
      {:attr => :due_at, :value => Proc.new{|task| task.due_at.to_s(:slashes) if task.due_at }},
      {:attr => :user_full_name },
      {:attr => :completed, :value => Proc.new{|task| task.completed? ? 'Yes' : 'No' } }
    ]
    @editable  = false
    @deactivable = false
  end

end
