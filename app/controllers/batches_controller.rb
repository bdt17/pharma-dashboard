class BatchesController < ApplicationController
  before_action :authenticate_user!

  # /batches.pdf never had a real implementation behind it -- the action
  # just rendered placeholder text ("Batches - Phase 10 Enterprise SaaS")
  # to anyone who hit the route, unauthenticated. The real, authenticated,
  # org-scoped batch data (counts, active/non-compliant batches, recent
  # custody activity) already lives on the dashboard
  # (DashboardController#index) -- send people there instead of
  # continuing to serve fake content from a redundant stub. A real
  # "export batches as PDF" feature, if wanted, is a separate build.
  def index
    redirect_to dashboard_path
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
