module BotProtectionHelper
  # Drop inside any form whose controller uses `protect_from_bots` (see
  # BotProtection). The honeypot is moved off-screen rather than
  # display:none -- some bots skip fields hidden that way -- and is kept
  # out of the tab order, screen readers, and browser autofill.
  def bot_protection_fields
    honeypot = tag.div(style: "position:absolute;left:-10000px;top:auto;width:1px;height:1px;overflow:hidden;", aria: { hidden: true }) do
      label_tag(BotProtection::HONEYPOT_FIELD, "Leave this field empty") +
        text_field_tag(BotProtection::HONEYPOT_FIELD, nil, tabindex: -1, autocomplete: "off")
    end
    honeypot + hidden_field_tag(BotProtection::TIMESTAMP_FIELD, BotProtection.form_token)
  end
end
