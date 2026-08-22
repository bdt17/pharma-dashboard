# Prawn's built-in AFM fonts (Helvetica, etc.) only support WinAnsi-range
# characters. We stay within that (basic Latin + the degree sign for °C),
# so silence the advisory warning it prints on every PDF generation.
Prawn::Fonts::AFM.hide_m17n_warning = true
