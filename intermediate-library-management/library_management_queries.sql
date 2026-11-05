CREATE TABLE books (
    book_id BIGSERIAL PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    total_copies INTEGER NOT NULL DEFAULT 1,
    available_copies INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT chk_total_copies
        CHECK (total_copies > 0),

    CONSTRAINT chk_available_copies
        CHECK (
            available_copies >= 0
            AND available_copies <= total_copies
        )
);


CREATE TABLE members (
    member_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    phone VARCHAR(20),
    membership_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT chk_member_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'SUSPENDED'
            )
        )
);


CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    book_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'ISSUED',
    fine_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id),

    CONSTRAINT fk_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    CONSTRAINT chk_transaction_status
        CHECK (
            status IN (
                'ISSUED',
                'RETURNED',
                'OVERDUE'
            )
        ),

    CONSTRAINT chk_dates
        CHECK (
            due_date >= issue_date
            AND (
                return_date IS NULL
                OR return_date >= issue_date
            )
        ),

    CONSTRAINT chk_fine
        CHECK (fine_amount >= 0)
);


INSERT INTO books (
    isbn,
    title,
    author,
    category,
    total_copies,
    available_copies
)
VALUES
(
    '9780000000001',
    'SQL Fundamentals',
    'Thanay R',
    'Database',
    3,
    3
),
(
    '9780000000002',
    'Java Programming',
    'Manoj K',
    'Programming',
    2,
    2
),
(
    '9780000000003',
    'Web Development',
    'Vinay K',
    'Web',
    4,
    4
),
(
    '9780000000004',
    'Data Structures',
    'Simah D',
    'Computer Science',
    2,
    2
),
(
    '9780000000005',
    'Cloud Computing',
    'Bhav P',
    'Cloud',
    3,
    3
);


INSERT INTO members (
    first_name,
    last_name,
    email,
    phone
)
VALUES
(
    'Raj',
    'K',
    'raj.k@example.com',
    '5553001001'
),
(
    'Rani',
    'M',
    'rani.m@example.com',
    '5553001002'
),
(
    'Thomas',
    'V',
    'thomas.v@example.com',
    '5553001003'
),
(
    'Mahi',
    'C',
    'mahi.c@example.com',
    '5553001004'
);


INSERT INTO transactions (
    book_id,
    member_id,
    issue_date,
    due_date,
    return_date,
    status,
    fine_amount
)
VALUES
(
    1,
    1,
    CURRENT_DATE - 30,
    CURRENT_DATE - 16,
    CURRENT_DATE - 14,
    'RETURNED',
    4.00
),
(
    2,
    1,
    CURRENT_DATE - 20,
    CURRENT_DATE - 6,
    CURRENT_DATE - 6,
    'RETURNED',
    0.00
),
(
    3,
    2,
    CURRENT_DATE - 18,
    CURRENT_DATE - 4,
    NULL,
    'OVERDUE',
    0.00
),
(
    1,
    3,
    CURRENT_DATE - 5,
    CURRENT_DATE + 9,
    NULL,
    'ISSUED',
    0.00
),
(
    4,
    2,
    CURRENT_DATE - 3,
    CURRENT_DATE + 11,
    NULL,
    'ISSUED',
    0.00
);


UPDATE books
SET available_copies = available_copies - 1
WHERE book_id IN (1, 3, 4);


-- ISSUE BOOK

INSERT INTO transactions (
    book_id,
    member_id,
    issue_date,
    due_date,
    status
)
SELECT
    5,
    4,
    CURRENT_DATE,
    CURRENT_DATE + 14,
    'ISSUED'
WHERE EXISTS (
    SELECT 1
    FROM books
    WHERE book_id = 5
      AND available_copies > 0
)
AND EXISTS (
    SELECT 1
    FROM members
    WHERE member_id = 4
      AND status = 'ACTIVE'
);


UPDATE books
SET available_copies = available_copies - 1
WHERE book_id = 5
  AND available_copies > 0;


-- CURRENTLY ISSUED BOOKS

SELECT
    t.transaction_id,
    b.title,
    b.author,
    m.first_name || ' ' || m.last_name
        AS member_name,
    t.issue_date,
    t.due_date,
    t.status
FROM transactions t
JOIN books b
    ON t.book_id = b.book_id
JOIN members m
    ON t.member_id = m.member_id
WHERE t.status IN ('ISSUED', 'OVERDUE')
ORDER BY t.due_date;


-- RETURN BOOK

UPDATE transactions
SET
    return_date = CURRENT_DATE,
    status = 'RETURNED',
    fine_amount =
        CASE
            WHEN CURRENT_DATE > due_date
            THEN (CURRENT_DATE - due_date) * 2.00
            ELSE 0
        END
WHERE transaction_id = 4
  AND return_date IS NULL;


UPDATE books
SET available_copies = available_copies + 1
WHERE book_id = (
    SELECT book_id
    FROM transactions
    WHERE transaction_id = 4
);


-- FINE REPORT

SELECT
    t.transaction_id,

    m.first_name || ' ' || m.last_name
        AS member_name,

    b.title,

    t.issue_date,

    t.due_date,

    t.return_date,

    CASE
        WHEN t.return_date IS NOT NULL
             AND t.return_date > t.due_date
        THEN
            (t.return_date - t.due_date) * 2.00

        WHEN t.return_date IS NULL
             AND CURRENT_DATE > t.due_date
        THEN
            (CURRENT_DATE - t.due_date) * 2.00

        ELSE 0
    END AS calculated_fine

FROM transactions t

JOIN members m
    ON t.member_id = m.member_id

JOIN books b
    ON t.book_id = b.book_id

ORDER BY calculated_fine DESC;


