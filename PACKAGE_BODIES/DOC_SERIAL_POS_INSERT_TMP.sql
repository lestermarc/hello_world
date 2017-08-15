--------------------------------------------------------
--  DDL for Package Body DOC_SERIAL_POS_INSERT_TMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_SERIAL_POS_INSERT_TMP" 
is
  /**
  *  Description
  *    Insere dans la table temp des position avec des délais pour les bien
  *    dont la réf principale correspond à la réf. passée en param
  */
  procedure InsertSerialPosWithDelay(iReference in varchar2, iDocumentID in number, iBasisDelay in date, iTypeDelay in varchar2)
  is
  begin
    InsertSerialPosWithoutDelay(iReference, iDocumentID);
    -- Màj des délais des positions de la table temp
    UpdateSerialPosDelay(iBasisDelay, iTypeDelay);
  end InsertSerialPosWithDelay;

  /**
  * function GetPositionLocation
  * Description
  *   Return stock location to initialize positons
  * @created fpe 28.08.2014
  * @updated
  * @public
  * @return
  */
  function GetPositionLocation(
    iGoodId              in DOC_POSITION.GCO_GOOD_ID%type
  , iThirdId             in DOC_DOCUMENT.PAC_THIRD_ID%type
  , iMvtKindId           in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , iAdminDomain         in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , iInitStockPlace      in DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type
  , iMvtUtility          in DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type
  , iTransfertProprietor in DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type
  )
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    lStockID                  DOC_POSITION.STM_STOCK_ID%type;
    lLocationID               DOC_POSITION.STM_LOCATION_ID%type;
    lTraStockID               DOC_POSITION.STM_STM_STOCK_ID%type;
    lTraLocationID            DOC_POSITION.STM_STM_LOCATION_ID%type;
    lCdaStockID               DOC_POSITION.STM_STOCK_ID%type;
    lCdaLocationID            DOC_POSITION.STM_LOCATION_ID%type;
    lCdaPosReference          DOC_POSITION.POS_REFERENCE%type;
    lCdaPosSecondaryReference DOC_POSITION.POS_SECONDARY_REFERENCE%type;
    lCdaPosShortDescription   DOC_POSITION.POS_SHORT_DESCRIPTION%type;
    lCdaPosLongDescription    DOC_POSITION.POS_LONG_DESCRIPTION%type;
    lCdaPosFreeDescription    DOC_POSITION.POS_FREE_DESCRIPTION%type;
    lCdaPosEANCode            DOC_POSITION.POS_EAN_CODE%type;
    lCdaPosEANUCC14Code       DOC_POSITION.POS_EAN_UCC14_CODE%type;
    lCdaPosHIBCPrimaryCode    DOC_POSITION.POS_HIBC_PRIMARY_CODE%type;
    lCdaDicUnitMeasure        DOC_POSITION.DIC_UNIT_OF_MEASURE_ID%type;
    lCdaPosConvertFactor      DOC_POSITION.POS_CONVERT_FACTOR%type;
    lCdaGooNumberDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lCdaQuantity              DOC_POSITION.POS_BASIS_QUANTITY%type;
  begin
    -- Recherche les infos des données compl. (stock, descriptions, ...)
    GCO_FUNCTIONS.GetComplementaryData(iGoodId
                                     , iAdminDomain
                                     , iThirdId
                                     , PCS.PC_I_LIB_SESSION.GetUserLangId
                                     , null
                                     , iTransfertProprietor
                                     , null   -- ComplDataID
                                     , lCdaStockID
                                     , lCdaLocationID
                                     , lCdaPosReference
                                     , lCdaPosSecondaryReference
                                     , lCdaPosShortDescription
                                     , lCdaPosLongDescription
                                     , lCdaPosFreeDescription
                                     , lCdaPosEANCode
                                     , lCdaPosEANUCC14Code
                                     , lCdaPosHIBCPrimaryCode
                                     , lCdaDicUnitMeasure
                                     , lCdaPosConvertFactor
                                     , lCdaGooNumberDecimal
                                     , lCdaQuantity
                                      );
    DOC_LIB_POSITION.getStockAndLocation(iGoodId   -- Bien
                                       , iThirdId
                                       , iMvtKindId   -- Genre de mouvement
                                       , iAdminDomain
                                       , lCdaStockId   -- Stock du bien (données complémentaires)
                                       , lCdaLocationId   -- Emplacement du bien (données complémentaires)
                                       , null   -- Stock parent
                                       , null   -- Emplacement parent
                                       , null   -- Stock cible parent
                                       , null   -- Emplacement cible parent
                                       , iInitStockPlace   -- Initialisation du stock et de l'emplacement
                                       , iMvtUtility   -- Utilisation du stock du genre de mouvement
                                       , 0   -- Transfert stock et emplacement depuis le parent
                                       , null   -- Sous-traitant permettant l'initialisation du stock source
                                       , null   -- Sous-traitant permettant l'initialisation du stock cible
                                       , lStockID   -- Stock recherché
                                       , lLocationID   -- Emplacement recherché
                                       , lTraStockID   -- Stock cible recherché
                                       , lTraLocationID   -- Emplacement cible recherché
                                        );
    return lLocationID;
  end GetPositionLocation;

  /**
  *  Description
  *    Insere dans la table temp des position sans les délais pour les bien
  *    dont la réf principale correspond à la réf. passée en param
  */
  procedure InsertSerialPosWithoutDelay(iReference in varchar2, iDocumentID in number)
  is
    lGaugeID             number;
    lAdminDomain         varchar2(10);
    lMvtSort             varchar2(10);
    lSearchCSAGapID      number;
    lGapID               number;
    lGoodThirdRestrict   signtype;   -- 1: Prendre les biens du partenaire uniquement; 0:tous les biens
    lPacThirdId          DOC_DOCUMENT.PAC_THIRD_ID%type;
    lMovementKindId      STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInitStockPlace      DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;
    lMvtUtility          DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    lTransfertProprietor DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type;
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a une référence dans le champs de la recherche
    -- Evite dans tous les cas un fullscan
    if ltrim(rtrim(iReference) ) is not null then
      -- Recherche l'ID du gabarit et le domaine du document et genre de mvt
      --  pour l'utiliser lors de la recherche du gabarit position
      select GAU.DOC_GAUGE_ID
           , GAU.C_ADMIN_DOMAIN
           , nvl(MOK.C_MOVEMENT_SORT, 'NULL')
           , GAS.GAS_GOOD_THIRD
           , DMT.PAC_THIRD_ID
           , GAP.STM_MOVEMENT_KIND_ID
           , GAP.GAP_INIT_STOCK_PLACE
           , GAP.GAP_MVT_UTILITY
           , GAP.GAP_TRANSFERT_PROPRIETOR
        into lGaugeID
           , lAdminDomain
           , lMvtSort
           , lGoodThirdRestrict
           , lPacThirdId
           , lMovementKindId
           , lInitStockPlace
           , lMvtUtility
           , lTransfertProprietor
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
           , STM_MOVEMENT_KIND MOK
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = '1'
         and GAP.GAP_DEFAULT = 1
         and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+);

      -- Faire la recherche de l'ID du gabarit position au niveau des données compl de vente
      -- Si domaine = 'Vente' et Genre de Mvt <> 'Sortie'
      if     (lAdminDomain = '2')
         and (lMvtSort <> 'SOR') then
        lSearchCSAGapID  := 1;
      else
        lSearchCSAGapID  := 0;
        lGapID           := DOC_SERIAL_POS_INSERT_TMP.GetDefaultGapID(lGaugeID);
      end if;

      -- Insertion dans la table temporaire
      if lGoodThirdRestrict = 0 then   -- recherche des biens sans restriction sur le partenaire
        insert into DOC_TMP_POSITION_DETAIL
                    (DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , DTP_SESSION_ID
                   , DOC_DOCUMENT_ID
                   , CRG_SELECT
                   , PDE_BASIS_QUANTITY
                   , GCO_GOOD_ID
                   , PPS_NOMENCLATURE_ID
                   , DOC_GAUGE_POSITION_ID
                   , CSA_GAP_TYPE_MANDATORY
                   , STM_LOCATION_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
               , INIT_ID_SEQ.currval DOC_POSITION_ID
               , SQL_CMD.*
            from (select   userenv('SESSIONID') DTP_SESSION_ID
                         , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                         , 0 CRG_SELECT
                         , 0.0 PDE_BASIS_QUANTITY
                         , GOO.GCO_GOOD_ID GCO_GOOD_ID
                         , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                         , decode(lSearchCSAGapID
                                , 0, lGapID
                                , DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID)
                                 ) DOC_GAUGE_POSITION_ID
                         , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                         , DOC_SERIAL_POS_INSERT_TMP.GetPositionLocation(GOO.GCO_GOOD_ID
                                                                       , DMT.PAC_THIRD_ID
                                                                       , lMovementKindId
                                                                       , lAdminDomain
                                                                       , lInitStockPlace
                                                                       , lMvtUtility
                                                                       , lTransfertProprietor
                                                                        )
                         , sysdate A_DATECRE
                         , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      from GCO_GOOD GOO
                         , DOC_DOCUMENT DMT
                     where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(iReference)
                       and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                       and DMT.DOC_DOCUMENT_ID = iDocumentID
                  order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
      else   -- recherche des biens des biens autorisés pour le partenaire
        insert into DOC_TMP_POSITION_DETAIL
                    (DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , DTP_SESSION_ID
                   , DOC_DOCUMENT_ID
                   , CRG_SELECT
                   , PDE_BASIS_QUANTITY
                   , GCO_GOOD_ID
                   , PPS_NOMENCLATURE_ID
                   , DOC_GAUGE_POSITION_ID
                   , CSA_GAP_TYPE_MANDATORY
                   , STM_LOCATION_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
               , INIT_ID_SEQ.currval DOC_POSITION_ID
               , SQL_CMD.*
            from (select   userenv('SESSIONID') DTP_SESSION_ID
                         , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                         , 0 CRG_SELECT
                         , 0.0 PDE_BASIS_QUANTITY
                         , GOO.GCO_GOOD_ID GCO_GOOD_ID
                         , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                         , decode(lSearchCSAGapID
                                , 0, lGapID
                                , DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID)
                                 ) DOC_GAUGE_POSITION_ID
                         , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                         , DOC_SERIAL_POS_INSERT_TMP.GetPositionLocation(GOO.GCO_GOOD_ID
                                                                       , DMT.PAC_THIRD_ID
                                                                       , lMovementKindId
                                                                       , lAdminDomain
                                                                       , lInitStockPlace
                                                                       , lMvtUtility
                                                                       , lTransfertProprietor
                                                                        )
                         , sysdate A_DATECRE
                         , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      from GCO_GOOD GOO
                         , DOC_DOCUMENT DMT
                     where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(iReference)
                       and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                       and (    ( (select 1
                                     from GCO_COMPL_DATA_PURCHASE DAT
                                        , DOC_GAUGE GAU
                                    where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                      and DAT.PAC_SUPPLIER_PARTNER_ID = lPacThirdId
                                      and GAU.DOC_GAUGE_ID = lGaugeID
                                      and GAU.C_ADMIN_DOMAIN = '1') > 0
                                )
                            or ( (select 1
                                    from GCO_COMPL_DATA_SALE DAT
                                       , DOC_GAUGE GAU
                                   where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                     and DAT.PAC_CUSTOM_PARTNER_ID = lPacThirdId
                                     and GAU.DOC_GAUGE_ID = lGaugeID
                                     and GAU.C_ADMIN_DOMAIN = '2') > 0
                               )
                           )
                       and DMT.DOC_DOCUMENT_ID = iDocumentID
                  order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
      end if;
    end if;
  end InsertSerialPosWithoutDelay;

  /**
  *  Description
  *    Insere dans la table temp des position avec les biens passés dans la liste
  */
  procedure InsertSerialPosByGoodList(iGoodList in varchar2, iDocumentID in number, iBasisDelay in date, iTypeDelay in varchar2)
  is
    lGaugeID             number;
    lAdminDomain         varchar2(10);
    lMvtSort             varchar2(10);
    lSearchCSAGapID      number;
    lGapID               number;
    iForward             number;
    lGoodThirdRestrict   signtype;   -- 1: Prendre les biens du partenaire uniquement; 0:tous les biens
    lPacThirdId          DOC_DOCUMENT.PAC_THIRD_ID%type;
    lMovementKindId      STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInitStockPlace      DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;
    lMvtUtility          DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    lTransfertProprietor DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type;
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Recherche l'ID du gabarit et le domaine du document et genre de mvt
    --  pour l'utiliser lors de la recherche du gabarit position
    select GAU.DOC_GAUGE_ID
         , GAU.C_ADMIN_DOMAIN
         , nvl(MOK.C_MOVEMENT_SORT, 'NULL')
         , GAS.GAS_GOOD_THIRD
         , DMT.PAC_THIRD_ID
         , GAP.STM_MOVEMENT_KIND_ID
         , GAP.GAP_INIT_STOCK_PLACE
         , GAP.GAP_MVT_UTILITY
         , GAP.GAP_TRANSFERT_PROPRIETOR
      into lGaugeID
         , lAdminDomain
         , lMvtSort
         , lGoodThirdRestrict
         , lPacThirdId
         , lMovementKindId
         , lInitStockPlace
         , lMvtUtility
         , lTransfertProprietor
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
         , DOC_GAUGE_POSITION GAP
         , DOC_GAUGE_STRUCTURED GAS
         , STM_MOVEMENT_KIND MOK
     where DMT.DOC_DOCUMENT_ID = iDocumentID
       and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
       and GAP.C_GAUGE_TYPE_POS = '1'
       and GAP.GAP_DEFAULT = 1
       and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+);

    -- Faire la recherche de l'ID du gabarit position au niveau des données compl de vente
    -- Si domaine = 'Vente' et Genre de Mvt <> 'Sortie'
    if     (lAdminDomain = '2')
       and (lMvtSort <> 'SOR') then
      lSearchCSAGapID  := 1;
    else
      lSearchCSAGapID  := 0;
      lGapID           := DOC_SERIAL_POS_INSERT_TMP.GetDefaultGapID(lGaugeID);
    end if;

    -- Insertion dans la table temporaire
    if lGoodThirdRestrict = 0 then   -- recherche des biens sans restriction sur le partenaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , 0.0 PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                       , decode(lSearchCSAGapID, 0, lGapID, DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                          DOC_GAUGE_POSITION_ID
                       , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                       , DOC_SERIAL_POS_INSERT_TMP.GetPositionLocation(GOO.GCO_GOOD_ID
                                                                     , DMT.PAC_THIRD_ID
                                                                     , lMovementKindId
                                                                     , lAdminDomain
                                                                     , lInitStockPlace
                                                                     , lMvtUtility
                                                                     , lTransfertProprietor
                                                                      )
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                    from GCO_GOOD GOO
                       , DOC_DOCUMENT DMT
                   where instr(iGoodList, ',' || GOO.GCO_GOOD_ID || ',') > 0
                     and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                     and DMT.DOC_DOCUMENT_ID = iDocumentID
                order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    else   -- recherche des biens autorisés pour le partenaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , 0.0 PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                       , decode(lSearchCSAGapID, 0, lGapID, DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                          DOC_GAUGE_POSITION_ID
                       , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                       , DOC_SERIAL_POS_INSERT_TMP.GetPositionLocation(GOO.GCO_GOOD_ID
                                                                     , DMT.PAC_THIRD_ID
                                                                     , lMovementKindId
                                                                     , lAdminDomain
                                                                     , lInitStockPlace
                                                                     , lMvtUtility
                                                                     , lTransfertProprietor
                                                                      )
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                    from GCO_GOOD GOO
                       , DOC_DOCUMENT DMT
                   where instr(iGoodList, ',' || GOO.GCO_GOOD_ID || ',') > 0
                     and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                     and (    ( (select 1
                                   from GCO_COMPL_DATA_PURCHASE DAT
                                      , DOC_GAUGE GAU
                                  where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                    and DAT.PAC_SUPPLIER_PARTNER_ID = lPacThirdId
                                    and GAU.DOC_GAUGE_ID = lGaugeID
                                    and GAU.C_ADMIN_DOMAIN = '1') > 0
                              )
                          or ( (select 1
                                  from GCO_COMPL_DATA_SALE DAT
                                     , DOC_GAUGE GAU
                                 where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                   and DAT.PAC_CUSTOM_PARTNER_ID = lPacThirdId
                                   and GAU.DOC_GAUGE_ID = lGaugeID
                                   and GAU.C_ADMIN_DOMAIN = '2') > 0
                             )
                         )
                     and DMT.DOC_DOCUMENT_ID = iDocumentID
                order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    end if;

    -- Màj des délais des positions de la table temp
    UpdateSerialPosDelay(iBasisDelay, iTypeDelay);
  end InsertSerialPosByGoodList;

  /**
  *  Description
  *    Insere dans la table temp des position avec des délais pour les bien
  *    dont la réf principale correspond à la réf. passée en param
  *    avec la qté qui est disponnible en stock
  */
  procedure InsertSerialPosAvailableQty(iReference in varchar2, iDocumentID in number, iBasisDelay in date, iTypeDelay in varchar2)
  is
    lGaugeID           number;
    lAdminDomain       varchar2(10);
    lMvtSort           varchar2(10);
    lSearchCSAGapID    number;
    lGapID             number;
    iForward           number;
    lGoodThirdRestrict signtype;   -- 1: Prendre les biens du partenaire uniquement; 0:tous les biens
    lPacThirdId        DOC_DOCUMENT.PAC_THIRD_ID%type;
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a une référence dans le champs de la recherche
    -- Evite dans tous les cas un fullscan
    if ltrim(rtrim(iReference) ) is not null then
      -- Recherche l'ID du gabarit et le domaine du document et genre de mvt
      --  pour l'utiliser lors de la recherche du gabarit position
      select GAU.DOC_GAUGE_ID
           , GAU.C_ADMIN_DOMAIN
           , nvl(MOK.C_MOVEMENT_SORT, 'NULL')
           , GAS.GAS_GOOD_THIRD
           , DMT.PAC_THIRD_ID
        into lGaugeID
           , lAdminDomain
           , lMvtSort
           , lGoodThirdRestrict
           , lPacThirdId
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
           , STM_MOVEMENT_KIND MOK
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = '1'
         and GAP.GAP_DEFAULT = 1
         and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+);

      -- Faire la recherche de l'ID du gabarit position au niveau des données compl de vente
      -- Si domaine = 'Vente' et Genre de Mvt <> 'Sortie'
      if     (lAdminDomain = '2')
         and (lMvtSort <> 'SOR') then
        lSearchCSAGapID  := 1;
      else
        lSearchCSAGapID  := 0;
        lGapID           := DOC_SERIAL_POS_INSERT_TMP.GetDefaultGapID(lGaugeID);
      end if;

      -- Insertion dans la table temporaire
      if lGoodThirdRestrict = 0 then   -- recherche des biens sans restriction sur le partenaire
        insert into DOC_TMP_POSITION_DETAIL
                    (DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , DTP_SESSION_ID
                   , DOC_DOCUMENT_ID
                   , CRG_SELECT
                   , PDE_BASIS_QUANTITY
                   , PDE_BASIS_QUANTITY_SU
                   , GCO_GOOD_ID
                   , PPS_NOMENCLATURE_ID
                   , DOC_GAUGE_POSITION_ID
                   , CSA_GAP_TYPE_MANDATORY
                   , STM_LOCATION_ID
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , PDE_CHARACTERIZATION_VALUE_1
                   , PDE_CHARACTERIZATION_VALUE_2
                   , PDE_CHARACTERIZATION_VALUE_3
                   , PDE_CHARACTERIZATION_VALUE_4
                   , PDE_CHARACTERIZATION_VALUE_5
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
               , INIT_ID_SEQ.currval DOC_POSITION_ID
               , SQL_CMD.*
            from (select   userenv('SESSIONID') DTP_SESSION_ID
                         , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                         , 0 CRG_SELECT
                         , null PDE_BASIS_QUANTITY
                         , SPO.SPO_AVAILABLE_QUANTITY PDE_BASIS_QUANTITY_SU
                         , GOO.GCO_GOOD_ID GCO_GOOD_ID
                         , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                         , decode(lSearchCSAGapID
                                , 0, lGapID
                                , DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID)
                                 ) DOC_GAUGE_POSITION_ID
                         , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                         , SPO.STM_LOCATION_ID STM_LOCATION_ID
                         , SPO.GCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION_ID
                         , SPO.GCO_GCO_CHARACTERIZATION_ID GCO_GCO_CHARACTERIZATION_ID
                         , SPO.GCO2_GCO_CHARACTERIZATION_ID GCO2_GCO_CHARACTERIZATION_ID
                         , SPO.GCO3_GCO_CHARACTERIZATION_ID GCO3_GCO_CHARACTERIZATION_ID
                         , SPO.GCO4_GCO_CHARACTERIZATION_ID GCO4_GCO_CHARACTERIZATION_ID
                         , SPO.SPO_CHARACTERIZATION_VALUE_1 PDE_CHARACTERIZATION_VALUE_1
                         , SPO.SPO_CHARACTERIZATION_VALUE_2 PDE_CHARACTERIZATION_VALUE_2
                         , SPO.SPO_CHARACTERIZATION_VALUE_3 PDE_CHARACTERIZATION_VALUE_3
                         , SPO.SPO_CHARACTERIZATION_VALUE_4 PDE_CHARACTERIZATION_VALUE_4
                         , SPO.SPO_CHARACTERIZATION_VALUE_5 PDE_CHARACTERIZATION_VALUE_5
                         , sysdate A_DATECRE
                         , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      from GCO_GOOD GOO
                         , GCO_PRODUCT PDT
                         , DOC_DOCUMENT DMT
                         , STM_STOCK_POSITION SPO
                         , STM_STOCK STO
                         , STM_LOCATION LOC
                     where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(iReference)
                       and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                       and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                       and DMT.DOC_DOCUMENT_ID = iDocumentID
                       and SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                       and SPO.STM_STOCK_ID = STO.STM_STOCK_ID
                       and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
                       and SPO.SPO_AVAILABLE_QUANTITY > 0
                  order by GOO.GOO_MAJOR_REFERENCE
                         , STO.STO_CLASSIFICATION
                         , LOC.LOC_CLASSIFICATION) SQL_CMD;
      else   -- recherche des biens autorisés pour le partenaire
        insert into DOC_TMP_POSITION_DETAIL
                    (DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , DTP_SESSION_ID
                   , DOC_DOCUMENT_ID
                   , CRG_SELECT
                   , PDE_BASIS_QUANTITY
                   , PDE_BASIS_QUANTITY_SU
                   , GCO_GOOD_ID
                   , PPS_NOMENCLATURE_ID
                   , DOC_GAUGE_POSITION_ID
                   , CSA_GAP_TYPE_MANDATORY
                   , STM_LOCATION_ID
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , PDE_CHARACTERIZATION_VALUE_1
                   , PDE_CHARACTERIZATION_VALUE_2
                   , PDE_CHARACTERIZATION_VALUE_3
                   , PDE_CHARACTERIZATION_VALUE_4
                   , PDE_CHARACTERIZATION_VALUE_5
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
               , INIT_ID_SEQ.currval DOC_POSITION_ID
               , SQL_CMD.*
            from (select   userenv('SESSIONID') DTP_SESSION_ID
                         , DMT.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
                         , 0 CRG_SELECT
                         , null PDE_BASIS_QUANTITY
                         , SPO.SPO_AVAILABLE_QUANTITY PDE_BASIS_QUANTITY_SU
                         , GOO.GCO_GOOD_ID GCO_GOOD_ID
                         , DOC_POSITION_FUNCTIONS.GetInitialNomenclature(GOO.GCO_GOOD_ID) PPS_NOMENCLATURE_ID
                         , decode(lSearchCSAGapID
                                , 0, lGapID
                                , DOC_SERIAL_POS_INSERT_TMP.GetComplDataSaleGapID(GOO.GCO_GOOD_ID, lGaugeID, DMT.PAC_THIRD_CDA_ID)
                                 ) DOC_GAUGE_POSITION_ID
                         , decode(lSearchCSAGapID, 0, null, DOC_SERIAL_POS_INSERT_TMP.GetCSAGaugeMandatoryType(GOO.GCO_GOOD_ID, DMT.PAC_THIRD_CDA_ID) )
                                                                                                                                         CSA_GAP_TYPE_MANDATORY
                         , SPO.STM_LOCATION_ID STM_LOCATION_ID
                         , SPO.GCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION_ID
                         , SPO.GCO_GCO_CHARACTERIZATION_ID GCO_GCO_CHARACTERIZATION_ID
                         , SPO.GCO2_GCO_CHARACTERIZATION_ID GCO2_GCO_CHARACTERIZATION_ID
                         , SPO.GCO3_GCO_CHARACTERIZATION_ID GCO3_GCO_CHARACTERIZATION_ID
                         , SPO.GCO4_GCO_CHARACTERIZATION_ID GCO4_GCO_CHARACTERIZATION_ID
                         , SPO.SPO_CHARACTERIZATION_VALUE_1 PDE_CHARACTERIZATION_VALUE_1
                         , SPO.SPO_CHARACTERIZATION_VALUE_2 PDE_CHARACTERIZATION_VALUE_2
                         , SPO.SPO_CHARACTERIZATION_VALUE_3 PDE_CHARACTERIZATION_VALUE_3
                         , SPO.SPO_CHARACTERIZATION_VALUE_4 PDE_CHARACTERIZATION_VALUE_4
                         , SPO.SPO_CHARACTERIZATION_VALUE_5 PDE_CHARACTERIZATION_VALUE_5
                         , sysdate A_DATECRE
                         , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      from GCO_GOOD GOO
                         , GCO_PRODUCT PDT
                         , DOC_DOCUMENT DMT
                         , STM_STOCK_POSITION SPO
                         , STM_STOCK STO
                         , STM_LOCATION LOC
                     where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(iReference)
                       and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                       and (    ( (select 1
                                     from GCO_COMPL_DATA_PURCHASE DAT
                                        , DOC_GAUGE GAU
                                    where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                      and DAT.PAC_SUPPLIER_PARTNER_ID = lPacThirdId
                                      and GAU.DOC_GAUGE_ID = lGaugeID
                                      and GAU.C_ADMIN_DOMAIN = '1') > 0
                                )
                            or ( (select 1
                                    from GCO_COMPL_DATA_SALE DAT
                                       , DOC_GAUGE GAU
                                   where GOO.GCO_GOOD_ID = DAT.GCO_GOOD_ID
                                     and DAT.PAC_CUSTOM_PARTNER_ID = lPacThirdId
                                     and GAU.DOC_GAUGE_ID = lGaugeID
                                     and GAU.C_ADMIN_DOMAIN = '2') > 0
                               )
                           )
                       and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                       and DMT.DOC_DOCUMENT_ID = iDocumentID
                       and SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                       and SPO.STM_STOCK_ID = STO.STM_STOCK_ID
                       and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
                       and SPO.SPO_AVAILABLE_QUANTITY > 0
                  order by GOO.GOO_MAJOR_REFERENCE
                         , STO.STO_CLASSIFICATION
                         , LOC.LOC_CLASSIFICATION) SQL_CMD;
      end if;

      -- Màj des délais des positions de la table temp
      UpdateSerialPosDelay(iBasisDelay, iTypeDelay);
    end if;
  end InsertSerialPosAvailableQty;

  /**
  *  Description
  *    Insere dans la table temp des position cpt pour les bien
  *    dont la réf principale correspond à la réf. passée en param
  */
  procedure InsertSerialPosCpt(iReference in varchar2, iDocumentID in number, iPTPositionID in number, iGapID in number)
  is
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a une référence dans le champs de la recherche
    -- Evite dans tous les cas un fullscan
    if ltrim(rtrim(iReference) ) is not null then
      -- Insertion dans la table temporaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , DOC_GAUGE_POSITION_ID
                 , STM_LOCATION_ID
                 , DOC_DOC_POSITION_ID
                 , DTP_UTIL_COEF
                 , PDE_BASIS_DELAY
                 , PDE_INTERMEDIATE_DELAY
                 , PDE_FINAL_DELAY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , iDocumentID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , POS.POS_BASIS_QUANTITY PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , iGapID DOC_GAUGE_POSITION_ID
                       , POS.STM_LOCATION_ID STM_LOCATION_ID
                       , iPTPositionID DOC_DOC_POSITION_ID
                       , 1 DTP_UTIL_COEF
                       , PDE.PDE_BASIS_DELAY
                       , PDE.PDE_INTERMEDIATE_DELAY
                       , PDE.PDE_FINAL_DELAY
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                    from GCO_GOOD GOO
                       , DOC_POSITION POS
                       , (select max(PDE_BASIS_DELAY) PDE_BASIS_DELAY
                               , max(PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY
                               , max(PDE_FINAL_DELAY) PDE_FINAL_DELAY
                            from DOC_POSITION_DETAIL
                           where DOC_POSITION_ID = iPTPositionID) PDE
                   where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(iReference)
                     and POS.DOC_POSITION_ID = iPTPositionID
                order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    end if;
  end InsertSerialPosCpt;

  /**
  *  Description
  *    Insere dans la table temp des position CPT avec les biens passés dans la liste
  */
  procedure InsertSerialPosCptByGoodList(iGoodList in varchar2, iDocumentID in number, iPTPositionID in varchar2, iGapID in varchar2)
  is
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a au moins un bien dans la liste
    -- Evite dans tous les cas un fullscan
    if ltrim(rtrim(iGoodList) ) is not null then
      -- Insertion dans la table temporaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , DOC_GAUGE_POSITION_ID
                 , STM_LOCATION_ID
                 , DOC_DOC_POSITION_ID
                 , DTP_UTIL_COEF
                 , PDE_BASIS_DELAY
                 , PDE_INTERMEDIATE_DELAY
                 , PDE_FINAL_DELAY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , iDocumentID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , POS.POS_BASIS_QUANTITY PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , iGapID DOC_GAUGE_POSITION_ID
                       , POS.STM_LOCATION_ID STM_LOCATION_ID
                       , iPTPositionID DOC_DOC_POSITION_ID
                       , 1 DTP_UTIL_COEF
                       , PDE.PDE_BASIS_DELAY
                       , PDE.PDE_INTERMEDIATE_DELAY
                       , PDE.PDE_FINAL_DELAY
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                    from GCO_GOOD GOO
                       , DOC_POSITION POS
                       , (select max(PDE_BASIS_DELAY) PDE_BASIS_DELAY
                               , max(PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY
                               , max(PDE_FINAL_DELAY) PDE_FINAL_DELAY
                            from DOC_POSITION_DETAIL
                           where DOC_POSITION_ID = iPTPositionID) PDE
                   where instr(iGoodList, ',' || GOO.GCO_GOOD_ID || ',') > 0
                     and POS.DOC_POSITION_ID = iPTPositionID
                order by GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    end if;
  end InsertSerialPosCptByGoodList;

  /**
  * procedure InsertSerialPosInstall
  * Description
  *    Insere dans la table temp des positions avec des biens liés aux installations (type de dossier)
  * @created Nuno Gomes Vieira 15.02.2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure InsertSerialPosInstall(iReference in varchar2, iDocumentID in number)
  is
    lDocCurrencyID       DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    lDefaultCurrencyID   DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    lGapID               number;
    lAdminDomain         varchar2(10);
    lPacThirdId          DOC_DOCUMENT.PAC_THIRD_ID%type;
    lMovementKindId      STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInitStockPlace      DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;
    lMvtUtility          DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;
    lTransfertProprietor DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type;
  begin
    -- Effacer les données de la table temporaire
    DeleteAllTmpTable(userenv('SESSIONID') );

    -- Ne lancer que s'il y a une référence dans le champs de la recherche
    -- Evite dans tous les cas un fullscan
    if ltrim(rtrim(iReference) ) is not null then
      -- Recherche l'ID du gabarit et le domaine du document et genre de mvt
      --  pour l'utiliser lors de la recherche du gabarit position
      select GAU.C_ADMIN_DOMAIN
           , DMT.PAC_THIRD_ID
           , GAP.STM_MOVEMENT_KIND_ID
           , GAP.GAP_INIT_STOCK_PLACE
           , GAP.GAP_MVT_UTILITY
           , GAP.GAP_TRANSFERT_PROPRIETOR
           , GAP.DOC_GAUGE_POSITION_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , ACS_FUNCTION.GetLocalCurrencyId
        into lAdminDomain
           , lPacThirdId
           , lMovementKindId
           , lInitStockPlace
           , lMvtUtility
           , lTransfertProprietor
           , lGapId
           , lDocCurrencyID
           , lDefaultCurrencyID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
           , STM_MOVEMENT_KIND MOK
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = '1'
         and GAP.GAP_DEFAULT = 1
         and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+);

      -- Insertion dans la table temporaire
      insert into DOC_TMP_POSITION_DETAIL
                  (DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DTP_SESSION_ID
                 , DOC_DOCUMENT_ID
                 , CRG_SELECT
                 , PDE_BASIS_QUANTITY
                 , GCO_GOOD_ID
                 , PDE_DOC_RECORD_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , SQL_CMD.*
          from (select   userenv('SESSIONID') DTP_SESSION_ID
                       , iDocumentID DOC_DOCUMENT_ID
                       , 0 CRG_SELECT
                       , 1.0 PDE_BASIS_QUANTITY
                       , GOO.GCO_GOOD_ID GCO_GOOD_ID
                       , RCO.DOC_RECORD_ID
                       , lGapID DOC_GAUGE_POSITION_ID
                       , null CSA_GAP_TYPE_MANDATORY
                       , DOC_SERIAL_POS_INSERT_TMP.GetPositionLocation(GOO.GCO_GOOD_ID
                                                                     , DMT.PAC_THIRD_ID
                                                                     , lMovementKindId
                                                                     , lAdminDomain
                                                                     , lInitStockPlace
                                                                     , lMvtUtility
                                                                     , lTransfertProprietor
                                                                      )
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                    from DOC_RECORD RCO
                       , GCO_GOOD GOO
                       , GCO_PRODUCT PDT
                       , DOC_DOCUMENT DMT
                   where RCO.RCO_TITLE like LIKE_PARAM(iReference)
                     and RCO.C_RCO_TYPE = '11'
                     and RCO.C_RCO_STATUS = '0'
                     and RCO.RCO_MACHINE_GOOD_ID = GOO.GCO_GOOD_ID
                     and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                     and DMT.DOC_DOCUMENT_ID = iDocumentID
                order by RCO.RCO_TITLE
                       , GOO.GOO_MAJOR_REFERENCE) SQL_CMD;
    end if;
  end InsertSerialPosInstall;

  /**
  * procedure InsertSerialPosInstallDelay
  * Description
  *    Insere dans la table temp des positions avec des biens liés
  *      aux installations (type de dossier) avec les délais
  * @created Nuno Gomes Vieira 15.02.2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure InsertSerialPosInstallDelay(iReference in varchar2, iDocumentID in number, iBasisDelay in date, iTypeDelay in varchar2)
  is
  begin
    InsertSerialPosInstall(iReference, iDocumentID);
    -- Màj des délais des positions de la table temp
    UpdateSerialPosDelay(iBasisDelay, iTypeDelay);
  end InsertSerialPosInstallDelay;

  /**
  * procedure UpdateSerialPosDelay
  * Description
  *    Màj des délais des positions de la table temp
  */
  procedure UpdateSerialPosDelay(iBasisDelay in date, iTypeDelay in varchar2)
  is
    -- Données de la table temp pour les positions qui viennent d'être insérées
    cursor lcurTempPos
    is
      select   DTP.DOC_POSITION_ID
             , DTP.PDE_BASIS_DELAY
             , DTP.PDE_INTERMEDIATE_DELAY
             , DTP.PDE_FINAL_DELAY
             , DTP.GCO_GOOD_ID
             , DMT.PAC_THIRD_CDA_ID
             , GAU.C_ADMIN_DOMAIN
             , GAU.C_GAUGE_TYPE
             , GAP.GAP_POS_DELAY
             , GAP.C_GAUGE_SHOW_DELAY
             , GAP.GAP_TRANSFERT_PROPRIETOR
             , LOC.STM_STOCK_ID
             , TRA_LOC.STM_STOCK_ID STM_STM_STOCK_ID
          from DOC_TMP_POSITION_DETAIL DTP
             , DOC_GAUGE GAU
             , DOC_GAUGE_POSITION GAP
             , DOC_DOCUMENT DMT
             , STM_LOCATION LOC
             , STM_LOCATION TRA_LOC
         where DTP.DTP_SESSION_ID = userenv('SESSIONID')
           and DTP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and DTP.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
           and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and DTP.STM_LOCATION_ID = LOC.STM_LOCATION_ID(+)
           and DTP.STM_STM_LOCATION_ID = TRA_LOC.STM_LOCATION_ID(+)
      order by DTP.DOC_POSITION_DETAIL_ID;

    lBasisDelayMW varchar2(10);
    lInterDelayMW varchar2(10);
    lFinalDelayMW varchar2(10);
    lBasisDelay   date;
    lInterDelay   date;
    lFinalDelay   date;
    lForward      number;
  begin

    -- Calcul des délais en avant ou en arrière selon le délai passé
    if iTypeDelay = 'BASIS' then
      lForward  := 1;
    else
      lForward  := 0;
    end if;

    -- Mise à jour du Délai intermédiaire et du délai final selon les données compl.
    for ltplTempPos in lcurTempPos loop
      lBasisDelay    := iBasisDelay;
      lInterDelay    := iBasisDelay;
      lFinalDelay    := iBasisDelay;
      lBasisDelayMW  := null;
      lInterDelayMW  := null;
      lFinalDelayMW  := null;
      -- Recherche du délai inter et final selon le délai de base
      DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(ltplTempPos.C_GAUGE_SHOW_DELAY
                                              , ltplTempPos.GAP_POS_DELAY
                                              , iTypeDelay
                                              , lForward
                                              , ltplTempPos.PAC_THIRD_CDA_ID
                                              , ltplTempPos.GCO_GOOD_ID
                                              , ltplTempPos.STM_STOCK_ID
                                              , ltplTempPos.STM_STM_STOCK_ID
                                              , ltplTempPos.C_ADMIN_DOMAIN
                                              , ltplTempPos.C_GAUGE_TYPE
                                              , ltplTempPos.GAP_TRANSFERT_PROPRIETOR
                                              , lBasisDelayMW
                                              , lInterDelayMW
                                              , lFinalDelayMW
                                              , lBasisDelay
                                              , lInterDelay
                                              , lFinalDelay
                                               );

      -- Mise à jour du Délai intermédiaire et du délai final selon les données compl.
      update DOC_TMP_POSITION_DETAIL
         set PDE_BASIS_DELAY = lBasisDelay
           , PDE_INTERMEDIATE_DELAY = lInterDelay
           , PDE_FINAL_DELAY = lFinalDelay
       where DTP_SESSION_ID = userenv('SESSIONID')
         and DOC_POSITION_ID = ltplTempPos.DOC_POSITION_ID;
    end loop;
  end UpdateSerialPosDelay;

  /**
  *  Description
  *    Efface toutes les données de la table temp pour l'ID de session en param
  */
  procedure DeleteAllTmpTable(iSessionID in number)
  is
  begin
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = iSessionID;
  end DeleteAllTmpTable;

  /**
  *  Description
  *    Renvoi l'ID du gabarit position par défaut du type '1'
  */
  function GetDefaultGapID(iGaugeID in number)
    return number
  is
    lGapID DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
  begin
    -- ID gabarit position pour la position type 1 par défaut du gabarit passé en param
    select DOC_GAUGE_POSITION_ID
      into lGapID
      from DOC_GAUGE_POSITION
     where DOC_GAUGE_ID = iGaugeID
       and GAP_DEFAULT = 1
       and C_GAUGE_TYPE_POS = '1';

    return lGapID;
  exception
    when no_data_found then
      return null;
  end GetDefaultGapID;

  /**
  *  Description
  *    Renvoi l'ID du gabarit position par défaut pour le type de position définit dans la donnée compl de vente
  */
  function GetComplDataSaleGapID(iGoodID in number, iGaugeID in number, iThirdID in number)
    return number
  is
    lGapID DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
  begin
    -- ID gabarit position par défaut correspondant au type da gabarit définit dans les données compl de vente
    select nvl(GAP_CSA.DOC_GAUGE_POSITION_ID, GAP_DEF.DOC_GAUGE_POSITION_ID) DOC_GAUGE_POSITION_ID
      into lGapID
      from DOC_GAUGE_POSITION GAP_DEF
         , DOC_GAUGE_POSITION GAP_CSA
         , (select nvl(max(C_GAUGE_TYPE_POS), '1') C_GAUGE_TYPE_POS
              from GCO_COMPL_DATA_SALE
             where GCO_COMPL_DATA_SALE_ID(+) = GCO_FUNCTIONS.GetComplDataSaleId(iGoodID, iThirdID) ) CSA
     where GAP_DEF.DOC_GAUGE_ID = iGaugeID
       and GAP_DEF.GAP_DEFAULT = 1
       and GAP_DEF.C_GAUGE_TYPE_POS = '1'
       and GAP_CSA.DOC_GAUGE_ID = iGaugeID
       and GAP_CSA.GAP_DEFAULT = 1
       and GAP_CSA.C_GAUGE_TYPE_POS = CSA.C_GAUGE_TYPE_POS;

    return lGapID;
  exception
    when no_data_found then
      return null;
  end GetComplDataSaleGapID;

  /**
  *  Description
  *    Indique s'il y a un type de position obligatoire défini sur la donnée compl. de vente
  */
  function GetCSAGaugeMandatoryType(iGoodID in number, iThirdID in number)
    return varchar2
  is
    lGaugeTypePos varchar2(10);
  begin
    select decode(max(CSA_GAUGE_TYPE_POS_MANDATORY), 1, max(C_GAUGE_TYPE_POS), null)
      into lGaugeTypePos
      from GCO_COMPL_DATA_SALE
     where GCO_COMPL_DATA_SALE_ID(+) = GCO_FUNCTIONS.GetComplDataSaleId(iGoodID, iThirdID);

    return lGaugeTypePos;
  end GetCSAGaugeMandatoryType;
end DOC_SERIAL_POS_INSERT_TMP;
