# Builds the small two-segment SVG badge served at /verify/:token/badge.svg
# and embedded on customers' own sites. Deliberately self-contained: no
# external fonts or images (an SVG loaded via <img> can't fetch either),
# fixed geometry, plain text.
class VerificationBadge
  # shields.io-style palette.
  LABEL_BG = "#1f3a53" # brand navy
  VERIFIED_BG = "#0f766e" # accent teal
  UNVERIFIED_BG = "#6b7280" # neutral grey

  LABEL_TEXT = "Pharma Transport"
  HEIGHT = 20
  CHAR_WIDTH = 6.2 # rough advance for the 11px Verdana-ish stack
  PAD = 8

  def initialize(organization)
    @organization = organization
    @verified = organization.verified?
  end

  def svg
    value = @verified ? "DSCSA verified" : "not verified"
    label_w = segment_width(LABEL_TEXT)
    value_w = segment_width(value)
    total_w = label_w + value_w
    value_bg = @verified ? VERIFIED_BG : UNVERIFIED_BG

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{total_w}" height="#{HEIGHT}" role="img" aria-label="#{LABEL_TEXT}: #{value}">
        <title>#{LABEL_TEXT}: #{value}</title>
        <rect width="#{total_w}" height="#{HEIGHT}" rx="3" fill="#{LABEL_BG}"/>
        <rect x="#{label_w}" width="#{value_w}" height="#{HEIGHT}" rx="3" fill="#{value_bg}"/>
        <rect x="#{label_w}" width="4" height="#{HEIGHT}" fill="#{value_bg}"/>
        <g fill="#fff" font-family="Verdana,DejaVu Sans,Geneva,sans-serif" font-size="11">
          <text x="#{label_w / 2.0}" y="14" text-anchor="middle">#{LABEL_TEXT}</text>
          <text x="#{label_w + value_w / 2.0}" y="14" text-anchor="middle">#{value}</text>
        </g>
      </svg>
    SVG
  end

  private

  def segment_width(text)
    (text.length * CHAR_WIDTH + PAD * 2).ceil
  end
end
