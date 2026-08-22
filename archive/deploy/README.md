# Archived deploy configs

The active deployment target for this app is **Render** (`render.yaml`, `.render.env`,
`Procfile` at the repo root — see the "release: rails db:migrate && rails db:seed" line,
which is Render's release-phase convention).

This directory holds two deploy configurations that were present in the repo alongside
Render's but are not currently in use:

- `kamal/` — Rails 8's default deploy tool (`config/deploy.yml` + `.kamal/`). Restore this
  if the app moves to self-hosted/VPS deployment instead of Render.
- `k8s/` — GKE manifests (`gke-cluster.yaml`, `ingress-hpa.yaml`, `services-db.yaml`,
  `deploy-gcp.sh`). Restore this if the app moves to Kubernetes/GCP.

Keeping unused deploy tooling live at the repo root (as it was before this cleanup) made
it unclear which of the three was actually driving production, and each had its own
environment/secrets expectations that could silently drift out of sync with the real
config. If one of these becomes the real target again, move it back out of `archive/`
so it's clearly live, and retire the others the same way.
