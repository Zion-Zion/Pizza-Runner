/*

-- This section would be used to solve the case study questions for Pizza Runner

Case Study Questions
This case study has LOTS of questions - they are broken up by area of focus including:

	Pizza Metrics
	Runner and Customer Experience
	Ingredient Optimisation
	Pricing and Ratings
	Bonus DML Challenges (DML = Data Manipulation Language)
*/


-- A.PIZZA METRICS

-- How many pizzas were ordered?

SELECT COUNT(*) AS number_of_pizzas_ordered
FROM pizza_runner.customer_orders;

-- How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM pizza_runner.customer_orders;

-- How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(*) AS successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- How many of each type of pizza was delivered?

SELECT CAST(pn.pizza_name AS VARCHAR(10)) pizza_name, COUNT(CAST(pn.pizza_name AS VARCHAR(10))) AS number_of_delivered_pizzas
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
JOIN pizza_runner.pizza_names pn
ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY CAST(pn.pizza_name AS VARCHAR(10));

-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT co.customer_id,
		COUNT(CASE WHEN co.pizza_id = 1 THEN 'Meatlovers' END) Num_Meatlovers_pizza,
		COUNT(CASE WHEN co.pizza_id = 2 THEN 'Vegetarian' END) Num_Vegetarian_pizza
FROM pizza_runner.customer_orders co
JOIN pizza_runner.pizza_names pn
ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id;

-- What was the maximum number of pizzas delivered in a single order?

SELECT TOP 1 COUNT(order_id) max_num_orders
FROM pizza_runner.customer_orders
GROUP BY order_id
ORDER BY COUNT(order_id) DESC;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT co.customer_id,
		COUNT(CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 'no' END) no_change,
		COUNT(CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 'yes' END) at_least_one_change
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(*) number_of_pizzas_with_exclusion_and_extras
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL AND co.exclusions IS NOT NULL AND co.extras IS NOT NULL;


-- What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(hour, order_time) "hour", COUNT(order_id) number_of_orders
FROM pizza_runner.customer_orders
GROUP BY DATEPART(hour, order_time);

-- What was the volume of orders for each day of the week?

SELECT DATENAME(WEEKDAY, order_time) week_day, COUNT(order_id) number_of_orders
FROM pizza_runner.customer_orders
GROUP BY DATENAME(WEEKDAY, order_time), DATEPART(WEEKDAY, order_time)
ORDER BY DATEPART(WEEKDAY, order_time) ASC;


--B. RUNNER AND CUSTOMER EXPERIENCE

-- How many runners signed up for each 1 week period starting from 2021-01-01?
SELECT 
    CEILING(DATEDIFF(DAY, '2021-01-01', registration_date) / 7.0) AS WEEK_,
    COUNT(runner_id) AS number_of_runners
FROM pizza_runner.runners
WHERE registration_date >= '2021-01-01'
GROUP BY CEILING(
				DATEDIFF(DAY, '2021-01-01', registration_date) / 7.0)
ORDER BY WEEK_;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id, CONCAT(AVG(duration), ' minutes') AS Avg_duration
FROM pizza_runner.runner_orders
GROUP BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT co.order_id, COUNT(co.pizza_id) AS pizza_count, 
       CONCAT(DATEDIFF(minute, co.order_time, ro.pickup_time), ' minutes') AS duration
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id, DATEDIFF(minute, co.order_time, ro.pickup_time)
ORDER BY pizza_count DESC;

-- What was the average distance travelled for each customer?

SELECT co.customer_id, CONCAT(AVG(ro.distance), ' km') avg_distance
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT CONCAT(
		DIFFERENCE(MAX(duration), MIN(duration)), ' minutes') delivery_time_difference
FROM pizza_runner.runner_orders;


-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT CONCAT(AVG(distance / duration), ' km/min') avg_speed,
		runner_id, order_id
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id, order_id
ORDER BY runner_id, order_id;

-- What is the successful delivery percentage for each runner?
SELECT SUM(CASE WHEN cancellation is null THEN 1 ELSE 0 END) AS successful_orders,
		COUNT(order_id) total_orders,
		CONCAT((
				CAST(SUM(CASE WHEN cancellation is null THEN 1 ELSE 0 END) AS float) / COUNT(order_id)) *100, '%') [successful delivery percentage], runner_id
FROM pizza_runner.runner_orders
GROUP BY runner_id;

-- C. INGREDIENT OPTIMISATION

