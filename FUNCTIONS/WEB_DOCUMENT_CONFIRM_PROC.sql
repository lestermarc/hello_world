--------------------------------------------------------
--  DDL for Function WEB_DOCUMENT_CONFIRM_PROC
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "WEB_DOCUMENT_CONFIRM_PROC" (
    WEB_DOCUMENT_CONFIRM_PROC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , pEcoUserId in econcept.eco_users.eco_users_id%type
  , pMsg out varchar2
) RETURN NUMBER
IS
tmpVar doc_document.doc_document_id%type;
tmpStatus doc_document.C_DOCUMENT_STATUS%type;
tmpErrorCode varchar2(10);
tmpErrorMsg  varchar2(2000);
/******************************************************************************
   NAME:       WEB_DOCUMENT_CONFIRM_PROC
   PURPOSE: exemple de procédure appelée depuis ePrint, ici cpour confirmer un
   document logistique


******************************************************************************/
BEGIN
   pMsg := '<b>Document validé.</b>';

  select
     doc_document_id,
     C_DOCUMENT_STATUS
   into
     tmpVar,
     tmpStatus
   from
     doc_document
   where
     doc_document_id = WEB_DOCUMENT_CONFIRM_PROC_ID;

    if (tmpStatus <> '01' ) then
      pMsg := '<b>Document déjà validé.</b>';
      return WEB_FUNCTIONS.RETURN_WARNING;
    end if;

   doc_document_functions.CONFIRMDOCUMENT(tmpVar,tmpErrorCode,tmpErrorMsg,0);
   commit;

  pMsg := tmpErrorCode||' '||tmpErrorMsg;

   RETURN  WEB_FUNCTIONS.RETURN_WARNING;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       pMsg := '<b>Document non trouvé.</b>';
       return WEB_FUNCTIONS.RETURN_WARNING;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       pMsg := '<b>Document non trouvé.</b>';
       return WEB_FUNCTIONS.RETURN_FATAL;
END WEB_DOCUMENT_CONFIRM_PROC;
