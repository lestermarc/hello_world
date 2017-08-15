--------------------------------------------------------
--  DDL for Package Body DOC_SERIAL_POS_CREATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_SERIAL_POS_CREATE" 
is
  procedure RegroupPositions(iSessionID in DOC_TMP_POSITION_DETAIL.DTP_SESSION_ID%type)
  is
    lnPosID  DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type;
    lnGoodID DOC_TMP_POSITION_DETAIL.GCO_GOOD_ID%type;
    lnGapID  DOC_TMP_POSITION_DETAIL.DOC_GAUGE_POSITION_ID%type;
  begin
    lnPosID  := null;

    -- Regroupement des détails en une seule position si même bien et type de pos (uniquement type 1)
    for ltplDetail in (select   DTP.DOC_POSITION_ID
                              , DTP.DOC_POSITION_DETAIL_ID
                              , DTP.GCO_GOOD_ID
                              , DTP.DOC_GAUGE_POSITION_ID
                              , GAP.C_GAUGE_TYPE_POS
                           from DOC_TMP_POSITION_DETAIL DTP
                              , DOC_GAUGE_POSITION GAP
                          where DTP.DTP_SESSION_ID = iSessionID
                            and DTP.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                       order by DTP.DOC_POSITION_DETAIL_ID asc) loop
      if     (lnPosID is not null)
         and (lnGoodID = ltplDetail.GCO_GOOD_ID)
         and (lnGapID = ltplDetail.DOC_GAUGE_POSITION_ID)
         and (ltplDetail.C_GAUGE_TYPE_POS = '1') then
        update DOC_TMP_POSITION_DETAIL
           set DOC_POSITION_ID = lnPosID
         where DTP_SESSION_ID = iSessionID
           and DOC_POSITION_DETAIL_ID = ltplDetail.DOC_POSITION_DETAIL_ID;
      else
        lnPosID   := ltplDetail.DOC_POSITION_ID;
        lnGoodID  := ltplDetail.GCO_GOOD_ID;
        lnGapID   := ltplDetail.DOC_GAUGE_POSITION_ID;
      end if;
    end loop;
  end RegroupPositions;

  /**
  * procedure CreateSerialPosition
  * Description
  *   Création d'une position sur la base des données de la table temp
  */
  procedure CreateSerialPosition(iSessionID in DOC_TMP_POSITION_DETAIL.DTP_SESSION_ID%type, iPositionID in DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type)
  is
    /* Données de la table temp pour l'ID de position passé en param */
    cursor lcrPos
    is
      select   DTP.DOC_DOCUMENT_ID
             , DTP.DOC_POSITION_ID
             , DTP.DOC_POSITION_DETAIL_ID
          from DOC_TMP_POSITION_DETAIL DTP
         where DTP.DTP_SESSION_ID = iSessionID
           and DTP.DOC_POSITION_ID = iPositionID
      order by DTP.DOC_POSITION_DETAIL_ID asc;

    ltplPos lcrPos%rowtype;
    lnPosID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    open lcrPos;

    fetch lcrPos
     into ltplPos;

    if lcrPos%found then
      lnPosID  := null;
      /* Création de la position et du détail */
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => lnPosID
                                           , aDocumentID       => ltplPos.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '110'
                                           , aTmpPosID         => ltplPos.DOC_POSITION_ID
                                           , aTmpPdeID         => ltplPos.DOC_POSITION_DETAIL_ID
                                           , aGenerateDetail   => 1
                                           , aGenerateCPT      => 1
                                            );
    end if;

    close lcrPos;

    /* Effacer la liste des détails traités de la table Temp */
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = iSessionID
            and DOC_POSITION_ID = iPositionID;
  end CreateSerialPosition;

  /**
  * procedure CreateSerialPositionGrouped
  * Description
  *   Création d'une position sur la base des données de la table temp
  *     en regroupant plusieurs détails sur une position
  */
  procedure CreateSerialPositionGrouped(
    iSessionID  in DOC_TMP_POSITION_DETAIL.DTP_SESSION_ID%type
  , iPositionID in DOC_TMP_POSITION_DETAIL.DOC_POSITION_ID%type
  )
  is
    /* Infos de la position à créér */
    cursor lcrPos
    is
      select   sum(PDE_BASIS_QUANTITY) TOTAL_QTY
             , DOC_POSITION_ID
             , DOC_DOCUMENT_ID
          from DOC_TMP_POSITION_DETAIL
         where DTP_SESSION_ID = iSessionID
           and DOC_POSITION_ID = iPositionID
           and CRG_SELECT = 1
      group by DOC_POSITION_ID
             , DOC_DOCUMENT_ID;

    ltplPos lcrPos%rowtype;
    lnPosID DOC_POSITION.DOC_POSITION_ID%type;
    lnPdeID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    open lcrPos;

    fetch lcrPos
     into ltplPos;

    if lcrPos%found then
      lnPosID  := null;
      /* Création de la position */
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => lnPosID
                                           , aDocumentID       => ltplPos.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '110'
                                           , aBasisQuantity    => ltplPos.TOTAL_QTY
                                           , aTmpPosID         => ltplPos.DOC_POSITION_ID
                                           , aGenerateDetail   => 0
                                            );

      /* Création des détails de position */
      for tplPdeToCreate in (select   DTP.DOC_POSITION_DETAIL_ID
                                 from DOC_TMP_POSITION_DETAIL DTP
                                where DTP.DTP_SESSION_ID = iSessionID
                                  and DTP.DOC_POSITION_ID = iPositionID
                                  and DTP.CRG_SELECT = 1
                             order by DTP.DOC_POSITION_DETAIL_ID) loop
        lnPdeID  := null;
        DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => lnPdeID
                                         , aPositionID      => lnPosID
                                         , aPdeCreateMode   => '110'
                                         , aTmpPdeID        => tplPdeToCreate.DOC_POSITION_DETAIL_ID
                                          );
      end loop;

      -- Màj du flag de rupture de stock
      -- Si le détail est créé indépendament de la position (comme c'est le cas ci-dessus)
      -- il faut lancer la méthode de màj du flag de rupture de stock de la position
      DOC_FUNCTIONS.FlagPositionManco(position_id => lnPosID, document_id => null);
    end if;

    close lcrPos;

    /* Effacer la liste des détails traités de la table Temp */
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = iSessionID
            and DOC_POSITION_ID = iPositionID
            and CRG_SELECT = 1;
  end CreateSerialPositionGrouped;
end DOC_SERIAL_POS_CREATE;
