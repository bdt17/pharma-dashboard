Devise.setup do |config|
  config.after_sign_in_path_for = lambda { |user| root_path }
end
