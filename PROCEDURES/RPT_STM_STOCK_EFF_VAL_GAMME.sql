--------------------------------------------------------
--  DDL for Procedure RPT_STM_STOCK_EFF_VAL_GAMME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_STOCK_EFF_VAL_GAMME" (
   arefcursor     IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2,
   parameter_9      IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   parameter_11     IN       VARCHAR2,
   parameter_12     IN       NUMBER,
   parameter_13     IN       NUMBER,
   parameter_14     IN       NUMBER,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/*
*Description USED FOR REPORT STM_STOCK_EFFECTIF_VALORISED_GAMME.RPT

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 21 FEb 2009
* @LASTUPDATE 26 jan 2010
** @PARAM PARAMETER_0     Mode de Prix  (0: Mode de gestion, 1: PRCS, 2 PRC, 3 PRF, 4 prix dernier mouvement)
* @PARAM PARAMETER_1     Out Category (0: no 1: yes)
* @PARAM PARAMETER_6     Name of selected category ( 0:All)
* @PARAM PARAMETER_7     Date value (yyyymmdd)
* @PARAM PARAMETER_8     Short description (0:No - 1:Yes)
* @PARAM PARAMETER_9     Long description (0:No - 1:Yes)
* @PARAM PARAMETER_10    Free description (0:No - 1:Yes)
* @PARAM PARAMETER_11    Product Selection (1:All)
* @PARAM PARAMETER_12    Gco_good_id (com_list if PARAMETER_11 =0)
* @PARAM PARAMETER_13    Stm_Stock_id (com_list)
* @PARAM PARAMETER_14    Stm_Location_id (com_list)
* @PARAM procuser_lanid  User language
*/

   CATEGORY                  VARCHAR2 (4000 CHAR);
BEGIN
   IF parameter_6 <> '0'
   THEN
      CATEGORY := parameter_6;
   ELSE
      CATEGORY := '*';
   END IF;

IF PARAMETER_11 = '1' THEN -- ALL PRODUCTS

   OPEN arefcursor FOR
      SELECT 'GROUP_STRING' group_string, goo.gco_good_id,
             goo.c_management_mode, goo.goo_major_reference,
             goo.gco_good_category_wording, lin.dic_good_line_wording,
             fam.dic_good_family_wording, MOD.dic_good_model_wording,
             grp.dic_good_group_wording, goo.goo_number_of_decimal,
             fcp.cpr_price,
             price,
             qty,
             qty_cc,
             qty_cf,
             case when PARAMETER_8 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01')
             ELSE ''
             END  des_short_description,
             case when PARAMETER_9 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01')
             ELSE ''
             END  des_long_description,
             case when PARAMETER_10 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01')
             ELSE ''
             END  des_free_description
      FROM (select
                    gco_functions.getcostpricewithmanagementmode
                                  (goo.gco_good_id, NULL, DECODE (parameter_0, '0', goo.c_management_mode, parameter_0), SYSDATE ) price,
                    NVL(rpt_functions.getqtystockt (goo.gco_good_id, parameter_14 ),0) qty,
                    NVL(rpt_functions.getqtycct (goo.gco_good_id, parameter_14 ),0) qty_cc,
                    NVL(rpt_functions.getqtycft (goo.gco_good_id, parameter_14 ),0) qty_cf,
                    GOO.gco_good_id,
                    c_management_mode,
                    goo_major_reference,
                    goo_number_of_decimal,
                    dic_good_line_id,
                    dic_good_family_id,
                    dic_good_model_id,
                    dic_good_group_id,
                    cat.gco_good_category_wording
              FROM  gco_good goo, gco_good_category cat,  gco_product pdt
              WHERE goo.gco_good_id = pdt.gco_good_id
                    AND goo.gco_good_category_id = cat.gco_good_category_id
                    AND pdt.pdt_stock_management in (1,2)
                    AND cat.gco_good_category_wording LIKE like_param (CATEGORY)
      ) goo,
      dic_good_line lin,
      dic_good_family fam,
      dic_good_model MOD,
      dic_good_group grp,
      (SELECT gco_good_id, cpr_price
                FROM ptc_fixed_costprice
               WHERE c_costprice_status = 'ACT' AND cpr_default = 1) fcp
       WHERE goo.dic_good_line_id = lin.dic_good_line_id(+)
         AND goo.dic_good_family_id = fam.dic_good_family_id(+)
         AND goo.dic_good_model_id = MOD.dic_good_model_id(+)
         AND goo.dic_good_group_id = grp.dic_good_group_id(+)
         AND goo.gco_good_id = fcp.gco_good_id(+)
         AND qty <> 0 and qty_cc <> 0 and qty_cf <> 0;

ELSE   --SELECTION OF PRODUCTS

   OPEN arefcursor FOR
      SELECT 'GROUP_STRING' group_string, goo.gco_good_id,
             goo.c_management_mode, goo.goo_major_reference,
             cat.gco_good_category_wording, lin.dic_good_line_wording,
             fam.dic_good_family_wording, MOD.dic_good_model_wording,
             grp.dic_good_group_wording, goo.goo_number_of_decimal,
             fcp.cpr_price,
             gco_functions.getcostpricewithmanagementmode
                                       (goo.gco_good_id,
                                        NULL,
                                        DECODE (parameter_0,
                                                '0', goo.c_management_mode,
                                                parameter_0
                                               ),
                                        SYSDATE
                                       ) price,
              NVL(rpt_functions.getqtystockt (goo.gco_good_id,
                                          parameter_14
                                         ),0) qty,
              NVL(rpt_functions.getqtycct (goo.gco_good_id,
                                       parameter_14
                                      ),0) qty_cc,
             NVL(rpt_functions.getqtycft (goo.gco_good_id,
                                       parameter_14
                                      ),0) qty_cf,
             case when PARAMETER_8 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01')
             ELSE ''
             END  des_short_description,
             case when PARAMETER_9 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01')
             ELSE ''
             END  des_long_description,
             case when PARAMETER_10 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01')
             ELSE ''
             END  des_free_description
        FROM gco_good goo,
             gco_product pdt,
             gco_good_category cat,
             dic_good_line lin,
             dic_good_family fam,
             dic_good_model MOD,
             dic_good_group grp,
             com_list com,
             (SELECT gco_good_id, cpr_price
                FROM ptc_fixed_costprice
               WHERE c_costprice_status = 'ACT' AND cpr_default = 1) fcp
       WHERE goo.gco_good_id = pdt.gco_good_id
         AND goo.gco_good_category_id = cat.gco_good_category_id
         AND goo.dic_good_line_id = lin.dic_good_line_id(+)
         AND goo.dic_good_family_id = fam.dic_good_family_id(+)
         AND goo.dic_good_model_id = MOD.dic_good_model_id(+)
         AND goo.dic_good_group_id = grp.dic_good_group_id(+)
         AND goo.gco_good_id = fcp.gco_good_id(+)
         AND pdt.pdt_stock_management in (1,2)
         AND goo.gco_good_id = com.lis_id_1
         AND com.lis_job_id = parameter_12
         AND com.lis_code = 'GCO_GOOD_ID'
         AND cat.gco_good_category_wording LIKE like_param (CATEGORY);

end if;

DELETE FROM COM_LIST WHERE COM_LIST_ID IN (PARAMETER_12,PARAMETER_13,PARAMETER_14);

commit;

END rpt_stm_stock_eff_val_gamme;
