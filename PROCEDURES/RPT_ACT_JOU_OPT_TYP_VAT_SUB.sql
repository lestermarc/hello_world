--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOU_OPT_TYP_VAT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOU_OPT_TYP_VAT_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report ACT_JOURNAL_OPERATION_TYP

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_1     DIC_OPERATION_TYP_ID from
* @PARAM PARAMETER_2     DIC_OPERATION_TYP_ID to
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cat.dic_operation_typ_id, vat_acc.acc_number,
             v_tax.tax_vat_amount_lc, v_tax.ht_lc, v_tax.ttc_lc,
             v_imp.act_financial_imputation_id, v_imp.imf_primary,
             v_imp.c_genre_transaction
        FROM v_act_fin_imputation_date v_imp,
             v_act_det_tax v_tax,
             act_document atd,
             acj_catalogue_document cat,
             acs_account vat_acc
       WHERE v_imp.act_financial_imputation_id = v_tax.act_financial_imputation_id(+)
         AND v_imp.act_document_id = atd.act_document_id
         AND atd.acj_catalogue_document_id = cat.acj_catalogue_document_id
         AND v_imp.acs_tax_code_id = vat_acc.acs_account_id(+)
         AND (       (parameter_1 <> parameter_2)
                 AND (parameter_1 IS NOT NULL AND parameter_2 IS NOT NULL)
                 AND (    cat.dic_operation_typ_id >= parameter_1
                      AND cat.dic_operation_typ_id <= parameter_2
                     )
              OR (    (parameter_1 <> parameter_2)
                  AND (parameter_1 IS NOT NULL AND parameter_2 IS NULL)
                  AND (cat.dic_operation_typ_id >= parameter_1)
                 )
              OR (    (parameter_1 <> parameter_2)
                  AND (parameter_1 IS NULL AND parameter_2 IS NOT NULL)
                  AND (cat.dic_operation_typ_id <= parameter_2)
                 )
              OR (    (    parameter_1 = parameter_2
                       AND parameter_1 IS NOT NULL
                       AND parameter_2 IS NOT NULL
                      )
                  AND (cat.dic_operation_typ_id = parameter_1)
                 )
              OR (parameter_1 IS NULL AND parameter_2 IS NULL)
             )
         AND (v_tax.act_det_tax_id IS NULL OR nvl(v_tax.tax_tmp_vat_encashment, 0) = 0
             );
END rpt_act_jou_opt_typ_vat_sub;
