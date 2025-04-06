# Using the database
USE projectcapstone;

# Data Wrangling 
#Checking for the null values 
SELECT * FROM amazon WHERE `invoice id` IS NULL OR branch IS NULL OR city IS NULL OR `customer type` IS NULL OR gender IS NULL OR `product line` IS NULL OR `unit price` IS NULL 
OR quantity IS NULL OR `Tax 5%` IS NULL OR total IS NULL OR `Date` IS NULL OR `time` IS NULL OR payment IS NULL OR cogs IS NULL OR `gross margin percentage` IS NULL 
OR `gross income` IS NULL OR rating IS NULL;
# Hence, after excetuing we could see there are no null values in the table amazon, number of columns are 17 and rows are 1000.

#Feature Engineering
# Adding a three new columns - timeofday,dayname and monthname
ALTER TABLE amazon
ADD COLUMN timeofday VARCHAR(30),
ADD COLUMN dayname VARCHAR(30),
ADD COLUMN monthname VARCHAR(30); 
# We use alter command to add a column in the table,after adding the three new columns the number of columns are 20 and rows are 1000.

SET SQL_safe_updates = 0;
# By default in mysql safe updates is set to 1, we need to set it to zero to make some operations. 

# Inserting data into the new columns.
UPDATE amazon
SET timeofday = CASE
    WHEN TIME(`time`) BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
    WHEN TIME(`time`) BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
    WHEN TIME(`time`) BETWEEN '18:00:00' AND '21:59:59' THEN 'Evening'
    ELSE 'Night'
END;

UPDATE amazon
SET dayname = CASE 
    WHEN DAYOFWEEK(date) = 1 THEN 'Sunday'
    WHEN DAYOFWEEK(date) = 2 THEN 'Monday'
    WHEN DAYOFWEEK(date) = 3 THEN 'Tuesday'
    WHEN DAYOFWEEK(date) = 4 THEN 'Wednesday'
    WHEN DAYOFWEEK(date) = 5 THEN 'Thursday'
    WHEN DAYOFWEEK(date) = 6 THEN 'Friday'
    WHEN DAYOFWEEK(date) = 7 THEN 'Saturday'
END;

UPDATE amazon
SET monthname = MONTHNAME(`date`);
# Using update command we can set the data into the columns timeofday,dayname and monthname. 

#1.What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT city) AS distinct_city_count
FROM amazon;
# This query will return the number of unique cities present in the city column of the amazon table and distinct_city_count is the alias which we use it as 'AS'. 

#2.For each branch, what is the corresponding city? 
SELECT branch, city
FROM amazon; 
# This query gives a list of all rows in the amazon table, displaying both the branch and the city values for each sale. 

#3.What is the count of distinct product lines in the dataset? 
SELECT COUNT(DISTINCT `product line`) AS distinct_product_line_count
FROM amazon; 
# This query counts the unique values in the product_line column from the amazon table using COUNT(DISTINCT ...) and gives the number of distinct product lines in the dataset.

#4.Which payment method occurs most frequently? 
SELECT payment, COUNT(*) AS payment_count
FROM amazon
GROUP BY payment
ORDER BY payment_count DESC
LIMIT 1; 
# This query counts the occurrences of each payment_method in the amazon table and order by  the results in descending order by payment_count which gives the most frequent payment method using LIMIT 1.

#5.Which product line has the highest sales? 
SELECT `product line`, SUM(total) AS total_sales
FROM amazon
GROUP BY `product line`
ORDER BY total_sales DESC
LIMIT 1; 
# This query calculates the total sales for each product_line by summing the total column and order by  the results in descending order which gives the product line with the highest total sales using LIMIT 1. 

#6.How much revenue is generated each month? 
SELECT monthname , SUM(total) AS revenue
FROM amazon
GROUP BY monthname
ORDER BY revenue desc; 
# This query calculates monthly revenue by grouping rows based on the monthname column and summing the total column as revenue and order by revenue column to get the output. 

