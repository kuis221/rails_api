class ContactEvent < ActiveRecord::Base
  belongs_to :contactable, polymorphic: true
  belongs_to :event

  accepts_nested_attributes_for :contactable

  validates :event_id, :uniqueness => { :scope => [:contactable_type, :contactable_id] }


  delegate :full_name, :street1, :street2, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :zip_code, to: :contactable

  def title
    contactable.respond_to?(:title) ? contactable.title : contactable.role_name
  end

  def build_contactable(params={}, assignment_options={})
    self.contactable = Contact.new(params, assignment_options)
  end
end
