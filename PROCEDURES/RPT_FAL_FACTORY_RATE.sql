--------------------------------------------------------
--  DDL for Procedure RPT_FAL_FACTORY_RATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_FACTORY_RATE" (
  arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
  aFAL_LOT_ID      IN       number,
  procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
is
  vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
begin
  pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
  vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select ftl.fal_schedule_step_id
         , ffr.fal_factory_floor_id
         , nvl(ffr.ffr_rate1, 0) FAC_RATE1
         , nvl(ffr.ffr_rate2, 0) FAC_RATE2
         , nvl(ffr.ffr_rate3, 0) FAC_RATE3
         , nvl(ffr.ffr_rate4, 0) FAC_RATE4
         , nvl(ffr.ffr_rate5, 0) FAC_RATE5
      from fal_factory_rate ffr
         , fal_factory_floor fff
         , fal_task_link ftl
     where ftl.fal_lot_id = aFAL_LOT_ID
       and ftl.fal_factory_floor_id = fff.fal_factory_floor_id
       and fff.fal_factory_floor_id = ffr.fal_factory_floor_id
       and trunc(ffr.ffr_validity_date) = (select max(trunc(ffr2.ffr_validity_date))
                                             from fal_factory_rate ffr2
                                            where trunc(ffr2.ffr_validity_date) <= trunc(nvl(ftl.tal_end_real_date, ftl.tal_end_plan_date))
                                              and ffr2.fal_factory_floor_id = ffr.FAL_FACTORY_FLOOR_ID);
end RPT_FAL_FACTORY_RATE;
