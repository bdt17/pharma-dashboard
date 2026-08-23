# Wraps the existing PdfChainOfCustodyGenerator (unchanged, still just
# renders a PDF from a Batch) and turns each generation into a real,
# versioned, hashed ComplianceReport row, persisting the exact PDF bytes
# so a past version can be re-downloaded byte-for-byte later. Called from
# ComplianceReportsController#create.
#
# Note for step 4 (extending the PDF's own content): the hash is computed
# from the rendered bytes, so the PDF can't embed its own content_hash
# without changing what's being hashed. It's fine for the PDF footer to
# show its version number (known before rendering) -- verifying the hash
# is meant to happen out-of-band, by comparing a copy of the file against
# this record, not by the file checking itself.
class ComplianceReportGenerator
  Result = Struct.new(:compliance_report, :pdf_bytes, keyword_init: true)

  def initialize(batch)
    @batch = batch
  end

  def generate!(generated_by:)
    pdf_bytes = PdfChainOfCustodyGenerator.new(batch).generate
    content_hash = Digest::SHA256.hexdigest(pdf_bytes)

    compliance_report = ComplianceReport.create_next_version!(
      batch: batch,
      generated_by: generated_by,
      content_hash: content_hash,
      pdf_data: pdf_bytes
    )

    Result.new(compliance_report: compliance_report, pdf_bytes: pdf_bytes)
  end

  private

  attr_reader :batch
end
