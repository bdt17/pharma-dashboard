# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # Shared building block for every tenant-scoped record (Vehicle, Batch,
  # ...): a user may only act on records belonging to their own
  # organization. Concrete policies opt into this explicitly rather than
  # ApplicationPolicy assuming every record has an `organization` -- some
  # records (e.g. the user's own account) don't.
  def same_organization?
    record.respond_to?(:organization_id) && record.organization_id == user.organization_id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
