if ENV['WEB']
  ActiveAdmin::BaseController.send(:include, Brandscopic::ActiveAdminVersionManager)
end
