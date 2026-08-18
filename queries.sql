-- =========================================================
-- Social Media Ad Performance Analysis — SQL Queries
-- Tables: campaigns, ads, users, ad_events
-- =========================================================

-- 1. Full funnel breakdown (event counts by stage)
SELECT event_type, COUNT(*) AS total_events
FROM ad_events
GROUP BY event_type
ORDER BY total_events DESC;


-- 2. Click-through rate (CTR) by campaign
SELECT c.name AS campaign_name,
  SUM(CASE WHEN e.event_type = 'Impression' THEN 1 ELSE 0 END) AS impressions,
  SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
  ROUND(SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN e.event_type = 'Impression' THEN 1 ELSE 0 END), 0) * 100, 2) AS ctr_percent
FROM ad_events e
JOIN ads a ON e.ad_id = a.ad_id
JOIN campaigns c ON a.campaign_id = c.campaign_id
GROUP BY c.name
ORDER BY ctr_percent DESC;


-- 3. Purchase conversion rate by platform (Facebook vs Instagram)
SELECT a.ad_platform,
  SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
  SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases,
  ROUND(SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END), 0) * 100, 2) AS conversion_rate
FROM ad_events e
JOIN ads a ON e.ad_id = a.ad_id
GROUP BY a.ad_platform
ORDER BY conversion_rate DESC;


-- 4. Conversion rate by ad type (Video / Stories / Carousel / Image)
SELECT a.ad_type,
  SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
  SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases,
  ROUND(SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN e.event_type = 'Click' THEN 1 ELSE 0 END), 0) * 100, 2) AS conversion_rate
FROM ad_events e
JOIN ads a ON e.ad_id = a.ad_id
GROUP BY a.ad_type
ORDER BY conversion_rate DESC;


-- 5. Purchases broken down by actual user demographics
SELECT u.user_gender, u.age_group, COUNT(*) AS purchases
FROM ad_events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_type = 'Purchase'
GROUP BY u.user_gender, u.age_group
ORDER BY purchases DESC;


-- 6. Targeting accuracy — does targeted gender match who actually converts?
SELECT a.target_gender, u.user_gender, COUNT(*) AS matches
FROM ad_events e
JOIN ads a ON e.ad_id = a.ad_id
JOIN users u ON e.user_id = u.user_id
WHERE e.event_type = 'Purchase'
GROUP BY a.target_gender, u.user_gender
ORDER BY matches DESC;


-- 7. Best day/time for engagement (Click, Like, Share, Purchase)
SELECT day_of_week, time_of_day, COUNT(*) AS total_engagement
FROM ad_events
WHERE event_type IN ('Click', 'Like', 'Share', 'Purchase')
GROUP BY day_of_week, time_of_day
ORDER BY total_engagement DESC;


-- 8. Cost per purchase by campaign (ROI proxy)
SELECT c.name, c.total_budget,
  SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases,
  ROUND(c.total_budget / NULLIF(SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END), 0), 2) AS cost_per_purchase
FROM campaigns c
JOIN ads a ON c.campaign_id = a.campaign_id
JOIN ad_events e ON a.ad_id = e.ad_id
GROUP BY c.name, c.total_budget
ORDER BY cost_per_purchase ASC;


-- 9. Purchases by country
SELECT u.country, COUNT(*) AS purchases
FROM ad_events e
JOIN users u ON e.user_id = u.user_id
WHERE e.event_type = 'Purchase'
GROUP BY u.country
ORDER BY purchases DESC;


-- 10. Monthly purchase trend (excludes partial current month if needed)
SELECT DATE_FORMAT(timestamp, '%Y-%m') AS month, COUNT(*) AS purchases
FROM ad_events
WHERE event_type = 'Purchase'
GROUP BY month
ORDER BY month;


-- 11. Data quality check — duplicate user_id check (used during modeling)
SELECT user_id, COUNT(*) AS occurrences
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- 12. Data range check — used to confirm partial-month data (e.g. August)
SELECT MIN(timestamp) AS earliest_event, MAX(timestamp) AS latest_event
FROM ad_events;
