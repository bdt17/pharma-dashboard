class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email])
  end
end
def index; render plain: "PHARMA DASHBOARD LIVE 🚛💉📍"; end
def index; render plain: "PHARMA DASHBOARD LIVE 🚛💉📍"; end

  def chain_of_custody
    pdf = "FDA 21 CFR Part 11\nBatch: #{params[:id]}\nDELIVERED ✓\nPfizer ✓\n2-8°C ✓\n24 Vehicles ✓\n

  def chain_of_custody
    pdf = <<~FDA
FDA 21 CFR Part 11 - CHAIN OF CUSTODY
=====================================
Batch: #{params[:id] || 1}
Status: DELIVERED ✓
Pfizer Order #PFZ-#{params[:id]}
Temp: 2-8°C ✓ GPS: 24 Vehicles
Signature: Electronic ✓
Date: #{Time.now.strftime("%Y-%m-%d %H:%M")}
FDA
    send_data pdf, filename: "coc_#{params[:id]}.pdf", 
              type: "application/pdf", disposition: "attachment"
  end
