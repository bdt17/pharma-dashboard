class AddPdfDataToComplianceReports < ActiveRecord::Migration[8.1]
  def change
    # Stored directly in Postgres rather than via ActiveStorage: this app's
    # Render web service has no persistent disk or cloud storage service
    # configured (confirmed -- config/storage.yml has no non-local service,
    # and Render's default filesystem is ephemeral across deploys/restarts,
    # which we've seen happen repeatedly this session). A tamper-evident
    # record that silently loses its own file on the next deploy defeats
    # the point. Postgres is the one place in this stack that's actually
    # durable, and these files are small (a few KB to low hundreds of KB).
    #
    # Persisting the exact bytes (not just the hash) is also what makes a
    # *past* version re-downloadable byte-for-byte as it was issued, rather
    # than only provable-if-you-still-have-a-copy-elsewhere.
    add_column :compliance_reports, :pdf_data, :binary, null: false
  end
end
