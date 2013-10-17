class Contact < ActiveRecord::Base

  scoped_to_company

  has_many :contact_events, dependent: :destroy, as: :contactable

  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    [first_name, last_name].join ' '
  end
end
