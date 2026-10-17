# 06 · Suppliers and purchase orders (Khareedari)

## Purpose

Buy raw material and finished goods from suppliers in a controlled way. **A PO is the only way stock comes in.** A munshi makes the PO, a partner approves it, the godown receives the goods (which raises stock automatically), and the business pays the supplier over time.

## Data

**suppliers**: id (`S01`), name, city, phone, supplies (e.g. "Cotton yarn", "Finished goods (CMT)"), opening_balance (owed to them at go-live).

**purchase_orders**

| Field | Type | Notes |
|---|---|---|
| po_no | text | `PO-1001`, per-company sequence |
| date | date | |
| supplier_id | fk | |
| status | enum | `Draft`, `Pending Approval`, `Approved`, `Received`, `Cancelled` |
| total | money | Sum of lines |
| note | text | Note for the supplier |
| created_by | user | |
| approved_by, approved_at | user, timestamp | |
| received_on, received_by | date, user | |

**purchase_order_lines**: po_no, item_id, qty, unit, rate, amount.

**supplier_payments** (new; the prototype only stored a `paid` total): id, date, supplier_id, po_no (optional), amount, method (Cash, Bank Transfer, Cheque, JazzCash, Easypaisa), ref, paid_by.

**Calculated per PO:**

- paid = sum of supplier_payments for this PO
- balance ("to pay") = total − paid, only once the PO is Received (otherwise 0)
- pay_status = `Not due` (not received yet), `Unpaid`, `Partly paid` or `Paid`

## Workflow

```
Draft → Pending Approval → Approved → Received
   ↘ (delete; drafts only)     ↘ Cancelled (Partner, before Received)
```

1. **Make PO** (Accountant or Partner): choose supplier, add lines. The rate pre-fills from the item and can be changed. Then "Send for approval" or "Save as draft".
2. **Approve** (Partner only). If a partner makes the PO, they may approve it in the same step. Logged as `Approved`.
3. **Receive goods** (Store Incharge or Partner, Approved only): creates one `In` stock move per line with ref = po_no and sets received_on. Logged as `Received` per line with the quantity. v1 receives the full PO; partial receiving is an open decision.
4. **Pay supplier** (Partner or Accountant): records a supplier payment against the PO.
5. **Cancel** (Partner, any state before Received). Stock is not touched.
6. Drafts may be edited or deleted by their maker. Deleting is logged.

**Owner's current instruction:** hide PO status in the UI for now. Keep the statuses and approval in the data and the API. On screen, show only a **Draft** tab, plus "Approved by" and "Goods received" on the view page.

## Screens

### Purchase orders list

- **Tabs:** All · Unpaid · Partly paid · Paid · Draft (counts)
- **Search:** PO number, supplier, item names
- **Date range:** all by default
- **Dropdowns:** Supplier, Made by
- **Totals:** Purchase orders · Value (excludes draft and cancelled) · Paid · Still to pay (red)
- **Columns:** PO #, Date, Supplier, Items (e.g. "Cotton Yarn 20s × 1,520 kg"), Total, To pay, Approved by. Default sort newest first.
- **Actions:** PDF; "New PO" (if role can make POs)
- **Row click:** PO view
- **PDF "Purchase orders"**, landscape: PO #, Date, Supplier, Items, Total, Paid, To pay, Approved by. Totals of Total, Paid, To pay

### New PO form (inline panel)

- Supplier (required), PO date (default today)
- Lines: Item · Qty · Rate (Rs) · Amount, with × to remove and "+ Add another item"
- Live PO total
- Note for supplier (optional)
- Buttons: Send for approval, Save as draft
- Validation: "Please choose a supplier and at least one item with quantity."
- Opening from a stock item's "New PO for this item" pre-fills that item, its rate and its default supplier.

### PO view

- **Title:** PO number; "Bought from <supplier>"
- **Facts:** Supplier, PO date, Made by, Approved by (or "Not yet"), Goods received (date or "Not yet"), Supplier payment status
- **Money strip:** PO total, Paid (green), To pay (red if above 0)
- **Sections:**
  - Items ordered: item, qty, unit, rate, amount
  - Goods received in godown: the stock In moves for this PO (date, item, qty, unit, received by). Click opens the item.
  - Payments to supplier, once that table exists
- **Actions,** shown only when allowed:
  - Download PDF
  - Approve (Partner, when Pending Approval)
  - Receive goods (Store Incharge/Partner, not yet received or cancelled)
  - Pay supplier (when to pay > 0)
  - Edit draft (Draft)
  - Make a copy (creates a new draft with the same lines)
  - Cancel PO (Partner, before received)

### Suppliers

A simple list of suppliers (name, city, phone, supplies, total to pay) with add and edit, under Purchase orders or Settings. A supplier khata like the customer khata (11) is a likely follow-up.

## Dashboard links

- "You owe suppliers" figure = sum of to-pay over received POs.
- Monthly chart "Purchases" series = PO totals by PO date, excluding Draft and Cancelled.

## Acceptance criteria

- An Accountant cannot approve. A Store Incharge cannot create a PO and cannot receive one that is not approved.
- Receiving updates stock for every line in one transaction, or for none.
- A cancelled PO never changes stock and is excluded from Value and Purchases totals.
- The Draft tab lists only drafts. Its PDF says `Show: Draft` in the filters line.
