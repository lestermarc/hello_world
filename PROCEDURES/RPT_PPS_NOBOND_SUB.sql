--------------------------------------------------------
--  DDL for Procedure RPT_PPS_NOBOND_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PPS_NOBOND_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0   in pps_nomenclature.pps_nomenclature_id%type

)
IS
/**Description
* procedure used for report PPS_NOMENCLATURE.RPT
* @author JLIU 15 Jan 2009
* @lastUpdate AWU 5 oct 2010
* @version
* @public
* parameter_2 pps_nomenclature_id
*/

vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id

BEGIN


   PPS_INIT.SETNOMID (parameter_0);
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR

      select PPS.QUERY_ID_SEQ,
             pps.level_nom,
             COM_FUNCTIONS.GETDESCODEDESCR('C_REMPLACEMENT_NOM',bon.C_REMPLACEMENT_NOM ,vpc_lang_id) C_REMPLACEMENT_NOM,
             COM_FUNCTIONS.GETDESCODEDESCR('C_TYPE_COM',BON.C_TYPE_COM ,vpc_lang_id) C_TYPE_COM,
             COM_FUNCTIONS.GETDESCODEDESCR('C_DISCHARGE_COM',bon.C_DISCHARGE_COM ,vpc_lang_id) C_DISCHARGE_COM,
             COM_FUNCTIONS.GETDESCODEDESCR('C_KIND_COM',bon.C_KIND_COM ,vpc_lang_id) C_KIND_COM,
             bon.com_val,
             bon.com_substitut,
             bon.com_pos,
             bon.com_util_coeff,
             BON.COM_REF_QTY,
             bon.com_pdir_coeff,
             bon.com_rec_pcent,
             bon.com_interval,
             bon.com_beg_valid,
             bon.com_end_valid,
             bon.com_remplacement,
             GOO.GOO_MAJOR_REFERENCE,
             GOO.GOO_SECONDARY_REFERENCE,
             gco_functions.getdescription (goo.gco_good_id,
                                           procuser_lanid,
                                           1,
                                           '01'
                                          ) descr
      from
      v_pps_nomenclature_interro pps,
      gco_good goo,
      pps_nom_bond bon,
      pps_range_operation ope
      where
          PPS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
      AND bon.pps_range_operation_id = ope.pps_range_operation_id(+)
      and PPS.PPS_NOM_BOND_ID = BON.PPS_NOM_BOND_ID
      order by query_id_seq;

--      SELECT dbt.wdt_structure, dbt.wdt_level, dbt.wdt_order,
--             bon.c_remplacement_nom, bon.c_type_com, bon.c_discharge_com,
--             bon.c_kind_com, bon.com_val, bon.com_substitut, bon.com_pos,
--             bon.com_util_coeff, bon.com_pdir_coeff, bon.com_rec_pcent,
--             bon.com_interval, bon.com_beg_valid, bon.com_end_valid,
--             bon.com_remplacement, des.goo_major_reference,
--             des.goo_secondary_reference, des.c_description_type,
--             des.pc_lang_id
--        FROM pcs.pc_work_dbtree dbt,
--             pps_nom_bond bon,
--             pps_range_operation ope,
--             v_good_description des
--       WHERE dbt.wdt_id_num = bon.pps_nom_bond_id
--         AND bon.pps_range_operation_id = ope.pps_range_operation_id(+)
--         AND bon.gco_good_id = des.gco_good_id
--         AND des.pc_lang_id = procuser_lanid --TO_NUMBER (lang_id)
--         AND dbt.wdt_structure = TO_NUMBER (parameter_0)
--         AND dbt.wdt_level >= 1
--         AND dbt.wdt_level <= TO_NUMBER (parameter_1)
--         AND des.c_description_type = '01';
END rpt_pps_nobond_sub;
