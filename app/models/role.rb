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

  accepts_nested_attributes_for :permissions

  scope :active, -> { where(active: true) }
  scope :not_admin, -> { where(is_admin: false)}

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

  def permission_for(action, subject_class, subject: nil, mode: 'none')
    permissions.find(
      proc { permissions.build(action: action, subject_class: subject_class.to_s, subject_id: subject, mode: mode) }
    ) do |p|
      p.action.to_s == action.to_s && p.subject_class.to_s == subject_class.to_s && p.subject_id == subject
    end
  end

  def has_permission?(action, subject_class)
    is_admin? || cached_permissions.any? { |p| p['mode'] != 'none' && p['action'].to_s == action.to_s && p['subject_class'].to_s == subject_class.to_s }
  end

  def cached_permissions
    @cached_permissions ||= (Rails.cache.fetch("role_permissions_#{id}") do
      permissions.map(&:attributes)
    end)
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

        facet :status if include_facets

        order_by(params[:sorting] || :name, params[:sorting_dir] || :asc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def report_fields
      {
        name:       { title: 'Name' }
      }
    end
  end
end
