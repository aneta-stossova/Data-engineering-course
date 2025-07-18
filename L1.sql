-- L1_google_sheets 
-- L1_status
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_status` AS
SELECT
  CAST(id_status AS INT) AS product_status_id -- PK
  ,TRIM(LOWER(status_name)) AS product_status_name -- TRIM and LOWER are used to ensure consistency in text fields
  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_update_date
FROM
  `bubbly-monument-455614-i7.L0_google_sheets.status`
WHERE id_status IS NOT NULL
  AND status_name IS NOT NULL
  -- checking unique IDs
QUALIFY ROW_NUMBER() OVER(PARTITION BY product_status_id) = 1;

-- L1_branch 
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_branch` AS
SELECT
 SAFE_CAST(id_branch AS INT) AS branch_id -- PK
  ,TRIM(LOWER(branch_name)) AS branch_name -- TRIM and LOWER are used to ensure consistency in text fields
  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_status_update_date
FROM `bubbly-monument-455614-i7.L0_google_sheets.branch`
WHERE SAFE_CAST(id_branch AS INT) IS NOT NULL;


-- L1_product
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_product` AS
SELECT
  CAST(id_product AS INT) AS product_id -- PK
  ,TRIM(LOWER(name)) AS product_name -- TRIM and LOWER are used to ensure consistency in text fields
  ,TRIM(LOWER(type)) AS product_type
  ,TRIM(LOWER(category)) AS product_category
  ,CAST(is_vat_applicable AS BOOL) AS is_vat_applicable
  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_update_date
FROM `bubbly-monument-455614-i7.L0_google_sheets.product`
WHERE id_product IS NOT NULL
  AND name IS NOT NULL
-- unique id
QUALIFY ROW_NUMBER() OVER(PARTITION BY product_id) = 1;

-- L1_accounting_system
-- L1_invoice
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_invoice` AS
SELECT
  CAST(id_invoice AS INT) AS invoice_id --PK
  ,CAST(id_invoice_old AS INT) AS invoice_previous_id
  ,CAST(invoice_id_contract AS INT) AS contract_id --FK
  ,CAST(status AS INT) AS invoice_status_id
  ,CAST(id_branch AS INT) AS branch_id --FK
-- Invoice status. Invoice status < 100 have been issued. >= 100 - not issued
  ,IF(status < 100, TRUE, FALSE) AS flag_invoice_issued
  ,DATE(TIMESTAMP(date), 'Europe/Prague') AS date_issue
  ,DATE(TIMESTAMP(scadent), 'Europe/Prague') AS due_date
  ,DATE(TIMESTAMP(date_paid), 'Europe/Prague') AS paid_date
  ,DATE(TIMESTAMP(start_date), 'Europe/Prague') AS start_date
  ,DATE(TIMESTAMP(end_date), 'Europe/Prague') AS end_date
  ,DATE(TIMESTAMP(date_insert), 'Europe/Prague') AS insert_date
  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS update_date
  ,CAST(value AS FLOAT64) AS amount_w_vat
  ,CAST(payed AS FLOAT64) AS amount_payed
  ,CAST(flag_paid_currier AS BOOL) AS flag_paid_currier
  ,CAST(invoice_type AS INT) AS invoice_type_id
-- Invoice_type:1 - invoice, 2 - return, 3 - credit_note, 4 - other
  ,CASE
    WHEN invoice_type = 1 THEN "invoice"
    WHEN invoice_type = 2 THEN "return"
    WHEN invoice_type = 3 THEN "credit_note"
    WHEN invoice_type = 4 THEN "other"
END AS invoice_type
  ,number AS invoice_number
  ,CAST(value_storno AS FLOAT64) AS return_w_vat
FROM `bubbly-monument-455614-i7.L0_accounting_system.invoice`;

