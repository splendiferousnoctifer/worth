# worth

Tracks what your things are worth to you: cost per day, week, month and year, cost per use, subscriptions, a wishlist and insights. It is not a budget or spending plan.

One static file (`index.html`), no build step.

## Host it on GitHub Pages

1. Create a **public** repo (e.g. `worth`) and push this folder (`index.html`, `README.md`, `.gitignore`).
2. Repo → Settings → Pages → *Deploy from a branch* → `main` / root.
3. Open `https://<you>.github.io/worth/`.

The site contains code only. Your data is never committed here (`.gitignore` blocks `*.json`).

## Keep your data (sync)

Data is saved in the browser automatically. For backup and multi-device sync the app uses a [Supabase](https://supabase.com) project:

- Sign in with your email (a one-time link, no password) in **Settings → Sync across devices**.
- Your data is stored as one row in `public.worth_data`, protected by row-level security so only your account can read or write it.
- Edits from several devices are merged per record (newest change wins) and deletions are remembered.
- The URL and publishable key in `index.html` are meant to be public. The page's Content-Security-Policy only allows requests to that Supabase project.

### One-time Supabase setup

1. Create a project, then run the SQL in `supabase/schema.sql`.
2. Authentication → URL Configuration: set **Site URL** to your Pages URL and add it (and `http://localhost:8791`) under **Redirect URLs**.
3. After you have signed in once, turn off *Authentication → Sign In / Providers → Allow new users to sign up* so nobody else can create accounts.

Export / Import in Settings still works as a manual backup.
