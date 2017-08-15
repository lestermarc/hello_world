--------------------------------------------------------
--  DDL for Package Body COM_CONFIG_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_CONFIG_CONTROL" 
is
  /**
  * Description
  *   Contrôle les configurations présentes dans la table PCS.COM_LIST_ID_TEMP
  */
  procedure ControlComIdConfigs(aCompanyOwner in varchar2 default 'PCS')
  is
  begin
    -- Recherche des valeurs des configurations
    update PCS.COM_LIST_ID_TEMP
       set LID_FREE_MEMO_1 = PCS.PC_CONFIG.GetConfig(LID_FREE_CHAR_1
                                                   , LID_FREE_NUMBER_4
                                                   , LID_FREE_NUMBER_5)
     where LID_DESCRIPTION = 'PC_CBASE_ID'
       and nvl(LID_FREE_CHAR_2, 'PCS') = aCompanyOwner;

    -- Contrôle des configurations dont le contrôle est demandé (LID_FREE_NUMBER_3 = OSC_CONTROL)
    update PCS.COM_LIST_ID_TEMP
       set LID_CODE = ControlConfig(LID_FREE_CHAR_1
                                  , LID_FREE_MEMO_1
                                  , 0
                                  , LID_FREE_CHAR_2)
     where LID_DESCRIPTION = 'PC_CBASE_ID'
       and LID_FREE_NUMBER_3 = 1
       and nvl(LID_FREE_CHAR_2, 'PCS') = aCompanyOwner;
  end ControlComIdConfigs;

  /**
  * function ControlConfig
  * Description
  *   Contrôle la valeur de la configuration passée en paramètre, et son type
  *   si demandé.
  *   Valeurs de retour :
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   testées par Delphi et mises à 0 si incorrectes.
    */
  function ControlConfig(
    aConfigName   in PCS.PC_CBASE.CBACNAME%type
  , aValue        in PCS.PC_CBASE.CBACVALUE%type
  , aControlType  in number default 0
  , aCompanyOwner in PCS.PC_SCRIP.SCRDBOWNER%type default null
  )
    return number
  is
    vSqlControl   PCS.PC_CBASE.CBACSQLCTRL%type;
    vConfigType   PCS.PC_CBASE.CBACTYPE%type;
    vNotNull      PCS.PC_CBASE.CBACTYPE%type;
    vCompanyOwner PCS.PC_SCRIP.SCRDBOWNER%type;
    vMacroPos     integer;
    vResult       number;
  begin
    -- Recherche du nom du schéma de la société
    vCompanyOwner  := nvl(trim(aCompanyOwner), PCS.PC_I_LIB_SESSION.GetCompanyOwner);

    -- Recherche des infos de la config (en remplaçant les macros)
    -- Les macros sont scindées pour ne pas être remplacées au passage des scripts
    select replace(replace(replace(CBACSQLCTRL, '[PCS' || '_OWNER]', 'PCS'), '[COMPANY' || '_OWNER]', vCompanyOwner)
                 , '[C' || 'O]'
                 , vCompanyOwner
                  )
         , CBACTYPE
         , CBACNOTNULL
      into vSqlControl
         , vConfigType
         , vNotNull
      from PCS.PC_CBASE
     where CBACNAME_UPPER = upper(aConfigName)
       and CBACREPORT is null;

    -- Suppression de l'éventuelle macro [FORMAT_SQL] en fin de commande
    vMacroPos      := instr(vSqlControl, '[FORMAT_SQL]');

    if vMacroPos > 0 then
      vSqlControl  := substr(vSqlControl, 1, vMacroPos - 1);
    end if;

    -- Contrôle du type de la valeur de la configuration si demandé
    if aControlType = 1 then
      vResult  := ControlConfigType(aValue => aValue, aConfigType => vConfigType, aNotNull => vNotNull);
    else
      vResult  := 1;
    end if;

    -- Si le type de la valeur est correct, contrôle de la valeur elle-même
    -- Les macros sont scindées pour ne pas être remplacées au passage des scripts
    if vResult > 0 then
      vResult  :=
        ControlConfigValue(aValue        => replace(replace(replace(aValue, '[PCS' || '_OWNER]', 'PCS')
                                                          , '[COMPANY' || '_OWNER]'
                                                          , vCompanyOwner
                                                           )
                                                  , '[C' || 'O]'
                                                  , vCompanyOwner
                                                   )
                         , aConfigType   => vConfigType
                         , aNotNull      => vNotNull
                         , aSqlControl   => vSqlControl
                          );
    end if;

    return vResult;
  end ControlConfig;

  /**
  * function ControlConfigType
  * Description
  *   Contrôle le type de la valeur passée en paramètre.
  *   Valeurs de retour :
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   testées par Delphi et mises à 0 si incorrectes.
  */
  function ControlConfigType(
    aValue      in PCS.PC_CBASE.CBACVALUE%type
  , aConfigType in PCS.PC_CBASE.CBACTYPE%type
  , aNotNull    in PCS.PC_CBASE.CBACNOTNULL%type
  )
    return number
  is
    vResult number := 0;
    vValue  number;
  begin
    --aValue  := trim(aValue);
    if aValue is null then
      -- Renvoie correct si valeur nulle autorisée, incorrect sinon
      return 1 - aNotNull;
    elsif(aConfigType = 'DIRECTORY') then
      -- Contrôle reporté si la config est de type DIRECTORY (à effectuer en Delphi)
      -- On suppose que la valeur est correcte. Sera mise à jour par Delphi si incorrecte.
      return 1;
    elsif    (aConfigType = 'STRING')
          or (aConfigType = 'OTHER') then
      -- Pas de contrôle spécifique
      return 1;
    elsif aConfigType = 'BOOLEAN' then
      if    (aValue = 'True')
         or (aValue = 'False') then
        return 1;
      end if;
    elsif    (aConfigType = 'INTEGER')
          or (aConfigType = 'FLOAT')
          or (aConfigType = 'RECORD_ID') then
      -- Contrôle type numérique
      begin
        vValue  := to_number(aValue);
      exception
        when invalid_number then
          return 0;
        when others then
          raise;
      end;

      if    (aConfigType = 'INTEGER')
         or (aConfigType = 'RECORD_ID') then
        -- Contrôle type entier (pas de séparateur décimal)
        if instr(aValue, trim(to_char(0.0, 'D') ) ) > 0 then
          return 0;
        else
          return 1;
        end if;
      elsif(aConfigType = 'FLOAT') then
        -- Pas de second contrôle spécifique
        return 1;
      end if;

      return 0;
    end if;

    return 0;
  end ControlConfigType;

  /**
  * function ControlConfigValue
  * Description
  *   Contrôle la valeur de la configuration passée en paramètre selon la
  *   commande SQL de contrôle spécifiée.
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   testées par Delphi et mises à 0 si incorrectes.
  */
  function ControlConfigValue(
    aValue      in PCS.PC_CBASE.CBACVALUE%type
  , aConfigType in PCS.PC_CBASE.CBACTYPE%type
  , aNotNull    in PCS.PC_CBASE.CBACNOTNULL%type
  , aSqlControl in PCS.PC_CBASE.CBACSQLCTRL%type
  )
    return number
  is
    vSqlControl PCS.PC_CBASE.CBACSQLCTRL%type;
    vResult     number                          := 0;
  begin
    -- Contrôle des valeurs nulles
    if aValue is null then
      -- Renvoie correcte si valeur nulle autorisée, incorrecte sinon
      return 1 - aNotNull;
    end if;

    -- Contrôle reporté si la config est de type DIRECTORY (à effectuer en Delphi)
    -- On suppose que la valeur est correcte. Sera mise à jour par Delphi si incorrecte.
    if aConfigType = 'DIRECTORY' then
      return 1;
    end if;

    -- Pas de contrôle si commande vide
    if aSqlControl is null then
      return 1;
    end if;

    -- Contrôle de la valeur selon la commande de contrôle
    begin
      vSqlControl  := replace(aSqlControl, ':Config', ':CONFIG');
      vSqlControl  := replace(vSqlControl, ':config', ':CONFIG');

      -- Remplacement du paramèrtre :CONFIG par sa valeur (on remplace ' par '' dans les strings)
      if aConfigType in('STRING', 'BOOLEAN') then
        vSqlControl  := replace(vSqlControl, ':CONFIG', '''' || replace(aValue, '''', '''''') || '''');
      else
        vSqlControl  := replace(vSqlControl, ':CONFIG', aValue);
      end if;

      -- Contrôle de la valeur
      execute immediate vSqlControl
                   into vResult;
    exception
      when no_data_found then
        return 0;
    end;

    if vResult > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end ControlConfigValue;
end COM_CONFIG_CONTROL;
