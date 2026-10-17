# 10 · Payments received (Wusooli)

## Purpose

Record every rupee a customer pays, by any method, against a bill or on account, with a receipt that can be sent to the customer.

## Data: payments

| Field | Type | Notes |
|---|---|---|
| rcpt_no | text | `RV-5001` |
| date | date | |
| customer_id | fk | |
| inv_no | text | A bill number, `Opening balance`, or `On account` |
| method | enum | `Cash`, `Bank Transfer`, `Cheque`, `JazzCash`, `Easypaisa` |
| ref | text | Cheque no. and bank (`Chq #004512 · HBL`), bank transfer ref (`IBFT · Meezan · 7731…`), or wallet TID. Required for every method except Cash |
| amount | money > 0 | |
| received_by | user | |
| reversed_by, reversed_at, reverse_reason | | When a partner reverses it |

**Built:** a payment is against a bill, the opening balance, or "on account". It can't exceed what is still due on that bill or opening balance; on account has no cap. Payments are append-only. A Postgres trigger allows only one change, the partner's reversal, which sets `reversed_at/by/reason`. Reversed payments stop counting towards bills and udhaar, and both lines show in the khata. Cheque clearing and auto-applying on-account money are not built.

## Rules

- A payment against a bill cannot exceed that bill's balance. Any extra goes "On account" (ask the owner whether on-account money should auto-apply to the oldest bill).
- **Reversing** (Partner only) never deletes. It marks the receipt reversed and adds a reversing jama entry, e.g. for a bounced cheque. Both stay in the log and the khata.
- **Cheque clearing (optional, ask):** cheques may need a "cleared / bounced" step before they count.

## Screens

### Payments list

- **Tabs:** All · Cash · Bank Transfer · Cheque · JazzCash · Easypaisa (counts)
- **Search:** receipt no., party, cheque no. or TID, bill no.
- **Date range:** default This month
- **Dropdowns:** Party, Received by
- **Totals:** Receipts · Total received (green) · Cash · Bank, cheque, wallet
- **Columns:** Receipt #, Date, Party, Against, Method, Cheque / TID, Amount, Received by. Default sort newest first.
- **Actions:** PDF; "Receive payment" (Accountant, Partner)
- **Row click:** receipt view
- **PDF "Payments received"**, landscape, with total of Amount

### Receive payment form (inline panel)

- Party: after picking, show "Total udhaar: Rs X · N open bills, oldest first"
- Against bill: the party's unpaid bills, oldest first, as "INV-2041 · 3 Sep 2026 · baqaya Rs 1,20,000", plus "On account (no bill)". The oldest is selected by default.
- Amount (Rs): defaults to the chosen bill's balance
- Date (default today)
- Method: chips for Cash, Bank Transfer, Cheque, JazzCash, Easypaisa
- Reference: required unless Cash. The message names what is missing: "Please enter the cheque number" or "Please enter the transaction ID (TID)".
- Save receipt: creates the payment, adds a jama line to the khata, logs `Payment received`, and shows "Saved. Download receipt" in the form.
- Opened from a bill or customer, it arrives with the party (and bill) pre-filled.

### Receipt view

- **Title:** "Receipt RV-5150"; "From <party>"
- **Facts:** Customer, Date, Against, Method, Cheque / TID, Received by
- **Money strip:** Amount received (green), Customer still owes (their current udhaar)
- **Actions:**
  - Download receipt (PDF in 02)
  - Open bill
  - Customer
  - Reverse receipt (Partner, with reason)

## Dashboard links

- "Received this month" = sum of payments from the 1st to today, compared with the same days of last month.
- Monthly chart "Received" series.

## Acceptance criteria

- Saving a Rs 50,000 cheque against INV-2041 lowers that bill's baqaya and the customer's udhaar by Rs 50,000. The khata gets a jama line, and the log shows who saved it.
- Cheque without a number is refused.
- A reversed receipt brings the balance back and both entries show in the khata.
