-- DATA CLEANING AND MANIPULATION--------------------------------------------------------------------------------------------------------

select * from HR_Data

-- The termdate column has the word UTC in the column which makes it impossible to change the data type from str to Datetime
-- so i removed the UTC word from the dates
Update hr_data
set termdate = REPLACE(termdate, ' UTC', '')

-- The script below changes the termdate column data type from string to datetime
alter table hr_data
alter column termdate
datetime

-- The script below standardize my data so as to display Accountant for all job title that displays accountant I, II, III, IV
-- and for all other job titles that fall into the same category
update HR_Data
set jobtitle = Ltrim(Rtrim(
	case
	when jobtitle like '% I' then
left(jobtitle, len(jobtitle) - 2)
	when jobtitle like '% II' then
left(jobtitle, len(jobtitle) - 3)
	when jobtitle like '% III' then
left(jobtitle, len(jobtitle) - 4)
	when jobtitle like '% IV' then
left(jobtitle, len(jobtitle) - 3)
	when jobtitle like '% V' then
left(jobtitle, len(jobtitle) - 2)
	Else jobtitle
	end))
	
-- I used the below script to check for outliers in the Birthdate column but fortunately there was none
select datediff(year, birthdate, getdate()) as age
from HR_Data 
where datediff(year, birthdate, getdate()) > 60

-- Added the Age column
Alter table Hr_data
	add Age as
	datediff(Year, birthdate, getdate())

-- Removed 5,304 rows where the birth date and hire date has less than 18yrs difference as that is child labour
delete 
from HR_Data
where tenure_yrs > (Age - 18)

-- Added the tenure year column
alter table hr_data
	add Tenure_Yrs as
	datediff(YEAR, hire_date,
isnull(termdate, getdate()))

-- There was a typo in the job title column which the below script corrects, Says Relationshiop manager instead of Relationship Manager
update HR_Data
set jobtitle = 'Relationship Manager'
where jobtitle = 'Relationshiop Manager'

-- The below script check if there are any future date in the hire date column but there was none
select * from HR_Data
where hire_date > GETDATE()


-- The script below allows me to view my table description and column data types
exec sp_help 'hr_data'


-- EXPLORATORY DATA ANALYSIS (EDA)--------------------------------------------------------------------------------------------------------

-- Main Table
select *
from HR_Data

-- Active Employees
select id from HR_Data
where termdate is null

-- Terminated Employees
select id from HR_Data
where termdate is not null

-- Employees Employment Status
select id, first_name,gender,
	case when termdate is null then 'Active'
	else 'terminated'
	end as employment_status
	from HR_Data

-- Employee Turnover Rate
select (count(case when termdate is not null then 1 end) * 1.0) /
count(*) * 100 as Turnover_Rate from HR_Data

-- Turnover Rate By Department
select department, (count(case when termdate is not null then 1 end) * 1.0) /
count(*) * 100 as Turnover_Rate from HR_Data
group by department

-- Hire To Termination Ratio
select count(case when hire_date is not null then 1 end) * 1.0 /
count(case when termdate is not null then 1 end) as Hire_To_Term_Ratio
from HR_Data

-- Average Lenght Of Employment
select id,
	round(
	avg(
		cast(datediff(day, hire_date,
	isnull(termdate, getdate())) as float) / 365),2)
	as avg_Length from HR_Data
	where hire_date is not null
	group by id

-- Tenure Distribution
select id,department, gender, race,
	case when tenure_Yrs < 1 then '0-1 Years'
	when tenure_yrs between 1 and 3 then '1-3 Years'
	when tenure_yrs between 3 and 5 then '3-5 Years'
	when tenure_yrs between 5 and 10 then '5-10 Years'
	else '10+ Years'
	end as Tenure_Bucket from HR_Data

-- Age Grouping
select Id,
	case when age between 18 and 30 then '18-30'
	when age between 30 and 40 then '30-40'
	when age between 40 and 50 then '40-50'
	else '50+'
	end as Age_Group from HR_Data