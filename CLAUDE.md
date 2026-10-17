# Hassan Traders

Admin app for Pakistani traders and manufacturers: stock, purchase orders, sales orders, bills, payments, customer khata and an activity log shared by two partners.

## Read first

- `docs/specs/README.md`: build order, stack and open decisions. Ask before building anything an open decision touches.
- `docs/specs/00-overview.md`: glossary (udhaar, khata, naam/jama, wusooli…), number and date formats, global rules.
- Before building a module, read its spec and `01-shared-ui.md`. If the module has PDFs, also read `02-pdf-exports.md`.

## Stack

Rails 8.1, Ruby 4.0, PostgreSQL, Hotwire with importmap (no Node), Tailwind via tailwindcss-rails, Solid Queue/Cache/Cable, Kamal.

## Rules that apply everywhere

- Every business table has `company_id`. Scope every query to the current company.
- Check permissions on the server with Pundit, using the role matrix in spec 03.
- Every create, edit, approve, cancel, reverse, receive, dispatch, login and PDF download writes to the activity log (spec 04) in the same transaction.
- Never hard-delete bills, payments, POs, orders or stock moves. Cancel or reverse instead.
- Stock changes only through stock moves created by receiving a PO, dispatching an order or a production issue.
- Store money as integer rupees. Display it as `Rs 12,50,000` with lakh grouping.

## Commands

- `bin/dev`: run the app with the Tailwind watcher
- `bin/rails test`: tests
- `bin/rubocop`: lint
