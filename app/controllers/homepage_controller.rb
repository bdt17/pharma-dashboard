class HomepageController < ApplicationController
  def index
    render layout: false, html: <<~HTML
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Dashboard</title>
</head>
<body>
  <h1>Pharma Transport</h1>
  <p>127 Active Batches | 24 Live Vehicles</p>
</body>
</html>
HTML
  end
end
