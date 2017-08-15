--------------------------------------------------------
--  DDL for Procedure RPT_FAL_FACTORY_FLOOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_FACTORY_FLOOR" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid    IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description Used for report FAL_FACTORY_FLOOR,FAL_FACTORY_FLOOR_BATCH. This one is used only since SP6

*@created LBU 05 SEP 2008
*@lastUpdate 17 Mar 2010 cliu
*@public
*@param USER_LANID  : user language
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT   fal_factory_floor.fac_reference,
               fal_factory_floor.fac_describe,
               fal_factory_floor.fac_resource_number,
               fal_factory_floor.FAC_PIC,
               fal_factory_floor.FAC_INFINITE_FLOOR,
               fal_factory_floor.FAC_OUT_OF_ORDER,
               fal_factory_floor.FAC_IS_MACHINE,
               fal_factory_floor.FAC_IS_OPERATOR,
               fal_factory_floor.FAC_IS_PERSON,
               fal_factory_floor.FAC_IS_BLOCK,
               fal_factory_rate.ffr_validity_date,
               fal_factory_rate.ffr_rate1, fal_factory_rate.ffr_rate2,
               fal_factory_rate.ffr_rate3, fal_factory_rate.ffr_rate4,
               fal_factory_rate.ffr_rate5,
               fal_factory_floor.pac_calendar_type_id,
               fal_factory_floor.dic_floor_free_code_id,
               fal_factory_floor.dic_floor_free_code2_id,
               fal_factory_floor.dic_floor_free_code3_id,
               fal_factory_floor.dic_floor_free_code4_id,
               fal_factory_floor.FAL_FAL_FACTORY_FLOOR_ID,
               fal_factory_floor.FAL_GRP_FACTORY_FLOOR_ID,
               fal_factory_floor.FAL_FACTORY_FLOOR_ID,
               (select distinct 1 from fal_factory_floor FF2 where FF2.FAL_FAL_FACTORY_FLOOR_ID = fal_factory_floor.FAL_FACTORY_FLOOR_ID) HAS_MACHINE,
               (select distinct 1 from fal_factory_floor FF3 where FF3.FAL_GRP_FACTORY_FLOOR_ID = fal_factory_floor.FAL_FACTORY_FLOOR_ID) HAS_EMPLOYEE
          FROM fal_factory_floor,
               (select fal_factory_floor_id, max(ffr_validity_date) ffr_validity_date
               from fal_factory_rate
               where ffr_validity_date <= SYSDATE
               group by fal_factory_floor_id) eff_date,
               fal_factory_rate
         WHERE fal_factory_floor.fal_factory_floor_id = eff_date.fal_factory_floor_id(+)
         and fal_factory_rate.fal_factory_floor_id (+) = eff_date.fal_factory_floor_id
         and fal_factory_rate.FFR_VALIDITY_DATE(+) = eff_date.FFR_VALIDITY_DATE
      ORDER BY fal_factory_floor.fac_reference;
END RPT_fal_factory_floor;
