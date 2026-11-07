CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE events (
    event_id BIGSERIAL PRIMARY KEY,
    event_name VARCHAR(200) NOT NULL,
    venue VARCHAR(200) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    CONSTRAINT chk_event_status
        CHECK (
            status IN (
                'OPEN',
                'CLOSED',
                'CANCELLED'
            )
        )
);


CREATE TABLE seats (
    seat_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL,
    seat_number VARCHAR(20) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',

    CONSTRAINT fk_seat_event
        FOREIGN KEY (event_id)
        REFERENCES events(event_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_seat_price
        CHECK (price > 0),

    CONSTRAINT chk_seat_status
        CHECK (
            status IN (
                'AVAILABLE',
                'BOOKED'
            )
        ),

    CONSTRAINT uq_event_seat
        UNIQUE (
            event_id,
            seat_number
        )
);


CREATE TABLE bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    booking_status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED',
    amount NUMERIC(10, 2) NOT NULL,
    booked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,

    CONSTRAINT fk_booking_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_booking_event
        FOREIGN KEY (event_id)
        REFERENCES events(event_id),

    CONSTRAINT fk_booking_seat
        FOREIGN KEY (seat_id)
        REFERENCES seats(seat_id),

    CONSTRAINT chk_booking_status
        CHECK (
            booking_status IN (
                'CONFIRMED',
                'CANCELLED'
            )
        ),

    CONSTRAINT chk_booking_amount
        CHECK (amount > 0)
);


INSERT INTO users (
    first_name,
    last_name,
    email
)
VALUES
(
    'Thanay',
    'R',
    'thanay.r@example.com'
),
(
    'Manoj',
    'K',
    'manoj.k@example.com'
),
(
    'Vinay',
    'K',
    'vinay.k@example.com'
),
(
    'Simha',
    'D',
    'simha.d@example.com'
);


INSERT INTO events (
    event_name,
    venue,
    event_date
)
VALUES (
    'Tech Conference 2027',
    'Downtown Convention Center',
    '2027-03-20 10:00:00'
);


INSERT INTO seats (
    event_id,
    seat_number,
    price
)
SELECT
    1,
    'A' || seat_no,
    CASE
        WHEN seat_no <= 5
            THEN 150.00
        WHEN seat_no <= 10
            THEN 120.00
        ELSE 90.00
    END
FROM generate_series(
    1,
    20
) AS seat_no;


-- Prevent more than one active booking for the same seat

CREATE UNIQUE INDEX uq_confirmed_booking_seat
ON bookings(seat_id)
WHERE booking_status = 'CONFIRMED';


CREATE INDEX idx_seats_event_status
ON seats(
    event_id,
    status
);


CREATE INDEX idx_bookings_user
ON bookings(user_id);


CREATE INDEX idx_bookings_event
ON bookings(event_id);


CREATE INDEX idx_bookings_booked_at
ON bookings(booked_at);


-- Safe booking procedure

CREATE OR REPLACE PROCEDURE book_ticket(
    p_user_id BIGINT,
    p_event_id BIGINT,
    p_seat_id BIGINT
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_seat_status VARCHAR(20);
    v_price NUMERIC(10, 2);
    v_seat_event BIGINT;
    v_event_status VARCHAR(20);

BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION
            'User % does not exist',
            p_user_id;
    END IF;


    SELECT status
    INTO v_event_status
    FROM events
    WHERE event_id = p_event_id;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Event % does not exist',
            p_event_id;
    END IF;


    IF v_event_status <> 'OPEN' THEN
        RAISE EXCEPTION
            'Event is not open for booking';
    END IF;


    SELECT
        status,
        price,
        event_id
    INTO
        v_seat_status,
        v_price,
        v_seat_event
    FROM seats
    WHERE seat_id = p_seat_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Seat % does not exist',
            p_seat_id;
    END IF;


    IF v_seat_event <> p_event_id THEN
        RAISE EXCEPTION
            'Seat does not belong to this event';
    END IF;


    IF v_seat_status <> 'AVAILABLE' THEN
        RAISE EXCEPTION
            'Seat is already booked';
    END IF;


    UPDATE seats
    SET status = 'BOOKED'
    WHERE seat_id = p_seat_id;


    INSERT INTO bookings (
        user_id,
        event_id,
        seat_id,
        amount
    )
    VALUES (
        p_user_id,
        p_event_id,
        p_seat_id,
        v_price
    );

END;

$$;


-- Cancel booking procedure

CREATE OR REPLACE PROCEDURE cancel_booking(
    p_booking_id BIGINT
)

LANGUAGE plpgsql

AS $$

DECLARE
    v_seat_id BIGINT;
    v_booking_status VARCHAR(20);

BEGIN

    SELECT
        seat_id,
        booking_status
    INTO
        v_seat_id,
        v_booking_status
    FROM bookings
    WHERE booking_id = p_booking_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Booking % does not exist',
            p_booking_id;
    END IF;


    IF v_booking_status <> 'CONFIRMED' THEN
        RAISE EXCEPTION
            'Booking is already cancelled';
    END IF;


    UPDATE bookings
    SET
        booking_status = 'CANCELLED',
        cancelled_at = CURRENT_TIMESTAMP
    WHERE booking_id = p_booking_id;


    UPDATE seats
    SET status = 'AVAILABLE'
    WHERE seat_id = v_seat_id;

END;

$$;


-- Available seats

SELECT
    seat_id,
    seat_number,
    price
FROM seats
WHERE event_id = 1
  AND status = 'AVAILABLE'
ORDER BY seat_id;


-- Booking report

SELECT
    b.booking_id,

    u.first_name
        || ' '
        || u.last_name
        AS customer_name,

    e.event_name,

    s.seat_number,

    b.amount,

    b.booking_status,

    b.booked_at

FROM bookings b

JOIN users u
    ON b.user_id =
       u.user_id

JOIN events e
    ON b.event_id =
       e.event_id

JOIN seats s
    ON b.seat_id =
       s.seat_id

ORDER BY b.booked_at DESC;


-- Event summary

SELECT
    e.event_id,
    e.event_name,

    COUNT(s.seat_id)
        AS total_seats,

    COUNT(*) FILTER (
        WHERE s.status = 'AVAILABLE'
    ) AS available_seats,

    COUNT(*) FILTER (
        WHERE s.status = 'BOOKED'
    ) AS booked_seats

FROM events e

JOIN seats s
    ON e.event_id =
       s.event_id

GROUP BY
    e.event_id,
    e.event_name;


-- Revenue report

SELECT
    e.event_name,

    COUNT(b.booking_id)
        AS confirmed_bookings,

    COALESCE(
        SUM(b.amount),
        0
    ) AS total_revenue

FROM events e

LEFT JOIN bookings b
    ON e.event_id =
       b.event_id
    AND b.booking_status =
        'CONFIRMED'

GROUP BY
    e.event_id,
    e.event_name;


-- Execution plan example

EXPLAIN
SELECT
    seat_id,
    seat_number,
    price
FROM seats
WHERE event_id = 1
  AND status = 'AVAILABLE';
