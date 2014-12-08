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
  has_many :permissions, inverse_of: :role
  validates :name, presence: true

  accepts_nested_attributes_for :permissions, reject_if: proc { |attributes| !attributes['enabled'] }

  scope :active, -> { where(active: true) }

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

  def permission_for(action, subject_class, subject = nil)
    cached_permissions.find(
      proc { permissions.build(action: action, subject_class: subject_class.to_s, subject_id: subject) }
    ) do |p|
      p.action.to_s == action.to_s && p.subject_class.to_s == subject_class.to_s && p.subject_id == subject
    end
  end

  def has_permission?(action, subject_class)
    is_admin? || cached_permissions.any? { |p| p.action.to_s == action.to_s && p.subject_class.to_s == subject_class.to_s }
  end

  def cached_permissions
    @cached_permissions ||= Rails.cache.fetch("role_permissions_#{id}") do
      permissions.all.to_a
    end
  end

  def clear_cached_permissions
    @cached_permissions = nil
    Rails.cache.delete("role_permissions_#{id}")
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?
        with(:id, params[:role]) if params.key?(:role) && params[:role].present?

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :asc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def searchable_params
      [role: [], status: []]
    end

    def report_fields
      {
        name:       { title: 'Name' }
      }
    end
  end
end
