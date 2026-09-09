# frozen_string_literal: true

class AuditLogPolicy < ApplicationPolicy
  # Read-only, same access level the Dashboard/Compliance pages already
  # give their own inline "Recent activity" slices -- any signed-in
  # member of the organization, matching Alerts/Webhooks (viewing is
  # open to all; only mutating actions elsewhere are admin-gated, and
  # there's nothing to mutate here).
  def index?
    true
  end

  class Scope < Scope
    # AuditLog has no organization_id of its own -- every entry belongs
    # to the user who triggered it, so scoping goes through that
    # association instead of ApplicationPolicy#same_organization?
    # (which needs record.organization_id directly). Matches the query
    # DashboardController and ComplianceController already ran inline;
    # centralized here so a third call site doesn't duplicate it again.
    def resolve
      scope.where(user: user.organization.users)
    end
  end
end
