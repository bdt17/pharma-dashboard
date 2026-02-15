class PdfsController < ApplicationController
  def test
    render plain: "PDF Generation Engine Ready\n#{Time.now.utc.iso8601}", status: 200
  end
end
