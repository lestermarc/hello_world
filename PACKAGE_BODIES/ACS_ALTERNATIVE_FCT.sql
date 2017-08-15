--------------------------------------------------------
--  DDL for Package Body ACS_ALTERNATIVE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_ALTERNATIVE_FCT" 
is

  /**
  * Description Fonctions principale d'imporation des comptes financier dans la présentation alternative
  **/
  procedure AccImportTreatement(pAlternative ACS_ALTERNATIVE.ACS_ALTERNATIVE_ID%type, pDescription number, pTreated in out number)
  is
  begin
    if AllAccImported(pAlternative) = 1 then
      pTreated := 0;
    else
      ImportAccIntoSynonym(pAlternative);
      if pDescription = 1 then
        ImportAltDescription(pAlternative);
      end if;
      pTreated := 1;
	  end if;
  end AccImportTreatement;

  /**
  * Description Tester si tous les comptes sont dans la présentation alternative(1) ou non(0)
  **/
  function AllAccImported(pAlternative ACS_ALTERNATIVE.ACS_ALTERNATIVE_ID%type)
    return number
  is
    vCounter number;
    vResult  number;
  begin
    select count(*)
    into vCounter
    from ACS_ACCOUNT ACC, ACS_SUB_SET SUB
    where ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
      and SUB.C_SUB_SET = 'ACC'
      and not exists (select 1 from ACS_SYNONYM_DATA SYN where SYN.ACS_ALTERNATIVE_ID = pAlternative and ACC.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID);
    if vCounter   = 0 then vResult := 1;
    elsif vCounter > 0 then vResult := 0;
    end if;
    return vResult;
  end;

  /**
  * Description Imporations de tous les comptes dans la table des synonymes
  **/
  procedure ImportAccIntoSynonym(pAlternative ACS_ALTERNATIVE.ACS_ALTERNATIVE_ID%type)
  is
  begin
    insert into ACS_SYNONYM_DATA(
        ACS_SYNONYM_DATA_ID
      , ACS_ALTERNATIVE_ID
      , ACS_ACCOUNT_ID
      , SYN_NUMBER
      , A_DATECRE
      , A_IDCRE)
    select INIT_ID_SEQ.nextval
         , pAlternative
         , ACC.ACS_ACCOUNT_ID
         , ACC.ACC_NUMBER
         , SYSDATE
         , PCS.PC_I_LIB_SESSION.GetUserIni
    from ACS_ACCOUNT ACC
       , ACS_SUB_SET SUB
    where ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
      and SUB.C_SUB_SET = 'ACC'
      and not exists (select 1 from ACS_SYNONYM_DATA SYN where SYN.ACS_ALTERNATIVE_ID = pAlternative and ACC.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID);
  end ImportAccIntoSynonym;

  /**
  * Description Importations des descriptifs des comptes alternatifs
  **/
  procedure ImportAltDescription(pAlternative ACS_ALTERNATIVE.ACS_ALTERNATIVE_ID%type)
  is
  begin
    insert into ACS_ALT_DESCRIPTION(
        ACS_ALT_DESCRIPTION_ID
      , ACS_SYNONYM_DATA_ID
      , ALT_DESCRIPTION
      , ALT_LONG_DESCRIPTION
      , PC_LANG_ID
      , A_DATECRE
      , A_IDCRE)
    select INIT_ID_SEQ.nextval
         , SYN.ACS_SYNONYM_DATA_ID
         , DES.DES_DESCRIPTION_SUMMARY
         , DES.DES_DESCRIPTION_LARGE
         , DES.PC_LANG_ID
         , SYSDATE
         , PCS.PC_I_LIB_SESSION.GetUserIni
    from ACS_DESCRIPTION DES
       , ACS_SYNONYM_DATA SYN
    where SYN.ACS_ALTERNATIVE_ID = pAlternative
      and DES.ACS_ACCOUNT_ID     = SYN.ACS_ACCOUNT_ID
      and not exists ( select 1 from  ACS_ALT_DESCRIPTION DES2, ACS_SYNONYM_DATA SYN2
                       where SYN2.ACS_SYNONYM_DATA_ID  =  DES2.ACS_SYNONYM_DATA_ID
                         and SYN.ACS_SYNONYM_DATA_ID    = SYN2.ACS_SYNONYM_DATA_ID );
  end ImportAltDescription;


end ACS_ALTERNATIVE_FCT;
