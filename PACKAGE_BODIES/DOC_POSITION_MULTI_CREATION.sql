--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_MULTI_CREATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_MULTI_CREATION" 
is
  /**
  * procedure GenerateGoodPos
  *
  * Description : Génération dans la table temp des propositions de position
  *               pour un bien spécifique ainsi que pour les bien en corrélation
  */
  procedure GenerateGoodPos(
    DocumentID       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , GoodID           in GCO_GOOD.GCO_GOOD_ID%type
  , DicConnectedType in GCO_CONNECTED_GOOD.DIC_CONNECTED_TYPE_ID%type
  )
  is
    vAdminDomain      varchar2(10);
    vPAC_THIRD_CDA_ID DOC_DOCUMENT.PAC_THIRD_CDA_ID%type;
  begin
    -- Effacer les données existantes da la table tmp
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = userenv('SESSIONID');

    -- Recherche le domaine du document, parce que pour le domaine vente on doit aller
     -- chercher le type de position à créer au niveau des donnnées complémentaires de vente
    select GAU.C_ADMIN_DOMAIN
         , DMT.PAC_THIRD_CDA_ID
      into vAdminDomain
         , vPAC_THIRD_CDA_ID
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = DocumentID
       and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    -- Dans le domaine Vente chercher le type de position à créer dans les données compl. de vente
    if vAdminDomain = '2' then
      -- Insertion dans la table temp la proposition de position pour le bien passé en param
      insert into DOC_TMP_POSITION_DETAIL
                  (DTP_SESSION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , GCO_GOOD_ID
                 , CRG_SELECT
                 , DTP_UTIL_COEF
                 , GCO_CONNECTED_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                  )
        select userenv('SESSIONID') DTP_SESSION_ID
             , INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , DocumentID
             , GoodID
             , 1 CON_DEFAULT_SELECTION
             , 1 CON_UTIL_COEFF
             , null GCO_CONNECTED_GOOD_ID
             , NOM.PPS_NOMENCLATURE_ID
             , GetGapID(DOC.DOC_GAUGE_ID, nvl(CSA.C_GAUGE_TYPE_POS, '1') ) DOC_GAUGE_POSITION_ID
             , decode(CSA.CSA_GAUGE_TYPE_POS_MANDATORY, 1, CSA.C_GAUGE_TYPE_POS, null) CSA_GAP_TYPE_MANDATORY
          from GCO_GOOD GOO
             , PPS_NOMENCLATURE NOM
             , GCO_COMPL_DATA_SALE CSA
             , DOC_DOCUMENT DOC
         where GOO.GCO_GOOD_ID = GoodID
           and DOC.DOC_DOCUMENT_ID = DocumentID
           and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID(+)
           and NOM.NOM_DEFAULT(+) = 1
           and NOM.C_TYPE_NOM(+) = '2'
           and CSA.GCO_COMPL_DATA_SALE_ID(+) = GCO_FUNCTIONS.GetComplDataSaleId(GOO.GCO_GOOD_ID, vPAC_THIRD_CDA_ID);

      -- Insertion dans la table temp les propositions de position
      -- pour les biens en corrélation avec le bien passé en param
      insert into DOC_TMP_POSITION_DETAIL
                  (DTP_SESSION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , GCO_GOOD_ID
                 , CRG_SELECT
                 , DTP_UTIL_COEF
                 , GCO_CONNECTED_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                 , CSA_GAP_TYPE_MANDATORY
                  )
        select userenv('SESSIONID') DTP_SESSION_ID
             , INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , DocumentID
             , CON.GCO_GCO_GOOD_ID
             , CON.CON_DEFAULT_SELECTION
             , CON.CON_UTIL_COEFF
             , CON.GCO_CONNECTED_GOOD_ID
             , NOM.PPS_NOMENCLATURE_ID
             , GetGapID(DOC.DOC_GAUGE_ID, nvl(CSA.C_GAUGE_TYPE_POS, '1') ) DOC_GAUGE_POSITION_ID
             , decode(CSA.CSA_GAUGE_TYPE_POS_MANDATORY, 1, CSA.C_GAUGE_TYPE_POS, null) CSA_GAP_TYPE_MANDATORY
          from GCO_CONNECTED_GOOD CON
             , PPS_NOMENCLATURE NOM
             , GCO_COMPL_DATA_SALE CSA
             , DOC_DOCUMENT DOC
         where CON.GCO_GOOD_ID = GoodID
           and (   CON.DIC_CONNECTED_TYPE_ID = DicConnectedType
                or DicConnectedType is null)
           and DOC.DOC_DOCUMENT_ID = DocumentID
           and CON.GCO_GCO_GOOD_ID = NOM.GCO_GOOD_ID(+)
           and NOM.NOM_DEFAULT(+) = 1
           and NOM.C_TYPE_NOM(+) = '2'
           and CSA.GCO_COMPL_DATA_SALE_ID(+) = GCO_FUNCTIONS.GetComplDataSaleId(CON.GCO_GCO_GOOD_ID, vPAC_THIRD_CDA_ID);
    else   -- Autre domaine
      -- Insertion dans la table temp la proposition de position pour le bien passé en param
      insert into DOC_TMP_POSITION_DETAIL
                  (DTP_SESSION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , GCO_GOOD_ID
                 , CRG_SELECT
                 , DTP_UTIL_COEF
                 , GCO_CONNECTED_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                  )
        select userenv('SESSIONID') DTP_SESSION_ID
             , INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , DocumentID
             , GoodID
             , 1 CON_DEFAULT_SELECTION
             , 1 CON_UTIL_COEFF
             , null GCO_CONNECTED_GOOD_ID
             , NOM.PPS_NOMENCLATURE_ID
             , GetGapID(DOC.DOC_GAUGE_ID, '1') DOC_GAUGE_POSITION_ID
          from GCO_GOOD GOO
             , PPS_NOMENCLATURE NOM
             , DOC_DOCUMENT DOC
         where GOO.GCO_GOOD_ID = GoodID
           and DOC.DOC_DOCUMENT_ID = DocumentID
           and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID(+)
           and NOM.NOM_DEFAULT(+) = 1
           and NOM.C_TYPE_NOM(+) = '2';

      -- Insertion dans la table temp les propositions de position
      -- pour les biens en corrélation avec le bien passé en param
      insert into DOC_TMP_POSITION_DETAIL
                  (DTP_SESSION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DOC_POSITION_ID
                 , DOC_DOCUMENT_ID
                 , GCO_GOOD_ID
                 , CRG_SELECT
                 , DTP_UTIL_COEF
                 , GCO_CONNECTED_GOOD_ID
                 , PPS_NOMENCLATURE_ID
                 , DOC_GAUGE_POSITION_ID
                  )
        select userenv('SESSIONID') DTP_SESSION_ID
             , INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
             , INIT_ID_SEQ.currval DOC_POSITION_ID
             , DocumentID
             , CON.GCO_GCO_GOOD_ID
             , CON.CON_DEFAULT_SELECTION
             , CON.CON_UTIL_COEFF
             , CON.GCO_CONNECTED_GOOD_ID
             , NOM.PPS_NOMENCLATURE_ID
             , GetGapID(DOC.DOC_GAUGE_ID, '1') DOC_GAUGE_POSITION_ID
          from GCO_CONNECTED_GOOD CON
             , PPS_NOMENCLATURE NOM
             , DOC_DOCUMENT DOC
         where CON.GCO_GOOD_ID = GoodID
           and (   CON.DIC_CONNECTED_TYPE_ID = DicConnectedType
                or DicConnectedType is null)
           and DOC.DOC_DOCUMENT_ID = DocumentID
           and CON.GCO_GCO_GOOD_ID = NOM.GCO_GOOD_ID(+)
           and NOM.NOM_DEFAULT(+) = 1
           and NOM.C_TYPE_NOM(+) = '2';
    end if;
  end GenerateGoodPos;

  /**
  * procedure GenerateDetailOnePosition
  *
  * Description : Génération des détails de position dans la table temp
  *                 pour une proposition de position figurant dans la table temp
  */
  procedure GenerateDetailOnePosition(
    TmpPositionID in DOC_POSITION.DOC_POSITION_ID%type
  , DetailCount   in number
  , DetailQty     in DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
  , DetailDelay   in DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , TypeDelay     in varchar2
  )
  is
    -- Informations sur la proposition de position de la table temp
    cursor crPosition(cPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    is
      select DTP.GCO_GOOD_ID
           , DTP.STM_LOCATION_ID
           , DTP.DOC_DOCUMENT_ID
           , DMT.PAC_THIRD_CDA_ID
           , DTP.DOC_GAUGE_POSITION_ID
           , DTP.PPS_NOMENCLATURE_ID
           , DTP.DTP_UTIL_COEF
           , DTP.CRG_SELECT
        from DOC_TMP_POSITION_DETAIL DTP
           , DOC_DOCUMENT DMT
       where DTP.DOC_POSITION_ID = cPositionID
         and DTP.DOC_POSITION_DETAIL_ID = DTP.DOC_POSITION_ID
         and DTP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

    tplPosition   crPosition%rowtype;

    -- Informations du gabarit
    cursor crGaugeInfo(cGapID in number)
    is
      select GAP.GAP_POS_DELAY
           , GAP.C_GAUGE_SHOW_DELAY
           , GAU.C_ADMIN_DOMAIN
           , GAU.C_GAUGE_TYPE
        from DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
       where GAP.DOC_GAUGE_POSITION_ID = cGapID
         and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    tplGaugeInfo  crGaugeInfo%rowtype;
    -- Compteur pour le nbr de détails à créér
    iCounter      number(9);
    datBasisDelay date;
    datInterDelay date;
    datFinalDelay date;
    BasisDelayMW  varchar2(10);
    InterDelayMW  varchar2(10);
    FinalDelayMW  varchar2(10);
    iForward      integer;
  begin
    -- Calcul des délais en avant ou en arrière selon le délai passé
    if TypeDelay = 'BASIS' then
      iForward  := 1;
    else
      iForward  := 0;
    end if;

    -- Informations de la position courante
    open crPosition(TmpPositionID);

    fetch crPosition
     into tplPosition;

    close crPosition;

    -- Ne pas faire de traitement la cadence est nulle
    -- Ou que la position n'est pas sélectionnée
    if     (DetailCount > 0)
       and (tplPosition.CRG_SELECT = 1) then
      -- Efface les détails existants pour la position
      delete from DOC_TMP_POSITION_DETAIL
            where DTP_SESSION_ID = userenv('SESSIONID')
              and DOC_POSITION_ID = TmpPositionID
              and DOC_POSITION_DETAIL_ID <> TmpPositionID;

      -- Reprise du délais passé en param
      datBasisDelay  := DetailDelay;
      datInterDelay  := DetailDelay;
      datFinalDelay  := DetailDelay;

      -- Informations du gabarit courant
      open crGaugeInfo(tplPosition.DOC_GAUGE_POSITION_ID);

      fetch crGaugeInfo
       into tplGaugeInfo;

      close crGaugeInfo;

      -- Recherche les délais pour le détail à créér
      DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(tplGaugeInfo.C_GAUGE_SHOW_DELAY
                                              , tplGaugeInfo.GAP_POS_DELAY
                                              , TypeDelay
                                              , iForward
                                              , tplPosition.PAC_THIRD_CDA_ID
                                              , tplPosition.GCO_GOOD_ID
                                              , null   -- STM_STOCK_ID
                                              , null   -- STM_STM_STOCK_ID
                                              , tplGaugeInfo.C_ADMIN_DOMAIN
                                              , tplGaugeInfo.C_GAUGE_TYPE
                                              , 0   -- GAP_TRANSFERT_PROPRIETOR
                                              , BasisDelayMW
                                              , InterDelayMW
                                              , FinalDelayMW
                                              , datBasisDelay
                                              , datInterDelay
                                              , datFinalDelay
                                               );
      -- Compteur des détails créés
      iCounter       := 0;

      -- Création des détails dans la table temp pour la proposition de position spécifiée
      while iCounter < DetailCount loop
        insert into DOC_TMP_POSITION_DETAIL
                    (DTP_SESSION_ID
                   , DOC_POSITION_DETAIL_ID
                   , DOC_POSITION_ID
                   , DOC_DOCUMENT_ID
                   , GCO_GOOD_ID
                   , DOC_GAUGE_POSITION_ID
                   , PPS_NOMENCLATURE_ID
                   , PDE_BASIS_QUANTITY
                   , PDE_BASIS_DELAY
                   , PDE_INTERMEDIATE_DELAY
                   , PDE_FINAL_DELAY
                    )
          select userenv('SESSIONID')
               , INIT_ID_SEQ.nextval DOC_POSITION_DETAIL_ID
               , TmpPositionID
               , tplPosition.DOC_DOCUMENT_ID
               , tplPosition.GCO_GOOD_ID
               , tplPosition.DOC_GAUGE_POSITION_ID
               , tplPosition.PPS_NOMENCLATURE_ID
               , tplPosition.DTP_UTIL_COEF * DetailQty
               , datBasisDelay
               , datInterDelay
               , datFinalDelay
            from dual;

        -- Màj du compteur des détails créés
        iCounter  := iCounter + 1;
      end loop;
    end if;
  end GenerateDetailOnePosition;

  /**
  * procedure GenerateDetailAllPosition
  *
  * Description : Génération des détails de position dans la table temp
  *                 pour toutes les propositions de position figurant dans la table temp
  */
  procedure GenerateDetailAllPosition(TmpPositionID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    -- Informations sur les propositions de positions de la table temp
    cursor crPositionToCreateDetail(cPositionID in number)
    is
      select DOC_POSITION_ID
           , DOC_DOCUMENT_ID
           , GCO_GOOD_ID
           , DOC_GAUGE_POSITION_ID
           , PPS_NOMENCLATURE_ID
           , nvl(DTP_UTIL_COEF, 1) DTP_UTIL_COEF
           , PDE_BASIS_QUANTITY
        from DOC_TMP_POSITION_DETAIL
       where DTP_SESSION_ID = userenv('SESSIONID')
         and DOC_POSITION_ID <> cPositionID
         and CRG_SELECT = 1;

    -- Liste des détails de la position courante à copier sur les autres positions
    cursor crPdeToCopy(cPositionID in number)
    is
      select *
        from DOC_TMP_POSITION_DETAIL
       where DOC_POSITION_ID = cPositionID
         and DOC_POSITION_ID <> DOC_POSITION_DETAIL_ID;

    tmpUtilCoeff DOC_TMP_POSITION_DETAIL.DTP_UTIL_COEF%type;
  begin
    -- Effacer tous les détails de la table temp des positions sélectionnées, sauf ceux de la position en cours
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = userenv('SESSIONID')
            and DOC_POSITION_ID <> TmpPositionID
            and DOC_POSITION_ID <> DOC_POSITION_DETAIL_ID
            and CRG_SELECT = 1;

    -- Recherche le coefficient d'utilisation de la position à copier
    select nvl(DTP_UTIL_COEF, 1)
      into tmpUtilCoeff
      from DOC_TMP_POSITION_DETAIL
     where DOC_POSITION_ID = TmpPositionID
       and DOC_POSITION_ID = DOC_POSITION_DETAIL_ID;

    -- Copie les détails de la position en cours sur toutes les autres positions.
    -- Balayer la liste des positions qui n'ont pas de détails
    for tplPositionToCreateDetail in crPositionToCreateDetail(TmpPositionID) loop
      -- Balayer la liste des détails de la position courante
      for tplPdeToCopy in crPdeToCopy(TmpPositionID) loop
        -- Changer les valeurs sur le nouveau détail par rapport à sa propre position
        select INIT_ID_SEQ.nextval
             , tplPositionToCreateDetail.DOC_POSITION_ID
             , tplPositionToCreateDetail.DOC_DOCUMENT_ID
             , tplPositionToCreateDetail.GCO_GOOD_ID
             , tplPositionToCreateDetail.DOC_GAUGE_POSITION_ID
             , tplPositionToCreateDetail.PPS_NOMENCLATURE_ID
             , (tplPdeToCopy.PDE_BASIS_QUANTITY / tmpUtilCoeff) * tplPositionToCreateDetail.DTP_UTIL_COEF
          into tplPdeToCopy.DOC_POSITION_DETAIL_ID
             , tplPdeToCopy.DOC_POSITION_ID
             , tplPdeToCopy.DOC_DOCUMENT_ID
             , tplPdeToCopy.GCO_GOOD_ID
             , tplPdeToCopy.DOC_GAUGE_POSITION_ID
             , tplPdeToCopy.PPS_NOMENCLATURE_ID
             , tplPdeToCopy.PDE_BASIS_QUANTITY
          from dual;

        insert into DOC_TMP_POSITION_DETAIL
             values tplPdeToCopy;
      end loop;
    end loop;
  end GenerateDetailAllPosition;

  /**
  * procedure GeneratePositions
  *
  * Description : Génération les positions d'après les propositions de position
  *                 qui se trouvent dans la table temp
  */
  procedure GeneratePositions(TypeDelay in varchar2)
  is
    -- Liste des propositions de positions de la table temp
    cursor crPositionToCreate
    is
      select DOC_POSITION_ID
           , DOC_POSITION_DETAIL_ID
           , DOC_DOCUMENT_ID
           , GCO_GOOD_ID
           , DOC_GAUGE_POSITION_ID
           , PPS_NOMENCLATURE_ID
        from DOC_TMP_POSITION_DETAIL
       where DTP_SESSION_ID = userenv('SESSIONID')
         and DOC_POSITION_ID = DOC_POSITION_DETAIL_ID
         and CRG_SELECT = 1;

    -- Liste des détails des propositions de positions de la table temp
    cursor crDetailToCreate(cPositionID in number, cTypeDelay in varchar2)
    is
      select   DOC_POSITION_ID
             , DOC_POSITION_DETAIL_ID
             , DOC_DOCUMENT_ID
             , GCO_GOOD_ID
             , PDE_BASIS_QUANTITY
             , PDE_BASIS_DELAY
             , PDE_INTERMEDIATE_DELAY
             , PDE_FINAL_DELAY
          from DOC_TMP_POSITION_DETAIL
         where DOC_POSITION_ID = cPositionID
           and DOC_POSITION_DETAIL_ID <> cPositionID
      order by decode(cTypeDelay, 'BASIS', PDE_BASIS_DELAY, 'INTER', PDE_INTERMEDIATE_DELAY, 'FINAL', PDE_FINAL_DELAY);

    -- Informations du gabarit
    cursor crGaugeInfo(cGapID in number)
    is
      select GAP.STM_MOVEMENT_KIND_ID
           , GAS.GAS_CHARACTERIZATION
           , GAU.C_ADMIN_DOMAIN
           , GAU.DOC_GAUGE_ID
        from DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAP.DOC_GAUGE_POSITION_ID = cGapID
         and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    tplGaugeInfo crGaugeInfo%rowtype;
    tmpPOS_ID    number;
    PosQuantity  number;
    TypePos      DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Liste des propositions des positions
    for tplPositionToCreate in crPositionToCreate loop
      select C_GAUGE_TYPE_POS
        into TypePos
        from DOC_GAUGE_POSITION
       where DOC_GAUGE_POSITION_ID = tplPositionToCreate.DOC_GAUGE_POSITION_ID;

      -- Position autres que 7,8,9,10
      if TypePos not in('7', '8', '9', '10') then
        -- Calcul de la qté de la position
        select sum(PDE_BASIS_QUANTITY)
          into PosQuantity
          from DOC_TMP_POSITION_DETAIL
         where DOC_POSITION_ID = tplPositionToCreate.DOC_POSITION_ID;

        -- Création de la position
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => tplPositionToCreate.DOC_POSITION_ID
                                             , aDocumentID       => tplPositionToCreate.DOC_DOCUMENT_ID
                                             , aPosCreateMode    => '115'
                                             , aBasisQuantity    => PosQuantity
                                             , aTmpPosID         => tplPositionToCreate.DOC_POSITION_ID
                                             , aGenerateDetail   => 0
                                              );

        -- Création des détails
        for tplDetailToCreate in crDetailToCreate(tplPositionToCreate.DOC_POSITION_ID, TypeDelay) loop
          DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => tplDetailToCreate.DOC_POSITION_DETAIL_ID
                                           , aPositionID      => tplDetailToCreate.DOC_POSITION_ID
                                           , aPdeCreateMode   => '115'
                                           , aTmpPdeID        => tplDetailToCreate.DOC_POSITION_DETAIL_ID
                                            );
        end loop;

        -- Màj du flag de rupture de stock
        -- Si le détail est créé indépendament de la position (comme c'est le cas ci-dessus)
        -- il faut lancer la méthode de màj du flag de rupture de stock de la position
        DOC_FUNCTIONS.FlagPositionManco(position_id => tplPositionToCreate.DOC_POSITION_ID, document_id => null);
      -- Pour les position Kit et assemblage on créé autant de positions qu'il y a de détails
      elsif TypePos in('7', '8', '9', '10') then
        for tplDetailToCreate in crDetailToCreate(tplPositionToCreate.DOC_POSITION_ID, TypeDelay) loop
          tmpPOS_ID  := null;
          -- Création de la position et du détail
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => tmpPOS_ID
                                               , aDocumentID       => tplDetailToCreate.DOC_DOCUMENT_ID
                                               , aPosCreateMode    => '115'
                                               , aBasisQuantity    => tplDetailToCreate.PDE_BASIS_QUANTITY
                                               , aTmpPosID         => tplDetailToCreate.DOC_POSITION_ID
                                               , aTmpPdeID         => tplDetailToCreate.DOC_POSITION_DETAIL_ID
                                               , aGenerateDetail   => 1
                                               , aGenerateCPT      => 1
                                                );
        end loop;
      end if;
    end loop;

    -- Effacer les données temporaires de la table DOC_TMP_POSITION_DETAIL
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = userenv('SESSIONID');
  end GeneratePositions;

  /**
  * function GetGapID
  *
  * Description : Renvoi l'ID du gabarit position selon le ID de gabarit et
  *                 le type de position
  */
  function GetGapID(GaugeID in number, TypePos in varchar2)
    return number
  is
    cursor crGetGapID(cGaugeID in number, cTypePos in varchar2)
    is
      select   DOC_GAUGE_POSITION_ID
             , 1 TO_ORDER
          from DOC_GAUGE_POSITION
         where DOC_GAUGE_ID = cGaugeID
           and GAP_DEFAULT = 1
           and C_GAUGE_TYPE_POS = cTypePos
      union
      select   DOC_GAUGE_POSITION_ID
             , 2 TO_ORDER
          from DOC_GAUGE_POSITION
         where DOC_GAUGE_ID = cGaugeID
           and GAP_DEFAULT = 1
           and C_GAUGE_TYPE_POS = '1'
      order by TO_ORDER;

    tplGetGapID crGetGapID%rowtype;
  begin
    open crGetGapID(GaugeID, TypePos);

    fetch crGetGapID
     into tplGetGapID;

    close crGetGapID;

    return tplGetGapID.DOC_GAUGE_POSITION_ID;
  end GetGapID;
end DOC_POSITION_MULTI_CREATION;
