-- ============================================
-- Student Management System Database
-- ============================================


-- ============================================
-- 1. STUDENTS TABLE
-- ============================================

CREATE TABLE students (
    student_id BIGSERIAL PRIMARY KEY,

    first_name VARCHAR(100)
        NOT NULL,

    last_name VARCHAR(100)
        NOT NULL,

    email VARCHAR(200)
        NOT NULL
        UNIQUE,

    phone VARCHAR(20)
        UNIQUE,

    date_of_birth DATE
        NOT NULL,

    city VARCHAR(100),

    enrollment_date DATE
        NOT NULL
        DEFAULT CURRENT_DATE,

    status VARCHAR(20)
        NOT NULL
        DEFAULT 'ACTIVE',

    CONSTRAINT chk_student_status
        CHECK (
            status IN (
                'ACTIVE',
                'INACTIVE',
                'GRADUATED'
            )
        )
);


-- ============================================
-- 2. COURSES TABLE
-- ============================================

CREATE TABLE courses (
    course_id BIGSERIAL PRIMARY KEY,

    course_code VARCHAR(20)
        NOT NULL
        UNIQUE,

    course_name VARCHAR(150)
        NOT NULL,

    department VARCHAR(100)
        NOT NULL,

    credits INTEGER
        NOT NULL,

    fee NUMERIC(10, 2)
        NOT NULL,

    CONSTRAINT chk_course_credits
        CHECK (
            credits BETWEEN 1 AND 6
        ),

    CONSTRAINT chk_course_fee
        CHECK (
            fee >= 0
        )
);


-- ============================================
-- 3. ENROLLMENTS TABLE
-- ============================================

CREATE TABLE enrollments (
    enrollment_id BIGSERIAL PRIMARY KEY,

    student_id BIGINT
        NOT NULL,

    course_id BIGINT
        NOT NULL,

    semester VARCHAR(20)
        NOT NULL,

    enrollment_year INTEGER
        NOT NULL,

    marks NUMERIC(5, 2),

    grade VARCHAR(2),

    enrollment_status VARCHAR(20)
        NOT NULL
        DEFAULT 'ENROLLED',

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_semester
        CHECK (
            semester IN (
                'SPRING',
                'SUMMER',
                'FALL'
            )
        ),

    CONSTRAINT chk_enrollment_year
        CHECK (
            enrollment_year BETWEEN 2000 AND 2100
        ),

    CONSTRAINT chk_marks
        CHECK (
            marks IS NULL
            OR marks BETWEEN 0 AND 100
        ),

    CONSTRAINT chk_grade
        CHECK (
            grade IS NULL
            OR grade IN (
                'A',
                'B',
                'C',
                'D',
                'F'
            )
        ),

    CONSTRAINT chk_enrollment_status
        CHECK (
            enrollment_status IN (
                'ENROLLED',
                'COMPLETED',
                'DROPPED'
            )
        ),

    CONSTRAINT uq_student_course_semester
        UNIQUE (
            student_id,
            course_id,
            semester,
            enrollment_year
        )
);


-- ============================================
-- 4. SAMPLE STUDENTS
-- ============================================

INSERT INTO students (
    first_name,
    last_name,
    email,
    phone,
    date_of_birth,
    city
)
VALUES
(
    'Thanay',
    'R',
    'thanay.r@example.com',
    '5551001221',
    '2001-05-15',
    'Kansas City'
),
(
    'manoj',
    'k',
    'manoj.k@example.com',
    '5551001232',
    '2000-09-22',
    'Chicago'
),
(
    'Simha',
    'D',
    'simha.d@example.com',
    '5551001233',
    '2002-02-10',
    'Dallas'
),
(
    'Vinay',
    'K',
    'vinay.k@example.com',
    '5551001244',
    '2001-12-01',
    'Atlanta'
),
(
    'Bhav',
    'P',
    'bhav.p@example.com',
    '5551001255',
    '1999-07-18',
    'Newyork'
);


-- ============================================
-- 5. SAMPLE COURSES
-- ============================================

INSERT INTO courses (
    course_code,
    course_name,
    department,
    credits,
    fee
)
VALUES
(
    'CS101',
    'Introduction to Programming',
    'Computer Science',
    3,
    1200.00
),
(
    'CS201',
    'Database Systems',
    'Computer Science',
    4,
    1500.00
),
(
    'MATH101',
    'College Mathematics',
    'Mathematics',
    3,
    1000.00
),
(
    'BUS101',
    'Business Fundamentals',
    'Business',
    3,
    1100.00
);


-- ============================================
-- 6. SAMPLE ENROLLMENTS
-- ============================================

INSERT INTO enrollments (
    student_id,
    course_id,
    semester,
    enrollment_year,
    marks,
    grade,
    enrollment_status
)
VALUES
(
    1,
    1,
    'FALL',
    2026,
    88,
    'A',
    'COMPLETED'
),
(
    1,
    2,
    'FALL',
    2026,
    79,
    'B',
    'COMPLETED'
),
(
    2,
    1,
    'FALL',
    2026,
    92,
    'A',
    'COMPLETED'
),
(
    2,
    3,
    'FALL',
    2026,
    84,
    'A',
    'COMPLETED'
),
(
    3,
    2,
    'FALL',
    2026,
    72,
    'C',
    'COMPLETED'
),
(
    4,
    1,
    'FALL',
    2026,
    81,
    'A',
    'COMPLETED'
),
(
    4,
    4,
    'FALL',
    2026,
    76,
    'B',
    'COMPLETED'
),
(
    5,
    3,
    'FALL',
    2026,
    68,
    'D',
    'COMPLETED'
);


