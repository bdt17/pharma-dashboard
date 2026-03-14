class BatchesController < ApplicationController
  def index; end
  
  def show
    if params[:id] == '1'
      send_file Rails.root.join('public', 'test.pdf'), 
                filename: 'chain-of-custody.pdf', 
                type: 'application/pdf', 
                disposition: 'attachment'
    else
      render plain: "Batch #{params[:id]} - Coming Soon", status: 200
    end
  end
end
