ActiveAdmin.register SatisfactionSurvey do
  actions :index, :show

  menu parent: "Users"

  index do
    column :first_name, sortable: 'users.first_name' do |survey|
      survey.company_user.first_name
    end
    column :last_name, sortable: 'users.last_name' do |survey|
      survey.company_user.last_name
    end
    column :email_address, sortable: 'users.email' do |survey|
      survey.company_user.email
    end
    column :company, sortable: :company_id do |survey|
      survey.company_user.company.name
    end
    column :rating, sortable: :rating do |survey|
      survey.rating.capitalize
    end
    column :feedback
    column "Date/Time", sortable: :created_at do |survey|
      survey.created_at
    end
    default_actions
  end

  filter :company_id, as: :select, collection: proc { Company.all(order: :name) }
  filter :company_user_id, as: :select, collection: proc { CompanyUser.all(include: [:user], order: "users.first_name") }
  filter :rating
  filter :feedback
  filter :updated_at

  controller do
    def scoped_collection
      resource_class.joins(company_user: [:user, :company]).includes(company_user: [:user, :company])
    end
  end
end