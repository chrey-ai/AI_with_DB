SELECT customer_id,
       city,
       state,
       country,
       sentiment_score,
       name,
       email
FROM public.customers
LIMIT 1000;