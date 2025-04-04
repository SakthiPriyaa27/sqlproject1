create database loan_management_system;
use loan_management_system; 
select count(*) from customer_income;
select * from customer_income;

-- creating grade based on applicant_income

create table applicant_income_grade  as select *,
case
when applicantincome > 15000 then'Grade A'
when applicantincome > 9000 then 'Grade B'
when applicantincome > 5000 then 'Middle Class Customer'
else 'Low Class'
end as Grades,
case 
when applicantIncome < 5000 and property_area = 'Rural' then 3
when applicantIncome < 5000 and property_area = 'Semi Rural' then 3.5
when applicantIncome < 5000 and property_area = 'Urban' then 5 
when applicantIncome < 5000 and property_area = 'Semi Urban' then 2.5
else 7
end as monthly_interest_percentage from customer_income;

drop table applicant_income_grade;
select * from applicant_income_grade;

commit;


-- creating row level trigger for loan amount and statement level trigger for cibil score
-- row level trigger

create table loan_values(loan_id varchar (10)primary key,customer_id varchar (15),loan_amount text (25),
loan_amount_term int, cibil_score int);

delimiter //
create trigger loan_amount before insert on loan_values for each row
begin 
if new.loan_amount is null then set new.loan_amount = 'Loan Still Processing';
end if;	
end //
delimiter ;
show triggers;
drop trigger loan_amount;

insert into loan_values select * from loan_status;

drop table loan_values;
select * from loan_values;
select count(*) from loan_values where loan_amount= 'loan still processing' ;

   -- statement level trigger
   
    -- primary table 
create table loan_det(loan_id varchar (10)primary key,customer_id varchar (15),loan_amount text (25),
loan_amount_term int, cibil_score int);
drop table loan_det;
select * from loan_det;
select count(*) from loan_det;

    -- secondaty table
create table cibil_score_update (loan_id varchar(40), loan_amount varchar(100),
cibil_score int, cibil_score_status varchar(100)); 
desc cibil_score_update;
drop table cibil_score_update;
select * from cibil_score_update ;
select count(*) from cibil_score_update;

Delimiter //
create trigger cibil_score_update after insert on loan_det for each row
begin
insert into  cibil_score_update (loan_id, loan_amount, cibil_score, cibil_score_status)
values (new.loan_id,new.loan_amount,new.cibil_score,
case
when new.cibil_score > 900 then 'High cibil score'
when new.cibil_score > 750 then 'No penalty'
when new.cibil_score > 0 then 'Penalty customers'
else 'Reject customers (Cannot apply loan)'
end);
end //
Delimiter ;
show triggers;
drop trigger cibil_score_update;

 insert into Loan_det select * from loan_values;
select * from loan_det;
select count(*) from cibil_score_update where cibil_score_status = 'High cibil score';
select count(*) from cibil_score_update where cibil_score_status = 'no penalty';
select count(*) from cibil_score_update where cibil_score_status = 'penalty customers';
select count(*) from cibil_score_update where cibil_score_status = 'reject customers (cannot apply loan)';

select * from cibil_score_update;

select count(*) loan_det;

-- sheet-2
-- Then deleting the loan still processing and reject customers

delete from cibil_score_update where loan_amount= 'loan still processing' ;
delete from cibil_score_update where cibil_score_status='Reject customers (Cannot apply loan)'; 

select count(*) from cibil_score_update;
select * from cibil_score_update;

-- sheet 2
-- Update loan as integers
alter table cibil_score_update modify loan_amount varchar(50);
desc cibil_score_update;

-- sheet2
-- caluclation monthly interest

create table monthly_interest 
select a.*,c.loan_amount,c.cibil_score,c.cibil_score_status,
case 
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3/100))
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3.5/100))
when applicantIncome<5000 and Property_Area = "urban" then (c.loan_amount * (5/100))
when applicantIncome<5000 and Property_Area = "semi urban" then (c.loan_amount* (2.5/100))
else (c.loan_amount*(7/100))
end as monthly_interest_cal from applicant_income_grade a inner join cibil_score_update c  on c.loan_id=a.loan_id;
drop table monthly_interest;

-- table 3
-- annual intererst calculation
-- create table annual_interest 
select *,
monthly_interest_cal*12 as anuual_interest_calc from monthly_interest ;

select * from annual_interest;
drop table annual_interest;

-- table - 4 
-- customer info table 
-- Update gender and age based on customer id 
select * from customer_info; 

update customer_info set Gender = case
when Customer_id in ('IP43006', 'IP43016', 'IP43508', 'IP43577', 'IP43589', 'IP43593') then 'Female'
when Customer_id in ('IP43018', 'IP43038') then 'Male'
else Gender
end,
Age = case 
when Customer_ID = 'IP43007' then 45
when Customer_ID = 'IP43009' then  32
else Age
end;

select * from applicant_income_grade;
select* from annual_interest ;
select* from cibil_score_update;
select * from customer_info;
select * from country_state;
select * from region_info;

-- Join all the 5 tables without repeating the fields

drop table table_1;

create table table_1 select aig.*, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed 
from applicant_income_grade as aig
inner join annual_interest as ai on aig.loan_id=ai.loan_id
inner join cibil_score_update as c on ai.loan_id=c.loan_id
inner join customer_info as d on aig.customer_id=d.customer_id
inner join country_state as cs on aig.customer_id=cs.customer_id
inner join region_info as r on r.region_id=cs.region_id;


select * from table_1;
select count(*) from table_1;

-- output 2 
-- find the mismatch details using joins - output 2

select * from region_info;
select * from country_state;
select * from customer_info;

create table table_2 select r.*,cs.customer_id,cs.loan_id,cs.customer_name,cs.postal_code,cs.segment,cs.state,
cd.gender,cd.age,cd.married,cd.education,cd.self_employed from region_info r 
left join country_state cs on r.region_id=cs.region_id
left join customer_info cd on r.region_id=cd.region_id where cs.customer_id is null;
select * from table_2;

-- Filter high cibil score - output 3

create table  table_3 select aig.*, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from applicant_income_grade aig
inner join annual_interest ai on aig.loan_id=ai.loan_id
inner join cibil_score_update c on ai.loan_id=c.loan_id
inner join customer_info d on aig.customer_id=d.customer_id
inner join country_state cs on aig.customer_id=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where ai.cibil_score_status = "High cibil score";

drop table table_3;
select * from table_3;
select count(*) from table_3 ;

-- Filter home office and corporate - output 4

create table table_4 select aig.loan_id,aig.customer_id,aig.applicantincome,aig.coapplicantincome,aig.property_area,aig.loan_status,aig.grades,
aig.monthly_interest_percentage, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from applicant_income_grade aig
inner join annual_interest ai on aig.loan_id=ai.loan_id
inner join cibil_score_update c on ai.loan_id=c.loan_id
inner join customer_info d on aig.customer_id=d.customer_id
inner join country_state cs on aig.customer_id=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where segment in("Home office", "corporate");

select * from table_4;
select count(*) from table_4;

-- Store all the outputs as procedure
drop procedure final_output;
delimiter // 
create procedure final_output ()
select * from annual_interest;
select * from applicant_income_grade;
select * from cibil_score_update;
select * from country_state;
select * from customer_income;
select * from customer_info;
select * from loan_det;
select * from loan_values;
select * from monthly_interest;
select* from region_info;
select * from table_1;
select * from table_2;
select * from table_3;
select * from table_4;
end //
delimiter ;

call final_output();
select count(*) from cibil_score_update ;

