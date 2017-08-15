--------------------------------------------------------
--  DDL for Package Body LPM_LIB_CONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_LIB_CONTRACT" 
as
  /**
  * procedure IsInContractPeriod
  * description :
  *    Détermine si une période est comprise dans la durée d'un contrat.
  */
  function IsInContractPeriod(iContractId in LPM_CONTRACT.LPM_CONTRACT_ID%type, iFromDate in date, iToDate in date)
    return integer
  is
    ln_result  integer;
    ld_maxdate date;
  begin
    select to_date('31129999', 'DDMMYYYY')
      into ld_maxdate
      from dual;

    select sign(count(*) )
      into ln_result
      from LPM_CONTRACT P
     where LPM_CONTRACT_ID = iContractId
       and iFromDate >= LCT_START_DATE
       and (   iToDate is null
            or iToDate <= nvl(LCT_END_DATE, ld_maxdate) );

    return ln_result;
  end IsInContractPeriod;

  /**
  * procedure HasReferents
  * description :
  *    Détermine si un contrat possède des appartenances.
  */
  function HasReferents(iContractId in LPM_CONTRACT.LPM_CONTRACT_ID%type)
    return integer
  is
    ln_result integer;
  begin
    select sign(count(*) )
      into ln_result
      from LPM_REFERENTS
     where LPM_CONTRACT_ID = iContractId;

    return ln_result;
  end HasReferents;
end LPM_LIB_CONTRACT;
