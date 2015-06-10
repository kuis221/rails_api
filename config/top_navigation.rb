SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  navigation.renderer = SimpleNavigationBootstrap

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
    primary.item :help_menu, '', '#help-modal', link: { 'class' => 'single-link', icon_class: 'icon-help', 'data-toggle' => 'modal', 'role' => 'button' }

    options = []
    options.push([:users, 'Users', company_users_path(return: nil, phase: nil), highlights_on: %r{^/users.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, CompanyUser)
    options.push([:teams, 'Teams', teams_path(return: nil, phase: nil), highlights_on: %r{^/teams.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, Team)
    options.push([:roles, 'Roles', roles_path(return: nil, phase: nil), highlights_on: %r{^/roles.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, Role)
    options.push([:campaigns, 'Campaigns', campaigns_path(return: nil, phase: nil), highlights_on: %r{^/campaigns.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, Campaign)
    options.push([:day_parts, 'Brands', brands_path(return: nil, phase: nil), highlights_on: %r{^/brands.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, Brand)
    options.push([:activity_types, 'Activity Types', activity_types_path(return: nil, phase: nil), highlights_on: %r{^/activity_types.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, ActivityType)
    options.push([:areas, 'Areas', areas_path(return: nil, phase: nil), highlights_on: %r{^/areas.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, Area)
    options.push([:brand_portfolios, 'Brand Portfolios', brand_portfolios_path(return: nil, phase: nil), highlights_on: %r{^/brand_portfolios.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, BrandPortfolio)
    options.push([:date_ranges, 'Date Ranges', date_ranges_path(return: nil, phase: nil), highlights_on: %r{^/date_ranges.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, DateRange)
    options.push([:day_parts, 'Day Parts', day_parts_path(return: nil, phase: nil), highlights_on: %r{^/day_parts.*}, link: { icon_class: 'icon-checked' }]) if can?(:index, DayPart)

    unless options.empty?
      primary.item :admin, '', options.first[2], class: 'header-menu', link: { class: 'dropdown-toggle', 'data-toggle' => 'dropdown', icon_class: 'icon-gear' } do |secondary|
        options.each { |option| secondary.item(*option) }
      end
    end

    primary.item :notifications, '', '#', link: { 'class' => 'dropdown-toggle', 'data-toggle' => 'dropdown' } do |secondary|
      secondary.item :loading, 'Wait...'
    end

    primary.item :user_menu,  current_user.full_name, '#', class: 'header-menu', link: { 'class' => 'dropdown-toggle', 'data-toggle' => 'dropdown' }, if: lambda { user_signed_in? } do |secondary|
      secondary.item :users, 'View Profile',  profile_company_users_path(return: nil, phase: nil), link: { icon_class: 'icon-user pull-left' }
      secondary.item :users, 'Logout', destroy_user_session_path(return: nil, phase: nil), link: { method: :delete, icon_class: 'icon-on pull-left' }
    end
  end
end
