-- L3_dim_branch 
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L3.L3_dim_branch` AS
SELECT
    branch_id
    ,branch_name
FROM `bubbly-monument-455614-i7.L2.L2_branch`;


-- L3_dim_contract
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L3.L3_dim_contract` AS
SELECT
    contract_id
    ,branch_id
    ,contract_valid_from
    ,contract_valid_to
    ,registration_end_reason
    ,CASE
      WHEN DATE_DIFF(contract_valid_to, contract_valid_from, day)/365.25 < 0.5 THEN 'less than half year'
      WHEN DATE_DIFF(contract_valid_to, contract_valid_from, day)/365.25 < 1 THEN 'less than 1 year'
      WHEN DATE_DIFF(contract_valid_to, contract_valid_from, day)/365.25 < 2 THEN 'less than 2 years'
      WHEN DATE_DIFF(contract_valid_to, contract_valid_from, day)/365.25 > 2 THEN 'more than 2 years'
      ELSE 'unknown'
    END AS contract_duration
    ,EXTRACT(YEAR FROM contract_valid_from) AS start_year_of_contract
    ,contract_status
    ,flag_prolongation
FROM `bubbly-monument-455614-i7.L2.L2_contract`
;

-- L3_dim_product_purchase
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L3.L3_dim_product_purchase` AS
SELECT
  product_purchase_id
  ,product_id
  ,product_name
  ,product_type
  ,product_valid_from
  ,product_valid_to
  ,unit
  ,flag_unlimited_product
FROM `bubbly-monument-455614-i7.L2.L2_product_purchase`;

-- L3_fact_invoice
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L3.L3_fact_invoice` AS
SELECT
  i.invoice_id,
  i.contract_id,
  pp.product_id,
  i.amount_w_vat,
  i.return_w_vat,
  (i.amount_w_vat - i.return_w_vat) AS total_paid,
  i.paid_date,
  i.date_issue
FROM `bubbly-monument-455614-i7.L2.L2_invoice` AS i
LEFT JOIN `bubbly-monument-455614-i7.L2.L2_product_purchase` AS pp
  ON i.contract_id = pp.contract_id;
