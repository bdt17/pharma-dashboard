# Wrong 2FA codes used to share Devise's failed_attempts counter, which
# Devise resets on every successful password sign-in -- so an attacker
# holding the password could guess codes indefinitely, 4 per login. This
# counter is reset only by a correct second factor (or an expired lock).
class AddSecondFactorFailedAttemptsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :second_factor_failed_attempts, :integer, default: 0, null: false
  end
end
