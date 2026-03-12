class BatchesController < ApplicationController
  before_action :set_batch, only: %i[show edit update destroy coc_pdf]
  before_action :authenticate_user!, except: %i[index show coc_pdf]

  # GET /batches
  def index
    @batches = Batch.all.order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "batches_report_#{Date.current}",
               layout: "pdf",
               page_size: 'A4'
      end
    end
  end

  # GET /batches/1
  def show
  end

  # GET /batches/1/chain-of-custody.pdf
  def coc_pdf
    respond_to do |format|
      format.pdf do
        # layout: false fixes the MissingTemplate error
        render pdf: "coc_#{@batch.id}",
               template: "batches/coc_pdf",
               layout: false,  # ← THIS IS THE KEY FIX
               page_size: 'A4'
      end
    end
  end

  # GET /batches/new
  def new
    @batch = Batch.new
  end

  # GET /batches/1/edit
  def edit
  end

  # POST /batches
  def create
    @batch = Batch.new(batch_params)

    if @batch.save
      redirect_to @batch, notice: "Batch was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /batches/1
  def update
    if @batch.update(batch_params)
      redirect_to @batch, notice: "Batch was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /batches/1
  def destroy
    @batch.destroy
    redirect_to batches_url, notice: "Batch was successfully destroyed."
  end

  private

  def set_batch
    @batch = Batch.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Batch not found", status: :not_found
  end

  def batch_params
    params.require(:batch).permit(:status, :batch_number, :pharma_type, :location, 
                                  :temperature, :humidity, :notes) # adjust fields as needed
  end
end
