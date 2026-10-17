# Hassan Traders: business admin app specs

These files describe a multi-company admin app for Pakistani traders and manufacturers: stock, purchasing, sales, bills, payments, customer khata and an activity log that two partners can both trust. Each file is written so Claude (or a developer) can build one module from it.

The clickable prototype these specs come from: https://claude.ai/artifact/Wv39ETvbTyLXDFSeoZ6XUa. It runs on made-up sample data, and its action buttons only show what would happen. Where a spec and the prototype disagree, the spec wins.

## Files

| File | What it covers |
|---|---|
| [00-overview.md](00-overview.md) | Product, users, glossary of business terms, number and date formats, global rules |
| [01-shared-ui.md](01-shared-ui.md) | Light theme, layout, list page, view page, filters, forms, empty and loading states |
| [02-pdf-exports.md](02-pdf-exports.md) | Every PDF: list reports that follow filters, and single-record PDFs |
| [03-company-users-access.md](03-company-users-access.md) | Company profile, logo, brand colour, partners, staff, roles, login |
| [04-activity-log.md](04-activity-log.md) | Append-only "who did what" log |
| [05-items-and-stock.md](05-items-and-stock.md) | Items, stock levels, stock in/out register, stock card |
| [06-suppliers-and-purchase-orders.md](06-suppliers-and-purchase-orders.md) | Suppliers, purchase orders, receiving goods, paying suppliers |
| [07-customers.md](07-customers.md) | Customers (parties), credit limit, balances |
| [08-sales-orders.md](08-sales-orders.md) | Orders, dispatch from godown |
| [09-bills.md](09-bills.md) | Bills (invoices), due dates, overdue |
| [10-payments.md](10-payments.md) | Payments received (wusooli), receipts |
| [11-khata.md](11-khata.md) | Customer ledger with running balance |
| [12-dashboard.md](12-dashboard.md) | Home screen: figures, needs attention, charts |

## Suggested build order

1. 00, 01, 02: read first. Build the shared UI pieces (list page, view page, filter bar, PDF service) before any module.
2. 03 company, users and access, then 04 activity log. Every later module writes to the log and checks permissions.
3. 05 items and stock.
4. 06 suppliers and purchase orders. Receiving a PO is the only way stock goes up.
5. 07 customers, 08 sales orders, 09 bills, 10 payments, in that order.
6. 11 khata, which is read-only and built from bills and payments.
7. 12 dashboard last, since it reads from everything else.

## Stack (decided)

- **Rails 8.1** on Ruby 4.0, **PostgreSQL**. One app, server-rendered, no separate API.
- **Hotwire** (Turbo and Stimulus) with **importmap**. No Node build and no JS bundle.
- **Tailwind CSS** through `tailwindcss-rails` (standalone binary). Map the colour tokens in 01-shared-ui.md to Tailwind theme colours.
- Filters, sorting and tabs are plain GET forms and links, so the URL holds the filter state (01). Use Turbo Frames for the table and Turbo Drive for view pages.
- Background jobs, cache and websockets use the built-in Solid Queue, Solid Cache and Solid Cable. No Redis.
- Planned gems:
  - `pundit` for access checks and `rolify` for company-scoped roles (03)
  - `prawn` and `prawn-table` for PDFs (02)
  - `pagy` for paging very long lists
  - `devise` for login (sessions only: lockable, trackable, timeoutable, rememberable)
  - The activity log is our own insert-only table (04), not a gem.
- Deploy with Kamal to one small VPS (about $5–7 a month).

## Decisions still open

These are not settled. Ask the owner before building the parts they touch.
- **Stock costing.** Weighted average cost on each receipt (recommended) or fixed rate per item. See 05.
- **Partial receiving of a PO** and **partial dispatch of an order.** Not in v1 unless asked.
- **Sales tax (GST) on bills.** Not in v1. Company NTN and STRN are stored and printed already.
- **Partner approval and partnership shares.** Removed from module 03 for now; roles come from rolify only.
- **Purchase order status.** The owner asked to hide PO statuses in the UI for now (only a Draft tab is shown). The approval workflow still exists underneath. See 06.
- **Supplier khata.** Only a customer khata is specified. A matching supplier khata is a likely next request.
- **Urdu script.** Labels are English with familiar Roman Urdu terms. Urdu (Nastaliq) labels may be added later; keep all UI strings in one translation file from day one.
