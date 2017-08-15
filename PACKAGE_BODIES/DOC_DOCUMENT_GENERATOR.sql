--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_GENERATOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_GENERATOR" 
is
  /**
  * function pProtectDocument
  * Description
  *    Cette fonction protège le document que l'on va traiter et retourne 1 si tout s'est bien déroulé
  * @created fp 05.01.2007
  * @lastUpdate
  * @private
  * @param  aInterfaceId : id du document interface à protéger
  * @return 1 si OK, 0 si on a pas pu protéger le document
  */
  function pProtectDocument(aInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return number
  is
    pragma autonomous_transaction;
    tplInterface DOC_INTERFACE%rowtype;
  begin
    select     *
          into tplInterface
          from DOC_INTERFACE
         where DOC_INTERFACE_ID = aInterfaceId
    for update nowait;

    if tplInterface.DOI_PROTECTED = 1 then
      commit;
      return 0;
    else
      update DOC_INTERFACE
         set DOI_PROTECTED = 1
       where DOC_INTERFACE_ID = aInterfaceId;

      commit;
      return 1;
    end if;
  exception
    when ex.ROW_LOCKED then
      rollback;
      return 0;
  end pProtectDocument;

  /**
  * procedure GenerateJobPendingDocuments
  * Description
  *    generate all pending documents from a job
  */
  procedure GenerateJobPendingDocuments(aDebug in number default 0, aCommit in number default 1, aOrigin in varchar2 default null)
  is
    vNewDocumentIDList varchar2(2000);
    vErrMsg            varchar2(2000);
  begin
    GeneratePendingDocuments(vNewDocumentIDList, vErrMsg, aDebug, aCommit, aOrigin);
  end GenerateJobPendingDocuments;

  /**
  * procedure GeneratePendingDocuments
  * Description
  *    generate all pending documents
  */
  procedure GeneratePendingDocuments(
    aNewDocumentsIdList out    varchar2
  , aErrorMsg           out    varchar2
  , aDebug              in     number default 0
  , aCommit             in     number default 1
  , aOrigin             in     varchar2 default null
  )
  is
    cursor crPendingDocuments(aCrOrigin in varchar2)
    is
      select   DOC_INTERFACE_ID
          from DOC_INTERFACE
         where C_DOI_INTERFACE_STATUS in('02', '05', '90')
           and DOI_PROTECTED = 0
           and (   aCrOrigin is null
                or C_DOC_INTERFACE_ORIGIN = aCrOrigin)
      order by 1;
  begin
    for tplPendingDocument in crPendingDocuments(aOrigin) loop
      -- Effacement de la liste des document créés, car si beaucoup de documents
      -- créés la variable de retour n'est pas assez grande pour contenir tous les id
      if length(aNewDocumentsIdList) > 1500 then
        aNewDocumentsIdList  := null;
      end if;

      GenerateDocument(tplPendingDocument.DOC_INTERFACE_ID, 0, aErrorMsg, 0, aCommit, aNewDocumentsIdList);
    end loop;
  end GeneratePendingDocuments;

  /**
  * procedure GenerateDocument
  * Description
  *   Génére un document logistique depuis le DOC_INTERFACE
  */
  procedure GenerateDocument(
    aInterfaceId        in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aConfirm            in     number default 0
  , aErrorMsg           out    varchar2
  , aDebug              in     number default 0
  , aCommit             in     number default 1
  , aNewDocumentsIdList in out varchar2
  )
  is
    -- DOC_CART_OE_GAUGE = Gabarit qui déclenche l'Order Entry
    -- DOC_CART_OE_LP_TARGET = Gabarit destination dans la décharge de l'Order Entry
    -- Recherche les gabarits de l'ORDER_ENTRY
    cursor crGetOEGauges
    is
      select SRC_GAU.DOC_GAUGE_ID OE_SOURCE_GAUGE_ID
           , TGT_GAU.DOC_GAUGE_ID OE_TARGET_GAUGE_ID
        from DOC_GAUGE SRC_GAU
           , DOC_GAUGE TGT_GAU
       where SRC_GAU.GAU_DESCRIBE = PCS.PC_CONFIG.GETCONFIG('DOC_CART_OE_GAUGE')
         and TGT_GAU.GAU_DESCRIBE = PCS.PC_CONFIG.GETCONFIG('DOC_CART_OE_LP_TARGET');

    tplGetOEGauges       crGetOEGauges%rowtype;
    iDischargeOrderEntry integer;
    aOE_SrcGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    aOE_TgtGaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    errorCode            varchar2(10);
    doi_status           DOC_INTERFACE.C_DOI_INTERFACE_STATUS%type;
    myError              varchar2(4000);
    vActiveSavepoint     boolean;
  begin
    if pProtectDocument(aInterfaceId) = 1 then
      -- Recherche les gabarits de l'ORDER_ENTRY
      open crGetOEGauges;

      fetch crGetOEGauges
       into tplGetOEGauges;

      aOE_SrcGaugeID    := tplGetOEGauges.OE_SOURCE_GAUGE_ID;
      aOE_TgtGaugeID    := tplGetOEGauges.OE_TARGET_GAUGE_ID;

      close crGetOEGauges;

      vActiveSavepoint  := false;

      for tplDocumentsToGenerate in (select   nvl(DOP.DOC_GAUGE_ID, DOI.DOC_GAUGE_ID) DOC_GAUGE_ID
                                            , (case
                                                 when nvl(DOI.C_INTERFACE_GEN_MODE, 'INSERT') = 'INSERT' then(case
                                                                                                                when DOI.C_DOC_INTERFACE_ORIGIN = '301' then '141'
                                                                                                                when DOI.C_DOC_INTERFACE_ORIGIN = '401' then '142'
                                                                                                                else '140'
                                                                                                              end
                                                                                                             )
                                                 when DOI.C_INTERFACE_GEN_MODE = 'DISCHARGE' then(case
                                                                                                    when DOI.C_DOC_INTERFACE_ORIGIN = '301' then '341'
                                                                                                    else '340'
                                                                                                  end
                                                                                                 )
                                                 when DOI.C_INTERFACE_GEN_MODE = 'UPDATE' then '440'
                                               end
                                              ) C_DOC_CREATE_MODE
                                         from DOC_INTERFACE DOI
                                            , DOC_INTERFACE_POSITION DOP
                                        where DOI.DOC_INTERFACE_ID = DOP.DOC_INTERFACE_ID
                                          and DOI.DOC_INTERFACE_ID = aInterfaceID
                                          and DOI.C_DOI_INTERFACE_STATUS in('02', '05', '90')
                                          and DOP.C_DOP_INTERFACE_STATUS in('02', '05', '90')
                                     group by nvl(DOP.DOC_GAUGE_ID, DOI.DOC_GAUGE_ID)
                                            , DOI.C_INTERFACE_GEN_MODE
                                            , DOI.C_DOC_INTERFACE_ORIGIN) loop
        declare
          newDocumentId   DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
          SrcDocumentID   DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
          iGenIntFootChrg integer;
        begin
          -- Place un savepoint avant la génération du document pour un éventuel rollback
          savepoint GenerateDocument;
          vActiveSavepoint  := true;

          begin
            -- Vérifier s'il y a des remises/taxes dans la table DOC_INTERFACE_FOOT_CHARGE
            select nvl(DOI_FOOT_CHARGE_COPY, 0)
              into iGenIntFootChrg
              from DOC_INTERFACE
             where DOC_INTERFACE_ID = aInterfaceID;

            -- Méthode générale pour la création de document
            DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID    => newDocumentID
                                                 , aMode             => tplDocumentsToGenerate.C_DOC_CREATE_MODE   -- Code générateur de document
                                                 , aGaugeID          => tplDocumentsToGenerate.DOC_GAUGE_ID
                                                 , aSrcInterfaceID   => aInterfaceId
                                                 , aErrorMsg         => aErrorMsg
                                                 , aDebug            => aDebug
                                                  );

            -- Erreur contrôlée lors de la création du document
            if aErrorMsg is not null then
              -- Annule la création du document en cas d'erreur contrôlée
              rollback to savepoint GenerateDocument;
              vActiveSavepoint  := false;
              UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                          , aIntPositionID   => null
                                          , aIntPosNumber    => null
                                          , aNewStatus       => '90'
                                          , aErrorMsg        => aErrorMsg
                                           );
              -- Applique les modifications du suivi
              commit;
              goto NextDocument;
            else
              -- Applique la création du nouveau document
              commit;
            end if;
          exception
            when others then
              -- Annule la création du document en cas d'erreur incontrôlée, si ce n'est pas déjà fait
              if vActiveSavepoint then
                rollback to savepoint GenerateDocument;
                vActiveSavepoint  := false;
              end if;

              aErrorMsg  := 'PCS - Erreur document' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
              UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                          , aIntPositionID   => null
                                          , aIntPosNumber    => null
                                          , aNewStatus       => '90'
                                          , aErrorMsg        => aErrorMsg
                                           );
              -- Applique les modifications du suivi
              commit;
              goto NextDocument;
          end;

          -- Génération des positions du document
          GeneratePositions(aInterfaceId, tplDocumentsToGenerate.DOC_GAUGE_ID, newDocumentId, aErrorMsg, aDebug);

          -- Création des remises/taxes selon les données de la table DOC_INTERFACE_FOOT_CHARGE
          if     (aErrorMsg is null)
             and (iGenIntFootChrg = 1) then
            CreateInterfaceFootCharge(newDocumentID, aInterfaceID);

            -- Màj les flags sur le recalcul ou la création des remises/taxes de pied de document
            update DOC_DOCUMENT
               set DMT_RECALC_FOOT_CHARGE = 0
                 , DMT_CREATE_FOOT_CHARGE = 0
             where DOC_DOCUMENT_ID = newDocumentID;

            commit;
            -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
            -- cas d'exception si le savepoint n'a pas été reposé.
            vActiveSavepoint  := false;
          end if;

          -- erreur contrôlée lors de la création des positions
          if aErrorMsg is not null then
            -- Déprotéger le document avant l'effacement
            update DOC_DOCUMENT
               set DMT_PROTECTED = 0
             where DOC_DOCUMENT_ID = newDocumentID;

            -- Effacer le document logistique
            DOC_DELETE.DeleteDocument(newDocumentID, 0);
            commit;
            goto NextDocument;
          -- La maj des enregistrements DOC_INTERFACE_POSITION a déjà été faite dans la méthode GeneratePositions
          end if;

          -- Mise à jour de la liste des documents créés
          if aNewDocumentsIdList is not null then
            aNewDocumentsIdList  := aNewDocumentsIdList || ',' || newDocumentId;
          else
            aNewDocumentsIdList  := newDocumentId;
          end if;

          -- Finalisation du document
          begin
            -- Place un savepoint avant la finalization du document pour un éventuel rollback
            savepoint GenerateDocument;
            vActiveSavepoint  := true;
            DOC_FINALIZE.FinalizeDocument(newDocumentID, 1, 1, 1);
            -- Applique le finalisation du document et son éventuelle confirmation.
            commit;
            -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
            -- cas d'exception si le savepoint n'a pas été reposé.
            vActiveSavepoint  := false;
          exception
            when others then
              -- Annule la création du document en cas d'erreur incontrôlée, si ce n'est pas déjà fait
              if vActiveSavepoint then
                rollback to savepoint GenerateDocument;
                vActiveSavepoint  := false;
              end if;

              aErrorMsg  := 'PCS - Erreur finalisation document' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              -- Màj du document logistique avec l'erreur obtenue lors de la finalisation du document et protèger le doc
              update DOC_DOCUMENT
                 set DMT_ERROR_MESSAGE = aErrorMsg
                   , DMT_PROTECTED = 1
               where DOC_DOCUMENT_ID = newDocumentID;

              commit;
              goto NextDocument;
          end;

          begin
            -- Place un savepoint avant la finalization du document pour un éventuel rollback
            savepoint GenerateDocument;
            vActiveSavepoint  := true;
            -- Création des données de la vente au comptant
            GenerateFootPayment(aDocumentID => newDocumentID, aInterfaceID => aInterfaceID);
            commit;
            -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
            -- cas d'exception si le savepoint n'a pas été reposé.
            vActiveSavepoint  := false;
          exception
            when others then
              -- Annule la création des données de la vente au comptant en cas d'erreur incontrôlée, si ce n'est pas déjà fait
              if vActiveSavepoint then
                rollback to savepoint GenerateDocument;
                vActiveSavepoint  := false;
              end if;

              aErrorMsg  :=
                        'PCS - Erreur à la création de la vente au comptant' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

              -- Màj du document logistique avec l'erreur obtenue lors de la finalisation du document et protèger le doc
              update DOC_DOCUMENT
                 set DMT_ERROR_MESSAGE = aErrorMsg
                   , DMT_PROTECTED = 1
               where DOC_DOCUMENT_ID = newDocumentID;

              commit;
              goto NextDocument;
          end;

          -- Vérifie si on doit faire une décharge ORDER_ENTRY
          if     (aOE_SrcGaugeID is not null)
             and (aOE_TgtGaugeID is not null)
             and (aOE_SrcGaugeID = tplDocumentsToGenerate.DOC_GAUGE_ID) then
            iDischargeOrderEntry  := 1;
          else
            iDischargeOrderEntry  := 0;
          end if;

          -- Confirmation du document
          -- il faut effectuer la confirmation du document source
          --  si confirmation demandée OU si on doit faire la décharge Order Entry
          if    (aConfirm = 1)
             or (iDischargeOrderEntry = 1) then
            DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(newDocumentId, errorCode, aErrorMsg, 1);
            -- On valide les modifications dans tous les cas.
            commit;
            -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
            -- cas d'exception si le savepoint n'a pas été reposé.
            vActiveSavepoint  := false;

            -- Stoper le processus s'il y a eu une erreur lors de la confirmation
            if nvl(errorCode, aErrorMsg) is not null then
              aErrorMsg  := 'PCS - Erreur confirmation document' || ' - ' || errorCode || ' ' || aErrorMsg;
              goto NextDocument;
            end if;
          end if;

          -- Décharge - ORDER_ENTRY
          if iDischargeOrderEntry = 1 then
            begin
              SrcDocumentID  := newDocumentId;
              newDocumentId  := null;
              -- Décharge - ORDER_ENTRY
              DischargeOEDocument(aNewDocumentID   => newDocumentId
                                , aSrcDocumentID   => SrcDocumentID
                                , aMode            => '345'   -- Décharge - ORDER_ENTRY
                                , aSrcGaugeID      => tplDocumentsToGenerate.DOC_GAUGE_ID
                                , aTgtGaugeID      => aOE_TgtGaugeID
                                , aInterfaceID     => aInterfaceID
                                , aErrorMsg        => aErrorMsg
                                , aDebug           => aDebug
                                 );

              -- Mise à jour de la liste des documents créés
              if newDocumentID is not null then
                aNewDocumentsIdList  := aNewDocumentsIdList || ',' || newDocumentId || '*';
              end if;

              commit;
            exception
              -- Lorsque l'on a eu un problème lors de la décharge
              when others then
                -- Mise à jour de la liste des documents créés si le document à quand même été créé
                if newDocumentID is not null then
                  select max(DOC_DOCUMENT_ID)
                    into newDocumentID
                    from DOC_DOCUMENT
                   where DOC_DOCUMENT_ID = newDocumentID;

                  if newDocumentID is not null then
                    aNewDocumentsIdList  := aNewDocumentsIdList || ',' || newDocumentId || '*';
                  end if;
                end if;

                goto NextDocument;
            end;
          end if;
        end;

        <<NextDocument>>
        -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
        -- cas d'exception si le savepoint n'a pas été reposé.
        vActiveSavepoint  := false;

        -- Stocker les messages d'erreur entre chaque création de document
        if aErrorMsg is not null then
          if myError is null then
            myError  := aErrorMsg;
          else
            myError  := myError || co.cLineBreak || '                 ' || aErrorMsg;
          end if;
        end if;
      end loop;

      -- Màj du statut du record du DOC_INTERFACE_ID
      UpdateInterfaceStatus(aInterfaceID);
      -- lorsque l'on utilise se package par job oracle le dernier document n'était pas commité
      commit;
      aErrorMsg         := myError;
    end if;
  end GenerateDocument;

  /**
  * procedure DischargeOEDocument
  * Description
  *   Effectue la décharge par Order Entry du document source issu de la création par le DOC_INTERFACE
  */
  procedure DischargeOEDocument(
    aNewDocumentID in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSrcDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aMode          in     varchar2
  , aSrcGaugeID    in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aTgtGaugeID    in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aInterfaceID   in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aErrorMsg      in out varchar2
  , aDebug         in     number default 0
  , aCommit        in     number default 1
  )
  is
    tmpFlowID        DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    SqlCmd           varchar2(32000);
    vActiveSavepoint boolean;
  begin
    begin
      -- Recherche le flux de décharge
      select DOC_I_LIB_GAUGE.GetFlowID(GAU.C_ADMIN_DOMAIN, DMT.PAC_THIRD_ID)
        into tmpFlowID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = aSrcDocumentID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;
    exception
      when no_data_found then
        tmpFlowID  := null;
        aErrorMsg  :=
                'PCS - Aucun flux de décharge trouvé (DischargeOEDocument)' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        return;
    end;

    begin
      -- Place un savepoint avant la génération du document pour un éventuel rollback
      savepoint DischargeOEDocument;
      vActiveSavepoint  := true;
      -- Méthode générale pour la création de document
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID    => aNewDocumentID
                                           , aSrcDocumentID    => aSrcDocumentID
                                           , aGaugeID          => aTgtGaugeID
                                           , aMode             => aMode   -- Décharge - Order Entry
                                           , aSrcInterfaceID   => aInterfaceId
                                           , aErrorMsg         => aErrorMsg
                                           , aDebug            => aDebug
                                            );

      if aErrorMsg is not null then
        -- Annule la création du document en cas d'erreur contrôlée
        rollback to savepoint DischargeOEDocument;
        vActiveSavepoint  := false;
      else
        -- Applique la création du nouveau document
        commit;
        -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
        -- cas d'exception si le savepoint n'a pas été reposé.
        vActiveSavepoint  := false;
      end if;
    exception
      when others then
        -- Annule la création du document en cas d'erreur incontrôlée, si ce n'est pas déjà fait
        if vActiveSavepoint then
          rollback to savepoint DischargeOEDocument;
          vActiveSavepoint  := false;
        end if;

        aErrorMsg  := 'PCS - Erreur document (DischargeOEDocument)' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        return;
    end;

    begin
      -- Place un savepoint avant la génération du document pour un éventuel rollback
      savepoint DischargeOEDocument;
      vActiveSavepoint  := true;
      -- Création d'une position texte sur le document source indiquant l'origine du document
      GenerateOETextPosition(aNewDocumentID   => aNewDocumentID
                           , aSrcDocumentID   => aSrcDocumentID
                           , aMode            => aMode   -- Décharge - Order Entry
                           , aErrorMsg        => aErrorMsg
                           , aDebug           => aDebug
                            );

      if aErrorMsg is null then
        -- Aucune erreur, on applique la création de la nouvelle position
        commit;
        -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
        -- cas d'exception si le savepoint n'a pas été reposé.
        vActiveSavepoint  := false;
      else
        -- S'il y a eu une erreur identifiée lors de la création de la position
        -- Annule la création du document en cas d'erreur contrôlée
        rollback to savepoint DischargeOEDocument;
        vActiveSavepoint  := false;

        -- Déprotéger le document avant l'effacement
        update DOC_DOCUMENT
           set DMT_PROTECTED = 0
         where DOC_DOCUMENT_ID = aNewDocumentID;

        -- Effacer le document logistique
        DOC_DELETE.DeleteDocument(aNewDocumentID, 0);
        commit;
        return;
      end if;
    exception
      when others then
        -- Annule la création de la position courante en cas d'erreur incontrôlée, si ce n'est pas déjà fait (commit ou rollback)
        if vActiveSavepoint then
          rollback to savepoint DischargeOEDocument;
          vActiveSavepoint  := false;
        end if;

        aErrorMsg  := 'PCS - Erreur position/détail (DischargeOEDocument)' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        -- Termine le traitement
        return;
    end;

    begin
      -- Place un savepoint avant le remplissage de la table temporaire de décharge pour un éventuel rollback
      -- en cas d'exception.
      savepoint DischargeOEDocument;
      vActiveSavepoint  := true;
      -- Rechercher la cmd sql externe pour l'insertion de la préparation de la décharge dans la table temp de décharge
      SqlCmd            := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_INTERFACE', aGroup => 'INTERFACE_OE_DISCHARGE', aSqlId => 'DISCHARGE', aHeader => false);
      SqlCmd            := replace(SqlCmd, '[COMPANY_OWNER' || '].', '');
      SqlCmd            := replace(SqlCmd, '[CO' || '].', '');

      -- Effacer les éventuels enregistrement restant dans la table de décharge
      delete from DOC_POS_DET_COPY_DISCHARGE
            where NEW_DOCUMENT_ID = aNewDocumentID;

      -- Insertion de la préparation de la décharge dans la table temp de décharge
      execute immediate SqlCmd
                  using aNewDocumentID, aSrcDocumentID;

      -- Applique l'insertion de la préparation de la décharge
      commit;
      -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
      -- cas d'exception si le savepoint n'a pas été reposé.
      vActiveSavepoint  := false;
      -- Place un savepoint avant la génération de la position par décharge pour un éventuel rollback
      savepoint DischargeOEDocument;
      vActiveSavepoint  := true;
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(aNewDocumentId);
      -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId, tmpFlowID);
      -- Applique la création des positions
      commit;
      -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
      -- cas d'exception si le savepoint n'a pas été reposé.
      vActiveSavepoint  := false;

      -- Effacer la table de décharge
      delete from DOC_POS_DET_COPY_DISCHARGE
            where NEW_DOCUMENT_ID = aNewDocumentID;

      -- Applique la suppression des entrées dans la table temporaire
      commit;
      -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
      -- cas d'exception si le savepoint n'a pas été reposé.
      vActiveSavepoint  := false;
      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(aNewDocumentID, 1, 1, 1);
      -- Applique le finalisation du document et son éventuelle confirmation.
      commit;
    exception
      when others then
        -- Annule le remplissage de la table temporaire de décharge ou la création de la position courante en cas
        -- d'erreur incontrôlée, si ce n'est pas déjà fait (commit ou rollback)
        if vActiveSavepoint then
          rollback to savepoint DischargeOEDocument;
          vActiveSavepoint  := false;
        end if;

        aErrorMsg  :=
               'PCS - Erreur décharge position/détail (DischargeOEDocument)' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        -- Termine le traitement sans monter l'exception
        return;
    end;
  end DischargeOEDocument;

  /**
  * procedure GenerateOETextPosition
  * Description
  *   Génération de la position texte pour le document issu de l'Order Entry
  */
  procedure GenerateOETextPosition(
    aNewDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSrcDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aMode          in     varchar2
  , aErrorMsg      out    varchar2
  , aDebug         in     number default 0
  )
  is
    newPositionId DOC_POSITION.DOC_POSITION_ID%type;
    posBodyText   DOC_POSITION.POS_BODY_TEXT%type;
  begin
    -- Recherche le n° de document source
    select max(DMT_NUMBER || ' - ' || to_char(sysdate, 'DD.MM.YYYY') )
      into posBodyText
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aSrcDocumentID;

    -- Créer une position de type texte contenant le n° du document source
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => newPositionId
                                         , aDocumentID      => aNewDocumentId
                                         , aPosCreateMode   => '140'
                                         , aTypePos         => '4'
                                         , aPosBodyText     => posBodyText
                                         , aErrorMsg        => aErrorMsg
                                         , aDebug           => aDebug
                                          );
  end GenerateOETextPosition;

  /**
  * procedure GeneratePositions
  * Description
  *   Génération des positions depuis le DOC_INTERFACE_POSITION
  */
  procedure GeneratePositions(
    aInterfaceID   in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aGaugeID       in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aNewDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorMsg      out    varchar2
  , aDebug         in     number default 0
  , aCommit        in     number default 1
  )
  is
    cursor crInterfacePositions(cInterfaceId DOC_INTERFACE.DOC_INTERFACE_ID%type, cGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select decode(SEL.DOC_INTERFACE_POSITION_ID, -1, null, SEL.DOC_INTERFACE_POSITION_ID) DOC_INTERFACE_POSITION_ID
           , SEL.DOP_POS_NUMBER
           , SEL.C_INTERFACE_GEN_MODE
           , SEL.C_GAUGE_TYPE_POS
        from (select   DOP.DOC_INTERFACE_POSITION_ID
                     , DOP.DOP_POS_NUMBER
                     , nvl(DOP.C_INTERFACE_GEN_MODE, 'INSERT') as C_INTERFACE_GEN_MODE
                     , DOP.C_GAUGE_TYPE_POS
                  from DOC_INTERFACE_POSITION DOP
                     , DOC_INTERFACE DOI
                 where DOP.DOC_INTERFACE_ID = cInterfaceId
                   and DOP.DOC_INTERFACE_ID = DOI.DOC_INTERFACE_ID
                   and nvl(DOP.DOC_GAUGE_ID, DOI.DOC_GAUGE_ID) = cGaugeId
                   and DOP.DOP_POS_NUMBER is null
                   and DOP.DOC_POSITION_PT_ID is null
              union
              select   -1 DOC_INTERFACE_POSITION_ID
                     , DOP.DOP_POS_NUMBER
                     , nvl(DOP.C_INTERFACE_GEN_MODE, 'INSERT') as C_INTERFACE_GEN_MODE
                     , DOP.C_GAUGE_TYPE_POS
                  from DOC_INTERFACE_POSITION DOP
                     , DOC_INTERFACE DOI
                 where DOP.DOC_INTERFACE_ID = cInterfaceId
                   and DOP.DOC_INTERFACE_ID = DOI.DOC_INTERFACE_ID
                   and nvl(DOP.DOC_GAUGE_ID, DOI.DOC_GAUGE_ID) = cGaugeId
                   and DOP.DOP_POS_NUMBER is not null
                   and DOP.DOC_POSITION_PT_ID is null
              group by DOP.DOP_POS_NUMBER
                     , nvl(DOP.C_INTERFACE_GEN_MODE, 'INSERT')
                     , DOP.C_GAUGE_TYPE_POS
              order by 3 asc
                     , 2 asc
                     , 1 asc) SEL;

    vPosMode     varchar(3);
    newStatus    DOC_INTERFACE_POSITION.C_DOP_INTERFACE_STATUS%type;
    tmpFlowID    DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    SqlCmd       varchar2(32000);
    vCptCount    integer;
    vNewPosCptID DOC_POSITION.DOC_POSITION_ID%type;
    vGenCpt      integer;
    vPosPTID     DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
  begin
    begin
      -- Recherche le flux de création
      select DOC_I_LIB_GAUGE.GetFlowID(GAU.C_ADMIN_DOMAIN, DMT.PAC_THIRD_ID)
        into tmpFlowID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = aNewDocumentID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;
    exception
      when no_data_found then
        tmpFlowID  := null;
    end;

    for tplInterfacePosition in crInterfacePositions(aInterfaceId, aGaugeId) loop
      declare
        newPositionID     DOC_POSITION.DOC_POSITION_ID%type;
        iGenPosChrg       integer;
        iIntPosChrg       integer;
        tmpChargeIntPosID DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type;
        vActiveSavepoint  boolean;
      begin
        vActiveSavepoint  := false;

        -- Vérifier s'il y a des remises/taxes dans la table DOC_INTERFACE_POS_CHARGE
        if tplInterfacePosition.DOC_INTERFACE_POSITION_ID is not null then
          tmpChargeIntPosID  := tplInterfacePosition.DOC_INTERFACE_POSITION_ID;
        else
          select min(DOC_INTERFACE_POSITION_ID)
            into tmpChargeIntPosID
            from DOC_INTERFACE_POSITION
           where DOC_INTERFACE_ID = aInterfaceId
             and DOP_POS_NUMBER = tplInterfacePosition.DOP_POS_NUMBER;
        end if;

        begin
          select decode(nvl(DOP_POS_CHARGE_COPY, 0), 0, 1, 0)
               , nvl(DOP_POS_CHARGE_COPY, 0)
            into iGenPosChrg
               , iIntPosChrg
            from DOC_INTERFACE_POSITION
           where DOC_INTERFACE_POSITION_ID = tmpChargeIntPosID;
        exception
          when no_data_found then
            iGenPosChrg  := 1;
            iIntPosChrg  := 0;
        end;

        if tplInterfacePosition.C_INTERFACE_GEN_MODE = 'INSERT' then
          -- Place un savepoint avant la génération de la position pour un éventuel rollback
          savepoint GeneratePosition;
          vActiveSavepoint  := true;
          vCptCount         := 0;

          -- Rechercher le mode de création sur le document
          select C_DOC_CREATE_MODE
            into vPosMode
            from DOC_DOCUMENT
           where DOC_DOCUMENT_ID = aNewDocumentID;

          -- Si position de type PT, vérifier si les composants figurent dans
          -- la table DOC_INTERFACE_POSITION
          if tplInterfacePosition.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
            -- Rechercher l'id de la position interface, si on possède uniquement le n° de position
            if tplInterfacePosition.DOC_INTERFACE_POSITION_ID is null then
              select min(DOC_INTERFACE_POSITION_ID)
                into vPosPTID
                from DOC_INTERFACE_POSITION
               where DOC_INTERFACE_ID = aInterfaceId
                 and DOP_POS_NUMBER = tplInterfacePosition.DOP_POS_NUMBER;
            else
              vPosPTID  := tplInterfacePosition.DOC_INTERFACE_POSITION_ID;
            end if;

            -- Rechercher les positions CPT figurant dans la DOC_INTERFACE_POSITION
            select count(*)
              into vCptCount
              from DOC_INTERFACE_POSITION
             where DOC_INTERFACE_ID = aInterfaceId
               and DOC_POSITION_PT_ID = vPosPTID;

            -- Il y a des cpt dans la table des pos, alors créer ici les pos CPT
            if vCptCount > 0 then
              -- La création de la position PT, ne doit pas créer les CPT
              -- On se charge de la création des CPT en balayant la table des positions
              vGenCpt  := 0;
            else
              -- Pas de cpt dans la table des positions
              -- La création de la position PT, doit créer les CPT
              vGenCpt  := 1;
            end if;
          else
            -- La position n'est pas une position de type PT
            -- Pas de création de positions CPT
            vGenCpt  := 0;
          end if;

          -- Création de la position
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => newPositionID
                                               , aDocumentID               => aNewDocumentId
                                               , aPosCreateMode            => vPosMode
                                               , aGenerateDetail           => 1
                                               , aGenerateCPT              => vGenCpt
                                               , aInterfaceID              => aInterfaceId
                                               , aInterfacePosID           => tplInterfacePosition.DOC_INTERFACE_POSITION_ID
                                               , aInterfacePosNbr          => tplInterfacePosition.DOP_POS_NUMBER
                                               , aGenerateDiscountCharge   => iGenPosChrg
                                               , aDebug                    => aDebug
                                               , aErrorMsg                 => aErrorMsg
                                                );

          if aErrorMsg is null then
            -- Création des remises/taxes selon les données de la table DOC_INTERFACE_POS_CHARGE
            if iIntPosChrg = 1 then
              CreateInterfacePosCharge(aPositionID => newPositionId, aIntPositionID => tmpChargeIntPosID);
              -- Recalcul des montants de la position selon les remises/taxes
              DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(newPositionId);
            end if;

            -- Applique la création de la nouvelle position et de ses éventuelles remises et taxes
            commit;
            -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
            -- cas d'exception si le savepoint n'a pas été reposé.
            vActiveSavepoint  := false;
            -- Mise à jour des enregistrement DOC_INTERFACE_POSITION traités
            UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                        , aIntPositionID   => tplInterfacePosition.DOC_INTERFACE_POSITION_ID
                                        , aIntPosNumber    => tplInterfacePosition.DOP_POS_NUMBER
                                        , aNewStatus       => '04'
                                        , aErrorMsg        => aErrorMsg
                                         );
            -- Applique les modifications du suivi
            commit;

            -- Création des positions CPT, qui se trouvent dans la table DOC_INTERFACE_POSITION
            if vCptCount > 0 then
              for tplPosCpt in (select   DOC_INTERFACE_POSITION_ID
                                       , DOP_POS_NUMBER
                                    from DOC_INTERFACE_POSITION
                                   where DOC_INTERFACE_ID = aInterfaceID
                                     and DOC_POSITION_PT_ID = vPosPTID
                                order by DOP_POS_NUMBER
                                       , DOC_INTERFACE_POSITION_ID) loop
                -- Place un savepoint avant la génération de la position pour un éventuel rollback
                savepoint GeneratePosCPT;
                vActiveSavepoint  := true;
                -- Création de la position composant
                vNewPosCptID      := null;
                -- Création de la position
                DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => vNewPosCptID
                                                     , aDocumentID               => aNewDocumentId
                                                     , aPosCreateMode            => vPosMode
                                                     , aPTPositionID             => newPositionID
                                                     , aGenerateDetail           => 1
                                                     , aInterfaceID              => aInterfaceId
                                                     , aInterfacePosID           => tplPosCpt.DOC_INTERFACE_POSITION_ID
                                                     , aInterfacePosNbr          => tplPosCpt.DOP_POS_NUMBER
                                                     , aGenerateDiscountCharge   => iGenPosChrg
                                                     , aDebug                    => aDebug
                                                     , aErrorMsg                 => aErrorMsg
                                                      );

                if aErrorMsg is null then
                  -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
                  -- cas d'exception si le savepoint n'a pas été reposé.
                  commit;
                  vActiveSavepoint  := false;
                  -- Mise à jour des enregistrement DOC_INTERFACE_POSITION traités
                  UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                              , aIntPositionID   => tplPosCpt.DOC_INTERFACE_POSITION_ID
                                              , aIntPosNumber    => tplPosCpt.DOP_POS_NUMBER
                                              , aNewStatus       => '04'
                                              , aErrorMsg        => aErrorMsg
                                               );
                  -- Applique les modifications du suivi
                  commit;
                else
                  -- S'il y a eu une erreur identifiée lors de la création de la position
                  -- Annule la création du document en cas d'erreur contrôlée
                  rollback to savepoint GeneratePosCPT;
                  vActiveSavepoint  := false;
                  -- Echec à la création -> Bloquer les enregistrements de la table DOC_INTERFACE_POSITION
                  newStatus         := '90';
                  -- Mise à jour des enregistrement DOC_INTERFACE_POSITION traités
                  UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                              , aIntPositionID   => tplPosCpt.DOC_INTERFACE_POSITION_ID
                                              , aIntPosNumber    => tplPosCpt.DOP_POS_NUMBER
                                              , aNewStatus       => newStatus
                                              , aErrorMsg        => aErrorMsg
                                               );
                  -- Applique les modifications du suivi
                  commit;
                  -- Termine le traitement
                  return;
                end if;
              end loop;

              -- Màj des montants/poids de la position PT
              DOC_POSITION_FUNCTIONS.UpdatePositionPTAmounts(newPositionID);
              commit;
            end if;
          else
            -- S'il y a eu une erreur identifiée lors de la création de la position
            -- Annule la création du document en cas d'erreur contrôlée
            rollback to savepoint GeneratePosition;
            vActiveSavepoint  := false;
            -- Echec à la création -> Bloquer les enregistrements de la table DOC_INTERFACE_POSITION
            newStatus         := '90';
            -- Mise à jour des enregistrement DOC_INTERFACE_POSITION traités
            UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                        , aIntPositionID   => tplInterfacePosition.DOC_INTERFACE_POSITION_ID
                                        , aIntPosNumber    => tplInterfacePosition.DOP_POS_NUMBER
                                        , aNewStatus       => newStatus
                                        , aErrorMsg        => aErrorMsg
                                         );
            -- Applique les modifications du suivi
            commit;
            -- Termine le traitement
            return;
          end if;
        elsif tplInterfacePosition.C_INTERFACE_GEN_MODE = 'DISCHARGE' then
          -- Place un savepoint avant le remplissage de la table temporaire de décharge pour un éventuel rollback
          -- en cas d'exception.
          savepoint GeneratePosition;
          vActiveSavepoint  := true;
          -- Rechercher la cmd sql externe pour l'insertion de la préparation de la décharge dans la table temp de décharge
          SqlCmd            := PCS.PC_FUNCTIONS.GetSql(aTableName   => 'DOC_INTERFACE', aGroup => 'INTERFACE_DISCHARGE', aSqlId => 'DISCHARGE'
                                                     , aHeader      => false);
          SqlCmd            := replace(SqlCmd, '[COMPANY_OWNER' || '].', '');
          SqlCmd            := replace(SqlCmd, '[CO' || '].', '');

          -- Effacer les éventuels enregistrement restant dans la table de décharge
          delete from DOC_POS_DET_COPY_DISCHARGE
                where NEW_DOCUMENT_ID = aNewDocumentID;

          -- Insertion de la préparation de la décharge dans la table temp de décharge
          execute immediate SqlCmd
                      using aNewDocumentID, aInterfaceId, tplInterfacePosition.DOC_INTERFACE_POSITION_ID, tplInterfacePosition.DOP_POS_NUMBER;

          -- Applique l'insertion de la préparation de la décharge
          commit;
          -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
          -- cas d'exception si le savepoint n'a pas été reposé.
          vActiveSavepoint  := false;

          -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
          declare
            InputData         varchar2(32000);
            TargetPositionId  DOC_POSITION.DOC_POSITION_ID%type;
            DischargeInfoCode varchar2(10);
          begin
            -- Assignation du dernier numéro de position d'après le document en cours
            DOC_COPY_DISCHARGE.SetLastDocPosNumber(aNewDocumentId);

            for tplPosition in (select   DOC_POSITION_ID
                                    from DOC_POS_DET_COPY_DISCHARGE
                                   where NEW_DOCUMENT_ID = aNewDocumentId
                                     and CRG_SELECT = 1
                                     and DOC_DOC_POSITION_ID is null
                                group by DOC_POSITION_ID
                                order by min(DOC_POS_DET_COPY_DISCHARGE_ID) ) loop
              -- Place un savepoint avant la génération de la position par décharge pour un éventuel rollback
              savepoint GeneratePosition;
              vActiveSavepoint  := true;
              --appel de la décharge de position
              DOC_COPY_DISCHARGE.DischargePosition(tplPosition.DOC_POSITION_ID
                                                 , aNewDocumentId
                                                 , null
                                                 , null
                                                 , tmpFlowID
                                                 , InputData
                                                 , TargetPositionId
                                                 , DischargeInfoCode
                                                  );

              -- Création des remises/taxes selon les données de la table DOC_INTERFACE_POS_CHARGE
              if iIntPosChrg = 1 then
                -- Effacer les remises et taxes qui ont éventuellement été crées dans la décharge
                delete from DOC_POSITION_CHARGE
                      where DOC_POSITION_ID = TargetPositionId;

                -- Recalcul des montants de la position selon les remises/taxes
                DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(TargetPositionId);
                -- Création des remises/taxes selon les données de la table DOC_INTERFACE_POS_CHARGE
                CreateInterfacePosCharge(aPositionID => TargetPositionId, aIntPositionID => tmpChargeIntPosID);
                -- Recalcul des montants de la position selon les remises/taxes
                DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(TargetPositionId);
              end if;

              -- Applique la création de la nouvelle position et de ses éventuelles remises et taxes
              commit;
              -- Le commit supprime tous les savepoints. Il faut donc éviter d'effectuer le rollback to savepoint en
              -- cas d'exception si le savepoint n'a pas été reposé.
              vActiveSavepoint  := false;
            end loop;
          end;

          -- Effacer la table de décharge
          delete from DOC_POS_DET_COPY_DISCHARGE
                where NEW_DOCUMENT_ID = aNewDocumentID;

          -- Applique la suppression des entrées dans la table temporaire
          commit;
          -- Mise à jour des enregistrement DOC_INTERFACE_POSITION traités
          UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                      , aIntPositionID   => tplInterfacePosition.DOC_INTERFACE_POSITION_ID
                                      , aIntPosNumber    => tplInterfacePosition.DOP_POS_NUMBER
                                      , aNewStatus       => '04'
                                      , aErrorMsg        => aErrorMsg
                                       );
          -- Applique les modifications du suivi
          commit;
        end if;
      exception
        when others then
          -- Annule le remplissage de la table temporaire de décharge ou la création de la position courante et de ses
          -- éventuelles remises et taxes en cas d'erreur incontrôlée, si ce n'est pas déjà fait (commit ou rollback)
          if vActiveSavepoint then
            rollback to savepoint GeneratePosition;
            vActiveSavepoint  := false;
          end if;

          aErrorMsg  := 'PCS - Erreur position/détail' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          UpdateInterfacePositionStatus(aInterfaceID     => aInterfaceId
                                      , aIntPositionID   => tplInterfacePosition.DOC_INTERFACE_POSITION_ID
                                      , aIntPosNumber    => tplInterfacePosition.DOP_POS_NUMBER
                                      , aNewStatus       => '90'
                                      , aErrorMsg        => aErrorMsg
                                       );
          -- Applique les modifications du suivi
          commit;
          -- Termine le traitement
          return;
      end;
    end loop;
  end GeneratePositions;

  procedure UpdateInterfaceStatus(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    cursor crIntPosStatus(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select nvl(sum(decode(C_DOP_INTERFACE_STATUS, '04', 1, 0) ), 0) STATUS_04
           , nvl(sum(decode(C_DOP_INTERFACE_STATUS, '90', 1, 0) ), 0) STATUS_90
           , count(*) TOTAL
        from DOC_INTERFACE_POSITION
       where DOC_INTERFACE_ID = cInterfaceID;

    tplIntPosStatus crIntPosStatus%rowtype;
  begin
    open crIntPosStatus(aInterfaceID);

    fetch crIntPosStatus
     into tplIntPosStatus;

    close crIntPosStatus;

    -- Toutes les positions interface sont liquidées
    if tplIntPosStatus.STATUS_04 = tplIntPosStatus.TOTAL then
      -- Liquider aussi l'enregistrement du DOC_INTERFACE
      update DOC_INTERFACE
         set C_DOI_INTERFACE_STATUS = '04'
           , C_DOI_INTERFACE_FAIL_REASON = null
           , DOI_ERROR = 0
           , DOI_ERROR_MESSAGE = 0
           , DOI_PROTECTED = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID;
    -- Toutes les positions interface sont en erreur
    elsif tplIntPosStatus.STATUS_90 = tplIntPosStatus.TOTAL then
      -- Mettre en erreur aussi l'enregistrement du DOC_INTERFACE
      update DOC_INTERFACE
         set C_DOI_INTERFACE_STATUS = '90'
           , C_DOI_INTERFACE_FAIL_REASON = nvl(C_DOI_INTERFACE_FAIL_REASON, '900')
           , DOI_PROTECTED = 0
           , DOI_ERROR = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID;
    end if;
  end UpdateInterfaceStatus;

  procedure UpdateInterfacePositionStatus(
    aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aIntPosNumber  in DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type
  , aNewStatus     in DOC_INTERFACE_POSITION.C_DOP_INTERFACE_STATUS%type
  , aErrorMsg      in varchar2
  )
  is
  begin
    -- ID de position interface
    if aIntPositionID is not null then
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = aNewStatus
           , DOP_ERROR = decode(aErrorMsg, null, 0, 1)
           , DOP_ERROR_MESSAGE = aErrorMsg
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID
         and DOC_INTERFACE_POSITION_ID = aIntPositionID;
    -- Numéro de position
    elsif aIntPosNumber is not null then
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = aNewStatus
           , DOP_ERROR = decode(aErrorMsg, null, 0, 1)
           , DOP_ERROR_MESSAGE = aErrorMsg
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID
         and DOP_POS_NUMBER = aIntPosNumber;
    -- ID de la table DOC_INTERFACE
    else
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = aNewStatus
           , DOP_ERROR = decode(aErrorMsg, null, 0, 1)
           , DOP_ERROR_MESSAGE = aErrorMsg
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID;
    end if;

    -- Màj du statut de l'interface en attente de l'intervention utilisateur
    if aNewStatus = '90' then
      update DOC_INTERFACE
         set C_DOI_INTERFACE_STATUS = '05'
           , C_DOI_INTERFACE_FAIL_REASON = nvl(C_DOI_INTERFACE_FAIL_REASON, '900')
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = aInterfaceID;
    end if;
  end UpdateInterfacePositionStatus;

  /**
  * procedure GenerateFootPayment
  * Description
  *    Création de la vente au comptant selon les données de la table DOC_INTERFACE_FOOT_PAYMENT
  */
  procedure GenerateFootPayment(
    aDocumentID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aCommit      in number default 1
  )
  is
    cursor crFootPayment(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   *
          from DOC_INTERFACE_FOOT_PAYMENT
         where DOC_INTERFACE_ID = cInterfaceID
      order by DOC_INTERFACE_FOOT_PAYMENT_ID;

    tplFootPayment                 crFootPayment%rowtype;
    iGAS_CASH_REGISTER             DOC_GAUGE_STRUCTURED.GAS_CASH_REGISTER%type;
    iGAS_CASH_MULTIPLE_TRANSACTION DOC_GAUGE_STRUCTURED.GAS_CASH_MULTIPLE_TRANSACTION%type;
    vC_DIRECT_PAY                  PAC_PAYMENT_CONDITION.C_DIRECT_PAY%type;
    nFOO_DOCUMENT_TOTAL_AMOUNT     DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
  begin
    open crFootPayment(aInterfaceID);

    fetch crFootPayment
     into tplFootPayment;

    -- Vérifier s'il y a des données de vente au comptant à créér
    if crFootPayment%found then
      -- Recherche les flags du gabarit et de la condition de paiement
      select nvl(max(GAS.GAS_CASH_REGISTER), 0)
           , nvl(max(GAS.GAS_CASH_MULTIPLE_TRANSACTION), 0)
           , nvl(max(PCO.C_DIRECT_PAY), 0)
           , nvl(max(FOO.FOO_DOCUMENT_TOTAL_AMOUNT), 0)
        into iGAS_CASH_REGISTER
           , iGAS_CASH_MULTIPLE_TRANSACTION
           , vC_DIRECT_PAY
           , nFOO_DOCUMENT_TOTAL_AMOUNT
        from DOC_DOCUMENT DMT
           , DOC_FOOT FOO
           , DOC_GAUGE_STRUCTURED GAS
           , PAC_PAYMENT_CONDITION PCO
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and DMT.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+);

      -- Vente au comptant "Multiple"
      if     (iGAS_CASH_MULTIPLE_TRANSACTION = 1)
         and (vC_DIRECT_PAY <> '0') then
        -- Effacer les encaissements générés en standard dans le FinalizeDocument
        delete from DOC_FOOT_PAYMENT
              where DOC_FOOT_ID = aDocumentID;

        commit;

        while crFootPayment%found loop
          -- Recalculer les montants MB et MD s'ils n'ont pas étés inscrits dans la table
          if tplFootPayment.FOP_PAID_AMOUNT_MB is null then
            -- Modification du montant à encaisser (reçu)
            DOC_FOOT_PAYMENT_FUNCTIONS.OnReceivedAmountModification(tplFootPayment.FOP_RECEIVED_AMOUNT
                                                                  , null
                                                                  , tplFootPayment.ACS_FINANCIAL_CURRENCY_ID
                                                                  , aDocumentID
                                                                  , tplFootPayment.FOP_EXCHANGE_RATE
                                                                  , tplFootPayment.FOP_BASE_PRICE
                                                                  , tplFootPayment.FOP_RECEIVED_AMOUNT_MD
                                                                  , tplFootPayment.FOP_RECEIVED_AMOUNT_MB
                                                                  , tplFootPayment.FOP_PAID_AMOUNT
                                                                  , tplFootPayment.FOP_PAID_AMOUNT_MD
                                                                  , tplFootPayment.FOP_PAID_AMOUNT_MB
                                                                  , tplFootPayment.FOP_RETURNED_AMOUNT
                                                                  , tplFootPayment.FOP_RETURNED_AMOUNT_MD
                                                                  , tplFootPayment.FOP_RETURNED_AMOUNT_MB
                                                                  , tplFootPayment.FOP_PAID_BALANCED_AMOUNT
                                                                  , tplFootPayment.FOP_PAID_BALANCED_AMOUNT_MD
                                                                  , tplFootPayment.FOP_PAID_BALANCED_AMOUNT_MB
                                                                  , tplFootPayment.FOP_DISCOUNT_AMOUNT
                                                                  , tplFootPayment.FOP_DISCOUNT_AMOUNT_MD
                                                                  , tplFootPayment.FOP_DISCOUNT_AMOUNT_MB
                                                                  , tplFootPayment.FOP_DEDUCTION_AMOUNT
                                                                  , tplFootPayment.FOP_DEDUCTION_AMOUNT_MD
                                                                  , tplFootPayment.FOP_DEDUCTION_AMOUNT_MB
                                                                   );
          end if;

          insert into DOC_FOOT_PAYMENT
                      (DOC_FOOT_PAYMENT_ID
                     , DOC_FOOT_ID
                     , ACJ_JOB_TYPE_S_CATALOGUE_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , FAM_FIXED_ASSETS_ID
                     , HRM_PERSON_ID
                     , C_FAM_TRANSACTION_TYP
                     , FOP_EXCHANGE_RATE
                     , FOP_BASE_PRICE
                     , FOP_PAID_AMOUNT
                     , FOP_PAID_AMOUNT_MD
                     , FOP_PAID_AMOUNT_MB
                     , FOP_RECEIVED_AMOUNT
                     , FOP_RECEIVED_AMOUNT_MD
                     , FOP_RECEIVED_AMOUNT_MB
                     , FOP_RETURNED_AMOUNT
                     , FOP_RETURNED_AMOUNT_MD
                     , FOP_RETURNED_AMOUNT_MB
                     , FOP_PAID_BALANCED_AMOUNT
                     , FOP_PAID_BALANCED_AMOUNT_MD
                     , FOP_PAID_BALANCED_AMOUNT_MB
                     , FOP_DISCOUNT_AMOUNT
                     , FOP_DISCOUNT_AMOUNT_MD
                     , FOP_DISCOUNT_AMOUNT_MB
                     , FOP_DEDUCTION_AMOUNT
                     , FOP_DEDUCTION_AMOUNT_MD
                     , FOP_DEDUCTION_AMOUNT_MB
                     , FOP_TERMINAL
                     , FOP_TERMINAL_SEQ
                     , FOP_TRANSACTION_DATE
                     , FOP_IMF_TEXT_1
                     , FOP_IMF_TEXT_2
                     , FOP_IMF_TEXT_3
                     , FOP_IMF_TEXT_4
                     , FOP_IMF_TEXT_5
                     , FOP_IMF_NUMBER_1
                     , FOP_IMF_NUMBER_2
                     , FOP_IMF_NUMBER_3
                     , FOP_IMF_NUMBER_4
                     , FOP_IMF_NUMBER_5
                     , A_DATECRE
                     , A_IDCRE
                      )
            select init_id_seq.nextval
                 , aDocumentID
                 , tplFootPayment.ACJ_JOB_TYPE_S_CATALOGUE_ID
                 , tplFootPayment.ACS_FINANCIAL_CURRENCY_ID
                 , tplFootPayment.DIC_IMP_FREE1_ID
                 , tplFootPayment.DIC_IMP_FREE2_ID
                 , tplFootPayment.DIC_IMP_FREE3_ID
                 , tplFootPayment.DIC_IMP_FREE4_ID
                 , tplFootPayment.DIC_IMP_FREE5_ID
                 , tplFootPayment.FAM_FIXED_ASSETS_ID
                 , tplFootPayment.HRM_PERSON_ID
                 , tplFootPayment.C_FAM_TRANSACTION_TYP
                 , tplFootPayment.FOP_EXCHANGE_RATE
                 , tplFootPayment.FOP_BASE_PRICE
                 , tplFootPayment.FOP_PAID_AMOUNT
                 , tplFootPayment.FOP_PAID_AMOUNT_MD
                 , tplFootPayment.FOP_PAID_AMOUNT_MB
                 , tplFootPayment.FOP_RECEIVED_AMOUNT
                 , tplFootPayment.FOP_RECEIVED_AMOUNT_MD
                 , tplFootPayment.FOP_RECEIVED_AMOUNT_MB
                 , tplFootPayment.FOP_RETURNED_AMOUNT
                 , tplFootPayment.FOP_RETURNED_AMOUNT_MD
                 , tplFootPayment.FOP_RETURNED_AMOUNT_MB
                 , tplFootPayment.FOP_PAID_BALANCED_AMOUNT
                 , tplFootPayment.FOP_PAID_BALANCED_AMOUNT_MD
                 , tplFootPayment.FOP_PAID_BALANCED_AMOUNT_MB
                 , tplFootPayment.FOP_DISCOUNT_AMOUNT
                 , tplFootPayment.FOP_DISCOUNT_AMOUNT_MD
                 , tplFootPayment.FOP_DISCOUNT_AMOUNT_MB
                 , tplFootPayment.FOP_DEDUCTION_AMOUNT
                 , tplFootPayment.FOP_DEDUCTION_AMOUNT_MD
                 , tplFootPayment.FOP_DEDUCTION_AMOUNT_MB
                 , tplFootPayment.FOP_TERMINAL
                 , tplFootPayment.FOP_TERMINAL_SEQ
                 , tplFootPayment.FOP_TRANSACTION_DATE
                 , tplFootPayment.FOP_IMF_TEXT_1
                 , tplFootPayment.FOP_IMF_TEXT_2
                 , tplFootPayment.FOP_IMF_TEXT_3
                 , tplFootPayment.FOP_IMF_TEXT_4
                 , tplFootPayment.FOP_IMF_TEXT_5
                 , tplFootPayment.FOP_IMF_NUMBER_1
                 , tplFootPayment.FOP_IMF_NUMBER_2
                 , tplFootPayment.FOP_IMF_NUMBER_3
                 , tplFootPayment.FOP_IMF_NUMBER_4
                 , tplFootPayment.FOP_IMF_NUMBER_5
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
              from dual;

          fetch crFootPayment
           into tplFootPayment;
        end loop;
      -- Vente au comptant "Simple"
      elsif(iGAS_CASH_REGISTER = 1) then
        if tplFootPayment.ACJ_JOB_TYPE_S_CATALOGUE_ID is not null then
          tplFootPayment.FOP_PAID_BALANCED_AMOUNT  := 0;
          tplFootPayment.FOP_RETURNED_AMOUNT       := 0;

          if     (tplFootPayment.FOP_PAID_AMOUNT >= 0)
             and (tplFootPayment.FOP_PAID_AMOUNT <= least(nFOO_DOCUMENT_TOTAL_AMOUNT, tplFootPayment.FOP_RECEIVED_AMOUNT) ) then
            tplFootPayment.FOP_RETURNED_AMOUNT       := tplFootPayment.FOP_RECEIVED_AMOUNT - tplFootPayment.FOP_PAID_AMOUNT;
            tplFootPayment.FOP_PAID_BALANCED_AMOUNT  := nFOO_DOCUMENT_TOTAL_AMOUNT - tplFootPayment.FOP_PAID_AMOUNT;
          end if;

          -- Màj du pied selon les données de la vente au comptant définies dans la table DOC_INTERFACE_FOOT_PAYMENT
          update DOC_FOOT
             set FOO_PAID_AMOUNT = nvl(tplFootPayment.FOP_PAID_AMOUNT, 0)
               , FOO_RECEIVED_AMOUNT = nvl(tplFootPayment.FOP_RECEIVED_AMOUNT, 0)
               , FOO_RETURN_AMOUNT = tplFootPayment.FOP_RETURNED_AMOUNT
               , FOO_PAID_BALANCED_AMOUNT = tplFootPayment.FOP_PAID_BALANCED_AMOUNT
               , ACJ_JOB_TYPE_S_CAT_PMT_ID = tplFootPayment.ACJ_JOB_TYPE_S_CATALOGUE_ID
           where DOC_DOCUMENT_ID = aDocumentID;
        end if;
      end if;
    end if;

    close crFootPayment;
  end GenerateFootPayment;

  /**
  * procedure CreateInterfacePosCharge
  * Description
  *    Création des remises/taxes de position selon les données de la table DOC_INTERFACE_POS_CHARGE
  */
  procedure CreateInterfacePosCharge(
    aPositionID    in DOC_POSITION.DOC_POSITION_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  )
  is
    /* Recherche les comptes définis sur la position */
    cursor lcrPosition(cPosID in DOC_POSITION.DOC_POSITION_ID%type)
    is
      select POS.GCO_GOOD_ID
           , POS.DOC_RECORD_ID
           , POS.ACS_FINANCIAL_ACCOUNT_ID
           , POS.ACS_DIVISION_ACCOUNT_ID
           , POS.ACS_CPN_ACCOUNT_ID
           , POS.ACS_PF_ACCOUNT_ID
           , POS.ACS_PJ_ACCOUNT_ID
           , POS.ACS_CDA_ACCOUNT_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.DOC_GAUGE_ID
           , DMT.PAC_THIRD_ACI_ID
           , DMT.DMT_DATE_DOCUMENT
           , GAU.C_ADMIN_DOMAIN
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where POS.DOC_POSITION_ID = cPosID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    ltplPosition lcrPosition%rowtype;
    vPCH_Row     DOC_POSITION_CHARGE%rowtype;
    vAccountInfo ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vElemID      PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    vElemType    varchar2(2);
  begin
    -- Recherche les comptes définis sur la position
    open lcrPosition(aPositionId);

    fetch lcrPosition
     into ltplPosition;

    close lcrPosition;

    -- Infos de la Remise/ Taxe définie dans la table DOC_INTERFACE_POS_CHARGE
    for tplPCH in (select   *
                       from DOC_INTERFACE_POS_CHARGE
                      where DOC_INTERFACE_POSITION_ID = aIntPositionID
                   order by DOC_INTERFACE_POS_CHARGE_ID) loop
      vPCH_Row      := null;
      vAccountInfo  := null;

      -- Recalcul de la remise/taxe = NON
      if tplPCH.DIP_CALCULATE_CHARGE = 0 then
        -- Déterminer si Remise / Taxe
        if tplPCH.C_FINANCIAL_CHARGE = '02' then
          -- Remise
          vElemID    := tplPCH.PTC_DISCOUNT_ID;
          vElemType  := '20';
        elsif tplPCH.C_FINANCIAL_CHARGE = '03' then
          -- Taxe
          vElemID    := tplPCH.PTC_CHARGE_ID;
          vElemType  := '30';
        end if;

        if    (ltplPosition.GAS_FINANCIAL = 1)
           or (ltplPosition.GAS_ANALYTICAL = 1) then
          -- Utiliser les comptes finance/analytiques définis dans la table DOC_INTERFACE_POS_CHARGE si pas nuls
          if    (tplPCH.ACS_DIVISION_ACCOUNT_ID is not null)
             or (tplPCH.ACS_FINANCIAL_ACCOUNT_ID is not null)
             or (tplPCH.ACS_CPN_ACCOUNT_ID is not null)
             or (tplPCH.ACS_CDA_ACCOUNT_ID is not null)
             or (tplPCH.ACS_PF_ACCOUNT_ID is not null)
             or (tplPCH.ACS_PJ_ACCOUNT_ID is not null) then
            vPCH_Row.ACS_DIVISION_ACCOUNT_ID   := tplPCH.ACS_DIVISION_ACCOUNT_ID;
            vPCH_Row.ACS_FINANCIAL_ACCOUNT_ID  := tplPCH.ACS_FINANCIAL_ACCOUNT_ID;
            vPCH_Row.ACS_CPN_ACCOUNT_ID        := tplPCH.ACS_CPN_ACCOUNT_ID;
            vPCH_Row.ACS_CDA_ACCOUNT_ID        := tplPCH.ACS_CDA_ACCOUNT_ID;
            vPCH_Row.ACS_PF_ACCOUNT_ID         := tplPCH.ACS_PF_ACCOUNT_ID;
            vPCH_Row.ACS_PJ_ACCOUNT_ID         := tplPCH.ACS_PJ_ACCOUNT_ID;
          else
            -- Rechercher les comptes finance/analytiques sur la remise/taxe
            --  si ceux-ci n'ont pas été définis dans la table DOC_INTERFACE_POS_CHARGE
            begin
              if tplPCH.PTC_CHARGE_ID is not null then
                select ACS_DIVISION_ACCOUNT_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                  into vPCH_Row.ACS_DIVISION_ACCOUNT_ID
                     , vPCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                     , vPCH_Row.ACS_CPN_ACCOUNT_ID
                     , vPCH_Row.ACS_CDA_ACCOUNT_ID
                     , vPCH_Row.ACS_PF_ACCOUNT_ID
                     , vPCH_Row.ACS_PJ_ACCOUNT_ID
                  from PTC_CHARGE
                 where PTC_CHARGE_ID = tplPCH.PTC_CHARGE_ID;
              elsif tplPCH.PTC_DISCOUNT_ID is not null then
                select ACS_DIVISION_ACCOUNT_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                  into vPCH_Row.ACS_DIVISION_ACCOUNT_ID
                     , vPCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                     , vPCH_Row.ACS_CPN_ACCOUNT_ID
                     , vPCH_Row.ACS_CDA_ACCOUNT_ID
                     , vPCH_Row.ACS_PF_ACCOUNT_ID
                     , vPCH_Row.ACS_PJ_ACCOUNT_ID
                  from PTC_DISCOUNT
                 where PTC_DISCOUNT_ID = tplPCH.PTC_DISCOUNT_ID;
              end if;
            exception
              when no_data_found then
                null;
            end;
          end if;

          -- Information complémentaires
          vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplPCH.HRM_PERSON_ID);
          vAccountInfo.FAM_FIXED_ASSETS_ID    := tplPCH.FAM_FIXED_ASSETS_ID;
          vAccountInfo.C_FAM_TRANSACTION_TYP  := tplPCH.C_FAM_TRANSACTION_TYP;
          vAccountInfo.DEF_DIC_IMP_FREE1      := tplPCH.DIC_IMP_FREE1_ID;
          vAccountInfo.DEF_DIC_IMP_FREE2      := tplPCH.DIC_IMP_FREE2_ID;
          vAccountInfo.DEF_DIC_IMP_FREE3      := tplPCH.DIC_IMP_FREE3_ID;
          vAccountInfo.DEF_DIC_IMP_FREE4      := tplPCH.DIC_IMP_FREE4_ID;
          vAccountInfo.DEF_DIC_IMP_FREE5      := tplPCH.DIC_IMP_FREE5_ID;
          vAccountInfo.DEF_TEXT1              := tplPCH.PCH_IMP_TEXT_1;
          vAccountInfo.DEF_TEXT2              := tplPCH.PCH_IMP_TEXT_2;
          vAccountInfo.DEF_TEXT3              := tplPCH.PCH_IMP_TEXT_3;
          vAccountInfo.DEF_TEXT4              := tplPCH.PCH_IMP_TEXT_4;
          vAccountInfo.DEF_TEXT5              := tplPCH.PCH_IMP_TEXT_5;
          vAccountInfo.DEF_NUMBER1            := to_char(tplPCH.PCH_IMP_NUMBER_1);
          vAccountInfo.DEF_NUMBER2            := to_char(tplPCH.PCH_IMP_NUMBER_2);
          vAccountInfo.DEF_NUMBER3            := to_char(tplPCH.PCH_IMP_NUMBER_3);
          vAccountInfo.DEF_NUMBER4            := to_char(tplPCH.PCH_IMP_NUMBER_4);
          vAccountInfo.DEF_NUMBER5            := to_char(tplPCH.PCH_IMP_NUMBER_5);
          --
          -- Initialisation des comptes en fonction type d'élement et avec contrôle des imputations
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(iElementID         => vElemID
                                                 , iElementType       => vElemType
                                                 , iAdminDomain       => ltplPosition.C_ADMIN_DOMAIN
                                                 , iDateRef           => ltplPosition.DMT_DATE_DOCUMENT
                                                 , iGoodID            => ltplPosition.GCO_GOOD_ID
                                                 , iGaugeID           => ltplPosition.DOC_GAUGE_ID
                                                 , iDocumentID        => ltplPosition.DOC_DOCUMENT_ID
                                                 , iPositionID        => aPositionId
                                                 , iRecordID          => ltplPosition.DOC_RECORD_ID
                                                 , iThirdID           => ltplPosition.PAC_THIRD_ACI_ID
                                                 , iInFinancialID     => ltplPosition.ACS_FINANCIAL_ACCOUNT_ID
                                                 , iInDivisionID      => ltplPosition.ACS_DIVISION_ACCOUNT_ID
                                                 , iInCPNAccountID    => ltplPosition.ACS_CPN_ACCOUNT_ID
                                                 , iInCDAAccountID    => ltplPosition.ACS_CDA_ACCOUNT_ID
                                                 , iInPFAccountID     => ltplPosition.ACS_PF_ACCOUNT_ID
                                                 , iInPJAccountID     => ltplPosition.ACS_PJ_ACCOUNT_ID
                                                 , ioFinancialID      => vPCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                                                 , ioDivisionID       => vPCH_Row.ACS_DIVISION_ACCOUNT_ID
                                                 , iOutCPNAccountID   => vPCH_Row.ACS_CPN_ACCOUNT_ID
                                                 , iOutCDAAccountID   => vPCH_Row.ACS_CDA_ACCOUNT_ID
                                                 , iOutPFAccountID    => vPCH_Row.ACS_PF_ACCOUNT_ID
                                                 , iOutPJAccountID    => vPCH_Row.ACS_PJ_ACCOUNT_ID
                                                 , iotAccountInfo     => vAccountInfo
                                                  );

          -- Effacer les valeurs des comptes analytiques si pas gérés
          if (ltplPosition.GAS_ANALYTICAL = 0) then
            vPCH_Row.ACS_CPN_ACCOUNT_ID  := null;
            vPCH_Row.ACS_CDA_ACCOUNT_ID  := null;
            vPCH_Row.ACS_PF_ACCOUNT_ID   := null;
            vPCH_Row.ACS_PJ_ACCOUNT_ID   := null;
          end if;
        end if;

        -- Init des données du record de l'insertion
        select INIT_ID_SEQ.nextval
          into vPCH_Row.DOC_POSITION_CHARGE_ID
          from dual;

        vPCH_Row.DOC_POSITION_ID             := aPositionID;
        --
        vPCH_Row.HRM_PERSON_ID               := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
        vPCH_Row.FAM_FIXED_ASSETS_ID         := vAccountInfo.FAM_FIXED_ASSETS_ID;
        vPCH_Row.C_FAM_TRANSACTION_TYP       := vAccountInfo.C_FAM_TRANSACTION_TYP;
        vPCH_Row.PCH_IMP_TEXT_1              := vAccountInfo.DEF_TEXT1;
        vPCH_Row.PCH_IMP_TEXT_2              := vAccountInfo.DEF_TEXT2;
        vPCH_Row.PCH_IMP_TEXT_3              := vAccountInfo.DEF_TEXT3;
        vPCH_Row.PCH_IMP_TEXT_4              := vAccountInfo.DEF_TEXT4;
        vPCH_Row.PCH_IMP_TEXT_5              := vAccountInfo.DEF_TEXT5;
        vPCH_Row.PCH_IMP_NUMBER_1            := vAccountInfo.DEF_NUMBER1;
        vPCH_Row.PCH_IMP_NUMBER_2            := vAccountInfo.DEF_NUMBER2;
        vPCH_Row.PCH_IMP_NUMBER_3            := vAccountInfo.DEF_NUMBER3;
        vPCH_Row.PCH_IMP_NUMBER_4            := vAccountInfo.DEF_NUMBER4;
        vPCH_Row.PCH_IMP_NUMBER_5            := vAccountInfo.DEF_NUMBER5;
        vPCH_Row.DIC_IMP_FREE1_ID            := vAccountInfo.DEF_DIC_IMP_FREE1;
        vPCH_Row.DIC_IMP_FREE2_ID            := vAccountInfo.DEF_DIC_IMP_FREE2;
        vPCH_Row.DIC_IMP_FREE3_ID            := vAccountInfo.DEF_DIC_IMP_FREE3;
        vPCH_Row.DIC_IMP_FREE4_ID            := vAccountInfo.DEF_DIC_IMP_FREE4;
        vPCH_Row.DIC_IMP_FREE5_ID            := vAccountInfo.DEF_DIC_IMP_FREE5;
        --
        vPCH_Row.PTC_CHARGE_ID               := tplPCH.PTC_CHARGE_ID;
        vPCH_Row.PTC_DISCOUNT_ID             := tplPCH.PTC_DISCOUNT_ID;
        vPCH_Row.C_FINANCIAL_CHARGE          := tplPCH.C_FINANCIAL_CHARGE;
        vPCH_Row.PCH_DESCRIPTION             := tplPCH.PCH_DESCRIPTION;
        vPCH_Row.PCH_AMOUNT                  := tplPCH.PCH_AMOUNT;
        vPCH_Row.PCH_RATE                    := tplPCH.PCH_RATE;
        vPCH_Row.PCH_EXPRESS_IN              := tplPCH.PCH_EXPRESS_IN;
        vPCH_Row.A_DATECRE                   := sysdate;
        vPCH_Row.A_IDCRE                     := PCS.PC_I_LIB_SESSION.GetUserIni;
        vPCH_Row.A_DATEMOD                   := null;
        vPCH_Row.A_IDMOD                     := null;
        vPCH_Row.A_RECLEVEL                  := tplPCH.A_RECLEVEL;
        vPCH_Row.A_RECSTATUS                 := tplPCH.A_RECSTATUS;
        vPCH_Row.A_CONFIRM                   := tplPCH.A_CONFIRM;
        vPCH_Row.DOC_DOC_POSITION_CHARGE_ID  := tplPCH.DOC_DOC_POSITION_CHARGE_ID;
        vPCH_Row.C_CALCULATION_MODE          := tplPCH.C_CALCULATION_MODE;
        vPCH_Row.C_ROUND_TYPE                := tplPCH.C_ROUND_TYPE;
        vPCH_Row.PCH_AMOUNT_B                := tplPCH.PCH_AMOUNT_B;
        vPCH_Row.PCH_AMOUNT_E                := tplPCH.PCH_AMOUNT_E;
        vPCH_Row.PCH_TRANSFERT_PROP          := tplPCH.PCH_TRANSFERT_PROP;
        vPCH_Row.PCH_MODIFY                  := tplPCH.PCH_MODIFY;
        vPCH_Row.PCH_IN_SERIES_CALCULATION   := tplPCH.PCH_IN_SERIES_CALCULATION;
        vPCH_Row.PCH_BALANCE_AMOUNT          := tplPCH.PCH_BALANCE_AMOUNT;
        vPCH_Row.PCH_NAME                    := tplPCH.PCH_NAME;
        vPCH_Row.PCH_CALC_AMOUNT             := tplPCH.PCH_CALC_AMOUNT;
        vPCH_Row.PCH_CALC_AMOUNT_B           := tplPCH.PCH_CALC_AMOUNT_B;
        vPCH_Row.PCH_CALC_AMOUNT_E           := tplPCH.PCH_CALC_AMOUNT_E;
        vPCH_Row.PCH_LIABLED_AMOUNT          := tplPCH.PCH_LIABLED_AMOUNT;
        vPCH_Row.PCH_LIABLED_AMOUNT_B        := tplPCH.PCH_LIABLED_AMOUNT_B;
        vPCH_Row.PCH_LIABLED_AMOUNT_E        := tplPCH.PCH_LIABLED_AMOUNT_E;
        vPCH_Row.PCH_FIXED_AMOUNT            := tplPCH.PCH_FIXED_AMOUNT;
        vPCH_Row.PCH_FIXED_AMOUNT_B          := tplPCH.PCH_FIXED_AMOUNT_B;
        vPCH_Row.PCH_FIXED_AMOUNT_E          := tplPCH.PCH_FIXED_AMOUNT_E;
        vPCH_Row.PCH_EXCEEDED_AMOUNT_FROM    := tplPCH.PCH_EXCEEDED_AMOUNT_FROM;
        vPCH_Row.PCH_EXCEEDED_AMOUNT_TO      := tplPCH.PCH_EXCEEDED_AMOUNT_TO;
        vPCH_Row.PCH_MIN_AMOUNT              := tplPCH.PCH_MIN_AMOUNT;
        vPCH_Row.PCH_MAX_AMOUNT              := tplPCH.PCH_MAX_AMOUNT;
        vPCH_Row.PCH_IS_MULTIPLICATOR        := tplPCH.PCH_IS_MULTIPLICATOR;
        vPCH_Row.PCH_ROUND_AMOUNT            := tplPCH.PCH_ROUND_AMOUNT;
        vPCH_Row.PCH_STORED_PROC             := tplPCH.PCH_STORED_PROC;
        vPCH_Row.PCH_AUTOMATIC_CALC          := tplPCH.PCH_AUTOMATIC_CALC;
        vPCH_Row.PCH_SQL_EXTERN_ITEM         := tplPCH.PCH_SQL_EXTERN_ITEM;
        vPCH_Row.PCH_QUANTITY_FROM           := tplPCH.PCH_QUANTITY_FROM;
        vPCH_Row.PCH_QUANTITY_TO             := tplPCH.PCH_QUANTITY_TO;
        vPCH_Row.PCH_UNIT_DETAIL             := tplPCH.PCH_UNIT_DETAIL;
        vPCH_Row.DOC_DOCUMENT_ID             := tplPCH.DOC_DOCUMENT_ID;
        vPCH_Row.PAC_THIRD_ID                := tplPCH.PAC_THIRD_ID;
        vPCH_Row.PCH_MODIFY_RATE             := tplPCH.PCH_MODIFY_RATE;
        vPCH_Row.PCH_AMOUNT_V                := tplPCH.PCH_AMOUNT_V;
        vPCH_Row.PCH_EXCLUSIVE               := tplPCH.PCH_EXCLUSIVE;
        vPCH_Row.PCH_DISCHARGED              := tplPCH.PCH_DISCHARGED;
        vPCH_Row.PCH_CUMULATIVE              := tplPCH.PCH_CUMULATIVE;
        vPCH_Row.C_CHARGE_ORIGIN             := tplPCH.C_CHARGE_ORIGIN;
        vPCH_Row.DOC_DETAIL_COST_ID          := tplPCH.DOC_DETAIL_COST_ID;
        vPCH_Row.PAC_THIRD_ACI_ID            := tplPCH.PAC_THIRD_ACI_ID;
        vPCH_Row.PAC_THIRD_DELIVERY_ID       := tplPCH.PAC_THIRD_DELIVERY_ID;
        vPCH_Row.PAC_THIRD_TARIFF_ID         := tplPCH.PAC_THIRD_TARIFF_ID;
        vPCH_Row.PCH_IMPUTATION              := tplPCH.PCH_IMPUTATION;
        vPCH_Row.PCH_PRCS_USE                := tplPCH.PCH_PRCS_USE;
      else
        -- Recalcul de la remise/taxe = OUI
        null;
      end if;

      -- Insertion de la remise/taxe
      DOC_DISCOUNT_CHARGE.InsertPositionCharge(vPCH_Row);
      -- Recalculer les montants de la position
      DOC_POSITION_FUNCTIONS.UpdateAmountsDiscountCharge(aPositionID);
    end loop;
  end CreateInterfacePosCharge;

  /**
  * procedure CreateInterfaceFootCharge
  * Description
  *    Création des remises/taxes de pied de document selon les données de la table DOC_INTERFACE_FOOT_CHARGE
  */
  procedure CreateInterfaceFootCharge(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    cursor crFootCharge(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   *
          from DOC_INTERFACE_FOOT_CHARGE
         where DOC_INTERFACE_ID = cInterfaceID
      order by DOC_INTERFACE_FOOT_CHARGE_ID;

    tplFCH       crFootCharge%rowtype;

    /* Recherche les comptes définis sur le document */
    cursor lcrDocument(cDocID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select DMT.DOC_GAUGE_ID
           , DMT.DOC_DOCUMENT_ID
           , DMT.DOC_RECORD_ID
           , DMT.PAC_THIRD_ACI_ID
           , DMT.DMT_DATE_DOCUMENT
           , GAU.C_ADMIN_DOMAIN
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where DMT.DOC_DOCUMENT_ID = cDocID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    ltplDocument lcrDocument%rowtype;
    vAccountInfo ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    VElemID      PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    vElemType    varchar2(2);
    vFCH_Row     DOC_FOOT_CHARGE%rowtype;
  begin
    -- Recherche les comptes définis sur le document
    open lcrDocument(aDocumentID);

    fetch lcrDocument
     into ltplDocument;

    close lcrDocument;

    -- Infos de la Remise/ Taxe / Frais défini dans la table DOC_INTERFACE_FOOT_CHARGE
    for tplFCH in (select   *
                       from DOC_INTERFACE_FOOT_CHARGE
                      where DOC_INTERFACE_ID = aInterfaceID
                   order by DOC_INTERFACE_FOOT_CHARGE_ID) loop
      vFCH_Row      := null;
      vAccountInfo  := null;

      -- Recalcul de la remise/taxe = NON
      if tplFCH.DIF_CALCULATE_CHARGE = 0 then
        -- Déterminer si Remise / Taxe / Frais
        if tplFCH.C_FINANCIAL_CHARGE = '01' then
          -- Frais
          vElemID    := null;
          vElemType  := '50';
        elsif tplFCH.C_FINANCIAL_CHARGE = '02' then
          -- Remise
          vElemID    := tplFCH.PTC_DISCOUNT_ID;
          vElemType  := '20';
        elsif tplFCH.C_FINANCIAL_CHARGE = '03' then
          -- Taxe
          vElemID    := tplFCH.PTC_CHARGE_ID;
          vElemType  := '30';
        end if;

        if    (ltplDocument.GAS_FINANCIAL = 1)
           or (ltplDocument.GAS_ANALYTICAL = 1) then
          -- Utiliser les comptes finance/analytiques définis dans la table DOC_INTERFACE_FOOT_CHARGE si pas nuls
          if    (tplFCH.ACS_DIVISION_ACCOUNT_ID is not null)
             or (tplFCH.ACS_FINANCIAL_ACCOUNT_ID is not null)
             or (tplFCH.ACS_CPN_ACCOUNT_ID is not null)
             or (tplFCH.ACS_CDA_ACCOUNT_ID is not null)
             or (tplFCH.ACS_PF_ACCOUNT_ID is not null)
             or (tplFCH.ACS_PJ_ACCOUNT_ID is not null) then
            vFCH_Row.ACS_DIVISION_ACCOUNT_ID   := tplFCH.ACS_DIVISION_ACCOUNT_ID;
            vFCH_Row.ACS_FINANCIAL_ACCOUNT_ID  := tplFCH.ACS_FINANCIAL_ACCOUNT_ID;
            vFCH_Row.ACS_CPN_ACCOUNT_ID        := tplFCH.ACS_CPN_ACCOUNT_ID;
            vFCH_Row.ACS_CDA_ACCOUNT_ID        := tplFCH.ACS_CDA_ACCOUNT_ID;
            vFCH_Row.ACS_PF_ACCOUNT_ID         := tplFCH.ACS_PF_ACCOUNT_ID;
            vFCH_Row.ACS_PJ_ACCOUNT_ID         := tplFCH.ACS_PJ_ACCOUNT_ID;
          else
            -- Rechercher les comptes finance/analytiques sur la remise/taxe
            --  si ceux-ci n'ont pas été définis dans la table DOC_INTERFACE_FOOT_CHARGE
            begin
              if tplFCH.PTC_CHARGE_ID is not null then
                select ACS_DIVISION_ACCOUNT_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                  into vFCH_Row.ACS_DIVISION_ACCOUNT_ID
                     , vFCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                     , vFCH_Row.ACS_CPN_ACCOUNT_ID
                     , vFCH_Row.ACS_CDA_ACCOUNT_ID
                     , vFCH_Row.ACS_PF_ACCOUNT_ID
                     , vFCH_Row.ACS_PJ_ACCOUNT_ID
                  from PTC_CHARGE
                 where PTC_CHARGE_ID = tplFCH.PTC_CHARGE_ID;
              elsif tplFCH.PTC_DISCOUNT_ID is not null then
                select ACS_DIVISION_ACCOUNT_ID
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_PJ_ACCOUNT_ID
                  into vFCH_Row.ACS_DIVISION_ACCOUNT_ID
                     , vFCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                     , vFCH_Row.ACS_CPN_ACCOUNT_ID
                     , vFCH_Row.ACS_CDA_ACCOUNT_ID
                     , vFCH_Row.ACS_PF_ACCOUNT_ID
                     , vFCH_Row.ACS_PJ_ACCOUNT_ID
                  from PTC_DISCOUNT
                 where PTC_DISCOUNT_ID = tplFCH.PTC_DISCOUNT_ID;
              end if;
            exception
              when no_data_found then
                null;
            end;
          end if;

          -- Information complémentaires
          vAccountInfo.DEF_HRM_PERSON         := ACS_I_LIB_LOGISTIC_FINANCIAL.GetEmpNumber(tplFCH.HRM_PERSON_ID);
          vAccountInfo.FAM_FIXED_ASSETS_ID    := tplFCH.FAM_FIXED_ASSETS_ID;
          vAccountInfo.C_FAM_TRANSACTION_TYP  := tplFCH.C_FAM_TRANSACTION_TYP;
          vAccountInfo.DEF_DIC_IMP_FREE1      := tplFCH.DIC_IMP_FREE1_ID;
          vAccountInfo.DEF_DIC_IMP_FREE2      := tplFCH.DIC_IMP_FREE2_ID;
          vAccountInfo.DEF_DIC_IMP_FREE3      := tplFCH.DIC_IMP_FREE3_ID;
          vAccountInfo.DEF_DIC_IMP_FREE4      := tplFCH.DIC_IMP_FREE4_ID;
          vAccountInfo.DEF_DIC_IMP_FREE5      := tplFCH.DIC_IMP_FREE5_ID;
          vAccountInfo.DEF_TEXT1              := tplFCH.FCH_IMP_TEXT_1;
          vAccountInfo.DEF_TEXT2              := tplFCH.FCH_IMP_TEXT_2;
          vAccountInfo.DEF_TEXT3              := tplFCH.FCH_IMP_TEXT_3;
          vAccountInfo.DEF_TEXT4              := tplFCH.FCH_IMP_TEXT_4;
          vAccountInfo.DEF_TEXT5              := tplFCH.FCH_IMP_TEXT_5;
          vAccountInfo.DEF_NUMBER1            := to_char(tplFCH.FCH_IMP_NUMBER_1);
          vAccountInfo.DEF_NUMBER2            := to_char(tplFCH.FCH_IMP_NUMBER_2);
          vAccountInfo.DEF_NUMBER3            := to_char(tplFCH.FCH_IMP_NUMBER_3);
          vAccountInfo.DEF_NUMBER4            := to_char(tplFCH.FCH_IMP_NUMBER_4);
          vAccountInfo.DEF_NUMBER5            := to_char(tplFCH.FCH_IMP_NUMBER_5);
          --
          -- Initialisation des comptes en fonction type d'élement et avec contrôle des imputations
          ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(iCurId           => vElemID
                                                   , iElementType     => vElemType
                                                   , iAdminDomain     => ltplDocument.C_ADMIN_DOMAIN
                                                   , iDateRef         => ltplDocument.DMT_DATE_DOCUMENT
                                                   , iGaugeId         => ltplDocument.DOC_GAUGE_ID
                                                   , iDocumentId      => ltplDocument.DOC_DOCUMENT_ID
                                                   , iPositionId      => null
                                                   , iRecordId        => ltplDocument.DOC_RECORD_ID
                                                   , iThirdId         => ltplDocument.PAC_THIRD_ACI_ID
                                                   , iInFinancialId   => null
                                                   , iInDivisionId    => null
                                                   , iInCpnId         => null
                                                   , iInCdaId         => null
                                                   , iInPfId          => null
                                                   , iInPjId          => null
                                                   , ioFinancialId    => vFCH_Row.ACS_FINANCIAL_ACCOUNT_ID
                                                   , ioDivisionId     => vFCH_Row.ACS_DIVISION_ACCOUNT_ID
                                                   , ioCpnId          => vFCH_Row.ACS_CPN_ACCOUNT_ID
                                                   , ioCdaId          => vFCH_Row.ACS_CDA_ACCOUNT_ID
                                                   , ioPfId           => vFCH_Row.ACS_PF_ACCOUNT_ID
                                                   , ioPjId           => vFCH_Row.ACS_PJ_ACCOUNT_ID
                                                   , iotAccountInfo   => vAccountInfo
                                                    );

          -- Effacer les valeurs des comptes analytiques si pas gérés
          if (ltplDocument.GAS_ANALYTICAL = 0) then
            vFCH_Row.ACS_CPN_ACCOUNT_ID  := null;
            vFCH_Row.ACS_CDA_ACCOUNT_ID  := null;
            vFCH_Row.ACS_PF_ACCOUNT_ID   := null;
            vFCH_Row.ACS_PJ_ACCOUNT_ID   := null;
          end if;
        end if;

        -- Init des données du record de l'insertion
        select INIT_ID_SEQ.nextval
          into vFCH_Row.DOC_FOOT_CHARGE_ID
          from dual;

        vFCH_Row.DOC_FOOT_ID                := aDocumentID;
        --
        vFCH_Row.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
        vFCH_Row.FAM_FIXED_ASSETS_ID        := vAccountInfo.FAM_FIXED_ASSETS_ID;
        vFCH_Row.C_FAM_TRANSACTION_TYP      := vAccountInfo.C_FAM_TRANSACTION_TYP;
        vFCH_Row.FCH_IMP_TEXT_1             := vAccountInfo.DEF_TEXT1;
        vFCH_Row.FCH_IMP_TEXT_2             := vAccountInfo.DEF_TEXT2;
        vFCH_Row.FCH_IMP_TEXT_3             := vAccountInfo.DEF_TEXT3;
        vFCH_Row.FCH_IMP_TEXT_4             := vAccountInfo.DEF_TEXT4;
        vFCH_Row.FCH_IMP_TEXT_5             := vAccountInfo.DEF_TEXT5;
        vFCH_Row.FCH_IMP_NUMBER_1           := vAccountInfo.DEF_NUMBER1;
        vFCH_Row.FCH_IMP_NUMBER_2           := vAccountInfo.DEF_NUMBER2;
        vFCH_Row.FCH_IMP_NUMBER_3           := vAccountInfo.DEF_NUMBER3;
        vFCH_Row.FCH_IMP_NUMBER_4           := vAccountInfo.DEF_NUMBER4;
        vFCH_Row.FCH_IMP_NUMBER_5           := vAccountInfo.DEF_NUMBER5;
        vFCH_Row.DIC_IMP_FREE1_ID           := vAccountInfo.DEF_DIC_IMP_FREE1;
        vFCH_Row.DIC_IMP_FREE2_ID           := vAccountInfo.DEF_DIC_IMP_FREE2;
        vFCH_Row.DIC_IMP_FREE3_ID           := vAccountInfo.DEF_DIC_IMP_FREE3;
        vFCH_Row.DIC_IMP_FREE4_ID           := vAccountInfo.DEF_DIC_IMP_FREE4;
        vFCH_Row.DIC_IMP_FREE5_ID           := vAccountInfo.DEF_DIC_IMP_FREE5;
        --
        vFCH_Row.ACS_TAX_CODE_ID            := tplFCH.ACS_TAX_CODE_ID;
        vFCH_Row.PTC_CHARGE_ID              := tplFCH.PTC_CHARGE_ID;
        vFCH_Row.PTC_DISCOUNT_ID            := tplFCH.PTC_DISCOUNT_ID;
        vFCH_Row.DOC_DOC_FOOT_CHARGE_ID     := tplFCH.DOC_DOC_FOOT_CHARGE_ID;
        vFCH_Row.C_FINANCIAL_CHARGE         := tplFCH.C_FINANCIAL_CHARGE;
        vFCH_Row.C_ROUND_TYPE               := tplFCH.C_ROUND_TYPE;
        vFCH_Row.C_CALCULATION_MODE         := tplFCH.C_CALCULATION_MODE;
        vFCH_Row.FCH_DESCRIPTION            := tplFCH.FCH_DESCRIPTION;
        vFCH_Row.FCH_EXCL_AMOUNT            := tplFCH.FCH_EXCL_AMOUNT;
        vFCH_Row.FCH_VAT_AMOUNT             := tplFCH.FCH_VAT_AMOUNT;
        vFCH_Row.FCH_VAT_BASE_AMOUNT        := tplFCH.FCH_VAT_BASE_AMOUNT;
        vFCH_Row.FCH_INCL_AMOUNT            := tplFCH.FCH_INCL_AMOUNT;
        vFCH_Row.FCH_RATE                   := tplFCH.FCH_RATE;
        vFCH_Row.FCH_EXPRESS_IN             := tplFCH.FCH_EXPRESS_IN;
        vFCH_Row.FCH_EXCL_AMOUNT_B          := tplFCH.FCH_EXCL_AMOUNT_B;
        vFCH_Row.FCH_EXCL_AMOUNT_E          := tplFCH.FCH_EXCL_AMOUNT_E;
        vFCH_Row.FCH_VAT_AMOUNT_E           := tplFCH.FCH_VAT_AMOUNT_E;
        vFCH_Row.FCH_INCL_AMOUNT_B          := tplFCH.FCH_INCL_AMOUNT_B;
        vFCH_Row.FCH_INCL_AMOUNT_E          := tplFCH.FCH_INCL_AMOUNT_E;
        vFCH_Row.FCH_TRANSFERT_PROP         := tplFCH.FCH_TRANSFERT_PROP;
        vFCH_Row.FCH_MODIFY                 := tplFCH.FCH_MODIFY;
        vFCH_Row.FCH_IN_SERIES_CALCULATION  := tplFCH.FCH_IN_SERIES_CALCULATION;
        vFCH_Row.FCH_BALANCE_AMOUNT         := tplFCH.FCH_BALANCE_AMOUNT;
        vFCH_Row.FCH_NAME                   := tplFCH.FCH_NAME;
        vFCH_Row.FCH_CALC_AMOUNT            := tplFCH.FCH_CALC_AMOUNT;
        vFCH_Row.FCH_CALC_AMOUNT_B          := tplFCH.FCH_CALC_AMOUNT_B;
        vFCH_Row.FCH_CALC_AMOUNT_E          := tplFCH.FCH_CALC_AMOUNT_E;
        vFCH_Row.FCH_LIABLED_AMOUNT         := tplFCH.FCH_LIABLED_AMOUNT;
        vFCH_Row.FCH_LIABLED_AMOUNT_B       := tplFCH.FCH_LIABLED_AMOUNT_B;
        vFCH_Row.FCH_LIABLED_AMOUNT_E       := tplFCH.FCH_LIABLED_AMOUNT_E;
        vFCH_Row.FCH_FIXED_AMOUNT           := tplFCH.FCH_FIXED_AMOUNT;
        vFCH_Row.FCH_FIXED_AMOUNT_B         := tplFCH.FCH_FIXED_AMOUNT_B;
        vFCH_Row.FCH_FIXED_AMOUNT_E         := tplFCH.FCH_FIXED_AMOUNT_E;
        vFCH_Row.FCH_EXCEEDED_AMOUNT_FROM   := tplFCH.FCH_EXCEEDED_AMOUNT_FROM;
        vFCH_Row.FCH_EXCEEDED_AMOUNT_TO     := tplFCH.FCH_EXCEEDED_AMOUNT_TO;
        vFCH_Row.FCH_MIN_AMOUNT             := tplFCH.FCH_MIN_AMOUNT;
        vFCH_Row.FCH_MAX_AMOUNT             := tplFCH.FCH_MAX_AMOUNT;
        vFCH_Row.FCH_IS_MULTIPLICATOR       := tplFCH.FCH_IS_MULTIPLICATOR;
        vFCH_Row.FCH_ROUND_AMOUNT           := tplFCH.FCH_ROUND_AMOUNT;
        vFCH_Row.FCH_STORED_PROC            := tplFCH.FCH_STORED_PROC;
        vFCH_Row.FCH_AUTOMATIC_CALC         := tplFCH.FCH_AUTOMATIC_CALC;
        vFCH_Row.FCH_SQL_EXTERN_ITEM        := tplFCH.FCH_SQL_EXTERN_ITEM;
        vFCH_Row.A_DATECRE                  := sysdate;
        vFCH_Row.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;
        vFCH_Row.A_DATEMOD                  := null;
        vFCH_Row.A_IDMOD                    := null;
        vFCH_Row.A_RECLEVEL                 := tplFCH.A_RECLEVEL;
        vFCH_Row.A_RECSTATUS                := tplFCH.A_RECSTATUS;
        vFCH_Row.A_CONFIRM                  := tplFCH.A_CONFIRM;
        vFCH_Row.PAC_THIRD_ID               := tplFCH.PAC_THIRD_ID;
        vFCH_Row.FCH_MODIFY_RATE            := tplFCH.FCH_MODIFY_RATE;
        vFCH_Row.FCH_EXCL_AMOUNT_V          := tplFCH.FCH_EXCL_AMOUNT_V;
        vFCH_Row.FCH_VAT_AMOUNT_V           := tplFCH.FCH_VAT_AMOUNT_V;
        vFCH_Row.FCH_INCL_AMOUNT_V          := tplFCH.FCH_INCL_AMOUNT_V;
        vFCH_Row.FCH_LIABLED_AMOUNT_V       := tplFCH.FCH_LIABLED_AMOUNT_V;
        vFCH_Row.FCH_EXCLUSIVE              := tplFCH.FCH_EXCLUSIVE;
        vFCH_Row.C_CHARGE_ORIGIN            := tplFCH.C_CHARGE_ORIGIN;
        vFCH_Row.DOC_FOOT_CHARGE_SRC_ID     := tplFCH.DOC_FOOT_CHARGE_SRC_ID;
        vFCH_Row.FCH_DISCHARGED             := tplFCH.FCH_DISCHARGED;
        vFCH_Row.FCH_VAT_LIABLED_RATE       := tplFCH.FCH_VAT_LIABLED_RATE;
        vFCH_Row.FCH_VAT_LIABLED_AMOUNT     := tplFCH.FCH_VAT_LIABLED_AMOUNT;
        vFCH_Row.FCH_VAT_RATE               := tplFCH.FCH_VAT_RATE;
        vFCH_Row.FCH_VAT_TOTAL_AMOUNT       := tplFCH.FCH_VAT_TOTAL_AMOUNT;
        vFCH_Row.FCH_VAT_TOTAL_AMOUNT_B     := tplFCH.FCH_VAT_TOTAL_AMOUNT_B;
        vFCH_Row.FCH_VAT_TOTAL_AMOUNT_V     := tplFCH.FCH_VAT_TOTAL_AMOUNT_V;
        vFCH_Row.FCH_VAT_DEDUCTIBLE_RATE    := tplFCH.FCH_VAT_DEDUCTIBLE_RATE;
        vFCH_Row.DOC_POSITION_COST_ID       := tplFCH.DOC_POSITION_COST_ID;
        vFCH_Row.PAC_THIRD_ACI_ID           := tplFCH.PAC_THIRD_ACI_ID;
        vFCH_Row.PAC_THIRD_DELIVERY_ID      := tplFCH.PAC_THIRD_DELIVERY_ID;
        vFCH_Row.PAC_THIRD_TARIFF_ID        := tplFCH.PAC_THIRD_TARIFF_ID;
        vFCH_Row.FCH_IMPUTATION             := tplFCH.FCH_IMPUTATION;
        vFCH_Row.FCH_FROZEN                 := tplFCH.FCH_FROZEN;
        vFCH_Row.DOC_INVOICE_EXPIRY_ID      := tplFCH.DOC_INVOICE_EXPIRY_ID;
      else
        -- Recalcul de la remise/taxe = OUI
        null;
      end if;

      -- Insertion de la remise/taxe
      DOC_DISCOUNT_CHARGE.InsertFootCharge(vFCH_Row);
    end loop;
  end CreateInterfaceFootCharge;
end DOC_DOCUMENT_GENERATOR;
