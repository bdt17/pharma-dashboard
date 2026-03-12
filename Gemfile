source "https://rubygems.org"
ruby "3.3.5"

# Core Rails
gem "rails", "~> 8.1.1"
gem "pg", "~> 1.5.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "propshaft"

# Authentication
gem "devise"

# PDF Generation
gem "wicked_pdf"
gem "wkhtmltopdf-binary"
gem 'prawn'           # Proper PDFs (bye raw PDF strings)
gem 'prawn-table'     # Tables for batch data
gem 'rqrcode'         # GS1 QR codes

# Payments & Billing
gem "stripe-rails", "~> 2.6"

# Image Processing (ActiveStorage)
gem "image_processing", "~> 1.2"

# Asset pipeline
# gem "bootsnap", require: false
gem 'bootsnap', '>= 1.16.0', require: false

# Production only

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
end

gem 'tailwindcss-rails'
gem 'stripe', '~> 10.0'
gem 'pdfkit'
