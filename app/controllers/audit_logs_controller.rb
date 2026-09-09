# The full audit trail, and a real export -- the Dashboard and Compliance
# pages have only ever shown inline slices (10 and 25 entries), with no
# way to see or hand over the rest. AuditLogPolicy is read-only (viewing
# is open to any org member, same as those inline slices already were;
# there's nothing here to mutate).
class AuditLogsController < ApplicationController
  before_action :authenticate_user!

  # Newest 200 on screen -- same "cap it, don't build a full pager until
  # someone actually needs history past that" call as the webhook
  # delivery log. CSV export (see AuditLog.to_csv) always has everything,
  # regardless of the on-screen cap -- that's the point of it.
  ON_SCREEN_LIMIT = 200

  def index
    logs = policy_scope(AuditLog).order(created_at: :desc)

    respond_to do |format|
      format.html { @audit_logs = logs.limit(ON_SCREEN_LIMIT) }
      format.csv do
        filename = "audit-log-#{current_organization.name.parameterize}-#{Date.current.iso8601}.csv"
        send_data logs.to_csv, filename: filename, type: "text/csv"
      end
    end
  end
end
