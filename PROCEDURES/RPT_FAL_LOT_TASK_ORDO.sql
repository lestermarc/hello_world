--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_TASK_ORDO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_TASK_ORDO" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER,
   parameter_1      IN       DATE,
   parameter_2      IN       NUMBER,
   parameter_3      IN       VARCHAR2
)
IS
/**Description - used for report FAL_LOT_TASK_ORDO

* @author AWU 7 April 2009
* @lastUpdate feb 2010
* @public
* @param parameter_0:  choice between begin and end date used to filter record 0/begin  1/end
* @param parameter_1:  lot_date
* @param parameter_2   task type choice 0/all 1/internal 2/external
* @param parameter_3   Workshop list
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
   param_begin   DATE;
   param_end     DATE;
   param_task    NUMBER;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   IF parameter_0 = 0
   THEN
      param_begin := parameter_1;
   ELSIF parameter_0 = 1
   THEN
      param_end := parameter_1;
   END IF;

   CASE parameter_2
      WHEN 0
      THEN
         NULL;
      WHEN 1
      THEN
         param_task := 1;
      WHEN 2
      THEN
         param_task := 2;
      ELSE
         NULL;
   END CASE;

   OPEN arefcursor FOR
      SELECT
         DECODE
              ((SELECT COUNT (fpg.fal_lot_progress_id)
                FROM fal_lot_progress fpg
                WHERE fpg.fal_lot_id = lot.fal_lot_id
                     AND fpg.flp_reversal = 0),
                 0, '0',
                 '1'
                ) tracking_indication,
         lot.fal_lot_id, lot.lot_refcompl,
             NVL (tal.tal_begin_plan_date,
                  lot.lot_plan_begin_dte
                 ) tal_begin_plan_date,
             NVL (tal.tal_end_plan_date,
                  lot.lot_plan_end_dte
                 ) tal_end_plan_date,
             TO_CHAR (NVL (tal.tal_end_plan_date, lot.lot_plan_end_dte),
                      'IW'
                     ) tal_end_plan_date_iw,
             NVL (tal.tal_task_manuf_time,
                  lot.lot_plan_lead_time
                 ) tal_task_manuf_time,
             Case When
                (SELECT MIN (fln.fln_margin)
                   FROM fal_network_supply fns, fal_network_link fln
                   WHERE fns.fal_network_supply_id = fln.fal_network_supply_id
                         AND fns.fal_lot_id = lot.fal_lot_id) < 0
             THEN
                (SELECT MIN (fln.fln_margin)
                   FROM fal_network_supply fns, fal_network_link fln
                   WHERE fns.fal_network_supply_id = fln.fal_network_supply_id
                         AND fns.fal_lot_id = lot.fal_lot_id)
             ELSE
                (SELECT MAX (fln.fln_margin)
                   FROM fal_network_supply fns, fal_network_link fln
                   WHERE fns.fal_network_supply_id = fln.fal_network_supply_id
                         AND fns.fal_lot_id = lot.fal_lot_id)
              END  fln_margin,
             (SELECT goo.goo_major_reference
                FROM gco_good goo
               WHERE goo.gco_good_id = lot.gco_good_id) goo_major_reference,
             gco_functions.getdescription (lot.gco_good_id,
                                           procuser_lanid,
                                           1,
                                           '01'
                                          ) short_description,
             tal.c_task_type,
             pcs.pc_functions.getdescodedescr ('C_TASK_TYPE',
                                               tal.c_task_type,
                                               vpc_lang_id
                                              ) task_type,
             DECODE (tal.c_task_type,
                     1, (SELECT fac.fac_reference
                           FROM fal_factory_floor fac
                          WHERE fac.fal_factory_floor_id =
                                                      tal.fal_factory_floor_id),
                     2, (SELECT per.per_name
                           FROM pac_person per
                          WHERE per.pac_person_id =
                                                   tal.pac_supplier_partner_id),
                     ''
                    ) client,
             tal.fal_schedule_step_id, tal.scs_step_number,
             (SELECT tas.tas_ref
                FROM fal_task tas
               WHERE tas.fal_task_id = tal.fal_task_id) tas_ref,
             lot.lot_plan_end_dte,
             TO_CHAR (lot.lot_plan_end_dte, 'IW') lot_plan_end_dte_iw,
             tal.tal_plan_qty, tal.tal_due_qty
        FROM fal_task_link tal,
             fal_lot lot,
             fal_order ord,
             fal_job_program jop
       WHERE tal.fal_lot_id = lot.fal_lot_id
         AND lot.fal_order_id = ord.fal_order_id
         AND ord.fal_job_program_id = jop.fal_job_program_id
         AND (parameter_3 is null  or instr( ',' || parameter_3 ||',' , ',' || TAL.FAL_FACTORY_FLOOR_ID ||',' ) > 0 )
         AND lot.c_lot_status IN ('1', '2')
         AND tal.tal_due_qty > 0
         AND (lot.lot_plan_begin_dte <= param_begin OR param_begin IS NULL)
         AND (lot.lot_plan_end_dte <= param_end OR param_end IS NULL)
         AND (tal.c_task_type = param_task OR param_task IS NULL);
END rpt_fal_lot_task_ordo;
