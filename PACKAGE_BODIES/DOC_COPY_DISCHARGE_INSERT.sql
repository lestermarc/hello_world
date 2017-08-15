--------------------------------------------------------
--  DDL for Package Body DOC_COPY_DISCHARGE_INSERT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_COPY_DISCHARGE_INSERT" 
is
  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base du
  *    stock disponible
  */
  procedure InsertDischargeDetail(
    ANewDocumentID in number
  , ADocumentList  in varchar2
  , ARecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , AReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crDischargePde(ADocumentID in number)
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
                    , PDE.PDE_BALANCE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, DMT_TGT.DOC_GAUGE_ID, DMT_TGT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
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
                    , DOC_RECORD RCO
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE_POSITION GAP_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  -- and DOC_I_LIB_SUBCONTRACT.AllowDischarge(PDE.DOC_POSITION_DETAIL_ID, PDE.PDE_BALANCE_QUANTITY) = 1
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   AReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(AReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = ADocumentID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (    exists(
                                                       select DOC_GAUGE_POSITION_ID
                                                         from DOC_GAUGE_POSITION GAP_LINK
                                                        where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                          and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                 and (exists(
                                                        select POS_CPT.DOC_POSITION_ID
                                                          from DOC_POSITION POS_CPT
                                                         where POS_CPT.DOC_DOC_POSITION_ID = POS2.DOC_POSITION_ID
                                                           and POS_CPT.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
                                                           and POS_CPT.C_DOC_POS_STATUS < '04')
                                                     )
                                                )
                                            )
                                          )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101', '21') )
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
                  and DOC_I_LIB_GAUGE.CanReceipt(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePde              crDischargePde%rowtype;

    cursor crDischargePdeCPT(aPositionID in number)
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
                    , least(PDE.PDE_BALANCE_QUANTITY
                          , decode(DCD.DCD_QUANTITY
                                 , 0, PDE.PDE_BALANCE_QUANTITY
                                 , ACS_FUNCTION.RoundNear(DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1), 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 0)
                                  )
                           ) DCD_QUANTITY
                    , least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                          , ACS_FUNCTION.RoundNear(decode(DCD.DCD_QUANTITY, 0, PDE.PDE_BALANCE_QUANTITY, DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1) ) *
                                                   POS.POS_CONVERT_FACTOR
                                                 , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                 , 1
                                                  )
                           ) DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
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
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle) )
                  and POS.DOC_DOC_POSITION_ID = APositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = ANewDocumentID
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
    currentPositionID            DOC_POSITION.DOC_POSITION_ID%type;
    cGaugeTypePos                DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Balayer la liste des documents à décharger
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      open crDischargePde(tplDoc.DOC_DOCUMENT_ID);

      fetch crDischargePde
       into tplDischargePde;

      -- Tant qu'il reste des détails à traiter
      while crDischargePde%found loop
        -- Mémorise la position courante pour déterminer un changement de position ainsi que le type de position.
        currentPositionID                         := tplDischargePde.DOC_POSITION_ID;
        cGaugeTypePos                             := tplDischargePde.C_GAUGE_TYPE_POS;

        -- Création d'une entrée dans la table temporaire pour les positions que ne sont pas des composants (DOC_DOC_POSITION_ID is null)
        select init_id_seq.nextval
          into vNewDcdID
          from dual;

        -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
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
        vInsertDcd.DOC_RECORD_ID                  := tplDischargePde.DOC_RECORD_ID;
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
        vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
        vInsertDcd.DCD_QUANTITY                   := tplDischargePde.DCD_QUANTITY;
        vInsertDcd.DCD_QUANTITY_SU                := tplDischargePde.DCD_QUANTITY_SU;
        vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
        vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
        vInsertDcd.POS_CONVERT_FACTOR_CALC        := nvl(vConvertFactorCalc, tplDischargePde.POS_CONVERT_FACTOR);
        vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
        vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
        vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
        vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
        vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
        vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
        vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
        vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
        vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

        insert into V_DOC_POS_DET_COPY_DISCHARGE
             values vInsertDcd;

        fetch crDischargePde
         into tplDischargePde;

        -- Détermine si des composants doivent être créés sur la base d'un éventuel produit terminé.
        -- C'est uniquement après la création du dernier détail du produit terminé que la création des composants
        -- doit s'effectuer.
        if cGaugeTypePos in('7', '8', '9', '10') then
          -- Dernier record ou changement de position
          if    not crDischargePde%found
             or currentPositionID <> tplDischargePde.DOC_POSITION_ID then
            -- Réinitialise les variables permettant la redéfinission éventuelle de la quantité  du produit terminé si
            -- tous les composants ont une quantité à 0.
            dblGreatestSumQuantityCPT     := 0;
            dblGreatestSumQuantityCPT_SU  := 0;

            -- Traitement des détails de positions composants.
            for tplDischargePdeCPT in crDischargePdeCPT(currentPositionID) loop
              /* Stock la plus grande quantité des composants après application du
                 coefficient d'utilisation */
              if (nvl(tplDischargePdeCPT.POS_UTIL_COEFF, 0) = 0) then
                dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
                dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
              else
                dblGreatestSumQuantityCPT     :=
                                               greatest(dblGreatestSumQuantityCPT, tplDischargePdeCPT.PDE_BALANCE_QUANTITY / tplDischargePdeCPT.POS_UTIL_COEFF);
                dblGreatestSumQuantityCPT_SU  :=
                                            greatest(dblGreatestSumQuantityCPT_SU, tplDischargePdeCPT.PDE_BALANCE_QUANTITY / tplDischargePdeCPT.POS_UTIL_COEFF);
              end if;

              -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
              vInsertDcdCpt                               := null;
              vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
              vInsertDcdCpt.NEW_DOCUMENT_ID               := tplDischargePdeCPT.NEW_DOCUMENT_ID;

              -- C'est uniquement la quantité solde du composant qui influence l'indicateur de sélection. Attention, toutefois, dans
              -- le cas ou la quantité du composant est à 0, il faut tout de même séléctionner le composant. Voir DEVLOG-14824.
              if     (tplDischargePdeCPT.PDE_BALANCE_QUANTITY = 0)
                 and (tplDischargePdeCPT.PDE_BASIS_QUANTITY <> 0) then
                vInsertDcdCpt.CRG_SELECT  := 0;
              else
                vInsertDcdCpt.CRG_SELECT  := 1;
              end if;

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
              -- Il ne faut pas reprendre la quantité provenant du PT pour initialiser la quantité du CPT
              -- (dans ce contexte en tout cas) mais uniquement la quantité solde du CPT. Cela permet de
              -- gérer sans distinction les kit standard et les kit partiels.
              vInsertDcdCpt.DCD_QUANTITY                  := tplDischargePdeCPT.PDE_BALANCE_QUANTITY;
              vInsertDcdCpt.DCD_QUANTITY_SU               := tplDischargePdeCPT.PDE_BALANCE_QUANTITY;
              vInsertDcdCpt.DCD_BALANCE_FLAG              := tplDischargePdeCPT.DCD_BALANCE_FLAG;
              vInsertDcdCpt.POS_CONVERT_FACTOR            := tplDischargePdeCPT.POS_CONVERT_FACTOR;
              vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplDischargePdeCPT.POS_CONVERT_FACTOR;
              vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE;
              vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE_INCL;
              vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplDischargePdeCPT.DIC_UNIT_OF_MEASURE_ID;
              vInsertDcdCpt.POS_UTIL_COEFF                := tplDischargePdeCPT.POS_UTIL_COEFF;
              vInsertDcdCpt.DCD_VISIBLE                   := tplDischargePdeCPT.DCD_VISIBLE;
              vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
              vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
              vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
              vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

              insert into V_DOC_POS_DET_COPY_DISCHARGE
                   values vInsertDcdCpt;
            end loop;   -- for tplDischargePdeCPT

            /**
            * Redéfinit la quantité du produit terminé en fonction de la quantité
            * des composants. Valable en principe uniquement lorsque les quantités du PT et des CPT
            * sont désolidarisés (kit partielle).
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
                   , CRG_SELECT = 0
               where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
            end if;
          end if;
        end if;
      end loop;   -- crDischargePde%found

      close crDischargePde;
    end loop;   -- for tplDoc
  end InsertDischargeDetail;

  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base des
  *    attributions sur stock
  */
  procedure InsertDischargeDetailAttrib(
    ANewDocumentID  in number
  , ADocumentList   in varchar2
  , ARecordTitle    in DOC_RECORD.RCO_TITLE%type default null
  , AReference      in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , AShowAttribOnly in integer default 0
  )
  is
    cursor crDischargePde(ADocumentID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , decode(POS.C_GAUGE_TYPE_POS
                           , '1', decode(PDT.PDT_STOCK_MANAGEMENT
                                       , 1, decode(PDT.C_PRODUCT_DELIVERY_TYP
                                                 , '2', 1
                                                 , decode(CUS.C_DELIVERY_TYP, '2', 1, decode(FLN.FLN_QTY, null, 0, 0, 0, 1) )
                                                  )
                                       , 1
                                        )
                           , '7', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribs(POS.DOC_POSITION_ID)
                           , '8', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribs(POS.DOC_POSITION_ID)
                           , '9', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribs(POS.DOC_POSITION_ID)
                           , '10', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribs(POS.DOC_POSITION_ID)
                           , 1
                            ) as CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , nvl(SPO.STM_LOCATION_ID, PDE.STM_LOCATION_ID) STM_LOCATION_ID
                    , nvl(SPO.GCO_CHARACTERIZATION_ID, PDE.GCO_CHARACTERIZATION_ID) GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO.GCO_GCO_CHARACTERIZATION_ID) GCO_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.GCO2_GCO_CHARACTERIZATION_ID) GCO2_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.GCO3_GCO_CHARACTERIZATION_ID) GCO3_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.GCO4_GCO_CHARACTERIZATION_ID) GCO4_GCO_CHARACTERIZATION_ID
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
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, PDE.PDE_CHARACTERIZATION_VALUE_1) SPO_CHARACTERIZATION_VALUE_1
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, PDE.PDE_CHARACTERIZATION_VALUE_2) SPO_CHARACTERIZATION_VALUE_2
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, PDE.PDE_CHARACTERIZATION_VALUE_3) SPO_CHARACTERIZATION_VALUE_3
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, PDE.PDE_CHARACTERIZATION_VALUE_4) SPO_CHARACTERIZATION_VALUE_4
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, PDE.PDE_CHARACTERIZATION_VALUE_5) SPO_CHARACTERIZATION_VALUE_5
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
                    , decode(PDE.PDE_BALANCE_QUANTITY
                           , 0, 0
                           , decode(POS.C_GAUGE_TYPE_POS
                                  , '1', decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY / POS.POS_CONVERT_FACTOR, 0), PDE.PDE_BALANCE_QUANTITY)
                                  , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  ,
