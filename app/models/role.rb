# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :integer
#  active      :boolean          default(TRUE)
#  description :text
#  is_admin    :boolean          default(FALSE)
#

class Role < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  has_many :company_users
  has_many :permissions

  attr_accessible :name, :description, :permissions_attributes
  validates :name, presence: true

  accepts_nested_attributes_for :permissions, reject_if: proc { |attributes| !attributes['enabled'] }

  scope :active, where(:active => true)

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def permission_for(action, subject_class)
    permissions.detect{|p| p.action.to_s == action.to_s && p.subject_class.to_s == subject_class.to_s } || permissions.build(action: action, subject_class: subject_class.to_s)
  end

  def has_permission?(action, subject_class)
    permissions.any?{|p| p.action.to_s == action.to_s && p.subject_class.to_s == subject_class.to_s }
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'role'
            with :id, value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

end