-- What are the standard ingredients for each pizza?
WITH p_r_sep AS (
	SELECT pizza_id, cs.Value
	FROM pizza_runner.pizza_recipes
	CROSS APPLY STRING_SPLIT (CAST(toppings AS nvarchar(30)), ',') cs)

SELECT CAST(pn.pizza_name AS nvarchar(30)) pizza_type,
		STRING_AGG(CAST(pt.topping_name AS nvarchar(30)), ', ') standard_ingredients
FROM pizza_runner.pizza_names pn
JOIN p_r_sep
ON p_r_sep.pizza_id = pn.pizza_id
JOIN pizza_runner.pizza_toppings pt
ON p_r_sep.Value = pt.topping_id
GROUP BY CAST(pn.pizza_name AS nvarchar(30));

-- What was the most commonly added extra?

WITH extras_sep AS (
	SELECT pizza_id, TRIM(cs.Value) Value
	FROM pizza_runner.customer_orders
	CROSS APPLY STRING_SPLIT (extras, ',') cs)

SELECT TOP 1 (CAST(pt.topping_name AS nvarchar(15))) topping,
		COUNT(Value) times_added
FROM extras_sep
JOIN pizza_runner.pizza_toppings pt
ON extras_sep.Value = pt.topping_id
GROUP BY (CAST(pt.topping_name AS nvarchar(15)))
ORDER BY 2 DESC;

-- What was the most common exclusion?

WITH exclu_sep AS (
	SELECT pizza_id, TRIM(cs.Value) Value
	FROM pizza_runner.customer_orders
	CROSS APPLY STRING_SPLIT (exclusions, ',') cs)

SELECT TOP 1 (CAST(pt.topping_name AS nvarchar(15))) topping,
		COUNT(Value) times_excluded
FROM exclu_sep
JOIN pizza_runner.pizza_toppings pt
ON exclu_sep.Value = pt.topping_id
GROUP BY (CAST(pt.topping_name AS nvarchar(15)))
ORDER BY 2 DESC;


-- D. PRICING AND RATINGS

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT CONCAT('$', SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END)) AS total_earnings
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;

-- What if there was an additional $1 charge for any pizza extras?

SELECT CONCAT('$', 
    (SELECT SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END)
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL) 
    +
    (SELECT 1 * COUNT(Value)
    FROM(
		SELECT pizza_id, TRIM(cs.Value) Value
        FROM pizza_runner.customer_orders
        CROSS APPLY STRING_SPLIT(extras, ',') cs
        ) extras_sep
    JOIN pizza_runner.runner_orders ro ON extras_sep.Value = ro.order_id
    WHERE ro.cancellation IS NULL)
) [earnings + charge];


-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

-- Drop the table if it exists
DROP TABLE IF EXISTS pizza_runner.runner_ratings;

-- Create the new table
USE [SQL Challenge 2];
CREATE TABLE pizza_runner.runner_ratings (
    order_id INT,
    runner_id INT,
    ratings INT
);

-- Insert sample data
INSERT INTO pizza_runner.runner_ratings (order_id, runner_id, ratings)
SELECT 
    order_id,
    runner_id,
    CASE 
        WHEN cancellation IS NOT NULL THEN NULL
        ELSE ABS(CHECKSUM(NEWID())) % 5 + 1
    END AS ratings
FROM 
    pizza_runner.runner_orders;

-- View the inserted data
SELECT * FROM pizza_runner.runner_ratings;


/* Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */

SELECT co.customer_id, co.order_id, ro.runner_id, rr.ratings, co.order_time, ro.pickup_time,
		CONCAT(DATEDIFF(minute, co.order_time, ro.pickup_time), ' minutes') [order/pickup_time_difference], ro.duration,
		CONCAT(AVG(ro.distance / ro.duration), ' km/min') avg_speed, COUNT(co.pizza_id) number_of_pizzas
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON co.order_id = ro.order_id
JOIN pizza_runner.runner_ratings rr
ON rr.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY  co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.ratings,
    co.order_time,
    ro.pickup_time,
    ro.duration;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

SELECT CONCAT('$', 
    (SELECT SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END)
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL) 
    -
    (SELECT SUM(distance * 0.3)
    FROM pizza_runner.runner_orders
    WHERE cancellation IS NULL)
) [earnings_after_delivery_charges];


-- E. BONUS QUESTIONS

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


INSERT INTO pizza_runner.pizza_recipes
VALUES
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10');

INSERT INTO pizza_runner.pizza_names
VALUES
  (3, 'Supreme');

-- View modified data
SELECT *
FROM pizza_runner.pizza_recipes;

SELECT *
FROM pizza_runner.pizza_names;
