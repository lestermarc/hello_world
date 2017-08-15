--------------------------------------------------------
--  DDL for Package Body FAL_PRC_REPORT_ATTRIB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_REPORT_ATTRIB" 
is
  /**
  * procedure  CheckTransferAttributions
  * Description
  *    Contr�le si il s'agit d'un transfert d'attributions
  * @created fp 26.05.2009
  * @lastUpdate
  * @public
  * @param itMovementRecord  : tuple STM_STOCK_MOVEMENT
  */
  procedure CheckTransferAttributions(itMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lMovementSort       STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType       STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lTransfer           number(1);
    lC_ATTRIB_TRSF_KIND STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type;
  begin
    -- recherche d'informations concernant les genres de mouvements
    select C_MOVEMENT_TYPE
         , C_MOVEMENT_SORT
         , sign(nvl(stm_stm_movement_kind_id, 0) )
         , C_ATTRIB_TRSF_KIND
      into lMovementType
         , lMovementSort
         , lTransfer
         , lC_ATTRIB_TRSF_KIND
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = itMovementRecord.STM_MOVEMENT_KIND_ID;

    -- exclure ausyst�matiquement les movement de report d'exercice
    if lMovementType <> 'EXE' then
      -- teste s'il s'agit d'un mouvement de transfert
      if     lTransfer = 1
         and lC_ATTRIB_TRSF_KIND > '0' then
        STM_PRC_MOVEMENT.gAttribTransfertMode  := true;
      end if;
    end if;
  end CheckTransferAttributions;

  /**
  * procedure  TransferAttributions
  * Description
  *    Transfert d'attributions
  * @created fp 26.05.2009
  * @lastUpdate
  * @public
  * @param itMovementRecord  : tuple STM_STOCK_MOVEMENT
  */
  procedure TransferAttributions(itMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lMovementSort       STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType       STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lStockPositionId    STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    lQtyToTransfer      STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lQtyStock           STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lQtyProvInput       STM_STOCK_POSITION.SPO_PROVISORY_INPUT%type;
    lQtyAssigned        STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type;
    lTransfer           number(1);
    lC_ATTRIB_TRSF_KIND STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type;

    function GetTmpQtyToTransfert(iStockPositionID number)
      return number
    is
      result number;
    begin
      select nvl(sum(FRA_QTY), 0)
        into result
        from FAL_TMP_REPORT_ATTRIB
       where STM_STOCK_POSITION_ID = iStockPositionID;

      return result;
    exception
      when others then
        return 0;
    end;

    procedure GetPositionInfo(itMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    is
    begin
      begin
        -- recherche de la position de stock correspondante
        select     STM_STOCK_POSITION_ID
                 , SPO_STOCK_QUANTITY
                 , SPO_PROVISORY_INPUT
                 , SPO_ASSIGN_QUANTITY
              into lStockPositionId
                 , lQtyStock
                 , lQtyProvInput
                 , lQtyAssigned
              from STM_STOCK_POSITION
             where GCO_GOOD_ID = itMovementRecord.GCO_GOOD_ID
               and STM_LOCATION_ID = itMovementRecord.STM_LOCATION_ID
               and (     (   GCO_CHARACTERIZATION_ID = itMovementRecord.GCO_CHARACTERIZATION_ID
                          or (    itMovementRecord.GCO_CHARACTERIZATION_ID is null
                              and GCO_CHARACTERIZATION_ID is null)
                         )
                    and (   GCO_GCO_CHARACTERIZATION_ID = itMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                         or (    itMovementRecord.GCO_GCO_CHARACTERIZATION_ID is null
                             and GCO_GCO_CHARACTERIZATION_ID is null)
                        )
                    and (   GCO2_GCO_CHARACTERIZATION_ID = itMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                         or (    itMovementRecord.GCO2_GCO_CHARACTERIZATION_ID is null
                             and GCO2_GCO_CHARACTERIZATION_ID is null)
                        )
                    and (   GCO3_GCO_CHARACTERIZATION_ID = itMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                         or (    itMovementRecord.GCO3_GCO_CHARACTERIZATION_ID is null
                             and GCO3_GCO_CHARACTERIZATION_ID is null)
                        )
                    and (   GCO4_GCO_CHARACTERIZATION_ID = itMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                         or (    itMovementRecord.GCO4_GCO_CHARACTERIZATION_ID is null
                             and GCO4_GCO_CHARACTERIZATION_ID is null)
                        )
                    and (   SPO_CHARACTERIZATION_VALUE_1 = itMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                         or (    itMovementRecord.SMO_CHARACTERIZATION_VALUE_1 is null
                             and SPO_CHARACTERIZATION_VALUE_1 is null)
                        )
                    and (   SPO_CHARACTERIZATION_VALUE_2 = itMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                         or (    itMovementRecord.SMO_CHARACTERIZATION_VALUE_2 is null
                             and SPO_CHARACTERIZATION_VALUE_2 is null)
                        )
                    and (   SPO_CHARACTERIZATION_VALUE_3 = itMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                         or (    itMovementRecord.SMO_CHARACTERIZATION_VALUE_3 is null
                             and SPO_CHARACTERIZATION_VALUE_3 is null)
                        )
                    and (   SPO_CHARACTERIZATION_VALUE_4 = itMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                         or (    itMovementRecord.SMO_CHARACTERIZATION_VALUE_4 is null
                             and SPO_CHARACTERIZATION_VALUE_4 is null)
                        )
                    and (   SPO_CHARACTERIZATION_VALUE_5 = itMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                         or (    itMovementRecord.SMO_CHARACTERIZATION_VALUE_5 is null
                             and SPO_CHARACTERIZATION_VALUE_5 is null)
                        )
                   )
        for update;
      exception
        when no_data_found then
          null;   -- si pas de position de stock trouv�e, il y a incoh�rence, mais on ne la traite pas ici
      end;
    end;
  begin
    -- recherche d'informations concernant les genres de mouvements
    select C_MOVEMENT_TYPE
         , C_MOVEMENT_SORT
         , sign(nvl(stm_stm_movement_kind_id, 0) )
         , C_ATTRIB_TRSF_KIND
      into lMovementType
         , lMovementSort
         , lTransfer
         , lC_ATTRIB_TRSF_KIND
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = itMovementRecord.STM_MOVEMENT_KIND_ID;

    -- exclure ausyst�matiquement les movement de report d'exercice
    if lMovementType <> 'EXE' then
      -- teste s'il s'agit d'un mouvement de transfert
      if     lTransfer = 1
         and lC_ATTRIB_TRSF_KIND > '0' then
        -- recherche de l'id de la position de stock et des quantit�s
        GetPositionInfo(itMovementRecord);

        if    (    lMovementSort = 'SOR'
               and sign(itMovementRecord.SMO_MOVEMENT_QUANTITY) = 1)
           or (    lMovementSort = 'ENT'
               and sign(itMovementRecord.SMO_MOVEMENT_QUANTITY) = -1) then
          if lC_ATTRIB_TRSF_KIND = '1' then   -- automatique
            -- recherche de la quantit� � transf�rer (attention, le mouvement est d�j� effectu�))
            lQtyToTransfer  := lQtyAssigned - lQtyStock - GetTmpQtyToTransfert(lStockPositionId);
          else
            select GetTotTransferAttrib(itMovementRecord.STM_STOCK_MOVEMENT_ID)
              into lQtyToTransfer
              from dual;
          end if;

          -- si on ne peut pas transf�rer sans toucher � la quantit� attribu�e
          -- Le d�placement des attributions ne doit pas se faire pour les stocks pouvant �tre n�gatif (voir DOC_LIB_ALLOY.StockDeficitControl)
          if lQtyToTransfer > 0 and lQtyStock >= 0 then
            -- si mouvement d'entr�e d�j� effectu�
            if itMovementRecord.STM_STOCK_MOVEMENT_ID > nvl(itMovementRecord.STM_STM_STOCK_MOVEMENT_ID, itMovementRecord.STM_STOCK_MOVEMENT_ID) then
              -- d�placement direct des attributions sans passer par la table temporaire
              FAL_PRC_REPORT_ATTRIB.MoveAttribTrsfInput(itMovementRecord.STM_STM_STOCK_MOVEMENT_ID
                                                      , lStockPositionId
                                                      , lQtyToTransfer
                                                      , itMovementRecord.SMO_MOVEMENT_QUANTITY
                                                      , lC_ATTRIB_TRSF_KIND
                                                       );
            else
              -- ins�rer la quantit� � d�placer dans la table de travail
              -- recherche des attributions � d�placer
              FAL_PRC_REPORT_ATTRIB.InsertFirstMoveInformations(itMovementRecord.STM_STOCK_MOVEMENT_ID
                                                              , lStockPositionId
                                                              , itMovementRecord.STM_LOCATION_ID
                                                              , lQtyToTransfer
                                                               );
            end if;
          end if;
        elsif    (    lMovementSort = 'ENT'
                  and sign(itMovementRecord.SMO_MOVEMENT_QUANTITY) = 1)
              or (    lMovementSort = 'SOR'
                  and sign(itMovementRecord.SMO_MOVEMENT_QUANTITY) = -1) then
          -- si mouvement d'entr�e d�j� effectu�
          if itMovementRecord.STM_STOCK_MOVEMENT_ID > nvl(itMovementRecord.STM_STM_STOCK_MOVEMENT_ID, itMovementRecord.STM_STOCK_MOVEMENT_ID) then
            -- d�placement direct des attributions sans passer par la table temporaire
            FAL_PRC_REPORT_ATTRIB.MoveAttribTrsfOutput(itMovementRecord.STM_STM_STOCK_MOVEMENT_ID
                                                     , lStockPositionId
                                                     , itMovementRecord.STM_LOCATION_ID
                                                     , itMovementRecord.SMO_MOVEMENT_QUANTITY
                                                     , lC_ATTRIB_TRSF_KIND
                                                      );
          else
            -- ins�rer la quantit� � d�placer dans la table de travail
            -- recherche des attributions � d�placer
            FAL_PRC_REPORT_ATTRIB.InsertFirstMoveInformations(itMovementRecord.STM_STOCK_MOVEMENT_ID, lStockPositionId, itMovementRecord.STM_LOCATION_ID, 0);
          end if;
        end if;
      -- mouvement de stock d'entr�e pouvant g�rer une extourne
      elsif     itMovementRecord.DOC_POSITION_DETAIL_ID is not null
            and lMovementSort = 'ENT' then
        if itMovementRecord.SMO_EXTOURNE_MVT = 1 then
          -- recherche de l'id de la position de stock et des quantit�s
          GetPositionInfo(itMovementRecord);
          -- recherche de la quantit� � transf�rer (attention, le mouvement est d�j� effectu�))
          lQtyToTransfer  := lQtyAssigned - lQtyStock;
          -- Le d�placement des attributions ne doit pas se faire pour les stocks pouvant �tre n�gatif (voir DOC_LIB_ALLOY.StockDeficitControl)
          if lQtyToTransfer > 0 and lQtyStock >= 0 then
            -- d�placement direct des attributions sans passer par la table temporaire
            FAL_PRC_REPORT_ATTRIB.MoveAttribTrsfInput(itMovementRecord.DOC_POSITION_DETAIL_ID
                                                    , lStockPositionId
                                                    , lQtyToTransfer
                                                    , itMovementRecord.SMO_MOVEMENT_QUANTITY
                                                    , lC_ATTRIB_TRSF_KIND
                                                     );
          end if;
        else
          declare
            lExtourne DOC_GAUGE_RECEIPT.GAR_EXTOURNE_MVT%type;
          begin
            --- Recherche si on a affaire � un mouvement provoquant une extourne
            select GAR.GAR_EXTOURNE_MVT
              into lExtourne
              from DOC_POSITION_DETAIL PDE
                 , DOC_GAUGE_RECEIPT GAR
             where PDE.DOC_POSITION_DETAIL_ID = itMovementRecord.DOC_POSITION_DETAIL_ID
               and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
               and GAR.GAR_EXTOURNE_MVT = 1;

            -- recherche de l'id de la position de stock
            GetPositionInfo(itMovementRecord);
            -- ins�rer la quantit� � d�placer dans la table de travail
            -- recherche des attributions � d�placer
            FAL_PRC_REPORT_ATTRIB.InsertFirstMoveInformations(itMovementRecord.DOC_POSITION_DETAIL_ID, lStockPositionId, itMovementRecord.STM_LOCATION_ID, 0);
          exception
            when no_data_found then
              null;
          end;
        end if;
      end if;
    end if;
  end TransferAttributions;

  /**
  * Description
  *   D�place les attributions besoin/apppro incritent dans la table temporaire de report d'attribution sur
  *   des attributions besoin/stock d'apr�s les positions de stock g�n�r� par la position courante.
  */
  procedure MoveAttributionLink(iPositionID in number, iPositionDetailID in number default null)
  is
    -- curseur sur les attributions � reporter
    cursor lcurReportAttrib
    is
      select   FRA.FAL_TMP_REPORT_ATTRIB_ID
             , FRA.FAL_NETWORK_LINK_ID
             , FRA.FAL_NETWORK_NEED_ID
             , FRA.FAL_NETWORK_SUPPLY_ID
             , FRA.STM_STOCK_POSITION_ID
             , FRA.FRA_QTY
             , FRA.FRA_NEED_DELAY
          from FAL_TMP_REPORT_ATTRIB FRA
      order by FRA.FRA_NEED_DELAY;

    ltplReportAttrib       lcurReportAttrib%rowtype;

    type tStockPositionInfo is record(
      STM_STOCK_POSITION_ID STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
    , PDE_FINAL_QUANTITY_SU DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type
    );

    type ttStockPositionInfo is table of tStockPositionInfo;

    ltplStockPositionInfo  ttStockPositionInfo;

    type tSupplyPositionInfo is record(
      FAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type
    , PDE_FINAL_QUANTITY_SU DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type
    );

    type ttSupplyPositionInfo is table of tSupplyPositionInfo;

    ltplSupplyPositionInfo ttSupplyPositionInfo;

    type tNeedPositionInfo is record(
      FAL_NETWORK_NEED_ID   FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
    , PDE_FINAL_QUANTITY_SU DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type
    );

    type ttNeedPositionInfo is table of tNeedPositionInfo;

    ltplNeedPositionInfo   ttNeedPositionInfo;
    lPdtStockAllocBatch    GCO_PRODUCT.PDT_STOCK_ALLOC_BATCH%type;
    lStmMovementKindID     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lGauAdminDomain        DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lGauGaugeType          DOC_GAUGE.C_GAUGE_TYPE%type;
    lFlnBalanceAttribQty   DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
    lFlnQty                DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
    lIntIndex              integer;
    lIntCount              integer;
  begin
    if iPositionID is not null then
      begin
        select POS.STM_MOVEMENT_KIND_ID
             , GAU.C_ADMIN_DOMAIN
             , GAU.C_GAUGE_TYPE
             , nvl(PDT.PDT_STOCK_ALLOC_BATCH, 0)
          into lStmMovementKindID
             , lGauAdminDomain
             , lGauGaugeType
             , lPdtStockAllocBatch
          from GCO_PRODUCT PDT
             , DOC_POSITION POS
             , DOC_GAUGE GAU
         where PDT.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and POS.DOC_POSITION_ID = iPositionID
           and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID;
      exception
        when no_data_found then
          null;
      end;

      -- Cas 1 CF -> BR : Transformation d'une attribution besoin/appro en besoin/stock - Partie repartition
      if     lStmMovementKindID is not null
         and (nvl(lGauAdminDomain, '0') = '1')
         and (nvl(lGauGaugeType, '0') = '3')
         and (nvl(lPdtStockAllocBatch, 0) = 1) then
        -- Chargement des positions de stock associ�s � chaque d�tail de position de la position sp�cifi�e
        select   SPO.STM_STOCK_POSITION_ID
               , PDE.PDE_FINAL_QUANTITY_SU
        bulk collect into ltplStockPositionInfo
            from STM_STOCK_POSITION SPO
               , DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_ID = iPositionID
             and (   PDE.DOC_POSITION_DETAIL_ID = iPositionDetailID
                  or iPositionDetailID is null)
             and SPO.GCO_GOOD_ID = PDE.GCO_GOOD_ID
             and SPO.STM_LOCATION_ID = PDE.STM_LOCATION_ID
             and not(    PDE.GCO_CHARACTERIZATION_ID is not null
                     and PDE.PDE_CHARACTERIZATION_VALUE_1 is null)
             and not(    PDE.GCO_GCO_CHARACTERIZATION_ID is not null
                     and PDE.PDE_CHARACTERIZATION_VALUE_2 is null)
             and not(    PDE.GCO2_GCO_CHARACTERIZATION_ID is not null
                     and PDE.PDE_CHARACTERIZATION_VALUE_3 is null)
             and not(    PDE.GCO3_GCO_CHARACTERIZATION_ID is not null
                     and PDE.PDE_CHARACTERIZATION_VALUE_4 is null)
             and not(    PDE.GCO4_GCO_CHARACTERIZATION_ID is not null
                     and PDE.PDE_CHARACTERIZATION_VALUE_5 is null)
             and (     (   SPO.GCO_CHARACTERIZATION_ID = PDE.GCO_CHARACTERIZATION_ID
                        or (    PDE.GCO_CHARACTERIZATION_ID is null
                            and SPO.GCO_CHARACTERIZATION_ID is null)
                       )
                  and (   SPO.GCO_GCO_CHARACTERIZATION_ID = PDE.GCO_GCO_CHARACTERIZATION_ID
                       or (    PDE.GCO_GCO_CHARACTERIZATION_ID is null
                           and SPO.GCO_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   SPO.GCO2_GCO_CHARACTERIZATION_ID = PDE.GCO2_GCO_CHARACTERIZATION_ID
                       or (    PDE.GCO2_GCO_CHARACTERIZATION_ID is null
                           and SPO.GCO2_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   SPO.GCO3_GCO_CHARACTERIZATION_ID = PDE.GCO3_GCO_CHARACTERIZATION_ID
                       or (    PDE.GCO3_GCO_CHARACTERIZATION_ID is null
                           and SPO.GCO3_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   SPO.GCO4_GCO_CHARACTERIZATION_ID = PDE.GCO4_GCO_CHARACTERIZATION_ID
                       or (    PDE.GCO4_GCO_CHARACTERIZATION_ID is null
                           and SPO.GCO4_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   SPO.SPO_CHARACTERIZATION_VALUE_1 = PDE.PDE_CHARACTERIZATION_VALUE_1
                       or (    PDE.PDE_CHARACTERIZATION_VALUE_1 is null
                           and SPO.SPO_CHARACTERIZATION_VALUE_1 is null)
                      )
                  and (   SPO.SPO_CHARACTERIZATION_VALUE_2 = PDE.PDE_CHARACTERIZATION_VALUE_2
                       or (    PDE.PDE_CHARACTERIZATION_VALUE_2 is null
                           and SPO.SPO_CHARACTERIZATION_VALUE_2 is null)
                      )
                  and (   SPO.SPO_CHARACTERIZATION_VALUE_3 = PDE.PDE_CHARACTERIZATION_VALUE_3
                       or (    PDE.PDE_CHARACTERIZATION_VALUE_3 is null
                           and SPO.SPO_CHARACTERIZATION_VALUE_3 is null)
                      )
                  and (   SPO.SPO_CHARACTERIZATION_VALUE_4 = PDE.PDE_CHARACTERIZATION_VALUE_4
                       or (    PDE.PDE_CHARACTERIZATION_VALUE_4 is null
                           and SPO.SPO_CHARACTERIZATION_VALUE_4 is null)
                      )
                  and (   SPO.SPO_CHARACTERIZATION_VALUE_5 = PDE.PDE_CHARACTERIZATION_VALUE_5
                       or (    PDE.PDE_CHARACTERIZATION_VALUE_5 is null
                           and SPO.SPO_CHARACTERIZATION_VALUE_5 is null)
                      )
                 )
        order by PDE.PDE_FINAL_QUANTITY_SU desc;

        if (ltplStockPositionInfo.count > 0) then
          -- Traitement de chaque besoin � r�attribuer.
          for tplReportAttrib in lcurReportAttrib loop
            -- Initialise la quantit� du besoin � attribuer.
            lFlnBalanceAttribQty  := tplReportAttrib.FRA_QTY;

            -- Recherche la quantit� � r�attribuer selon les conditions suivantes :
            --
            -- Si l'attribution d'origine n'existe plus, il faut reporter l'ensemble de la quantit� attribu� initiale.
            -- Si l'attribution d'origine poss�de toujours la m�me quantit� attribu�e, aucun report ne sera effectu�.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e inf�rieure � la quantit� attribu�e initiale,
            -- la quantit� du report sera : Quantit� attribu� initiale - Quantit� attribu� actuelle.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e sup�rieure � la quantit� attribu�e initiale,
            -- aucun report ne sera effectu�.
            --
            begin
              select greatest(lFlnBalanceAttribQty - FLN.FLN_QTY, 0)
                into lFlnBalanceAttribQty
                from FAL_NETWORK_LINK FLN
               where FLN.FAL_NETWORK_LINK_ID = tplReportAttrib.FAL_NETWORK_LINK_ID;
            exception
              when no_data_found then
                null;
            end;

            lIntCount             := 0;

            -- Tant qu'il reste des quantit�s du besoin � r�attribuer et des quantit�s sur les positions de stock ...
            while(lFlnBalanceAttribQty > 0)
             and (ltplStockPositionInfo.count > lIntCount) loop
              -- Balaye les positions de stock disponible par ordre d�croissant de la quantit�
              for lIntIndex in ltplStockPositionInfo.first .. ltplStockPositionInfo.last loop
                -- Traite uniquement les positions de stock avec une quantit� encore � attribuer
                if     (ltplStockPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU > 0)
                   and (lFlnBalanceAttribQty > 0) then
                  if lFlnBalanceAttribQty <= ltplStockPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU then
                    lFlnQty  := lFlnBalanceAttribQty;
                  else
                    lFlnQty  := ltplStockPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU;
                  end if;

                  FAL_NETWORK_DOC.CreateAttribBesoinApproOrStock(aFAL_NETWORK_NEED_ID     => tplReportAttrib.FAL_NETWORK_NEED_ID
                                                               , aSTM_STOCK_POSITION_ID   => ltplStockPositionInfo(lIntIndex).STM_STOCK_POSITION_ID
                                                               , aFLN_QTY                 => lFlnQty
                                                                );
                  -- Redefinit la quantit� du d�tail restant � attribuer.
                  lFlnBalanceAttribQty                                    := lFlnBalanceAttribQty - lFlnQty;
                  -- Redefinit la quantit� de la position de stock qui peut-�tre encore attribu�.
                  ltplStockPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU  := ltplStockPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU - lFlnQty;
                else
                  -- Incr�mente le compteur des positions de stock �puis�.
                  lIntCount  := lIntCount + 1;
                end if;
              end loop;

              -- Mise � jour de la quantit� du besoin � attribuer. Il est indispensable que la table temporaire de
              -- report d'attribution soit � jour car il est possible que la m�thode de report d'attribution soit
              -- appel� une seconde fois.
              update FAL_TMP_REPORT_ATTRIB
                 set FRA_QTY = greatest(lFlnBalanceAttribQty, 0)
               where FAL_TMP_REPORT_ATTRIB_ID = tplReportAttrib.FAL_TMP_REPORT_ATTRIB_ID;

              -- V�rifie s'il existe encore des positions de stock avec des quantit�s non attribu�es.
              -- si ce n'est pas le cas, on sort de la boucle et on passe au besoin suivant.
              if ltplStockPositionInfo.count > lIntCount then
                -- R�initialise le compteur des quantit�s des positions de stock encore disponible pour permettre
                -- de continuer la r�partition.
                lIntCount  := 0;
              end if;
            end loop;
          end loop;
        end if;
      -- Cas 2 CF -> CF : Deplacement d'une attribution besoin/appro1 sur besoin/appro2 - Partie repartition
      elsif     lStmMovementKindID is null
            and (nvl(lGauAdminDomain, '0') = '1')
            and (nvl(lGauGaugeType, '0') = '2') then
        -- Chargement des informations de chaque d�tail de position de la position sp�cifi�e
        select   FAS.FAL_NETWORK_SUPPLY_ID
               , PDE.PDE_FINAL_QUANTITY_SU
        bulk collect into ltplSupplyPositionInfo
            from FAL_NETWORK_SUPPLY FAS
               , DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_ID = iPositionID
             and (   PDE.DOC_POSITION_DETAIL_ID = iPositionDetailID
                  or iPositionDetailID is null)
             and FAS.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
        order by PDE.PDE_FINAL_QUANTITY_SU desc;

        if (ltplSupplyPositionInfo.count > 0) then
          -- Traitement de chaque besoin � r�attribuer.
          for tplReportAttrib in lcurReportAttrib loop
            -- Initialise la quantit� du besoin � attribuer.
            lFlnBalanceAttribQty  := tplReportAttrib.FRA_QTY;

            -- Recherche la quantit� � r�attribuer selon les conditions suivantes :
            --
            -- Si l'attribution d'origine n'existe plus, il faut reporter l'ensemble de la quantit� attribu� initiale.
            -- Si l'attribution d'origine poss�de toujours la m�me quantit� attribu�e, aucun report ne sera effectu�.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e inf�rieure � la quantit� attribu�e initiale,
            -- la quantit� du report sera : Quantit� attribu� initiale - Quantit� attribu� actuelle.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e sup�rieure � la quantit� attribu�e initiale,
            -- aucun report ne sera effectu�.
            --
            begin
              select greatest(lFlnBalanceAttribQty - FLN.FLN_QTY, 0)
                into lFlnBalanceAttribQty
                from FAL_NETWORK_LINK FLN
               where FLN.FAL_NETWORK_LINK_ID = tplReportAttrib.FAL_NETWORK_LINK_ID;
            exception
              when no_data_found then
                null;
            end;

            lIntCount             := 0;

            -- Tant qu'il reste des quantit�s du besoin � r�attribuer et des quantit�s sur les appro. ...
            while(lFlnBalanceAttribQty > 0)
             and (ltplSupplyPositionInfo.count > lIntCount) loop
              -- Balaye les appro disponible par ordre d�croissant de la quantit�
              for lIntIndex in ltplSupplyPositionInfo.first .. ltplSupplyPositionInfo.last loop
                -- Traite uniquement les approvisionnement avec une quantit� encore � attribuer
                if     (ltplSupplyPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU > 0)
                   and (lFlnBalanceAttribQty > 0) then
                  if lFlnBalanceAttribQty <= ltplSupplyPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU then
                    lFlnQty  := lFlnBalanceAttribQty;
                  else
                    lFlnQty  := ltplSupplyPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU;
                  end if;

                  FAL_NETWORK_DOC.CreateAttribBesoinApproOrStock(aFAL_NETWORK_NEED_ID     => tplReportAttrib.FAL_NETWORK_NEED_ID
                                                               , aFAL_NETWORK_SUPPLY_ID   => ltplSupplyPositionInfo(lIntIndex).FAL_NETWORK_SUPPLY_ID
                                                               , aFLN_QTY                 => lFlnQty
                                                                );
                  -- Redefinit la quantit� du d�tail restant � attribuer.
                  lFlnBalanceAttribQty                                     := lFlnBalanceAttribQty - lFlnQty;
                  -- Redefinit la quantit� de l'approvisionnement qui peut-�tre encore attribu�.
                  ltplSupplyPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU  := ltplSupplyPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU - lFlnQty;
                else
                  -- Incr�mente le compteur des approvisionnements �puis�s.
                  lIntCount  := lIntCount + 1;
                end if;
              end loop;

              -- V�rifie s'il existe encore des approvisionnements avec des quantit�s non attribu�es.
              -- si ce n'est pas le cas, on sort de la boucle et on passe au besoin suivant.
              if ltplSupplyPositionInfo.count > lIntCount then
                -- R�initialise le compteur des quantit�s des approvisionnement encore disponible pour permettre
                -- de continuer la r�partition.
                lIntCount  := 0;
              end if;
            end loop;
          end loop;
        end if;
      -- Cas 3 CC -> CC : Deplacement d'une attribution besoin1/appro sur besoin2/appro ou besoin1/stock sur
      -- besoin2/stock - Partie repartition
      elsif     lStmMovementKindID is null
            and (nvl(lGauAdminDomain, '0') = '2')
            and (nvl(lGauGaugeType, '0') = '1') then
        -- Chargement des informations de chaque d�tail de position de la position sp�cifi�e
        select   FAN.FAL_NETWORK_NEED_ID
               , PDE.PDE_FINAL_QUANTITY_SU
        bulk collect into ltplNeedPositionInfo
            from FAL_NETWORK_NEED FAN
               , DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_ID = iPositionID
             and (   PDE.DOC_POSITION_DETAIL_ID = iPositionDetailID
                  or iPositionDetailID is null)
             and FAN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
        order by PDE.PDE_FINAL_QUANTITY_SU desc;

        if (ltplNeedPositionInfo.count > 0) then
          -- Traitement de chaque attribution � d�placer.
          for tplReportAttrib in lcurReportAttrib loop
            -- Initialise la quantit� de la position de stock ou de l'appro � attribuer.
            lFlnBalanceAttribQty  := tplReportAttrib.FRA_QTY;

            -- Recherche la quantit� � r�attribuer selon les conditions suivantes :
            --
            -- Si l'attribution d'origine n'existe plus, il faut reporter l'ensemble de la quantit� attribu� initiale.
            -- Si l'attribution d'origine poss�de toujours la m�me quantit� attribu�e, aucun report ne sera effectu�.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e inf�rieure � la quantit� attribu�e initiale,
            -- la quantit� du report sera : Quantit� attribu� initiale - Quantit� attribu� actuelle.
            -- Si l'attribution d'origine poss�de une quantit� attribu�e sup�rieure � la quantit� attribu�e initiale,
            -- aucun report ne sera effectu�.
            --
            begin
              select greatest(lFlnBalanceAttribQty - FLN.FLN_QTY, 0)
                into lFlnBalanceAttribQty
                from FAL_NETWORK_LINK FLN
               where FLN.FAL_NETWORK_LINK_ID = tplReportAttrib.FAL_NETWORK_LINK_ID;
            exception
              when no_data_found then
                null;
            end;

            -- Traitement d'une attribution besoin/appro
            if tplReportAttrib.STM_STOCK_POSITION_ID is null then
              lIntCount  := 0;

              -- Tant qu'il reste des quantit�s de l'appro � r�attribuer et des quantit�s sur les besoin ...
              while(lFlnBalanceAttribQty > 0)
               and (ltplNeedPositionInfo.count > lIntCount) loop
                -- Balaye les besoins disponibles par ordre d�croissant de la quantit�
                for lIntIndex in ltplNeedPositionInfo.first .. ltplNeedPositionInfo.last loop
                  -- Traite uniquement les besoins avec une quantit� encore � attribuer
                  if     (ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU > 0)
                     and (lFlnBalanceAttribQty > 0) then
                    if lFlnBalanceAttribQty <= ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU then
                      lFlnQty  := lFlnBalanceAttribQty;
                    else
                      lFlnQty  := ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU;
                    end if;

                    FAL_NETWORK_DOC.CreateAttribBesoinApproOrStock(aFAL_NETWORK_NEED_ID     => ltplNeedPositionInfo(lIntIndex).FAL_NETWORK_NEED_ID
                                                                 , aFAL_NETWORK_SUPPLY_ID   => tplReportAttrib.FAL_NETWORK_SUPPLY_ID
                                                                 , aFLN_QTY                 => lFlnQty
                                                                  );
                    -- Redefinit la quantit� du d�tail restant � attribuer.
                    lFlnBalanceAttribQty                                   := lFlnBalanceAttribQty - lFlnQty;
                    -- Redefinit la quantit� du besoin qui peut-�tre encore attribu�.
                    ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU  := ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU - lFlnQty;
                  else
                    -- Incr�mente le compteur des approvisionnements �puis�s.
                    lIntCount  := lIntCount + 1;
                  end if;
                end loop;   -- for lIntIndex in ltplNeedPositionInfo.first .. ltplNeedPositionInfo.last loop

                -- V�rifie s'il existe encore des besoins avec des quantit�s non attribu�es.
                -- si ce n'est pas le cas, on sort de la boucle et on passe � l'attribution suivante.
                if ltplNeedPositionInfo.count > lIntCount then
                  -- R�initialise le compteur des quantit�s des besoins encore disponible pour permettre
                  -- de continuer la r�partition.
                  lIntCount  := 0;
                end if;
              end loop;
            -- Traitement d'une attribution besoin/stock
            else
              lIntCount  := 0;

              -- Tant qu'il reste des quantit�s sur la position de stock � r�attribuer et des quantit�s sur les besoin ...
              while(lFlnBalanceAttribQty > 0)
               and (ltplNeedPositionInfo.count > lIntCount) loop
                -- Balaye les besoins disponibles par ordre d�croissant de la quantit�
                for lIntIndex in ltplNeedPositionInfo.first .. ltplNeedPositionInfo.last loop
                  -- Traite uniquement les besoins avec une quantit� encore � attribuer
                  if     (ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU > 0)
                     and (lFlnBalanceAttribQty > 0) then
                    if lFlnBalanceAttribQty <= ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU then
                      lFlnQty  := lFlnBalanceAttribQty;
                    else
                      lFlnQty  := ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU;
                    end if;

                    FAL_NETWORK_DOC.CreateAttribBesoinApproOrStock(aFAL_NETWORK_NEED_ID     => ltplNeedPositionInfo(lIntIndex).FAL_NETWORK_NEED_ID
                                                                 , aSTM_STOCK_POSITION_ID   => tplReportAttrib.STM_STOCK_POSITION_ID
                                                                 , aFLN_QTY                 => lFlnQty
                                                                  );
                    -- Redefinit la quantit� du d�tail restant � attribuer.
                    lFlnBalanceAttribQty                                   := lFlnBalanceAttribQty - lFlnQty;
                    -- Redefinit la quantit� du besoin qui peut-�tre encore attribu�.
                    ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU  := ltplNeedPositionInfo(lIntIndex).PDE_FINAL_QUANTITY_SU - lFlnQty;
                  else
                    -- Incr�mente le compteur des positions de stock �puis�s.
                    lIntCount  := lIntCount + 1;
                  end if;
                end loop;   -- for lIntIndex in ltplNeedPositionInfo.first .. ltplNeedPositionInfo.last loop

                -- V�rifie s'il existe encore des besoins avec des quantit�s non attribu�es.
                -- si ce n'est pas le cas, on sort de la boucle et on passe � l'attribution suivante.
                if ltplNeedPositionInfo.count > lIntCount then
                  -- R�initialise le compteur des quantit�s des besoins encore disponible pour permettre
                  -- de continuer la r�partition.
                  lIntCount  := 0;
                end if;
              end loop;
            end if;   -- if tplReportAttrib.STM_STOCK_POSITION_ID is null then
          end loop;   -- for tplReportAttrib in lcurReportAttrib loop
        end if;   -- if (ltplNeedPositionInfo.count > 0) then
      end if;
    end if;   -- if iPositionID is not null then
  end MoveAttributionLink;

  /**
  * procedure CheckAttributionLink
  * Description
  *   Supprime les attributions besoin/stock associ�es � la position de stock courante pour garantir l'int�grit� de
  *   la containte entre la quantit� effective et la quantit� attribu�
  * @author VJE
  */
  procedure CheckAttributionLink(iStockPositionID in number, iQtyDeleted in DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type)
  is
    -- curseur sur les attributions suceptible d'�tre supprim�e
    cursor lcurDeletingAttrib(iStockPositionID number, lQty number)
    is
      select   FLN.FAL_NETWORK_LINK_ID
             , FLN.FAL_NETWORK_NEED_ID
             , FLN.FLN_QTY
             , FLN.FLN_NEED_DELAY
          from FAL_NETWORK_LINK FLN
         where FLN.STM_STOCK_POSITION_ID = iStockPositionID
      order by FLN.A_DATECRE desc
             , FLN.FLN_NEED_DELAY asc
             , FLN.FLN_QTY desc;

    ltplDeletingAttrib    lcurDeletingAttrib%rowtype;
    lFlnBalanceQtyDeleted FAL_NETWORK_LINK.FLN_QTY%type;
    lFlnBeforeQty         FAL_NETWORK_LINK.FLN_QTY%type;
    lFlnAfterQty          FAL_NETWORK_LINK.FLN_QTY%type;
  begin
    if iStockPositionID is not null then
      lFlnBalanceQtyDeleted  := iQtyDeleted;

      -- Traitement de chaque besoin susceptile d'�tre supprimer.
      for tplDeletingAttrib in lcurDeletingAttrib(iStockPositionID, iQtyDeleted) loop
        -- Si la quantit� � effacer est nulle, cela indique qu'il faut supprimer la totalit� de l'attribution.
        -- Dans le cas de la v�rification des attributions avant l'effacement d'une position de stock en particulier.
        -- Voir trigger STM_SPO_BD_CHECK_ATTRIB.
        if iQtyDeleted is null then
          lFlnBalanceQtyDeleted  := tplDeletingAttrib.FLN_QTY;
        end if;

        if (lFlnBalanceQtyDeleted > 0) then
          if (lFlnBalanceQtyDeleted >= tplDeletingAttrib.FLN_QTY) then
            lFlnBeforeQty  := tplDeletingAttrib.FLN_QTY;
            lFlnAfterQty   := 0;
          else
            lFlnBeforeQty  := tplDeletingAttrib.FLN_QTY;
            lFlnAfterQty   := tplDeletingAttrib.FLN_QTY - lFlnBalanceQtyDeleted;
          end if;

          -- Processus : Report sur R�seau Besoin ...
          update FAL_NETWORK_NEED
             set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) +(lFlnBeforeQty - lFlnAfterQty)
               , FAN_STK_QTY = nvl(FAN_STK_QTY, 0) -(lFlnBeforeQty - lFlnAfterQty)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = tplDeletingAttrib.FAL_NETWORK_NEED_ID;

          if iQtyDeleted is null then
            delete from FAL_NETWORK_LINK
                  where FAL_NETWORK_LINK_ID = tplDeletingAttrib.FAL_NETWORK_LINK_ID;
          else
            FAL_NETWORK.Attribution_MAJ_BesoinStock(tplDeletingAttrib.FAL_NETWORK_NEED_ID, lFlnBeforeQty, lFlnAfterQty, tplDeletingAttrib.FAL_NETWORK_LINK_ID);
          end if;

          -- Redefinit la quantit� restant � d�sattribuer.
          lFlnBalanceQtyDeleted  := lFlnBalanceQtyDeleted -(lFlnBeforeQty - lFlnAfterQty);
        end if;
      end loop;
    end if;
  end CheckAttributionLink;

  /**
  * Description
  *    Transfert d'attributions : insertion des informations de transfert des mouvements de stock de sortie
  */
  procedure InsertFirstMoveInformations(
    iStockMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iLocationId      in STM_LOCATION.STM_LOCATION_ID%type
  , iQtyToTransfer   in STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  )
  is
  begin
    -- insertion des informations relatives au mouvement de sortie quand il est ant�rieur au mouvement d'entr�e
    insert into FAL_TMP_REPORT_ATTRIB
                (FAL_TMP_REPORT_ATTRIB_ID
               , STM_STOCK_POSITION_ID
               , STM_LOCATION_ID
               , STM_STOCK_MOVEMENT_ID
               , FRA_QTY
                )
         values (GetNewId
               , iStockPositionId
               , iLocationId
               , iStockMovementId
               , iQtyToTransfer
                );
  end InsertFirstMoveInformations;

  function IsInList(iottAttrDisp in ttAttrDisp, iNetLinkId FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type)
    return boolean
  is
    lResult boolean     := false;
    j       pls_integer;
  begin
    for j in 1 .. iottAttrDisp.count loop
      if iottAttrDisp(j).FAL_NETWORK_LINK_ID = iNetLinkId then
        lResult  := true;
      end if;
    end loop;

    return lResult;
  end IsInList;

  /**
  * Description
  *    D�fini quelles attributions seront d�plac�es
  */
  procedure DispatchAttributions(
    iStockPositionId           STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iMinQuantity               STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iTotalQuantity             STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iottAttrDisp        in out ttAttrDisp
  , iC_ATTRIB_TRSF_KIND        STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type
  , iStockMovementId           STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  )
  is
  begin
    if iC_ATTRIB_TRSF_KIND = '1' then
      DispatchAttributions_AUTO(iStockPositionId, iMinQuantity, iTotalQuantity, iottAttrDisp, false);
    else
      DispatchAttributions_MANUAL(iStockMovementId, iottAttrDisp);
    end if;
  end DispatchAttributions;

  /**
  * procedure pDecreaseQtyToTransfert
  * Description
  *   D�cr�mente dans les attributions restant � transf�rer, la quantit� pass�e en param�tre
  * @created fp 16.03.2012
  * @lastUpdate
  * @public
  * @param iStockPositionId : position de stock de r�f�rence
  * @param iQuantity : quantit� � d�cr�menter
  */
  procedure pDecreaseQtyToTransfert(
    iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iQuantity        in STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  )
  is
    lBalanceQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type   := iQuantity;
  begin
    for ltplPositionsRemaining in (select   FAL_TMP_REPORT_ATTRIB_ID
                                          , FRA_QTY
                                       from FAL_TMP_REPORT_ATTRIB
                                      where STM_STOCK_POSITION_ID = iStockPositionId
                                   order by FRA_QTY) loop
      if lBalanceQty < ltplPositionsRemaining.FRA_QTY then
        update FAL_TMP_REPORT_ATTRIB
           set FRA_QTY = FRA_QTY - lBalanceQty
         where FAL_TMP_REPORT_ATTRIB_ID = ltplPositionsRemaining.FAL_TMP_REPORT_ATTRIB_ID;

        exit;
      else
        delete from FAL_TMP_REPORT_ATTRIB
              where FAL_TMP_REPORT_ATTRIB_ID = ltplPositionsRemaining.FAL_TMP_REPORT_ATTRIB_ID;

        if lBalanceQty = ltplPositionsRemaining.FRA_QTY then
          exit;
        else
          lBalanceQty  := lBalanceQty - ltplPositionsRemaining.FRA_QTY;
        end if;
      end if;
    end loop;
  end pDecreaseQtyToTransfert;

  /**
  * Description
  *    D�fini quelles attributions seront d�plac�es
  */
  procedure DispatchAttributions_AUTO(
    iStockPositionId        STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iMinQuantity            STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iTotalQuantity          STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iottAttrDisp     in out ttAttrDisp
  , ibBypassPerfect         boolean
  )
  is
    lFound   boolean     := false;
    lCounter pls_integer;
  begin
    -- Si la r�partition parfaite n'a pas fonctionn�
    if    ibBypassPerfect
       or DispatchAttributionsPerfect(iStockPositionId, iMinQuantity, iTotalQuantity, iottAttrDisp) = -1 then
      lCounter  := iottAttrDisp.count + 1;

      -- si pas trouv�, alors on recherche si on trouve une attribution plus grande
      -- que la qt� attrib � transf�rer, mais plus petite que la quantit� totale du transfert
      if not lFound then
        declare
          -- curseur triant les plus grandes quantit�s en premier
          cursor crMatch2(
            iStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
          , iMinQuantity     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
          , iTotalQuantity   STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
          )
          is
            select   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                   , 0 STM_TRANSFER_ATTRIB_ID
                   , 0 STM_STOCK_MOVEMENT_ID
                   , FAL_NETWORK_LINK.FLN_QTY
                   , FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                   , FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
                   , FAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                   , FAL_NETWORK_LINK.STM_LOCATION_ID
                from FAL_NETWORK_LINK
               where STM_STOCK_POSITION_ID = iStockPositionId
                 and FLN_QTY > iMinQuantity
                 and FLN_QTY <= iTotalQuantity
            order by FLN_QTY;

          lBalanceQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type   := iMinQuantity;
        begin
          for tplMatch2 in crMatch2(iStockPositionId, iMinQuantity, iTotalQuantity) loop
            -- Si on a transf�r� plus que demand�, il faut sous-traire le surplus de ce qu'il reste � transf�rer
            if tplMatch2.FLN_QTY - iMinQuantity > 0 then
              pDecreaseQtyToTransfert(iStockPositionId, tplMatch2.FLN_QTY - iMinQuantity);
            end if;

            iottAttrDisp(lCounter)  := tplMatch2;
            lFound                  := true;
            exit;   -- on s'arr�te � la premi�te itt�ration
          end loop;
        end;
      end if;

      -- si pas trouv�, alors on recherche la quantit� dans toutes les attributions
      -- en commen�ant par la plus grande jusqu'� ce que la quantit� � d�placer
      -- soit atteinte
      if not lFound then
        declare
          -- curseur triant les plus grandes quantit�s en premier
          cursor crMatch3(iStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
          is
            select   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                   , 0 STM_TRANSFER_ATTRIB_ID
                   , 0 STM_STOCK_MOVEMENT_ID
                   , FAL_NETWORK_LINK.FLN_QTY
                   , FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                   , FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
                   , FAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                   , FAL_NETWORK_LINK.STM_LOCATION_ID
                from FAL_NETWORK_LINK
               where STM_STOCK_POSITION_ID = iStockPositionId
            order by FLN_QTY desc;

          lBalanceQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type   := iMinQuantity;
          lQty        STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
        begin
          for tplMatch3 in crMatch3(iStockPositionId) loop
            if not IsInList(iottAttrDisp, tplMatch3.FAL_NETWORK_LINK_ID) then
              iottAttrDisp(lCounter)          := tplMatch3;
              iottAttrDisp(lCounter).FLN_QTY  := least(tplMatch3.FLN_QTY, lBalanceQty);
              lBalanceQty                     := lBalanceQty - iottAttrDisp(lCounter).FLN_QTY;
              lQty                            := iottAttrDisp(lCounter).FLN_QTY;
              lFound                          :=(lBalanceQty = 0);
              exit;
            end if;
          end loop;

          if not lFound then
            DispatchAttributions_AUTO(iStockPositionId, lBalanceQty, iTotalQuantity - lQty, iottAttrDisp, true);
            lFound  := true;
          end if;
        end;
      end if;

      -- Si pas trouv�, d�clenchement d'une exception car incoh�rence
      if not lFound then
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Integrity of attributions is violated.') );
      end if;
    end if;
  end DispatchAttributions_AUTO;

  /**
  * Description
  *    D�fini quelles attributions seront d�plac�es
  */
  procedure DispatchAttributions_MANUAL(iStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type, iottAttrDisp in out ttAttrDisp)
  is
    lFound               boolean                        := false;
    lCounter             pls_integer;

    cursor lcurListReportAttrib(iStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
    is
      select   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
             , STM_TRANSFER_ATTRIB.STM_TRANSFER_ATTRIB_ID
             , STM_TRANSFER_ATTRIB.STM_STOCK_MOVEMENT_ID
             , STM_TRANSFER_ATTRIB.STA_QTY
             , FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
             , FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
             , FAL_NETWORK_LINK.STM_STOCK_POSITION_ID
             , FAL_NETWORK_LINK.STM_LOCATION_ID
          from FAL_NETWORK_LINK
             , STM_TRANSFER_ATTRIB
         where FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID = STM_TRANSFER_ATTRIB.FAL_NETWORK_LINK_ID
           and STM_TRANSFER_ATTRIB.STM_STOCK_MOVEMENT_ID = iStockMovementId
      order by FLN_NEED_DELAY asc;

    ltplListReportAttrib lcurListReportAttrib%rowtype;
  begin
    lCounter  := iottAttrDisp.count + 1;

    for ltplListReportAttrib in lcurListReportAttrib(iStockMovementId) loop
      if ltplListReportAttrib.STA_QTY > 0 then
        iottAttrDisp(lCounter)  := ltplListReportAttrib;
        lCounter                := iottAttrDisp.count + 1;
      end if;
    end loop;
  end DispatchAttributions_MANUAL;

  /**
  * Description
  *    Tentative de r�partitions des attributions sans solde
  */
  function DispatchAttributionsPerfect(
    iStockPositionId        STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iMinQuantity            STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iTotalQuantity          STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iottAttrDisp     in out ttAttrDisp
  )
    return number
  is
    lFound           boolean     := false;
    lCounter         pls_integer;
    lResult          number;
    lIsRecord        boolean     := false;
    lUpperCallResult number;

    -- curseur recherchant la qt� exacte
    cursor crMatch1(iStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type, iQuantity STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type)
    is
      select   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
             , 0 STM_TRANSFER_ATTRIB_ID
             , 0 STM_STOCK_MOVEMENT_ID
             , FAL_NETWORK_LINK.FLN_QTY
             , FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
             , FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
             , FAL_NETWORK_LINK.STM_STOCK_POSITION_ID
             , FAL_NETWORK_LINK.STM_LOCATION_ID
          from FAL_NETWORK_LINK
         where STM_STOCK_POSITION_ID = iStockPositionId
           and FLN_QTY <= iQuantity
      order by FLN_QTY desc
             , FLN_NEED_DELAY desc;

    function IsInList(iottAttrDisp in ttAttrDisp, iNetLinkId FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type)
      return boolean
    is
      lResult boolean     := false;
      j       pls_integer;
    begin
      for j in 1 .. iottAttrDisp.count loop
        if iottAttrDisp(j).FAL_NETWORK_LINK_ID = iNetLinkId then
          lResult  := true;
        end if;
      end loop;

      return lResult;
    end IsInList;
  begin
    lCounter  := iottAttrDisp.count + 1;

    -- recherche si on a une attribution correspondant exactement � la quantit�
    for tplMatch1 in crMatch1(iStockPositionId, iMinQuantity) loop
      if not IsInList(iottAttrDisp, tplMatch1.FAL_NETWORK_LINK_ID) then
        lIsRecord               := true;
        iottAttrDisp(lCounter)  := tplMatch1;

        if iottAttrDisp(lCounter).FLN_QTY = iMinQuantity then
          lFound   := true;
          lResult  := 0;
          exit;   -- on s'arr�te � la premi�te itt�ration
        else
          lResult  := DispatchAttributionsPerfect(iStockPositionId, iMinQuantity - tplMatch1.FLN_QTY, iTotalQuantity - tplMatch1.FLN_QTY, iottAttrDisp);

          if lResult = 0 then
            exit;
          else
            iottAttrDisp(lCounter)  := null;
          end if;
        end if;
      end if;
    end loop;

    -- si aucun record trouv�
    if not lIsRecord then
      return -1;
    else
      return lResult;
    end if;
  end DispatchAttributionsPerfect;

  /**
  * Description
  *    D�placement des attributions suite � un transfert commen�ant par le mouvement d'entr�e
  */
  procedure MoveAttribTrsfInput(
    iInputMovementId    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iStockPositionId    STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iQtyMinToTransfer   STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iQtyTotalTransfer   STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iC_ATTRIB_TRSF_KIND STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type
  )
  is
    lttAttrDisp       FAL_PRC_REPORT_ATTRIB.ttAttrDisp;
    ltplTrsfInputInfo FAL_TMP_REPORT_ATTRIB%rowtype;
    lCounter          pls_integer;
    lAttribQty        FAL_NETWORK_LINK.FLN_QTY%type;
    lttTransferAttrib FAL_PRC_REPORT_ATTRIB.ttAttrDisp;
  begin
    DispatchAttributions(iStockPositionId, iQtyMinToTransfer, iQtyTotalTransfer, lttTransferAttrib, iC_ATTRIB_TRSF_KIND, iInputMovementId);

    begin
      -- recherche des infos du mouvement d'entr�e
      select *
        into ltplTrsfInputInfo
        from FAL_TMP_REPORT_ATTRIB
       where STM_STOCK_MOVEMENT_ID = iInputMovementId;

      -- supression du lien
      delete from FAL_TMP_REPORT_ATTRIB
            where FAL_TMP_REPORT_ATTRIB_ID = ltplTrsfInputInfo.FAL_TMP_REPORT_ATTRIB_ID;
    exception
      when no_data_found then
        raise_application_error
             (-20000
            , PCS.PC_FUNCTIONS.TranslateWord('PCS - Aucun mouvement d''entr�e correspondant dans la table temporaire, d�placement d''attribution impossible.')
             );
    end;

    -- pour chaque attribution � d�placer
    for lCounter in lttTransferAttrib.first .. lttTransferAttrib.last loop
      -- exclu les transferts sur le m�me stock (p.ex: positions kit-produit termin�)
      if lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID <> ltplTrsfInputInfo.STM_STOCK_POSITION_ID then
        -- recherche de la quantit� originale de l'attribution
        select FLN_QTY
          into lAttribQty
          from FAL_NETWORK_LINK
         where FAL_NETWORK_LINK_ID = lttTransferAttrib(lCounter).FAL_NETWORK_LINK_ID;

        -- supression de l'attrib originale
        FAL_REDO_ATTRIBS.SuppressionAttribution(lttTransferAttrib(lCounter).FAL_NETWORK_LINK_ID
                                              , lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID
                                              , lttTransferAttrib(lCounter).FAL_NETWORK_SUPPLY_ID
                                              , lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID
                                              , lttTransferAttrib(lCounter).STM_LOCATION_ID
                                              , lAttribQty
                                              , (lAttribQty = lttTransferAttrib(lCounter).FLN_QTY)
                                               );

        -- dans le cas ou l'on ne supprime pas l'entier de l'attribution
        if lAttribQty <> lttTransferAttrib(lCounter).FLN_QTY then
          -- recr�er l'attrib pour le solde
          FAL_NETWORK.CreateAttribBesoinStock(lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID
                                            , lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID
                                            , lttTransferAttrib(lCounter).STM_LOCATION_ID
                                            , lAttribQty - lttTransferAttrib(lCounter).FLN_QTY
                                             );
        end if;

        FAL_NETWORK.CreateAttribBesoinStock(lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID
                                          , ltplTrsfInputInfo.STM_STOCK_POSITION_ID
                                          , ltplTrsfInputInfo.STM_LOCATION_ID
                                          , lttTransferAttrib(lCounter).FLN_QTY
                                           );
      end if;
    end loop;

    STM_PRC_MOVEMENT.gAttribTransfertMode  := false;
    STM_I_PRC_STOCK_POSITION.checkAssignedQuantity(iStockPositionId);

    -- supression des liens
    delete from STM_TRANSFER_ATTRIB
          where STM_TRANSFER_ATTRIB.STM_STOCK_MOVEMENT_ID = iInputMovementId;
  end MoveAttribTrsfInput;

  /**
  * Description
  *    D�placement des attributions suite � un transfert commen�ant par le mouvement de sortie
  */
  procedure MoveAttribTrsfOutput(
    iOutputMovementId   STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iStockPositionId    STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iLocationId         STM_LOCATION.STM_LOCATION_ID%type
  , iQtyTotalTransfer   STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iC_ATTRIB_TRSF_KIND STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type
  )
  is
    ltplTrsfInputInfo FAL_TMP_REPORT_ATTRIB%rowtype;
    lAttribQty        FAL_NETWORK_LINK.FLN_QTY%type;
    lCounter          pls_integer;
    lttTransferAttrib FAL_PRC_REPORT_ATTRIB.ttAttrDisp;
  begin
    begin
      -- recherche des infos du mouvement de sortie
      select *
        into ltplTrsfInputInfo
        from FAL_TMP_REPORT_ATTRIB
       where STM_STOCK_MOVEMENT_ID = iOutputMovementId;

      -- supression du lien
      delete from FAL_TMP_REPORT_ATTRIB
            where FAL_TMP_REPORT_ATTRIB_ID = ltplTrsfInputInfo.FAL_TMP_REPORT_ATTRIB_ID;
    exception
      when no_data_found then
        return;   -- on s'arr�te l� car aucun transfert n'est � effectuer
    end;

    -- S�lectionne les attributions � d�placer
    DispatchAttributions(ltplTrsfInputInfo.STM_STOCK_POSITION_ID
                       , ltplTrsfInputInfo.FRA_QTY
                       , iQtyTotalTransfer
                       , lttTransferAttrib
                       , iC_ATTRIB_TRSF_KIND
                       , iOutputMovementId
                        );

    -- pour chaque attribution � d�placer
    for lCounter in lttTransferAttrib.first .. lttTransferAttrib.last loop
      -- exclu les transferts sur le m�me stock (p.ex: positions kit-produit termin�)
      if lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID <> iStockPositionId then
        -- recherche de la quantit� originale de l'attribution
        select FLN_QTY
          into lAttribQty
          from FAL_NETWORK_LINK
         where FAL_NETWORK_LINK_ID = lttTransferAttrib(lCounter).FAL_NETWORK_LINK_ID;

        -- supression de l'attrib originale
        FAL_REDO_ATTRIBS.SuppressionAttribution(lttTransferAttrib(lCounter).FAL_NETWORK_LINK_ID
                                              , lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID
                                              , lttTransferAttrib(lCounter).FAL_NETWORK_SUPPLY_ID
                                              , lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID
                                              , lttTransferAttrib(lCounter).STM_LOCATION_ID
                                              , lAttribQty
                                              , (lAttribQty = lttTransferAttrib(lCounter).FLN_QTY)
                                               );

        -- dans le cas ou l'on ne supprime pas l'entier de l'attribution
        if lAttribQty <> lttTransferAttrib(lCounter).FLN_QTY then
          -- recr�er l'attrib pour le solde
          FAL_NETWORK.CreateAttribBesoinStock(lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID
                                            , lttTransferAttrib(lCounter).STM_STOCK_POSITION_ID
                                            , lttTransferAttrib(lCounter).STM_LOCATION_ID
                                            , lAttribQty - lttTransferAttrib(lCounter).FLN_QTY
                                             );
        end if;

        -- cr�er l'attrib sur le stock de destination
        FAL_NETWORK.CreateAttribBesoinStock(lttTransferAttrib(lCounter).FAL_NETWORK_NEED_ID, iStockPositionId, iLocationId, lttTransferAttrib(lCounter).FLN_QTY);
      end if;
    end loop;

    STM_PRC_MOVEMENT.gAttribTransfertMode  := false;
    STM_I_PRC_STOCK_POSITION.checkAssignedQuantity(iStockPositionId);

    -- supression des liens
    delete from STM_TRANSFER_ATTRIB
          where STM_TRANSFER_ATTRIB.STM_STOCK_MOVEMENT_ID = iOutputMovementId;
  end MoveAttribTrsfOutput;

  /**
  * function InitQteApproStock
  * Description
  *    Mise � jour de la table de gestion du transfert des attributions selon une quantit�
  * @created AG 27.01.2011
  * @lastUpdate AG 27.01.2011
  * @public
  * @param iStockPositionId : id de la position de stock
  * @param iStockMovementId : id du mouvement de stock
  * @param iC_ATTRIB_TRSF_KIND : mode de transfert (0=pas de transfert 1=transfert automatique, 2 et 3 manuel)
  * @param iQteAttr  : quantit� � attribuer
  */
  procedure InitQteApproStock(
    iStockPositionId            STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iStockMovementId            STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iC_ATTRIB_TRSF_KIND         STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type
  , iQteAttr                    STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iListFAL_NETWORK_NEED_ID in varchar2 default null
  )
  is
    cursor lcurReportAttrib
    is
      select   FRA.STM_TRANSFER_ATTRIB_ID
             , FRA.FAL_NETWORK_LINK_ID
             , FRA.STM_STOCK_MOVEMENT_ID
             , FRA.STM_STOCK_POSITION_ID
             , FRA.STA_ATTRIB_QTY
             , FRA.STA_QTY
             , FRA.STA_NEED_DELAY
          from STM_TRANSFER_ATTRIB FRA
         where (   STM_STOCK_MOVEMENT_ID is null
                or STM_STOCK_MOVEMENT_ID = iStockMovementId)
      order by FRA.STA_NEED_DELAY
             , FRA.STM_TRANSFER_ATTRIB_ID;

    ltplReportAttrib lcurReportAttrib%rowtype;
    lnQteAttr        STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
  begin
    lnQteAttr  := iQteAttr;

    delete from STM_TRANSFER_ATTRIB
          where (STM_STOCK_MOVEMENT_ID is null)
             or (     (STA_QTY = 0)
                 and STM_STOCK_POSITION_ID = iStockPositionId)
             or (     (STM_STOCK_MOVEMENT_ID = iStockMovementId)
                 and (STM_STOCK_POSITION_ID <> iStockPositionId) );

    insert into STM_TRANSFER_ATTRIB
                (STM_TRANSFER_ATTRIB_ID
               , FAL_NETWORK_LINK_ID
               , STM_STOCK_POSITION_ID
               , STM_STOCK_MOVEMENT_ID
               , STA_ATTRIB_QTY
               , STA_QTY
               , STA_NEED_DELAY
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
           , FAL_NETWORK_LINK.STM_STOCK_POSITION_ID
           , iStockMovementID
           , FAL_NETWORK_LINK.FLN_QTY
           , decode(iC_ATTRIB_TRSF_KIND, '2', FAL_NETWORK_LINK.FLN_QTY, '3', 0)
           , FAL_NETWORK_LINK.FLN_NEED_DELAY
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from FAL_NETWORK_LINK
           , FAL_NETWORK_NEED
           , STM_STOCK_POSITION
       where FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID = FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID
         and FAL_NETWORK_LINK.STM_STOCK_POSITION_ID = STM_STOCK_POSITION.STM_STOCK_POSITION_ID
         and STM_STOCK_POSITION.STM_STOCK_POSITION_ID = iStockPositionId
         and (   iListFAL_NETWORK_NEED_ID is null
              or FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID in iListFAL_NETWORK_NEED_ID)
         and not exists(select FAL_NETWORK_LINK_ID
                          from STM_TRANSFER_ATTRIB
                         where STM_TRANSFER_ATTRIB.FAL_NETWORK_LINK_ID = FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID);

    -- pour chaque attribution � d�placer
    for tplReportAttrib in lcurReportAttrib loop
      if tplReportAttrib.STM_STOCK_MOVEMENT_ID is not null then
        if tplReportAttrib.STA_QTY > lnQteAttr then
          if lnQteAttr > 0 then
            update STM_TRANSFER_ATTRIB
               set STA_QTY = lnQteAttr
                 , STM_STOCK_MOVEMENT_ID = iStockMovementId
             where STM_TRANSFER_ATTRIB_ID = tplReportAttrib.STM_TRANSFER_ATTRIB_ID;
          else
            update STM_TRANSFER_ATTRIB
               set STA_QTY = 0
                 , STM_STOCK_MOVEMENT_ID = null
             where STM_TRANSFER_ATTRIB_ID = tplReportAttrib.STM_TRANSFER_ATTRIB_ID;
          end if;

          lnQteAttr  := 0;
        else
          lnQteAttr  := lnQteAttr - tplReportAttrib.STA_QTY;
        end if;
      else
        if tplReportAttrib.STA_ATTRIB_QTY > lnQteAttr then
          if lnQteAttr > 0 then
            update STM_TRANSFER_ATTRIB
               set STA_QTY = lnQteAttr
                 , STM_STOCK_MOVEMENT_ID = iStockMovementId
             where STM_TRANSFER_ATTRIB_ID = tplReportAttrib.STM_TRANSFER_ATTRIB_ID;
          else
            update STM_TRANSFER_ATTRIB
               set STA_QTY = 0
                 , STM_STOCK_MOVEMENT_ID = null
             where STM_TRANSFER_ATTRIB_ID = tplReportAttrib.STM_TRANSFER_ATTRIB_ID;
          end if;

          lnQteAttr  := 0;
        else
          update STM_TRANSFER_ATTRIB
             set STA_QTY = STA_ATTRIB_QTY
               , STM_STOCK_MOVEMENT_ID = iStockMovementId
           where STM_TRANSFER_ATTRIB_ID = tplReportAttrib.STM_TRANSFER_ATTRIB_ID;

          lnQteAttr  := lnQteAttr - tplReportAttrib.STA_ATTRIB_QTY;
        end if;
      end if;
    end loop;
  end;

/**
  * function  GetTotTransferAttrib
  * Description
  *    Total des attributions mise � jour relative � une position de stock
  * @created AG 27.01.2011
  * @lastUpdate AG 27.01.2011
  * @public
  * @param  iStockMovementId : id du mouvement de stock
  * @param iQty  : quantit� � attribuer
  */
  function GetTotTransferAttrib(iStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type)
    return STM_TRANSFER_ATTRIB.STA_QTY%type
  is
    lnQty STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    select nvl(sum(STA_QTY), 0)
      into lnQTY
      from STM_TRANSFER_ATTRIB
     where STM_STOCK_MOVEMENT_ID = iStockMovementId;

    return lnQty;
  end GetTotTransferAttrib;

  /**
  * procedure   UpdateDOC_POSITIONLocation
  * Description
  *    Mise � jour de l'emplacement de la position d'un document DOC_POSITION.STM_LOCATION_ID
  * @created AG 28.02.2011
  * @lastUpdate AG 28.02.2011
  * @public
  * @param  iPositionId : id de la position du document
  * @param iNewLocationId  : Id du nouvel emplacement
  */
  procedure UpdateDOC_POSITIONLocation(iPositionId DOC_POSITION.DOC_POSITION_ID%type, iNewLocationId DOC_POSITION.STM_LOCATION_ID%type)
  is
    cursor lcurReportAttrib
    is
      select DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID
           , DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY
           , DOC_POSITION_DETAIL.PDE_ATTRIB_QUANTITY
           , DOC_POSITION_DETAIL.STM_STOCK_MOVEMENT_ID
           , STM_STOCK_POSITION.STM_STOCK_POSITION_ID
           , STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY
        from DOC_POSITION_DETAIL
           , STM_STOCK_POSITION
       where DOC_POSITION_ID = iPositionId
         and STM_STOCK_POSITION.STM_STOCK_POSITION_ID =
               (STM_FUNCTIONS.GetPositionId(DOC_POSITION_DETAIL.GCO_GOOD_ID
                                          , DOC_POSITION_DETAIL.STM_LOCATION_ID
                                          , DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID
                                          , DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID
                                          , DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID
                                          , DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID
                                          , DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID
                                          , DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1
                                          , DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_2
                                          , DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_3
                                          , DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_4
                                          , DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_5
                                           )
               );

    ltplReportAttrib     lcurReportAttrib%rowtype;
    lvC_ATTRIB_TRSF_KIND STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type;
  begin
    select nvl(MOK.C_ATTRIB_TRSF_KIND, 'NULL')
      into lvC_ATTRIB_TRSF_KIND
      from STM_MOVEMENT_KIND MOK
         , DOC_POSITION POS
     where POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
       and POS.DOC_POSITION_ID = iPositionId;

    update DOC_POSITION_DETAIL
       set STM_LOCATION_ID = iNewLocationId
         , PDE_ATTRIB_QUANTITY = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini
     where DOC_POSITION_ID = iPositionId;

    if    (lvC_ATTRIB_TRSF_KIND = '2')
       or   -- manuel avec initialisation
          (lvC_ATTRIB_TRSF_KIND = '3') then   -- manuel sans initialisation
      -- Traitement de chaque besoin � r�attribuer.
      for ltplReportAttrib in lcurReportAttrib loop
        if (nvl(ltplReportAttrib.STM_STOCK_MOVEMENT_ID, 0) <> 0) then
          delete from STM_TRANSFER_ATTRIB
                where STM_STOCK_MOVEMENT_ID = ltplReportAttrib.STM_STOCK_MOVEMENT_ID;

          if (lvC_ATTRIB_TRSF_KIND = '2') then   -- initialisation
            FAL_PRC_REPORT_ATTRIB.InitQteApproStock(ltplReportAttrib.STM_STOCK_POSITION_ID
                                                  , ltplReportAttrib.STM_STOCK_MOVEMENT_ID
                                                  , lvC_ATTRIB_TRSF_KIND
                                                  , ltplReportAttrib.PDE_BASIS_QUANTITY
                                                   );

            update DOC_POSITION_DETAIL
               set PDE_ATTRIB_QUANTITY = FAL_PRC_REPORT_ATTRIB.GetTotTransferAttrib(ltplReportAttrib.STM_STOCK_MOVEMENT_ID)
             where DOC_POSITION_DETAIL_ID = ltplReportAttrib.DOC_POSITION_DETAIL_ID;
          else   -- sans initialisation
            update DOC_POSITION_DETAIL
               set PDE_ATTRIB_QUANTITY = 0
             where DOC_POSITION_DETAIL_ID = ltplReportAttrib.DOC_POSITION_DETAIL_ID;
          end if;
        end if;
      end loop;
    end if;
  end UpdateDOC_POSITIONLocation;

  /**
  * procedure   MoveCptAllocOnBatch
  * Description
  *   Report des attributions des composants d'une proposition sur un OF
  */
  procedure MoveCptAllocOnBatch(iPropId in FAL_LOT_PROP.FAL_LOT_PROP_ID%type, iBatchId in FAL_LOT.FAL_LOT_ID%type)
  is
    type tAllocSaved is record(
      FLN_QTY                  FAL_NETWORK_LINK.FLN_QTY%type
    , FAL_NETWORK_NEED_ID      FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID%type
    , FAL_NETWORK_SUPPLY_ID    FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID%type
    , STM_STOCK_POSITION_ID    FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
    , STM_LOCATION_ID          FAL_NETWORK_LINK.STM_LOCATION_ID%type
    , GCO_GOOD_ID              FAL_NETWORK_NEED.GCO_GOOD_ID%type
    , FAL_LOT_MAT_LINK_PROP_ID FAL_NETWORK_NEED.FAL_LOT_MAT_LINK_PROP_ID%type
    );

    type tblAllocSaved is table of tAllocSaved
      index by pls_integer;

    type tBatchRequirement is record(
      FAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
    , GCO_GOOD_ID         FAL_NETWORK_NEED.GCO_GOOD_ID%type
    );

    type tblBatchRequirements is table of tBatchRequirement
      index by pls_integer;

    lAllocSaved        tblAllocSaved;
    lBatchRequirements tblBatchRequirements;
    lLnkIdx            integer;
    lReqIdx            integer                                          := 0;
    lPreviousCptId     FAL_NETWORK_NEED.FAL_LOT_MAT_LINK_PROP_ID%type   := 0;
    lnFreeQty          FAL_NETWORK_NEED.FAN_FREE_QTY%type               := 0;
  begin
    /* S�lection des attributions de la propositions */
    select   LNK.FLN_QTY
           , LNK.FAL_NETWORK_NEED_ID
           , LNK.FAL_NETWORK_SUPPLY_ID
           , LNK.STM_STOCK_POSITION_ID
           , LNK.STM_LOCATION_ID
           , NEED.GCO_GOOD_ID
           , NEED.FAL_LOT_MAT_LINK_PROP_ID
    bulk collect into lAllocSaved
        from FAL_NETWORK_LINK LNK
           , FAL_NETWORK_NEED NEED
       where LNK.FAL_NETWORK_NEED_ID = NEED.FAL_NETWORK_NEED_ID
         and NEED.FAL_LOT_PROP_ID = iPropId
         and NEED.FAL_LOT_MAT_LINK_PROP_ID is not null
    order by NEED.GCO_GOOD_ID
           , NEED.FAL_LOT_MAT_LINK_PROP_ID
           , NEED.STM_LOCATION_ID
           , NEED.FAN_BALANCE_QTY;

    /* S�lection des besoins du lot sur lesquels il faut reporter les attributions */
    select   FAL_NETWORK_NEED_ID
           , GCO_GOOD_ID
    bulk collect into lBatchRequirements
        from FAL_NETWORK_NEED
       where FAL_LOT_ID = iBatchId
         and FAL_LOT_MATERIAL_LINK_ID is not null
    order by GCO_GOOD_ID
           , FAL_LOT_MATERIAL_LINK_ID
           , STM_LOCATION_ID
           , FAN_BALANCE_QTY;

    for lLnkIdx in 1 .. lAllocSaved.count loop
      /* Suppression Attributions Besoin-Stock */
      FAL_NETWORK.Attribution_Suppr_BesoinStock(lAllocSaved(lLnkIdx).FAL_NETWORK_NEED_ID);
      /* Suppression Attributions Besoin-Appro */
      FAL_NETWORK.Attribution_Suppr_BesoinAppro(lAllocSaved(lLnkIdx).FAL_NETWORK_NEED_ID);

      if lPreviousCptId <> lAllocSaved(lLnkIdx).FAL_LOT_MAT_LINK_PROP_ID then
        /* Changement de composant sur le lien, on change aussi sur le besoin en repartant du besoin sur lequel on �tait d�j� positionn�.
           Le probl�me est si on a plusieurs fois le m�me bien dans les composants. D'o� les tests sur le GCO_GOOD_ID et le FAL_LOT_MAT_LINK_PROP_ID. */
        lPreviousCptId  := lAllocSaved(lLnkIdx).FAL_LOT_MAT_LINK_PROP_ID;
        lReqIdx         := lReqIdx + 1;

        loop
          exit when(lReqIdx > lBatchRequirements.count)
                or (lBatchRequirements(lReqIdx).GCO_GOOD_ID >= lAllocSaved(lLnkIdx).GCO_GOOD_ID);
          lReqIdx  := lReqIdx + 1;
        end loop;
      end if;

      if (lReqIdx > lBatchRequirements.count) then
        exit;
      end if;

      if lAllocSaved(lLnkIdx).GCO_GOOD_ID = lBatchRequirements(lReqIdx).GCO_GOOD_ID then
        /* S'il y a eu diminution de quantit� sur la proposition avant la reprise, les r�seaux de la proposition ne tiennent pas compte de cette
           r�duction alors que ceux de l'OF sont faits en tenant bien compte de la nouvelle quantit�. On pourra donc moins attribuer sur l'OF
           que la quantit� d'origine. Il faut donc v�rifier syst�matiquement la quantit� libre du besoin avant de reporter l'attribution. */
        lnFreeQty  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('FAL_NETWORK_NEED', 'FAN_FREE_QTY', lBatchRequirements(lReqIdx).FAL_NETWORK_NEED_ID);

        if lnFreeQty > 0 then
          if lAllocSaved(lLnkIdx).FAL_NETWORK_SUPPLY_ID is not null then
            FAL_NETWORK.CreateAttribBesoinAppro(lBatchRequirements(lReqIdx).FAL_NETWORK_NEED_ID
                                              , lAllocSaved(lLnkIdx).FAL_NETWORK_SUPPLY_ID
                                              , least(lAllocSaved(lLnkIdx).FLN_QTY, lnFreeQty)
                                               );
          else
            FAL_NETWORK.CreateAttribBesoinStock(lBatchRequirements(lReqIdx).FAL_NETWORK_NEED_ID
                                              , lAllocSaved(lLnkIdx).STM_STOCK_POSITION_ID
                                              , lAllocSaved(lLnkIdx).STM_LOCATION_ID
                                              , least(lAllocSaved(lLnkIdx).FLN_QTY, lnFreeQty)
                                               );
          end if;
        end if;
      end if;
    end loop;
  end MoveCptAllocOnBatch;
end FAL_PRC_REPORT_ATTRIB;
