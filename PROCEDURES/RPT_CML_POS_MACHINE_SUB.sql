--------------------------------------------------------
--  DDL for Procedure RPT_CML_POS_MACHINE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_POS_MACHINE_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       cml_position.cml_position_id%TYPE
)
IS
/*
* Description stored procedure used for the report CML_POSITION_STD

* @created AWU 01 NOV 2008
* @lastupdate AWU 23 Apr 2009
* @public
* @param PARAMETER_0: CML_POSITION_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cpm.cml_position_machine_id,
             (SELECT rco2.rco_title
                FROM doc_record rco2
               WHERE rco2.doc_record_id =
                                       cpm.doc_rco_machine_id)
                                                             no_installation,

             /*No installation*/
             cpm.cpm_weight,                                   /*Pond?ation*/
             (SELECT ctt.ctt_key
                FROM asa_counter cou, asa_counter_type ctt
               WHERE cou.asa_counter_type_id =
                                             ctt.asa_counter_type_id
                 AND cou.asa_counter_id = cmd.asa_counter_id) compteur,

             /*Compteur*/
             cmd.cmd_initial_statement,             /*Compteur d?ut contrat*/
             cmd.cmd_last_invoice_statement         /*Compteur derni?e fact*/
        FROM cml_position_machine cpm, cml_position_machine_detail cmd
       WHERE cpm.cml_position_machine_id = cmd.cml_position_machine_id(+)
         AND cpm.cml_position_id = parameter_0;
END rpt_cml_pos_machine_sub;
