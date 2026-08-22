class ComplianceController < ApplicationController
  def index
    render plain: "Compliance OK", layout: false
  end
end
