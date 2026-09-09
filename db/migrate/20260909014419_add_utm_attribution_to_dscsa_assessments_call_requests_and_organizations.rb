# First-touch UTM attribution (see UtmTracking) on every place the
# acquisition funnel ends in a record: a DSCSA assessment, a call request,
# or a brand-new organization from self-serve signup. Nullable everywhere
# -- most traffic (direct visits, organic search, an existing customer)
# has no campaign to attribute, and that's not an error state.
class AddUtmAttributionToDscsaAssessmentsCallRequestsAndOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :dscsa_assessments, :utm_source, :string
    add_column :dscsa_assessments, :utm_campaign, :string
    add_column :call_requests, :utm_source, :string
    add_column :call_requests, :utm_campaign, :string
    add_column :organizations, :utm_source, :string
    add_column :organizations, :utm_campaign, :string
  end
end
