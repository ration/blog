---
layout: post
title:  Dealing with PostgreSQL Times and Local Times
date:   2024-06-07 08:24:48 +0300
tags:   [postgresql]
---

My current work involves a lot of local time dependent operations. This means answering a lot annoying questions like
"Find the maximum value during workdays between 7-21.", "Highest value during daytime in February (in Country X)",
"Find the average value average value for today" or "Highest value during December".

To get started let's create table:

```sql
CREATE TABLE Measurement(
    id SERIAL PRIMARY KEY,
    value DOUBLE PRECISION NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL
);
```

I will not get into details about the "TIMESTAMP WITH TIME ZONE" (spoiler: I will) type and it's hairy spots, you can go
to [this yagabyte article](https://www.yugabyte.com/blog/postgresql-timestamps-timezones/) or
[EnterpriseDB](https://www.enterprisedb.com/postgres-tutorials/postgres-time-zone-explained) for that.

Lets generate a six of months of data as in increasing series, one measurement per hour, on the hour. Let's ask ChatGPT
to create the generate_series query, lazy as we are. ChatGPT (and Gemini) suggests to calculate the amount hour ours
between the timestamps like this: `SELECT EXTRACT(EPOCH FROM AGE('2024-07-01 00:00:00+00', '2024-01-01 00:00:00+00')) /
3600 AS hours_difference;` This returns returns 4320, which is not correct. The `AGE`function documentation says: 

>   "Subtract arguments, producing a “symbolic” result that uses years and months, rather than just days". 

The
[doc](https://www.postgresql.org/docs/current/functions-datetime.html) doesn't get into any more details, but I suppose
it simply calculates the span from epoc with 30 day months. Oops. ChatGPT even suggested to use `JUSTIFY_HOURS`, which is
even more incorrect. I can't even imagine what it tried to do there.

Fine, let's do it hourself, *sigh*:

```sql
INSERT INTO Measurement (value, time)
SELECT
  generate_series(0, (SELECT EXTRACT(EPOCH FROM 
                     '2024-07-01 00:00:00+00'::timestamp - 
                     '2024-01-01 00:00:00+00'::timestamp) / 3600 AS hours_difference), 1) 
                     as value,
  generate_series(
    '2024-01-01 00:00:00+00'::timestamptz,
    '2024-07-01 00:00:00+00'::timestamptz,
    '1 hour'::interval
  ) AS time;
```

BOOM! Six months of data. The annoying part starts immediately as we actually can't answer a question like "highest
value in January in Finland", since we are missing data from the first two hours of Finnish time. So let's use February.
Nothing special, datewise speaking, happened in February 2024, right?

# Careful with casts

Let's take one of the tasks: "Find the highest value and time during work daytime (after 7 and before 21 i.e.
7:00-20:59.59) in February in Finland". Since our data is an increasing series, and looking at the calendar, the highest
value should be the last Thursday 29th, at 20:00, so in utc 18:00. We write (ChatGPT wrote!) something like this:

```sql
SELECT value,
       time
FROM Measurement
WHERE EXTRACT(DOW FROM (time::timestamp AT TIME ZONE 'Europe/Helsinki')) BETWEEN 1 AND 5
  AND EXTRACT(HOUR FROM (time::timestamp AT TIME ZONE 'Europe/Helsinki')) BETWEEN 7 AND 20
  AND date_trunc('month', time, 'Europe/Helsinki') =
      date_trunc('month', '2024-02-01'::timestamp, 'Europe/Helsinki')
ORDER BY value DESC
LIMIT 1
```

This gives gives us `1437` at `2024-02-29 21:00:00.000000 +00:00`, which is wrong. Three hours after the correct value?
Can you spot the error?

There's a spurious cast `::timestamp` which casts `time` to type `TIMESTAMP WITHOUT TIMEZONE` i.e. it strips timezone
information out from the timestamp, then "converts it from Finnish time" i.e. shifts it two ours backward to get back to
UTC. And voíla - we have a stamp in the range, albeit all wrong. Here, the correct syntax is simply no casts, but we
could also cast with `::timestamptz`, which would solve our problem as well.

Sometimes PostgreSQL fails to implicit cast timestamps, so to be sure we just always use tz-version, right? Let's say we
need the first value of the month. We write something like this:

```sql
SELECT value, time FROM measurement 
WHERE time >= '2024-02-01'::timestamptz AT TIME ZONE 'Europe/Helsinki' 
ORDER BY time limit 1;
```
-> `746,2024-02-01 02:00:00.000000 +00:00`

Not quite. Now the logic works against our intention: 2024-02-01 is casted as UTC value (2024-02-01T00:00:00Z), then
converted to Helsinki time i.e. two hours forward. `::timestamp` does what we wanted here - assumes the date is in
Finnish time, and the end result is UTC timestamped (all PostgresSQL timestamps are UTC internally) correctly.

You can also use the `date_trunc` function, which takes a third parameter of the timezone. This might make the intention
more clear:

```sql
SELECT value,
       time
FROM Measurement
WHERE date_trunc('month', time, 'Europe/Helsinki') = date_trunc('month', '2024-02-01', 'Europe/Helsinki')
ORDER BY value ASC
LIMIT 1
```

Interestingly here, it doesn't matter if you cast '2024-02-01' in the date_trunc method - the result is the same. These
all produce the same value:

```sql
SELECT value,
       date_trunc('month', '2024-02-01'::timestamptz, 'Europe/Helsinki') as tz,
       date_trunc('month', '2024-02-01'::timestamp, 'Europe/Helsinki') as notz,
       date_trunc('month', '2024-02-01', 'Europe/Helsinki') as plain,
       time
FROM Measurement
WHERE date_trunc('month', time, 'Europe/Helsinki') = date_trunc('month', '2024-02-01'::timestamptz, 'Europe/Helsinki')
ORDER BY value ASC
LIMIT 1
```

### Querying many key values

From our original questions, let's try to answer many key values at once:
- Average and peak workday value (and time)
- Average and peak "other time" values

We might end up with something like this:

```sql
WITH workday AS (SELECT value,
                        time
                 FROM Measurement
                 WHERE EXTRACT(DOW FROM (time AT TIME ZONE 'Europe/Helsinki')) BETWEEN 1 AND 5
                   AND EXTRACT(HOUR FROM (time AT TIME ZONE 'Europe/Helsinki')) BETWEEN 7 AND 20
                   AND date_trunc('month', time, 'Europe/Helsinki') =
                       date_trunc('month', '2024-02-01', 'Europe/Helsinki')),
     ohter_time as (SELECT value,
                           time
                    FROM Measurement
                    WHERE NOT (EXTRACT(DOW FROM (time AT TIME ZONE 'Europe/Helsinki')) BETWEEN 1 AND 5
                        AND EXTRACT(HOUR FROM (time AT TIME ZONE 'Europe/Helsinki')) BETWEEN 7 AND 20)
                      AND date_trunc('month', time, 'Europe/Helsinki') =
                          date_trunc('month', '2024-02-01', 'Europe/Helsinki')),
     max_work as (SELECT value AS work_max,
                         time  AS work_max_time
                  FROM workday
                  ORDER BY value DESC
                  LIMIT 1),
     avg_work AS (SELECT AVG(value) as average FROM workday),
     other_max as (SELECT value AS other_max_value,
                          time  AS other_max_value_time
                   FROM ohter_time
                   ORDER BY value DESC
                   LIMIT 1),
     avg_other AS (SELECT AVG(value) as average FROM workday)
SELECT m.*, a.*, om.*, ao.*
FROM max_work m,
     avg_work a,
     other_max om,
     avg_other ao;
```


ChatGPT does a decent job creating at least a scaffolding of the query, but it invents syntax and functions so you still
need to know what you are duing. And makes fun to debug castin issues, which was the inspiration for this post.
