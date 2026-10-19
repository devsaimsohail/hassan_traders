# 07 · Customers (Parties)

## Purpose

Keep every wholesale customer with their credit terms, and show at a glance how much each one owes, how much is past due, and who is over their credit limit.

## Data: customers

| Field | Type | Notes |
|---|---|---|
| id | text | `C01` |
| name | text | e.g. "Khan Brothers" |
| city, area | text | e.g. Peshawar, Qissa Khwani |
| phone | text | Mobile, `03xx-xxxxxxx` |
| credit_limit | money | |
| terms_days | number | Days to pay. Sets each bill's due date (15, 30, 45…) |
| opening_balance | money | Udhaar at go-live, the B/F line in khata |
| note | text | e.g. "Credit hold: no new orders until Rs 5 lakh received" |

**Calculated per customer:**

- billed = sum of their bill amounts
- received = sum of their payments (including payments against the opening balance)
- balance (udhaar) = opening_balance + billed − received
- overdue (past due) = sum of balances of their bills whose status is Overdue
- last_payment = date of their latest payment
- over_limit = balance > credit_limit

**Built so far:** billed, received, overdue and last payment are 0 or empty until bills (09) and payments (10) exist. `Customer::WITH_BALANCES` computes every balance in SQL, and those modules plug their sums into it.

## Rules

**Owner's current instruction:** hide credit limit and payment terms in the UI for now. Only the customer name is required on the add / edit form. The columns stay in the data: new customers get no credit limit and 30-day terms, and bills still take their due date from `terms_days`. While hidden, there is no "Over credit limit" tab, pill, column or total, and booking an order shows no credit warning. The rest of this spec describes the full design for when they come back.

- Changing the credit limit is Partner-only and logs old → new.
- **Optional (ask the owner):** warn, or block, a new sales order when the customer is over their limit or has a credit-hold note.
- Customers are never deleted. They can be marked inactive.

## Screens

### Customers list

- **Tabs:** All · Has udhaar · Overdue · Over credit limit (counts)
- **Search:** name, city, mobile, area
- **Dropdown:** City
- **Totals:** Parties · Total udhaar · Past due (red) · Over limit (amber)
- **Columns:** Party, City, Mobile, Credit limit, Udhaar, Past due, Last payment, Over limit pill. Default sort udhaar, highest first. Over-limit rows get the red left bar.
- **Row click:** customer view
- **PDF "Customer balances"**, landscape: Party, City, Mobile, Credit limit, Bills, Received, Udhaar, Past due, Last payment. Totals of the money columns

### Customer view

- **Title:** name, "Over credit limit" pill if so; "area, city"
- **Facts:** Mobile, City, Credit limit, Payment terms (days), Last payment
- **Money strip:** Total bills, Received (green), Owes you (red if above 0), Past due (red if above 0)
- **Sections** (rows open their own record):
  - Unpaid bills, oldest due date first: Bill #, Date, Due, Baqaya, Status
  - Latest payments (8): Receipt #, Date, Method, Amount
  - Latest orders (8): Order #, Date, Amount, Status
- **Actions:**
  - Open khata (primary)
  - Receive payment: goes to Payments with the form open and this customer pre-selected
  - Khata PDF
  - Change credit limit (Partner)
  - Edit details (Partner, Accountant)
- **Nice to have:** a WhatsApp button that opens WhatsApp with the khata PDF or a balance message, e.g. "Assalam o Alaikum, aap ka baqaya Rs 10,97,500 hai…". Confirm with the owner.

### Add / edit customer

Name, city, area, mobile, credit limit, payment terms (days), opening balance (only at creation), note.

## Dashboard links

- "Customers owe you" = sum of balances. Its "past due" line = sum of overdue.
- "Who owes the most" chart = top 8 by balance, with the overdue part in red. Click opens that customer's khata.

## Acceptance criteria

- A customer's balance equals the closing balance of their khata for "All dates".
- Over credit limit tab count = number of customers with balance > limit.
- PDF with City = Lahore and the Overdue tab lists only Lahore customers with past-due bills.
