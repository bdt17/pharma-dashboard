class LandingController < ApplicationController
  def index
  end
  
  def pharmacists
    render plain: "PHARMACIST PORTAL COMING SOON - FDA Compliant Order System", status: :ok
  end
  
  def patients
    render plain: "PATIENT APP COMING SOON - iOS/Android Pharmacy Orders", status: :ok
  end
end
