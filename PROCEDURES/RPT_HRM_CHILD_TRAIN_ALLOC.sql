--------------------------------------------------------
--  DDL for Procedure RPT_HRM_CHILD_TRAIN_ALLOC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_CHILD_TRAIN_ALLOC" (
 aRefCursor       in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
 parameter_0      in     varchar2,
 procuser_lanid   in     PCS.PC_LANG.LANID%type
)
IS

/**
*Description
Used for report FAM_STRUCTURE

*author VHA
*created VHA 05 MAY 2011
*updated VHA 08 MAY 2012
* @public
*@param PARAMETER_0 :   Employee status
*/

vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;

begin
  PCS.PC_I_LIB_SESSION.setLanId (procuser_lanid);
  vpc_lang_id := PCS.PC_I_LIB_SESSION.GetUserLangId;

  open aRefCursor for
    select
        P.DIC_CANTON_WORK_ID,
        DC.WOC_DESCR,
        P.HRM_PERSON_ID,
        P.PER_LAST_NAME,
        P.PER_FIRST_NAME,
        P.EMP_NUMBER,
        HRM_VAR.childrenallowance(P.HRM_PERSON_ID, 1,'CHILDREN') + HRM_VAR.childrenallowance(P.HRM_PERSON_ID, 2,'CHILDREN') TOTAL_ALOC,
        R.REL_NAME,
        R.REL_FIRST_NAME,
        HRM_FUNCTIONS.ageingivenperiod(sysdate, R.REL_BIRTH_DATE) CHILDREN_AGE,
        R.REL_BIRTH_DATE,
        HRM_FUNCTIONS.arrayvalue2('CHILDREN',P.DIC_CANTON_WORK_ID||'1', HRM_FUNCTIONS.ageingivenperiod(sysdate, R.REL_BIRTH_DATE)) CHILDREN_ALOC,
        HRM_FUNCTIONS.arrayvalue2('CHILDREN',P.DIC_CANTON_WORK_ID||'2', HRM_FUNCTIONS.ageingivenperiod(sysdate, R.REL_BIRTH_DATE)) TRAINING_ALOC
    from
        HRM_PERSON P,
        DIC_CANTON_WORK DC,
        HRM_RELATED_TO R
    where
        P.DIC_CANTON_WORK_ID = DC.DIC_CANTON_WORK_ID
        and P.HRM_PERSON_ID = R.HRM_EMPLOYEE_ID
        and R.C_RELATED_TO_TYPE = '2'
        and (INSTR(','||parameter_0||',', TO_CHAR(','||P.EMP_STATUS||',')) > 0 OR parameter_0 is null)
        and R.REL_IS_DEPENDANT = 1
        and not exists(select 1 from HRM_RELATED_ALLOCATION A
                 where A.HRM_RELATED_TO_ID = R.HRM_RELATED_TO_ID and
                  sysdate between trunc(ALLO_BEGIN,'month') and nvl(ALLO_END, sysdate));
end RPT_HRM_CHILD_TRAIN_ALLOC;
