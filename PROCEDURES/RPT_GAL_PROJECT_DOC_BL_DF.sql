--------------------------------------------------------
--  DDL for Procedure RPT_GAL_PROJECT_DOC_BL_DF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_PROJECT_DOC_BL_DF" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report GAL_PROJECT_DOC_BL_DF

* @author VHA
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param parameter_0: DMT_NUMBER
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
    select VDC.LANID
         , VDC.DMT_NUMBER
         , VDC.DOC_DOCUMENT_ID
         , VDC.FOO_FOOT_TEXT
         , VDC.POS_NUMBER
         , VDC.POS_REFERENCE
         , VDC.POS_SHORT_DESCRIPTION
         , VDC.POS_BODY_TEXT
         , VDC.POS_LONG_DESCRIPTION
         , VDC.POS_FREE_DESCRIPTION
         , VDC.C_GAUGE_TYPE_POS
         , VDC.POS_FINAL_QUANTITY
         , VDC.DIC_UNIT_OF_MEASURE_ID
         , VDC.POS_NET_VALUE_EXCL
         , VDC.DOC_POSITION_ID
         , VDC.PDE_CHARACTERIZATION_VALUE_1
         , VDC.PDE_CHARACTERIZATION_VALUE_2
         , VDC.PDE_CHARACTERIZATION_VALUE_3
         , VDC.PDE_CHARACTERIZATION_VALUE_4
         , VDC.PDE_CHARACTERIZATION_VALUE_5
         , VDC.PDE_FINAL_DELAY
         , VDC.P_PDE_FINAL_QUANTITY
         , VDC.DMT_TITLE_TEXT
         , VDC.DMT_HEADING_TEXT
         , VDC.DMT_DOCUMENT_TEXT
         , VDC.DMT_ADDRESS2
         , VDC.DMT_FORMAT_CITY2
         , VDC.PER_NAME
         , VDC.PER_FORENAME
         , VDC.PER_ACTIVITY
         , VDC.DMT_ADDRESS1
         , VDC.DMT_FORMAT_CITY1
         , VDC.GOO_NUMBER_OF_DECIMAL
         , VDC.POS_BASIS_QUANTITY
         , VDC.C_GAUGE_TITLE
         , VDC.PERE_DMT_NUMBER
         , VDC.G_PERE_DMT_NUMBER
         , VDC.C_DOCUMENT_STATUS
         , VDC.G_PERE_C_GAUGE_TITLE
         , VDC.G_PERE_DMT_DATE_DOCUMENT
         , VDC.PERE_C_GAUGE_TITLE
         , VDC.PERE_DMT_DATE_DOCUMENT
         , VDC.GCO1_CHARAC_DESCR
         , VDC.GCO2_CHARAC_DESCR
         , VDC.GCO3_CHARAC_DESCR
         , VDC.GCO4_CHARAC_DESCR
         , VDC.GCO5_CHARAC_DESCR
         , VDC.PDE_FINAL_QUANTITY
         , VDC.C_ADMIN_DOMAIN
         , VDC.C_GAUGE_SHOW_DELAY
         , VDC.PDE_INTERMEDIATE_DELAY
         , VDC.GAP_POS_DELAY
         , VDC.C_DOC_POS_STATUS
         , VDC.DMT_TOWN2
         , VDC.DMT_TOWN1
         , VDC.LOT_REFCOMPL
         , VDC.SCS_SHORT_DESCR
         , VDC.SCS_LONG_DESCR
         , VDC.SCS_FREE_DESCR
         , VDC.COMP_MAJOR_REFERENCE
         , VDC.GOO_MAJOR_REFERENCE
         , VDC.PER2_NAME
         , VDC.PER2_FORENAME
         , VDC.PER2_ACTIVITY
         , VDC.RCO_TITLE
         , GLK.GAL_TASK_LINK_ID
         , GLK.C_TASK_TYPE
         , GLK.SCS_SHORT_DESCR SCS_SHORT_DESCR_GLK
         , GLK.DOC_RECORD_ID
         , GLK1.SCS_SHORT_DESCR SCS_SHORT_DESCR_GLK_PREV
         , GTL.GCO_GOOD_ID
         , GTL.GTL_PLAN_VERSION
         , GTL.GTL_PLAN_NUMBER
         , GTD.GAL_TASK_LINK_ID_PREV
      from V_DOC_POS_4_PRNT VDC
         , GAL_TASK_LOT_LINK_DOC GTD
         , GAL_TASK_LINK GLK
         , GAL_TASK_LINK GLK1
         , GAL_TASK_LOT GTL
     where VDC.DOC_DOCUMENT_ID = GTD.DOC_DOCUMENT_ID
       and GTD.GAL_TASK_LINK_ID(+) = GLK.GAL_TASK_LINK_ID
       and GTD.GAL_TASK_LINK_ID_PREV = GLK1.GAL_TASK_LINK_ID
       and VDC.GCO_GOOD_ID = GTL.GCO_GOOD_ID
       and VDC.DMT_NUMBER = parameter_0;
end RPT_GAL_PROJECT_DOC_BL_DF;
