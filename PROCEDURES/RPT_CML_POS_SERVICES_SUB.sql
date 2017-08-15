--------------------------------------------------------
--  DDL for Procedure RPT_CML_POS_SERVICES_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_POS_SERVICES_SUB" (
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
      SELECT cps.cml_position_service_id,
             (SELECT goo_major_reference
                FROM gco_good goo
               WHERE goo.gco_good_id = cps.gco_cml_service_id)
                                                              ref_prestation,
                                                           /*Ref prestation*/
             cps.cps_long_description                       /*Descr. Longue*/
        FROM cml_position_service cps
       WHERE cps.cml_position_id = parameter_0;
END rpt_cml_pos_services_sub;
