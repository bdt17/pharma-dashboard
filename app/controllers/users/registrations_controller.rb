# Self-service signup: overrides Devise's default registration flow because
# User belongs_to :organization (required), and there was previously no way
# to supply one -- the stock Devise form has no organization field, so every
# signup attempt failed with a bare "Organization must exist" and no way to
# proceed. Nothing in the app created an Organization outside a Rails
# console before this.
#
# Building both records together, in one request: the new user becomes the
# admin of a brand-new organization, not a member of an existing one --
# there's no invite/join-existing-org flow here, deliberately, since that's
# a distinct feature (who's allowed to add members to *your* organization)
# that doesn't exist yet either.
module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      build_resource(sign_up_params)
      resource.role = "admin"
      resource.requires_email_confirmation = true
      resource.build_organization(name: organization_name)

      resource.save
      yield resource if block_given?

      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, "signed_up_but_#{resource.inactive_message}".to_sym
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        # A required-but-blank organization name fails validation on the
        # *associated* Organization, which Rails surfaces on the user as a
        # generic "Organization is invalid" -- copy the real underlying
        # message across so the form says something a person can act on.
        if resource.organization&.errors&.any?
          resource.organization.errors.full_messages.each { |msg| resource.errors.add(:organization_name, msg) }
        end
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    private

    def organization_name
      params.dig(:user, :organization_name)
    end

    def sign_up_params
      params.require(:user).permit(:email, :password, :password_confirmation, :terms_accepted)
    end
  end
end
