# Off by default, like every other alert-behavior toggle in the app --
# ExcursionNotifier.resolved sends no SMS at all unless an org opts in.
class AddAllClearSmsEnabledToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :all_clear_sms_enabled, :boolean, default: false, null: false
  end
end
