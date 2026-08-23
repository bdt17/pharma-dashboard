# Standard Devise :confirmable columns. Adding this module because
# self-service signup is going live for the first time (see
# Users::RegistrationsController) -- without email confirmation gating
# access, anyone could spin up unlimited new organizations to keep
# re-triggering ComplianceReportQuota's free-tier limit, which would
# undermine the metering this app is meant to sell.
class AddConfirmableToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Existing accounts (created via console, not self-service signup)
    # should not suddenly get locked out -- back-fill confirmed_at so
    # Devise treats them as already confirmed.
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL"
      end
    end
  end
end
