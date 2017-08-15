--------------------------------------------------------
--  DDL for Procedure RPT_PAC_ADDRESS_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_ADDRESS_LIST" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2
)
IS
/**
 Description - used for the report PAC_ADDRESS_LIST
 @Created JLIU - 27 August 2009
 @lastUpdate mzh 17.05.2010
 @public
 @PARAM  parameter_0  PER_NAME: (FROM)
 @PARAM  parameter_1  PER_NAME : (TO)
 @PARAM  parameter_2  Adresses: 0= Toutes; 1= Clients; 2= Fournisseurs; 3= Personnes
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT DISTINCT cus.pac_custom_partner_id, sup.pac_supplier_partner_id,
                      rep.pac_person_id, rep.per_name, rep.per_forename,
                      rep.per_short_name, rep.per_activity, rep.per_key1,
                      rep.per_key2
                 FROM pac_custom_partner cus,
                      pac_supplier_partner sup,
                      pac_person rep
                WHERE rep.pac_person_id = cus.pac_custom_partner_id(+)
                  AND rep.pac_person_id = sup.pac_supplier_partner_id(+)
                  AND (    rep.per_name >= NVL (parameter_0, '(')
                       AND rep.per_name <= NVL (parameter_1, '}')
                      )
                  AND (   parameter_2 = '0'
                       OR (    parameter_2 = '1'
                           AND cus.pac_custom_partner_id IS NOT NULL
                          )
                       OR (    parameter_2 = '2'
                           AND sup.pac_supplier_partner_id IS NOT NULL
                          )
                       OR (    parameter_2 = '3'
                           AND cus.pac_custom_partner_id IS NULL
                           AND sup.pac_supplier_partner_id IS NULL
                          )
                      );
END rpt_pac_address_list;
