module EventAttendance
  extend ActiveSupport::Concern

  included do
    has_many :invites, dependent: :destroy, inverse_of: :event
    has_many :invite_individuals, through: :invites, source: :individuals
  end

end
