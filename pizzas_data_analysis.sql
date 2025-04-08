-- Basic:
-- Retrieve the total number of orders placed.
select count(*) as Total_orders 
from orders;

-- Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),
            2) AS Total_Sales
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id;



-- Identify the highest-priced pizza.
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;


-- Identify the most common pizza size ordered.
select quantity ,count(order_details_id) 
from order_details
group by quantity;

SELECT 
    pizzas.size,
    COUNT(order_details.order_details_id) AS order_count
FROM
    pizzas
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;




-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_types.name, SUM(order_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;




-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pizza_types.category, SUM(order_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.category
ORDER BY quantity DESC;



-- Determine the distribution of orders by hour of the day.
SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time);


-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(name) AS pizza_count
FROM
    pizza_types
GROUP BY category;


-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    ROUND(AVG(quantity), 0) AS avg_pizza_ordered_per_day
FROM
    (SELECT 
        orders.order_date, SUM(order_details.quantity) AS quantity
    FROM
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY orders.order_date) AS order_quantity;


-- Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;  


-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
-- with CTE it looks like great
WITH total_sales AS (
    SELECT SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
)

SELECT 
    pt.category,
    ROUND(SUM(od.quantity * p.price) / (SELECT total_revenue FROM total_sales) * 100, 2) AS revenue
FROM 
    pizza_types pt
JOIN 
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN 
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY 
    pt.category;

    

-- Analyze the cumulative revenue generated over time.
SELECT 
    o.order_date,
    SUM(od.quantity * p.price) AS daily_revenue,
    ROUND(SUM(SUM(od.quantity * p.price)) OVER (ORDER BY o.order_date), 2) AS cumulative_revenue
FROM 
    order_details od
JOIN 
    orders o ON od.order_id = o.order_id
JOIN 
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY 
    o.order_date
ORDER BY 
    o.order_date;

-- using CTE 
WITH daily_revenue AS (
    SELECT 
        o.order_date,
        SUM(od.quantity * p.price) AS daily_revenue
    FROM 
        order_details od
    JOIN 
        orders o ON od.order_id = o.order_id
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY 
        o.order_date
)

SELECT 
    dr.order_date,
    dr.daily_revenue,
    ROUND(
        (SELECT SUM(daily_revenue) 
         FROM daily_revenue dr2 
         WHERE dr2.order_date <= dr.order_date), 
        2
    ) AS cumulative_revenue
FROM 
    daily_revenue dr
ORDER BY 
    dr.order_date;



-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
-- with subquery
select category, name , revenue 
from
(select category , name , revenue , 
rank() over(partition by category order by revenue) as rn
from  
(select pizza_types.category, pizza_types.name, 
sum(order_details.quantity * pizzas.price) as revenue 
from pizza_types 
join pizzas on pizza_types.pizza_type_id = pizzas.pizza_type_id 
join order_details on pizzas.pizza_id = order_details.pizza_id 
group by  pizza_types.category, pizza_types.name) as a) as b 
where rn <= 3;


-- using CTE
WITH ranked_pizzas AS (
    SELECT 
        pt.category,
        pt.name AS pizza_type,
        SUM(od.quantity * p.price) AS revenue,
        RANK() OVER(PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS `rank`
    FROM 
        pizza_types pt
    JOIN 
        pizzas p ON pt.pizza_type_id = p.pizza_type_id
    JOIN 
        order_details od ON od.pizza_id = p.pizza_id
    GROUP BY 
        pt.category, pt.name
)

SELECT 
    category,
    pizza_type,
    revenue
FROM 
    ranked_pizzas
WHERE 
    `rank` <= 3
ORDER BY 
    category, `rank`;










