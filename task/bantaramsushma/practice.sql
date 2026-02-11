use role sysadmin;
use warehouse compute_wh;

CREATE OR REPLACE DATABASE practice;
CREATE OR REPLACE SCHEMA practice.snow_test;
use database practice;
use schema snow_test; 
SELECT CURRENT_ROLE(),
       CURRENT_WAREHOUSE(),
       CURRENT_DATABASE(),
       CURRENT_SCHEMA();
create or replace table emp
(
  review_id INT,
    review_text STRING
);

INSERT INTO emp VALUES
(1, 'Delivery was fast and product quality is excellent'),
(2, 'Package arrived late and customer service was poor'),
(3, 'Very happy with the purchase, will order again'),
(4, 'Worst experience, refund process is too slow');

select * from emp;
--sentiment
select review_text,snowflake.cortex.sentiment(review_text) as sentiment
from emp;



--summarize

select snowflake.cortex.summarize(
listagg(review_text,'.')) as overall_summary
from emp;

SELECT SNOWFLAKE.CORTEX.SUMMARIZE(
  'Delivery was fast and product quality is excellent.
   Package arrived late and customer service was poor.
   Very happy with the purchase, will order again.
   Worst experience, refund process is too slow.
   Support team was helpful and resolved the issue.
   Product packaging was damaged during transit.'
);

--answer
--select snowflake.cortex.answer(
---review_text,
--'Is the customer happy?'
--) as answer 
--from emp;

/*CREATE OR REPLACE TABLE support_docs (
    doc_id INT,
    content STRING
);

INSERT INTO support_docs VALUES
(1, 'Refunds are processed within 5 business days'),
(2, 'Orders are shipped within 24 hours'),
(3, 'Customer support is available 24/7 via chat'),
(4, 'Delivery delays may happen during festivals');



SHOW TABLES LIKE 'SUPPORT_DOCS';
DESC TABLE support_docs;

ALTER TABLE practice.snow_test.support_docs
ADD SEARCH OPTIMIZATION ON (content);

SHOW PARAMETERS LIKE '%SEARCH_OPTIMIZATION%';

CREATE OR REPLACE CORTEX SEARCH SERVICE help_search
ON content
FROM support_docs;

SELECT *
FROM help_search
WHERE SEARCH('How long does refund take?');*/


CREATE OR REPLACE TABLE invoices (
  invoice_id INT AUTOINCREMENT,
  invoice_text STRING
);

INSERT INTO invoices (invoice_text)
VALUES (
'Invoice Number: INV-2345
Vendor Name: ABC Technologies Pvt Ltd
Invoice Date: 10-Jan-2024
GST Number: 29ABCDE1234F1Z5
Total Amount: ₹45,200
Tax: ₹3,200
Payment Due Date: 20-Jan-2024'
);

USE ROLE ACCOUNTADMIN;

SELECT CURRENT_ROLE();


SELECT
  SNOWFLAKE.CORTEX.AI_EXTRACT(
      invoice_text,
      OBJECT_CONSTRUCT(
          'invoice_number', 'Invoice Number',
          'vendor_name', 'Vendor Name',
          'invoice_date', 'Invoice Date',
          'total_amount', 'Total Amount',
          'tax', 'Tax',
          'gst_number', 'GST Number'
      )
  ) AS extracted_data
FROM invoices;

