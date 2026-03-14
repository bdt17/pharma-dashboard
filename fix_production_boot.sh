#!/bin/bash
echo "🔧 FIXING RAILS PRODUCTION BOOT + LANDING PAGE"

# 1. Fix production.rb (comment broken action_controller)
sed -i 's/config.action_controller/# config.action_controller/' config/environments/production.rb
sed -i 's/config.action_controller/# config.action_controller/' config/environments/development.rb

# 2. Deploy landing page config.ru
cat > config.ru << 'HEREDOC'
ENV['RACK_ENV'] ||= 'production'
require_relative 'config/environment'

app = lambda do |env|
  if env["PATH_INFO"] == "/"
    [200, {"Content-Type" => "text/html"}, [<<HTML]]
<!DOCTYPE html>
<html>
<head>
  <title>Pharma Transport Dashboard</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:system-ui;background:linear-gradient(135deg,#0f172a 0%,#1e293b 100%);color:#fff;min-height:100vh;position:relative}
    .login{position:fixed;right:2rem;top:2rem;z-index:9999;padding:16px 32px;background:#0984C0;color:#fff!important;text-decoration:none!important;border-radius:12px;font-weight:800;font-size:1.2rem;box-shadow:0 8px 32px rgba(9,132,192,.6)}
    .login:hover{background:#0e73b3;transform:translateY(-4px);box-shadow:0 12px 40px rgba(9,132,192,.7)}
    .container{max-width:1200px;margin:0 auto;padding:8rem 2rem 4rem;text-align:center}
    .logo{font-size:5rem;font-weight:900;background:linear-gradient(45deg,#3b82f6,#10b981);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
  </style>
</head>
<body>
  <a href="/users/sign_in" class="login">🔐 ENTERPRISE LOGIN</a>
  <div class="container">
    <div class="logo">Pharma Transport</div>
    <h1>Phase 10 • 22/22 Endpoints • $5M ARR</h1>
    <p>Fleet GPS • FDA CoC PDFs • Live Phoenix AZ</p>
  </div>
</body>
</html>
HTML
  else
    Rails.application.call(env)
  end
end

run app
HEREDOC

# 3. Clean git + force deploy
git add -A
git commit --no-edit -m "fix: production.rb boot + landing page z9999"
git push origin main

echo "✅ Deploy started - wait 3min then test:"
echo "curl -s https://pharma-dashboard-beq2.onrender.com/ | grep LOGIN"
