-- L2_branch 
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L2.L2_branch` AS
SELECT
    branch_id
    ,branch_name
FROM `bubbly-monument-455614-i7.L1.L1_branch`
WHERE branch_name != 'unknown';


-- L2_product
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L2.L2_product` AS
SELECT
    product_id
    ,product_name
    ,product_type
    ,product_category
FROM `bubbly-monument-455614-i7.L1.L1_product`
WHERE product_category IN ('product','rent');

-- L2_invoice
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L2.L2_invoice` AS
SELECT
    invoice_id
    ,invoice_previous_id
    ,contract_id
    ,invoice_type
    ,ROW_NUMBER() OVER (PARTITION BY contract_id ORDER BY date_issue) as invoice_order
    -- Replacement of negative values with 0 because negative values are not valid in this context:
    ,CASE
        WHEN amount_w_vat < 0 THEN 0
        ELSE amount_w_vat
    END AS amount_w_vat
    -- Replacement of negative values with 0 because negative values are not valid in this context:
    ,CASE
        WHEN amount_w_vat < 0 THEN 0
        ELSE amount_w_vat
    END / 1.2 AS amount_wo_vat -- -- Calculating price without VAT (20%)
    ,return_w_vat
    ,invoice_status_id
    ,flag_invoice_issued
    ,date_issue
    ,due_date
    ,paid_date
    ,start_date
    ,end_date
    ,insert_date
    ,update_date
FROM `bubbly-monument-455614-i7.L1.L1_invoice`
WHERE invoice_type = 'invoice'
  AND flag_invoice_issued = TRUE;


-- L2_contract
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L2.L2_contract` AS
SELECT
    contract_id
    ,branch_id
    ,contract_valid_from
    ,contract_valid_to
    ,registered_date
    ,registration_end_reason
    ,signed_date
    ,activation_process_date
    ,prolongation_date
    ,flag_prolongation
    ,contract_status
    ,flag_sent_email
FROM `bubbly-monument-455614-i7.L1.L1_contract`
-- Filtering out invalid or incomplete contract records:
WHERE contract_valid_from IS NOT NULL -- ensures contract has a defined start date
  AND contract_valid_to IS NOT NULL -- ensures contract has a defined end date
  AND contract_valid_from < contract_valid_to -- avoids logically incorrect contracts (e.g. ending before they start)
  AND registered_date IS NOT NULL -- filters out unregistered or incomplete entries
;


-- L2_product_purchase
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L2.L2_product_purchase` AS
WITH cleaned_price AS (
  SELECT
    product_purchase_id
    ,product_id
    ,contract_id
    ,product_name
    ,product_type
    ,product_category
    ,product_status
    -- Replacement of negative values with 0 because negative values are not valid in this context
    ,CASE
      WHEN price_wo_vat < 0 THEN 0
      ELSE price_wo_vat
    END AS price_wo_vat
    ,unit
    ,product_valid_from
    ,product_valid_to
    ,IF(product_valid_from = '2035-12-31', TRUE, FALSE) AS flag_unlimited_product
    ,create_date
    ,update_date
  FROM `bubbly-monument-455614-i7.L1.L1_product_purchase`
  WHERE product_category IN ('product','rent')
    AND product_status IS NOT NULL
    AND product_status NOT IN ('canceled', 'canceled registration', 'disconnected')
)
SELECT
  *,
  -- Calculation of the price including VAT (20%) based on the price without VAT
  price_wo_vat * 1.2 AS price_w_vat
FROM cleaned_price;
