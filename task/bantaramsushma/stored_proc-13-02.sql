
use database practice;
use schema snow_test;

show tables;

select * from customer_ta;

create or replace table salary_table(
id number ,
gross_sal number,
emp_name string 


);

insert into salary_table(id,gross_sal,emp_name)
values(1,120000,'swathi');

select * from salary_table;

--------with identifier------------------

create or replace procedure my_context()
returns number(10,2)
language sql
 as 
 declare 
    its_sal_table text default 'salary_table';
    pk_val number default 1;
    tax_per number(12,2) default 0.22;
    taxable_sal number(12,2);
begin 
    let gross_sal_val number(12,2) default (select gross_sal from identifier(:its_sal_table) where id = :pk_val);

    taxable_sal := gross_sal_val * tax_per;
    return taxable_sal;

end;

call my_context();