#7.In which month did the cost of goods sold reach its peak? 
SELECT monthname, SUM(cogs) AS total_cogs
FROM amazon
GROUP BY monthname
ORDER BY total_cogs DESC
LIMIT 1; 
# This query calculates the total cost of goods sold (COGS) for each month by summing the cogs column and grouping by month and order by the results in descending order and returns the month with the highest total COGS using LIMIT 1.

#8.Which product line generated the highest revenue? 
SELECT `product line`, SUM(total) as Revenue 
FROM amazon 
GROUP BY `product line`
ORDER BY Revenue DESC
LIMIT 1;
# This query calculates revenue for each product_line by summing the total column and grouping by product line,sorts the results in descending order and returns the product line with the highest revenue using LIMIT 1.

#9.In which city was the highest revenue recorded? 
SELECT city, SUM(total) as Revenue 
FROM amazon 
GROUP BY city 
ORDER BY Revenue DESC
LIMIT 1; 
# This query calculates the revenue for each city by summing the total column and grouping by city, sorts the results in descending order and returns the city with the highest revenue using LIMIT 1.

#10.Which product line incurred the highest Value Added Tax? 
SELECT `product line`, SUM(`Tax 5%`) AS Total_Tax
FROM amazon 
GROUP BY `product line` 
ORDER BY Total_Tax DESC
LIMIT 1; 
# This query calculates the total Tax (VAT) for each product_line by summing the Tax 5% column and grouping by product line, sorts the results in descending order and returns the product line with the highest VAT using LIMIT 1.

#11.For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
WITH product_sales AS (
    SELECT 
        `product line`, 
        SUM(total) AS total_sales
    FROM amazon
    GROUP BY `product line`),
    avg_sales AS (
    SELECT AVG(total_sales) AS avg_total_sales FROM product_sales)
SELECT 
    ps.`product line`, 
    ps.total_sales,
    CASE 
        WHEN ps.total_sales > (SELECT avg_total_sales FROM avg_sales) THEN 'Good'
        ELSE 'Bad'
    END AS sales_category
FROM product_sales ps; 
#In this query the first CTE (product_sales) calculates total sales for each product line by grouping data. The second CTE (avg_sales) computes the average total sales across all product lines. Finally, the main query compares each product line’s total sales with the average and categorizes it as "Good" or "Bad".

#12.Identify the branch that exceeded the average number of products sold. 
WITH branch_sales AS (
    SELECT branch, SUM(quantity) AS total_quantity
    FROM amazon
    GROUP BY branch), 
    avg_quantity AS (
    SELECT AVG(total_quantity) AS avg_total_quantity FROM branch_sales)
SELECT bs.branch, bs.total_quantity
FROM branch_sales bs
WHERE bs.total_quantity > (SELECT avg_total_quantity FROM avg_quantity);
#In this query the first CTE (branch_sales) calculates the total quantity of products sold at each branch. The second CTE (avg_quantity) computes the average number of products sold across all branches. Finally, the main query filters and retrieves only those branches where the total quantity sold exceeds the average. 

#13.Which product line is most frequently associated with each gender? 
WITH gender_product_counts AS (
    SELECT gender, `product line`, COUNT(*) AS purchase_count
    FROM amazon
    GROUP BY gender, `product line`), 
    ranked_products AS (
    SELECT gender, `product line`, purchase_count,RANK() OVER (PARTITION BY gender ORDER BY purchase_count DESC) AS rnk
    FROM gender_product_counts)
SELECT gender, `product line`, purchase_count
FROM ranked_products
WHERE rnk = 1; 
# In this query the first CTE (gender_product_counts) calculates the total number of purchases for each product line and gender. The second CTE (ranked_products) ranks the product lines for each gender based on the purchase count, using the RANK() function. The final query selects the product line with the highest rank (most purchases) for each gender, giving the most frequently purchased product line per gender.

