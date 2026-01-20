class LandingController < ApplicationController
  def index; end
  def pharmacists
    render plain: "🏥 PHARMACIST PORTAL - FDA Orders Live", status: :ok
  end
  def patients
    render plain: "📱 PATIENT APP - Pharmacy Delivery Live", status: :ok
  end
end
