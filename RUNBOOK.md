# Operations runbook

Operator procedures that need shell access to the production service
(Render dashboard → the web service → **Shell**). Run everything with
`bundle exec` from the app root.

## A user is locked out of two-factor authentication

Symptom: an admin or pharmacist can't get past the "Enter your authentication
code" screen and has no backup codes left, or a dispatcher/driver in the same
situation asks for help. There is deliberately no in-app reset — it requires an
operator.

1. Check the current state:

   ```
   bundle exec rails "two_factor:status[user@example.com]"
   ```

2. Reset it (prompts for confirmation):

   ```
   bundle exec rails "two_factor:reset[user@example.com]"
   ```

This clears the secret, backup codes, and enabled flag, and writes a
`two_factor_reset` entry to the audit log (visible in the user's organization
dashboard). On their next sign-in:

- an **admin / pharmacist** is required to enroll again before using the app;
- anyone else can re-enroll at their leisure from the **Security** page.

The logic lives in `app/services/two_factor_reset.rb`; the tasks are in
`lib/tasks/two_factor.rake`.
