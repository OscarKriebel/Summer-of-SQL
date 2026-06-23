--Get Report
SELECT *
FROM crime_scene_report
WHERE type = 'murder' AND city = 'SQL City' AND date = 20180115;

--Get Interview from Report Witnesses              
SELECT 
	interview.transcript,
	person.id AS person_id,
	person.name,
	person.license_id,
	person.ssn,
	person.address_number,
	person.address_street_name
FROM interview
INNER JOIN person
	ON interview.person_id = person.id
WHERE (name LIKE 'Annabel%' AND address_street_name = 'Franklin Ave') 
	OR (address_street_name = 'Northwestern Dr' 
		AND address_number = 
			(SELECT MAX(address_number) FROM person WHERE address_street_name = 'Northwestern Dr'));

            WITH witness AS (
  	SELECT
		check_in_date AS wit_date,
		check_in_time AS wit_in,
		check_out_time AS wit_out
	FROM get_fit_now_check_in AS c
	INNER JOIN get_fit_now_member AS m
		ON c.membership_id = m.id
	INNER JOIN person
		ON m.person_id = person.id
	WHERE person.id = 16371
);

--Find Criminal from Interviews
SELECT
	person.name,
	person.id,
	person.license_id,
	d.plate_number
FROM get_fit_now_member AS m
INNER JOIN get_fit_now_check_in AS c
	ON m.id = c.membership_id
INNER JOIN witness
	ON c.check_in_date = witness.wit_date
INNER JOIN person
	ON m.person_id = person.id
INNER JOIN drivers_license AS d
	ON person.license_id = d.id
WHERE m.id LIKE '48Z%' AND m.membership_status = 'gold' AND c.check_in_time < witness.wit_out AND d.plate_number LIKE '%H42W%';

--Find Criminal Interview
SELECT *
FROM interview
WHERE person_id = 67318;

--Find True Criminal
WITH concerts AS (
	SELECT 
  		person_id, 
  		COUNT(*) AS total
	FROM facebook_event_checkin
	WHERE event_name = 'SQL Symphony Concert' AND date BETWEEN 20171201 AND 20171231
	GROUP BY person_id
)

SELECT *
FROM person
INNER JOIN drivers_license AS d
	ON person.license_id = d.id
INNER JOIN income
	ON person.ssn = income.ssn
INNER JOIN concerts
	ON person.id = concerts.person_id
WHERE (d.height BETWEEN 65 AND 67) 
	AND gender = 'female' 
	AND hair_color = 'red'
	AND car_make = 'Tesla'
	AND car_model = 'Model S'
	AND concerts.total = 3
ORDER BY annual_income DESC;