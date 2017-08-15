--------------------------------------------------------
--  DDL for Procedure RPT_PPS_NOMENCLATURE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PPS_NOMENCLATURE" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0   in pps_nomenclature.pps_nomenclature_id%type,
   parameter_1   IN       VARCHAR2
   )
IS
/**Description - used for report PPS_NOMENCLATURE
* @author JLIU 15 Jan 2009
* @lastUpdate 5 oct 2010
* @public
* Parameter_2   pps_nomenclature_id
*/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id

begin

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

open arefcursor for
     select goo.goo_major_reference,
            nom.nom_text,
            COM_FUNCTIONS.GETDESCODEDESCR('C_TYPE_NOM',nom.C_TYPE_NOM ,vpc_lang_id) C_TYPE_NOM,
            nom.nom_version,
            nom.nom_default,
            nom.a_datecre,
            nom.a_datemod,
            nom.nom_ref_qty,
            goo.goo_secondary_reference,
            gco_functions.getdescription (goo.gco_good_id,
                                           procuser_lanid,
                                           1,
                                           '01'
                                          ) descr
       from pps_nomenclature nom
           ,gco_good goo
      where nom.gco_good_id = goo.gco_good_id
            and nom.pps_Nomenclature_id = parameter_0;


end;
