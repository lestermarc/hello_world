--------------------------------------------------------
--  DDL for Procedure RPT_PAC_ADDRESS_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_ADDRESS_FORM" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2
)
IS
/**
 Description - used for the report PAC_ADDRESS_FORM

 @author AWU 1 Dec 2008
 @lastupdate 13 Feb 2009
 @public
 @PARAM  parameter_0  Client de : (PER_NAME)
 @PARAM  parameter_1  Client à : (PER_NAME)
 @PARAM  parameter_3  Sélection: 0 = Aucune, 1 = Création, 2 = Modification
 @PARAM  parameter_4  Date du: (Création ou modification) YYYYMMDD
 @PARAM  parameter_5  Date au: (Création ou modification) YYYYMMDD
 @PARAM  parameter_6  Initiales utilisateur: (Création ou modification)
 @PARAM  parameter_8  pac_person_id
*/
   vpc_lang_id             pcs.pc_lang.pc_lang_id%TYPE;
   param_a_datecre_start   DATE;
   param_a_datecre_end     DATE;
   param_a_idcre           VARCHAR2 (5);
   param_a_datemod_start   DATE;
   param_a_datemod_end     DATE;
   param_a_idmod           VARCHAR2 (5);
BEGIN
   CASE parameter_3
      WHEN '0'
      THEN
         NULL;
      WHEN '1'
      THEN
         IF parameter_4 = '0'
         THEN
            IF parameter_6 IS NOT NULL
            THEN
               param_a_idcre := parameter_6;
            END IF;
         ELSE
            param_a_datecre_start := parameter_4;
            param_a_datecre_end := parameter_5;

            IF parameter_6 IS NOT NULL
            THEN
               param_a_idcre := parameter_6;
            END IF;
         END IF;
      WHEN '2'
      THEN
         IF parameter_4 = '0'
         THEN
            IF parameter_6 IS NOT NULL
            THEN
               param_a_idmod := parameter_6;
            END IF;
         ELSE
            param_a_datemod_start := parameter_4;
            param_a_datemod_end := parameter_5;

            IF parameter_6 IS NOT NULL
            THEN
               param_a_idmod := parameter_6;
            END IF;
         END IF;
      ELSE
         NULL;
   END CASE;

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT per.pac_person_id, per.dic_person_politness_id, per.per_name,
             per.per_forename, per.per_short_name, per.per_contact,
             per.per_comment, per.per_activity, per.per_key1, per.per_key2,
             per.dic_free_code1_id, per.dic_free_code2_id,
             per.dic_free_code3_id, per.dic_free_code4_id,
             per.dic_free_code5_id, per.dic_free_code6_id,
             per.dic_free_code7_id, per.dic_free_code8_id,
             per.dic_free_code9_id, per.dic_free_code10_id,
             thi.dic_third_activity_id, thi.dic_third_area_id,
             thi.dic_juridical_status_id, thi.dic_citi_code_id,
             thi.thi_no_siren, thi.thi_no_siret, thi.thi_no_tva,
             thi.thi_no_intra, thi.thi_custom_number, thi.pac_pac_person_id
        FROM pac_third thi, pac_person per
       WHERE per.pac_person_id = thi.pac_third_id(+)
         AND (   (per.per_name >= parameter_0 AND per.per_name <= parameter_1
                 )
              OR (parameter_0 IS NULL AND parameter_1 IS NULL AND parameter_8 = per.pac_person_id)
             )
         AND (   (    per.a_datecre >= param_a_datecre_start
                  AND per.a_datecre <= param_a_datecre_end
                 )
              OR param_a_datecre_start IS NULL
             )
         AND (   per.a_idcre = param_a_idcre
              OR (    param_a_idcre IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '1')
                 )
             )
         AND (   (    per.a_datemod >= param_a_datemod_start
                  AND per.a_datemod <= param_a_datemod_end
                 )
              OR param_a_datemod_start IS NULL
             )
         AND (   per.a_idmod = param_a_idmod
              OR (    param_a_idmod IS NULL
                  AND (parameter_4 <> 0 OR parameter_3 <> '2')
                 )
             );
END rpt_pac_address_form;
