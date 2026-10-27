# Keep secrets and personal data out of the logs. Without this, every
# sign-in, signup, password reset, and 2FA challenge wrote the password,
# reset/confirmation token, or OTP code into Render's logs in plaintext,
# along with lead emails/phones, device IMEIs, and whole base64 signature
# images. Matching is partial and case-insensitive (:passw catches
# password, password_confirmation, current_password; :token catches
# reset_password_token, confirmation_token, api_token, ...). Also applied
# to ActiveRecord#inspect via filter_attributes.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :signature, :phone, :imei
]
