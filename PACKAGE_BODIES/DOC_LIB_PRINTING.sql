--------------------------------------------------------
--  DDL for Package Body DOC_LIB_PRINTING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_PRINTING" 
is
  /**********************************************************************
  * Description : Recherche l'ID du Flux actif selon un domaine et un tiers
  */
  function IsJobPartialyPrinted(iJobId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lTotalDetail  pls_integer;
    lTotalPrinted pls_integer;
  begin
    select count(*), sum(nvl(PJD_PRINTED,0))
      into lTotalDetail, lTotalPrinted
      from DOC_PRINT_JOB_DETAIL
     where DOC_PRINT_JOB_ID = iJobId;
    if lTotalPrinted > 0 and lTotalDetail <> lTotalPrinted then
      return 1;
    else
      return 0;
    end if;
  end IsJobPartialyPrinted;

end DOC_LIB_PRINTING;
