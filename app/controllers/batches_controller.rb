class BatchesController < ApplicationController
  def index
    @page_title = "Batch Tracking"
    @content = "💉 CHAIN OF CUSTODY\n✅ Temperature History\n✅ Location Audit Trail\n✅ Signature Verification\n✅ 21 CFR Part 11"
  end
  
  def chain_of_custody
    @page_title = "Chain of Custody ##{params[:id]}"
    @content = "🔗 BATCH #{params[:id]}\n📅 Full audit trail generated\n✅ DEA/FDA compliant"
  end
end
