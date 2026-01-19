Rails.application.routes.draw do
  root to: proc { |env|
    ts = Time.current.to_i
    [
      200,
      { "Content-Type" => "text/html", "Cache-Control" => "no-cache" },
      [File.read(Rails.root.join("public", "dashboard.html"))]
    ]
  }
end
