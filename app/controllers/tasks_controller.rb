class TasksController < FilteredController
  belongs_to :event, :user, :optional => true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show]

  has_scope :by_user

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  layout false, only: :progress_bar

  custom_actions collection: [:progress_bar]

  respond_to_datatables do
    columns [
      {:attr => :title, :value => Proc.new{|task| @controller.view_context.link_to(task.title, @controller.view_context.task_comments_path(task), remote: true, class: 'data-resource-details-link')}, :searchable => true, :clickable => false},
      {:attr => :last_activity, :value => Proc.new{|task| task.updated_at.to_s(:slashes) if task.updated_at }, :clickable => false},
      {:attr => :due_at, :value => Proc.new{|task| task.due_at.to_s(:slashes) if task.due_at }, :clickable => false},
      {:attr => :user_full_name, :clickable => false },
      {:attr => :completed, :value => Proc.new{|task| @controller.view_context.simple_form_for([task.event, task], remote: true) {|f| f.input :completed, :label => false, :input_html => {:class => 'task-completed-checkbox'}} }, :clickable => false}
    ]
    @editable  = true
    @deactivable = true
  end

  private
    def collection_to_json
      collection.map{|task| {
        :id => task.id,
        :title => task.title,
        :last_activity => task.updated_at.try(:to_s,:slashes),
        :due_at => task.due_at.try(:to_s, :slashes),
        :user => {
          :id => task.user.try(:id),
          :first_name => task.user.try(:first_name),
          :last_name => task.user.try(:last_name),
          :email => task.user.try(:email),
          :full_name => task.user.try(:full_name)
        },
        :completed => task.completed,
        :complete_form => view_context.simple_form_for([task.event, task], remote: true) {|f| f.input :completed, :label => false, :input_html => {:class => 'task-completed-checkbox'}},
        :links => {
            edit: edit_resource_url(task),
            show: resource_url(task),
            activate: url_for([:activate, parent, task]),
            deactivate: url_for([:deactivate, parent, task])
        }
      }}
    end

    def sort_options
      {
        'title' => { :order => 'tasks.title' },
        'due_at' => { :order => 'tasks.due_at' },
        'user_name' => { :order => 'tu.first_name', :joins => 'LEFT JOIN users tu ON tu.id = tasks.user_id' },
        'completed' => { :order => 'tasks.completed' }
      }
    end

end
