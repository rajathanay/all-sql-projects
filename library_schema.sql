-- Library Database Setup


-- BOOKS

CREATE TABLE books (
    book_id BIGSERIAL PRIMARY KEY,

    isbn VARCHAR(20)
        NOT NULL
        UNIQUE,

    title VARCHAR(200)
        NOT NULL,

    author VARCHAR(150)
        NOT NULL,

    category VARCHAR(100),

    published_year SMALLINT,

    total_copies INTEGER
        NOT NULL
        DEFAULT 1,

    available_copies INTEGER
        NOT NULL
        DEFAULT 1,

    created_at TIMESTAMP
        NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_published_year
        CHECK (
            published_year IS NULL
            OR published_year BETWEEN 1000 AND 2100
        ),

    CONSTRAINT chk_total_copies
        CHECK (
            total_copies > 0
        ),

    CONSTRAINT chk_available_copies
        CHECK (
            available_copies >= 0
            AND available_copies <= total_copies
        )
);


-- MEMBERS

CREATE TABLE members (
    member_id BIGSERIAL PRIMARY KEY,

    first_name VARCHAR(100)
        NOT NULL,

    last_name VARCHAR(100)
        NOT NULL,

    email VARCHAR(200)
        NOT NULL
        UNIQUE,

    phone VARCHAR(20)
        UNIQUE,

    membership_date DATE
        NOT NULL
        DEFAULT CURRENT_DATE,

    status VARCHAR(20)
        NOT NULL
        DEFAULT 'ACTIVE',

    CONSTRAINT chk_member_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'SUSPENDED'
            )
        )
);


-- TRANSACTIONS

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,

    book_id BIGINT
        NOT NULL,

    member_id BIGINT
        NOT NULL,

    issue_date DATE
        NOT NULL
        DEFAULT CURRENT_DATE,

    due_date DATE
        NOT NULL,

    return_date DATE,

    status VARCHAR(20)
        NOT NULL
        DEFAULT 'ISSUED',

    fine_amount NUMERIC(10, 2)
        NOT NULL
        DEFAULT 0.00,

    CONSTRAINT fk_transaction_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_transaction_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_transaction_status
        CHECK (
            status IN (
                'ISSUED',
                'RETURNED',
                'OVERDUE'
            )
        ),

    CONSTRAINT chk_due_date
        CHECK (
            due_date >= issue_date
        ),

    CONSTRAINT chk_return_date
        CHECK (
            return_date IS NULL
            OR return_date >= issue_date
        ),

    CONSTRAINT chk_fine_amount
        CHECK (
            fine_amount >= 0
        )
);