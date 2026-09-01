# Roadmap — next steps

Sequenced in dependency order. Context: the failed-payment recovery banner
(PR #112) and telemetry linking + temperature-excursion alerts (PR #113)
are the two most recent pieces of work this builds on.

## 0. Merge what's done

- Merge **#112** (dunning banner), then **#113** (excursion alerts).
- Rebase #113 if the trivial `test/controllers/dashboard_controller_test.rb`
  conflict appears (both PRs add a test just above the same anchor).

## 1. Solid Queue — the keystone

Everything below needs durable background jobs. Excursion email currently
rides the in-process `:async` adapter and is lost on restart.

- Add the `solid_queue` gem, install its schema, set
  `config.active_job.queue_adapter = :solid_queue`.
- Add a worker process to `Procfile` and `render.yaml`.
- The dead `config/queue.yml` and `config/recurring.yml` scaffolding is
  already in the repo waiting for this.

Size: small–medium. No Redis. Unblocks items 2, 3, 4, 6.

## 2. SMS / voice excursion alerts — first new revenue line

- Twilio delivery, gated behind Pro+ or sold as a per-org add-on (reuse the
  existing Stripe addon-checkout machinery).
- Rationale: a high-value biologic going warm at 2am is worth a text —
  clear willingness to pay.
- Hooks into `ExcursionMonitor`'s notify path.
- **Prereq:** a small per-org alert-config model + settings page
  (recipients, phone numbers, quiet hours). Do this first.

## 3. Automated packet-per-delivery

- Job on the custody `delivered` event → auto-generate the Compliance Packet.
- Packets are manual and metered today, so this drives packet consumption
  and tier upgrades. No new pricing needed.

## 4. `past_due` recovery email

- Complements #112's in-app banner. Stripe retries a failed card for ~3
  weeks; an email reaches people who aren't signing in.
- Small once the queue (item 1) exists.

## 5. Excursion events in the Compliance Packet PDF  *(no queue needed)*

- `PdfChainOfCustodyGenerator` already has a temperature section; feed it
  the new `ExcursionEvent` records (peak temp, duration, reading count)
  instead of only raw telemetry min/max.
- The packet is what customers pay for — worth sharpening. Can be done anytime.

## 6. Outbound webhooks — Enterprise tier

- Let pharmacies push excursion + custody events into their own WMS/ERP.
- `webhook_endpoints` model, HMAC-signed delivery job, retry/backoff.
- This is the feature that justifies a real Enterprise price.

## 7. Growth loop: embeddable verification badge  *(independent)*

- `/verify/:token.svg` plus a `<script>` snippet customers drop on their
  own site.
- Every embed is a backlink and a trust signal — free distribution.

## Before real fleets connect

- Confirm `rack-attack` covers `POST /api/v1/gps`. It's in the Gemfile; the
  ingest endpoint is device-token authenticated and will get hammered once
  real trackers are online.
