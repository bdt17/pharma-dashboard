class Api::WaymoController < Api::BaseController

  def create
    render json: {
      endpoint: "waymo",
      vehicle_id: params[:id],
      status: "dispatched",
      received_at: Time.current,
      payload: params.permit!.to_h
    }
  end
end
