Rails.application.routes.draw do
  # Your dashboard is served automatically from public/index.html
  # No root route needed - Rails does this by default
end
  get '/', to: 'dashboard#index'
