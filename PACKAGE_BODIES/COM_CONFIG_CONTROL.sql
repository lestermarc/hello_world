--------------------------------------------------------
--  DDL for Package Body COM_CONFIG_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_CONFIG_CONTROL" 
is
  /**
  * Description
  *   Contr�le les configurations pr�sentes dans la table PCS.COM_LIST_ID_TEMP
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

    -- Contr�le des configurations dont le contr�le est demand� (LID_FREE_NUMBER_3 = OSC_CONTROL)
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
  *   Contr�le la valeur de la configuration pass�e en param�tre, et son type
  *   si demand�.
  *   Valeurs de retour :
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   test�es par Delphi et mises � 0 si incorrectes.
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
    -- Recherche du nom du sch�ma de la soci�t�
    vCompanyOwner  := nvl(trim(aCompanyOwner), PCS.PC_I_LIB_SESSION.GetCompanyOwner);

    -- Recherche des infos de la config (en rempla�ant les macros)
    -- Les macros sont scind�es pour ne pas �tre remplac�es au passage des scripts
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

    -- Suppression de l'�ventuelle macro [FORMAT_SQL] en fin de commande
    vMacroPos      := instr(vSqlControl, '[FORMAT_SQL]');

    if vMacroPos > 0 then
      vSqlControl  := substr(vSqlControl, 1, vMacroPos - 1);
    end if;

    -- Contr�le du type de la valeur de la configuration si demand�
    if aControlType = 1 then
      vResult  := ControlConfigType(aValue => aValue, aConfigType => vConfigType, aNotNull => vNotNull);
    else
      vResult  := 1;
    end if;

    -- Si le type de la valeur est correct, contr�le de la valeur elle-m�me
    -- Les macros sont scind�es pour ne pas �tre remplac�es au passage des scripts
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
  *   Contr�le le type de la valeur pass�e en param�tre.
  *   Valeurs de retour :
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   test�es par Delphi et mises � 0 si incorrectes.
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
      -- Renvoie correct si valeur nulle autoris�e, incorrect sinon
      return 1 - aNotNull;
    elsif(aConfigType = 'DIRECTORY') then
      -- Contr�le report� si la config est de type DIRECTORY (� effectuer en Delphi)
      -- On suppose que la valeur est correcte. Sera mise � jour par Delphi si incorrecte.
      return 1;
    elsif    (aConfigType = 'STRING')
          or (aConfigType = 'OTHER') then
      -- Pas de contr�le sp�cifique
      return 1;
    elsif aConfigType = 'BOOLEAN' then
      if    (aValue = 'True')
         or (aValue = 'False') then
        return 1;
      end if;
    elsif    (aConfigType = 'INTEGER')
          or (aConfigType = 'FLOAT')
          or (aConfigType = 'RECORD_ID') then
      -- Contr�le type num�rique
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
        -- Contr�le type entier (pas de s�parateur d�cimal)
        if instr(aValue, trim(to_char(0.0, 'D') ) ) > 0 then
          return 0;
        else
          return 1;
        end if;
      elsif(aConfigType = 'FLOAT') then
        -- Pas de second contr�le sp�cifique
        return 1;
      end if;

      return 0;
    end if;

    return 0;
  end ControlConfigType;

  /**
  * function ControlConfigValue
  * Description
  *   Contr�le la valeur de la configuration pass�e en param�tre selon la
  *   commande SQL de contr�le sp�cifi�e.
  *      0 : Type incorrect
  *      1 : Type correct
  *   Exception : les configurations de type 'DIRECTORY' retournent 1. Elles seront
  *   test�es par Delphi et mises � 0 si incorrectes.
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
    -- Contr�le des valeurs nulles
    if aValue is null then
      -- Renvoie correcte si valeur nulle autoris�e, incorrecte sinon
      return 1 - aNotNull;
    end if;

    -- Contr�le report� si la config est de type DIRECTORY (� effectuer en Delphi)
    -- On suppose que la valeur est correcte. Sera mise � jour par Delphi si incorrecte.
    if aConfigType = 'DIRECTORY' then
      return 1;
    end if;

    -- Pas de contr�le si commande vide
    if aSqlControl is null then
      return 1;
    end if;

    -- Contr�le de la valeur selon la commande de contr�le
    begin
      vSqlControl  := replace(aSqlControl, ':Config', ':CONFIG');
      vSqlControl  := replace(vSqlControl, ':config', ':CONFIG');

      -- Remplacement du param�rtre :CONFIG par sa valeur (on remplace ' par '' dans les strings)
      if aConfigType in('STRING', 'BOOLEAN') then
        vSqlControl  := replace(vSqlControl, ':CONFIG', '''' || replace(aValue, '''', '''''') || '''');
      else
        vSqlControl  := replace(vSqlControl, ':CONFIG', aValue);
      end if;

      -- Contr�le de la valeur
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
