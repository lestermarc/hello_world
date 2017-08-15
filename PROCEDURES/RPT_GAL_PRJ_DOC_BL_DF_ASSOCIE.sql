--------------------------------------------------------
--  DDL for Procedure RPT_GAL_PRJ_DOC_BL_DF_ASSOCIE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_PRJ_DOC_BL_DF_ASSOCIE" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report GAL_PROJECT_DOC_BL_DF_DOC_ASSOCIE

* @author VHA
* @lastUpdate VHA 26 JUNE 2013
* @public
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
    select DOC.DOC_DOCUMENT_ID
         , DOC.DOC_GAUGE_ID
         , DOC.DMT_NUMBER
         , DOC.DMT_DATE_DOCUMENT
         , GAG.GAU_DESCRIBE
      from DOC_DOCUMENT DOC
         , DOC_GAUGE GAG
     where DOC.DOC_GAUGE_ID = GAG.DOC_GAUGE_ID;
end RPT_GAL_PRJ_DOC_BL_DF_ASSOCIE;
