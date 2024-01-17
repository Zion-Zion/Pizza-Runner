-- Dealing with 'null' and whitespace values, and replacing them with NULL
UPDATE pizza_runner.customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', ' ');

UPDATE pizza_runner.customer_orders
SET extras = NULL
WHERE extras IN ('null', ' ');

UPDATE pizza_runner.runner_orders
SET cancellation = NULL
WHERE cancellation IN ('null', ' ');

-- Setting NULL for columns where orders were cancelled

UPDATE pizza_runner.runner_orders
SET pickup_time = NULL
WHERE cancellation IS NOT NULL; 

UPDATE pizza_runner.runner_orders
SET distance = NULL
WHERE cancellation IS NOT NULL;

UPDATE pizza_runner.runner_orders
SET duration = NULL
WHERE cancellation IS NOT NULL;

-- Cleaning up distance and duration values

UPDATE pizza_runner.runner_orders
SET distance = RTRIM(distance, ' km');

UPDATE pizza_runner.runner_orders
SET duration = RTRIM(duration, ' minutes');

-- Correcting data types

ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN pickup_time DATETIME;

ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN duration INT;

ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN distance FLOAT;