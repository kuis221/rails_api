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
        :active => task.active?,
        :completed => task.completed,
        :complete_form => view_context.simple_form_for([task.event, task], remote: true) {|f| f.input :completed, :label => false, :input_html => {:class => 'task-completed-checkbox'}},
        :links => {
            edit: edit_resource_url(task),
            comments: task_comments_path(task),
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
