--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_ALLOY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_ALLOY_FUNCTIONS" 
is
  /**
  * Description
  *    Graphe Génération Matières Positions
  */
  procedure GeneratePositionMat(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
  is
    cursor crGoodPreciousMatWeighing(cGoodID number)
    is
      select GPM.GCO_PRECIOUS_MAT_ID
           , GPM.GCO_ALLOY_ID
           , GPM.GPM_REAL_WEIGHT
        from GCO_PRECIOUS_MAT GPM
           , GCO_ALLOY LOY
       where GPM.GCO_GOOD_ID = cGoodID
         and GPM.GCO_ALLOY_ID = LOY.GCO_ALLOY_ID
         and nvl(LOY.GAL_GENERIC, 0) = 0
         and GPM.GPM_WEIGHT = 1;

    /*
    cursor crAlloyComponents(cAlloyID number)
    is
      select GAC.DIC_BASIS_MATERIAL_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
       where GAC.GCO_ALLOY_ID = cAlloyID;
    */
    bStop                     boolean;
    bWeighing                 boolean;
    posCreateMat              DOC_POSITION.POS_CREATE_MAT%type;
    posGoodID                 GCO_GOOD.GCO_GOOD_ID%type;
    posManufacturedGoodID     GCO_GOOD.GCO_GOOD_ID%type;
    lGoodID                   GCO_GOOD.GCO_GOOD_ID%type;
    dmtDocumentID             DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    doaPositionAlloyID        DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
    doaBaseMatPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
    gasWeighingMgm            DOC_GAUGE_STRUCTURED.GAS_WEIGHING_MGM%type;
    gasWeightMat              DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    PosLotType                DOC_GAUGE_POSITION.C_DOC_LOT_TYPE%type;
    gpmWeight                 GCO_PRECIOUS_MAT.GPM_WEIGHT%type;
    thirdWeighingMgnt         PAC_CUSTOM_PARTNER.C_WEIGHING_MGNT%type;
    fweWeighID1               FAL_WEIGH.FAL_WEIGH_ID%type;
    fweWeighID2               FAL_WEIGH.FAL_WEIGH_ID%type;
  begin
    bStop      := false;
    gpmWeight  := 0;

    begin
      select POS.POS_CREATE_MAT
           , POS.GCO_GOOD_ID
           , POS.GCO_MANUFACTURED_GOOD_ID
           , POS.DOC_DOCUMENT_ID
           , GAS.GAS_WEIGHING_MGM
           , GAS.GAS_WEIGHT_MAT
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.C_WEIGHING_MGNT
                  , cAdminDomainSale, CUS.C_WEIGHING_MGNT
                  , cAdminDomainSubContract, SUP.C_WEIGHING_MGNT
                  , nvl(CUS.C_WEIGHING_MGNT, SUP.C_WEIGHING_MGNT)
                   ) C_WEIGHING_MGNT
           , GPO.C_DOC_LOT_TYPE
        into posCreateMat
           , posGoodID
           , posManufacturedGoodID
           , dmtDocumentID
           , gasWeighingMgm
           , gasWeightMat
           , thirdWeighingMgnt
           , PosLotType
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_POSITION GPO
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where POS.DOC_POSITION_ID = aPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GPO.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = POS.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = POS.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      begin
        -- Assignation de l'ID du bien selon STT ou non.
        if (DOC_LIB_SUBCONTRACT.IsPositionSubcontract(iPositionId => aPositionID) = 1) then
          lGoodId  := nvl(PosManufacturedGoodId, DOC_LIB_SUBCONTRACT.getManufacturedGoodId(iPositionId => aPositionID) );
        else
          lGoodId  := PosGoodId;
        end if;

        -- Test si le bien gère les matières précieuses et les poids matières précieuses.
        select max(GPM.GPM_WEIGHT)
          into gpmWeight
          from GCO_PRECIOUS_MAT GPM
             , GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = lGoodID
           and GOO.GOO_PRECIOUS_MAT = 1
           and GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and GPM.GPM_WEIGHT = 1;
      exception
        when no_data_found then
          bStop  := true;
      end;
    end if;

    if     not bStop
       and gasWeightMat = 1
       and gpmWeight = 1
       and posCreateMat <> 2 then
      -- Pour chaque matières précieuses du produit géré en pesée
      for tplGoodPreciousMatWeighing in crGoodPreciousMatWeighing(lGoodID) loop
        ----
        -- Création Matière Position de type Alliage
        --
        CreatePositionMatAlloyType(aPositionID, lGoodId, tplGoodPreciousMatWeighing.GCO_PRECIOUS_MAT_ID, gasWeighingMgm, thirdWeighingMgnt, doaPositionAlloyID);

        ----
        -- La génération de la pesée doit se faire dans les cas suivants :
        --    1. Le gabarit gère les pesées
        --    2. Le tiers est en pesée théorique
        --       ou La matière précieuse courante n'est pas en pesée réelle (donc en pesée théorique)
        --
        if (gasWeighingMgm = 1) then
          if (thirdWeighingMgnt = 2) then
            bWeighing  := true;
          elsif(tplGoodPreciousMatWeighing.GPM_REAL_WEIGHT = 0) then
            bWeighing  := true;
          else
            bWeighing  := false;
          end if;

          if bWeighing then
            -- Génération pesée
            GenerateWeighing(aPositionID, lGoodId, tplGoodPreciousMatWeighing.GCO_PRECIOUS_MAT_ID, fweWeighID1, fweWeighID2);
          -- Mise à jour création pesé Poids Position
          --UpdatePositionMatWeigh(doaPositionAlloyID, fweWeighID, null, null);
          end if;
        end if;

        ----
        -- Génération (création ou modification) des matières de base de l'alliage courant en fonction de la nouvelle
        -- position matière précieuse de type alliage créée. Voir graphes Génération Matières Position et
        -- Création Matières Positions.
        --
        GeneratePositionMatBaseMatType(aPositionID, doaPositionAlloyID, tplGoodPreciousMatWeighing.GCO_ALLOY_ID);
      end loop;

      -- Mise à jour de l'indicateur Matières position créées
      update DOC_POSITION
         set POS_CREATE_MAT = 2
       where DOC_POSITION_ID = aPositionID;

      ----
      -- Mise à jour de l'indicateur de re-calcul des Matières pied
      --
      UpdateDocumentFlag(aPositionID);
    end if;
  end GeneratePositionMat;

  /**
  * Description
  *    Processus Génération pesé
  */
  procedure GenerateWeighing(
    aPositionID        DOC_POSITION.DOC_POSITION_ID%type
  , aGoodID            GCO_GOOD.GCO_GOOD_ID%type
  , aPreciousMatID     GCO_PRECIOUS_MAT.GCO_PRECIOUS_MAT_ID%type
  , aWeighID1      out FAL_WEIGH.FAL_WEIGH_ID%type
  , aWeighID2      out FAL_WEIGH.FAL_WEIGH_ID%type
  )
  is
    lOperator PCS.PC_USER.USE_INI%type;
  begin
    begin
      select PCS.PC_I_LIB_SESSION.GetUserIni
        into lOperator
        from DIC_OPERATOR
       where DIC_OPERATOR_ID = PCS.PC_I_LIB_SESSION.GetUserIni;
    exception
      when no_data_found then
        lOperator  := 'SYS';
    end;

    insert into FAL_WEIGH FWE
                (FWE.FAL_WEIGH_ID
               , FWE.GCO_ALLOY_ID
               , FWE.GCO_GOOD_ID
               , FWE.FAL_LOT_ID
               , FWE.FAL_SCHEDULE_STEP_ID
               , FWE.DOC_POSITION_ID
               , FWE.DOC_DOCUMENT_ID
               , FWE.DIC_OPERATOR_ID
               , FWE.FAL_SCALE_PAN_ID
               , FWE.FWE_PAN_WEIGHT
               , FWE.FWE_IN
               , FWE.FWE_WASTE
               , FWE.FWE_TURNINGS
               , FWE.FWE_INIT
               , FWE.FAL_POSITION1_ID
               , FWE.FAL_POSITION2_ID
               , FWE.FWE_DATE
               , FWE.FWE_PIECE_QTY
               , FWE.FWE_WEIGHT
               , FWE.FWE_WEIGHT_MAT
               , FWE.FWE_COMMENT
               , FWE.GAL_ALLOY_REF
               , FWE.FWE_POSITION1_DESCR
               , FWE.FWE_POSITION2_DESCR
               , FWE.GOO_MAJOR_REFERENCE
               , FWE.GOO_SECONDARY_REFERENCE
               , FWE.FWE_WEEKDATE
               , FWE.DMT_NUMBER
               , FWE.C_WEIGH_TYPE
               , FWE.A_DATECRE
               , FWE.A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- FAL_WEIGH_ID
           , GPM.GCO_ALLOY_ID   -- GCO_ALLOY_ID
           , POS.GCO_GOOD_ID   -- GCO_GOOD_ID
           , null   -- FAL_LOT_ID
           , null   -- FAL_SCHEDULE_STEP_ID
           , POS.DOC_POSITION_ID   -- DOC_POSITION_ID
           , POS.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
           , lOperator   -- DIC_OPERATOR_ID
           , null   -- FAL_SCALE_PAN_ID
           , 0   -- FWE_PAN_WEIGHT
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', 1, 'SOR', 0, null)   -- FWE_IN
           , 0   -- FWE_WASTE
           , 0   -- FWE_TURNINGS
           , 0   -- FWE_INIT
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', FPO.FAL_POSITION_ID, null)   -- FAL_POSITION1_ID
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'SOR', FPO.FAL_POSITION_ID, null)   -- FAL_POSITION2_ID
           , sysdate   -- FWE_DATE
           , POS.POS_BASIS_QUANTITY_SU   -- FWE_PIECE_QTY
           , POS.POS_BASIS_QUANTITY_SU * GPM.GPM_WEIGHT_DELIVER   -- FWE_WEIGHT
           , POS.POS_BASIS_QUANTITY_SU * GPM.GPM_WEIGHT_DELIVER   -- FWE_WEIGHT_MAT
           , null   -- FWE_COMMENT
           , GAL.GAL_ALLOY_REF   -- GAL_ALLOY_REF
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', FPO.FPO_DESCRIPTION, null)   -- FWE_POSITION1_DESCR
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'SOR', FPO.FPO_DESCRIPTION, null)   -- FWE_POSITION2_DESCR
           , GOO.GOO_MAJOR_REFERENCE   -- GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE   -- GOO_SECONDARY_REFERENCE
           , to_char(sysdate, 'YYYY.WW')   -- FWE_WEEKDATE
           , DMT.DMT_NUMBER   -- DMT_NUMBER
           , '3'   -- Type de pesée : Venant d'un document, il s'agit toujours de "Mouvement matières" --> C_WEIGH_TYPE = '3'
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , STM_MOVEMENT_KIND MOK
           , FAL_POSITION FPO
           , GCO_PRECIOUS_MAT GPM
           , GCO_ALLOY GAL
           , GCO_GOOD GOO
       where POS.DOC_POSITION_ID = aPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID
         and FPO.STM_STOCK_ID = POS.STM_STOCK_ID
         and GPM.GCO_GOOD_ID = aGoodId
         and GPM.GCO_PRECIOUS_MAT_ID = aPreciousMatID
         and GAL.GCO_ALLOY_ID(+) = GPM.GCO_ALLOY_ID
         and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID;

    select INIT_ID_SEQ.currval
      into aWeighID1
      from dual;

    --transfert de stock si POS.STM_STM_STOCK_ID est non null -> entrée dans le stock sous traitant
    insert into FAL_WEIGH FWE
                (FWE.FAL_WEIGH_ID
               , FWE.GCO_ALLOY_ID
               , FWE.GCO_GOOD_ID
               , FWE.FAL_LOT_ID
               , FWE.FAL_SCHEDULE_STEP_ID
               , FWE.DOC_POSITION_ID
               , FWE.DOC_DOCUMENT_ID
               , FWE.DIC_OPERATOR_ID
               , FWE.FAL_SCALE_PAN_ID
               , FWE.FWE_PAN_WEIGHT
               , FWE.FWE_IN
               , FWE.FWE_WASTE
               , FWE.FWE_TURNINGS
               , FWE.FWE_INIT
               , FWE.FAL_POSITION1_ID
               , FWE.FAL_POSITION2_ID
               , FWE.FWE_DATE
               , FWE.FWE_PIECE_QTY
               , FWE.FWE_WEIGHT
               , FWE.FWE_WEIGHT_MAT
               , FWE.FWE_COMMENT
               , FWE.GAL_ALLOY_REF
               , FWE.FWE_POSITION1_DESCR
               , FWE.FWE_POSITION2_DESCR
               , FWE.GOO_MAJOR_REFERENCE
               , FWE.GOO_SECONDARY_REFERENCE
               , FWE.FWE_WEEKDATE
               , FWE.DMT_NUMBER
               , FWE.C_WEIGH_TYPE
               , FWE.A_DATECRE
               , FWE.A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- FAL_WEIGH_ID
           , GPM.GCO_ALLOY_ID   -- GCO_ALLOY_ID
           , POS.GCO_GOOD_ID   -- GCO_GOOD_ID
           , null   -- FAL_LOT_ID
           , null   -- FAL_SCHEDULE_STEP_ID
           , POS.DOC_POSITION_ID   -- DOC_POSITION_ID
           , POS.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
           , lOperator   -- DIC_OPERATOR_ID
           , null   -- FAL_SCALE_PAN_ID
           , 0   -- FWE_PAN_WEIGHT
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', 0, 'SOR', 1, null)   -- FWE_IN
           , 0   -- FWE_WASTE
           , 0   -- FWE_TURNINGS
           , 0   -- FWE_INIT
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', null, FPO.FAL_POSITION_ID)   -- FAL_POSITION1_ID
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'SOR', null, FPO.FAL_POSITION_ID)   -- FAL_POSITION2_ID
           , sysdate   -- FWE_DATE
           , POS.POS_BASIS_QUANTITY_SU   -- FWE_PIECE_QTY
           , POS.POS_BASIS_QUANTITY_SU * GPM.GPM_WEIGHT_DELIVER   -- FWE_WEIGHT
           , POS.POS_BASIS_QUANTITY_SU * GPM.GPM_WEIGHT_DELIVER   -- FWE_WEIGHT_MAT
           , null   -- FWE_COMMENT
           , GAL.GAL_ALLOY_REF   -- GAL_ALLOY_REF
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'ENT', null, FPO.FPO_DESCRIPTION)   -- FWE_POSITION1_DESCR
           , decode(MOK.C_MOVEMENT_SORT, null, null, 'SOR', null, FPO.FPO_DESCRIPTION)   -- FWE_POSITION2_DESCR
           , GOO.GOO_MAJOR_REFERENCE   -- GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE   -- GOO_SECONDARY_REFERENCE
           , to_char(sysdate, 'YYYY.WW')   -- FWE_WEEKDATE
           , DMT.DMT_NUMBER   -- DMT_NUMBER
           , '3'   -- Type de pesée : Venant d'un document, il s'agit toujours de "Mouvement matières" --> C_WEIGH_TYPE = '3'
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , STM_MOVEMENT_KIND MOK
           , FAL_POSITION FPO
           , GCO_PRECIOUS_MAT GPM
           , GCO_ALLOY GAL
           , GCO_GOOD GOO
       where POS.DOC_POSITION_ID = aPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID
         and FPO.STM_STOCK_ID = POS.STM_STM_STOCK_ID
         and GPM.GCO_GOOD_ID = aGoodId
         and GPM.GCO_PRECIOUS_MAT_ID = aPreciousMatID
         and GAL.GCO_ALLOY_ID(+) = GPM.GCO_ALLOY_ID
         and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID;

    select INIT_ID_SEQ.currval
      into aWeighID2
      from dual;
  end GenerateWeighing;

  /**
  * Description
  *    Processus Création Matière Position de type Alliage
  */
  procedure CreatePositionMatAlloyType(
    aPositionID           DOC_POSITION.DOC_POSITION_ID%type
  , aGoodID               GCO_GOOD.GCO_GOOD_ID%type
  , aPreciousMatID        GCO_PRECIOUS_MAT.GCO_PRECIOUS_MAT_ID%type
  , aWeighingMgm          DOC_GAUGE_STRUCTURED.GAS_WEIGHING_MGM%type
  , aThirdWeighingMgm     PAC_CUSTOM_PARTNER.C_WEIGHING_MGNT%type
  , aPositionAlloyID  out DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aMode                 varchar2 default null
  )
  is
  begin
    select INIT_ID_SEQ.nextval
      into aPositionAlloyID
      from dual;

    insert into DOC_POSITION_ALLOY DOA
                (DOA.DOC_POSITION_ALLOY_ID
               , DOA.DOC_POSITION_ID
               , DOA.DOC_DOCUMENT_ID
               , DOA.GCO_ALLOY_ID
               , DOA.DIC_BASIS_MATERIAL_ID
               , DOA.C_MUST_WEIGH
               , DOA.C_MUST_TYPE
               , DOA.DOA_WEIGHT
               , DOA.DOA_WEIGHT_MAT
               , DOA.DOA_STONE_NUM
               , DOA.DOA_WEIGHT_DELIVERY_TH
               , DOA.DOA_WEIGHT_DELIVERY
               , DOA.DOA_WEIGHT_DIF
               , DOA.DOA_LOSS_TH
               , DOA.DOA_LOSS
               , DOA.DOA_WEIGHT_INVEST_TH
               , DOA.DOA_WEIGHT_INVEST
               , DOA.DOA_COMMENT
               , DOA.A_DATECRE
               , DOA.A_IDCRE
                )
      select aPositionAlloyID   -- DOC_POSITION_ALLOY_ID
           , POS.DOC_POSITION_ID   -- DOC_POSITION_ID
           , POS.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
           , GPM.GCO_ALLOY_ID   -- GCO_ALLOY_ID
           , null   -- DIC_BASIS_MATERIAL_ID
           , decode(nvl(aWeighingMgm, 0), 1, '01', '03')   -- C_MUST_WEIGH
           , decode(nvl(aWeighingMgm, 0), 0, decode(nvl(aThirdWeighingMgm, 1), 1, decode(GPM.GPM_REAL_WEIGHT, 1, '01', '03'), '03'), '03')   -- C_MUST_TYPE
           , null   -- DOA_WEIGHT
           , null   -- DOA_WEIGHT_MAT
           , GPM.GPM_STONE_NUMBER * POS.POS_BASIS_QUANTITY_SU   -- DOA_STONE_NUM
           , GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU   -- DOA_WEIGHT_DELIVERY_TH
           , decode(nvl(aWeighingMgm, 0)
                  , 0, decode(nvl(aThirdWeighingMgm, 1)
                            , 1, decode(GPM.GPM_THEORICAL_WEIGHT, 1, GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU, null)
                            , 2, GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU
                            , null
                             )
                  , 1, null
                  , null
                   )   -- DOA_WEIGHT_DELIVERY
           , decode(GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU
                  , 0, 0
                  , ( (GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU) -
                     nvl(decode(nvl(aWeighingMgm, 0)
                              , 0, decode(nvl(aThirdWeighingMgm, 1)
                                        , 1, decode(GPM.GPM_THEORICAL_WEIGHT, 1, GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU, null)
                                        , 2, GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU
                                        , null
                                         )
                              , 1, null
                              , null
                               )
                       , 0
                        )
                    ) *
                    100 /
                    (GPM.GPM_WEIGHT_DELIVER * POS.POS_BASIS_QUANTITY_SU)
                   )   -- DOA_WEIGHT_DIF
           , GPM.GPM_LOSS_UNIT * POS.POS_BASIS_QUANTITY_SU   -- DOA_LOSS_TH
           , GPM.GPM_LOSS_UNIT * POS.POS_BASIS_QUANTITY_SU   -- DOA_LOSS
           , GPM.GPM_WEIGHT_INVEST * POS.POS_BASIS_QUANTITY_SU   -- DOA_WEIGHT_INVEST_TH
           , decode(nvl(aWeighingMgm, 0)
                  , 0, decode(nvl(aThirdWeighingMgm, 1)
                            , 1, decode(GPM.GPM_THEORICAL_WEIGHT, 1, GPM.GPM_WEIGHT_INVEST * POS.POS_BASIS_QUANTITY_SU, null)
                            , 2, GPM.GPM_WEIGHT_INVEST * POS.POS_BASIS_QUANTITY_SU
                            , null
                             )
                  , 1, null
                  , null
                   )   -- DOA_WEIGHT_INVEST
           , null   -- DOA_COMMENT
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from DOC_POSITION POS
           , GCO_PRECIOUS_MAT GPM
       where POS.DOC_POSITION_ID = aPositionID
         and GPM.GCO_GOOD_ID = aGoodId
         and GPM.GCO_PRECIOUS_MAT_ID = aPreciousMatID;
  end CreatePositionMatAlloyType;

  /**
  * Description
  *    Processus Création Matière Position de type Matière de base
  */
  procedure CreatePositionMatBaseMatType(
    aPositionID             DOC_POSITION.DOC_POSITION_ID%type
  , aSrcPositionAlloyID     DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aAlloyID                GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialID        DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aRate                   GCO_ALLOY_COMPONENT.GAC_RATE%type
  , aPositionAlloyID    out DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  )
  is
  begin
    select INIT_ID_SEQ.nextval
      into aPositionAlloyID
      from dual;

    insert into DOC_POSITION_ALLOY DOA
                (DOA.DOC_POSITION_ALLOY_ID
               , DOA.DOC_POSITION_ID
               , DOA.DOC_DOCUMENT_ID
               , DOA.GCO_ALLOY_ID
               , DOA.DIC_BASIS_MATERIAL_ID
               , DOA.C_MUST_WEIGH
               , DOA.C_MUST_TYPE
               , DOA.DOA_WEIGHT
               , DOA.DOA_WEIGHT_MAT
               , DOA.DOA_STONE_NUM
               , DOA.DOA_WEIGHT_DELIVERY_TH
               , DOA.DOA_WEIGHT_DELIVERY
               , DOA.DOA_WEIGHT_DIF
               , DOA.DOA_LOSS_TH
               , DOA.DOA_LOSS
               , DOA.DOA_WEIGHT_INVEST_TH
               , DOA.DOA_WEIGHT_INVEST
               , DOA.DOA_COMMENT
               , DOA.A_DATECRE
               , DOA.A_IDCRE
                )
      select aPositionAlloyID   -- DOC_POSITION_ALLOY_ID
           , aPositionID   -- DOC_POSITION_ID
           , DOA_SRC.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
           , null   -- GCO_ALLOY_ID
           , aBasisMaterialID   -- DIC_BASIS_MATERIAL_ID
           , '03'   -- C_MUST_WEIGH
           , '03'   -- C_MUST_TYPE
           , nvl(DOA_SRC.DOA_WEIGHT, 0) * aRate   -- DOA_WEIGHT
           , nvl(DOA_SRC.DOA_WEIGHT_MAT, 0) * aRate   -- DOA_WEIGHT_MAT
           , null   -- DOA_STONE_NUM
           , nvl(DOA_SRC.DOA_WEIGHT_DELIVERY_TH, 0) * aRate   -- DOA_WEIGHT_DELIVERY_TH
           , nvl(DOA_SRC.DOA_WEIGHT_DELIVERY, 0) * aRate   -- DOA_WEIGHT_DELIVERY
           , decode(nvl( (DOA_SRC.DOA_WEIGHT_DELIVERY_TH * aRate), 0)
                  , 0, 0
                  , ( (DOA_SRC.DOA_WEIGHT_DELIVERY_TH * aRate) -(nvl(DOA_SRC.DOA_WEIGHT_DELIVERY, 0) * aRate) ) * 100 /(DOA_SRC.DOA_WEIGHT_DELIVERY_TH * aRate)
                   )   -- DOA_WEIGHT_DIF
           , nvl(DOA_SRC.DOA_LOSS_TH, 0) * aRate   -- DOA_LOSS_TH
           , nvl(DOA_SRC.DOA_LOSS_TH, 0) * aRate   -- DOA_LOSS
           , nvl(DOA_SRC.DOA_WEIGHT_INVEST_TH, 0) * aRate   -- DOA_WEIGHT_INVEST_TH
           , nvl(DOA_SRC.DOA_WEIGHT_INVEST, 0) * aRate   -- DOA_WEIGHT_INVEST
           , null   -- DOA_COMMENT
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from DOC_POSITION_ALLOY DOA_SRC
       where DOA_SRC.DOC_POSITION_ALLOY_ID = aSrcPositionAlloyID;
  end CreatePositionMatBaseMatType;

  /**
  * Description
  *    Processus Création Matière Position d'après les données de la position parent
  */
  procedure CreatePositionMatFromParent(
    aPositionID       DOC_POSITION.DOC_POSITION_ID%type
  , aSourcePositionID DOC_POSITION.DOC_POSITION_ID%type
  , aMode             varchar2 default 'DISCHARGE'
  )
  is
    cursor crSourcePositionAlloy(cSourcePositionID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , DOA.GCO_ALLOY_ID
           , DOA.DIC_BASIS_MATERIAL_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) DOA_WEIGHT_DELIVERY_TH
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(DOA.DOA_WEIGHT_DIF, 0) DOA_WEIGHT_DIF
           , nvl(DOA.DOA_LOSS_TH, 0) DOA_LOSS_TH
           , nvl(DOA.DOA_LOSS, 0) DOA_LOSS
           , nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) DOA_WEIGHT_INVEST_TH
           , nvl(DOA.DOA_WEIGHT_INVEST, 0) DOA_WEIGHT_INVEST
           , nvl(DOA.DOA_STONE_NUM, 0) DOA_STONE_NUM
           , DOA.DOA_COMMENT
           , nvl(DOA.DOA_RATE_DATE, DMT.DMT_DATE_DOCUMENT) DOA_RATE_DATE
           , DOA.STM_STOCK_ID
        from DOC_POSITION_ALLOY DOA
           , DOC_DOCUMENT DMT
       where DOA.DOC_POSITION_ID = cSourcePositionID
         and DMT.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID;

    tplSourcePositionAlloy   crSourcePositionAlloy%rowtype;
    gasWeighingMgm           DOC_GAUGE_STRUCTURED.GAS_WEIGHING_MGM%type;
    gasWeightMat             DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    dmtDocumentID            DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    posBasisQuantitySU       DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
    posSourceBasisQuantitySU DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
    posCreateMat             DOC_POSITION.POS_CREATE_MAT%type;
    doaPositionAlloyID       DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
    gpmStoneNumber           GCO_PRECIOUS_MAT.GPM_STONE_NUMBER%type;
    gpmWeightDeliver         GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
    gpmLossUnit              GCO_PRECIOUS_MAT.GPM_LOSS_UNIT%type;
    gpmWeightInvest          GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST%type;
    gpmPreciousMatID         GCO_PRECIOUS_MAT.GCO_PRECIOUS_MAT_ID%type;
    gpmRealWeight            GCO_PRECIOUS_MAT.GPM_REAL_WEIGHT%type;
    gpmWeight                GCO_PRECIOUS_MAT.GPM_WEIGHT%type;
    fweWeighID               FAL_WEIGH.FAL_WEIGH_ID%type;
    posGoodID                GCO_GOOD.GCO_GOOD_ID%type;
    posManufacturedGoodID    GCO_GOOD.GCO_GOOD_ID%type;
    thirdWeighingMgnt        PAC_CUSTOM_PARTNER.C_WEIGHING_MGNT%type;
    bStop                    boolean;
    bWeighing                boolean;
    nIsSubcontractPos        number;
  begin
    bStop      := false;
    gpmWeight  := 0;

    begin
      select POS.POS_CREATE_MAT
           , POS.GCO_GOOD_ID
           , POS.GCO_MANUFACTURED_GOOD_ID
           , POS.POS_BASIS_QUANTITY_SU
           , DMT.DOC_DOCUMENT_ID
           , GAS.GAS_WEIGHING_MGM
           , GAS.GAS_WEIGHT_MAT
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.C_WEIGHING_MGNT
                  , cAdminDomainSale, CUS.C_WEIGHING_MGNT
                  , cAdminDomainSubContract, SUP.C_WEIGHING_MGNT
                  , nvl(CUS.C_WEIGHING_MGNT, SUP.C_WEIGHING_MGNT)
                   ) C_WEIGHING_MGNT
           , DOC_LIB_SUBCONTRACT.IsPositionSubcontract(iPositionId => POS.DOC_POSITION_ID)
        into posCreateMat
           , posGoodID
           , posManufacturedGoodID
           , posBasisQuantitySU
           , dmtDocumentID
           , gasWeighingMgm
           , gasWeightMat
           , thirdWeighingMgnt
           , nIsSubcontractPos
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where POS.DOC_POSITION_ID = aPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = POS.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = POS.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      begin
        -- teste si le bien gêre les matières précieuses et les poids matières précieuses.
        select max(GPM.GPM_WEIGHT)
          into gpmWeight
          from GCO_PRECIOUS_MAT GPM
             , GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = DECODE(nIsSubcontractPos,1,posManufacturedGoodID,posGoodID)
           and GOO.GOO_PRECIOUS_MAT = 1
           and GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and GPM.GPM_WEIGHT = 1;
      exception
        when no_data_found then
          bStop  := true;
      end;
    end if;

    if     not bStop
       and gasWeightMat = 1
       and gpmWeight = 1
       and posCreateMat <> 2 then
      -- Chargement des matières position source.
      open crSourcePositionAlloy(aSourcePositionID);

      fetch crSourcePositionAlloy
       into tplSourcePositionAlloy;

      -- Vérifie la présence de matière position sur la position source.
      if not crSourcePositionAlloy%found then
        -- Si aucune matière position sur la position source, nous nous trouvons dans le cas suivant :
        -- La gestion des matières positions a été mise en place après la création de la position source (DEVLOG-14034)
        -- Dans ce cas, il faut garantir la création des matières positions sur la nouvelle position. D'ou la génération
        -- des matières positions comme en création simple.
        GeneratePositionMat(aPositionID);
      else
        -- Reprise des matières positions de la position source.

        -- Recherche la quantité de base en unité de stockage de la position source pour calculer la proportionnalité.
        select POS.POS_BASIS_QUANTITY_SU
          into posSourceBasisQuantitySU
          from DOC_POSITION POS
         where POS.DOC_POSITION_ID = aSourcePositionID;

        -- Balaie l'ensemble des matières position source.
        while crSourcePositionAlloy%found loop
          gpmStoneNumber    := null;
          gpmWeightDeliver  := null;
          gpmLossUnit       := null;
          gpmWeightInvest   := null;
          gpmPreciousMatID  := null;
          gpmRealWeight     := null;
          gpmWeight         := null;

          if tplSourcePositionAlloy.GCO_ALLOY_ID is not null then
            begin
              select GPM.GPM_STONE_NUMBER
                   , GPM.GPM_WEIGHT_DELIVER
                   , GPM.GPM_LOSS_UNIT
                   , GPM.GPM_WEIGHT_INVEST
                   , GPM.GCO_PRECIOUS_MAT_ID
                   , GPM.GPM_REAL_WEIGHT
                   , GPM.GPM_WEIGHT
                into gpmStoneNumber
                   , gpmWeightDeliver
                   , gpmLossUnit
                   , gpmWeightInvest
                   , gpmPreciousMatID
                   , gpmRealWeight
                   , gpmWeight
                from GCO_PRECIOUS_MAT GPM
               where GPM.GCO_ALLOY_ID = tplSourcePositionAlloy.GCO_ALLOY_ID
                 and GPM.GCO_GOOD_ID = DECODE(nIsSubcontractPos,1,posManufacturedGoodID,posGoodID);
            exception
              when no_data_found then
                null;
            end;
          end if;

          insert into DOC_POSITION_ALLOY DOA
                      (DOA.DOC_POSITION_ALLOY_ID
                     , DOA.DOC_POSITION_ID
                     , DOA.DOC_DOCUMENT_ID
                     , DOA.GCO_ALLOY_ID
                     , DOA.DIC_BASIS_MATERIAL_ID
                     , DOA.C_MUST_WEIGH
                     , DOA.C_MUST_TYPE
                     , DOA.DOA_WEIGHT
                     , DOA.DOA_WEIGHT_MAT
                     , DOA.DOA_STONE_NUM
                     , DOA.DOA_WEIGHT_DELIVERY_TH
                     , DOA.DOA_WEIGHT_DELIVERY
                     , DOA.DOA_WEIGHT_DIF
                     , DOA.DOA_LOSS_TH
                     , DOA.DOA_LOSS
                     , DOA.DOA_WEIGHT_INVEST_TH
                     , DOA.DOA_WEIGHT_INVEST
                     , DOA.DOA_COMMENT
                     , DOA.DOA_RATE_DATE
                     , DOA.STM_STOCK_ID
                     , DOA.A_DATECRE
                     , DOA.A_IDCRE
                      )
            select INIT_ID_SEQ.nextval   -- DOC_POSITION_ALLOY_ID
                 , aPositionID   -- DOC_POSITION_ID
                 , dmtDocumentID   -- DOC_DOCUMENT_ID
                 , tplSourcePositionAlloy.GCO_ALLOY_ID   -- GCO_ALLOY_ID
                 , tplSourcePositionAlloy.DIC_BASIS_MATERIAL_ID   -- DIC_BASIS_MATERIAL_ID
                 , '03'   -- C_MUST_WEIGH
                 , '03'   -- C_MUST_TYPE
                 , null   -- DOA_WEIGHT
                 , null   -- DOA_WEIGHT_MAT
                 , nvl(gpmStoneNumber, tplSourcePositionAlloy.DOA_STONE_NUM / posSourceBasisQuantitySU) * posBasisQuantitySU   -- DOA_STONE_NUM
                 , nvl(gpmWeightDeliver, tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY_TH / posSourceBasisQuantitySU) * posBasisQuantitySU   -- DOA_WEIGHT_DELIVERY_TH
                 , tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY / posSourceBasisQuantitySU * posBasisQuantitySU   -- DOA_WEIGHT_DELIVERY
                 , decode(nvl(gpmWeightDeliver, tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY_TH / posSourceBasisQuantitySU) * posBasisQuantitySU
                        , 0, 0
                        , ( (nvl(gpmWeightDeliver, tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY_TH / posSourceBasisQuantitySU) * posBasisQuantitySU) -
                           (tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY / posSourceBasisQuantitySU * posBasisQuantitySU
                           )
                          ) *
                          100 /
                          (nvl(gpmWeightDeliver, tplSourcePositionAlloy.DOA_WEIGHT_DELIVERY_TH / posSourceBasisQuantitySU) * posBasisQuantitySU)
                         )   -- DOA_WEIGHT_DIF
                 , nvl(gpmLossUnit, tplSourcePositionAlloy.DOA_LOSS_TH / posSourceBasisQuantitySU) * posBasisQuantitySU   -- DOA_LOSS_TH
                 , tplSourcePositionAlloy.DOA_LOSS / posSourceBasisQuantitySU * posBasisQuantitySU   -- DOA_LOSS
                 , nvl(gpmWeightInvest, tplSourcePositionAlloy.DOA_WEIGHT_INVEST_TH / posSourceBasisQuantitySU) * posBasisQuantitySU   -- DOA_WEIGHT_INVEST_TH
                 , tplSourcePositionAlloy.DOA_WEIGHT_INVEST / posSourceBasisQuantitySU * posBasisQuantitySU   -- DOA_WEIGHT_INVEST
                 , tplSourcePositionAlloy.DOA_COMMENT   -- DOA_COMMENT
                 , tplSourcePositionAlloy.DOA_RATE_DATE   -- DOA_RATE_DATE
                 , tplSourcePositionAlloy.STM_STOCK_ID   -- STM_STOCK_ID
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
              from dual;

          fetch crSourcePositionAlloy
           into tplSourcePositionAlloy;
        end loop;

        -- Mise à jour de l'indicateur Matières position créées
        update DOC_POSITION
           set POS_CREATE_MAT = 2
         where DOC_POSITION_ID = aPositionID;

        ----
        -- Mise à jour de l'indicateur de re-calcul des Matières pied
        --
        UpdateDocumentFlag(aPositionID);
      end if;

      close crSourcePositionAlloy;
    end if;
  end CreatePositionMatFromParent;

  /**
  * Description
  *    Processus Mise à jour création pesé Poids Position
  */
  procedure UpdatePositionMatWeigh(
    aPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aWeighID         FAL_WEIGH.FAL_WEIGH_ID%type
  , aWeight          FAL_WEIGH.FWE_WEIGHT%type
  , aWeightMat       FAL_WEIGH.FWE_WEIGHT_MAT%type
  )
  is
    bStop        boolean;
    fweWeight    FAL_WEIGH.FWE_WEIGHT%type;
    fweWeightMat FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    bStop  := false;

    if aWeighID is null then
      fweWeight     := nvl(aWeight, 0);
      fweWeightMat  := nvl(aWeightMat, 0);
    else
      -- Attention : L'id de la pesée ne doit pas être transmis si l'appel de la procèdure UpdatePositionMatWeigh
      -- s'effectue dans les triggers de insert et/ou d'update de la pesée.
      begin
        select nvl(FWE.FWE_WEIGHT, 0)
             , nvl(FWE.FWE_WEIGHT_MAT, 0)
          into fweWeight
             , fweWeightMat
          from FAL_WEIGH FWE
         where FWE.FAL_WEIGH_ID = aWeighID;
      exception
        when no_data_found then
          bStop  := true;
      end;
    end if;

    if not bStop then
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_WEIGHT = nvl(DOA.DOA_WEIGHT, 0) + fweWeight
           , DOA.DOA_WEIGHT_MAT = nvl(DOA.DOA_WEIGHT_MAT, 0) + fweWeightMat
           , DOA.DOA_WEIGHT_DELIVERY = nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + fweWeightMat
           , DOA.DOA_WEIGHT_DIF =
               decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0)
                    , 0, 0
                    , (DOA.DOA_WEIGHT_DELIVERY_TH -(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + fweWeightMat) ) * 100 / DOA.DOA_WEIGHT_DELIVERY_TH
                     )
           , DOA.C_MUST_WEIGH = '02'
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , DOA.A_DATEMOD = sysdate
       where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
    end if;
  end UpdatePositionMatWeigh;

  /**
  * Description
  *    Processus Mise à jour Matière Position de type Matière de base
  */
  procedure UpdatePositionMatBaseMatType(
    aPositionAlloyID      DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aAlloyPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aRate                 GCO_ALLOY_COMPONENT.GAC_RATE%type
  )
  is
    cursor crPositionAlloy(cPositionAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) DOA_WEIGHT_DELIVERY_TH
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(DOA.DOA_WEIGHT_DIF, 0) DOA_WEIGHT_DIF
           , nvl(DOA.DOA_LOSS_TH, 0) DOA_LOSS_TH
           , nvl(DOA.DOA_LOSS, 0) DOA_LOSS
           , nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) DOA_WEIGHT_INVEST_TH
           , nvl(DOA.DOA_WEIGHT_INVEST, 0) DOA_WEIGHT_INVEST
        from DOC_POSITION_ALLOY DOA
       where DOA.DOC_POSITION_ALLOY_ID = cPositionAlloyID;

    tplPositionAlloy crPositionAlloy%rowtype;
  begin
    open crPositionAlloy(aAlloyPositionAlloyID);

    fetch crPositionAlloy
     into tplPositionAlloy;

    if crPositionAlloy%found then
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_WEIGHT = nvl(DOA.DOA_WEIGHT, 0) +(tplPositionAlloy.DOA_WEIGHT * aRate)
           , DOA.DOA_WEIGHT_MAT = nvl(DOA.DOA_WEIGHT_MAT, 0) +(tplPositionAlloy.DOA_WEIGHT_MAT * aRate)
           , DOA.DOA_WEIGHT_DELIVERY_TH = nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) +(tplPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate)
           , DOA.DOA_WEIGHT_DELIVERY = nvl(DOA.DOA_WEIGHT_DELIVERY, 0) +(tplPositionAlloy.DOA_WEIGHT_DELIVERY * aRate)
           , DOA.DOA_WEIGHT_DIF =
               decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0)
                    , 0, 0
                    , ( (DOA.DOA_WEIGHT_DELIVERY_TH +(tplPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate) ) -
                       (DOA.DOA_WEIGHT_DELIVERY +(tplPositionAlloy.DOA_WEIGHT_DELIVERY * aRate)
                       )
                      ) *
                      100 /
                      (DOA.DOA_WEIGHT_DELIVERY_TH +(tplPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate) )
                     )
           , DOA.DOA_LOSS_TH = nvl(DOA.DOA_LOSS_TH, 0) +(tplPositionAlloy.DOA_LOSS_TH * aRate)
           , DOA.DOA_LOSS = nvl(DOA.DOA_LOSS_TH, 0) +(tplPositionAlloy.DOA_LOSS_TH * aRate)
           , DOA.DOA_WEIGHT_INVEST_TH = nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) +(tplPositionAlloy.DOA_WEIGHT_INVEST_TH * aRate)
           , DOA.DOA_WEIGHT_INVEST = nvl(DOA.DOA_WEIGHT_INVEST, 0) +(tplPositionAlloy.DOA_WEIGHT_INVEST * aRate)
           , DOA.A_DATEMOD = sysdate
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
    end if;

    close crPositionAlloy;
  end UpdatePositionMatBaseMatType;

  /**
  * Description
  *   Suppression des pesées et matières liés à la position en cours d'effacement.
  *   Voir graphe Suppression position figurant dans l'analyse Facturation des matières
  *   précieuses.
  */
  procedure DeleteAllPositionMat(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
  is
  begin
    DeleteFalWeigh(aPositionID);
    DeletePositionAlloy(aPositionID);
    ----
    -- Mise à jour de l'indicateur de re-calcul des Matières pied
    --
    UpdateDocumentFlag(aPositionID);
  end DeleteAllPositionMat;

  /**
  * Description
  *    Processus Mise à jour pesé Matière Position de type Matière de base
  */
  procedure UpdatePositionMatWeighBaseMat(
    aPositionAlloyID    DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aSrcPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aRate               GCO_ALLOY_COMPONENT.GAC_RATE%type
  , aWeight             DOC_POSITION_ALLOY.DOA_WEIGHT%type default null
  , aWeightMat          DOC_POSITION_ALLOY.DOA_WEIGHT_MAT%type default null
  , aWeightDelivery     DOC_POSITION_ALLOY.DOA_WEIGHT_DELIVERY%type default null
  )
  is
    cursor crPositionAlloy(cSrcPositionAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , DOA.DOC_DOCUMENT_ID
           , DMT.DMT_NUMBER
           , GAL.GAL_ALLOY_REF
        from DOC_POSITION_ALLOY DOA
           , DOC_DOCUMENT DMT
           , GCO_ALLOY GAL
       where DOA.DOC_POSITION_ALLOY_ID = cSrcPositionAlloyID
         and DMT.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID
         and GAL.GCO_ALLOY_ID = DOA.GCO_ALLOY_ID;

    tplPositionAlloy crPositionAlloy%rowtype;
  begin
    open crPositionAlloy(aSrcPositionAlloyID);

    fetch crPositionAlloy
     into tplPositionAlloy;

    if crPositionAlloy%found then
      -- Inscription de l'événement dans l'historique des modifications
      -- DOC_FUNCTIONS.CreateHistoryInformation(tplPositionAlloy.DOC_DOCUMENT_ID
      --                                      , null
      --                                      , tplPositionAlloy.DMT_NUMBER
      --                                      , 'PL/SQL'
      --                                      , 'UpdatePositionMatWeighBaseMat'
      --                                      , 'Position d''alliage   : ' ||
      --                                        aSrcPositionAlloyID ||
      --                                        chr(13) ||
      --                                        'Alliage               : ' ||
      --                                        tplPositionAlloy.GAL_ALLOY_REF ||
      --                                        chr(13) ||
      --                                        '---' ||
      --                                        chr(13) ||
      --                                        'Position matière      : ' ||
      --                                        aPositionAlloyID ||
      --                                        chr(13) ||
      --                                        'Poids alliage         : ' ||
      --                                        tplPositionAlloy.DOA_WEIGHT ||
      --                                        chr(13) ||
      --                                        'Poids alliage matière : ' ||
      --                                        tplPositionAlloy.DOA_WEIGHT_MAT ||
      --                                        chr(13) ||
      --                                        'Poids alliage livré   : ' ||
      --                                        tplPositionAlloy.DOA_WEIGHT_DELIVERY ||
      --                                        chr(13) ||
      --                                        'Taux                  : ' ||
      --                                        aRate
      --                                      , null
      --                                      , null
      --                                       );
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_WEIGHT = nvl(DOA.DOA_WEIGHT, 0) +(nvl(aWeight, tplPositionAlloy.DOA_WEIGHT) * aRate)
           , DOA.DOA_WEIGHT_MAT = nvl(DOA.DOA_WEIGHT_MAT, 0) +(nvl(aWeightMat, tplPositionAlloy.DOA_WEIGHT_MAT) * aRate)
           , DOA.DOA_WEIGHT_DELIVERY = nvl(DOA.DOA_WEIGHT_DELIVERY, 0) +(nvl(aWeightDelivery, tplPositionAlloy.DOA_WEIGHT_DELIVERY) * aRate)
           , DOA.DOA_WEIGHT_DIF =
               decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0)
                    , 0, 0
                    , (DOA.DOA_WEIGHT_DELIVERY_TH -(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) +(nvl(aWeightDelivery, tplPositionAlloy.DOA_WEIGHT_DELIVERY) * aRate) ) ) *
                      100 /
                      DOA.DOA_WEIGHT_DELIVERY_TH
                     )
           , DOA.A_DATEMOD = sysdate
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
    end if;

    close crPositionAlloy;
  end UpdatePositionMatWeighBaseMat;

  /**
  * Description
  *    Graphe Validation Pesée
  */
  procedure ValidateWeighing(
    aPositionID    DOC_POSITION.DOC_POSITION_ID%type
  , aWeighID       FAL_WEIGH.FAL_WEIGH_ID%type
  , aWeight        FAL_WEIGH.FWE_WEIGHT%type
  , aWeightMat     FAL_WEIGH.FWE_WEIGHT_MAT%type
  , aInPositionID  FAL_WEIGH.FAL_POSITION1_ID%type
  , aOutPositionID FAL_WEIGH.FAL_POSITION2_ID%type
  , aAlloyID       GCO_ALLOY.GCO_ALLOY_ID%type
  )
  is
    cursor crSrcPositionAlloy(cPositionID number, cAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(MOK.C_MOVEMENT_SORT, 'UNKNOWN') C_MOVEMENT_SORT
        from DOC_POSITION_ALLOY DOA
           , DOC_POSITION POS
           , STM_MOVEMENT_KIND MOK
       where DOA.DOC_POSITION_ID = cPositionID
         and DOA.GCO_ALLOY_ID = cAlloyID
         and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
         and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID;

    tplSrcPositionAlloy crSrcPositionAlloy%rowtype;

    cursor crAlloyComponents(cPositionID number, cAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
           , DOC_POSITION_ALLOY DOA
       where GAC.GCO_ALLOY_ID = cAlloyID
         and DOA.DIC_BASIS_MATERIAL_ID = GAC.DIC_BASIS_MATERIAL_ID
         and DOA.DOC_POSITION_ID = cPositionID;

    bStop               boolean;
  begin
    open crSrcPositionAlloy(aPositionID, aAlloyID);

    begin
      fetch crSrcPositionAlloy
       into tplSrcPositionAlloy;

      bStop  := not crSrcPositionAlloy%found;

      if not bStop then
        -- Vérifie que la pesée courante correspond au genre de mouvement de la position. En effet, un mouvement d'entrée
        -- sur la position doit correspondre à une pesée entrée et vice-versa.
        -- AGE20130123 (DEVPRD-12245) : en sous-traitance (opératoire ou achat), aucun mouvement n'est créé sur les CAST, CST, BRAST, BRST.
        -- Mais il faut tout de même mettre à jour les positions matières avec les pesées effectuées.
        if    (    tplSrcPositionAlloy.C_MOVEMENT_SORT = 'ENT'
               and aInPositionID is not null)
           or (    tplSrcPositionAlloy.C_MOVEMENT_SORT = 'SOR'
               and aOutPositionID is not null)
           or (     (DOC_LIB_SUBCONTRACT.IsPositionSubcontract(iPositionID => aPositionID) = 1)
               and (tplSrcPositionAlloy.C_MOVEMENT_SORT = 'UNKNOWN')
               and aInPositionID is not null
              ) then   -- STO ou STA
          ----
          -- Mise à jour création pesé Poids Position
          --
          UpdatePositionMatWeigh(tplSrcPositionAlloy.DOC_POSITION_ALLOY_ID, aWeighID, aWeight, aWeightMat);

          for tplAlloyComponents in crAlloyComponents(aPositionID, aAlloyID) loop
            ----
            -- Mise à jour pesé Matière Position de type Matière de base - Retrait des anciennes valeurs.
            --
            UpdatePositionMatWeighBaseMat(tplAlloyComponents.DOC_POSITION_ALLOY_ID
                                        , tplSrcPositionAlloy.DOC_POSITION_ALLOY_ID
                                        , tplAlloyComponents.GAC_RATE
                                        , tplSrcPositionAlloy.DOA_WEIGHT * -1
                                        , tplSrcPositionAlloy.DOA_WEIGHT_MAT * -1
                                        , tplSrcPositionAlloy.DOA_WEIGHT_DELIVERY * -1
                                         );
            ----
            -- Mise à jour pesé Matière Position de type Matière de base - Ajout des nouvelles valeurs.
            --
            UpdatePositionMatWeighBaseMat(tplAlloyComponents.DOC_POSITION_ALLOY_ID, tplSrcPositionAlloy.DOC_POSITION_ALLOY_ID, tplAlloyComponents.GAC_RATE);
          end loop;

          ----
          -- Mise à jour de l'indicateur de re-calcul des Matières pied
          --
          UpdateDocumentFlag(aPositionID);
        end if;
      end if;

      close crSrcPositionAlloy;
    exception
      when others then
        close crSrcPositionAlloy;

        raise;
    end;
  end ValidateWeighing;

  /**
  * Description
  *    Graphe Suppression Pesée
  */
  procedure DeleteWeighing(
    aPositionID    DOC_POSITION.DOC_POSITION_ID%type
  , aWeighID       FAL_WEIGH.FAL_WEIGH_ID%type
  , aInPositionID  FAL_WEIGH.FAL_POSITION1_ID%type
  , aOutPositionID FAL_WEIGH.FAL_POSITION2_ID%type
  , aAlloyID       GCO_ALLOY.GCO_ALLOY_ID%type
  )
  is
    cursor crAlloyComponents(cPositionID number, cAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
           , DOC_POSITION_ALLOY DOA
       where GAC.GCO_ALLOY_ID = cAlloyID
         and DOA.DIC_BASIS_MATERIAL_ID = GAC.DIC_BASIS_MATERIAL_ID
         and DOA.DOC_POSITION_ID = cPositionID;

    bStop              boolean;
    doaPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
    cMovementSort      STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
  begin
    bStop  := false;

    begin
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(MOK.C_MOVEMENT_SORT, 'UNKNOWN')
        into doaPositionAlloyID
           , cMovementSort
        from DOC_POSITION_ALLOY DOA
           , DOC_POSITION POS
           , STM_MOVEMENT_KIND MOK
       where DOA.DOC_POSITION_ID = aPositionID
         and DOA.GCO_ALLOY_ID = aAlloyID
         and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
         and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      -- Vérifie que la pesée courante correspond au genre de mouvement de la position. En effet, un mouvement d'entrée
      -- sur la position doit correspondre à une pesée entrée et vice-versa.
      if    (    cMovementSort = 'ENT'
             and aInPositionID is not null)
         or (    cMovementSort = 'SOR'
             and aOutPositionID is not null) then
        ----
        -- Mise à jour suppression pesé Poids Position
        --
        UpdatePositionMatDeleteWeigh(doaPositionAlloyID);

        for tplAlloyComponents in crAlloyComponents(aPositionID, aAlloyID) loop
          ----
          -- Mise à jour Suppression pesé Matière Position de type Matière de base
          --
          UpdDelPositionMatWeighBaseMat(tplAlloyComponents.DOC_POSITION_ALLOY_ID, doaPositionAlloyID, tplAlloyComponents.GAC_RATE);
        end loop;

        ----
        -- Mise à jour de l'indicateur de re-calcul des Matières pied
        --
        UpdateDocumentFlag(aPositionID);
      end if;
    end if;
  end DeleteWeighing;

  /**
  * Description
  *    Processus Mise à jour suppression pesé Poids Position
  */
  procedure UpdatePositionMatDeleteWeigh(aPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type)
  is
  begin
    update DOC_POSITION_ALLOY DOA
       set DOA.DOA_WEIGHT = 0
         , DOA.DOA_WEIGHT_MAT = 0
         , DOA.DOA_WEIGHT_DELIVERY = 0
         , DOA.DOA_WEIGHT_DIF = decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0), 0, 0, DOA.DOA_WEIGHT_DELIVERY_TH * 100 / DOA.DOA_WEIGHT_DELIVERY_TH)
         , DOA.A_DATEMOD = sysdate
         , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
  end UpdatePositionMatDeleteWeigh;

  /**
  * Description
  *    Processus Mise à jour Suppression pesé Matière Position de type Matière de base
  */
  procedure UpdDelPositionMatWeighBaseMat(
    aPositionAlloyID      DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aAlloyPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aRate                 GCO_ALLOY_COMPONENT.GAC_RATE%type
  )
  is
    cursor crAlloyPositionAlloy(cPositionAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
        from DOC_POSITION_ALLOY DOA
       where DOA.DOC_POSITION_ALLOY_ID = cPositionAlloyID;

    tplAlloyPositionAlloy crAlloyPositionAlloy%rowtype;
  begin
    open crAlloyPositionAlloy(aAlloyPositionAlloyID);

    fetch crAlloyPositionAlloy
     into tplAlloyPositionAlloy;

    if crAlloyPositionAlloy%found then
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_WEIGHT = nvl(DOA.DOA_WEIGHT, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT * aRate)
           , DOA.DOA_WEIGHT_MAT = nvl(DOA.DOA_WEIGHT_MAT, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_MAT * aRate)
           , DOA.DOA_WEIGHT_DELIVERY = nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY * aRate)
           , DOA.DOA_WEIGHT_DIF =
               decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0)
                    , 0, 0
                    , (DOA.DOA_WEIGHT_DELIVERY_TH -(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY * aRate) ) ) *
                      100 /
                      DOA.DOA_WEIGHT_DELIVERY_TH
                     )
           , DOA.A_DATEMOD = sysdate
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
    end if;

    close crAlloyPositionAlloy;
  end UpdDelPositionMatWeighBaseMat;

  /**
  * Description
  *    Mise à jour des matières de base de l'alliage courant en fonction des modifications apportées sur la matière
  *    position. Voir graphe Modification Matières Positions
  */
  procedure UpdateChangeBaseMatType(
    aPositionID       DOC_POSITION.DOC_POSITION_ID%type
  , aAlloyID          GCO_ALLOY.GCO_ALLOY_ID%type
  , aOldWeighDelivery DOC_POSITION_ALLOY.DOA_WEIGHT_DELIVERY%type
  , aNewWeighDelivery DOC_POSITION_ALLOY.DOA_WEIGHT_DELIVERY%type
  , aOldWeighInvest   DOC_POSITION_ALLOY.DOA_WEIGHT_INVEST%type
  , aNewWeighInvest   DOC_POSITION_ALLOY.DOA_WEIGHT_INVEST%type
  , aOldLoss          DOC_POSITION_ALLOY.DOA_LOSS%type
  , aNewLoss          DOC_POSITION_ALLOY.DOA_LOSS%type
  )
  is
    cursor crAlloyComponents(cAlloyID number)
    is
      select GAC.DIC_BASIS_MATERIAL_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
       where GAC.GCO_ALLOY_ID = cAlloyID;

    doaBaseMatPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
  begin
    for tplAlloyComponents in crAlloyComponents(aAlloyID) loop
      -- Vérifie l'existance d'un matière de base similaire
      begin
        select DOA.DOC_POSITION_ALLOY_ID
          into doaBaseMatPositionAlloyID
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_POSITION_ID = aPositionID
           and DOA.DIC_BASIS_MATERIAL_ID = tplAlloyComponents.DIC_BASIS_MATERIAL_ID;
      exception
        when no_data_found then
          doaBaseMatPositionAlloyID  := null;
      end;

      --raise_application_error(-20001, aOldWeighDelivery || '/' || aNewWeighDelivery || '/' || doaBaseMatPositionAlloyID);
      if doaBaseMatPositionAlloyID is not null then
        ----
        -- Update Matière Position de type Matière de base
        --
        update DOC_POSITION_ALLOY DOA
           set DOA.DOA_WEIGHT_DELIVERY =
                             nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -
                             (aOldWeighDelivery * tplAlloyComponents.GAC_RATE) +
                             (aNewWeighDelivery * tplAlloyComponents.GAC_RATE)
             , DOA.DOA_LOSS = nvl(DOA.DOA_LOSS, 0) -(aOldLoss * tplAlloyComponents.GAC_RATE) +(aNewLoss * tplAlloyComponents.GAC_RATE)
             , DOA.DOA_WEIGHT_DIF =
                 decode(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0)
                      , 0, 0
                      , (DOA.DOA_WEIGHT_DELIVERY_TH -
                         (nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -(aOldWeighDelivery * tplAlloyComponents.GAC_RATE) +(aNewWeighDelivery * tplAlloyComponents.GAC_RATE)
                         )
                        ) *
                        100 /
                        DOA.DOA_WEIGHT_DELIVERY_TH
                       )
             , DOA.DOA_WEIGHT_INVEST =
                                   nvl(DOA.DOA_WEIGHT_INVEST, 0) -
                                   (aOldWeighInvest * tplAlloyComponents.GAC_RATE) +
                                   (aNewWeighInvest * tplAlloyComponents.GAC_RATE)
             , DOA.A_DATEMOD = sysdate
             , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOA.DOC_POSITION_ALLOY_ID = doaBaseMatPositionAlloyID;
      end if;
    end loop;

    ----
    -- Mise à jour de l'indicateur de re-calcul des Matières pied
    --
    UpdateDocumentFlag(aPositionID);
  end UpdateChangeBaseMatType;

  /**
  * Description
  *    Génération (création ou modification) des matières de base de l'alliage courant en fonction de la nouvelle
  *    position matière précieuse de type alliage créée. Voir graphes Génération Matières Position et
  *    Création Matières Positions.
  */
  procedure GeneratePositionMatBaseMatType(
    aPositionID      DOC_POSITION.DOC_POSITION_ID%type
  , aPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aAlloyID         GCO_ALLOY.GCO_ALLOY_ID%type
  )
  is
    cursor crAlloyComponents(cAlloyID number)
    is
      select GAC.DIC_BASIS_MATERIAL_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
       where GAC.GCO_ALLOY_ID = cAlloyID;

    doaBaseMatPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
  begin
    for tplAlloyComponents in crAlloyComponents(aAlloyID) loop
      -- Vérifie l'existance d'un matière de base similaire
      begin
        select DOA.DOC_POSITION_ALLOY_ID
          into doaBaseMatPositionAlloyID
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_POSITION_ID = aPositionID
           and DOA.DIC_BASIS_MATERIAL_ID = tplAlloyComponents.DIC_BASIS_MATERIAL_ID;
      exception
        when no_data_found then
          doaBaseMatPositionAlloyID  := null;
      end;

      if doaBaseMatPositionAlloyID is null then
        ----
        -- Création Matière Position de type Matière de base
        --
        CreatePositionMatBaseMatType(aPositionID
                                   , aPositionAlloyID
                                   , aAlloyID
                                   , tplAlloyComponents.DIC_BASIS_MATERIAL_ID
                                   , tplAlloyComponents.GAC_RATE
                                   , doaBaseMatPositionAlloyID
                                    );
      else
        --raise_application_error(-20001, doaBaseMatPositionAlloyID || '/' || tplAlloyComponents.DIC_BASIS_MATERIAL_ID || '/' || doaBaseMatPositionAlloyID);

        ----
        -- Mise à jour Matière Position de type Matière de base
        --
        UpdatePositionMatBaseMatType(doaBaseMatPositionAlloyID, aPositionAlloyID, tplAlloyComponents.GAC_RATE);
      end if;
    end loop;
  end GeneratePositionMatBaseMatType;

  /**
  * Description
  *    Mise à jour flag de re-calcul des matières sur pied. Voir graphes Génération Matières Positions,
  *    Création Matières Positions, Modification Matières Position, Suppression Matières Positions, Validation
  *    Pesée, Suppression Pesée, Modification Quantité de base Position et Suppression Position.
  */
  procedure UpdateDocumentFlag(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
  is
    bStop            boolean;
    dmtDocumentID    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    dmtCreateFootMat DOC_DOCUMENT.DMT_CREATE_FOOT_MAT%type;
  begin
    bStop  := false;

    begin
      select DMT.DOC_DOCUMENT_ID
           , DMT.DMT_CREATE_FOOT_MAT
        into dmtDocumentID
           , dmtCreateFootMat
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
       where POS.DOC_POSITION_ID = aPositionID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      -- Mise à jour de l'indicateur de re-calcul des Matières pied, uniquement
      -- si des matières ont déjà été créées sur le pied.
      if nvl(dmtCreateFootMat, 0) = 2 then
        UpdateDocumentFootMatFlags(aDocumentID => dmtDocumentID, aRecalcFootMat => 1);
      end if;
    end if;
  end UpdateDocumentFlag;

  /**
  * Description
  *    Graphe Suppression Matières Positions
  */
  procedure DeletePositionMatAlloyType(aAlloyPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type)
  is
    cursor crDeletingPositionAlloy(cPositionAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , DOA.DOC_POSITION_ID
           , DOA.GCO_ALLOY_ID
        from DOC_POSITION_ALLOY DOA
       where DOA.DOC_POSITION_ALLOY_ID = cPositionAlloyID;

    tplDeletingPositionAlloy  crDeletingPositionAlloy%rowtype;

    cursor crAlloyComponents(cAlloyID number)
    is
      select GAC.DIC_BASIS_MATERIAL_ID
           , GAC.GAC_RATE / 100 GAC_RATE
        from GCO_ALLOY_COMPONENT GAC
       where GAC.GCO_ALLOY_ID = cAlloyID;

    doaBaseMatPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
  begin
    open crDeletingPositionAlloy(aAlloyPositionAlloyID);

    fetch crDeletingPositionAlloy
     into tplDeletingPositionAlloy;

    if crDeletingPositionAlloy%found then
      ----
      -- Effacement de l'éventuelle pesée associée à la matière position à effacer
      --
      delete from FAL_WEIGH
            where DOC_POSITION_ID = tplDeletingPositionAlloy.DOC_POSITION_ID
              and GCO_ALLOY_ID = tplDeletingPositionAlloy.GCO_ALLOY_ID;

      for tplAlloyComponents in crAlloyComponents(tplDeletingPositionAlloy.GCO_ALLOY_ID) loop
        ----
        -- Recherche la matière de base position correspondant à la matière de base courant de l'alliage.
        --
        begin
          select DOA.DOC_POSITION_ALLOY_ID
            into doaBaseMatPositionAlloyID
            from DOC_POSITION_ALLOY DOA
           where DOA.DOC_POSITION_ID = tplDeletingPositionAlloy.DOC_POSITION_ID
             and DOA.DIC_BASIS_MATERIAL_ID = tplAlloyComponents.DIC_BASIS_MATERIAL_ID;
        exception
          when no_data_found then
            doaBaseMatPositionAlloyID  := null;
        end;

        if doaBaseMatPositionAlloyID is not null then
          ----
          -- Processus Mise à jour Suppression Matière Position de type Matière de base
          --
          UpdDelPositionMatBaseMatType(doaBaseMatPositionAlloyID, tplDeletingPositionAlloy.DOC_POSITION_ALLOY_ID, tplAlloyComponents.GAC_RATE);

          begin
            select DOA.DOC_POSITION_ALLOY_ID
              into doaBaseMatPositionAlloyID
              from DOC_POSITION_ALLOY DOA
             where DOA.DOC_POSITION_ALLOY_ID = doaBaseMatPositionAlloyID
               and nvl(DOA.DOA_WEIGHT_DELIVERY, 0) = 0;
          exception
            when no_data_found then
              doaBaseMatPositionAlloyID  := null;
          end;

          if doaBaseMatPositionAlloyID is not null then
            ----
            -- Effacement de matière position de type matière de base car elle n'est plus utilisé par un alliage
            --
            DeletePositionAlloy(doaBaseMatPositionAlloyID);
          end if;
        end if;
      end loop;

      ----
      -- Mise à jour de l'indicateur de re-calcul des Matières pied
      --
      UpdateDocumentFlag(tplDeletingPositionAlloy.DOC_POSITION_ID);
    end if;

    close crDeletingPositionAlloy;
  end DeletePositionMatAlloyType;

  /**
  * Description
  *    Processus Mise à jour Suppression Matière Position de type Matière de base
  */
  procedure UpdDelPositionMatBaseMatType(
    aPositionAlloyID      DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aAlloyPositionAlloyID DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type
  , aRate                 GCO_ALLOY_COMPONENT.GAC_RATE%type
  )
  is
    cursor crAlloyPositionAlloy(cPositionAlloyID number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT, 0) DOA_WEIGHT
           , nvl(DOA.DOA_WEIGHT_MAT, 0) DOA_WEIGHT_MAT
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) DOA_WEIGHT_DELIVERY_TH
           , nvl(DOA.DOA_WEIGHT_INVEST, 0) DOA_WEIGHT_INVEST
           , nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) DOA_WEIGHT_INVEST_TH
           , nvl(DOA.DOA_LOSS_TH, 0) DOA_LOSS_TH
        from DOC_POSITION_ALLOY DOA
       where DOA.DOC_POSITION_ALLOY_ID = cPositionAlloyID;

    tplAlloyPositionAlloy crAlloyPositionAlloy%rowtype;
  begin
    open crAlloyPositionAlloy(aAlloyPositionAlloyID);

    fetch crAlloyPositionAlloy
     into tplAlloyPositionAlloy;

    if crAlloyPositionAlloy%found then
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_WEIGHT = greatest(nvl(DOA.DOA_WEIGHT, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT * aRate), 0)
           , DOA.DOA_WEIGHT_MAT = greatest(nvl(DOA.DOA_WEIGHT_MAT, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_MAT * aRate), 0)
           , DOA.DOA_WEIGHT_DELIVERY_TH = nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate)
           , DOA.DOA_WEIGHT_DELIVERY = nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY * aRate)
           , DOA.DOA_WEIGHT_DIF =
               decode( (nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate) )
                    , 0, 0
                    , ( (nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate) ) -
                       (nvl(DOA.DOA_WEIGHT_DELIVERY, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY * aRate)
                       )
                      ) *
                      100 /
                      (nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_DELIVERY_TH * aRate) )
                     )
           , DOA.DOA_LOSS_TH = nvl(DOA.DOA_LOSS_TH, 0) -(tplAlloyPositionAlloy.DOA_LOSS_TH * aRate)
           , DOA.DOA_WEIGHT_INVEST_TH = nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_INVEST_TH * aRate)
           , DOA.DOA_WEIGHT_INVEST = nvl(DOA.DOA_WEIGHT_INVEST, 0) -(tplAlloyPositionAlloy.DOA_WEIGHT_INVEST * aRate)
           , DOA.A_DATEMOD = sysdate
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOA.DOC_POSITION_ALLOY_ID = aPositionAlloyID;
    end if;

    close crAlloyPositionAlloy;
  end UpdDelPositionMatBaseMatType;

  /**
  * procedure generateAlloyCharge
  * Description
  *   Génération des taxes "matières précieuses" pour les alliages
  * @created fp 24.03.2004
  */
  procedure generateAlloyCharge(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aChargeName in PTC_CHARGE.CRG_NAME%type, aGenerated out number)
  is
    cursor crPositionAlloy(
      cDocumentId      DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , cChargeName      PTC_CHARGE.CRG_NAME%type
    , cAdvMaterialMode PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type
    )
    is
      select DOA.DOC_POSITION_ID
           , DOA.GCO_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(DFA.DFA_RATE, 0) DFA_RATE
           , DFA.DFA_BASE_COST
           , GAL.GAL_ALLOY_REF
           , GAU.C_ADMIN_DOMAIN
           , CRG.CRG_NAME
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.PC_LANG_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DOC_GAUGE_ID
           , POS.DOC_RECORD_ID
           , POS.PAC_THIRD_ID
           , POS.PAC_THIRD_ACI_ID
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , substr(nvl( (select CDE.CHD_DESCR
                            from PTC_CHARGE_DESCRIPTION CDE
                           where CDE.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
                             and CDE.PC_LANG_ID = DMT.PC_LANG_ID), CRG.CRG_NAME) ||
                    ' - ' ||
                    GAL.GAL_ALLOY_REF ||
                    decode(DFA.DFA_RATE_DATE, null, '', ' - ' || to_char(DFA.DFA_RATE_DATE, 'DD.MM.YYYY') )
                  , 1
                  , 255
                   ) CRG_DESCRIPTION
           , nvl(decode(cAdvMaterialMode
                      , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                      , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                      , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                       ) *
                 (DFA.DFA_RATE / nvl(DFA.DFA_BASE_COST, 1) )
               , 0
                ) PCH_AMOUNT
           , ACS_FUNCTION.ConvertAmountForView(nvl(decode(cAdvMaterialMode
                                                        , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                                                        , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                                                        , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                                                         ) *
                                                   (nvl(DFA.DFA_RATE, 0) / nvl(DFA.DFA_BASE_COST, 1) )
                                                 , 0
                                                  )
                                             , DMT.ACS_FINANCIAL_CURRENCY_ID
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , DMT.DMT_DATE_DOCUMENT
                                             , DMT.DMT_RATE_OF_EXCHANGE
                                             , DMT.DMT_BASE_PRICE
                                             , 0
                                              ) CRG_FIXED_AMOUNT_B
           , decode(cAdvMaterialMode
                  , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                  , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                  , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                   ) DOA_WEIGHT
           , CRG.CRG_IN_SERIE_CALCULATION
           , 0 CRG_EXCLUSIVE
           , CRG.CRG_PRCS_USE
           , CRG.PTC_CHARGE_ID
           , CRG.ACS_FINANCIAL_ACCOUNT_ID
           , CRG.ACS_DIVISION_ACCOUNT_ID
           , CRG.ACS_CPN_ACCOUNT_ID
           , CRG.ACS_CDA_ACCOUNT_ID
           , CRG.ACS_PF_ACCOUNT_ID
           , CRG.ACS_PJ_ACCOUNT_ID
           , CRG.ACS_FINANCIAL_ACCOUNT_ID POS_ACS_FINANCIAL_ACCOUNT_ID
           , CRG.ACS_DIVISION_ACCOUNT_ID POS_ACS_DIVISION_ACCOUNT_ID
           , CRG.ACS_CPN_ACCOUNT_ID POS_ACS_CPN_ACCOUNT_ID
           , CRG.ACS_CDA_ACCOUNT_ID POS_ACS_CDA_ACCOUNT_ID
           , CRG.ACS_PF_ACCOUNT_ID POS_ACS_PF_ACCOUNT_ID
           , CRG.ACS_PJ_ACCOUNT_ID POS_ACS_PJ_ACCOUNT_ID
           , DFA.STM_STOCK_ID
           , DFA.DOC_FOOT_ID
           , GAL.GCO_GOOD_ID
        from DOC_POSITION_ALLOY DOA
           , DOC_FOOT_ALLOY DFA
           , DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , GCO_ALLOY GAL
           , PTC_CHARGE CRG
       where DOA.DOC_DOCUMENT_ID = cDocumentId
         and DFA.DOC_FOOT_ID = DOA.DOC_DOCUMENT_ID
         and DOA.GCO_ALLOY_ID = DFA.GCO_ALLOY_ID
         and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and GAL.GCO_ALLOY_ID = DOA.GCO_ALLOY_ID
         and DFA.DIC_COST_FOOT_ID is null
         and CRG.CRG_NAME = cChargeName
         and CRG.C_CHARGE_TYPE = decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
         and DMT.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    accountInfo                  ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    cAdvMaterialMode             PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type;
    bStop                        boolean;
    canGenerateDiscount          boolean;
    metalAccount                 PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    thaManaged                   PAC_THIRD_ALLOY.THA_MANAGED%type;
    docMetalAccount              PCS.PC_CBASE.CBACNAME%type;
    cThirdMaterialRelationType   PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cThirdMaterialRelationTypeMA PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    posChargeAmount              DOC_POSITION.POS_CHARGE_AMOUNT%type;
    posDiscountAmount            DOC_POSITION.POS_DISCOUNT_AMOUNT%type;
    lvChargeList                 varchar2(32000);
  begin
    bStop  := false;

    begin
      select decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.C_ADV_MATERIAL_MODE
                  , cAdminDomainSale, CUS.C_ADV_MATERIAL_MODE
                  , cAdminDomainSubContract, SUP.C_ADV_MATERIAL_MODE
                  , nvl(CUS.C_ADV_MATERIAL_MODE, SUP.C_ADV_MATERIAL_MODE)
                   )
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , cAdminDomainSale, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                  , cAdminDomainSubContract, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                   ) C_THIRD_MATERIAL_RELATION_TYPE
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.CRE_METAL_ACCOUNT
                  , cAdminDomainSale, CUS.CUS_METAL_ACCOUNT
                  , cAdminDomainSubContract, SUP.CRE_METAL_ACCOUNT
                  , nvl(CUS.CUS_METAL_ACCOUNT, SUP.CRE_METAL_ACCOUNT)
                   ) METAL_ACCOUNT
        into cAdvMaterialMode
           , cThirdMaterialRelationType
           , metalAccount
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where DMT.DOC_DOCUMENT_ID = aDocumentId
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      docMetalAccount  := PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT');

      -- curseur sur les positions alliages
      for tplPositionAlloy in crPositionAlloy(aDocumentId, aChargeName, cAdvMaterialMode) loop
        declare
          -- déclaré dans la boucle FOR pour éviter de devoir réinitialiser chaque champ du record l'un après l'autre à chaque passage
          recPositionCharge DOC_POSITION_CHARGE%rowtype;
        begin
          -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
          thaManaged  := 0;

          begin
            if    (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainPurchase)
               or (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSubContract) then
              select nvl(THA.THA_MANAGED, 0)
                into thaManaged
                from PAC_THIRD_ALLOY THA
               where THA.PAC_SUPPLIER_PARTNER_ID = tplPositionAlloy.PAC_THIRD_ID
                 and THA.GCO_ALLOY_ID = tplPositionAlloy.GCO_ALLOY_ID;
            elsif tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSale then
              select nvl(THA.THA_MANAGED, 0)
                into thaManaged
                from PAC_THIRD_ALLOY THA
               where THA.PAC_CUSTOM_PARTNER_ID = tplPositionAlloy.PAC_THIRD_ID
                 and THA.GCO_ALLOY_ID = tplPositionAlloy.GCO_ALLOY_ID;
            else
              thaManaged  := 1;
            end if;
          exception
            when no_data_found then
              -- Si aucune matière/alliage n'est trouvée pour le tiers, on autorise par défaut la création de la remise
              thaManaged  := 1;
          end;

          -- Le code de gestion de la matière/alliage courante n'a pas d'influence lorsque la gestion des comptes poids
          -- est activée.
          if     (docMetalAccount = '1')
             and (metalAccount = 1) then
            canGenerateDiscount  := true;
          else
            canGenerateDiscount  :=(thaManaged = 1);
          end if;

          if canGenerateDiscount then
            -- Recherche le type de relation avec tiers présent sur l'éventuel compte poids lié au tiers.
            cThirdMaterialRelationTypeMA  := cThirdMaterialRelationType;

            if     (docMetalAccount = '1')
               and (metalAccount = 1) then
              if tplPositionAlloy.STM_STOCK_ID is not null then
                begin
                  select nvl(STO.C_THIRD_MATERIAL_RELATION_TYPE, cThirdMaterialRelationTypeMA)
                    into cThirdMaterialRelationTypeMA
                    from STM_STOCK STO
                   where STO.STM_STOCK_ID = tplPositionAlloy.STM_STOCK_ID;
                exception
                  when no_data_found then
                    null;
                end;
              else
                -- Le compte poids n'est pas spécifié sur la matière pied. C'est donc type de relation qui se trouve sur le
                -- compte poids par défaut qui est utilisé.
                begin
                  select nvl(STO.C_THIRD_MATERIAL_RELATION_TYPE, cThirdMaterialRelationTypeMA)
                    into cThirdMaterialRelationTypeMA
                    from STM_STOCK STO
                   where STO.STO_DEFAULT_METAL_ACCOUNT = 1;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;

            -- Le type de relation tiers est différent de prix complet.
            if (cThirdMaterialRelationTypeMA <> '5') then
              -- Si gestion des comptes financiers ou analytiques
              if    (tplPositionAlloy.GAS_FINANCIAL = 1)
                 or (tplPositionAlloy.GAS_ANALYTICAL = 1) then
                -- Utilise les comptes de la taxe
                recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID  := tplPositionAlloy.ACS_FINANCIAL_ACCOUNT_ID;
                recPositionCharge.ACS_DIVISION_ACCOUNT_ID   := tplPositionAlloy.ACS_DIVISION_ACCOUNT_ID;
                recPositionCharge.ACS_CPN_ACCOUNT_ID        := tplPositionAlloy.ACS_CPN_ACCOUNT_ID;
                recPositionCharge.ACS_CDA_ACCOUNT_ID        := tplPositionAlloy.ACS_CDA_ACCOUNT_ID;
                recPositionCharge.ACS_PF_ACCOUNT_ID         := tplPositionAlloy.ACS_PF_ACCOUNT_ID;
                recPositionCharge.ACS_PJ_ACCOUNT_ID         := tplPositionAlloy.ACS_PJ_ACCOUNT_ID;
                accountInfo.DEF_HRM_PERSON                  := null;
                accountInfo.FAM_FIXED_ASSETS_ID             := null;
                accountInfo.C_FAM_TRANSACTION_TYP           := null;
                accountInfo.DEF_DIC_IMP_FREE1               := null;
                accountInfo.DEF_DIC_IMP_FREE2               := null;
                accountInfo.DEF_DIC_IMP_FREE3               := null;
                accountInfo.DEF_DIC_IMP_FREE4               := null;
                accountInfo.DEF_DIC_IMP_FREE5               := null;
                accountInfo.DEF_TEXT1                       := null;
                accountInfo.DEF_TEXT2                       := null;
                accountInfo.DEF_TEXT3                       := null;
                accountInfo.DEF_TEXT4                       := null;
                accountInfo.DEF_TEXT5                       := null;
                accountInfo.DEF_NUMBER1                     := null;
                accountInfo.DEF_NUMBER2                     := null;
                accountInfo.DEF_NUMBER3                     := null;
                accountInfo.DEF_NUMBER4                     := null;
                accountInfo.DEF_NUMBER5                     := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplPositionAlloy.PTC_CHARGE_ID
                                                         , '30'
                                                         , tplPositionAlloy.C_ADMIN_DOMAIN
                                                         , tplPositionAlloy.DMT_DATE_DOCUMENT
                                                         , tplPositionAlloy.DOC_GAUGE_ID
                                                         , tplPositionAlloy.DOC_DOCUMENT_ID
                                                         , tplPositionAlloy.DOC_POSITION_ID
                                                         , tplPositionAlloy.DOC_RECORD_ID
                                                         , tplPositionAlloy.PAC_THIRD_ACI_ID
                                                         , tplPositionAlloy.POS_ACS_FINANCIAL_ACCOUNT_ID
                                                         , tplPositionAlloy.POS_ACS_DIVISION_ACCOUNT_ID
                                                         , tplPositionAlloy.POS_ACS_CPN_ACCOUNT_ID
                                                         , tplPositionAlloy.POS_ACS_CDA_ACCOUNT_ID
                                                         , tplPositionAlloy.POS_ACS_PF_ACCOUNT_ID
                                                         , tplPositionAlloy.POS_ACS_PJ_ACCOUNT_ID
                                                         , recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID
                                                         , recPositionCharge.ACS_DIVISION_ACCOUNT_ID
                                                         , recPositionCharge.ACS_CPN_ACCOUNT_ID
                                                         , recPositionCharge.ACS_CDA_ACCOUNT_ID
                                                         , recPositionCharge.ACS_PF_ACCOUNT_ID
                                                         , recPositionCharge.ACS_PJ_ACCOUNT_ID
                                                         , accountInfo
                                                          );

                if (tplPositionAlloy.GAS_ANALYTICAL = 0) then
                  recPositionCharge.ACS_CPN_ACCOUNT_ID  := null;
                  recPositionCharge.ACS_CDA_ACCOUNT_ID  := null;
                  recPositionCharge.ACS_PJ_ACCOUNT_ID   := null;
                  recPositionCharge.ACS_PF_ACCOUNT_ID   := null;
                end if;
              end if;

              recPositionCharge.DOC_POSITION_ID            := tplPositionAlloy.DOC_POSITION_ID;
              recPositionCharge.C_CHARGE_ORIGIN            := 'PM';
              recPositionCharge.C_FINANCIAL_CHARGE         := '03';
              recPositionCharge.PCH_NAME                   := tplPositionAlloy.CRG_NAME;
              recPositionCharge.PCH_DESCRIPTION            := tplPositionAlloy.CRG_DESCRIPTION;
              recPositionCharge.PCH_AMOUNT                 := tplPositionAlloy.PCH_AMOUNT;
              recPositionCharge.PCH_FIXED_AMOUNT_B         := tplPositionAlloy.CRG_FIXED_AMOUNT_B;
              recPositionCharge.C_CALCULATION_MODE         := '0';
              recPositionCharge.PCH_IN_SERIES_CALCULATION  := tplPositionAlloy.CRG_IN_SERIE_CALCULATION;
              recPositionCharge.PCH_EXCLUSIVE              := tplPositionAlloy.CRG_EXCLUSIVE;
              recPositionCharge.PCH_PRCS_USE               := tplPositionAlloy.CRG_PRCS_USE;
              recPositionCharge.PCH_MODIFY                 := 0;
              recPositionCharge.PTC_CHARGE_ID              := tplPositionAlloy.PTC_CHARGE_ID;
              recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID   := recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID;
              recPositionCharge.ACS_DIVISION_ACCOUNT_ID    := recPositionCharge.ACS_DIVISION_ACCOUNT_ID;
              recPositionCharge.ACS_CPN_ACCOUNT_ID         := recPositionCharge.ACS_CPN_ACCOUNT_ID;
              recPositionCharge.ACS_CDA_ACCOUNT_ID         := recPositionCharge.ACS_CDA_ACCOUNT_ID;
              recPositionCharge.ACS_PF_ACCOUNT_ID          := recPositionCharge.ACS_PF_ACCOUNT_ID;
              recPositionCharge.ACS_PJ_ACCOUNT_ID          := recPositionCharge.ACS_PJ_ACCOUNT_ID;
              recPositionCharge.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(accountInfo.DEF_HRM_PERSON);
              recPositionCharge.FAM_FIXED_ASSETS_ID        := accountInfo.FAM_FIXED_ASSETS_ID;
              recPositionCharge.C_FAM_TRANSACTION_TYP      := accountInfo.C_FAM_TRANSACTION_TYP;
              recPositionCharge.PCH_IMP_TEXT_1             := accountInfo.DEF_TEXT1;
              recPositionCharge.PCH_IMP_TEXT_2             := accountInfo.DEF_TEXT2;
              recPositionCharge.PCH_IMP_TEXT_3             := accountInfo.DEF_TEXT3;
              recPositionCharge.PCH_IMP_TEXT_4             := accountInfo.DEF_TEXT4;
              recPositionCharge.PCH_IMP_TEXT_5             := accountInfo.DEF_TEXT5;
              recPositionCharge.PCH_IMP_NUMBER_1           := to_number(accountInfo.DEF_NUMBER1);
              recPositionCharge.PCH_IMP_NUMBER_2           := to_number(accountInfo.DEF_NUMBER2);
              recPositionCharge.PCH_IMP_NUMBER_3           := to_number(accountInfo.DEF_NUMBER3);
              recPositionCharge.PCH_IMP_NUMBER_4           := to_number(accountInfo.DEF_NUMBER4);
              recPositionCharge.PCH_IMP_NUMBER_5           := to_number(accountInfo.DEF_NUMBER5);
              recPositionCharge.DIC_IMP_FREE1_ID           := accountInfo.DEF_DIC_IMP_FREE1;
              recPositionCharge.DIC_IMP_FREE2_ID           := accountInfo.DEF_DIC_IMP_FREE2;
              recPositionCharge.DIC_IMP_FREE3_ID           := accountInfo.DEF_DIC_IMP_FREE3;
              recPositionCharge.DIC_IMP_FREE4_ID           := accountInfo.DEF_DIC_IMP_FREE4;
              recPositionCharge.DIC_IMP_FREE5_ID           := accountInfo.DEF_DIC_IMP_FREE5;
              DOC_DISCOUNT_CHARGE.InsertPositionCharge(recPositionCharge);
              aGenerated                                   := aGenerated + 1;

              -- Création des marges matière COFIPAC ou COFITER (alliage)
              if cThirdMaterialRelationType in('6', '7') then
                -- 6 : COFIPAC
                if cThirdMaterialRelationType = '6' then
                  -- Domaine : Achat
                  if    (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainPurchase)
                     or (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSubContract) then
                    lvChargeList  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_PUR');
                  -- Domaine : Vente
                  elsif tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSale then
                    lvChargeList  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFIPAC_CRG_SAL');
                  end if;
                -- 7 : COFITER
                elsif cThirdMaterialRelationType = '7' then
                  -- Domaine : Achat
                  if    (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainPurchase)
                     or (tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSubContract) then
                    lvChargeList  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_PUR');
                  -- Domaine : Vente
                  elsif tplPositionAlloy.C_ADMIN_DOMAIN = cAdminDomainSale then
                    lvChargeList  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POSPMM_COFITER_CRG_SAL');
                  end if;
                end if;

                DOC_DISCOUNT_CHARGE.CreatePreciousMatMargin(aPositionId         => tplPositionAlloy.DOC_POSITION_ID
                                                          , aPreciousGoodId     => tplPositionAlloy.GCO_GOOD_ID
                                                          , aLiabledAmount      => tplPositionAlloy.PCH_AMOUNT
                                                          , aDescription        => tplPositionAlloy.GAL_ALLOY_REF
                                                          , aDateref            => tplPositionAlloy.DMT_DATE_DOCUMENT
                                                          , aQuantityref        => tplPositionAlloy.DOA_WEIGHT
                                                          , aCurrencyId         => tplPositionAlloy.ACS_FINANCIAL_CURRENCY_ID
                                                          , aRateOfExchange     => tplPositionAlloy.DMT_RATE_OF_EXCHANGE
                                                          , aBasePrice          => tplPositionAlloy.DMT_BASE_PRICE
                                                          , aLangId             => tplPositionAlloy.PC_LANG_ID
                                                          , aChargeNameList     => lvChargeList
                                                          , aDiscountNameList   => '[NOT_USED]'
                                                          , aChargeAmount       => posChargeAmount
                                                          , aDiscountAmount     => posDiscountAmount
                                                           );
              -- Le type de relation tiers est matières facturées.
              elsif(cThirdMaterialRelationTypeMA = '1') then
                DOC_DISCOUNT_CHARGE.CreatePreciousMatMargin(aPositionId         => tplPositionAlloy.DOC_POSITION_ID
                                                          , aPreciousGoodId     => tplPositionAlloy.GCO_GOOD_ID
                                                          , aLiabledAmount      => tplPositionAlloy.PCH_AMOUNT
                                                          , aDescription        => tplPositionAlloy.GAL_ALLOY_REF
                                                          , aDateref            => tplPositionAlloy.DMT_DATE_DOCUMENT
                                                          , aQuantityref        => tplPositionAlloy.DOA_WEIGHT
                                                          , aCurrencyId         => tplPositionAlloy.ACS_FINANCIAL_CURRENCY_ID
                                                          , aRateOfExchange     => tplPositionAlloy.DMT_RATE_OF_EXCHANGE
                                                          , aBasePrice          => tplPositionAlloy.DMT_BASE_PRICE
                                                          , aLangId             => tplPositionAlloy.PC_LANG_ID
                                                          , aChargeNameList     => null
                                                          , aDiscountNameList   => null
                                                          , aChargeAmount       => posChargeAmount
                                                          , aDiscountAmount     => posDiscountAmount
                                                           );
              end if;
            end if;
          end if;
        end;
      end loop;
    end if;
  end generateAlloyCharge;

  /**
  * procedure generateBaseMaterialCharge
  * Description
  *   Génération des taxes "matières précieuses" pour les matériaux de base
  * @created fp 24.03.2004
  */
  procedure generateBaseMaterialCharge(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aChargeName in PTC_CHARGE.CRG_NAME%type, aGenerated out number)
  is
    cursor crPositionMaterial(cAdvMaterialMode in PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type)
    is
      select DISTINCT DOA.DOC_POSITION_ID
           , DFA.DIC_BASIS_MATERIAL_ID
           , GAU.C_ADMIN_DOMAIN
           , CRG.CRG_NAME
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.PC_LANG_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DOC_GAUGE_ID
           , POS.DOC_RECORD_ID
           , POS.PAC_THIRD_ID
           , POS.PAC_THIRD_ACI_ID
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
           , substr(nvl( (select CDE.CHD_DESCR
                            from PTC_CHARGE_DESCRIPTION CDE
                           where CDE.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
                             and CDE.PC_LANG_ID = DMT.PC_LANG_ID), CRG.CRG_NAME) ||
                    ' - ' ||
                    DOA.DIC_BASIS_MATERIAL_ID ||
                    decode(DFA.DFA_RATE_DATE, null, '', ' - ' || to_char(DFA.DFA_RATE_DATE, 'DD.MM.YYYY') )
                  , 1
                  , 255
                   ) CRG_DESCRIPTION
           , nvl(decode(cAdvMaterialMode
                      , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                      , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                      , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                       ) *
                 (DFA.DFA_RATE / nvl(DFA.DFA_BASE_COST, 1) )
               , 0
                ) PCH_AMOUNT
           , ACS_FUNCTION.ConvertAmountForView(nvl(decode(cAdvMaterialMode
                                                        , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                                                        , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                                                        , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                                                         ) *
                                                   (nvl(DFA.DFA_RATE, 0) / nvl(DFA.DFA_BASE_COST, 1) )
                                                 , 0
                                                  )
                                             , DMT.ACS_FINANCIAL_CURRENCY_ID
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , DMT.DMT_DATE_DOCUMENT
                                             , DMT.DMT_RATE_OF_EXCHANGE
                                             , DMT.DMT_BASE_PRICE
                                             , 0
                                              ) CRG_FIXED_AMOUNT_B
           , decode(cAdvMaterialMode
                  , '01', nvl(DOA.DOA_WEIGHT_DELIVERY, 0)
                  , '02', nvl(DOA.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                  , '03', nvl(DOA.DOA_WEIGHT_INVEST, 0)
                   ) DOA_WEIGHT
           , CRG.CRG_IN_SERIE_CALCULATION
           , 0 CRG_EXCLUSIVE
           , CRG.CRG_PRCS_USE
           , CRG.PTC_CHARGE_ID
           , CRG.ACS_FINANCIAL_ACCOUNT_ID
           , CRG.ACS_DIVISION_ACCOUNT_ID
           , CRG.ACS_CPN_ACCOUNT_ID
           , CRG.ACS_CDA_ACCOUNT_ID
           , CRG.ACS_PF_ACCOUNT_ID
           , CRG.ACS_PJ_ACCOUNT_ID
           , CRG.ACS_FINANCIAL_ACCOUNT_ID POS_ACS_FINANCIAL_ACCOUNT_ID
           , CRG.ACS_DIVISION_ACCOUNT_ID POS_ACS_DIVISION_ACCOUNT_ID
           , CRG.ACS_CPN_ACCOUNT_ID POS_ACS_CPN_ACCOUNT_ID
           , CRG.ACS_CDA_ACCOUNT_ID POS_ACS_CDA_ACCOUNT_ID
           , CRG.ACS_PF_ACCOUNT_ID POS_ACS_PF_ACCOUNT_ID
           , CRG.ACS_PJ_ACCOUNT_ID POS_ACS_PJ_ACCOUNT_ID
           , DFA.STM_STOCK_ID
           , GOO.GCO_GOOD_ID
        from DOC_POSITION_ALLOY DOA
           , DOC_FOOT_ALLOY DFA
           , DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DIC_BASIS_MATERIAL BMA
           , PTC_CHARGE CRG
           , GCO_ALLOY GAL
           , GCO_ALLOY_COMPONENT GAC
           , GCO_GOOD GOO
       where DOA.DOC_DOCUMENT_ID = aDocumentId
         and DFA.DOC_FOOT_ID = DOA.DOC_DOCUMENT_ID
         and DOA.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
         and DFA.DIC_BASIS_MATERIAL_ID = BMA.DIC_BASIS_MATERIAL_ID
         and DFA.DIC_COST_FOOT_ID is null
         and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and CRG.CRG_NAME = aChargeName
         and CRG.C_CHARGE_TYPE = decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
         and DMT.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAC.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
         and GAC.GAC_RATE = 100
         and GAL.GCO_ALLOY_ID = GAC.GCO_ALLOY_ID
         and GOO.GCO_GOOD_ID = GAL.GCO_GOOD_ID;

    cursor crPosMatUsh(cAdvMaterialMode in PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type)
    is
      select distinct DOA.DOC_POSITION_ID
                    , GPD.DIC_BASIS_MATERIAL_ID
                    , GAU.C_ADMIN_DOMAIN
                    , CRG.CRG_NAME
                    , DMT.DOC_DOCUMENT_ID
                    , DMT.DMT_DATE_DOCUMENT
                    , DMT.DMT_RATE_OF_EXCHANGE
                    , DMT.DMT_BASE_PRICE
                    , DMT.PC_LANG_ID
                    , DMT.ACS_FINANCIAL_CURRENCY_ID
                    , DMT.DOC_GAUGE_ID
                    , POS.DOC_RECORD_ID
                    , POS.PAC_THIRD_ID
                    , POS.PAC_THIRD_ACI_ID
                    , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
                    , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
                    , substr(nvl( (select CDE.CHD_DESCR
                                     from PTC_CHARGE_DESCRIPTION CDE
                                    where CDE.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
                                      and CDE.PC_LANG_ID = DMT.PC_LANG_ID), CRG.CRG_NAME) ||
                             ' - ' ||
                             GPD.DIC_BASIS_MATERIAL_ID ||
                             decode(DFA_MAT.DFA_RATE_DATE, null, '', ' - ' || to_char(DFA_MAT.DFA_RATE_DATE, 'DD.MM.YYYY') )
                           , 1
                           , 255
                            ) CRG_DESCRIPTION
                    , nvl(decode(cAdvMaterialMode
                               , '01', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0)
                               , '02', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA_MAT.DOA_LOSS, 0)
                               , '03', nvl(DOA_MAT.DOA_WEIGHT_INVEST, 0)
                                ) *
                          (DFA_MAT.DFA_RATE / nvl(DFA_MAT.DFA_BASE_COST, 1) )
                        , 0
                         ) PCH_AMOUNT
                    , ACS_FUNCTION.ConvertAmountForView(nvl(decode(cAdvMaterialMode
                                                                 , '01', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0)
                                                                 , '02', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                                                                 , '03', nvl(DOA_MAT.DOA_WEIGHT_INVEST, 0)
                                                                  ) *
                                                            (nvl(DFA_MAT.DFA_RATE, 0) / nvl(DFA_MAT.DFA_BASE_COST, 1) )
                                                          , 0
                                                           )
                                                      , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                      , ACS_FUNCTION.GetLocalCurrencyId
                                                      , DMT.DMT_DATE_DOCUMENT
                                                      , DMT.DMT_RATE_OF_EXCHANGE
                                                      , DMT.DMT_BASE_PRICE
                                                      , 0
                                                       ) CRG_FIXED_AMOUNT_B
                    , decode(cAdvMaterialMode
                           , '01', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0)
                           , '02', nvl(DOA_MAT.DOA_WEIGHT_DELIVERY, 0) + nvl(DOA.DOA_LOSS, 0)
                           , '03', nvl(DOA_MAT.DOA_WEIGHT_INVEST, 0)
                            ) DOA_WEIGHT
                    , CRG.CRG_IN_SERIE_CALCULATION
                    , 0 CRG_EXCLUSIVE
                    , CRG.CRG_PRCS_USE
                    , CRG.PTC_CHARGE_ID
                    , CRG.ACS_FINANCIAL_ACCOUNT_ID
                    , CRG.ACS_DIVISION_ACCOUNT_ID
                    , CRG.ACS_CPN_ACCOUNT_ID
                    , CRG.ACS_CDA_ACCOUNT_ID
                    , CRG.ACS_PF_ACCOUNT_ID
                    , CRG.ACS_PJ_ACCOUNT_ID
                    , CRG.ACS_FINANCIAL_ACCOUNT_ID POS_ACS_FINANCIAL_ACCOUNT_ID
                    , CRG.ACS_DIVISION_ACCOUNT_ID POS_ACS_DIVISION_ACCOUNT_ID
                    , CRG.ACS_CPN_ACCOUNT_ID POS_ACS_CPN_ACCOUNT_ID
                    , CRG.ACS_CDA_ACCOUNT_ID POS_ACS_CDA_ACCOUNT_ID
                    , CRG.ACS_PF_ACCOUNT_ID POS_ACS_PF_ACCOUNT_ID
                    , CRG.ACS_PJ_ACCOUNT_ID POS_ACS_PJ_ACCOUNT_ID
                    , DFA.STM_STOCK_ID
                    , null as GCO_GOOD_ID
                 from DOC_POSITION_ALLOY DOA
                    , DOC_FOOT_ALLOY DFA
                    , DOC_DOCUMENT DMT
                    , DOC_POSITION POS
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_STRUCTURED GAS
                    , PTC_CHARGE CRG
                    , (select   DIC_BASIS_MATERIAL_ID
                              , GCO_ALLOY_ID
                           from GCO_PRECIOUS_RATE_DATE
                          where GPR_TABLE_MODE = 1
                            and DIC_BASIS_MATERIAL_ID is not null
                            and GCO_ALLOY_ID is not null
                       group by DIC_BASIS_MATERIAL_ID
                              , GCO_ALLOY_ID) GPD
                    , DOC_FOOT_ALLOY DFA_MAT
                    , DOC_POSITION_ALLOY DOA_MAT
                where DOA.DOC_DOCUMENT_ID = aDocumentId
                  and DOA_MAT.DOC_DOCUMENT_ID = aDocumentId
                  and DFA.DOC_FOOT_ID = DOA.DOC_DOCUMENT_ID
                  and DOA.GCO_ALLOY_ID = DFA.GCO_ALLOY_ID
                  and DOA.GCO_ALLOY_ID = GPD.GCO_ALLOY_ID
                  and DFA.DIC_COST_FOOT_ID is null
                  and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                  and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA_MAT.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                  and CRG.CRG_NAME = aChargeName
                  and CRG.C_CHARGE_TYPE = decode(GAU.C_ADMIN_DOMAIN, cAdminDomainSale, '1', cAdminDomainPurchase, '2', cAdminDomainSubContract, '2', '0')
                  and DMT.DOC_DOCUMENT_ID = DOA.DOC_DOCUMENT_ID
                  and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
                  and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
                  and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                  and DFA_MAT.DIC_COST_FOOT_ID is null
                  and DFA_MAT.DOC_FOOT_ID = DOA.DOC_DOCUMENT_ID
                  and GPD.DIC_BASIS_MATERIAL_ID = DFA_MAT.DIC_BASIS_MATERIAL_ID
                  and DOA_MAT.DIC_BASIS_MATERIAL_ID = GPD.DIC_BASIS_MATERIAL_ID
                  and POS.DOC_POSITION_ID = DOA_MAT.DOC_POSITION_ID;

    tplPositionMaterial          crPositionMaterial%rowtype;
    accountInfo                  ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    lvAdvMaterialMode            PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type;
    bStop                        boolean;
    canGenerateDiscount          boolean;
    metalAccount                 PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    thaManaged                   PAC_THIRD_ALLOY.THA_MANAGED%type;
    docMetalAccount              PCS.PC_CBASE.CBACNAME%type;
    lvThirdMaterialRelationType  PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cThirdMaterialRelationTypeMA PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    posChargeAmount              DOC_POSITION.POS_CHARGE_AMOUNT%type;
    posDiscountAmount            DOC_POSITION.POS_DISCOUNT_AMOUNT%type;
  begin
    bStop  := false;

    begin
      select decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.C_ADV_MATERIAL_MODE
                  , cAdminDomainSale, CUS.C_ADV_MATERIAL_MODE
                  , cAdminDomainSubContract, SUP.C_ADV_MATERIAL_MODE
                  , nvl(CUS.C_ADV_MATERIAL_MODE, SUP.C_ADV_MATERIAL_MODE)
                   )
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , cAdminDomainSale, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                  , cAdminDomainSubContract, nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                   ) C_THIRD_MATERIAL_RELATION_TYPE
           , decode(GAU.C_ADMIN_DOMAIN
                  , cAdminDomainPurchase, SUP.CRE_METAL_ACCOUNT
                  , cAdminDomainSale, CUS.CUS_METAL_ACCOUNT
                  , cAdminDomainSubContract, SUP.CRE_METAL_ACCOUNT
                  , nvl(CUS.CUS_METAL_ACCOUNT, SUP.CRE_METAL_ACCOUNT)
                   ) METAL_ACCOUNT
        into lvAdvMaterialMode
           , lvThirdMaterialRelationType
           , metalAccount
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where DMT.DOC_DOCUMENT_ID = aDocumentId
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      docMetalAccount  := PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT');

      -- Ouverture du curseur pour le mode COFIPAC ou COFITER
      if lvThirdMaterialRelationType in('6', '7') then
        open crPosMatUsh(lvAdvMaterialMode);

        fetch crPosMatUsh
         into tplPositionMaterial;

        bStop  := not crPosMatUsh%found;
      else
        open crPositionMaterial(lvAdvMaterialMode);

        fetch crPositionMaterial
         into tplPositionMaterial;

        bStop  := not crPositionMaterial%found;
      end if;

      while not bStop loop
        -- curseur sur les positions alliages
        declare
          -- déclaré dans la boucle FOR pour éviter de devoir réinitialiser chaque champ du record l'un après l'autre à chaque passage
          recPositionCharge DOC_POSITION_CHARGE%rowtype;
        begin
          -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
          thaManaged  := 0;

          begin
            if    (tplPositionMaterial.C_ADMIN_DOMAIN = cAdminDomainPurchase)
               or (tplPositionMaterial.C_ADMIN_DOMAIN = cAdminDomainSubContract) then
              select nvl(THA.THA_MANAGED, 0)
                into thaManaged
                from PAC_THIRD_ALLOY THA
               where THA.PAC_SUPPLIER_PARTNER_ID = tplPositionMaterial.PAC_THIRD_ID
                 and THA.DIC_BASIS_MATERIAL_ID = tplPositionMaterial.DIC_BASIS_MATERIAL_ID;
            elsif tplPositionMaterial.C_ADMIN_DOMAIN = cAdminDomainSale then
              select nvl(THA.THA_MANAGED, 0)
                into thaManaged
                from PAC_THIRD_ALLOY THA
               where THA.PAC_CUSTOM_PARTNER_ID = tplPositionMaterial.PAC_THIRD_ID
                 and THA.DIC_BASIS_MATERIAL_ID = tplPositionMaterial.DIC_BASIS_MATERIAL_ID;
            else
              thaManaged  := 1;
            end if;
          exception
            when no_data_found then
              -- Si aucune matière/alliage n'est trouvée pour le tiers, on autorise par défaut la création de la remise
              thaManaged  := 1;
          end;

          -- Le code de gestion de la matière/alliage courante n'a pas d'influence lorsque la gestion des comptes poids
          -- est activée.
          if     (docMetalAccount = '1')
             and (metalAccount = 1) then
            canGenerateDiscount  := true;
          else
            canGenerateDiscount  :=(thaManaged = 1);
          end if;

          if canGenerateDiscount then
            -- Recherche le type de relation avec tiers présent sur l'éventuel compte poids lié au tiers.
            cThirdMaterialRelationTypeMA  := lvThirdMaterialRelationType;

            if     (docMetalAccount = '1')
               and (metalAccount = 1) then
              if tplPositionMaterial.STM_STOCK_ID is not null then
                begin
                  select nvl(STO.C_THIRD_MATERIAL_RELATION_TYPE, cThirdMaterialRelationTypeMA)
                    into cThirdMaterialRelationTypeMA
                    from STM_STOCK STO
                   where STO.STM_STOCK_ID = tplPositionMaterial.STM_STOCK_ID;
                exception
                  when no_data_found then
                    null;
                end;
              else
                -- Le compte poids n'est pas spécifié sur la matière pied. C'est donc type de relation qui se trouve sur le
                -- compte poids par défaut qui est utilisé.
                begin
                  select nvl(STO.C_THIRD_MATERIAL_RELATION_TYPE, cThirdMaterialRelationTypeMA)
                    into cThirdMaterialRelationTypeMA
                    from STM_STOCK STO
                   where STO.STO_DEFAULT_METAL_ACCOUNT = 1;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;

            -- Le type de relation tiers est différent de prix complet.
            if (cThirdMaterialRelationTypeMA <> '5') then
              -- Si gestion des comptes financiers ou analytiques
              if    (tplPositionMaterial.GAS_FINANCIAL = 1)
                 or (tplPositionMaterial.GAS_ANALYTICAL = 1) then
                -- Utilise les comptes de la taxe
                recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID  := tplPositionMaterial.ACS_FINANCIAL_ACCOUNT_ID;
                recPositionCharge.ACS_DIVISION_ACCOUNT_ID   := tplPositionMaterial.ACS_DIVISION_ACCOUNT_ID;
                recPositionCharge.ACS_CPN_ACCOUNT_ID        := tplPositionMaterial.ACS_CPN_ACCOUNT_ID;
                recPositionCharge.ACS_CDA_ACCOUNT_ID        := tplPositionMaterial.ACS_CDA_ACCOUNT_ID;
                recPositionCharge.ACS_PF_ACCOUNT_ID         := tplPositionMaterial.ACS_PF_ACCOUNT_ID;
                recPositionCharge.ACS_PJ_ACCOUNT_ID         := tplPositionMaterial.ACS_PJ_ACCOUNT_ID;
                accountInfo.DEF_HRM_PERSON                  := null;
                accountInfo.FAM_FIXED_ASSETS_ID             := null;
                accountInfo.C_FAM_TRANSACTION_TYP           := null;
                accountInfo.DEF_DIC_IMP_FREE1               := null;
                accountInfo.DEF_DIC_IMP_FREE2               := null;
                accountInfo.DEF_DIC_IMP_FREE3               := null;
                accountInfo.DEF_DIC_IMP_FREE4               := null;
                accountInfo.DEF_DIC_IMP_FREE5               := null;
                accountInfo.DEF_TEXT1                       := null;
                accountInfo.DEF_TEXT2                       := null;
                accountInfo.DEF_TEXT3                       := null;
                accountInfo.DEF_TEXT4                       := null;
                accountInfo.DEF_TEXT5                       := null;
                accountInfo.DEF_NUMBER1                     := null;
                accountInfo.DEF_NUMBER2                     := null;
                accountInfo.DEF_NUMBER3                     := null;
                accountInfo.DEF_NUMBER4                     := null;
                accountInfo.DEF_NUMBER5                     := null;
                -- recherche des comptes
                ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplPositionMaterial.PTC_CHARGE_ID
                                                         , '30'
                                                         , tplPositionMaterial.C_ADMIN_DOMAIN
                                                         , tplPositionMaterial.DMT_DATE_DOCUMENT
                                                         , tplPositionMaterial.DOC_GAUGE_ID
                                                         , tplPositionMaterial.DOC_DOCUMENT_ID
                                                         , tplPositionMaterial.DOC_POSITION_ID
                                                         , tplPositionMaterial.DOC_RECORD_ID
                                                         , tplPositionMaterial.PAC_THIRD_ACI_ID
                                                         , tplPositionMaterial.POS_ACS_FINANCIAL_ACCOUNT_ID
                                                         , tplPositionMaterial.POS_ACS_DIVISION_ACCOUNT_ID
                                                         , tplPositionMaterial.POS_ACS_CPN_ACCOUNT_ID
                                                         , tplPositionMaterial.POS_ACS_CDA_ACCOUNT_ID
                                                         , tplPositionMaterial.POS_ACS_PF_ACCOUNT_ID
                                                         , tplPositionMaterial.POS_ACS_PJ_ACCOUNT_ID
                                                         , recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID
                                                         , recPositionCharge.ACS_DIVISION_ACCOUNT_ID
                                                         , recPositionCharge.ACS_CPN_ACCOUNT_ID
                                                         , recPositionCharge.ACS_CDA_ACCOUNT_ID
                                                         , recPositionCharge.ACS_PF_ACCOUNT_ID
                                                         , recPositionCharge.ACS_PJ_ACCOUNT_ID
                                                         , accountInfo
                                                          );

                if (tplPositionMaterial.GAS_ANALYTICAL = 0) then
                  recPositionCharge.ACS_CPN_ACCOUNT_ID  := null;
                  recPositionCharge.ACS_CDA_ACCOUNT_ID  := null;
                  recPositionCharge.ACS_PJ_ACCOUNT_ID   := null;
                  recPositionCharge.ACS_PF_ACCOUNT_ID   := null;
                end if;
              end if;

              recPositionCharge.DOC_POSITION_ID            := tplPositionMaterial.DOC_POSITION_ID;
              recPositionCharge.C_CHARGE_ORIGIN            := 'PM';
              recPositionCharge.C_FINANCIAL_CHARGE         := '03';
              recPositionCharge.PCH_NAME                   := tplPositionMaterial.CRG_NAME;
              recPositionCharge.PCH_DESCRIPTION            := tplPositionMaterial.CRG_DESCRIPTION;
              recPositionCharge.PCH_AMOUNT                 := tplPositionMaterial.PCH_AMOUNT;
              recPositionCharge.PCH_FIXED_AMOUNT_B         := tplPositionMaterial.CRG_FIXED_AMOUNT_B;
              recPositionCharge.C_CALCULATION_MODE         := '0';
              recPositionCharge.PCH_IN_SERIES_CALCULATION  := tplPositionMaterial.CRG_IN_SERIE_CALCULATION;
              recPositionCharge.PCH_EXCLUSIVE              := tplPositionMaterial.CRG_EXCLUSIVE;
              recPositionCharge.PCH_PRCS_USE               := tplPositionMaterial.CRG_PRCS_USE;
              recPositionCharge.PCH_MODIFY                 := 0;
              recPositionCharge.PTC_CHARGE_ID              := tplPositionMaterial.PTC_CHARGE_ID;
              recPositionCharge.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(accountInfo.DEF_HRM_PERSON);
              recPositionCharge.FAM_FIXED_ASSETS_ID        := accountInfo.FAM_FIXED_ASSETS_ID;
              recPositionCharge.C_FAM_TRANSACTION_TYP      := accountInfo.C_FAM_TRANSACTION_TYP;
              recPositionCharge.PCH_IMP_TEXT_1             := accountInfo.DEF_TEXT1;
              recPositionCharge.PCH_IMP_TEXT_2             := accountInfo.DEF_TEXT2;
              recPositionCharge.PCH_IMP_TEXT_3             := accountInfo.DEF_TEXT3;
              recPositionCharge.PCH_IMP_TEXT_4             := accountInfo.DEF_TEXT4;
              recPositionCharge.PCH_IMP_TEXT_5             := accountInfo.DEF_TEXT5;
              recPositionCharge.PCH_IMP_NUMBER_1           := to_number(accountInfo.DEF_NUMBER1);
              recPositionCharge.PCH_IMP_NUMBER_2           := to_number(accountInfo.DEF_NUMBER2);
              recPositionCharge.PCH_IMP_NUMBER_3           := to_number(accountInfo.DEF_NUMBER3);
              recPositionCharge.PCH_IMP_NUMBER_4           := to_number(accountInfo.DEF_NUMBER4);
              recPositionCharge.PCH_IMP_NUMBER_5           := to_number(accountInfo.DEF_NUMBER5);
              recPositionCharge.DIC_IMP_FREE1_ID           := accountInfo.DEF_DIC_IMP_FREE1;
              recPositionCharge.DIC_IMP_FREE2_ID           := accountInfo.DEF_DIC_IMP_FREE2;
              recPositionCharge.DIC_IMP_FREE3_ID           := accountInfo.DEF_DIC_IMP_FREE3;
              recPositionCharge.DIC_IMP_FREE4_ID           := accountInfo.DEF_DIC_IMP_FREE4;
              recPositionCharge.DIC_IMP_FREE5_ID           := accountInfo.DEF_DIC_IMP_FREE5;
              -- création de la taxe de position
              DOC_DISCOUNT_CHARGE.InsertPositionCharge(recPositionCharge);
              aGenerated                                   := aGenerated + 1;

              -- Les marges ne doivent pas êtres générées pour la relation tiers 6-(COFIPAC) et 7-(COFITER)
              -- Le type de relation tiers est matières facturées.
              if     not(lvThirdMaterialRelationType in('6', '7') )
                 and (cThirdMaterialRelationTypeMA = '1') then
                DOC_DISCOUNT_CHARGE.CreatePreciousMatMargin(aPositionId         => tplPositionMaterial.DOC_POSITION_ID
                                                          , aPreciousGoodId     => tplPositionMaterial.GCO_GOOD_ID
                                                          , aLiabledAmount      => tplPositionMaterial.PCH_AMOUNT
                                                          , aDescription        => tplPositionMaterial.DIC_BASIS_MATERIAL_ID
                                                          , aDateref            => tplPositionMaterial.DMT_DATE_DOCUMENT
                                                          , aQuantityref        => tplPositionMaterial.DOA_WEIGHT
                                                          , aCurrencyId         => tplPositionMaterial.ACS_FINANCIAL_CURRENCY_ID
                                                          , aRateOfExchange     => tplPositionMaterial.DMT_RATE_OF_EXCHANGE
                                                          , aBasePrice          => tplPositionMaterial.DMT_BASE_PRICE
                                                          , aLangId             => tplPositionMaterial.PC_LANG_ID
                                                          , aChargeNameList     => null
                                                          , aDiscountNameList   => null
                                                          , aChargeAmount       => posChargeAmount
                                                          , aDiscountAmount     => posDiscountAmount
                                                           );
              end if;
            end if;
          end if;
        end;

        -- Balayage du curseur
        if lvThirdMaterialRelationType in('6', '7') then
          fetch crPosMatUsh
           into tplPositionMaterial;

          bStop  := not crPosMatUsh%found;
        else
          fetch crPositionMaterial
           into tplPositionMaterial;

          bStop  := not crPositionMaterial%found;
        end if;
      end loop;

      -- Fermeture du curseur selon le mode utilisé
      if lvThirdMaterialRelationType in('6', '7') then
        close crPosMatUsh;
      else
        close crPositionMaterial;
      end if;
    end if;
  end generateBaseMaterialCharge;

  /**
  * Description
  *   procédure de génération des taxes de position relatives aux matières précieuses
  */
  procedure generatePreciousMatCharge(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aGenerated out number)
  is
    adminDomain                DOC_GAUGE.C_ADMIN_DOMAIN%type;
    chargeName                 PTC_CHARGE.CRG_NAME%type;
    materialMgntMode           PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type;
    thirdId                    PAC_THIRD.PAC_THIRD_ID%type;
    gasWeightMat               DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    cThirdMaterialRelationType PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    lbGenerateStandard         boolean;
  begin
    -- recherche du domaine
    select GAU.C_ADMIN_DOMAIN
         , DMT.PAC_THIRD_ID
         , GAS.GAS_WEIGHT_MAT
         , C_THIRD_MATERIAL_RELATION_TYPE
      into adminDomain
         , thirdId
         , gasWeightMat
         , cThirdMaterialRelationType
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where DMT.DOC_DOCUMENT_ID = aDocumentId
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    if thirdId is not null then
      -- si le gabarit gère les matières précieuses
      if gasWeightMat = 1 then
        -- recherche de la liste des taxes selon le domaine
        if    (adminDomain = cAdminDomainPurchase)
           or (adminDomain = cAdminDomainSubContract) then
          select C_MATERIAL_MGNT_MODE
               , nvl(cThirdMaterialRelationType, C_THIRD_MATERIAL_RELATION_TYPE)
            into materialMgntMode
               , cThirdMaterialRelationType
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = thirdId;
        elsif adminDomain = cAdminDomainSale then
          select C_MATERIAL_MGNT_MODE
               , nvl(cThirdMaterialRelationType, C_THIRD_MATERIAL_RELATION_TYPE)
            into materialMgntMode
               , cThirdMaterialRelationType
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = thirdId;
        end if;

        --supression des taxes "Matières premières" déjà existantes
        delete from DOC_POSITION_CHARGE
              where DOC_DOCUMENT_ID = aDocumentId
                and C_CHARGE_ORIGIN in('PM', 'PMM');

        -- Le type de relation tiers doit être différent de 5 - Prix complet
        if (cThirdMaterialRelationType <> '5') then
          lbGenerateStandard  := true;

          -- Type relation tiers - 6 - Confié (CONFIPAC)
          if cThirdMaterialRelationType = '6' then
            if    (adminDomain = cAdminDomainPurchase)
               or (adminDomain = cAdminDomainSubContract) then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_PUR');
            elsif adminDomain = cAdminDomainSale then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFIPAC_CRG_SAL');
            end if;

            if chargeName is not null then
              lbGenerateStandard  := false;
              -- Alliages
              generateAlloyCharge(aDocumentId, chargeName, aGenerated);

              -- Matières de base
              if    (adminDomain = cAdminDomainPurchase)
                 or (adminDomain = cAdminDomainSubContract) then
                generateBaseMaterialCharge(aDocumentId, PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_CHARGE_PURCHASE'), aGenerated);
              elsif adminDomain = cAdminDomainSale then
                generateBaseMaterialCharge(aDocumentId, PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_CHARGE_SALE'), aGenerated);
              end if;
            end if;
          -- Type relation tiers - 7 - Facturé (CONFITER)
          elsif cThirdMaterialRelationType = '7' then
            if    (adminDomain = cAdminDomainPurchase)
               or (adminDomain = cAdminDomainSubContract) then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_PUR');
            elsif adminDomain = cAdminDomainSale then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_COFITER_CRG_SAL');
            end if;

            if chargeName is not null then
              lbGenerateStandard  := false;
              -- Alliages
              generateAlloyCharge(aDocumentId, chargeName, aGenerated);
            end if;
          end if;

          if lbGenerateStandard then
            if    (adminDomain = cAdminDomainPurchase)
               or (adminDomain = cAdminDomainSubContract) then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_CHARGE_PURCHASE');
            elsif adminDomain = cAdminDomainSale then
              chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_POS_CHARGE_SALE');
            end if;

            -- Alliages
            if materialMgntMode = '1' then
              generateAlloyCharge(aDocumentId, chargeName, aGenerated);
            -- Matières de base
            elsif materialMgntMode = '2' then
              generateBaseMaterialCharge(aDocumentId, chargeName, aGenerated);
            end if;
          end if;
        end if;
      end if;
    end if;
  end generatePreciousMatCharge;

  /**
  * procedure DeleteFalWeigh
  * Description
  *   Effacement des pesées (FAL_WEIGH) de la position (DOC_POSITION_ID)
  */
  procedure DeleteFalWeigh(aPositionID in number)
  is
  begin
    delete from FAL_WEIGH
          where DOC_POSITION_ID = aPositionID;
  end DeleteFalWeigh;

  /**
  * procedure DeletePositionAlloy
  * Description
  *   Effacement des positions alliage (DOC_POSITION_ALLOY)
  *     de la position (DOC_POSITION_ID)
  */
  procedure DeletePositionAlloy(aPositionID in number)
  is
  begin
    delete from DOC_POSITION_ALLOY
          where DOC_POSITION_ID = aPositionID;
  end DeletePositionAlloy;

  /**
  * procedure UpdateDocumentFootMatFlags
  * Description
  *   Màj des flags sur les matières précieuses du document
  */
  procedure UpdateDocumentFootMatFlags(aDocumentID in number, aCreateFootMat in integer default -1, aRecalcFootMat in integer default -1)
  is
  begin
    update DOC_DOCUMENT
       set DMT_CREATE_FOOT_MAT = decode(aCreateFootMat, -1, DMT_CREATE_FOOT_MAT, aCreateFootMat)
         , DMT_RECALC_FOOT_MAT = decode(aRecalcFootMat, -1, DMT_RECALC_FOOT_MAT, aRecalcFootMat)
     where DOC_DOCUMENT_ID = aDocumentID;
  end UpdateDocumentFootMatFlags;

  /**
  * procedure UpdateAlloyPosQtyChange
  * Description
  *   Processus de màj des divers élements des matières précieuses lors de la modification de la qté d'une position
  */
  procedure UpdateAlloyPosQtyChange(aPositionID in number, aOldQuantitySU in number, aNewQuantitySU in number)
  is
    posCreateMat DOC_POSITION.POS_CREATE_MAT%type;
  begin
    posCreateMat  := null;
    UpdateAlloyPosQtyChange(aPositionID, null, null, aOldQuantitySU, aNewQuantitySU, null, null, posCreateMat);
  end UpdateAlloyPosQtyChange;

  /**
  * procedure UpdateAlloyPosQtyChange
  * Description
  *   Processus de màj des divers élements des matières précieuses lors de la modification de la qté d'une position.
  *   Cette procédure doit impérativement être utilisé pour un appel à partir d'un trigger sur la table des
  *   position. En particulier dans le trigger DOC_POS_BIUD_UPDATE_FLAGS.
  */
  procedure UpdateAlloyPosQtyChange(
    aPositionID       in     number
  , aDocumentID       in     number
  , aGoodID           in     number
  , aOldQuantitySU    in     number
  , aNewQuantitySU    in     number
  , aDmtCreateFootMat in     DOC_DOCUMENT.DMT_CREATE_FOOT_MAT%type
  , aGasWeightMat     in     DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type
  , aPosCreateMat     in out DOC_POSITION.POS_CREATE_MAT%type
  )
  is
    nDocumentID       number;
    iDmtCreateFootMat integer;
    iPosCreateMat     integer;
    iGasWeightMat     integer;
    iSrcGasWeightMat  integer;
    nDetailParentID   DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    gcoGoodID         GCO_GOOD.GCO_GOOD_ID%type;
  begin
    /* Suppression des pesées liées à la position */
    DeleteFalWeigh(aPositionID);

    /* Recherche d'informations */
    begin
      /* Informations sur le document de la position modifiée */
      if aDocumentID is null then
        select DMT.DOC_DOCUMENT_ID
             , DMT.DMT_CREATE_FOOT_MAT
             , GAS.GAS_WEIGHT_MAT
             , POS.POS_CREATE_MAT
             , POS.GCO_GOOD_ID
          into nDocumentID
             , iDmtCreateFootMat
             , iGasWeightMat
             , iPosCreateMat
             , gcoGoodID
          from DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_STRUCTURED GAS
         where POS.DOC_POSITION_ID = aPositionID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;
      else
        nDocumentID        := aDocumentID;
        iDmtCreateFootMat  := aDmtCreateFootMat;
        iGasWeightMat      := aGasWeightMat;
        iPosCreateMat      := aPosCreateMat;
        gcoGoodID          := aGoodID;
      end if;
    exception
      when no_data_found then
        iGasWeightMat  := 0;
    end;

    /* Gabarit document -> Gestion des poids matières précieuses = OUI */
    if iGasWeightMat = 1 then
      /* Vérifier si en décharge */
      select nvl(max(DOC_DOC_POSITION_DETAIL_ID), 0)
        into nDetailParentID
        from DOC_POSITION_DETAIL
       where DOC_POSITION_ID = aPositionID
         and DOC_GAUGE_RECEIPT_ID is not null;

      /* Vérifie si le gabarit document de la position parent à la
         Gestion des poids matières précieuses = OUI */
      if nDetailParentID <> 0 then
        select GAS.GAS_WEIGHT_MAT
          into iSrcGasWeightMat
          from DOC_POSITION_DETAIL PDE
             , DOC_GAUGE_STRUCTURED GAS
         where PDE.DOC_POSITION_DETAIL_ID = nDetailParentID
           and PDE.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;
      end if;

      /* Position avec décharge et dont le gabarit de la positIon parent
         Gestion des poids matières précieuses = OUI */
      if     (nDetailParentID <> 0)
         and (iSrcGasWeightMat = 1) then
        /* Màj des matières précieuses liées à la position */
        UpdAlloyDischPosQtyChange(aPositionID, gcoGoodID, aOldQuantitySU, aNewQuantitySU);
        /* Màj document, matière sur pied à recalculer = 1 */
        UpdateDocumentFootMatFlags(aDocumentID => nDocumentID, aRecalcFootMat => 1);
      else
        /* Suppression des matières positions liées à la position */
        DeletePositionAlloy(aPositionID);

        /* Si les matières précieuses sont gérées sur la position */
        if iPosCreateMat <> 0 then
          /* Mise à jour ou retour (pour appel à partir d'un trigger) de l'indicateur Matières position à créér */
          if aDocumentID is null then
            update DOC_POSITION
               set POS_CREATE_MAT = 1
             where DOC_POSITION_ID = aPositionID;
          else
            aPosCreateMat  := 1;
          end if;
        end if;

        /* Si matières sur pied document ont été crées */
        if iDmtCreateFootMat = 2 then
          /* Màj flag document, matière sur pied à recalculer */
          UpdateDocumentFootMatFlags(aDocumentID => nDocumentID, aRecalcFootMat => 1);
        end if;
      end if;
    end if;
  end UpdateAlloyPosQtyChange;

  /**
  * procedure UpdAlloyDischPosQtyChange
  * Description
  *   Processus de màj des positons d'alliage lors de la modification
  *     de la qté d'une position qui est issue d'une décharge
  */
  procedure UpdAlloyDischPosQtyChange(aPositionID in number, aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aOldQuantitySU in number, aNewQuantitySU in number)
  is
    cursor crPositionAlloy(cPositionID in number, cGoodID in number)
    is
      select DOA.DOC_POSITION_ALLOY_ID
           , nvl(DOA.DOA_WEIGHT_DELIVERY, 0) DOA_WEIGHT_DELIVERY
           , nvl(DOA.DOA_LOSS, 0) DOA_LOSS
           , nvl(DOA.DOA_WEIGHT_INVEST, 0) DOA_WEIGHT_INVEST
           , GPM.GPM_STONE_NUMBER
           , GPM.GPM_WEIGHT_DELIVER
           , GPM.GPM_LOSS_UNIT
           , GPM.GPM_WEIGHT_INVEST
        from DOC_POSITION_ALLOY DOA
           , GCO_PRECIOUS_MAT GPM
       where DOA.DOC_POSITION_ID = cPositionID
         and DOA.GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
         and GPM.GCO_GOOD_ID = cGoodID;

    tmpDOA_STONE_NUM          DOC_POSITION_ALLOY.DOA_STONE_NUM%type;
    tmpDOA_WEIGHT_DELIVERY_TH DOC_POSITION_ALLOY.DOA_WEIGHT_DELIVERY_TH%type;
    tmpDOA_WEIGHT_DELIVERY    DOC_POSITION_ALLOY.DOA_WEIGHT_DELIVERY%type;
    tmpDOA_WEIGHT_DIF         DOC_POSITION_ALLOY.DOA_WEIGHT_DIF%type;
    tmpDOA_LOSS               DOC_POSITION_ALLOY.DOA_LOSS%type;
    tmpDOA_LOSS_TH            DOC_POSITION_ALLOY.DOA_LOSS_TH%type;
    tmpDOA_WEIGHT_INVEST_TH   DOC_POSITION_ALLOY.DOA_WEIGHT_INVEST_TH%type;
    tmpDOA_WEIGHT_INVEST      DOC_POSITION_ALLOY.DOA_WEIGHT_INVEST%type;
    tmpDOA_COMMENT            DOC_POSITION_ALLOY.DOA_COMMENT%type;
  begin
    for tplPositionAlloy in crPositionAlloy(aPositionID, aGoodID) loop
      /* Recalculer les valeurs en fonction de la nouvelle quantité */
      /* Nombre de pierres */
      tmpDOA_STONE_NUM           := tplPositionAlloy.GPM_STONE_NUMBER * aNewQuantitySU;
      /* Poids livré théorique */
      tmpDOA_WEIGHT_DELIVERY_TH  := tplPositionAlloy.GPM_WEIGHT_DELIVER * aNewQuantitySU;

      /* Poids livré */
      if aOldQuantitySU <> 0 then
        tmpDOA_WEIGHT_DELIVERY  := (aNewQuantitySU * tplPositionAlloy.DOA_WEIGHT_DELIVERY) / aOldQuantitySU;
      else
        tmpDOA_WEIGHT_DELIVERY  := 0;
      end if;

      /* Ecart */
      if tmpDOA_WEIGHT_DELIVERY_TH <> 0 then
        tmpDOA_WEIGHT_DIF  := (tmpDOA_WEIGHT_DELIVERY_TH - tmpDOA_WEIGHT_DELIVERY) * 100 / tmpDOA_WEIGHT_DELIVERY_TH;
      else
        tmpDOA_WEIGHT_DIF  := 0;
      end if;

      /* Perte */
      if aOldQuantitySU <> 0 then
        tmpDOA_LOSS  := (aNewQuantitySU * tplPositionAlloy.DOA_LOSS) / aOldQuantitySU;
      else
        tmpDOA_LOSS  := 0;
      end if;

      /* Perte théorique */
      tmpDOA_LOSS_TH             := tplPositionAlloy.GPM_LOSS_UNIT * aNewQuantitySU;
      /* Poids investi théorique */
      tmpDOA_WEIGHT_INVEST_TH    := tplPositionAlloy.GPM_WEIGHT_INVEST * aNewQuantitySU;

      /* Poids investi */
      if aOldQuantitySU <> 0 then
        tmpDOA_WEIGHT_INVEST  := (aNewQuantitySU * tplPositionAlloy.DOA_WEIGHT_INVEST) / aOldQuantitySU;
      else
        tmpDOA_WEIGHT_INVEST  := 0;
      end if;

      /* màj du tuple */
      update DOC_POSITION_ALLOY DOA
         set DOA.DOA_STONE_NUM = tmpDOA_STONE_NUM
           , DOA.DOA_WEIGHT_DELIVERY_TH = tmpDOA_WEIGHT_DELIVERY_TH
           , DOA.DOA_WEIGHT_DELIVERY = tmpDOA_WEIGHT_DELIVERY
           , DOA.DOA_WEIGHT_DIF = tmpDOA_WEIGHT_DIF
           , DOA.DOA_LOSS = tmpDOA_LOSS
           , DOA.DOA_LOSS_TH = tmpDOA_LOSS_TH
           , DOA.DOA_WEIGHT_INVEST_TH = tmpDOA_WEIGHT_INVEST_TH
           , DOA.DOA_WEIGHT_INVEST = tmpDOA_WEIGHT_INVEST
           , DOA.A_DATEMOD = sysdate
           , DOA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOA.DOC_POSITION_ALLOY_ID = tplPositionAlloy.DOC_POSITION_ALLOY_ID;
    end loop;

    /* màj des tuples des matières de base */
    if aOldQuantitySU <> 0 then
      update DOC_POSITION_ALLOY DOA
         set DOA_WEIGHT_DELIVERY_TH = (aNewQuantitySU * DOA_WEIGHT_DELIVERY_TH) / aOldQuantitySU
           , DOA_WEIGHT_DELIVERY = (aNewQuantitySU * DOA_WEIGHT_DELIVERY) / aOldQuantitySU
           , DOA_LOSS = (aNewQuantitySU * DOA_LOSS) / aOldQuantitySU
           , DOA_LOSS_TH = (aNewQuantitySU * DOA_LOSS_TH) / aOldQuantitySU
           , DOA_WEIGHT_INVEST_TH = (aNewQuantitySU * DOA_WEIGHT_INVEST_TH) / aOldQuantitySU
           , DOA_WEIGHT_INVEST = (aNewQuantitySU * DOA_WEIGHT_INVEST) / aOldQuantitySU
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = aPositionID
         and DIC_BASIS_MATERIAL_ID is not null;
    else
      update DOC_POSITION_ALLOY DOA
         set DOA_WEIGHT_DELIVERY_TH = 0
           , DOA_WEIGHT_DELIVERY = 0
           , DOA_LOSS = 0
           , DOA_LOSS_TH = 0
           , DOA_WEIGHT_INVEST_TH = 0
           , DOA_WEIGHT_INVEST = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = aPositionID
         and DIC_BASIS_MATERIAL_ID is not null;
    end if;
  end UpdAlloyDischPosQtyChange;
end DOC_POSITION_ALLOY_FUNCTIONS;
