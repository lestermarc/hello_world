--------------------------------------------------------
--  DDL for Package Body ACT_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PUBLIC" 
is

  /**
  * Description
  *   Cette fonction détermine si un compte financier est tenu en ME
  */
  function isFinAccountInME(aACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type) return number
  is
  begin

    return ACS_FUNCTION.isFinAccountInME(aACS_FINANCIAL_ACCOUNT_ID);

  end isFinAccountInME;

  /**
  * Description
  *   Cette fonction retourne le nom abrégé du partenaire dont l'Id du compte est
  *   passé en paramètre, si le partenaire est de type "individuel" ou "groupe",
  *   le descriptif du compte auxiliaire si le partenaire est de type
  *   "Partenaire divers".
  */
  function GetPer_short_Name(aACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID %type)
    return ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY %type
  is
  begin

    return ACS_FUNCTION.GetPer_short_Name(aACS_AUXILIARY_ACCOUNT_ID);

  end GetPer_short_Name;

  /**
  * Description
  *   Cette fonction retourne le libellé court d'un compte, dans la langue de
  *   l'utilisateur courant.
  */
  function GetAccountDescriptionSummary(currency_id in number) return varchar2
  is
  begin

    return ACS_FUNCTION.GetAccountDescriptionSummary(currency_id);

  end GetAccountDescriptionSummary;

  /**
  * Description
  *   Cette fonction retourne l'Id de la monnaie de base
  */
  function GetLocalCurrencyId return number
  is
  begin

    return ACS_FUNCTION.GetLocalCurrencyId;

  end GetLocalCurrencyId;

  /**
  * Description
  *    Fonction de recherche du solde d'un compte financier ou d'un compte
  *    auxiliaire pour une division donnée, à une période donnée.
  */
  function PeriodSoldeAmount(aACS_ACCOUNT_ID            ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                             aACS_DIVISION_ACCOUNT_ID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                             aACS_PERIOD_ID             ACT_TOTAL_BY_PERIOD.ACS_PERIOD_ID%type,
                             aC_TYPE_CUMUL              ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type,
                             aLC                        number,
                             aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type)
    return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
  is
  begin

    return ACS_FUNCTION.PeriodSoldeAmount(aACS_ACCOUNT_ID, aACS_DIVISION_ACCOUNT_ID, aACS_PERIOD_ID, aC_TYPE_CUMUL,
                                          aLC, aACS_FINANCIAL_CURRENCY_ID);

  end PeriodSoldeAmount;

  /**
  * Description
  *   Cette fonction détermine si un utilisateur donné a le droit d'utiliser un
  *   modèle de travail donné
  */
  function IsUserAutorizedForJobType(aPC_USER_ID number, aACJ_JOB_TYPE_ID number) return number
  is
  begin

    return ACT_FUNCTIONS.IsUserAutorizedForJobType(aPC_USER_ID, aACJ_JOB_TYPE_ID);

  end IsUserAutorizedForJobType;

end;