-- ============================================
-- BASIC SELECT QUERIES
-- ============================================


-- 1. View all students

SELECT *
FROM students
ORDER BY student_id;


-- 2. View all courses

SELECT *
FROM courses
ORDER BY course_id;


-- 3. View all enrollments

SELECT *
FROM enrollments
ORDER BY enrollment_id;


-- ============================================
-- SEARCH QUERIES
-- ============================================


-- 4. Search students by first name

SELECT *
FROM students
WHERE first_name ILIKE '%john%';


-- 5. Search students by city

SELECT *
FROM students
WHERE city ILIKE '%kansas%';


-- 6. Search courses containing the word Database

SELECT *
FROM courses
WHERE course_name ILIKE '%database%';


-- ============================================
-- FILTER QUERIES
-- ============================================


-- 7. Find active students

SELECT
    student_id,
    first_name,
    last_name,
    email,
    status
FROM students
WHERE status = 'ACTIVE'
ORDER BY last_name;


-- 8. Find students from Kansas City

SELECT
    student_id,
    first_name,
    last_name,
    city
FROM students
WHERE city = 'Kansas City';


-- 9. Find courses with 3 or more credits

SELECT
    course_code,
    course_name,
    credits
FROM courses
WHERE credits >= 3
ORDER BY credits DESC;


-- 10. Find courses with fee between 1000 and 1300

SELECT
    course_code,
    course_name,
    fee
FROM courses
WHERE fee BETWEEN 1000 AND 1300
ORDER BY fee;


-- 11. Find Computer Science or Mathematics courses

SELECT
    course_code,
    course_name,
    department
FROM courses
WHERE department IN (
    'Computer Science',
    'Mathematics'
);


-- ============================================
-- AGGREGATE QUERIES
-- ============================================


-- 12. Total number of students

SELECT
    COUNT(*) AS total_students
FROM students;


-- 13. Total number of courses

SELECT
    COUNT(*) AS total_courses
FROM courses;


-- 14. Average marks

SELECT
    ROUND(
        AVG(marks),
        2
    ) AS average_marks
FROM enrollments
WHERE marks IS NOT NULL;


-- 15. Highest marks

SELECT
    MAX(marks) AS highest_marks
FROM enrollments;


-- 16. Lowest marks

SELECT
    MIN(marks) AS lowest_marks
FROM enrollments;


-- 17. Total course fees

SELECT
    SUM(fee) AS total_course_fees
FROM courses;


-- ============================================
-- GROUP BY QUERIES
-- ============================================


-- 18. Number of students by city

SELECT
    city,
    COUNT(*) AS student_count
FROM students
GROUP BY city
ORDER BY student_count DESC;


-- 19. Number of courses by department

SELECT
    department,
    COUNT(*) AS course_count
FROM courses
GROUP BY department
ORDER BY department;


-- 20. Average marks by course

SELECT
    course_id,
    ROUND(
        AVG(marks),
        2
    ) AS average_marks
FROM enrollments
WHERE marks IS NOT NULL
GROUP BY course_id
ORDER BY course_id;


-- ============================================
-- HAVING
-- ============================================


-- 21. Courses with average marks above 75

SELECT
    course_id,
    ROUND(
        AVG(marks),
        2
    ) AS average_marks
FROM enrollments
WHERE marks IS NOT NULL
GROUP BY course_id
HAVING AVG(marks) > 75
ORDER BY average_marks DESC;


-- ============================================
-- BASIC STUDENT REPORT
-- ============================================


-- 22. Student course report

SELECT
    s.student_id,

    s.first_name
        || ' '
        || s.last_name
        AS student_name,

    c.course_code,

    c.course_name,

    e.semester,

    e.enrollment_year,

    e.marks,

    e.grade,

    e.enrollment_status

FROM enrollments e

JOIN students s
    ON e.student_id =
       s.student_id

JOIN courses c
    ON e.course_id =
       c.course_id

ORDER BY
    s.student_id,
    c.course_code;


-- ============================================
-- STUDENT PERFORMANCE REPORT
-- ============================================


-- 23. Average marks for each student

SELECT
    s.student_id,

    s.first_name
        || ' '
        || s.last_name
        AS student_name,

    ROUND(
        AVG(e.marks),
        2
    ) AS average_marks

FROM students s

JOIN enrollments e
    ON s.student_id =
       e.student_id

WHERE e.marks IS NOT NULL

GROUP BY
    s.student_id,
    s.first_name,
    s.last_name

ORDER BY average_marks DESC;


-- ============================================
-- COURSE ENROLLMENT REPORT
-- ============================================


-- 24. Number of students in each course

SELECT
    c.course_code,
    c.course_name,
    

    COUNT(
        e.student_id
    ) AS total_students

FROM courses c

LEFT JOIN enrollments e
    ON c.course_id =
       e.course_id

GROUP BY
    c.course_id,
    c.course_code,
    c.course_name

ORDER BY total_students DESC;


-- ============================================
-- UPDATE EXAMPLE
-- ============================================


-- Example:
-- Change a student's city

UPDATE students
SET city = 'St. Louis'
WHERE student_id = 5;


-- ============================================
-- DELETE EXAMPLE
-- ============================================

-- DELETE FROM enrollments
-- WHERE enrollment_id = 8;