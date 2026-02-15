class ComplianceController < ApplicationController
  def index
    render html: '<h1>FDA Part 11 Compliance</h1><p>All systems 21 CFR compliant</p>'
  end
end
