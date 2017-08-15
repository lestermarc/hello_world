--------------------------------------------------------
--  DDL for Package Body DOC_EDEC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDEC_FUNCTIONS" 
is
  function RemoveCompanyOwner(iSql in clob)
    return clob
  is
    lResult clob;
  begin
    lResult  := replace(upper(iSql), '[COMPANY_OWNER' || '].', '');
    lResult  := replace(upper(lResult), '[CO' || '].', '');
    return lResult;
  end RemoveCompanyOwner;

  /**
  * procedure GenerateHeader
  * Description
  *   Création de l'entête de la déclaration EDEC
  */
  procedure GenerateHeader(
    aHeaderID      out    DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in     DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vEdecCode        DOC_EDI_TYPE.C_EDI_METHOD%type      default null;
    vSqlCmd          varchar2(32000);
    ln_EdiTypeId     doc_edi_type.doc_edi_type_id%type;
    lv_packageName   varchar2(50);
    lv_exp_method    varchar2(50);
    lv_exportVersion varchar2(50);
    lv_exportMethods varchar2(32000);
    lv_errorMsg      varchar2(32000);
  begin
    aHeaderID  := null;
    vEdecCode  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecCode(aDocumentID => aDocumentID, aPackingListID => aPackingListID);

    if vEdecCode is not null then
      /* ============================================================
         procédure generate_header, cascade de recherche

         1) variable "EDI" GENERATE_PACKAGE.GENERATE_HEADER
         2) commande sql DOC_EDEC_HEADER/E100/GenerateHeader ou
            commande sql DOC_EDEC_HEADER/E101/GenerateHeader
         3) procédure standard ERP

      */
      lv_exportMethods  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecExportMethods(aDocumentID => aDocumentID, aPackingListID => aPackingListID);

      select DET.DOC_EDI_TYPE_ID
           , MTH.EXP_METHOD
        into ln_EdiTypeId
           , lv_exp_method
        from DOC_EDI_TYPE DET
           , (select distinct column_value exp_method
                         from table(PCS.CHARLISTTOTABLE(lv_exportMethods, ';') ) ) MTH
       where MTH.EXP_METHOD is not null
         and MTH.EXP_METHOD = DET.DET_NAME
         and DET.C_EDI_METHOD in('E100', 'E101')
         and DET.PC_EXCHANGE_SYSTEM_ID is not null;

      lv_packageName    := doc_edi_function.getparamvalue('GENERATE_PACKAGE.GENERATEHEADER', ln_EdiTypeID);
      lv_exportVersion  := upper(doc_edi_function.getparamvalue('EXPORT_PACKAGE.VERSION', ln_EdiTypeID) );

      if lv_packageName is not null then
        /* ============================================================
          1) variable "EDI" GENERATE_PACKAGE.GENERATE_HEADER
        */
        begin
          execute immediate 'begin ' || lv_packageName || '.GENERATEHEADER(:on_DocEdecHeaderId, :in_DocDocumentId, :in_DocPackingList);' || ' end;'
                      using out aHeaderID, in aDocumentID, in aPackingListID;
        exception
          when others then
            lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0001');
            lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
            lv_errorMsg  := replace(lv_errorMsg, '%p2', 'GENERATE_PACKAGE.GENERATEHEADER');
            lv_errorMsg  := replace(lv_errorMsg, '%p3', lv_packageName || '.GENERATEHEADER');
            lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
            lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
            pcs.ra(substr(lv_errorMsg, 1, 4000) );
        end;
      else
        /* ============================================================
           2) commande sql DOC_EDEC_HEADER/E100/GenerateHeader ou
              commande sql DOC_EDEC_HEADER/E101/GenerateHeader
        */
        vSqlCmd  := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_EDEC_HEADER', aGroup => vEdecCode, aSqlId => 'GenerateHeader', aHeader => false);
        vSqlCmd  := RemoveCompanyOwner(vSqlCmd);

        if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 0 then
          begin
            execute immediate vSqlCmd
                        using out aHeaderID, in aDocumentID, in aPackingListID;
          exception
            when others then
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0004');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', 'DOC_EDEC_HEADER/' || vEdecCode || '/GenerateHeader. ');
              lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
              lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
          end;
        else
          if vEdecCode = 'E100' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'ETRANS_V1') then
              DOC_EDI_EDEC_ETRANS_V1.GenerateHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'ETRANS_V1_1') then
              DOC_EDI_EDEC_ETRANS_V1_1.GenerateHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              begin
                lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
                lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
                lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
                lv_errorMsg  := replace(lv_errorMsg, '%p3', 'ETRANS_V1,ETRANS_V1_1');
                pcs.ra(substr(lv_errorMsg, 1, 4000) );
              end;
            end if;
          elsif vEdecCode = 'E101' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'EXPOWIN_V4') then
              DOC_EDI_EDEC_EXPOWIN_V4.GenerateHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'EXPOWIN_V405') then
              DOC_EDI_EDEC_EXPOWIN_V405.GenerateHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              begin
                lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
                lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
                lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
                lv_errorMsg  := replace(lv_errorMsg, '%p3', 'EXPOWIN_V4,EXPOWIN_V405');
                pcs.ra(substr(lv_errorMsg, 1, 4000) );
              end;
            end if;
          end if;
        end if;
      end if;
    end if;
  end GenerateHeader;

  /**
  * procedure ReinitializeHeader
  * Description
  *   Màj des données de l'entête et création des adresses
  */
  procedure ReinitializeHeader(
    aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vEdecCode        DOC_EDI_TYPE.C_EDI_METHOD%type      default null;
    vSqlCmd          varchar2(32000);
    lv_packageName   varchar2(50);
    ln_EdiTypeId     doc_edi_type.doc_edi_type_id%type;
    lv_exp_method    varchar2(50);
    lv_exportMethods varchar2(32000);
    lv_errorMsg      varchar2(32000);
    lv_exportVersion varchar2(50);
  begin
    vEdecCode  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecCode(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);

    if vEdecCode is not null then
      /* ============================================================
         procédure ReinitializeHeader, cascade de recherche

         1) variable "EDI" GENERATE_PACKAGE.REINITIALIZE_HEADER
         2) commande sql DOC_EDEC_HEADER/E100/ReinitializeHeader ou
            commande sql DOC_EDEC_HEADER/E101/ReinitializeHeader
         3) procédure standard
      */
      lv_exportMethods  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecExportMethods(aHeaderID => aHeaderID);

      select DET.DOC_EDI_TYPE_ID
           , MTH.EXP_METHOD
        into ln_EdiTypeId
           , lv_exp_method
        from DOC_EDI_TYPE DET
           , (select distinct column_value exp_method
                         from table(PCS.CHARLISTTOTABLE(lv_exportMethods, ';') ) ) MTH
       where MTH.EXP_METHOD is not null
         and MTH.EXP_METHOD = DET.DET_NAME
         and DET.C_EDI_METHOD in('E100', 'E101')
         and DET.PC_EXCHANGE_SYSTEM_ID is not null;

      lv_packageName    := doc_edi_function.getparamvalue('GENERATE_PACKAGE.REINITIALIZEHEADER', ln_EdiTypeID);
      lv_exportVersion  := upper(doc_edi_function.getparamvalue('EXPORT_PACKAGE.VERSION', ln_EdiTypeID) );

      if lv_packageName is not null then
        /* ============================================================
          1) variable "EDI" GENERATE_PACKAGE.REINITIALIZE_HEADER
        */
        begin
          execute immediate 'begin ' || lv_packageName || '.REINITIALIZEHEADER(:in_DocEdecHeaderId, :in_DocDocumentId, :in_DocPackingList);' || ' end;'
                      using in aHeaderID, in aDocumentID, in aPackingListID;
        exception
          when others then
            lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0001');
            lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
            lv_errorMsg  := replace(lv_errorMsg, '%p2', 'GENERATE_PACKAGE.REINITIALIZEHEADER');
            lv_errorMsg  := replace(lv_errorMsg, '%p3', lv_packageName || '.REINITIALIZEHEADER');
            lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
            lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
            pcs.ra(substr(lv_errorMsg, 1, 4000) );
        end;
      else
        /* ============================================================
          2) commande sql DOC_EDEC_HEADER/E100/ReinitializeHeader ou
             commande sql DOC_EDEC_HEADER/E101/ReinitializeHeader
        */
        vSqlCmd  := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_EDEC_HEADER', aGroup => vEdecCode, aSqlId => 'ReinitializeHeader', aHeader => false);
        vSqlCmd  := RemoveCompanyOwner(vSqlCmd);

        if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 0 then
          begin
            execute immediate vSqlCmd
                        using in aHeaderID, in aDocumentID, in aPackingListID;
          exception
            when others then
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0004');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', 'DOC_EDEC_HEADER/' || vEdecCode || '/ReinitializeHeader. ');
              lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
              lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
          end;
        else
          if vEdecCode = 'E100' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'ETRANS_V1') then
              DOC_EDI_EDEC_ETRANS_V1.ReinitializeHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'ETRANS_V1_1') then
              DOC_EDI_EDEC_ETRANS_V1_1.ReinitializeHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              begin
                lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
                lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
                lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
                lv_errorMsg  := replace(lv_errorMsg, '%p3', 'ETRANS_V1,ETRANS_V1_1');
                pcs.ra(substr(lv_errorMsg, 1, 4000) );
              end;
            end if;
          elsif vEdecCode = 'E101' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'EXPOWIN_V4') then
              DOC_EDI_EDEC_EXPOWIN_V4.ReinitializeHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'EXPOWIN_V405') then
              DOC_EDI_EDEC_EXPOWIN_V405.ReinitializeHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              begin
                lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
                lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
                lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
                lv_errorMsg  := replace(lv_errorMsg, '%p3', 'EXPOWIN_V4,EXPOWIN_V405');
                pcs.ra(substr(lv_errorMsg, 1, 4000) );
              end;
            end if;
          end if;
        end if;
      end if;
    end if;
  end ReinitializeHeader;

  /**
  * procedure DischargeHeader
  * Description
  *   Décharge de l'entête de la déclaration (création de l'entête et des adresses)
  */
  procedure DischargeHeader(
    aHeaderID      in out DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in     DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
  begin
    -- Si l'id a été passé en param, vérifier que le row existe
    if aHeaderID is not null then
      select max(DOC_EDEC_HEADER_ID)
        into aHeaderID
        from DOC_EDEC_HEADER
       where DOC_EDEC_HEADER_ID = aHeaderID;
    end if;

    -- L'entête EDEC n'existe pas, création de l'entête EDEC
    if aHeaderID is null then
      DOC_EDEC_FUNCTIONS.GenerateHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
    else
      -- Màj des données de l'entête et création des adresses
      DOC_EDEC_FUNCTIONS.ReinitializeHeader(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
    end if;
  end DischargeHeader;

  /**
  * procedure DischargePositions
  * Description
  *    Création des positions EDEC par décharge d'un document (DOC_DOCUMENT) ou
  *      par décharge des positions liées à un envoi (DOC_PACKING_LIST)
  */
  procedure DischargePositions(
    aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type default null
  )
  is
    vEdecCode        DOC_EDI_TYPE.C_EDI_METHOD%type      default null;
    vSqlCmd          varchar2(32000);
    lv_packageName   varchar2(50);
    ln_EdiTypeId     doc_edi_type.doc_edi_type_id%type;
    lv_exp_method    varchar2(50);
    lv_exportMethods varchar2(32000);
    lv_errorMsg      varchar2(32000);
    lv_exportVersion varchar2(50);
  begin
    vEdecCode  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecCode(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);

    if vEdecCode is not null then
      /* ============================================================
         procédure DischargePositions, cascade de recherche

         1) variable "EDI" GENERATE_PACKAGE.DISCHARGE_POSITIONS
         2) commande sql DOC_EDEC_HEADER/E100/DischargePositions ou
            commande sql DOC_EDEC_HEADER/E101/DischargePositions
         3) procédure standard
      */
      lv_exportMethods  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecExportMethods(aDocumentID => aDocumentID, aPackingListID => aPackingListID);

      select DET.DOC_EDI_TYPE_ID
           , MTH.EXP_METHOD
        into ln_EdiTypeId
           , lv_exp_method
        from DOC_EDI_TYPE DET
           , (select distinct column_value exp_method
                         from table(PCS.CHARLISTTOTABLE(lv_exportMethods, ';') ) ) MTH
       where MTH.EXP_METHOD is not null
         and MTH.EXP_METHOD = DET.DET_NAME
         and DET.C_EDI_METHOD in('E100', 'E101')
         and DET.PC_EXCHANGE_SYSTEM_ID is not null;

      lv_packageName    := doc_edi_function.getparamvalue('GENERATE_PACKAGE.DISCHARGEPOSITIONS', ln_EdiTypeID);
      lv_exportVersion  := upper(doc_edi_function.getparamvalue('EXPORT_PACKAGE.VERSION', ln_EdiTypeID) );

      if lv_packageName is not null then
        /* ============================================================
          1) variable "EDI" GENERATE_PACKAGE.DISCHARGE_POSITIONS
        */
        begin
          execute immediate 'begin ' || lv_packageName || '.DISCHARGEPOSITIONS(:in_DocEdecHeaderId, :in_DocDocumentId, :in_DocPackingList);' || ' end;'
                      using in aHeaderID, in aDocumentID, in aPackingListID;
        exception
          when others then
            lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0001');
            lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
            lv_errorMsg  := replace(lv_errorMsg, '%p2', 'GENERATE_PACKAGE.DISCHARGEPOSITIONS');
            lv_errorMsg  := replace(lv_errorMsg, '%p3', lv_packageName || '.DISCHARGEPOSITIONS');
            lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
            lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
            pcs.ra(substr(lv_errorMsg, 1, 4000) );
        end;
      else
        /* ============================================================
          2) commande sql DOC_EDEC_HEADER/E100/DischargePositions ou
             commande sql DOC_EDEC_HEADER/E101/DischargePositions
        */
        vSqlCmd  := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_EDEC_POSITION', aGroup => vEdecCode, aSqlId => 'DischargePositions', aHeader => false);
        vSqlCmd  := RemoveCompanyOwner(vSqlCmd);

        if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 0 then
          begin
            execute immediate vSqlCmd
                        using in aHeaderID, in aDocumentID, in aPackingListID;
          exception
            when others then
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0004');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', 'DOC_EDEC_POSITION/' || vEdecCode || '/DischargePositions. ');
              lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
              lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
          end;
        else
          if vEdecCode = 'E100' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'ETRANS_V1') then
              DOC_EDI_EDEC_ETRANS_V1.DischargePositions(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'ETRANS_V1_1') then
              DOC_EDI_EDEC_ETRANS_V1_1.DischargePositions(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
              lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
              lv_errorMsg  := replace(lv_errorMsg, '%p3', 'ETRANS_V1,ETRANS_V1_1');
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
            end if;
          elsif vEdecCode = 'E101' then
            if    (lv_exportVersion is null)
               or (lv_exportVersion = 'EXPOWIN_V4') then
              DOC_EDI_EDEC_EXPOWIN_V4.DischargePositions(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            elsif(lv_exportVersion = 'EXPOWIN_V405') then
              DOC_EDI_EDEC_EXPOWIN_V405.DischargePositions(aHeaderID => aHeaderID, aDocumentID => aDocumentID, aPackingListID => aPackingListID);
            else
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
              lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
              lv_errorMsg  := replace(lv_errorMsg, '%p3', 'EXPOWIN_V4,EXPOWIN_V405');
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
            end if;
          end if;
        end if;
      end if;
    end if;
  end DischargePositions;

/******************************************************************************/
/************************  PUBLIC  ********************************************/
/******************************************************************************/

  /**
  * procedure EdecProtect
  * Description
  *    Gestion des protections sur les déclaration EDEC
  */
  procedure EdecProtect(iHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, iProtect in integer default 1, ioSession in out string)
  is
  begin
    if     (iProtect = 1)
       and ioSession is null then
      select DBMS_SESSION.unique_session_id
        into ioSession
        from dual;
    end if;

    update DOC_EDEC_HEADER
       set DEH_PROTECTED = iProtect
         , DEH_SESSION_ID = ioSession
     where DOC_EDEC_HEADER_ID = iHeaderID;
  end EdecProtect;

  /**
  * procedure EdecProtectAutoCommit
  * Description
  *    Gestion des protections sur les déclaration EDEC en transaction autonome. Impose l'assignation d'une session unique provenant
  *    de la session Oracle appelant.
  */
  procedure EdecProtectAutoCommit(iHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, iProtect in integer default 1, ioSession in out string)
  is
    pragma autonomous_transaction;
  begin
    if     (iProtect = 1)
       and ioSession is null then
      PCS.ra(pcs.pc_functions.translateword('Numéro unique de session Oracle requis !') );
    end if;

    EdecProtect(iHeaderID, iProtect, ioSession);
    commit;   -- Indispensable en transaction autonome
  end EdecProtectAutoCommit;

  /**
  * procedure ExportEdec
  * Description
  *    Export d'une interface EDEC
  */
  procedure ExportEdec(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
    vExportList      varchar2(4000)  default null;
    lv_ExpErrorMsg   varchar2(250);
    lv_ErrorMsg      varchar2(32000);
    lv_exportVersion varchar2(50);
  begin
    -- Récuperer les méthodes d'export du client de livraison et du client de facturation
    vExportList  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecExportMethods(aHeaderID => aHeaderID);

    -- Balayer la liste des méthodes qui sont de type EDEC -> "E100" ou "E101"
    for tplMethod in (select DET.DOC_EDI_TYPE_ID
                           , DET.C_EDI_METHOD
                           , MTH.EXP_METHOD
                        from DOC_EDI_TYPE DET
                           , (select distinct column_value exp_method
                                         from table(PCS.CHARLISTTOTABLE(vExportList, ';') ) ) MTH
                       where MTH.EXP_METHOD is not null
                         and MTH.EXP_METHOD = DET.DET_NAME
                         and DET.C_EDI_METHOD in('E100', 'E101')
                         and DET.PC_EXCHANGE_SYSTEM_ID is not null) loop
      lv_exportVersion  := upper(doc_edi_function.getparamvalue('EXPORT_PACKAGE.VERSION', tplMethod.DOC_EDI_TYPE_ID) );

      -- Création de l'export EDEC ETrans
      if tplMethod.C_EDI_METHOD = 'E100' then
        if    (lv_exportVersion is null)
           or (lv_exportVersion = 'ETRANS_V1') then
          DOC_EDI_EDEC_ETRANS_V1.GenerateExport(aEdecHeaderID => aHeaderID, aEdiTypeID => tplMethod.DOC_EDI_TYPE_ID, aErrorMsg => lv_ExpErrorMsg);
        elsif(lv_exportVersion = 'ETRANS_V1_1') then
          DOC_EDI_EDEC_ETRANS_V1_1.GenerateExport(aEdecHeaderID => aHeaderID, aEdiTypeID => tplMethod.DOC_EDI_TYPE_ID, aErrorMsg => lv_ExpErrorMsg);
        else
          begin
            lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
            lv_errorMsg  := replace(lv_errorMsg, '%p1', tplMethod.exp_method);
            lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
            lv_errorMsg  := replace(lv_errorMsg, '%p3', 'ETRANS_V1,ETRANS_V1_1');
            pcs.ra(substr(lv_errorMsg, 1, 4000) );
          end;
        end if;
      -- Création de l'export EDEC ExpoWin
      elsif tplMethod.C_EDI_METHOD = 'E101' then
        if    (lv_exportVersion is null)
           or (lv_exportVersion = 'EXPOWIN_V4') then
          DOC_EDI_EDEC_EXPOWIN_V4.GenerateExport(aEdecHeaderID => aHeaderID, aEdiTypeID => tplMethod.DOC_EDI_TYPE_ID, aErrorMsg => lv_ExpErrorMsg);
        elsif(lv_exportVersion = 'EXPOWIN_V405') then
          DOC_EDI_EDEC_EXPOWIN_V405.GenerateExport(aEdecHeaderID => aHeaderID, aEdiTypeID => tplMethod.DOC_EDI_TYPE_ID, aErrorMsg => lv_ExpErrorMsg);
        else
          lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0002');
          lv_errorMsg  := replace(lv_errorMsg, '%p1', tplMethod.exp_method);
          lv_errorMsg  := replace(lv_errorMsg, '%p2', 'EXPORT_PACKAGE.VERSION');
          lv_errorMsg  := replace(lv_errorMsg, '%p3', 'EXPOWIN_V4,EXPOWIN_V405');
          pcs.ra(substr(lv_errorMsg, 1, 4000) );
        end if;
      end if;

      -- Arreter le traitement si erreur durant l'export
      if lv_ExpErrorMsg is not null then
        PCS.RA(lv_ExpErrorMsg);
      end if;
    end loop;

    -- mise à jour du statut de la déclaration : "Exportée"
    if lv_ExpErrorMsg is null then
      update DOC_EDEC_HEADER
         set C_EDEC_STATUS = '99'
       where DOC_EDEC_HEADER_ID = aHeaderID;
    end if;
  end ExportEdec;

  /**
  * procedure RenewEdec
  * Description
  *    Régénération d'une interface EDEC
  */
  procedure RenewEdec(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type)
  is
    vDOC_DOCUMENT_ID     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vDOC_PACKING_LIST_ID DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type;
  begin
    select DOC_DOCUMENT_ID
         , DOC_PACKING_LIST_ID
      into vDOC_DOCUMENT_ID
         , vDOC_PACKING_LIST_ID
      from DOC_EDEC_HEADER
     where DOC_EDEC_HEADER_ID = aHeaderID;

    if    (vDOC_DOCUMENT_ID is not null)
       or (vDOC_PACKING_LIST_ID is not null) then
      -- Efface toutes les positions de la table DOC_EDEC_POSITION ainsi que ses enfants
      DOC_EDEC_UTILITY_FUNCTIONS.DeleteEdecPos(aHeaderID);

      -- Décharge
      if (vDOC_DOCUMENT_ID is not null) then
        DischargeDocument(aDocumentID => vDOC_DOCUMENT_ID, aHeaderID => aHeaderID);
      elsif(vDOC_PACKING_LIST_ID is not null) then
        DischargePackingList(aPackingListID => vDOC_PACKING_LIST_ID, aHeaderID => aHeaderID);
      end if;
    end if;
  end RenewEdec;

  /**
  * procedure DischargeDocument
  * Description
  *    Création de la déclaration EDEC par décharge d'un document (DOC_DOCUMENT)
  */
  procedure DischargeDocument(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type default null)
  is
    vHeaderID DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type;
  begin
    vHeaderID  := aHeaderID;
    -- Décharge de l'entête de la déclaration (création de l'entête et des adresses)
    DOC_EDEC_FUNCTIONS.DischargeHeader(aHeaderID => vHeaderID, aDocumentID => aDocumentID, aPackingListID => null);
    -- Décharge des positions (création des positions, détails et emballages )
    DOC_EDEC_FUNCTIONS.DischargePositions(aHeaderID => vHeaderID, aDocumentID => aDocumentID, aPackingListID => null);
  exception
    when others then
      DOC_EDEC_UTILITY_FUNCTIONS.CreateDischErrorLog(aID      => aDocumentID
                                                   , aError   => DBMS_UTILITY.format_error_stack || chr(10) || DBMS_UTILITY.format_error_backtrace
                                                    );
  end DischargeDocument;

  /**
  * procedure DischargePackingList
  * Description
  *    Création de la déclaration EDEC par décharge d'un envoi (DOC_PACKING_LIST)
  */
  procedure DischargePackingList(
    aPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type
  , aHeaderID      in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type default null
  )
  is
    vHeaderID DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type;
  begin
    vHeaderID  := aHeaderID;
    -- Décharge de l'entête de la déclaration (création de l'entête et des adresses)
    DOC_EDEC_FUNCTIONS.DischargeHeader(aHeaderID => vHeaderID, aDocumentID => null, aPackingListID => aPackingListID);
    -- Décharge des positions (création des positions, détails et emballages )
    DOC_EDEC_FUNCTIONS.DischargePositions(aHeaderID => vHeaderID, aDocumentID => null, aPackingListID => aPackingListID);
  exception
    when others then
      DOC_EDEC_UTILITY_FUNCTIONS.CreateDischErrorLog(aID      => aPackingListID
                                                   , aError   => DBMS_UTILITY.format_error_stack || chr(10) || DBMS_UTILITY.format_error_backtrace
                                                    );
  end DischargePackingList;

  /**
  * procedure DoControlEdec
  * Description
  *    Contrôle d'une interface EDEC
  */
  procedure DoControlEdec(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aErrorMsg out varchar2)
  is
    vEdecCode        DOC_EDI_TYPE.C_EDI_METHOD%type      default null;
    vSqlCmd          varchar2(32000);
    lv_packageName   varchar2(50);
    ln_EdiTypeId     doc_edi_type.doc_edi_type_id%type;
    lv_exp_method    varchar2(50);
    lv_exportMethods varchar2(32000);
    lv_errorMsg      varchar2(32000);
    lv_exportVersion varchar2(50);
  begin
    aErrorMsg  := null;
    vEdecCode  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecCode(aHeaderID => aHeaderID);

    if vEdecCode is not null then
      /* ============================================================
         procédure generate_header, cascade de recherche

         1) variable "EDI" GENERATE_PACKAGE.CONTROL_EDEC
         2) commande sql DOC_EDEC_HEADER/E100/ControlEdec ou
            commande sql DOC_EDEC_HEADER/E101/ControlEdec
         3) procédure standard
      */
      lv_exportMethods  := DOC_EDEC_UTILITY_FUNCTIONS.GetEdecExportMethods(aHeaderID => aHeaderID);

      select DET.DOC_EDI_TYPE_ID
           , MTH.EXP_METHOD
        into ln_EdiTypeId
           , lv_exp_method
        from DOC_EDI_TYPE DET
           , (select distinct column_value exp_method
                         from table(PCS.CHARLISTTOTABLE(lv_exportMethods, ';') ) ) MTH
       where MTH.EXP_METHOD is not null
         and MTH.EXP_METHOD = DET.DET_NAME
         and DET.C_EDI_METHOD in('E100', 'E101')
         and DET.PC_EXCHANGE_SYSTEM_ID is not null;

      lv_packageName    := doc_edi_function.getparamvalue('GENERATE_PACKAGE.CONTROLEDEC', ln_EdiTypeID);

      if lv_packageName is not null then
        /* ============================================================
          1) variable "EDI" GENERATE_PACKAGE.GENERATE_HEADER
        */
        begin
          execute immediate 'begin ' || lv_packageName || '.CONTROLEDEC(:in_DocEdecHeaderId, :ov_errMsg);' || ' end;'
                      using in aHeaderID, out aErrorMsg;
        exception
          when others then
            lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0001');
            lv_errorMsg  := replace(lv_errorMsg, '%p1', lv_exp_method);
            lv_errorMsg  := replace(lv_errorMsg, '%p2', 'GENERATE_PACKAGE.CONTROLEDEC');
            lv_errorMsg  := replace(lv_errorMsg, '%p3', lv_packageName || '.CONTROLEDEC');
            lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
            lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
            pcs.ra(substr(lv_errorMsg, 1, 4000) );
        end;
      else
        /* ============================================================
          2) commande sql DOC_EDEC_HEADER/E100/ControlEdec ou
             commande sql DOC_EDEC_HEADER/E101/ControlEdec
        */
        vSqlCmd  := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_EDEC_HEADER', aGroup => vEdecCode, aSqlId => 'ControlEdec', aHeader => false);
        vSqlCmd  := RemoveCompanyOwner(vSqlCmd);

        if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 0 then
          begin
            -- Appel du contrôle indiv
            execute immediate vSqlCmd
                        using in aHeaderID, out aErrorMsg;
          exception
            when others then
              lv_errorMsg  := PCS.PC_FUNCTIONS.TranslateWord('EDEC-0004');
              lv_errorMsg  := replace(lv_errorMsg, '%p1', 'DOC_EDEC_HEADER/' || vEdecCode || '/ControlEdec. ');
              lv_errorMsg  := lv_errorMsg || chr(10) || PCS.PC_FUNCTIONS.TranslateWord('EDEC-0003') || ': ';
              lv_errorMsg  := lv_errorMsg || DBMS_UTILITY.format_error_backtrace;
              pcs.ra(substr(lv_errorMsg, 1, 4000) );
          end;
        else
          -- Appel du contrôle standard
          ControlEdec(aHeaderID => aHeaderID, aErrorMsg => aErrorMsg);
        end if;
      end if;
    end if;
  end DoControlEdec;

  /**
  * procedure ControlEdecStandard
  * Description
  *    Contrôle d'une interface EDEC
  */
  procedure ControlEdec(aHeaderID in DOC_EDEC_HEADER.DOC_EDEC_HEADER_ID%type, aErrorMsg out varchar2)
  is
    vCount        integer;
    vHeaderNumber DOC_EDEC_HEADER.DEH_TRADER_DECLARATION_NUMBER%type;
  begin
    aErrorMsg  := null;

    --  Vérifie si toutes les positions d'une interface E-EDEC ont le champ DEP_STATISTICAL_VALUE renseigné
    select count(*)
      into vCount
      from DOC_EDEC_POSITION
     where DOC_EDEC_HEADER_ID = aHeaderID
       and DEP_STATISTICAL_VALUE = 0;

    if vCount > 0 then
      -- Recherche le n° de la déclaration pour pouvoir l'afficher dans le msg d'erreur
      select DEH_TRADER_DECLARATION_NUMBER
        into vHeaderNumber
        from DOC_EDEC_HEADER
       where DOC_EDEC_HEADER_ID = aHeaderID;

      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Le numéro de déclaration %s contient des positions dont la valeur statistique est égale à zéro.');
      aErrorMsg  := replace(aErrorMsg, '%s', vHeaderNumber);
    end if;
  end ControlEdec;
end DOC_EDEC_FUNCTIONS;
