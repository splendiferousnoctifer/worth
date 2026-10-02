# Worth — data schema

Reference for anything (a script, another task or agent) that reads or writes Worth data.

**What this data is:** a tracker of what things are worth to the owner (cost per day, per use, per month). It is **not** a ledger, budget or spending plan: there are no transactions, balances, debts or due dates. Amounts are plain numbers in a single currency.

## 1. Where the data lives

| Place | Detail |
|---|---|
| Browser | `localStorage["worth-tracker:state"]`, the payload below |
| Cloud (optional) | Supabase table `public.worth_data`, one row per user: `user_id uuid pk`, `data jsonb` (the payload), `version int`, `updated_at timestamptz`. Row-level security: a signed-in user only sees their own row. |
| Backup file | Settings → Export backup: the payload without `version`, `tomb`, `settings`, `u` (see §5) |

## 2. Payload

```jsonc
{
  "version": 1,
  "settings": { "currency": "EUR", "income": 3200, "u": 1790000000000 },
  "items":   [ /* Item */ ],
  "subs":    [ /* Subscription */ ],
  "wishes":  [ /* Wish */ ],
  "tomb":    { "<record id>": 1790000000000 }
}
```

- `settings.currency`: one of `EUR USD GBP CHF JPY`. All amounts everywhere are in this one currency; there is no conversion.
- `settings.income`: monthly **net** income, `0` if unset. Only used as a yardstick to show "x % of income".
- `u`: **last-changed time, Unix milliseconds.** See §4.

## 3. Records

All records share: `id` (string, unique across all three lists, a UUID is fine), `name` (string, ≤ 60), `cat` (string category, may be empty, ≤ 24), `u` (ms).
Dates are calendar dates `YYYY-MM-DD` in local time, never timestamps. Money is a non-negative number (not cents).

### Item: something that was bought
| field | type | notes |
|---|---|---|
| `price` | number ≥ 0 | what was paid |
| `resale` | number ≥ 0 | expected or actual resale value; **ignored** unless `resaleOn` or `sold` is true |
| `resaleOn` | boolean | user opted to subtract `resale` from the cost |
| `sold` | boolean | item was sold; implies `end` is set and `resale` is the sale price |
| `start` | date | owned since |
| `end` | date \| null | `null` = still in use; set when retired/sold. Must be ≥ `start` |
| `uses` | integer ≥ 0 | times used (for cost per use) |
| `rating` | 0–5 | "was it worth it", `0` = unrated |

### Subscription: a recurring charge
| field | type | notes |
|---|---|---|
| `price` | number ≥ 0 | amount per billing period |
| `period` | `"month"` \| `"year"` | billing period of `price` |
| `start` | date | |
| `end` | date \| null | `null` = active, otherwise cancelled on that date |

### Wish: something considered but not bought
| field | type | notes |
|---|---|---|
| `price` | number ≥ 0 | |
| `resale` | number ≥ 0 | expected resale |
| `resaleOn` | boolean | subtract `resale` from the cost |
| `keep` | number > 0 | how long it would be kept |
| `unit` | `"years"` \| `"months"` | unit of `keep` |
| `cmp` | item id \| `""` | owned item to compare against |

## 4. Writing rules (so changes survive sync)

Devices merge per record: **the record with the larger `u` wins**; a tombstone newer than a record deletes it.

- **Add** a record: new unique `id`, `u = Date.now()`.
- **Edit** a record: change fields and set `u = Date.now()`. If `u` is not raised the edit can be overwritten by another device.
- **Delete** a record: remove it from its list **and** set `tomb[id] = Date.now()`. Without the tombstone it comes back on the next sync.
- **Settings** change: update `settings` and raise `settings.u`.
- Never reuse an `id` for a different record.
- In Supabase, update `data` **and** increment `version` in one statement, conditional on the old version:
  `PATCH /rest/v1/worth_data?user_id=eq.<uid>&version=eq.<old>` with `{"data": {...}, "version": <old+1>}`. If zero rows come back, someone else wrote first: re-read, re-merge, retry.
- Always read the current payload and **append to it**. Never write a payload that only contains your new records.

### Example: add a subscription
```json
{
  "id": "5b0c7d3e-5f0e-4a8e-9a53-1d6f2a9c0b11",
  "name": "Netflix",
  "cat": "Entertainment",
  "price": 13.99,
  "period": "month",
  "start": "2024-01-01",
  "end": null,
  "u": 1790000000000
}
```
Append it to `subs`. A yearly plan is `"price": 120, "period": "year"`. To cancel, set `end` to the cancellation date and bump `u`.

## 5. Import / export file

Export writes `{ "currency", "income", "items", "subs", "wishes" }`. Import **replaces everything** in the app with the file's content (records without `u` are stamped as changed now), so a file used for import must contain **all** existing records plus the new ones, each with a unique `id`. Import requires `items` to be an array.

## 6. Derived numbers (never stored)

Constants: `MONTH = 30.4375` days, `YEAR = 365.25` days. `today` is the local date.

```
net(item/wish)  = price − (resaleOn || sold ? resale : 0), floored at 0
days(item)      = max(1, daysBetween(start, end ?? today) + 1)      // inclusive
perDay          = net / days
perWeek/Month/Year = perDay × 7 / MONTH / YEAR
costPerUse      = uses > 0 ? net / uses : null

sub.monthly     = period == "year" ? price / 12 : price
sub.perDay      = monthly / MONTH ;  sub.perYear = monthly × 12
sub.paidSoFar   = monthly × days / MONTH                              // days as for items

wish.keepDays   = keep × (unit == "years" ? 365.25 : 30.4375)
wish.perDay     = net / keepDays

totalPerDay     = Σ perDay of items with end == null  +  Σ sub.perDay of subs with end == null
incomeShare(x)  = x_per_month / settings.income                      // only if income > 0
```

## 7. Access and safety

- Cloud access needs the user's own Supabase session (email sign-in). The publishable key in `index.html` is public by design; row-level security does the protecting.
- Do **not** use the project's `service_role` key from anything that ships to a browser; it bypasses row-level security.
- This file and the repo must never contain real user data. Keep backups and exports out of version control (`*.json` is git-ignored).
