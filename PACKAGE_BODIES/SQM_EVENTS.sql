--------------------------------------------------------
--  DDL for Package Body SQM_EVENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_EVENTS" 
is
/*-----------------------------------------------------------------------------------*/
  procedure InactivateThird(pThirdId in SQM_RESULT.PAC_THIRD_ID%type, pGoodId in SQM_RESULT.GCO_GOOD_ID%type)
  is
    cStatus PAC_SUPPLIER_PARTNER.C_PARTNER_STATUS%type;
  begin
    select C_PARTNER_STATUS
      into cStatus
      from PAC_SUPPLIER_PARTNER
     where PAC_SUPPLIER_PARTNER_ID = pThirdId;

    if cStatus = '1' then
      update PAC_SUPPLIER_PARTNER
         set C_PARTNER_STATUS = '2'
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
       where PAC_SUPPLIER_PARTNER_ID = pThirdID;
    end if;
  end InactivateThird;
end SQM_EVENTS;
