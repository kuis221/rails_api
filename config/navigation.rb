SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'your_selected_class'
  navigation.selected_class = 'active'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  # navigation.active_leaf_class = 'your_active_leaf_class'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false
  navigation.items do |primary|
    primary.item :dashboard, 'Dashboard', root_path,  highlights_on: %r(/$)
    primary.item :events, 'Events', events_path, highlights_on: %r(/events)
    primary.item :tasks, 'Tasks', mine_tasks_path, highlights_on: %r(/tasks) do |secondary|
      secondary.item :mine_tasks, 'My Tasks', mine_tasks_path, highlights_on: %r(/tasks/mine)
      secondary.item :team_tasks, 'Team Tasks', my_teams_tasks_path, highlights_on: %r(/tasks/my_teams)
    end
    primary.item :venues, 'Venues', venues_path, highlights_on: %r(/research) do |secondary|
      secondary.item :venues, 'Venues', venues_path, highlights_on: %r(/research/venues)
    end
    primary.item :results, 'Results', results_event_data_path, highlights_on: %r(/results) do |secondary|
      secondary.item :event_data, 'Event Data', results_event_data_path, highlights_on: %r(/results/event_data)
      secondary.item :comments, 'Comments', results_comments_path, highlights_on: %r(/results/comments)
      secondary.item :photos, 'Photos', results_photos_path, highlights_on: %r(/results/photos)
      secondary.item :expenses, 'Expenses', results_expenses_path, highlights_on: %r(/results/expenses)
      secondary.item :surveys, 'Surveys', results_surveys_path, highlights_on: %r(/results/surveys)
    end
    primary.item :analysis, 'Analysis', analysis_campaigns_report_path,  highlights_on: %r(/analysis) do |secondary|
      secondary.item :snapshot_report, 'Snapshot Report', '#', highlights_on: %r(/analysis/snapshot_report)
      secondary.item :campaings_report, 'Campaings Report', '#', highlights_on: %r(/analysis/campaigns_report)
      secondary.item :staff_performance, 'Staff Performance', '#', highlights_on: %r(/analysis/staff_performance)
    end
  end
end