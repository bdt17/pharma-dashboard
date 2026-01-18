
# Render production secret key fix
config.secret_key_base = ENV['SECRET_KEY_BASE']
# Render production fixes
config.force_ssl = false
config.eager_load = true
config.secret_key_base = ENV['SECRET_KEY_BASE']
config.public_file_server.enabled = true
config.secret_key_base = ENV['SECRET_KEY_BASE'] || 'fallback_dummy_key_for_render'
config.force_ssl = false
config.eager_load = true
