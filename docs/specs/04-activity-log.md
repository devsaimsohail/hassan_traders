# 04 · Activity log ("Kis ne kya kiya")

## Purpose

A permanent record of who did what and when, so two partners can trust the books and spot mistakes or misuse. **Nobody can edit or delete it, not even a partner.**

## Data: activity_log (append-only)

| Field | Type | Notes |
|---|---|---|
| id | serial | Shown as `L00001` |
| company_id | uuid | |
| at | timestamp | Asia/Karachi |
| user_id, user_name, role | | Name and role copied at write time, so renames don't rewrite history |
| action | enum | Created, Approved, Received, Dispatched, Issued, Payment received, Edited, Deleted, Cancelled, Reversed, Logged in, Login failed, Downloaded PDF |
| module | enum | Purchase, Stock, Sales, Invoices, Payments, Customers, Users, Settings, Reports, Login |
| ref | text | Record number it is about: `PO-1042`, `SO-3101`, `INV-2120`, `RV-5150`, item code `R01`, customer code `C08`, user code `U06`, or empty |
| detail | text | One plain sentence, e.g. "Received 1,500 kg Cotton Yarn 20s — stock updated" |
| old_value, new_value | json, nullable | For edits, e.g. rate 700 → 720 |
| device | text | e.g. "Android · Faisalabad", "Windows PC · Office" |
| ip | text | |

- The database user the app runs as has INSERT and SELECT only on this table. No UPDATE or DELETE.
- Writes happen in the same transaction as the business change, so a change can't happen without its log entry.

## What gets logged (at least)

| Event | Example detail |
|---|---|
| PO created | New PO for Kohinoor Yarn Traders — Rs 10,94,400 |
| PO approved | Approved PO — Rs 10,94,400 |
| Goods received | Received 1,500 kg Cotton Yarn 20s — stock updated |
| Production issue | Weekly raw material issued to production |
| Order created | Order from Khan Brothers — Rs 3,46,000 |
| Order dispatched | Dispatched to Khan Brothers (Peshawar) |
| Bill created | Bill to Khan Brothers — Rs 3,46,000 |
| Payment received | Rs 1,50,000 Cheque from Khan Brothers against INV-2101 |
| Edits | Rate changed: Rs 700 → Rs 720 (Cotton Yarn 20s); Credit limit changed: Rs 10,00,000 → Rs 7,00,000; Due date extended by 15 days — approved by Haji Muhammad Aslam |
| Cancellations and reversals | PO cancelled — rate too high; Order cancelled — stock not available |
| Deleted draft | Deleted draft PO (never approved) for Shaheen Packages |
| People | Disabled login for Kamran Javed (left the company) |
| Logins | Logged in from Lahore; Login failed: 3 failed attempts — account is disabled |
| PDF downloads | Downloaded Bills report (this month) |

## Screen: Activity log page (Partner: Yes, Accountant: View)

- A short info line on top: "This log cannot be edited or deleted, not even by a partner, so both partners always see the same record."
- List page pattern (01-shared-ui):
  - **Tabs:** Everything · Needs attention (Deleted, Login failed, Edited, Cancelled, Reversed) · Money (Payments, Invoices) · Stock (Stock, Purchase)
  - **Search:** what happened, ref, person
  - **Date range:** default This month
  - **Dropdowns:** Person, Section (module), Action
  - **Totals strip:** Entries · People · Needs attention
  - **Columns:** When, Person, Action (pill), Ref, What happened, Device. Role and section also show on wide screens.
  - Deleted and failed-login rows get the red left bar.
  - **Click a row** to open the record named in `ref` (PO, order, bill, receipt, customer or item view). Rows without a ref (logins) don't open and show no chevron.
- **PDF:** landscape, columns When, Person, Role, Action, Ref, What happened, Device, following the filters.
- An Accountant sees the log but cannot download other people's login history. Decide with the owner whether that restriction is wanted.

## Dashboard use

The dashboard's "Latest activity" card shows the 5 newest entries (When, Who, What), with a "See full log" link.

## Acceptance criteria

- Every action listed above creates exactly one entry with the right user, time and ref.
- An attempt to update or delete a log row fails at the database level.
- Filtering to Person = Bilal Ahmed, Section = Payments, Last month, then downloading, gives a PDF with the same rows.
