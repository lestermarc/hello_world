--------------------------------------------------------
--  DDL for Package Body COM_VFIELDS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_VFIELDS" 
is
  /**
  * Description
  *   Méthode de création de detail par copie
  */
  procedure p_getComVFieldsRecordIdFromPk2(iTableName in varchar2, iRecordId in number, oComVfieldsRecordId out COM_VFIELDS_RECORD.COM_VFIELDS_RECORD_ID%type)
  is
  begin
    begin
      select cvr.COM_VFIELDS_RECORD_ID
        into oComVfieldsRecordId
        from COM_VFIELDS_RECORD cvr
       where cvr.VFI_REC_ID = iRecordId
         and cvr.VFI_TABNAME = iTableName;
    exception
      when no_data_found then
        oComVfieldsRecordId  := null;
    end;
  end p_getComVFieldsRecordIdFromPk2;

  /**
   * Description
   *     Récupère les infos du champ physique utilisé pour sauvegarder un champ virtuel
   */
  procedure RetrieveVF2Infos(
    aTableName       in     varchar2
  , aFieldName       in     varchar2
  , aDataFieldName   out    varchar2
  , aDataFieldLength out    number
  , aDataFieldType   out    varchar2
  )
  is
    cursor crDataFieldInfos(aTableName in varchar2, aFieldName in varchar2, aObjectId in number)
    is
      select   VF.FLDNAME
             , VF.FLDLENGTH
             , VF.FLDTYPE
          from PCS.PC_TABLE TBL
             , PCS.PC_FLDSC FLD
             , PCS.PC_FLDSC VF
         where TBL.PC_TABLE_ID = FLD.PC_TABLE_ID
           and nvl(FLD.FLDVIRTUALFIELD, 0) = 1
           and FLD.PC_VFIELD_VALUE_ID = VF.PC_FLDSC_ID
           and (   FLD.PC_OBJECT_ID = aObjectId
                or FLD.PC_OBJECT_ID is null)
           and FLD.FLDNAME = aFieldName
           and TBL.TABNAME = aTableName
      order by FLD.PC_OBJECT_ID;

    tplDataFieldInfos crDataFieldInfos%rowtype;
  begin
    -- Recherche du nom du champ correspondant au champ virtuel demandé
    open crDataFieldInfos(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

    fetch crDataFieldInfos
     into tplDataFieldInfos;

    if crDataFieldInfos%found then
      aDataFieldName    := tplDataFieldInfos.FLDNAME;
      aDataFieldLength  := tplDataFieldInfos.FLDLENGTH;
      aDataFieldType    := tplDataFieldInfos.FLDTYPE;
    end if;

    close crDataFieldInfos;
  end RetrieveVF2Infos;

  /**
   * Description
   *     Récupère le nom du champ physique utilisé pour sauvegarder un champ virtuel
   */
  procedure RetrieveVF2Name(aTableName in varchar2, aFieldName in varchar2, aDataFieldName out varchar2)
  is
    vFieldLength PCS.PC_FLDSC.FLDLENGTH%type;
    vFieldType   PCS.PC_FLDSC.FLDTYPE%type;
  begin
    RetrieveVF2Infos(aTableName, aFieldName, aDataFieldName, vFieldLength, vFieldType);
  end RetrieveVF2Name;

  /**
   * Description
   *     Détermine si il existe un/des camps virtuels pour un enregistrement
   */
  function ExistsVFields(aTableName in varchar2, aIdFieldValue in number, aFilter in varchar2 default null)
    return number
  is
    NbFields     number;
    nbRows       integer;
    result       number;
    CId          integer;
    TestSql      varchar2(32767);
    UpperTestSql varchar2(32767);
    CompanyName  pcs.PC_COMP.COM_NAME%type;

    cursor GetCompanyName(aComp_Id in number)
    is
      select a.com_name
        from pcs.pc_comp a
       where a.pc_comp_id = aComp_Id;
  begin
    nbFields      := 0;
    TestSql       := pcs.PC_FUNCTIONS.GetSql(aTableName, 'VFIELDS', 'SQL01', pcs.PC_I_LIB_SESSION.GetObjectId);

    if TestSql is null then
      -- cf pfctFreeCodes
      if aFilter is null then
        TestSql  :=
          'select VFLD.FLDNAME ' ||
          '  from PCS.PC_FLDSC VFLD, PCS.PC_TABLE TBL ' ||
          ' where TBL.TABNAME = :TABNAME ' ||
          '   and (   VFLD.PC_OBJECT_ID = :PC_OBJECT_ID ' ||
          '         or (    VFLD.PC_OBJECT_ID is null ' ||
          '             and not exists( ' ||
          '                   select SUB_FLD.PC_FLDSC_ID ' ||
          '                     from PCS.PC_FLDSC SUB_FLD ' ||
          '                    where SUB_FLD.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '                      and SUB_FLD.FLDNAME = VFLD.FLDNAME ' ||
          '                      and SUB_FLD.PC_OBJECT_ID = :PC_OBJECT_ID))) ' ||
          '   and VFLD.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '   and VFLD.FLDVIRTUALFIELD = 1 ' ||
          '   and VFLD.FLDVISIBLE = 1 ' ||
          '   and not exists( ' ||
          '               select CSF.PC_VFIELD_CONTEXT_ID ' ||
          '                 from PCS.PC_CONTEXT CTX ' ||
          '                    , PCS.PC_VFIELD_CONTEXT CSF ' ||
          '                where CTX.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '                  and CSF.PC_CONTEXT_ID = CTX.PC_CONTEXT_ID ' ||
          '                  and VFLD.PC_FLDSC_ID = CSF.PC_FLDSC_ID) ';
      else
        TestSql  :=
          'select VFLD.FLDNAME ' ||
          '  from PCS.PC_FLDSC VFLD, PCS.PC_TABLE TBL ' ||
          '     , PCS.PC_CONTEXT CTX ' ||
          '     , PCS.PC_VFIELD_CONTEXT CSF ' ||
          ' where TBL.TABNAME = :TABNAME ' ||
          '   and (   VFLD.PC_OBJECT_ID = :PC_OBJECT_ID ' ||
          '         or (    VFLD.PC_OBJECT_ID is null ' ||
          '             and not exists( ' ||
          '                   select SUB_FLD.PC_FLDSC_ID ' ||
          '                     from PCS.PC_FLDSC SUB_FLD ' ||
          '                    where SUB_FLD.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '                      and SUB_FLD.FLDNAME = VFLD.FLDNAME ' ||
          '                      and SUB_FLD.PC_OBJECT_ID = :PC_OBJECT_ID))) ' ||
          '   and VFLD.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '   and VFLD.FLDVIRTUALFIELD = 1 ' ||
          '   and VFLD.FLDVISIBLE = 1 ' ||
          '   and CTX.PC_TABLE_ID = TBL.PC_TABLE_ID ' ||
          '   and CSF.PC_CONTEXT_ID = CTX.PC_CONTEXT_ID ' ||
          '   and CSF.CSF_DESCODE_VALUE = :FILTER ' ||
          '   and CSF.PC_FLDSC_ID = FLD.PC_FLDSC_ID ';
      end if;
    end if;

    TestSql       := 'SELECT COUNT(*) NBREC FROM (' || TestSql || ')';
    cid           := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(cid, TestSql, DBMS_SQL.v7);
    UpperTestSql  := upper(TestSql);

    if instr(UpperTestSql, ':TABNAME') > 0 then
      DBMS_SQL.BIND_VARIABLE(cId, 'TABNAME', aTableName);
    end if;

    if instr(UpperTestSql, ':PC_OBJECT_ID') > 0 then
      DBMS_SQL.BIND_VARIABLE(cId, 'PC_OBJECT_ID', pcs.PC_I_LIB_SESSION.GetObjectId);
    end if;

    if instr(UpperTestSql, ':COM_NAME') > 0 then
      open GetCompanyName(pcs.PC_I_LIB_SESSION.GETCOMPANYID);

      fetch GetCompanyName
       into CompanyName;

      DBMS_SQL.BIND_VARIABLE(cId, 'COM_NAME', CompanyName);

      close GetCompanyName;
    end if;

    if instr(UpperTestSql, ':REC_ID') > 0 then
      DBMS_SQL.BIND_VARIABLE(cId, 'REC_ID', aIdFieldValue);
    end if;

    if instr(UpperTestSql, ':OBJ_NAME') > 0 then
      DBMS_SQL.BIND_VARIABLE(cId, 'OBJ_NAME', pcs.PC_I_LIB_SESSION.GetObjectName);
    end if;

    if instr(UpperTestSql, ':FILTER') > 0 then
      DBMS_SQL.BIND_VARIABLE(cId, 'FILTER', aFilter);
    end if;

    DBMS_SQL.DEFINE_COLUMN(cid, 1, nbFields);
    NbRows        := DBMS_SQL.EXECUTE_AND_FETCH(cid);
    DBMS_SQL.column_value(cId, 1, nbFields);
    DBMS_SQL.CLOSE_CURSOR(cid);

    if nbFields = 0 then
      return 0;
    else
      return 1;
    end if;
  end ExistsVFields;

  /**
  * Description
  *     Retourne la valeur d'un champ virtuel
  *     Type caractère
  */
  function GetVFChar(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return varchar2
  is
    result    COM_VFIELDS_VALUE.CVF_CHAR%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;

    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   flddefault
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;
  begin
    begin
      select CVF_CHAR
           , CVF_TYPE
        into result
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;
    exception
      -- pas de champ virtuel
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into result;

        close pc_fldsc_cursor;

        fieldType  := 'C';
    end;

    -- -- vérification du type du champ
    if fieldType = 'C' then
      return result;
    else
      raise_application_error
        (-20044
       , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la fonction GetVFChar, n''est pas du bon type par rapport à COM_VFIELDS_VALUE')
               , 'XXXX'
               , aFieldName
                )
        );
    end if;
  end GetVFChar;

  /**
  * Description
  *     Retourne la valeur d'un champ virtuel
  *     Type numérique
  */
  function GetVFNumber(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return number
  is
    result    COM_VFIELDS_VALUE.CVF_NUM%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;

    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   decode(flddefault, null, null, to_number(flddefault) )
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;
  begin
    begin
      select CVF_NUM
           , CVF_TYPE
        into result
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;
    exception
      -- pas de champ virtuel
      when no_data_found then
        begin
          open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

          fetch pc_fldsc_cursor
           into result;

          close pc_fldsc_cursor;

          fieldType  := 'N';
        exception
          when others then
            raise_application_error
                            (-20047
                           , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur par défaut du champ numérique "XXXX" n''est pas convertible en nombre')
                                   , 'XXXX'
                                   , aFieldName
                                    )
                            );
        end;
    end;

    -- -- vérification du type du champ
    if fieldType = 'N' then
      return result;
    else
      raise_application_error
        (-20044
       , replace
               (PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la fonction GetVFNumber, n''est pas du bon type par rapport à COM_VFIELDS_VALUE')
              , 'XXXX'
              , aFieldName
               )
        );
    end if;
  end GetVFNumber;

  /**
  * Description
  *     Retourne la valeur d'un champ virtuel
  *     Type bolléen
  */
  function GetVFBoolean(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return number
  is
    result    COM_VFIELDS_VALUE.CVF_BOOL%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;

    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   decode(flddefault, null, null, to_number(flddefault) )
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;
  begin
    begin
      select CVF_BOOL
           , CVF_TYPE
        into result
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;
    exception
      -- pas de champ virtuel
      when no_data_found then
        begin
          open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

          fetch pc_fldsc_cursor
           into result;

          close pc_fldsc_cursor;

          fieldType  := 'B';

          if result not in(null, 0, 1) then
            raise_application_error(-20048, 'start exception');
          end if;
        exception
          when others then
            raise_application_error(-20048
                                  , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur par défaut du champ boolean "XXXX" est mal formatée')
                                          , 'XXXX'
                                          , aFieldName
                                           )
                                   );
        end;
    end;

    -- -- vérification du type du champ
    if fieldType = 'B' then
      return result;
    else
      raise_application_error
        (-20044
       , replace
              (PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la fonction GetVFBoolean, n''est pas du bon type par rapport à COM_VFIELDS_VALUE')
             , 'XXXX'
             , aFieldName
              )
        );
    end if;
  end GetVFBoolean;

  /**
  * Description
  *     Retourne la valeur d'un champ virtuel
  *     Type memo
  */
  function GetVFMemo(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return varchar2
  is
    result    COM_VFIELDS_VALUE.CVF_MEMO%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;

    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   flddefault
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;
  begin
    begin
      select CVF_MEMO
           , CVF_TYPE
        into result
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;
    exception
      -- pas de champ virtuel
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into result;

        close pc_fldsc_cursor;

        fieldType  := 'M';
    end;

    -- -- vérification du type du champ
    if fieldType = 'M' then
      return result;
    else
      raise_application_error
        (-20044
       , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la fonction GetVFMemo, n''est pas du bon type par rapport à COM_VFIELDS_VALUE')
               , 'XXXX'
               , aFieldName
                )
        );
    end if;
  end GetVFMemo;

  /**
  * Description
  *     Retourne la valeur d'un champ virtuel
  *     Type date
  */
  function GetVFDate(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return date
  is
    result    COM_VFIELDS_VALUE.CVF_DATE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;

    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   decode(flddefault, null, null, to_date(flddefault) )
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;
  begin
    begin
      select CVF_DATE
           , CVF_TYPE
        into result
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;
    exception
      -- pas de champ virtuel
      when no_data_found then
        begin
          open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

          fetch pc_fldsc_cursor
           into result;

          close pc_fldsc_cursor;

          fieldType  := 'D';
        exception
          when others then
            raise_application_error(-20049
                                  , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur par défaut du champ date "XXXX" est mal formatée')
                                          , 'XXXX'
                                          , aFieldName
                                           )
                                   );
        end;
    end;

    -- -- vérification du type du champ
    if fieldType = 'D' then
      return result;
    else
      raise_application_error
        (-20044
       , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la fonction GetVFDate, n''est pas du bon type par rapport à COM_VFIELDS_VALUE')
               , 'XXXX'
               , aFieldName
                )
        );
    end if;
  end GetVFDate;

  /**
  * Description
  *     Initialise la valeur d'un champ virtuel
  *     Type caractère
  */
  procedure SetVFChar(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in COM_VFIELDS_VALUE.CVF_CHAR%type)
  is
    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   pc_fldsc_id
             , fldtype
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;

    fldscId   PCS.PC_FLDSC.PC_FLDSC_ID%type;
    fType     PCS.PC_FLDSC.FLDTYPE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    comVfId   COM_VFIELDS_VALUE.COM_VFIELDS_VALUE_ID%type;
  begin
    begin
      -- recherche de l'id. Si pas trouvé, déclenchement exception. Insertion dans la partie exception
      -- Si trouvé, mise à jour de la valeur
      select COM_VFIELDS_VALUE_ID
           , CVF_TYPE
        into comVfId
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;

      -- Vérification du type
      if fieldType = 'C' then
        update COM_VFIELDS_VALUE
           set CVF_CHAR = aVFFieldValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_VFIELDS_VALUE_ID = comVfId;
      else
        raise_application_error
          (-20045
         , replace
             (PCS.PC_FUNCTIONS.TranslateWord
                   ('PCS - Le champ "XXXX" passé à la procedure SetVFChar, n''est pas du bon type par rapport à la valeur déjà existante dans COM_VFIELDS_VALUE')
            , 'XXXX'
            , aFieldName
             )
          );
      end if;
    exception
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into fldscId
            , fType;

        close pc_fldsc_cursor;

        if fldscId is not null then
          if fType in('FTSTRING', 'FTBYTE', 'FTVARBYTE') then
            insert into COM_VFIELDS_VALUE
                        (COM_VFIELDS_VALUE_ID
                       , CVF_TABNAME
                       , CVF_FLDNAME
                       , CVF_REC_ID
                       , CVF_TYPE
                       , CVF_BOOL
                       , CVF_CHAR
                       , CVF_DATE
                       , CVF_NUM
                       , CVF_MEMO
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , aTableName
                       , aFieldName
                       , aIdFieldValue
                       , 'C'
                       , null
                       , aVFFieldValue
                       , null
                       , null
                       , null
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          else
            raise_application_error
              (-20046
             , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVfChar, n''est pas du bon type par rapport à PC_FLDSC')
                     , 'XXXX'
                     , aFieldName
                      )
              );
          end if;
        else
          raise_application_error
                           (-20047
                          , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVfChar n''a pas été trouvé dans PC_FLDSC')
                                  , 'XXXX'
                                  , aFieldName
                                   )
                           );
        end if;
    end;
  end SetVFChar;

  /**
  * Description
  *     Initialise la valeur d'un champ virtuel
  *     Type numérique
  */
  procedure SetVFNumber(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in COM_VFIELDS_VALUE.CVF_NUM%type)
  is
    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   pc_fldsc_id
             , fldtype
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;

    fldscId   PCS.PC_FLDSC.PC_FLDSC_ID%type;
    fType     PCS.PC_FLDSC.FLDTYPE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    comVfId   COM_VFIELDS_VALUE.COM_VFIELDS_VALUE_ID%type;
  begin
    begin
      -- recherche de l'id. Si pas trouvé, déclenchement exception. Insertion dans la partie exception
      -- Si trouvé, mise à jour de la valeur
      select COM_VFIELDS_VALUE_ID
           , CVF_TYPE
        into comVfId
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;

      -- Vérification du type
      if fieldType = 'N' then
        update COM_VFIELDS_VALUE
           set CVF_NUM = aVFFieldValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_VFIELDS_VALUE_ID = comVfId;
      else
        raise_application_error
          (-20045
         , replace
             (PCS.PC_FUNCTIONS.TranslateWord
                    ('PCS - Le champ "XXXX" passé à la fonction GetVFDate, n''est pas du bon type par rapport à la valeur déjà existante dans COM_VFIELDS_VALUE')
            , 'XXXX'
            , aFieldName
             )
          );
      end if;
    exception
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into fldscId
            , fType;

        close pc_fldsc_cursor;

        if fldscId is not null then
          if fType in('FTCURRENCY', 'FTFLOAT', 'FTINTEGER', 'FTSMALLINT') then
            insert into COM_VFIELDS_VALUE
                        (COM_VFIELDS_VALUE_ID
                       , CVF_TABNAME
                       , CVF_FLDNAME
                       , CVF_REC_ID
                       , CVF_TYPE
                       , CVF_BOOL
                       , CVF_CHAR
                       , CVF_DATE
                       , CVF_NUM
                       , CVF_MEMO
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , aTableName
                       , aFieldName
                       , aIdFieldValue
                       , 'N'
                       , null
                       , null
                       , null
                       , aVFFieldValue
                       , null
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          else
            raise_application_error
               (-20046
              , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFNum, n''est pas du bon type par rapport à PC_FLDSC')
                      , 'XXXX'
                      , aFieldName
                       )
               );
          end if;
        else
          raise_application_error
                            (-20047
                           , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFNum n''a pas été trouvé dans PC_FLDSC')
                                   , 'XXXX'
                                   , aFieldName
                                    )
                            );
        end if;
    end;
  end SetVFNumber;

  /**
  * Description
  *     Initialise la valeur d'un champ virtuel
  *     Type booléen
  */
  procedure SetVFBoolean(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in COM_VFIELDS_VALUE.CVF_BOOL%type)
  is
    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   pc_fldsc_id
             , fldtype
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;

    fldscId   PCS.PC_FLDSC.PC_FLDSC_ID%type;
    fType     PCS.PC_FLDSC.FLDTYPE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    comVfId   COM_VFIELDS_VALUE.COM_VFIELDS_VALUE_ID%type;
  begin
    begin
      -- recherche de l'id. Si pas trouvé, déclenchement exception. Insertion dans la partie exception
      -- Si trouvé, mise à jour de la valeur
      select COM_VFIELDS_VALUE_ID
           , CVF_TYPE
        into comVfId
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;

      -- Vérification du type
      if fieldType = 'B' then
        update COM_VFIELDS_VALUE
           set CVF_BOOL = aVFFieldValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_VFIELDS_VALUE_ID = comVfId;
      else
        raise_application_error
          (-20045
         , replace
             (PCS.PC_FUNCTIONS.TranslateWord
                ('PCS - Le champ "XXXX" passé à la procedure SetVFBoolean, n''est pas du bon type par rapport à la valeur déjà existante dans COM_VFIELDS_VALUE')
            , 'XXXX'
            , aFieldName
             )
          );
      end if;
    exception
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into fldscId
            , fType;

        close pc_fldsc_cursor;

        if fldscId is not null then
          if fType in('FTBOOLEAN') then
            insert into COM_VFIELDS_VALUE
                        (COM_VFIELDS_VALUE_ID
                       , CVF_TABNAME
                       , CVF_FLDNAME
                       , CVF_REC_ID
                       , CVF_TYPE
                       , CVF_BOOL
                       , CVF_CHAR
                       , CVF_DATE
                       , CVF_NUM
                       , CVF_MEMO
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , aTableName
                       , aFieldName
                       , aIdFieldValue
                       , 'B'
                       , aVFFieldValue
                       , null
                       , null
                       , null
                       , null
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          else
            raise_application_error
              (-20046
             , replace
                      (PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFBoolean, n''est pas du bon type par rapport à PC_FLDSC')
                     , 'XXXX'
                     , aFieldName
                      )
              );
          end if;
        else
          raise_application_error
                       (-20047
                      , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFBoolean, n''a pas été trouvé dans PC_FLDSC')
                              , 'XXXX'
                              , aFieldName
                               )
                       );
        end if;
    end;
  end SetVFBoolean;

  /**
  * Description
  *     Initialise la valeur d'un champ virtuel
  *     Type memo
  */
  procedure SetVFMemo(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in COM_VFIELDS_VALUE.CVF_MEMO%type)
  is
    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   pc_fldsc_id
             , fldtype
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;

    fldscId   PCS.PC_FLDSC.PC_FLDSC_ID%type;
    fType     PCS.PC_FLDSC.FLDTYPE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    comVfId   COM_VFIELDS_VALUE.COM_VFIELDS_VALUE_ID%type;
  begin
    begin
      -- recherche de l'id. Si pas trouvé, déclenchement exception. Insertion dans la partie exception
      -- Si trouvé, mise à jour de la valeur
      select COM_VFIELDS_VALUE_ID
           , CVF_TYPE
        into comVfId
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;

      -- Vérification du type
      if fieldType = 'M' then
        update COM_VFIELDS_VALUE
           set CVF_MEMO = aVFFieldValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_VFIELDS_VALUE_ID = comVfId;
      else
        raise_application_error
          (-20045
         , replace
             (PCS.PC_FUNCTIONS.TranslateWord
                   ('PCS - Le champ "XXXX" passé à la procedure SetVFMemo, n''est pas du bon type par rapport à la valeur déjà existante dans COM_VFIELDS_VALUE')
            , 'XXXX'
            , aFieldName
             )
          );
      end if;
    exception
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into fldscId
            , fType;

        close pc_fldsc_cursor;

        if fldscId is not null then
          if fType in('FTMEMO') then
            insert into COM_VFIELDS_VALUE
                        (COM_VFIELDS_VALUE_ID
                       , CVF_TABNAME
                       , CVF_FLDNAME
                       , CVF_REC_ID
                       , CVF_TYPE
                       , CVF_BOOL
                       , CVF_CHAR
                       , CVF_DATE
                       , CVF_NUM
                       , CVF_MEMO
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , aTableName
                       , aFieldName
                       , aIdFieldValue
                       , 'M'
                       , null
                       , null
                       , null
                       , null
                       , aVFFieldValue
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          else
            raise_application_error
              (-20046
             , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFMemo, n''est pas du bon type par rapport à PC_FLDSC')
                     , 'XXXX'
                     , aFieldName
                      )
              );
          end if;
        else
          raise_application_error
                         (-20047
                        , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX"  passé à la procedure SetVFMemo, n''a pas été trouvé dans PC_FLDSC')
                                , 'XXXX'
                                , aFieldName
                                 )
                         );
        end if;
    end;
  end SetVFMemo;

  /**
  * Description
  *     Initialise la valeur d'un champ virtuel
  *     Type date
  */
  procedure SetVFDate(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in COM_VFIELDS_VALUE.CVF_DATE%type)
  is
    cursor pc_fldsc_cursor(aTableName varchar2, aFieldName varchar2, aObjectId number)
    is
      select   pc_fldsc_id
             , fldtype
          from pcs.pc_fldsc fld
             , pcs.pc_table tab
         where fld.fldname = upper(aFieldName)
           and tab.tabname(+) = upper(aTableName)
           and fld.pc_table_id = tab.pc_table_id(+)
           and (   fld.pc_object_id = aObjectId
                or fld.pc_object_id is null)
      order by fld.pc_object_id desc
             , fld.pc_table_id desc;

    fldscId   PCS.PC_FLDSC.PC_FLDSC_ID%type;
    fType     PCS.PC_FLDSC.FLDTYPE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    comVfId   COM_VFIELDS_VALUE.COM_VFIELDS_VALUE_ID%type;
  begin
    begin
      -- recherche de l'id. Si pas trouvé, déclenchement exception. Insertion dans la partie exception
      -- Si trouvé, mise à jour de la valeur
      select COM_VFIELDS_VALUE_ID
           , CVF_TYPE
        into comVfId
           , fieldtype
        from COM_VFIELDS_VALUE
       where CVF_TABNAME = upper(aTableName)
         and CVF_FLDNAME = upper(aFieldName)
         and CVF_REC_ID = aIdFieldValue;

      -- Vérification du type
      if fieldType = 'D' then
        update COM_VFIELDS_VALUE
           set CVF_DATE = aVFFieldValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where COM_VFIELDS_VALUE_ID = comVfId;
      else
        raise_application_error
          (-20045
         , replace
             (PCS.PC_FUNCTIONS.TranslateWord
                   ('PCS - Le champ "XXXX" passé à la procedure SetVFDate, n''est pas du bon type par rapport à la valeur déjà existante dans COM_VFIELDS_VALUE')
            , 'XXXX'
            , aFieldName
             )
          );
      end if;
    exception
      when no_data_found then
        open pc_fldsc_cursor(aTableName, aFieldName, PCS.PC_I_LIB_SESSION.GetObjectId);

        fetch pc_fldsc_cursor
         into fldscId
            , fType;

        close pc_fldsc_cursor;

        if fldscId is not null then
          if fType in('FTDATE', 'FTTIME', 'FTDATETIME') then
            insert into COM_VFIELDS_VALUE
                        (COM_VFIELDS_VALUE_ID
                       , CVF_TABNAME
                       , CVF_FLDNAME
                       , CVF_REC_ID
                       , CVF_TYPE
                       , CVF_BOOL
                       , CVF_CHAR
                       , CVF_DATE
                       , CVF_NUM
                       , CVF_MEMO
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (init_id_seq.nextval
                       , aTableName
                       , aFieldName
                       , aIdFieldValue
                       , 'D'
                       , null
                       , null
                       , aVFFieldValue
                       , null
                       , null
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          else
            raise_application_error
              (-20046
             , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFDate, n''est pas du bon type par rapport à PC_FLDSC')
                     , 'XXXX'
                     , aFieldName
                      )
              );
          end if;
        else
          raise_application_error
                          (-20047
                         , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le champ "XXXX" passé à la procedure SetVFDate, n''a pas été trouvé dans PC_FLDSC')
                                 , 'XXXX'
                                 , aFieldName
                                  )
                          );
        end if;
    end;
  end SetVFDate;

  /**
  * Description
  *         Copie un ou plusieurs champs virtuels
  */
  procedure DuplicateVirtualField(aTableName in varchar2, aFieldName in varchar2, aIDRecordSource in number, aIDRecordTarget in number)
  is
    ConditionFieldName  varchar2(50);
    ltCRUD_DEF          FWK_I_TYP_DEFINITION.t_crud_def;
    lComVFieldsRecordId COM_VFIELDS_RECORD.COM_VFIELDS_RECORD_ID%type;
  begin
    --Récupération de la ligne à dupliquer pour com_vfields_record
    p_getComVFieldsRecordIdFromPk2(aTableName, aIDRecordSource, lComVFieldsRecordId);

    -- Vérifie si l'on a défini ou pas le noms d'un champs virtuel spécifiquement ou bien
    -- si l'on veut en copier plusieurs pour le record ID source.
    select nvl(rtrim(ltrim(aFieldName) ), 0) FIELD_NAME
      into ConditionFieldName
      from dual;

    -- Copie de tous les champs virtuels pour l'ID du record Source
    if ConditionFieldName = '0' then
      insert into COM_VFIELDS_VALUE
                  (COM_VFIELDS_VALUE_ID
                 , CVF_TABNAME
                 , CVF_FLDNAME
                 , CVF_REC_ID
                 , CVF_TYPE
                 , CVF_BOOL
                 , CVF_CHAR
                 , CVF_DATE
                 , CVF_NUM
                 , CVF_MEMO
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- COM_VFIELDS_VALUE_ID
             , CVF_TABNAME
             , CVF_FLDNAME
             , aIDRecordTarget   -- CVF_REC_ID
             , CVF_TYPE
             , CVF_BOOL
             , CVF_CHAR
             , CVF_DATE
             , CVF_NUM
             , CVF_MEMO
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from COM_VFIELDS_VALUE
         where CVF_TABNAME = aTableName
           and CVF_REC_ID = aIDRecordSource;

      --Le cas com_vfields_record
      if lComVFieldsRecordId is not null then
        -- Duplication de la ligne
        FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_COM_ENTITY.gcComVfieldsRecord, iot_crud_definition => ltCRUD_DEF);
        FWK_I_MGT_ENTITY.PrepareDuplicate(iot_crud_definition => ltCRUD_DEF, ib_initialize => true, in_main_id => lComVFieldsRecordId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VFI_REC_ID', aIDRecordTarget);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;
    else
      -- Copie du champ virtuel nommé de l'ID du record Source
      insert into COM_VFIELDS_VALUE
                  (COM_VFIELDS_VALUE_ID
                 , CVF_TABNAME
                 , CVF_FLDNAME
                 , CVF_REC_ID
                 , CVF_TYPE
                 , CVF_BOOL
                 , CVF_CHAR
                 , CVF_DATE
                 , CVF_NUM
                 , CVF_MEMO
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval   -- COM_VFIELDS_VALUE_ID
             , CVF_TABNAME
             , CVF_FLDNAME
             , aIDRecordTarget   -- CVF_REC_ID
             , CVF_TYPE
             , CVF_BOOL
             , CVF_CHAR
             , CVF_DATE
             , CVF_NUM
             , CVF_MEMO
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from COM_VFIELDS_VALUE
         where CVF_TABNAME = aTableName
           and CVF_REC_ID = aIDRecordSource
           and CVF_FLDNAME = ConditionFieldName;

      --Le cas com_vfields_record
      if lComVFieldsRecordId is not null then
        -- Création de la nouvelle ligne et mise à jour de la vlaeur
        FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_COM_ENTITY.gcComVfieldsRecord, iot_crud_definition => ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VFI_TABNAME', aTableName);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'VFI_REC_ID', aIDRecordTarget);

        if    (instr(aFieldName, 'VFI_INTEGER') > 0)
           or (instr(aFieldName, 'VFI_FLOAT') > 0) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition   => ltCRUD_DEF
                                        , iv_column_name        => aFieldName
                                        , iv_value              => FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'COM_VFIELDS_RECORD'
                                                                                                       , iv_column_name   => aFieldName
                                                                                                       , it_pk_value      => lComVFieldsRecordId
                                                                                                        )
                                         );
        elsif    (instr(aFieldName, 'VFI_CHAR') > 0)
              or (instr(aFieldName, 'VFI_DESCODES') > 0)
              or (instr(aFieldName, 'VFI_MEMO') > 0) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition   => ltCRUD_DEF
                                        , iv_column_name        => aFieldName
                                        , iv_value              => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'COM_VFIELDS_RECORD'
                                                                                                         , iv_column_name   => aFieldName
                                                                                                         , it_pk_value      => lComVFieldsRecordId
                                                                                                          )
                                         );
        elsif(instr(aFieldName, 'VFI_DATE') > 0) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition   => ltCRUD_DEF
                                        , iv_column_name        => aFieldName
                                        , iv_value              => FWK_I_LIB_ENTITY.getDateFieldFromPk(iv_entity_name   => 'COM_VFIELDS_RECORD'
                                                                                                     , iv_column_name   => aFieldName
                                                                                                     , it_pk_value      => lComVFieldsRecordId
                                                                                                      )
                                         );
        end if;

        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;
    end if;
  end DuplicateVirtualField;

  /**
  * Description
  *    Maj des valeurs des champs virtuels 2ème type
  */
  procedure SetVF2Value(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in date)
  is
    vfieldName    PCS.PC_FLDSC.FLDNAME%type;
    sqlCommand    varchar2(4000);
    dynamicCursor integer;
    errorCursor   integer;
    testId        COM_VFIELDS_RECORD.COM_VFIELDS_RECORD_ID%type;
  begin
    -- Recherche du nom du champ correspondant au champ virtuel demandé
    RetrieveVF2Name(aTableName, aFieldName, vfieldName);

    if vfieldName is not null then
      begin
        -- Recherche l'existance d'un record correspondant
        select COM_VFIELDS_RECORD_ID
          into testId
          from COM_VFIELDS_RECORD
         where VFI_REC_ID = aIdFieldValue
           and VFI_TABNAME = aTableName;

        sqlCommand  :=
          'UPDATE COM_VFIELDS_RECORD SET ' ||
          vfieldName ||
          '= :VFIELDVALUE, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni, A_DATEMOD = sysdate WHERE VFI_REC_ID = :RECORD_ID AND VFI_TABNAME = :TABLENAME';
      exception
        when no_data_found then
          sqlCommand  :=
            'INSERT INTO COM_VFIELDS_RECORD(COM_VFIELDS_RECORD_ID, VFI_TABNAME, VFI_REC_ID, ' ||
            vfieldName ||
            ', A_IDCRE, A_DATECRE) VALUES(INIT_ID_SEQ.NEXTVAL, :TABLENAME, :RECORD_ID, :VFIELDVALUE, PCS.PC_I_LIB_SESSION.GetUserIni, sysdate)';
      end;

      -- ouverture du curseur dynamique et retour de la valeur
      dynamicCursor  := DBMS_SQL.open_cursor;

      begin
        -- Vérification
        DBMS_SQL.parse(dynamicCursor, sqlCommand, DBMS_SQL.native);
        -- Assignation de variables de la commande
        DBMS_SQL.bind_variable(dynamicCursor, ':RECORD_ID', aIdFieldValue);
        DBMS_SQL.bind_variable(dynamicCursor, ':TABLENAME', aTableName);
        DBMS_SQL.bind_variable(dynamicCursor, ':VFIELDVALUE', aVFFieldValue);
        -- Execution
        errorCursor  := DBMS_SQL.execute(dynamicCursor);
        -- Ferme le curseur
        DBMS_SQL.close_cursor(dynamicCursor);
      exception
        when others then
          -- Ferme le curseur
          DBMS_SQL.close_cursor(dynamicCursor);
          raise_application_error(-20000, 'PCS - Error in dynamic call of SQL statement ' || sqlCommand || chr(13) || sqlerrm);
      end;
    end if;
  end SetVF2Value;

  /**
  * Description
  *    Maj des valeurs des champs virtuels 2ème type
  */
  procedure SetVF2Value(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in varchar2)
  is
    vfieldName    PCS.PC_FLDSC.FLDNAME%type;
    sqlCommand    varchar2(4000);
    dynamicCursor integer;
    errorCursor   integer;
    testId        COM_VFIELDS_RECORD.COM_VFIELDS_RECORD_ID%type;
  begin
    -- Recherche du nom du champ correspondant au champ virtuel demandé
    RetrieveVF2Name(aTableName, aFieldName, vfieldName);

    if vfieldName is not null then
      begin
        -- Recherche l'existance d'un record correspondant
        select COM_VFIELDS_RECORD_ID
          into testId
          from COM_VFIELDS_RECORD
         where VFI_REC_ID = aIdFieldValue
           and VFI_TABNAME = aTableName;

        sqlCommand  :=
          'UPDATE COM_VFIELDS_RECORD SET ' ||
          vfieldName ||
          '= :VFIELDVALUE, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni, A_DATEMOD = sysdate WHERE VFI_REC_ID = :RECORD_ID AND VFI_TABNAME = :TABLENAME';
      exception
        when no_data_found then
          sqlCommand  :=
            'INSERT INTO COM_VFIELDS_RECORD(COM_VFIELDS_RECORD_ID, VFI_TABNAME, VFI_REC_ID, ' ||
            vfieldName ||
            ', A_IDCRE, A_DATECRE) VALUES(INIT_ID_SEQ.NEXTVAL, :TABLENAME, :RECORD_ID, :VFIELDVALUE, PCS.PC_I_LIB_SESSION.GetUserIni, sysdate)';
      end;

      -- ouverture du curseur dynamique et retour de la valeur
      dynamicCursor  := DBMS_SQL.open_cursor;

      begin
        -- Vérification
        DBMS_SQL.parse(dynamicCursor, sqlCommand, DBMS_SQL.native);
        -- Assignation de variables de la commande
        DBMS_SQL.bind_variable(dynamicCursor, ':RECORD_ID', aIdFieldValue);
        DBMS_SQL.bind_variable(dynamicCursor, ':TABLENAME', aTableName);
        DBMS_SQL.bind_variable(dynamicCursor, ':VFIELDVALUE', aVFFieldValue);
        -- Execution
        errorCursor  := DBMS_SQL.execute(dynamicCursor);
        -- Ferme le curseur
        DBMS_SQL.close_cursor(dynamicCursor);
      exception
        when others then
          -- Ferme le curseur
          DBMS_SQL.close_cursor(dynamicCursor);
          raise_application_error(-20000, 'PCS - Error in dynamic call of SQL statement ' || sqlCommand || chr(13) || sqlerrm);
      end;
    end if;
  end SetVF2Value;

  /**
  * Description
  *    Maj des valeurs des champs virtuels 2ème type
  */
  procedure SetVF2Value(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number, aVFFieldValue in number)
  is
    vfieldName    PCS.PC_FLDSC.FLDNAME%type;
    sqlCommand    varchar2(4000);
    dynamicCursor integer;
    errorCursor   integer;
    testId        COM_VFIELDS_RECORD.COM_VFIELDS_RECORD_ID%type;
  begin
    -- Recherche du nom du champ correspondant au champ virtuel demandé
    RetrieveVF2Name(aTableName, aFieldName, vfieldName);

    if vfieldName is not null then
      begin
        -- Recherche l'existance d'un record correspondant
        select COM_VFIELDS_RECORD_ID
          into testId
          from COM_VFIELDS_RECORD
         where VFI_REC_ID = aIdFieldValue
           and VFI_TABNAME = aTableName;

        sqlCommand  :=
          'UPDATE COM_VFIELDS_RECORD SET ' ||
          vfieldName ||
          '= :VFIELDVALUE, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni, A_DATEMOD = sysdate WHERE VFI_REC_ID = :RECORD_ID AND VFI_TABNAME = :TABLENAME';
      exception
        when no_data_found then
          sqlCommand  :=
            'INSERT INTO COM_VFIELDS_RECORD(COM_VFIELDS_RECORD_ID, VFI_TABNAME, VFI_REC_ID, ' ||
            vfieldName ||
            ', A_IDCRE, A_DATECRE) VALUES(INIT_ID_SEQ.NEXTVAL, :TABLENAME, :RECORD_ID, :VFIELDVALUE, PCS.PC_I_LIB_SESSION.GetUserIni, sysdate)';
      end;

      -- ouverture du curseur dynamique et retour de la valeur
      dynamicCursor  := DBMS_SQL.open_cursor;

      begin
        -- Vérification
        DBMS_SQL.parse(dynamicCursor, sqlCommand, DBMS_SQL.native);
        -- Assignation de variables de la commande
        DBMS_SQL.bind_variable(dynamicCursor, ':RECORD_ID', aIdFieldValue);
        DBMS_SQL.bind_variable(dynamicCursor, ':TABLENAME', aTableName);
        DBMS_SQL.bind_variable(dynamicCursor, ':VFIELDVALUE', aVFFieldValue);
        -- Execution
        errorCursor  := DBMS_SQL.execute(dynamicCursor);
        -- Ferme le curseur
        DBMS_SQL.close_cursor(dynamicCursor);
      exception
        when others then
          -- Ferme le curseur
          DBMS_SQL.close_cursor(dynamicCursor);
          raise_application_error(-20000, 'PCS - Error in dynamic call of SQL statement ' || sqlCommand || chr(13) || sqlerrm);
      end;
    end if;
  end SetVF2Value;

  /**
  * Description
  *    Recherche des valeurs des champs virtuels 2ème type
  */
  function GetVF2Value(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return varchar2
  is
    result        varchar2(4000);
    tmpDate       date;
    vfieldName    PCS.PC_FLDSC.FLDNAME%type;
    vFieldLength  PCS.PC_FLDSC.FLDLENGTH%type;
    vFieldType    PCS.PC_FLDSC.FLDTYPE%type;
    sqlCommand    varchar2(4000);
    dynamicCursor integer;
    errorCursor   integer;
  begin
    -- Recherche du nom du champ correspondant au champ virtuel demandé
    RetrieveVF2Infos(aTableName, aFieldName, vfieldName, vfieldLength, vfieldType);

    if vfieldName is null then
      return null;
    end if;

    -- Contruction de la commande de recherche de la valeur
    sqlCommand     := 'SELECT ' || vfieldName || ' FROM COM_VFIELDS_RECORD WHERE VFI_REC_ID = :RECORD_ID AND VFI_TABNAME = :TABLENAME';
    -- ouverture du curseur dynamique et retour de la valeur
    dynamicCursor  := DBMS_SQL.open_cursor;

    begin
      -- Vérification
      DBMS_SQL.parse(dynamicCursor, sqlCommand, DBMS_SQL.native);

      -- Définition des colonnes du select
      if vFieldType in('FTDATETIME', 'FTDATE', 'FTTIME') then
        DBMS_SQL.DEFINE_COLUMN(DynamicCursor, 1, tmpDate);
      else
        DBMS_SQL.DEFINE_COLUMN(DynamicCursor, 1, result, vFieldLength);
      end if;

      -- Assignation de variables de la commande
      DBMS_SQL.bind_variable(dynamicCursor, ':RECORD_ID', aIdFieldValue);
      DBMS_SQL.bind_variable(dynamicCursor, ':TABLENAME', aTableName);
      -- Execution
      errorCursor  := DBMS_SQL.execute(dynamicCursor);

      -- Obtenir le tuple suivant
      if DBMS_SQL.fetch_rows(dynamicCursor) > 0 then
        if vFieldType in('FTDATETIME', 'FTDATE', 'FTTIME') then
          DBMS_SQL.column_value(dynamicCursor, 1, tmpDate);
          result  := to_char(tmpDate, 'DD.MM.YYYY HH24:MI:SS');
        else
          DBMS_SQL.column_value(dynamicCursor, 1, result);
        end if;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(dynamicCursor);
    exception
      when others then
        -- Ferme le curseur
        DBMS_SQL.close_cursor(dynamicCursor);
        raise_application_error(-20000, 'PCS - Error in dynamic call of SQL statement ' || sqlCommand || chr(13) || sqlerrm);
    end;

    return result;
  end GetVF2Value;

  function GetVF2Value_char(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return varchar2
  is
  begin
    return GetVf2Value(aTableName, aFieldName, aIdFieldValue);
  end GetVF2Value_char;

  function GetVF2Value_number(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return number
  is
  begin
    return to_number(GetVf2Value(aTableName, aFieldName, aIdFieldValue) );
  end GetVF2Value_number;

  function GetVF2Value_date(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number)
    return date
  is
  begin
    return to_date(GetVf2Value(aTableName, aFieldName, aIdFieldValue), 'DD.MM.YYYY HH24:MI:SS');
  end GetVF2Value_date;
end COM_VFIELDS;
