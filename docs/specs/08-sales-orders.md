# 08 · Sales orders

## Purpose

Book what a customer wants, dispatch it from the godown (which lowers stock), and raise the bill.

## Data

**sales_orders**: so_no (`SO-3001`), date, customer_id, status (`Pending`, `Dispatched`, `Delivered`, `Cancelled`), amount (sum of lines), booked_by, dispatched_on, dispatched_by, delivered_on, inv_no (bill made from it), note.

**sales_order_lines**: so_no, item_id (products only), qty, unit, rate (pre-filled from the item's sale price, editable), amount.

## Workflow

```
Pending → Dispatched → Delivered
   ↘ Cancelled (Partner, only while Pending)
```

1. **Book order** (Sales Officer, Partner): customer, lines. Optionally warn if the customer is over their credit limit (see 07).
2. **Dispatch** (Store Incharge, Partner): checks stock for every line. If any line is short, refuse and say which ("Only 40 set of Towel Set (3 pcs) in stock"). Otherwise create one `Out` stock move per line (reason `Sale dispatch`, ref = so_no), set Dispatched, and create the bill (09) the same day. One transaction.
3. **Delivered:** marked when the customer confirms receipt (Store Incharge, Sales Officer, Partner).
4. **Cancel:** Partner only, Pending only. Logged with a reason ("stock not available", "cancelled by party").

**Built:** dispatch always makes the bill in the same transaction, so there is no separate "Make bill" step. Booking past the credit limit shows a warning, not a block. Cancelling is partner-only and needs a reason.

## Screens

### Sales orders list

- **Tabs:** All · Pending · Dispatched · Delivered · Cancelled (counts)
- **Search:** order no., party, item names, bill no.
- **Date range**
- **Dropdowns:** Party, City, Booked by
- **Totals:** Orders · Order value (excludes cancelled) · Not yet dispatched (amber)
- **Columns:** Order #, Date, Party, City, Items (e.g. "Lawn Suit 3-Piece × 80, Chiffon Dupatta × 120"), Amount, Status pill, Bill #. Default sort newest first.
- **Actions:** PDF; "New order" (Sales Officer, Partner)
- **Row click:** order view
- **PDF "Sales orders"**, landscape, with total of Amount

### Order view

- **Title:** order no. and status pill; "Order from <party>, <city>"
- **Facts:** Customer, City, Order date, Booked by, Bill (number or "Not made yet")
- **Money strip:** Order amount
- **Sections:**
  - Items: item, qty, unit, rate, amount
  - Dispatched from godown: the stock Out moves for this order (date, item, qty, unit, dispatched by). Click opens the item.
- **Actions:**
  - Download PDF
  - Open bill
  - Dispatch goods (Pending; Store Incharge/Partner)
  - Make bill (Pending without a bill, if bills are made separately)
  - Customer
  - Cancel order (Partner, Pending)

### New order form (inline panel)

Customer (shows current udhaar and credit limit once picked), date, lines (Item · Qty · Rate · Amount), live total, note. Buttons: Save order.

## Dashboard links

"Needs attention: N orders are not dispatched yet" → opens this list on the Pending tab.

## Acceptance criteria

- Dispatching reduces stock of each line's item by its qty and creates the bill. If any line lacks stock, nothing changes.
- A cancelled order has no stock moves and no bill.
- Order value in the totals strip excludes cancelled orders.
