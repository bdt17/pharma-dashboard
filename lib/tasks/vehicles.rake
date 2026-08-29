namespace :vehicles do
  desc "Re-save every vehicle api_token so it's stored encrypted at rest (safe to re-run)"
  task encrypt_api_tokens: :environment do
    scope = Vehicle.where.not(api_token: nil)
    total = scope.count
    done = 0

    scope.find_each do |vehicle|
      vehicle.encrypt # ActiveRecord::Encryption: encrypts encryptable attrs + saves
      done += 1
    end

    puts "Re-saved api_token for #{done}/#{total} vehicles -- all encrypted at rest now."
  end
end
