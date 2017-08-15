--------------------------------------------------------
--  DDL for Package Body ASA_TRACABILITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_TRACABILITY" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Teste si le produit est concerné par la traçabilité
  */
  function isTracable(aGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    vTraceChar number;
  begin
    -- produit avec au moins une caractérisation "traçable" (non-morphologique)
    select sign(count(*) )
      into vTraceChar
      from GCO_CHARACTERIZATION CHA
     where CHA.GCO_GOOD_ID = aGoodID
       and C_CHARACT_TYPE <> '2'
       and CHA.CHA_STOCK_MANAGEMENT = 1;

    return vTraceChar;
  end isTracable;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Ajout de la donnée de§ traçabilité
  */
  procedure AddTracability(
    aASA_RECORD_ID         in ASA_RECORD.ASA_RECORD_ID%type
  , aGCO_GOOD_ID           in GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID       in GCO_GOOD.GCO_GOOD_ID%type default null
  , aHIS_PT_PIECE          in FAL_TRACABILITY.HIS_PT_PIECE%type
  , aHIS_PT_LOT            in FAL_TRACABILITY.HIS_PT_LOT%type
  , aHIS_PT_VERSION        in FAL_TRACABILITY.HIS_PT_VERSION%type
  , aHIS_CHRONOLOGY_PT     in FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type
  , aHIS_PT_STD_CHAR_1     in FAL_TRACABILITY.HIS_PT_STD_CHAR_1%type
  , aHIS_PT_STD_CHAR_2     in FAL_TRACABILITY.HIS_PT_STD_CHAR_2%type
  , aHIS_PT_STD_CHAR_3     in FAL_TRACABILITY.HIS_PT_STD_CHAR_3%type
  , aHIS_PT_STD_CHAR_4     in FAL_TRACABILITY.HIS_PT_STD_CHAR_4%type
  , aHIS_PT_STD_CHAR_5     in FAL_TRACABILITY.HIS_PT_STD_CHAR_5%type
  , aHIS_CPT_PIECE         in FAL_TRACABILITY.HIS_CPT_PIECE%type
  , aHIS_CPT_LOT           in FAL_TRACABILITY.HIS_CPT_LOT%type
  , aHIS_CPT_VERSION       in FAL_TRACABILITY.HIS_CPT_VERSION%type
  , aHIS_CHRONOLOGY_CPT    in FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%type
  , aHIS_CPT_STD_CHAR_1    in FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%type
  , aHIS_CPT_STD_CHAR_2    in FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%type
  , aHIS_CPT_STD_CHAR_3    in FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%type
  , aHIS_CPT_STD_CHAR_4    in FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%type
  , aHIS_CPT_STD_CHAR_5    in FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%type
  , aSTM_STOCK_MOVEMENT_ID in FAL_TRACABILITY.STM_STOCK_MOVEMENT_ID%type default null
  , aHIS_QTY               in FAL_TRACABILITY.HIS_QTY%type
  )
  is
  begin
    insert into FAL_TRACABILITY
                (FAL_TRACABILITY_ID
               , C_TRACABILITY_SOURCE
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , ASA_RECORD_ID
               , HIS_PT_PIECE
               , HIS_PT_LOT
               , HIS_PT_VERSION
               , HIS_CHRONOLOGY_PT
               , HIS_PT_STD_CHAR_1
               , HIS_PT_STD_CHAR_2
               , HIS_PT_STD_CHAR_3
               , HIS_PT_STD_CHAR_4
               , HIS_PT_STD_CHAR_5
               , HIS_CPT_PIECE
               , HIS_CPT_LOT
               , HIS_CPT_VERSION
               , HIS_CHRONOLOGY_CPT
               , HIS_CPT_STD_CHAR_1
               , HIS_CPT_STD_CHAR_2
               , HIS_CPT_STD_CHAR_3
               , HIS_CPT_STD_CHAR_4
               , HIS_CPT_STD_CHAR_5
               , STM_STOCK_MOVEMENT_ID
               , HIS_QTY
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- FAL_TRACABILITY_ID
           , 'ASA'   -- C_TRACABILITY_SOURCE
           , aGCO_GOOD_ID
           , aGCO_GCO_GOOD_ID
           , aASA_RECORD_ID
           , aHIS_PT_PIECE
           , aHIS_PT_LOT
           , aHIS_PT_VERSION
           , aHIS_CHRONOLOGY_PT
           , aHIS_PT_STD_CHAR_1
           , aHIS_PT_STD_CHAR_2
           , aHIS_PT_STD_CHAR_3
           , aHIS_PT_STD_CHAR_4
           , aHIS_PT_STD_CHAR_5
           , aHIS_CPT_PIECE
           , aHIS_CPT_LOT
           , aHIS_CPT_VERSION
           , aHIS_CHRONOLOGY_CPT
           , aHIS_CPT_STD_CHAR_1
           , aHIS_CPT_STD_CHAR_2
           , aHIS_CPT_STD_CHAR_3
           , aHIS_CPT_STD_CHAR_4
           , aHIS_CPT_STD_CHAR_5
           , aSTM_STOCK_MOVEMENT_ID
           , aHIS_QTY
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from dual;
  end AddTracability;

/*--------------------------------------------------------------------------------------------------------------------*/
 /**
 * Description
 *   Enregistrement des données de réparation (un seul produit réparé) dans la traçabilité
 */
  procedure SaveTracabilityStd(aRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    tplRecord        ASA_RECORD%rowtype;
    vPiecePT         ASA_RECORD.ARE_PIECE%type;
    vSetPT           ASA_RECORD.ARE_SET%type;
    vVersionPT       ASA_RECORD.ARE_VERSION%type;
    vChronologicalPT ASA_RECORD.ARE_CHRONOLOGICAL%type;
    -- variables internes pour les caractérisations standard
    charStd1PT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd2PT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd3PT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd4PT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd5PT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
  begin
    -- Infos du produit réparé
    select *
      into tplRecord
      from ASA_RECORD
     where ASA_RECORD_ID = aRecordID;

    -- Récupération des caractérisations du PT (produit réparé) par type
    GCO_FUNCTIONS.ClassifyCharacterizations(aCharac1Id       => tplRecord.GCO_NEW_CHAR1_ID
                                          , aCharac2Id       => tplRecord.GCO_NEW_CHAR2_ID
                                          , aCharac3Id       => tplRecord.GCO_NEW_CHAR3_ID
                                          , aCharac4Id       => tplRecord.GCO_NEW_CHAR4_ID
                                          , aCharac5Id       => tplRecord.GCO_NEW_CHAR5_ID
                                          , aCharValue1      => tplRecord.ARE_NEW_CHAR1_VALUE
                                          , aCharValue2      => tplRecord.ARE_NEW_CHAR2_VALUE
                                          , aCharValue3      => tplRecord.ARE_NEW_CHAR3_VALUE
                                          , aCharValue4      => tplRecord.ARE_NEW_CHAR4_VALUE
                                          , aCharValue5      => tplRecord.ARE_NEW_CHAR5_VALUE
                                          , aPiece           => vPiecePT
                                          , aSet             => vSetPT
                                          , aVersion         => vVersionPT
                                          , aChronological   => vChronologicalPT
                                          , aCharStd1        => CharStd1PT
                                          , aCharStd2        => CharStd2PT
                                          , aCharStd3        => CharStd3PT
                                          , aCharStd4        => CharStd4PT
                                          , aCharStd5        => CharStd5PT
                                           );
    -- Inscrire le produit à réparer comme CPT
    AddTracability(aASA_RECORD_ID        => tplRecord.ASA_RECORD_ID
                 , aGCO_GOOD_ID          => tplRecord.GCO_NEW_GOOD_ID
                 , aHIS_PT_PIECE         => vPiecePT
                 , aHIS_PT_LOT           => vSetPT
                 , aHIS_PT_VERSION       => vVersionPT
                 , aHIS_CHRONOLOGY_PT    => vChronologicalPT
                 , aHIS_PT_STD_CHAR_1    => CharStd1PT
                 , aHIS_PT_STD_CHAR_2    => CharStd2PT
                 , aHIS_PT_STD_CHAR_3    => CharStd3PT
                 , aHIS_PT_STD_CHAR_4    => CharStd4PT
                 , aHIS_PT_STD_CHAR_5    => CharStd5PT
                 , aHIS_CPT_PIECE        => tplRecord.ARE_PIECE
                 , aHIS_CPT_LOT          => tplRecord.ARE_SET
                 , aHIS_CPT_VERSION      => tplRecord.ARE_VERSION
                 , aHIS_CHRONOLOGY_CPT   => tplRecord.ARE_CHRONOLOGICAL
                 , aHIS_CPT_STD_CHAR_1   => tplRecord.ARE_STD_CHAR_1
                 , aHIS_CPT_STD_CHAR_2   => tplRecord.ARE_STD_CHAR_2
                 , aHIS_CPT_STD_CHAR_3   => tplRecord.ARE_STD_CHAR_3
                 , aHIS_CPT_STD_CHAR_4   => tplRecord.ARE_STD_CHAR_4
                 , aHIS_CPT_STD_CHAR_5   => tplRecord.ARE_STD_CHAR_5
                 , aGCO_GCO_GOOD_ID      => tplRecord.GCO_ASA_TO_REPAIR_ID
                 , aHIS_QTY              => tplRecord.ARE_REPAIR_QTY
                  );

    -- Recherche des composants "traçables"
    for tplComponents in (select *
                            from ASA_RECORD_COMP ARC
                           where ASA_RECORD_ID = tplRecord.ASA_RECORD_ID
                             and ASA_RECORD_EVENTS_ID = tplRecord.ASA_RECORD_EVENTS_ID
                             and (    (ARC_PIECE is not null)
                                  or (ARC.ARC_SET is not null)
                                  or (ARC.ARC_VERSION is not null)
                                  or (ARC.ARC_CHRONOLOGICAL is not null)
                                  or (ARC.ARC_STD_CHAR_1 is not null)
                                  or (ARC.ARC_STD_CHAR_2 is not null)
                                  or (ARC.ARC_STD_CHAR_3 is not null)
                                  or (ARC.ARC_STD_CHAR_4 is not null)
                                  or (ARC.ARC_STD_CHAR_5 is not null)
                                 )
                             and STM_COMP_STOCK_MVT_ID is not null
                             and ARC_PROTECTED = 0) loop
      if isTracable(tplComponents.GCO_COMPONENT_ID) = 1 then
        -- Inscrire le composant comme CPT
        AddTracability(aASA_RECORD_ID           => tplRecord.ASA_RECORD_ID
                     , aGCO_GOOD_ID             => tplRecord.GCO_NEW_GOOD_ID
                     , aHIS_PT_PIECE            => vPiecePT
                     , aHIS_PT_LOT              => vSetPT
                     , aHIS_PT_VERSION          => vVersionPT
                     , aHIS_CHRONOLOGY_PT       => vChronologicalPT
                     , aHIS_PT_STD_CHAR_1       => CharStd1PT
                     , aHIS_PT_STD_CHAR_2       => CharStd2PT
                     , aHIS_PT_STD_CHAR_3       => CharStd3PT
                     , aHIS_PT_STD_CHAR_4       => CharStd4PT
                     , aHIS_PT_STD_CHAR_5       => CharStd5PT
                     , aGCO_GCO_GOOD_ID         => tplComponents.GCO_COMPONENT_ID
                     , aHIS_CPT_PIECE           => tplComponents.ARC_PIECE
                     , aHIS_CPT_LOT             => tplComponents.ARC_SET
                     , aHIS_CPT_VERSION         => tplComponents.ARC_VERSION
                     , aHIS_CHRONOLOGY_CPT      => tplComponents.ARC_CHRONOLOGICAL
                     , aHIS_CPT_STD_CHAR_1      => tplComponents.ARC_STD_CHAR_1
                     , aHIS_CPT_STD_CHAR_2      => tplComponents.ARC_STD_CHAR_2
                     , aHIS_CPT_STD_CHAR_3      => tplComponents.ARC_STD_CHAR_3
                     , aHIS_CPT_STD_CHAR_4      => tplComponents.ARC_STD_CHAR_4
                     , aHIS_CPT_STD_CHAR_5      => tplComponents.ARC_STD_CHAR_5
                     , aSTM_STOCK_MOVEMENT_ID   => tplComponents.STM_COMP_STOCK_MVT_ID
                     , aHIS_QTY                 => tplComponents.ARC_QUANTITY
                      );

        -- Protéger le composant pour empêcher sa modification/suppression après traçabilité
        update ASA_RECORD_COMP
           set ARC_PROTECTED = 1
         where ASA_RECORD_COMP_ID = tplComponents.ASA_RECORD_COMP_ID;
      end if;
    end loop;
  end SaveTracabilityStd;

/*--------------------------------------------------------------------------------------------------------------------*/
 /**
 * Description
 *   Enregistrement des données de réparation (multi-quantité) dans la traçabilité
 */
  procedure SaveTracabilityMulti(aRecordID in ASA_RECORD.ASA_RECORD_ID%type, aError out number)
  is
    vPiecePT          ASA_RECORD.ARE_PIECE%type;
    vSetPT            ASA_RECORD.ARE_SET%type;
    vVersionPT        ASA_RECORD.ARE_VERSION%type;
    vChronologicalPT  ASA_RECORD.ARE_CHRONOLOGICAL%type;
    vPieceCPT         ASA_RECORD.ARE_PIECE%type;
    vSetCPT           ASA_RECORD.ARE_SET%type;
    vVersionCPT       ASA_RECORD.ARE_VERSION%type;
    vChronologicalCPT ASA_RECORD.ARE_CHRONOLOGICAL%type;
    -- variables internes pour les caractérisations standard
    charStd1PT        STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd2PT        STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd3PT        STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd4PT        STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd5PT        STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd1CPT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd2CPT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd3CPT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd4CPT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd5CPT       STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
  begin
    -- Contrôle de l'appairage des composants
    select sign(count(*) )
      into aError
      from ASA_RECORD_COMP ARC
         , ASA_RECORD REC
     where ARC.ASA_RECORD_ID = REC.ASA_RECORD_ID
       and ARC.ASA_RECORD_EVENTS_ID = REC.ASA_RECORD_EVENTS_ID
       and REC.ASA_RECORD_ID = aRecordID
       and ARC.ASA_RECORD_DETAIL_ID is null;

    if aError = 0 then
      -- curseur sur les détails de réparation
      for tplRecordDetail in (select REC.GCO_NEW_GOOD_ID
                                   , RRD.RRD_QTY_REPAIRED
                                   , RRD.GCO_CHAR1_ID GCO_NEW_CHAR1_ID
                                   , RRD.GCO_CHAR2_ID GCO_NEW_CHAR2_ID
                                   , RRD.GCO_CHAR3_ID GCO_NEW_CHAR3_ID
                                   , RRD.GCO_CHAR4_ID GCO_NEW_CHAR4_ID
                                   , RRD.GCO_CHAR5_ID GCO_NEW_CHAR5_ID
                                   , RRD.RRD_NEW_CHAR1_VALUE
                                   , RRD.RRD_NEW_CHAR2_VALUE
                                   , RRD.RRD_NEW_CHAR3_VALUE
                                   , RRD.RRD_NEW_CHAR4_VALUE
                                   , RRD.RRD_NEW_CHAR5_VALUE
                                   , REC.GCO_ASA_TO_REPAIR_ID
                                   , RED.RED_QTY_TO_REPAIR
                                   , RED.GCO_CHAR1_ID
                                   , RED.GCO_CHAR2_ID
                                   , RED.GCO_CHAR3_ID
                                   , RED.GCO_CHAR4_ID
                                   , RED.GCO_CHAR5_ID
                                   , RED.RED_CHAR1_VALUE
                                   , RED.RED_CHAR2_VALUE
                                   , RED.RED_CHAR3_VALUE
                                   , RED.RED_CHAR4_VALUE
                                   , RED.RED_CHAR5_VALUE
                                   , REC.ASA_RECORD_EVENTS_ID
                                   , RED.ASA_RECORD_DETAIL_ID
                                from ASA_RECORD_DETAIL RED
                                   , ASA_RECORD_REP_DETAIL RRD
                                   , ASA_RECORD REC
                               where RRD.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
                                 and RED.ASA_RECORD_ID = REC.ASA_RECORD_ID
                                 and REC.ASA_RECORD_ID = aRecordID) loop
        -- Récupération des caractérisations du PT (produit réparé) par type
        GCO_FUNCTIONS.ClassifyCharacterizations(aCharac1Id       => tplRecordDetail.GCO_NEW_CHAR1_ID
                                              , aCharac2Id       => tplRecordDetail.GCO_NEW_CHAR2_ID
                                              , aCharac3Id       => tplRecordDetail.GCO_NEW_CHAR3_ID
                                              , aCharac4Id       => tplRecordDetail.GCO_NEW_CHAR4_ID
                                              , aCharac5Id       => tplRecordDetail.GCO_NEW_CHAR5_ID
                                              , aCharValue1      => tplRecordDetail.RRD_NEW_CHAR1_VALUE
                                              , aCharValue2      => tplRecordDetail.RRD_NEW_CHAR2_VALUE
                                              , aCharValue3      => tplRecordDetail.RRD_NEW_CHAR3_VALUE
                                              , aCharValue4      => tplRecordDetail.RRD_NEW_CHAR4_VALUE
                                              , aCharValue5      => tplRecordDetail.RRD_NEW_CHAR5_VALUE
                                              , aPiece           => vPiecePT
                                              , aSet             => vSetPT
                                              , aVersion         => vVersionPT
                                              , aChronological   => vChronologicalPT
                                              , aCharStd1        => CharStd1PT
                                              , aCharStd2        => CharStd2PT
                                              , aCharStd3        => CharStd3PT
                                              , aCharStd4        => CharStd4PT
                                              , aCharStd5        => CharStd5PT
                                               );
        -- Récupération des caractérisations du CPT (produit à réparer) par type
        GCO_FUNCTIONS.ClassifyCharacterizations(aCharac1Id       => tplRecordDetail.GCO_CHAR1_ID
                                              , aCharac2Id       => tplRecordDetail.GCO_CHAR2_ID
                                              , aCharac3Id       => tplRecordDetail.GCO_CHAR3_ID
                                              , aCharac4Id       => tplRecordDetail.GCO_CHAR4_ID
                                              , aCharac5Id       => tplRecordDetail.GCO_CHAR5_ID
                                              , aCharValue1      => tplRecordDetail.RED_CHAR1_VALUE
                                              , aCharValue2      => tplRecordDetail.RED_CHAR2_VALUE
                                              , aCharValue3      => tplRecordDetail.RED_CHAR3_VALUE
                                              , aCharValue4      => tplRecordDetail.RED_CHAR4_VALUE
                                              , aCharValue5      => tplRecordDetail.RED_CHAR5_VALUE
                                              , aPiece           => vPieceCPT
                                              , aSet             => vSetCPT
                                              , aVersion         => vVersionCPT
                                              , aChronological   => vChronologicalCPT
                                              , aCharStd1        => CharStd1CPT
                                              , aCharStd2        => CharStd2CPT
                                              , aCharStd3        => CharStd3CPT
                                              , aCharStd4        => CharStd4CPT
                                              , aCharStd5        => CharStd5CPT
                                               );
        -- Inscrire le produit à réparer comme CPT
        AddTracability(aASA_RECORD_ID        => aRecordID
                     , aGCO_GOOD_ID          => tplRecordDetail.GCO_NEW_GOOD_ID
                     , aHIS_PT_PIECE         => vPiecePT
                     , aHIS_PT_LOT           => vSetPT
                     , aHIS_PT_VERSION       => vVersionPT
                     , aHIS_CHRONOLOGY_PT    => vChronologicalPT
                     , aHIS_PT_STD_CHAR_1    => CharStd1PT
                     , aHIS_PT_STD_CHAR_2    => CharStd2PT
                     , aHIS_PT_STD_CHAR_3    => CharStd3PT
                     , aHIS_PT_STD_CHAR_4    => CharStd4PT
                     , aHIS_PT_STD_CHAR_5    => CharStd5PT
                     , aHIS_CPT_PIECE        => vPieceCPT
                     , aHIS_CPT_LOT          => vSetCPT
                     , aHIS_CPT_VERSION      => vVersionCPT
                     , aHIS_CHRONOLOGY_CPT   => vChronologicalCPT
                     , aHIS_CPT_STD_CHAR_1   => CharStd1CPT
                     , aHIS_CPT_STD_CHAR_2   => CharStd2CPT
                     , aHIS_CPT_STD_CHAR_3   => CharStd3CPT
                     , aHIS_CPT_STD_CHAR_4   => CharStd4CPT
                     , aHIS_CPT_STD_CHAR_5   => CharStd5CPT
                     , aGCO_GCO_GOOD_ID      => tplRecordDetail.GCO_ASA_TO_REPAIR_ID
                     , aHIS_QTY              => tplRecordDetail.RED_QTY_TO_REPAIR
                      );

        -- curseur sur les composants n'ayant pas encore été "tracés"
        for tplComponents in (select *
                                from ASA_RECORD_COMP ARC
                               where ARC.ASA_RECORD_DETAIL_ID = tplRecordDetail.ASA_RECORD_DETAIL_ID
                                 and ARC.ASA_RECORD_EVENTS_ID = tplRecordDetail.ASA_RECORD_EVENTS_ID
                                 and (    (ARC.ARC_PIECE is not null)
                                      or (ARC.ARC_SET is not null)
                                      or (ARC.ARC_VERSION is not null)
                                      or (ARC.ARC_CHRONOLOGICAL is not null)
                                      or (ARC.ARC_STD_CHAR_1 is not null)
                                      or (ARC.ARC_STD_CHAR_2 is not null)
                                      or (ARC.ARC_STD_CHAR_3 is not null)
                                      or (ARC.ARC_STD_CHAR_4 is not null)
                                      or (ARC.ARC_STD_CHAR_5 is not null)
                                     )
                                 and ARC.STM_COMP_STOCK_MVT_ID is not null
                                 and ARC.ARC_PROTECTED = 0) loop
          if isTracable(tplComponents.GCO_COMPONENT_ID) = 1 then
            -- Inscrire le composant comme CPT
            AddTracability(aASA_RECORD_ID           => aRecordID
                         , aGCO_GOOD_ID             => tplRecordDetail.GCO_NEW_GOOD_ID
                         , aHIS_PT_PIECE            => vPiecePT
                         , aHIS_PT_LOT              => vSetPT
                         , aHIS_PT_VERSION          => vVersionPT
                         , aHIS_CHRONOLOGY_PT       => vChronologicalPT
                         , aHIS_PT_STD_CHAR_1       => CharStd1PT
                         , aHIS_PT_STD_CHAR_2       => CharStd2PT
                         , aHIS_PT_STD_CHAR_3       => CharStd3PT
                         , aHIS_PT_STD_CHAR_4       => CharStd4PT
                         , aHIS_PT_STD_CHAR_5       => CharStd5PT
                         , aGCO_GCO_GOOD_ID         => tplComponents.GCO_COMPONENT_ID
                         , aHIS_CPT_PIECE           => tplComponents.ARC_PIECE
                         , aHIS_CPT_LOT             => tplComponents.ARC_SET
                         , aHIS_CPT_VERSION         => tplComponents.ARC_VERSION
                         , aHIS_CHRONOLOGY_CPT      => tplComponents.ARC_CHRONOLOGICAL
                         , aHIS_CPT_STD_CHAR_1      => tplComponents.ARC_STD_CHAR_1
                         , aHIS_CPT_STD_CHAR_2      => tplComponents.ARC_STD_CHAR_2
                         , aHIS_CPT_STD_CHAR_3      => tplComponents.ARC_STD_CHAR_3
                         , aHIS_CPT_STD_CHAR_4      => tplComponents.ARC_STD_CHAR_4
                         , aHIS_CPT_STD_CHAR_5      => tplComponents.ARC_STD_CHAR_5
                         , aSTM_STOCK_MOVEMENT_ID   => tplComponents.STM_COMP_STOCK_MVT_ID
                         , aHIS_QTY                 => tplComponents.ARC_QUANTITY
                          );

            -- Protéger le composant pour empêcher sa modification/suppression après traçabilité
            update ASA_RECORD_COMP
               set ARC_PROTECTED = 1
             where ASA_RECORD_COMP_ID = tplComponents.ASA_RECORD_COMP_ID;
          end if;
        end loop;
      end loop;
    end if;
  end SaveTracabilityMulti;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Enregistrement des données de réparation dans la traçabilité
  */
  procedure SaveTracability(aRecordID in ASA_RECORD.ASA_RECORD_ID%type, aError out number)
  is
    vGoodID GCO_GOOD.GCO_GOOD_ID%type;
    vQtyMgm ASA_REP_TYPE.RET_QTY_MGM%type;
  begin
    aError  := 0;

    -- Recherche du bien réparé
    select nvl(GCO_NEW_GOOD_ID, 0)
      into vGoodID
      from ASA_RECORD
     where ASA_RECORD_ID = aRecordID;

    -- Vérifier que le bien est concerné par la traçabilité
    if isTracable(vGoodID) = 1 then
      select RET.RET_QTY_MGM
        into vQtyMgm
        from ASA_RECORD REC
           , ASA_REP_TYPE RET
       where REC.ASA_REP_TYPE_ID = RET.ASA_REP_TYPE_ID
         and REC.ASA_RECORD_ID = aRecordID;

      if vQtyMgm = 0 then
        -- Traçabilité "simple"
        SaveTracabilityStd(aRecordID);
      else
        -- Traçabilité multi-quantité
        SaveTracabilityMulti(aRecordID, aError);
      end if;
    end if;
  end SaveTracability;
end ASA_TRACABILITY;
