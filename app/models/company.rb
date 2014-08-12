# == Schema Information
#
# Table name: companies
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  timezone_support :boolean
#  settings         :hstore
#

class Company < ActiveRecord::Base
  attr_accessor :admin_email
  attr_accessor :no_create_admin

  serialize :settings, ActiveRecord::Coders::Hstore

  has_many :company_users, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :brand_portfolios, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :areas, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :date_ranges, dependent: :destroy
  has_many :day_parts, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :kpis, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :activity_types, dependent: :destroy
  has_many :tags, :order => 'name ASC', :autosave => true, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :admin_email, presence: true, on: :create, unless: :no_create_admin

  validates_format_of :admin_email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true

  after_create :create_admin_role_and_user

  def self.current=(company)
    Thread.current[:company] = company
  end

  def self.current
    Thread.current[:company]
  end

  # Returns the value for setting #{name} if present, or the #{default} value if not set
  def setting(name, default=nil)
    if settings && settings.has_key?(name.to_s)
      settings[name.to_s]
    else
      default
    end
  end

  def team_member_options
    ActiveRecord::Base.connection.select_all("
      #{company_users.active.select('company_users.id, users.first_name || \' \' || users.last_name as name, \'company_user\' as type').joins(:user).to_sql}
      UNION ALL
      #{teams.active.select('teams.id, teams.name, \'team\' as type').to_sql}
      ORDER BY name ASC
    ").map{|r| [r['name'], "#{r['type']}:#{r['id']}", {class: r['type']}] }
  end


  private
    def create_admin_role_and_user
      if admin_email
        role = self.roles.create({name: 'Super Admin', is_admin: true}, without_protection: true)
        if user = User.where(["lower(users.email) = '%s'", admin_email.downcase]).first
          new_company_user = self.company_users.build({role_id: role.id, user: user}, without_protection: true)
          new_company_user.save validate: false
          UserMailer.company_existing_admin_invitation(user, self).deliver
        else
          new_user = User.create({email: admin_email, first_name: 'Admin', last_name: 'User', inviting_user: true}, as: :admin)
          new_company_user = self.company_users.create({role_id: role.id, user: new_user}, without_protection: true)
          new_user.skip_invitation = true
          new_user.invite!
          new_user.update_attributes({invitation_sent_at: Time.now.utc}, without_protection: true)
          UserMailer.company_admin_invitation(new_user).deliver
        end
      end
    end
end
