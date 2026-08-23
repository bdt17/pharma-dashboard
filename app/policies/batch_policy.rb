# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  def index?
    true # scoped to the user's own organization via Scope below
  end

  def show?
    same_organization? || own_delivery?
  end

  def create?
    user.admin? || user.dispatcher?
  end

  def update?
    (user.admin? || user.dispatcher?) && same_organization?
  end

  def destroy?
    user.admin? && same_organization?
  end

  # Recording a custody event isn't the same permission as editing the
  # batch's own attributes (update?) -- whoever is physically handling the
  # batch should be able to log a handoff, including the assigned driver.
  def record_custody?
    (user.admin? || user.dispatcher? || user.driver?) && (same_organization? || own_delivery?)
  end

  # A formal Compliance Packet is a billable, customer-facing artifact
  # (each generation counts toward the organization's plan quota -- see
  # the pricing-metering design) -- deliberately narrower than
  # record_custody?. A driver can log what happened during a delivery, but
  # issuing the official versioned report is an organizational/billing
  # action, not a field one. No own_delivery? carve-out here on purpose.
  def generate_compliance_report?
    (user.admin? || user.dispatcher?) && same_organization?
  end

  class Scope < Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end

  private

  # A driver can always see a batch assigned to them, even if for some
  # reason it's tagged to a different organization than their own (e.g. a
  # cross-org delivery handoff) -- the assignment itself is the grant.
  def own_delivery?
    user.driver? && record.driver_id == user.id
  end
end
