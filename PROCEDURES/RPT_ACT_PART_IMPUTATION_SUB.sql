--------------------------------------------------------
--  DDL for Procedure RPT_ACT_PART_IMPUTATION_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_PART_IMPUTATION_SUB" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_99   IN       NUMBER
)
/**
*Description  Used for report ACT_DOC_PRE_CTRL
*
*@created AWU 20 MAY 2009
*@lastUpdate
*@public
*@param PARAMETER_0 ACT_DOCUMENT_ID
*/
IS
BEGIN
   OPEN arefcursor FOR
      SELECT par.par_document, perc.per_name per_name_cus,
             perc.per_forename per_forname_cus, pers.per_name per_name_sup,
             pers.per_forename per_forename_sup
        FROM act_part_imputation par, pac_person perc, pac_person pers
       WHERE par.pac_custom_partner_id = perc.pac_person_id(+)
         AND par.pac_supplier_partner_id = pers.pac_person_id(+)
         AND par.act_document_id = parameter_99;
END rpt_act_part_imputation_sub;
