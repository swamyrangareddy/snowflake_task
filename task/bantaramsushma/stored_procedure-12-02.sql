
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