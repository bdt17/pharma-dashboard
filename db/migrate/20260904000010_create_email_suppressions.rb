# A global opt-out list for marketing-style email (the DSCSA assessment
# follow-up sequence today; anything similar later). Keyed by email, not
# by whatever record originated the email -- the same person can retake
# the DSCSA assessment and generate a new DscsaAssessment row, and an
# unsubscribe has to stick regardless. Transactional mail (dunning, card
# expiry, excursion alerts) is unaffected; those go to existing paying
# customers about their own account, not prospects.
class CreateEmailSuppressions < ActiveRecord::Migration[8.1]
  def change
    create_table :email_suppressions do |t|
      t.string :email, null: false

      t.timestamps
    end

    add_index :email_suppressions, :email, unique: true
  end
end
