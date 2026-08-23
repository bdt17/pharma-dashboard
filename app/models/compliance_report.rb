# One immutable row per generated Compliance Packet -- the tamper-evident
# version ledger for a Batch's chain-of-custody PDF. See the compliance
# packet assessment for the full design; this is step 1: the model,
# migration, and versioning/hash-chain logic in isolation, with no
# generator/controller wired to it yet.
class ComplianceReport < ApplicationRecord
  belongs_to :batch
  belongs_to :organization
  belongs_to :generated_by, class_name: "User"

  SHA256_HEX = /\A[a-f0-9]{64}\z/

  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :batch_id }
  validates :content_hash, presence: true, format: { with: SHA256_HEX, message: "must be a 64-character SHA-256 hex digest" }
  validates :previous_hash, format: { with: SHA256_HEX, message: "must be a 64-character SHA-256 hex digest" }, allow_nil: true

  # Append-only ledger, same rationale as CustodyLog: a compliance packet
  # is a record of what was reported at a point in time. A correction is a
  # new version, not an edit of history. `persisted?` is false while the
  # record is still being created, so this only blocks *later* updates/
  # destroys, not the initial save.
  def readonly?
    persisted?
  end

  # The one write path for issuing a new version -- keeps version
  # -sequencing and hash-chaining in one place instead of every caller
  # computing "batch.compliance_reports.max + 1" itself and risking two
  # concurrent callers picking the same number. The unique index on
  # [batch_id, version] is the actual race-safety net; this just retries
  # once if it loses that race.
  def self.create_next_version!(batch:, generated_by:, content_hash:)
    attempts = 0
    begin
      attempts += 1
      last = batch.compliance_reports.order(:version).last
      create!(
        batch: batch,
        organization: batch.organization,
        generated_by: generated_by,
        version: (last&.version || 0) + 1,
        content_hash: content_hash,
        previous_hash: last&.content_hash
      )
    rescue ActiveRecord::RecordNotUnique
      retry if attempts < 3
      raise
    end
  end
end
