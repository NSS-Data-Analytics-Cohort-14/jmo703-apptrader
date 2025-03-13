-- #### 1. Loading the data
-- a. Launch PgAdmin and create a new database called app_trader.  

-- b. Right-click on the app_trader database and choose `Restore...`  

-- c. Use the default values under the `Restore Options` tab. 

-- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of this repository.  

-- e. Click `Restore` to load the database.  

-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  

--	THIS IS SHOWING THE TOP APPS W HIGHER THAN 4.5 STARS, COST MONEY AND HAVE A HIGH REVIEW COUNT
SELECT *
FROM play_store_apps;

SELECT 
	name,
	review_count,
	price,
	price * 10000 AS buying_price,
	rating,
	price * review_count AS total_money_spent,
	primary_genre
FROM
	(SELECT 
		name
		,CAST(review_count AS NUMERIC) AS review_count
		,CAST (price AS NUMERIC) AS price
		,rating
		,primary_genre
	FROM app_store_apps)
WHERE review_count > 5000
AND rating >= 4.5
AND price >= 1
ORDER BY total_money_spent DESC;

SELECT
	AVG(price),
	primary_genre
FROM app_store_apps
GROUP BY primary_genre;
	

--     - `play_store_apps` with 10840 rows


-- #### 2. Assumptions


-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 

SELECT
    ap.name, --APP NAME
	
    ROUND((p.rating + a.rating) / 2, 1) AS avg_rating, -- Rating
	
    ((ROUND((p.rating + a.rating) / 2, 1) * 2) + 1) AS lifespan, -- Lifespan (Rating *2 + 1)
	GREATEST(
        CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
        CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
    ) AS max_price, -- Max Price
	
    (GREATEST(
        CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
        CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
    ) * 10000) AS purchase_price, -- Purchase Price
	
    (CASE
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) AS monthly_earning, --monthly_earning (fixed value)
	
    1000 AS marketing_cost, -- marketing_cost (fixed value)
	
    ((CASE
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) - (GREATEST(
        CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
        CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
    ) * 10000) - 1000) AS profit, -- Profit
	
    p.content_rating,
    a.primary_genre,
    p.genres AS secondary_genre,
    'both' AS store
FROM (
    SELECT name
    FROM app_store_apps
    INTERSECT
    SELECT name
    FROM play_store_apps
) AS ap
LEFT JOIN play_store_apps AS p
    ON p.name = ap.name
LEFT JOIN app_store_apps AS a
    ON a.name = ap.name
GROUP BY ap.name, p.rating, a.rating, p.price, a.price, p.content_rating, a.primary_genre, p.genres, p.name, a.name
HAVING ROUND((p.rating + a.rating) / 2, 1) >= 3.0
ORDER BY profit DESC
LIMIT 10;

SELECT 
a.name,
GREATEST (a.price, p.price)
FROM app_store_apps AS a
LEFT JOIN play_store_apps AS p
on a.name = p.name;

SELECT
    ap.name,
    ROUND((p.rating + a.rating) / 2 / 0.5, 0) * 0.5 AS avg_rating,
    (ROUND((p.rating + a.rating) / 2 / 0.5, 0) * 0.5 * 2) + 1 AS lifespan,
    GREATEST(
        CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
        CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
    ) AS max_price,
    CASE 
        WHEN GREATEST(
            CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
            CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
        ) = 0 THEN 10000
        ELSE GREATEST(
            CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
            CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
        ) * 10000
    END AS purchase_price,
    CASE 
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END AS monthly_earning,
    1000 AS marketing_cost,
    (CASE 
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) 
    - (
        GREATEST(
            CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
            CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
        ) * 10000
    ) 
    - 1000 AS profit,
    
    -- Profit at the end of lifespan
    (
        ((ROUND((p.rating + a.rating) / 2 / 0.5, 0) * 0.5 * 2) + 1) *  -- lifespan
        (CASE 
            WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
            WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
            ELSE 0
        END) * 12
    ) 
    - (
        CASE 
            WHEN GREATEST(
                CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
                CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
            ) = 0 THEN 10000
            ELSE GREATEST(
                CAST(REPLACE(CAST(p.price AS text), '$', '') AS numeric),
                CAST(REPLACE(CAST(a.price AS text), '$', '') AS numeric)
            ) * 10000
        END
    )
    - (1000 * 12 * ((ROUND((p.rating + a.rating) / 2 / 0.5, 0) * 0.5 * 2) + 1)) 
    AS lifespan_profit,

    p.content_rating,
    a.primary_genre,
    p.genres AS secondary_genre,
    'both' AS store

