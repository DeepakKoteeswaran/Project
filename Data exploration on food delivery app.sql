
--1	What is the total amount spent by each customer on Zomato?

select a.userid,sum(price) as total_amount from sales a
join product b
on a.product_id= b.product_id
group by a.userid

--2. How many days has each customer visited Zomato?

select userid,count(distinct created_date) distinct_days from sales
group by userid

-- 3. What was the first product purchased by a customer?
select * from
(select rank() over (partition by userid order by created_date) as rnk,a.userid,  a. created_date, b.product_name from sales a join product b on a.product_id= b.product_id) a
where rnk=1

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select count(product_id), userid from sales
where product_id=(select top 1 product_id from sales
group by product_id
order by count(product_id) desc)
group by userid, product_id

--5. Which item was the most popular for each customer? 
select * from
(select *,rank() over(partition by userid order by cpi) rnk 
from (select userid,product_id, count(product_id) as cpi from sales
group by userid, product_id) c) d
where rnk=1


--6. Which item was first purchased by customer after they became a member? 
select * from
(select *, rank() over(partition by userid order by created_date) as rnk from 
(select created_date, gold_signup_date,a.userid, product_id from sales a
join goldusers_signup b on a.userid= b.userid and created_date> gold_signup_date) c) d
where rnk= 1

--7 Which item was purchased just before the customer became the member?
select d.* from
(select a.userid, a. created_date, product_id, rank() over (partition by a.userid order by created_date desc) rnk from sales a
join goldusers_signup b on  a.userid= b.userid and created_date<  gold_signup_date) d
where rnk=1


--8. what is the total number of orders total and amount spent by each customer after they became a member? 


select c.userid, sum(price), sum(cnt) from
(select a.userid,price,count(created_date) cnt from sales a
join goldusers_signup b on  a.userid= b.userid 
join product d on a.product_id= d.product_id and created_date< gold_signup_date
group by a.userid, created_date, price) c
group by c.userid

--9. If buying each product generates points for eg 5rs=2 uber points  and each product has different purchasing points for eg for p1 5rs=1 zomato point, for p2 10rs =5 zomato point , p3 5rs=1 zomato point 

--calucate points collected by each customer and for which product most points have been given till now

-- 1st part
select b.userid,  sum(price/amountPerPoint) Totalpoints from 
(select *, case when product_id =1 or product_id=3 then 5 when product_id = 2 then 2 else 0 end as amountPerPoint from product) a 
join sales b on b.product_id= a. product_id
group by b.userid

--2nd part
select top 1 * from
(select b.product_id,  sum(price/amountPerPoint) Totalpoints from 
(select *, case when product_id =1 or product_id=3 then 5 when product_id = 2 then 2 else 0 end as amountPerPoint from product) a 
join sales b on b.product_id= a. product_id
group by  b.product_id
) v
order by Totalpoints desc

--10 In the first one year after a customer joins the gold membership (including their joining date) irrrespective of what the customer has purchased they get 5 zomato points for every 10 rs. 
-- who earned more user 1 or user 3? 

select b.userid, created_date,gold_signup_date,(price/amountPerPoint)+(price/2)  points from 
(select *, case when product_id =1 or product_id=3 then 5 when product_id = 2 then 2 else 0 end as amountPerPoint from product) a 
join sales b on b.product_id= a. product_id
join goldusers_signup c on  c.userid= b.userid and created_date>= gold_signup_date and created_date< = DATEADD(YEAR,1,gold_signup_date)

-- 11 rank all the trascations of the customers 
select  *,rank() over (partition by userid order by created_date) rnk from sales

--12 rank all the transactions for each member whenever they ordered are a zomato gold member. For every non gold member transaction mark as na 


select userid,created_date, case when rnk=0 then 'na' else rnk end as rnkk  from
(select a.userid, created_date, gold_signup_date, cast((case when gold_signup_date is  null then 0 else rank() over (partition by b.userid order by created_date) end) as varchar) as rnk   from sales a
left join goldusers_signup b on a.userid= b.userid and created_date>= gold_signup_date) d
order by rnkk
