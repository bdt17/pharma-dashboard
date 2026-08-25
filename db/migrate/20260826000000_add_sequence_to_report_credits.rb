class AddSequenceToReportCredits < ActiveRecord::Migration[8.1]
  def change
    # Previously exactly one ReportCredit could ever exist per checkout
    # session (a plain unique index on stripe_checkout_session_id). A bulk
    # pack (see StripeBulkAddonPriceSync) grants several discrete credit
    # rows from a single checkout session, so each row within that session
    # now needs its own sequence number -- the pair is what's actually
    # unique, not the session id alone.
    remove_index :report_credits, :stripe_checkout_session_id, unique: true
    add_column :report_credits, :sequence, :integer, null: false, default: 1
    add_index :report_credits, [ :stripe_checkout_session_id, :sequence ], unique: true,
              name: "index_report_credits_on_session_id_and_sequence"
  end
end
