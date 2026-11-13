require "test_helper"

class Ops::RowCountsTest < ActiveSupport::TestCase
  test "one sorted line per business table with its count and newest update" do
    org = Organization.create!(name: "Main Street Rx")
    lines = Ops::RowCounts.call

    assert_equal lines, lines.sort
    org_line = lines.find { |line| line.start_with?("organizations ") }
    assert_match(/organizations\s+#{Organization.count}\s+\d{4}-\d{2}-\d{2}T/, org_line)
    assert org.updated_at.utc.iso8601.in?(org_line) || Organization.maximum(:updated_at).utc.iso8601.in?(org_line)
  end

  test "skips migration bookkeeping and job-queue tables" do
    tables = Ops::RowCounts.call.map { |line| line.split.first }
    assert_includes tables, "custody_logs"
    assert tables.none? { |t| t.start_with?("schema_migrations", "ar_internal_metadata", "solid_queue_") }
  end
end
