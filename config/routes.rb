Rails.application.routes.draw do
get "/up", to: -> (env) { [200, {}, ["ok"]] }

end
