--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_PACKAGING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_PACKAGING" 
is
  -- Cr�ation des positions emballage pour le document
  procedure CreatePackagingPosition(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crPosition(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   SHI.GCO_GOOD_ID
             , sum(POS.POS_FINAL_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_QUANTITY
             , sum(POS.POS_BALANCE_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_BALANCE_QTY
             , SHI.STM_STOCK_ID
             , SHI.STM_LOCATION_ID
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , GCO_COMPL_DATA_SALE CSA
             , GCO_PACKING_ELEMENT SHI
         where DMT.DOC_DOCUMENT_ID = cDocumentID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and CSA.GCO_COMPL_DATA_SALE_ID = GCO_FUNCTIONS.GetComplDataSaleId(POS.GCO_GOOD_ID, nvl(DMT.PAC_THIRD_DELIVERY_ID, DMT.PAC_THIRD_ID) )
           and CSA.GCO_COMPL_DATA_SALE_ID = SHI.GCO_COMPL_DATA_SALE_ID
      group by SHI.GCO_GOOD_ID
             , SHI.STM_STOCK_ID
             , SHI.STM_LOCATION_ID;

    tplPosition crPosition%rowtype;

    cursor crDetail(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cGoodID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   POS.DOC_DOCUMENT_ID
             , SHI.GCO_GOOD_ID
             , PDE_BASIS_DELAY
             , PDE_INTERMEDIATE_DELAY
             , PDE_FINAL_DELAY
             , sum(PDE_FINAL_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_QUANTITY
             , sum(PDE_BALANCE_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_BALANCE_QTY
             , SHI.STM_STOCK_ID
             , SHI.STM_LOCATION_ID
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , GCO_COMPL_DATA_SALE CSA
             , GCO_PACKING_ELEMENT SHI
         where DMT.DOC_DOCUMENT_ID = cDocumentID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and POS.GCO_GOOD_ID = CSA.GCO_GOOD_ID
           and CSA.GCO_COMPL_DATA_SALE_ID = GCO_FUNCTIONS.GetComplDataSaleId(POS.GCO_GOOD_ID, nvl(DMT.PAC_THIRD_DELIVERY_ID, DMT.PAC_THIRD_ID) )
           and SHI.GCO_COMPL_DATA_SALE_ID = CSA.GCO_COMPL_DATA_SALE_ID
           and SHI.GCO_GOOD_ID = cGoodID
           and POS.C_GAUGE_TYPE_POS = '1'
      group by POS.DOC_DOCUMENT_ID
             , SHI.GCO_GOOD_ID
             , SHI.STM_STOCK_ID
             , SHI.STM_LOCATION_ID
             , PDE_BASIS_DELAY
             , PDE_INTERMEDIATE_DELAY
             , PDE_FINAL_DELAY;

    tplDetail   crDetail%rowtype;
    tmpGAP_ID   DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
  begin
    -- effacement des positions packaging pour �tre s�r
    DeletePackagingPosition(aDocumentId);

    -- V�rifier que le gabarit position contient le type de position pour l'emballage
    select nvl(max(GAP.DOC_GAUGE_POSITION_ID), 0) GAP_ID
      into tmpGAP_ID
      from DOC_GAUGE_POSITION GAP
         , DOC_DOCUMENT DOC
     where DOC.DOC_DOCUMENT_ID = aDocumentID
       and DOC.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
       and GAP.C_GAUGE_TYPE_POS = '1'
       and GAP.GAP_DESIGNATION = 'Packaging';

    -- V�rifier que le gabarit position contient le type de position pour l'emballage
    if tmpGAP_ID <> 0 then
      -- Curseur sur les positions du document
      open crPosition(aDocumentID);

      fetch crPosition
       into tplPosition;

      -- Balayer les positions du document pour lesquelles on doit cr�er des positions Emballage
      while crPosition%found loop
        declare
          NewPOS_ID DOC_POSITION.DOC_POSITION_ID%type;
        begin
          -- Cr�ation de la position
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => NewPOS_ID
                                               , aDocumentID       => aDocumentID
                                               , aPosCreateMode    => '117'
                                               , aGapID            => tmpGAP_ID
                                               , aGoodID           => tplPosition.GCO_GOOD_ID
                                               , aBasisQuantity    => tplPosition.PACK_QUANTITY
                                               , aBalanceQty       => tplPosition.PACK_BALANCE_QTY
                                               , aStockID          => tplPosition.STM_STOCK_ID
                                               , aLocationID       => tplPosition.STM_LOCATION_ID
                                               , aGenerateDetail   => 0
                                                );

          -- Cr�ation des d�tails de position pour la position emballage courante
          open crDetail(aDocumentID, tplPosition.GCO_GOOD_ID);

          fetch crDetail
           into tplDetail;

          -- Balayer les d�tails de position � cr�er
          while crDetail%found loop
            declare
              NewPDE_ID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
            begin
              DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => NewPDE_ID
                                               , aPositionID      => NewPOS_ID
                                               , aPdeCreateMode   => '117'
                                               , aQuantity        => tplDetail.PACK_QUANTITY
                                               , aBalanceQty      => tplDetail.PACK_BALANCE_QTY
                                               , aBasisDelay      => tplDetail.PDE_BASIS_DELAY
                                               , aInterDelay      => tplDetail.PDE_INTERMEDIATE_DELAY
                                               , aFinalDelay      => tplDetail.PDE_FINAL_DELAY
                                                );

              -- D�tail suivant
              fetch crDetail
               into tplDetail;
            end;
          end loop;

          close crDetail;

          -- position suivante
          fetch crPosition
           into tplPosition;
        end;
      end loop;

      close crPosition;
    end if;
  end CreatePackagingPosition;

  -- Effacement des positions emballage du document
  procedure DeletePackagingPosition(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    for tplPosPackagingList in (select DOC_POSITION_ID
                                  from DOC_POSITION
                                 where DOC_DOCUMENT_ID = aDocumentID
                                   and DOC_GAUGE_POSITION_ID =
                                         (select GAP.DOC_GAUGE_POSITION_ID
                                            from DOC_GAUGE_POSITION GAP
                                               , DOC_DOCUMENT DOC
                                           where DOC.DOC_DOCUMENT_ID = aDocumentID
                                             and DOC.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
                                             and GAP.C_GAUGE_TYPE_POS = '1'
                                             and GAP.GAP_DESIGNATION = 'Packaging') ) loop
      DOC_DELETE.DeletePosition(aPositionId => tplPosPackagingList.DOC_POSITION_ID, aMajDocStatus => false);
    end loop;
  end DeletePackagingPosition;

  -- Sauvegarde les liens de d�charge du document courant
  procedure SaveParentLinks(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    ListDocID.delete;

    select distinct PDE_SRC.DOC_DOCUMENT_ID
    bulk collect into ListDocID
               from DOC_POSITION_DETAIL PDE_TGT
                  , DOC_POSITION_DETAIL PDE_SRC
              where PDE_TGT.DOC_DOCUMENT_ID = aDocumentID
                and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID is not null
                and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
           group by PDE_SRC.DOC_DOCUMENT_ID;
  end SaveParentLinks;

  -- M�j des emballages sur les documents sources de d�charge
  procedure UpdateParentPackaging(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crDocumentSource(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select distinct DOC_DOCUMENT_ID
                 from (select PDE_SRC.DOC_DOCUMENT_ID
                         from DOC_POSITION_DETAIL PDE_TGT
                            , DOC_POSITION_DETAIL PDE_SRC
                        where PDE_TGT.DOC_DOCUMENT_ID = cDocumentID
                          and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID is not null
                          and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                       union
                       select COM_LIST_ID_TEMP_ID DOC_DOCUMENT_ID
                         from COM_LIST_ID_TEMP
                        where LID_CODE = 'PACKAGING-DOC_DOCUMENT_ID')
             order by 1;

    cursor crDetail(cPositionID DOC_POSITION.DOC_POSITION_ID%type)
    is
      select   DOC_POSITION_DETAIL_ID
             , PDE_BASIS_QUANTITY
             , PDE_BALANCE_QUANTITY
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = cPositionID
      order by PDE_BASIS_DELAY
             , DOC_POSITION_DETAIL_ID;

    tplDetail             crDetail%rowtype;
    DocumentSrcID         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNEW_PACK_QUANTITY    DOC_POSITION.POS_BASIS_QUANTITY%type;
    vNEW_PACK_BALANCE_QTY DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vQty                  DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vIndex                integer;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'PACKAGING-DOC_DOCUMENT_ID';

    if ListDocID.count > 0 then
      for vIndex in ListDocID.first .. ListDocID.last loop
        begin
          insert into COM_LIST_ID_TEMP
                      (COM_LIST_ID_TEMP_ID
                     , LID_CODE
                      )
               values (ListDocID(vIndex)
                     , 'PACKAGING-DOC_DOCUMENT_ID'
                      );
        exception
          when others then
            null;
        end;
      end loop;
    end if;

    -- M�j des positions packaging sur les documents parents (DECHARGE)
    open crDocumentSource(aDocumentID);

    fetch crDocumentSource
     into DocumentSrcID;

    while crDocumentSource%found loop
      -- Liste des positions emballage � modifier du document source
      for tplPosPack in (select   POS.DOC_POSITION_ID
                                , POS.GCO_GOOD_ID
                                , POS.POS_BASIS_QUANTITY OLD_PACK_QUANTITY
                                , POS.POS_BALANCE_QUANTITY OLD_PACK_BALANCE_QTY
                                , POS.STM_STOCK_ID
                                , POS.STM_LOCATION_ID
                             from DOC_POSITION POS
                                , DOC_GAUGE_POSITION GAP
                            where POS.DOC_DOCUMENT_ID = DocumentSrcID
                              and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                              and POS.C_GAUGE_TYPE_POS = '1'
                              and GAP.GAP_DESIGNATION = 'Packaging'
                         order by POS.DOC_POSITION_ID) loop
        -- Calculer les qt�s pour pour les emballages pour les positions bien en fonction
        -- du bien emballage, stock et emplacement
        select sum(POS.POS_FINAL_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_QUANTITY
             , sum(POS.POS_BALANCE_QUANTITY * decode(nvl(SHI.SHI_QUOTA, 0), 0, 1, SHI.SHI_QUOTA) ) PACK_BALANCE_QTY
          into vNEW_PACK_QUANTITY
             , vNEW_PACK_BALANCE_QTY
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_GAUGE_POSITION GAP
             , GCO_COMPL_DATA_SALE CSA
             , GCO_PACKING_ELEMENT SHI
         where DMT.DOC_DOCUMENT_ID = DocumentSrcID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.C_GAUGE_TYPE_POS = '1'
           and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
           and GAP.GAP_DESIGNATION <> 'Packaging'
           and CSA.GCO_COMPL_DATA_SALE_ID = GCO_FUNCTIONS.GetComplDataSaleId(POS.GCO_GOOD_ID, nvl(DMT.PAC_THIRD_DELIVERY_ID, DMT.PAC_THIRD_ID) )
           and CSA.GCO_COMPL_DATA_SALE_ID = SHI.GCO_COMPL_DATA_SALE_ID
           and SHI.GCO_GOOD_ID = tplPosPack.GCO_GOOD_ID
           and nvl(SHI.STM_STOCK_ID, tplPosPack.STM_STOCK_ID) = tplPosPack.STM_STOCK_ID
           and nvl(SHI.STM_LOCATION_ID, tplPosPack.STM_LOCATION_ID) = tplPosPack.STM_LOCATION_ID;

        -- Pour une position emballage identifi�e
        -- Qt� emballage calcul�e = Qt� emballage ET
        -- Qt� solde emballage calcul�e <> Qt� solde emballage
        if     (vNEW_PACK_QUANTITY = tplPosPack.OLD_PACK_QUANTITY)
           and (vNEW_PACK_BALANCE_QTY <> tplPosPack.OLD_PACK_BALANCE_QTY) then
          -- M�j de la position emballage
          update DOC_POSITION
             set POS_BALANCE_QUANTITY = vNEW_PACK_BALANCE_QTY
               , C_DOC_POS_STATUS = case
                                     when vNEW_PACK_BALANCE_QTY = 0 then '04'
                                     when vNEW_PACK_BALANCE_QTY = vNEW_PACK_QUANTITY then '02'
                                     else '03'
                                   end
           where DOC_POSITION_ID = tplPosPack.DOC_POSITION_ID;

          -- M�j des d�tails de la position emballage
          -- Si qt� solde position = 0 , Alors qt� solde d�tails = 0
          if (vNEW_PACK_BALANCE_QTY = 0) then
            update DOC_POSITION_DETAIL
               set PDE_BALANCE_QUANTITY = 0
             where DOC_POSITION_ID = tplPosPack.DOC_POSITION_ID;
          -- Si qt� solde position = qt� position, Alors qt� solde d�tail = qt� d�tail
          elsif(vNEW_PACK_BALANCE_QTY = vNEW_PACK_QUANTITY) then
            update DOC_POSITION_DETAIL
               set PDE_BALANCE_QUANTITY = PDE_BASIS_QUANTITY
             where DOC_POSITION_ID = tplPosPack.DOC_POSITION_ID;
          else
            -- Si la qt� solde est diff. de 0 et diff. de la qt� de la position
            -- Il faut balayer les �ventuels d�tails pour effectuer le traitement
            -- de la qt� solde de chaque d�tail
            --
            -- Qt� diff�rencielle entre l'ancienne qt� solde et la nouvelle qt� solde
            vQty  := abs(tplPosPack.OLD_PACK_BALANCE_QTY - vNEW_PACK_BALANCE_QTY);

            -- Diminution de la qt� solde
            if (vNEW_PACK_BALANCE_QTY < tplPosPack.OLD_PACK_BALANCE_QTY) then
              open crDetail(tplPosPack.DOC_POSITION_ID);

              fetch crDetail
               into tplDetail;

              while(crDetail%found)
               and (vQty > 0) loop
                if tplDetail.PDE_BALANCE_QUANTITY > 0 then
                  update DOC_POSITION_DETAIL
                     set PDE_BALANCE_QUANTITY = greatest(tplDetail.PDE_BALANCE_QUANTITY - vQty, 0)
                   where DOC_POSITION_ID = tplPosPack.DOC_POSITION_ID;

                  -- Soustraire la qt� utilis�e � la qt� qui doit etre sold�e
                  vQty  := vQty - greatest(tplDetail.PDE_BALANCE_QUANTITY - vQty, 0);
                end if;

                fetch crDetail
                 into tplDetail;
              end loop;

              close crDetail;
            -- Augmentation de la qt� solde
            else
              open crDetail(tplPosPack.DOC_POSITION_ID);

              fetch crDetail
               into tplDetail;

              while(crDetail%found)
               and (vQty > 0) loop
                if tplDetail.PDE_BALANCE_QUANTITY < tplDetail.PDE_BASIS_QUANTITY then
                  update DOC_POSITION_DETAIL
                     set PDE_BALANCE_QUANTITY = least(tplDetail.PDE_BALANCE_QUANTITY + vQty, tplDetail.PDE_BASIS_QUANTITY)
                   where DOC_POSITION_ID = tplPosPack.DOC_POSITION_ID;

                  -- Soustraire la qt� utilis�e � la qt� qu'il faut rajouter au solde
                  vQty  := vQty -(least(tplDetail.PDE_BALANCE_QUANTITY + vQty, tplDetail.PDE_BASIS_QUANTITY) - tplDetail.PDE_BALANCE_QUANTITY);
                end if;

                fetch crDetail
                 into tplDetail;
              end loop;

              close crDetail;
            end if;
          end if;
        end if;
      end loop;

      -- M�j du statut du document source
      DOC_PRC_DOCUMENT.UpdateDocumentStatus(DocumentSrcID);

      fetch crDocumentSource
       into DocumentSrcID;
    end loop;

    close crDocumentSource;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'PACKAGING-DOC_DOCUMENT_ID';

    ListDocID.delete;
  end;

  -- Proc�dure � appeler � la validation d'un document pour les positions EMBALLAGE
  procedure OnValidateDocumentPackaging(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Cr�ation des pos EMB pour le document courant
    CreatePackagingPosition(aDocumentID);
    -- M�j des positions EMB sur les doc des liens parents qui figurent dans la liste ListDocID
    UpdateParentPackaging(aDocumentID);
  end OnValidateDocumentPackaging;

  -- Proc�dure � appeler apr�s �dition d'un document contenant des positions EMBALLAGE
  procedure OnUpdatePackagingDocument(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Effacement des positions emballage du document
    DeletePackagingPosition(aDocumentID);
    -- Sauvegarde les liens de d�charge du document courant
    SaveParentLinks(aDocumentID);
  end OnUpdatePackagingDocument;
end DOC_DOCUMENT_PACKAGING;
