class BatchesController < ApplicationController
  def index; end
  def show
    if params[:id] == '1'
      send_file Rails.root.join('public', 'test.pdf'), 
                filename: 'chain-of-custody.pdf', 
                type: 'application/pdf', 
                disposition: 'attachment'
    end
  end
end
