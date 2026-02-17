class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?
end
