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

**users**: id, name, mobile (unique, used to log in), email (optional), city, password_digest, must_change_password, failed_login_count, locked_until, last_login_at, last_device, disabled_at, disabled_by.

**roles** (rolify): a user's role is a rolify role scoped to a company, e.g. `user.add_role(:accountant, company)`. Role names are `partner`, `accountant`, `store_incharge` and `sales_officer`. A user has one role per company, and the companies a user can open are the ones they have a role in. There is no memberships table. Partnership shares and partner approval are not built for now.

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
- **People table:** name, role, mobile, city, last login and device, login status (Active / Disabled), Disable or Enable. The current user's row is highlighted. "+ Add person" button.
- **Who can do what table:** the permission matrix above, as pills.

### Add person

- Name, mobile, role, city, temporary password. They must choose their own password at first login.
- If the mobile number already has a login (from another company), that person just gets a role here and keeps their password.
- Disabling a person blocks login immediately (their sessions end) and keeps all their history. A partner cannot disable themselves.
- Later: send the login link by SMS or WhatsApp, and require the other partner's approval to add a partner.

### Login

- Mobile number and password (decided). OTP may come later.
  - Lock for 15 minutes after 5 failed attempts.
  - Log every login (`Logged in`, with device and city or IP) and every failed attempt (`Login failed`). Failed attempts show red in the log.
  - A login attempt on a disabled account is logged as `Login failed`, with "account is disabled" in the detail.
- After login, a user with several companies picks one. The company switcher stays in the top bar.

### Top bar

- Partner avatars (initials) with "2 partners", so staff know who can see everything.
- The user's name and role, with the company switcher and Log out.
- The prototype has a "Logged in as" dropdown for demoing roles. It is not built: users only ever see their own login.

## Acceptance criteria

- A Store Incharge sees only Stock, Purchase orders (view) and Sales orders (view) in the menu. Calling the bills API returns 403.
- A Partner changes the brand colour. Buttons, active menu, chart main series and the PDF top strip all use the new colour after save.
- Removing the logo shows initials everywhere, including PDFs.
- Disabling Kamran Javed stops his next login, and the log shows who disabled him and when.
- Both partners see identical numbers on every screen at the same moment.
