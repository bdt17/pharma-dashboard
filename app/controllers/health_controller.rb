class HealthController < ApplicationController
  def index
  end
end
def index; render plain: "🟢 PHARMA OK #{Time.now}"; end
