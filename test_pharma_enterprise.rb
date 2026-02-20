#!/usr/bin/env ruby
require "net/http"
require "uri"
require "json"

BASE_URL = "https://pharma-dashboard-beq2.onrender.com"
SCRIPT_VERSION = "v9.2"

# [PASTE THE FULL IMPROVED SCRIPT FROM EARLIER - too long for here]
# Key fix: replace line 92 with:
fda_ready = root[:body]&.to_s&.include?("Pharma") || 
            vehicles[:body]&.to_s&.include?("PHX") ||
            (api_health[:json] && api_health[:json]['status'] == 'ok')
