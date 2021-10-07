module Devise
  module Strategies
    class AdminOnly < Base
      # Applies to users where login_enabled is false
      def valid?
        user_param = params[:user]
        if user_param
          user = User.find_by_email params[:user][:email]
          user && !user.login_enabled
        else
          false
        end
      end

      # Always fail login for user when login_enabled is nil or false
      def authenticate!
        fail!("Cannot login user.")
      end
    end
  end
end