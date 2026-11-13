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

## Backup restore drill (quarterly, and before any risky migration)

A backup you have never restored is a hope, not a backup. This drill proves
production data can be recovered, and how long it takes. It never touches the
live database: the restore goes to a **new** database that is deleted afterwards.

0. **Check the plan.** Render dashboard → the production Postgres database. On
   Render's free Postgres plan there are no backups and the database itself
   expires. If production is on it, upgrade first; nothing below is possible
   without a paid plan.
1. **Fingerprint production.** Render → the web service → **Shell**:

       bin/rails ops:row_counts

   Copy the output (one line per table: name, row count, newest `updated_at`)
   into a local file, e.g. `prod-YYYYMMDD.txt`. Note the time.
2. **Restore to a new database.** Render → the database → **Recovery**
   (point-in-time recovery) → pick a time a few minutes before step 1 → restore
   into a **new** database named `pharma-restore-drill-YYYYMMDD`. If the screen
   differs, follow Render's "Postgres backups and recovery" docs. Note when the
   restore starts and finishes.
3. **Fingerprint the copy.** Copy the new database's *internal* connection URL,
   then in the web service's Shell run, for this one command only:

       DATABASE_URL='<restored copy internal URL>' bin/rails ops:row_counts

   Save it as `restore-YYYYMMDD.txt`. Never set the service's `DATABASE_URL`
   environment variable to the copy.
4. **Compare.** `diff prod-YYYYMMDD.txt restore-YYYYMMDD.txt`. Every table should
   match, except rows created or updated between the restore point and step 1
   (their newest `updated_at` shows it). Missing tables or much lower counts
   mean the restore failed: stop and contact Render support.
5. **Delete the copy** (Render → that database → Settings → Delete) so it isn't
   billed.
6. **Log it** below: date, restore point, how long the restore took, result.

| Date | Restore point | Restore took | Result | By |
|---|---|---|---|---|
| _not yet run_ | | | | |
