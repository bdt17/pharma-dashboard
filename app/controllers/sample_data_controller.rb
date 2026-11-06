# Loads and clears the sample shipments a new account can explore before
# it has its own -- see SampleData. Same permission as adding a batch.
class SampleDataController < ApplicationController
  before_action :authenticate_user!

  def create
    authorize Batch.new(organization: current_organization), :create?

    if SampleData.load!(current_organization, user: current_user)
      AuditLog.record!(event: "sample_data_loaded", user: current_user, ip_address: request.remote_ip)
      redirect_to dashboard_path, notice: "Sample shipments loaded. Clear them any time with the Clear sample data button."
    else
      redirect_to dashboard_path, alert: "Sample data is only available before your first real shipment."
    end
  end

  def destroy
    authorize Batch.new(organization: current_organization), :create?

    SampleData.clear!(current_organization)
    AuditLog.record!(event: "sample_data_cleared", user: current_user, ip_address: request.remote_ip)
    redirect_to dashboard_path, notice: "Sample data cleared."
  end
end
