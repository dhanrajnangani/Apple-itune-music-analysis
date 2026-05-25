use apple_itunes_music_analysis;
select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;

-- SECTION 1 : EMPLOYEES & BASIC ANALYTICS

-- Q1. Who is the senior most employee based on job title?
SELECT employee_id,
first_name,
title,
levels
from employee
order by levels ASC
LIMIT 1 ;

-- Q2. Which countries have the most invoices?

SELECT billing_country as country,
count(*) as invoice_count
from invoice
group by billing_country
order by invoice_count DESC;

-- Q3. What are the top 3 values of total invoice?

SELECT round(total, 2) as total_invoice
from invoice
order by total desc
limit 3;

-- SECTION 2: CUSTOMER ANALYTICS

-- Q4. Which city has the best customers?
--     (city where we made the most money — for a Music Festival)

SELECT billing_city as city,
round(sum(total), 2) as total_revenue
from invoice
group by billing_city
order by total_revenue desc
limit 1 ;

-- Q5. Who is the best customer?
-- (customer who has spent the most money overall)

SELECT c.customer_id,
concat(c.first_name, ' ' , C.last_name) AS customer_name,
c.country,
ROUND(sum(i.total), 2) AS total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id
order by total_spent DESC
limit 1;


-- Q6. Return email, first name, last name & genre of all Rock Music listeners.

SELECT distinct c.email, c.last_name, g.name as genre
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where g.name = 'Rock'
order by c.email ASC;


-- SECTION 3: MUSIC CONTENT ANALYSIS


-- Q7. Top 10 rock bands — artists who have written the most Rock music.

SELECT ar.name as artist_name, count(t.track_id) as total_tracks
from artist ar
join album al on ar.artist_id = al.artist_id
join track t on al.album_id = t.album_id
join genre g on t.genre_id = g.genre_id
where g.name = 'Rock'
group by ar.artist_id
order by total_tracks DESC
limit 10;


-- Q8. All tracks with a song length longer than the average song length.
-- Returns Name and Milliseconds, ordered longest first.

SELECT name, milliseconds
from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds DESC;

-- Q9. How much has each customer spent on the best-selling artist?
--     Uses a CTE to first find the top artist, then joins to customers.

with best_selling_artist as (select ar.artist_id, ar.name as artist_name, round(sum(il.unit_price * il.quantity), 2) as total_sales
from artist ar 
join album al on ar.artist_id = al.artist_id
join track t on al.album_id = t.album_id
join invoice_line il on t.track_id = il.track_id
group by ar.artist_id
order by total_sales DESC
limit 1
)
SELECT concat(c.first_name, ' ' , c.last_name) as customer_name, bsa.artist_name, round(sum(il.unit_price * il.quantity), 2) as total_spent
from customer c 
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album al on t.album_id = al.album_id
join best_selling_artist bsa on al.artist_id = bsa.artist_id
group by c.customer_id, bsa.artist_name
order by total_spent DESC;


-- SECTION 4: ADVANCED ANALYTICS (Window Functions & CTEs)

-- Q10. Most popular music genre per country.
-- Uses RANK() to handle ties — all tied genres are returned.

with country_genre_sales as ( select i.billing_country as country, g.name as genre, count(il.invoice_line_id) as purchases, rank() over (partition by i.billing_country order by count(il.invoice_line_id)DESC) as rnk
from invoice i 
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
group by i.billing_country, g.genre_id )

select  country, genre, purchases
from country_genre_sales
where rnk = 1
order by country;


-- Q11. Top spending customer per country.
-- Uses RANK() to include ties — all top spenders returned per country.

with customer_spending as (
 select c.customer_id,
 concat(c.first_name, ' ', c.last_name) as customer_name,
 c.country, round(sum(i.total), 2) as total_spent,
 rank() over ( partition by c.country order by sum(i.total)DESC ) as rnk

from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id )
select country, customer_name, total_spent 
from customer_spending
where rnk = 1
order by country;



-- SECTION 5: POPULARITY & GEOGRAPHIC TRENDS


-- Q12. Most popular artists by tracks sold and revenue generated.

select ar.name as artist_name,
 count(il.invoice_line_id) as track_sold,
 round(sum(il.unit_price * il.quantity), 2) as total_revenue
 from artist ar
 join album al on ar.artist_id = al.artist_id
 join track t on al.album_id = t.album_id
 join invoice_line il on t.track_id = il.track_id
 group by ar.artist_id
 order by track_sold DESC limit 10;
 
 
 -- Q13. Most popular song (track purchased most often).


select t.name as track_name,
ar.name as artist_name, 
count(il.invoice_line_id) as times_purchased
from track t
join invoice_line il on t.track_id = il.track_id
join album al on t.album_id = al.album_id
join artist ar on al.artist_id = ar.artist_id
group by t.track_id
order by times_purchased desc
limit 5 ;


-- Q14. Average price of different types of music, broken down by genre.
-- Includes min/max price to spot outliers.

select g.name as genre, 
count(t.track_id)  as total_tracks,
round(avg(t.unit_price), 2) as avg_price,
round(min(t.unit_price), 2) as min_price,
round(max(t.unit_price), 2) as max_price
from genre g 
join track t on g.genre_id = t.genre_id
group by g.genre_id
order by avg_price desc, total_tracks DESC;


-- Q15. Most popular countries for music purchases.
-- Returns customer count, tracks purchased, and total revenue per country.


select i.billing_country as country,
count(distinct i.customer_id) as customers,
count(il.invoice_line_id) as tracks_purchased,
round(sum(il.unit_price * il.quantity), 2) as total_revenue
from invoice i
join invoice_line il on i.invoice_id = il.invoice_id
group by i.billing_country
order by total_revenue DESC;