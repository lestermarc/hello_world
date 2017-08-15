--------------------------------------------------------
--  DDL for Package Body HRM_LIB_HISTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_HISTORY" 
as
  /**
  * function HasAdditionalData
  * description :
  *    Indique s'il existe des données complémentaires lié à un décompte
  */
  function HasAdditionalData(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY.HIT_PAY_NUM%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_HISTORY
     where HRM_EMPLOYEE_ID = iEmployeeID
       and HIT_PAY_NUM = iPayNum
       and length(HIT_ADDITIONAL_DATA) > 0;

    return lnResult;
  end HasAdditionalData;
end HRM_LIB_HISTORY;
