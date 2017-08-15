--------------------------------------------------------
--  DDL for Package Body HRM_LIB_TAXSOURCE_LEDGER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_TAXSOURCE_LEDGER" 
as
  /**
  * procedure IsTaxSourceListDefined
  * description :
  *    Indique si la liste d�di�e � l'imp�t � la source est d�finie correctement
  */
  function IsTaxSourceListDefined
    return integer
  is
    lnResult integer;
  begin
    -- Ctrl de coh�rance de la liste de type '111'
    select sign(count(*) )
      into lnResult
      from HRM_CONTROL_LIST COL
     where COL.C_CONTROL_LIST_TYPE = '111'
       and PCS.PC_CONFIG.GETCONFIG('HRM_LOCALISATION') = 'CH'
       and exists(select 1
                    from HRM_CONTROL_ELEMENTS COE
                   where COE.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                     and COE.COE_BOX = 'A')
       and exists(select 1
                    from HRM_CONTROL_ELEMENTS COE
                   where COE.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                     and COE.COE_BOX = 'B')
       and exists(select 1
                    from HRM_CONTROL_ELEMENTS COE
                   where COE.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                     and COE.COE_BOX = 'B3');

    return lnResult;
  end IsTaxSourceListDefined;

  /**
  * function IsEmployeePaySourceTaxed
  * description :
  *    Indique si le d�compte de l'employ� doit �tre impos� � la source
  */
  function IsEmployeePaySourceTaxed(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_HISTORY_DETAIL HIS
         , HRM_CONTROL_ELEMENTS COE
         , HRM_CONTROL_LIST COL
         , HRM_EMPLOYEE_TAXSOURCE EMT
     where HIS.HRM_ELEMENTS_ID = COE.HRM_CONTROL_ELEMENTS_ID
       and COE.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
       and HIS.HRM_EMPLOYEE_ID = EMT.HRM_PERSON_ID
       and hrm_date.activeperiodenddate between EMT.EMT_FROM and HRM_DATE.ENDEMPTAXDATE(emt_from, emt_to, emt.hrm_person_id)
       and COL.C_CONTROL_LIST_TYPE = '111'
       and HIS.HRM_EMPLOYEE_ID = iEmployeeID
       and HIS.HIS_PAY_NUM = iPayNum;

    return lnResult;
  end IsEmployeePaySourceTaxed;

  /**
  * function TaxSourceLedgerExists
  * description :
  *    Indique s'il y a une journalisation d'un imp�t � la source en fonction d'un d�compte
  */
  function TaxSourceLedgerExists(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_TAXSOURCE_LEDGER
     where HRM_PERSON_ID = iEmployeeID
       and ELM_TAX_HIT_PAY_NUM = iPayNum;

    return lnResult;
  end TaxSourceLedgerExists;

  /**
  * function TaxSourceLedgerRecipientExists
  * description :
  *    Indique s'il y a une journalisation d'un imp�t � la source en fonction du destinataire de la quittance
  */
  function TaxSourceLedgerRecipientExists(
    iEmployeeID     in HRM_PERSON.HRM_PERSON_ID%type
  , iElmRecipientID in HRM_TAXSOURCE_LEDGER.HRM_ELM_RECIPIENT_ID%type
  , iEndPeriodDate  in date
  )
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_TAXSOURCE_LEDGER
     where HRM_PERSON_ID = iEmployeeID
       and HRM_ELM_RECIPIENT_ID = iElmRecipientID
       and to_char(ELM_TAX_PER_END, 'YYYY-MM') = to_char(iEndPeriodDate, 'YYYY-MM')
       and C_ELM_TAX_TYPE = '03';

    return lnResult;
  end TaxSourceLedgerRecipientExists;

  /**
  * function CanDeleteTaxSourceLedger
  * description :
  *    Indique si on peu effacer une ligne de journalisation de l'imp�t � la source
  */
  function CanDeleteTaxSourceLedger(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
    return integer
  is
    lnRecipientConfID HRM_TAXSOURCE_LEDGER.HRM_ELM_RECIPIENT_CONF_ID%type;
    lnResult          integer;
  begin
    lnResult  := 1;

    -- V�rifier si la d�claration a �t� faite
    select max(HRM_ELM_RECIPIENT_CONF_ID)
      into lnRecipientConfID
      from HRM_TAXSOURCE_LEDGER
     where HRM_PERSON_ID = iEmployeeID
       and ELM_TAX_HIT_PAY_NUM = iPayNum;

    -- La d�claration a �t� faite, donc la suppression est interdite
    if lnRecipientConfID is not null then
      lnResult  := 0;
    end if;

    return lnResult;
  end CanDeleteTaxSourceLedger;

  /**
  * function IsEmployeeConfessionMissing
  * description :
  *    Indique si la confession d'un ou plusieurs employ�s est manquante
  *      dans journalisation de l'imp�t � la source pour une p�riode donn�e
  */
  function IsEmployeeConfessionMissing(iEndPeriodDate in date)
    return integer
  is
    lnMissing integer;
  begin
    -- On v�rifie si la confession n'a pas �t� saisie pour une p�riode donn�e/canton
    --  et quelle n'a pas d�j� �t� saisie pour une p�riode pr�c�dente pour le m�me canton
    select sign(nvl(min(TSL.HRM_PERSON_ID), 0) )
      into lnMissing
      from HRM_TAXSOURCE_LEDGER TSL
     where TSL.ELM_TAX_PER_END = iEndPeriodDate
       and (   TSL.ELM_TAX_CODE like '%Y'
            or TSL.C_HRM_IS_CAT is not null)
       and TSL.C_HRM_TAX_CONFESSION is null
       and not exists(select 1
                        from HRM_TAXSOURCE_LEDGER TSL2
                       where TSL2.HRM_PERSON_ID = TSL.HRM_PERSON_ID
                         and TSL2.ELM_TAX_PER_END <= iEndPeriodDate
                         and TSL2.C_HRM_TAX_CONFESSION is not null);

    return lnMissing;
  end IsEmployeeConfessionMissing;

  /**
  * function CantonBelongsToOFSCity
  * description :
  *    D�termine si un canton appartient � une commune OFS donn�e.
  */
  function CantonBelongsToOFSCity(iCanton in HRM_TAXSOURCE_LEDGER.C_HRM_CANTON%type, iPcOFSCityID in HRM_TAXSOURCE_LEDGER.PC_OFS_CITY_ID%type)
    return integer
  is
    ln_result integer;
  begin
    select sign(count(*) )
      into ln_result
      from PCS.PC_OFS_CITY OFS
     where OFS.PC_OFS_CITY_ID = iPcOFSCityID
       and OFS.OFS_CANTON = iCanton;

    return ln_result;
  end CantonBelongsToOFSCity;

  /**
  * function HasEntriesStartingFrom
  * description :
  *    Indique s'il y a une journalisation d'un imp�t � la source pour un utilisateur � partir d'une p�riode donn�e
  */
  function HasEntriesStartingFrom(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iBeginPeriod in date)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_TAXSOURCE_LEDGER
     where HRM_PERSON_ID = iEmployeeID
       and ELM_TAX_PER_END >= iBeginPeriod;

    return lnResult;
  end HasEntriesStartingFrom;

  /**
  * function HasUndeclaredEntries
  * description :
  *    Indique s'il y a une journalisation d'un imp�t � la source pour un utilisateur qui n'a pas �t�
  *    d�clar� dans la p�riode active
  */
  function HasUndeclaredEntries(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_TAXSOURCE_LEDGER
     where HRM_PERSON_ID = iEmployeeID
       and C_ELM_TAX_TYPE <> '01'
       and HRM_ELM_RECIPIENT_CONF_ID is null;

    return lnResult;
  end HasUndeclaredEntries;
end HRM_LIB_TAXSOURCE_LEDGER;
