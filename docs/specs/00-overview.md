# 00 · Overview

## Product

A web admin app (desktop first, works on phone) for small and mid-size Pakistani businesses that buy raw material or goods, keep stock in a godown, sell on credit to wholesale customers ("parties") and collect payments over weeks.

Core promises:

1. **Stock is trustworthy.** Stock only goes up when goods are received against a purchase order. It only goes down on a sale dispatch or a production issue. Nobody can type a stock number by hand.
2. **Money is trustworthy.** Every bill, payment and khata entry can be traced to the person who made it.
3. **Partners see the same picture.** A business usually has two partners. Both log in, both see everything, and every action is written to an activity log that nobody can edit or delete.
4. **Easy for the user.** Plain English with the Roman Urdu terms business owners already use (udhaar, khata, wusooli). Clean, compact screens. Every list can be filtered, and every list and record can be downloaded as a PDF.

## Users

| Role | Who | Typical work |
|---|---|---|
| Partner (Malik) | The owners, usually 2, with partnership shares | Everything. Approves POs, cancels, reverses, sets credit limits, manages staff |
| Accountant (Munshi) | Office staff | Makes POs, bills and payment receipts, reads khata |
| Store Incharge | Godown staff | Receives goods, dispatches orders, issues raw material to production |
| Sales Officer | Field or market staff | Books sales orders, checks customer khata |

The full permission matrix is in [03-company-users-access.md](03-company-users-access.md).

## Multi-company

- Every record belongs to exactly one company (`company_id` on every table, enforced on every query).
- A user can belong to more than one company, with a role per company. Switching company switches everything.
- Two partners of the same company are two users with the `Partner` role in that company.

## Glossary

Use these words in the UI where shown. In code, use the English names.

| UI term | Meaning | Code name |
|---|---|---|
| Party | A customer (sometimes also used for suppliers) | customer |
| Udhaar | Money a customer owes on credit | receivable / balance |
| Lene hain | "To receive": total customers owe you | receivable |
| Dene hain | "To pay": total you owe suppliers | payable |
| Wusooli | Collection, payment received from a customer | payment |
| Khata | Ledger of one party | ledger |
| Naam | Debit entry in khata (a bill raises what they owe) | debit |
| Jama | Credit entry in khata (a payment lowers what they owe) | credit |
| Baqaya | Balance still due | balance |
| B/F | Brought forward, the opening balance of a period | opening |
| Kacha maal | Raw material | category = Raw Material |
| Tayyar maal | Finished goods | category = Product |
| Godown | Warehouse or store | warehouse |
| Munshi | Accountant or clerk | Accountant role |
| Malik | Owner or partner | Partner role |
| Bill | Invoice to a customer | invoice |
| CMT | Cut-make-trim stitching contractor, a typical supplier of finished goods | supplier |
| GRN | Goods received against a PO | receipt |

## Formats

- **Currency:** PKR, shown as `Rs 12,50,000` with lakh/crore grouping (`Intl.NumberFormat('en-IN')`). No paisa in the UI. Negative amounts are `-Rs 5,000`.
- **Short amounts** (chart labels, axis ticks): `12.5 lakh`, `1.25 crore`, `45k`.
- **Dates:** `18 Oct 2026`. Date and time: `18 Oct 2026, 11:42 am`. Weeks start on Monday.
- **Percent change:** `+12.3%`, `-5.0%`. Green when good, red when bad.
- **Document numbers:** each sequence is per company and never reused, even after cancelling.
  - `PO-1001` purchase order
  - `SO-3001` sales order
  - `INV-2001` bill
  - `RV-5001` payment receipt
  - `PI-YYMMDD` production issue slip
  - Item codes are `R01` for raw material and `P01` for products. Customer codes are `C01`, supplier codes `S01`.
- **Timezone:** Asia/Karachi for everything a user sees, including "today", "this month" and timestamps in the log.

## Global rules

1. **No hard deletes of business records.** Bills, payments, POs, orders and stock moves are cancelled or reversed, never deleted. Drafts that were never approved may be deleted, and the deletion is logged.
2. **Every create, edit, approve, cancel, reverse, receive, dispatch, login, failed login and PDF download** writes an activity log entry (see 04).
3. **Edits keep history.** When a field like a rate, credit limit or due date changes, the log stores the old and new value.
4. **Permissions are checked on the server** for every read and write, not only by hiding buttons.
5. **Totals are calculated, not stored,** where possible. Balances, stock levels and khata running balances come from the underlying entries, so they can never drift.
6. **Money is stored as integers** (rupees) or fixed-point decimals, never floats.
