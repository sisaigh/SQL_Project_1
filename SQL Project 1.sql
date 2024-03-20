
-- 1) DML/DDL: The dvdrental db already has a pre-populated data in it, but let's assume that the business 
-- is still running in which case we need to not only analyze existing data but also maintain 
-- the database mainly by INSERTing data for new rentals and UPDATEing the db for existing rentals
--i.e implementing DML (Data Manipulation Language). To this effect,

		--Write ALL the queries we need to rent out a given movie. (Hint: these are the business logics 
		-- that go into this task: 
		-- 1.1) First confirm that the given movie is in stock, 

					SELECT *
					FROM inventory
					WHERE inventory_id NOT IN 
						(SELECT inventory_id 
						FROM  rental)

		--1.2) then INSERT a row into the rental and the payment tables. 
		
				
				--1.2.1) INSERTing row to rental tabe
				
				-- First check the highest differne between rental date Vs return date to obtian potentially struggling customers
				--then identify the number total number of actual rental dates for each movie and compare it with the rental 
				-- duration settled for each movie to identify customer with outstanding balance 
		 
		 		SELECT rental.customer_id, sum(film.rental_duration), sum(rental.return_date - rental.rental_date) as difference
 					FROM rental
 					LEFT JOIN inventory USING (inventory_id)
 					INNER JOIN film USING (film_id)
 				WHERE (film.rental_duration >= (date_part('day', rental.return_date - rental.rental_date)))
 				AND rental.return_date IS NOT NULL
 				GROUP BY 1
 				ORDER BY 2 DESC;
				
				
			
		-- Then inset the row into rental talbe 
		
	
				INSERT INTO rental(rental_id,rental_date,inventory_id,customer_id, 
								   return_date, staff_id, last_update)
				VALUES ('16050',CURRENT_TIMESTAMP,'5','197',
						CURRENT_TIMESTAMP + Interval '1 day' * (SELECT rental_duration FROM film WHERE film_id = 1 ),
						'2',CURRENT_TIMESTAMP);
		
	-- After adding rental id and customer id
		
		SELECT * FROM rental  
			ORDER BY rental_id DESC
				      
						
				--1.2.2) INSERTing row to payment tabe
							
												
				INSERT INTO payment (payment_id,customer_id, staff_id,rental_id, 
									 amount,payment_date)
				VALUES ('32099', 197,'2','16050',5.94,CURRENT_TIMESTAMP)
				
		-- to obtain rental rate and duration to get the amount (rate*durtion)	
		
		SELECT film.rental_rate, film.rental_duration
			FROM film
				LEFT JOIN inventory USING(film_id)
			WHERE inventory.inventory_id = 5;

		
		--after adding payment id 	
			SELECT *  FROM payment 
			ORDER BY Payment_id DESC
						
		--1.3) You may also need to check whether the customer has an outstanding balance or an overdue rental 
		--before allowing him/her to rent a new DVD).
		

			
				--1.3.1) Outstanding balance ***
				
				SELECT customer_id, first_name || ' ' || last_name AS customer_name,
    					SUM(amount) AS total_payments,
    					SUM(CASE WHEN return_date IS NULL THEN rental_duration * rental_rate END) AS total_rental_charges,
    					SUM(CASE WHEN return_date IS NULL THEN 1 ELSE 0 END) AS outstanding_rentals
				FROM film 
					LEFT JOIN inventory USING(film_id)
					LEFT JOIN rental USING(inventory_id)
					LEFT JOIN customer USING (customer_id)    							
					LEFT JOIN payment USING(customer_id)
				GROUP BY customer_id, customer_name
				HAVING SUM(amount) < SUM(CASE WHEN return_date IS NULL THEN rental_duration * rental_rate END);

					
				--1.3.2) Overdue rental check 
				
				SELECT  customer_id, first_name || ' ' || last_name AS customer_name,
    				    rental_id, rental_date, return_date, now() AS current_time,
    					CASE
       					WHEN return_date IS NULL AND now() > rental_date + INTERVAL '1 day' * rental_duration THEN 'Overdue'
        				ELSE 'Not Overdue'
    					END AS rental_status
					
					FROM customer
						INNER JOIN rental USING (customer_id)
							INNER JOIN Inventory USING (inventory_id)
								INNER JOIN film USING (film_id)
						WHERE return_date IS NULL AND now() > rental_date + INTERVAL '1 day' * rental_duration AND rental_id=16050
						ORDER BY customer_id, rental_date;
				
			--1.3.3) Check rental status 
		
			SELECT  customer_id, first_name || ' ' || last_name AS customer_name,
    				    rental_id, rental_date, return_date, now() AS current_time,
						CASE
       					WHEN return_date IS NULL AND now() > rental_date + INTERVAL '1 day' * rental_duration THEN 'Overdue'
        				ELSE 'Not Overdue'
    					END AS rental_status
					
					FROM customer
						INNER JOIN rental USING (customer_id)
							INNER JOIN Inventory USING (inventory_id)
								INNER JOIN film USING (film_id)
						WHERE rental_id=16050
						ORDER BY customer_id, rental_date;		
				
				
		--1.4) write ALL the queries we need to process return of a rented movie. **** (Hint: 
		--update the rental table and add the return date by first identifying 
		--the rental_id to update based on the inventory_id of the movie being returned.)
			
				UPDATE rental
				SET return_date = CURRENT_TIMESTAMP + Interval '1 day' * (SELECT rental_duration FROM film WHERE film_id = 1 )
				WHERE rental_id = '16050';

								
				-- Check row in the rental table with rental and retun date
	
				SELECT* FROM rental
				WHERE rental_id = 16050
	

