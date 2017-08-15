--------------------------------------------------------
--  DDL for Procedure RPT_GAL_PRJ_DF_LISTEART_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_PRJ_DF_LISTEART_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_1    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for subreport GAL_PROJECT_DF_LISTEARTICLE used in report GAL_PROJECT_BON_OP_DF

* @author VHA
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param parameter_1: GAL_TASK_LINK_ID
*/
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if (parameter_1 is not null) then
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
         , GAL_PROJECT_ID
         , PRJ_WORDING
         , DFCODE
         , DFDESCRIPTION
         , DFWORDING
         , DFSTARTDATE
         , DFENDDATE
         , DFAUTHOR
         , DFVERSION
         , DFSTATE
         , DFPRIORITY
         , DFTCA_WORDING
         , GAL_TASK_ID
         , GAL_TASK_ID_2
         , GAL_FATHER_TASK_ID
         , DFLOCATION
         , TAS_CODE
         , TAS_WORDING
         , TAS_END_DATE
         , TAS_VERSION
         , TAS_AUTHOR
         , DIC_GLO_WORDING
         , PER_NAME
         , PER_FORENAME
         , GTL_SEQUENCE
         , GTL_PLAN_NUMBER
         , GTL_QUANTITY
         , GTL_PLAN_VERSION
         , SCS_STEP_NUMBER
         , SCS_SHORT_DESCR
         , SCS_FREE_DESCR
         , SCS_LONG_DESCR
         , TAL_DUE_TSK
         , TAL_TSK_BALANCE
         , TAL_ACHIEVED_TSK
         , TAL_END_PLAN_DATE
         , TAL_BEGIN_PLAN_DATE
         , GAL_TASK_LINK_ID
         , CB_GAL_TASK_LINK_ID
         , FAC_REFERENCE
         , FAC_DESCRIBE
         , GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
         , PC_LANG_ID
         , DES_SHORT_DESCRIPTION
         , DES_LONG_DESCRIPTION
         , DES_FREE_DESCRIPTION
         , TAS_DESCRIPTION
         , C_TASK_TYPE
         , DOC_RECORD_ID
      from (select PRJ_CODE
                 , GAL_PROJECT.GAL_PROJECT_ID
                 , PRJ_WORDING
                 , TASCHILD.TAS_CODE DFCODE
                 , TASCHILD.TAS_DESCRIPTION DFDESCRIPTION
                 , TASCHILD.TAS_WORDING DFWORDING
                 , TASCHILD.TAS_START_DATE DFSTARTDATE
                 , TASCHILD.TAS_END_DATE DFENDDATE
                 , TASCHILD.TAS_AUTHOR DFAUTHOR
                 , TASCHILD.TAS_VERSION DFVERSION
                 , TASCHILD.C_TAS_STATE DFSTATE
                 , TASCHILD.TAS_PRIORITY DFPRIORITY
                 , TCA_WORDING DFTCA_WORDING
                 , to_char(TASCHILD.GAL_TASK_ID) GAL_TASK_ID
                 , TASCHILD.GAL_TASK_ID GAL_TASK_ID_2
                 , to_char(TASCHILD.GAL_FATHER_TASK_ID) GAL_FATHER_TASK_ID
                 , nvl(CHILDLOCATION.DIC_GLO_WORDING, nvl(FATHERLOCATION.DIC_GLO_WORDING, AFFAIRELOCATION.DIC_GLO_WORDING) ) DFLOCATION
                 , TASFATHER.TAS_CODE
                 , TASFATHER.TAS_WORDING
                 , TASFATHER.TAS_END_DATE
                 , TASFATHER.TAS_VERSION
                 , TASFATHER.TAS_AUTHOR
                 , FATHERLOCATION.DIC_GLO_WORDING
                 , PER_NAME
                 , PER_FORENAME
                 , GTL_SEQUENCE
                 , GTL_PLAN_NUMBER
                 , GTL_QUANTITY
                 , GTL_PLAN_VERSION
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
                 , GAL_TASK_LINK.GAL_TASK_LINK_ID CB_GAL_TASK_LINK_ID
                 , FAC_REFERENCE
                 , FAC_DESCRIBE
                 , GOO_MAJOR_REFERENCE
                 , GOO_SECONDARY_REFERENCE
                 , PC_LANG_ID
                 , DES_SHORT_DESCRIPTION
                 , DES_LONG_DESCRIPTION
                 , DES_FREE_DESCRIPTION
                 , TASFATHER.TAS_DESCRIPTION
                 , C_TASK_TYPE
                 , GAL_TASK_LINK.DOC_RECORD_ID
              from GAL_TASK_CATEGORY
                 , GAL_TASK_LOT_LINK
                 , GAL_TASK_LOT
                 , GAL_TASK_LINK
                 , GAL_TASK TASCHILD
                 , GAL_TASK TASFATHER
                 , DIC_GAL_LOCATION CHILDLOCATION
                 , DIC_GAL_LOCATION FATHERLOCATION
                 , DIC_GAL_LOCATION AFFAIRELOCATION
                 , GAL_PROJECT
                 , GCO_GOOD
                 , GCO_DESCRIPTION
                 , FAL_FACTORY_FLOOR
                 , PAC_CUSTOM_PARTNER
                 , PAC_PERSON
             where GAL_TASK_LOT.GAL_TASK_LOT_ID = GAL_TASK_LOT_LINK.GAL_TASK_LOT_ID
               and GAL_TASK_LOT_LINK.GAL_TASK_LINK_ID = GAL_TASK_LINK.GAL_TASK_LINK_ID
               and TASCHILD.GAL_TASK_ID = GAL_TASK_LOT_LINK.GAL_TASK_ID
               and TASCHILD.GAL_FATHER_TASK_ID = TASFATHER.GAL_TASK_ID(+)
               and TASCHILD.GAL_PROJECT_ID = GAL_PROJECT.GAL_PROJECT_ID
               and TASCHILD.DIC_GAL_LOCATION_ID = CHILDLOCATION.DIC_GAL_LOCATION_ID(+)
               and TASFATHER.DIC_GAL_LOCATION_ID = FATHERLOCATION.DIC_GAL_LOCATION_ID(+)
               and AFFAIRELOCATION.dic_gal_location_id(+) = GAL_PROJECT.dic_gal_location_id
               and GAL_TASK_LOT.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID
               and GCO_GOOD.GCO_GOOD_ID = GCO_DESCRIPTION.GCO_GOOD_ID
               and GCO_DESCRIPTION.C_DESCRIPTION_TYPE = '01'
               and GAL_TASK_LINK.FAL_FACTORY_FLOOR_ID = FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID(+)
               and PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = PAC_PERSON.PAC_PERSON_ID(+)
               and GAL_PROJECT.PAC_CUSTOM_PARTNER_ID = PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID(+)
               and TASCHILD.GAL_TASK_CATEGORY_ID = GAL_TASK_CATEGORY.GAL_TASK_CATEGORY_ID(+)
            union
            select PRJ_CODE
                 , GAL_PROJECT.GAL_PROJECT_ID
                 , PRJ_WORDING
                 , TASCHILD.TAS_CODE DFCODE
                 , TASCHILD.TAS_DESCRIPTION DFDESCRIPTION
                 , TASCHILD.TAS_WORDING DFWORDING
                 , TASCHILD.TAS_START_DATE DFSTARTDATE
                 , TASCHILD.TAS_END_DATE DFENDDATE
                 , TASCHILD.TAS_AUTHOR DFAUTHOR
                 , TASCHILD.TAS_VERSION DFVERSION
                 , TASCHILD.C_TAS_STATE DFSTATE
                 , TASCHILD.TAS_PRIORITY DFPRIORITY
                 , TCA_WORDING DFTCA_WORDING
                 , to_char(TASCHILD.GAL_TASK_ID) GAL_TASK_ID
                 , TASCHILD.GAL_TASK_ID GAL_TASK_ID_2
                 , to_char(TASCHILD.GAL_FATHER_TASK_ID) GAL_FATHER_TASK_ID
                 , nvl(CHILDLOCATION.DIC_GLO_WORDING, nvl(FATHERLOCATION.DIC_GLO_WORDING, AFFAIRELOCATION.DIC_GLO_WORDING) ) DFLOCATION
                 , TASFATHER.TAS_CODE
                 , TASFATHER.TAS_WORDING
                 , TASFATHER.TAS_END_DATE
                 , TASFATHER.TAS_VERSION
                 , TASFATHER.TAS_AUTHOR
                 , FATHERLOCATION.DIC_GLO_WORDING
                 , PER_NAME
                 , PER_FORENAME
                 , null
                 , null
                 , null
                 , null
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
                 , GAL_TASK_LINK.GAL_TASK_LINK_ID CB_GAL_TASK_LINK_ID
                 , FAC_REFERENCE
                 , FAC_DESCRIBE
                 , null
                 , null
                 , 99
                 , null
                 , null
                 , null
                 , TASFATHER.TAS_DESCRIPTION
                 , C_TASK_TYPE
                 , GAL_TASK_LINK.DOC_RECORD_ID
              from GAL_TASK_CATEGORY
                 , GAL_TASK_LOT_LINK
                 , GAL_TASK_LINK
                 , GAL_TASK TASCHILD
                 , GAL_TASK TASFATHER
                 , DIC_GAL_LOCATION CHILDLOCATION
                 , DIC_GAL_LOCATION FATHERLOCATION
                 , DIC_GAL_LOCATION AFFAIRELOCATION
                 , GAL_PROJECT
                 , FAL_FACTORY_FLOOR
                 , PAC_CUSTOM_PARTNER
                 , PAC_PERSON
             where TASCHILD.GAL_TASK_ID = GAL_TASK_LINK.GAL_TASK_ID
               and GAL_TASK_LINK.GAL_TASK_LINK_ID = GAL_TASK_LOT_LINK.GAL_TASK_LINK_ID(+)
               and TASCHILD.GAL_FATHER_TASK_ID = TASFATHER.GAL_TASK_ID(+)
               and TASCHILD.GAL_PROJECT_ID = GAL_PROJECT.GAL_PROJECT_ID
               and TASCHILD.DIC_GAL_LOCATION_ID = CHILDLOCATION.DIC_GAL_LOCATION_ID(+)
               and TASFATHER.DIC_GAL_LOCATION_ID = FATHERLOCATION.DIC_GAL_LOCATION_ID(+)
               and AFFAIRELOCATION.dic_gal_location_id(+) = GAL_PROJECT.dic_gal_location_id
               and GAL_TASK_LINK.FAL_FACTORY_FLOOR_ID = FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID(+)
               and PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = PAC_PERSON.PAC_PERSON_ID(+)
               and GAL_PROJECT.PAC_CUSTOM_PARTNER_ID = PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID(+)
               and TASCHILD.GAL_TASK_CATEGORY_ID = GAL_TASK_CATEGORY.GAL_TASK_CATEGORY_ID(+))
     where GAL_TASK_LINK_ID = to_number(parameter_1)
       and PC_LANG_ID = vpc_lang_id;
end RPT_GAL_PRJ_DF_LISTEART_SUB;
