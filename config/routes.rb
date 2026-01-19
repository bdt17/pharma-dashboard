Rails.application.routes.draw do
  root "dashboard#index"
  get "/dashboard", to: "dashboard#index"
end

get "/", to: proc { |env| 
  ts = Time.current.to_i
  [
    200, 
    { "Content-Type" => "text/html", "Cache-Control" => "no-cache, no-store, must-revalidate" },
    [File.read(Rails.root.join("public", "dashboard.html")) + "<!-- v#{ts} -->"]
  ]
}
