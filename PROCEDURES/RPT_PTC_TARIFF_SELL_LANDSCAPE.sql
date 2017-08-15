--------------------------------------------------------
--  DDL for Procedure RPT_PTC_TARIFF_SELL_LANDSCAPE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PTC_TARIFF_SELL_LANDSCAPE" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   procparam_0       IN      GCO_GOOD.GOO_MAJOR_REFERENCE%TYPE,
   procparam_1       IN      PTC_TARIFF.DIC_TARIFF_ID%TYPE,
   procparam_2       IN      PAC_PERSON.PER_NAME%TYPE
)
/*
* Description
* STORED PROCEDURE USED FOR REPORT PTC_TARIFF_BUY_LANDSCAPE
* @AUTHOR JJI
* @Creation DATE May.20 2010 JJI
* @LASTUPDATE oct 2010
* @PUBLIC
*  procparam_0      GOO_MAJOR_REFERENCE
*  procparam_1      DIC_TARIFF_ID
*  procparam_2      NOM DU FOURNISSEUR
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT   goo.gco_good_id, goo.goo_major_reference,
               goo.goo_secondary_reference, per.pac_person_id, per.per_name,
               ptc.ptc_tariff_id,
               (SELECT   COUNT
                            (pab_grp.ptc_tariff_table_id
                            )
                    FROM ptc_tariff_table pab_grp
                   WHERE pab_grp.ptc_tariff_id = ptc.ptc_tariff_id
                GROUP BY pab_grp.ptc_tariff_id) price_table_record_number,
               ptc.dic_tariff_id, ptc.c_tariff_type,
               ptc.c_tariffication_mode, ptc.trf_starting_date,
               ptc.trf_ending_date,
               NVL (TO_CHAR (ptc.trf_starting_date, 'yyyyMMdd'),
                    '99999999'
                   ) to_nume_trf_start_date,
               ptc.trf_descr, ptc.trf_unit, pab.tta_from_quantity,
               pab.tta_to_quantity, pab.tta_price, acu.currency,
               des.dit_table, des.dit_descr, lan_des.lanid
          FROM ptc_tariff ptc,
               ptc_tariff_table pab,
               v_acs_financial_currency acu,
               gco_good goo,
               pac_person per,
               dico_description des,
               pcs.pc_lang lan_des
         WHERE goo.gco_good_id = ptc.gco_good_id
           AND ptc.c_tariff_type = 'A_FACTURER'
           AND ptc.ptc_tariff_id = pab.ptc_tariff_id
           AND goo.goo_major_reference LIKE LIKE_PARAM_FS (procparam_0)
           AND nvl(per.per_name,'%') like like_param_fs (procparam_2)
           AND PTC.DIC_TARIFF_ID like like_param_fs (procparam_1)
           AND ptc.pac_third_id = per.pac_person_id(+)
           AND ptc.acs_financial_currency_id = acu.acs_financial_currency_id
           AND (ptc.dic_tariff_id IS NULL OR des.dit_table = 'DIC_TARIFF')
           AND ptc.dic_tariff_id = des.dit_code(+)
           AND des.pc_lang_id = lan_des.pc_lang_id(+)
           AND (des.pc_lang_id = vpc_lang_id OR des.pc_lang_id IS NULL)
      ORDER BY goo.goo_major_reference,
               ptc.dic_tariff_id ASC,
               ptc.trf_descr,
               TO_NUMBER (NVL (TO_CHAR (ptc.trf_starting_date, 'yyyyMMdd'),
                               '00000000'
                              )
                         ) DESC,
               ptc.ptc_tariff_id ASC;
END rpt_ptc_tariff_sell_landscape;
