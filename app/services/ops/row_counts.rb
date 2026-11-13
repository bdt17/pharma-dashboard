module Ops
  # A fingerprint of the database for the backup-restore drill (RUNBOOK.md):
  # every application table's row count and newest updated_at, one line
  # per table, sorted, so two runs -- production and a restored copy --
  # can be compared with `diff`. Job-queue and cache tables are skipped:
  # they churn constantly and aren't business data. Read-only.
  class RowCounts
    SKIP = /\A(schema_migrations|ar_internal_metadata|solid_queue_|solid_cache_|solid_cable_)/

    def self.call(connection = ActiveRecord::Base.connection)
      connection.tables.reject { |table| table.match?(SKIP) }.sort.map do |table|
        quoted = connection.quote_table_name(table)
        count = connection.select_value("SELECT COUNT(*) FROM #{quoted}").to_i
        newest = if connection.column_exists?(table, :updated_at)
          connection.select_value("SELECT MAX(updated_at) FROM #{quoted}")&.then { |t| Time.zone.parse(t.to_s).utc.iso8601 }
        end
        "#{table.ljust(32)} #{count.to_s.rjust(8)}  #{newest || '-'}"
      end
    end
  end
end
