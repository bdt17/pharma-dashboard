# FIXED Routes.rb - Rails 8.1.2
Rails.application.routes.draw do
  root "home#index"
  get "/health", to: "home#health"
end
# Phase 15 LIVE
