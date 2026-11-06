class AddReportDownloadedAtToDscsaAssessments < ActiveRecord::Migration[8.1]
  def change
    add_column :dscsa_assessments, :report_downloaded_at, :datetime
  end
end
