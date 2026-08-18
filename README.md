# Social-Media-Ad-Performance-Dashboard
An end-to-end data analytics project analyzing social media advertising performance across Facebook and Instagram — from raw event-level data to an interactive Power BI dashboard.
Tools used: MySQL (querying) · Power BI (dashboard & DAX & data modeling) · Tableau Public (planned)

Project Overview

This project analyzes ~90,000 ad interaction events across multiple campaigns to answer a core business question:

Which campaigns, platforms, and audience segments actually drive purchases — and where is the ad budget being spent most efficiently?

The dataset simulates a real-world digital advertising funnel: Impression → Click → Like/Share/Comment → Purchase, tracked across users with different demographics, targeting parameters, and campaign budgets.

The data is organized into four relational tables:

Table	Description	Key Columns
campaigns	Campaign-level metadata	campaign_id, name, start_date, end_date, duration_days, total_budget
ads	Individual ad creatives and targeting	ad_id, campaign_id, ad_platform, ad_type, target_gender, target_age_group, target_interests
users	User demographic data	user_id, user_gender, user_age, age_group, country, location, interests
ad_events	Event-level interaction log (fact table)	event_id, ad_id, user_id, timestamp, day_of_week, time_of_day, event_type

campaigns (1) ──< ads (many)
ads (1) ──< ad_events (many)
users (1) ──< ad_events (many)
ad_events is the central fact table, with event_type capturing six interaction types: Impression, Click, Like, Comment, Share, Purchase.

Power BI Dashboard

The dashboard is built across 4 pages:

Executive Overview — KPI summary (Impressions, Clicks, Purchases, CTR, Conversion Rate, Cost per Purchase), conversion funnel, purchase trend, platform breakdown, and campaign budget comparison
Campaign Performance — Campaign × platform matrix, CTR by platform, conversion rate by ad type, and a budget-vs-purchases scatter plot
Audience Insights — Purchases by age/gender, targeting accuracy matrix, geographic breakdown
Timing & Behavior — Engagement heatmap by day/time

SQL Analysis

All exploratory analysis was done in MySQL before building the Power BI model. Key queries below (full set in queries.sql):

SELECT event_type, COUNT(*) AS total_events
FROM ad_events
GROUP BY event_type
ORDER BY total_events DESC;

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

SELECT c.name, c.total_budget,
  SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases,
  ROUND(c.total_budget / NULLIF(SUM(CASE WHEN e.event_type = 'Purchase' THEN 1 ELSE 0 END), 0), 2) AS cost_per_purchase
FROM campaigns c
JOIN ads a ON c.campaign_id = a.campaign_id
JOIN ad_events e ON a.ad_id = e.ad_id
GROUP BY c.name, c.total_budget
ORDER BY cost_per_purchase ASC;

SELECT a.target_gender, u.user_gender, COUNT(*) AS matches
FROM ad_events e
JOIN ads a ON e.ad_id = a.ad_id
JOIN users u ON e.user_id = u.user_id
WHERE e.event_type = 'Purchase'
GROUP BY a.target_gender, u.user_gender
ORDER BY matches DESC;



