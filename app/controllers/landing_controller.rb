class LandingController < ApplicationController
  def index; end
  def pharmacists
    render plain: "🏥 PHARMACIST PORTAL LIVE - FDA Compliant", status: :ok
  end
  def patients
    render plain: "📱 PATIENT APP LIVE - Pharmacy Delivery", status: :ok
  end
end
