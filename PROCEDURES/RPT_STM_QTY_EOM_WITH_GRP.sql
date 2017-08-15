--------------------------------------------------------
--  DDL for Procedure RPT_STM_QTY_EOM_WITH_GRP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_QTY_EOM_WITH_GRP" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
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
/**
*Description USED FOR REPORT STM_QTY_END_OF_MONTH_WITH_GROUP.RPT
* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 21 Feb 2009
* @LASTUPDATE MZH 16 Apr 2010
* @PUBLIC
* @PARAM PARAMETER_0     Mode de Prix  (0: Mode de gestion, 1: PRCS, 2 PRC, 3 PRF, 4 prix dernier mouvement)
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
   vpc_lang_id               pcs.pc_lang.pc_lang_id%TYPE;
   p_category_wording        VARCHAR2 (200 CHAR);
   t_date                    DATE;
   vlis_job_id               NUMBER(12);

BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   IF parameter_6 <> '0'
   THEN
      p_category_wording := parameter_6;
   ELSE
      p_category_wording := '*';
   END IF;

   t_date := TO_DATE (parameter_7, 'YYYYMMDD');



   SELECT
   INIT_ID_SEQ.NEXTVAL INTO vlis_job_id
   FROM
   DUAL;

   RPT_FUNCTIONS.INSERTSELECTEDSTOCKATDATE(parameter_7,parameter_14,parameter_11,parameter_12,vlis_job_id);

IF PARAMETER_11 = '1' THEN -- ALL PRODUCTS
   OPEN arefcursor FOR
      SELECT 'GROUP_STRING' group_string, fam.dic_good_family_wording,
             grp.dic_good_group_wording, lne.dic_good_line_wording,
             MOD.dic_good_model_wording, goo1.gco_good_id, goo1.c_good_status,
             goo1.c_management_mode, goo1.goo_major_reference,
             goo1.DIC_UNIT_OF_MEASURE_ID,
             goo1.goo_number_of_decimal, goo1.gco_good_category_wording,
             goo1.qty_lig,
             case when PARAMETER_8 = 1 THEN gco_functions.getdescription (goo1.gco_good_id, procuser_lanid, 1, '01')
             ELSE ''
             END  v_descr,
             case when PARAMETER_9 = 1 THEN gco_functions.getdescription (goo1.gco_good_id, procuser_lanid, 2, '01')
             ELSE ''
             END  v_descr_long,
             case when PARAMETER_10 = 1 THEN gco_functions.getdescription (goo1.gco_good_id, procuser_lanid, 3, '01')
             ELSE ''
             END  v_descr_free,
             gco_functions.getcostpricewithmanagementmode
                              (goo1.gco_good_id,
                               NULL,
                               DECODE (parameter_0,
                                       '0', goo1.c_management_mode,
                                       parameter_0
                                      ),
                               t_date
                              ) v_prix_produit
        FROM (select goo.gco_good_id,
                     goo.dic_good_line_id,
                     goo.dic_good_family_id,
                     goo.dic_good_model_id,
                     goo.dic_good_group_id,
                     goo.goo_number_of_decimal,
                     DIC_UNIT_OF_MEASURE_ID,
                     goo.c_management_mode,
                     goo.goo_major_reference,
                     goo.c_good_status,
                     cat.gco_good_category_wording,
                     LIS.LIS_FREE_NUMBER_1 qty_lig
             FROM gco_good goo, gco_good_category cat, COM_LIST LIS
             where goo.gco_good_category_id = cat.gco_good_category_id
                   AND cat.gco_good_category_wording LIKE  like_param (p_category_wording)
                   and GOO.GCO_GOOD_ID = LIS.LIS_ID_1
                   AND LIS.LIS_JOB_ID = VLIS_JOB_ID
             ) goo1,
             dic_good_family fam,
             dic_good_group grp,
             dic_good_line lne,
             dic_good_model MOD,
             gco_product pdt
       WHERE goo1.gco_good_id = pdt.gco_good_id
         AND goo1.dic_good_line_id = lne.dic_good_line_id(+)
         AND goo1.dic_good_family_id = fam.dic_good_family_id(+)
         AND goo1.dic_good_model_id = MOD.dic_good_model_id(+)
         AND goo1.dic_good_group_id = grp.dic_good_group_id(+)
         AND qty_lig <> 0;

ELSE   --SELECTION OF PRODUCTS
      OPEN arefcursor FOR
      SELECT 'GROUP_STRING' group_string, fam.dic_good_family_wording,
             grp.dic_good_group_wording, lne.dic_good_line_wording,
             MOD.dic_good_model_wording, goo.gco_good_id, goo.c_good_status,
             goo.c_management_mode, goo.goo_major_reference,
             goo.DIC_UNIT_OF_MEASURE_ID,
             goo.goo_number_of_decimal, cat.gco_good_category_wording,
             LIS.LIS_FREE_NUMBER_1 qty_lig,
             case when PARAMETER_8 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01')
             ELSE ''
             END  v_descr,
             case when PARAMETER_9 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01')
             ELSE ''
             END  v_descr_long,
             case when PARAMETER_10 = 1 THEN gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01')
             ELSE ''
             END  v_descr_free,
             gco_functions.getcostpricewithmanagementmode
                              (goo.gco_good_id,
                               NULL,
                               DECODE (parameter_0,
                                       '0', goo.c_management_mode,
                                       parameter_0
                                      ),
                               t_date
                              ) v_prix_produit
        FROM gco_good goo,
             dic_good_family fam,
             dic_good_group grp,
             dic_good_line lne,
             dic_good_model MOD,
             gco_good_category cat,
             gco_product pdt,
             COM_LIST LIS
       WHERE goo.gco_good_id = pdt.gco_good_id
         AND goo.gco_good_category_id = cat.gco_good_category_id
         AND goo.dic_good_line_id = lne.dic_good_line_id(+)
         AND goo.dic_good_family_id = fam.dic_good_family_id(+)
         AND goo.dic_good_model_id = MOD.dic_good_model_id(+)
         AND goo.dic_good_group_id = grp.dic_good_group_id(+)
         AND cat.gco_good_category_wording LIKE
                                               like_param (p_category_wording)
         AND GOO.GCO_GOOD_ID = LIS.LIS_ID_1
                   AND LIS.LIS_JOB_ID = VLIS_JOB_ID;

END IF;



END rpt_stm_qty_eom_with_grp;
