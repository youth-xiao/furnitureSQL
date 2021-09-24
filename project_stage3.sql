DROP TABLE IF EXISTS project.furniture_list CASCADE;


-- create a table with adding a primary key
CREATE TABLE project.furniture_list(
	product_id serial PRIMARY KEY NOT NULL,
	product_name varchar(20) NOT NULL,
	product_description varchar(40),
	unit_cost numeric (5,2) NOT NULL,
	unit_price numeric (5,2) NOT NULL,
	designer varchar(30),
	first_produced date NOT NULL
);


INSERT INTO project.furniture_list(product_name, product_description, unit_cost, unit_price, designer, first_produced)
(
	VALUES
	('Wood Round Table', '20lbs, 30inch wide', 40.83, 90.53, 'Lucy Wong', '3/15/2020'),
	('Plastic Green Chair', '3lb, semi-transparent', 32.22, 56.82, 'Tommy Liu', '2/28/2019'),
	('Aluminum Office Desk', '90lbs, 40inch wide', 59.80, 80.56, 'Jeff Lee', '5/23/2020'),
	('Hard Wood Bedframe', '100lbs', 68.02, 98.90, 'Emily Lam', '8/10/2018')
);

SELECT * FROM project.furniture_list; --- REMEMBER to use cost_histories and price_histories to insert money values

SELECT * FROM project.furniture_list;


DROP INDEX IF EXISTS ix_furniture_product_id;
CREATE UNIQUE INDEX ix_furniture_product_id ON project.furniture_list USING btree (product_id);

DROP INDEX IF EXISTS ix_furniture_product_name;
CREATE UNIQUE INDEX ix_furniture_product_name ON project.furniture_list USING btree (product_name);

DROP INDEX IF EXISTS ix_furniture_unit_cost;
CREATE INDEX ix_furniture_unit_cost ON project.furniture_list USING btree (unit_cost);

DROP INDEX IF EXISTS ix_furniture_unit_price;
CREATE INDEX ix_furniture_unit_price ON project.furniture_list USING btree (unit_price);



-- create a table with adding a primary key

DROP TABLE IF EXISTS project.client_list CASCADE;

CREATE TABLE project.client_list(
	client_id serial NOT NULL PRIMARY KEY,
	client_company varchar(30) NOT NULL,
	client_manager varchar(30) NOT NULL,
	client_phone varchar(14) NOT NULL,
	client_email varchar(30) NOT NULL,
	client_country varchar(20) NOT NULL,
	client_city varchar(20) NOT NULL,
	client_history date NOT NULL
);

INSERT INTO project.client_list(client_company, client_manager, client_phone, client_email, client_country,
							   client_city, client_history)
(
	VALUES
	('Nature Life', 'Gina Rong', '9803823920', 'ginar440@naturelife.com', 'United States', 'New York City', '9/5/2018'),
	('Mirror Me', 'Helen Zhu', '34728374850', 'sales3@mirrorme.com', 'United Kingdom', 'London', '3/22/2020'),
	('DoReMe', 'Bob Yu', '13567283740', 'bobyu09@123.com', 'China', 'Shanghai', '11/30/2016')
);

SELECT * FROM project.client_list;

DROP INDEX IF EXISTS ix_client_id;
CREATE UNIQUE INDEX ix_client_id ON project.client_list USING btree (client_id);

DROP INDEX IF EXISTS ix_client_phone;
CREATE UNIQUE INDEX ix_client_phone ON project.client_list USING btree (client_phone);


-- create a table with adding a primary key

DROP TABLE IF EXISTS project.order_list CASCADE;

