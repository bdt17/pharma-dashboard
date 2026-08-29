# Public "have someone call me" form used from the marketing pages -- the
# compliance-officer retainer, the DSCSA readiness result page, and a
# general entry point. No account required. POST /request-a-call is
# throttled in config/initializers/rack_attack.rb.
class CallRequestsController < ApplicationController
  def new
    @call_request = CallRequest.new(topic: resolved_topic, context: params[:context].to_s.first(4000).presence)
  end

  def create
    @call_request = CallRequest.new(call_request_params)
    @call_request.topic = resolved_topic(@call_request.topic)

    if @call_request.save
      CallRequestMailer.notify(@call_request).deliver_later
      redirect_to call_request_thanks_path
    else
      render :new, status: :unprocessable_content
    end
  end

  def thanks
  end

  private

  def call_request_params
    params.require(:call_request).permit(:name, :email, :pharmacy_name, :phone, :topic, :message, :context)
  end

  def resolved_topic(candidate = params[:topic])
    CallRequest::TOPICS.include?(candidate.to_s) ? candidate.to_s : "general"
  end
end