-- L1_invoice_load
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_invoice_load` AS
SELECT
  CAST(id_load AS INT) AS invoice_load_id -- PK
  ,CAST(id_contract AS INT) AS contract_id -- FK
  ,CAST(id_package AS INT) AS package_id -- FK
  ,CAST(id_invoice AS INT) AS invoice_id
  ,CAST(id_package_template AS INT) AS product_id -- FK
  ,CAST(notlei AS FLOAT64) AS price_wo_vat_usd
  ,CAST(tva AS INT) AS vat_rate
  ,CAST(value AS FLOAT64) AS price_w_vat_usd
  ,CAST(payed AS FLOAT64) AS paid_w_vat_usd
  -- Following CASE expression is used to normalize inconsistent unit values (e.g. typos, different languages, or     encoding issues)
  ,CASE
    WHEN um IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') THEN 'month'
    WHEN um = 'kus' THEN "item"
    WHEN um = 'min' THEN "minutes"
    WHEN um = 'den' THEN "day"
    WHEN um = '0' THEN null
    ELSE um
  END AS unit
  ,TRIM(LOWER(currency)) AS currency
  ,CAST(quantity AS FLOAT64) AS quantity
  ,DATE(TIMESTAMP(start_date), 'Europe/Prague') AS start_date
  ,DATE(TIMESTAMP(end_date), 'Europe/Prague') AS end_date
  ,DATE(TIMESTAMP(date_insert), 'Europe/Prague') AS date_insert
  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS date_update
FROM `bubbly-monument-455614-i7.L0_accounting_system.invoices_load`;

-- L1_contract
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_contract` AS
SELECT
  CAST(id_contract AS INT) AS contract_id -- PK
  ,CAST(id_branch AS INT) AS branch_id -- FK
  ,DATE(TIMESTAMP(date_contract_valid_from), 'Europe/Prague') AS contract_valid_from
  ,DATE(TIMESTAMP(date_contract_valid_to), 'Europe/Prague') AS contract_valid_to
  ,DATE(TIMESTAMP(date_registered), 'Europe/Prague') AS registered_date
  ,DATE(TIMESTAMP(date_signed), 'Europe/Prague') AS signed_date
  ,DATE(TIMESTAMP(activation_process_date), 'Europe/Prague') AS activation_process_date
  ,DATE(TIMESTAMP(prolongation_date), 'Europe/Prague') AS prolongation_date
  ,TRIM(LOWER(registration_end_reason)) AS registration_end_reason -- TRIM and LOWER are used to ensure consistency in text fields
  ,CAST(flag_prolongation AS BOOL) AS flag_prolongation
  ,CAST(flag_send_inv_email AS BOOL) AS flag_sent_email
  ,TRIM(LOWER(contract_status)) AS contract_status
FROM `bubbly-monument-455614-i7.L0_crm.contract`;

-- L1_product_purchase
CREATE OR REPLACE VIEW `bubbly-monument-455614-i7.L1.L1_product_purchase` AS
SELECT
  CAST(pp.id_package AS INT) AS product_purchase_id -- PK
  ,CAST(pp.id_contract AS INT) AS contract_id -- FK
  ,CAST(pp.id_package_template AS INT) AS product_id -- FK
  ,DATE(TIMESTAMP(pp.date_insert), 'Europe/Prague') AS create_date
  ,DATE(TIMESTAMP(pp.start_date), 'Europe/Prague') AS product_valid_from
  ,DATE(TIMESTAMP(pp.end_date), 'Europe/Prague') AS product_valid_to
  ,CAST(pp.fee AS FLOAT64) AS price_wo_vat
  ,DATE(TIMESTAMP(pp.date_update), 'Europe/Prague') AS update_date
  ,CAST(pp.package_status AS INT) AS product_status_id -- FK
  ,s.product_status_name AS product_status
  ,p.product_name AS product_name
  ,p.product_type AS product_type
  ,p.product_category AS product_category 
  -- Following CASE expression is used to normalize inconsistent unit values (e.g. typos, different languages, or     encoding issues)
  ,CASE
    WHEN measure_unit IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') THEN 'month'
    WHEN measure_unit = 'kus' THEN "item"
    WHEN measure_unit = 'min' THEN "minutes"
    WHEN measure_unit = 'den' THEN "day"
END AS unit
FROM `bubbly-monument-455614-i7.L0_crm.product_purchase` AS pp
LEFT JOIN `bubbly-monument-455614-i7.L1.L1_product` AS p
  ON pp.id_package_template = p.product_id
LEFT JOIN `bubbly-monument-455614-i7.L1.L1_status` AS s
  ON pp.package_status = s.product_status_id
;
