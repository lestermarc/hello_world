--------------------------------------------------------
--  DDL for Procedure RPT_PPS_NOM_BOND_DELTA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PPS_NOM_BOND_DELTA" (aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
                                                    procParam_0 in number,
                                                    procParam_1 in number,
                                                    procParam_2 in number,
                                                    procUser_lanid in varchar2,
                                                    procCompany_lanid in varchar2,
                                                    procCompany_name in varchar2,
                                                    procCompany_owner in varchar2,
                                                    procPc_conli_id in varchar2,
                                                    procPc_object_id in varchar2,
                                                    procPc_user_id in varchar2,
                                                    procPc_comp_id in varchar2
                                                 )
                                                 is

/*
 * Stored procedure used for the report PPS_NOM_BOND_DELTA
 * Replace the procedure PPS_NOM_BOND_DELTA_RPT
*/

/* variables locales propres à la procédure */

begin

/* ============================================================================

   Paramètres :

   procParam_0        nomenclature source
   procParam_1        nomenclature cible
   procParam_2        quantité référence

============================================================================ */
if procPc_comp_id is not null then
   pcs.PC_I_LIB_SESSION.SetCompanyId (to_number(procPc_comp_id));
end if;

if procPc_user_id is not null then
   pcs.PC_I_LIB_SESSION.SetUserId (to_number(procPc_user_id));
end if;

if procPc_object_id is not null then
   pcs.PC_I_LIB_SESSION.SetObjectId (to_number(procPc_object_id));
end if;

if procUser_lanid is not null then
   pcs.PC_I_LIB_SESSION.setLanId (procUser_lanid);
end if;

pps_nom_bond_fct.generate_bond_delta (procParam_0, procParam_1, procParam_2);

/* ============================================================================

   Remplacer "Select * from dual" par l'ordre SQL approprié.

============================================================================ */

open aRefCursor
 for
     select case
             when delta_nom.nbd_util_coeff > 0 then 'ADD' else 'DEL'
            end delta_type,
            goo1.goo_major_reference src_product_major_ref,
            pps1.nom_version src_nom_version,
            pcs.pc_functions.GetDescodeDescr ('C_TYPE_NOM', pps1.c_type_nom, pcs.PC_I_LIB_SESSION.GetUserLangId) src_type_nom,
            goo1.goo_secondary_reference src_product_secondary_ref,
            (select des.des_short_description
               from gco_description des
              where goo1.gco_good_id = des.gco_good_id (+)
                and des.pc_lang_id (+) = pcs.PC_I_LIB_SESSION.GetUserLangId
                and des.c_description_type = '01') src_product_short_description,
            goo2.goo_major_reference tgt_product_major_ref,
            pps2.nom_version tgt_nom_version,
            pcs.pc_functions.GetDescodeDescr ('C_TYPE_NOM', pps2.c_type_nom, pcs.PC_I_LIB_SESSION.GetUserLangId) tgt_type_nom,
            goo2.goo_secondary_reference tgt_product_secondary_ref,
            (select des.des_short_description
               from gco_description des
              where goo2.gco_good_id = des.gco_good_id (+)
                and des.pc_lang_id (+) = pcs.PC_I_LIB_SESSION.GetUserLangId
                and des.c_description_type = '01') tgt_product_short_description,
            delta_nom.ref_qty,
            delta_nom.goo_major_reference cpt_major_ref,
            pps3.nom_version cpt_nom_version,
            delta_nom.goo_secondary_reference cpt_secondary_ref,
            delta_nom.des_short_description cpt_short_description,
            delta_nom.nbd_util_coeff cpt_delta_coeff
       from pps_nomenclature pps1,
            pps_nomenclature pps2,
            pps_nomenclature pps3,
            gco_good goo1,
            gco_good goo2,
            (select procParam_0 source_nomenclature_id,
                    procParam_1 target_nomenclature_id,
                    procParam_2 ref_qty,
                    nbd.nbd_util_coeff ,
                    goo_cpt.goo_major_reference,
                    goo_cpt.goo_secondary_reference,
                    nbd.pps_pps_nomenclature_id,
                    (select des.des_short_description
                       from gco_description des
                      where goo_cpt.gco_good_id = des.gco_good_id (+)
                        and des.pc_lang_id (+) = pcs.PC_I_LIB_SESSION.GetUserLangId
                        and des.c_description_type = '01') des_short_description
               from pps_nom_bond_delta nbd,
                    gco_good goo_cpt
              where nbd.gco_good_id = goo_cpt.gco_good_id) delta_nom
      where delta_nom.source_nomenclature_id = pps1.pps_nomenclature_id
        and pps1.gco_good_id = goo1.gco_good_id
        and delta_nom.target_nomenclature_id = pps2.pps_nomenclature_id
        and pps2.gco_good_id = goo2.gco_good_id
        and delta_nom.pps_pps_nomenclature_id = pps3.pps_nomenclature_id (+);

end RPT_PPS_NOM_BOND_DELTA;
