require "test_helper"

class CsvSafeTest < ActiveSupport::TestCase
  test "prefixes strings that a spreadsheet would treat as a formula" do
    [ "=1+1", "+1", "-1", "@SUM(A1)", "\tx", "\rx" ].each do |value|
      assert_equal "'#{value}", CsvSafe.cell(value)
    end
  end

  test "leaves ordinary strings and non-strings alone" do
    assert_equal "LOT-1", CsvSafe.cell("LOT-1")
    assert_equal(-5.5, CsvSafe.cell(-5.5))
    assert_nil CsvSafe.cell(nil)
  end
end
