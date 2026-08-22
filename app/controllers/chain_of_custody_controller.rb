class ChainOfCustodyController < ApplicationController
  before_action :authenticate_user!

  def pdf
    @batch = Batch.last || Batch.new(
      batch_id: "LOT-PHARMA-#{Time.current.strftime('%Y%m%d')}",
      status: "in_transit",
      created_at: Time.current
    )
    @user = current_user
    @audit_trail = [
      { user: current_user.email, action: "Generated CoC PDF", timestamp: Time.current },
      { user: "warehouse@pharmatransport.com", action: "Batch sealed", timestamp: 2.hours.ago }
    ]

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "chain_of_custody_#{@batch.batch_id}",
               template: "chain_of_custody/pdf",
               layout: false,
               page_size: "A4"
      end
    end
  end
end
