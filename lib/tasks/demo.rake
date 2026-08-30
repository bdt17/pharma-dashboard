namespace :demo do
  desc "Rebuild the demo organization's operational data (vehicles/batches/custody/telemetry) from scratch"
  task reset: :environment do
    if Rails.env.production?
      abort "demo:reset is refused in production."
    end

    organization = Organization.find_by(name: "Demo Pharma Transport")
    abort "No 'Demo Pharma Transport' organization -- run bin/rails db:seed first." unless organization

    DemoData.reset!(organization)
    puts "Rebuilt: #{organization.vehicles.count} vehicles, #{organization.batches.count} batches " \
         "(#{organization.batches.non_compliant.count} in excursion)."
  end
end
