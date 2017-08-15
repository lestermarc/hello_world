--------------------------------------------------------
--  DDL for Procedure RPT_ACJ_CATALOGUE_TYPE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACJ_CATALOGUE_TYPE" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_0 in     varchar2
, PARAMETER_1 in     varchar2
, PARAMETER_2 in     varchar2
, PARAMETER_3 in     varchar2
, PARAMETER_4 in     varchar2
, PARAMETER_5 in     varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
* description used for report ACJ_CATALOGE_TYPE

* @author JLIU
* @lastupdate 1 Sep 2009
* @public
* @param PARAMETER_0    Modèle de (MOD_DESCR)
* @param PARAMETER_1    Modèle à  (MOD_DESCR)
* @param PARAMETER_2    Sélection : 0 = Aucune, 1 = Création, 2 = Modification
* @param PARAMETER_3    Date du : (ACJ_CATALOGUE_TYPE.A_DATECRE ou  ACJ_CATALOGUE_TYPE.A_DATEMOD)
* @param PARAMETER_4    Date au : (ACJ_CATALOGUE_TYPE.A_DATECRE ou ACJ_CATALOGUE_TYPE.A_DATEMOD)
* @param PARAMETER_5    Initiales User : (ACJ_CATALOGUE_TYPE.A_IDCRE ou ACJ_CATALOGUE_TYPE.A_IDMOD)
*/

begin

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);

open aRefCursor for

 SELECT
 acj.acj_catalogue_type_id,
 acj.mod_key,
 acj.mod_descr,
 acj.c_type_catalogue,
 acj.c_model_typ,
 acj.acs_financial_currency_id,
 cur.pc_curr_id,
 acj.c_round_type,
 acj.mod_rounded_amount,
 acj.a_datecre,
 acj.a_datemod,
 acj.a_idcre,
 acj.a_idmod
 FROM
 acs_financial_currency cur,
 acj_catalogue_type acj
 WHERE
 acj.acs_financial_currency_id = cur.acs_financial_currency_id
 AND (acj.MOD_DESCR >= NVL(PARAMETER_0,'A') AND acj.MOD_DESCR <= NVL(PARAMETER_1,'z'))
 AND (PARAMETER_2='0'
      OR
      (PARAMETER_2 = '1' AND (PARAMETER_3 = '0' OR TRUNC(acj.A_DATECRE) >= TO_DATE(PARAMETER_3,'YYYYMMDD'))
                         AND (PARAMETER_4 = '0' OR TRUNC(acj.A_DATECRE) <= TO_DATE(PARAMETER_4,'YYYYMMDD'))
                         AND (PARAMETER_5 IS NULL OR ACJ.A_IDCRE = PARAMETER_5))
      OR
      (PARAMETER_2 = '2' AND (PARAMETER_3 = '0' OR TRUNC(acj.A_DATEMOD) >= TO_DATE(PARAMETER_3,'YYYYMMDD'))
                         AND (PARAMETER_4 = '0' OR TRUNC(acj.A_DATEMOD) <= TO_DATE(PARAMETER_4,'YYYYMMDD'))
                         AND (PARAMETER_5 IS NULL OR ACJ.A_IDMOD = PARAMETER_5))
      )


 ;


END RPT_ACJ_CATALOGUE_TYPE;
