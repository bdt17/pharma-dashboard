class ReportsController < ApplicationController
  def pdf
    @batch = Batch.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "batch_#{@batch.id}_custody",
               template: "reports/pdf",
               layout: 'pdf'
      end
    end
  end
end
