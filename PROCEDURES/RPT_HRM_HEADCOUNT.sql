--------------------------------------------------------
--  DDL for Procedure RPT_HRM_HEADCOUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_HEADCOUNT" (
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
 *   05.12.2013: Procedure renamed  from HRM_HEADCOUNT_RPT to RPT_HRM_HEADCOUNT
 */
is
  vLangId PCS.PC_LANG.PC_LANG_ID%TYPE;
  vRefDate DATE;
  vRefDateEnd DATE;
  vEndDate DATE;
begin
  vLangId := PR_PC_USELANG_ID;

  -- Dates
  vEndDate := to_date('31.12.2022', 'dd.mm.yyyy');

  if (PROCPARAM_0 is not null) then
    vRefDate := to_date(PROCPARAM_0||'01', 'yyyymmdd');
  end if;

  vRefDateEnd := last_day(vRefDate);

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
      when 6 then AXE||' '||COM_DIC_FUNCTIONS.getDicoDescr('DIC_RESPONSABILITY', AXE, vLangId)
      when 7 then AXE||' '||COM_DIC_FUNCTIONS.getDicoDescr('DIC_PROFESSIONAL_CATEGORY', AXE, vLangId)
    end AXE,
    EFFECTIF,
    EFFECTIF_H,
    EFFECTIF_F,
    RATE,
    RATE_H,
    RATE_F,
    CNT_IN,
    CNT_OUT,
    CNT_IN - CNT_OUT DIFF_INOUT,
    AGE,
    SENIORITY
    FROM
      (SELECT
         AXE,
         SUM(CNT) EFFECTIF,
         SUM(case PER_GENDER when 'M' then CNT else 0 end) EFFECTIF_H,
         SUM(case PER_GENDER when 'F' then CNT else 0 end) EFFECTIF_F,
         SUM(RATE) RATE,
         SUM(case PER_GENDER when 'M' then RATE else 0 end) RATE_H,
         SUM(case PER_GENDER when 'F' then RATE else 0 end) RATE_F,
         SUM(CNT_IN) CNT_IN,
         SUM(CNT_OUT) CNT_OUT,
         AVG(AGE) AGE,
         AVG(SENIORITY) SENIORITY
       FROM
         (SELECT
            case PROCPARAM_1
              when 0 then j.dic_department_id
              when 1 then j.job_div_number
              when 2 then j.job_cda_number
              when 3 then j.job_pf_number
              when 4 then j.job_pj_number
              when 5 then j.job_code||' '||job_descr
              when 6 then j.dic_responsability_id
              when 7 then j.dic_professional_category_id
            end AXE,
            case when pej_from >= vRefDate then 1 else 0 end CNT_IN,  -- Entrée dans le mois
            case when pej_to <= vRefDateEnd then 1 else 0 end CNT_OUT, -- Sortie dans le mois
            1 CNT,
            pj.pej_affect_rate / 100 RATE,
            hrm_functions.AgeInGivenPeriod(vRefDate, per_birth_date) AGE,
            trunc(months_between(
                Least(last_day(pej_to), vRefDateEnd),
                last_day(pej_from)) / 12) SENIORITY,
            p.per_gender
          FROM
            hrm_person p,
            hrm_job j,
            (SELECT  pej_from, nvl(pej_to, vEndDate) pej_to, pej_affect_rate,
               hrm_job_id, hrm_person_id
             FROM hrm_person_job) pj
          WHERE
            p.hrm_person_id = pj.hrm_person_id AND
            j.hrm_job_id = pj.hrm_job_id AND
            -- Employés présent, entrés ou sortis dans la période
            vRefDate between trunc(pej_from, 'month') and pej_to) v
       GROUP BY
         AXE);
end RPT_HRM_HEADCOUNT;
