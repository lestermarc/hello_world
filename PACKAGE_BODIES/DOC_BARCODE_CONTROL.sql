--------------------------------------------------------
--  DDL for Package Body DOC_BARCODE_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_BARCODE_CONTROL" 
is
  /**
  * Description
  *   Contrôle des données pour un enregistrement DOC_BARCODE
  *   retourne le code erreur trouvé
  */
  function ControlBarCodeRecord(
    aDOC_BARCODE_ID               in TTypeID
  , aDOC_BARCODE_HEADER_ID        in TTypeID
  , aDOC_POSITION_DETAIL_ID       in TTypeID
  , aDOC_POSITION_ID              in TTypeID
  , aGCO_GOOD_ID                  in TTypeID
  , aGCO_GCO_GOOD_ID              in TTypeID
  , aSTM_LOCATION_ID              in TTypeID
  , aGCO_CHARACTERIZATION_ID      in TTypeID
  , aGCO2_CHARACTERIZATION_ID     in TTypeID
  , aGCO3_CHARACTERIZATION_ID     in TTypeID
  , aGCO4_CHARACTERIZATION_ID     in TTypeID
  , aGCO5_CHARACTERIZATION_ID     in TTypeID
  , aDBA_CHARACTERIZATION_VALUE_1 in TTypeChara
  , aDBA_CHARACTERIZATION_VALUE_2 in TTypeChara
  , aDBA_CHARACTERIZATION_VALUE_3 in TTypeChara
  , aDBA_CHARACTERIZATION_VALUE_4 in TTypeChara
  , aDBA_CHARACTERIZATION_VALUE_5 in TTypeChara
  , aDBA_QUANTITY                 in TTypeQty
  )
    return TTypeError
  is
    -- Déclaration de la variable pour le stockage du code erreur
    BARCODE_ERROR TTypeError;

    -- Contrôle sur l'existance du doc position détail
    function DocPosDetailFound
      return boolean
    is
      DocPosDetailCount integer;
    begin
      select count(1)
        into DocPosDetailCount
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID;

      return(DocPosDetailCount = 1);
    exception
      when no_data_found then
        return false;
    end DocPosDetailFound;

    -- Recherche le domain courant
    function GetAdminDomain(aPositionDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
      return DOC_GAUGE.C_ADMIN_DOMAIN%type
    is
      cAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
    begin
      select GAU.C_ADMIN_DOMAIN
        into cAdminDomain
        from DOC_POSITION_DETAIL PDE
           , DOC_GAUGE GAU
       where PDE.DOC_POSITION_DETAIL_ID = aPositionDetailID
         and GAU.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID;

      return trim(cAdminDomain);
    exception
      when no_data_found then
        return '';
    end GetAdminDomain;

    -- Contrôle sur le statut "à solder" ou "soldé partiellement" de la position
    function PosBalanceIsOK
      return boolean
    is
      DocPosStatus DOC_POSITION.C_DOC_POS_STATUS%type;
    begin
      select C_DOC_POS_STATUS
        into DocPosStatus
        from DOC_POSITION
       where DOC_POSITION_ID = aDOC_POSITION_ID;

      return(    (DocPosStatus = '02')
             or (DocPosStatus = '03') );
    exception
      when no_data_found then
        return false;
    end PosBalanceIsOK;

    -- Détermination de la quantité W (somme des qtés saisies pour les DOC_BARCODE similaire à celui en cours)
    function GetQuantityW
      return TTypeQty
    is
      QuantityW TTypeQty;
      StkNumber number;
    begin
      if aGCO_CHARACTERIZATION_ID is not null then
        select decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0)
          into StkNumber
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;

        -- Si la caractérisation est en gestion de stock
        if StkNumber = 1 then
          select sum(DBA_QUANTITY)
            into QuantityW
            from DOC_BARCODE
           where DOC_BARCODE_ID <> aDOC_BARCODE_ID
             and DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
             and DOC_BARCODE_HEADER_ID = aDOC_BARCODE_HEADER_ID
             and GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID
             and (   GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
                  or aGCO_CHARACTERIZATION_ID is null
                  or aGCO_CHARACTERIZATION_ID = 0)
             and (   DBA_CHARACTERIZATION_VALUE_1 = aDBA_CHARACTERIZATION_VALUE_1
                  or aDBA_CHARACTERIZATION_VALUE_1 is null
                  or aDBA_CHARACTERIZATION_VALUE_1 = '');
        else
          select sum(DBA_QUANTITY)
            into QuantityW
            from DOC_BARCODE
           where DOC_BARCODE_ID <> aDOC_BARCODE_ID
             and DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
             and DOC_BARCODE_HEADER_ID = aDOC_BARCODE_HEADER_ID
             and GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;
      else
        select sum(DBA_QUANTITY)
          into QuantityW
          from DOC_BARCODE
         where DOC_BARCODE_ID <> aDOC_BARCODE_ID
           and DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
           and DOC_BARCODE_HEADER_ID = aDOC_BARCODE_HEADER_ID
           and GCO_GOOD_ID = aGCO_GOOD_ID
           and STM_LOCATION_ID = aSTM_LOCATION_ID;
      end if;

      if QuantityW is null then
        QuantityW  := 0;
      end if;

      return(QuantityW + aDBA_QUANTITY);
    exception
      when no_data_found then
        return aDBA_QUANTITY;
    end GetQuantityW;

    -- Détermination de la quantité X (qté solde de la doc position détail)
    function GetQuantityX
      return TTypeQty
    is
      QuantityX TTypeQty;
    begin
      select PDE_BALANCE_QUANTITY
        into QuantityX
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID;

      if QuantityX is null then
        QuantityX  := 0;
      end if;

      return QuantityX;
    exception
      when no_data_found then
        return 0;
    end GetQuantityX;

    -- Détermination de la quantité Y (somme des qtés saisies pour les DOC_BARCODE similaire à la doc position détail en cours)
    function GetQuantityY
      return TTypeQty
    is
      QuantityY TTypeQty;
    begin
      select sum(DBA_QUANTITY)
        into QuantityY
        from DOC_BARCODE
       where DOC_BARCODE_ID <> aDOC_BARCODE_ID
         and DOC_BARCODE_HEADER_ID = aDOC_BARCODE_HEADER_ID
         and DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID;

      if QuantityY is null then
        QuantityY  := 0;
      end if;

      return(QuantityY + aDBA_QUANTITY);
    exception
      when no_data_found then
        return aDBA_QUANTITY;
    end GetQuantityY;

    -- Détermination de la quantité Z (disponibilité de la position de stock concernée)
    function GetQuantityZ
      return TTypeQty
    is
      QuantityZ TTypeQty;
      StkNumber number;
    begin
      if aGCO_CHARACTERIZATION_ID is not null then
        select decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0)
          into StkNumber
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID;

        -- Si la caractérisation est en gestion de stock
        if StkNumber = 1 then
          select nvl(sum(SPO_AVAILABLE_QUANTITY + SPO_ASSIGN_QUANTITY), 0)
            into QuantityZ
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID
             and (   GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
                  or aGCO_CHARACTERIZATION_ID is null
                  or aGCO_CHARACTERIZATION_ID = 0)
             and (   SPO_CHARACTERIZATION_VALUE_1 = aDBA_CHARACTERIZATION_VALUE_1
                  or aDBA_CHARACTERIZATION_VALUE_1 is null
                  or aDBA_CHARACTERIZATION_VALUE_1 = '');
        else
          select nvl(sum(SPO_AVAILABLE_QUANTITY + SPO_ASSIGN_QUANTITY), 0)
            into QuantityZ
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;
      else
        select nvl(sum(SPO_AVAILABLE_QUANTITY + SPO_ASSIGN_QUANTITY), 0)
          into QuantityZ
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGCO_GOOD_ID
           and STM_LOCATION_ID = aSTM_LOCATION_ID;
      end if;

      if QuantityZ is null then
        QuantityZ  := 0;
      end if;

      return QuantityZ;
    exception
      when no_data_found then
        return 0;
    end GetQuantityZ;

    -- Produit géré en stock ou pas
    function stkMgt
      return number
    is
      vResult GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    begin
      begin
        select PDT_STOCK_MANAGEMENT
          into vResult
          from GCO_PRODUCT
         where GCO_GOOD_ID = aGCO_GOOD_ID;
      exception
        when no_data_found then
          return 0;
      end;

      return vResult;
    end stkMgt;
  begin
    -- Gestion de l'erreur 1
      -- Contrôle sur l'existance du doc position détail
    if not DocPosDetailFound then
      -- Erreur Code 1
      BARCODE_ERROR  := '1';
    -- Gestion de l'erreur 2
    -- Contrôle sur le statut "à solder" ou "soldé partiellement" de la position
    elsif not PosBalanceIsOK then
      -- Erreur Code 2
      BARCODE_ERROR  := '2';
      -- Gestion de l'erreur 3
    -- Contrôle sur l'existance du produit
    elsif aGCO_GOOD_ID is null then
      -- Erreur Code 3
      BARCODE_ERROR  := '3';
    -- Gestion de l'erreur 4
    -- Contrôle sur la saisie de la caractérisation
    elsif    (     (aDBA_CHARACTERIZATION_VALUE_1 is null)
              and (aGCO_CHARACTERIZATION_ID is not null) )
          or (     (aDBA_CHARACTERIZATION_VALUE_2 is null)
              and (aGCO2_CHARACTERIZATION_ID is not null) )
          or (     (aDBA_CHARACTERIZATION_VALUE_3 is null)
              and (aGCO3_CHARACTERIZATION_ID is not null) )
          or (     (aDBA_CHARACTERIZATION_VALUE_4 is null)
              and (aGCO4_CHARACTERIZATION_ID is not null) )
          or (     (aDBA_CHARACTERIZATION_VALUE_5 is null)
              and (aGCO5_CHARACTERIZATION_ID is not null) ) then
      -- Erreur Code 4
      BARCODE_ERROR  := '4';
    -- Gestion de l'erreur 5
    -- Contrôle sur la cohérence du stock informatique et celui physique (pour les produits gérés en stock)
    elsif     StkMgt = '1'
          and (GetQuantityZ < GetQuantityW)
          and GetAdminDomain(aDOC_POSITION_DETAIL_ID) <> '1' then
      -- Erreur Code 5
      BARCODE_ERROR  := '5';
    -- Gestion de l'erreur 6
    -- Contrôle sur la correspondance du bien saisie et du bien commandé
    elsif(aGCO_GOOD_ID <> aGCO_GCO_GOOD_ID) then
      -- Erreur Code 6
      BARCODE_ERROR  := '6';
    -- Gestion de l'erreur 7
    -- Contrôle sur la redondance d'une séquence de saisie
    elsif(GetQuantityY > GetQuantityX) then
      -- Erreur Code 7
      BARCODE_ERROR  := '7';
    else
      -- Sinon, tous les contrôles ont été négatifs
      BARCODE_ERROR  := null;
    end if;

    -- Retourne le code erreur trouvé
    return BARCODE_ERROR;
  end ControlBarCodeRecord;

  /**
  * function ControlBarCodeRecord
  * Description
  *   Contrôle des données pour une ligne de DOC_BARCODE
  *   retourne le code erreur trouvé
  *   (version simplifiée)
  * @created fp 22.08.2006
  * @lastUpdate
  * @public
  * @param aDOC_BARCODE_ID
  */
  function ControlBarCodeRecord(aDOC_BARCODE_ID in TTypeID)
    return TTypeError
  is
  begin
    for tplBarcodeInfos in (select *
                              from DOC_BARCODE
                             where DOC_BARCODE_ID = aDOC_BARCODE_ID) loop
      return ControlBarCodeRecord(tplBarCodeInfos.DOC_BARCODE_ID
                                , tplBarCodeInfos.DOC_BARCODE_HEADER_ID
                                , tplBarCodeInfos.DOC_POSITION_DETAIL_ID
                                , tplBarCodeInfos.DOC_POSITION_ID
                                , tplBarCodeInfos.GCO_GOOD_ID
                                , tplBarCodeInfos.GCO_GCO_GOOD_ID
                                , tplBarCodeInfos.STM_LOCATION_ID
                                , tplBarCodeInfos.GCO_CHARACTERIZATION_ID
                                , tplBarCodeInfos.GCO_GCO_CHARACTERIZATION_ID
                                , tplBarCodeInfos.GCO2_GCO_CHARACTERIZATION_ID
                                , tplBarCodeInfos.GCO3_GCO_CHARACTERIZATION_ID
                                , tplBarCodeInfos.GCO4_GCO_CHARACTERIZATION_ID
                                , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_1
                                , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_2
                                , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_3
                                , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_4
                                , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_5
                                , tplBarCodeInfos.DBA_QUANTITY
                                 );
    end loop;
  end ControlBarCodeRecord;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Contrôle des données pour tous les enregistrements de la table DOC_BARCODE
  procedure ControlBarCodeTable(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type)
  is
    -- Curseur sur la table DOC_BARCODE
    cursor crBarCodeInfos(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type)
    is
      select     DOC_BARCODE_ID
               , DOC_BARCODE_HEADER_ID
               , DOC_POSITION_DETAIL_ID
               , DOC_POSITION_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , STM_LOCATION_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , DBA_CHARACTERIZATION_VALUE_1
               , DBA_CHARACTERIZATION_VALUE_2
               , DBA_CHARACTERIZATION_VALUE_3
               , DBA_CHARACTERIZATION_VALUE_4
               , DBA_CHARACTERIZATION_VALUE_5
               , DBA_QUANTITY
               , DBA_ACCEPT
            from DOC_BARCODE
           where DOC_BARCODE_HEADER_ID = aHeaderId
             and C_DOC_BARCODE_STATUS <> '99'
      for update;

    -- Enregistrement de la table DOC_BARCODE
    tplBarCodeInfos crBarCodeInfos%rowtype;
    -- Variable de récupération du code d'erreur
    BarCodeError    TTypeError;
    vAccept         DOC_BARCODE.DBA_ACCEPT%type;
  begin
    -- S'assurer qu'il y ai un enregistrement ...
    for tplBarCodeInfos in crBarCodeInfos(aHeaderId) loop
      -- Récupération du code d'erreur
      BarCodeError  :=
        ControlBarCodeRecord(tplBarCodeInfos.DOC_BARCODE_ID
                           , tplBarCodeInfos.DOC_BARCODE_HEADER_ID
                           , tplBarCodeInfos.DOC_POSITION_DETAIL_ID
                           , tplBarCodeInfos.DOC_POSITION_ID
                           , tplBarCodeInfos.GCO_GOOD_ID
                           , tplBarCodeInfos.GCO_GCO_GOOD_ID
                           , tplBarCodeInfos.STM_LOCATION_ID
                           , tplBarCodeInfos.GCO_CHARACTERIZATION_ID
                           , tplBarCodeInfos.GCO_GCO_CHARACTERIZATION_ID
                           , tplBarCodeInfos.GCO2_GCO_CHARACTERIZATION_ID
                           , tplBarCodeInfos.GCO3_GCO_CHARACTERIZATION_ID
                           , tplBarCodeInfos.GCO4_GCO_CHARACTERIZATION_ID
                           , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_1
                           , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_2
                           , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_3
                           , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_4
                           , tplBarCodeInfos.DBA_CHARACTERIZATION_VALUE_5
                           , tplBarCodeInfos.DBA_QUANTITY
                            );

      if BarCodeError not in('6', '7') then
        vAccept  := 0;
      else
        vAccept  := tplBarCodeInfos.DBA_ACCEPT;
      end if;

      -- MAJ du code erreur de l'enregistrement en cours
      update DOC_BARCODE
         set C_BARCODE_ERROR = decode(vAccept, 1, null, BarCodeError)
           , DBA_ACCEPT = vAccept
           , C_DOC_BARCODE_STATUS = decode(BarCodeError, null, '30', decode(vAccept, 1, '30', '20') )
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_BARCODE_ID = tplBarCodeInfos.DOC_BARCODE_ID;
    end loop;

    updateHeaderStatus(aHeaderId);
  end ControlBarCodeTable;

  /**
  * Description
  *    création de l'entête d'une importation barcode
  */
  procedure createBarcodeHeader(aDescription DOC_BARCODE_HEADER.DBH_DESCRIPTION%type, aHeaderId out DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type)
  is
  begin
    select INIT_ID_SEQ.nextval
      into aHeaderId
      from dual;

    insert into DOC_BARCODE_HEADER
                (DOC_BARCODE_HEADER_ID
               , PC_USER_ID
               , C_DOC_BARCODE_HEADER_STATUS
               , DBH_DESCRIPTION
               , A_DATECRE
               , A_IDCRE
                )
         values (aHeaderId
               , PCS.PC_I_LIB_SESSION.GetUserId
               , '10'
               , aDescription || '_' || PCS.PC_I_LIB_SESSION.getUserIni || '_' || to_char(sysdate, 'YYYYMMDDHH24MISS')
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end createBarcodeHeader;

  /**
  * procedure updateBarcodeHeaderArchive
  * Description
  *    Mise à jour du nom du fichier archive
  * @created fp 25.04.2006
  * @lastUpdate
  * @public
  * @param aHeaderId : Id de l'entête
  * @param aFileName : nom du fichier d'archive
  */
  procedure updateBarcodeHeaderArchive(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type, aFileName DOC_BARCODE_HEADER.DBH_ARCHIVE_FILENAME%type)
  is
  begin
    update DOC_BARCODE_HEADER
       set DBH_ARCHIVE_FILENAME = aFileName
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where DOC_BARCODE_HEADER_ID = aHeaderId;
  end updateBarcodeHeaderArchive;

  /**
  * Description
  *    création d'une ligne d'importation
  */
  procedure createBarcodeLine(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type, aLine DOC_BARCODE.DBA_IMPORTED_LINE%type)
  is
  begin
    insert into DOC_BARCODE
                (DOC_BARCODE_ID
               , DOC_BARCODE_HEADER_ID
               , C_DOC_BARCODE_STATUS
               , DBA_IMPORTED_LINE
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , aHeaderId
               , '10'   -- IMPORTED
               , aLine
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end createBarcodeLine;

  /**
  * Description
  *    exemple de procedure d'extraction des champs
  */
  procedure documentValidationSample(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type)
  is
  begin
    --raise_application_error(-20000,ExtractLine(DBA_IMPORTED_LINE, 2, ';')||'/'||ExtractLine(DBA_IMPORTED_LINE, 3, ';')||'/'||ExtractLine(DBA_IMPORTED_LINE, 4, ';')||'/'||ExtractLine(DBA_IMPORTED_LINE, 5, ';')||'/'||ExtractLine(DBA_IMPORTED_LINE, 6, ';'));
    update DOC_BARCODE
       set DOC_POSITION_DETAIL_ID = to_number(substr(ExtractLine(DBA_IMPORTED_LINE, 2, ';'), 2) )
         , DBA_INPUT_MAJOR_REFERENCE = CleanStr(substr(ExtractLine(DBA_IMPORTED_LINE, 3, ';'), 2) )
         , GCO_GOOD_ID = (select GCO_GOOD_ID
                            from GCO_GOOD
                           where GOO_MAJOR_REFERENCE = CleanStr(substr(ExtractLine(DBA_IMPORTED_LINE, 3, ';'), 2) ) )
         , DBA_CHARACTERIZATION_VALUE_1 = CleanStr(substr(ExtractLine(DBA_IMPORTED_LINE, 4, ';'), 2) )
         , DBA_QUANTITY = to_number(CleanStr(ExtractLine(DBA_IMPORTED_LINE, 5, ';') ) )
         , A_DATECRE = to_date(trim(ExtractLine(DBA_IMPORTED_LINE, 6, ';') ), 'DD/MM/YYYY HH24:MI')
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where DOC_BARCODE_HEADER_ID = aHeaderId;
  end documentValidationSample;

  /**
  * procedure documentValidation
  * Description
  *    appel dynamique de la procedure de validation
  * @created fp 10.05.2006
  * @lastUpdate
  * @public
  * @param aHeaderId : id de la ligne à décoder
  * @param aProcName : nom de la procedure de validation
  * @return true si exécution OK
  */
  function documentValidation(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type, aProcName PCS.PC_IMPORT_DATA.IMD_CONTROL_FILE%type)
    return boolean
  is
    vSqlCommand varchar2(200);
  begin
    vSqlCommand  := 'BEGIN ' || aProcName || '(:aHeaderId);' || ' END;';

    execute immediate vSqlCommand
                using aHeaderId;

    return true;
  exception
    when others then
      raise_application_error(-20000
                            , 'PCS - error in validation : ' || aProcName || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                             );
  end documentValidation;

  /**
  * Description
  *    décodage de l'importation complète
  */
  procedure decodeBarcode(
    aBarcodeId         DOC_BARCODE.DOC_BARCODE_ID%type
  , aProcName          PCS.PC_IMPORT_DATA.IMD_CONTROL_FILE%type
  , aBarcodeStatus out DOC_BARCODE.C_DOC_BARCODE_STATUS%type
  )
  is
    -- Récupération de toutes les informations selon un DOC_POSITION_DETAIL_ID
    -- dans les tables : DOC_POSITION_DETAIL, DOC_POSITION et DOC_DOCUMENT
    cursor crDocInfosRecord(aDocPosDetailID in TTypeID)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , POS.DOC_POSITION_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_NUMBER
           , DMT.DOC_GAUGE_ID
           , DMT.PAC_THIRD_ID
           , POS.POS_NUMBER
           , POS.DOC_RECORD_ID
           , POS.PAC_REPRESENTATIVE_ID
           , PDE.STM_LOCATION_ID
           , POS.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , PDE.PDE_BASIS_DELAY
           , PDE.PDE_BASIS_DELAY_W
           , PDE.PDE_BASIS_DELAY_M
           , PDE.PDE_INTERMEDIATE_DELAY
           , PDE.PDE_INTERMEDIATE_DELAY_W
           , PDE.PDE_INTERMEDIATE_DELAY_M
           , PDE.PDE_FINAL_DELAY
           , PDE.PDE_FINAL_DELAY_W
           , PDE.PDE_FINAL_DELAY_M
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , GCO_GOOD GOO
       where PDE.DOC_POSITION_DETAIL_ID = aDocPosDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID;

    vHeaderStatus DOC_BARCODE_HEADER.C_DOC_BARCODE_HEADER_STATUS%type   default '30';
  begin
    for tplDOC_BARCODE in (select *
                             from DOC_BARCODE
                            where DOC_BARCODE_ID = aBarcodeId) loop
      declare
        -- Record de toutes les informations selon un DOC_POSITION_DETAIL_ID
        tplDocInfosRecord crDocInfosRecord%rowtype;
      begin
        -- Ouverture du curseur sur toutes les informations selon un DOC_POSITION_DETAIL_ID
        for tplDocInfosRecord in crDocInfosRecord(tplDOC_BARCODE.DOC_POSITION_DETAIL_ID) loop
          -- Date de modification
          tplDOC_BARCODE.A_DATEMOD                  := sysdate;
          -- Utilisateur
          tplDOC_BARCODE.A_IDMOD                    := PCS.PC_I_LIB_SESSION.GetUserIni;
          -- ID position
          tplDOC_BARCODE.DOC_POSITION_ID            := tplDocInfosRecord.DOC_POSITION_ID;
          -- ID document
          tplDOC_BARCODE.DOC_DOCUMENT_ID            := tplDocInfosRecord.DOC_DOCUMENT_ID;
          -- N° document
          tplDOC_BARCODE.DBA_DMT_NUMBER             := tplDocInfosRecord.DMT_NUMBER;
          -- ID gabarit document source
          tplDOC_BARCODE.DOC_GAUGE_ID               := tplDocInfosRecord.DOC_GAUGE_ID;
          -- ID partenaire
          tplDOC_BARCODE.PAC_THIRD_ID               := tplDocInfosRecord.PAC_THIRD_ID;
          -- N° position
          tplDOC_BARCODE.DBA_POS_NUMBER             := tplDocInfosRecord.POS_NUMBER;
          -- ID dossier
          tplDOC_BARCODE.DOC_RECORD_ID              := tplDocInfosRecord.DOC_RECORD_ID;
          -- ID représentant
          tplDOC_BARCODE.PAC_REPRESENTATIVE_ID      := tplDocInfosRecord.PAC_REPRESENTATIVE_ID;

          -- ID emplacement
          if PCS.PC_CONFIG.GetConfig('DOC_BARCODE_INIT_STM_LOCATION') = '1' then
            tplDOC_BARCODE.STM_LOCATION_ID  := tplDocInfosRecord.STM_LOCATION_ID;
          end if;

          -- ID bien commandé
          tplDOC_BARCODE.GCO_GCO_GOOD_ID            := tplDocInfosRecord.GCO_GOOD_ID;
          -- Réf principale du bien commandé
          tplDOC_BARCODE.DBA_ORDER_MAJOR_REFERENCE  := tplDocInfosRecord.GOO_MAJOR_REFERENCE;
          -- Délai de base
          tplDOC_BARCODE.DBA_BASIS_DELAY            := tplDocInfosRecord.PDE_BASIS_DELAY;
          -- Délai intermédiaire
          tplDOC_BARCODE.DBA_INTERMEDIATE_DELAY     := tplDocInfosRecord.PDE_INTERMEDIATE_DELAY;
          -- Délai final
          tplDOC_BARCODE.DBA_FINAL_DELAY            := tplDocInfosRecord.PDE_FINAL_DELAY;
        end loop;

        select GCO_GOOD_ID
          into tplDOC_BARCODE.GCO_GOOD_ID
          from GCO_GOOD
         where GOO_MAJOR_REFERENCE = tplDOC_BARCODE.DBA_INPUT_MAJOR_REFERENCE;

        if tplDOC_BARCODE.GCO_CHARACTERIZATION_ID is null then
          -- recherche des infos sur les caractérisations
          declare
            vCharacType1 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
            vCharacType2 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
            vCharacType3 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
            vCharacType4 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
            vCharacType5 GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
            vCharacDesc1 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
            vCharacDesc2 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
            vCharacDesc3 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
            vCharacDesc4 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
            vCharacDesc5 GCO_DESC_LANGUAGE.DLA_DESCRIPTION%type;
          begin
            -- C'est le gabarit cible qui définit les caractérisation gérées et
            -- non le gabarit source. Mais comme la cible n'est pas encore connue
            -- on initialise tous les id de caractérisations
            GCO_FUNCTIONS.GetListOfStkChar(aGoodId        => tplDOC_BARCODE.GCO_GOOD_ID
                                         , aCharac1Id     => tplDOC_BARCODE.GCO_CHARACTERIZATION_ID
                                         , aCharac2Id     => tplDOC_BARCODE.GCO_GCO_CHARACTERIZATION_ID
                                         , aCharac3Id     => tplDOC_BARCODE.GCO2_GCO_CHARACTERIZATION_ID
                                         , aCharac4Id     => tplDOC_BARCODE.GCO3_GCO_CHARACTERIZATION_ID
                                         , aCharac5Id     => tplDOC_BARCODE.GCO4_GCO_CHARACTERIZATION_ID
                                         , aCharacType1   => vCharacType1
                                         , aCharacType2   => vCharacType2
                                         , aCharacType3   => vCharacType3
                                         , aCharacType4   => vCharacType4
                                         , aCharacType5   => vCharacType5
                                         , aCharacDesc1   => vCharacDesc1
                                         , aCharacDesc2   => vCharacDesc2
                                         , aCharacDesc3   => vCharacDesc3
                                         , aCharacDesc4   => vCharacDesc4
                                         , aCharacDesc5   => vCharacDesc5
                                          );
          end;
        end if;

        -- Contrôle des données pour l'enregistrement DOC_BARCODE en cours
        tplDOC_BARCODE.C_BARCODE_ERROR  :=
          ControlBarCodeRecord(tplDOC_BARCODE.DOC_BARCODE_ID
                             , tplDOC_BARCODE.DOC_BARCODE_HEADER_ID
                             , tplDOC_BARCODE.DOC_POSITION_DETAIL_ID
                             , tplDOC_BARCODE.DOC_POSITION_ID
                             , tplDOC_BARCODE.GCO_GOOD_ID
                             , tplDOC_BARCODE.GCO_GCO_GOOD_ID
                             , tplDOC_BARCODE.STM_LOCATION_ID
                             , tplDOC_BARCODE.GCO_CHARACTERIZATION_ID
                             , tplDOC_BARCODE.GCO_GCO_CHARACTERIZATION_ID
                             , tplDOC_BARCODE.GCO2_GCO_CHARACTERIZATION_ID
                             , tplDOC_BARCODE.GCO3_GCO_CHARACTERIZATION_ID
                             , tplDOC_BARCODE.GCO4_GCO_CHARACTERIZATION_ID
                             , tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1
                             , tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_2
                             , tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_3
                             , tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_4
                             , tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_5
                             , tplDOC_BARCODE.DBA_QUANTITY
                              );

        if tplDOC_BARCODE.C_BARCODE_ERROR is not null then
          aBarcodeStatus                       := '20';   -- Verified with errors
          tplDOC_BARCODE.C_DOC_BARCODE_STATUS  := '20';   -- Verified with errors
        else
          aBarcodeStatus                       := '30';   -- Verified
          tplDOC_BARCODE.C_DOC_BARCODE_STATUS  := '30';   -- Verified
        end if;

        -- mise à jour de la ligne courante
        update DOC_BARCODE
           set DOC_DOCUMENT_ID = tplDOC_BARCODE.DOC_DOCUMENT_ID
             , DOC_POSITION_ID = tplDOC_BARCODE.DOC_POSITION_ID
             , DOC_POSITION_DETAIL_ID = tplDOC_BARCODE.DOC_POSITION_DETAIL_ID
             , DOC_RECORD_ID = tplDOC_BARCODE.DOC_RECORD_ID
             , GCO_CHARACTERIZATION_ID = tplDOC_BARCODE.GCO_CHARACTERIZATION_ID
             , GCO_GCO_CHARACTERIZATION_ID = tplDOC_BARCODE.GCO_GCO_CHARACTERIZATION_ID
             , GCO2_GCO_CHARACTERIZATION_ID = tplDOC_BARCODE.GCO2_GCO_CHARACTERIZATION_ID
             , GCO3_GCO_CHARACTERIZATION_ID = tplDOC_BARCODE.GCO3_GCO_CHARACTERIZATION_ID
             , GCO4_GCO_CHARACTERIZATION_ID = tplDOC_BARCODE.GCO4_GCO_CHARACTERIZATION_ID
             , PAC_THIRD_ID = tplDOC_BARCODE.PAC_THIRD_ID
             , PAC_REPRESENTATIVE_ID = tplDOC_BARCODE.PAC_REPRESENTATIVE_ID
             , GCO_GOOD_ID = tplDOC_BARCODE.GCO_GOOD_ID
             , DOC_GAUGE_ID = tplDOC_BARCODE.DOC_GAUGE_ID
             , DOC_DOC_GAUGE_ID = tplDOC_BARCODE.DOC_DOC_GAUGE_ID
             , GCO_GCO_GOOD_ID = tplDOC_BARCODE.GCO_GCO_GOOD_ID
             , STM_LOCATION_ID = tplDOC_BARCODE.STM_LOCATION_ID
             , C_BARCODE_ERROR = tplDOC_BARCODE.C_BARCODE_ERROR
             , C_DOC_BARCODE_STATUS = tplDOC_BARCODE.C_DOC_BARCODE_STATUS
             , DBA_ACCEPT = tplDOC_BARCODE.DBA_ACCEPT
             , DBA_BASIS_DELAY = tplDOC_BARCODE.DBA_BASIS_DELAY
             , DBA_FINAL_DELAY = tplDOC_BARCODE.DBA_FINAL_DELAY
             , DBA_INTERMEDIATE_DELAY = tplDOC_BARCODE.DBA_INTERMEDIATE_DELAY
             , DBA_POS_NUMBER = tplDOC_BARCODE.DBA_POS_NUMBER
             , DBA_DMT_NUMBER = tplDOC_BARCODE.DBA_DMT_NUMBER
             , DBA_QUANTITY = tplDOC_BARCODE.DBA_QUANTITY
             , DBA_ORDER_MAJOR_REFERENCE = tplDOC_BARCODE.DBA_ORDER_MAJOR_REFERENCE
             , DBA_INPUT_MAJOR_REFERENCE = tplDOC_BARCODE.DBA_INPUT_MAJOR_REFERENCE
             , DBA_CHARACTERIZATION_VALUE_1 = nvl2(tplDOC_BARCODE.GCO_CHARACTERIZATION_ID, tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_1, null)
             , DBA_CHARACTERIZATION_VALUE_2 = nvl2(tplDOC_BARCODE.GCO_GCO_CHARACTERIZATION_ID, tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_2, null)
             , DBA_CHARACTERIZATION_VALUE_3 = nvl2(tplDOC_BARCODE.GCO2_GCO_CHARACTERIZATION_ID, tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_3, null)
             , DBA_CHARACTERIZATION_VALUE_4 = nvl2(tplDOC_BARCODE.GCO3_GCO_CHARACTERIZATION_ID, tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_4, null)
             , DBA_CHARACTERIZATION_VALUE_5 = nvl2(tplDOC_BARCODE.GCO4_GCO_CHARACTERIZATION_ID, tplDOC_BARCODE.DBA_CHARACTERIZATION_VALUE_5, null)
             , DBA_INPUT_SECONDARY_REFERENCE = tplDOC_BARCODE.DBA_INPUT_SECONDARY_REFERENCE
             , A_DATEMOD = tplDOC_BARCODE.A_DATEMOD
             , A_IDMOD = tplDOC_BARCODE.A_IDMOD
         where DOC_BARCODE_ID = tplDOC_BARCODE.DOC_BARCODE_ID;
      end;
    end loop;
  end decodeBarcode;

  /**
  * Description
  *    décodage de l'importation complète
  */
  procedure decodeBarcodeHeader(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type, aProcName PCS.PC_IMPORT_DATA.IMD_CONTROL_FILE%type)
  is
    -- Récupération de toutes les informations selon un DOC_POSITION_DETAIL_ID
    -- dans les tables : DOC_POSITION_DETAIL, DOC_POSITION et DOC_DOCUMENT
    cursor crDocInfosRecord(aDocPosDetailID in TTypeID)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , POS.DOC_POSITION_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_NUMBER
           , DMT.DOC_GAUGE_ID
           , DMT.PAC_THIRD_ID
           , POS.POS_NUMBER
           , POS.DOC_RECORD_ID
           , POS.PAC_REPRESENTATIVE_ID
           , PDE.STM_LOCATION_ID
           , POS.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , PDE.PDE_BASIS_DELAY
           , PDE.PDE_BASIS_DELAY_W
           , PDE.PDE_BASIS_DELAY_M
           , PDE.PDE_INTERMEDIATE_DELAY
           , PDE.PDE_INTERMEDIATE_DELAY_W
           , PDE.PDE_INTERMEDIATE_DELAY_M
           , PDE.PDE_FINAL_DELAY
           , PDE.PDE_FINAL_DELAY_W
           , PDE.PDE_FINAL_DELAY_M
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , GCO_GOOD GOO
       where PDE.DOC_POSITION_DETAIL_ID = aDocPosDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID;

    vHeaderStatus DOC_BARCODE_HEADER.C_DOC_BARCODE_HEADER_STATUS%type   default '30';
  begin
    if documentValidation(aHeaderId, aProcName) then
      for tplDOC_BARCODE in (select DOC_BARCODE_ID
                               from DOC_BARCODE
                              where DOC_BARCODE_HEADER_ID = aHeaderId) loop
        decodeBarcode(tplDOC_BARCODE.DOC_BARCODE_ID, aProcName, vHeaderStatus);
      end loop;

      update DOC_BARCODE_HEADER
         set C_DOC_BARCODE_HEADER_STATUS = vHeaderStatus
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_BARCODE_HEADER_ID = aHeaderId;
    end if;
  end decodeBarcodeHeader;

  /**
  * Description
  *    mise à jour du status du header de l'importation barcode
  */
  procedure updateHeaderStatus(aHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type)
  is
    vNbImported   pls_integer;
    vNbError      pls_integer;
    vNbVerified   pls_integer;
    vNbGenerated  pls_integer;
    vNbDeleted    pls_integer;
    vNbTot        pls_integer;
    vHeaderStatus DOC_BARCODE_HEADER.C_DOC_BARCODE_HEADER_STATUS%type;
  begin
    select sum(decode(C_DOC_BARCODE_STATUS, '10', 1, 0) )
         , sum(decode(C_DOC_BARCODE_STATUS, '20', 1, 0) )
         , sum(decode(C_DOC_BARCODE_STATUS, '30', 1, 0) )
         , sum(decode(C_DOC_BARCODE_STATUS, '50', 1, 0) )
         , sum(decode(C_DOC_BARCODE_STATUS, '99', 1, 0) )
         , count(*)
      into vNbImported
         , vNbError
         , vNbVerified
         , vNbGenerated
         , vNbDeleted
         , vNbTot
      from DOC_BARCODE
     where DOC_BARCODE_HEADER_ID = aHeaderId;

    if vNbTot = vNbImported + vNbDeleted then
      vHeaderStatus  := '10';   -- importé
    elsif vNbError > 0 then
      vHeaderStatus  := '20';   -- vérifié avec erreur
    elsif vNbTot = vNbVerified + vNbDeleted then
      vHeaderStatus  := '30';   -- vérifié
    elsif vNbTot = vNbGenerated then
      vHeaderStatus  := '50';   -- vérifié
    elsif vNbTot = vNbGenerated + vNbDeleted then
      vHeaderStatus  := '40';   -- vérifié
    else
      vHeaderStatus  := '00';   -- vérifié
    end if;

    -- mise à jour selon la plus petite valeur des détails
    update DOC_BARCODE_HEADER MAIN
       set C_DOC_BARCODE_HEADER_STATUS = vHeaderStatus
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where DOC_BARCODE_HEADER_ID = aHeaderId;
  end updateHeaderStatus;

  /**
  * Description
  *    Effacement logique d'une ligne d'importation
  */
  procedure logicalBarcodeDelete(aBarcodeId DOC_BARCODE.DOC_BARCODE_ID%type)
  is
    vBarcodeHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type;
  begin
    update    DOC_BARCODE
          set C_DOC_BARCODE_STATUS = '99'
        where DOC_BARCODE_ID = aBarcodeId
    returning DOC_BARCODE_HEADER_ID
         into vBarcodeHeaderId;

    updateHeaderStatus(vBarcodeHeaderId);
  end logicalBarcodeDelete;

  /**
  * Description
  *    Réactive une ligne effacée logiquement
  */
  procedure reactiveBarcode(aBarcodeId DOC_BARCODE.DOC_BARCODE_ID%type)
  is
    vBarcodeHeaderId DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID%type;
  begin
    update    DOC_BARCODE
          set C_DOC_BARCODE_STATUS = '10'   --ControlBarCodeRecord(aBarcodeId)
        where DOC_BARCODE_ID = aBarcodeId
    returning DOC_BARCODE_HEADER_ID
         into vBarcodeHeaderId;

    updateHeaderStatus(vBarcodeHeaderId);
  end reactiveBarcode;

  /**
  * Description
  *    Réactive une ligne effacée logiquement
  */
  function canReactiveBarcode(aBarcodeId DOC_BARCODE.DOC_BARCODE_ID%type)
    return number
  is
    vBarcodeStatus       DOC_BARCODE.C_DOC_BARCODE_STATUS%type;
    vBarcodeHeaderStatus DOC_BARCODE_HEADER.C_DOC_BARCODE_HEADER_STATUS%type;
  begin
    select DOC_BARCODE.C_DOC_BARCODE_STATUS
         , DOC_BARCODE_HEADER.C_DOC_BARCODE_HEADER_STATUS
      into vBarcodeStatus
         , vBarcodeHeaderStatus
      from DOC_BARCODE
         , DOC_BARCODE_HEADER
     where DOC_BARCODE.DOC_BARCODE_HEADER_ID = DOC_BARCODE_HEADER.DOC_BARCODE_HEADER_ID
       and DOC_BARCODE.DOC_BARCODE_ID = aBarcodeId;

    if     vBarcodeStatus = '99'
       and vBarcodeHeaderStatus in('10', '20', '30') then
      return 1;
    else
      return 0;
    end if;
  end;
end DOC_BARCODE_CONTROL;
