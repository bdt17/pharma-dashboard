class DashboardController < ApplicationController
  def index; head :ok; end
  def health; head :ok; end
  def api_health; head :ok; end
  def vehicles; head :ok; end
  def batches; head :ok; end
  def compliance; head :ok; end
  def billing; head :ok; end
end
