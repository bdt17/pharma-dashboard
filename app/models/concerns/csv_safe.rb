# Neutralizes spreadsheet formula injection in CSV exports. A cell that
# starts with = + - @ (or a tab / carriage return) is treated as a formula
# by Excel, LibreOffice and Google Sheets, so a lot number or event string
# like "=HYPERLINK(...)" typed into the app would execute when an auditor
# opens the export. Prefixing a single quote makes it plain text, per the
# OWASP "CSV Injection" guidance. Only strings are touched -- a negative
# temperature is a number and must keep its minus sign.
module CsvSafe
  FORMULA_TRIGGERS = /\A[=+\-@\t\r]/

  def self.cell(value)
    value.is_a?(String) && value.match?(FORMULA_TRIGGERS) ? "'#{value}" : value
  end

  def self.row(values)
    values.map { |value| cell(value) }
  end
end
