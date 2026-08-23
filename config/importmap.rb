# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Vendored manually (no bin/importmap binstub exists in this repo to
# automate it) from https://cdn.jsdelivr.net/npm/signature_pad@5/dist/signature_pad.js
# -- used for capturing custody/proof-of-delivery signatures. MIT licensed.
pin "signature_pad", to: "signature_pad.js"
