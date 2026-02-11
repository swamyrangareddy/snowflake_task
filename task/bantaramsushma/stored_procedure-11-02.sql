use role accountadmin;
use warehouse compute_wh;

CREATE OR REPLACE DATABASE practice;
CREATE OR REPLACE SCHEMA practice.snow_test;
use database practice;
use schema snow_test; 


create or replace procedure profit()
returns number
language SQL
AS
$$
DECLARE 
    cost_price number(5,2) default 100;
    result number(5,2);
BEGIN
    LET selling_price number(5,2) :=500;
      IF (selling_price > cost_price)
      THEN
      result := selling_price - cost_price;
      ELSE 
      result := cost_price - selling_price;
      END IF;

    return result;

END 
$$;

      
CALL profit()