/* Lab | SQL Subqueries*/

/* Instructions
In this lab, you will be using the Sakila database of movie rentals.*/

-- 1. Get number of monthly active customers.
with cte_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
)
select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
from cte_active_customers
group by Activity_year, Activity_Month;

-- 2. Active users in the previous month.
with cte1_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), cte2_active_customers as (
	select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte1_active_customers
	group by Activity_year, Activity_Month
)
select Activity_year, Activity_month, Active_customers, 
   lag(Active_customers) over (order by Activity_year, Activity_Month) as Last_month
from cte2_active_customers;

-- 3. Percentage change in the number of active customers.
with cte1_active_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), cte2_active_customers as (
	select Activity_year, Activity_Month, count(distinct customer_id) as Active_customers
	from cte1_active_customers
	group by Activity_year, Activity_Month
), cte_active_customers_prev as (
	select Activity_year, Activity_month, Active_customers, 
	   lag(Active_customers) over (order by Activity_year, Activity_Month) as Last_month
	from cte2_active_customers)
select *,
	(Active_customers - Last_month) as Difference,
    concat(round((Active_customers - Last_month)/Active_customers*100), "%") as Percent_Difference
from cte_active_customers_prev;

-- 4. Retained customers every month.

-- step 1: get the unique active customers per month
with cte_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
)
select distinct 
	customer_id as Active_id, 
	Activity_year, 
	Activity_month
from cte_customers
order by Active_id, Activity_year, Activity_month;

-- step 2: self join to find recurrent customers (users that made a transfer this month and also last month)
with cte_customers as (
	select customer_id, convert(payment_date, date) as Activity_date,
		date_format(convert(payment_date,date), '%m') as Activity_Month,
		date_format(convert(payment_date,date), '%Y') as Activity_year
	from sakila.payment
), retained_customers as (
	select distinct 
		customer_id as Active_id, 
		Activity_year, 
		Activity_month
	from cte_customers
	order by Active_id, Activity_year, Activity_month
)
select rec1.Active_id, rec1.Activity_year, rec1.Activity_month, rec2.Activity_month as Previous_month
from retained_customers rec1
join retained_customers rec2
on rec1.Activity_year = rec2.Activity_year -- To match the similar years. It is not perfect, is we wanted to make sure that, for example, Dez/1994 would connect with Jan/1995, we would have to do something like: case when rec1.Activity_month = 1 then rec1.Activity_year + 1 else rec1.Activity_year end
and rec1.Activity_month = rec2.Activity_month+1 -- To match current month with previous month. It is not perfect, if you want to connect Dezember with January we would need something like this: case when rec2.Activity_month+1 = 13 then 12 else rec2.Activity_month+1 end;
and rec1.Active_id = rec2.Active_id -- To get recurrent users.
order by rec1.Active_id, rec1.Activity_year, rec1.Activity_month;

-- Extra: 

-- 1. dentify High-Value Customers:
-- Objective: Find customers who have consistently spent above the average amount on rentals.

-- Step 1: Calculate average spent on rentals
select avg(amount) from sakila.payment;

-- Step 2: List all the customers and their average spending, plus total and used the previous querry as subquerry to filter out the ones above the average
select c.customer_id, c.first_name, c.last_name, avg(p.amount) as avg_spending, sum(p.amount) as total_spending
from sakila.customer c
join sakila.payment p 
on c.customer_id = p.customer_id
group by c.customer_id, c.first_name, c.last_name
having avg(p.amount) > (select avg(amount) from sakila.payment)
order by avg_spending desc;
