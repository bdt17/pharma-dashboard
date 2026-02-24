class DashboardController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    @vehicles_count = Vehicle.count
    @batches_count = Batch.count  
    @latest_telemetry = Telemetry.last
    render layout: 'application', inline: <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Pharma Dashboard</title></head>
      <body>
        <h1>🩺 Pharma Transport Enterprise</h1>
        <p>Vehicles: <%= @vehicles_count %> | Batches: <%= @batches_count %></p>
        <% if @latest_telemetry %>
          <p>Latest GPS: <%= @latest_telemetry.lat %>, <%= @latest_telemetry.lng %></p>
        <% end %>
      </body>
      </html>
    HTML
  end
end
