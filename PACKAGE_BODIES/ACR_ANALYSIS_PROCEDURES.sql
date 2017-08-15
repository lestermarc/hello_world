--------------------------------------------------------
--  DDL for Package Body ACR_ANALYSIS_PROCEDURES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_ANALYSIS_PROCEDURES" 

is
  /**
  * Exemple de procédure utilisée dans les actions d'analyse
  **/
  procedure ACR_ACTION_TEST_PROCEDURE(pAnalysisId        ACR_ANALYSIS.ACR_ANALYSIS_ID%type,
                                      pAnalysisMethodId  ACR_ANALYSIS_METHOD.ACR_ANALYSIS_METHOD_ID%type,
                                      pActionId          ACR_ANALYSIS_ACTION.ACR_ANALYSIS_ACTION_ID%type
                                      )
  is
    vCommentText  ACR_ANALYSIS.AAN_COMMENT%type;
  begin
    select AAN.AAN_DESCRIPTION ||CHR(13)||CHR(10) ||
           AAM.AAM_DESCRIPTION ||CHR(13)||CHR(10) ||
           AAT.AAT_DESCRIPTION ||CHR(13)||CHR(10) ||
           'EXECUTED ON  << '   || TO_CHAR(SYSDATE, 'DD.MM.YYYY  HH.MM.SS')   || ' >> ' ||CHR(13)||CHR(10) ||
           'EXECUTED BY  << '   || PCS.PC_I_LIB_SESSION.GetUserName || ' >> '
    into vCommentText
    from ACR_ANALYSIS_ACT_TYPE AAT, ACR_ANALYSIS AAN, ACR_ANALYSIS_METHOD AAM, ACR_ANALYSIS_ACTION AAA
    where AAN.ACR_ANALYSIS_ID          = pAnalysisId
      and AAM.ACR_ANALYSIS_METHOD_ID   = AAN.ACR_ANALYSIS_METHOD_ID
      and AAM.ACR_ANALYSIS_METHOD_ID   = AAT.ACR_ANALYSIS_METHOD_ID
      and AAA.ACR_ANALYSIS_ACTION_ID   = pActionId
      and AAT.ACR_ANALYSIS_ACT_TYPE_ID = AAA.ACR_ANALYSIS_ACT_TYPE_ID
      and AAM.ACR_ANALYSIS_METHOD_ID   = pAnalysisMethodId;


    update ACR_ANALYSIS
    set AAN_COMMENT = vCommentText
    where ACR_ANALYSIS_ID = pAnalysisId;
  end;

end ACR_ANALYSIS_PROCEDURES;