CREATE TABLE project.order_list(
	order_id serial NOT NULL PRIMARY KEY,
	client_id smallint NOT NULL,
	order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO project.order_list(client_id)
(
	VALUES
	(2),
	(1),
	(3),
	(3)
);

SELECT * FROM project.order_list;


-- create a table: add a primary with two fields in a separate query

DROP TABLE IF EXISTS project.items_per_order CASCADE;

CREATE TABLE project.items_per_order(
	order_id smallint NOT NULL,
	product_id smallint NOT NULL,
	number_units smallint NOT NULL,
	order_status varchar(15) NOT NULL
);

INSERT INTO project.items_per_order(
	VALUES
	(1, 4, 10, 'In process'),
	(1, 3, 5, 'Reviewed'),
	(2, 1, 6, 'Pending'),
	(3, 1, 12, 'Completed'),
	(4, 2, 5, 'In process'),
	(2, 3, 12, 'Completed'),
	(4, 4, 18, 'Pending')
);

SELECT * FROM project.items_per_order;

-- create a primary with two fields
ALTER TABLE project.items_per_order DROP CONSTRAINT IF EXISTS pk_items_per_order;
ALTER TABLE project.items_per_order
	ADD CONSTRAINT pk_items_per_order PRIMARY KEY(order_id, product_id);


-- create  index
DROP INDEX IF EXISTS ix_order_status CASCADE;
CREATE INDEX ix_order_status ON project.items_per_order USING btree (order_status);

DROP INDEX IF EXISTS ix_items_product_id;
CREATE INDEX ix_items_product_id ON project.items_per_order USING btree (product_id);


/*
foreign key between client_list and order_list
*/
ALTER TABLE project.order_list DROP CONSTRAINT IF EXISTS fk_order_client;
ALTER TABLE project.order_list
	ADD CONSTRAINT fk_order_client FOREIGN KEY(client_id)
		REFERENCES project.client_list(client_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT
;

/*
foreign key between items_per_order and furniture_list
*/
ALTER TABLE project.items_per_order DROP CONSTRAINT IF EXISTS fk_items_furniture;
ALTER TABLE project.items_per_order
	ADD CONSTRAINT fk_items_furniture FOREIGN KEY(product_id)
		REFERENCES project.furniture_list(product_id)
			ON UPDATE CASCADE
			ON DELETE RESTRICT
;

/*
foreign key between items_per_order and order_list
*/
ALTER TABLE project.items_per_order DROP CONSTRAINT IF EXISTS fk_items_per_order_order_list;
ALTER TABLE project.items_per_order
	ADD CONSTRAINT fk_items_per_order_order_list FOREIGN KEY(order_id)
		REFERENCES project.order_list(order_id)
		ON UPDATE CASCADE
		ON DELETE RESTRICT
;



--------- Trigger functions

DROP TABLE IF EXISTS project.cost_price_histories CASCADE;

CREATE TABLE project.cost_price_histories(
	product_id smallint,
	cost_old numeric(5,2),
	cost_new numeric(5,2),
	price_old numeric(5,2),
	price_new numeric(5,2),
	date_time_changed timestamptz DEFAULT CURRENT_TIMESTAMP
);

DROP FUNCTION IF EXISTS project.update_cost_price CASCADE;

CREATE FUNCTION project.update_cost_price() RETURNS TRIGGER
	LANGUAGE 'plpgsql'
	VOLATILE
AS
$BODY$
	DECLARE var_product_id smallint;
	BEGIN
		IF TG_OP IN('INSERT', 'UPDATE') THEN
			var_product_id = NEW.product_id;
		ELSE
			var_product_id = OLD.product_id;
		END IF;
		
		INSERT INTO project.cost_price_histories
		VALUES(var_product_id,
			   OLD.unit_cost::numeric(5,2), NEW.unit_cost::numeric(5,2),
			   OLD.unit_price::numeric(5,2), NEW.unit_price::numeric(5,2));
			   
		RETURN NEW;
	END;
$BODY$;

DROP TRIGGER IF EXISTS trigger_update_cost_price_after
ON project.furniture_list;

CREATE TRIGGER trigger_update_cost_price_after
AFTER INSERT OR DELETE OR UPDATE
ON project.furniture_list
FOR EACH ROW
EXECUTE PROCEDURE project.update_cost_price();

INSERT INTO project.cost_price_histories(product_id, cost_new, price_new)
VALUES
	(1, 40.83, 90.53),
 	(2, 32.22, 56.82),
	(3, 59.80, 80.56),
	(4, 68.02, 98.90)
;

SELECT * FROM project.cost_price_histories;

UPDATE project.furniture_list SET unit_cost = 39.00 WHERE product_id = 1;
UPDATE project.furniture_list SET unit_price = 95.68 WHERE product_id = 4;
---------

DROP VIEW IF EXISTS project.vw_order_summary;
CREATE VIEW project.vw_order_summary AS
SELECT cl.client_company, ipo.order_id, fl.product_id, fl.product_name,
	   ch.cost_new, ph.price_new, ipo.number_units, ipo.order_status, ol.order_date
FROM project.items_per_order ipo
INNER JOIN project.cost_histories ch
	ON ipo.product_id = ch.product_id
INNER JOIN project.price_histories ph
	ON ch.product_id = ph.product_id
INNER JOIN project.order_list ol
	ON ipo.order_id = ol.order_id
INNER JOIN project.client_list cl
	ON ol.client_id = cl.client_id
INNER JOIN project.furniture_list fl
	ON fl.product_id = ipo.product_id;
	
SELECT * FROM project.vw_order_summary;
SELECT * FROM project.code_vw;

-------

DROP VIEW IF EXISTS project.vw_revenue_profit;

CREATE VIEW project.vw_revenue_profit AS
WITH vw_date_lead_lag AS (
	SELECT date_time_changed, LEAD(date_time_changed)OVER(PARTITION BY product_id) AS lead_date,
	product_id, cost_new, price_new
	FROM project.cost_price_histories
	ORDER BY product_id, date_time_changed),

	date_period AS(
	SELECT product_id,
		   tstzrange(dll.date_time_changed, dll.lead_date,'[)') AS period
	FROM vw_date_lead_lag dll
	)

SELECT cl.client_id, cl.client_company,
	   SUM(dll.price_new * number_units) OVER(PARTITION BY cl.client_id) AS revenue,
	   SUM((dll.price_new - cost_new) * number_units) OVER(PARTITION BY cl.client_id) AS profit
FROM project.vw_date_lead_lag dll
INNER JOIN date_period dp
	ON dll.product_id = dp.product_id
INNER JOIN project.items_per_order ipo
	ON dll.product_id = ipo.product_id
INNER JOIN project.order_list ol
	ON ipo.order_id = ol.order_id
INNER JOIN project.client_list cl
	ON ol.client_id = cl.client_id
WHERE dp.period @> ol.order_date::timestamptz;
SELECT * FROM vw_revenue_profit;

	
/* QUESTIONS 1: For the table 'items_per_order', I used two fields for creating a primary key.
			  Does it affect when I am creating a foreign key by using just one field?
   *** Advisable to add an index whenever add a foreign key??? ***
   *** What is the relationship between index and a foreign key? Are they overlapped or complementary ***
   *** LECTURE 3 note: add an index to the new id_city column in students. This index covers the foreign key constraint? ***

/*--------------------------
	FOREIGN KEY CHECKLIST
 ---------------------------
 
 order_list : client_list			DONE
 items_per_order : order_list		DONE
 items_per_order : furniture_list   DONE	*/
 
--------------------------------
### 2/3: ADD A DOZEN OF QUERIES (~4 VIEWS, ~8 AD HOC) ###
/* FUNCTIONS AND CONCEPTS TO BE APPLIED
1. serial numbers
2. index
*** Still cannot really distinguish the differences between serial numbers and index ***
*** COVERING INDEX: The variable that is used on the many side, the table with that's serving
					as the many side of that one too many join should have an index ***
3. Union, union all, intercept, except
4. Common Table Expression
5. GROUP BY
6. WHERE, HAVING
7. UPDATE, ALTER, DELETE, INSERT...
8. WINDOW
*/


/* add unique constraint on product_id/client_id, preventing duplicates
add contraint to numeric, precision, scale
money, always 2 d.p
avoid using arrays, maybe create a separate table for managers
*/
*/

-- What is the most popular furniture over the years?
DROP VIEW IF EXISTS project.vw_popular_furniture;

CREATE VIEW project.vw_popular_furniture AS
SELECT
	fl.product_id, fl.product_name,
	SUM(number_units) AS total_units
FROM project.items_per_order ipo
LEFT JOIN project.order_list ol
	ON ipo.order_id = ol.order_id
LEFT JOIN project.client_list cl
	ON ol.client_id = cl.client_id
LEFT JOIN project.furniture_list fl
	ON fl.product_id = ipo.product_id
GROUP BY fl.product_id
ORDER BY 3 DESC;

SELECT * FROM project.vw_popular_furniture;


-------
SELECT * FROM project.items_per_order;

SELECT DISTINCT ON(order_status) order_status, SUM(number_units) OVER(PARTITION BY order_status) AS quantity_by_status
FROM project.items_per_order
ORDER BY order_status;

---


DROP TABLE IF EXISTS project.query_table;
CREATE TABLE project.query_table (description text, query_code text);

INSERT INTO project.query_table(description, query_code)
VALUES ('quantity_by_status',
	   'SELECT DISTINCT ON(order_status) order_status, SUM(number_units) OVER(PARTITION BY order_status) AS quantity_by_status
FROM project.items_per_order
ORDER BY order_status;');

SELECT * FROM project.query_table;


-------

/*
What is the latest order from each company?
*/

SELECT
		DISTINCT ON(ol.client_id)
		client_id
		, ol.order_id
		, MAX(order_date) OVER(PARTITION BY client_id ORDER BY order_date DESC)
FROM project.order_list ol
INNER JOIN project.items_per_order ipo
	ON ipo.order_id = ol.order_id
ORDER BY ol.client_id;


INSERT INTO query_table(description, query_code)
VALUES ('Latest order for each company',
	   'SELECT
		DISTINCT ON(ol.client_id)
		client_id
		, ol.order_id
		, MAX(order_date) OVER(PARTITION BY client_id ORDER BY order_date DESC)
FROM project.order_list ol
INNER JOIN project.items_per_order ipo
	ON ipo.order_id = ol.order_id
ORDER BY ol.client_id;');


--- Which company has the longest history and how many months?

SELECT DISTINCT ON(earliest)
	client_id,
	client_company,
	client_history,
	MIN(client_history) OVER(ORDER BY client_history) AS earliest,
	(CURRENT_DATE - client_history)/30 AS duration_months
	FROM project.client_list
	ORDER BY earliest ASC;
	
INSERT INTO query_table(description, query_code)
VALUES ('Which company has the longest history and how many months?',
	   'SELECT DISTINCT ON(earliest)
	client_id,
	client_company,
	client_history,
	MIN(client_history) OVER(ORDER BY client_history) AS earliest,
	(CURRENT_DATE - client_history)/30 AS duration_months
	FROM project.client_list
	ORDER BY earliest ASC;');
	
SELECT * FROM query_table;



