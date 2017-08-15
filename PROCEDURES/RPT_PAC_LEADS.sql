--------------------------------------------------------
--  DDL for Procedure RPT_PAC_LEADS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_LEADS" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR,
   parameter_1   IN       VARCHAR
)
IS
/**
 Description - used for the report PAC_LEADS

 @author AWU Jan 2009
 @lastupdate VHA 08 May 2012
 @public
 @PARAM  parameter_0  LEA_DATE
 @PARAM  parameter_1  LEA_DATE
*/
BEGIN
   OPEN arefcursor FOR
      SELECT lea.pac_person_id, lea.lea_label, lea.dic_lea_category_id,
             lea.dic_lea_subcategory_id, lea.dic_lea_classification_id,
             lea.c_opportunity_status, lea.dic_lea_rating_id,
             lea.lea_budget_amount, lea.lea_project_begin_date,
             lea.lea_project_end_date,
             lea.lea_company_name, per.per_name,
             nvl(rep.rep_descr,pcs.pc_functions.translateword2 ('Pas de représentant',1)) rep_descr,
             nvl(ste.ste_description,pcs.pc_functions.translateword2 ('Pas de territoire de vente',1)) ste_description,
             cur.currency
        FROM pac_lead lea,
             pac_person per,
             pac_sale_territory ste,
             pac_representative rep,
             pcs.pc_curr cur
       WHERE lea.pac_person_id = per.pac_person_id
         AND lea.pac_sale_territory_id = ste.pac_sale_territory_id(+)
         AND lea.pac_representative_id = rep.pac_representative_id(+)
         AND lea.pc_curr_id = cur.pc_curr_id(+)
         AND lea.lea_date BETWEEN TO_DATE (parameter_0, 'YYYY-MM-DD')
                              AND TO_DATE (parameter_1, 'YYYY-MM-DD');
END rpt_pac_leads;
