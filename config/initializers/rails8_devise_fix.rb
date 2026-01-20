Rails.application.config.to_prepare do
  Dir[Rails.root.join('app/models/**/*.rb')].each { |f| require f }
  require 'devise'
end
