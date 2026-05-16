
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email VARCHAR(100) UNIQUE,
    user_role VARCHAR(20) CHECK (user_role IN ('admin', 'employee', 'technical_staff')) DEFAULT 'employee'
);


CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(50),
    release_date DATE,
    budget DECIMAL(15, 2),
    production_status VARCHAR(50) DEFAULT 'Pre-production'
);


CREATE TABLE crew (
    crew_id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE SET NULL,
    full_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(50) 
);


CREATE TABLE cast_members (
    cast_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10),
    contact_info TEXT
);


CREATE TABLE movie_cast (
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
    cast_id INTEGER REFERENCES cast_members(cast_id) ON DELETE CASCADE,
    role_name VARCHAR(100),
    amount DECIMAL(15, 2), 
    PRIMARY KEY (movie_id, cast_id)
);

CREATE TABLE production_expenses (
    expense_id SERIAL PRIMARY KEY,
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
    description TEXT,
    amount DECIMAL(15, 2) NOT NULL,
    expense_date DATE DEFAULT CURRENT_DATE
);


INSERT INTO users (username, password_hash, email, user_role) VALUES 
('admin_melik', 'ps123', 'admin@film.com', 'admin'),
('editor_helin', 'ps1234', 'helin@film.com', 'employee'),
('cameraman_emirkan', 'ps12345', 'can@film.com', 'technical_staff');


INSERT INTO movies (title, genre, budget, production_status) VALUES 
('Interstellar 2', 'Sci-Fi', 150000000, 'Filming'),
('The Great Gatsby', 'Drama', 100000000, 'Released'),
('Inception 2', 'Action', 160000000, 'Pre-production');

INSERT INTO crew (user_id, movie_id, full_name, specialization) VALUES 
(3, 1, 'Can Yılmaz', 'Director of Photography'),
(2, 2, 'Ali Demir', 'Film Editor');


INSERT INTO cast_members (full_name, gender, contact_info) VALUES 
('Leonardo DiCaprio', 'Male', 'leo@hollywood.com'),
('Anne Hathaway', 'Female', 'anne@hollywood.com');


INSERT INTO movie_cast (movie_id, cast_id, role_name, amount) VALUES 
(1, 2, 'Brand', 5000000),
(2, 1, 'Jay Gatsby', 20000000);

INSERT INTO production_expenses (movie_id, description, amount, expense_date) VALUES 
(1, 'Visual Effects (VFX)', 2000000, '2026-05-01'),
(1, 'Catering', 50000, '2026-05-05'),
(2, 'Costumes', 300000, '2025-12-10');


SELECT m.title, SUM(p.amount) as total_spent
FROM movies m
JOIN production_expenses p ON m.movie_id = p.movie_id
GROUP BY m.title;


SELECT role_name, COUNT(*) as actor_count
FROM movie_cast
GROUP BY role_name;


SELECT title, budget 
FROM movies 
WHERE budget > 1000000 AND production_status = 'Released'
ORDER BY budget DESC;


SELECT c.full_name, m.title, c.specialization
FROM crew c
JOIN movies m ON c.movie_id = m.movie_id;


SELECT m.title, AVG(mc.amount) as average_actor_fee
FROM movies m
JOIN movie_cast mc ON m.movie_id = mc.movie_id
GROUP BY m.title;


CREATE OR REPLACE FUNCTION check_movie_budget()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.budget IS NOT NULL AND NEW.budget < 0 THEN
        RAISE EXCEPTION 'Movie budget cannot be negative!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
INSERT INTO movies (title, genre, budget, production_status)
VALUES ('wrong budget film', 'Drama', -5000, 'Pre-production');

CREATE TRIGGER trg_check_budget
BEFORE INSERT OR UPDATE ON movies
FOR EACH ROW
EXECUTE FUNCTION check_movie_budget();



CREATE OR REPLACE FUNCTION log_expense_deletion()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Expense deleted for movie ID %, amount: %',
    OLD.movie_id,
    OLD.amount;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_after_expense_delete
AFTER DELETE ON production_expenses
FOR EACH ROW
EXECUTE FUNCTION log_expense_deletion();
SELECT * FROM production_expenses;
DELETE FROM production_expenses WHERE expense_id = 2;





CREATE OR REPLACE FUNCTION set_default_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_role IS NULL THEN
        NEW.user_role := 'employee';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_default_role
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION set_default_role();
INSERT INTO users (username, password_hash, email)
VALUES ('test_user', 'ps123', 'testuser@film.com');
SELECT username, email, user_role FROM users WHERE username = 'test_user';



CREATE OR REPLACE FUNCTION get_total_movie_costs(p_movie_id INT) 
RETURNS DECIMAL AS $$
BEGIN
    RETURN (SELECT SUM(amount) FROM production_expenses WHERE movie_id = p_movie_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE update_movie_status(p_movie_id INT, p_new_status TEXT)
AS $$
BEGIN
    UPDATE movies SET production_status = p_new_status WHERE movie_id = p_movie_id;
END;
$$ LANGUAGE plpgsql;

CALL update_movie_status(1, 'Completed');

SELECT movie_id, production_status
FROM movies
WHERE movie_id = 1;