#14.Calculate the average rating for each product line.
SELECT `product line`, AVG(rating) AS average_rating
FROM amazon
GROUP BY `product line`;
# This query groups the data by product_line to calculate the average rating for each product line. It uses the AVG() function to compute the average of the rating column for each group and give the output as the product lines with their average ratings.

#15.Count the sales occurrences for each time of day on every weekday.
SELECT dayname, timeofday, COUNT(*) AS sales_count
FROM amazon
GROUP BY dayname, timeofday
ORDER BY dayname, timeofday; 
# The query calculates the sales occurances(sales_count) for each combination of dayname and timeofday from the amazon table. It groups the data by dayname and timeofday, by which counts are calculated for each unoque pair and the result is ordered by dayname and timeofday to show sales for each weekday. 

#16.Identify the customer type contributing the highest revenue. 
SELECT customer_type, SUM(total) AS total_revenue
FROM amazon
GROUP BY customer_type
ORDER BY total_revenue DESC
LIMIT 1; 
# This query calculates the total revenue (total_revenue) for each customer_type by summing up the total sales for each type. It then groups the results by customer_type using GROUP BY. The query sorts the results in descending order by total revenue (ORDER BY total_revenue DESC) and limits the output to just one record using LIMIT 1,to show the hoghest revenue. 

#17.Determine the city with the highest VAT percentage. 
SELECT city, MAX(`Tax 5%`) AS highest_VAT
FROM amazon
GROUP BY city
ORDER BY highest_VAT DESC
LIMIT 1;
# This query finds the city with the highest VAT percentage by using MAX(Tax 5%) to select the maximum VAT value for each city. It groups the data by city with GROUP BY an then sorts in descending order by VAT using ORDER BY highest_VAT DESC, and LIMIT 1 ensures that only the city with the highest VAT is returned.

#18.Identify the customer type with the highest VAT payments. 
SELECT `customer type`, SUM(`Tax 5%`) AS total_VAT
FROM amazon
GROUP BY `customer type`
ORDER BY total_VAT DESC
LIMIT 1; 
# This query calculates the total VAT payments (total_VAT) for each customer_type by summing the Tax 5% values.It groups the data by customer_type using GROUP BY. The results are sorted by total VAT in descending order with ORDER BY total_VAT DESC, and LIMIT 1 ensures that only the customer type with the highest VAT payments is returned.

#19.What is the count of distinct customer types in the dataset? 
SELECT COUNT(DISTINCT `customer type`) AS distinct_customer_types
FROM amazon; 
# This query uses COUNT(DISTINCT customer_type) to count the number of unique customer types in the amazon table. By applying DISTINCT, it ensures only distinct customer types are counted, eliminating duplicates. The result is labeled as distinct_customer_types to show the total number of different customer types in the dataset.

#20.What is the count of distinct payment methods in the dataset? 
SELECT COUNT(DISTINCT payment) AS distinct_payment_methods
FROM amazon;
# This query uses COUNT(DISTINCT payment) to count the number of unique payment methods in the amazon table. By using DISTINCT, it ensures that only distinct payment methods are counted, excluding any duplicates. The result is labeled as distinct_payment_methods to show the total number of unique payment methods in the dataset.

#21.Which customer type occurs most frequently? 
SELECT `customer type`, COUNT(`customer type`) AS occurrence_count
FROM amazon
GROUP BY `customer type`
ORDER BY occurrence_count DESC
LIMIT 1; 
# This query counts how many times each customer_type appears in the amazon table using COUNT(customer type). It groups the data by customer_type with GROUP BY to calculate the occurrences for each type. The results are sorted by occurrence count in descending order with ORDER BY occurrence_count DESC, and LIMIT 1 ensures that only the most frequent customer type is returned. 

