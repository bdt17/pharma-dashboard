class BatchesController < ApplicationController
  def index; render plain: "GS1 pharma batches → FDA 21 CFR 11"; end
  def show; render plain: "LOT-PHARMA-20260223 → 2-8°C"; end
  def custody_report; render plain: "PDF Chain of Custody ready"; end
end
