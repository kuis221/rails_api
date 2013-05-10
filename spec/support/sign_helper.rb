module SignHelper
  def sign_in(user)
    if user.is_a?(AdminUser)
      post admin_user_session_path,
           {
             :admin_user => {
               :email    => user.email,
               :password => user.password
             }
           }
    else
      post user_session_path,
           {
             :user => {
               :email    => user.email,
               :password => user.password
             }
           }
    end
  end
end