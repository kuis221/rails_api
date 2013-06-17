# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#  company_id  :integer
#  active      :boolean          default(TRUE)
#  description :text
#

class Role < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  PERMISSIONS = %w{events tasks analysis campaigns users roles other_admin}

  has_many :company_users

  attr_accessible :name, :description, :permissions
  validates :name, presence: true

  serialize :permissions

  scope :active, where(:active => true)
  scope :with_text, lambda{|text| where('roles.name ilike ? or roles.description ilike ? ', "%#{text}%", "%#{text}%") }

  searchable do
    integer :id

    text :name
    text :description

    string :name
    string :description

    boolean :active

    integer :company_id
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'role'
            with :id, value
          end
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

end