#22.Identify the customer type with the highest purchase frequency. 
SELECT `customer type`, COUNT(`Customer type`) AS purchase_frequency
FROM amazon
GROUP BY `customer type`
ORDER BY purchase_frequency DESC
LIMIT 1; 
# This query counts how many purchases each customer_type has made by using COUNT(*) to count the rows associated with each type. It groups the data by customer_type using GROUP BY, allowing the count to be calculated for each customer type. The results are then sorted in descending order by purchase_frequency with ORDER BY, and LIMIT 1 ensures that only the customer type with the highest purchase frequency is returned.

#23.Determine the predominant gender among customers. 
SELECT gender, COUNT(gender) AS gender_count
FROM amazon
GROUP BY gender
ORDER BY gender_count DESC
LIMIT 1;
# This query counts the occurrences of each gender in the amazon table using COUNT(gender). It groups the data by gender using GROUP BY to calculate the count for each gender. The results are sorted by gender_count in descending order with ORDER BY, and LIMIT 1 ensures that only the gender with the highest count is returned.

#24.Examine the distribution of genders within each branch. 
SELECT branch, gender, COUNT(gender) AS gender_count
FROM amazon
GROUP BY branch, gender
ORDER BY branch, gender; 
# This query counts the occurrences of each gender within each branch using COUNT(gender),it groups the data by both branch and gender with GROUP BY, so the gender distribution is calculated for each branch separately. The result is sorted by branch and then by gender using ORDER BY, ensuring a clear and organized view of gender distribution across branches. 

#25.Identify the time of day when customers provide the most ratings. 
SELECT timeofday, COUNT(rating) AS rating_count
FROM amazon
GROUP BY timeofday
ORDER BY rating_count DESC
LIMIT 1; 
# This query counts the number of ratings for each timeofday, grouping the data by time of day. It then orders the results in descending order by rating count, returning the time of day with the most ratings.

#26.Determine the time of day with the highest customer ratings for each branch. 
WITH RatingCount AS (
    SELECT branch,timeofday,COUNT(rating) AS rating_count
    FROM amazon
    GROUP BY branch, timeofday)
SELECT branch, timeofday, rating_count
FROM RatingCount
WHERE (branch, rating_count) IN (
    SELECT branch, MAX(rating_count)
    FROM RatingCount
    GROUP BY branch
); 
# This query first counts the number of ratings for each combination of branch and timeofday, then assigns a rank to each timeofday within each branch based on the rating count, using the ROW_NUMBER() window function. The PARTITION BY branch ensures that the ranking is done separately for each branch, and ORDER BY COUNT(rating) DESC ranks the time of day with the highest rating count first. The final result filters to return only the top-ranked time of day (highest rating count) for each branch by selecting WHERE rn = 1.

#27.Identify the day of the week with the highest average ratings. 
SELECT dayname, AVG(rating) AS avg_rating
FROM amazon
GROUP BY dayname
ORDER BY avg_rating DESC
LIMIT 1; 
# This query calculates the average rating (AVG(rating)) for each dayname by grouping the data by dayname with GROUP BY. It then sorts the results by the average rating in descending order using ORDER BY avg_rating DESC, ensuring that the day with the highest average rating appears first. Finally, LIMIT 1 returns only the day with the highest average rating.

#28.Determine the day of the week with the highest average ratings for each branch.
WITH RankedDays AS (
    SELECT branch,dayname,AVG(rating) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rn
    FROM amazon
    GROUP BY branch, dayname
)
SELECT branch, dayname, avg_rating
FROM RankedDays
WHERE rn = 1; 
# This query calculates the average rating (AVG(rating)) for each combination of branch and dayname, and ranks the days within each branch based on the highest average rating using the ROW_NUMBER() window function. The PARTITION BY branch ensures that the ranking is done for each branch separately, and ORDER BY AVG(rating) DESC ranks the days in descending order of average rating. The WHERE rn = 1 filter ensures that only the day with the highest average rating for each branch is returned.