-- révision 1.0
--                            '7', decode(GAP.DOC_DOC_GAUGE_POSITION_ID, -- Gabarit position lié ?
--                                        -- Non, on reprend la quantité attribué minimal des composants
--                                        null, DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID),
--                                              -- Oui, on reprend la quantité solde du produit terminé
--                                              PDE.PDE_BALANCE_QUANTITY),
--                            '8', decode(GAP.DOC_DOC_GAUGE_POSITION_ID, -- Gabarit position lié ?
--                                        -- Non, on reprend la quantité attribué minimal des composants
--                                        null, DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID),
--                                              -- Oui, on reprend la quantité solde du produit terminé
--                                              PDE.PDE_BALANCE_QUANTITY),
--                            '9', decode(GAP.DOC_DOC_GAUGE_POSITION_ID, -- Gabarit position lié ?
--                                        -- Non, on reprend la quantité attribué minimal des composants
--                                        null, DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID),
--                                              -- Oui, on reprend la quantité solde du produit terminé
--                                              PDE.PDE_BALANCE_QUANTITY),
--                            '10',decode(GAP.DOC_DOC_GAUGE_POSITION_ID, -- Gabarit position lié ?
--                                        -- Non, on reprend la quantité attribué minimal des composants
--                                        null, DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID),
--                                              -- Oui, on reprend la quantité solde du produit terminé
--                                              PDE.PDE_BALANCE_QUANTITY),
                                    PDE.PDE_BALANCE_QUANTITY
                                   )
                            ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(decode(PDE.PDE_BALANCE_QUANTITY
                                                  , 0, 0
                                                  , decode(POS.C_GAUGE_TYPE_POS
                                                         , '1', decode(PDT.PDT_STOCK_MANAGEMENT
                                                                     , 1, nvl(FLN.FLN_QTY / POS.POS_CONVERT_FACTOR, 0)
                                                                     , PDE.PDE_BALANCE_QUANTITY
                                                                      )
                                                         , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID)
                                                                    , PDE.PDE_BALANCE_QUANTITY)
                                                         , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID)
                                                                    , PDE.PDE_BALANCE_QUANTITY)
                                                         , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID)
                                                                    , PDE.PDE_BALANCE_QUANTITY)
                                                         , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID)
                                                                     , PDE.PDE_BALANCE_QUANTITY
                                                                      )
                                                         , PDE.PDE_BALANCE_QUANTITY
                                                          )
                                                   ) *
                                             POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, DMT_TGT.DOC_GAUGE_ID, DMT_TGT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , FLN.FAL_NETWORK_LINK_ID
                    , GAP.DOC_DOC_GAUGE_POSITION_ID
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE_POSITION GAP_TGT
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_POSITION GAP
                    , GCO_PRODUCT PDT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , DOC_RECORD RCO
                where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   AReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(AReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = ADocumentID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (    exists(
                                                       select DOC_GAUGE_POSITION_ID
                                                         from DOC_GAUGE_POSITION GAP_LINK
                                                        where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                          and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                 and (exists(
                                                        select POS_CPT.DOC_POSITION_ID
                                                          from DOC_POSITION POS_CPT
                                                         where POS_CPT.DOC_DOC_POSITION_ID = POS2.DOC_POSITION_ID
                                                           and POS_CPT.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
                                                           and POS_CPT.C_DOC_POS_STATUS < '04')
                                                     )
                                                )
                                            )
                                          )
                                     --and ( ( POS2.C_DOC_POS_STATUS in ('02','03')
                                     --    and ( PDE2.PDE_BALANCE_QUANTITY <> 0 or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0 )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101', '21') )
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
                  and DOC_I_LIB_GAUGE.CanReceipt(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePde    crDischargePde%rowtype;

    cursor crDischargePdeCPT(APositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , DCD.DCD_QUANTITY
                    , POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = APositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = ANewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT crDischargePdeCPT%rowtype;
    --
    vNewDcdID          DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
  begin
    -- Balayer la liste des documents à décharger
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      for tplDischargePde in crDischargePde(tplDoc.DOC_DOCUMENT_ID) loop
        -- Si affichage (et décharge) uniquement des détails attribués = 1 Alors
        --   Inserer uniquement ces détails là
        -- Sinon
        --   Inserer tous les détails
        if    (AShowAttribOnly = 0)
           or (     (AShowAttribOnly = 1)
               and (tplDischargePde.CRG_SELECT = 1) ) then
          select init_id_seq.nextval
            into vNewDcdID
            from dual;

          -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
          -- Il faut rechercher le facteur de conversion calculé.
          vConvertFactorCalc  :=
            GCO_FUNCTIONS.GetThirdConvertFactor(tplDischargePde.GCO_GOOD_ID
                                              , tplDischargePde.PAC_THIRD_CDA_ID
                                              , tplDischargePde.C_GAUGE_TYPE_POS
                                              , null
                                              , tplDischargePde.TGT_PAC_THIRD_CDA_ID
                                              , tplDischargePde.TGT_C_ADMIN_DOMAIN
                                               );

          insert into V_DOC_POS_DET_COPY_DISCHARGE
                      (DOC_POS_DET_COPY_DISCHARGE_ID
                     , DOC_POSITION_DETAIL_ID
                     , NEW_DOCUMENT_ID
                     , CRG_SELECT
                     , DOC_GAUGE_FLOW_ID
                     , DOC_POSITION_ID
                     , DOC_DOC_POSITION_ID
                     , DOC_DOC_POSITION_DETAIL_ID
                     , DOC2_DOC_POSITION_DETAIL_ID
                     , GCO_GOOD_ID
                     , STM_LOCATION_ID
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , STM_STM_LOCATION_ID
                     , DIC_PDE_FREE_TABLE_1_ID
                     , DIC_PDE_FREE_TABLE_2_ID
                     , DIC_PDE_FREE_TABLE_3_ID
                     , FAL_SCHEDULE_STEP_ID
                     , DOC_RECORD_ID
                     , DOC_DOCUMENT_ID
                     , PAC_THIRD_ID
                     , PAC_THIRD_ACI_ID
                     , PAC_THIRD_DELIVERY_ID
                     , PAC_THIRD_TARIFF_ID
                     , DOC_GAUGE_ID
                     , DOC_GAUGE_RECEIPT_ID
                     , DOC_GAUGE_COPY_ID
                     , C_GAUGE_TYPE_POS
                     , DIC_DELAY_UPDATE_TYPE_ID
                     , PDE_BASIS_DELAY
                     , PDE_INTERMEDIATE_DELAY
                     , PDE_FINAL_DELAY
                     , PDE_SQM_ACCEPTED_DELAY
                     , PDE_BASIS_QUANTITY
                     , PDE_INTERMEDIATE_QUANTITY
                     , PDE_FINAL_QUANTITY
                     , PDE_BALANCE_QUANTITY
                     , PDE_BALANCE_QUANTITY_PARENT
                     , PDE_BASIS_QUANTITY_SU
                     , PDE_INTERMEDIATE_QUANTITY_SU
                     , PDE_FINAL_QUANTITY_SU
                     , PDE_MOVEMENT_QUANTITY
                     , PDE_MOVEMENT_VALUE
                     , PDE_CHARACTERIZATION_VALUE_1
                     , PDE_CHARACTERIZATION_VALUE_2
                     , PDE_CHARACTERIZATION_VALUE_3
                     , PDE_CHARACTERIZATION_VALUE_4
                     , PDE_CHARACTERIZATION_VALUE_5
                     , PDE_DELAY_UPDATE_TEXT
                     , PDE_DECIMAL_1
                     , PDE_DECIMAL_2
                     , PDE_DECIMAL_3
                     , PDE_TEXT_1
                     , PDE_TEXT_2
                     , PDE_TEXT_3
                     , PDE_DATE_1
                     , PDE_DATE_2
                     , PDE_DATE_3
                     , PDE_GENERATE_MOVEMENT
                     , DCD_QUANTITY
                     , DCD_QUANTITY_SU
                     , DCD_BALANCE_FLAG
                     , POS_CONVERT_FACTOR
                     , POS_CONVERT_FACTOR_CALC
                     , POS_GROSS_UNIT_VALUE
                     , POS_GROSS_UNIT_VALUE_INCL
                     , POS_UNIT_OF_MEASURE_ID
                     , DCD_DEPLOYED_COMPONENTS
                     , FAL_NETWORK_LINK_ID
                     , DCD_VISIBLE
                     , A_DATECRE
                     , A_IDCRE
                     , PDE_ST_PT_REJECT
                     , PDE_ST_CPT_REJECT
                      )
               values (vNewDcdID
                     , tplDischargePde.DOC_POSITION_DETAIL_ID
                     , ANewDocumentID
                     , tplDischargePde.CRG_SELECT
                     , tplDischargePde.DOC_GAUGE_FLOW_ID
                     , tplDischargePde.DOC_POSITION_ID
                     , tplDischargePde.DOC_DOC_POSITION_ID
                     , tplDischargePde.DOC_DOC_POSITION_DETAIL_ID
                     , tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID
                     , tplDischargePde.GCO_GOOD_ID
                     , tplDischargePde.STM_LOCATION_ID
                     , tplDischargePde.GCO_CHARACTERIZATION_ID
                     , tplDischargePde.GCO_GCO_CHARACTERIZATION_ID
                     , tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID
                     , tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID
                     , tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID
                     , tplDischargePde.STM_STM_LOCATION_ID
                     , tplDischargePde.DIC_PDE_FREE_TABLE_1_ID
                     , tplDischargePde.DIC_PDE_FREE_TABLE_2_ID
                     , tplDischargePde.DIC_PDE_FREE_TABLE_3_ID
                     , tplDischargePde.FAL_SCHEDULE_STEP_ID
                     , tplDischargePde.DOC_RECORD_ID
                     , tplDischargePde.DOC_DOCUMENT_ID
                     , tplDischargePde.PAC_THIRD_ID
                     , tplDischargePde.PAC_THIRD_ACI_ID
                     , tplDischargePde.PAC_THIRD_DELIVERY_ID
                     , tplDischargePde.PAC_THIRD_TARIFF_ID
                     , tplDischargePde.DOC_GAUGE_ID
                     , tplDischargePde.DOC_GAUGE_RECEIPT_ID
                     , tplDischargePde.DOC_GAUGE_COPY_ID
                     , tplDischargePde.C_GAUGE_TYPE_POS
                     , tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID
                     , tplDischargePde.PDE_BASIS_DELAY
                     , tplDischargePde.PDE_INTERMEDIATE_DELAY
                     , tplDischargePde.PDE_FINAL_DELAY
                     , tplDischargePde.PDE_SQM_ACCEPTED_DELAY
                     , tplDischargePde.PDE_BASIS_QUANTITY
                     , tplDischargePde.PDE_INTERMEDIATE_QUANTITY
                     , tplDischargePde.PDE_FINAL_QUANTITY
                     , tplDischargePde.PDE_BALANCE_QUANTITY
                     , tplDischargePde.PDE_BALANCE_QUANTITY_PARENT
                     , tplDischargePde.PDE_BASIS_QUANTITY_SU
                     , tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU
                     , tplDischargePde.PDE_FINAL_QUANTITY_SU
                     , tplDischargePde.PDE_MOVEMENT_QUANTITY
                     , tplDischargePde.PDE_MOVEMENT_VALUE
                     , tplDischargePde.SPO_CHARACTERIZATION_VALUE_1
                     , tplDischargePde.SPO_CHARACTERIZATION_VALUE_2
                     , tplDischargePde.SPO_CHARACTERIZATION_VALUE_3
                     , tplDischargePde.SPO_CHARACTERIZATION_VALUE_4
                     , tplDischargePde.SPO_CHARACTERIZATION_VALUE_5
                     , tplDischargePde.PDE_DELAY_UPDATE_TEXT
                     , tplDischargePde.PDE_DECIMAL_1
                     , tplDischargePde.PDE_DECIMAL_2
                     , tplDischargePde.PDE_DECIMAL_3
                     , tplDischargePde.PDE_TEXT_1
                     , tplDischargePde.PDE_TEXT_2
                     , tplDischargePde.PDE_TEXT_3
                     , tplDischargePde.PDE_DATE_1
                     , tplDischargePde.PDE_DATE_2
                     , tplDischargePde.PDE_DATE_3
                     , tplDischargePde.PDE_GENERATE_MOVEMENT
                     , tplDischargePde.DCD_QUANTITY
                     , tplDischargePde.DCD_QUANTITY_SU
                     , tplDischargePde.DCD_BALANCE_FLAG
                     , tplDischargePde.POS_CONVERT_FACTOR
                     , nvl(vConvertFactorCalc, tplDischargePde.POS_CONVERT_FACTOR)
                     , tplDischargePde.POS_GROSS_UNIT_VALUE
                     , tplDischargePde.POS_GROSS_UNIT_VALUE_INCL
                     , tplDischargePde.DIC_UNIT_OF_MEASURE_ID
                     , tplDischargePde.DCD_DEPLOYED_COMPONENTS
                     , tplDischargePde.FAL_NETWORK_LINK_ID
                     , 0   -- DCD_VISIBLE
                     , tplDischargePde.NEW_A_DATECRE
                     , tplDischargePde.NEW_A_IDCRE
                     , tplDischargePde.PDE_ST_PT_REJECT
                     , tplDischargePde.PDE_ST_CPT_REJECT
                      );

          -- Traitement d'une position kit ou assemblage
          if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
            -- Traitement des détails de positions composants.
            for tplDischargePdeCPT in crDischargePdeCPT(tplDischargePde.DOC_POSITION_ID) loop
              if tplDischargePde.DOC_DOC_GAUGE_POSITION_ID is null then
                /* Si aucun gabarit position lié. Les cpts sont toujours inférieurs
                   ou égal au PT. Pour garantir cela, il faut inserer dans la vue
                   et non directement dans la table. En effet, la vue recalcul la
                   quantité du composant en fonction du PT. */
                insert into V_DOC_POS_DET_COPY_DISCHARGE
                            (DOC_POSITION_DETAIL_ID
                           , NEW_DOCUMENT_ID
                           , CRG_SELECT
                           , DOC_GAUGE_FLOW_ID
                           , DOC_POSITION_ID
                           , DOC_DOC_POSITION_ID
                           , DOC_DOC_POSITION_DETAIL_ID
                           , DOC2_DOC_POSITION_DETAIL_ID
                           , GCO_GOOD_ID
                           , STM_LOCATION_ID
                           , GCO_CHARACTERIZATION_ID
                           , GCO_GCO_CHARACTERIZATION_ID
                           , GCO2_GCO_CHARACTERIZATION_ID
                           , GCO3_GCO_CHARACTERIZATION_ID
                           , GCO4_GCO_CHARACTERIZATION_ID
                           , STM_STM_LOCATION_ID
                           , DIC_PDE_FREE_TABLE_1_ID
                           , DIC_PDE_FREE_TABLE_2_ID
                           , DIC_PDE_FREE_TABLE_3_ID
                           , FAL_SCHEDULE_STEP_ID
                           , DOC_DOCUMENT_ID
                           , PAC_THIRD_ID
                           , PAC_THIRD_ACI_ID
                           , PAC_THIRD_DELIVERY_ID
                           , PAC_THIRD_TARIFF_ID
                           , DOC_GAUGE_ID
                           , DOC_GAUGE_RECEIPT_ID
                           , DOC_GAUGE_COPY_ID
                           , C_GAUGE_TYPE_POS
                           , DIC_DELAY_UPDATE_TYPE_ID
                           , PDE_BASIS_DELAY
                           , PDE_INTERMEDIATE_DELAY
                           , PDE_FINAL_DELAY
                           , PDE_SQM_ACCEPTED_DELAY
                           , PDE_BASIS_QUANTITY
                           , PDE_INTERMEDIATE_QUANTITY
                           , PDE_FINAL_QUANTITY
                           , PDE_BALANCE_QUANTITY
                           , PDE_BALANCE_QUANTITY_PARENT
                           , PDE_BASIS_QUANTITY_SU
                           , PDE_INTERMEDIATE_QUANTITY_SU
                           , PDE_FINAL_QUANTITY_SU
                           , PDE_MOVEMENT_QUANTITY
                           , PDE_MOVEMENT_VALUE
                           , PDE_CHARACTERIZATION_VALUE_1
                           , PDE_CHARACTERIZATION_VALUE_2
                           , PDE_CHARACTERIZATION_VALUE_3
                           , PDE_CHARACTERIZATION_VALUE_4
                           , PDE_CHARACTERIZATION_VALUE_5
                           , PDE_DELAY_UPDATE_TEXT
                           , PDE_DECIMAL_1
                           , PDE_DECIMAL_2
                           , PDE_DECIMAL_3
                           , PDE_TEXT_1
                           , PDE_TEXT_2
                           , PDE_TEXT_3
                           , PDE_DATE_1
                           , PDE_DATE_2
                           , PDE_DATE_3
                           , PDE_GENERATE_MOVEMENT
                           , DCD_QUANTITY
                           , DCD_QUANTITY_SU
                           , DCD_BALANCE_FLAG
                           , POS_CONVERT_FACTOR
                           , POS_CONVERT_FACTOR_CALC
                           , POS_GROSS_UNIT_VALUE
                           , POS_GROSS_UNIT_VALUE_INCL
                           , POS_UNIT_OF_MEASURE_ID
                           , POS_UTIL_COEFF
                           , FAL_NETWORK_LINK_ID
                           , DCD_VISIBLE
                           , A_DATECRE
                           , A_IDCRE
                           , PDE_ST_PT_REJECT
                           , PDE_ST_CPT_REJECT
                            )
                  (select PDE.DOC_POSITION_DETAIL_ID
                        , ANewDocumentID
                        , tplDischargePdeCPT.CRG_SELECT
                        , PDE.DOC_GAUGE_FLOW_ID
                        , PDE.DOC_POSITION_ID
                        , POS.DOC_DOC_POSITION_ID
                        , PDE.DOC_DOC_POSITION_DETAIL_ID
                        , PDE.DOC2_DOC_POSITION_DETAIL_ID
                        , POS.GCO_GOOD_ID
                        , SPO.STM_LOCATION_ID
                        , SPO.GCO_CHARACTERIZATION_ID
                        , SPO.GCO_GCO_CHARACTERIZATION_ID
                        , SPO.GCO2_GCO_CHARACTERIZATION_ID
                        , SPO.GCO3_GCO_CHARACTERIZATION_ID
                        , SPO.GCO4_GCO_CHARACTERIZATION_ID
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
                        , SPO.SPO_CHARACTERIZATION_VALUE_1
                        , SPO.SPO_CHARACTERIZATION_VALUE_2
                        , SPO.SPO_CHARACTERIZATION_VALUE_3
                        , SPO.SPO_CHARACTERIZATION_VALUE_4
                        , SPO.SPO_CHARACTERIZATION_VALUE_5
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
                        , least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                              , ACS_FUNCTION.RoundNear(tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                     , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                     , 0
                                                      )
                               ) DCD_QUANTITY
                        , ACS_FUNCTION.RoundNear(least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                     , tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                      ) *
                                                 POS.POS_CONVERT_FACTOR
                                               , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                               , 1
                                                ) DCD_QUANTITY_SU
                        , 0 DCD_BALANCE_FLAG
                        , POS.POS_CONVERT_FACTOR
                        , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                        , POS.POS_GROSS_UNIT_VALUE
                        , POS.POS_GROSS_UNIT_VALUE_INCL
                        , POS.DIC_UNIT_OF_MEASURE_ID
                        , POS.POS_UTIL_COEFF
                        , FLN.FAL_NETWORK_LINK_ID
                        , 0   -- DCD_VISIBLE
                        , sysdate
                        , PCS.PC_I_LIB_SESSION.GetUserIni
                        , tplDischargePdeCPT.PDE_ST_PT_REJECT
                        , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                     from DOC_POSITION_DETAIL PDE
                        , DOC_POSITION POS
                        , DOC_DOCUMENT DMT
                        , FAL_NETWORK_LINK FLN
                        , FAL_NETWORK_NEED FAN
                        , STM_STOCK_POSITION SPO
                        , GCO_GOOD GOO
                        , GCO_PRODUCT PDT
                    where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                      and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                      and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                      and PDE.PDE_BALANCE_QUANTITY > 0
                      and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                      and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                      and FLN.STM_STOCK_POSITION_ID(+) is not null
                      and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                      and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                      and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
              else
                /* Si un gabarit position est lié. Les cpts sont indépendants du PT.
                   Pour garantir cela, il faut inserer directement dans la table.
                   En effet, la quantité du composant est toujours le min de la
                   quantité attribuée et de la quantité solde. */
                insert into V_DOC_POS_DET_COPY_DISCHARGE
                            (DOC_POSITION_DETAIL_ID
                           , NEW_DOCUMENT_ID
                           , CRG_SELECT
                           , DOC_GAUGE_FLOW_ID
                           , DOC_POSITION_ID
                           , DOC_DOC_POSITION_ID
                           , DOC_DOC_POSITION_DETAIL_ID
                           , DOC2_DOC_POSITION_DETAIL_ID
                           , GCO_GOOD_ID
                           , STM_LOCATION_ID
                           , GCO_CHARACTERIZATION_ID
                           , GCO_GCO_CHARACTERIZATION_ID
                           , GCO2_GCO_CHARACTERIZATION_ID
                           , GCO3_GCO_CHARACTERIZATION_ID
                           , GCO4_GCO_CHARACTERIZATION_ID
                           , STM_STM_LOCATION_ID
                           , DIC_PDE_FREE_TABLE_1_ID
                           , DIC_PDE_FREE_TABLE_2_ID
                           , DIC_PDE_FREE_TABLE_3_ID
                           , FAL_SCHEDULE_STEP_ID
                           , DOC_DOCUMENT_ID
                           , PAC_THIRD_ID
                           , PAC_THIRD_ACI_ID
                           , PAC_THIRD_DELIVERY_ID
                           , PAC_THIRD_TARIFF_ID
                           , DOC_GAUGE_ID
                           , DOC_GAUGE_RECEIPT_ID
                           , DOC_GAUGE_COPY_ID
                           , C_GAUGE_TYPE_POS
                           , DIC_DELAY_UPDATE_TYPE_ID
                           , PDE_BASIS_DELAY
                           , PDE_INTERMEDIATE_DELAY
                           , PDE_FINAL_DELAY
                           , PDE_SQM_ACCEPTED_DELAY
                           , PDE_BASIS_QUANTITY
                           , PDE_INTERMEDIATE_QUANTITY
                           , PDE_FINAL_QUANTITY
                           , PDE_BALANCE_QUANTITY
                           , PDE_BALANCE_QUANTITY_PARENT
                           , PDE_BASIS_QUANTITY_SU
                           , PDE_INTERMEDIATE_QUANTITY_SU
                           , PDE_FINAL_QUANTITY_SU
                           , PDE_MOVEMENT_QUANTITY
                           , PDE_MOVEMENT_VALUE
                           , PDE_CHARACTERIZATION_VALUE_1
                           , PDE_CHARACTERIZATION_VALUE_2
                           , PDE_CHARACTERIZATION_VALUE_3
                           , PDE_CHARACTERIZATION_VALUE_4
                           , PDE_CHARACTERIZATION_VALUE_5
                           , PDE_DELAY_UPDATE_TEXT
                           , PDE_DECIMAL_1
                           , PDE_DECIMAL_2
                           , PDE_DECIMAL_3
                           , PDE_TEXT_1
                           , PDE_TEXT_2
                           , PDE_TEXT_3
                           , PDE_DATE_1
                           , PDE_DATE_2
                           , PDE_DATE_3
                           , PDE_GENERATE_MOVEMENT
                           , DCD_QUANTITY
                           , DCD_QUANTITY_SU
                           , DCD_BALANCE_FLAG
                           , POS_CONVERT_FACTOR
                           , POS_CONVERT_FACTOR_CALC
                           , POS_GROSS_UNIT_VALUE
                           , POS_GROSS_UNIT_VALUE_INCL
                           , POS_UNIT_OF_MEASURE_ID
                           , POS_UTIL_COEFF
                           , FAL_NETWORK_LINK_ID
                           , DCD_VISIBLE
                           , A_DATECRE
                           , A_IDCRE
                           , PDE_ST_PT_REJECT
                           , PDE_ST_CPT_REJECT
                            )
                  (select PDE.DOC_POSITION_DETAIL_ID
                        , ANewDocumentID
                        , tplDischargePdeCPT.CRG_SELECT
                        , PDE.DOC_GAUGE_FLOW_ID
                        , PDE.DOC_POSITION_ID
                        , POS.DOC_DOC_POSITION_ID
                        , PDE.DOC_DOC_POSITION_DETAIL_ID
                        , PDE.DOC2_DOC_POSITION_DETAIL_ID
                        , POS.GCO_GOOD_ID
                        , SPO.STM_LOCATION_ID
                        , SPO.GCO_CHARACTERIZATION_ID
                        , SPO.GCO_GCO_CHARACTERIZATION_ID
                        , SPO.GCO2_GCO_CHARACTERIZATION_ID
                        , SPO.GCO3_GCO_CHARACTERIZATION_ID
                        , SPO.GCO4_GCO_CHARACTERIZATION_ID
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
                        , SPO.SPO_CHARACTERIZATION_VALUE_1
                        , SPO.SPO_CHARACTERIZATION_VALUE_2
                        , SPO.SPO_CHARACTERIZATION_VALUE_3
                        , SPO.SPO_CHARACTERIZATION_VALUE_4
                        , SPO.SPO_CHARACTERIZATION_VALUE_5
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
                        , least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                              , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                     , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                     , 0
                                                      )
                               ) DCD_QUANTITY
                        , ACS_FUNCTION.RoundNear(least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                     , PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                      ) *
                                                 POS.POS_CONVERT_FACTOR
                                               , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                               , 1
                                                ) DCD_QUANTITY_SU
                        , 0 DCD_BALANCE_FLAG
                        , POS.POS_CONVERT_FACTOR
                        , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                        , POS.POS_GROSS_UNIT_VALUE
                        , POS.POS_GROSS_UNIT_VALUE_INCL
                        , POS.DIC_UNIT_OF_MEASURE_ID
                        , POS.POS_UTIL_COEFF
                        , FLN.FAL_NETWORK_LINK_ID
                        , 0   -- DCD_VISIBLE
                        , sysdate
                        , PCS.PC_I_LIB_SESSION.GetUserIni
                        , tplDischargePdeCPT.PDE_ST_PT_REJECT
                        , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                     from DOC_POSITION_DETAIL PDE
                        , DOC_POSITION POS
                        , DOC_DOCUMENT DMT
                        , FAL_NETWORK_LINK FLN
                        , FAL_NETWORK_NEED FAN
                        , STM_STOCK_POSITION SPO
                        , GCO_GOOD GOO
                        , GCO_PRODUCT PDT
                    where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                      and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                      and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                      and PDE.PDE_BALANCE_QUANTITY > 0
                      and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                      and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                      and FLN.STM_STOCK_POSITION_ID(+) is not null
                      and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                      and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                      and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
              end if;
            end loop;
          end if;
        end if;
      end loop;
    end loop;
  end InsertDischargeDetailAttrib;

  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base de la quantité solde
  */
  procedure InsertDischargeDetailBalance(
    ANewDocumentID in number
  , ADocumentList  in varchar2
  , ARecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , AReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crDischargePde(ADocumentID in number)
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
                    , PDE.PDE_BALANCE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, DMT_TGT.DOC_GAUGE_ID, DMT_TGT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
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
                    , DOC_RECORD RCO
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE_POSITION GAP_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   AReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(AReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = ADocumentID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (    exists(
                                                       select DOC_GAUGE_POSITION_ID
                                                         from DOC_GAUGE_POSITION GAP_LINK
                                                        where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                          and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                 and (exists(
                                                        select POS_CPT.DOC_POSITION_ID
                                                          from DOC_POSITION POS_CPT
                                                         where POS_CPT.DOC_DOC_POSITION_ID = POS2.DOC_POSITION_ID
                                                           and POS_CPT.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
                                                           and POS_CPT.C_DOC_POS_STATUS < '04')
                                                     )
                                                )
                                            )
                                          )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101', '21') )
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
                  and DOC_I_LIB_GAUGE.CanReceipt(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePde    crDischargePde%rowtype;

    cursor crDischargePdeCPT(APositionID in number)
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
                    , PDE.PDE_BALANCE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
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
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle) )
                  and POS.DOC_DOC_POSITION_ID = APositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = ANewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT crDischargePdeCPT%rowtype;
    --
    vNewDcdID          DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd         V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt      V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    currentPositionID  DOC_POSITION.DOC_POSITION_ID%type;
    cGaugeTypePos      DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Balayer la liste des documents à décharger
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      open crDischargePde(tplDoc.DOC_DOCUMENT_ID);

      fetch crDischargePde
       into tplDischargePde;

      -- Tant qu'il reste des détails à traiter
      while crDischargePde%found loop
        -- Mémorise la position courante pour déterminer un changement de position ainsi que le type de position.
        currentPositionID                         := tplDischargePde.DOC_POSITION_ID;
        cGaugeTypePos                             := tplDischargePde.C_GAUGE_TYPE_POS;

        select init_id_seq.nextval
          into vNewDcdID
          from dual;

        -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
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
        vInsertDcd.DOC_RECORD_ID                  := tplDischargePde.DOC_RECORD_ID;
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
        vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
        vInsertDcd.DCD_QUANTITY                   := tplDischargePde.DCD_QUANTITY;
        vInsertDcd.DCD_QUANTITY_SU                := tplDischargePde.DCD_QUANTITY_SU;
        vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
        vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
        vInsertDcd.POS_CONVERT_FACTOR_CALC        := nvl(vConvertFactorCalc, tplDischargePde.POS_CONVERT_FACTOR);
        vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
        vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
        vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
        vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
        vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
        vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
        vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
        vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
        vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

        insert into V_DOC_POS_DET_COPY_DISCHARGE
             values vInsertDcd;

        fetch crDischargePde
         into tplDischargePde;

        -- Détermine si des composants doivent être créés sur la base d'un éventuel produit terminé.
        -- C'est uniquement après la création du dernier détail du produit terminé que la création des composants
        -- doit s'effectuer.
        if cGaugeTypePos in('7', '8', '9', '10') then
          -- Dernier record ou changement de position
          if    not crDischargePde%found
             or currentPositionID <> tplDischargePde.DOC_POSITION_ID then
            -- Traitement des détails de positions composants.
            for tplDischargePdeCPT in crDischargePdeCPT(currentPositionID) loop
              -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
              vInsertDcdCpt                               := null;
              vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
              vInsertDcdCpt.NEW_DOCUMENT_ID               := tplDischargePdeCPT.NEW_DOCUMENT_ID;

              -- C'est uniquement la quantité solde du composant qui influence l'indicateur de sélection. Attention, toutefois, dans
              -- le cas ou la quantité du composant est à 0, il faut tout de même séléctionner le composant. Voir DEVLOG-14824.
              if     (tplDischargePdeCPT.PDE_BALANCE_QUANTITY = 0)
                 and (tplDischargePdeCPT.PDE_BASIS_QUANTITY <> 0) then
                vInsertDcdCpt.CRG_SELECT  := 0;
              else
                vInsertDcdCpt.CRG_SELECT  := 1;
              end if;

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
              vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
              vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
              vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
              vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

              insert into V_DOC_POS_DET_COPY_DISCHARGE
                   values vInsertDcdCpt;
            end loop;   -- for tplDischargePdeCPT
          end if;
        end if;
      end loop;   -- crDischargePde%found

      close crDischargePde;
    end loop;   -- for tplDoc
  end InsertDischargeDetailBalance;

  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base des
  *    attributions sur stock pour ce qui concerne les positions simple (type 1,2,3) et
  *    les composants (avec lien sur PT). Par contre, pour les PT on tient compte de
  *    l'ensemble des détails fils pour définir leurs quantités. Les composants et
  *    positions normales non attribués ne sont pas sélectionnés. Un paramètre permet
  *    de sélectionner ou non les composants non attribués (avec une quantité à 0). Cela permet
  *    de faire apparaitre, sur le document fils, les composants que l'on a pas réussi à livrer.
  */
  procedure InsertDischargeAttribFull(
    ANewDocumentID     in number
  , ADocumentList      in varchar2
  , ARecordTitle       in DOC_RECORD.RCO_TITLE%type default null
  , AReference         in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , ASelectUnAttribCPT in number default 1
  )
  is
    cursor crQuantityPT(aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    is
      select   decode(nvl(POS_CPT.POS_UTIL_COEFF, 0)
                    , 0, 0
                    , DOC_ATTRIB_FUNCTIONS.GetDischargedQuantity(POS_CPT.DOC_POSITION_ID) / decode(nvl(POS_CPT.POS_UTIL_COEFF, 0)
                                                                                                 , 0, 1
                                                                                                 , POS_CPT.POS_UTIL_COEFF
                                                                                                  )
                     ) +
               decode(nvl(POS_CPT.POS_UTIL_COEFF, 0)
                    , 0, 0
                    , nvl(DOC_ATTRIB_FUNCTIONS.GetAttribQuantity(POS_CPT.DOC_POSITION_ID), 0) /
                      decode(nvl(POS_CPT.POS_UTIL_COEFF, 0), 0, 1, POS_CPT.POS_UTIL_COEFF)
                     ) QUANTITY_PT
          from DOC_POSITION_DETAIL PDE_CPT
             , DOC_POSITION POS_CPT
         where POS_CPT.DOC_DOC_POSITION_ID = aPositionID
           and PDE_CPT.DOC_POSITION_ID = POS_CPT.DOC_POSITION_ID
      order by 1;

    tplQuantityPT              crQuantityPT%rowtype;

    cursor crDischargePde(ADocumentID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , decode(POS.C_GAUGE_TYPE_POS
                           , '1', decode(PDT.PDT_STOCK_MANAGEMENT
                                       , 1, decode(PDT.C_PRODUCT_DELIVERY_TYP
                                                 , '2', 1
                                                 , decode(CUS.C_DELIVERY_TYP, '2', 1, decode(FLN.FLN_QTY, null, 0, 0, 0, 1) )
                                                  )
                                       , 1
                                        )
                           , '7', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribsPartial(POS.DOC_POSITION_ID)
                           , '8', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribsPartial(POS.DOC_POSITION_ID)
                           , '9', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribsPartial(POS.DOC_POSITION_ID)
                           , '10', DOC_ATTRIB_FUNCTIONS.CtrlComponentsAttribsPartial(POS.DOC_POSITION_ID)
                           , 1
                            ) as CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , nvl(SPO.STM_LOCATION_ID, PDE.STM_LOCATION_ID) STM_LOCATION_ID
                    , nvl(SPO.GCO_CHARACTERIZATION_ID, PDE.GCO_CHARACTERIZATION_ID) GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO.GCO_GCO_CHARACTERIZATION_ID) GCO_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.GCO2_GCO_CHARACTERIZATION_ID) GCO2_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.GCO3_GCO_CHARACTERIZATION_ID) GCO3_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.GCO4_GCO_CHARACTERIZATION_ID) GCO4_GCO_CHARACTERIZATION_ID
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
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, PDE.PDE_CHARACTERIZATION_VALUE_1) SPO_CHARACTERIZATION_VALUE_1
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, PDE.PDE_CHARACTERIZATION_VALUE_2) SPO_CHARACTERIZATION_VALUE_2
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, PDE.PDE_CHARACTERIZATION_VALUE_3) SPO_CHARACTERIZATION_VALUE_3
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, PDE.PDE_CHARACTERIZATION_VALUE_4) SPO_CHARACTERIZATION_VALUE_4
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, PDE.PDE_CHARACTERIZATION_VALUE_5) SPO_CHARACTERIZATION_VALUE_5
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
                    , decode(PDE.PDE_BALANCE_QUANTITY
                           , 0, 0
                           , decode(POS.C_GAUGE_TYPE_POS
                                  , '1', decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY / POS.POS_CONVERT_FACTOR, 0), PDE.PDE_BALANCE_QUANTITY)
                                  , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribCPTQuantityReal(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribCPTQuantityReal(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribCPTQuantityReal(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribCPTQuantityReal(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , PDE.PDE_BALANCE_QUANTITY
                                   )
                            ) DCD_QUANTITY
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, DMT_TGT.DOC_GAUGE_ID, DMT_TGT.PAC_THIRD_ID) as DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , FLN.FAL_NETWORK_LINK_ID
                    , GAP.DOC_DOC_GAUGE_POSITION_ID
                    , GOO.GOO_NUMBER_OF_DECIMAL
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_POSITION GAP
                    , GCO_PRODUCT PDT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , DOC_RECORD RCO
                    , DOC_GAUGE_POSITION GAP_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   AReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(AReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = ADocumentID
                           and (    (     ( (       POS2.C_DOC_POS_STATUS in('02', '03')
                                                and (   PDE2.PDE_BALANCE_QUANTITY <> 0
                                                     or nvl(PDE2.PDE_FINAL_QUANTITY, 0) = 0)
                                             or (    exists(
                                                       select DOC_GAUGE_POSITION_ID
                                                         from DOC_GAUGE_POSITION GAP_LINK
                                                        where GAP_LINK.DOC_GAUGE_POSITION_ID = POS2.DOC_GAUGE_POSITION_ID
                                                          and GAP_LINK.DOC_DOC_GAUGE_POSITION_ID is not null)
                                                 and (exists(
                                                        select POS_CPT.DOC_POSITION_ID
                                                          from DOC_POSITION POS_CPT
                                                         where POS_CPT.DOC_DOC_POSITION_ID = POS2.DOC_POSITION_ID
                                                           and POS_CPT.DOC_DOCUMENT_ID = POS2.DOC_DOCUMENT_ID
                                                           and POS_CPT.C_DOC_POS_STATUS < '04')
                                                     )
                                                )
                                            )
                                          )
                                     and POS2.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                                     and POS2.DOC_DOC_POSITION_ID is null
                                    )
                                or (POS2.C_GAUGE_TYPE_POS not in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101', '21') )
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
                  and DOC_I_LIB_GAUGE.CanReceipt(DMT.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, PDE.DOC_POSITION_DETAIL_ID) > 0
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePde            crDischargePde%rowtype;

    cursor crDischargePdeCPT(APositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , DCD.DCD_QUANTITY
                    , POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = APositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = ANewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT         crDischargePdeCPT%rowtype;
    vNewDcdID                  DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    nSumQtyAlreadyDischargedPT DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    nQuantityPT                DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    nQuantityPT_SU             DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    vConvertFactorCalc         GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
  begin
    -- Balayer la liste des documents à décharger
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      for tplDischargePde in crDischargePde(tplDoc.DOC_DOCUMENT_ID) loop
        select init_id_seq.nextval
          into vNewDcdID
          from dual;

        -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
        -- Il faut rechercher le facteur de conversion calculé.
        vConvertFactorCalc  :=
          GCO_FUNCTIONS.GetThirdConvertFactor(tplDischargePde.GCO_GOOD_ID
                                            , tplDischargePde.PAC_THIRD_CDA_ID
                                            , tplDischargePde.C_GAUGE_TYPE_POS
                                            , null
                                            , tplDischargePde.TGT_PAC_THIRD_CDA_ID
                                            , tplDischargePde.TGT_C_ADMIN_DOMAIN
                                             );

        ----
        -- Recherche la somme des détails fils lié au produit terminé (position de type 7, 8, 9, 10)
        --
        begin
          select nvl(sum(PDE_SONS.PDE_FINAL_QUANTITY), 0)
            into nSumQtyAlreadyDischargedPT
            from DOC_POSITION_DETAIL PDE_SONS
               , DOC_POSITION POS_SONS
           where PDE_SONS.DOC_DOC_POSITION_DETAIL_ID = tplDischargePde.DOC_POSITION_DETAIL_ID
             and POS_SONS.DOC_POSITION_ID = PDE_SONS.DOC_POSITION_ID
             and POS_SONS.C_GAUGE_TYPE_POS in('7', '8', '9', '10');
        exception
          when no_data_found then
            nSumQtyAlreadyDischargedPT  := 0;
        end;

        if (nSumQtyAlreadyDischargedPT = 0) then
          nQuantityPT  := trunc(tplDischargePde.DCD_QUANTITY);
        else
          ----
          -- Détermine la quantité du produit terminé en tenant compte de la quantité déjà déchargé pour le produit terminé et
          -- de la quantité déjà déchargé pour ces composants. Dans le calcul, la quantité déjà réservé (attribuée) des composants
          -- intervient également. Ce traitement permet de garantir la livraison de kit complet.
          ----
          open crQuantityPT(tplDischargePde.DOC_POSITION_ID);

          -- Recherche la quantité exprimé dans la quantité du produit terminé (en tenant compte du coefficient d'utilisation de chaque
          -- composant). Utilise la plus petit quantité de chaque composant.
          --
          -- quantité CPT = quantité déchargée (quantité finale + quantité soldée sur parent) + quantité attribuée
          -- quantité PT = quantité CPT la plus petite / coefficient d'utilisation
          --
          fetch crQuantityPT
           into tplQuantityPT;

          nQuantityPT  := tplQuantityPT.QUANTITY_PT;

          ----
          -- Si la quantité déjà déchargé du PT est plus petite ou égale à la futur quantité du PT, on retire ce qui est déjà déchargé de
          -- la future quantité du PT, sinon on considère qu'il n'y a pas suffisement de quantité disponible sur les composants et cours de
          -- livraison pour pouvoir facturer le produit terminé.
          --
          if (nSumQtyAlreadyDischargedPT <= nQuantityPT) then
            nQuantityPT  := trunc(nQuantityPT - nSumQtyAlreadyDischargedPT);
          else
            nQuantityPT  := 0;
          end if;

          close crQuantityPT;
        end if;

        -- Calcul la quantité du produit terminé en unité de stockage
        nQuantityPT_SU      := ACS_FUNCTION.RoundNear(nQuantityPT, 1 / power(10, nvl(tplDischargePde.GOO_NUMBER_OF_DECIMAL, 0) ), 0);

        insert into V_DOC_POS_DET_COPY_DISCHARGE
                    (DOC_POS_DET_COPY_DISCHARGE_ID
                   , DOC_POSITION_DETAIL_ID
                   , NEW_DOCUMENT_ID
                   , CRG_SELECT
                   , DOC_GAUGE_FLOW_ID
                   , DOC_POSITION_ID
                   , DOC_DOC_POSITION_ID
                   , DOC_DOC_POSITION_DETAIL_ID
                   , DOC2_DOC_POSITION_DETAIL_ID
                   , GCO_GOOD_ID
                   , STM_LOCATION_ID
                   , GCO_CHARACTERIZATION_ID
                   , GCO_GCO_CHARACTERIZATION_ID
                   , GCO2_GCO_CHARACTERIZATION_ID
                   , GCO3_GCO_CHARACTERIZATION_ID
                   , GCO4_GCO_CHARACTERIZATION_ID
                   , STM_STM_LOCATION_ID
                   , DIC_PDE_FREE_TABLE_1_ID
                   , DIC_PDE_FREE_TABLE_2_ID
                   , DIC_PDE_FREE_TABLE_3_ID
                   , FAL_SCHEDULE_STEP_ID
                   , DOC_RECORD_ID
                   , DOC_DOCUMENT_ID
                   , PAC_THIRD_ID
                   , PAC_THIRD_ACI_ID
                   , PAC_THIRD_DELIVERY_ID
                   , PAC_THIRD_TARIFF_ID
                   , DOC_GAUGE_ID
                   , DOC_GAUGE_RECEIPT_ID
                   , DOC_GAUGE_COPY_ID
                   , C_GAUGE_TYPE_POS
                   , DIC_DELAY_UPDATE_TYPE_ID
                   , PDE_BASIS_DELAY
                   , PDE_INTERMEDIATE_DELAY
                   , PDE_FINAL_DELAY
                   , PDE_SQM_ACCEPTED_DELAY
                   , PDE_BASIS_QUANTITY
                   , PDE_INTERMEDIATE_QUANTITY
                   , PDE_FINAL_QUANTITY
                   , PDE_BALANCE_QUANTITY
                   , PDE_BALANCE_QUANTITY_PARENT
                   , PDE_BASIS_QUANTITY_SU
                   , PDE_INTERMEDIATE_QUANTITY_SU
                   , PDE_FINAL_QUANTITY_SU
                   , PDE_MOVEMENT_QUANTITY
                   , PDE_MOVEMENT_VALUE
                   , PDE_CHARACTERIZATION_VALUE_1
                   , PDE_CHARACTERIZATION_VALUE_2
                   , PDE_CHARACTERIZATION_VALUE_3
                   , PDE_CHARACTERIZATION_VALUE_4
                   , PDE_CHARACTERIZATION_VALUE_5
                   , PDE_DELAY_UPDATE_TEXT
                   , PDE_DECIMAL_1
                   , PDE_DECIMAL_2
                   , PDE_DECIMAL_3
                   , PDE_TEXT_1
                   , PDE_TEXT_2
                   , PDE_TEXT_3
                   , PDE_DATE_1
                   , PDE_DATE_2
                   , PDE_DATE_3
                   , PDE_GENERATE_MOVEMENT
                   , DCD_QUANTITY
                   , DCD_QUANTITY_SU
                   , DCD_BALANCE_FLAG
                   , POS_CONVERT_FACTOR
                   , POS_CONVERT_FACTOR_CALC
                   , POS_GROSS_UNIT_VALUE
                   , POS_GROSS_UNIT_VALUE_INCL
                   , POS_UNIT_OF_MEASURE_ID
                   , DCD_DEPLOYED_COMPONENTS
                   , FAL_NETWORK_LINK_ID
                   , DCD_VISIBLE
                   , A_DATECRE
                   , A_IDCRE
                   , PDE_ST_PT_REJECT
                   , PDE_ST_CPT_REJECT
                    )
             values (vNewDcdID
                   , tplDischargePde.DOC_POSITION_DETAIL_ID
                   , ANewDocumentID
                   , tplDischargePde.CRG_SELECT
                   , tplDischargePde.DOC_GAUGE_FLOW_ID
                   , tplDischargePde.DOC_POSITION_ID
                   , tplDischargePde.DOC_DOC_POSITION_ID
                   , tplDischargePde.DOC_DOC_POSITION_DETAIL_ID
                   , tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID
                   , tplDischargePde.GCO_GOOD_ID
                   , tplDischargePde.STM_LOCATION_ID
                   , tplDischargePde.GCO_CHARACTERIZATION_ID
                   , tplDischargePde.GCO_GCO_CHARACTERIZATION_ID
                   , tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID
                   , tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID
                   , tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID
                   , tplDischargePde.STM_STM_LOCATION_ID
                   , tplDischargePde.DIC_PDE_FREE_TABLE_1_ID
                   , tplDischargePde.DIC_PDE_FREE_TABLE_2_ID
                   , tplDischargePde.DIC_PDE_FREE_TABLE_3_ID
                   , tplDischargePde.FAL_SCHEDULE_STEP_ID
                   , tplDischargePde.DOC_RECORD_ID
                   , tplDischargePde.DOC_DOCUMENT_ID
                   , tplDischargePde.PAC_THIRD_ID
                   , tplDischargePde.PAC_THIRD_ACI_ID
                   , tplDischargePde.PAC_THIRD_DELIVERY_ID
                   , tplDischargePde.PAC_THIRD_TARIFF_ID
                   , tplDischargePde.DOC_GAUGE_ID
                   , tplDischargePde.DOC_GAUGE_RECEIPT_ID
                   , tplDischargePde.DOC_GAUGE_COPY_ID
                   , tplDischargePde.C_GAUGE_TYPE_POS
                   , tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID
                   , tplDischargePde.PDE_BASIS_DELAY
                   , tplDischargePde.PDE_INTERMEDIATE_DELAY
                   , tplDischargePde.PDE_FINAL_DELAY
                   , tplDischargePde.PDE_SQM_ACCEPTED_DELAY
                   , tplDischargePde.PDE_BASIS_QUANTITY
                   , tplDischargePde.PDE_INTERMEDIATE_QUANTITY
                   , tplDischargePde.PDE_FINAL_QUANTITY
                   , tplDischargePde.PDE_BALANCE_QUANTITY
                   , tplDischargePde.PDE_BALANCE_QUANTITY_PARENT
                   , tplDischargePde.PDE_BASIS_QUANTITY_SU
                   , tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU
                   , tplDischargePde.PDE_FINAL_QUANTITY_SU
                   , tplDischargePde.PDE_MOVEMENT_QUANTITY
                   , tplDischargePde.PDE_MOVEMENT_VALUE
                   , tplDischargePde.SPO_CHARACTERIZATION_VALUE_1
                   , tplDischargePde.SPO_CHARACTERIZATION_VALUE_2
                   , tplDischargePde.SPO_CHARACTERIZATION_VALUE_3
                   , tplDischargePde.SPO_CHARACTERIZATION_VALUE_4
                   , tplDischargePde.SPO_CHARACTERIZATION_VALUE_5
                   , tplDischargePde.PDE_DELAY_UPDATE_TEXT
                   , tplDischargePde.PDE_DECIMAL_1
                   , tplDischargePde.PDE_DECIMAL_2
                   , tplDischargePde.PDE_DECIMAL_3
                   , tplDischargePde.PDE_TEXT_1
                   , tplDischargePde.PDE_TEXT_2
                   , tplDischargePde.PDE_TEXT_3
                   , tplDischargePde.PDE_DATE_1
                   , tplDischargePde.PDE_DATE_2
                   , tplDischargePde.PDE_DATE_3
                   , tplDischargePde.PDE_GENERATE_MOVEMENT
                   , nQuantityPT
                   , nQuantityPT_SU
                   , tplDischargePde.DCD_BALANCE_FLAG
                   , tplDischargePde.POS_CONVERT_FACTOR
                   , nvl(vConvertFactorCalc, tplDischargePde.POS_CONVERT_FACTOR)
                   , tplDischargePde.POS_GROSS_UNIT_VALUE
                   , tplDischargePde.POS_GROSS_UNIT_VALUE_INCL
                   , tplDischargePde.DIC_UNIT_OF_MEASURE_ID
                   , tplDischargePde.DCD_DEPLOYED_COMPONENTS
                   , tplDischargePde.FAL_NETWORK_LINK_ID
                   , 0   -- DCD_VISIBLE
                   , tplDischargePde.NEW_A_DATECRE
                   , tplDischargePde.NEW_A_IDCRE
                   , tplDischargePde.PDE_ST_PT_REJECT
                   , tplDischargePde.PDE_ST_CPT_REJECT
                    );

        -- Traitement d'une position kit ou assemblage
        if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
          -- Traitement des détails de positions composants.
          for tplDischargePdeCPT in crDischargePdeCPT(tplDischargePde.DOC_POSITION_ID) loop
            if tplDischargePde.DOC_DOC_GAUGE_POSITION_ID is null then
              /* Si aucun gabarit position lié. Les cpts sont toujours inférieurs
                 ou égal au PT. Pour garantir cela, il faut inserer dans la vue
                 et non directement dans la table. En effet, la vue recalcul la
                 quantité du composant en fonction du PT. */
              insert into V_DOC_POS_DET_COPY_DISCHARGE
                          (DOC_POSITION_DETAIL_ID
                         , NEW_DOCUMENT_ID
                         , CRG_SELECT
                         , DOC_GAUGE_FLOW_ID
                         , DOC_POSITION_ID
                         , DOC_DOC_POSITION_ID
                         , DOC_DOC_POSITION_DETAIL_ID
                         , DOC2_DOC_POSITION_DETAIL_ID
                         , GCO_GOOD_ID
                         , STM_LOCATION_ID
                         , GCO_CHARACTERIZATION_ID
                         , GCO_GCO_CHARACTERIZATION_ID
                         , GCO2_GCO_CHARACTERIZATION_ID
                         , GCO3_GCO_CHARACTERIZATION_ID
                         , GCO4_GCO_CHARACTERIZATION_ID
                         , STM_STM_LOCATION_ID
                         , DIC_PDE_FREE_TABLE_1_ID
                         , DIC_PDE_FREE_TABLE_2_ID
                         , DIC_PDE_FREE_TABLE_3_ID
                         , FAL_SCHEDULE_STEP_ID
                         , DOC_DOCUMENT_ID
                         , PAC_THIRD_ID
                         , PAC_THIRD_ACI_ID
                         , PAC_THIRD_DELIVERY_ID
                         , PAC_THIRD_TARIFF_ID
                         , DOC_GAUGE_ID
                         , DOC_GAUGE_RECEIPT_ID
                         , DOC_GAUGE_COPY_ID
                         , C_GAUGE_TYPE_POS
                         , DIC_DELAY_UPDATE_TYPE_ID
                         , PDE_BASIS_DELAY
                         , PDE_INTERMEDIATE_DELAY
                         , PDE_FINAL_DELAY
                         , PDE_SQM_ACCEPTED_DELAY
                         , PDE_BASIS_QUANTITY
                         , PDE_INTERMEDIATE_QUANTITY
                         , PDE_FINAL_QUANTITY
                         , PDE_BALANCE_QUANTITY
                         , PDE_BALANCE_QUANTITY_PARENT
                         , PDE_BASIS_QUANTITY_SU
                         , PDE_INTERMEDIATE_QUANTITY_SU
                         , PDE_FINAL_QUANTITY_SU
                         , PDE_MOVEMENT_QUANTITY
                         , PDE_MOVEMENT_VALUE
                         , PDE_CHARACTERIZATION_VALUE_1
                         , PDE_CHARACTERIZATION_VALUE_2
                         , PDE_CHARACTERIZATION_VALUE_3
                         , PDE_CHARACTERIZATION_VALUE_4
                         , PDE_CHARACTERIZATION_VALUE_5
                         , PDE_DELAY_UPDATE_TEXT
                         , PDE_DECIMAL_1
                         , PDE_DECIMAL_2
                         , PDE_DECIMAL_3
                         , PDE_TEXT_1
                         , PDE_TEXT_2
                         , PDE_TEXT_3
                         , PDE_DATE_1
                         , PDE_DATE_2
                         , PDE_DATE_3
                         , PDE_GENERATE_MOVEMENT
                         , DCD_QUANTITY
                         , DCD_QUANTITY_SU
                         , DCD_BALANCE_FLAG
                         , POS_CONVERT_FACTOR
                         , POS_CONVERT_FACTOR_CALC
                         , POS_GROSS_UNIT_VALUE
                         , POS_GROSS_UNIT_VALUE_INCL
                         , POS_UNIT_OF_MEASURE_ID
                         , POS_UTIL_COEFF
                         , FAL_NETWORK_LINK_ID
                         , DCD_VISIBLE
                         , A_DATECRE
                         , A_IDCRE
                         , PDE_ST_PT_REJECT
                         , PDE_ST_CPT_REJECT
                          )
                (select PDE.DOC_POSITION_DETAIL_ID
                      , ANewDocumentID
                      , tplDischargePdeCPT.CRG_SELECT
                      , PDE.DOC_GAUGE_FLOW_ID
                      , PDE.DOC_POSITION_ID
                      , POS.DOC_DOC_POSITION_ID
                      , PDE.DOC_DOC_POSITION_DETAIL_ID
                      , PDE.DOC2_DOC_POSITION_DETAIL_ID
                      , POS.GCO_GOOD_ID
                      , SPO.STM_LOCATION_ID
                      , SPO.GCO_CHARACTERIZATION_ID
                      , SPO.GCO_GCO_CHARACTERIZATION_ID
                      , SPO.GCO2_GCO_CHARACTERIZATION_ID
                      , SPO.GCO3_GCO_CHARACTERIZATION_ID
                      , SPO.GCO4_GCO_CHARACTERIZATION_ID
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
                      , SPO.SPO_CHARACTERIZATION_VALUE_1
                      , SPO.SPO_CHARACTERIZATION_VALUE_2
                      , SPO.SPO_CHARACTERIZATION_VALUE_3
                      , SPO.SPO_CHARACTERIZATION_VALUE_4
                      , SPO.SPO_CHARACTERIZATION_VALUE_5
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
                      , least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                            , ACS_FUNCTION.RoundNear(tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                   , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                   , 0
                                                    )
                             ) DCD_QUANTITY
                      , ACS_FUNCTION.RoundNear(least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                   , tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                    ) *
                                               POS.POS_CONVERT_FACTOR
                                             , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                             , 1
                                              ) DCD_QUANTITY_SU
                      , 0 DCD_BALANCE_FLAG
                      , POS.POS_CONVERT_FACTOR
                      , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                      , POS.POS_GROSS_UNIT_VALUE
                      , POS.POS_GROSS_UNIT_VALUE_INCL
                      , POS.DIC_UNIT_OF_MEASURE_ID
                      , POS.POS_UTIL_COEFF
                      , FLN.FAL_NETWORK_LINK_ID
                      , 0   -- DCD_VISIBLE
                      , sysdate
                      , PCS.PC_I_LIB_SESSION.GetUserIni
                      , tplDischargePdeCPT.PDE_ST_PT_REJECT
                      , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                   from DOC_POSITION_DETAIL PDE
                      , DOC_POSITION POS
                      , DOC_DOCUMENT DMT
                      , FAL_NETWORK_LINK FLN
                      , FAL_NETWORK_NEED FAN
                      , STM_STOCK_POSITION SPO
                      , GCO_GOOD GOO
                      , GCO_PRODUCT PDT
                  where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                    and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                    and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                    and PDE.PDE_BALANCE_QUANTITY > 0
                    and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                    and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                    and FLN.STM_STOCK_POSITION_ID(+) is not null
                    and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                    and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                    and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
            else
              /* Si un gabarit position est lié. Les cpts sont indépendants du PT.

                 C'est dans ce context là qu'intervient la possibilité de proposer la sélection
                 ou non des composants non attribués (ASelectUnAttribCPT).

                 TODO : supprimer la distinction d'insertion dans la vue ou dans la table. Voir commentaire ci-dessous.

                 Pour garantir cela, il faut inserer directement dans la table.
                 En effet, la quantité du composant est toujours le min de la
                 quantité attribuée et de la quantité solde. */
              insert into V_DOC_POS_DET_COPY_DISCHARGE
                          (DOC_POSITION_DETAIL_ID
                         , NEW_DOCUMENT_ID
                         , CRG_SELECT
                         , DOC_GAUGE_FLOW_ID
                         , DOC_POSITION_ID
                         , DOC_DOC_POSITION_ID
                         , DOC_DOC_POSITION_DETAIL_ID
                         , DOC2_DOC_POSITION_DETAIL_ID
                         , GCO_GOOD_ID
                         , STM_LOCATION_ID
                         , GCO_CHARACTERIZATION_ID
                         , GCO_GCO_CHARACTERIZATION_ID
                         , GCO2_GCO_CHARACTERIZATION_ID
                         , GCO3_GCO_CHARACTERIZATION_ID
                         , GCO4_GCO_CHARACTERIZATION_ID
                         , STM_STM_LOCATION_ID
                         , DIC_PDE_FREE_TABLE_1_ID
                         , DIC_PDE_FREE_TABLE_2_ID
                         , DIC_PDE_FREE_TABLE_3_ID
                         , FAL_SCHEDULE_STEP_ID
                         , DOC_DOCUMENT_ID
                         , PAC_THIRD_ID
                         , PAC_THIRD_ACI_ID
                         , PAC_THIRD_DELIVERY_ID
                         , PAC_THIRD_TARIFF_ID
                         , DOC_GAUGE_ID
                         , DOC_GAUGE_RECEIPT_ID
                         , DOC_GAUGE_COPY_ID
                         , C_GAUGE_TYPE_POS
                         , DIC_DELAY_UPDATE_TYPE_ID
                         , PDE_BASIS_DELAY
                         , PDE_INTERMEDIATE_DELAY
                         , PDE_FINAL_DELAY
                         , PDE_SQM_ACCEPTED_DELAY
                         , PDE_BASIS_QUANTITY
                         , PDE_INTERMEDIATE_QUANTITY
                         , PDE_FINAL_QUANTITY
                         , PDE_BALANCE_QUANTITY
                         , PDE_BALANCE_QUANTITY_PARENT
                         , PDE_BASIS_QUANTITY_SU
                         , PDE_INTERMEDIATE_QUANTITY_SU
                         , PDE_FINAL_QUANTITY_SU
                         , PDE_MOVEMENT_QUANTITY
                         , PDE_MOVEMENT_VALUE
                         , PDE_CHARACTERIZATION_VALUE_1
                         , PDE_CHARACTERIZATION_VALUE_2
                         , PDE_CHARACTERIZATION_VALUE_3
                         , PDE_CHARACTERIZATION_VALUE_4
                         , PDE_CHARACTERIZATION_VALUE_5
                         , PDE_DELAY_UPDATE_TEXT
                         , PDE_DECIMAL_1
                         , PDE_DECIMAL_2
                         , PDE_DECIMAL_3
                         , PDE_TEXT_1
                         , PDE_TEXT_2
                         , PDE_TEXT_3
                         , PDE_DATE_1
                         , PDE_DATE_2
                         , PDE_DATE_3
                         , PDE_GENERATE_MOVEMENT
                         , DCD_QUANTITY
                         , DCD_QUANTITY_SU
                         , DCD_BALANCE_FLAG
                         , POS_CONVERT_FACTOR
                         , POS_CONVERT_FACTOR_CALC
                         , POS_GROSS_UNIT_VALUE
                         , POS_GROSS_UNIT_VALUE_INCL
                         , POS_UNIT_OF_MEASURE_ID
                         , POS_UTIL_COEFF
                         , FAL_NETWORK_LINK_ID
                         , DCD_VISIBLE
                         , A_DATECRE
                         , A_IDCRE
                         , PDE_ST_PT_REJECT
                         , PDE_ST_CPT_REJECT
                          )
                (select PDE.DOC_POSITION_DETAIL_ID
                      , ANewDocumentID
                      , decode(nvl(ASelectUnAttribCPT, 1)
                             , 1, tplDischargePdeCPT.CRG_SELECT
                             , decode(least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                          , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                                 , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                                 , 0
                                                                  )
                                           )
                                    , 0, 0
                                    , tplDischargePdeCPT.CRG_SELECT
                                     )
                              )
                      , PDE.DOC_GAUGE_FLOW_ID
                      , PDE.DOC_POSITION_ID
                      , POS.DOC_DOC_POSITION_ID
                      , PDE.DOC_DOC_POSITION_DETAIL_ID
                      , PDE.DOC2_DOC_POSITION_DETAIL_ID
                      , POS.GCO_GOOD_ID
                      , SPO.STM_LOCATION_ID
                      , SPO.GCO_CHARACTERIZATION_ID
                      , SPO.GCO_GCO_CHARACTERIZATION_ID
                      , SPO.GCO2_GCO_CHARACTERIZATION_ID
                      , SPO.GCO3_GCO_CHARACTERIZATION_ID
                      , SPO.GCO4_GCO_CHARACTERIZATION_ID
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
                      , SPO.SPO_CHARACTERIZATION_VALUE_1
                      , SPO.SPO_CHARACTERIZATION_VALUE_2
                      , SPO.SPO_CHARACTERIZATION_VALUE_3
                      , SPO.SPO_CHARACTERIZATION_VALUE_4
                      , SPO.SPO_CHARACTERIZATION_VALUE_5
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
                      , least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                            , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1), 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                                   , 0)
                             ) DCD_QUANTITY
                      , ACS_FUNCTION.RoundNear(least(decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                   , PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                    ) *
                                               POS.POS_CONVERT_FACTOR
                                             , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                             , 1
                                              ) DCD_QUANTITY_SU
                      , 0 DCD_BALANCE_FLAG
                      , POS.POS_CONVERT_FACTOR
                      , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                      , POS.POS_GROSS_UNIT_VALUE
                      , POS.POS_GROSS_UNIT_VALUE_INCL
                      , POS.DIC_UNIT_OF_MEASURE_ID
                      , POS.POS_UTIL_COEFF
                      , FLN.FAL_NETWORK_LINK_ID
                      , 0
                      -- DCD_VISIBLE
                 ,      sysdate
                      , PCS.PC_I_LIB_SESSION.GetUserIni
                      , tplDischargePdeCPT.PDE_ST_PT_REJECT
                      , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                   from DOC_POSITION_DETAIL PDE
                      , DOC_POSITION POS
                      , DOC_DOCUMENT DMT
                      , FAL_NETWORK_LINK FLN
                      , FAL_NETWORK_NEED FAN
                      , STM_STOCK_POSITION SPO
                      , GCO_GOOD GOO
                      , GCO_PRODUCT PDT
                  where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                    and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                    and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                    and PDE.PDE_BALANCE_QUANTITY > 0
                    and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                    and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                    and FLN.STM_STOCK_POSITION_ID(+) is not null
                    and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                    and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                    and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
            end if;
          end loop;
        end if;
      end loop;
    end loop;
  end InsertDischargeAttribFull;

  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base des
  *    attributions sur stock pour ce qui concerne les positions simple (type 1,2,3) et
  *    les composants (avec lien sur PT). Par contre, pour les PT on tient compte de
  *    l'ensemble des détails fils pour définir leurs quantités. Les composants et
  *    positions normales non attribués sont sélectionnés.
  */
  procedure InsertDischargeDetailAttribAll(
    ANewDocumentID in number
  , ADocumentList  in varchar2
  , ARecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , AReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
  begin
    InsertDischargeAttribFull(ANewDocumentID, ADocumentList, ARecordTitle, AReference, 1);
  end InsertDischargeDetailAttribAll;

  /**
  * Description
  *    Création des données de décharge dans la table temporaire sur la base des
  *    attributions sur stock pour ce qui concerne les positions simple (type 1,2,3) et
  *    les composants (avec lien sur PT). Par contre, pour les PT on tient compte de
  *    l'ensemble des détails fils pour définir leurs quantités. Les composants et
  *    positions normales non attribués ne sont pas sélectionnés.
  */
  procedure InsertDischargeDetailAttrib2(
    ANewDocumentID in number
  , ADocumentList  in varchar2
  , ARecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , AReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
  begin
    InsertDischargeAttribFull(ANewDocumentID, ADocumentList, ARecordTitle, AReference, 0);
  end InsertDischargeDetailAttrib2;

  /**
  * procedure InsertCopyDetail
  * Description
  *    Création des données de copie dans la table temporaire
  */
  procedure InsertCopyDetail(
    aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocumentList  in varchar2
  , aPositionList  in varchar2 default null
  , aRecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , aReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crCopyPde(cDocumentID in number)
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
                    , PDE.PDE_FINAL_QUANTITY DCD_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY_SU DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
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
                    , DOC_RECORD RCO
                    , DOC_GAUGE_POSITION GAP
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE_POSITION GAP_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and DMT.DOC_DOCUMENT_ID = cDocumentID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID is null
                  and POS.C_DOC_POS_STATUS <> '05'
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   aPositionList is null
                       or POS.DOC_POSITION_ID in(select column_value
                                                   from table(idListToTable(aPositionList) ) ) )
                  and (   aRecordTitle is null
                       or RCO.RCO_TITLE like(aRecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   aReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(aReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
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

    vTplCopyPde        crCopyPde%rowtype;

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
                    , PDE.PDE_FINAL_QUANTITY DCD_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY_SU DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
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
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_RECORD RCO
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   aRecordTitle is null
                       or RCO.RCO_TITLE like(aRecordTitle) )
                  and POS.DOC_DOC_POSITION_ID = cPositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and GAU.DOC_GAUGE_ID = DCD.DOC_GAUGE_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    vTplCopyPdeCPT     crCopyPdeCPT%rowtype;
    --
    vConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    vInsertDcd         V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt      V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    currentPositionID  DOC_POSITION.DOC_POSITION_ID%type;
    cGaugeTypePos      DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Balayer la liste des documents à copier
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      open crCopyPde(tplDoc.DOC_DOCUMENT_ID);

      fetch crCopyPde
       into vTplCopyPde;

      -- Tant qu'il reste des détails à traiter
      while crCopyPde%found loop
        -- Mémorise la position courante pour déterminer un changement de position ainsi que le type de position.
        currentPositionID                        := vTplCopyPde.DOC_POSITION_ID;
        cGaugeTypePos                            := vTplCopyPde.C_GAUGE_TYPE_POS;
        -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
        -- Il faut rechercher le facteur de conversion calculé.
        vConvertFactorCalc                       :=
          GCO_FUNCTIONS.GetThirdConvertFactor(vTplCopyPde.GCO_GOOD_ID
                                            , vTplCopyPde.PAC_THIRD_CDA_ID
                                            , vTplCopyPde.C_GAUGE_TYPE_POS
                                            , null
                                            , vTplCopyPde.TGT_PAC_THIRD_CDA_ID
                                            , vTplCopyPde.TGT_C_ADMIN_DOMAIN
                                             );
        -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
        vInsertDcd                               := null;
        vInsertDcd.DOC_POSITION_DETAIL_ID        := vTplCopyPde.DOC_POSITION_DETAIL_ID;
        vInsertDcd.NEW_DOCUMENT_ID               := vTplCopyPde.NEW_DOCUMENT_ID;
        vInsertDcd.CRG_SELECT                    := vTplCopyPde.CRG_SELECT;
        vInsertDcd.DOC_GAUGE_FLOW_ID             := vTplCopyPde.DOC_GAUGE_FLOW_ID;
        vInsertDcd.DOC_POSITION_ID               := vTplCopyPde.DOC_POSITION_ID;
        vInsertDcd.DOC_DOC_POSITION_ID           := vTplCopyPde.DOC_DOC_POSITION_ID;
        vInsertDcd.DOC_DOC_POSITION_DETAIL_ID    := vTplCopyPde.DOC_DOC_POSITION_DETAIL_ID;
        vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID   := vTplCopyPde.DOC2_DOC_POSITION_DETAIL_ID;
        vInsertDcd.GCO_GOOD_ID                   := vTplCopyPde.GCO_GOOD_ID;
        vInsertDcd.STM_LOCATION_ID               := vTplCopyPde.STM_LOCATION_ID;
        vInsertDcd.GCO_CHARACTERIZATION_ID       := vTplCopyPde.GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO_GCO_CHARACTERIZATION_ID   := vTplCopyPde.GCO_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO2_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO3_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID  := vTplCopyPde.GCO4_GCO_CHARACTERIZATION_ID;
        vInsertDcd.STM_STM_LOCATION_ID           := vTplCopyPde.STM_STM_LOCATION_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_1_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_1_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_2_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_2_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_3_ID       := vTplCopyPde.DIC_PDE_FREE_TABLE_3_ID;
        vInsertDcd.FAL_SCHEDULE_STEP_ID          := vTplCopyPde.FAL_SCHEDULE_STEP_ID;
        vInsertDcd.DOC_RECORD_ID                 := vTplCopyPde.DOC_RECORD_ID;
        vInsertDcd.DOC_DOCUMENT_ID               := vTplCopyPde.DOC_DOCUMENT_ID;
        vInsertDcd.PAC_THIRD_ID                  := vTplCopyPde.PAC_THIRD_ID;
        vInsertDcd.PAC_THIRD_ACI_ID              := vTplCopyPde.PAC_THIRD_ACI_ID;
        vInsertDcd.PAC_THIRD_DELIVERY_ID         := vTplCopyPde.PAC_THIRD_DELIVERY_ID;
        vInsertDcd.PAC_THIRD_TARIFF_ID           := vTplCopyPde.PAC_THIRD_TARIFF_ID;
        vInsertDcd.DOC_GAUGE_ID                  := vTplCopyPde.DOC_GAUGE_ID;
        vInsertDcd.DOC_GAUGE_RECEIPT_ID          := vTplCopyPde.DOC_GAUGE_RECEIPT_ID;
        vInsertDcd.DOC_GAUGE_COPY_ID             := vTplCopyPde.DOC_GAUGE_COPY_ID;
        vInsertDcd.C_GAUGE_TYPE_POS              := vTplCopyPde.C_GAUGE_TYPE_POS;
        vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID      := vTplCopyPde.DIC_DELAY_UPDATE_TYPE_ID;
        vInsertDcd.PDE_BASIS_DELAY               := vTplCopyPde.PDE_BASIS_DELAY;
        vInsertDcd.PDE_INTERMEDIATE_DELAY        := vTplCopyPde.PDE_INTERMEDIATE_DELAY;
        vInsertDcd.PDE_FINAL_DELAY               := vTplCopyPde.PDE_FINAL_DELAY;
        vInsertDcd.PDE_SQM_ACCEPTED_DELAY        := vTplCopyPde.PDE_SQM_ACCEPTED_DELAY;
        vInsertDcd.PDE_BASIS_QUANTITY            := vTplCopyPde.PDE_BASIS_QUANTITY;
        vInsertDcd.PDE_INTERMEDIATE_QUANTITY     := vTplCopyPde.PDE_INTERMEDIATE_QUANTITY;
        vInsertDcd.PDE_FINAL_QUANTITY            := vTplCopyPde.PDE_FINAL_QUANTITY;
        vInsertDcd.PDE_BALANCE_QUANTITY          := vTplCopyPde.PDE_BALANCE_QUANTITY;
        vInsertDcd.PDE_BALANCE_QUANTITY_PARENT   := vTplCopyPde.PDE_BALANCE_QUANTITY_PARENT;
        vInsertDcd.PDE_BASIS_QUANTITY_SU         := vTplCopyPde.PDE_BASIS_QUANTITY_SU;
        vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU  := vTplCopyPde.PDE_INTERMEDIATE_QUANTITY_SU;
        vInsertDcd.PDE_FINAL_QUANTITY_SU         := vTplCopyPde.PDE_FINAL_QUANTITY_SU;
        vInsertDcd.PDE_MOVEMENT_QUANTITY         := vTplCopyPde.PDE_MOVEMENT_QUANTITY;
        vInsertDcd.PDE_MOVEMENT_VALUE            := vTplCopyPde.PDE_MOVEMENT_VALUE;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_1  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_1;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_2  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_2;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_3  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_3;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_4  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_4;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_5  := vTplCopyPde.PDE_CHARACTERIZATION_VALUE_5;
        vInsertDcd.PDE_DELAY_UPDATE_TEXT         := vTplCopyPde.PDE_DELAY_UPDATE_TEXT;
        vInsertDcd.PDE_DECIMAL_1                 := vTplCopyPde.PDE_DECIMAL_1;
        vInsertDcd.PDE_DECIMAL_2                 := vTplCopyPde.PDE_DECIMAL_2;
        vInsertDcd.PDE_DECIMAL_3                 := vTplCopyPde.PDE_DECIMAL_3;
        vInsertDcd.PDE_TEXT_1                    := vTplCopyPde.PDE_TEXT_1;
        vInsertDcd.PDE_TEXT_2                    := vTplCopyPde.PDE_TEXT_2;
        vInsertDcd.PDE_TEXT_3                    := vTplCopyPde.PDE_TEXT_3;
        vInsertDcd.PDE_DATE_1                    := vTplCopyPde.PDE_DATE_1;
        vInsertDcd.PDE_DATE_2                    := vTplCopyPde.PDE_DATE_2;
        vInsertDcd.PDE_DATE_3                    := vTplCopyPde.PDE_DATE_3;
        vInsertDcd.PDE_GENERATE_MOVEMENT         := vTplCopyPde.PDE_GENERATE_MOVEMENT;
        vInsertDcd.DCD_QUANTITY                  := vTplCopyPde.DCD_QUANTITY;
        vInsertDcd.DCD_QUANTITY_SU               := vTplCopyPde.DCD_QUANTITY_SU;
        vInsertDcd.DCD_BALANCE_FLAG              := vTplCopyPde.DCD_BALANCE_FLAG;
        vInsertDcd.POS_CONVERT_FACTOR            := vTplCopyPde.POS_CONVERT_FACTOR;
        vInsertDcd.POS_CONVERT_FACTOR_CALC       := nvl(vConvertFactorCalc, vTplCopyPde.POS_CONVERT_FACTOR);
        vInsertDcd.POS_GROSS_UNIT_VALUE          := vTplCopyPde.POS_GROSS_UNIT_VALUE;
        vInsertDcd.POS_GROSS_UNIT_VALUE_INCL     := vTplCopyPde.POS_GROSS_UNIT_VALUE_INCL;
        vInsertDcd.POS_UNIT_OF_MEASURE_ID        := vTplCopyPde.DIC_UNIT_OF_MEASURE_ID;
        vInsertDcd.DCD_DEPLOYED_COMPONENTS       := vTplCopyPde.DCD_DEPLOYED_COMPONENTS;
        vInsertDcd.DCD_VISIBLE                   := 0;
        vInsertDcd.A_DATECRE                     := vTplCopyPde.NEW_A_DATECRE;
        vInsertDcd.A_IDCRE                       := vTplCopyPde.NEW_A_IDCRE;
        vInsertDcd.PDE_ST_PT_REJECT              := vTplCopyPde.PDE_ST_PT_REJECT;
        vInsertDcd.PDE_ST_CPT_REJECT             := vTplCopyPde.PDE_ST_CPT_REJECT;

        insert into V_DOC_POS_DET_COPY_DISCHARGE
             values vInsertDcd;

        fetch crCopyPde
         into vTplCopyPde;

        -- Détermine si des composants doivent être créés sur la base d'un éventuel produit terminé.
        -- C'est uniquement après la création du dernier détail du produit terminé que la création des composants
        -- doit s'effectuer.
        if cGaugeTypePos in('7', '8', '9', '10') then
          -- Dernier record ou changement de position
          if    not crCopyPde%found
             or currentPositionID <> vTplCopyPde.DOC_POSITION_ID then
            -- Traitement des détails de positions composants.
            for vTplCopyPdeCPT in crCopyPdeCPT(currentPositionID) loop
              -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
              vInsertDcdCpt                               := null;
              vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := vTplCopyPdeCPT.DOC_POSITION_DETAIL_ID;
              vInsertDcdCpt.NEW_DOCUMENT_ID               := vTplCopyPdeCPT.NEW_DOCUMENT_ID;
              vInsertDcdCpt.CRG_SELECT                    := vTplCopyPdeCPT.CRG_SELECT;
              vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := vTplCopyPdeCPT.DOC_GAUGE_FLOW_ID;
              vInsertDcdCpt.DOC_POSITION_ID               := vTplCopyPdeCPT.DOC_POSITION_ID;
              vInsertDcdCpt.DOC_DOC_POSITION_ID           := vTplCopyPdeCPT.DOC_DOC_POSITION_ID;
              vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := vTplCopyPdeCPT.DOC_DOC_POSITION_DETAIL_ID;
              vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := vTplCopyPdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
              vInsertDcdCpt.GCO_GOOD_ID                   := vTplCopyPdeCPT.GCO_GOOD_ID;
              vInsertDcdCpt.STM_LOCATION_ID               := vTplCopyPdeCPT.STM_LOCATION_ID;
              vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := vTplCopyPdeCPT.GCO_CHARACTERIZATION_ID;
              vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := vTplCopyPdeCPT.GCO_GCO_CHARACTERIZATION_ID;
              vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
              vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
              vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := vTplCopyPdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
              vInsertDcdCpt.STM_STM_LOCATION_ID           := vTplCopyPdeCPT.STM_STM_LOCATION_ID;
              vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_1_ID;
              vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_2_ID;
              vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := vTplCopyPdeCPT.DIC_PDE_FREE_TABLE_3_ID;
              vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := vTplCopyPdeCPT.FAL_SCHEDULE_STEP_ID;
              vInsertDcdCpt.DOC_DOCUMENT_ID               := vTplCopyPdeCPT.DOC_DOCUMENT_ID;
              vInsertDcdCpt.PAC_THIRD_ID                  := vTplCopyPdeCPT.PAC_THIRD_ID;
              vInsertDcdCpt.PAC_THIRD_ACI_ID              := vTplCopyPdeCPT.PAC_THIRD_ACI_ID;
              vInsertDcdCpt.PAC_THIRD_DELIVERY_ID         := vTplCopyPdeCPT.PAC_THIRD_DELIVERY_ID;
              vInsertDcdCpt.PAC_THIRD_TARIFF_ID           := vTplCopyPdeCPT.PAC_THIRD_TARIFF_ID;
              vInsertDcdCpt.DOC_GAUGE_ID                  := vTplCopyPdeCPT.DOC_GAUGE_ID;
              vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := vTplCopyPdeCPT.DOC_GAUGE_RECEIPT_ID;
              vInsertDcdCpt.DOC_GAUGE_COPY_ID             := vTplCopyPdeCPT.DOC_GAUGE_COPY_ID;
              vInsertDcdCpt.C_GAUGE_TYPE_POS              := vTplCopyPdeCPT.C_GAUGE_TYPE_POS;
              vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := vTplCopyPdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
              vInsertDcdCpt.PDE_BASIS_DELAY               := vTplCopyPdeCPT.PDE_BASIS_DELAY;
              vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := vTplCopyPdeCPT.PDE_INTERMEDIATE_DELAY;
              vInsertDcdCpt.PDE_FINAL_DELAY               := vTplCopyPdeCPT.PDE_FINAL_DELAY;
              vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := vTplCopyPdeCPT.PDE_SQM_ACCEPTED_DELAY;
              vInsertDcdCpt.PDE_BASIS_QUANTITY            := vTplCopyPdeCPT.PDE_BASIS_QUANTITY;
              vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := vTplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY;
              vInsertDcdCpt.PDE_FINAL_QUANTITY            := vTplCopyPdeCPT.PDE_FINAL_QUANTITY;
              vInsertDcdCpt.PDE_BALANCE_QUANTITY          := vTplCopyPdeCPT.PDE_BALANCE_QUANTITY;
              vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := vTplCopyPdeCPT.PDE_BALANCE_QUANTITY_PARENT;
              vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := vTplCopyPdeCPT.PDE_BASIS_QUANTITY_SU;
              vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := vTplCopyPdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
              vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := vTplCopyPdeCPT.PDE_FINAL_QUANTITY_SU;
              vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := vTplCopyPdeCPT.PDE_MOVEMENT_QUANTITY;
              vInsertDcdCpt.PDE_MOVEMENT_VALUE            := vTplCopyPdeCPT.PDE_MOVEMENT_VALUE;
              vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_1;
              vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_2;
              vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_3;
              vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_4;
              vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := vTplCopyPdeCPT.PDE_CHARACTERIZATION_VALUE_5;
              vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := vTplCopyPdeCPT.PDE_DELAY_UPDATE_TEXT;
              vInsertDcdCpt.PDE_DECIMAL_1                 := vTplCopyPdeCPT.PDE_DECIMAL_1;
              vInsertDcdCpt.PDE_DECIMAL_2                 := vTplCopyPdeCPT.PDE_DECIMAL_2;
              vInsertDcdCpt.PDE_DECIMAL_3                 := vTplCopyPdeCPT.PDE_DECIMAL_3;
              vInsertDcdCpt.PDE_TEXT_1                    := vTplCopyPdeCPT.PDE_TEXT_1;
              vInsertDcdCpt.PDE_TEXT_2                    := vTplCopyPdeCPT.PDE_TEXT_2;
              vInsertDcdCpt.PDE_TEXT_3                    := vTplCopyPdeCPT.PDE_TEXT_3;
              vInsertDcdCpt.PDE_DATE_1                    := vTplCopyPdeCPT.PDE_DATE_1;
              vInsertDcdCpt.PDE_DATE_2                    := vTplCopyPdeCPT.PDE_DATE_2;
              vInsertDcdCpt.PDE_DATE_3                    := vTplCopyPdeCPT.PDE_DATE_3;
              vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := vTplCopyPdeCPT.PDE_GENERATE_MOVEMENT;
              vInsertDcdCpt.DCD_QUANTITY                  := vTplCopyPdeCPT.DCD_QUANTITY;
              vInsertDcdCpt.DCD_QUANTITY_SU               := vTplCopyPdeCPT.DCD_QUANTITY_SU;
              vInsertDcdCpt.DCD_BALANCE_FLAG              := vTplCopyPdeCPT.DCD_BALANCE_FLAG;
              vInsertDcdCpt.POS_CONVERT_FACTOR            := vTplCopyPdeCPT.POS_CONVERT_FACTOR;
              vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := vTplCopyPdeCPT.POS_CONVERT_FACTOR;
              vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := vTplCopyPdeCPT.POS_GROSS_UNIT_VALUE;
              vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := vTplCopyPdeCPT.POS_GROSS_UNIT_VALUE_INCL;
              vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := vTplCopyPdeCPT.DIC_UNIT_OF_MEASURE_ID;
              vInsertDcdCpt.POS_UTIL_COEFF                := vTplCopyPdeCPT.POS_UTIL_COEFF;
              vInsertDcdCpt.DCD_VISIBLE                   := 0;
              vInsertDcdCpt.A_DATECRE                     := vTplCopyPdeCPT.NEW_A_DATECRE;
              vInsertDcdCpt.A_IDCRE                       := vTplCopyPdeCPT.NEW_A_IDCRE;
              vInsertDcdCpt.PDE_ST_PT_REJECT              := vTplCopyPdeCPT.PDE_ST_PT_REJECT;
              vInsertDcdCpt.PDE_ST_CPT_REJECT             := vTplCopyPdeCPT.PDE_ST_CPT_REJECT;

              insert into V_DOC_POS_DET_COPY_DISCHARGE
                   values vInsertDcdCpt;
            end loop;   -- for vTplCopyPdeCPT
          end if;
        end if;
      end loop;   -- crCopyPde%found

      close crCopyPde;
    end loop;   -- for tplDoc
  end InsertCopyDetail;

  /**
  * Description
  *    Création des données de copie dans la table temporaire sur la base des
  *    attributions sur stock
  */
  procedure InsertCopyDetailAttrib(
    ANewDocumentID in number
  , ADocumentList  in varchar2
  , aPositionList  in varchar2 default null
  , ARecordTitle   in DOC_RECORD.RCO_TITLE%type default null
  , AReference     in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crCopyPde(ADocumentID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 as CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.POS_NUMBER
                    , POS.GCO_GOOD_ID
                    , nvl(SPO.STM_LOCATION_ID, PDE.STM_LOCATION_ID) STM_LOCATION_ID
                    , nvl(SPO.GCO_CHARACTERIZATION_ID, PDE.GCO_CHARACTERIZATION_ID) GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO.GCO_GCO_CHARACTERIZATION_ID) GCO_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.GCO2_GCO_CHARACTERIZATION_ID) GCO2_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.GCO3_GCO_CHARACTERIZATION_ID) GCO3_GCO_CHARACTERIZATION_ID
                    , nvl(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.GCO4_GCO_CHARACTERIZATION_ID) GCO4_GCO_CHARACTERIZATION_ID
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
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_1, PDE.PDE_CHARACTERIZATION_VALUE_1) SPO_CHARACTERIZATION_VALUE_1
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_2, PDE.PDE_CHARACTERIZATION_VALUE_2) SPO_CHARACTERIZATION_VALUE_2
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_3, PDE.PDE_CHARACTERIZATION_VALUE_3) SPO_CHARACTERIZATION_VALUE_3
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_4, PDE.PDE_CHARACTERIZATION_VALUE_4) SPO_CHARACTERIZATION_VALUE_4
                    , nvl(SPO.SPO_CHARACTERIZATION_VALUE_5, PDE.PDE_CHARACTERIZATION_VALUE_5) SPO_CHARACTERIZATION_VALUE_5
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
                    , decode(POS.C_GAUGE_TYPE_POS
                           , '1', decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY / POS.POS_CONVERT_FACTOR, 0), PDE.PDE_FINAL_QUANTITY)
                           , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                           , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                           , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                           , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(decode(POS.C_GAUGE_TYPE_POS
                                                  , '1', decode(PDT.PDT_STOCK_MANAGEMENT
                                                              , 1, nvl(FLN.FLN_QTY / POS.POS_CONVERT_FACTOR, 0)
                                                              , PDE.PDE_FINAL_QUANTITY
                                                               )
                                                  , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                                                  , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                                                  , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                                                  , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_FINAL_QUANTITY)
                                                  , PDE.PDE_FINAL_QUANTITY
                                                   ) *
                                             POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , FLN.FAL_NETWORK_LINK_ID
                    , GAP.DOC_DOC_GAUGE_POSITION_ID
                    , DMT_TGT.DOC_DOCUMENT_ID NEW_DOCUMENT_ID
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                    , DOC_GAUGE_POSITION GAP_TGT
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_POSITION GAP
                    , GCO_PRODUCT PDT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , DOC_RECORD RCO
                where DMT.DOC_DOCUMENT_ID = aDocumentID
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID is null
                  and POS.C_DOC_POS_STATUS <> '05'
                  and (   aPositionList is null
                       or POS.DOC_POSITION_ID in(select column_value
                                                   from table(idListToTable(aPositionList) ) ) )
                  and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (   ARecordTitle is null
                       or RCO.RCO_TITLE like(ARecordTitle || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and (   AReference is null
                       or GOO.GOO_MAJOR_REFERENCE like(AReference || '%')
                       or not POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                      )
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
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

    tplCopyPde         crCopyPde%rowtype;

    cursor crCopyPdeCPT(cPositionID in number, cLinkedGapPos in number)
    is
      select   PDE.DOC_POSITION_DETAIL_ID
             , ANewDocumentID NEW_DOCUMENT_ID
             , DCD.CRG_SELECT
             , PDE.DOC_GAUGE_FLOW_ID
             , PDE.DOC_POSITION_ID
             , POS.DOC_DOC_POSITION_ID
             , PDE.DOC_DOC_POSITION_DETAIL_ID
             , PDE.DOC2_DOC_POSITION_DETAIL_ID
             , POS.GCO_GOOD_ID
             , SPO.STM_LOCATION_ID
             , SPO.GCO_CHARACTERIZATION_ID
             , SPO.GCO_GCO_CHARACTERIZATION_ID
             , SPO.GCO2_GCO_CHARACTERIZATION_ID
             , SPO.GCO3_GCO_CHARACTERIZATION_ID
             , SPO.GCO4_GCO_CHARACTERIZATION_ID
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
             , SPO.SPO_CHARACTERIZATION_VALUE_1 PDE_CHARACTERIZATION_VALUE_1
             , SPO.SPO_CHARACTERIZATION_VALUE_2 PDE_CHARACTERIZATION_VALUE_2
             , SPO.SPO_CHARACTERIZATION_VALUE_3 PDE_CHARACTERIZATION_VALUE_3
             , SPO.SPO_CHARACTERIZATION_VALUE_4 PDE_CHARACTERIZATION_VALUE_4
             , SPO.SPO_CHARACTERIZATION_VALUE_5 PDE_CHARACTERIZATION_VALUE_5
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
             , least(case
                       when PDT.PDT_STOCK_MANAGEMENT = 1 then nvl(FLN.FLN_QTY, 0)
                       else PDE.PDE_FINAL_QUANTITY
                     end
                   , case
                       when cLinkedGapPos = 0 then DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                       else PDE.PDE_FINAL_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                     end
                    ) DCD_QUANTITY
             , ACS_FUNCTION.RoundNear(least(case
                                              when PDT.PDT_STOCK_MANAGEMENT = 1 then nvl(FLN.FLN_QTY, 0)
                                              else PDE.PDE_FINAL_QUANTITY
                                            end
                                          , case
                                              when cLinkedGapPos = 0 then DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                              else PDE.PDE_FINAL_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                            end
                                           ) *
                                      POS.POS_CONVERT_FACTOR
                                    , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                    , 1
                                     ) DCD_QUANTITY_SU
             , 0 DCD_BALANCE_FLAG
             , POS.POS_CONVERT_FACTOR
             , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
             , POS.POS_GROSS_UNIT_VALUE
             , POS.POS_GROSS_UNIT_VALUE_INCL
             , POS.DIC_UNIT_OF_MEASURE_ID
             , POS.POS_UTIL_COEFF
             , POS.POS_NUMBER
             , FLN.FAL_NETWORK_LINK_ID
             , 0 as DCD_VISIBLE
             , sysdate NEW_A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
             , PDE.PDE_ST_PT_REJECT
             , PDE.PDE_ST_CPT_REJECT
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , FAL_NETWORK_LINK FLN
             , FAL_NETWORK_NEED FAN
             , STM_STOCK_POSITION SPO
             , GCO_GOOD GOO
             , GCO_PRODUCT PDT
             , DOC_POS_DET_COPY_DISCHARGE DCD
         where POS.DOC_DOC_POSITION_ID = cPositionID
           and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
           and DCD.NEW_DOCUMENT_ID = aNewDocumentID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and PDE.PDE_BALANCE_QUANTITY > 0
           and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
           and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
           and FLN.STM_STOCK_POSITION_ID(+) is not null
           and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
           and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
           and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
      order by POS.POS_NUMBER
             , PDE.PDE_BASIS_DELAY
             , PDE.DOC_POSITION_DETAIL_ID;

    tplCopyPdeCPT      crCopyPdeCPT%rowtype;
    --
    vNewDcdID          DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd         V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt      V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    vLinkedGapPos      number(1);
    currentPositionID  DOC_POSITION.DOC_POSITION_ID%type;
    cGaugeTypePos      DOC_POSITION.C_GAUGE_TYPE_POS%type;
  begin
    -- Balayer la liste des documents à décharger
    for tplDoc in (select column_value DOC_DOCUMENT_ID
                     from table(idListToTable(aDocumentList) ) ) loop
      -- Liste des détails du document source
      open crCopyPde(tplDoc.DOC_DOCUMENT_ID);

      fetch crCopyPde
       into tplCopyPde;

      -- Tant qu'il reste des détails à traiter
      while crCopyPde%found loop
        -- Mémorise la position courante pour déterminer un changement de position ainsi que le type de position.
        currentPositionID                         := tplCopyPde.DOC_POSITION_ID;
        cGaugeTypePos                             := tplCopyPde.C_GAUGE_TYPE_POS;

        select init_id_seq.nextval
          into vNewDcdID
          from dual;

        -- Traitement du changement de partenaire. Si le patenaire source est différent du partenaire cible,
        -- Il faut rechercher le facteur de conversion calculé.
        vConvertFactorCalc                        :=
          GCO_FUNCTIONS.GetThirdConvertFactor(tplCopyPde.GCO_GOOD_ID
                                            , tplCopyPde.PAC_THIRD_CDA_ID
                                            , tplCopyPde.C_GAUGE_TYPE_POS
                                            , null
                                            , tplCopyPde.TGT_PAC_THIRD_CDA_ID
                                            , tplCopyPde.TGT_C_ADMIN_DOMAIN
                                             );
        -- Initialisation de la variable avec les données à insèrer dans la table V_DOC_POS_DET_COPY_DISCHARGE
        vInsertDcd                                := null;
        vInsertDcd.DOC_POS_DET_COPY_DISCHARGE_ID  := vNewDcdID;
        vInsertDcd.DOC_POSITION_DETAIL_ID         := tplCopyPde.DOC_POSITION_DETAIL_ID;
        vInsertDcd.NEW_DOCUMENT_ID                := tplCopyPde.NEW_DOCUMENT_ID;
        vInsertDcd.CRG_SELECT                     := tplCopyPde.CRG_SELECT;
        vInsertDcd.DOC_GAUGE_FLOW_ID              := tplCopyPde.DOC_GAUGE_FLOW_ID;
        vInsertDcd.DOC_POSITION_ID                := tplCopyPde.DOC_POSITION_ID;
        vInsertDcd.DOC_DOC_POSITION_ID            := tplCopyPde.DOC_DOC_POSITION_ID;
        vInsertDcd.DOC_DOC_POSITION_DETAIL_ID     := tplCopyPde.DOC_DOC_POSITION_DETAIL_ID;
        vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID    := tplCopyPde.DOC2_DOC_POSITION_DETAIL_ID;
        vInsertDcd.GCO_GOOD_ID                    := tplCopyPde.GCO_GOOD_ID;
        vInsertDcd.STM_LOCATION_ID                := tplCopyPde.STM_LOCATION_ID;
        vInsertDcd.GCO_CHARACTERIZATION_ID        := tplCopyPde.GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO_GCO_CHARACTERIZATION_ID    := tplCopyPde.GCO_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID   := tplCopyPde.GCO2_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID   := tplCopyPde.GCO3_GCO_CHARACTERIZATION_ID;
        vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID   := tplCopyPde.GCO4_GCO_CHARACTERIZATION_ID;
        vInsertDcd.STM_STM_LOCATION_ID            := tplCopyPde.STM_STM_LOCATION_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_1_ID        := tplCopyPde.DIC_PDE_FREE_TABLE_1_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_2_ID        := tplCopyPde.DIC_PDE_FREE_TABLE_2_ID;
        vInsertDcd.DIC_PDE_FREE_TABLE_3_ID        := tplCopyPde.DIC_PDE_FREE_TABLE_3_ID;
        vInsertDcd.FAL_SCHEDULE_STEP_ID           := tplCopyPde.FAL_SCHEDULE_STEP_ID;
        vInsertDcd.DOC_RECORD_ID                  := tplCopyPde.DOC_RECORD_ID;
        vInsertDcd.DOC_DOCUMENT_ID                := tplCopyPde.DOC_DOCUMENT_ID;
        vInsertDcd.PAC_THIRD_ID                   := tplCopyPde.PAC_THIRD_ID;
        vInsertDcd.PAC_THIRD_ACI_ID               := tplCopyPde.PAC_THIRD_ACI_ID;
        vInsertDcd.PAC_THIRD_DELIVERY_ID          := tplCopyPde.PAC_THIRD_DELIVERY_ID;
        vInsertDcd.PAC_THIRD_TARIFF_ID            := tplCopyPde.PAC_THIRD_TARIFF_ID;
        vInsertDcd.DOC_GAUGE_ID                   := tplCopyPde.DOC_GAUGE_ID;
        vInsertDcd.DOC_GAUGE_RECEIPT_ID           := tplCopyPde.DOC_GAUGE_RECEIPT_ID;
        vInsertDcd.DOC_GAUGE_COPY_ID              := tplCopyPde.DOC_GAUGE_COPY_ID;
        vInsertDcd.C_GAUGE_TYPE_POS               := tplCopyPde.C_GAUGE_TYPE_POS;
        vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID       := tplCopyPde.DIC_DELAY_UPDATE_TYPE_ID;
        vInsertDcd.PDE_BASIS_DELAY                := tplCopyPde.PDE_BASIS_DELAY;
        vInsertDcd.PDE_INTERMEDIATE_DELAY         := tplCopyPde.PDE_INTERMEDIATE_DELAY;
        vInsertDcd.PDE_FINAL_DELAY                := tplCopyPde.PDE_FINAL_DELAY;
        vInsertDcd.PDE_SQM_ACCEPTED_DELAY         := tplCopyPde.PDE_SQM_ACCEPTED_DELAY;
        vInsertDcd.PDE_BASIS_QUANTITY             := tplCopyPde.PDE_BASIS_QUANTITY;
        vInsertDcd.PDE_INTERMEDIATE_QUANTITY      := tplCopyPde.PDE_INTERMEDIATE_QUANTITY;
        vInsertDcd.PDE_FINAL_QUANTITY             := tplCopyPde.PDE_FINAL_QUANTITY;
        vInsertDcd.PDE_BALANCE_QUANTITY           := tplCopyPde.PDE_BALANCE_QUANTITY;
        vInsertDcd.PDE_BALANCE_QUANTITY_PARENT    := tplCopyPde.PDE_BALANCE_QUANTITY_PARENT;
        vInsertDcd.PDE_BASIS_QUANTITY_SU          := tplCopyPde.PDE_BASIS_QUANTITY_SU;
        vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU   := tplCopyPde.PDE_INTERMEDIATE_QUANTITY_SU;
        vInsertDcd.PDE_FINAL_QUANTITY_SU          := tplCopyPde.PDE_FINAL_QUANTITY_SU;
        vInsertDcd.PDE_MOVEMENT_QUANTITY          := tplCopyPde.PDE_MOVEMENT_QUANTITY;
        vInsertDcd.PDE_MOVEMENT_VALUE             := tplCopyPde.PDE_MOVEMENT_VALUE;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_1   := tplCopyPde.SPO_CHARACTERIZATION_VALUE_1;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_2   := tplCopyPde.SPO_CHARACTERIZATION_VALUE_2;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_3   := tplCopyPde.SPO_CHARACTERIZATION_VALUE_3;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_4   := tplCopyPde.SPO_CHARACTERIZATION_VALUE_4;
        vInsertDcd.PDE_CHARACTERIZATION_VALUE_5   := tplCopyPde.SPO_CHARACTERIZATION_VALUE_5;
        vInsertDcd.PDE_DELAY_UPDATE_TEXT          := tplCopyPde.PDE_DELAY_UPDATE_TEXT;
        vInsertDcd.PDE_DECIMAL_1                  := tplCopyPde.PDE_DECIMAL_1;
        vInsertDcd.PDE_DECIMAL_2                  := tplCopyPde.PDE_DECIMAL_2;
        vInsertDcd.PDE_DECIMAL_3                  := tplCopyPde.PDE_DECIMAL_3;
        vInsertDcd.PDE_TEXT_1                     := tplCopyPde.PDE_TEXT_1;
        vInsertDcd.PDE_TEXT_2                     := tplCopyPde.PDE_TEXT_2;
        vInsertDcd.PDE_TEXT_3                     := tplCopyPde.PDE_TEXT_3;
        vInsertDcd.PDE_DATE_1                     := tplCopyPde.PDE_DATE_1;
        vInsertDcd.PDE_DATE_2                     := tplCopyPde.PDE_DATE_2;
        vInsertDcd.PDE_DATE_3                     := tplCopyPde.PDE_DATE_3;
        vInsertDcd.PDE_GENERATE_MOVEMENT          := tplCopyPde.PDE_GENERATE_MOVEMENT;
        vInsertDcd.DCD_QUANTITY                   := tplCopyPde.DCD_QUANTITY;
        vInsertDcd.DCD_QUANTITY_SU                := tplCopyPde.DCD_QUANTITY_SU;
        vInsertDcd.DCD_BALANCE_FLAG               := tplCopyPde.DCD_BALANCE_FLAG;
        vInsertDcd.POS_CONVERT_FACTOR             := tplCopyPde.POS_CONVERT_FACTOR;
        vInsertDcd.POS_CONVERT_FACTOR_CALC        := nvl(vConvertFactorCalc, tplCopyPde.POS_CONVERT_FACTOR);
        vInsertDcd.POS_GROSS_UNIT_VALUE           := tplCopyPde.POS_GROSS_UNIT_VALUE;
        vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplCopyPde.POS_GROSS_UNIT_VALUE_INCL;
        vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplCopyPde.DIC_UNIT_OF_MEASURE_ID;
        vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplCopyPde.DCD_DEPLOYED_COMPONENTS;
        vInsertDcd.FAL_NETWORK_LINK_ID            := tplCopyPde.FAL_NETWORK_LINK_ID;
        vInsertDcd.DCD_VISIBLE                    := tplCopyPde.DCD_VISIBLE;
        vInsertDcd.A_DATECRE                      := tplCopyPde.NEW_A_DATECRE;
        vInsertDcd.A_IDCRE                        := tplCopyPde.NEW_A_IDCRE;
        vInsertDcd.PDE_ST_PT_REJECT               := tplCopyPde.PDE_ST_PT_REJECT;
        vInsertDcd.PDE_ST_CPT_REJECT              := tplCopyPde.PDE_ST_CPT_REJECT;

        insert into V_DOC_POS_DET_COPY_DISCHARGE
             values vInsertDcd;

        fetch crCopyPde
         into tplCopyPde;

        -- Détermine si des composants doivent être créés sur la base d'un éventuel produit terminé.
        -- C'est uniquement après la création du dernier détail du produit terminé que la création des composants
        -- doit s'effectuer.
        if cGaugeTypePos in('7', '8', '9', '10') then
          -- Dernier record ou changement de position
          if    not crCopyPde%found
             or currentPositionID <> tplCopyPde.DOC_POSITION_ID then
            -- Gabarit position lié ou pas
            if tplCopyPde.DOC_DOC_GAUGE_POSITION_ID is null then
              vLinkedGapPos  := 0;
            else
              vLinkedGapPos  := 1;
            end if;

            -- Traitement des détails de positions composants.
            for tplCopyPdeCPT in crCopyPdeCPT(tplCopyPde.DOC_POSITION_ID, vLinkedGapPos) loop
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
              vInsertDcdCpt.FAL_NETWORK_LINK_ID           := tplCopyPdeCPT.FAL_NETWORK_LINK_ID;
              vInsertDcdCpt.DCD_VISIBLE                   := tplCopyPdeCPT.DCD_VISIBLE;
              vInsertDcdCpt.A_DATECRE                     := tplCopyPdeCPT.NEW_A_DATECRE;
              vInsertDcdCpt.A_IDCRE                       := tplCopyPdeCPT.NEW_A_IDCRE;
              vInsertDcdCpt.PDE_ST_PT_REJECT              := tplCopyPdeCPT.PDE_ST_PT_REJECT;
              vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplCopyPdeCPT.PDE_ST_CPT_REJECT;

              insert into V_DOC_POS_DET_COPY_DISCHARGE
                   values vInsertDcdCpt;
            end loop;
          end if;
        end if;
      end loop;   -- crCopyPde%found

      close crCopyPde;
    end loop;   -- for tplDoc
  end InsertCopyDetailAttrib;
end DOC_COPY_DISCHARGE_INSERT;