-- 2) DQL: Now that we have an up-to-date database, let's write some queries and analyze the data 
-- to understand how our DVD rental business is performing so far

		-- 2.1) Which movie genres are the most and least popular? And how much revenue have they each 
		-- generated for the business? - USE densrank
		
			-- 2.1.1) MOST popular: 
		
				SELECT name ,COUNT(film_id)AS rental_frequency,SUM(payment.amount) AS total_amount 
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
					INNER JOIN payment USING (rental_id)
				GROUP BY name
				ORDER BY rental_frequency DESC
				LIMIT 1;
				
			-- 2.1.2) LEAST popular: 	
				
				SELECT name,COUNT(film_id)AS rental_frequency,SUM(payment.amount) AS total_amount 
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
					INNER JOIN payment USING (rental_id)
				GROUP BY name
				ORDER BY rental_frequency ASC
				LIMIT 1;

		--2.2) What are the top 10 most popular movies? And how many times have they each been rented out thus far?
			
			SELECT title,COUNT(film_id)AS rental_frequency 
				FROM film
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
				GROUP BY title
				ORDER BY rental_frequency DESC
				LIMIT 10;

				

		--3.1) Which genres have the highest and the lowest average rental rate?
		
				-- 3.1.1) HIGHEST rental rate: 
		
				SELECT name ,AVG (rental_rate )AS rental_rate 
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)								
				GROUP BY name
				ORDER BY rental_rate DESC
				LIMIT 1;
				
				-- 3.1.2) LOWEST rental rate:
		
				SELECT name ,AVG (rental_rate )AS rental_rate 
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)					
				GROUP BY name
				ORDER BY rental_rate ASC
				LIMIT 1;
			

		--2.4) How many rented movies were returned late? Is this somehow correlated with the genre of a movie?
				
				--2.4.2) Count of late movies,
				
				SELECT COUNT(*) AS overdue_count
						FROM customer
    					INNER JOIN rental USING (customer_id)
    					INNER JOIN inventory USING (inventory_id)
    					INNER JOIN film USING (film_id)
						WHERE return_date IS NOT NULL AND
    					EXTRACT(days FROM (return_date - rental_date)) > rental_duration 
					
				
				--2.4.2) Correlation of late movies, Yes- somehow renters are keeping sports movies
				-- for longer days
				
					SELECT name,COUNT(*) AS overdue_count
						FROM rental 
    					INNER JOIN inventory USING (inventory_id)
    					INNER JOIN film USING (film_id)
						INNER JOIN film_category USING (film_id)
						INNER JOIN category USING(category_id)
							WHERE return_date IS NOT NULL AND
    					EXTRACT(days FROM (return_date - rental_date)) > rental_duration 
					GROUP BY name 
					ORDER BY overdue_count DESC;
				
				--2.4.3) List of late movies,
				
					SELECT customer_id, first_name || ' ' || last_name AS customer_name,
    				    rental_id,title,
						MAX(rental_date) AS rental_date, 
						MAX(return_date) AS return_date,
						MAX(rental_duration) AS rental_duration,
    					CASE
       					WHEN EXTRACT(days FROM (MAX(return_date) - MAX(rental_date))) > MAX(rental_duration) THEN 'Overdue'
						ELSE 'Not Overdue'
    					END AS rental_status
					FROM customer
						INNER JOIN rental USING (customer_id)
						INNER JOIN Inventory USING (inventory_id)
						INNER JOIN film USING (film_id)
					GROUP BY rental_id,title,customer_name,customer_id
					ORDER BY customer_id, MAX(rental_date);
						
							
			

		--2.5) What are the top 5 cities that rent the most movies? 
			
			SELECT city, COUNT (rental_id )AS rented_movies
				FROM city
					INNER JOIN address USING (city_id) 
					INNER JOIN customer USING (address_id)
					INNER JOIN rental USING (customer_id)
				GROUP BY city
				ORDER BY rented_movies DESC
				LIMIT 5;
				
				-- 2.5.1) How about in terms of total sales volume?
				
				SELECT city, COUNT (rental_id )AS rented_movies, sum(payment.amount)AS total_sales
				FROM city
					INNER JOIN address USING (city_id) 
					INNER JOIN customer USING (address_id)
					INNER JOIN rental USING (customer_id)
					INNER JOIN payment USING (rental_id)
				GROUP BY city
				ORDER BY 3 DESC
				LIMIT 5;
			
				

 		--2.6) 	let's say you want to give discounts as a reward to your loyal customers and those who return movies 
 				--they rented on time. So, who are your 10 best customers in this respect?
 
 				 SELECT customer_id,
    					CONCAT(first_name, ' ', last_name) AS customer_name,
    					COUNT(rental_id) AS total_rentals,
    					SUM(CASE WHEN return_date <= rental_date + INTERVAL '1 day' * rental_duration 
							THEN 1 ELSE 0 END) AS on_time_returns
					FROM customer 
    				INNER JOIN rental USING(customer_id)
    				INNER JOIN inventory USING(inventory_id)
    				INNER JOIN film USING(film_id)
				GROUP BY customer_id, customer_name
				HAVING COUNT(rental_id) > 0  -- this insures a customers have made at least one rental
				ORDER BY on_time_returns DESC
				LIMIT 10;
				
				
		
						
 
		--2.7) What are the 10 best rated movies? Is customer rating somehow correlated with revenue? 
		
			--2.7.1) 10 best rated movies 
			
			SELECT title, COUNT (rental_id)AS rental_frequency, rating
				FROM film
					LEFT JOIN inventory USING (film_id)
						LEFT JOIN rental USING (inventory_id)
				GROUP BY title,rating
				ORDER BY rental_frequency DESC
				LIMIT 10;
				
				
			--2.7.2) Correlation with revenue - No it is not correlated 
		
				SELECT title,rating,
    				COUNT(rental_id) AS rental_frequency,
    				SUM(payment.amount) AS total_revenue
				FROM film 
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
					INNER JOIN payment USING (rental_id)
				GROUP BY title, rating
				ORDER BY total_revenue DESC
				LIMIT 10;

		
		
			--2.7.3) Which actors have acted in most number of the most popular or highest rated movies?
				
				
				select count(film.film_id) as No_of_movies, count(rental.rental_id) as popular, sum(amount) as total_revenue, CONCAT(first_name, ' ', last_name)as full_name
					from payment
