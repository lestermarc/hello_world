--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_MATCHING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_MATCHING" 
is
  /**
  * procedure AutomaticMatch
  * Description
  *   Méthode de base pour le matching d'un document DOC_INTERFACE
  * @created ngv
  * @lastUpdate
  * @public
  * @param aInterfaceID   : id DOC_INTERFACE
  */
  procedure AutomaticMatch(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aMode          in varchar2
  )
  is
    vGaugeList     ID_TABLE_TYPE                                       := ID_TABLE_TYPE();
    vGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    vThirdID       PAC_THIRD.PAC_THIRD_ID%type;
    vProcMatching  PCS.PC_EXCHANGE_SYSTEM.ECS_PROC_LOG_MATCHING%type;
    vDOI_ID        DOC_INTERFACE.DOC_INTERFACE_ID%type;
    vDOI_STATUS    DOC_INTERFACE.C_DOI_INTERFACE_STATUS%type;
    vDOI_PROTECTED DOC_INTERFACE.DOI_PROTECTED%type;
  begin
    -- id document interface
    vDOI_ID  := aInterfaceID;

    -- Récuperer l'id du document interface si c'est l'id de la position qui a été passé
    if aInterfaceID is null then
      begin
        select DOC_INTERFACE_ID
          into vDOI_ID
          from DOC_INTERFACE_POSITION
         where DOC_INTERFACE_POSITION_ID = aIntPositionID;
      exception
        when no_data_found then
          vDOI_ID  := null;
      end;
    end if;

    -- Rechercher le statut de l'interface et voir si protégé
    begin
      select nvl(C_DOI_INTERFACE_STATUS, '00')
           , nvl(DOI_PROTECTED, 0)
        into vDOI_STATUS
           , vDOI_PROTECTED
        from DOC_INTERFACE
       where DOC_INTERFACE_ID = vDOI_ID;
    exception
      when no_data_found then
        vDOI_PROTECTED  := 1;
    end;

    -- Statut '01' - En préparation, '05' - En attente de l'intervention de l'utilisateur
    if     (vDOI_ID is not null)
       and (vDOI_STATUS in('01', '05') )
       and (vDOI_PROTECTED = 0) then
      -- Renvoi la liste des gabarits source pour la décharge en fonction du
      -- gabarit cible défini sur le document DOC_INTERFACE
      vGaugeList  := GetGaugeDischSrcList(aInterfaceID => vDOI_ID);

      -- Pas de gabarit source pour la décharge
      if vGaugeList.count = 0 then
        GenInterfaceError(aInterfaceID => vDOI_ID, aErrorText => PCS.PC_FUNCTIONS.TranslateWord('Flux documents - Pas de gabarit déchargeable défini!') );
      -- Plusieurs gabarits source trouvés pour la décharge
      elsif vGaugeList.count > 1 then
        GenInterfaceError(aInterfaceID   => vDOI_ID
                        , aErrorText     => PCS.PC_FUNCTIONS.TranslateWord('Flux documents - Plusieurs gabarits déchargeables sont définis!')
                         );
      else
        -- Un seul gabarit source pour la décharge a été trouvée -> Poursuivre le matching

        -- Rechercher la méthode à utiliser pour effectuer le matching
        --vProcMatching  := 'DOC_INTERFACE_MATCHING.MatchInterface';
        select max(ECS.ECS_PROC_LOG_MATCHING)
          into vProcMatching
          from DOC_INTERFACE DOI
             , PCS.PC_EXCHANGE_SYSTEM ECS
             , PCS.PC_EXCHANGE_DATA_IN EDI
         where DOI.DOC_INTERFACE_ID = vDOI_ID
           and DOI.PC_EXCHANGE_DATA_IN_ID = EDI.PC_EXCHANGE_DATA_IN_ID
           and EDI.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

        -- Si la méthode de matching n'a pas été trouvée, mettre en erreur le document DOC_INTERFACE
        if vProcMatching is null then
          GenInterfaceError
                 (aInterfaceID   => vDOI_ID
                , aErrorText     => PCS.PC_FUNCTIONS.TranslateWord
                                                                 ('Système d''échange de données - La procédure de rapprochement logistique n''est pas définie!')
                 );
        else
          -- Execution de la méthode de matching
          begin
            execute immediate 'begin ' || vProcMatching || '(:DOI_ID, :DOP_ID, :MODE);' || ' end;'
                        using vDOI_ID, aIntPositionID, aMode;
          exception
            when others then
              GenInterfaceError(aInterfaceID   => vDOI_ID
                              , aErrorText     => PCS.PC_FUNCTIONS.TranslateWord('Erreur lors de l''éxecution de la méthode de rapprochement logistique!')
                               );
          end;
        end if;
      end if;
    end if;
  end AutomaticMatch;

  /**
  * procedure DeleteMatch
  * Description
  *   Effacement d'une ou plusieurs lignes de la table DOC_INTERFACE_MATCH
  *    avec la reconstruction des matchs manquants pour avoir le solde qté
  */
  procedure DeleteMatch(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aIntMatchID    in DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type default null
  , aCompleteMatch in integer default 1
  )
  is
    vDOP_ID DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type   default null;
  begin
    -- Sauvegarde de l'id du DOP pour reconstruire le delta des qtés à matcher
    vDOP_ID  := aIntPositionID;

    -- Balayer la ou les lignes de match à effacer
    for tplMatch in (select   DMA.DOC_INTERFACE_MATCH_ID
                            , nvl(DOP.DOP_QTY, 0) DOP_QTY
                            , DOP.DOC_INTERFACE_POSITION_ID
                            , DOP.DOC_INTERFACE_ID
                         from DOC_INTERFACE_MATCH DMA
                            , DOC_INTERFACE_POSITION DOP
                        where DMA.DOC_INTERFACE_POSITION_ID = DOP.DOC_INTERFACE_POSITION_ID
                          and DMA.DOC_INTERFACE_MATCH_ID = nvl(aIntMatchID, DMA.DOC_INTERFACE_MATCH_ID)
                          and DOP.DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOP.DOC_INTERFACE_POSITION_ID)
                          and DOP.DOC_INTERFACE_ID = nvl(aInterfaceID, DOP.DOC_INTERFACE_ID)
                     order by DMA.DOC_INTERFACE_POSITION_ID
                            , DMA.DOC_INTERFACE_MATCH_ID) loop
      -- Sauvegarde de l'id du DOP pour reconstruire le delta des qtés à matcher
      if aIntMatchID is not null then
        vDOP_ID  := tplMatch.DOC_INTERFACE_POSITION_ID;
      end if;

      -- Effacement du match
      delete from DOC_INTERFACE_MATCH
            where DOC_INTERFACE_MATCH_ID = tplMatch.DOC_INTERFACE_MATCH_ID;
    end loop;

    -- Reconstruire les matchs sans lien sur les détails avec le delta des qtés à matcher
    if aCompleteMatch = 1 then
      CompleteMatch(aInterfaceID => aInterfaceID, aIntPositionID => vDOP_ID);
    end if;
  end DeleteMatch;

  /**
  * procedure CompleteMatch
  * Description
  *   Reconstruction des matchs manquants pour avoir le solde qté
  */
  procedure CompleteMatch(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  )
  is
    vSumQty DOC_INTERFACE_MATCH.DMA_QUANTITY%type             default 0;
    vDMA_ID DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type;
  begin
    -- Balayer les positions d'interface pour vérifier le delta sur les qtés
    for tplPos in (select   DOC_INTERFACE_POSITION_ID
                          , DOP_QTY
                       from DOC_INTERFACE_POSITION
                      where DOC_INTERFACE_ID = nvl(aInterfaceID, DOC_INTERFACE_ID)
                        and DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOC_INTERFACE_POSITION_ID)
                        and GCO_GOOD_ID is not null
                        and C_INTERFACE_GEN_MODE = 'DISCHARGE'
                        and nvl(DOP_QTY, 0) <> 0
                   order by DOC_INTERFACE_POSITION_ID) loop
      -- Rechercher la qté totale de la position dans la table des matchs
      begin
        select   sum(nvl(DMA_QUANTITY, 0) )
            into vSumQty
            from DOC_INTERFACE_MATCH
           where DOC_INTERFACE_POSITION_ID = tplPOS.DOC_INTERFACE_POSITION_ID
        group by DOC_INTERFACE_POSITION_ID;
      exception
        when no_data_found then
          vSumQty  := 0;
      end;

      -- Si la qté totale des matchs est inférieure à la qté de la position
      -- il faut créer ou modifier un match pour que la qté totale corresponde
      -- à la qté de la position
      if vSumQty < tplPos.DOP_QTY then
        --  Créer ou modifier la ligne de match avec le delta de la qté ...
        vDMA_ID  := InsertMatchDetail(aIntPositionID => tplPos.DOC_INTERFACE_POSITION_ID, aDetailID => null, aQuantity =>(tplPos.DOP_QTY - vSumQty) );
      end if;
    end loop;
  end CompleteMatch;

  /**
  * function InsertMatchDetail
  * Description
  *   Insertion d'une ligne dans la table DOC_INTERFACE_MATCH
  */
  function InsertMatchDetail(
    aIntPositionID in DOC_INTERFACE_MATCH.DOC_INTERFACE_POSITION_ID%type
  , aDetailID      in DOC_INTERFACE_MATCH.DOC_POSITION_DETAIL_ID%type
  , aQuantity      in DOC_INTERFACE_MATCH.DMA_QUANTITY%type
  )
    return DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type
  is
    vDMA_ID DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type;
  begin
    -- Vérifier s'il existe une ligne match sans lien sur un détail
    begin
      select DOC_INTERFACE_MATCH_ID
        into vDMA_ID
        from DOC_INTERFACE_MATCH
       where DOC_INTERFACE_POSITION_ID = aIntPositionID
         and DOC_POSITION_DETAIL_ID is null;
    exception
      when no_data_found then
        vDMA_ID  := null;
    end;

    -- S'il existe une ligne match sans lien sur un détail, il faut màj la
    -- qté de celle-ci avec le delta des qtés totales des matchs et celle
    -- de la DOP
    -- Sinon
    --  Créer une ligne de match avec le delta de la qté ...
    if vDMA_ID is not null then
      update DOC_INTERFACE_MATCH
         set DMA_QUANTITY = aQuantity
           , DOC_POSITION_DETAIL_ID = aDetailID
       where DOC_INTERFACE_MATCH_ID = vDMA_ID;
    else
      select INIT_ID_SEQ.nextval
        into vDMA_ID
        from dual;

      insert into DOC_INTERFACE_MATCH
                  (DOC_INTERFACE_MATCH_ID
                 , DOC_INTERFACE_POSITION_ID
                 , DOC_POSITION_DETAIL_ID
                 , DMA_QUANTITY
                  )
           values (vDMA_ID
                 , aIntPositionID
                 , aDetailID
                 , aQuantity
                  );
    end if;

    return vDMA_ID;
  end InsertMatchDetail;

  /**
  * function InsertMatch
  * Description
  *   Insertion d'une ligne dans la table DOC_INTERFACE_MATCH avec le controle
  *   des données à insérer.
  */
  function InsertMatch(
    aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aDetailID      in DOC_INTERFACE_MATCH.DOC_POSITION_DETAIL_ID%type
  , aQuantity      in DOC_INTERFACE_MATCH.DMA_QUANTITY%type
  )
    return varchar2
  is
    vResult varchar2(10);
    vDMA_ID DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type;
  begin
    -- Controle des données à insérer
    vResult  := CtrlMatchDetail(aIntMatchID => null, aIntPositionID => aIntPositionID, aDetailID => aDetailID, aQuantity => aQuantity);

    -- Insertion de la ligne de match
    if vResult is null then
      vDMA_ID  := InsertMatchDetail(aIntPositionID => aIntPositionID, aDetailID => aDetailID, aQuantity => aQuantity);
    end if;

    return vResult;
  end InsertMatch;

  /**
  * procedure InsertMatch
  * Description
  *   Cette procédure appele la fonction InsertMatch, elle a été développée pour
  *     etre appelée depuis delphi
  */
  procedure InsertMatch(
    aIntPositionID in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aDetailID      in     DOC_INTERFACE_MATCH.DOC_POSITION_DETAIL_ID%type
  , aQuantity      in     DOC_INTERFACE_MATCH.DMA_QUANTITY%type
  , aErrorCode     out    varchar2
  )
  is
  begin
    aErrorCode  := InsertMatch(aIntPositionID => aIntPositionID, aDetailID => aDetailID, aQuantity => aQuantity);
  end InsertMatch;

  /**
  * function CtrlMatchDetail
  * Description
  *   Contrôle des données à insérer dans la table de match ou
  *     controle d'un ligne de la table de match (dépends des params entrants)
  */
  function CtrlMatchDetail(
    aIntMatchID    in DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type default null
  , aIntPositionID in DOC_INTERFACE_MATCH.DOC_INTERFACE_POSITION_ID%type default null
  , aDetailID      in DOC_INTERFACE_MATCH.DOC_POSITION_DETAIL_ID%type default null
  , aQuantity      in DOC_INTERFACE_MATCH.DMA_QUANTITY%type default null
  )
    return varchar2
  is
    -- Rechercher les informations de la position interface
    cursor crDop(cIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
    is
      select nvl(DOP.DOP_QTY, 0) DOP_QTY
           , DOP.GCO_GOOD_ID
           , DOP.DOC_RECORD_ID
           , case
               when(DOP.DOP_FATHER_DMT_NUMBER is not null)
               and (DOP.DOP_FATHER_POS_NUMBER is not null) then 1
               else 0
             end DISCH_WITH_LINK
           , DOI.DOC_GAUGE_ID
           , DOI.PAC_THIRD_ID
        from DOC_INTERFACE_POSITION DOP
           , DOC_INTERFACE DOI
       where DOP.DOC_INTERFACE_POSITION_ID = cIntPositionID
         and DOP.DOC_INTERFACE_ID = DOI.DOC_INTERFACE_ID;

    -- Rechercher les infos du détail à décharger
    cursor crDetailSrc(cDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE.PDE_BALANCE_QUANTITY
           , POS.GCO_GOOD_ID
           , POS.C_DOC_POS_STATUS
           , nvl(POS.DOC_RECORD_ID, DMT.DOC_RECORD_ID) DOC_RECORD_ID
           , nvl(DMT.DMT_PROTECTED, 0) DMT_PROTECTED
           , DMT.DOC_GAUGE_ID
           , DMT.PAC_THIRD_ID
           , PDE.DOC_GAUGE_FLOW_ID
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
       where PDE.DOC_POSITION_DETAIL_ID = cDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;

    tplDop       crDop%rowtype;
    tplDetailSrc crDetailSrc%rowtype;
    vPDE_ID      DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vDMA_QTY     DOC_INTERFACE_MATCH.DMA_QUANTITY%type;
    vSumMatchQty DOC_INTERFACE_MATCH.DMA_QUANTITY%type;
    vDOP_ID      DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
    vGAR_ID      DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type;
  begin
    -- Ctrl d'un match existant
    if aIntMatchID is not null then
      select DOC_INTERFACE_POSITION_ID
           , DOC_POSITION_DETAIL_ID
           , DMA_QUANTITY
        into vDOP_ID
           , vPDE_ID
           , vDMA_QTY
        from DOC_INTERFACE_MATCH DMA
       where DMA.DOC_INTERFACE_MATCH_ID = aIntMatchID;

      -- Vérifier le total de la qté matchée pour le DOP_ID
      select nvl(sum(DMA_QUANTITY), 0)
        into vSumMatchQty
        from DOC_INTERFACE_MATCH
       where DOC_INTERFACE_POSITION_ID = vDOP_ID;
    else
      -- Ctrl d'un match à insérer
      vDOP_ID   := aIntPositionID;
      vPDE_ID   := aDetailID;
      vDMA_QTY  := aQuantity;

      -- Vérifier le total de la qté matchée pour le DOP_ID
      select nvl(sum(DMA_QUANTITY), 0)
        into vSumMatchQty
        from DOC_INTERFACE_MATCH
       where DOC_INTERFACE_POSITION_ID = vDOP_ID
         and DOC_POSITION_DETAIL_ID is not null;
    end if;

    -- Rechercher les infos de la position interface
    open crDop(vDOP_ID);

    fetch crDop
     into tplDop;

    close crDop;

    -- Qté totale des rapprochements est supérieure à la DOP_QTY
    if (vSumMatchQty + nvl(aQuantity, 0) ) > tplDop.DOP_QTY then
      -- Màj du code d'erreur sur la ligne de match
      UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '07');
      return '07';   -- Qté totale des rapprochements est supérieure à la qté position
    end if;

    -- S'il y a un lien sur un détail, cela veut dire que l'on va effectuer une
    -- décharge. Donc, il faut faire divers controles en relation.
    if vPDE_ID is not null then
      -- Rechercher les infos du détail à décharger
      open crDetailSrc(vPDE_ID);

      fetch crDetailSrc
       into tplDetailSrc;

      close crDetailSrc;

      -- Décharge avec le lien donné par l'utilisateur dans les champs
      -- DOP_FATHER_DMT_NUMBER et DOP_FATHER_POS_NUMBER de la position interface
      if tplDop.DISCH_WITH_LINK = 1 then
        -- Vérifier que l'on ai le même partenaire entre la source et la cible
        if (tplDetailSrc.PAC_THIRD_ID <> tplDop.PAC_THIRD_ID) then
          UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '09');
          return '09';   -- Partenaire différent entre la source et cible
        end if;

        -- Vérifier que l'on ai le même bien entre la source et la cible
        if (tplDetailSrc.GCO_GOOD_ID <> tplDop.GCO_GOOD_ID) then
          UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '10');
          return '10';   -- Bien différent entre la source et cible
        end if;

        -- Vérification du dossier entre la source et la cible
        if     (tplDop.DOC_RECORD_ID is not null)
           and (tplDetailSrc.DOC_RECORD_ID is not null)
           and (tplDop.DOC_RECORD_ID <> tplDetailSrc.DOC_RECORD_ID) then
          UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '11');
          return '11';   -- Dossier différent entre la source et cible
        end if;
      end if;

      -- Le doc source est protégé
      if tplDetailSrc.DMT_PROTECTED = 1 then
        -- Màj du code d'erreur sur la ligne de match
        UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '04');
        return '04';   -- Le document à décharger est protégé
      end if;

      if tplDetailSrc.C_DOC_POS_STATUS not in('02', '03') then
        -- Màj du code d'erreur sur la ligne de match
        UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '05');
        return '05';   -- Le statut de la position à décharger n'est pas correct
      end if;

      -- Rechercher la somme des qtés qui sont matchées sur le même détail que
      -- le match actuel
      if aIntMatchID is not null then
        select sum(nvl(DMA_QUANTITY, 0) )
          into vSumMatchQty
          from DOC_INTERFACE_MATCH
         where DOC_INTERFACE_MATCH_ID <> aIntMatchID
           and DOC_POSITION_DETAIL_ID = vPDE_ID;
      else
        select sum(nvl(DMA_QUANTITY, 0) )
          into vSumMatchQty
          from DOC_INTERFACE_MATCH
         where DOC_POSITION_DETAIL_ID = vPDE_ID;
      end if;

      -- Qté solde sur le détail est suffisante pour tous les matchs sur celui-ci
      if tplDetailSrc.PDE_BALANCE_QUANTITY <(vDMA_QTY + vSumMatchQty) then
        -- Màj du code d'erreur sur la ligne de match
        UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '06');
        return '06';   -- Qté solde insuffisante sur le détail à décharger
      end if;

      -- Vérifier le flux de décharge entre les 2 gabarits
      if DOC_I_LIB_GAUGE.CanReceipt(iGaugeSrc => tplDetailSrc.DOC_GAUGE_ID, iGaugeDst => tplDop.DOC_GAUGE_ID, iPosDetailId => vPDE_ID) = 0 then
        -- Màj du code d'erreur sur la ligne de match
        UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '01');
        return '01';   -- Pas de flux de décharge entre les 2 gabarits
      end if;

      -- S'il y a un changement de bien ou de partenaire, il faut faire une
      -- vérification pour voir si le flux le permet
      if    (tplDetailSrc.GCO_GOOD_ID <> tplDop.GCO_GOOD_ID)
         or (tplDetailSrc.PAC_THIRD_ID <> tplDop.PAC_THIRD_ID) then
        vGAR_ID  :=
          DOC_I_LIB_GAUGE.GetGaugeReceiptID(iSourceGaugeID   => tplDetailSrc.DOC_GAUGE_ID
                                          , iTargetGaugeID   => tplDop.DOC_GAUGE_ID
                                          , iThirdID         => tplDop.PAC_THIRD_ID
                                          , iFlowID          => tplDetailSrc.DOC_GAUGE_FLOW_ID
                                           );

        -- S'il y a un changement de bien, il faut vérifier si celui-ci est autorisé
        if (tplDetailSrc.GCO_GOOD_ID <> tplDop.GCO_GOOD_ID) then
          if DOC_I_LIB_GAUGE.GetGaugeReceiptFlag(iReceiptID => vGAR_ID, iFieldName => 'GAR_GOOD_CHANGING') = 0 then
            -- Màj du code d'erreur sur la ligne de match
            UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '02');
            return '02';   -- Le changement de bien n'est pas autorisé dans le flux
          end if;
        end if;

        -- S'il y a un changement de partenaire, il faut vérifier si celui-ci est autorisé
        if (tplDetailSrc.PAC_THIRD_ID <> tplDop.PAC_THIRD_ID) then
          if DOC_I_LIB_GAUGE.GetGaugeReceiptFlag(iReceiptID => vGAR_ID, iFieldName => 'GAR_PARTNER_CHANGING') = 0 then
            -- Màj du code d'erreur sur la ligne de match
            UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '03');
            return '03';   -- Le changement de partenaire n'est pas autorisé dans le flux
          end if;
        end if;
      end if;
    else
        -- Pas de lien de décharge sur le détail parent
      -- Décharge avec le lien donné par l'utilisateur dans les champs
      -- DOP_FATHER_DMT_NUMBER et DOP_FATHER_POS_NUMBER de la position interface
      if tplDop.DISCH_WITH_LINK = 1 then
        -- Position à décharger introuvable
        UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => '08');
        return '08';   -- Position à décharger introuvable
      end if;
    end if;

    -- Màj du code d'erreur sur la ligne de match à NULL
    UpdateMatchErrorCode(aIntMatchID => aIntMatchID, aErrorCode => null);
    return null;
  end CtrlMatchDetail;

  /**
  * procedure CtrlMatchDetail
  * Description
  *   Cette procédure appele la fonction CtrlMatchDetail, elle a été développée pour
  *     etre appelée depuis delphi
  */
  procedure CtrlMatchDetail(
    aIntMatchID    in     DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type
  , aIntPositionID in     DOC_INTERFACE_MATCH.DOC_INTERFACE_POSITION_ID%type
  , aDetailID      in     DOC_INTERFACE_MATCH.DOC_POSITION_DETAIL_ID%type
  , aQuantity      in     DOC_INTERFACE_MATCH.DMA_QUANTITY%type
  , aErrorCode     out    varchar2
  )
  is
  begin
    aErrorCode  := CtrlMatchDetail(aIntMatchID => aIntMatchID, aIntPositionID => aIntPositionID, aDetailID => aDetailID, aQuantity => aQuantity);
  end CtrlMatchDetail;

  /**
  * procedure UpdateMatchErrorCode
  * Description
  *   Màj du code d'erreur sur la ligne de match passée en param
  */
  procedure UpdateMatchErrorCode(aIntMatchID in DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type, aErrorCode in varchar2 default null)
  is
  begin
    update DOC_INTERFACE_MATCH
       set C_DOC_INT_MATCH_ERROR = aErrorCode
     where DOC_INTERFACE_MATCH_ID = aIntMatchID;
  end UpdateMatchErrorCode;

  /**
  * function ControlMatch
  * Description
  *   Contrôle de cohérance des données des matchs
  */
  function ControlMatch(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type default null
  , aIntMatchID    in DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type default null
  )
    return varchar2
  is
    vErrorCode varchar2(10)                                            default null;
    vResult    varchar2(10)                                            default null;
    vDOP_ID    DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type   default null;
  begin
    vDOP_ID  := aIntPositionID;

    -- Balayer les lignes de match à controler
    for tplMatch in (select   DMA.DOC_INTERFACE_MATCH_ID
                            , DOP.DOC_INTERFACE_POSITION_ID
                         from DOC_INTERFACE_MATCH DMA
                            , DOC_INTERFACE_POSITION DOP
                        where DMA.DOC_INTERFACE_POSITION_ID = DOP.DOC_INTERFACE_POSITION_ID
                          and DMA.DOC_INTERFACE_MATCH_ID = nvl(aIntMatchID, DMA.DOC_INTERFACE_MATCH_ID)
                          and DOP.DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOP.DOC_INTERFACE_POSITION_ID)
                          and DOP.DOC_INTERFACE_ID = nvl(aInterfaceID, DOP.DOC_INTERFACE_ID)
                     order by DMA.DOC_INTERFACE_POSITION_ID
                            , DMA.DOC_INTERFACE_MATCH_ID) loop
      -- Sauvegarder l'ID du DOP pour effectuer le ctrl sur la qté totale matchée
      if aIntMatchID is not null then
        vDOP_ID  := tplMatch.DOC_INTERFACE_POSITION_ID;
      end if;

      -- Controle d'une ligne de match
      vErrorCode  := CtrlMatchDetail(aIntMatchID => tplMatch.DOC_INTERFACE_MATCH_ID);
      -- Valeur de retour
      vResult     := nvl(vResult, vErrorCode);
    end loop;

    -- Si le controle globale est ok, il faut vérifier si toutes les positions
    -- sont totalement matchées.
    -- Si ce n'est pas le cas, Màj de la variable du controle globale à Match partiel
    if vResult is null then
      -- Résultat du ctrl, valeurs possibles :
      -- 00 - Match complet et correct
      -- 99 - Pas d'erreur mais au moins une position n'est pas totalement matché
      select case
               when count(DOP.DOC_INTERFACE_POSITION_ID) = 0 then '00'
               else '99'
             end
        into vResult
        from (select DOC_INTERFACE_POSITION_ID
                   , nvl(DOP_QTY, 0) DOP_QTY
                from DOC_INTERFACE_POSITION
               where DOC_INTERFACE_ID = nvl(aInterfaceID, DOC_INTERFACE_ID)
                 and DOC_INTERFACE_POSITION_ID = nvl(vDOP_ID, DOC_INTERFACE_POSITION_ID)
                 and GCO_GOOD_ID is not null
                 and C_INTERFACE_GEN_MODE = 'DISCHARGE'
                 and nvl(DOP_QTY, 0) <> 0) DOP
           , (select   DMA.DOC_INTERFACE_POSITION_ID
                     , sum(DMA.DMA_QUANTITY) DMA_QUANTITY
                  from DOC_INTERFACE DOI
                     , DOC_INTERFACE_POSITION DOP
                     , DOC_INTERFACE_MATCH DMA
                 where DOI.DOC_INTERFACE_ID = nvl(aInterfaceID, DOI.DOC_INTERFACE_ID)
                   and DOI.DOC_INTERFACE_ID = DOP.DOC_INTERFACE_ID
                   and DOP.DOC_INTERFACE_POSITION_ID = nvl(vDOP_ID, DOP.DOC_INTERFACE_POSITION_ID)
                   and DMA.DOC_INTERFACE_POSITION_ID = DOP.DOC_INTERFACE_POSITION_ID
                   and DMA.DOC_POSITION_DETAIL_ID is not null
              group by DMA.DOC_INTERFACE_POSITION_ID) DMA
       where DOP.DOC_INTERFACE_POSITION_ID = DMA.DOC_INTERFACE_POSITION_ID(+)
         and DOP.DOP_QTY <> nvl(DMA.DMA_QUANTITY, -1);
    end if;

    return vResult;
  end ControlMatch;

  /**
  * procedure ControlMatch
  * Description
  *   Cette procédure appele la fonction ControlMatch, elle a été développée pour
  *     etre appelée depuis delphi
  */
  procedure ControlMatch(
    aInterfaceID   in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aIntMatchID    in     DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type
  , aResult        out    varchar2
  )
  is
  begin
    aResult  := ControlMatch(aInterfaceID => aInterfaceID, aIntPositionID => aIntPositionID, aIntMatchID => aIntMatchID);
  end ControlMatch;

  /**
  * function ValidateMatch
  * Description
  *   Mise en place des liens sur les positions pour la décharge et
  *     effacement des données de la table de match
  */
  function ValidateMatch(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return integer
  is
  begin
    -- Etablir les liens de match sur la table DOP
    ApplyMatch(aInterfaceID => aInterfaceID);
    -- Effacer les données de la table de match
    DeleteMatch(aInterfaceID => aInterfaceID, aCompleteMatch => 0);
    return 1;
  exception
    when others then
      return 0;
  end ValidateMatch;

  /**
  * procedure ValidateMatch
  * Description
  *   Mise en place des liens sur les positions pour la décharge et
  *     effacement des données de la table de match
  */
  procedure ValidateMatch(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, aResult out integer)
  is
  begin
    aResult  := ValidateMatch(aInterfaceID => aInterfaceID);
  end ValidateMatch;

  /**
  * procedure ApplyMatch
  * Description
  *   Mise en place des liens de décharge sur les positions DOP pour tout un
  *     document DOC_INTERFACE
  */
  procedure ApplyMatch(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    vDOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type   default null;
  begin
    -- Traiter les positions qui ne se trouvent pas dans la table de match
    -- pour les mettre en mode de création "INSERT"
    for tplPos in (select   DOC_INTERFACE_POSITION_ID
                       from DOC_INTERFACE_POSITION
                      where DOC_INTERFACE_ID = aInterfaceID
                        and DOC_INTERFACE_ORIGIN_POS_ID is null
                        and C_INTERFACE_GEN_MODE = 'DISCHARGE'
                        and nvl(DOP_QTY, 0) <> 0
                   minus
                   select   DOP.DOC_INTERFACE_POSITION_ID
                       from DOC_INTERFACE_POSITION DOP
                          , DOC_INTERFACE_MATCH DMA
                      where DOP.DOC_INTERFACE_ID = aInterfaceID
                        and DMA.DOC_INTERFACE_POSITION_ID = DOP.DOC_INTERFACE_POSITION_ID
                   group by DOP.DOC_INTERFACE_POSITION_ID
                   order by DOC_INTERFACE_POSITION_ID) loop
      -- Metre ces positions en mode de création "INSERT"
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = '02'
           , DOC_POSITION_DETAIL_ID = null
           , DOC_POSITION_ID = null
           , DOC_DOCUMENT_ID = null
           , C_INTERFACE_GEN_MODE = 'INSERT'
           , DOP_ERROR = 0
           , DOP_ERROR_MESSAGE = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_POSITION_ID = tplPos.DOC_INTERFACE_POSITION_ID;
    end loop;

    -- Balayer la table de match pour le DOP_ID pour effectuer les Màj ou les splits
    for tplMatch in (select   DOP.DOC_INTERFACE_POSITION_ID
                         from DOC_INTERFACE_POSITION DOP
                            , DOC_INTERFACE_MATCH DMA
                        where DOP.DOC_INTERFACE_ID = aInterfaceID
                          and DMA.DOC_INTERFACE_POSITION_ID = DOP.DOC_INTERFACE_POSITION_ID
                     group by DOP.DOC_INTERFACE_POSITION_ID
                     order by DOP.DOC_INTERFACE_POSITION_ID) loop
      -- Mise en place des liens de décharge pour la position en cours
      ApplyMatchPosition(aIntPositionID => tplMatch.DOC_INTERFACE_POSITION_ID);
    end loop;

    -- Mise en place du lien de décharge sur le document DOC_INTERFACE
    ApplyMatchDocument(aInterfaceID => aInterfaceID);
  end ApplyMatch;

  /**
  * procedure ApplyMatchDocument
  * Description
  *   Mise en place du lien de décharge sur le document DOC_INTERFACE
  */
  procedure ApplyMatchDocument(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    vDOC_ID_SRC DOC_DOCUMENT.DOC_DOCUMENT_ID%type   default null;
  begin
    -- Vérifier si un document source est spécifié dans l'interface DOCUMENT
    begin
      select DMT.DOC_DOCUMENT_ID
        into vDOC_ID_SRC
        from DOC_INTERFACE DOI
           , DOC_DOCUMENT DMT
       where DOI.DOC_INTERFACE_ID = aInterfaceID
         and DMT.DMT_NUMBER = DOI.DOI_FATHER_DMT_NUMBER;
    exception
      when no_data_found then
        vDOC_ID_SRC  := null;
    end;

    if vDOC_ID_SRC is null then
      -- Rechercher le DOC_ID pour le lien de décharge d'en-tête de document
      -- en utilisant le 1er DOC_ID trouvé dans le DOP par ordre croissant du DOP_ID
      begin
        select   DOC_DOCUMENT_ID
            into vDOC_ID_SRC
            from DOC_INTERFACE_POSITION
           where DOC_INTERFACE_ID = aInterfaceID
             and C_INTERFACE_GEN_MODE = 'DISCHARGE'
             and DOC_DOCUMENT_ID is not null
             and rownum = 1
        order by DOC_INTERFACE_POSITION_ID;
      exception
        when no_data_found then
          vDOC_ID_SRC  := null;
      end;
    end if;

    update DOC_INTERFACE
       set DOC_DOCUMENT_ID = vDOC_ID_SRC
         , C_DOI_INTERFACE_STATUS = '02'
         , C_INTERFACE_GEN_MODE = case
                                   when vDOC_ID_SRC is not null then 'DISCHARGE'
                                   else 'INSERT'
                                 end
         , DOI_ERROR = 0
         , DOI_ERROR_MESSAGE = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_ID = aInterfaceID;
  end ApplyMatchDocument;

  /**
  * procedure ApplyMatchPosition
  * Description
  *   Mise en place des liens de décharge sur les positions DOP pour une
  *     position DOC_INTERFACE_POSITION
  */
  procedure ApplyMatchPosition(aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
  is
    vFirst          boolean                                                 default true;
    vDOP_QTY_ORIGIN DOC_INTERFACE_POSITION.DOP_QTY%type                     default 0;
    vQtySum         DOC_INTERFACE_POSITION.DOP_QTY%type                     default 0;
    vID             DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
  begin
    -- Sauvegarder la qté DOP de base
    select nvl(DOP_QTY, 0)
      into vDOP_QTY_ORIGIN
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_POSITION_ID = aIntPositionID;

    -- Balayer la table de match pour le DOP_ID pour effectuer les Màj ou les splits
    for tplMatch in (select   PDE.DOC_POSITION_DETAIL_ID
                            , PDE.DOC_POSITION_ID
                            , PDE.DOC_DOCUMENT_ID
                            , nvl(DMA.DMA_QUANTITY, 0) DMA_QUANTITY
                            , case
                                when PDE.DOC_POSITION_DETAIL_ID is not null then 'DISCHARGE'
                                else 'INSERT'
                              end GEN_MODE
                         from DOC_POSITION_DETAIL PDE
                            , DOC_INTERFACE_MATCH DMA
                        where DMA.DOC_INTERFACE_POSITION_ID = aIntPositionID
                          and DMA.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID(+)
                     order by PDE.DOC_DOCUMENT_ID asc nulls last
                            , PDE.DOC_POSITION_ID asc nulls last
                            , PDE.DOC_POSITION_DETAIL_ID asc nulls last) loop
      -- Si c'est la 1ere ligne, on fait une màj du DOP existant
      if vFirst then
        vFirst  := false;

        update DOC_INTERFACE_POSITION
           set C_DOP_INTERFACE_STATUS = '02'
             , C_INTERFACE_GEN_MODE = tplMatch.GEN_MODE
             , DOP_QTY = tplMatch.DMA_QUANTITY
             , DOP_QTY_VALUE = tplMatch.DMA_QUANTITY
             , DOC_POSITION_DETAIL_ID = tplMatch.DOC_POSITION_DETAIL_ID
             , DOC_POSITION_ID = tplMatch.DOC_POSITION_ID
             , DOC_DOCUMENT_ID = tplMatch.DOC_DOCUMENT_ID
             , DOP_ERROR = 0
             , DOP_ERROR_MESSAGE = null
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_INTERFACE_POSITION_ID = aIntPositionID;
      else
        -- Créer une nouvelle DOP avec comme origine la DOP de base
        vID  :=
          SplitPosition(aIntPositionID   => aIntPositionID
                      , aGenMode         => tplMatch.GEN_MODE
                      , aQuantity        => tplMatch.DMA_QUANTITY
                      , aDetailID        => tplMatch.DOC_POSITION_DETAIL_ID
                      , aPositionID      => tplMatch.DOC_POSITION_ID
                      , aDocumentID      => tplMatch.DOC_DOCUMENT_ID
                       );
      end if;

      -- Cummul de la qté utilisée
      vQtySum  := vQtySum + tplMatch.DMA_QUANTITY;
    end loop;

    -- S'il y a une qté solde, il faut créer une ligne DOP avec le code INSERT
    if (vQtySum < vDOP_QTY_ORIGIN) then
      vID  :=
        SplitPosition(aIntPositionID   => aIntPositionID
                    , aGenMode         => 'INSERT'
                    , aQuantity        => vDOP_QTY_ORIGIN - vQtySum
                    , aDetailID        => null
                    , aPositionID      => null
                    , aDocumentID      => null
                     );
    end if;
  end ApplyMatchPosition;

  /**
  * procedure UndoMatch
  * Description
  *   Effacement des splits et regroupement pour evenir à l'état initial des positions
  *     pour tout le document DOC_INTERFACE
  */
  procedure UndoMatch(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
  begin
    -- Balayer la table de match pour le DOP_ID pour effectuer les Màj ou les splits
    for tplMatch in (select   DOP.DOC_INTERFACE_POSITION_ID
                         from DOC_INTERFACE_POSITION DOP
                        where DOP.DOC_INTERFACE_ID = aInterfaceID
                          and DOP.DOC_INTERFACE_ORIGIN_POS_ID is null
                          and DOP.GCO_GOOD_ID is not null
                     order by DOP.DOC_INTERFACE_POSITION_ID) loop
      -- Effacement des splits de la position courante
      UndoMatchPosition(aIntPositionID => tplMatch.DOC_INTERFACE_POSITION_ID);
    end loop;

    -- Màj de la ligne DOI en enlevant les liens de décharge
    update DOC_INTERFACE
       set C_DOI_INTERFACE_STATUS = '01'
         , DOI_ERROR = 0
         , DOI_ERROR_MESSAGE = null
         , DOC_DOCUMENT_ID = null
         , C_INTERFACE_GEN_MODE = DOI_ORIGIN_GEN_MODE
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_ID = aInterfaceID;
  end UndoMatch;

  /**
  * procedure UndoMatchPosition
  * Description
  *   Effacement des splits et regroupement pour evenir à l'état initial des positions
  *     pour une position DOC_INTERFACE_POSITION
  */
  procedure UndoMatchPosition(aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
  is
    vDOI_ID        DOC_INTERFACE.DOC_INTERFACE_ID%type;
    vDOP_ORIGIN_ID DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
    vDOP_QTY       DOC_INTERFACE_POSITION.DOP_QTY%type                     default 0;
  begin
    -- Rechercher l'id de la position origine et l'id du doc_interface
    select DOC_INTERFACE_ID
         , nvl(DOC_INTERFACE_ORIGIN_POS_ID, DOC_INTERFACE_POSITION_ID)
      into vDOI_ID
         , vDOP_ORIGIN_ID
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_POSITION_ID = aIntPositionID;

    -- Récupérer la qté totale pour la position ainsi que les éventuels splits
    select sum(nvl(DOP_QTY, 0) )
      into vDOP_QTY
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_ID = vDOI_ID
       and nvl(DOC_INTERFACE_ORIGIN_POS_ID, DOC_INTERFACE_POSITION_ID) = vDOP_ORIGIN_ID;

    -- Màj de la ligne DOP en enlevant les liens de décharge
    update DOC_INTERFACE_POSITION
       set C_DOP_INTERFACE_STATUS = '01'
         , DOP_ERROR = 0
         , DOP_ERROR_MESSAGE = null
         , DOP_QTY = vDOP_QTY
         , DOP_QTY_VALUE = vDOP_QTY
         , DOC_DOCUMENT_ID = null
         , DOC_POSITION_ID = null
         , DOC_POSITION_DETAIL_ID = null
         , C_INTERFACE_GEN_MODE = DOP_ORIGIN_GEN_MODE
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_POSITION_ID = vDOP_ORIGIN_ID;

    -- Si la DOP de départ a été splittée, effacer les DOP issus de ce split
    delete from DOC_INTERFACE_POSITION
          where DOC_INTERFACE_ID = vDOI_ID
            and DOC_INTERFACE_ORIGIN_POS_ID = vDOP_ORIGIN_ID;
  end UndoMatchPosition;

  /**
  * function SplitPosition
  * Description
  *   Split d'une position DOC_INTERFACE_POSITION et création d'une nouvelle
  *     avec une certaine qté passée en param
  */
  function SplitPosition(
    aIntPositionID DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aGenMode       DOC_INTERFACE_POSITION.C_INTERFACE_GEN_MODE%type
  , aQuantity      DOC_INTERFACE_POSITION.DOP_QTY%type
  , aDetailID      DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aPositionID    DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentID    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
    return DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  is
    vDOP_ID DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
    vDOP    DOC_INTERFACE_POSITION%rowtype;
  begin
    -- ID de la nouvelle position
    select INIT_ID_SEQ.nextval
      into vDOP_ID
      from dual;

    -- Données de la position à spliter
    select *
      into vDOP
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_POSITION_ID = aIntPositionID;

    vDOP.DOC_INTERFACE_POSITION_ID    := vDOP_ID;
    vDOP.DOC_INTERFACE_ORIGIN_POS_ID  := aIntPositionID;
    vDOP.C_DOP_INTERFACE_STATUS       := '02';
    vDOP.DOP_POS_NUMBER               := null;
    vDOP.DOP_QTY                      := aQuantity;
    vDOP.DOP_QTY_VALUE                := aQuantity;
    vDOP.DOC_DOCUMENT_ID              := aDocumentID;
    vDOP.DOC_POSITION_ID              := aPositionID;
    vDOP.DOC_POSITION_DETAIL_ID       := aDetailID;
    vDOP.C_INTERFACE_GEN_MODE         := aGenMode;
    vDOP.A_DATECRE                    := sysdate;
    vDOP.A_IDCRE                      := PCS.PC_I_LIB_SESSION.GetUserIni;
    vDOP.A_DATEMOD                    := null;
    vDOP.A_IDMOD                      := null;
    vDOP.A_DATEMOD                    := null;
    vDOP.A_IDMOD                      := null;
    vDOP.DOP_ERROR                    := 0;
    vDOP.DOP_ERROR_MESSAGE            := null;

    insert into DOC_INTERFACE_POSITION
         values vDOP;

    return vDOP_ID;
  end SplitPosition;

  /**
  * function GetGaugeDischSrcList
  * Description
  *   Renvoi la liste des gabarits source pour la décharge en fonction du
  *     gabarit cible défini sur le document DOC_INTERFACE
  */
  function GetGaugeDischSrcList(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return ID_TABLE_TYPE
  is
    vGaugeList ID_TABLE_TYPE                 := ID_TABLE_TYPE();
    vGaugeID   DOC_GAUGE.DOC_GAUGE_ID%type;
    vThirdID   PAC_THIRD.PAC_THIRD_ID%type;
  begin
    -- Rechercher le gabarit et tiers du document cible
    select DOC_GAUGE_ID
         , PAC_THIRD_ID
      into vGaugeID
         , vThirdID
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = aInterfaceID;

    -- Liste des ids gabarits source
    vGaugeList  := DOC_I_LIB_GAUGE.GetGaugeSrcListDischarge(iGaugeID => vGaugeID, iThirdID => vThirdID);
    return vGaugeList;
  end GetGaugeDischSrcList;

  /**
  * procedure GenInterfaceError
  * Description
  *   Màj du code d'erreur sur le document DOC_INTERFACE
  */
  procedure GenInterfaceError(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, aErrorText in varchar2)
  is
  begin
    update DOC_INTERFACE
       set C_DOI_INTERFACE_STATUS = '90'
         , DOI_ERROR = 1
         , DOI_ERROR_MESSAGE = substr(aErrorText, 1, 4000)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_ID = aInterfaceID;
  end GenInterfaceError;

  /**
  * procedure GenIntPositonError
  * Description
  *   Màj du code d'erreur sur la position DOC_INTERFACE_POSITION
  */
  procedure GenIntPositonError(aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type, aErrorText in varchar2)
  is
  begin
    update DOC_INTERFACE_POSITION
       set C_DOP_INTERFACE_STATUS = '90'
         , DOP_ERROR = 1
         , DOP_ERROR_MESSAGE = substr(aErrorText, 1, 4000)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_POSITION_ID = aIntPositionID;
  end GenIntPositonError;

  /**
  * function GetMatchBalanceQty
  * Description
  *   Retourne la quantité restante a matcher
  */
  function GetMatchBalanceQty(aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
    return DOC_INTERFACE_MATCH.DMA_QUANTITY%type
  is
    vDOP_QTY     DOC_INTERFACE_POSITION.DOP_QTY%type;
    vSumMatchQty DOC_INTERFACE_MATCH.DMA_QUANTITY%type;
  begin
    -- Qté déjà matchée
    begin
      select nvl(sum(nvl(DMA_QUANTITY, 0) ), 0)
        into vSumMatchQty
        from DOC_INTERFACE_MATCH
       where DOC_INTERFACE_POSITION_ID = aIntPositionID
         and DOC_POSITION_DETAIL_ID is not null;
    exception
      when no_data_found then
        vSumMatchQty  := 0;
    end;

    -- Qté de la position
    select nvl(DOP_QTY, 0)
      into vDOP_QTY
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_POSITION_ID = aIntPositionID;

    return greatest( (vDOP_QTY - vSumMatchQty), 0);
  end GetMatchBalanceQty;

  /**
  * procedure MatchInterface
  * Description
  *   Méthode de base pour le matching d'un document DOC_INTERFACE
  * @created ngv
  * @lastUpdate
  * @public
  * @param aInterfaceID   : id DOC_INTERFACE
  */
  procedure MatchInterface(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aMode          in varchar2
  )
  is
    vDOI_ID    DOC_INTERFACE.DOC_INTERFACE_ID%type   default null;
    vGaugeList ID_TABLE_TYPE                         := ID_TABLE_TYPE();
    vDMT_SRC   DOC_DOCUMENT.DMT_NUMBER%type;
  begin
    -- id document interface
    vDOI_ID  := aInterfaceID;

    -- Récuperer l'id du document interface si c'est l'id de la position qui a été passé
    if aInterfaceID is null then
      select DOC_INTERFACE_ID
        into vDOI_ID
        from DOC_INTERFACE_POSITION
       where DOC_INTERFACE_POSITION_ID = aIntPositionID;
    end if;

    -- Stoper le traitement si pas d'id document interface
    if vDOI_ID is not null then
      -- Mode
      --   01 : compléter
      --   02 : reconstruction
      if aMode = '02' then
        -- En mode reconstruction, effacer les matchs existants
        if aIntPositionID is not null then
          delete from DOC_INTERFACE_MATCH
                where DOC_INTERFACE_POSITION_ID = aIntPositionID;
        else
          delete from DOC_INTERFACE_MATCH
                where DOC_INTERFACE_POSITION_ID in(select DOC_INTERFACE_POSITION_ID
                                                     from DOC_INTERFACE_POSITION
                                                    where DOC_INTERFACE_ID = aInterfaceID);
        end if;
      end if;

      -- Méthode de base pour le matching des positions
      MatchPositions(aInterfaceID => vDOI_ID, aIntPositionID => aIntPositionID);
    end if;
  end MatchInterface;

  /**
  * procedure MatchPositions
  * Description
  *   Méthode de base pour le matching des positions
  */
  procedure MatchPositions(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
  is
    vCount integer;
  begin
    -- Vérifier s'il y a une référence sur la position source à décharge
    select count(DOC_INTERFACE_POSITION_ID)
      into vCount
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_ID = nvl(aInterfaceID, DOC_INTERFACE_ID)
       and DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOC_INTERFACE_POSITION_ID)
       and GCO_GOOD_ID is not null
       and C_INTERFACE_GEN_MODE = 'DISCHARGE'
       and nvl(DOP_QTY, 0) <> 0
       and DOP_FATHER_DMT_NUMBER is not null
       and DOP_FATHER_POS_NUMBER is not null;

    -- Positions avec lien sur la position source
    if vCount > 0 then
      MatchPosWithLink(aInterfaceID => aInterfaceID, aIntPositionID => aIntPositionID);
    else
      MatchPosWithoutLink(aInterfaceID => aInterfaceID, aIntPositionID => aIntPositionID);
    end if;

    -- Reconstruire les matchs sans lien sur les détails avec le delta des qtés à matcher
    CompleteMatch(aInterfaceID => aInterfaceID, aIntPositionID => aIntPositionID);
  end MatchPositions;

  /**
  * procedure MatchPosWithLink
  * Description
  *   Méthode de matching des positions pour les positions interface dont le
  *     lien sur la position source est défini dans les champs
  *     DOP_FATHER_DMT_NUMBER et DOP_FATHER_POS_NUMBER
  */
  procedure MatchPosWithLink(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
  is
    -- Détails document/position source
    -- Le tri se fait :
    -- 1. Qté solde du détail = Qté à matcher
    -- 2. Qté solde du détail > Qté à matcher
    -- 3. Délai du détail par ordre croissant
    -- 4. Id du détail par ordre croissant
    cursor crDetail(
      cDocFather   DOC_DOCUMENT.DMT_NUMBER%type
    , cPosFather   DOC_POSITION.POS_NUMBER%type
    , cDelayFather DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
    , cQtyToMatch  DOC_INTERFACE_MATCH.DMA_QUANTITY%type
    )
    is
      select   DOC_POSITION_DETAIL_ID
             , PDE_BALANCE_QUANTITY
          from (select PDE.DOC_POSITION_DETAIL_ID
                     , PDE.PDE_FINAL_QUANTITY
                     , PDE.PDE_BALANCE_QUANTITY - (select nvl(sum(DMA_QUANTITY), 0)
                                                     from DOC_INTERFACE_MATCH
                                                    where DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) as PDE_BALANCE_QUANTITY
                     , PDE.PDE_BASIS_DELAY
                     , POS.POS_BALANCE_QUANTITY
                     , POS.DOC_RECORD_ID POS_DOC_RECORD_ID
                     , DMT.DOC_RECORD_ID DMT_DOC_RECORD_ID
                  from DOC_POSITION_DETAIL PDE
                     , DOC_POSITION POS
                     , DOC_DOCUMENT DMT
                 where DMT.DMT_NUMBER = cDocFather
                   and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                   and POS.POS_NUMBER = cPosFather
                   and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                   and PDE.PDE_BASIS_DELAY = nvl(cDelayFather, PDE.PDE_BASIS_DELAY)
                   and PDE.PDE_BALANCE_QUANTITY - (select nvl(sum(DMA_QUANTITY), 0)
                                                     from DOC_INTERFACE_MATCH
                                                    where DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) > 0)
      order by (case
                  when cQtyToMatch = PDE_BALANCE_QUANTITY then 1
                  else 0
                end) desc
             , (case
                  when cQtyToMatch < PDE_BALANCE_QUANTITY then 1
                  else 0
                end) desc
             , PDE_BASIS_DELAY asc
             , DOC_POSITION_DETAIL_ID asc;

    tplPde      crDetail%rowtype;
    vDMA_ID     DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type;
    vMatchedQty DOC_INTERFACE_MATCH.DMA_QUANTITY%type             default 0;
    vQty        DOC_INTERFACE_MATCH.DMA_QUANTITY%type             default 0;
  begin
    -- Liste des positions interface à balayer pour effectuer le match en fonction
    -- des liens définis dans les champs DOP_FATHER_DMT_NUMBER et DOP_FATHER_POS_NUMBER
    for tplDop in (select   DOC_INTERFACE_POSITION_ID
                          , DOP_FATHER_DMT_NUMBER
                          , DOP_FATHER_POS_NUMBER
                          , DOP_FATHER_DELAY
                          , nvl(DOP_QTY, 0) DOP_QTY
                          , DOC_RECORD_ID
                       from DOC_INTERFACE_POSITION
                      where DOC_INTERFACE_ID = nvl(aInterfaceID, DOC_INTERFACE_ID)
                        and DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOC_INTERFACE_POSITION_ID)
                        and GCO_GOOD_ID is not null
                        and C_INTERFACE_GEN_MODE = 'DISCHARGE'
                        and nvl(DOP_QTY, 0) <> 0
                        and DOP_FATHER_DMT_NUMBER is not null
                        and DOP_FATHER_POS_NUMBER is not null
                   order by DOC_INTERFACE_POSITION_ID asc) loop
      -- Rechercher la qté totale déjà matchée pour la position interface courante
      select nvl(sum(DMA_QUANTITY), 0)
        into vMatchedQty
        from DOC_INTERFACE_MATCH
       where DOC_INTERFACE_POSITION_ID = tplDop.DOC_INTERFACE_POSITION_ID
         and DOC_POSITION_DETAIL_ID is not null;

      -- Vérifier s'il y a un solde à matcher ou bien si tout a déjà été matché
      -- pour la position interface courante
      if vMatchedQty < tplDop.DOP_QTY then
        -- Liste des détails de la position source avec la qté solde du détail
        open crDetail(tplDop.DOP_FATHER_DMT_NUMBER, tplDop.DOP_FATHER_POS_NUMBER, tplDop.DOP_FATHER_DELAY, tplDop.DOP_QTY - vMatchedQty);

        loop
          fetch crDetail
           into tplPde;

          -- Arreter le traitement lorsqu'il n'y a plus de détails source ou bien
          -- si la qté de de la position interface a été totalement matchée
          exit when(crDetail%notfound)
                or (vMatchedQty >= tplDop.DOP_QTY);
          -- Qté match  = Plus petite valeur de (Qté pos interface - Qté déjà matchée, Qté solde du détail courant)
          vQty         := least(tplDop.DOP_QTY - vMatchedQty, tplPde.PDE_BALANCE_QUANTITY);
          --  Créer ou modifier la ligne de match
          vDMA_ID      := InsertMatchDetail(aIntPositionID => tplDop.DOC_INTERFACE_POSITION_ID, aDetailID => tplPde.DOC_POSITION_DETAIL_ID, aQuantity => vQty);
          -- Màj du cummul de la qté déjà matchée pour la position interface courante
          vMatchedQty  := vMatchedQty + vQty;
        end loop;

        close crDetail;
      end if;
    end loop;
  end MatchPosWithLink;

  /**
  * procedure MatchPosWithoutLink
  * Description
  *   Méthode de matching des positions pour les positions interface dont le
  *     lien sur la position source n'est pas défini dans les champs
  *     DOP_FATHER_DMT_NUMBER et DOP_FATHER_POS_NUMBER
  */
  procedure MatchPosWithoutLink(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type, aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
  is
    -- Détails document/position source
    -- Le tri se fait :
    --  Gabarit source gère les délais = oui
    --    1a. Délai de base = Délai interface position
    --    1b. Délai de base ordre croissant
    --  Gabarit source gère les délais = non
    --    1. Date document ordre croissant
    --  2. Qté solde du détail = Qté à matcher
    --  3. Qté solde du détail > Qté à matcher
    --  4. Id du détail par ordre croissant
    cursor crDetail(
      cGaugeList   in ID_TABLE_TYPE
    , cThirdID     in PAC_THIRD.PAC_THIRD_ID%type
    , cGoodID      in GCO_GOOD.GCO_GOOD_ID%type
    , cRecordID    in DOC_RECORD.DOC_RECORD_ID%type
    , cFatherDelay in date
    , cQtyToMatch  in DOC_INTERFACE_MATCH.DMA_QUANTITY%type
    )
    is
      select   DOC_POSITION_DETAIL_ID
             , PDE_BALANCE_QUANTITY
          from (select PDE.DOC_POSITION_DETAIL_ID
                     , PDE.PDE_BALANCE_QUANTITY - (select nvl(sum(DMA_QUANTITY), 0)
                                                     from DOC_INTERFACE_MATCH
                                                    where DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) as PDE_BALANCE_QUANTITY
                     , PDE.PDE_BASIS_DELAY
                     , DMT.DMT_DATE_DOCUMENT
                     , nvl(GAP.GAP_DELAY, 0) GAP_DELAY
                  from DOC_POSITION_DETAIL PDE
                     , DOC_POSITION POS
                     , DOC_DOCUMENT DMT
                     , DOC_GAUGE_POSITION GAP
                     , (select distinct column_value DOC_GAUGE_ID
                                   from table(PCS.IdTableTypeToTable(cGaugeList) ) ) GAU_LIST
                 where DMT.DMT_PROTECTED = 0
                   and DMT.PAC_THIRD_ID = cThirdID
                   and DMT.DOC_GAUGE_ID = GAU_LIST.DOC_GAUGE_ID
                   and DMT.C_DOCUMENT_STATUS in('02', '03')
                   and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                   and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                   and POS.GCO_GOOD_ID = cGoodID
                   and (   cRecordID is null
                        or cRecordID = nvl(POS.DOC_RECORD_ID, DMT.DOC_RECORD_ID) )
                   and PDE.PDE_BALANCE_QUANTITY > 0
                   and POS.C_DOC_POS_STATUS in('02', '03')
                   and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                   and PDE.PDE_BALANCE_QUANTITY - (select nvl(sum(DMA_QUANTITY), 0)
                                                     from DOC_INTERFACE_MATCH
                                                    where DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) > 0)
      order by (case
                  when GAP_DELAY = 1 then case
                                           when(cFatherDelay = PDE_BASIS_DELAY) then 0
                                           else 1
                                         end
                  else null
                end) asc nulls last
             , (case
                  when GAP_DELAY = 1 then PDE_BASIS_DELAY
                  else null
                end) asc nulls last
             , (case
                  when GAP_DELAY = 0 then DMT_DATE_DOCUMENT
                  else null
                end) asc nulls last
             , (case
                  when cQtyToMatch = PDE_BALANCE_QUANTITY then 1
                  else 0
                end) desc
             , (case
                  when cQtyToMatch < PDE_BALANCE_QUANTITY then 1
                  else 0
                end) desc
             , DOC_POSITION_DETAIL_ID asc;

    tplPde      crDetail%rowtype;
    vDOI_ID     DOC_INTERFACE.DOC_INTERFACE_ID%type;
    vDMA_ID     DOC_INTERFACE_MATCH.DOC_INTERFACE_MATCH_ID%type;
    vMatchedQty DOC_INTERFACE_MATCH.DMA_QUANTITY%type             default 0;
    vQty        DOC_INTERFACE_MATCH.DMA_QUANTITY%type             default 0;
    vGaugeList  ID_TABLE_TYPE                                     := ID_TABLE_TYPE();
  begin
    vDOI_ID  := aInterfaceID;

    -- Recherchr l'id du document interface si pas passé en param
    if aInterfaceID is null then
      begin
        select DOC_INTERFACE_ID
          into vDOI_ID
          from DOC_INTERFACE_POSITION
         where DOC_INTERFACE_POSITION_ID = aIntPositionID;
      exception
        when no_data_found then
          vDOI_ID  := null;
      end;
    end if;

    if vDOI_ID is not null then
      -- Renvoi la liste des gabarits source pour la décharge en fonction du
      -- gabarit cible défini sur le document DOC_INTERFACE
      vGaugeList  := GetGaugeDischSrcList(aInterfaceID => vDOI_ID);

      if vGaugeList.count > 0 then
        -- Liste des positions interface à balayer pour effectuer le match
        for tplDop in (select   DOP.DOC_INTERFACE_POSITION_ID
                              , nvl(DOP.DOP_FATHER_DELAY, DOI.DOI_DOCUMENT_DATE) DOP_FATHER_DELAY
                              , nvl(DOP.DOP_QTY, 0) DOP_QTY
                              , DOP.DOC_RECORD_ID
                              , DOI.PAC_THIRD_ID
                              , DOP.GCO_GOOD_ID
                           from DOC_INTERFACE_POSITION DOP
                              , DOC_INTERFACE DOI
                          where DOP.DOC_INTERFACE_ID = nvl(vDOI_ID, DOP.DOC_INTERFACE_ID)
                            and DOP.DOC_INTERFACE_POSITION_ID = nvl(aIntPositionID, DOP.DOC_INTERFACE_POSITION_ID)
                            and DOI.DOC_INTERFACE_ID = DOP.DOC_INTERFACE_ID
                            and DOP.GCO_GOOD_ID is not null
                            and DOP.C_INTERFACE_GEN_MODE = 'DISCHARGE'
                            and nvl(DOP.DOP_QTY, 0) <> 0
                            and (   DOP.DOP_FATHER_DMT_NUMBER is null
                                 or DOP.DOP_FATHER_DMT_NUMBER is null)
                       order by DOP.DOC_INTERFACE_POSITION_ID asc) loop
          -- Rechercher la qté totale déjà matchée pour la position interface courante
          select nvl(sum(DMA_QUANTITY), 0)
            into vMatchedQty
            from DOC_INTERFACE_MATCH
           where DOC_INTERFACE_POSITION_ID = tplDop.DOC_INTERFACE_POSITION_ID
             and DOC_POSITION_DETAIL_ID is not null;

          -- Vérifier s'il y a un solde à matcher ou bien si tout a déjà été matché
          -- pour la position interface courante
          if vMatchedQty < tplDop.DOP_QTY then
            -- Liste des détails de la position source avec la qté solde du détail
            open crDetail(vGaugeList, tplDop.PAC_THIRD_ID, tplDop.GCO_GOOD_ID, tplDop.DOC_RECORD_ID, tplDop.DOP_FATHER_DELAY, tplDop.DOP_QTY - vMatchedQty);

            loop
              fetch crDetail
               into tplPde;

              -- Arreter le traitement lorsqu'il n'y a plus de détails source ou bien
              -- si la qté de de la position interface a été totalement matchée
              exit when(crDetail%notfound)
                    or (vMatchedQty >= tplDop.DOP_QTY);
              -- Qté match  = Plus petite valeur de (Qté pos interface - Qté déjà matchée, Qté solde du détail courant)
              vQty         := least(tplDop.DOP_QTY - vMatchedQty, tplPde.PDE_BALANCE_QUANTITY);
              --  Créer ou modifier la ligne de match
              vDMA_ID      :=
                            InsertMatchDetail(aIntPositionID   => tplDop.DOC_INTERFACE_POSITION_ID, aDetailID => tplPde.DOC_POSITION_DETAIL_ID
                                            , aQuantity        => vQty);
              -- Màj du cummul de la qté déjà matchée pour la position interface courante
              vMatchedQty  := vMatchedQty + vQty;
            end loop;

            close crDetail;
          end if;
        end loop;
      end if;
    end if;
  end MatchPosWithoutLink;
end DOC_INTERFACE_MATCHING;
