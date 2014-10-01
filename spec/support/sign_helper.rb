include Warden::Test::Helpers

module SignHelper
  def sign_in(user)
    if user.is_a?(AdminUser)
      login_as user, scope: :admin_user
    else
      user.invitation_accepted_at = Time.now
      user.save
      login_as user, scope: :user, run_callbacks: false
      user.current_company = user.companies.first
      User.current = user
    end
  end
end
