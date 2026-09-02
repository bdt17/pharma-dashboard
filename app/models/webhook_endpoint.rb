require "resolv"
require "ipaddr"

# A URL an organization has registered for outbound event delivery, plus
# the per-endpoint HMAC signing secret and the failure bookkeeping that
# auto-disables a dead endpoint. See WebhookDispatcher (fan-out) and
# WebhookDeliveryJob (the actual POST).
class WebhookEndpoint < ApplicationRecord
  belongs_to :organization

  # Consecutive failed deliveries (not retry attempts -- see
  # WebhookDeliveryJob) before the endpoint is switched off. The owner
  # re-enables it from the settings page once they've fixed their side.
  AUTO_DISABLE_AFTER = 10

  EVENT_TYPES = %w[excursion.started excursion.resolved custody.recorded webhook.test].freeze

  # The events an endpoint can choose to filter on. `webhook.test` is
  # excluded -- it's a manual test delivery, always sent regardless of an
  # endpoint's filter (see WebhookEndpointsController#test).
  SUBSCRIBABLE_EVENTS = (EVENT_TYPES - %w[webhook.test]).freeze

  before_validation :assign_signing_secret, on: :create
  before_validation :normalize_subscribed_events

  validates :url, presence: true, uniqueness: { scope: :organization_id }
  validates :signing_secret, presence: true
  validate :subscribed_events_are_known
  # Only when the URL is actually being set -- the failure-tracking writes
  # (record_failure!) must not be blocked because an endpoint's DNS went
  # bad after it was created. The delivery job re-checks at send time.
  validate :url_is_a_public_https_endpoint, if: -> { url.present? && (new_record? || will_save_change_to_url?) }

  scope :active, -> { where(active: true) }

  # HMAC-SHA256 of the raw request body, hex-encoded -- the value the
  # receiver recomputes with the same secret to authenticate the delivery.
  def sign(body)
    OpenSSL::HMAC.hexdigest("SHA256", signing_secret, body)
  end

  def record_success!
    update!(consecutive_failures: 0, last_success_at: Time.current, last_error: nil)
  end

  def record_failure!(message)
    failures = consecutive_failures + 1
    update!(
      consecutive_failures: failures,
      last_failure_at: Time.current,
      last_error: message.to_s.truncate(255),
      active: active? && failures < AUTO_DISABLE_AFTER
    )
  end

  def auto_disabled?
    !active? && consecutive_failures >= AUTO_DISABLE_AFTER
  end

  # Whether this endpoint should receive a given event. An empty
  # `subscribed_events` means "all events" (the pre-filtering default);
  # `webhook.test` is always delivered so the Send-test button works even
  # on a narrowly filtered endpoint.
  def delivers?(event)
    event.to_s == "webhook.test" || subscribed_events.empty? || subscribed_events.include?(event.to_s)
  end

  def all_events?
    subscribed_events.empty?
  end

  # HTTPS, and the host must resolve only to public addresses -- the guard
  # against pointing a webhook at localhost, a private range, or the cloud
  # metadata endpoint (169.254.169.254). Re-checked at delivery time too,
  # since DNS can change after the endpoint is saved.
  def self.public_https_url?(candidate)
    uri = URI.parse(candidate.to_s)
    return false unless uri.is_a?(URI::HTTPS) && uri.host.present?

    addresses = Resolv.getaddresses(uri.host)
    addresses.any? && addresses.none? { |address| blocked_ip?(address) }
  rescue URI::InvalidURIError, Resolv::ResolvError
    false
  end

  # IPv4/IPv6 ranges an outbound webhook must never reach: loopback,
  # RFC1918 / ULA private space, link-local (incl. the 169.254.169.254
  # cloud metadata address), "this network", and multicast.
  BLOCKED_RANGES = [
    "0.0.0.0/8", "127.0.0.0/8", "169.254.0.0/16",
    "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
    "224.0.0.0/4", "::1/128", "fc00::/7", "fe80::/10"
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  def self.blocked_ip?(address)
    ip = IPAddr.new(address.to_s)
    ip = ip.native if ip.ipv4_mapped?
    BLOCKED_RANGES.any? { |range| range.family == ip.family && range.include?(ip) }
  rescue IPAddr::Error
    true
  end

  private

  def assign_signing_secret
    self.signing_secret ||= "whsec_#{SecureRandom.hex(24)}"
  end

  # Drop blanks (Rails sends a "" from the unchecked-box hidden field) and
  # de-dupe, so `subscribed_events` is always a clean set.
  def normalize_subscribed_events
    self.subscribed_events = Array(subscribed_events).map(&:to_s).reject(&:blank?).uniq
  end

  def subscribed_events_are_known
    unknown = subscribed_events - SUBSCRIBABLE_EVENTS
    errors.add(:subscribed_events, "contains unknown events: #{unknown.join(', ')}") if unknown.any?
  end

  def url_is_a_public_https_endpoint
    return if self.class.public_https_url?(url)

    errors.add(:url, "must be an HTTPS URL that resolves to a public address")
  end
end
