# 12 · Dashboard (Khulasa)

## Purpose

The first screen a partner or munshi sees. It answers: How is business this month? Who owes us, and how much is late? What do I need to do today? Keep it compact: one figures strip, two cards side by side, one chart, one short activity list.

Visible to Partner and Accountant (03). Other roles land on their first allowed page.

"This month" is the 1st of the month to today (Asia/Karachi). "Last month" in comparisons means **the same days** of last month (1st to the same day number), so a half month is never compared with a full one.

## 1. Figures strip

One card, five cells split by thin dividers. Each cell has a label, a big number (20px semibold) and a small line under it.

| Label | Number | Small line |
|---|---|---|
| Sales this month | Sum of bill amounts dated this month | `+12.3% vs last month` (green if up, red if down) |
| Received this month | Sum of payments dated this month | `-37.3% vs last month` |
| Customers owe you | Sum of customer balances (07) | `Rs X past due` in red |
| You owe suppliers | Sum of "to pay" on received POs (06) | `For goods received` |
| Stock value | Sum of stock × rate over all items (05) | `At purchase rate` |

## 2. Needs attention

A card with up to 4 rows. Each row has a coloured dot, a plain sentence with the count, an amount under it where it applies, and a **View** button. View opens the list already filtered.

| Dot | Text | Amount | View opens |
|---|---|---|---|
| Red | "18 bills are past their due date" | Sum of their baqaya | Bills, Overdue tab |
| Blue | "2 orders are not dispatched yet" | Sum of order amounts | Sales orders, Pending tab |
| Amber | "1 item is running low on stock" | none | Stock, Status: Low |

- Use singular wording for 1 ("1 bill is past its due date").
- When a count is 0, show a green dot and a muted "No bill is past due" with no button.
- Hide View when the role can't open that page.
- The prototype also had "N purchase orders are waiting for a partner's approval". It was removed when the owner hid PO statuses. Bring it back if PO statuses return.

## 3. Who owes the most

Horizontal bars, top 8 customers by balance, name on the left, `Rs 24.8 lakh` at the end of each bar. The past-due part of each bar is red at the left; the rest is brand colour. Note "Red = past due". The tooltip shows udhaar, past due and credit limit. Clicking a bar opens that customer's khata.

## 4. Month by month

Grouped bars for the last 6 months: Sales (brand colour), Received (lighter brand) and Purchases (light grey-blue). The legend sits in the card header. The y-axis is in lakh. The current month's label says "Oct (1–18)" with the note "October shows 1–18 Oct only." Hovering a month shows all three values in rupees.

- Sales = bill amounts by bill date.
- Received = payments by payment date.
- Purchases = PO totals by PO date, excluding draft and cancelled.

## 5. Latest activity

The 5 newest activity log entries: When, Who, What. Failed logins and deletions have the red left bar. "See full log" link (only for roles that can see the log).

## Acceptance criteria

- Every number on the dashboard equals the same number reached from its list. For example, "Customers owe you" equals the Total udhaar on the Customers list with no filters.
- Every View button lands on a list whose tab and filters show exactly the counted rows.
- On a 400px-wide screen the figures stack and nothing scrolls sideways.
