class TrucksController < ApplicationController
  def index
    render plain: "Fleet Active: 12 trucks online", status: :ok
  end
end
