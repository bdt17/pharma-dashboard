namespace :ops do
  # Backup-restore drill fingerprint -- see RUNBOOK.md "Backup restore drill".
  #   bin/rails ops:row_counts                                  # this app's DB
  #   DATABASE_URL=<restored copy's URL> bin/rails ops:row_counts
  desc "Print row count + newest updated_at per table, for comparing a restored backup"
  task row_counts: :environment do
    puts Ops::RowCounts.call
  end
end