FROM (
    SELECT name FROM app_store_apps
    INTERSECT
    SELECT name FROM play_store_apps
) AS ap
LEFT JOIN play_store_apps AS p ON p.name = ap.name
LEFT JOIN app_store_apps AS a ON a.name = ap.name

GROUP BY ap.name, p.rating, a.rating, p.price, a.price, 
         p.content_rating, a.primary_genre, p.genres, p.name, a.name

HAVING ROUND((p.rating + a.rating) / 2, 1) >= 3.0
ORDER BY lifespan_profit DESC
LIMIT 10;

WITH appdata AS (
	SELECT
	ap.name,
	p.rating AS p_rating
	a.rating AS a_rating
)

SELECT
    ap.name,
    (ROUND((((p.rating + a.rating)/2)/0.5),0)*0.5) AS avg_rating,
    (((ROUND((((p.rating + a.rating)/2)/0.5),0)*0.5) * 2) + 1) AS lifespan,
    GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
        (a.price)
    ) AS max_price,
	CASE WHEN (GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
        (a.price)
    )) = 0 THEN '10000'
		WHEN (GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
        (a.price)
    )) > 0 THEN
	    (GREATEST(
	        CAST(REPLACE(p.price, '$', '') AS numeric),
	        (a.price) * 10000)) END AS purchase_price,
    (CASE
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) AS monthly_earning,
    1000 AS marketing_cost,
    ((CASE
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) - (GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
       (a.price) * 10000) - 1000)) AS profit,
	--profit at end of lifespan = (lifespan * monthly_earning * 12) - purchase_price - (marketing_cost * 12 * lifespan)
	((((ROUND((((p.rating + a.rating)/2)/0.5),0)*0.5) * 2) + 1) * --lifespan
	(CASE
        WHEN p.name IS NOT NULL AND a.name IS NOT NULL THEN 10000
        WHEN p.name IS NOT NULL OR a.name IS NOT NULL THEN 5000
        ELSE 0
    END) * 12) - --monthly_earning * 12
	CASE WHEN (GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
        (a.price))) = 0 THEN '10000'
		WHEN (GREATEST(
        CAST(REPLACE(p.price, '$', '') AS numeric),
        (a.price)
    )) > 0 THEN
	    (GREATEST(
	        CAST(REPLACE(p.price, '$', '') AS numeric),
	        (a.price)
	    ) * 10000) END - --purchase_price
	(1000 * 12 * --marketing_cost * 12
	(((ROUND((((p.rating + a.rating)/2)/0.5),0)*0.5) * 2) + 1)) AS lifespan_profit, --lifespan
    p.content_rating,
    a.primary_genre,
    p.genres AS secondary_genre,
    'both' AS store
FROM (
    SELECT name
    FROM app_store_apps
    INTERSECT
    SELECT name
    FROM play_store_apps
) AS ap
LEFT JOIN play_store_apps AS p
    ON p.name = ap.name
LEFT JOIN app_store_apps AS a
    ON a.name = ap.name
GROUP BY ap.name, p.rating, a.rating, p.price, a.price, p.content_rating, a.primary_genre, p.genres, p.name, a.name
HAVING ROUND((p.rating + a.rating) / 2, 1) >= 3.0
ORDER BY lifespan_profit DESC
LIMIT 10;

SELECT *
FROM app_store_apps
WHERE name LIKE 'Egg%';