--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_SUBCTR_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_SUBCTR_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report FAL_LOT_TASK_ORDO

* @author AWU 7 April 2009
* @lastUpdate
* @public
* @param parameter_1: FAL_SCHEDULE_STEP_ID
* Uniquement pour les gabarits de type Commande ss-traitance
*/

vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id

BEGIN
vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
SELECT pde.fal_schedule_step_id, dmt.dmt_number, pos.pos_number,
       pde.pde_basis_delay, pos.pos_basis_quantity,
       (SELECT gcdtext1
          FROM pcs.v_pc_descodes
         WHERE gcgname = 'C_DOCUMENT_STATUS'
           AND pc_lang_id = vpc_lang_id
           AND gclcode = dmt.c_document_status) C_STATUS
  FROM doc_position_detail pde,
       doc_position pos,
       doc_document dmt,
       doc_gauge gau
 WHERE pde.doc_position_id = pos.doc_position_id
   AND pos.doc_document_id = dmt.doc_document_id
   AND dmt.doc_gauge_id = gau.doc_gauge_id
   AND gau.dic_gauge_categ_id = 'Appro_ST'
   AND pde.fal_schedule_step_id = parameter_0;
END rpt_fal_lot_subctr_sub;
