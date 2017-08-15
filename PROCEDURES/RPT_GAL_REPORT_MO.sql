--------------------------------------------------------
--  DDL for Procedure RPT_GAL_REPORT_MO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_REPORT_MO" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for reports GAL_PROJECT_BON_OP_MO and GAL_PROJECT_FICHESUIVEUSE_MO

* @author VHA
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param parameter_0: GAL_TASK_ID
*/
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if (parameter_0 is not null) then
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
    select PRJ_CODE
         , GAL_PROJECT.GAL_PROJECT_ID
         , PRJ_WORDING
         , TAS_CODE
         , TAS_WORDING
         , TAS_START_DATE
         , TAS_END_DATE
         , TAS_AUTHOR
         , TAS_VERSION
         , to_char(GAL_TASK.GAL_TASK_ID) GAL_TASK_ID
         , nvl(TASKLOCATION.DIC_GLO_WORDING, AFFAIRELOCATION.DIC_GLO_WORDING) DIC_GLO_WORDING
         , PER_NAME
         , PER_FORENAME
         , SCS_STEP_NUMBER
         , SCS_SHORT_DESCR
         , SCS_FREE_DESCR
         , SCS_LONG_DESCR
         , TAL_DUE_TSK
         , TAL_TSK_BALANCE
         , TAL_ACHIEVED_TSK
         , TAL_END_PLAN_DATE
         , TAL_BEGIN_PLAN_DATE
         , to_char(GAL_TASK_LINK.GAL_TASK_LINK_ID) GAL_TASK_LINK_ID
         , FAC_REFERENCE
         , FAC_DESCRIBE
         , TAS_DESCRIPTION
      from GAL_TASK_LINK
         , GAL_TASK
         , DIC_GAL_LOCATION TASKLOCATION
         , DIC_GAL_LOCATION AFFAIRELOCATION
         , GAL_PROJECT
         , FAL_FACTORY_FLOOR
         , PAC_CUSTOM_PARTNER
         , PAC_PERSON
     where GAL_TASK.GAL_PROJECT_ID = GAL_PROJECT.GAL_PROJECT_ID
       and GAL_TASK.GAL_TASK_ID = GAL_TASK_LINK.GAL_TASK_ID
       and GAL_TASK.DIC_GAL_LOCATION_ID = TASKLOCATION.DIC_GAL_LOCATION_ID(+)
       and GAL_PROJECT.DIC_GAL_LOCATION_ID = AFFAIRELOCATION.DIC_GAL_LOCATION_ID(+)
       and GAL_TASK_LINK.FAL_FACTORY_FLOOR_ID = FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID
       and PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = PAC_PERSON.PAC_PERSON_ID(+)
       and GAL_PROJECT.PAC_CUSTOM_PARTNER_ID = PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID(+)
       and GAL_TASK.GAL_TASK_ID = to_number(parameter_0);
end RPT_GAL_REPORT_MO;
