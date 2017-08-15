--------------------------------------------------------
--  DDL for Package Body HRM_PRC_HISTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_HISTORY" 
as
   -- Additionnal data stored during the calculation process in java that will
  -- be retrieved in Delphi
  gxAdditionnalData xmltype;

  /**
  * procedure AddSessionAdditionalData
  * description :
  *    Ajoute du contenu XML à la variable de session gxAdditionnalData
  */
  procedure AddSessionAdditionalData(ixPart in xmltype)
  is
  begin
    select XMLConcat(gxAdditionnalData, ixPart)
      into gxAdditionnalData
      from dual;
  end AddSessionAdditionalData;

  /**
  * procedure ClearSessionAdditionalData
  * description :
  *    Ajoute du contenu XML à la variable de session gxAdditionnalData
  */
  procedure ClearSessionAdditionalData
  is
  begin
    gxAdditionnalData  := null;
  end ClearSessionAdditionalData;

  /**
  * procedure GetSessionAdditionalData
  * description :
  *    Retourne la valeur de la variable de session gxAdditionnalData
  */
  function GetSessionAdditionalData
    return clob
  is
    lcResult clob;
  begin
    if gxAdditionnalData is not null then
      select XMLElement(HRM_HISTORY, gxAdditionnalData).getCLOBVal()
        into lcResult
        from dual;
    end if;

    return lcResult;
  end GetSessionAdditionalData;

  /**
  * procedure SetAdditionalData
  * description :
  *    Sauvegarde les informations complémentaires lors du calcul dans la table HRM_HISTORY
  */
  procedure SetAdditionalData(
    iEmployeeID     in HRM_PERSON.HRM_PERSON_ID%type
  , iSheetID        in HRM_HISTORY.HRM_SALARY_SHEET_ID%type
  , iPayNum         in HRM_HISTORY.HIT_PAY_NUM%type
  , iAdditionalData in clob
  )
  is
  begin
    update HRM_HISTORY
       set HIT_ADDITIONAL_DATA = iAdditionalData
     where HRM_EMPLOYEE_ID = iEmployeeID
       and HRM_SALARY_SHEET_ID = iSheetID
       and HIT_PAY_NUM = iPayNum;
  end SetAdditionalData;
end HRM_PRC_HISTORY;
