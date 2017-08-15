--------------------------------------------------------
--  DDL for Procedure UPDATE_DOC_NETWORK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "UPDATE_DOC_NETWORK" 
is
  cursor GetDetailPositions(aGaugeType in DOC_GAUGE.C_GAUGE_TYPE%type)
  is
    select Detail.*
      from Doc_position_detail Detail
         , Doc_position position
         , Doc_document Doc
         , Doc_gauge Gauge
     where Detail.Doc_position_id = position.Doc_position_id
       and position.Doc_document_id = Doc.Doc_document_id
       and Doc.Doc_gauge_id = Gauge.Doc_gauge_id
       and position.C_DOC_POs_STATUS in('02', '03')
       and position.C_Gauge_Type_Pos in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101')
       and Gauge.c_Gauge_Type = aGaugeType;

  aCount       integer;
  aInsertCount integer;
  aRecords     integer;
  lvFanDescr   FAL_NETWORK_SUPPLY.FAN_DESCRIPTION%type;
begin
  aInsertCount  := 0;
  aRecords      := 0;

  -- Traitement des Approvisionnements ----------------------------------------------------------------------------------
  for aDetailRecord in GetDetailPositions('2') loop
    aRecords  := aRecords + 1;

    -- Vérifier si ce détail position n'existe pas déjà dans les réseaux ----------------------------------------------
    select count(*)
      into aCount
      from FAL_NETWORK_SUPPLY
     where DOC_POSITION_DETAIL_ID = aDetailRecord.DOC_POSITION_DETAIL_ID;

    DBMS_OUTPUT.put_line(to_char(aRecords) || '   Count : ' || to_char(aCount) );

    if aCount = 0 then
      aInsertCount  := aInsertCount + 1;

      -- Description de l'appro
      select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
        into lvFanDescr
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
       where POS.DOC_POSITION_ID = aDetailRecord.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

      -- Réseau inexistant. Processus : Création ReseauxLogAppro -----------------------------------------------------
      FAL_NETWORK_DOC.ReseauApproDOC_Creation(aPositionDetail     => aDetailRecord
                                            , pDocumentID         => null
                                            , pGoodID             => null
                                            , pDocRecordID        => null
                                            , pConversionFactor   => null
                                            , iDescription        => lvFanDescr
                                             );
    end if;
  end loop;

  -- Traitement des Besoins ---------------------------------------------------------------------------------------------
  for aDetailRecord in GetDetailPositions('1') loop
    aRecords  := aRecords + 1;

    -- Vérifier si ce détail position n'existe pas déjà dans les réseaux ----------------------------------------------
    select count(*)
      into aCount
      from FAL_NETWORK_NEED
     where DOC_POSITION_DETAIL_ID = aDetailRecord.DOC_POSITION_DETAIL_ID;

    DBMS_OUTPUT.put_line(to_char(aRecords) || '   Count : ' || to_char(aCount) );

    if aCount = 0 then
      aInsertCount  := aInsertCount + 1;

      -- Description du besoin
      select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
        into lvFanDescr
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
       where POS.DOC_POSITION_ID = aDetailRecord.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

      -- Réseau inexistant. Processus : Création ReseauxLogBesoin ----------------------------------------------------
      FAL_NETWORK_DOC.ReseauBesoinDOC_Creation(aPositionDetail          => aDetailRecord
                                             , pDocumentID              => null
                                             , pGoodID                  => null
                                             , pDocRecordID             => null
                                             , pConversionFactor        => null
                                             , pPAC_REPRESENTATIVE_ID   => null
                                             , iDescription             => lvFanDescr
                                              );
    end if;
  end loop;

  DBMS_OUTPUT.put_line('Nb records vus : ' || to_char(aRecords) );
  DBMS_OUTPUT.put_line('Nb records traités : ' || to_char(aInsertCount) );
end;