-- OVERDUE BOOKS

SELECT
    t.transaction_id,
    m.first_name || ' ' || m.last_name
        AS member_name,
    b.title,
    t.due_date,
    CURRENT_DATE - t.due_date
        AS days_overdue,
    (CURRENT_DATE - t.due_date) * 2.00
        AS current_fine

FROM transactions t

JOIN members m
    ON t.member_id = m.member_id

JOIN books b
    ON t.book_id = b.book_id

WHERE t.return_date IS NULL
  AND CURRENT_DATE > t.due_date

ORDER BY days_overdue DESC;


-- MEMBER-WISE BOOK HISTORY

SELECT
    m.member_id,

    m.first_name || ' ' || m.last_name
        AS member_name,

    b.title,

    b.author,

    t.issue_date,

    t.due_date,

    t.return_date,

    t.status,

    t.fine_amount

FROM members m

LEFT JOIN transactions t
    ON m.member_id = t.member_id

LEFT JOIN books b
    ON t.book_id = b.book_id

ORDER BY
    m.member_id,
    t.issue_date DESC;


-- HISTORY FOR ONE MEMBER

SELECT
    b.title,
    b.author,
    t.issue_date,
    t.due_date,
    t.return_date,
    t.status

FROM transactions t

JOIN books b
    ON t.book_id = b.book_id

WHERE t.member_id = 1

ORDER BY t.issue_date DESC;


-- BOOK BORROWING HISTORY

SELECT
    b.title,

    m.first_name || ' ' || m.last_name
        AS member_name,

    t.issue_date,
    t.return_date,
    t.status

FROM books b

LEFT JOIN transactions t
    ON b.book_id = t.book_id

LEFT JOIN members m
    ON t.member_id = m.member_id

ORDER BY
    b.title,
    t.issue_date DESC;


-- MOST BORROWED BOOKS

SELECT
    b.book_id,
    b.title,
    COUNT(t.transaction_id)
        AS times_borrowed

FROM books b

LEFT JOIN transactions t
    ON b.book_id = t.book_id

GROUP BY
    b.book_id,
    b.title

ORDER BY times_borrowed DESC;


-- MEMBERS WITH MORE THAN ONE TRANSACTION

SELECT
    m.member_id,

    m.first_name || ' ' || m.last_name
        AS member_name,

    COUNT(t.transaction_id)
        AS total_transactions

FROM members m

JOIN transactions t
    ON m.member_id = t.member_id

GROUP BY
    m.member_id,
    m.first_name,
    m.last_name

HAVING COUNT(t.transaction_id) > 1

ORDER BY total_transactions DESC;


-- SUBQUERY: MEMBERS WHO BORROWED DATABASE BOOKS

SELECT
    member_id,
    first_name,
    last_name

FROM members

WHERE member_id IN (

    SELECT t.member_id

    FROM transactions t

    JOIN books b
        ON t.book_id = b.book_id

    WHERE b.category = 'Database'
);


-- CORRELATED SUBQUERY

SELECT
    m.member_id,
    m.first_name,
    m.last_name

FROM members m

WHERE EXISTS (

    SELECT 1

    FROM transactions t

    WHERE t.member_id = m.member_id
      AND t.return_date IS NULL
);


-- CASE REPORT

SELECT
    title,
    available_copies,

    CASE
        WHEN available_copies = 0
            THEN 'NOT AVAILABLE'

        WHEN available_copies <= 1
            THEN 'LOW STOCK'

        ELSE 'AVAILABLE'
    END AS availability

FROM books

ORDER BY title;


-- COALESCE

SELECT
    transaction_id,
    return_date,
    COALESCE(
        return_date::TEXT,
        'Not Returned'
    ) AS return_status

FROM transactions;


-- VIEW

CREATE VIEW active_loans AS

SELECT
    t.transaction_id,
    b.title,

    m.first_name || ' ' || m.last_name
        AS member_name,

    t.issue_date,
    t.due_date,

    CASE
        WHEN CURRENT_DATE > t.due_date
            THEN 'OVERDUE'
        ELSE 'ISSUED'
    END AS loan_status

FROM transactions t

JOIN books b
    ON t.book_id = b.book_id

JOIN members m
    ON t.member_id = m.member_id

WHERE t.return_date IS NULL;


SELECT *
FROM active_loans
ORDER BY due_date;


-- INDEXES

CREATE INDEX idx_transactions_member
ON transactions(member_id);

CREATE INDEX idx_transactions_book
ON transactions(book_id);

CREATE INDEX idx_transactions_due_date
ON transactions(due_date);

CREATE INDEX idx_books_category
ON books(category);


-- STRING CLEANING

SELECT
    member_id,
    TRIM(first_name) AS first_name,
    TRIM(last_name) AS last_name,
    LOWER(TRIM(email)) AS clean_email
FROM members;


-- TOTAL FINES BY MEMBER

SELECT
    m.member_id,

    m.first_name || ' ' || m.last_name
        AS member_name,

    COUNT(t.transaction_id)
        AS total_transactions,

    COALESCE(
        SUM(
            CASE
                WHEN t.return_date IS NOT NULL
                     AND t.return_date > t.due_date
                THEN
                    (t.return_date - t.due_date) * 2.00

                WHEN t.return_date IS NULL
                     AND CURRENT_DATE > t.due_date
                THEN
                    (CURRENT_DATE - t.due_date) * 2.00

                ELSE 0
            END
        ),
        0
    ) AS total_fine

FROM members m

LEFT JOIN transactions t
    ON m.member_id = t.member_id

GROUP BY
    m.member_id,
    m.first_name,
    m.last_name

ORDER BY total_fine DESC;