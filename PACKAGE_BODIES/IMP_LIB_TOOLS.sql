--------------------------------------------------------
--  DDL for Package Body IMP_LIB_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_LIB_TOOLS" 
as
  /**
  * Description
  *    Retourne les initiales génériques lors de l'importation via Excel
  */
  function GetImportUserIni
    return varchar2
  as
  begin
    return 'IMP';
  end GetImportUserIni;

  /**
  * Description
  *    Retourne la description d'un champ
  */
  function GetFieldDescr(iFieldName in varchar2)
    return varchar2
  is
    lvDescr varchar2(4000);
  begin
    -- Rechercher le label du champ
    select max(FDI.FDILABEL) || ' (' || upper(iFieldName) || ')'
      into lvDescr
      from PCS.PC_FLDSC FLD
         , PCS.PC_FDICO FDI
     where FLD.FLDNAME = upper(iFieldName)
       and FLD.PC_FLDSC_ID = FDI.PC_FLDSC_ID
       and FDI.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID;

    return lvDescr;
  end GetFieldDescr;

  function factoryFloorExists(iFacReference in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from FAL_FACTORY_FLOOR
                   where upper(FAC_REFERENCE) = upper(iFacReference) );

    return lExists = 1;
  end factoryFloorExists;

  function blockExists(iFacReference in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(
                select 'x'
                  from FAL_FACTORY_FLOOR
                 where upper(FAC_REFERENCE) = upper(iFacReference)
                   and nvl(FAC_IS_BLOCK, 0) = 1
                union
                select 'x'
                  from IMP_FAL_FACTORY_FLOOR
                 where upper(FAC_REFERENCE) = upper(iFacReference)
                   and FAC_IS_BLOCK = 1);

    return lExists = 1;
  end blockExists;

  function operatorExists(iFacReference in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(
             select 'x'
               from FAL_FACTORY_FLOOR
              where upper(FAC_REFERENCE) = upper(iFacReference)
                and nvl(FAC_IS_OPERATOR, 0) = 1
             union
             select 'x'
               from IMP_FAL_FACTORY_FLOOR
              where upper(FAC_REFERENCE) = upper(iFacReference)
                and FAC_IS_OPERATOR = 1);

    return lExists = 1;
  end operatorExists;

  /**
  * function productExists
  * Description
  *    Contrôle l'existence du produit dont la référence est transmise.
  *    Ne tient pas compte de la casse.
  * @created age 19.11.2014
  * @lastUpdate
  * @public
  * @param iGooMajorReference : Référence du produit à rechercher.
  * @return true si le produit existe.
  */
  function productExists(iGooMajorReference in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from GCO_GOOD goo
                       , GCO_PRODUCT pdt
                   where pdt.GCO_GOOD_ID = goo.GCO_GOOD_ID
                     and upper(goo.GOO_MAJOR_REFERENCE) = upper(iGooMajorReference) );

    return lExists = 1;
  end productExists;

  /**
  * Description
  *    Contrôle l'existence du service dont la référence est transmise.
  *    Ne tient pas compte de la casse.
  */
  function serviceExists(iGooMajorReference in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from GCO_GOOD goo
                       , GCO_SERVICE srv
                   where srv.GCO_GOOD_ID = goo.GCO_GOOD_ID
                     and upper(goo.GOO_MAJOR_REFERENCE) = upper(iGooMajorReference) );

    return lExists = 1;
  end serviceExists;

  function supplierKey2Exists(iPerKey2 in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from PAC_PERSON per
                       , PAC_SUPPLIER_PARTNER cre
                   where cre.PAC_SUPPLIER_PARTNER_ID = per.PAC_PERSON_ID
                     and upper(per.PER_KEY2) = upper(iPerKey2) );

    return lExists = 1;
  end supplierKey2Exists;

  function schedulePlanExists(iSchRef in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from FAL_SCHEDULE_PLAN
                   where upper(SCH_REF) = upper(iSchRef) );

    return lExists = 1;
  end schedulePlanExists;

  function taskExists(iTasRef in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from FAL_TASK
                   where upper(TAS_REF) = upper(iTasRef) );

    return lExists = 1;
  end taskExists;

  function hrmEmployeeExists(iEmpNumber in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from HRM_PERSON
                   where PER_IS_EMPLOYEE = 1
                     and upper(EMP_NUMBER) = upper(iEmpNumber) );

    return lExists = 1;
  end hrmEmployeeExists;

  function cdaAccountExists(iAccNumber in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(
             select 'x'
               from ACS_ACCOUNT acc
                  , ACS_CDA_ACCOUNT cda
                  , ACS_SUB_SET sse
              where acc.ACS_ACCOUNT_ID = cda.ACS_CDA_ACCOUNT_ID
                and acc.ACS_SUB_SET_ID = sse.ACS_SUB_SET_ID
                and sse.C_SUB_SET = 'CDA'
                and acc.C_VALID = 'VAL'
                and upper(acc.ACC_NUMBER) = upper(iAccNumber) );

    return lExists = 1;
  end cdaAccountExists;

  function costCenterExists(iGccCode in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from GAL_COST_CENTER
                   where upper(GCC_CODE) = upper(iGccCode) );

    return lExists = 1;
  end costCenterExists;

  function scheduleExists(iSceDescr in varchar2)
    return boolean
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from PAC_SCHEDULE
                   where upper(SCE_DESCR) = upper(iSceDescr) );

    return lExists = 1;
  end scheduleExists;

  /**
  * function getLocationId
  * Description
  *    Retourne l'identifiant de l'emplacement de stock en fonction de la description de l'emplacement
  *    et de son stock.
  * @created age 07.08.2014
  * @lastUpdate
  * @public
  * @param iStockDescr    : Description du stock (non sensible à la casse)
  * @param iLocationDescr : Description de l'emplacement de stock (non sensible à la casse)
  * @return ID de l'emplacement de stock
  */
  function getLocationId(iStockDescr in STM_STOCK.STO_DESCRIPTION%type, iLocationDescr in STM_LOCATION.LOC_DESCRIPTION%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  as
    lLocationId STM_LOCATION.STM_LOCATION_ID%type;
  begin
    select loc.STM_LOCATION_ID
      into lLocationId
      from STM_LOCATION loc
         , STM_STOCK sto
     where loc.STM_STOCK_ID = sto.STM_STOCK_ID
       and upper(sto.STO_DESCRIPTION) = upper(iStockDescr)
       and upper(loc.LOC_DESCRIPTION) = upper(iLocationDescr);

    return lLocationId;
  exception
    when no_data_found then
      return null;
  end getLocationId;
end IMP_LIB_TOOLS;
