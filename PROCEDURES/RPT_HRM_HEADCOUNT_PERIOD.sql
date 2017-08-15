--------------------------------------------------------
--  DDL for Procedure RPT_HRM_HEADCOUNT_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_HEADCOUNT_PERIOD" (
  aRefCursor in out crystal_cursor_types.DualCursorTyp,
  PROCPARAM_0 VARCHAR2,
  PROCPARAM_1 number,
  PR_PC_USELANG_ID IN PCS.PC_LANG.PC_LANG_ID%TYPE
)
/**
 * @created 04/2008
 * @author ire
 * @update VHA 26 JUNE 2013
 *
 * Utilisé par le rapport HRM_HEADCOUNT.rpt
 * @param PROCPARAM_0  Période (YYYYMM)
 * @param PROCPARAM_1  Axe
 *
 * Modifications:
 *   05.12.2013: Procedure renamed from HRM_HEADCOUNT_PERIOD_RPT to RPT_HRM_HEADCOUNT_PERIOD
 */
is
  vLangId PCS.PC_LANG.PC_LANG_ID%TYPE := null;
  vRefDate DATE := null;
  vRefBeginDate DATE := null;
  vEndDate DATE := null;
begin
  vLangId := PR_PC_USELANG_ID;

  -- Dates
  vEndDate := to_date('31.12.2022', 'dd.mm.yyyy');

  if (PROCPARAM_0 is not null) then
    vRefDate := to_date(PROCPARAM_0||'01', 'yyyymmdd');
  end if;

  vRefBeginDate := trunc(vRefDate - 330, 'month');

  -- Query
  open aRefCursor for
  SELECT
    case PROCPARAM_1
      when 0 then AXE||' '||COM_DIC_FUNCTIONS.getDicoDescr('DIC_DEPARTMENT', AXE, vLangId)
      when 1 then AXE||' '||HRM_BREAK_FCT.get_Account_Descr('DTO', AXE, vLangId)
      when 2 then AXE||' '||HRM_BREAK_FCT.get_Account_Descr('CDA', AXE, vLangId)
      when 3 then AXE||' '||HRM_BREAK_FCT.get_Account_Descr('COS', AXE, vLangId)
      when 4 then AXE||' '||HRM_BREAK_FCT.get_Account_Descr('PRO', AXE, vLangId)
      when 5 then AXE
      when 6 then AXE||' '||COM_DIC_FUNCTIONS.getDicoDescr('DIC_PROFESSIONAL_CATEGORY', AXE, vLangId)
      when 7 then AXE||' '||COM_DIC_FUNCTIONS.getDicoDescr('DIC_RESPONSABILITY', AXE, vLangId)
    end AXE,
    PERIOD,
    EFFECTIF,
    CNT_IN,
    NVL(CNT_IN  / EFFECTIF * 100, 0) RATE_IN,
    CNT_OUT,
    NVL(CNT_OUT / EFFECTIF * 100, 0) RATE_OUT
  FROM
    (SELECT
       AXE,
       per_begin PERIOD,
       SUM(case when pej_from < per_begin then 1 end) EFFECTIF,-- Effectif au début du mois
       SUM(case when pej_from >= per_begin then 1 end) CNT_IN, -- Entrée dans le mois
       SUM(case when pej_to <= per_end then 1 end) CNT_OUT     -- Sortie dans le mois
     FROM
       (SELECT
          case PROCPARAM_1
            when 0 then j.dic_department_id
            when 1 then j.job_div_number
            when 2 then j.job_cda_number
            when 3 then j.job_pf_number
            when 4 then j.job_pj_number
            when 5 then j.job_code||' '||job_descr
            when 6 then j.dic_professional_category_id
            when 7 then j.dic_responsability_id
          end AXE,
          pej_from,
          pej_to,
          per_begin,
          per_end
        FROM
          hrm_job J,
          (SELECT pej_from, nvl(pej_to, vEndDate) pej_to, hrm_job_id FROM hrm_person_job) pj,
          hrm_period per
        WHERE
          j.hrm_job_id = pj.hrm_job_id AND
          -- Employés présent, entrés ou sortis dans la période
          pej_from <= per_end AND
          pej_to >= per_begin AND
          -- Filtre périodes selon date de référence
          per_begin BETWEEN vRefBeginDate AND vRefDate) v
     GROUP BY
       AXE, per_begin);

end RPT_HRM_HEADCOUNT_PERIOD;
