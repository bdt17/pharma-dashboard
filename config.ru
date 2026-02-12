require "rack"

run Rack::Builder.new do
  use Rack::ContentLength
  
  map "/" do
    run lambda { |env|
      [200, {"Content-Type" => "text/html"}, ["PHARMA DASHBOARD v8.1 LIVE"]]
    }
  end
  
  map "/health" do
    run lambda { |env|
      [200, {"Content-Type" => "application/json"}, ['{"status":"ok","timestamp":"' + Time.now.utc.iso8601 + '"}']]
    }
  end
  
  map "/api/health" do
    run lambda { |env|
      [200, {"Content-Type" => "application/json"}, ['{"status":"ok","version":"8.1"}']]
    }
  end
  
  map "/vehicles" do
    run lambda { |env|
      [200, {"Content-Type" => "application/json"}, ['[]']]
    }
  end
  
  map "/batches" do
    run lambda { |env|
      [200, {"Content-Type" => "application/json"}, ['[]']]
    }
  end
  
  map "/gps/update" do
    run lambda { |env|
      [200, {"Content-Type" => "application/json"}, ['{"received":true,"imei":"' + (env["rack.input"].read[0..15] || "unknown") + '"}']]
    }
  end
  
  map "/gps/stream" do
    run lambda { |env|
      [200, {"Content-Type" => "text/plain"}, [""]]
    }
  end
end
