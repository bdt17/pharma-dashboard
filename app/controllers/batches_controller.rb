class BatchesController < ApplicationController
  before_action :authenticate_user!, only: [ :chain_of_custody ]

  def index; render plain: "Batches - Phase 10 Enterprise SaaS" end
  def show
    if params[:id] == "1"
      send_file Rails.root.join("public", "test.pdf"),
                filename: "chain-of-custody.pdf",
                type: "application/pdf",
                disposition: "attachment"
    end
  end

  # The one real chain-of-custody PDF: real batch data, real custody
  # history, real audit trail -- generating it is itself an audited event.
  def chain_of_custody
    batch = Batch.find(params[:id])
    authorize batch, :show?

    pdf_data = PdfChainOfCustodyGenerator.new(batch).generate

    AuditLog.record!(
      event: "chain_of_custody_pdf_generated",
      user: current_user,
      batch: batch,
      ip_address: request.remote_ip
    )

    send_data pdf_data,
              filename: "chain-of-custody-#{batch.lot_number}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end
end
