# 02 · PDF exports

Every list has a **PDF** button, and most view pages have a record PDF. Business owners send these on WhatsApp and print them, so they must look clean and be exactly what the user is looking at.

## Rules for list PDFs

1. **Same rows as the screen.** Apply the current search, date range, dropdowns and tab, in the current sort order. Never "all records" unless no filter is set.
2. **Say what was filtered.** Under the header, print `Filters: Date: 1 Oct 2026 to 18 Oct 2026 | Party: Khan Brothers | Status: Overdue | Search: "lawn"`, or `Filters: none, all records`. Then `42 records, sorted as on screen`.
3. **Same totals as the screen.** Print the totals strip as boxes, then a bold Total row under the table for the money columns listed per module.
4. Landscape for wide lists (POs, orders, bills, payments, customers, activity). Portrait for stock, khata and single records.
5. Rows that need attention (overdue bills, over-limit customers, failed logins) print their text in dark red.
6. Long cell text is cut with `..` to fit the column. It never wraps onto other rows.

## Page layout (A4)

- A 6pt strip across the very top in the company brand colour.
- Left: company name (bold, 15pt) and under it one grey line: address, city, phone, NTN.
- Right: the document title in brand colour (e.g. "Bills report", "Bill INV-2041"), and under it `Generated 18 Oct 2026, 11:42 am by Haji Muhammad Aslam`.
- Company logo, if uploaded, at the far left before the name (max 40pt high).
- Body as above: filter lines, summary boxes, table with a light grey header row and faint zebra rows, totals row.
- Footer on every page: a short line on the left (e.g. "Al-Madina Textiles - Bills report - prepared from the app with the filters shown on page 1") and `Page 2 of 5` on the right.
- Currency in PDFs is written `Rs 12,50,000`, since the ₨ sign is not in standard PDF fonts. If Urdu text is ever printed, embed a Nastaliq font.

## Record PDFs

| PDF | From | Content |
|---|---|---|
| Bill | Bill view | Bill to, bill date, due date, order no., status. Summary: bill amount, received, balance due. Lines: item, qty, unit, rate, amount, total. Under the table, one line per payment received ("Received Rs X on date by method (ref), receipt RV-…") and "Balance due: Rs X" or "Fully paid. Shukriya!". Footer "computer generated bill, no signature needed" |
| Purchase order | PO view | Supplier, PO date, made by, approved by. Summary: PO total, paid, to pay. Lines with rates. Footer note "Please deliver to our godown and write this PO number on your bill", or the received date |
| Sales order | Order view | Customer, date, booked by, status, bill no. Lines at sale rate, total |
| Payment receipt | Payment view | Received from, date, method, cheque no. or TID, received by, amount, "Thank you. Shukriya!" |
| Stock card | Stock item view | Item, unit, reorder level. Summary: opening, received, sold or used, in stock now. Every in/out entry oldest first with a running balance column |
| Khata statement | Khata page, customer view | Party name, area, city, mobile, period, credit limit, terms. Summary: opening (B/F), naam (bills), jama (received), closing baqaya. Entries with running balance, totals row, "Closing balance payable by <party>: Rs X". Footer asks the party to confirm and gives the company mobile |

## File names

`<report-or-record>-<filter-or-party-slug>.pdf`, lowercase with hyphens, at most about 110 characters. For example `bills-report-date-1-oct-2026-to-18-oct-2026-status-overdue.pdf` or `khata-khan-brothers-this-month.pdf`.

## Implementation notes

- Generate on the server from the same query the list uses (pass the filter state), so a PDF of 5,000 rows does not depend on the browser.
- Every download writes an activity log entry: action `Downloaded PDF`, with the report name and filters in the detail.
- Acceptance check: for each list, set two filters and a sort, download, and confirm the PDF has the same row count, order and totals as the screen.
