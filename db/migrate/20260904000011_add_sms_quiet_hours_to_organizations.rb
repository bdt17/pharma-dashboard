# Two new columns, both additive: `time_zone` (an ActiveSupport::TimeZone
# name, e.g. "Pacific Time (US & Canada)" -- blank means "treat as UTC",
# not "unset", since the app has never had a timezone concept before this)
# and `sms_quiet_hours_enabled` (default false -- opt-in, matching the
# decision that a delayed cold-chain alert should never become the
# default behavior by accident).
class AddSmsQuietHoursToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :time_zone, :string
    add_column :organizations, :sms_quiet_hours_enabled, :boolean, default: false, null: false
  end
end
