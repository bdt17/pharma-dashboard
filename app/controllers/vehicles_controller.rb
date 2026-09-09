# Self-serve vehicle registration -- the piece of fleet setup that never
# existed in the app before this: every Vehicle here was previously
# created by hand (a console command, or the paid White-Glove Setup
# service). An admin or dispatcher can now register one themselves and
# get the API token a GPS tracker device needs to start reporting,
# without waiting on anyone. See VehiclePolicy for who can do what.
class VehiclesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle, only: %i[edit update]

  def new
    @vehicle = Vehicle.new
    authorize @vehicle
  end

  def create
    @vehicle = current_organization.vehicles.build(vehicle_params)
    authorize @vehicle

    if @vehicle.save
      # Shown exactly once, the same way 2FA backup codes are -- api_token
      # is encrypted at rest and never displayed again after this redirect.
      flash[:api_token] = @vehicle.api_token
      redirect_to edit_vehicle_path(@vehicle), notice: "Added #{@vehicle.name}. Copy its device token below before you leave this page."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @vehicle
  end

  def update
    authorize @vehicle

    if @vehicle.update(vehicle_params)
      redirect_to edit_vehicle_path(@vehicle), notice: "Updated #{@vehicle.name}."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_vehicle
    @vehicle = current_organization.vehicles.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:name, :imei, :plate)
  end
end
