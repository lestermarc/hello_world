--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_DISCHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_DISCHARGE" 
is
  /**
  * procedure PrepareDischarge
  * Description
  *   Appel de la méthode d'insertion dans la table temporaire de décharge DOC_POS_DET_COPY_DISCHARGE
  *     des positions à décharger figurant dans la DOC_POSITION_INTERFACE
  */
  procedure PrepareDischarge(
    aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aPosNumber     in DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type
  )
  is
  -- Interface_Origin DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type;
  begin
    /***** Exemple de code PL/SQL avec l'utilisation du code d'origine du document *****/
    /*
    -- Origine du document dans la table DOC_INTERFACE
    select C_DOC_INTERFACE_ORIGIN into Interface_Origin
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = aInterfaceID;

    if Interface_Origin = '201' then
      USER_DOC_INTERFACE_DISCHARGE.InsertDischargeDetail_201(aNewDocumentID, aInterfaceID, aIntPositionID, aPosNumber);
    else
      DOC_INTERFACE_DISCHARGE.InsertDischargeDetail(aNewDocumentID, aInterfaceID, aIntPositionID, aPosNumber);
    end if;
    */
    DOC_INTERFACE_DISCHARGE.InsertDischargeDetail(aNewDocumentID, aInterfaceID, aIntPositionID, aPosNumber);
  end PrepareDischarge;

  /**
  * procedure PrepareOEDischarge
  * Description
  *   Appel de la méthode d'insertion dans la table temporaire de décharge DOC_POS_DET_COPY_DISCHARGE
  *     des positions à décharger dans le cadre du processus Order Entry
  */
  procedure PrepareOEDischarge(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aSrcDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    DOC_INTERFACE_DISCHARGE.InsertOEDischargeDetail(aNewDocumentID, aSrcDocumentID);
  end PrepareOEDischarge;

  /**
  * procedure InsertDischargeDetail
  * Description
  *  Méthode d'insertion dans la table temporaire de décharge DOC_POS_DET_COPY_DISCHARGE
  *     des positions à décharger dans le cadre du processus Order Entry
  */
  procedure InsertDischargeDetail(
    aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInterfaceID   in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aIntPositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aPosNumber     in DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type
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
                    , DOP.DOP_QTY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(DOP.DOP_QTY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1) DCD_QUANTITY_SU
                    , decode(DOC_I_LIB_GAUGE.GetGaugeReceiptFlag(DOC_I_LIB_GAUGE.GetGaugeReceiptID(PDE.DOC_GAUGE_ID, DMT_TGT.DOC_GAUGE_ID, DMT_TGT.PAC_THIRD_ID)
                                                               , 'GAR_BALANCE_PARENT'
                                                                )
                           , 0, 0
                           , nvl(DOP.DOP_BALANCE_PARENT_POS, 0)
                            ) DCD_BALANCE_FLAG
                    , 0 DCD_VISIBLE
                    , case
                        when DOI.C_DOC_INTERFACE_ORIGIN = '301' then '341'
                        else '340'
                      end C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
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
                    , ANewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , GCO_GOOD GOO
                    , DOC_INTERFACE_POSITION DOP
                    , DOC_INTERFACE DOI
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                where DOP.DOC_INTERFACE_ID = aInterfaceID
                  and (   DOP.DOC_INTERFACE_POSITION_ID = aIntPositionID
                       or aIntPositionID is null)
                  and (   DOP.DOP_POS_NUMBER = aPosNumber
                       or aPosNumber is null)
                  and DOI.DOC_INTERFACE_ID = DOP.DOC_INTERFACE_ID
                  and DOP.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT_TGT.DOC_DOCUMENT_ID = ANewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = DOP.DOC_DOCUMENT_ID
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
                          , case
                              when DCD.DCD_QUANTITY = 0 then PDE.PDE_BALANCE_QUANTITY
                              else DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                            end) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(least(PDE.PDE_BALANCE_QUANTITY
                                                 , case
                                                     when DCD.DCD_QUANTITY = 0 then PDE.PDE_BALANCE_QUANTITY
                                                     else DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                   end
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
                    , POS.POS_UTIL_COEFF
                    , POS.POS_NUMBER
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
      vInsertDcd.C_PDE_CREATE_MODE              := tplDischargePde.C_PDE_CREATE_MODE;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      -- Traitement d'une position kit ou assemblage
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
          -- Utiliser le code d'origine de création de la position PT
          vInsertDcdCpt.C_PDE_CREATE_MODE             := tplDischargePde.C_PDE_CREATE_MODE;
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
  * procedure InsertOEDischargeDetail
  * Description
  *   Méthode d'insertion dans la table temporaire de décharge DOC_POS_DET_COPY_DISCHARGE
  *     des positions à décharger dans le cadre du processus Order Entry
  */
  procedure InsertOEDischargeDetail(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aSrcDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crDischargePde
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
                    , decode(PDE.PDE_BALANCE_QUANTITY
                           , 0, 0
                           , decode(POS.C_GAUGE_TYPE_POS
                                  , '1', decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                  , '7', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '8', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '9', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , '10', least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(POS.DOC_POSITION_ID), PDE.PDE_BALANCE_QUANTITY)
                                  , PDE.PDE_BALANCE_QUANTITY
                                   )
                            ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(decode(PDE.PDE_BALANCE_QUANTITY
                                                  , 0, 0
                                                  , decode(POS.C_GAUGE_TYPE_POS
                                                         , '1', decode(PDT.PDT_STOCK_MANAGEMENT, 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
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
                    , 0 DCD_VISIBLE
                    , '345' C_PDE_CREATE_MODE
                    , POS.POS_CONVERT_FACTOR
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
                    , FLN.FAL_NETWORK_LINK_ID
                    , GAP.DOC_DOC_GAUGE_POSITION_ID
                    , DMT_TGT.PAC_THIRD_CDA_ID TGT_PAC_THIRD_CDA_ID
                    , GAU_TGT.C_ADMIN_DOMAIN TGT_C_ADMIN_DOMAIN
                    , ANewDocumentID NEW_DOCUMENT_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , DOC_GAUGE GAU
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE_STRUCTURED GAS
                    , DOC_GAUGE_POSITION GAP
                    , PAC_CUSTOM_PARTNER CUS
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , DOC_DOCUMENT DMT_TGT
                    , DOC_GAUGE GAU_TGT
                where DMT_TGT.DOC_DOCUMENT_ID = aNewDocumentID
                  and DMT_TGT.DOC_GAUGE_ID = GAU_TGT.DOC_GAUGE_ID
                  and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and SPO.STM_STOCK_POSITION_ID(+) = FLN.STM_STOCK_POSITION_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and PDE.DOC_POSITION_DETAIL_ID in(
                        select PDE2.DOC_POSITION_DETAIL_ID
                          from DOC_POSITION_DETAIL PDE2
                             , DOC_POSITION POS2
                             , DOC_DOCUMENT DMT2
                         where PDE2.DOC_POSITION_ID = POS2.DOC_POSITION_ID
                           and POS2.DOC_DOCUMENT_ID = DMT2.DOC_DOCUMENT_ID
                           and DMT2.DOC_DOCUMENT_ID = aSrcDocumentID
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
                                  where GAP.DOC_GAUGE_ID = DMT_TGT.DOC_GAUGE_ID
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

    tplDischargePde    crDischargePde%rowtype;

    cursor crDischargePdeCPT(cPositionID in number, cLinkedGapPos in number)
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
                       else PDE.PDE_BALANCE_QUANTITY
                     end
                   , case
                       when cLinkedGapPos = 0 then DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                       else PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                     end
                    ) DCD_QUANTITY
             , ACS_FUNCTION.RoundNear(least(case
                                              when PDT.PDT_STOCK_MANAGEMENT = 1 then nvl(FLN.FLN_QTY, 0)
                                              else PDE.PDE_BALANCE_QUANTITY
                                            end
                                          , case
                                              when cLinkedGapPos = 0 then DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                              else PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
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
             , '345' C_PDE_CREATE_MODE
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

    tplDischargePdeCPT crDischargePdeCPT%rowtype;
    --
    vNewDcdID          DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd         V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt      V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    vLinkedGapPos      number(1);
  begin
    /* Ouverture des détail de position déchargeables du document déchargeable courant */
    -- Liste des détails du document source
    for tplDischargePde in crDischargePde loop
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
      vInsertDcd.FAL_NETWORK_LINK_ID            := tplDischargePde.FAL_NETWORK_LINK_ID;
      vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE              := tplDischargePde.C_PDE_CREATE_MODE;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      -- Traitement d'une position kit ou assemblage
      if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        -- Gabarit position lié ou pas
        if tplDischargePde.DOC_DOC_GAUGE_POSITION_ID is null then
          vLinkedGapPos  := 0;
        else
          vLinkedGapPos  := 1;
        end if;

        -- Traitement des détails de positions composants.
        for tplDischargePdeCPT in crDischargePdeCPT(vInsertDcd.DOC_POSITION_ID, vLinkedGapPos) loop
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
          vInsertDcdCpt.FAL_NETWORK_LINK_ID           := tplDischargePdeCPT.FAL_NETWORK_LINK_ID;
          vInsertDcdCpt.DCD_VISIBLE                   := tplDischargePdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := tplDischargePdeCPT.C_PDE_CREATE_MODE;
          vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;
      end if;
    end loop;
  end InsertOEDischargeDetail;
end DOC_INTERFACE_DISCHARGE;
