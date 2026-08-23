# Triggers and serves the formal, versioned, hashed Compliance Packet --
# distinct from the informal /batches/:id/chain-of-custody.pdf endpoint,
# which stays as a free, unversioned preview any user who can view the
# batch can pull. This is the billable, quota-counted artifact: generating
# one is restricted to admin/dispatcher (see BatchPolicy#generate_compliance_report?),
# and every generation is itself an audited event.
class ComplianceReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_batch
  before_action :set_compliance_report, only: [ :show, :download ]

  def index
    authorize @batch, :show?
    @compliance_reports = @batch.compliance_reports
  end

  def show
    authorize @batch, :show?
  end

  def create
    authorize @batch, :generate_compliance_report?

    result = ComplianceReportGenerator.new(@batch).generate!(generated_by: current_user)
    report = result.compliance_report

    AuditLog.record!(
      event: "compliance_report_generated",
      user: current_user,
      batch: @batch,
      ip_address: request.remote_ip,
      data: { version: report.version, content_hash: report.content_hash }
    )

    redirect_to batch_compliance_report_path(@batch, report), notice: "Compliance packet v#{report.version} generated."
  end

  def download
    authorize @batch, :show?
    send_data @compliance_report.pdf_data,
              filename: "compliance-packet-#{@batch.lot_number}-v#{@compliance_report.version}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_batch
    @batch = Batch.find(params[:batch_id])
  end

  def set_compliance_report
    @compliance_report = @batch.compliance_reports.find(params[:id])
  end
end
