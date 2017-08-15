--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_COMP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_COMP_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2,
   parameter_1   IN       asa_record_comp.asa_record_events_id%TYPE,
   parameter_2   IN       asa_record_comp.arc_optional%TYPE,
   parameter_3   IN       VARCHAR2,
   parameter_4   IN       NUMBER
)
IS
/*
* description used for report asa_report_form3

* @created in proconcept china
* @created pna 3 sep 2007
* @lastupdate VHA 26 JUNE 2013
* @public
* @param parameter_0: asa_record.asa_record_id
* @param parameter_1: asa_record_events.asa_record_events_id
* @param parameter_2: arc_optional
* @param parameter_3: a_datecre of last offer
* @param parameter_4: boolean 0  date is smaller or equal, 1 - date is bigger or equal
*/
   optional   VARCHAR2 (10) := null;
BEGIN
    if (parameter_2 is not null) then
       CASE parameter_2
          WHEN 0
          THEN
             optional := '0';
          WHEN 1
          THEN
             optional := '1';
          WHEN 2
          THEN
             optional := '0,1';
       END CASE;
    end if;

   OPEN arefcursor FOR
      SELECT arc.asa_record_comp_id, arc.asa_record_id, arc.arc_position,
             arc.gco_component_id, arc.arc_sale_price, arc.arc_quantity,
             arc.arc_sale_price * arc.arc_quantity arc_total_price,
             arc.stm_comp_location_id, arc.a_datecre, arc.arc_optional,
             arc.asa_record_events_id, arc.arc_descr, arc.arc_descr2,
             arc.stm_comp_stock_mvt_id, arc.c_asa_accept_option,
             goo.goo_major_reference, goo.dic_good_family_id,
             goo.goo_number_of_decimal, cat.dic_category_free_1_id
        FROM asa_record_comp arc, gco_good goo, gco_good_category cat
       WHERE arc.gco_component_id = goo.gco_good_id
         AND goo.gco_good_category_id = cat.gco_good_category_id(+)
         AND arc.asa_record_id = TO_NUMBER (parameter_0)
         AND arc.asa_record_events_id = parameter_1
         AND INSTR (optional, TO_CHAR (arc.arc_optional)) > 0
         AND (   (    parameter_4 = '0'
                  AND (arc.a_datecre) <=
                               (TO_DATE (parameter_3, 'YYYYMMDD HH24:MI:SS')
                               )
                 )
              OR (    parameter_4 = '1'
                  AND (arc.a_datecre) >
                               (TO_DATE (parameter_3, 'YYYYMMDD HH24:MI:SS')
                               )
                 )
             );
END rpt_asa_record_form3_comp_sub;
