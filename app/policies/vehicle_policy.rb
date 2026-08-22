# frozen_string_literal: true

class VehiclePolicy < ApplicationPolicy
  def index?
    true # scoped to the user's own organization via Scope below
  end

  def show?
    same_organization?
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

  class Scope < Scope
    def resolve
      scope.where(organization_id: user.organization_id)
    end
  end
end
