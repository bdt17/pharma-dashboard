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
    @quota = ComplianceReportQuota.new(@batch.organization)
  end

  def show
    authorize @batch, :show?
  end

  def create
    authorize @batch, :generate_compliance_report?
    organization = @batch.organization
    quota = ComplianceReportQuota.new(organization)

    credit = quota.credit_to_consume
    overage = credit.nil? && quota.overage_billable?

    if credit.nil? && !overage && quota.exceeded?
      redirect_to batch_compliance_reports_path(@batch), alert: limit_reached_message(quota)
      return
    end

    invoice_item = charge_overage!(organization) if overage
    return if performed?

    result = generate_report!(invoice_item)
    report = result.compliance_report
    credit&.consume!
    PacketOverage.record!(organization: organization, compliance_report: report, invoice_item: invoice_item) if invoice_item

    AuditLog.record!(
      event: "compliance_report_generated",
      user: current_user,
      batch: @batch,
      ip_address: request.remote_ip,
      data: { version: report.version, content_hash: report.content_hash }
    )

    redirect_to batch_compliance_report_path(@batch, report), notice: generated_message(report, invoice_item)
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

  # Creates the pending Stripe invoice item for one extra packet. Any
  # failure here (Stripe down or misconfigured, no customer) blocks the
  # generation rather than handing out a free billable artifact -- the
  # customer can retry or buy a single packet from Billing.
  def charge_overage!(organization)
    StripeBilling.add_packet_overage_item!(
      organization: organization,
      description: "Extra Compliance Packet — lot #{@batch.lot_number}"
    )
  rescue StripeBilling::NotConfigured, Stripe::StripeError => e
    Rails.logger.error("ComplianceReportsController#create: overage billing failed (#{e.class}: #{e.message})")
    redirect_to batch_compliance_reports_path(@batch),
                alert: "Couldn't add an extra packet to your next invoice just now. Try again, " \
                       "or buy a single packet from Billing."
    nil
  end

  # If generation blows up after the invoice item was created, back the
  # charge out so the customer isn't billed for a packet they never got.
  def generate_report!(invoice_item)
    ComplianceReportGenerator.new(@batch).generate!(generated_by: current_user)
  rescue StandardError
    if invoice_item
      begin
        Stripe::InvoiceItem.delete(invoice_item[:invoice_item_id])
      rescue Stripe::StripeError => e
        Rails.logger.error("ComplianceReportsController#create: failed to void overage item #{invoice_item[:invoice_item_id]} (#{e.message})")
      end
    end
    raise
  end

  def limit_reached_message(quota)
    "Monthly limit reached: #{quota.monthly_allowance} compliance packets per month on your current plan. " \
      "Upgrade for a higher allowance, buy a single extra packet from Billing, or turn on overage billing there."
  end

  def generated_message(report, invoice_item)
    base = "Compliance packet v#{report.version} generated."
    return base unless invoice_item

    "#{base} This one is past your monthly allowance — " \
      "#{helpers.number_to_currency(invoice_item[:amount_cents] / 100.0)} will be added to your next invoice."
  end
end
