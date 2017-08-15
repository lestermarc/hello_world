--------------------------------------------------------
--  DDL for Package Body VDOC_HRM_OEM_EXPENSES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_HRM_OEM_EXPENSES" 
IS
   PROCEDURE insert_expenses (
      pcschar_rec_id   IN   VARCHAR2,
      exp_comment      IN   VARCHAR2,
      exp_expenses     IN   CLOB
   )
   IS
   BEGIN
        /* Le tableau contient ceci :
        <?xml version="1.0" encoding="UTF-8"?>
      <exp_expenses>
        <ROW>
          <exp_date>2010-07-04 12:00:00.0</exp_date>
          <exp_type>01</exp_type>
          <exp_label>test</exp_label>
          <exp_division>000</exp_division>
          <exp_cda>999</exp_cda>
          <exp_pf />
          <exp_pj>null</exp_pj>
          <exp_record>null</exp_record>
          <exp_vat_no />
          <exp_vat_rate />
          <exp_amount>13.0</exp_amount>
          <exp_vat_amount />
          <exp_vat_code>100</exp_vat_code>
        </ROW>
        <ROW>
          <exp_date>2010-07-12 12:00:00.0</exp_date>
          <exp_type>01</exp_type>
          <exp_label>test2</exp_label>
          <exp_division>000</exp_division>
          <exp_cda>999</exp_cda>
          <exp_pf />
          <exp_pj>null</exp_pj>
          <exp_record>null</exp_record>
          <exp_vat_no />
          <exp_vat_rate />
          <exp_amount>13.0</exp_amount>
          <exp_vat_amount />
          <exp_vat_code>100</exp_vat_code>
        </ROW>
      </exp_expenses>*/

      --INSERT INTO log4me VALUES (exp_expenses);
      null;
   END;

   FUNCTION tax_amount (
      exp_amount     IN   act_det_tax.tax_vat_amount_lc%TYPE,
      exp_vat_code   IN   acs_account.acc_number%TYPE,
      exp_date       IN   TIMESTAMP
   )
      RETURN amount_type
   IS
      l_tax_id   acs_tax_code.acs_tax_code_id%TYPE;
   BEGIN
      SELECT acs_tax_code_id
        INTO l_tax_id
        FROM acs_tax_code
       WHERE EXISTS (
                SELECT 1
                  FROM acs_account
                 WHERE acs_account_id = acs_tax_code_id
                   AND acc_number = exp_vat_code);

      RETURN TRUNC (acs_function.calcvatamount (exp_amount,
                                                l_tax_id,
                                                'I',
                                                CAST (exp_date AS DATE),
                                                NULL,
                                                NULL,
                                                NULL
                                               ),
                    2
                   );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION total_summary (value_in IN CLOB DEFAULT EMPTY_CLOB)
      RETURN CLOB
   IS
      l_result   CLOB;
   BEGIN
      IF DBMS_LOB.getlength (value_in) > 0
      THEN
         SELECT TO_CHAR (SUM (TO_NUMBER (EXTRACTVALUE (COLUMN_VALUE,
                                                       'exp_amount'
                                                      )
                                        )
                             )
                        )
           INTO l_result
           FROM TABLE (XMLSEQUENCE (EXTRACT (XMLTYPE (value_in),
                                             '//ROW/exp_amount'
                                            )
                                   )
                      ) a;
      ELSE
         l_result := '0';
      END IF;

      RETURN l_result;
   END;
END;
