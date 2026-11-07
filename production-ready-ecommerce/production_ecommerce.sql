-- CORE TABLES

CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_user_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'BLOCKED'
            )
        )
);


CREATE TABLE addresses (
    address_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'USA',
    address_type VARCHAR(20) NOT NULL DEFAULT 'SHIPPING',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_address_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_address_type
        CHECK (
            address_type IN (
                'SHIPPING',
                'BILLING'
            )
        )
);


CREATE TABLE categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(120) NOT NULL UNIQUE,
    description VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT chk_category_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE'
            )
        )
);


CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_product_price
        CHECK (price >= 0),

    CONSTRAINT chk_product_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'DISCONTINUED'
            )
        )
);


CREATE TABLE inventory (
    product_id BIGINT PRIMARY KEY,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER NOT NULL DEFAULT 5,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_stock_quantity
        CHECK (stock_quantity >= 0),

    CONSTRAINT chk_reorder_level
        CHECK (reorder_level >= 0)
);


CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    shipping_address_id BIGINT NOT NULL,
    order_status VARCHAR(30) NOT NULL DEFAULT 'PLACED',
    subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    shipping_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_order_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_order_status
        CHECK (
            order_status IN (
                'PLACED',
                'PAID',
                'PROCESSING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED'
            )
        ),

    CONSTRAINT chk_order_amounts
        CHECK (
            subtotal >= 0
            AND tax_amount >= 0
            AND shipping_amount >= 0
            AND total_amount >= 0
        )
);


CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    line_total NUMERIC(14, 2) NOT NULL,

    CONSTRAINT fk_item_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_item_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_item_price
        CHECK (
            unit_price >= 0
            AND line_total >= 0
        ),

    CONSTRAINT uq_order_product
        UNIQUE (
            order_id,
            product_id
        )
);


CREATE TABLE payments (
    payment_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    payment_reference VARCHAR(100) NOT NULL UNIQUE,
    payment_method VARCHAR(30) NOT NULL,
    amount NUMERIC(14, 2) NOT NULL,
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    CONSTRAINT chk_payment_method
        CHECK (
            payment_method IN (
                'CARD',
                'BANK_TRANSFER',
                'WALLET'
            )
        ),

    CONSTRAINT chk_payment_status
        CHECK (
            payment_status IN (
                'PENDING',
                'PAID',
                'FAILED',
                'REFUNDED'
            )
        )
);


CREATE TABLE reviews (
    review_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    rating INTEGER NOT NULL,
    review_text VARCHAR(1000),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_review_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_review_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_rating
        CHECK (
            rating BETWEEN 1 AND 5
        ),

    CONSTRAINT uq_user_product_review
        UNIQUE (
            user_id,
            product_id
        )
);


-- SAMPLE DATA

INSERT INTO users (
    first_name,
    last_name,
    email,
    phone
)
VALUES
(
    'Thanay',
    'R',
    'thanay.r@example.com',
    '5555001001'
),
(
    'Manoj',
    'K',
    'manoj.k@example.com',
    '5555001002'
),
(
    'Vinay',
    'K',
    'vinay.k@example.com',
    '5555001003'
),
(
    'Simha',
    'D',
    'simha.d@example.com',
    '5555001004'
);


INSERT INTO addresses (
    user_id,
    address_line1,
    city,
    state,
    postal_code,
    is_default
)
VALUES
(
    1,
    '101 Main Street',
    'Kansas City',
    'Missouri',
    '64101',
    TRUE
),
(
    2,
    '202 Lake Avenue',
    'Chicago',
    'Illinois',
    '60601',
    TRUE
),
(
    3,
    '303 Oak Road',
    'Dallas',
    'Texas',
    '75201',
    TRUE
),
(
    4,
    '404 Peach Street',
    'Atlanta',
    'Georgia',
    '30301',
    TRUE
);


