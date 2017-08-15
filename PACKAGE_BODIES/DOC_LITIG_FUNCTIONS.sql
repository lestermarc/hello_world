--------------------------------------------------------
--  DDL for Package Body DOC_LITIG_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LITIG_FUNCTIONS" 
is
  /**
  * procedure GenerateInitialDocs
  * Description
  *   Méthode globale regroupant la création des documents de départ.
  */
  procedure GenerateInitialDocs(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vDOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Créer les documents de retour avec appro
    vDOC_ID  := GenReceptSupplyDoc(aJobID => aJobID, aDocumentID => aDocumentID);
    -- Créer les documents de retour sans appro
    vDOC_ID  := GenReceptDoc(aJobID => aJobID, aDocumentID => aDocumentID);
    -- Créer les documents de transfert en stock déchets avec appro
    vDOC_ID  := GenTrashSupplyDoc(aJobID => aJobID, aDocumentID => aDocumentID);
    -- Créer les documents de transfert en stock déchets
    vDOC_ID  := GenTrashDoc(aJobID => aJobID, aDocumentID => aDocumentID);
    -- Créer le document initial cible par copie ou décharge
    vDOC_ID  := GenerateInitialTgtDoc(aJobID => aJobID, aDocumentID => aDocumentID);
  end GenerateInitialDocs;

  /**
  * function GenerateInitialTgtDoc
  * Description
  *   Création par copie/décharge du document initial cible
  */
  function GenerateInitialTgtDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vSRC_DOC_ID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNEW_DOC_ID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vDOC_GAUGE_ID      DOC_GAUGE.DOC_GAUGE_ID%type;
    vGAUGE_LINK        DOC_LITIG_CONTEXT.C_DLX_START_GAUGE_LINK%type;
    vC_DOC_CREATE_MODE DOC_DOCUMENT.C_DOC_CREATE_MODE%type;
  begin
    -- Récuperer les données du document source
    begin
      select distinct DMT.DOC_DOCUMENT_ID
                    , DLX.DLX_GAU_START_TGT_ID
                    , DLX.C_DLX_START_GAUGE_LINK
                    , case
                        when nvl(DLX.C_DLX_START_GAUGE_LINK, '1') = '1' then '318'
                        else '218'
                      end C_DOC_CREATE_MODE
                 into vSRC_DOC_ID
                    , vDOC_GAUGE_ID
                    , vGAUGE_LINK
                    , vC_DOC_CREATE_MODE
                 from DOC_LITIG_JOB DLJ
                    , DOC_LITIG_PROCESS DLP
                    , DOC_DOCUMENT DMT
                    , DOC_LITIG_CONTEXT DLX
                where DLJ.DOC_LITIG_JOB_ID = aJobID
                  and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                  and DLP.DOC_DOCUMENT_ID = aDocumentID
                  and DLP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                  and DLP.DLP_DOC_INIT_TGT_ID is null;
    exception
      when no_data_found then
        vSRC_DOC_ID  := null;
    end;

    if vSRC_DOC_ID is not null then
      -- Création du document par copie ou décharge, selon code du contexte
      vNEW_DOC_ID  := null;
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID
                                           , aMode            => vC_DOC_CREATE_MODE
                                           , aGaugeID         => vDOC_GAUGE_ID
                                           , aSrcDocumentID   => vSRC_DOC_ID
                                            );

      -- Décharge des positions
      if vGAUGE_LINK = '1' then
        InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => vSRC_DOC_ID);
        -- Assignation du dernier numéro de position d'après le document en cours
        DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
        -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
        DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);
      else
        -- Copie des positions
        InsertCopyDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => vSRC_DOC_ID);
        -- Assignation du dernier numéro de position d'après le document en cours
        DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
        -- Copie des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
        DOC_COPY_DISCHARGE.CopyNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);
      end if;

      -- Màj des lignes des litiges avec le document initial cible genéré
      update DOC_LITIG_PROCESS
         set DLP_DOC_INIT_TGT_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DOC_DOCUMENT_ID = vSRC_DOC_ID;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
    end if;

    return vNEW_DOC_ID;
  end GenerateInitialTgtDoc;

  /**
  * function GenReceptSupplyDoc
  * Description
  *   Création par décharge du document retour en stock avec appro
  */
  function GenReceptSupplyDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNEW_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les données du document
    for tplDoc in (select   DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_RECEPT_SUPPLY_ID
                       from DOC_LITIG_JOB DLJ
                          , DOC_LITIG_CONTEXT DLX
                          , DOC_LITIG_PROCESS DLP
                          , DOC_DOCUMENT DMT
                      where DLJ.DOC_LITIG_JOB_ID = aJobID
                        and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                        and DLP.DOC_DOCUMENT_ID = aDocumentID
                        and DLP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                        and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                        and nvl(DLP.DLP_QTY, 0) > 0
                        and DLP.C_GOOD_LITIG = '1'
                        and DLX.DLX_GAU_RECEPT_SUPPLY_ID is not null
                        and DLP.DLP_DOC_RECEPT_SUPPLY_ID is null
                   group by DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_RECEPT_SUPPLY_ID) loop
      vNEW_DOC_ID  := null;
      -- Création du document pour le retour avec appro
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID
                                           , aMode            => '318'
                                           , aGaugeID         => tplDoc.DLX_GAU_RECEPT_SUPPLY_ID
                                           , aSrcDocumentID   => aDocumentID
                                            );
      -- Décharge des positions
      InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => aDocumentID, aGoodLitig => '1');
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
      -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);

      -- Màj des lignes des litiges avec le document de retour avec appro
      update DOC_LITIG_PROCESS
         set DLP_DOC_RECEPT_SUPPLY_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DOC_DOCUMENT_ID = aDocumentID
         and C_GOOD_LITIG = '1'
         and nvl(DLP_QTY, 0) > 0;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
      -- Effectuer la màj des liens entre les litiges et le retour avec appro
      UpdateLitigDetailLink(aNewDocumentID => vNEW_DOC_ID, aLinkField => 'RECEPT_SUPPLY');
    end loop;

    return vNEW_DOC_ID;
  end GenReceptSupplyDoc;

  /**
  * function GenReceptDoc
  * Description
  *   Création par décharge du document retour en stock sans appro
  */
  function GenReceptDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNEW_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les données du document
    for tplDoc in (select   DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_RECEPT_ID
                       from DOC_LITIG_JOB DLJ
                          , DOC_LITIG_CONTEXT DLX
                          , DOC_LITIG_PROCESS DLP
                          , DOC_DOCUMENT DMT
                      where DLJ.DOC_LITIG_JOB_ID = aJobID
                        and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                        and DLP.DOC_DOCUMENT_ID = aDocumentID
                        and DLP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                        and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                        and nvl(DLP.DLP_QTY, 0) > 0
                        and DLP.C_GOOD_LITIG = '2'
                        and DLX.DLX_GAU_RECEPT_ID is not null
                        and DLP.DLP_DOC_RECEPT_ID is null
                   group by DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_RECEPT_ID) loop
      vNEW_DOC_ID  := null;
      -- Création du document pour le retour sans appro
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID, aMode => '318', aGaugeID => tplDoc.DLX_GAU_RECEPT_ID
                                           , aSrcDocumentID   => aDocumentID);
      -- Décharge des positions
      InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => aDocumentID, aGoodLitig => '2');
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
      -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);

      -- Màj des lignes des litiges avec le document de retour sans appro
      update DOC_LITIG_PROCESS
         set DLP_DOC_RECEPT_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DOC_DOCUMENT_ID = aDocumentID
         and C_GOOD_LITIG = '2'
         and nvl(DLP_QTY, 0) > 0;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
      -- Effectuer la màj des liens entre les litiges et le retour sans appro
      UpdateLitigDetailLink(aNewDocumentID => vNEW_DOC_ID, aLinkField => 'RECEPT');
    end loop;

    return vNEW_DOC_ID;
  end GenReceptDoc;

  /**
  * function GenTrashSupplyDoc
  * Description
  *   Création par décharge du document transfert en stock déchets avec appro
  */
  function GenTrashSupplyDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNEW_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les données du document
    for tplDoc in (select   DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_TRASH_SUPPLY_ID
                       from DOC_LITIG_JOB DLJ
                          , DOC_LITIG_PROCESS DLP
                          , DOC_DOCUMENT DMT
                          , DOC_LITIG_CONTEXT DLX
                      where DLJ.DOC_LITIG_JOB_ID = aJobID
                        and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                        and DLP.DOC_DOCUMENT_ID = aDocumentID
                        and DLP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                        and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                        and DLP.C_GOOD_LITIG = '3'
                        and nvl(DLP.DLP_QTY, 0) > 0
                        and DLX.DLX_GAU_TRASH_SUPPLY_ID is not null
                        and DLP.DLP_DOC_TRASH_SUPPLY_ID is null
                   group by DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_TRASH_SUPPLY_ID) loop
      vNEW_DOC_ID  := null;
      -- Création du document pour le transfert en déchets
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID
                                           , aMode            => '318'
                                           , aGaugeID         => tplDoc.DLX_GAU_TRASH_SUPPLY_ID
                                           , aSrcDocumentID   => aDocumentID
                                            );
      -- Décharge des positions
      InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => aDocumentID, aGoodLitig => '3');
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
      -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);

      -- Màj des lignes des litiges avec le document transfert en déchets genéré
      update DOC_LITIG_PROCESS
         set DLP_DOC_TRASH_SUPPLY_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DOC_DOCUMENT_ID = aDocumentID
         and C_GOOD_LITIG = '3'
         and nvl(DLP_QTY, 0) > 0;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
      -- Effectuer la màj des liens entre les litiges et le transfert en stock déchets avec appro
      UpdateLitigDetailLink(aNewDocumentID => vNEW_DOC_ID, aLinkField => 'TRASH_SUPPLY');
    end loop;

    return vNEW_DOC_ID;
  end GenTrashSupplyDoc;

  /**
  * function GenTrashDoc
  * Description
  *   Création par décharge du document transfert en stock déchets sans appro
  */
  function GenTrashDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNEW_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les données du document
    for tplDoc in (select   DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_TRASH_ID
                       from DOC_LITIG_JOB DLJ
                          , DOC_LITIG_PROCESS DLP
                          , DOC_DOCUMENT DMT
                          , DOC_LITIG_CONTEXT DLX
                      where DLJ.DOC_LITIG_JOB_ID = aJobID
                        and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                        and DLP.DOC_DOCUMENT_ID = aDocumentID
                        and DLP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                        and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                        and DLP.C_GOOD_LITIG = '4'
                        and nvl(DLP.DLP_QTY, 0) > 0
                        and DLX.DLX_GAU_TRASH_ID is not null
                        and DLP.DLP_DOC_TRASH_ID is null
                   group by DMT.DOC_DOCUMENT_ID
                          , DLX.DLX_GAU_TRASH_ID) loop
      vNEW_DOC_ID  := null;
      -- Création du document pour le transfert en déchets
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID, aMode => '318', aGaugeID => tplDoc.DLX_GAU_TRASH_ID
                                           , aSrcDocumentID   => aDocumentID);
      -- Décharge des positions
      InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => aDocumentID, aGoodLitig => '4');
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
      -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);

      -- Màj des lignes des litiges avec le document transfert en déchets genéré
      update DOC_LITIG_PROCESS
         set DLP_DOC_TRASH_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DOC_DOCUMENT_ID = aDocumentID
         and C_GOOD_LITIG = '4'
         and nvl(DLP_QTY, 0) > 0;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
      -- Effectuer la màj des liens entre les litiges et le transfert en stock déchets sans appro
      UpdateLitigDetailLink(aNewDocumentID => vNEW_DOC_ID, aLinkField => 'TRASH');
    end loop;

    return vNEW_DOC_ID;
  end GenTrashDoc;

  /**
  * procedure GenerateFinalDocs
  * Description
  *   Méthode globale regroupant la création des documents finaux.
  */
  procedure GenerateFinalDocs(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vDOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Création du document final cible
    vDOC_ID  := GenerateFinalTgtDoc(aJobID => aJobID, aDocumentID => aDocumentID);
  -- La Note de débit doit être générée par la confirmation du document final cible
  end GenerateFinalDocs;

  /**
  * function GenerateFinalTgtDoc
  * Description
  *   Création par copie/décharge du document final cible
  */
  function GenerateFinalTgtDoc(aJobID in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type, aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vSRC_DOC_ID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNEW_DOC_ID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vDOC_GAUGE_ID      DOC_GAUGE.DOC_GAUGE_ID%type;
    vGAUGE_LINK        DOC_LITIG_CONTEXT.C_DLX_START_GAUGE_LINK%type;
    vC_DOC_CREATE_MODE DOC_DOCUMENT.C_DOC_CREATE_MODE%type;
  begin
    -- Récuperer les données du document source
    begin
      select distinct DMT.DOC_DOCUMENT_ID
                    , DLX.DLX_GAU_FINAL_TGT_ID
                    , DLX.C_DLX_FINAL_GAUGE_LINK
                    , case
                        when nvl(DLX.C_DLX_FINAL_GAUGE_LINK, '1') = '1' then '318'
                        else '218'
                      end C_DOC_CREATE_MODE
                 into vSRC_DOC_ID
                    , vDOC_GAUGE_ID
                    , vGAUGE_LINK
                    , vC_DOC_CREATE_MODE
                 from DOC_LITIG_JOB DLJ
                    , DOC_LITIG_PROCESS DLP
                    , DOC_DOCUMENT DMT
                    , DOC_LITIG_CONTEXT DLX
                where DLJ.DOC_LITIG_JOB_ID = aJobID
                  and DLJ.DOC_LITIG_JOB_ID = DLP.DOC_LITIG_JOB_ID
                  and DLP.DLP_DOC_FINAL_SRC_ID = aDocumentID
                  and DLP.DLP_DOC_FINAL_SRC_ID = DMT.DOC_DOCUMENT_ID
                  and DLJ.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                  and DLP.DLP_DOC_FINAL_TGT_ID is null;
    exception
      when no_data_found then
        vSRC_DOC_ID  := null;
    end;

    if vSRC_DOC_ID is not null then
      -- Création du document par copie ou décharge, selon code du contexte
      vNEW_DOC_ID  := null;
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vNEW_DOC_ID
                                           , aMode            => vC_DOC_CREATE_MODE
                                           , aGaugeID         => vDOC_GAUGE_ID
                                           , aSrcDocumentID   => vSRC_DOC_ID
                                            );

      -- Décharge des positions
      if vGAUGE_LINK = '1' then
        InsertDischargeDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => vSRC_DOC_ID);
        -- Insertion des données de litige dans la table DOC_LITIG_PROCESS
        InsertLitigOnCopyDischarge(aNewDocumentID => vNEW_DOC_ID, aMode => '1');
        -- Assignation du dernier numéro de position d'après le document en cours
        DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
        -- Décharge des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
        DOC_COPY_DISCHARGE.DischargeNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);
      else
        -- Copie des positions
        InsertCopyDetail(aNewDocumentID => vNEW_DOC_ID, aJobID => aJobID, aDocumentID => vSRC_DOC_ID);
        -- Insertion des données de litige dans la table DOC_LITIG_PROCESS
        InsertLitigOnCopyDischarge(aNewDocumentID => vNEW_DOC_ID, aMode => '2');
        -- Assignation du dernier numéro de position d'après le document en cours
        DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
        -- Copie des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
        DOC_COPY_DISCHARGE.CopyNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);
      end if;

      -- Màj des lignes des litiges avec le document final cible genéré
      update DOC_LITIG_PROCESS
         set DLP_DOC_FINAL_TGT_ID = vNEW_DOC_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_JOB_ID = aJobID
         and DLP_DOC_FINAL_SRC_ID = vSRC_DOC_ID;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
    end if;

    return vNEW_DOC_ID;
  end GenerateFinalTgtDoc;

  /**
  * function GenerateDebitNoteDoc
  * Description
  *   Création par copie du document note de débit
  */
  function GenerateDebitNoteDoc(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNEW_DOC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les données du document source
    for tplDoc in (select distinct POS_SRC.DOC_DOCUMENT_ID
                                 , DLX.DLX_GAU_DEBIT_NOTE_ID DOC_GAUGE_ID
                              from DOC_LITIG DLG
                                 , DOC_LITIG_CONTEXT DLX
                                 , DOC_DOCUMENT DMT
                                 , DOC_POSITION POS
                                 , DOC_POSITION_DETAIL PDE
                                 , DOC_POSITION_DETAIL PDE_SRC
                                 , DOC_POSITION POS_SRC
                                 , PAC_SUPPLIER_PARTNER SUP
                             where DMT.DOC_DOCUMENT_ID = aDocumentID
                               and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                               and SUP.C_SUPPLIER_LITIG = '1'
                               and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                               and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                               and PDE.DOC_PDE_LITIG_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                               and POS_SRC.DOC_POSITION_ID = PDE_SRC.DOC_POSITION_ID
                               and PDE_SRC.DOC_POSITION_DETAIL_ID = DLG.DOC_POSITION_DETAIL_ID
                               and DLG.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                               and DLX.DLX_GAU_FINAL_TGT_ID = DMT.DOC_GAUGE_ID
                               and DLG.DOC_PDE_DEBIT_NOTE_ID is null) loop
      -- Création du document note de débit par copie
      vNEW_DOC_ID  := null;
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID => vNEW_DOC_ID, aMode => '218', aGaugeID => tplDoc.DOC_GAUGE_ID, aSrcDocumentID => aDocumentID);
      -- Copie des positions avec comme qté la qté du litige
      InsertCopyDetailDebitNote(aNewDocumentID => vNEW_DOC_ID, aDocFinalTgtID => aDocumentID);
      -- Assignation du dernier numéro de position d'après le document en cours
      DOC_COPY_DISCHARGE.SetLastDocPosNumber(vNEW_DOC_ID);
      -- Copie des positions insérées ci-dessus dans la DOC_POS_DET_COPY_DISCHARGE
      DOC_COPY_DISCHARGE.CopyNewDocument(aNewDocumentId => vNEW_DOC_ID, aFlowId => null);
      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vNEW_DOC_ID, 1, 1, 1);
      -- Effectuer la màj des liens entre les litiges et la note de débit
      UpdateLitigDetailLink(aNewDocumentID => vNEW_DOC_ID, aLinkField => 'DEBIT_NOTE');
    end loop;

    return vNEW_DOC_ID;
  end GenerateDebitNoteDoc;

  /**
  * procedure GenerateLitigPos
  * Description
  *   Création des positions de type litige sur le document final
  */
  procedure GenerateLitigPos(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vPOS_ID DOC_POSITION.DOC_POSITION_ID%type;
    vPDE_ID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    for tplLitig in (select   POS.DOC_POSITION_ID
                            , DLP.DLP_QTY
                            , DLP.DOC_LITIG_ID
                            , POS.POS_NUMBER
                            , PDE.DOC_POSITION_DETAIL_ID
                         from DOC_LITIG_PROCESS DLP
                            , DOC_LITIG DLG
                            , DOC_POSITION_DETAIL PDE
                            , DOC_POSITION POS
                        where DLP.DLP_DOC_FINAL_SRC_ID = aDocumentID
                          and DLP.DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
                          and DLP.DLP_SELECTION = 1
                          and DLP.DOC_LITIG_ID = DLG.DOC_LITIG_ID
                          and DLG.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                          and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                          and DLG.DOC_PDE_FINAL_ID is null
                     order by POS.POS_NUMBER) loop
      vPOS_ID  := null;
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aDocumentID
                                           , aPosCreateMode    => '118'
                                           , aTypePos          => '21'
                                           , aSrcPositionID    => tplLitig.DOC_POSITION_ID
                                           , aBasisQuantity    => tplLitig.DLP_QTY
                                           , aLitigID          => tplLitig.DOC_LITIG_ID
                                           , aGenerateDetail   => 0
                                            );
      vPDE_ID  := null;
      DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => vPDE_ID
                                       , aPositionID      => vPOS_ID
                                       , aPdeCreateMode   => '118'
                                       , aSrcDetailID     => tplLitig.DOC_POSITION_DETAIL_ID
                                       , aQuantity        => tplLitig.DLP_QTY
                                       , aLitigID         => tplLitig.DOC_LITIG_ID
                                        );

      update DOC_LITIG
         set DOC_PDE_FINAL_ID = vPDE_ID
           , DLG_BALANCE_QTY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_ID = tplLitig.DOC_LITIG_ID;
    end loop;

    delete from DOC_LITIG_PROCESS
          where DLP_DOC_FINAL_SRC_ID = aDocumentID
            and DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID;
  end GenerateLitigPos;

  /**
  * procedure PrepareManualLitigPos
  * Description
  *   Mise en place de données temporaires pour récuperer les litiges encore ouverts
  *   pour lesquels on peut générer les positions litige sur le document final
  */
  function PrepareManualLitigPos(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return integer
  is
    vCount integer;
  begin
    delete from DOC_LITIG_PROCESS
          where DLP_DOC_FINAL_TGT_ID = aDocumentID
            and DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID;

    -- Liste des litiges qui n'ont pas encore généré des positions dans le doc
    -- final cible et donc les positions bien correspondantes ont été complétement
    -- déchargées sur des docs final cible
    for tplLitig in (select   DLG.DOC_LITIG_ID
                         from DOC_LITIG_CONTEXT DLX
                            , DOC_DOCUMENT DMT
                            , DOC_LITIG DLG
                            , DOC_DOCUMENT DMT_SRC
                            , DOC_POSITION POS_SRC
                            , DOC_POSITION_DETAIL PDE_SRC
                            , DOC_DOCUMENT DMT_TGT
                            , DOC_POSITION_DETAIL PDE_TGT
                        where DMT.DOC_DOCUMENT_ID = aDocumentID
                          and DLX.DLX_GAU_FINAL_TGT_ID = DMT.DOC_GAUGE_ID
                          and DLG.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
                          and DLG.DOC_PDE_FINAL_ID is null
                          and DLG.DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                          and DMT_TGT.DOC_GAUGE_ID = DLX.DLX_GAU_FINAL_TGT_ID
                          and DMT_TGT.DOC_DOCUMENT_ID = PDE_TGT.DOC_DOCUMENT_ID
                          and PDE_TGT.DOC_PDE_LITIG_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                          and DMT_SRC.DOC_DOCUMENT_ID = POS_SRC.DOC_DOCUMENT_ID
                          and POS_SRC.DOC_POSITION_ID = PDE_SRC.DOC_POSITION_ID
                          and DMT_SRC.PAC_THIRD_ID = DMT.PAC_THIRD_ID
                     group by DLG.DOC_LITIG_ID
                            , PDE_SRC.DOC_POSITION_DETAIL_ID
                            , PDE_SRC.PDE_BASIS_DELAY
                            , POS_SRC.POS_NUMBER
                            , DMT_SRC.DMT_NUMBER
                       having sum(PDE_TGT.PDE_BASIS_QUANTITY) = sum(PDE_SRC.PDE_BASIS_QUANTITY) - max(DLG.DLG_QTY)
                     order by DMT_SRC.DMT_NUMBER
                            , POS_SRC.POS_NUMBER
                            , PDE_SRC.PDE_BASIS_DELAY
                            , PDE_SRC.DOC_POSITION_DETAIL_ID) loop
      insert into DOC_LITIG_PROCESS
                  (DOC_LITIG_PROCESS_ID
                 , DLP_DOC_FINAL_TGT_ID
                 , DOC_LITIG_ID
                 , DLP_SESSION_ID
                 , DLP_SELECTION
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , aDocumentID
                 , tplLitig.DOC_LITIG_ID
                 , DBMS_SESSION.UNIQUE_SESSION_ID
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    -- Vérifier combien de lignes ont été insérées
    select count(*)
      into vCount
      from DOC_LITIG_PROCESS
     where DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
       and DLP_DOC_FINAL_TGT_ID = aDocumentID;

    return vCount;
  end PrepareManualLitigPos;

  /**
  * procedure GenerateManualLitigPos
  * Description
  *   Création d'une position de type litige sur le document final avec un id de litige en param
  */
  procedure GenerateManualLitigPos(
    aDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aLitigID    in     DOC_LITIG.DOC_LITIG_ID%type
  , aPositionID out    DOC_POSITION.DOC_POSITION_ID%type
  )
  is
    cursor crLitig
    is
      select DLG.DOC_LITIG_ID
           , DLG.DLG_QTY
           , POS.DOC_POSITION_ID
           , PDE.DOC_POSITION_DETAIL_ID
        from DOC_LITIG DLG
           , DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
       where DLG.DOC_LITIG_ID = aLitigID
         and DLG.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
         and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and DLG.DOC_PDE_FINAL_ID is null;

    tplLitig crLitig%rowtype;
    vPOS_ID  DOC_POSITION.DOC_POSITION_ID%type                 default null;
    vPDE_ID  DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type   default null;
  begin
    open crLitig;

    fetch crLitig
     into tplLitig;

    if crLitig%found then
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aDocumentID
                                           , aPosCreateMode    => '118'
                                           , aTypePos          => '21'
                                           , aSrcPositionID    => tplLitig.DOC_POSITION_ID
                                           , aBasisQuantity    => tplLitig.DLG_QTY
                                           , aLitigID          => tplLitig.DOC_LITIG_ID
                                           , aGenerateDetail   => 0
                                            );
      DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => vPDE_ID
                                       , aPositionID      => vPOS_ID
                                       , aPdeCreateMode   => '118'
                                       , aSrcDetailID     => tplLitig.DOC_POSITION_DETAIL_ID
                                       , aQuantity        => tplLitig.DLG_QTY
                                       , aLitigID         => tplLitig.DOC_LITIG_ID
                                        );

      update DOC_LITIG
         set DOC_PDE_FINAL_ID = vPDE_ID
           , DLG_BALANCE_QTY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_ID = tplLitig.DOC_LITIG_ID;

      aPositionID  := vPOS_ID;

      /* Effacer la liste des litiges traités de la table Temp */
      delete from DOC_LITIG_PROCESS
            where DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
              and DLP_DOC_FINAL_TGT_ID = aDocumentID
              and DOC_LITIG_ID = tplLitig.DOC_LITIG_ID;
    end if;

    close crLitig;
  end GenerateManualLitigPos;

  /**
  * function GetGoodLitig
  * Description
  *   Renvoi le type de litige du bien en fonction du tiers donné
  */
  function GetGoodLitig(aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    return varchar2
  is
    vComplDataID GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type;
    vGoodLitig   GCO_COMPL_DATA_PURCHASE.C_GOOD_LITIG%type                 default '1';
  begin
    vComplDataID  := GCO_FUNCTIONS.GetComplDataPurchaseId(aGoodID, aThirdID);

    if vComplDataID is not null then
      begin
        select nvl(C_GOOD_LITIG, '1')
          into vGoodLitig
          from GCO_COMPL_DATA_PURCHASE
         where GCO_COMPL_DATA_PURCHASE_ID = vComplDataID;
      exception
        when no_data_found then
          vGoodLitig  := '1';
      end;
    end if;

    return vGoodLitig;
  end GetGoodLitig;

  /**
  * procedure InsertDischargeDetail
  * Description
  *   Insertion des données de décharge dans la vue V_DOC_POS_DET_COPY_DISCHARGE
  */
  procedure InsertDischargeDetail(
    aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aJobID         in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGoodLitig     in varchar2 default null
  )
  is
    cursor crDischargePde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , nvl(DLP.DLP_DISCHARGE_QTY, 0) DLP_DISCHARGE_QTY
                    , nvl(DLP.DLP_QTY, 0) DLP_QTY
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '318' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , GOO.GOO_NUMBER_OF_DECIMAL
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_NUMBER
                    , case
                        when POS.C_GAUGE_TYPE_POS in('1', '2', '3') then 0
                        else 1
                      end DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , aNewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_LITIG_PROCESS DLP
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                where DLP.DOC_LITIG_JOB_ID = aJobID
                  and nvl(DLP.DOC_DOCUMENT_ID, DLP.DLP_DOC_FINAL_SRC_ID) = aDocumentID
                  and DLP.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and (   DLP.C_GOOD_LITIG = aGoodLitig
                       or aGoodLitig is null)
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT_TGT.DOC_DOCUMENT_ID = aNewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = aDocumentID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (exists(
                                                   select DOC_GAUGE_POSITION_ID
                                                     from DOC_GAUGE_POSITION GAP_LINK
                                                    where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                      and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                )
                                            )
                                          )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101') )
                               )
                           and exists(
                                 select GAP.DOC_GAUGE_POSITION_ID
                                   from DOC_GAUGE_POSITION GAP
                                  where GAP.DOC_GAUGE_ID = DMT2.DOC_GAUGE_ID
                                    and GAP.C_GAUGE_TYPE_POS = POS2.C_GAUGE_TYPE_POS
                                    and GAP.GAP_DESIGNATION in(
                                                 select GAP2.GAP_DESIGNATION
                                                   from DOC_GAUGE_POSITION GAP2
                                                  where GAP2.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                    and GAP2.C_GAUGE_TYPE_POS = POS2.C_GAUGE_TYPE_POS)
                                    and GAP.GAP_INCLUDE_TAX_TARIFF = POS2.POS_INCLUDE_TAX_TARIFF
                                    and GAP.GAP_VALUE_QUANTITY = (select GAP3.GAP_VALUE_QUANTITY
                                                                    from DOC_GAUGE_POSITION GAP3
                                                                   where GAP3.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID) ) )
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePde              crDischargePde%rowtype;

    cursor crDischargePdeCPT(cPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , null DCD_QUANTITY
                    , null DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '318' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , GAU.C_ADMIN_DOMAIN
                    , ANewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_RECORD RCO
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                    , DOC_LITIG_PROCESS DLP
                where DLP.DOC_LITIG_JOB_ID = aJobID
                  and nvl(DLP.DOC_DOCUMENT_ID, DLP.DLP_DOC_FINAL_SRC_ID) = aDocumentID
                  and DLP.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and POS.DOC_DOC_POSITION_ID = cPositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT           crDischargePdeCPT%rowtype;
    --
    vNewDcdID                    DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd                   V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt                V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc           GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    dblGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
  begin
    /* Ouverture des détail de position déchargeables du document déchargeable courant */
    -- Liste des détails du document source
    for tplDischargePde in crDischargePde loop
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      -- Traitement du changement de partenaire. Si le partenaire source est différent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calculé.
      vConvertFactorCalc                        :=
        GCO_FUNCTIONS.GetThirdConvertFactor(tplDischargePde.GCO_GOOD_ID
                                          , tplDischargePde.PAC_THIRD_CDA_ID
                                          , tplDischargePde.C_GAUGE_TYPE_POS
                                          , null
                                          , tplDischargePde.TGT_PAC_THIRD_CDA_ID
                                          , tplDischargePde.TGT_C_ADMIN_DOMAIN
                                           );
      -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
      vInsertDcd                                := null;
      vInsertDcd.DOC_POS_DET_COPY_DISCHARGE_ID  := vNewDcdID;
      vInsertDcd.DOC_POSITION_DETAIL_ID         := tplDischargePde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID                := tplDischargePde.NEW_DOCUMENT_ID;
      vInsertDcd.CRG_SELECT                     := tplDischargePde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID              := tplDischargePde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID                := tplDischargePde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID            := tplDischargePde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID     := tplDischargePde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID    := tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                    := tplDischargePde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID                := tplDischargePde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID        := tplDischargePde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID    := tplDischargePde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID            := tplDischargePde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID           := tplDischargePde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_DOCUMENT_ID                := tplDischargePde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                   := tplDischargePde.PAC_THIRD_ID;
      vInsertDcd.PAC_THIRD_ACI_ID               := tplDischargePde.PAC_THIRD_ACI_ID;
      vInsertDcd.PAC_THIRD_DELIVERY_ID          := tplDischargePde.PAC_THIRD_DELIVERY_ID;
      vInsertDcd.PAC_THIRD_TARIFF_ID            := tplDischargePde.PAC_THIRD_TARIFF_ID;
      vInsertDcd.DOC_GAUGE_ID                   := tplDischargePde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID           := tplDischargePde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID              := tplDischargePde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS               := tplDischargePde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID       := tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY                := tplDischargePde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY         := tplDischargePde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY                := tplDischargePde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY         := tplDischargePde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY             := tplDischargePde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY      := tplDischargePde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY             := tplDischargePde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY           := tplDischargePde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT    := tplDischargePde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU          := tplDischargePde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU   := tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU          := tplDischargePde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY          := tplDischargePde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE             := tplDischargePde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT          := tplDischargePde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                  := tplDischargePde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                  := tplDischargePde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                  := tplDischargePde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                     := tplDischargePde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                     := tplDischargePde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                     := tplDischargePde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                     := tplDischargePde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                     := tplDischargePde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                     := tplDischargePde.PDE_DATE_3;

      if aGoodLitig is null then
        vInsertDcd.DCD_QUANTITY  := tplDischargePde.DLP_DISCHARGE_QTY;
      else
        vInsertDcd.DCD_QUANTITY  := tplDischargePde.DLP_QTY;
      end if;

      vInsertDcd.DCD_QUANTITY_SU                :=
          ACS_FUNCTION.RoundNear(vInsertDcd.DCD_QUANTITY * tplDischargePde.POS_CONVERT_FACTOR, 1 / power(10, nvl(tplDischargePde.GOO_NUMBER_OF_DECIMAL, 0) ), 1);
      vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC        := nvl(vConvertFactorCalc, tplDischargePde.POS_CONVERT_FACTOR);
      vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
      vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE              := tplDischargePde.C_PDE_CREATE_MODE;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        dblGreatestSumQuantityCPT     := 0;
        dblGreatestSumQuantityCPT_SU  := 0;

        -- Traitement des détails de positions composants.
        for tplDischargePdeCPT in crDischargePdeCPT(vInsertDcd.DOC_POSITION_ID) loop
          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplDischargePdeCPT.POS_UTIL_COEFF, 0) = 0) then
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
          else
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, tplDischargePdeCPT.DCD_QUANTITY / tplDischargePdeCPT.POS_UTIL_COEFF);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, tplDischargePdeCPT.DCD_QUANTITY_SU / tplDischargePdeCPT.POS_UTIL_COEFF);
          end if;

          -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
          vInsertDcdCpt                               := null;
          vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.NEW_DOCUMENT_ID               := tplDischargePdeCPT.NEW_DOCUMENT_ID;
          vInsertDcdCpt.CRG_SELECT                    := tplDischargePdeCPT.CRG_SELECT;
          vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := tplDischargePdeCPT.DOC_GAUGE_FLOW_ID;
          vInsertDcdCpt.DOC_POSITION_ID               := tplDischargePdeCPT.DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_ID           := tplDischargePdeCPT.DOC_DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := tplDischargePdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := tplDischargePdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.GCO_GOOD_ID                   := tplDischargePdeCPT.GCO_GOOD_ID;
          vInsertDcdCpt.STM_LOCATION_ID               := tplDischargePdeCPT.STM_LOCATION_ID;
          vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := tplDischargePdeCPT.GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := tplDischargePdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.STM_STM_LOCATION_ID           := tplDischargePdeCPT.STM_STM_LOCATION_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := tplDischargePdeCPT.FAL_SCHEDULE_STEP_ID;
          vInsertDcdCpt.DOC_DOCUMENT_ID               := tplDischargePdeCPT.DOC_DOCUMENT_ID;
          vInsertDcdCpt.PAC_THIRD_ID                  := tplDischargePdeCPT.PAC_THIRD_ID;
          vInsertDcdCpt.PAC_THIRD_ACI_ID              := tplDischargePdeCPT.PAC_THIRD_ACI_ID;
          vInsertDcdCpt.PAC_THIRD_DELIVERY_ID         := tplDischargePdeCPT.PAC_THIRD_DELIVERY_ID;
          vInsertDcdCpt.PAC_THIRD_TARIFF_ID           := tplDischargePdeCPT.PAC_THIRD_TARIFF_ID;
          vInsertDcdCpt.DOC_GAUGE_ID                  := tplDischargePdeCPT.DOC_GAUGE_ID;
          vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := tplDischargePdeCPT.DOC_GAUGE_RECEIPT_ID;
          vInsertDcdCpt.DOC_GAUGE_COPY_ID             := tplDischargePdeCPT.DOC_GAUGE_COPY_ID;
          vInsertDcdCpt.C_GAUGE_TYPE_POS              := tplDischargePdeCPT.C_GAUGE_TYPE_POS;
          vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := tplDischargePdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vInsertDcdCpt.PDE_BASIS_DELAY               := tplDischargePdeCPT.PDE_BASIS_DELAY;
          vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := tplDischargePdeCPT.PDE_INTERMEDIATE_DELAY;
          vInsertDcdCpt.PDE_FINAL_DELAY               := tplDischargePdeCPT.PDE_FINAL_DELAY;
          vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := tplDischargePdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vInsertDcdCpt.PDE_BASIS_QUANTITY            := tplDischargePdeCPT.PDE_BASIS_QUANTITY;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vInsertDcdCpt.PDE_FINAL_QUANTITY            := tplDischargePdeCPT.PDE_FINAL_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY          := tplDischargePdeCPT.PDE_BALANCE_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := tplDischargePdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := tplDischargePdeCPT.PDE_BASIS_QUANTITY_SU;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := tplDischargePdeCPT.PDE_FINAL_QUANTITY_SU;
          vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := tplDischargePdeCPT.PDE_MOVEMENT_QUANTITY;
          vInsertDcdCpt.PDE_MOVEMENT_VALUE            := tplDischargePdeCPT.PDE_MOVEMENT_VALUE;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := tplDischargePdeCPT.PDE_DELAY_UPDATE_TEXT;
          vInsertDcdCpt.PDE_DECIMAL_1                 := tplDischargePdeCPT.PDE_DECIMAL_1;
          vInsertDcdCpt.PDE_DECIMAL_2                 := tplDischargePdeCPT.PDE_DECIMAL_2;
          vInsertDcdCpt.PDE_DECIMAL_3                 := tplDischargePdeCPT.PDE_DECIMAL_3;
          vInsertDcdCpt.PDE_TEXT_1                    := tplDischargePdeCPT.PDE_TEXT_1;
          vInsertDcdCpt.PDE_TEXT_2                    := tplDischargePdeCPT.PDE_TEXT_2;
          vInsertDcdCpt.PDE_TEXT_3                    := tplDischargePdeCPT.PDE_TEXT_3;
          vInsertDcdCpt.PDE_DATE_1                    := tplDischargePdeCPT.PDE_DATE_1;
          vInsertDcdCpt.PDE_DATE_2                    := tplDischargePdeCPT.PDE_DATE_2;
          vInsertDcdCpt.PDE_DATE_3                    := tplDischargePdeCPT.PDE_DATE_3;
          vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := tplDischargePdeCPT.PDE_GENERATE_MOVEMENT;
          vInsertDcdCpt.DCD_QUANTITY                  := tplDischargePdeCPT.DCD_QUANTITY;
          vInsertDcdCpt.DCD_QUANTITY_SU               := tplDischargePdeCPT.DCD_QUANTITY_SU;
          vInsertDcdCpt.DCD_BALANCE_FLAG              := tplDischargePdeCPT.DCD_BALANCE_FLAG;
          vInsertDcdCpt.POS_CONVERT_FACTOR            := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplDischargePdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vInsertDcdCpt.POS_UTIL_COEFF                := tplDischargePdeCPT.POS_UTIL_COEFF;
          vInsertDcdCpt.DCD_VISIBLE                   := tplDischargePdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := tplDischargePdeCPT.C_PDE_CREATE_MODE;
          vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;

        /**
        * Redéfinit la quantité du produit terminé en fonction de la quantité
        * des composants.
        *
        *   Selon la règle suivante (facture des livraisons CPT) :
        *
        *   Si toutes les quantités des composants sont à 0 alors on initialise
        *   la quantité du produit terminé avec 0, sinon on conserve la quantité
        *   initiale (quantité solde).
        */
        if (dblGreatestSumQuantityCPT = 0) then
          update DOC_POS_DET_COPY_DISCHARGE
             set DCD_QUANTITY = 0
               , DCD_QUANTITY_SU = 0
           where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
        end if;
      end if;
    end loop;
  end InsertDischargeDetail;

  /**
  * procedure InsertCopieDetail
  * Description
  *   Insertion des données de copie dans la vue V_DOC_POS_DET_COPY_DISCHARGE
  */
  procedure InsertCopyDetail(
    aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aJobID         in DOC_LITIG_JOB.DOC_LITIG_JOB_ID%type
  , aDocumentID    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
    cursor crCopyPde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , nvl(DLP.DLP_DISCHARGE_QTY, 0) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(DLP.DLP_DISCHARGE_QTY, 0) * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '218' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , ANewDocumentID NEW_DOCUMENT_ID
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_LITIG_PROCESS DLP
                    , DOC_GAUGE_POSITION GAP
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                where DLP.DOC_LITIG_JOB_ID = aJobID
                  and DLP.DOC_DOCUMENT_ID = aDocumentID
                  and DLP.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and DMT_TGT.DOC_DOCUMENT_ID = aNewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and DMT.DOC_DOCUMENT_ID = DLP.DOC_DOCUMENT_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID is null
                  and POS.C_DOC_POS_STATUS <> '05'
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and exists(
                        select GAP_TGT.DOC_GAUGE_POSITION_ID
                          from DOC_GAUGE_POSITION GAP_TGT
                         where GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                           and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                           and GAP_TGT.GAP_DESIGNATION = GAP.GAP_DESIGNATION)
                  and DOC_I_LIB_GAUGE.CanCopy(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplCopyPde                   crCopyPde%rowtype;

    cursor crCopyPdeCPT(cPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , nvl(DLP.DLP_DISCHARGE_QTY, 0) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(DLP.DLP_DISCHARGE_QTY, 0) * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '218' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , GAU.C_ADMIN_DOMAIN
                    , aNewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_LITIG_PROCESS DLP
                    , DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_RECORD RCO
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where DLP.DOC_LITIG_JOB_ID = aJobID
                  and DLP.DOC_DOCUMENT_ID = aDocumentID
                  and DLP.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and POS.DOC_DOC_POSITION_ID = cPositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplCopyPdeCPT                crCopyPdeCPT%rowtype;
    --
    vNewDcdID                    DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd                   V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt                V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc           GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    dblGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
  begin
    -- Liste des détails du document source
    for tplCopyPde in crCopyPde loop
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calculé.
      vConvertFactorCalc                       :=
        GCO_FUNCTIONS.GetThirdConvertFactor(tplCopyPde.GCO_GOOD_ID
                                          , tplCopyPde.PAC_THIRD_CDA_ID
                                          , tplCopyPde.C_GAUGE_TYPE_POS
                                          , null
                                          , tplCopyPde.TGT_PAC_THIRD_CDA_ID
                                          , tplCopyPde.TGT_C_ADMIN_DOMAIN
                                           );
      -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
      vInsertDcd                               := null;
      vInsertDcd.DOC_POSITION_DETAIL_ID        := tplCopyPde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID               := tplCopyPde.NEW_DOCUMENT_ID;
      vInsertDcd.CRG_SELECT                    := tplCopyPde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID             := tplCopyPde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID               := tplCopyPde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID           := tplCopyPde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID    := tplCopyPde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID   := tplCopyPde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                   := tplCopyPde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID               := tplCopyPde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID       := tplCopyPde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID   := tplCopyPde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID           := tplCopyPde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID          := tplCopyPde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_RECORD_ID                 := tplCopyPde.DOC_RECORD_ID;
      vInsertDcd.DOC_DOCUMENT_ID               := tplCopyPde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                  := tplCopyPde.PAC_THIRD_ID;
      vInsertDcd.PAC_THIRD_ACI_ID              := tplCopyPde.PAC_THIRD_ACI_ID;
      vInsertDcd.PAC_THIRD_DELIVERY_ID         := tplCopyPde.PAC_THIRD_DELIVERY_ID;
      vInsertDcd.PAC_THIRD_TARIFF_ID           := tplCopyPde.PAC_THIRD_TARIFF_ID;
      vInsertDcd.DOC_GAUGE_ID                  := tplCopyPde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID          := tplCopyPde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID             := tplCopyPde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS              := tplCopyPde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID      := tplCopyPde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY               := tplCopyPde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY        := tplCopyPde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY               := tplCopyPde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY        := tplCopyPde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY            := tplCopyPde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY     := tplCopyPde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY            := tplCopyPde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY          := tplCopyPde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT   := tplCopyPde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU         := tplCopyPde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU  := tplCopyPde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU         := tplCopyPde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY         := tplCopyPde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE            := tplCopyPde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT         := tplCopyPde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                 := tplCopyPde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                 := tplCopyPde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                 := tplCopyPde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                    := tplCopyPde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                    := tplCopyPde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                    := tplCopyPde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                    := tplCopyPde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                    := tplCopyPde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                    := tplCopyPde.PDE_DATE_3;
      vInsertDcd.PDE_GENERATE_MOVEMENT         := tplCopyPde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_QUANTITY                  := tplCopyPde.DCD_QUANTITY;
      vInsertDcd.DCD_QUANTITY_SU               := tplCopyPde.DCD_QUANTITY_SU;
      vInsertDcd.DCD_BALANCE_FLAG              := tplCopyPde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR            := tplCopyPde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC       := nvl(vConvertFactorCalc, tplCopyPde.POS_CONVERT_FACTOR);
      vInsertDcd.POS_GROSS_UNIT_VALUE          := tplCopyPde.POS_GROSS_UNIT_VALUE;
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL     := tplCopyPde.POS_GROSS_UNIT_VALUE_INCL;
      vInsertDcd.POS_UNIT_OF_MEASURE_ID        := tplCopyPde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS       := tplCopyPde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.DCD_VISIBLE                   := tplCopyPde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE             := tplCopyPde.C_PDE_CREATE_MODE;
      vInsertDcd.A_DATECRE                     := tplCopyPde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                       := tplCopyPde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT              := tplCopyPde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT             := tplCopyPde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      if tplCopyPde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        dblGreatestSumQuantityCPT     := 0;
        dblGreatestSumQuantityCPT_SU  := 0;

        -- Traitement des détails de positions composants.
        for tplCopyPdeCPT in crCopyPdeCPT(vInsertDcd.DOC_POSITION_ID) loop
          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplCopyPdeCPT.POS_UTIL_COEFF, 0) = 0) then
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
          else
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, tplCopyPdeCPT.DCD_QUANTITY / tplCopyPdeCPT.POS_UTIL_COEFF);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, tplCopyPdeCPT.DCD_QUANTITY_SU / tplCopyPdeCPT.POS_UTIL_COEFF);
          end if;

          -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
          vInsertDcdCpt                               := null;
          vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplCopyPdeCPT.DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.NEW_DOCUMENT_ID               := tplCopyPdeCPT.NEW_DOCUMENT_ID;
          vInsertDcdCpt.CRG_SELECT                    := tplCopyPdeCPT.CRG_SELECT;
          vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := tplCopyPdeCPT.DOC_GAUGE_FLOW_ID;
          vInsertDcdCpt.DOC_POSITION_ID               := tplCopyPdeCPT.DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_ID           := tplCopyPdeCPT.DOC_DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := tplCopyPdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := tplCopyPdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.GCO_GOOD_ID                   := tplCopyPdeCPT.GCO_GOOD_ID;
          vInsertDcdCpt.STM_LOCATION_ID               := tplCopyPdeCPT.STM_LOCATION_ID;
          vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := tplCopyPdeCPT.GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := tplCopyPdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.STM_STM_LOCATION_ID           := tplCopyPdeCPT.STM_STM_LOCATION_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := tplCopyPdeCPT.FAL_SCHEDULE_STEP_ID;
          vInsertDcdCpt.DOC_DOCUMENT_ID               := tplCopyPdeCPT.DOC_DOCUMENT_ID;
          vInsertDcdCpt.PAC_THIRD_ID                  := tplCopyPdeCPT.PAC_THIRD_ID;
          vInsertDcdCpt.PAC_THIRD_ACI_ID              := tplCopyPdeCPT.PAC_THIRD_ACI_ID;
          vInsertDcdCpt.PAC_THIRD_DELIVERY_ID         := tplCopyPdeCPT.PAC_THIRD_DELIVERY_ID;
          vInsertDcdCpt.PAC_THIRD_TARIFF_ID           := tplCopyPdeCPT.PAC_THIRD_TARIFF_ID;
          vInsertDcdCpt.DOC_GAUGE_ID                  := tplCopyPdeCPT.DOC_GAUGE_ID;
          vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := tplCopyPdeCPT.DOC_GAUGE_RECEIPT_ID;
          vInsertDcdCpt.DOC_GAUGE_COPY_ID             := tplCopyPdeCPT.DOC_GAUGE_COPY_ID;
          vInsertDcdCpt.C_GAUGE_TYPE_POS              := tplCopyPdeCPT.C_GAUGE_TYPE_POS;
          vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := tplCopyPdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vInsertDcdCpt.PDE_BASIS_DELAY               := tplCopyPdeCPT.PDE_BASIS_DELAY;
          vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := tplCopyPdeCPT.PDE_INTERMEDIATE_DELAY;
          vInsertDcdCpt.PDE_FINAL_DELAY               := tplCopyPdeCPT.PDE_FINAL_DELAY;
          vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := tplCopyPdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vInsertDcdCpt.PDE_BASIS_QUANTITY            := tplCopyPdeCPT.PDE_BASIS_QUANTITY;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := tplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vInsertDcdCpt.PDE_FINAL_QUANTITY            := tplCopyPdeCPT.PDE_FINAL_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY          := tplCopyPdeCPT.PDE_BALANCE_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := tplCopyPdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := tplCopyPdeCPT.PDE_BASIS_QUANTITY_SU;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := tplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := tplCopyPdeCPT.PDE_FINAL_QUANTITY_SU;
          vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := tplCopyPdeCPT.PDE_MOVEMENT_QUANTITY;
          vInsertDcdCpt.PDE_MOVEMENT_VALUE            := tplCopyPdeCPT.PDE_MOVEMENT_VALUE;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := tplCopyPdeCPT.PDE_DELAY_UPDATE_TEXT;
          vInsertDcdCpt.PDE_DECIMAL_1                 := tplCopyPdeCPT.PDE_DECIMAL_1;
          vInsertDcdCpt.PDE_DECIMAL_2                 := tplCopyPdeCPT.PDE_DECIMAL_2;
          vInsertDcdCpt.PDE_DECIMAL_3                 := tplCopyPdeCPT.PDE_DECIMAL_3;
          vInsertDcdCpt.PDE_TEXT_1                    := tplCopyPdeCPT.PDE_TEXT_1;
          vInsertDcdCpt.PDE_TEXT_2                    := tplCopyPdeCPT.PDE_TEXT_2;
          vInsertDcdCpt.PDE_TEXT_3                    := tplCopyPdeCPT.PDE_TEXT_3;
          vInsertDcdCpt.PDE_DATE_1                    := tplCopyPdeCPT.PDE_DATE_1;
          vInsertDcdCpt.PDE_DATE_2                    := tplCopyPdeCPT.PDE_DATE_2;
          vInsertDcdCpt.PDE_DATE_3                    := tplCopyPdeCPT.PDE_DATE_3;
          vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := tplCopyPdeCPT.PDE_GENERATE_MOVEMENT;
          vInsertDcdCpt.DCD_QUANTITY                  := tplCopyPdeCPT.DCD_QUANTITY;
          vInsertDcdCpt.DCD_QUANTITY_SU               := tplCopyPdeCPT.DCD_QUANTITY_SU;
          vInsertDcdCpt.DCD_BALANCE_FLAG              := tplCopyPdeCPT.DCD_BALANCE_FLAG;
          vInsertDcdCpt.POS_CONVERT_FACTOR            := tplCopyPdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplCopyPdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplCopyPdeCPT.POS_GROSS_UNIT_VALUE;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplCopyPdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplCopyPdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vInsertDcdCpt.POS_UTIL_COEFF                := tplCopyPdeCPT.POS_UTIL_COEFF;
          vInsertDcdCpt.DCD_VISIBLE                   := tplCopyPdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := tplCopyPdeCPT.C_PDE_CREATE_MODE;
          vInsertDcdCpt.A_DATECRE                     := tplCopyPdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplCopyPdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplCopyPdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplCopyPdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;

        /**
        * Redéfinit la quantité du produit terminé en fonction de la quantité
        * des composants.
        *
        *   Selon la règle suivante (facture des livraisons CPT) :
        *
        *   Si toutes les quantités des composants sont à 0 alors on initialise
        *   la quantité du produit terminé avec 0, sinon on conserve la quantité
        *   initiale (quantité solde).
        */
        if (dblGreatestSumQuantityCPT = 0) then
          update DOC_POS_DET_COPY_DISCHARGE
             set DCD_QUANTITY = 0
               , DCD_QUANTITY_SU = 0
           where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
        end if;
      end if;
    end loop;
  end InsertCopyDetail;

  /**
  * procedure InsertCopieDetailDebitNote
  * Description
  *   Insertion des données de copie dans la vue V_DOC_POS_DET_COPY_DISCHARGE
  *     pour la création des positions matérialisant le litige sur la note de débit
  * @created NGV August 2008
  * @lastUpdate
  * @public
  */
  procedure InsertCopyDetailDebitNote(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDocFinalTgtID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crCopyPde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , DMT.PAC_THIRD_CDA_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , nvl(DLG.DLG_QTY, 0) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(DLG.DLG_QTY, 0) * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '218' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , DLG.DLG_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , ANewDocumentID NEW_DOCUMENT_ID
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_LITIG DLG
                    , DOC_GAUGE_POSITION GAP
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = aNewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and DMT.DOC_DOCUMENT_ID = aDocFinalTgtID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and PDE.DOC_PDE_LITIG_ID = DLG.DOC_POSITION_DETAIL_ID
                  and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID is null
                  and POS.C_DOC_POS_STATUS <> '05'
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and exists(
                        select GAP_TGT.DOC_GAUGE_POSITION_ID
                          from DOC_GAUGE_POSITION GAP_TGT
                         where GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                           and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                           and GAP_TGT.GAP_DESIGNATION = GAP.GAP_DESIGNATION)
                  and DOC_I_LIB_GAUGE.CanCopy(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplCopyPde                   crCopyPde%rowtype;

    cursor crCopyPdeCPT(cPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_DOCUMENT_ID
                    , DMT.PAC_THIRD_ID
                    , DMT.PAC_THIRD_ACI_ID
                    , DMT.PAC_THIRD_DELIVERY_ID
                    , DMT.PAC_THIRD_TARIFF_ID
                    , PDE.DOC_GAUGE_ID
                    , null DOC_GAUGE_RECEIPT_ID
                    , 0 DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , nvl(DLG.DLG_QTY, 0) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(nvl(DLG.DLG_QTY, 0) * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , '218' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , GAU.C_ADMIN_DOMAIN
                    , aNewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_LITIG DLG
                    , DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_RECORD RCO
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where DLG.DOC_POSITION_DETAIL_ID = PDE.DOC_PDE_LITIG_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and POS.DOC_DOC_POSITION_ID = cPositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplCopyPdeCPT                crCopyPdeCPT%rowtype;
    --
    vNewDcdID                    DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd                   V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt                V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc           GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    dblGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
  begin
    -- Liste des détails du document source
    for tplCopyPde in crCopyPde loop
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calculé.
      vConvertFactorCalc                       :=
        GCO_FUNCTIONS.GetThirdConvertFactor(tplCopyPde.GCO_GOOD_ID
                                          , tplCopyPde.PAC_THIRD_CDA_ID
                                          , tplCopyPde.C_GAUGE_TYPE_POS
                                          , null
                                          , tplCopyPde.TGT_PAC_THIRD_CDA_ID
                                          , tplCopyPde.TGT_C_ADMIN_DOMAIN
                                           );
      -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
      vInsertDcd                               := null;
      vInsertDcd.DOC_POSITION_DETAIL_ID        := tplCopyPde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID               := tplCopyPde.NEW_DOCUMENT_ID;
      vInsertDcd.CRG_SELECT                    := tplCopyPde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID             := tplCopyPde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID               := tplCopyPde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID           := tplCopyPde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID    := tplCopyPde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID   := tplCopyPde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                   := tplCopyPde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID               := tplCopyPde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID       := tplCopyPde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID   := tplCopyPde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID  := tplCopyPde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID           := tplCopyPde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID       := tplCopyPde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID          := tplCopyPde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_RECORD_ID                 := tplCopyPde.DOC_RECORD_ID;
      vInsertDcd.DOC_DOCUMENT_ID               := tplCopyPde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                  := tplCopyPde.PAC_THIRD_ID;
      vInsertDcd.PAC_THIRD_ACI_ID              := tplCopyPde.PAC_THIRD_ACI_ID;
      vInsertDcd.PAC_THIRD_DELIVERY_ID         := tplCopyPde.PAC_THIRD_DELIVERY_ID;
      vInsertDcd.PAC_THIRD_TARIFF_ID           := tplCopyPde.PAC_THIRD_TARIFF_ID;
      vInsertDcd.DOC_GAUGE_ID                  := tplCopyPde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID          := tplCopyPde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID             := tplCopyPde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS              := tplCopyPde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID      := tplCopyPde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY               := tplCopyPde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY        := tplCopyPde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY               := tplCopyPde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY        := tplCopyPde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY            := tplCopyPde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY     := tplCopyPde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY            := tplCopyPde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY          := tplCopyPde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT   := tplCopyPde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU         := tplCopyPde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU  := tplCopyPde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU         := tplCopyPde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY         := tplCopyPde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE            := tplCopyPde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5  := tplCopyPde.PDE_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT         := tplCopyPde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                 := tplCopyPde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                 := tplCopyPde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                 := tplCopyPde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                    := tplCopyPde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                    := tplCopyPde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                    := tplCopyPde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                    := tplCopyPde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                    := tplCopyPde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                    := tplCopyPde.PDE_DATE_3;
      vInsertDcd.PDE_GENERATE_MOVEMENT         := tplCopyPde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_QUANTITY                  := tplCopyPde.DCD_QUANTITY;
      vInsertDcd.DCD_QUANTITY_SU               := tplCopyPde.DCD_QUANTITY_SU;
      vInsertDcd.DCD_BALANCE_FLAG              := tplCopyPde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR            := tplCopyPde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC       := nvl(vConvertFactorCalc, tplCopyPde.POS_CONVERT_FACTOR);
      vInsertDcd.POS_GROSS_UNIT_VALUE          := nvl(tplCopyPde.DLG_UNIT_VALUE, tplCopyPde.POS_GROSS_UNIT_VALUE);
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL     := nvl(tplCopyPde.DLG_UNIT_VALUE, tplCopyPde.POS_GROSS_UNIT_VALUE_INCL);
      vInsertDcd.POS_UNIT_OF_MEASURE_ID        := tplCopyPde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS       := tplCopyPde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.DCD_VISIBLE                   := tplCopyPde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE             := tplCopyPde.C_PDE_CREATE_MODE;
      vInsertDcd.A_DATECRE                     := tplCopyPde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                       := tplCopyPde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT              := tplCopyPde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT             := tplCopyPde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      if tplCopyPde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        dblGreatestSumQuantityCPT     := 0;
        dblGreatestSumQuantityCPT_SU  := 0;

        -- Traitement des détails de positions composants.
        for tplCopyPdeCPT in crCopyPdeCPT(vInsertDcd.DOC_POSITION_ID) loop
          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplCopyPdeCPT.POS_UTIL_COEFF, 0) = 0) then
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
          else
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, tplCopyPdeCPT.DCD_QUANTITY / tplCopyPdeCPT.POS_UTIL_COEFF);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, tplCopyPdeCPT.DCD_QUANTITY_SU / tplCopyPdeCPT.POS_UTIL_COEFF);
          end if;

          -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
          vInsertDcdCpt                               := null;
          vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplCopyPdeCPT.DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.NEW_DOCUMENT_ID               := tplCopyPdeCPT.NEW_DOCUMENT_ID;
          vInsertDcdCpt.CRG_SELECT                    := tplCopyPdeCPT.CRG_SELECT;
          vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := tplCopyPdeCPT.DOC_GAUGE_FLOW_ID;
          vInsertDcdCpt.DOC_POSITION_ID               := tplCopyPdeCPT.DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_ID           := tplCopyPdeCPT.DOC_DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := tplCopyPdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := tplCopyPdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.GCO_GOOD_ID                   := tplCopyPdeCPT.GCO_GOOD_ID;
          vInsertDcdCpt.STM_LOCATION_ID               := tplCopyPdeCPT.STM_LOCATION_ID;
          vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := tplCopyPdeCPT.GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := tplCopyPdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := tplCopyPdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.STM_STM_LOCATION_ID           := tplCopyPdeCPT.STM_STM_LOCATION_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := tplCopyPdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := tplCopyPdeCPT.FAL_SCHEDULE_STEP_ID;
          vInsertDcdCpt.DOC_DOCUMENT_ID               := tplCopyPdeCPT.DOC_DOCUMENT_ID;
          vInsertDcdCpt.PAC_THIRD_ID                  := tplCopyPdeCPT.PAC_THIRD_ID;
          vInsertDcdCpt.PAC_THIRD_ACI_ID              := tplCopyPdeCPT.PAC_THIRD_ACI_ID;
          vInsertDcdCpt.PAC_THIRD_DELIVERY_ID         := tplCopyPdeCPT.PAC_THIRD_DELIVERY_ID;
          vInsertDcdCpt.PAC_THIRD_TARIFF_ID           := tplCopyPdeCPT.PAC_THIRD_TARIFF_ID;
          vInsertDcdCpt.DOC_GAUGE_ID                  := tplCopyPdeCPT.DOC_GAUGE_ID;
          vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := tplCopyPdeCPT.DOC_GAUGE_RECEIPT_ID;
          vInsertDcdCpt.DOC_GAUGE_COPY_ID             := tplCopyPdeCPT.DOC_GAUGE_COPY_ID;
          vInsertDcdCpt.C_GAUGE_TYPE_POS              := tplCopyPdeCPT.C_GAUGE_TYPE_POS;
          vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := tplCopyPdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vInsertDcdCpt.PDE_BASIS_DELAY               := tplCopyPdeCPT.PDE_BASIS_DELAY;
          vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := tplCopyPdeCPT.PDE_INTERMEDIATE_DELAY;
          vInsertDcdCpt.PDE_FINAL_DELAY               := tplCopyPdeCPT.PDE_FINAL_DELAY;
          vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := tplCopyPdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vInsertDcdCpt.PDE_BASIS_QUANTITY            := tplCopyPdeCPT.PDE_BASIS_QUANTITY;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := tplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vInsertDcdCpt.PDE_FINAL_QUANTITY            := tplCopyPdeCPT.PDE_FINAL_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY          := tplCopyPdeCPT.PDE_BALANCE_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := tplCopyPdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := tplCopyPdeCPT.PDE_BASIS_QUANTITY_SU;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := tplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := tplCopyPdeCPT.PDE_FINAL_QUANTITY_SU;
          vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := tplCopyPdeCPT.PDE_MOVEMENT_QUANTITY;
          vInsertDcdCpt.PDE_MOVEMENT_VALUE            := tplCopyPdeCPT.PDE_MOVEMENT_VALUE;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := tplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := tplCopyPdeCPT.PDE_DELAY_UPDATE_TEXT;
          vInsertDcdCpt.PDE_DECIMAL_1                 := tplCopyPdeCPT.PDE_DECIMAL_1;
          vInsertDcdCpt.PDE_DECIMAL_2                 := tplCopyPdeCPT.PDE_DECIMAL_2;
          vInsertDcdCpt.PDE_DECIMAL_3                 := tplCopyPdeCPT.PDE_DECIMAL_3;
          vInsertDcdCpt.PDE_TEXT_1                    := tplCopyPdeCPT.PDE_TEXT_1;
          vInsertDcdCpt.PDE_TEXT_2                    := tplCopyPdeCPT.PDE_TEXT_2;
          vInsertDcdCpt.PDE_TEXT_3                    := tplCopyPdeCPT.PDE_TEXT_3;
          vInsertDcdCpt.PDE_DATE_1                    := tplCopyPdeCPT.PDE_DATE_1;
          vInsertDcdCpt.PDE_DATE_2                    := tplCopyPdeCPT.PDE_DATE_2;
          vInsertDcdCpt.PDE_DATE_3                    := tplCopyPdeCPT.PDE_DATE_3;
          vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := tplCopyPdeCPT.PDE_GENERATE_MOVEMENT;
          vInsertDcdCpt.DCD_QUANTITY                  := tplCopyPdeCPT.DCD_QUANTITY;
          vInsertDcdCpt.DCD_QUANTITY_SU               := tplCopyPdeCPT.DCD_QUANTITY_SU;
          vInsertDcdCpt.DCD_BALANCE_FLAG              := tplCopyPdeCPT.DCD_BALANCE_FLAG;
          vInsertDcdCpt.POS_CONVERT_FACTOR            := tplCopyPdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplCopyPdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplCopyPdeCPT.POS_GROSS_UNIT_VALUE;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplCopyPdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplCopyPdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vInsertDcdCpt.POS_UTIL_COEFF                := tplCopyPdeCPT.POS_UTIL_COEFF;
          vInsertDcdCpt.DCD_VISIBLE                   := tplCopyPdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := tplCopyPdeCPT.C_PDE_CREATE_MODE;
          vInsertDcdCpt.A_DATECRE                     := tplCopyPdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplCopyPdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplCopyPdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplCopyPdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;

        /**
        * Redéfinit la quantité du produit terminé en fonction de la quantité
        * des composants.
        *
        *   Selon la règle suivante (facture des livraisons CPT) :
        *
        *   Si toutes les quantités des composants sont à 0 alors on initialise
        *   la quantité du produit terminé avec 0, sinon on conserve la quantité
        *   initiale (quantité solde).
        */
        if (dblGreatestSumQuantityCPT = 0) then
          update DOC_POS_DET_COPY_DISCHARGE
             set DCD_QUANTITY = 0
               , DCD_QUANTITY_SU = 0
           where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
        end if;
      end if;
    end loop;
  end InsertCopyDetailDebitNote;

  procedure UpdateLitigFinalPdeID(aLitigID in DOC_LITIG.DOC_LITIG_ID%type, aDetailFinalID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
  begin
    update DOC_LITIG
       set DOC_PDE_FINAL_ID = aDetailFinalID
         , DLG_BALANCE_QTY = DLG_BALANCE_QTY - (select PDE_BASIS_QUANTITY
                                                  from DOC_POSITION_DETAIL
                                                 where DOC_POSITION_DETAIL_ID = aDetailFinalID)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_LITIG_ID = aLitigID;
  end UpdateLitigFinalPdeID;

  /**
  * procedure InsertLitigOnCopyDischarge
  * Description
  *   Insertion des données de litige dans la table DOC_LITIG_PROCESS pour la
  *     phase de copie/décharge du document final cible. Ces données seront
  *     disponnibles lors de l'interface de copie/décharge et l'utilisateur
  *     aura le choix s'il veut ou pas que les positions de type litige "21"
  *     soient crées sur le document final cible
  * @created NGV August 2008
  * @lastUpdate
  * @public
  * @param aNewDocumentId   : Id du nouveau document - document final cible
  * @param aMode            : '1' - Décharge ou '2' - Copie
  */
  procedure InsertLitigOnCopyDischarge(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aMode in varchar2 default '1')
  is
  begin
    delete from DOC_LITIG_PROCESS
          where DLP_DOC_FINAL_SRC_ID = aNewDocumentID
            and DLP_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID;

    insert into DOC_LITIG_PROCESS
                (DOC_LITIG_PROCESS_ID
               , DOC_LITIG_ID
               , DLP_DOC_FINAL_SRC_ID
               , DOC_POSITION_DETAIL_ID
               , GCO_GOOD_ID
               , DLP_SELECTION
               , DLP_QTY
               , DIC_LITIG_TYPE_ID
               , DLP_UNIT_VALUE
               , DLP_ACCEPTED_QTY
               , DLP_REFUSED_QTY
               , DLP_REFUSED_TEXT
               , DLP_COMMENT
               , DLP_SESSION_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval as DOC_LITIG_PROCESS_ID
           , DLG.DOC_LITIG_ID
           , aNewDocumentID as DLP_DOC_FINAL_SRC_ID
           , PDE.DOC_POSITION_DETAIL_ID
           , PDE_LTG.GCO_GOOD_ID
           , 1 as DLP_SELECTION
           , DLG.DLG_QTY
           , DLG.DIC_LITIG_TYPE_ID
           , DLG.DLG_UNIT_VALUE
           , DLG.DLG_ACCEPTED_QTY
           , DLG.DLG_REFUSED_QTY
           , DLG.DLG_REFUSED_TEXT
           , DLG.DLG_COMMENT
           , DBMS_SESSION.UNIQUE_SESSION_ID as DLP_SESSION_ID
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from DOC_POS_DET_COPY_DISCHARGE DCD
           , DOC_POSITION_DETAIL PDE
           , DOC_DOCUMENT DMT
           , DOC_LITIG DLG
           , DOC_POSITION_DETAIL PDE_LTG
           , DOC_LITIG_CONTEXT DLX
           , DOC_DOCUMENT DMT_TGT
       where DCD.NEW_DOCUMENT_ID = aNewDocumentID
         and DCD.NEW_DOCUMENT_ID = DMT_TGT.DOC_DOCUMENT_ID
         and DCD.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
         and PDE.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and PDE.DOC_PDE_LITIG_ID = DLG.DOC_POSITION_DETAIL_ID
         and DLG.DOC_PDE_FINAL_ID is null
         and DLG.DOC_POSITION_DETAIL_ID = PDE_LTG.DOC_POSITION_DETAIL_ID
         and DLG.DOC_LITIG_CONTEXT_ID = DLX.DOC_LITIG_CONTEXT_ID
         and DLX.DLX_GAU_FINAL_SRC_ID = DMT.DOC_GAUGE_ID
         and DLX.DLX_GAU_FINAL_TGT_ID = DMT_TGT.DOC_GAUGE_ID
         and DLX.C_DLX_FINAL_GAUGE_LINK = aMode;
  end InsertLitigOnCopyDischarge;

  /**
  * function CheckContextFlow
  * Description
  *   Vérification des liens de copie/décharge entre les divers gabarits d'un contexte
  */
  function CheckContextFlow(aContextID in DOC_LITIG_CONTEXT.DOC_LITIG_CONTEXT_ID%type)
    return varchar2
  is
    cursor crContext
    is
      select DLX_GAU_START_SRC_ID
           , DLX_GAU_START_TGT_ID
           , case
               when C_DLX_START_GAUGE_LINK = '1' then 1
               else 0
             end START_LINK
           , DLX_GAU_RECEPT_ID
           , DLX_GAU_RECEPT_SUPPLY_ID
           , DLX_GAU_DEBIT_NOTE_ID
           , DLX_GAU_FIN_DEBIT_NOTE_ID
           , DLX_GAU_TRASH_ID
           , DLX_GAU_TRASH_SUPPLY_ID
           , DLX_GAU_FINAL_SRC_ID
           , DLX_GAU_FINAL_TGT_ID
           , case
               when C_DLX_FINAL_GAUGE_LINK = '1' then 1
               else 0
             end FINAL_LINK
           , 1 DISCHARGE_LINK
           , 0 COPY_LINK
        from DOC_LITIG_CONTEXT
       where DOC_LITIG_CONTEXT_ID = aContextID;

    tplContext        crContext%rowtype;
    vCount            integer;
    vMsg              varchar2(32000)     default null;
    vStartFlow        varchar2(32000)     default null;
    vFinalFlow        varchar2(32000)     default null;
    vReceptFlow       varchar2(32000)     default null;
    vReceptSupplyFlow varchar2(32000)     default null;
    vTrashFlow        varchar2(32000)     default null;
    vTrashSupplyFlow  varchar2(32000)     default null;
    vDebitNoteFlow    varchar2(32000)     default null;
    vFinDebitNoteFlow varchar2(32000)     default null;
  begin
    open crContext;

    fetch crContext
     into tplContext;

    if crContext%found then
      -- Recherche des flux copie/décharge entre gabarit initial source et cible
      vStartFlow  :=
        DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_START_SRC_ID
                                 , iGaugeDst      => tplContext.DLX_GAU_START_TGT_ID
                                 , iReceiptLink   => tplContext.START_LINK
                                  );

      -- Vérifier s'il y a au moins un flux de copie/décharge entre le gabarit initial source et cible
      select count(*)
        into vCount
        from (select column_value DOC_GAUGE_FLOW_ID
                from table(idListToTable(vStartFlow) ) );

      -- Pas de flux de copie/décharge entre le gabarit initial source et cible
      if vCount = 0 then
        vMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de copie/décharge entre le gabarit suivants :') ||
          co.cLineBreak ||
          PCS.PC_FUNCTIONS.TranslateWord('Gabarit initial source - Gabarit initial cible');
      end if;

      -- Recherche des flux copie/décharge entre gabarit final source et cible
      vFinalFlow  :=
        DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_FINAL_SRC_ID
                                 , iGaugeDst      => tplContext.DLX_GAU_FINAL_TGT_ID
                                 , iReceiptLink   => tplContext.FINAL_LINK
                                  );

      -- Vérifier s'il y a au moins un flux de copie/décharge entre le gabarit final source et cible
      select count(*)
        into vCount
        from (select column_value DOC_GAUGE_FLOW_ID
                from table(idListToTable(vFinalFlow) ) );

      -- Pas de flux de copie/décharge entre le gabarit final source et cible
      if vCount = 0 then
        vMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de copie/décharge entre le gabarit suivants :') ||
          co.cLineBreak ||
          PCS.PC_FUNCTIONS.TranslateWord('Gabarit final source - Gabarit final cible');
      end if;

      -- Vérifier s'il y a au moins un flux en commun entre les gabarits initiaux et les finaux
      select count(*)
        into vCount
        from (select column_value DOC_GAUGE_FLOW_ID
                from table(idListToTable(vStartFlow) ) ) STR
           , (select column_value DOC_GAUGE_FLOW_ID
                from table(idListToTable(vFinalFlow) ) ) FIN
       where STR.DOC_GAUGE_FLOW_ID = FIN.DOC_GAUGE_FLOW_ID;

      -- Pas de flux de copie/décharge en commun entre les gabarits initiaux et les finaux
      if vCount = 0 then
        vMsg  := PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de copie/décharge en commun entre les gabarits initiaux et les finaux !');
      end if;

      -- Recherche des flux décharge entre gabarit initial source et le retour
      if tplContext.DLX_GAU_RECEPT_ID is not null then
        vReceptFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_START_SRC_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_RECEPT_ID
                                   , iReceiptLink   => tplContext.DISCHARGE_LINK
                                    );

        -- Vérifier s'il y a au moins un flux de décharge entre le gabarit initial source et le retour
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vReceptFlow) ) );

        -- Pas de flux de décharge entre le gabarit initial source et le retour
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de décharge entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit initial source - Gabarit retour (sans appro)');
        end if;
      end if;

      -- Recherche des flux décharge entre gabarit initial source et le retour avec appro
      if tplContext.DLX_GAU_RECEPT_SUPPLY_ID is not null then
        vReceptSupplyFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_START_SRC_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_RECEPT_SUPPLY_ID
                                   , iReceiptLink   => tplContext.DISCHARGE_LINK
                                    );

        -- Vérifier s'il y a au moins un flux de décharge entre le gabarit initial source et le retour avec appro
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vReceptSupplyFlow) ) );

        -- Pas de flux de décharge entre le gabarit initial source et le retour avec appro
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de décharge entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit initial source - Gabarit retour (avec appro)');
        end if;
      end if;

      -- Recherche des flux décharge entre gabarit initial source et le transfert déchets
      if tplContext.DLX_GAU_TRASH_ID is not null then
        vTrashFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_START_SRC_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_TRASH_ID
                                   , iReceiptLink   => tplContext.DISCHARGE_LINK
                                    );

        -- Vérifier s'il y a au moins un flux de décharge entre le gabarit initial source et le transfert déchets
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vTrashFlow) ) );

        -- Pas de flux de décharge entre le gabarit initial source et le transfert déchets
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de décharge entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit initial source - Gabarit transfert en déchets (sans appro)');
        end if;
      end if;

      -- Recherche des flux décharge entre gabarit initial source et le transfert déchets avec appro
      if tplContext.DLX_GAU_TRASH_SUPPLY_ID is not null then
        vTrashSupplyFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_START_SRC_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_TRASH_SUPPLY_ID
                                   , iReceiptLink   => tplContext.DISCHARGE_LINK
                                    );

        -- Vérifier s'il y a au moins un flux de décharge entre le gabarit initial source et le transfert déchets avec appro
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vTrashSupplyFlow) ) );

        -- Pas de flux de décharge entre le gabarit initial source et le transfert déchets avec appro
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de décharge entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit initial source - Gabarit transfert en déchets (avec appro)');
        end if;
      end if;

      -- Recherche des flux copie entre gabarit final cible et la note de débit
      if tplContext.DLX_GAU_DEBIT_NOTE_ID is not null then
        vDebitNoteFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_FINAL_TGT_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_DEBIT_NOTE_ID
                                   , iReceiptLink   => tplContext.COPY_LINK
                                    );

        -- Vérifier s'il y a au moins un flux copie entre gabarit final cible et la note de débit
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vDebitNoteFlow) ) );

        -- Pas de flux copie entre gabarit final cible et la note de débit
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de copie entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit final cible - Gabarit note de débit');
        end if;
      end if;

      -- Recherche des flux copie entre gabarit final cible et la note de débit financière
      if tplContext.DLX_GAU_FIN_DEBIT_NOTE_ID is not null then
        vFinDebitNoteFlow  :=
          DOC_I_LIB_GAUGE.GetAllFlow(iGaugeSrc      => tplContext.DLX_GAU_FINAL_TGT_ID
                                   , iGaugeDst      => tplContext.DLX_GAU_FIN_DEBIT_NOTE_ID
                                   , iReceiptLink   => tplContext.COPY_LINK
                                    );

        -- Vérifier s'il y a au moins un flux copie entre gabarit final cible et la note de débit financière
        select count(*)
          into vCount
          from (select column_value DOC_GAUGE_FLOW_ID
                  from table(idListToTable(vFinDebitNoteFlow) ) );

        -- Pas de flux copie entre gabarit final cible et la note de débit financière
        if vCount = 0 then
          vMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de flux de copie entre les gabarits suivants :') ||
            co.cLineBreak ||
            PCS.PC_FUNCTIONS.TranslateWord('Gabarit final cible - Gabarit note de débit financière');
        end if;
      end if;
    end if;

    close crContext;

    return vMsg;
  end CheckContextFlow;

  /**
  * procesure UpdateLitigDetailLink
  * Description
  *   Effectue la màj du lien entre le litige et le document généré
  */
  procedure UpdateLitigDetailLink(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aLinkField in varchar2)
  is
  begin
    -- Effectuer la màj des liens entre les litiges et le détail du document généré
    for tplLitig in (select   DLG.DOC_LITIG_ID
                            , PDE.DOC_POSITION_DETAIL_ID
                         from DOC_LITIG DLG
                            , DOC_POSITION_DETAIL PDE
                        where PDE.DOC_DOCUMENT_ID = aNewDocumentID
                          and PDE.DOC_PDE_LITIG_ID = DLG.DOC_POSITION_DETAIL_ID
                     order by 1) loop
      update DOC_LITIG
         set DOC_PDE_DEBIT_NOTE_ID = case
                                      when aLinkField in('DEBIT_NOTE', 'FIN_DEBIT_NOTE') then tplLitig.DOC_POSITION_DETAIL_ID
                                      else DOC_PDE_DEBIT_NOTE_ID
                                    end
           , DOC_PDE_RECEPT_ID = case
                                  when aLinkField in('RECEPT', 'RECEPT_SUPPLY') then tplLitig.DOC_POSITION_DETAIL_ID
                                  else DOC_PDE_RECEPT_ID
                                end
           , DOC_PDE_TRASH_ID = case
                                 when aLinkField in('TRASH', 'TRASH_SUPPLY') then tplLitig.DOC_POSITION_DETAIL_ID
                                 else DOC_PDE_TRASH_ID
                               end
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_LITIG_ID = tplLitig.DOC_LITIG_ID;
    end loop;
  end UpdateLitigDetailLink;
end DOC_LITIG_FUNCTIONS;
