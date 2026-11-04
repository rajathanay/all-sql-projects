-- ============================================
-- E-Commerce Basic Schema
-- ============================================


-- ============================================
-- 1. USERS TABLE
-- ============================================

CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,

    first_name VARCHAR(100)
        NOT NULL,

    last_name VARCHAR(100)
        NOT NULL,

    email VARCHAR(200)
        NOT NULL
        UNIQUE,

    phone VARCHAR(20)
        UNIQUE,

    city VARCHAR(100),

    created_at TIMESTAMP
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20)
        NOT NULL
        DEFAULT 'ACTIVE',

    CONSTRAINT chk_user_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE'
            )
        )
);


-- ============================================
-- 2. CATEGORIES TABLE
-- ============================================

CREATE TABLE categories (
    category_id BIGSERIAL PRIMARY KEY,

    category_name VARCHAR(100)
        NOT NULL
        UNIQUE,

    description VARCHAR(300),

    created_at TIMESTAMP
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- 3. PRODUCTS TABLE
-- ============================================

CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,

    category_id BIGINT
        NOT NULL,

    product_name VARCHAR(150)
        NOT NULL,

    description VARCHAR(500),

    price NUMERIC(10, 2)
        NOT NULL,

    stock_quantity INTEGER
        NOT NULL
        DEFAULT 0,

    status VARCHAR(20)
        NOT NULL
        DEFAULT 'ACTIVE',

    created_at TIMESTAMP
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_product_price
        CHECK (
            price >= 0
        ),

    CONSTRAINT chk_stock_quantity
        CHECK (
            stock_quantity >= 0
        ),

    CONSTRAINT chk_product_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE'
            )
        )
);


-- ============================================
-- 4. ORDERS TABLE
-- ============================================

CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT
        NOT NULL,

    order_date TIMESTAMP
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    order_status VARCHAR(20)
        NOT NULL
        DEFAULT 'PLACED',

    total_amount NUMERIC(12, 2)
        NOT NULL,

    shipping_city VARCHAR(100)
        NOT NULL,

    CONSTRAINT fk_order_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_order_status
        CHECK (
            order_status IN (
                'PLACED',
                'PROCESSING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED'
            )
        ),

    CONSTRAINT chk_total_amount
        CHECK (
            total_amount >= 0
        )
);


-- ============================================
-- 5. SAMPLE USERS
-- ============================================

INSERT INTO users (
    first_name,
    last_name,
    email,
    phone,
    city
)
VALUES
(
    'John',
    'Smith',
    'john.smith@example.com',
    '5552001001',
    'Kansas City'
),
(
    'Sarah',
    'Johnson',
    'sarah.johnson@example.com',
    '5552001002',
    'Chicago'
),
(
    'Michael',
    'Brown',
    'michael.brown@example.com',
    '5552001003',
    'Dallas'
),
(
    'Emily',
    'Davis',
    'emily.davis@example.com',
    '5552001004',
    'Atlanta'
);


-- ============================================
-- 6. SAMPLE CATEGORIES
-- ============================================

INSERT INTO categories (
    category_name,
    description
)
VALUES
(
    'Electronics',
    'Electronic devices and accessories'
),
(
    'Books',
    'Books and learning materials'
),
(
    'Home',
    'Home and kitchen products'
),
(
    'Clothing',
    'Clothing and fashion products'
);


-- ============================================
-- 7. SAMPLE PRODUCTS
-- ============================================

INSERT INTO products (
    category_id,
    product_name,
    description,
    price,
    stock_quantity
)
VALUES
(
    1,
    'Wireless Headphones',
    'Bluetooth wireless headphones',
    89.99,
    25
),
(
    1,
    'Mechanical Keyboard',
    'USB mechanical keyboard',
    74.50,
    18
),
(
    2,
    'SQL Fundamentals',
    'Beginner SQL learning book',
    39.99,
    40
),
(
    3,
    'Coffee Maker',
    'Automatic coffee maker',
    59.95,
    15
),
(
    4,
    'Casual T-Shirt',
    'Cotton casual t-shirt',
    24.99,
    30
);


-- ============================================
-- 8. SAMPLE ORDERS
-- ============================================

INSERT INTO orders (
    user_id,
    order_status,
    total_amount,
    shipping_city
)
VALUES
(
    1,
    'DELIVERED',
    89.99,
    'Kansas City'
),
(
    2,
    'SHIPPED',
    114.49,
    'Chicago'
),
(
    3,
    'PROCESSING',
    39.99,
    'Dallas'
),
(
    1,
    'PLACED',
    59.95,
    'Kansas City'
);


-- ============================================
-- READ QUERIES
-- ============================================


-- 9. View all users

SELECT *
FROM users
ORDER BY user_id;


-- 10. View all categories

SELECT *
FROM categories
ORDER BY category_id;


-- 11. View all products