INSERT INTO categories (
    category_name,
    description
)
VALUES
(
    'Electronics',
    'Electronic products and accessories'
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


INSERT INTO products (
    category_id,
    sku,
    product_name,
    description,
    price
)
VALUES
(
    1,
    'ELEC-001',
    'Wireless Headphones',
    'Bluetooth noise cancelling headphones',
    99.99
),
(
    1,
    'ELEC-002',
    'Mechanical Keyboard',
    'USB mechanical keyboard for work and gaming',
    79.99
),
(
    1,
    'ELEC-003',
    'USB-C Charger',
    'Fast charging USB-C power adapter',
    29.99
),
(
    2,
    'BOOK-001',
    'SQL Fundamentals',
    'Beginner guide to relational databases and SQL',
    39.99
),
(
    2,
    'BOOK-002',
    'Java Programming',
    'Practical Java programming guide',
    44.99
),
(
    3,
    'HOME-001',
    'Coffee Maker',
    'Automatic programmable coffee maker',
    69.99
),
(
    4,
    'CLOTH-001',
    'Casual T-Shirt',
    'Cotton casual t-shirt',
    24.99
),
(
    4,
    'CLOTH-002',
    'Winter Jacket',
    'Warm winter jacket',
    129.99
);


INSERT INTO inventory (
    product_id,
    stock_quantity,
    reorder_level
)
VALUES
(1, 25, 5),
(2, 15, 5),
(3, 40, 10),
(4, 30, 5),
(5, 20, 5),
(6, 12, 4),
(7, 35, 10),
(8, 10, 3);


-- INDEXES

CREATE INDEX idx_addresses_user
ON addresses(user_id);


CREATE INDEX idx_products_category_status
ON products(
    category_id,
    status
);


CREATE INDEX idx_products_price
ON products(price);


CREATE INDEX idx_orders_user_created
ON orders(
    user_id,
    created_at DESC
);


CREATE INDEX idx_orders_status
ON orders(order_status);


CREATE INDEX idx_order_items_product
ON order_items(product_id);


CREATE INDEX idx_payments_order_status
ON payments(
    order_id,
    payment_status
);


CREATE INDEX idx_reviews_product
ON reviews(product_id);


CREATE INDEX idx_reviews_rating
ON reviews(rating);


CREATE INDEX idx_product_fulltext
ON products
USING GIN (
    to_tsvector(
        'english',
        product_name
        || ' '
        || COALESCE(description, '')
    )
);


-- UPDATE TIMESTAMP TRIGGER

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER

LANGUAGE plpgsql

AS $$

BEGIN

    NEW.updated_at =
        CURRENT_TIMESTAMP;

    RETURN NEW;

END;

$$;


CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE
ON products
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE
ON orders
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- VIEWS

CREATE VIEW product_catalog_view AS

SELECT
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.price,
    i.stock_quantity,
    p.status,

    COALESCE(
        ROUND(
            AVG(r.rating),
            2
        ),
        0
    ) AS average_rating,

    COUNT(r.review_id)
        AS review_count

FROM products p

JOIN categories c
    ON p.category_id =
       c.category_id

JOIN inventory i
    ON p.product_id =
       i.product_id

LEFT JOIN reviews r
    ON p.product_id =
       r.product_id

GROUP BY
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    p.price,
    i.stock_quantity,
    p.status;


CREATE VIEW order_summary_view AS

SELECT
    o.order_id,

    u.first_name
        || ' '
        || u.last_name
        AS customer_name,

    u.email,

    o.order_status,

    o.subtotal,
    o.tax_amount,
    o.shipping_amount,
    o.total_amount,

    COUNT(oi.order_item_id)
        AS item_lines,

    COALESCE(
        SUM(oi.quantity),
        0
    ) AS total_items,

    o.created_at

FROM orders o

JOIN users u
    ON o.user_id =
       u.user_id

LEFT JOIN order_items oi
    ON o.order_id =
       oi.order_id

GROUP BY
    o.order_id,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email;


CREATE VIEW product_sales_view AS

SELECT
    p.product_id,
    p.product_name,

    COALESCE(
        SUM(
            CASE
                WHEN o.order_status
                     <> 'CANCELLED'
                THEN oi.quantity
                ELSE 0
            END
        ),
        0
    ) AS units_sold,

    COALESCE(
        SUM(
            CASE
                WHEN o.order_status
                     <> 'CANCELLED'
                THEN oi.line_total
                ELSE 0
            END
        ),
        0
    ) AS revenue

FROM products p

LEFT JOIN order_items oi
    ON p.product_id =
       oi.product_id

LEFT JOIN orders o
    ON oi.order_id =
       o.order_id

GROUP BY
    p.product_id,
    p.product_name;


-- PLACE ORDER PROCEDURE

CREATE OR REPLACE PROCEDURE place_order(
    p_user_id BIGINT,
    p_address_id BIGINT,
    p_items JSONB,
    INOUT p_order_id BIGINT DEFAULT NULL
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_item JSONB;
    v_product_id BIGINT;
    v_quantity INTEGER;
    v_price NUMERIC(12, 2);
    v_stock INTEGER;
    v_status VARCHAR(20);
    v_subtotal NUMERIC(14, 2) := 0;
    v_tax NUMERIC(14, 2);
    v_shipping NUMERIC(14, 2);

BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = p_user_id
          AND status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION
            'Active user % does not exist',
            p_user_id;
    END IF;


    IF NOT EXISTS (
        SELECT 1
        FROM addresses
        WHERE address_id = p_address_id
          AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'Address does not belong to user';
    END IF;


    IF p_items IS NULL
       OR jsonb_array_length(p_items) = 0
    THEN
        RAISE EXCEPTION
            'Order must contain at least one product';
    END IF;


    FOR v_item IN
        SELECT *
        FROM jsonb_array_elements(
            p_items
        )
    LOOP

        v_product_id :=
            (v_item ->> 'product_id')::BIGINT;

        v_quantity :=
            (v_item ->> 'quantity')::INTEGER;


        IF v_quantity IS NULL
           OR v_quantity <= 0
        THEN
            RAISE EXCEPTION
                'Quantity must be greater than zero';
        END IF;


        SELECT
            p.price,
            i.stock_quantity,
            p.status
        INTO
            v_price,
            v_stock,
            v_status

        FROM products p

        JOIN inventory i
            ON p.product_id =
               i.product_id

        WHERE p.product_id =
              v_product_id

        FOR UPDATE OF i;


        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Product % does not exist',
                v_product_id;
        END IF;


        IF v_status <> 'ACTIVE' THEN
            RAISE EXCEPTION
                'Product % is not active',
                v_product_id;
        END IF;


        IF v_stock < v_quantity THEN
            RAISE EXCEPTION
                'Insufficient stock for product %',
                v_product_id;
        END IF;


        v_subtotal :=
            v_subtotal
            + (
                v_price
                * v_quantity
            );

    END LOOP;


    v_tax :=
        ROUND(
            v_subtotal * 0.08,
            2
        );


    v_shipping :=
        CASE
            WHEN v_subtotal >= 100
                THEN 0
            ELSE 10
        END;


    INSERT INTO orders (
        user_id,
        shipping_address_id,
        subtotal,
        tax_amount,
        shipping_amount,
        total_amount
    )
    VALUES (
        p_user_id,
        p_address_id,
        v_subtotal,
        v_tax,
        v_shipping,
        v_subtotal
            + v_tax
            + v_shipping
    )
    RETURNING order_id
    INTO p_order_id;


    FOR v_item IN
        SELECT *
        FROM jsonb_array_elements(
            p_items
        )
    LOOP

        v_product_id :=
            (v_item ->> 'product_id')::BIGINT;

        v_quantity :=
            (v_item ->> 'quantity')::INTEGER;


        SELECT price
        INTO v_price
        FROM products
        WHERE product_id =
              v_product_id;


        INSERT INTO order_items (
            order_id,
            product_id,
            quantity,
            unit_price,
            line_total
        )
        VALUES (
            p_order_id,
            v_product_id,
            v_quantity,
            v_price,
            v_price * v_quantity
        );


        UPDATE inventory
        SET
            stock_quantity =
                stock_quantity
                - v_quantity,

            updated_at =
                CURRENT_TIMESTAMP

        WHERE product_id =
              v_product_id;

    END LOOP;

END;

$$;


-- PAYMENT PROCEDURE

CREATE OR REPLACE PROCEDURE record_payment(
    p_order_id BIGINT,
    p_payment_reference VARCHAR,
    p_payment_method VARCHAR
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_total NUMERIC(14, 2);
    v_status VARCHAR(30);

BEGIN

    SELECT
        total_amount,
        order_status
    INTO
        v_total,
        v_status

    FROM orders

    WHERE order_id =
          p_order_id

    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Order % does not exist',
            p_order_id;
    END IF;


    IF v_status = 'CANCELLED' THEN
        RAISE EXCEPTION
            'Cancelled order cannot be paid';
    END IF;


    IF EXISTS (
        SELECT 1
        FROM payments
        WHERE order_id = p_order_id
          AND payment_status = 'PAID'
    ) THEN
        RAISE EXCEPTION
            'Order is already paid';
    END IF;


    INSERT INTO payments (
        order_id,
        payment_reference,
        payment_method,
        amount,
        payment_status,
        paid_at
    )
    VALUES (
        p_order_id,
        p_payment_reference,
        p_payment_method,
        v_total,
        'PAID',
        CURRENT_TIMESTAMP
    );


    UPDATE orders
    SET order_status = 'PAID'
    WHERE order_id =
          p_order_id;

END;

$$;


-- CANCEL ORDER PROCEDURE

CREATE OR REPLACE PROCEDURE cancel_order(
    p_order_id BIGINT
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_status VARCHAR(30);
    v_item RECORD;

BEGIN

    SELECT order_status
    INTO v_status
    FROM orders
    WHERE order_id =
          p_order_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Order % does not exist',
            p_order_id;
    END IF;


    IF v_status IN (
        'SHIPPED',
        'DELIVERED',
        'CANCELLED'
    ) THEN
        RAISE EXCEPTION
            'Order cannot be cancelled';
    END IF;


    FOR v_item IN

        SELECT
            product_id,
            quantity

        FROM order_items

        WHERE order_id =
              p_order_id

    LOOP

        UPDATE inventory
        SET
            stock_quantity =
                stock_quantity
                + v_item.quantity,

            updated_at =
                CURRENT_TIMESTAMP

        WHERE product_id =
              v_item.product_id;

    END LOOP;


    UPDATE orders
    SET order_status =
        'CANCELLED'
    WHERE order_id =
          p_order_id;


    UPDATE payments
    SET payment_status =
        'REFUNDED'
    WHERE order_id =
          p_order_id
      AND payment_status =
          'PAID';

END;

$$;


-- SAMPLE REVIEWS

INSERT INTO reviews (
    user_id,
    product_id,
    rating,
    review_text
)
VALUES
(
    1,
    1,
    5,
    'Very good sound quality'
),
(
    2,
    1,
    4,
    'Good headphones for the price'
),
(
    3,
    4,
    5,
    'Useful SQL learning book'
);


-- FULL-TEXT SEARCH EXAMPLE

SELECT
    product_id,
    product_name,
    description,
    price

FROM products

WHERE to_tsvector(
    'english',
    product_name
    || ' '
    || COALESCE(description, '')
)
@@ plainto_tsquery(
    'english',
    'wireless headphones'
);


-- PAGINATION AND SORTING

SELECT
    product_id,
    product_name,
    price

FROM products

WHERE status = 'ACTIVE'

ORDER BY
    price ASC,
    product_id ASC

LIMIT 5
OFFSET 0;


-- LOW STOCK REPORT

SELECT
    p.product_id,
    p.product_name,
    i.stock_quantity,
    i.reorder_level

FROM products p

JOIN inventory i
    ON p.product_id =
       i.product_id

WHERE i.stock_quantity
      <= i.reorder_level

ORDER BY i.stock_quantity;


-- TOP SELLING PRODUCTS

SELECT *
FROM product_sales_view

ORDER BY
    units_sold DESC,
    revenue DESC;


-- CUSTOMER ORDER HISTORY

SELECT
    o.order_id,
    o.order_status,
    o.total_amount,
    o.created_at

FROM orders o

WHERE o.user_id = 1

ORDER BY o.created_at DESC;


-- QUERY PLAN EXAMPLE

EXPLAIN ANALYZE

SELECT
    order_id,
    order_status,
    total_amount,
    created_at

FROM orders

WHERE user_id = 1

ORDER BY created_at DESC;