inner join rental using (rental_id)
inner join inventory using (inventory_id)
inner join film using (film_id)
inner join film_actor using (film_id)
inner join actor using (actor_id)
group by 4
order by 1 desc
limit 10;

			

 		--2.8)	Rentals and hence revenues  been falling behind among young families. 
 				--In order to reverse this, you wish to target all family movies for a promotion. 
 				--Identify all movies categorized as family films.
 			
			SELECT film_id, title, name
			FROM category
				INNER JOIN film_category USING (category_id)
				INNER JOIN film  USING (film_id)
			WHERE name = 'Family';

 
		--2.9) How much revenue has each store generated so far?
				
				SELECT store_id, SUM(payment.amount) AS total_revenue
				FROM
    				store 
					INNER JOIN staff USING(store_id)
					INNER JOIN payment USING(staff_id)
				GROUP BY 1
					
				

		-- 2.10) As a data analyst for the DVD rental business, you would 
				--like to have an easy way of viewing the Top 5 genres by average revenue. 
				--Write the query to get list of the top 5 genres in average revenue in 
				--descending order and create a view for it?
				
			
			--2.10.1  Creating a view for average revenue 
			
			CREATE VIEW top5_average_revenue_view AS
			 
			 SELECT 
					name,
					AVG(payment.amount) AS average_amount 
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
					INNER JOIN payment USING (rental_id)
					GROUP BY name
				ORDER BY average_amount DESC
				LIMIT 5;
				
			--2.10.1.0 We can then query the view like a table	
			
			SELECT * FROM top5_average_revenue_view;

				
			--2.10.2 (OPTIONAL) rental count, total, and average - we added this to show full picture as average sometimes could be misleading
			   
			   SELECT 
					name, COUNT (rental_id) AS rental_count,
					SUM(payment.amount) AS total_amount,
					AVG(payment.amount) AS average_amount
				FROM category
					INNER JOIN film_category USING (category_id)
					INNER JOIN film USING (film_id)
					INNER JOIN inventory USING (film_id)
					INNER JOIN rental USING (inventory_id)
					INNER JOIN payment USING (rental_id)
					GROUP BY name
				ORDER BY average_amount DESC
				LIMIT 5;
			


