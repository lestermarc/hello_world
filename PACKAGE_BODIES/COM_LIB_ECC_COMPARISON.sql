--------------------------------------------------------
--  DDL for Package Body COM_LIB_ECC_COMPARISON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_ECC_COMPARISON" 
is
  /**
  * function GetLevelTable
  * Description
  *   Renvoi la description de la table de niveau N° pour l'élément des diff. de données
  */
  function GetLevelTable(iEccDiffDataID in V_COM_ECC_DIFF_DATA.COM_ECC_DIFF_DATA_ID%type, iLevel in integer)
    return varchar2
  is
    lComLevel    V_COM_ECC_DIFF_DATA.COM_LEVEL%type;
    lCedTable    V_COM_ECC_DIFF_DATA.CED_TABLE%type;
    lParentID    V_COM_ECC_DIFF_DATA.COM_ECC_DIFF_DATA_PARENT_ID%type;
    lvTableDescr PCS.PC_TABLE_DESCR.TDE_DESCR%type;
    lvValueKey   V_COM_ECC_DIFF_DATA.CED_VALUE%type;
    lvHeaderKey  V_COM_ECC_DIFF_DATA.CED_VALUE%type;
  begin
    -- Infos de l'élément des diff. de données
    select CED.COM_LEVEL
         , CED.CED_TABLE
         , CED.COM_ECC_DIFF_DATA_PARENT_ID
         , (select CED_KEY.CED_VALUE
              from V_COM_ECC_DIFF_DATA CED_KEY
             where CED_KEY.COM_ECC_DIFF_DATA_PARENT_ID = CED.COM_ECC_DIFF_DATA_PARENT_ID
               and CED_KEY.CED_FIELD = 'VALUE_KEY')
         , (select CED_KEY.CED_VALUE
              from V_COM_ECC_DIFF_DATA CED_KEY
             where CED_KEY.CED_FIELD = 'HEADER_KEY')
      into lComLevel
         , lCedTable
         , lParentID
         , lvValueKey
         , lvHeaderKey
      from V_COM_ECC_DIFF_DATA CED
     where CED.COM_ECC_DIFF_DATA_ID = iEccDiffDataID;

    -- Si le niveau du tuple correspont au niveau demandé
    if iLevel = lComLevel then
      -- Renvoyer la description de la table du tuple courant
      lvTableDescr  := PCS.PC_LIB_TABLE.GetTableDescr(lCedTable, PCS.PC_I_LIB_SESSION.GetUserLangId);

      -- Ajout la clé d'identification de l'enregistrement
      if     lvHeaderKey is not null
         and (lComLevel = 1) then
        lvTableDescr  := lvTableDescr || ' - ' || lvHeaderKey;
      elsif lvValueKey is not null then
        -- Ajout la clé d'identification de l'enregistrement
        lvTableDescr  := lvTableDescr || ' - ' || lvValueKey;
      end if;
    -- Si le niveau du tuple est supérieur au niveau demandé et que le tuple courant possède un parent
    elsif     (iLevel < lComLevel)
          and (lParentID is not null) then
      -- Effectuer un appel récursif pour récupérer la description de la table pour le niveau demandé
      lvTableDescr  := GetLevelTable(lParentID, iLevel);
    -- Si le niveau demandé est supérieur au tuple courant
    elsif iLevel > lComLevel then
      -- Pas de description de table pour le niveau demandé
      lvTableDescr  := null;
    else
      -- Pas de description de table pour le niveau demandé
      lvTableDescr  := null;
    end if;

    return lvTableDescr;
  exception
    when no_data_found then
      return null;
  end GetLevelTable;

  /**
  * function isReservedField
  * Description
  *   Indique si le champ spécifié est un champ réservé
  */
  function isReservedField(iFieldName in varchar2)
    return number
  is
  begin
    if iFieldName in('TABLE_TYPE', 'TABLE_KEY', 'VALUE_KEY', 'HEADER_KEY', 'DOC_TRANSACTION_MODE') then
      return 1;
    else
      return 0;
    end if;
  end isReservedField;
end COM_LIB_ECC_COMPARISON;
