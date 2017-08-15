--------------------------------------------------------
--  DDL for Procedure RPT_PAC_SUP_PREC_MAT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_SUP_PREC_MAT_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_99     IN       NUMBER
)
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
/**
 Description - used for the report PAC_SUPPLIER_FORM
 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_99  PAC_SUPPLIER_PARTNER_ID
*/
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT sup.c_material_mgnt_mode,
             pcs.pc_functions.getdescodedescr
                                         ('C_MATERIAL_MGNT_MODE',
                                          sup.c_material_mgnt_mode,
                                          vpc_lang_id
                                         ) mgnt_mode,
             thi.gco_alloy_id, gal.gal_alloy_ref, gal.gal_alloy_descr,
             thi.dic_basis_material_id,
             (SELECT dit.dit_descr
                FROM dico_description dit
               WHERE dit.dit_table = 'DIC_BASIS_MATERIAL'
                 AND dit.dit_code = thi.dic_basis_material_id
                 AND dit.pc_lang_id = vpc_lang_id) dit_descr,
             thi.tha_managed, thi.tha_number,
             sup.c_third_material_relation_type,
             pcs.pc_functions.getdescodedescr
                ('C_THIRD_MATERIAL_RELATION_TYPE',
                 sup.c_third_material_relation_type,
                 vpc_lang_id
                ) third_material_relation_type,
             sup.c_weighing_mgnt,
             pcs.pc_functions.getdescodedescr
                                          ('C_WEIGHING_MGNT',
                                           sup.c_weighing_mgnt,
                                           vpc_lang_id
                                          ) weighing_mgnt,
             sup.c_adv_material_mode,
             pcs.pc_functions.getdescodedescr
                                  ('C_ADV_MATERIAL_MODE',
                                   sup.c_adv_material_mode,
                                   vpc_lang_id
                                  ) adv_material_mode
        FROM pac_supplier_partner sup, pac_third_alloy thi, gco_alloy gal
       WHERE sup.pac_supplier_partner_id = thi.pac_supplier_partner_id(+)
         AND thi.gco_alloy_id = gal.gco_alloy_id(+)
         AND sup.pac_supplier_partner_id = parameter_99;
END rpt_pac_sup_prec_mat_sub;
