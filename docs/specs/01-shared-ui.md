# 01 · Shared UI

Build these pieces once and reuse them in every module. The goal is clean, compact and easy to understand for a business owner who is not a computer person.

## Theme (light only)

| Token | Value | Use |
|---|---|---|
| bg | `#F6F7F9` | Page background |
| card | `#FFFFFF` | Cards, sidebar, inputs |
| line | `#E7E9EE` | Card borders, table header line |
| line-soft | `#F1F3F6` | Row dividers |
| text | `#101828` | Main text |
| muted | `#667085` | Labels, notes |
| faint | `#98A2B3` | Placeholders, icons |
| input border | `#D0D5DD` | Inputs and secondary buttons |
| green | `#067647` on `#ECFDF3` | Paid, received, OK |
| red | `#D92D20` on `#FEF3F2` | Overdue, past due, failed |
| amber | `#B54708` on `#FFFAEB` | Partial, low, pending |
| blue | `#175CD3` on `#EFF8FF` | Info, dispatched, created |
| brand | Company brand colour, default `#0F766E` | Primary buttons, active menu, chart main series, PDF top strip |

- Brand text colour is picked automatically: white on dark brand colours, near-black on light ones (relative luminance above 0.4).
- Font: one clean sans-serif. Base 14px. Numbers use tabular figures.
- Radius 10px on cards, 8px on inputs and buttons. Shadow at most `0 1px 2px rgba(16,24,40,.05)`.
- Status pills: small, rounded, soft background with a coloured dot. No heavy borders.

## Layout

- **Left sidebar** (about 14rem, white): company logo (or initials on the brand colour) and name, then menu groups.
  - Overview: Dashboard
  - Inventory: Stock, Purchase orders
  - Sales and money: Sales orders, Bills, Payments, Customers, Khata
  - Admin: Activity log, Settings
- Each menu item is one line: a 18px outline icon and a label. The active item gets a brand-tinted background and brand-coloured text.
- Menu items the user's role cannot see are hidden.
- **Top bar** on each page: page title (20px, semibold), one line of plain explanation under it, and on the right the partner avatars ("2 partners") plus a "Logged in as" switcher (company switcher in the real app).
- If the role can only view the page, show a small grey "View only" badge next to the title and hide every create/edit button.
- Below 860px wide, the sidebar becomes a horizontal scrolling menu at the top. Below 520px, filters stack full width.

## List page pattern

Every list (stock, register, POs, orders, bills, payments, customers, activity) is **one card** with these rows, top to bottom:

1. **Tabs** for the most important split, each with a count badge, e.g. `All 145 · Unpaid 12 · Partial 20 · Overdue 18 · Paid 95`. Counts respect all the other filters.
2. **Filter toolbar**, one row that wraps:
   - Search box (searches the fields listed per module)
   - Date range dropdown: All dates, Today, This week, This month, Last month, Last 3 months, Pick dates… (Pick dates shows From and To date inputs)
   - One dropdown per extra filter (party, city, supplier, person…). Options are filled from the data. The first option is "All …"
   - Any second group of choices also becomes a dropdown, e.g. "Status: all"
   - "Clear filters" link, shown only when something is filtered
   - On the right: **PDF** button (always), then the primary action button if the role allows (e.g. "New PO", "Receive payment")
3. **Totals strip**, one compact line of label/value pairs for the rows currently shown, e.g. `Bills 42 · Bill amount Rs 50,00,000 · Received Rs 32,00,000 · Baqaya Rs 18,00,000`. Bad numbers in red, good in green.
4. **Table**
   - Sticky header. Every header sorts on click (first click is descending for numbers and dates, ascending for text). Shows ↑ or ↓.
   - Rows show values only, formatted per 00-overview.
   - Numbers are right-aligned.
   - Rows that need attention get a thin red bar on the left edge (overdue, over credit limit, failed login, deleted).
   - Secondary columns hide below 860px.
   - Each row that opens a record ends with a `›` chevron, and the whole row is clickable and keyboard-focusable (Enter opens).
   - The table scrolls inside the card (max height about 40rem). Do not paginate under about 2,000 rows; above that, paginate on the server and keep totals over the full filtered set.
   - Empty result: "Nothing matches these filters." in the card body.

Filter state lives in the URL query string so a filtered list can be bookmarked and shared between partners, and survives refresh.

## View page pattern (one record)

Opening a row replaces the list with the record's view page. The browser back button and a "← Back to …" link return to the list with filters intact.

1. **Header card**
   - Title (record number or name, 20px) with a status pill if the record has one, and one line under it (e.g. "Order from Khan Brothers, Peshawar")
   - Action buttons on the right, primary first, small size. Only the actions the role allows and the record's state permits are shown.
   - **Facts grid:** label above value, 4–6 facts (party, dates, made by, approved by…)
   - **Money strip:** 1–4 boxed figures (total, paid, to pay…), coloured red or green where it means something
2. **Related sections**, each a card with a title and a compact table (items, payments, stock movements…). Rows in related tables also open their own record.
3. After an action, show a short confirmation line under the header ("Payment saved. Rs 1,00,000 added to Khan Brothers' khata.").

Cross-links: a bill links to its order, payments and customer; an order to its bill and customer; a PO to the items it moved; a stock item to every PO and order that moved it; an activity log entry to the record it mentions.

## Forms

- Forms open as an inline panel at the top of the list (not a modal), with a title, who is making it ("Made by Bilal Ahmed"), and Close.
- Label above each input. Required fields are marked. Validate on submit with one clear message in plain words, e.g. "Please choose a supplier and at least one item with quantity."
- Money inputs take whole rupees. Totals update live as lines change.
- Line items: Item, Qty, Rate (pre-filled from the item, editable), Amount (calculated), and a × to remove. "+ Add another item" underneath.
- Choosing a party pre-fills what it can (e.g. their oldest unpaid bill and its balance).

## States

- Loading: grey skeleton bars where data will appear. No spinners or "Loading…" text.
- Failed: one centred line with a small red dot, "Failed to load", and a Retry link.
- While a filter change reloads: dim the old content to 50% opacity and keep it readable.

## Accessibility

- All controls are reachable by keyboard with a visible focus ring in the brand colour.
- Tabs use `role=tab` and `aria-selected`; sortable headers use `aria-sort`.
- Colour is never the only signal: pills carry words, overdue rows also say "Overdue".
