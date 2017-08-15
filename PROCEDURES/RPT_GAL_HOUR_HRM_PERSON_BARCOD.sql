--------------------------------------------------------
--  DDL for Procedure RPT_GAL_HOUR_HRM_PERSON_BARCOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_HOUR_HRM_PERSON_BARCOD" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, poste_beg    in     varchar2
, poste_end    in     varchar2
, emp_beg    in     varchar2
, emp_end    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report GAL_HOUR_HRM_PERSON_BARCOD

* @author VHA
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param poste_beg: JOB_CODE
* @param poste_end: JOB_CODE
* @param emp_beg: EMP_NUMBER
* @param emp_end: EMP_NUMBER
*/
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if ((procuser_lanid is not null) and (pc_user_id is not null) and (pc_comp_id is not null) and (pc_conli_id is not null)) then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
      vpc_lang_id   := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id   := PCS.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id   := PCS.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id  := PCS.PC_I_LIB_SESSION.getConliId;
  end if;

  open arefcursor for
    select   PER.HRM_PERSON_ID
             , PER.EMP_NUMBER
             , PER.PER_FIRST_NAME
             , PER.PER_LAST_NAME
             , HJB.HRM_JOB_ID
             , HJB.JOB_CODE
             , HJB.JOB_DESCR
             , HPJ.PEJ_FROM
             , HPJ.PEJ_TO
      from HRM_JOB HJB
         , HRM_PERSON PER
         , HRM_PERSON_JOB HPJ
     where HJB.HRM_JOB_ID(+) = HPJ.HRM_JOB_ID
       and HPJ.HRM_PERSON_ID = PER.HRM_PERSON_ID
       and (    (HPJ.PEJ_FROM is null)
            or (HPJ.PEJ_FROM <= sysdate) )
       and (    (HPJ.PEJ_TO is null)
            or (HPJ.PEJ_TO >= sysdate) )
       and (    (poste_beg = '*')
            or (HJB.JOB_CODE >= poste_beg) )
       and (    (poste_end = '*')
            or (HJB.JOB_CODE <= poste_end) )
       and (    (    (emp_beg = '*')
                 or (PER.EMP_NUMBER is null) )
            or (PER.EMP_NUMBER >= emp_beg) )
       and (    (emp_end = '*')
            or (PER.EMP_NUMBER <= emp_end) );
end RPT_GAL_HOUR_HRM_PERSON_BARCOD;
