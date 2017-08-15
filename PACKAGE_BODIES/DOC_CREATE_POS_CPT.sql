--------------------------------------------------------
--  DDL for Package Body DOC_CREATE_POS_CPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_CREATE_POS_CPT" 
as
  /**
  * Procedure LoadNomenclatureCPT
  * Description
  *   Chargement de la table DOC-TMP_POSITION_DETAIL avec les données
  *     nécéssaires à la création de positions CPT (71,81,91,101)
  */
  procedure LoadNomenclatureCPT(
    aNomenclatureID   in PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type
  , aDocumentID       in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPTPositionID     in DOC_POSITION.DOC_POSITION_ID%type
  , aRecordID         in DOC_POSITION.DOC_RECORD_ID%type
  , aRepresentativeID in DOC_POSITION.PAC_REPRESENTATIVE_ID%type
  , aGaugeTypePos     in DOC_POSITION.C_GAUGE_TYPE_POS%type
  , aPTBasisQty       in DOC_POSITION.POS_BASIS_QUANTITY%type
  )
  is
    aCptSequence number;
  begin
    -- Effacer les données de la table temp
    DeleteSessionInfo;
    aCptSequence  := 0;
    -- Créér les positions dans la table temp selon les composants de la nomenclature
    GenerateCPTStructure(aNomenclatureID     => aNomenclatureID
                       , aDocumentID         => aDocumentID
                       , aPTPositionID       => aPTPositionID
                       , aRecordID           => aRecordID
                       , aRepresentativeID   => aRepresentativeID
                       , aGaugeTypePos       => aGaugeTypePos
                       , aPTBasisQty         => aPTBasisQTY
                       , aCptSequence        => aCptSequence
                        );
  end LoadNomenclatureCPT;

  /**
  * Procedure DeleteSessionInfo
  * Description
  *   Efface les données de la table DOC_TMP_POSITION_DETAIL pour la session courante
  */
  procedure DeleteSessionInfo
  is
  begin
    delete from DOC_TMP_POSITION_DETAIL
          where DTP_SESSION_ID = userenv('SESSIONID');
  end DeleteSessionInfo;

  /**
  * Procedure GenerateCPTStructure
  * Description
  *   Génération d'une structure des positions composants dans la table
  *     DOC_TMP_POSITION_DETAIL pour la création de positions CPT (71,81,91,101)
  */
  procedure GenerateCPTStructure(
    aNomenclatureID   in     PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type
  , aDocumentID       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPTPositionID     in     DOC_POSITION.DOC_POSITION_ID%type
  , aRecordID         in     DOC_POSITION.DOC_RECORD_ID%type
  , aRepresentativeID in     DOC_POSITION.PAC_REPRESENTATIVE_ID%type
  , aGaugeTypePos     in     DOC_POSITION.C_GAUGE_TYPE_POS%type
  , aPTBasisQty       in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , aCoeffMultiply    in     number default 1
  , aCptSequence      in out number
  )
  is
    -- Curseur sur les composants de la nomenclature
    cursor crComponents(cNomenclatureID in PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type)
    is
      select   COM_SEQ
             , COM_UTIL_COEFF
             , GCO_GOOD_ID
             , STM_LOCATION_ID
             , C_KIND_COM
             , PPS_PPS_NOMENCLATURE_ID
             , PPS_NOM_BOND_ID
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = cNomenclatureID
           and C_TYPE_COM = '1'
      order by COM_SEQ;

    tplComponents  crComponents%rowtype;
    NomenclatureID PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type;
    vVersion       PPS_NOMENCLATURE.NOM_VERSION%type;
  begin
    open crComponents(aNomenclatureID);

    fetch crComponents
     into tplComponents;

    while crComponents%found loop
      -- Composant de type "Composant"
      if tplComponents.C_KIND_COM = '1' then
        aCptSequence  := aCptSequence + 10;

        -- Inserer la ligne pour le composant courant dans la table temp
        insert into DOC_TMP_POSITION_DETAIL
                    (DTP_SESSION_ID
                   , DOC_DOCUMENT_ID
                   , DOC_POSITION_ID
                   , DOC_POSITION_DETAIL_ID
                   , CRG_SELECT
                   , DTP_SEQ
                   , DTP_UTIL_COEF
                   , GCO_GOOD_ID
                   , STM_LOCATION_ID
                   , DOC_DOC_POSITION_ID
                   , DOC_RECORD_ID
                   , PAC_REPRESENTATIVE_ID
                   , C_GAUGE_TYPE_POS
                   , POS_BASIS_QTY_PT
                   , PPS_NOM_BOND_ID
                    )
             values (userenv('SESSIONID')
                   , aDocumentID
                   , Init_ID_SEQ.nextval
                   , Init_ID_SEQ.nextval
                   , 1
                   , aCptSequence
                   , tplComponents.COM_UTIL_COEFF * aCoeffMultiply
                   , tplComponents.GCO_GOOD_ID
                   , tplComponents.STM_LOCATION_ID
                   , aPTPositionID
                   , aRecordID
                   , aRepresentativeID
                   , aGaugeTypePos
                   , aPTBasisQty
                   , tplComponents.PPS_NOM_BOND_ID
                    );
      -- Composant de type "Pseudo"
      elsif tplComponents.C_KIND_COM = '3' then
        -- Rechercher les composants de la nomenclature du composants courant

        -- Utiliser la nomenclature définie dans le composant en cours
        if tplComponents.PPS_PPS_NOMENCLATURE_ID is not null then
          NomenclatureID  := tplComponents.PPS_PPS_NOMENCLATURE_ID;
        else
          -- Recherche la nomenclature à utiliser en fonction de la configuration DOC_INITIAL_NOM_VERSION
          NomenclatureID  := DOC_POSITION_FUNCTIONS.GetInitialNomenclature(tplComponents.GCO_GOOD_ID);
        end if;

        -- Génerer les CPT si le composant en cours possède une nomenclature
        if NomenclatureID is not null then
          GenerateCPTStructure(NomenclatureID
                             , aDocumentID
                             , aPTPositionID
                             , aRecordID
                             , aRepresentativeID
                             , aGaugeTypePos
                             , aPTBasisQty
                             , tplComponents.COM_UTIL_COEFF
                             , aCptSequence
                              );
        end if;
      end if;

      -- Composant suivant
      fetch crComponents
       into tplComponents;
    end loop;

    close crComponents;
  end GenerateCPTStructure;

  /**
  * Procedure GeneratePositionCPT
  * Description
  *   Création des position CPT (71,81,91,101) depuis la table DOC_TMP_POSITION_DETAIL
  */
  procedure GeneratePositionCPT
  is
    cursor crPositionCPT
    is
      select   TMP.DOC_DOCUMENT_ID
             , TMP.DOC_POSITION_ID
             , TMP.DOC_POSITION_DETAIL_ID
             , TMP.DTP_UTIL_COEF
             , TMP.DTP_SEQ
             , TMP.GCO_GOOD_ID
             , decode(TMP.STM_LOCATION_ID, 0, null, TMP.STM_LOCATION_ID) STM_LOCATION_ID
             , TMP.DOC_DOC_POSITION_ID
             , decode(TMP.DOC_RECORD_ID, 0, null, TMP.DOC_RECORD_ID) DOC_RECORD_ID
             , decode(TMP.PAC_REPRESENTATIVE_ID, 0, null, TMP.PAC_REPRESENTATIVE_ID) PAC_REPRESENTATIVE_ID
             , TMP.POS_BASIS_QTY_PT
             , TMP.POS_BODY_TEXT
             , LOC.STM_STOCK_ID
             , decode(GAP_CPT.DOC_GAUGE_POSITION_ID, null, TMP.C_GAUGE_TYPE_POS, GAP_CPT.C_GAUGE_TYPE_POS) C_GAUGE_TYPE_POS
             , GAP_CPT.DOC_GAUGE_POSITION_ID
          from DOC_TMP_POSITION_DETAIL TMP
             , STM_LOCATION LOC
             , DOC_POSITION POS_PT
             , DOC_GAUGE_POSITION GAP_PT
             , DOC_GAUGE_POSITION GAP_CPT
         where TMP.DTP_SESSION_ID = userenv('SESSIONID')
           and TMP.CRG_SELECT = 1
           and TMP.STM_LOCATION_ID = LOC.STM_LOCATION_ID(+)
           and POS_PT.DOC_POSITION_ID = TMP.DOC_DOC_POSITION_ID
           and GAP_PT.DOC_GAUGE_POSITION_ID = POS_PT.DOC_GAUGE_POSITION_ID
           and GAP_CPT.DOC_GAUGE_POSITION_ID(+) = GAP_PT.DOC_DOC_GAUGE_POSITION_ID
      order by TMP.DTP_SEQ;

    tplPositionCPT crPositionCPT%rowtype;
  begin
    open crPositionCPT;

    fetch crPositionCPT
     into tplPositionCPT;

    while crPositionCPT%found loop
      -- Recherche l'ID réel du gabarit position. Pour le cas d'une position composant,
      -- il faut rechercher l'éventuelle gabarit position lié inscrit sur son produit
      -- terminé.

      -- Effacer les données de la variable
      DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      -- La variable ne doit pas être réinitialisée dans la méthode de création
      DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO  := 0;
      -- ID de l'extraction de commission
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF       := tplPositionCPT.DTP_UTIL_COEF;
      -- Création de la position composant
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID         => tplPositionCPT.DOC_POSITION_ID
                                           , aDocumentID         => tplPositionCPT.DOC_DOCUMENT_ID
                                           , aPosCreateMode      => '100'
                                           , aTypePos            => tplPositionCPT.C_GAUGE_TYPE_POS
                                           , aGapID              => tplPositionCPT.DOC_GAUGE_POSITION_ID
                                           , aGoodID             => tplPositionCPT.GCO_GOOD_ID
                                           , aPTPositionID       => tplPositionCPT.DOC_DOC_POSITION_ID
                                           , aBasisQuantity      => tplPositionCPT.POS_BASIS_QTY_PT
                                           , aRecordID           => tplPositionCPT.DOC_RECORD_ID
                                           , aRepresentativeID   => tplPositionCPT.PAC_REPRESENTATIVE_ID
                                           , aStockID            => tplPositionCPT.STM_STOCK_ID
                                           , aLocationID         => tplPositionCPT.STM_LOCATION_ID
                                           , aPosBodyText        => tplPositionCPT.POS_BODY_TEXT
                                           , aGenerateDetail     => 0
                                            );

      -- position suivante
      fetch crPositionCPT
       into tplPositionCPT;
    end loop;

    close crPositionCPT;

    -- Effacer les données de la table temp
    DeleteSessionInfo;
  end GeneratePositionCPT;
end DOC_CREATE_POS_CPT;
