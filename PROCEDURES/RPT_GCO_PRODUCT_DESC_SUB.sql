--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_DESC_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_DESC_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 21 FEB 2009
* @public
* @PARAM PARAMETER_0 gco_good_id
*/
BEGIN
   OPEN arefcursor FOR
      SELECT gco_good.gco_good_id, gco_description.des_short_description,
             gco_description.des_long_description,
             gco_description.des_free_description,
             gco_description_st.des_short_description des_short_descr_st,
             gco_description_st.des_long_description des_long_descr_st,
             gco_description_st.des_free_description des_free_descr_st,
             gco_description_pu.des_short_description des_short_descr_pu,
             gco_description_pu.des_long_description des_long_descr_pu,
             gco_description_pu.des_free_description des_free_descr_pu,
             gco_description_sa.des_short_description des_short_descr_sa,
             gco_description_sa.des_long_description des_long_descr_sa,
             gco_description_sa.des_free_description des_free_descr_sa,
             gco_description_fa.des_short_description des_short_descr_fa,
             gco_description_fa.des_long_description des_long_descr_fa,
             gco_description_fa.des_free_description des_free_descr_fa,
             gco_description_so.des_short_description des_short_descr_so,
             gco_description_so.des_long_description des_long_descr_so,
             gco_description_so.des_free_description des_free_descr_so,
             gco_description_sv.des_short_description des_short_descr_sv,
             gco_description_sv.des_long_description des_long_descr_sv,
             gco_description_sv.des_free_description des_free_descr_sv,
             gco_description_in.des_short_description des_short_descr_in,
             gco_description_in.des_long_description des_long_descr_in,
             gco_description_in.des_free_description des_free_descr_in,
             gco_description_ca.des_short_description des_short_descr_ca,
             gco_description_ca.des_long_description des_long_descr_ca,
             gco_description_ca.des_free_description des_free_descr_ca,
             gco_description_tk.des_short_description des_short_descr_tk,
             gco_description_tk.des_long_description des_long_descr_tk,
             gco_description_tk.des_free_description des_free_descr_tk,
             gco_description_iv.des_short_description des_short_descr_iv,
             gco_description_iv.des_long_description des_long_descr_iv,
             gco_description_iv.des_free_description des_free_descr_iv,
             lan.pc_lang_id, lan.lanname
        FROM gco_good,
             gco_description,
             gco_description gco_description_st,
             gco_description gco_description_pu,
             gco_description gco_description_sa,
             gco_description gco_description_fa,
             gco_description gco_description_so,
             gco_description gco_description_sv,
             gco_description gco_description_in,
             gco_description gco_description_ca,
             gco_description gco_description_tk,
             gco_description gco_description_iv,
             pcs.pc_lang lan
       WHERE gco_good.gco_good_id = gco_description.gco_good_id
         AND gco_description.c_description_type = 1
         AND gco_description.gco_good_id = gco_description_st.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_st.pc_lang_id(+)
         AND gco_description_st.c_description_type(+) = 2
         AND gco_description.gco_good_id = gco_description_pu.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_pu.pc_lang_id(+)
         AND gco_description_pu.c_description_type(+) = 3
         AND gco_description.gco_good_id = gco_description_sa.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_sa.pc_lang_id(+)
         AND gco_description_sa.c_description_type(+) = 4
         AND gco_description.gco_good_id = gco_description_fa.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_fa.pc_lang_id(+)
         AND gco_description_fa.c_description_type(+) = 5
         AND gco_description.gco_good_id = gco_description_so.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_so.pc_lang_id(+)
         AND gco_description_so.c_description_type(+) = 6
         AND gco_description.gco_good_id = gco_description_sv.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_sv.pc_lang_id(+)
         AND gco_description_sv.c_description_type(+) = 7
         AND gco_description.gco_good_id = gco_description_in.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_in.pc_lang_id(+)
         AND gco_description_in.c_description_type(+) = 8
         AND gco_description.gco_good_id = gco_description_ca.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_ca.pc_lang_id(+)
         AND gco_description_ca.c_description_type(+) = 9
         AND gco_description.gco_good_id = gco_description_tk.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_tk.pc_lang_id(+)
         AND gco_description_tk.c_description_type(+) = 10
         AND gco_description.gco_good_id = gco_description_iv.gco_good_id(+)
         AND gco_description.pc_lang_id = gco_description_iv.pc_lang_id(+)
         AND gco_description_iv.c_description_type(+) = 11
         AND gco_description.pc_lang_id = lan.pc_lang_id(+)
         AND gco_good.gco_good_id = parameter_0;
END rpt_gco_product_desc_sub;
