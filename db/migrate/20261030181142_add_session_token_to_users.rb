class AddSessionTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    # Mixed into User#authenticatable_salt, so rotating it ("Sign out other
    # devices") invalidates every stored session and remember-me cookie.
    # Starts nil: nobody is signed out by this migration.
    add_column :users, :session_token, :string
  end
end
