--------------------------------------------------------
--  DDL for Package Body COM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_FUNCTIONS" 
is
  /**
   * Collection pour noms de table.
   */
  type ttblTableName is table of varchar2(30)
    index by binary_integer;

  /*
  *  Proposition d'une fonction à completer qui retourne la(les) descriptions
  *  des Tables virtuelles COM_CPY........
  */
  function GetVCodeDesc(
    aTableName    in varchar2
  , aFieldName    in varchar2
  , aIdFieldValue in varchar2
  , aLang         in varchar2
  , aValue        in varchar2
  , aNumDesc      in varchar2 default '1'
  )
    return varchar2 deterministic
  is
    result COM_CPY_CODES_VALUE_DESCR.CPD_TEXT1%type;
  begin
    select case aNumDesc
             when '1' then CPD_TEXT1
             when '2' then CPD_TEXT2
             when '3' then CPD_TEXT3
           end
      into result
      from PCS.PC_FLDSC FLD
         , COM_CPY_CODES CCC
         , COM_CPY_CODES_VALUE CCCV
         , COM_CPY_CODES_VALUE_DESCR CCCVD
         , PCS.PC_LANG LNG
     where FLD.FLDNAME = aFieldName
       and FLD.FLDCCODE = CCC.CPC_NAME
       and CCCV.COM_CPY_CODES_ID = CCC.COM_CPY_CODES_ID
       and CCCV.COM_CPY_CODES_VALUE_ID = cccvd.COM_CPY_CODES_VALUE_ID
       and cccvd.PC_LANG_ID = LNG.PC_LANG_ID
       and LNG.LANID = aLang
       and CCCV.CPV_NAME = aValue;

    return result;
  end GetVCodeDesc;

  /**
  * Description
  *   Recherche de la description d'une valeur d'un descode
  *   en tenant compte des descodes "SOCIETE"
  */
  function GetDescodeDescr(
    aName  in pcs.pc_gcodes.gcgname%type
  , aValue in pcs.pc_gcodes.gclcode%type
  , LangId in pcs.pc_gcodes.pc_lang_id%type default pcs.PC_I_LIB_SESSION.GetUserLangId
  )
    return pcs.pc_gcodes.gcdtext1%type deterministic
  is
  begin
    return GetNumDescodeDescr(aName, aValue, '1', LangId);
  end GetDescodeDescr;

  /**
   * Propre version de la fonction DBMS_SESSION.IS_SESSION_ALIVE pour contourner
   * un bug Oracle concernant les versions RAC.
   * A remplacer par l'appel de la fonction is_session_alive du framework plsql
   */
  function is_session_alive(aSessionId in varchar2)
    return integer
  is
    ln_sid     number;
    ln_serial# number;
    ln_inst_id number;
    ln_result  integer;
  begin
    if (aSessionId is not null) then
      ln_sid      := to_number(substr(aSessionId, 1, 4), 'XXXX');
      ln_serial#  := to_number(substr(aSessionId, 5, 4), 'XXXX');
      ln_inst_id  := to_number(substr(aSessionId, 9, 4), 'XXXX');

      select count(*)
        into ln_result
        from dual
       where exists(select 1
                      from GV$SESSION
                     where sid = ln_sid
                       and SERIAL# = ln_serial#
                       and INST_ID = ln_inst_id);

      return ln_result;
    end if;

    return 0;
  end;

  /**
  * Description
  *   Build a session ID identifier from GV$SESSION (used to be compared at a DBMS_SESSION.UNIQUE_SESSION_ID result)
  */
  function BuidSessionId(iSID in number, iSerial in number, iInstance in number)
    return varchar2
  is
  begin
    --return lpad(trim(to_char(iSID, 'XXXX')),'0',4)||to_char(iSerial, 'XXXX')||to_char(iInstance, 'XXXX');
    return lpad(to_char(iSID, 'fmXXXX'), 4, '0') || lpad(to_char(iSerial, 'fmXXXX'), 4, '0') || lpad(to_char(iInstance, 'fmXXXX'), 4, '0');
  end BuidSessionId;

  /**
  * procedure GetSessionInfo
  * Description
  *    Retourne des informations relatives à la session oracle.
  * @created NGV MAY.2010
  * @lastUpdate
  * @public
  * @param
  */
  procedure GetSessionInfo(
    aSessionID  in     varchar2
  , aUserName   out    varchar2
  , aSchemaName out    varchar2
  , aOsUser     out    varchar2
  , aMachine    out    varchar2
  , aProgram    out    varchar2
  , aModule     out    varchar2
  )
  is
    ln_sid     number;
    ln_serial# number;
    ln_inst_id number;
    ln_result  integer;
  begin
    if (aSessionId is not null) then
      ln_sid      := to_number(substr(aSessionId, 1, 4), 'XXXX');
      ln_serial#  := to_number(substr(aSessionId, 5, 4), 'XXXX');
      ln_inst_id  := to_number(substr(aSessionId, 9, 4), 'XXXX');

      begin
        select username
             , schemaname
             , osuser
             , machine
             , program
             , module
          into aUserName
             , aSchemaName
             , aOsUser
             , aMachine
             , aProgram
             , aModule
          from GV$SESSION
         where sid = ln_sid
           and SERIAL# = ln_serial#
           and INST_ID = ln_inst_id;

        begin
          select USE_NAME
            into aUserName
            from PCS.PC_USER U
               , PCS.PC_AUDIT_TRAIL AUT
           where AUT.PC_USER_ID = U.PC_USER_ID
             and AUT.DIC_PC_AUDIT_EVENT_ID = 'LOGIN'
             and AUT.AUT_ORACLE_SESSION_ID = aSessionId;
        exception
          when no_data_found then
            null;
          when too_many_rows then
            select max(USE_NAME)
              into aUserName
              from PCS.PC_USER U
                 , PCS.PC_AUDIT_TRAIL AUT
             where AUT.PC_USER_ID = U.PC_USER_ID
               and AUT.DIC_PC_AUDIT_EVENT_ID = 'LOGIN'
               and AUT.AUT_ORACLE_SESSION_ID = aSessionId;
        end;
      exception
        when no_data_found then
          aUserName    := null;
          aSchemaName  := null;
          aOsUser      := null;
          aMachine     := null;
          aProgram     := null;
          aModule      := null;
      end;
    end if;
  end GetSessionInfo;

  /**
  * procedure updateID2Null
  * Description
  *    mise à null des clef étragères Nullable
  * @created FP 12.06.2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure updateID2Null(aTblTableName in ttblTableName)
  is
    cursor crNullableColumns(aTableName varchar2)
    is
      select column_name
        from user_tab_columns a
       where table_name = aTableName
         and substr(column_name, -3, 3) = '_ID'
         and NULLABLE = 'Y';
  begin
    for i in aTblTableName.first .. aTblTableName.last loop
      for tplNullableColumns in crNullableColumns(aTblTableName(i) ) loop
        --DBMS_OUTPUT.put_line('UPDATE '|| aTblTableName(i) ||' SET '|| tplNullableColumns.column_name ||'=NULL');
        execute immediate 'UPDATE ' || aTblTableName(i) || ' SET ' || tplNullableColumns.column_name || '=NULL';
      end loop;
    end loop;
  end;

  /**
  * procedure deleteSchemaTables
  * Description
  *    Effacement du contenu des tables du schéma
  * @created FP 12.06.2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure deleteSchemaTables(aTblTableName in ttblTableName)
  is
    j             binary_integer := 0;
    vTblTableName ttblTableName;
  begin
    for i in aTblTableName.first .. aTblTableName.last loop
      begin
        execute immediate 'DELETE FROM ' || aTblTableName(i);

        commit;
      exception
        when others then
          DBMS_OUTPUT.put_line('**************** FAILURE ON ' || aTblTableName(i) );
          vTblTableName(j)  := aTblTableName(i);
          j                 := j + 1;
      end;
    end loop;

    if (vTblTableName.count = aTblTableName.count) then
      updateID2Null(vTblTableName);
      deleteSchemaTables(vTblTableName);
    elsif(vTblTableName.count > 0) then
      deleteSchemaTables(vTblTableName);
    end if;
  end deleteSchemaTables;

  /**
  * procedure deleteSchemaTables
  * Description
  *    Effacement des données contenues dans les tables d'uns chéma
  * @created FP 12.06.2006
  * @lastUpdate
  * @public
  */
  procedure deleteSchemaTables
  is
    vTblTableName ttblTableName;
    i             binary_integer := 0;

    cursor crTablesToDelete
    is
      select table_name
        from user_tables
       where table_name not like 'MV%';
  begin
    for tplTablesToDelete in crTablesToDelete loop
      begin
        execute immediate 'DELETE FROM ' || tplTablesToDelete.table_name;

        commit;
      exception
        when others then
          DBMS_OUTPUT.put_line('**************** FAILURE ON ' || tplTablesToDelete.table_name);
          vTblTableName(i)  := tplTablesToDelete.table_name;
          i                 := i + 1;
      end;
    end loop;

    if (vTblTableName.count > 0) then
      deleteSchemaTables(vTblTableName);
    end if;

    commit;
  end deleteSchemaTables;

  /**
  * Description
  *   Duplication des pièces jointes
  */
  procedure DuplicateImageFiles(
    aOrigin   in COM_IMAGE_FILES.IMF_TABLE%type
  , aImfSrcId in COM_IMAGE_FILES.IMF_REC_ID%type
  , aImfTgtId in COM_IMAGE_FILES.IMF_REC_ID%type
  )
  is
  begin
    tblImageFiles.delete;

    select *
    bulk collect into tblImageFiles
      from COM_IMAGE_FILES
     where IMF_TABLE = aOrigin
       and IMF_REC_ID = aImfSrcId;

    -- Init des nouvelles valeurs du tuple
    if (tblImageFiles.count > 0) then
      for intIndex in tblImageFiles.first .. tblImageFiles.last loop
        tblImageFiles(intIndex).IMF_REC_ID  := aImfTgtId;
        tblImageFiles(intIndex).A_DATECRE   := sysdate;
        tblImageFiles(intIndex).A_IDCRE     := pcs.PC_I_LIB_SESSION.GetUserIni;
        tblImageFiles(intIndex).A_DATEMOD   := null;
        tblImageFiles(intIndex).A_IDMOD     := null;

        select INIT_ID_SEQ.nextval
          into tblImageFiles(intIndex).COM_IMAGE_FILES_ID
          from dual;
      end loop;

      -- Insertion des tuples dans la base
      forall intIndex in tblImageFiles.first .. tblImageFiles.last
        insert into COM_IMAGE_FILES
             values tblImageFiles(intIndex);
    end if;
  end DuplicateImageFiles;

  /**
  * procedure DicValidation
  * Description
  *   Validation d'un dictionnaire
  */
  procedure DicValidation(aDicName in PCS.PC_DICO_DESCRIPTION.DIT_TABLE%type, aDicId in PCS.PC_DICO_DESCRIPTION.DIT_CODE%type, aAllValues in varchar2)
  is
    vDicError constant varchar2(9)  := 'DIC_ERROR';
    vCount             number;
    vValue             varchar2(30);
  begin
    begin
      delete from COM_LIST_ID_TEMP
            where LID_CODE = aDicName
              and LID_DESCRIPTION = vDicError;
    exception
      when no_data_found then
        null;
    end;

    if (aDicName = 'DIC_ADDRESS_TYPE') then
      vValue  := substr(aAllValues, instr(aAllValues, '=') + 1);

      if (to_number(nvl(vValue, 0) ) > 0) then
        select count(*)
          into vCount
          from DIC_ADDRESS_TYPE
         where DAD_DEFAULT = 1
           and DIC_ADDRESS_TYPE_ID <> aDicId;

        if (vCount > 0) then   --Un autre dico défaut existe, signaler l'erreur
          insert into COM_LIST_ID_TEMP
                      (COM_LIST_ID_TEMP_ID
                     , LID_CODE
                     , LID_DESCRIPTION
                     , LID_FREE_CHAR_1
                     , LID_FREE_CHAR_2
                      )
               values (INIT_ID_SEQ.nextval
                     , aDicName
                     , vDicError
                     , pcs.pc_public.TranslateWord('Un type d''adresse ''défaut'' existe déjà')   -- Message d'erreur
                     , pcs.pc_public.TranslateWord('Erreur de saisie')
                      -- En-tête du message d'erreur
                      );
        end if;
      end if;
    end if;
  end DicValidation;

  /**
  * Description
  *   Recherche de la description d'une valeur d'un descode en fonction du numéro de description
  */
  function GetNumDescodeDescr(
    aName    in pcs.pc_gcodes.gcgname%type
  , aValue   in pcs.pc_gcodes.gclcode%type
  , aNumDesc in varchar2 default '1'
  , LangId   in pcs.pc_gcodes.pc_lang_id%type default pcs.PC_I_LIB_SESSION.GetUserLangId
  )
    return pcs.pc_gcodes.gcdtext1%type
  is
    result pcs.pc_gcodes.gcdtext1%type;
  begin
    select case aNumDesc
             when '1' then gcdtext1
             when '2' then gcdtext2
             when '3' then gcdtext3
           end
      into result
      from v_com_cpy_pcs_codes
     where gcgname = aName
       and gclcode = aValue
       and pc_lang_id = LangId;

    return result;
  exception
    when no_data_found then
      return null;
  end GetNumDescodeDescr;

  /**
  * Description
  *   indique si un champ existe dans une table
  */
  function FieldExists(iv_entity_name in fwk_i_typ_definition.ENTITY_NAME, iv_field_name in fwk_i_typ_definition.FIELD_NAME)
    return number
  is
  begin
    -- appel depuis un package créé dans un schéma soit société soit PCS à cause du AUTHID current_user utilisé par le package FWK_LIB_ENTITY
    return FWK_I_LIB_ENTITY.FieldExists(iv_entity_name => iv_entity_name, iv_field_name => iv_field_name);
  end FieldExists;
end COM_FUNCTIONS;
