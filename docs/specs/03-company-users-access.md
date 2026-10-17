# 03 · Company, users and access

## Purpose

Set up the company (name, optional logo, optional brand colour, business details), let two or more partners and their staff log in, and control what each role can see and do.

## Data

**companies**

| Field | Type | Notes |
|---|---|---|
| id | uuid | |
| name | text, required | Shown in the sidebar, on bills and PDFs |
| legal_name | text | e.g. "Al-Madina Textiles (Pvt) Ltd" |
| ntn | text | National Tax Number, printed on bills |
| strn | text | Sales tax registration number |
| address, city | text | |
| phone, mobile, email | text | Mobile is printed on khata statements |
| logo | image, optional | PNG/JPG/SVG/WebP, max 1 MB. Without it, show initials on the brand colour |
| brand_color | hex, optional | Default `#0F766E` |
| currency | text | `PKR` |
| fiscal_year_start | text | e.g. "1 July" |

**users**: id, name, mobile (unique, used to log in), email (optional), city, status (`Active` / `Disabled`), last_login_at, last_device.

**memberships**: user_id, company_id, role (`Partner`, `Accountant`, `Store Incharge`, `Sales Officer`), share_percent (partners only), created_at. A user can be in several companies.

## Permissions

`Yes` = can see and change, `View` = can see only, `No` = menu hidden and API refuses.

| Permission | Partner | Accountant (Munshi) | Store Incharge | Sales Officer |
|---|---|---|---|---|
| Dashboard | Yes | Yes | No | No |
| Stock | Yes | View | Yes | View |
| Make PO | Yes | Yes | View | No |
| Approve PO | Yes | No | No | No |
| Receive goods | Yes | No | Yes | No |
| Sales orders | Yes | View | View | Yes |
| Bills | Yes | Yes | No | View |
| Payments | Yes | Yes | No | No |
| Khata and customers | Yes | Yes | No | View |
| Activity log | Yes | View | No | No |
| Settings | Yes | No | No | No |

Partner-only actions anywhere in the app: approve PO, cancel PO, cancel order, reverse a payment receipt, extend a bill's due date, change a credit limit, add or disable people, change company settings.

Store the matrix as data (a roles table), not code, so it can be adjusted per company later. Check it on the server for every request.

## Screens

### Settings page (Partner only)

- **Company profile card**
  - Logo: preview, upload (PNG/JPG/SVG/WebP, under 1 MB), Remove. Hint: "Without a logo we show your initials."
  - Company name
  - Brand colour: 7 preset swatches (Teal `#0F766E`, Pakistan green `#01411C`, Navy `#1E3A8A`, Maroon `#9F1239`, Orange `#C2410C`, Purple `#6D28D9`, Black `#111827`) plus a custom colour picker. Hint: "Used on buttons, menus, charts and the top strip of every PDF."
  - Changes preview live. Save writes them and logs `Edited · Settings`.
- **Business details card:** registered name, NTN, STRN, address, phone, mobile, financial year start. Editable by partners.
- **Partners and staff table:** name, role, partnership share, mobile, city, usual device, login status (Active / Disabled). The current user's row is highlighted. "+ Add person" button.
- **Who can do what table:** the permission matrix above, as pills.

### Add person

- Name, mobile, role, share % (partners only).
- They get an SMS or WhatsApp link to set up their login.
- **Adding another partner needs the other partner's approval.** It stays pending until then, and both actions are logged.
- Disabling a person blocks login immediately and keeps all their history. Their open work (e.g. sales officer's customers) can be moved to someone else, and the move is logged.

### Login

- Open decision: mobile + OTP, or mobile/email + password. Either way:
  - Lock for 15 minutes after 5 failed attempts.
  - Log every login (`Logged in`, with device and city or IP) and every failed attempt (`Login failed`). Failed attempts show red in the log.
  - A login attempt on a disabled account is logged as `Login failed · account is disabled`.
- After login, a user with several companies picks one. The company switcher stays in the top bar.

### Top bar

- Partner avatars (initials) with "2 partners", so staff know who can see everything.
- The user's name and role, with the company switcher and Log out.
- The prototype has a "Logged in as" dropdown for demoing roles. **Do not ship that.** It is for demo only.

## Acceptance criteria

- A Store Incharge sees only Stock, Purchase orders (view) and Sales orders (view) in the menu. Calling the bills API returns 403.
- A Partner changes the brand colour. Buttons, active menu, chart main series and the PDF top strip all use the new colour after save.
- Removing the logo shows initials everywhere, including PDFs.
- Disabling Kamran Javed stops his next login, and the log shows who disabled him and when.
- Both partners see identical numbers on every screen at the same moment.