SELECT *
FROM products
ORDER BY product_id;


-- 12. View all orders

SELECT *
FROM orders
ORDER BY order_id;


-- ============================================
-- SEARCH AND FILTER QUERIES
-- ============================================


-- 13. Search product by name

SELECT *
FROM products
WHERE product_name ILIKE '%keyboard%';


-- 14. Find products below $60

SELECT
    product_id,
    product_name,
    price
FROM products
WHERE price < 60
ORDER BY price;


-- 15. Find products with stock greater than 20

SELECT
    product_name,
    stock_quantity
FROM products
WHERE stock_quantity > 20
ORDER BY stock_quantity DESC;


-- 16. Find active products

SELECT
    product_id,
    product_name,
    status
FROM products
WHERE status = 'ACTIVE';


-- 17. Find orders by status

SELECT
    order_id,
    user_id,
    order_status,
    total_amount
FROM orders
WHERE order_status IN (
    'PLACED',
    'PROCESSING'
);


-- 18. Find products priced between $30 and $100

SELECT
    product_name,
    price
FROM products
WHERE price BETWEEN 30 AND 100
ORDER BY price;


-- ============================================
-- CREATE / INSERT EXAMPLES
-- ============================================


-- 19. Create a new user

INSERT INTO users (
    first_name,
    last_name,
    email,
    phone,
    city
)
VALUES (
    'David',
    'Wilson',
    'david.wilson@example.com',
    '5552001005',
    'St. Louis'
);


-- 20. Create a new product

INSERT INTO products (
    category_id,
    product_name,
    description,
    price,
    stock_quantity
)
VALUES (
    1,
    'USB-C Charger',
    'Fast charging USB-C adapter',
    29.99,
    50
);


-- ============================================
-- UPDATE EXAMPLES
-- ============================================


-- 21. Update a product price

UPDATE products
SET price = 69.99
WHERE product_id = 2;


-- 22. Update product stock

UPDATE products
SET stock_quantity = 45
WHERE product_id = 3;


-- 23. Update user city

UPDATE users
SET city = 'Springfield'
WHERE user_id = 3;


-- 24. Update order status

UPDATE orders
SET order_status = 'DELIVERED'
WHERE order_id = 2;


-- ============================================
-- DELETE EXAMPLES
-- ============================================


-- Keep these commented while testing.
-- Uncomment only when you want to test DELETE.


-- 25. Delete an order

-- DELETE FROM orders
-- WHERE order_id = 4;


-- 26. Delete a product

-- DELETE FROM products
-- WHERE product_id = 6;


-- ============================================
-- AGGREGATE QUERIES
-- ============================================


-- 27. Total number of users

SELECT
    COUNT(*) AS total_users
FROM users;


-- 28. Total number of products

SELECT
    COUNT(*) AS total_products
FROM products;


-- 29. Average product price

SELECT
    ROUND(
        AVG(price),
        2
    ) AS average_product_price
FROM products;


-- 30. Highest product price

SELECT
    MAX(price) AS highest_price
FROM products;


-- 31. Lowest product price

SELECT
    MIN(price) AS lowest_price
FROM products;


-- 32. Total order value

SELECT
    SUM(total_amount)
        AS total_order_value
FROM orders;


-- ============================================
-- GROUP BY QUERIES
-- ============================================


-- 33. Number of products by category

SELECT
    category_id,
    COUNT(*) AS product_count
FROM products
GROUP BY category_id
ORDER BY category_id;


-- 34. Number of orders by status

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 35. Total sales by shipping city

SELECT
    shipping_city,
    SUM(total_amount)
        AS total_sales
FROM orders
GROUP BY shipping_city
ORDER BY total_sales DESC;


-- ============================================
-- BASIC JOIN REPORT
-- ============================================


-- 36. Product with category report

SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.price,
    p.stock_quantity

FROM products p

JOIN categories c
    ON p.category_id =
       c.category_id

ORDER BY p.product_id;


-- ============================================
-- USER ORDER REPORT
-- ============================================


-- 37. User order report

SELECT
    o.order_id,

    u.first_name
        || ' '
        || u.last_name
        AS customer_name,

    u.email,

    o.order_date,

    o.order_status,

    o.total_amount,

    o.shipping_city

FROM orders o

JOIN users u
    ON o.user_id =
       u.user_id

ORDER BY o.order_date DESC;


-- ============================================
-- CUSTOMER TOTAL ORDER VALUE
-- ============================================


-- 38. Total order amount for each customer

SELECT
    u.user_id,

    u.first_name
        || ' '
        || u.last_name
        AS customer_name,

    COUNT(o.order_id)
        AS total_orders,

    COALESCE(
        SUM(o.total_amount),
        0
    ) AS total_spent

FROM users u

LEFT JOIN orders o
    ON u.user_id =
       o.user_id

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

ORDER BY total_spent DESC;