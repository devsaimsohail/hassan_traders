# 05 · Items and stock (Maal)

## Purpose

Know what is in the godown and what it is worth, with every change traceable. **Stock only goes up when goods are received against a purchase order.** It only goes down on a sale dispatch or a production issue. There is no manual stock adjustment screen.

## Data

**items**

| Field | Type | Notes |
|---|---|---|
| id / code | text | `R01`… for raw material, `P01`… for products, unique per company |
| name | text | e.g. "Cotton Yarn 20s", "Lawn Suit 3-Piece" |
| category | enum | `Raw Material` (kacha maal) or `Product` (tayyar maal) |
| unit | text | kg, meter, cone, gross, pcs, suit, set… |
| rate | money | Purchase rate (avg cost). See costing below |
| sale_price | money | Products only |
| reorder_level | number | At or below this, the item is "Low" |
| opening_qty | number | Stock on the go-live date |
| default_supplier_id | fk | Pre-fills the supplier on a new PO |

**stock_moves** (append-only; corrections are new reversing moves)

| Field | Type | Notes |
|---|---|---|
| id | text | `MV-0001` |
| date | date | |
| item_id | fk | |
| type | enum | `In` / `Out` |
| reason | enum | `Purchase receive` (In), `Sale dispatch` (Out), `Production issue` (Out), `Reversal` (either) |
| qty | number > 0 | |
| ref | text | `PO-…` for receipts, `SO-…` for dispatches, `PI-YYMMDD` for production issue slips |
| by | user | |

**Calculated per item** (never stored by hand):

- stock_in = sum of In
- stock_out = sum of Out
- stock = opening_qty + stock_in − stock_out
- value = stock × rate
- last_in = date of the latest In
- status = `Out of stock` if stock ≤ 0, `Low` if stock ≤ reorder_level, else `OK`

## Rules

1. An `In` move can only be created by receiving a purchase order (06). The API rejects any other source.
2. An `Out` move is created by dispatching a sales order (08) or by a production issue slip (raw material only, Store Incharge or Partner).
3. Stock cannot go below zero. Dispatch and issue are refused with "Only 40 set in stock".
4. **Costing (decided): weighted average cost.** On each PO receipt, new rate = (stock before × old rate + received qty × PO rate) ÷ (stock before + received qty). If there was no stock, the PO rate becomes the rate. The rate is stored with paisa (2 decimals). The item also keeps `last_purchase_rate`, `last_purchase_on` and its usual supplier, all set on receipt. The item page shows "Average cost" and "Last bought Rs 12 on 18 Oct (+20%)".
5. Changing an item's rate or reorder level is an edit with old and new values in the log.

## Screens

### Stock page

Info line on top: "Stock goes up only when a purchase order is received. Nobody can add stock by hand, and every change is logged. Click an item to see its history."

Two tabs at the page top: **Stock in hand** and **In / out history**.

**Stock in hand** (list pattern)

- **Tabs:** All · Raw material · Finished goods (with counts)
- **Search:** item name or code
- **Dropdown:** Status: all / OK / Low / Out of stock
- **Totals:** Items · Stock value · Low or out (amber)
- **Columns:** Code, Item, Type, In stock, Unit, Reorder at, Value, Last received, Status pill. Low and out rows get the red left bar. Default sort by code.
- **Row click:** stock item view
- **PDF "Stock report":** Code, Item, Type, In stock, Unit, Reorder at, Avg rate, Value, Status. Total of Value

**In / out history** (list pattern)

- **Tabs:** All · In · Out
- **Search:** item, PO or order number, person
- **Date range:** default This month
- **Dropdowns:** Item, Reason, Done by
- **Totals:** Entries · In entries · Out entries (units are mixed, so no quantity total)
- **Columns:** Date, Item, In/Out pill, Reason, Qty, Unit, Against (ref), Done by. Default sort newest first.
- **Row click:** opens the PO or order in `ref`. Production slips don't open.
- **PDF "Stock in-out register"**

### Stock item view

- **Title:** item name, status pill, "Finished goods · code P04"
- **Facts:** Unit, Reorder at, Avg purchase rate, Last received
- **Money strip:** In stock (qty + unit), Stock value, Received since go-live, Sold or used
- **Section "Stock in / out":** every move, newest first (Date, In/Out, Reason, Qty, Against, Done by). Click opens the PO or order.
- **Actions:**
  - New PO for this item (if role can make POs). Opens the PO form with this item and its default supplier pre-filled.
  - Stock card PDF (always)
  - Change reorder level (Partner or Store Incharge)

### Production issue (Store Incharge, Partner)

Simple form: date, slip no. (auto `PI-YYMMDD`), lines of raw material item + qty. It checks stock is available and creates `Out` moves with reason `Production issue`. Logged as `Issued`.

## Acceptance criteria

- After receiving PO-1042 for 1,500 kg Cotton Yarn 20s, its stock rises by exactly 1,500 and an In move with ref PO-1042 appears.
- There is no API or screen that changes stock without a PO, order or production slip.
- Filtering the register to Item = Towel Set, Out, Last month, then downloading the PDF gives the same rows.
- The stock card PDF's last running balance equals "In stock" on screen.
