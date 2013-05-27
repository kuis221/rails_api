include Warden::Test::Helpers

module SignHelper
  def sign_in(user)

    if user.is_a?(AdminUser)
      login_as user, scope: :admin_user
    else
      user.confirmed_at = Time.now
      user.save
      login_as user, scope: :user, :run_callbacks => false
    end
  end
end