# worth

Tracks what your things are worth to you: cost per day, week, month and year, cost per use, subscriptions, a wishlist and insights. It is not a budget or spending plan.

One static file (`index.html`), no build step.

## Host it on GitHub Pages

1. Create a **public** repo (e.g. `worth`) and push this folder (`index.html`, `README.md`, `.gitignore`).
2. Repo → Settings → Pages → *Deploy from a branch* → `main` / root.
3. Open `https://<you>.github.io/worth/`.

The site contains code only. Your data is never committed here (`.gitignore` blocks `*.json`).

## Keep your data (sync)

Data is saved in the browser automatically. To keep it safe and share it across devices:

1. Create a **private** repo, e.g. `worth-data`, with a README so it isn't empty.
2. Create a fine-grained token at <https://github.com/settings/personal-access-tokens/new?name=worth-sync&description=Sync%20data%20for%20the%20worth%20app&target_name=splendiferousnoctifer&expires_in=90&contents=write> (prefilled; you only pick the repository):
   *Only select repositories* → `worth-data`, permission **Contents: Read and write**, with an expiry.
3. In the app: Settings → *Sync across devices* → enter `you/worth-data` and the token → Connect.

The app keeps one file, `worth.json`, in that repo. Changes are pushed a moment after you make them and pulled when you open the app. Edits from two devices are merged per record (newest change wins). The app refuses to connect to a public repo. The page's Content-Security-Policy only allows requests to `api.github.com`, and the token stays in your browser's local storage.

Export / Import in Settings still works as a manual backup.
