CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_customer_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'BLOCKED'
            )
        )
);


CREATE TABLE wallets (
    wallet_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL UNIQUE,
    wallet_number VARCHAR(30) NOT NULL UNIQUE,
    current_balance NUMERIC(14, 2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_wallet_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_wallet_balance
        CHECK (current_balance >= 0),

    CONSTRAINT chk_wallet_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'BLOCKED'
            )
        )
);


CREATE TABLE wallet_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL,
    related_wallet_id BIGINT,
    transaction_type VARCHAR(20) NOT NULL,
    amount NUMERIC(14, 2) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    description VARCHAR(250),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_transaction_wallet
        FOREIGN KEY (wallet_id)
        REFERENCES wallets(wallet_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_related_wallet
        FOREIGN KEY (related_wallet_id)
        REFERENCES wallets(wallet_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_transaction_type
        CHECK (
            transaction_type IN (
                'DEPOSIT',
                'WITHDRAWAL',
                'TRANSFER_IN',
                'TRANSFER_OUT'
            )
        ),

    CONSTRAINT chk_transaction_amount
        CHECK (amount > 0),

    CONSTRAINT chk_transaction_status
        CHECK (
            transaction_status IN (
                'SUCCESS',
                'FAILED'
            )
        )
);


INSERT INTO customers (
    first_name,
    last_name,
    email,
    phone
)
VALUES
(
    'John',
    'Smith',
    'john.smith@example.com',
    '5554001001'
),
(
    'Sarah',
    'Johnson',
    'sarah.johnson@example.com',
    '5554001002'
),
(
    'Michael',
    'Brown',
    'michael.brown@example.com',
    '5554001003'
),
(
    'Emily',
    'Davis',
    'emily.davis@example.com',
    '5554001004'
);


INSERT INTO wallets (
    customer_id,
    wallet_number,
    current_balance
)
VALUES
(
    1,
    'WALLET1001',
    5000.00
),
(
    2,
    'WALLET1002',
    3500.00
),
(
    3,
    'WALLET1003',
    7000.00
),
(
    4,
    'WALLET1004',
    2500.00
);


INSERT INTO wallet_transactions (
    wallet_id,
    transaction_type,
    amount,
    description,
    created_at
)
VALUES
(
    1,
    'DEPOSIT',
    5000.00,
    'Initial wallet funding',
    CURRENT_TIMESTAMP - INTERVAL '10 days'
),
(
    2,
    'DEPOSIT',
    3500.00,
    'Initial wallet funding',
    CURRENT_TIMESTAMP - INTERVAL '10 days'
),
(
    3,
    'DEPOSIT',
    7000.00,
    'Initial wallet funding',
    CURRENT_TIMESTAMP - INTERVAL '10 days'
),
(
    4,
    'DEPOSIT',
    2500.00,
    'Initial wallet funding',
    CURRENT_TIMESTAMP - INTERVAL '10 days'
);


INSERT INTO wallet_transactions (
    wallet_id,
    transaction_type,
    amount,
    description,
    created_at
)
VALUES
(
    1,
    'WITHDRAWAL',
    300.00,
    'ATM withdrawal',
    CURRENT_TIMESTAMP - INTERVAL '8 days'
),
(
    1,
    'DEPOSIT',
    500.00,
    'Salary adjustment',
    CURRENT_TIMESTAMP - INTERVAL '7 days'
),
(
    1,
    'WITHDRAWAL',
    200.00,
    'ATM withdrawal',
    CURRENT_TIMESTAMP - INTERVAL '6 days'
),
(
    2,
    'WITHDRAWAL',
    250.00,
    'Card payment',
    CURRENT_TIMESTAMP - INTERVAL '5 days'
),
(
    3,
    'WITHDRAWAL',
    600.00,
    'ATM withdrawal',
    CURRENT_TIMESTAMP - INTERVAL '4 days'
);


-- Running balance

SELECT
    transaction_id,
    wallet_id,
    transaction_type,
    amount,
    created_at,

    SUM(
        CASE
            WHEN transaction_type IN (
                'DEPOSIT',
                'TRANSFER_IN'
            )
            THEN amount

            WHEN transaction_type IN (
                'WITHDRAWAL',
                'TRANSFER_OUT'
            )
            THEN -amount

            ELSE 0
        END
    ) OVER (
        PARTITION BY wallet_id
        ORDER BY created_at, transaction_id
        ROWS BETWEEN
            UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS running_balance

FROM wallet_transactions

WHERE transaction_status = 'SUCCESS'

ORDER BY
    wallet_id,
    created_at,
    transaction_id;


-- Detailed transaction history

SELECT
    wt.transaction_id,

    c.first_name
        || ' '
        || c.last_name
        AS customer_name,

    w.wallet_number,

    wt.transaction_type,

    wt.amount,

    wt.description,

    wt.created_at,

    SUM(
        CASE
            WHEN wt.transaction_type IN (
                'DEPOSIT',
                'TRANSFER_IN'
            )
            THEN wt.amount

            ELSE -wt.amount
        END
    ) OVER (
        PARTITION BY wt.wallet_id
        ORDER BY
            wt.created_at,
            wt.transaction_id
    ) AS running_balance

FROM wallet_transactions wt

JOIN wallets w
    ON wt.wallet_id = w.wallet_id

JOIN customers c
    ON w.customer_id = c.customer_id

WHERE wt.transaction_status = 'SUCCESS'

ORDER BY
    wt.wallet_id,
    wt.created_at,
    wt.transaction_id;


-- LAG fraud detection data

WITH transaction_analysis AS (

    SELECT
        transaction_id,
        wallet_id,
        transaction_type,
        amount,
        created_at,

        LAG(amount) OVER (
            PARTITION BY wallet_id
            ORDER BY created_at, transaction_id
        ) AS previous_amount,

        LAG(created_at) OVER (
            PARTITION BY wallet_id
            ORDER BY created_at, transaction_id
        ) AS previous_transaction_time

    FROM wallet_transactions

    WHERE transaction_status = 'SUCCESS'
)

SELECT
    transaction_id,
    wallet_id,
    transaction_type,
    amount,
    previous_amount,
    created_at,
    previous_transaction_time,

    CASE
        WHEN
            previous_transaction_time IS NOT NULL
            AND created_at
                - previous_transaction_time
                <= INTERVAL '2 minutes'
            AND transaction_type IN (
                'WITHDRAWAL',
                'TRANSFER_OUT'
            )
        THEN 'RAPID TRANSACTION'

        WHEN amount >= 5000
        THEN 'LARGE TRANSACTION'

        ELSE 'NORMAL'
    END AS fraud_flag

FROM transaction_analysis

ORDER BY
    wallet_id,
    created_at;


-- Suspicious transactions only

WITH transaction_analysis AS (

    SELECT
        transaction_id,
        wallet_id,
        transaction_type,
        amount,
        created_at,

        LAG(created_at) OVER (
            PARTITION BY wallet_id
            ORDER BY created_at, transaction_id
        ) AS previous_transaction_time

    FROM wallet_transactions

    WHERE transaction_status = 'SUCCESS'
),

fraud_check AS (

    SELECT
        *,

        CASE
            WHEN
                previous_transaction_time IS NOT NULL
                AND created_at
                    - previous_transaction_time
                    <= INTERVAL '2 minutes'
                AND transaction_type IN (
                    'WITHDRAWAL',
                    'TRANSFER_OUT'
                )
            THEN 'RAPID TRANSACTION'

            WHEN amount >= 5000
            THEN 'LARGE TRANSACTION'

            ELSE 'NORMAL'
        END AS fraud_flag

    FROM transaction_analysis
)

SELECT *
FROM fraud_check
WHERE fraud_flag <> 'NORMAL'
ORDER BY created_at;


-- Stored procedure for fund transfer

CREATE OR REPLACE PROCEDURE transfer_funds(
    p_from_wallet BIGINT,
    p_to_wallet BIGINT,
    p_amount NUMERIC(14, 2)
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_from_balance NUMERIC(14, 2);
    v_from_status VARCHAR(20);
    v_to_status VARCHAR(20);

BEGIN

    IF p_amount <= 0 THEN
        RAISE EXCEPTION
            'Transfer amount must be greater than zero';
    END IF;

    IF p_from_wallet = p_to_wallet THEN
        RAISE EXCEPTION
            'Source and destination wallets cannot be the same';
    END IF;


    SELECT
        current_balance,
        status
    INTO
        v_from_balance,
        v_from_status
    FROM wallets
    WHERE wallet_id = p_from_wallet
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Source wallet % does not exist',
            p_from_wallet;
    END IF;


    SELECT status
    INTO v_to_status
    FROM wallets
    WHERE wallet_id = p_to_wallet
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Destination wallet % does not exist',
            p_to_wallet;
    END IF;


    IF v_from_status <> 'ACTIVE' THEN
        RAISE EXCEPTION
            'Source wallet is not active';
    END IF;


    IF v_to_status <> 'ACTIVE' THEN
        RAISE EXCEPTION
            'Destination wallet is not active';
    END IF;


    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION
            'Insufficient balance';
    END IF;


    UPDATE wallets
    SET current_balance =
        current_balance - p_amount
    WHERE wallet_id = p_from_wallet;


    UPDATE wallets
    SET current_balance =
        current_balance + p_amount
    WHERE wallet_id = p_to_wallet;


    INSERT INTO wallet_transactions (
        wallet_id,
        related_wallet_id,
        transaction_type,
        amount,
        description
    )
    VALUES (
        p_from_wallet,
        p_to_wallet,
        'TRANSFER_OUT',
        p_amount,
        'Wallet fund transfer'
    );


    INSERT INTO wallet_transactions (
        wallet_id,
        related_wallet_id,
        transaction_type,
        amount,
        description
    )
    VALUES (
        p_to_wallet,
        p_from_wallet,
        'TRANSFER_IN',
        p_amount,
        'Wallet fund transfer'
    );

END;

$$;


-- Wallet summary

SELECT
    w.wallet_id,
    w.wallet_number,

    c.first_name
        || ' '
        || c.last_name
        AS customer_name,

    w.current_balance,
    w.currency,
    w.status

FROM wallets w

JOIN customers c
    ON w.customer_id = c.customer_id

ORDER BY w.wallet_id;


-- Transaction ranking

SELECT
    wallet_id,
    transaction_id,
    transaction_type,
    amount,

    ROW_NUMBER() OVER (
        PARTITION BY wallet_id
        ORDER BY amount DESC
    ) AS row_number,

    RANK() OVER (
        PARTITION BY wallet_id
        ORDER BY amount DESC
    ) AS amount_rank,

    DENSE_RANK() OVER (
        PARTITION BY wallet_id
        ORDER BY amount DESC
    ) AS dense_amount_rank

FROM wallet_transactions

WHERE transaction_status = 'SUCCESS'

ORDER BY wallet_id, amount DESC;


-- Previous and next transaction

SELECT
    transaction_id,
    wallet_id,
    amount,

    LAG(amount) OVER (
        PARTITION BY wallet_id
        ORDER BY created_at, transaction_id
    ) AS previous_amount,

    LEAD(amount) OVER (
        PARTITION BY wallet_id
        ORDER BY created_at, transaction_id
    ) AS next_amount

FROM wallet_transactions

ORDER BY
    wallet_id,
    created_at,
    transaction_id;


CREATE INDEX idx_wallet_transactions_wallet
ON wallet_transactions(wallet_id);

CREATE INDEX idx_wallet_transactions_created
ON wallet_transactions(created_at);

CREATE INDEX idx_wallet_transactions_type
ON wallet_transactions(transaction_type);