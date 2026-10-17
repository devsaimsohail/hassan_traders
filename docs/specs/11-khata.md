# 11 · Khata (customer ledger)

## Purpose

The customer's running account the way Pakistani businesses keep it on paper: what they were billed (naam), what they paid (jama), and what they still owe (baqaya) after each entry. It must match the customer's balance exactly and be easy to send them as a PDF.

## Data

Read-only. Built from other tables, never typed in. Each entry:

| Field | Source |
|---|---|
| entry_id | `<customer>-OB` for the opening balance, otherwise the bill no. or receipt no. |
| date | Go-live date for the opening balance; bill date; payment date |
| type | `B/F` (opening balance), `Naam` (bill), `Jama` (payment) |
| ref | `B/F`, bill no., receipt no. |
| detail | `Opening balance`; `Bill against order SO-3101`; `Cheque · Chq #004512 · HBL · against INV-2041` |
| naam | Bill amount (or opening balance) |
| jama | Payment amount |
| balance | Running total of naam − jama, in date order. Same date: B/F, then Naam, then Jama |

Cancelled bills and reversed payments either drop out or appear with their reversing line. Pick one approach and use it everywhere; showing both lines is recommended for transparency.

## Screen: Khata page (Partner, Accountant: Yes; Sales Officer: View)

One card, top to bottom:

1. **Party header:** name; area, city; mobile; credit limit; payment terms. On the right: total udhaar today (red), past due, last payment, and an "Over credit limit" pill if so.
2. **Toolbar:**
   - Party dropdown (all customers A–Z, "name · city"). Defaults to the customer who owes the most, or the one you came from.
   - Period dropdown (All dates, Today, This week, This month, Last month, Last 3 months, Pick dates…)
   - On the right, Download PDF
3. **Totals strip:**
   - Opening on <start date> (B/F) = the running balance of the last entry before the period
   - Naam · bills
   - Jama · received (green)
   - Closing baqaya (red if above 0) = opening + naam − jama
4. **Table:** Date, Type pill (B/F grey, Naam blue, Jama green), Ref, Detail, Naam, Jama, Baqaya. Empty cells stay blank, not 0. "No entries in this period." when empty.

You arrive here from the menu, from a customer's view ("Open khata"), from a bill ("Customer khata") or from the dashboard's "Who owes the most" chart.

## PDF: Khata statement

Layout in 02. File name `khata-<party>-<period>.pdf`. Logged as `Downloaded PDF`, with the party and period in the detail.

**Nice to have:** "Send on WhatsApp" with the PDF.

## Acceptance criteria

- For "All dates", closing baqaya equals the customer's udhaar on the Customers list.
- For "Last month", opening B/F equals the closing baqaya of a run ending the day before the month started.
- The PDF's rows, totals and closing balance match the screen.
