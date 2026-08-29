class CreateDscsaAssessments < ActiveRecord::Migration[8.1]
  # A completed DSCSA readiness self-assessment: the answers, the computed
  # score, and (optionally) who took it. Public, pre-account -- it's an
  # acquisition funnel. `token` is the unguessable handle for the result page.
  def change
    create_table :dscsa_assessments do |t|
      t.string :token, null: false
      t.jsonb :answers, null: false, default: {}
      t.integer :score, null: false, default: 0
      t.string :band, null: false, default: "unknown"
      t.string :email
      t.string :pharmacy_name

      t.timestamps
    end

    add_index :dscsa_assessments, :token, unique: true
  end
end
