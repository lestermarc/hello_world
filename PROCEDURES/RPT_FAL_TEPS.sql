--------------------------------------------------------
--  DDL for Procedure RPT_FAL_TEPS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_TEPS" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description - Used reports FAL_TEPS_BY_MONTH, FAL_TEPS_BY_YEAR
* @created EQI 01 Jun 2008
* @lastUpdate VHA 20 April 2012
* @public
* @param parameter_0  :  Product from
* @param parameter_1  :  Product to
* @param parameter_6  :   Stock Selection
* @param parameter_7  :   Prop Plan Dir
* @param parameter_8  :   Needs Calculation Prop
*/
   vpc_lang_id               pcs.pc_lang.pc_lang_id%TYPE;
   goo_major_reference_min   VARCHAR2 (30 CHAR);
   goo_major_reference_max   VARCHAR2 (30 CHAR);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   IF parameter_0 = '*'
   THEN
      goo_major_reference_min := '(';
   ELSE
      goo_major_reference_min := parameter_0;
   END IF;

   IF parameter_1 = '*'
   THEN
      goo_major_reference_max := '}';
   ELSE
      goo_major_reference_max := parameter_1;
   END IF;

   OPEN arefcursor FOR
      SELECT '3. NEED' typ, goo.goo_major_reference, fnn.fan_description,
             flo.c_lot_status, per.per_short_name, sto.sto_description,
             fnn.fan_balance_qty * (-1) fan_balance_qty,
             TO_NUMBER (SUBSTR (TO_CHAR (fnn.fan_beg_plan, 'dd.MM.yyyy'), 7,
                                4)
                       ) annee,
             TO_NUMBER (SUBSTR (TO_CHAR (fnn.fan_beg_plan, 'dd.MM.yyyy'), 4,
                                2)
                       ) mois,
             TO_NUMBER
                (SUBSTR (doc_delay_functions.datetoweek (fnn.fan_beg_plan),
                         6,
                         2
                        )
                ) semaine,
             fnn.c_gauge_title, fnn.doc_position_detail_id, fnn.fal_lot_id,
             fnn.fal_doc_prop_id, fnn.fal_lot_prop_id, sto.stm_stock_id,
             '' stm_stm_location, fnn.fal_pic_line_id,
             DECODE
                (fnn.fal_pic_line_id,
                 NULL, '',
                 DECODE
                     (pcs.pc_config.getconfig ('FAL_PIC_WEEK_MONTH'),
                      1,  goo2.goo_major_reference
                       || ' - '
                       || TO_CHAR (fpl.pil_date, 'DD.MM.YYYY'),
                         goo2.goo_major_reference
                      || ' - '
                      || TRANSLATE
                                (doc_delay_functions.datetoweek (fpl.pil_date),
                                 '.',
                                 '/'
                                )
                     )
                ) fal_pic_line_descr,
             (SELECT com.cst_quantity_min
                FROM gco_compl_data_stock com
               WHERE sto.stm_stock_id = com.stm_stock_id(+)
                 AND goo.gco_good_id = com.gco_good_id(+)) cst_quantity_min,
             pcs.pc_config.getconfig
                                   ('DOC_DELAY_WEEKSTART')
                                                          doc_delay_weekstart
        FROM pac_person per,
             gco_good_category cat,
             gco_good goo,
             fal_lot flo,
             stm_stock sto,
             stm_location loc,
             fal_network_need fnn,
             fal_pic_line fpl,
             gco_good goo2                                                 --,
      WHERE  fnn.gco_good_id = goo.gco_good_id
         AND goo.gco_good_category_id = cat.gco_good_category_id
         AND fnn.pac_third_id = per.pac_person_id(+)
         AND fnn.stm_stock_id = sto.stm_stock_id
         AND fnn.stm_location_id = loc.stm_location_id
         AND fnn.fal_lot_id = flo.fal_lot_id(+)
         AND fnn.fal_pic_line_id = fpl.fal_pic_line_id(+)
         AND fpl.gco_good_id = goo2.gco_good_id(+)
         AND fnn.fan_beg_plan IS NOT NULL
         AND goo.goo_major_reference >= goo_major_reference_min
         AND goo.goo_major_reference <= goo_major_reference_max
         AND (
                   (instr( ';' || parameter_6  ||';' ,  ';' || sto.stm_stock_id ||';' ) > 0)
                OR (parameter_6 = '*')
             )
         AND ((   parameter_6 = '*'
               OR DECODE (fnn.fal_lot_id,
                          NULL, DECODE (doc_position_detail_id,
                                        NULL, DECODE (fpl.fal_pic_line_id,
                                                      NULL, 0,
                                                      1
                                                     ),
                                        1
                                       ),
                          1
                         ) = 1
               OR (    parameter_7 = 1
                   AND DECODE (c_gauge_title,
                               '14', DECODE (fal_doc_prop_id,
                                             NULL, DECODE (fal_lot_prop_id,
                                                           NULL, 0,
                                                           1
                                                          ),
                                             1
                                            ),
                               0
                              ) = 1
                  )
               OR (    parameter_8 = 1
                   AND DECODE (c_gauge_title,
                               '14', 0,
                               DECODE (fal_doc_prop_id,
                                       NULL, DECODE (fal_lot_prop_id,
                                                     NULL, 0,
                                                     1
                                                    ),
                                       1
                                      )
                              ) = 1
                  )
              )
             )
      UNION ALL
      SELECT '2. SUPPLY' typ, goo.goo_major_reference, fns.fan_description,
             flo.c_lot_status, per.per_short_name, sto.sto_description,
             fns.fan_balance_qty,
             TO_NUMBER (SUBSTR (TO_CHAR (fns.fan_end_plan, 'dd.MM.yyyy'), 7,
                                4)
                       ) annee,
             TO_NUMBER (SUBSTR (TO_CHAR (fns.fan_end_plan, 'dd.MM.yyyy'), 4,
                                2)
                       ) mois,
             TO_NUMBER
                (SUBSTR (doc_delay_functions.datetoweek (fns.fan_end_plan),
                         6,
                         2
                        )
                ) semaine,
             fns.c_gauge_title, fns.doc_position_detail_id, fns.fal_lot_id,
             fns.fal_doc_prop_id, fns.fal_lot_prop_id, sto.stm_stock_id,
             '' stm_stm_location, fns.fal_pic_line_id,
             DECODE
                (fns.fal_pic_line_id,
                 NULL, '',
                 DECODE
                     (pcs.pc_config.getconfig ('FAL_PIC_WEEK_MONTH'),
                      1,  goo2.goo_major_reference
                       || ' - '
                       || TO_CHAR (fpl.pil_date, 'DD.MM.YYYY'),
                         goo2.goo_major_reference
                      || ' - '
                      || TRANSLATE
                                (doc_delay_functions.datetoweek (fpl.pil_date),
                                 '.',
                                 '/'
                                )
                     )
                ) fal_pic_line_descr,
             (SELECT com.cst_quantity_min
                FROM gco_compl_data_stock com
               WHERE sto.stm_stock_id = com.stm_stock_id(+)
                 AND goo.gco_good_id = com.gco_good_id(+)) cst_quantity_min,
             pcs.pc_config.getconfig
                                   ('DOC_DELAY_WEEKSTART')
                                                          doc_delay_weekstart
        FROM pac_person per,
             gco_good_category cat,
             gco_good goo,
             stm_stock sto,
             stm_location loc,
             fal_lot flo,
             fal_network_supply fns,
             fal_pic_line fpl,
             gco_good goo2
       WHERE fns.gco_good_id = goo.gco_good_id
         AND goo.gco_good_category_id = cat.gco_good_category_id
         AND fns.pac_third_id = per.pac_person_id(+)
         AND fns.stm_stock_id = sto.stm_stock_id
         AND fns.stm_location_id = loc.stm_location_id
         AND fns.fal_lot_id = flo.fal_lot_id(+)
         AND fns.fal_pic_line_id = fpl.fal_pic_line_id(+)
         AND fpl.gco_good_id = goo2.gco_good_id(+)
         AND fns.fan_beg_plan IS NOT NULL
         AND goo.goo_major_reference >= goo_major_reference_min
         AND goo.goo_major_reference <= goo_major_reference_max
         AND (
                   (instr( ';' || parameter_6  ||';' ,  ';' || sto.stm_stock_id ||';' ) > 0)
                OR (parameter_6 = '*')
             )
         AND ((   parameter_6 = '*'
               OR DECODE (flo.fal_lot_id,
                          NULL, DECODE (doc_position_detail_id,
                                        NULL, DECODE (fpl.fal_pic_line_id,
                                                      NULL, 0,
                                                      1
                                                     ),
                                        1
                                       ),
                          1
                         ) = 1
               OR (    parameter_7 = 1
                   AND DECODE (c_gauge_title,
                               '14', DECODE (fal_doc_prop_id,
                                             NULL, DECODE (fal_lot_prop_id,
                                                           NULL, 0,
                                                           1
                                                          ),
                                             1
                                            ),
                               0
                              ) = 1
                  )
               OR (    parameter_8 = 1
                   AND DECODE (c_gauge_title,
                               '14', 0,
                               DECODE (fal_doc_prop_id,
                                       NULL, DECODE (fal_lot_prop_id,
                                                     NULL, 0,
                                                     1
                                                    ),
                                       1
                                      )
                              ) = 1
                  )
              )
             )
      UNION ALL
      (SELECT   '1. STOCK' typ, goo.goo_major_reference, '', '', '',
                sto.sto_description,
                SUM (ssp.spo_theoretical_quantity) fan_balance_qty,
                TO_NUMBER (NULL), TO_NUMBER (NULL), TO_NUMBER (NULL), '',
                TO_NUMBER (NULL), TO_NUMBER (NULL), TO_NUMBER (NULL),
                TO_NUMBER (NULL), sto.stm_stock_id, empl.loc_description,
                TO_NUMBER (NULL), '',
                TO_NUMBER (NULL),
                pcs.pc_config.getconfig
                                   ('DOC_DELAY_WEEKSTART')
                                                          doc_delay_weekstart
           FROM stm_stock sto,
                stm_location loc,
                stm_location empl,
                gco_good_category cat,
                gco_good goo,
                stm_stock_position ssp
          WHERE goo.gco_good_category_id = cat.gco_good_category_id
            AND ssp.stm_stock_id = sto.stm_stock_id
            AND ssp.stm_location_id = loc.stm_location_id
            AND ssp.gco_good_id = goo.gco_good_id
            AND loc.stm_location_id = empl.stm_location_id(+)
            AND goo.goo_major_reference >= goo_major_reference_min
            AND goo.goo_major_reference <= goo_major_reference_max
            AND (((   parameter_6 = '*'
                   OR (instr( ';' || parameter_6  ||';' ,  ';' || sto.stm_stock_id ||';' ) > 0 )
                  )
                 )
                )
       GROUP BY goo.goo_major_reference,
                goo.gco_good_id,
                sto.sto_description,
                sto.stm_stock_id,
                empl.loc_description,
                pcs.pc_config.getconfig ('DOC_DELAY_WEEKSTART')
       UNION ALL
       SELECT   '1. STOCK' typ, goo.goo_major_reference, '', '', '',
                sto.sto_description,
                TO_NUMBER (NULL),
                TO_NUMBER (NULL), TO_NUMBER (NULL), TO_NUMBER (NULL), '',
                TO_NUMBER (NULL), TO_NUMBER (NULL), TO_NUMBER (NULL),
                TO_NUMBER (NULL), sto.stm_stock_id, loc.loc_description,
                TO_NUMBER (NULL), '',
                com.cst_quantity_min,
                pcs.pc_config.getconfig
                                   ('DOC_DELAY_WEEKSTART')
                                                          doc_delay_weekstart
           FROM gco_compl_data_stock com,
                gco_good goo,
                stm_stock sto,
                stm_location loc
          WHERE  com.gco_good_id = goo.gco_good_id
          AND com.stm_stock_id = sto.stm_stock_id(+)
            AND com.stm_location_id = loc.stm_location_id(+)
            AND com.cst_quantity_min IS NOT NULL
            AND goo.goo_major_reference >= goo_major_reference_min
            AND goo.goo_major_reference <= goo_major_reference_max
            AND (parameter_6 = '*'
                   OR (instr( ';' || parameter_6  ||';' ,  ';' || sto.stm_stock_id ||';' ) > 0 )
                )
      );
END rpt_fal_teps;
