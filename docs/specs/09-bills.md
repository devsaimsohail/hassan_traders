# 09 · Bills (Invoices)

## Purpose

The bill is what the customer owes for a dispatch. It drives udhaar, due dates, overdue follow-up and the khata.

## Data

**invoices**: inv_no (`INV-2001`), date, due_date (= date + customer's terms_days), customer_id, so_no, amount (sum of lines), created_by, note.

**invoice_lines**: line_id (`INV-2001-1`), inv_no, item_id, qty, unit, rate, amount.

**Calculated per bill** (as of today):

- received = sum of payments with inv_no = this bill
- balance (baqaya) = amount − received
- status:
  - `Paid` if balance ≤ 0
  - else `Overdue` if due_date < today
  - else `Partial` if received > 0
  - else `Unpaid`
- days_overdue = today − due_date when Overdue, else 0

## Rules

- Bills are created by dispatching an order (08), copying its lines. A manual bill for walk-in sales can be added later.
- Bills are never deleted. A wrong bill is cancelled (Partner) with a reason; cancelled bills drop out of balances and khata but stay listed.
- Extending a due date is Partner-only, logged with old → new and who agreed.
- No sales tax in v1 (open decision). NTN and STRN print on the bill.

## Screens

### Bills list

- **Tabs:** All · Unpaid · Partial · Overdue · Paid (counts)
- **Search:** bill no., party, order no., city
- **Date range:** bill date
- **Dropdowns:** Party, City
- **Totals:** Bills · Bill amount · Received · Baqaya (red)
- **Columns:** Bill #, Date, Party, City, Amount, Received, Baqaya, Due date, Status pill. Days late shows on wide screens. Default sort newest first.
- **Row click:** bill view
- **PDF "Bills report"**, landscape: Bill #, Date, Party, City, Amount, Received, Baqaya, Due date, Days late, Status. Totals of Amount, Received, Baqaya. Overdue rows print in dark red.

### Bill view

- **Title:** "Bill INV-2041" with status pill; "party, city"
- **Facts:** Customer, Bill date, Due date, Days late (red, only if overdue), Order
- **Money strip:** Bill amount, Received (green), Baqaya (red if above 0)
- **Sections:**
  - Items: Item, Qty, Unit, Rate, Amount
  - Payments against this bill: Receipt #, Date, Method, Cheque/TID, Amount. Click opens the receipt.
- **Actions:**
  - Download PDF (bill layout in 02)
  - Receive payment: opens Payments with the customer and this bill pre-selected and the amount set to the balance
  - Open order
  - Customer khata
  - Extend due date (Partner, unpaid bills)
  - Cancel bill (Partner)

## Dashboard links

"Needs attention: N bills are past their due date · Rs X" → opens this list on the Overdue tab.

## Acceptance criteria

- A bill with due date yesterday and Rs 1 still unpaid shows Overdue. Paying that Rs 1 makes it Paid.
- The totals strip Baqaya equals the sum of the Baqaya column for the visible rows. The PDF shows the same.
- The bill PDF's "Balance due" equals Baqaya on screen.
