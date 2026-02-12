
---with global varable
create or replace procedure my_sp()
returns object
language sql

as

declare  
    --global_var boolean default True;  -- result : True
    global_var boolean;                 -- result : null
    global_var_02 number default 10;
    global_var_03 text default 'sample text';
    global_var_04 date default current_date();
    global_var_05 timestamp default current_timestamp();
    global_var_06 array default '[1,2,3]';
    global_var_07 variant  default parse_json('{"key":"value"}');
    global_var_08 object default  {'key':'value'};
begin 
    return global_var_08;

end;

call my_sp();


create or replace table customer_ta (
id number primary key,
emp_name string,
flag_val number
);

insert into customer_ta(id,emp_name,flag_val)
values(1,'ravi',-1),
(2,'raj',1),
(3,'rakesh',-1);

create or replace procedure deleting_inactive_flag()
returns text
language sql
as
declare 
    flag_v number(1) default -1;
begin 
    let sql_stat := 'delete from customer_ta where flag_val =' || flag_v;

    execute immediate sql_stat;

    return 'inactive customers deleted';
end;

call deleting_inactive_flag(); 

select * from customer_ta;