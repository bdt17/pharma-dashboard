class AddCardExpiryNotifiedForToOrganizations < ActiveRecord::Migration[8.1]
  def change
    # "YYYY-MM" of the card expiry we've already emailed this org about,
    # so CardExpiryCheckJob warns once per card rather than every day.
    # A replaced card has a different expiry, so the guard lifts on its own.
    add_column :organizations, :card_expiry_notified_for, :string
  end
end
