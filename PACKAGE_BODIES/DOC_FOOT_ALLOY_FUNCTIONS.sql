--------------------------------------------------------
--  DDL for Package Body DOC_FOOT_ALLOY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FOOT_ALLOY_FUNCTIONS" 
is
  /**
  * Description
  *    Graphe Génération Matières Pied
  */
  procedure GenerateFootMat(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    bStop                      boolean;
    dmtCreateFootMat           DOC_DOCUMENT.DMT_CREATE_FOOT_MAT%type;
    dmtRecalcFootMat           DOC_DOCUMENT.DMT_RECALC_FOOT_MAT%type;
    dmtDocumentDate            DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    dmtRateOfExchange          DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice               DOC_DOCUMENT.DMT_BASE_PRICE%type;
    srcDocumentID              DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    cAdminDomain               DOC_GAUGE.C_ADMIN_DOMAIN%type;
    gasWeighingMgm             DOC_GAUGE_STRUCTURED.GAS_WEIGHING_MGM%type;
    gasWeightMat               DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    thirdWeighingMgnt          PAC_CUSTOM_PARTNER.C_WEIGHING_MGNT%type;
    cThirdMaterialRelationType PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cMaterialMgntMode          PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    nAdvMaterialMgnt           PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type;
    dicFreeCode1ID             DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type;
    dicComplementaryDataID     DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type;
    datToExclude               DOC_FOOT_ALLOY.A_DATECRE%type;
    vCountAlloy                DOC_POSITION_ALLOY.DOC_POSITION_ALLOY_ID%type;
    bDischarge                 boolean;
  begin
    bStop  := false;

    begin
      select DMT.DMT_CREATE_FOOT_MAT
           , DMT.DMT_RECALC_FOOT_MAT
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , GAU.C_ADMIN_DOMAIN
           , GAS.GAS_WEIGHING_MGM
           , GAS.GAS_WEIGHT_MAT
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.C_WEIGHING_MGNT
                  , '2', CUS.C_WEIGHING_MGNT
                  , '5', SUP.C_WEIGHING_MGNT
                  , nvl(CUS.C_WEIGHING_MGNT, SUP.C_WEIGHING_MGNT)
                   ) C_WEIGHING_MGNT
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , '2', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                  , '5', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                   ) C_THIRD_MATERIAL_RELATION_TYPE
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.C_MATERIAL_MGNT_MODE
                  , '2', CUS.C_MATERIAL_MGNT_MODE
                  , '5', SUP.C_MATERIAL_MGNT_MODE
                  , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                   ) C_MATERIAL_MGNT_MODE
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.CRE_ADV_MATERIAL_MGNT
                  , '2', CUS.CUS_ADV_MATERIAL_MGNT
                  , '5', SUP.CRE_ADV_MATERIAL_MGNT
                  , nvl(CUS.CUS_ADV_MATERIAL_MGNT, SUP.CRE_ADV_MATERIAL_MGNT)
                   ) ADV_MATERIAL_MGNT
           , PER.DIC_FREE_CODE1_ID
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.DIC_COMPLEMENTARY_DATA_ID
                  , '2', CUS.DIC_COMPLEMENTARY_DATA_ID
                  , '5', SUP.DIC_COMPLEMENTARY_DATA_ID
                  , nvl(CUS.DIC_COMPLEMENTARY_DATA_ID, SUP.DIC_COMPLEMENTARY_DATA_ID)
                   ) DIC_COMPLEMENTARY_DATA_ID
        into dmtCreateFootMat
           , dmtRecalcFootMat
           , dmtDocumentDate
           , dmtRateOfExchange
           , dmtBasePrice
           , cAdminDomain
           , gasWeighingMgm
           , gasWeightMat
           , thirdWeighingMgnt
           , cThirdMaterialRelationType
           , cMaterialMgntMode
           , nAdvMaterialMgnt
           , dicFreeCode1ID
           , dicComplementaryDataID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.GAS_WEIGHT_MAT = 1
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and PER.PAC_PERSON_ID(+) = DMT.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if bStop then
      return;
    end if;

    -- Vérifie si le document courant possède au moins une position déchargée
    begin
      -- Recherche la présence de matière position sur la position source.
      select count(1)
        into vCountAlloy
        from DOC_POSITION_ALLOY DOA
       where DOA.DOC_DOCUMENT_ID in(
               select PDE_SRC.DOC_DOCUMENT_ID
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION_DETAIL PDE_SRC
                    , DOC_GAUGE_STRUCTURED GAS_SRC
                where PDE.DOC_DOCUMENT_ID = aDocumentID
                  and not exists(select 1
                                   from doc_foot_alloy dfa
                                  where DFA.GCO_ALLOY_ID is not null
                                    and DFA.DOC_FOOT_ID = aDocumentID)
                  and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                  and GAS_SRC.DOC_GAUGE_ID = PDE_SRC.DOC_GAUGE_ID
                  and GAS_SRC.GAS_WEIGHT_MAT = 1);

      -- Aucune matière position sur la position source indique une création des matières pieds sans aucune
      -- reprise des données de la source.
      bDischarge  :=(vCountAlloy > 0);
    exception
      when others then
        bDischarge  := false;
    end;

    if (dmtCreateFootMat = 1) then
      ----
      -- Génération (création ou modification) des matières pieds de type alliage
      --
      GenerateFootMatAlloyType(aDocumentID
                             , dmtDocumentDate
                             , dmtRateOfExchange
                             , dmtBasePrice
                             , cAdminDomain
                             , cThirdMaterialRelationType
                             , cMaterialMgntMode
                             , nAdvMaterialMgnt
                             , dicFreeCode1ID
                             , dicComplementaryDataID
                             , datToExclude
                             , bDischarge
                              );
      ----
      -- Génération (création ou modification) des matières pieds de type matière de base
      --
      GenerateFootMatBaseMatType(aDocumentID
                               , dmtDocumentDate
                               , dmtRateOfExchange
                               , dmtBasePrice
                               , cAdminDomain
                               , cThirdMaterialRelationType
                               , cMaterialMgntMode
                               , nAdvMaterialMgnt
                               , dicFreeCode1ID
                               , dicComplementaryDataID
                               , datToExclude
                               , bDischarge
                                );

      -- Mise à jour de l'indicateur de création des Matières pied
      update DOC_DOCUMENT
         set DMT_CREATE_FOOT_MAT = 2
           , DMT_RECALC_FOOT_MAT = 0
       where DOC_DOCUMENT_ID = aDocumentID;
    elsif     (dmtCreateFootMat = 2)
          and (dmtRecalcFootMat = 1) then
      -- Recalcul matières pied
      ----
      -- Génération (création ou modification) des matières pieds de type alliage
      --
      GenerateFootMatAlloyType(aDocumentID
                             , dmtDocumentDate
                             , dmtRateOfExchange
                             , dmtBasePrice
                             , cAdminDomain
                             , cThirdMaterialRelationType
                             , cMaterialMgntMode
                             , nAdvMaterialMgnt
                             , dicFreeCode1ID
                             , dicComplementaryDataID
                             , datToExclude
                             , bDischarge
                              );
      ----
      -- Supprime les matières pied qui sont liées à un alliage qui ne figure plus dans les matières positions
      --
      DeleteFootMatAlloyType(aDocumentID, bDischarge);
      ----
      -- Génération (création ou modification) des matières pieds de type matière de base
      --
      GenerateFootMatBaseMatType(aDocumentID
                               , dmtDocumentDate
                               , dmtRateOfExchange
                               , dmtBasePrice
                               , cAdminDomain
                               , cThirdMaterialRelationType
                               , cMaterialMgntMode
                               , nAdvMaterialMgnt
                               , dicFreeCode1ID
                               , dicComplementaryDataID
                               , datToExclude
                               , bDischarge
                                );
      ----
      -- Supprime les matières pied qui sont liées à une matière de base qui ne figure plus dans les matières positions.
      --
      --
      DeleteFootMatBaseMatType(aDocumentID, bDischarge);

      ----
      -- Mise à jour de l'indicateur de création des Matières pied
      --
      update DOC_DOCUMENT
         set DMT_CREATE_FOOT_MAT = 2
           , DMT_RECALC_FOOT_MAT = 0
       where DOC_DOCUMENT_ID = aDocumentID;
    end if;
  end GenerateFootMat;

  /**
  * Description
  *    Génération (création ou modification) des matières pieds de type alliage
  */
  procedure GenerateFootMatAlloyType(
    aDocumentID                       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocumentDate                     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aRateOfExchange                   DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice                        DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAdminDomain                      DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdMaterialRelationType        PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type
  , aMaterialMgntMode                 PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAdvMaterialMgnt                  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aDicFreeCode1ID                   DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDicComplementaryDataID           DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  , aDateToExclude             in out DOC_FOOT_ALLOY.A_DATECRE%type
  , aDischarge                        boolean
  )
  is
    cursor crAllPositionMatAlloyType(cDocumentID number)
    is
      select   DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.GCO_ALLOY_ID is not null
      group by DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE;

    bFounded            boolean;
    dfaAlloyFootAlloyID DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type;
  begin
    -- Pour chaque ensemble de matières position de même alliage
    for tplAllPositionMatAlloyType in crAllPositionMatAlloyType(aDocumentID) loop
      -- Vérifie l'existance d'une matière pied pour l'alliage courant à une date donnée
      select max(DFA.DOC_FOOT_ALLOY_ID)
        into dfaAlloyFootAlloyID
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = aDocumentID
         and nvl(tplAllPositionMatAlloyType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and DFA.GCO_ALLOY_ID = tplAllPositionMatAlloyType.GCO_ALLOY_ID;

      if dfaAlloyFootAlloyID is null then
        if aDischarge then
          ----
          -- Création Déchage Matière Pied de type Alliage
          --
          DischargeFootMatAlloyType(aDocumentID, aDateToExclude);
        else
          ----
          -- Création Matière Pied de type Alliage
          --
          CreateFootMatAlloyType(aDocumentID
                               , tplAllPositionMatAlloyType.GCO_ALLOY_ID
                               , tplAllPositionMatAlloyType.DOA_RATE_DATE
                               , aDocumentDate
                               , aRateOfExchange
                               , aBasePrice
                               , aAdminDomain
                               , aThirdMaterialRelationType
                               , aMaterialMgntMode
                               , aAdvMaterialMgnt
                               , aDicFreeCode1ID
                               , aDicComplementaryDataID
                               , aDateToExclude
                                );
        end if;
      else
        ----
        -- Re-calcul Matière Pied de type Alliage
        --
        RecalcFootMatAlloyType(aDocumentID
                             , tplAllPositionMatAlloyType.GCO_ALLOY_ID
                             , tplAllPositionMatAlloyType.DOA_RATE_DATE
                             , aAdvMaterialMgnt
                             , aMaterialMgntMode
                             , aDateToExclude
                             , aDischarge
                              );
      end if;
    end loop;
  end GenerateFootMatAlloyType;

  /**
  * Description
  *    Génération (création ou modification) des matières pieds de type matière de base
  */
  procedure GenerateFootMatBaseMatType(
    aDocumentID                       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocumentDate                     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aRateOfExchange                   DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice                        DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAdminDomain                      DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdMaterialRelationType        PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type
  , aMaterialMgntMode                 PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAdvMaterialMgnt                  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aDicFreeCode1ID                   DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDicComplementaryDataID           DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  , aDateToExclude             in out DOC_FOOT_ALLOY.A_DATECRE%type
  , aDischarge                        boolean
  )
  is
    cursor crAllPositionMatBaseMatType(cDocumentID number)
    is
      select   DISTINCT DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.DIC_BASIS_MATERIAL_ID is not null
      group by DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE;

    bFounded              boolean;
    dfaBaseMatFootAlloyID DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type;
    dmtDocumentID         DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Pour chaque ensemble de matières position de même matière de base
    for tplAllPositionMatBaseMatType in crAllPositionMatBaseMatType(aDocumentID) loop
      -- Vérifie l'existance d'une matière pied pour la matière de base courante
      select max(DFA.DOC_FOOT_ALLOY_ID)
        into dfaBaseMatFootAlloyID
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = aDocumentID
         and nvl(tplAllPositionMatBaseMatType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) =
                                                                                                    nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and DFA.DIC_BASIS_MATERIAL_ID = tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID;

      if dfaBaseMatFootAlloyID is null then
        if aDischarge then
          ----
          -- Création Déchage Matière Pied de type Matière de base
          --
          DischargeFootMatBaseMatType(aDocumentID, aDateToExclude);
        else
          ----
          -- Création Matière Pied de type Matière de base
          --
          CreateFootMatBaseMatType(aDocumentID
                                 , tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID
                                 , tplAllPositionMatBaseMatType.DOA_RATE_DATE
                                 , aDocumentDate
                                 , aRateOfExchange
                                 , aBasePrice
                                 , aAdminDomain
                                 , aThirdMaterialRelationType
                                 , aMaterialMgntMode
                                 , aAdvMaterialMgnt
                                 , aDicFreeCode1ID
                                 , aDicComplementaryDataID
                                 , aDateToExclude
                                  );
        end if;
      else
        ----
        -- Re-calcul Matière Pied de type Matière de base
        --
        RecalcFootMatBaseMatType(aDocumentID
                               , tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID
                               , tplAllPositionMatBaseMatType.DOA_RATE_DATE
                               , aAdvMaterialMgnt
                               , aMaterialMgntMode
                               , aDateToExclude
                               , aDischarge
                                );
      end if;
    end loop;
  end GenerateFootMatBaseMatType;

  /**
  * Description
  *    Processus Création Matière Pied de type Alliage
  */
  procedure CreateFootMatAlloyType(
    aDocumentID                       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAlloyID                          GCO_ALLOY.GCO_ALLOY_ID%type
  , aRateDate                         DOC_POSITION_ALLOY.DOA_RATE_DATE%type
  , aDocumentDate                     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aRateOfExchange                   DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice                        DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAdminDomain                      DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdMaterialRelationType        PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type
  , aMaterialMgntMode                 PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAdvMaterialMgnt                  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aDicFreeCode1ID                   DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDicComplementaryDataID           DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  , aDateToExclude             in out DOC_FOOT_ALLOY.A_DATECRE%type
  )
  is
    cursor crAllPositionMatAlloyType(cDocumentID number, cAlloyID number, cRateDate DOC_POSITION_ALLOY.DOA_RATE_DATE%type)
    is
      select   DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID
             , nvl(sum(DOA.DOA_WEIGHT), 0) DOA_WEIGHT
             , nvl(sum(DOA.DOA_WEIGHT_MAT), 0) DOA_WEIGHT_MAT
             , nvl(sum(DOA.DOA_STONE_NUM), 0) DOA_STONE_NUM
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY_TH), 0) DOA_WEIGHT_DELIVERY_TH
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY), 0) DOA_WEIGHT_DELIVERY
             , nvl(sum(DOA.DOA_LOSS_TH), 0) DOA_LOSS_TH
             , nvl(sum(DOA.DOA_LOSS), 0) DOA_LOSS
             , nvl(sum(DOA.DOA_WEIGHT_INVEST_TH), 0) DOA_WEIGHT_INVEST_TH
             , nvl(sum(DOA.DOA_WEIGHT_INVEST), 0) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.GCO_ALLOY_ID = cAlloyID
           and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(cRateDate, to_date('31.12.2999', 'DD.MM.YYYY') )
      group by DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID;

    bFounded        boolean;
    dfaRateTH       DOC_FOOT_ALLOY.DFA_RATE_TH%type;
    dfaRate         DOC_FOOT_ALLOY.DFA_RATE%type;
    dfaAmountTH     DOC_FOOT_ALLOY.DFA_AMOUNT_TH%type;
    dfaAmount       DOC_FOOT_ALLOY.DFA_AMOUNT%type;
    dicTypeRateID   GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type;
    cMustAdvance    DOC_FOOT_ALLOY.C_MUST_ADVANCE%type;
    nbAdvance       number;
    bStop           boolean;
    docMetalAccount PCS.PC_CBASE.CBACNAME%type;
    metalAccount    PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    stockID         STM_STOCK.STM_STOCK_ID%type;
    thirdStockID    STM_STOCK.STM_STOCK_ID%type;
    defaultStockID  STM_STOCK.STM_STOCK_ID%type;
    thirdID         DOC_DOCUMENT.PAC_THIRD_ID%type;
    thaManaged      PAC_THIRD_ALLOY.THA_MANAGED%type;
  begin
    aDateToExclude  := nvl(aDateToExclude, sysdate);
    bStop           := false;

    if PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') = '1' then
      begin
        select decode(GAU.C_ADMIN_DOMAIN, '1', SUP.STM_STOCK_ID, '2', CUS.STM_STOCK_ID, '5', SUP.STM_STOCK_ID, nvl(CUS.STM_STOCK_ID, SUP.STM_STOCK_ID) )
                                                                                                                                                    THIRD_STOCK
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                    , '2', nvl(CUS.CUS_METAL_ACCOUNT, 0)
                    , '5', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                    , nvl(CUS.CUS_METAL_ACCOUNT, nvl(SUP.CRE_METAL_ACCOUNT, 0) )
                     ) METAL_ACCOUNT
             , DMT.PAC_THIRD_ID
          into thirdStockID
             , metalAccount
             , thirdID
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
    end if;

    if not bStop then
      -- Recherche le compte poids par défaut
      begin
        select STO.STM_STOCK_ID DEFAULT_STOCK
          into defaultStockID
          from STM_STOCK STO
         where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
           and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
      exception
        when no_data_found then
          defaultStockID  := null;
      end;

      -- Pour chaque ensemble de matières position de même alliage
      for tplAllPositionMatAlloyType in crAllPositionMatAlloyType(aDocumentID, aAlloyID, aRateDate) loop
        -- Si le mode de gestion des matières est Alliage
        GetRates(aDocumentID
               , tplAllPositionMatAlloyType.GCO_ALLOY_ID
               , null
               , nvl(tplAllPositionMatAlloyType.DOA_RATE_DATE, aDocumentDate)
               , aRateOfExchange
               , aBasePrice
               , aAdminDomain
               , aThirdMaterialRelationType
               , aMaterialMgntMode
               , aAdvMaterialMgnt
               , aDicFreeCode1ID
               , aDicComplementaryDataID
               , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
               , tplAllPositionMatAlloyType.DOA_LOSS
               , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
               , dfaRateTH
               , dfaAmountTH
               , dfaRate
               , dfaAmount
                );

        -- Si le mode de gestion des matières est Matière de base
        if (aMaterialMgntMode = 2) then
          dfaAmountTH  := null;
          dfaAmount    := null;
        end if;

        select count(DOC_ALLOY_ADVANCE_ID)
          into nbAdvance
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION_DETAIL PDE_SRC
             , DOC_ALLOY_ADVANCE DAA
         where PDE.DOC_DOCUMENT_ID = aDocumentID
           and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and DAA.DOC_DOC_DOCUMENT_ID = PDE_SRC.DOC_DOCUMENT_ID;

        -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
        thaManaged  := 0;

        begin
          if aAdminDomain = '1'
            or aAdminDomain = '5' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_SUPPLIER_PARTNER_ID = thirdID
               and aMaterialMgntMode = '1'
               and THA.GCO_ALLOY_ID = tplAllPositionMatAlloyType.GCO_ALLOY_ID;
          elsif aAdminDomain = '2' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_CUSTOM_PARTNER_ID = thirdID
               and aMaterialMgntMode = '1'
               and THA.GCO_ALLOY_ID = tplAllPositionMatAlloyType.GCO_ALLOY_ID;
          else
            thaManaged  := 1;
          end if;
        exception
          when no_data_found then
            -- Si aucune matière/alliage n'est trouvée pour le tiers, le code de gestion est inactif.
            thaManaged  := null;
        end;

        -- Si gestion des avances et mode de gestion des matières en Alliages et document dont le père (s'il existe)
        -- n'a pas généré d'avance et que la matière/alliage est gérée sur le tiers.
        if     (aAdvMaterialMgnt = 1)
           and (metalAccount = 0)
           and (aMaterialMgntMode = 1)
           and (nbAdvance = 0)
           and (thaManaged = 1) then
          cMustAdvance  := '01';   -- Avance à décompter
        else
          cMustAdvance  := '03';   -- Avance non gérée
        end if;

        -- Définission du compte poids en fonction du code de gestion de la matière/alliage et du type de relation tiers.
        -- C'est toujours le compte poids par défaut sauf dans le cas ou la matière/alliage est gérée et que le type
        -- de relation tiers est Facturé, dans ce cas, c'est le compte poids du tiers qui est initialisé.
        -- Si la matière n'est pas présente sur le tiers, ne pas initialiser le compte poids (aucun mvt généré)
        if (thaManaged is null) then
          stockID  := null;
        elsif     (thaManaged = 1)
              and (aThirdMaterialRelationType <> '1') then
          stockID  := thirdStockID;
        else
          stockID  := defaultStockID;
        end if;

        insert into DOC_FOOT_ALLOY DFA
                    (DFA.DOC_FOOT_ALLOY_ID
                   , DFA.DOC_FOOT_ID
                   , DFA.GCO_ALLOY_ID
                   , DFA.DIC_BASIS_MATERIAL_ID
                   , DFA.DFA_WEIGHT
                   , DFA.DFA_WEIGHT_MAT
                   , DFA.DFA_STONE_NUM
                   , DFA.DFA_WEIGHT_DELIVERY_TH
                   , DFA.DFA_WEIGHT_DELIVERY
                   , DFA.DFA_WEIGHT_DIF
                   , DFA.DFA_LOSS_TH
                   , DFA.DFA_LOSS
                   , DFA.DFA_WEIGHT_INVEST_TH
                   , DFA.DFA_WEIGHT_INVEST
                   , DFA.DFA_RATE_TH
                   , DFA.DFA_AMOUNT_TH
                   , DFA.DFA_RATE
                   , DFA.DFA_BASE_COST
                   , DFA.DFA_AMOUNT
                   , DFA.DFA_COMMENT
                   , DFA.DIC_COST_FOOT_ID
                   , DFA.C_MUST_ADVANCE
                   , DFA.C_SHARING_MODE
                   , DFA.STM_STOCK_ID
                   , DFA.DFA_RATE_DATE
                   , DFA.A_DATECRE
                   , DFA.A_IDCRE
                    )
          select INIT_ID_SEQ.nextval   -- DOC_FOOT_ALLOY_ID
               , aDocumentID   -- DOC_FOOT_ID
               , tplAllPositionMatAlloyType.GCO_ALLOY_ID   -- GCO_ALLOY_ID
               , null   -- DIC_BASIS_MATERIAL_ID
               , tplAllPositionMatAlloyType.DOA_WEIGHT   -- DFA_WEIGHT
               , tplAllPositionMatAlloyType.DOA_WEIGHT_MAT   -- DFA_WEIGHT_MAT
               , tplAllPositionMatAlloyType.DOA_STONE_NUM   -- DFA_STONE_NUM
               , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH   -- DFA_WEIGHT_DELIVERY_TH
               , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY   -- DFA_WEIGHT_DELIVERY
               , decode(tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                      , 0, 0
                      , (tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY) *
                        100 /
                        tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                       )   -- DFA_WEIGHT_DIF
               , tplAllPositionMatAlloyType.DOA_LOSS_TH   -- DFA_LOSS_TH
               , tplAllPositionMatAlloyType.DOA_LOSS   -- DFA_LOSS
               , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST_TH   -- DFA_WEIGHT_INVEST_TH
               , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST   -- DFA_WEIGHT_INVEST
               , dfaRateTH   -- DFA_RATE_TH
               , dfaAmountTH   -- DFA_AMOUNT_TH
               , dfaRate   -- DFA_RATE
               , 1   -- DFA_BASE_COST
               , dfaAmount   -- DFA_AMOUNT
               , null   -- DFA_COMMENT
               , null   -- DIC_COST_FOOT_ID
               , cMustAdvance   -- C_MUST_ADVANCE
               , '05'   -- C_SHARING_MODE
               , decode(metalAccount, 1, nvl(tplAllPositionMatAlloyType.STM_STOCK_ID, stockID), null)   -- STM_STOCK_ID
               , tplAllPositionMatAlloyType.DOA_RATE_DATE   -- DFA_RATE_DATE
               , aDateToExclude   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
            from dual;
      end loop;
    end if;
  end CreateFootMatAlloyType;

  /**
  * Description
  *    Processus Création Matière Pied de type Matière de base
  */
  procedure CreateFootMatBaseMatType(
    aDocumentID                       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aBasisMaterialID                  DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aRateDate                         DOC_POSITION_ALLOY.DOA_RATE_DATE%type
  , aDocumentDate                     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aRateOfExchange                   DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice                        DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAdminDomain                      DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdMaterialRelationType        PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type
  , aMaterialMgntMode                 PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAdvMaterialMgnt                  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aDicFreeCode1ID                   DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDicComplementaryDataID           DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  , aDateToExclude             in out DOC_FOOT_ALLOY.A_DATECRE%type
  )
  is
    cursor crAllPositionMatBaseMatType(
      cDocumentID      number
    , cBasisMaterialID DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
    , cRateDate        DOC_POSITION_ALLOY.DOA_RATE_DATE%type
    )
    is
      select   DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID
             , sum(nvl(DOA.DOA_WEIGHT, 0) ) DOA_WEIGHT
             , sum(nvl(DOA.DOA_WEIGHT_MAT, 0) ) DOA_WEIGHT_MAT
             , sum(nvl(DOA.DOA_STONE_NUM, 0) ) DOA_STONE_NUM
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) ) DOA_WEIGHT_DELIVERY_TH
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) ) DOA_WEIGHT_DELIVERY
             , sum(nvl(DOA.DOA_LOSS_TH, 0) ) DOA_LOSS_TH
             , sum(nvl(DOA.DOA_LOSS, 0) ) DOA_LOSS
             , sum(nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) ) DOA_WEIGHT_INVEST_TH
             , sum(nvl(DOA.DOA_WEIGHT_INVEST, 0) ) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.DIC_BASIS_MATERIAL_ID = cBasisMaterialID
           and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(cRateDate, to_date('31.12.2999', 'DD.MM.YYYY') )
      group by DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID;

    bFounded        boolean;
    dfaRateTH       DOC_FOOT_ALLOY.DFA_RATE_TH%type;
    dfaRate         DOC_FOOT_ALLOY.DFA_RATE%type;
    dfaAmountTH     DOC_FOOT_ALLOY.DFA_AMOUNT_TH%type;
    dfaAmount       DOC_FOOT_ALLOY.DFA_AMOUNT%type;
    dicTypeRateID   GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type;
    cMustAdvance    DOC_FOOT_ALLOY.C_MUST_ADVANCE%type;
    nbAdvance       number;
    bStop           boolean;
    docMetalAccount PCS.PC_CBASE.CBACNAME%type;
    metalAccount    PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    stockID         STM_STOCK.STM_STOCK_ID%type;
    thirdStockID    STM_STOCK.STM_STOCK_ID%type;
    defaultStockID  STM_STOCK.STM_STOCK_ID%type;
    thirdID         DOC_DOCUMENT.PAC_THIRD_ID%type;
    thaManaged      PAC_THIRD_ALLOY.THA_MANAGED%type;
  begin
    aDateToExclude  := nvl(aDateToExclude, sysdate);
    bStop           := false;

    if PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') = '1' then
      begin
        select decode(GAU.C_ADMIN_DOMAIN, '1', SUP.STM_STOCK_ID, '2', CUS.STM_STOCK_ID, '5', SUP.STM_STOCK_ID, nvl(CUS.STM_STOCK_ID, SUP.STM_STOCK_ID) )
                                                                                                                                                    THIRD_STOCK
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                    , '2', nvl(CUS.CUS_METAL_ACCOUNT, 0)
                    , '5', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                    , nvl(CUS.CUS_METAL_ACCOUNT, nvl(SUP.CRE_METAL_ACCOUNT, 0) )
                     ) METAL_ACCOUNT
             , DMT.PAC_THIRD_ID
          into thirdStockID
             , metalAccount
             , thirdID
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
    end if;

    if not bStop then
      -- Recherche le compte poids par défaut
      begin
        select STO.STM_STOCK_ID DEFAULT_STOCK
          into defaultStockID
          from STM_STOCK STO
         where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
           and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
      exception
        when no_data_found then
          defaultStockID  := null;
      end;

      -- Pour chaque ensemble de matières position de même matière de base
      for tplAllPositionMatBaseMatType in crAllPositionMatBaseMatType(aDocumentID, aBasisMaterialID, aRateDate) loop
        GetRates(aDocumentID
               , null
               , tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID
               , nvl(tplAllPositionMatBaseMatType.DOA_RATE_DATE, aDocumentDate)
               , aRateOfExchange
               , aBasePrice
               , aAdminDomain
               , aThirdMaterialRelationType
               , aMaterialMgntMode
               , aAdvMaterialMgnt
               , aDicFreeCode1ID
               , aDicComplementaryDataID
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
               , tplAllPositionMatBaseMatType.DOA_LOSS
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
               , dfaRateTH
               , dfaAmountTH
               , dfaRate
               , dfaAmount
                );

        -- Si le mode de gestion des matières est alliage
        if (aMaterialMgntMode = 1) then
          dfaAmountTH  := null;
          dfaAmount    := null;
        end if;

        select count(DOC_ALLOY_ADVANCE_ID)
          into nbAdvance
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION_DETAIL PDE_SRC
             , DOC_ALLOY_ADVANCE DAA
         where PDE.DOC_DOCUMENT_ID = aDocumentID
           and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and DAA.DOC_DOC_DOCUMENT_ID = PDE_SRC.DOC_DOCUMENT_ID;

        -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
        thaManaged  := 0;

        begin
          if aAdminDomain = '1'
            or aAdminDomain = '5' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_SUPPLIER_PARTNER_ID = thirdID
               and aMaterialMgntMode = '2'
               and THA.DIC_BASIS_MATERIAL_ID = tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID;
          elsif aAdminDomain = '2' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_CUSTOM_PARTNER_ID = thirdID
               and aMaterialMgntMode = '2'
               and THA.DIC_BASIS_MATERIAL_ID = tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID;
          else
            thaManaged  := 1;
          end if;
        exception
          when no_data_found then
            -- Si aucune matière/alliage n'est trouvée pour le tiers, le code de gestion est inactif.
            thaManaged  := null;
        end;

        -- Si gestion des avances et mode de gestion des matières en Matière de base et document dont le père (s'il existe)
        -- n'a pas généré d'avance et que la matière/alliage est gérée sur le tiers.
        if     (aAdvMaterialMgnt = 1)
           and (metalAccount = 0)
           and (aMaterialMgntMode = 2)
           and (nbAdvance = 0)
           and (thaManaged = 1) then
          cMustAdvance  := '01';   -- Avance à décompter
        else
          cMustAdvance  := '03';   -- Avance non gérée
        end if;

        -- Définission du compte poids en fonction du code de gestion de la matière/alliage et du type de relation tiers.
        -- C'est toujours le compte poids par défaut sauf dans le cas ou la matière/alliage est gérée et que le type
        -- de relation tiers est différent de Facturé, dans ce cas, c'est le compte poids du tiers qui est initialisé.
        -- Si la matière n'est pas présente sur le tiers, ne pas initialiser le compte poids (aucun mvt généré)
        if (thaManaged is null) then
          stockID  := null;
        elsif     (thaManaged = 1)
              and (aThirdMaterialRelationType <> '1') then
          stockID  := thirdStockID;
        else
          stockID  := defaultStockID;
        end if;

        insert into DOC_FOOT_ALLOY DFA
                    (DFA.DOC_FOOT_ALLOY_ID
                   , DFA.DOC_FOOT_ID
                   , DFA.GCO_ALLOY_ID
                   , DFA.DIC_BASIS_MATERIAL_ID
                   , DFA.DFA_WEIGHT
                   , DFA.DFA_WEIGHT_MAT
                   , DFA.DFA_STONE_NUM
                   , DFA.DFA_WEIGHT_DELIVERY_TH
                   , DFA.DFA_WEIGHT_DELIVERY
                   , DFA.DFA_WEIGHT_DIF
                   , DFA.DFA_LOSS_TH
                   , DFA.DFA_LOSS
                   , DFA.DFA_WEIGHT_INVEST_TH
                   , DFA.DFA_WEIGHT_INVEST
                   , DFA.DFA_RATE_TH
                   , DFA.DFA_AMOUNT_TH
                   , DFA.DFA_RATE
                   , DFA.DFA_BASE_COST
                   , DFA.DFA_AMOUNT
                   , DFA.DFA_COMMENT
                   , DIC_COST_FOOT_ID
                   , DFA.C_MUST_ADVANCE
                   , DFA.C_SHARING_MODE
                   , DFA.STM_STOCK_ID
                   , DFA.DFA_RATE_DATE
                   , DFA.A_DATECRE
                   , DFA.A_IDCRE
                    )
          select INIT_ID_SEQ.nextval   -- DOC_FOOT_ALLOY_ID
               , aDocumentID   -- DOC_FOOT_ID
               , null   -- GCO_ALLOY_ID
               , tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID   -- DIC_BASIS_MATERIAL_ID
               , tplAllPositionMatBaseMatType.DOA_WEIGHT   -- DFA_WEIGHT
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_MAT   -- DFA_WEIGHT_MAT
               , tplAllPositionMatBaseMatType.DOA_STONE_NUM   -- DFA_STONE_NUM
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH   -- DFA_WEIGHT_DELIVERY_TH
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY   -- DFA_WEIGHT_DELIVERY
               , decode(tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                      , 0, 0
                      , (tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY) *
                        100 /
                        tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                       )   -- DFA_WEIGHT_DIF
               , tplAllPositionMatBaseMatType.DOA_LOSS_TH   -- DFA_LOSS_TH
               , tplAllPositionMatBaseMatType.DOA_LOSS   -- DFA_LOSS
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST_TH   -- DFA_WEIGHT_INVEST_TH
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST   -- DFA_WEIGHT_INVEST
               , dfaRateTH   -- DFA_RATE_TH
               , dfaAmountTH   -- DFA_AMOUNT_TH
               , dfaRate   -- DFA_RATE
               , 1   -- DFA_BASE_COST
               , dfaAmount   -- DFA_AMOUNT
               , null   -- DFA_COMMENT
               , null   -- DIC_COST_FOOT_ID
               , cMustAdvance   -- C_MUST_ADVANCE
               , '05'   -- C_SHARING_MODE
               , decode(metalAccount, 1, nvl(tplAllPositionMatBaseMatType.STM_STOCK_ID, stockID), null)   -- STM_STOCK_ID
               , tplAllPositionMatBaseMatType.DOA_RATE_DATE   -- DFA_RATE_DATE
               , aDateToExclude   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
            from dual;
      end loop;
    end if;
  end CreateFootMatBaseMatType;

  /**
  * Description
  *    Processus Re-calcul Matière Pied de type Alliage
  */
  procedure RecalcFootMatAlloyType(
    aDocumentID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAlloyID          GCO_ALLOY.GCO_ALLOY_ID%type
  , aRateDate         DOC_POSITION_ALLOY.DOA_RATE_DATE%type
  , aAdvMaterialMgnt  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aMaterialMgntMode PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aDateToExclude    DOC_FOOT_ALLOY.A_DATECRE%type
  , aDischarge        boolean
  )
  is
    cursor crAllPositionMatAlloyType(cDocumentID number, cAlloyID GCO_ALLOY.GCO_ALLOY_ID%type, cRateDate DOC_POSITION_ALLOY.DOA_RATE_DATE%type)
    is
      select   DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
             , sum(nvl(DOA.DOA_WEIGHT, 0) ) DOA_WEIGHT
             , sum(nvl(DOA.DOA_WEIGHT_MAT, 0) ) DOA_WEIGHT_MAT
             , sum(nvl(DOA.DOA_STONE_NUM, 0) ) DOA_STONE_NUM
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) ) DOA_WEIGHT_DELIVERY_TH
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) ) DOA_WEIGHT_DELIVERY
             , sum(nvl(DOA.DOA_LOSS_TH, 0) ) DOA_LOSS_TH
             , sum(nvl(DOA.DOA_LOSS, 0) ) DOA_LOSS
             , sum(nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) ) DOA_WEIGHT_INVEST_TH
             , sum(nvl(DOA.DOA_WEIGHT_INVEST, 0) ) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.GCO_ALLOY_ID = cAlloyID
           and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(cRateDate, to_date('31.12.2999', 'DD.MM.YYYY') )
      group by DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE;

    cMustAdvance DOC_FOOT_ALLOY.C_MUST_ADVANCE%type;
  begin
    -- Pour chaque ensemble de matières position de même alliage
    for tplAllPositionMatAlloyType in crAllPositionMatAlloyType(aDocumentID, aAlloyID, aRateDate) loop
      -- Si lien de décharge, les avances ne sont pas gérées.
      if aDischarge then
        cMustAdvance  := '03';   -- Avance non gérée
      -- Si gestion des avances et mode de gestion des matières en Alliages
      elsif     (aAdvMaterialMgnt = 1)
            and (aMaterialMgntMode = 1) then
        cMustAdvance  := '01';   -- Avance à décompter
      else
        cMustAdvance  := '03';   -- Avance non gérée
      end if;

      update DOC_FOOT_ALLOY DFA
         set DFA.DFA_WEIGHT = tplAllPositionMatAlloyType.DOA_WEIGHT
           , DFA.DFA_WEIGHT_MAT = tplAllPositionMatAlloyType.DOA_WEIGHT_MAT
           , DFA.DFA_STONE_NUM = tplAllPositionMatAlloyType.DOA_STONE_NUM
           , DFA.DFA_WEIGHT_DELIVERY_TH = tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
           , DFA.DFA_WEIGHT_DELIVERY = tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
           , DFA.DFA_WEIGHT_DIF =
               decode(tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                    , 0, 0
                    , (tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY) *
                      100 /
                      tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                     )
           , DFA.DFA_LOSS_TH = tplAllPositionMatAlloyType.DOA_LOSS_TH
           , DFA.DFA_LOSS = tplAllPositionMatAlloyType.DOA_LOSS
           , DFA.DFA_WEIGHT_INVEST_TH = tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST_TH
           , DFA.DFA_WEIGHT_INVEST = tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
           , DFA.DFA_AMOUNT_TH =
               GetAdvanceWeight(aDocumentID
                              , null
                              , null
                              , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
                              , tplAllPositionMatAlloyType.DOA_LOSS
                              , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
                               ) *
               DFA.DFA_RATE_TH
           , DFA.DFA_AMOUNT =
               GetAdvanceWeight(aDocumentID
                              , null
                              , null
                              , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
                              , tplAllPositionMatAlloyType.DOA_LOSS
                              , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
                               ) *
               DFA.DFA_RATE
           , DFA.C_MUST_ADVANCE = cMustAdvance
           , DFA.A_DATEMOD = sysdate
           , DFA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DFA.DOC_FOOT_ID = aDocumentID
         and nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(tplAllPositionMatAlloyType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and DFA.GCO_ALLOY_ID = tplAllPositionMatAlloyType.GCO_ALLOY_ID;
    end loop;
  end RecalcFootMatAlloyType;

  /**
  * Description
  *    Processus Re-calcul Matière Pied de type Matière de base
  */
  procedure RecalcFootMatBaseMatType(
    aDocumentID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aBasisMaterialID  DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aRateDate         DOC_POSITION_ALLOY.DOA_RATE_DATE%type
  , aAdvMaterialMgnt  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aMaterialMgntMode PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aDateToExclude    DOC_FOOT_ALLOY.A_DATECRE%type
  , aDischarge        boolean
  )
  is
    cursor crAllPositionMatBaseMatType(
      cDocumentID      number
    , cBasisMaterialID DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
    , cRateDate        DOC_POSITION_ALLOY.DOA_RATE_DATE%type
    )
    is
      select   DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
             , sum(nvl(DOA.DOA_WEIGHT, 0) ) DOA_WEIGHT
             , sum(nvl(DOA.DOA_WEIGHT_MAT, 0) ) DOA_WEIGHT_MAT
             , sum(nvl(DOA.DOA_STONE_NUM, 0) ) DOA_STONE_NUM
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY_TH, 0) ) DOA_WEIGHT_DELIVERY_TH
             , sum(nvl(DOA.DOA_WEIGHT_DELIVERY, 0) ) DOA_WEIGHT_DELIVERY
             , sum(nvl(DOA.DOA_LOSS_TH, 0) ) DOA_LOSS_TH
             , sum(nvl(DOA.DOA_LOSS, 0) ) DOA_LOSS
             , sum(nvl(DOA.DOA_WEIGHT_INVEST_TH, 0) ) DOA_WEIGHT_INVEST_TH
             , sum(nvl(DOA.DOA_WEIGHT_INVEST, 0) ) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.DIC_BASIS_MATERIAL_ID = cBasisMaterialID
           and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(cRateDate, to_date('31.12.2999', 'DD.MM.YYYY') )
      group by DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE;

    cMustAdvance DOC_FOOT_ALLOY.C_MUST_ADVANCE%type;
  begin
    -- Pour chaque ensemble de matières position de même alliage
    for tplAllPositionMatBaseMatType in crAllPositionMatBaseMatType(aDocumentID, aBasisMaterialID, aRateDate) loop
      -- Si lien de décharge, les avances ne sont pas gérées.
      if aDischarge then
        cMustAdvance  := '03';   -- Avance non gérée
      -- Si gestion des avances et mode de gestion des matières en Matière de base
      elsif     (aAdvMaterialMgnt = 1)
            and (aMaterialMgntMode = 2) then
        cMustAdvance  := '01';   -- Avance à décompter
      else
        cMustAdvance  := '03';
      -- Avance non gérée
      end if;

      update DOC_FOOT_ALLOY DFA
         set DFA.DFA_WEIGHT = tplAllPositionMatBaseMatType.DOA_WEIGHT
           , DFA.DFA_WEIGHT_MAT = tplAllPositionMatBaseMatType.DOA_WEIGHT_MAT
           , DFA.DFA_STONE_NUM = tplAllPositionMatBaseMatType.DOA_STONE_NUM
           , DFA.DFA_WEIGHT_DELIVERY_TH = tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
           , DFA.DFA_WEIGHT_DELIVERY = tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
           , DFA.DFA_WEIGHT_DIF =
               decode(tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                    , 0, 0
                    , (tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY) *
                      100 /
                      tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                     )
           , DFA.DFA_LOSS_TH = tplAllPositionMatBaseMatType.DOA_LOSS_TH
           , DFA.DFA_LOSS = tplAllPositionMatBaseMatType.DOA_LOSS
           , DFA.DFA_WEIGHT_INVEST_TH = tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST_TH
           , DFA.DFA_WEIGHT_INVEST = tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
           , DFA.DFA_AMOUNT_TH =
               GetAdvanceWeight(aDocumentID
                              , null
                              , null
                              , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
                              , tplAllPositionMatBaseMatType.DOA_LOSS
                              , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
                               ) *
               DFA.DFA_RATE_TH
           , DFA.DFA_AMOUNT =
               GetAdvanceWeight(aDocumentID
                              , null
                              , null
                              , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
                              , tplAllPositionMatBaseMatType.DOA_LOSS
                              , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
                               ) *
               DFA.DFA_RATE
           , DFA.C_MUST_ADVANCE = cMustAdvance
           , DFA.A_DATEMOD = sysdate
           , DFA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DFA.DOC_FOOT_ID = aDocumentID
         and nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) =
                                                                           nvl(tplAllPositionMatBaseMatType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
         and DFA.DIC_BASIS_MATERIAL_ID = tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID;
    end loop;
  end RecalcFootMatBaseMatType;

  /**
  * Description
  *    Supprime les matières pied qui sont liées à un alliage qui ne figure plus dans les matières positions.
  *    Voir graphe Fin Position.
  */
  procedure DeleteFootMatAlloyType(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDischarge boolean)
  is
    cursor crNonExistentFootMat(cDocumentID number)
    is
      select DFA.DOC_FOOT_ALLOY_ID
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = cDocumentID
         and DFA.GCO_ALLOY_ID is not null
         and not exists(
               select DOA.DOC_POSITION_ALLOY_ID
                 from DOC_POSITION_ALLOY DOA
                where DOA.GCO_ALLOY_ID = DFA.GCO_ALLOY_ID
                  and DOA.DOC_DOCUMENT_ID = DFA.DOC_FOOT_ID
                  and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) );
  begin
    -- Pour chaque matières pied qui ne possède plus d'alliage dans les positions matières
    for tplNonExistentFootMat in crNonExistentFootMat(aDocumentID) loop
      if not aDischarge then
        -- Suppression des avances de la matière pied sans position
        delete from DOC_ALLOY_ADVANCE
              where DOC_FOOT_ALLOY_ID = tplNonExistentFootMat.DOC_FOOT_ALLOY_ID;
      end if;

      -- Suppression de la matière pied sans position
      delete from DOC_FOOT_ALLOY
            where DOC_FOOT_ALLOY_ID = tplNonExistentFootMat.DOC_FOOT_ALLOY_ID;
    end loop;
  end DeleteFootMatAlloyType;

  /**
  * Description
  *    Supprime les matières pied qui sont liées à une matière de base qui ne figure plus dans les matières positions.
  *    Voir graphe Fin Position.
  */
  procedure DeleteFootMatBaseMatType(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDischarge boolean)
  is
    cursor crNonExistentFootMat(cDocumentID number)
    is
      select DFA.DOC_FOOT_ALLOY_ID
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = cDocumentID
         and DFA.DIC_BASIS_MATERIAL_ID is not null
         and not exists(
               select DOA.DOC_POSITION_ALLOY_ID
                 from DOC_POSITION_ALLOY DOA
                where DOA.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
                  and DOA.DOC_DOCUMENT_ID = DFA.DOC_FOOT_ID
                  and nvl(DOA.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) );
  begin
    -- Pour chaque matières pied qui ne possède plus d'alliage dans les positions matières
    for tplNonExistentFootMat in crNonExistentFootMat(aDocumentID) loop
      if not aDischarge then
        -- Suppression des avances de la matière pied sans position
        delete from DOC_ALLOY_ADVANCE
              where DOC_FOOT_ALLOY_ID = tplNonExistentFootMat.DOC_FOOT_ALLOY_ID;
      end if;

      -- Suppression de la matière pied sans position
      delete from DOC_FOOT_ALLOY
            where DOC_FOOT_ALLOY_ID = tplNonExistentFootMat.DOC_FOOT_ALLOY_ID;
    end loop;
  end DeleteFootMatBaseMatType;

  /**
  * Description
  *    Test if stock quantity is enough to execute movement
  */
  function IsStockEnough(iFootAlloyId in DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type)
    return number
  is
    lRemainingQuantity number;
    lMngtMode          PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    lnMetalAccount     DOC_FOOT_ALLOY.STM_STOCK_ID%type;
    lideficitControl   integer;
  begin
    -- Recherche le compte poids lié à la matière pied
    select max(STM_STOCK_ID)
      into lnMetalAccount
      from DOC_FOOT_ALLOY DFA
     where DFA.DOC_FOOT_ALLOY_ID = iFootAlloyId;

    -- Contrôle uniquement les matières pieds qui possèdent un compte poids
    if (lnMetalAccount is not null) then
      select decode(GAU.C_ADMIN_DOMAIN
                  , 1, SUP.C_MATERIAL_MGNT_MODE
                  , 2, CUS.C_MATERIAL_MGNT_MODE
                  , 5, SUP.C_MATERIAL_MGNT_MODE
                  , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                   ) C_MATERIAL_MGNT_MODE
        into lMngtMode
        from DOC_FOOT_ALLOY DFA
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where DFA.DOC_FOOT_ALLOY_ID = iFootAlloyId
         and DMT.DOC_DOCUMENT_ID = DFA.DOC_FOOT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;

      begin
        select   STM_FUNCTIONS.GetRealStockQuantity(GAL.GCO_GOOD_ID
                                                  , null
                                                  , (select LOC.STM_LOCATION_ID
                                                       from STM_LOCATION LOC
                                                      where LOC.STM_STOCK_ID = DFA.STM_STOCK_ID
                                                        and LOC.LOC_CLASSIFICATION = (select min(LOC2.LOC_CLASSIFICATION)
                                                                                        from STM_LOCATION LOC2
                                                                                       where LOC2.STM_STOCK_ID = DFA.STM_STOCK_ID) )
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                  , null
                                                   ) -
                 DOC_FOOT_ALLOY_FUNCTIONS.GetAdvanceWeight(DFA.DOC_FOOT_ID, null, null, DFA.DFA_WEIGHT_DELIVERY, DFA.DFA_LOSS, DFA.DFA_WEIGHT_INVEST) DELTA
               , DOC_I_LIB_ALLOY.StockDeficitControl(DFA.STM_STOCK_ID
                                                   , decode(lMngtMode
                                                          , '1', GAL.GCO_GOOD_ID
                                                          , '2', (select GCO_GOOD_ID
                                                                    from GCO_ALLOY GAL1
                                                                   where GAL1.GCO_ALLOY_ID =
                                                                            (select max(GAC.GCO_ALLOY_ID)
                                                                               from GCO_ALLOY_COMPONENT GAC
                                                                              where GAC.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
                                                                                and GAC.GAC_RATE = 100) )
                                                           )
                                                    )
            into lRemainingQuantity
               , lideficitControl
            from DOC_FOOT_ALLOY DFA
               , STM_LOCATION LOC
               , GCO_ALLOY GAL
           where DFA.DOC_FOOT_ALLOY_ID = iFootAlloyId
             and LOC.STM_STOCK_ID = DFA.STM_STOCK_ID
             and not exists(select STM_STOCK_MOVEMENT_ID
                              from STM_STOCK_MOVEMENT
                             where DOC_FOOT_ALLOY_ID = DFA.DOC_FOOT_ALLOY_ID)
             and LOC.LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                             from STM_LOCATION
                                            where STM_STOCK_ID = LOC.STM_STOCK_ID)
             and (    (     (lMngtMode = '1')
                       and (DFA.GCO_ALLOY_ID is not null) )
                  or (     (lMngtMode = '2')
                      and (DFA.DIC_BASIS_MATERIAL_ID is not null) ) )
             and (    (    lMngtMode = '1'
                       and GAL.GCO_ALLOY_ID = DFA.GCO_ALLOY_ID)
                  or (    lMngtMode = '2'
                      and GAL.GCO_ALLOY_ID = (select max(GAC.GCO_ALLOY_ID)
                                                from GCO_ALLOY_COMPONENT GAC
                                               where GAC.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
                                                 and GAC.GAC_RATE = 100) )
                 )
        order by DFA.DOC_FOOT_ALLOY_ID;
      exception
        when no_data_found then
          return 1;
      end;

      if lRemainingQuantity >= 0 then
        return 1;
      else
        -- Dans le cas ou l'on a pas suffisament de matière, contrôle de l'autorisation de mettre le compte poids à découvert
        if lideficitControl = 0 then
          return 1;
        else
          return 0;
        end if;
      end if;
    else   -- Compte poids inexistant
      return 1;
    end if;
  end IsStockEnough;

  /**
  * Description
  *    Test le document pour savoir si toutes les informations relatives aux matières précieuses
  *    ont été saisies
  */
  procedure TestDocumentFoot(
    aDocumentID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aWeightDone    out number
  , aAmountMatOk   out number
  , aAmountAlloyOk out number
  , aAdvanceOk     out number
  , aStockOk       out number
  )
  is
    adminDomain  DOC_GAUGE.C_ADMIN_DOMAIN%type;
    gasWeightMat DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    lMngtMode    PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    -- recherche du domaine
    select GAU.C_ADMIN_DOMAIN
         , nvl(GAS.GAS_WEIGHT_MAT, 0)
      into adminDomain
         , gasWeightMat
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
     where DMT.DOC_DOCUMENT_ID = aDocumentId
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    -- si le gabarit gère les matières précieuses
    if gasWeightMat = 1 then
      -- Contrôle si toutes les pesées ont été faites
      select nvl(max(decode(DOA.DOC_POSITION_ALLOY_ID, null, 1, 0) ), 1)
        into aWeightDone
        from DOC_POSITION_ALLOY DOA
           , DOC_POSITION POS
       where DOA.DOC_DOCUMENT_ID = aDocumentId
         and POS.DOC_POSITION_ID = DOA.DOC_POSITION_ID
         and (   DOA.C_MUST_WEIGH = '01'
              or DOA.C_MUST_TYPE = '01')
         and POS.STM_MOVEMENT_KIND_ID is not null;

      -- contrôle si on est pas en rupture de stock matière précieuses
      aStockOk  := 1;

      if documentWithAlloyMovements(aDocumentID) then
        -- for each foot alloy
        for ltplFootAlloy in (select DOC_FOOT_ALLOY_ID
                                from DOC_FOOT_ALLOY
                               where DOC_FOOT_ID = aDocumentId
                                 and STM_STOCK_ID is not null) loop
          if IsStockEnough(ltplFootAlloy.DOC_FOOT_ALLOY_ID) = 0 then
            aStockOk  := 0;
          end if;
        end loop;
      end if;

      if adminDomain in('1', '5') then   -- achats
        -- Contrôle si les avances ont été décomptées
        select nvl(min(decode(DFA.C_MUST_ADVANCE, '01', 0, 1) ), 1)
             , nvl(min(decode(SUP.C_MATERIAL_MGNT_MODE
                            , '1', decode(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                                        , '1', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                        , '4', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                         )
                             )
                      )
                 , 1
                  )
             , nvl(min(decode(SUP.C_MATERIAL_MGNT_MODE
                            , '2', decode(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                                        , '1', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                        , '4', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                         )
                             )
                      )
                 , 1
                  )
          into aAdvanceOk
             , aAmountAlloyOk
             , aAmountMatOk
          from DOC_FOOT_ALLOY DFA
             , DOC_DOCUMENT DMT
             , PAC_SUPPLIER_PARTNER SUP
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = DMT.PAC_THIRD_ID
           and SUP.CRE_ADV_MATERIAL_MGNT = 1
           and (    (    SUP.C_MATERIAL_MGNT_MODE = '2'
                     and DFA.DIC_BASIS_MATERIAL_ID is not null)
                or (    SUP.C_MATERIAL_MGNT_MODE = '1'
                    and DFA.GCO_ALLOY_ID is not null) );
      elsif adminDomain = '2' then   --ventes
        -- Contrôle si les avances ont été décomptées
        select nvl(min(decode(DFA.C_MUST_ADVANCE, '01', 0, 1) ), 1)
             , nvl(min(decode(CUS.C_MATERIAL_MGNT_MODE
                            , '1', decode(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                                        , '1', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                        , '4', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                         )
                             )
                      )
                 , 1
                  )
             , nvl(min(decode(CUS.C_MATERIAL_MGNT_MODE
                            , '2', decode(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                                        , '1', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                        , '4', sign(nvl(abs(DFA.DFA_AMOUNT), 0) )
                                         )
                             )
                      )
                 , 1
                  )
          into aAdvanceOk
             , aAmountAlloyOk
             , aAmountMatOk
          from DOC_FOOT_ALLOY DFA
             , DOC_DOCUMENT DMT
             , PAC_CUSTOM_PARTNER CUS
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = DMT.PAC_THIRD_ID
           and CUS.CUS_ADV_MATERIAL_MGNT = 1
           and (    (    CUS.C_MATERIAL_MGNT_MODE = '2'
                     and DFA.DIC_BASIS_MATERIAL_ID is not null)
                or (    CUS.C_MATERIAL_MGNT_MODE = '1'
                    and DFA.GCO_ALLOY_ID is not null) );
      else
        aAdvanceOk      := 1;
        aAmountMatOk    := 1;
        aAmountAlloyOk  := 1;
      end if;
    else
      -- si les matières précieuses ne sont pas gérées, tous les test sont OK
      aWeightDone     := 1;
      aAdvanceOk      := 1;
      aAmountMatOk    := 1;
      aAmountAlloyOk  := 1;
      aStockOk        := 1;
    end if;
  end TestDocumentFoot;

  /**
  * Description
  *   procédure de génération des remises de pied relatives aux matières précieuses
  */
  procedure generatePreciousMatDiscount(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aGenerated out number)
  is
    adminDomain                  DOC_GAUGE.C_ADMIN_DOMAIN%type;
    discountName                 PCS.PC_CBASE.CBACVALUE%type;
    langId                       PCS.PC_LANG.PC_LANG_ID%type;
    dateDocument                 date;
    gaugeId                      DOC_GAUGE.DOC_GAUGE_ID%type;
    recordId                     DOC_RECORD.DOC_RECORD_ID%type;
    vPAC_THIRD_ID                PAC_THIRD.PAC_THIRD_ID%type;
    vPAC_THIRD_ACI_ID            PAC_THIRD.PAC_THIRD_ID%type;
    vPAC_THIRD_VAT_ID            PAC_THIRD.PAC_THIRD_ID%type;
    vGAS_VAT                     DOC_GAUGE_STRUCTURED.GAS_VAT%type;
    SubmissionType               DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    MovementType                 DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    vatDetAccountId              DOC_DOCUMENT.ACS_VAT_DET_ACCOUNT_ID%type;
    gestValueQuantity            DOC_GAUGE_POSITION.GAP_VALUE_QUANTITY%type;
    quantity                     DOC_POSITION.POS_FINAL_QUANTITY%type;
    financial                    DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    analytical                   DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    infoCompl                    DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    accountInfo                  ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    gasWeightMat                 DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    materialRelationType         PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    cThirdMaterialRelationType   PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cThirdMaterialRelationTypeMA PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    metalAccount                 PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    thaManaged                   PAC_THIRD_ALLOY.THA_MANAGED%type;
    docMetalAccount              PCS.PC_CBASE.CBACNAME%type;
    canGenerateDiscount          boolean;
    cAdvMaterialMode             PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type;

    cursor crDiscount(
      cDiscountName         varchar2
    , cDocumentId           number
    , cLangId               number
    , cMaterialRelationType varchar2
    , cThirdMatRelType      varchar2
    , cAdvMaterialMode      varchar2
    )
    is
      select Distinct DNT.PTC_DISCOUNT_ID
           , 0 PTC_CHARGE_ID
           , nvl(DNT_IN_SERIES_CALCULATION, 0) cascade
           , 1 ORIGINAL
           , substr(nvl(DID_DESCR, DNT_NAME) ||
                    ' - ' ||
                    nvl(GAL.GAL_ALLOY_REF, DFA.DIC_BASIS_MATERIAL_ID) ||
                    decode(DFA.DFA_RATE_DATE, null, '', ' - ' || to_char(DFA.DFA_RATE_DATE, 'DD.MM.YYYY') )
                  , 1
                  , 255
                   ) DESCR
           , DNT_NAME
           , '0' C_CALCULATION_MODE
           , 0 DNT_RATE
           , 0 DNT_FRACTION
           , DFA.DFA_AMOUNT DNT_FIXED_AMOUNT   -- Toujours en monnaie de base sur ptc_discount
           , ACS_FUNCTION.ConvertAmountForView(nvl(DFA.DFA_AMOUNT, 0)
                                             , DMT.ACS_FINANCIAL_CURRENCY_ID
                                             , ACS_FUNCTION.GetLocalCurrencyId
                                             , DMT.DMT_DATE_DOCUMENT
                                             , DMT.DMT_RATE_OF_EXCHANGE
                                             , DMT.DMT_BASE_PRICE
                                             , 0
                                              ) DNT_FIXED_AMOUNT_B
           , 0 DNT_EXCEEDED_AMOUNT_FROM
           , 0 DNT_EXCEEDED_AMOUNT_TO
           , 0 DNT_MIN_AMOUNT
           , 0 DNT_MAX_AMOUNT
           , 0 DNT_QUANTITY_FROM
           , 0 DNT_QUANTITY_TO
           , null DNT_DATE_FROM
           , null DNT_DATE_TO
           , 0 DNT_IS_MULTIPLICATOR
           , null DNT_STORED_PROC
           , C_ROUND_TYPE
           , DNT_ROUND_AMOUNT
           , DNT.ACS_DIVISION_ACCOUNT_ID
           , DNT.ACS_FINANCIAL_ACCOUNT_ID
           , DNT.ACS_CPN_ACCOUNT_ID
           , DNT.ACS_CDA_ACCOUNT_ID
           , DNT.ACS_PF_ACCOUNT_ID
           , DNT.ACS_PJ_ACCOUNT_ID
           , 1 AUTOMATIC_CALC
           , nvl(DNT_IN_SERIES_CALCULATION, 0) DNT_IN_SERIES_CALCULATION
           , 0 DNT_TRANSFERT_PROP
           , 0 DNT_MODIFY
           , 0 DNT_UNIT_DETAIL
           , null DNT_SQL_EXTERN_ITEM
           , C_DISCOUNT_TYPE
           , 0 DNT_EXCLUSIVE
           , DFA.GCO_ALLOY_ID
           , DFA.DIC_BASIS_MATERIAL_ID
           , DFA.STM_STOCK_ID
        from PTC_DISCOUNT DNT
           , PTC_DISCOUNT_DESCR DID
           , DOC_FOOT_ALLOY DFA
           , GCO_ALLOY GAL
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DNT.DNT_NAME = cDiscountName
         and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
         and DID.PC_LANG_ID(+) = cLangID
         and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DNT.C_DISCOUNT_TYPE = decode(GAU.C_ADMIN_DOMAIN, '2', '1', '1', '2', '5', '2', '0')
         and DFA.DIC_COST_FOOT_ID is null
         and DFA.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID(+)
         and DMT.DOC_DOCUMENT_ID = cDocumentId
         and (    (    cMaterialRelationType = '1'
                   and DFA.GCO_ALLOY_ID is not null)
              or (    cMaterialRelationType = '2'
                  and DFA.DIC_BASIS_MATERIAL_ID is not null) )
         and cThirdMatRelType <> '6'
      union all
      select distinct DNT.PTC_DISCOUNT_ID
                    , 0 PTC_CHARGE_ID
                    , nvl(DNT_IN_SERIES_CALCULATION, 0) cascade
                    , 1 ORIGINAL
                    , substr(nvl(DID_DESCR, DNT_NAME) ||
                             ' - ' ||
                             GPD.DIC_BASIS_MATERIAL_ID ||
                             decode(DFA.DFA_RATE_DATE, null, '', ' - ' || to_char(DFA.DFA_RATE_DATE, 'DD.MM.YYYY') )
                           , 1
                           , 255
                            ) DESCR
                    , DNT_NAME
                    , '0' C_CALCULATION_MODE
                    , 0 DNT_RATE
                    , 0 DNT_FRACTION
--           , DFA.DFA_AMOUNT DNT_FIXED_AMOUNT   -- Toujours en monnaie de base sur ptc_discount
      ,               nvl(decode(cAdvMaterialMode
                               , '01', nvl(DFA_MAT.DFA_WEIGHT_DELIVERY, 0)
                               , '02', nvl(DFA_MAT.DFA_WEIGHT_DELIVERY, 0) + nvl(DFA_MAT.DFA_LOSS, 0)
                               , '03', nvl(DFA_MAT.DFA_WEIGHT_INVEST, 0)
                                ) *
                          (DFA_MAT.DFA_RATE / nvl(DFA_MAT.DFA_BASE_COST, 1) )
                        , 0
                         ) DNT_FIXED_AMOUNT
                    , ACS_FUNCTION.ConvertAmountForView(nvl(DFA_MAT.DFA_AMOUNT, 0)
                                                      , DMT.ACS_FINANCIAL_CURRENCY_ID
                                                      , ACS_FUNCTION.GetLocalCurrencyId
                                                      , DMT.DMT_DATE_DOCUMENT
                                                      , DMT.DMT_RATE_OF_EXCHANGE
                                                      , DMT.DMT_BASE_PRICE
                                                      , 0
                                                       ) DNT_FIXED_AMOUNT_B
                    , 0 DNT_EXCEEDED_AMOUNT_FROM
                    , 0 DNT_EXCEEDED_AMOUNT_TO
                    , 0 DNT_MIN_AMOUNT
                    , 0 DNT_MAX_AMOUNT
                    , 0 DNT_QUANTITY_FROM
                    , 0 DNT_QUANTITY_TO
                    , null DNT_DATE_FROM
                    , null DNT_DATE_TO
                    , 0 DNT_IS_MULTIPLICATOR
                    , null DNT_STORED_PROC
                    , C_ROUND_TYPE
                    , DNT_ROUND_AMOUNT
                    , DNT.ACS_DIVISION_ACCOUNT_ID
                    , DNT.ACS_FINANCIAL_ACCOUNT_ID
                    , DNT.ACS_CPN_ACCOUNT_ID
                    , DNT.ACS_CDA_ACCOUNT_ID
                    , DNT.ACS_PF_ACCOUNT_ID
                    , DNT.ACS_PJ_ACCOUNT_ID
                    , 1 AUTOMATIC_CALC
                    , nvl(DNT_IN_SERIES_CALCULATION, 0) DNT_IN_SERIES_CALCULATION
                    , 0 DNT_TRANSFERT_PROP
                    , 0 DNT_MODIFY
                    , 0 DNT_UNIT_DETAIL
                    , null DNT_SQL_EXTERN_ITEM
                    , C_DISCOUNT_TYPE
                    , 0 DNT_EXCLUSIVE
                    , null as GCO_ALLOY_ID
                    , GPD.DIC_BASIS_MATERIAL_ID
                    , DFA.STM_STOCK_ID
                 from PTC_DISCOUNT DNT
                    , PTC_DISCOUNT_DESCR DID
                    , DOC_FOOT_ALLOY DFA
                    , DOC_DOCUMENT DMT
                    , DOC_GAUGE GAU
                    , (select   DIC_BASIS_MATERIAL_ID
                              , GCO_ALLOY_ID
                           from GCO_PRECIOUS_RATE_DATE
                          where GPR_TABLE_MODE = 1
                            and DIC_BASIS_MATERIAL_ID is not null
                            and GCO_ALLOY_ID is not null
                       group by DIC_BASIS_MATERIAL_ID
                              , GCO_ALLOY_ID) GPD
                    , DOC_FOOT_ALLOY DFA_MAT
                where DNT.DNT_NAME = cDiscountName
                  and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
                  and DID.PC_LANG_ID(+) = cLangID
                  and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DNT.C_DISCOUNT_TYPE = decode(GAU.C_ADMIN_DOMAIN, '2', '1', '1', '2', '5', '2', '0')
                  and DFA.DIC_COST_FOOT_ID is null
                  and DFA.GCO_ALLOY_ID = GPD.GCO_ALLOY_ID
                  and DMT.DOC_DOCUMENT_ID = cDocumentId
                  and cThirdMatRelType = '6'
                  and DFA_MAT.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
                  and DFA_MAT.DIC_COST_FOOT_ID is null
                  and DFA_MAT.DIC_BASIS_MATERIAL_ID = GPD.DIC_BASIS_MATERIAL_ID
                  and nvl(DFA.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) = nvl(DFA_MAT.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') );
  begin
    -- intialisation de la valeur de retour
    aGenerated       := 0;

    -- recherche du domaine et de la langue du document
    select C_ADMIN_DOMAIN
         , PC_LANG_ID
         , DMT.DOC_GAUGE_ID
         , DMT.DMT_DATE_DOCUMENT
         , DMT.PAC_THIRD_ID
         , DMT.PAC_THIRD_ACI_ID
         , DMT.PAC_THIRD_VAT_ID
         , DMT.DOC_RECORD_ID
         , DMT.DIC_TYPE_SUBMISSION_ID
         , GAS.DIC_TYPE_MOVEMENT_ID
         , DMT.ACS_VAT_DET_ACCOUNT_ID
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
         , GAS_WEIGHT_MAT
         , nvl(GAS.GAS_VAT, 0) GAS_VAT
         , decode(GAU.C_ADMIN_DOMAIN
                , '1', SUP.C_MATERIAL_MGNT_MODE
                , '2', CUS.C_MATERIAL_MGNT_MODE
                , '5', SUP.C_MATERIAL_MGNT_MODE
                , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                 ) C_MATERIAL_MGNT_MODE
         , decode(GAU.C_ADMIN_DOMAIN
                , '1', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                , '2', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                , '5', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                 ) C_THIRD_MATERIAL_RELATION_TYPE
         , decode(GAU.C_ADMIN_DOMAIN
                , '1', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                , '2', nvl(CUS.CUS_METAL_ACCOUNT, 0)
                , '5', nvl(SUP.CRE_METAL_ACCOUNT, 0)
                , nvl(CUS.CUS_METAL_ACCOUNT, nvl(SUP.CRE_METAL_ACCOUNT, 0) )
                 ) METAL_ACCOUNT
         , decode(GAU.C_ADMIN_DOMAIN
                , '1', SUP.C_ADV_MATERIAL_MODE
                , '2', CUS.C_ADV_MATERIAL_MODE
                , '5', SUP.C_ADV_MATERIAL_MODE
                , nvl(CUS.C_ADV_MATERIAL_MODE, SUP.C_ADV_MATERIAL_MODE)
                 )
      into adminDomain
         , langId
         , gaugeId
         , dateDocument
         , vPAC_THIRD_ID
         , vPAC_THIRD_ACI_ID
         , vPAC_THIRD_VAT_ID
         , recordId
         , submissionType
         , movementType
         , vatDetAccountId
         , financial
         , analytical
         , infoCompl
         , gasWeightMat
         , vGAS_VAT
         , materialRelationType
         , cThirdMaterialRelationType
         , metalAccount
         , cAdvMaterialMode
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_DOCUMENT DMT
         , PAC_SUPPLIER_PARTNER SUP
         , PAC_CUSTOM_PARTNER CUS
     where DMT.DOC_DOCUMENT_ID = aDocumentId
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
       and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;

    docMetalAccount  := PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT');

    -- si le gabarit gère les matières précieuses
    if gasWeightMat = 1 then
      -- Le type de relation tiers 6 : Confié (COFIPAC)
      if cThirdMaterialRelationType = '6' then
        -- recherche de la liste des remises selon le domaine
        if adminDomain = '1'
          or adminDomain = '5' then
          discountName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_FOO_COFIPAC_DNT_PUR');
        elsif adminDomain = '2' then
          discountName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_FOO_COFIPAC_DNT_SAL');
        end if;
      else
        -- recherche de la liste des remises selon le domaine
        if adminDomain = '1'
          or adminDomain = '5' then
          discountName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_FOO_DISCOUNT_PURCHASE');
        elsif adminDomain = '2' then
          discountName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_FOO_DISCOUNT_SALE');
        end if;
      end if;

      -- si des remises sont configurées on continue
      if discountName is not null then
        -- supression des remises "Matières précieuses" déjà existantes
        delete from DOC_FOOT_CHARGE
              where DOC_FOOT_ID = aDocumentId
                and C_CHARGE_ORIGIN = 'PM';

        -- création des remise "Matières précieuses"
        for tplDiscount in crDiscount(discountName, aDocumentId, langId, materialRelationType, cThirdMaterialRelationType, cAdvMaterialMode) loop
          declare
            -- déclaré dans la boucle FOR pour éviter de devoir réinitialiser chaque champ du record l'un après l'autre à chaque passage
            recFootCharge DOC_FOOT_CHARGE%rowtype;
          begin
            -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
            thaManaged  := 0;

            begin
              if adminDomain = '1'
                or admindomain = '5' then
                select nvl(THA.THA_MANAGED, 0)
                  into thaManaged
                  from PAC_THIRD_ALLOY THA
                 where THA.PAC_SUPPLIER_PARTNER_ID = vPAC_THIRD_ID
                   and (    (    MaterialRelationType = '1'
                             and THA.GCO_ALLOY_ID = tplDiscount.GCO_ALLOY_ID)
                        or (    MaterialRelationType = '2'
                            and THA.DIC_BASIS_MATERIAL_ID = tplDiscount.DIC_BASIS_MATERIAL_ID)
                       );
              elsif adminDomain = '2' then
                select nvl(THA.THA_MANAGED, 0)
                  into thaManaged
                  from PAC_THIRD_ALLOY THA
                 where THA.PAC_CUSTOM_PARTNER_ID = vPAC_THIRD_ID
                   and (    (    MaterialRelationType = '1'
                             and THA.GCO_ALLOY_ID = tplDiscount.GCO_ALLOY_ID)
                        or (    MaterialRelationType = '2'
                            and THA.DIC_BASIS_MATERIAL_ID = tplDiscount.DIC_BASIS_MATERIAL_ID)
                       );
              else
                thaManaged  := 1;
              end if;
            exception
              when no_data_found then
                -- Si aucune matière/alliage n'est trouvée pour le tiers, le code de gestion est inactif.
                thaManaged  := null;
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
              -- Recherche le type de relation avec tiers présent sur l'éventuel compte poids lié à la matière pied courante
              -- pour autant que les comptes poids soit géré en global (config.) et au niveau du tiers. Si les comptes poids
              -- ne sont pas géré, c'est le type de relation avec tier du tier qui sera utilisé.
              cThirdMaterialRelationTypeMA  := cThirdMaterialRelationType;

              if     (docMetalAccount = '1')
                 and (metalAccount = 1) then
                if tplDiscount.STM_STOCK_ID is not null then
                  begin
                    select nvl(cThirdMaterialRelationTypeMA, STO.C_THIRD_MATERIAL_RELATION_TYPE)
                      into cThirdMaterialRelationTypeMA
                      from STM_STOCK STO
                     where STO.STM_STOCK_ID = tplDiscount.STM_STOCK_ID;
                  exception
                    when no_data_found then
                      null;
                  end;
                else
                  -- Le compte poids n'est pas spécifié sur la matière pied. C'est donc type de relation qui se trouve sur le
                  -- compte poids par défaut qui est utilisé.
                  begin
                    select nvl(cThirdMaterialRelationTypeMA, STO.C_THIRD_MATERIAL_RELATION_TYPE)
                      into cThirdMaterialRelationTypeMA
                      from STM_STOCK STO
                     where STO.STO_DEFAULT_METAL_ACCOUNT = 1;
                  exception
                    when no_data_found then
                      null;
                  end;
                end if;
              end if;

              -- Le type de relation tiers est
              --  2 : Matière partiellement confiée
              --  4 : Matière restituée.
              --  6 : Confié (COFIPAC)
              if (    (cThirdMaterialRelationType = '6')
                  or (cThirdMaterialRelationTypeMA = '2')
                  or (cThirdMaterialRelationTypeMA = '4') ) then
                -- recherche des comptes
                if (    (financial = 1)
                    or (analytical = 1) ) then
                  -- Utilise les comptes de la remise
                  recFootCharge.ACS_FINANCIAL_ACCOUNT_ID  := tplDiscount.ACS_FINANCIAL_ACCOUNT_ID;
                  recFootCharge.ACS_DIVISION_ACCOUNT_ID   := tplDiscount.ACS_DIVISION_ACCOUNT_ID;
                  recFootCharge.ACS_CPN_ACCOUNT_ID        := tplDiscount.ACS_CPN_ACCOUNT_ID;
                  recFootCharge.ACS_CDA_ACCOUNT_ID        := tplDiscount.ACS_CDA_ACCOUNT_ID;
                  recFootCharge.ACS_PF_ACCOUNT_ID         := tplDiscount.ACS_PF_ACCOUNT_ID;
                  recFootCharge.ACS_PJ_ACCOUNT_ID         := tplDiscount.ACS_PJ_ACCOUNT_ID;
                  accountInfo.DEF_HRM_PERSON              := null;
                  accountInfo.FAM_FIXED_ASSETS_ID         := null;
                  accountInfo.C_FAM_TRANSACTION_TYP       := null;
                  accountInfo.DEF_DIC_IMP_FREE1           := null;
                  accountInfo.DEF_DIC_IMP_FREE2           := null;
                  accountInfo.DEF_DIC_IMP_FREE3           := null;
                  accountInfo.DEF_DIC_IMP_FREE4           := null;
                  accountInfo.DEF_DIC_IMP_FREE5           := null;
                  accountInfo.DEF_TEXT1                   := null;
                  accountInfo.DEF_TEXT2                   := null;
                  accountInfo.DEF_TEXT3                   := null;
                  accountInfo.DEF_TEXT4                   := null;
                  accountInfo.DEF_TEXT5                   := null;
                  accountInfo.DEF_NUMBER1                 := null;
                  accountInfo.DEF_NUMBER2                 := null;
                  accountInfo.DEF_NUMBER3                 := null;
                  accountInfo.DEF_NUMBER4                 := null;
                  accountInfo.DEF_NUMBER5                 := null;
                  -- recherche des comptes
                  ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDiscount.PTC_DISCOUNT_ID
                                                           , '20'
                                                           , adminDomain
                                                           , dateDocument
                                                           , gaugeId
                                                           , aDocumentId
                                                           , null
                                                           , recordId
                                                           , vPAC_THIRD_ACI_ID
                                                           , null
                                                           , null
                                                           , null
                                                           , null
                                                           , null
                                                           , null
                                                           , recFootCharge.ACS_FINANCIAL_ACCOUNT_ID
                                                           , recFootCharge.ACS_DIVISION_ACCOUNT_ID
                                                           , recFootCharge.ACS_CPN_ACCOUNT_ID
                                                           , recFootCharge.ACS_CDA_ACCOUNT_ID
                                                           , recFootCharge.ACS_PF_ACCOUNT_ID
                                                           , recFootCharge.ACS_PJ_ACCOUNT_ID
                                                           , accountInfo
                                                            );

                  if (analytical = 0) then
                    recFootCharge.ACS_CPN_ACCOUNT_ID  := null;
                    recFootCharge.ACS_CDA_ACCOUNT_ID  := null;
                    recFootCharge.ACS_PJ_ACCOUNT_ID   := null;
                    recFootCharge.ACS_PF_ACCOUNT_ID   := null;
                  end if;
                end if;

                -- Code TVA géré sur le gabarit
                if vGAS_VAT = 1 then
                  recFootCharge.ACS_TAX_CODE_ID  :=
                    ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(tplDiscount.C_DISCOUNT_TYPE
                                                          , vPAC_THIRD_VAT_ID
                                                          , 0
                                                          , tplDiscount.PTC_DISCOUNT_ID
                                                          , null
                                                          , adminDomain
                                                          , submissionType
                                                          , movementType
                                                          , vatDetAccountId
                                                           );
                else
                  recFootCharge.ACS_TAX_CODE_ID  := null;
                end if;

                recFootCharge.DOC_FOOT_ID                := aDocumentId;
                recFootCharge.C_CHARGE_ORIGIN            := 'PM';   -- Matières précieuses
                recFootCharge.C_FINANCIAL_CHARGE         := '02';   -- Remise
                recFootCharge.FCH_NAME                   := tplDiscount.DNT_NAME;
                recFootCharge.FCH_DESCRIPTION            := tplDiscount.Descr;
                recFootCharge.FCH_EXCL_AMOUNT            := nvl(tplDiscount.DNT_FIXED_AMOUNT, 0);
                recFootCharge.FCH_INCL_AMOUNT            := nvl(tplDiscount.DNT_FIXED_AMOUNT, 0);   -- TVA calculée ultérieurement
                recFootCharge.FCH_FIXED_AMOUNT_B         := nvl(tplDiscount.DNT_FIXED_AMOUNT, 0);
                recFootCharge.C_CALCULATION_MODE         := '0';
                recFootCharge.FCH_IN_SERIES_CALCULATION  := tplDiscount.DNT_IN_SERIES_CALCULATION;
                recFootCharge.PTC_DISCOUNT_ID            := tplDiscount.PTC_DISCOUNT_ID;
                recFootCharge.HRM_PERSON_ID              := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(accountInfo.DEF_HRM_PERSON);
                recFootCharge.FAM_FIXED_ASSETS_ID        := accountInfo.FAM_FIXED_ASSETS_ID;
                recFootCharge.C_FAM_TRANSACTION_TYP      := accountInfo.C_FAM_TRANSACTION_TYP;
                recFootCharge.FCH_IMP_TEXT_1             := accountInfo.DEF_TEXT1;
                recFootCharge.FCH_IMP_TEXT_2             := accountInfo.DEF_TEXT2;
                recFootCharge.FCH_IMP_TEXT_3             := accountInfo.DEF_TEXT3;
                recFootCharge.FCH_IMP_TEXT_4             := accountInfo.DEF_TEXT4;
                recFootCharge.FCH_IMP_TEXT_5             := accountInfo.DEF_TEXT5;
                recFootCharge.FCH_IMP_NUMBER_1           := to_number(accountInfo.DEF_NUMBER1);
                recFootCharge.FCH_IMP_NUMBER_2           := to_number(accountInfo.DEF_NUMBER2);
                recFootCharge.FCH_IMP_NUMBER_3           := to_number(accountInfo.DEF_NUMBER3);
                recFootCharge.FCH_IMP_NUMBER_4           := to_number(accountInfo.DEF_NUMBER4);
                recFootCharge.FCH_IMP_NUMBER_5           := to_number(accountInfo.DEF_NUMBER5);
                recFootCharge.DIC_IMP_FREE1_ID           := accountInfo.DEF_DIC_IMP_FREE1;
                recFootCharge.DIC_IMP_FREE2_ID           := accountInfo.DEF_DIC_IMP_FREE2;
                recFootCharge.DIC_IMP_FREE3_ID           := accountInfo.DEF_DIC_IMP_FREE3;
                recFootCharge.DIC_IMP_FREE4_ID           := accountInfo.DEF_DIC_IMP_FREE4;
                recFootCharge.DIC_IMP_FREE5_ID           := accountInfo.DEF_DIC_IMP_FREE5;
                -- création de la taxe de pied
                DOC_DISCOUNT_CHARGE.InsertFootCharge(recFootCharge);
              end if;
            end if;
          end;
        end loop;

        -- active le flag de recalcul des remises/taxes de pied
        update DOC_DOCUMENT
           set DMT_RECALC_FOOT_CHARGE = 1
         where DOC_DOCUMENT_ID = aDocumentID;

        aGenerated  := 1;
      end if;
    end if;
  exception
    when no_data_found then
      raise_application_error(-20910, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le document passé en paramètre n''existe pas') );
  end generatePreciousMatDiscount;

  /**
  * Description
  *    Processus Création Déchage Matière Pied de type Alliage
  */
  procedure DischargeFootMatAlloyType(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDateToExclude in out DOC_FOOT_ALLOY.A_DATECRE%type)
  is
    cursor crAllPositionMatAlloyType(cDocumentID number)
    is
      select   DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID
             , nvl(sum(DOA.DOA_WEIGHT), 0) DOA_WEIGHT
             , nvl(sum(DOA.DOA_WEIGHT_MAT), 0) DOA_WEIGHT_MAT
             , nvl(sum(DOA.DOA_STONE_NUM), 0) DOA_STONE_NUM
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY_TH), 0) DOA_WEIGHT_DELIVERY_TH
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY), 0) DOA_WEIGHT_DELIVERY
             , nvl(sum(DOA.DOA_LOSS_TH), 0) DOA_LOSS_TH
             , nvl(sum(DOA.DOA_LOSS), 0) DOA_LOSS
             , nvl(sum(DOA.DOA_WEIGHT_INVEST_TH), 0) DOA_WEIGHT_INVEST_TH
             , nvl(sum(DOA.DOA_WEIGHT_INVEST), 0) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.GCO_ALLOY_ID is not null
      group by DOA.GCO_ALLOY_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID;

    bFounded             boolean;
    initialStockID       STM_STOCK.STM_STOCK_ID%type;
  begin
    aDateToExclude  := nvl(aDateToExclude, sysdate);

    -- Pour chaque ensemble de matières position de même alliage
    for tplAllPositionMatAlloyType in crAllPositionMatAlloyType(aDocumentID) loop
      ----
      -- Recherche la matière pied parent de l'alliage courant.
      --
      for ltplSrcFootAlloy in (select distinct PDE_SRC.PAC_THIRD_ID as SRC_PAC_THIRD_ID
                                             , PDE.PAC_THIRD_ID as TGT_PAC_THIRD_ID
                                             , DFA_SRC.DFA_RATE_TH
                                             , DFA_SRC.DFA_RATE
                                             , STM_STOCK_ID
                                             , DFA_SRC.DFA_BASE_COST
                                          from DOC_POSITION_DETAIL PDE
                                             , DOC_POSITION_DETAIL PDE_SRC
                                             , DOC_FOOT_ALLOY DFA_SRC
                                             , DOC_DOCUMENT DMT_SRC
                                         where PDE.DOC_DOCUMENT_ID = aDocumentID
                                           and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                                           and DFA_SRC.DOC_FOOT_ID = PDE_SRC.DOC_DOCUMENT_ID
                                           and PDE_SRC.DOC_DOCUMENT_ID = DMT_SRC.DOC_DOCUMENT_ID
--           and nvl(DFA_SRC.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) =
--               nvl(tplAllPositionMatAlloyType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                                           and DFA_SRC.GCO_ALLOY_ID = tplAllPositionMatAlloyType.GCO_ALLOY_ID
                                      )loop

        -- Recherche le compte poids de la matière pied cible uniquement si la matière position courante ne possède pas de compte poids.
        initialStockID  := tplAllPositionMatAlloyType.STM_STOCK_ID;

        if initialStockID is null then
          GetStockID(aDocumentID, tplAllPositionMatAlloyType.GCO_ALLOY_ID, null, initialStockID);
        end if;

        insert into DOC_FOOT_ALLOY DFA
                    (DFA.DOC_FOOT_ALLOY_ID
                   , DFA.DOC_FOOT_ID
                   , DFA.GCO_ALLOY_ID
                   , DFA.DIC_BASIS_MATERIAL_ID
                   , DFA.DFA_WEIGHT
                   , DFA.DFA_WEIGHT_MAT
                   , DFA.DFA_STONE_NUM
                   , DFA.DFA_WEIGHT_DELIVERY_TH
                   , DFA.DFA_WEIGHT_DELIVERY
                   , DFA.DFA_WEIGHT_DIF
                   , DFA.DFA_LOSS_TH
                   , DFA.DFA_LOSS
                   , DFA.DFA_WEIGHT_INVEST_TH
                   , DFA.DFA_WEIGHT_INVEST
                   , DFA.DFA_RATE_TH
                   , DFA.DFA_AMOUNT_TH
                   , DFA.DFA_RATE
                   , DFA.DFA_BASE_COST
                   , DFA.DFA_AMOUNT
                   , DFA.DFA_COMMENT
                   , DIC_COST_FOOT_ID
                   , DFA.C_MUST_ADVANCE
                   , DFA.C_SHARING_MODE
                   , DFA.DFA_RATE_DATE
                   , DFA.STM_STOCK_ID
                   , DFA.A_DATECRE
                   , DFA.A_IDCRE
                    )
          Values( INIT_ID_SEQ.nextval   -- DOC_FOOT_ALLOY_ID
               , aDocumentID   -- DOC_FOOT_ID
               , tplAllPositionMatAlloyType.GCO_ALLOY_ID   -- GCO_ALLOY_ID
               , null   -- DIC_BASIS_MATERIAL_ID
               , tplAllPositionMatAlloyType.DOA_WEIGHT   -- DFA_WEIGHT
               , tplAllPositionMatAlloyType.DOA_WEIGHT_MAT   -- DFA_WEIGHT_MAT
               , tplAllPositionMatAlloyType.DOA_STONE_NUM   -- DFA_STONE_NUM
               , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH   -- DFA_WEIGHT_DELIVERY_TH
               , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY   -- DFA_WEIGHT_DELIVERY
               , decode(tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                      , 0, 0
                      , (tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY) *
                        100 /
                        tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY_TH
                       )   -- DFA_WEIGHT_DIF
               , tplAllPositionMatAlloyType.DOA_LOSS_TH   -- DFA_LOSS_TH
               , tplAllPositionMatAlloyType.DOA_LOSS   -- DFA_LOSS
               , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST_TH   -- DFA_WEIGHT_INVEST_TH
               , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST   -- DFA_WEIGHT_INVEST
               , ltplSrcFootAlloy.DFA_RATE_TH   -- DFA_RATE_TH
               , GetAdvanceWeight(aDocumentID
                                , null
                                , null
                                , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
                                , tplAllPositionMatAlloyType.DOA_LOSS
                                , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
                                 ) *
                 ltplSrcFootAlloy.DFA_RATE_TH   -- DFA_AMOUNT_TH
               , ltplSrcFootAlloy.DFA_RATE   -- DFA_RATE
               , ltplSrcFootAlloy.DFA_BASE_COST   -- DFA_BASE_COST
               , GetAdvanceWeight(aDocumentID
                                , null
                                , null
                                , tplAllPositionMatAlloyType.DOA_WEIGHT_DELIVERY
                                , tplAllPositionMatAlloyType.DOA_LOSS
                                , tplAllPositionMatAlloyType.DOA_WEIGHT_INVEST
                                 ) *
                 ltplSrcFootAlloy.DFA_RATE /
                 ltplSrcFootAlloy.DFA_BASE_COST   -- DFA_AMOUNT
               , null --todo
               , null   -- DIC_COST_FOOT_ID
               , '03'   -- C_MUST_ADVANCE
               , '05'   -- C_SHARING_MODE
               , tplAllPositionMatAlloyType.DOA_RATE_DATE   -- DFA_RATE_DATE
               , case
                   when(initialStockID is null)
                   and (ltplSrcFootAlloy.SRC_PAC_THIRD_ID = ltplSrcFootAlloy.TGT_PAC_THIRD_ID) then ltplSrcFootAlloy.STM_STOCK_ID   -- Compte poids parent si pas changement de tiers
                   else initialStockID   -- Compte poids comme en création
                 end   -- STM_STOCK_ID
               , aDateToExclude   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
               );

      end loop;
    end loop;
  end DischargeFootMatAlloyType;

  /**
  * Description
  *    Processus Création Déchage Matière Pied de type Matière de base
  */
  procedure DischargeFootMatBaseMatType(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDateToExclude in out DOC_FOOT_ALLOY.A_DATECRE%type)
  is
    cursor crAllPositionMatBaseMatType(cDocumentID number)
    is
      select   DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID
             , nvl(sum(DOA.DOA_WEIGHT), 0) DOA_WEIGHT
             , nvl(sum(DOA.DOA_WEIGHT_MAT), 0) DOA_WEIGHT_MAT
             , nvl(sum(DOA.DOA_STONE_NUM), 0) DOA_STONE_NUM
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY_TH), 0) DOA_WEIGHT_DELIVERY_TH
             , nvl(sum(DOA.DOA_WEIGHT_DELIVERY), 0) DOA_WEIGHT_DELIVERY
             , nvl(sum(DOA.DOA_LOSS_TH), 0) DOA_LOSS_TH
             , nvl(sum(DOA.DOA_LOSS), 0) DOA_LOSS
             , nvl(sum(DOA.DOA_WEIGHT_INVEST_TH), 0) DOA_WEIGHT_INVEST_TH
             , nvl(sum(DOA.DOA_WEIGHT_INVEST), 0) DOA_WEIGHT_INVEST
          from DOC_POSITION_ALLOY DOA
         where DOA.DOC_DOCUMENT_ID = cDocumentID
           and DOA.DIC_BASIS_MATERIAL_ID is not null
      group by DOA.DIC_BASIS_MATERIAL_ID
             , DOA.DOA_RATE_DATE
             , DOA.STM_STOCK_ID;

    bFounded       boolean;
    initialStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    aDateToExclude  := nvl(aDateToExclude, sysdate);

    -- Pour chaque ensemble de matières position de même matière de base
    for tplAllPositionMatBaseMatType in crAllPositionMatBaseMatType(aDocumentID) loop
      ----
      -- Recherche la matière pied parent de la matière de base courante.
      --
      for ltplSrcFootAlloy in (select distinct PDE_SRC.PAC_THIRD_ID as SRC_PAC_THIRD_ID
                                             , PDE.PAC_THIRD_ID as TGT_PAC_THIRD_ID
                                             , DFA_SRC.DFA_RATE_TH
                                             , DFA_SRC.DFA_RATE
                                             , STM_STOCK_ID
                                             , DFA_SRC.DFA_BASE_COST
                                          from DOC_POSITION_DETAIL PDE
                                             , DOC_POSITION_DETAIL PDE_SRC
                                             , DOC_FOOT_ALLOY DFA_SRC
                                             , DOC_DOCUMENT DMT_SRC
                                         where PDE.DOC_DOCUMENT_ID = aDocumentID
                                           and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                                           and DFA_SRC.DOC_FOOT_ID = PDE_SRC.DOC_DOCUMENT_ID
                                           and PDE_SRC.DOC_DOCUMENT_ID = DMT_SRC.DOC_DOCUMENT_ID
--           and nvl(DFA_SRC.DFA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') ) =
--               nvl(tplAllPositionMatBaseMatType.DOA_RATE_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                                           and DFA_SRC.DIC_BASIS_MATERIAL_ID = tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID)loop
        -- Inscription de l'événement dans l'historique des modifications
        -- DOC_FUNCTIONS.CreateHistoryInformation(aDocumentID
        --                                      , null
        --                                      , dmtNumber
        --                                      , 'PL/SQL'
        --                                      , 'DischargeFootMatBaseMatType'
        --                                      , 'Matière pied source   : ' || ltplSrcFootAlloy.DOC_FOOT_ALLOY_ID || chr(13) ||
        --                                        'Matière de base       : ' || tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID || chr(13) || '---' || chr(13) ||
        --                                        'Poids                 : ' || tplAllPositionMatBaseMatType.DOA_WEIGHT || chr(13) ||
        --                                        'Poids matière         : ' || tplAllPositionMatBaseMatType.DOA_WEIGHT_MAT || chr(13) ||
        --                                        'Poids livré           : ' || tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY || chr(13) ||
        --                                        'Poids investi         : ' || tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST || chr(13) ||
        --                                        'Perte                 : ' || tplAllPositionMatBaseMatType.DOA_LOSS || chr(13) ||
        --                                        'Compte poids position : ' || tplAllPositionMatBaseMatType.STM_STOCK_ID || chr(13) ||
        --                                        'Date cours position   : ' || tplAllPositionMatBaseMatType.DOA_RATE_DATE
        --                                      , null
        --                                      , null
        --                                      );
        -- Recherche le compte poids de la matière pied cible uniquement si la matière position courante ne possède pas de compte poids.
        initialStockID  := tplAllPositionMatBaseMatType.STM_STOCK_ID;

        if initialStockID is null then
          GetStockID(aDocumentID, null, tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID, initialStockID);
        end if;

        insert into DOC_FOOT_ALLOY DFA
                    (DFA.DOC_FOOT_ALLOY_ID
                   , DFA.DOC_FOOT_ID
                   , DFA.GCO_ALLOY_ID
                   , DFA.DIC_BASIS_MATERIAL_ID
                   , DFA.DFA_WEIGHT
                   , DFA.DFA_WEIGHT_MAT
                   , DFA.DFA_STONE_NUM
                   , DFA.DFA_WEIGHT_DELIVERY_TH
                   , DFA.DFA_WEIGHT_DELIVERY
                   , DFA.DFA_WEIGHT_DIF
                   , DFA.DFA_LOSS_TH
                   , DFA.DFA_LOSS
                   , DFA.DFA_WEIGHT_INVEST_TH
                   , DFA.DFA_WEIGHT_INVEST
                   , DFA.DFA_RATE_TH
                   , DFA.DFA_AMOUNT_TH
                   , DFA.DFA_RATE
                   , DFA.DFA_BASE_COST
                   , DFA.DFA_AMOUNT
                   , DFA.DFA_COMMENT
                   , DIC_COST_FOOT_ID
                   , DFA.C_MUST_ADVANCE
                   , DFA.C_SHARING_MODE
                   , DFA.DFA_RATE_DATE
                   , DFA.STM_STOCK_ID
                   , DFA.A_DATECRE
                   , DFA.A_IDCRE
                    )
          values( INIT_ID_SEQ.nextval   -- DOC_FOOT_ALLOY_ID
               , aDocumentID   -- DOC_FOOT_ID
               , null   -- GCO_ALLOY_ID
               , tplAllPositionMatBaseMatType.DIC_BASIS_MATERIAL_ID   -- DIC_BASIS_MATERIAL_ID
               , tplAllPositionMatBaseMatType.DOA_WEIGHT   -- DFA_WEIGHT
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_MAT   -- DFA_WEIGHT_MAT
               , tplAllPositionMatBaseMatType.DOA_STONE_NUM   -- DFA_STONE_NUM
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH   -- DFA_WEIGHT_DELIVERY_TH
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY   -- DFA_WEIGHT_DELIVERY
               , decode(tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                      , 0, 0
                      , (tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH - tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY) *
                        100 /
                        tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY_TH
                       )   -- DFA_WEIGHT_DIF
               , tplAllPositionMatBaseMatType.DOA_LOSS_TH   -- DFA_LOSS_TH
               , tplAllPositionMatBaseMatType.DOA_LOSS   -- DFA_LOSS
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST_TH   -- DFA_WEIGHT_INVEST_TH
               , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST   -- DFA_WEIGHT_INVEST
               , ltplSrcFootAlloy.DFA_RATE_TH   -- DFA_RATE_TH
               , GetAdvanceWeight(aDocumentID
                                , null
                                , null
                                , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
                                , tplAllPositionMatBaseMatType.DOA_LOSS
                                , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
                                 ) *
                 ltplSrcFootAlloy.DFA_RATE_TH   -- DFA_AMOUNT_TH
               , ltplSrcFootAlloy.DFA_RATE   -- DFA_RATE
               , ltplSrcFootAlloy.DFA_BASE_COST   -- DFA_BASE_COST
               , GetAdvanceWeight(aDocumentID
                                , null
                                , null
                                , tplAllPositionMatBaseMatType.DOA_WEIGHT_DELIVERY
                                , tplAllPositionMatBaseMatType.DOA_LOSS
                                , tplAllPositionMatBaseMatType.DOA_WEIGHT_INVEST
                                 ) *
                 ltplSrcFootAlloy.DFA_RATE /
                 ltplSrcFootAlloy.DFA_BASE_COST   -- DFA_AMOUNT
                 , null
               , null   -- DIC_COST_FOOT_ID
               , '03'   -- C_MUST_ADVANCE
               , '05'   -- C_SHARING_MODE
               , tplAllPositionMatBaseMatType.DOA_RATE_DATE   -- DFA_RATE_DATE
               , case
                   when(initialStockID is null)
                   and (ltplSrcFootAlloy.SRC_PAC_THIRD_ID = ltplSrcFootAlloy.TGT_PAC_THIRD_ID) then ltplSrcFootAlloy.STM_STOCK_ID   -- Compte poids parent si pas changement de tiers
                   else initialStockID   -- Compte poids comme en création
                 end   -- STM_STOCK_ID
               , aDateToExclude   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
               );

      end loop;
    end loop;
  end DischargeFootMatBaseMatType;

  /**
  * Description
  *   recherchec du mode de gestion des matières précieuses
  */
  function GetMatManagementMode(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  is
    result PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    select decode(GAU.C_ADMIN_DOMAIN
                , '1', SUP.C_MATERIAL_MGNT_MODE
                , '2', CUS.C_MATERIAL_MGNT_MODE
                , '5', SUP.C_MATERIAL_MGNT_MODE
                , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                 )
      into result
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
         , PAC_CUSTOM_PARTNER CUS
         , PAC_SUPPLIER_PARTNER SUP
     where DMT.DOC_DOCUMENT_ID = aDocumentID
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
       and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;

    return result;
  end GetMatManagementMode;

  /**
  * Description
  *   Recherche le poids à utiliser en fonction du mode de gestion des avances
  */
  function GetAdvanceWeight(
    aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAdvMaterialMgnt    PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aAdvMaterialMode    PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type
  , aWeightDelivery  in DOC_FOOT_ALLOY.DFA_WEIGHT_DELIVERY%type
  , aLoss            in DOC_FOOT_ALLOY.DFA_LOSS%type
  , aWeightInvest    in DOC_FOOT_ALLOY.DFA_WEIGHT_INVEST%type
  )
    return number
  is
    result           DOC_FOOT_ALLOY.DFA_WEIGHT_DELIVERY%type;
    cAdvMaterialMode PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type;
    advMaterialMgnt  PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type;
  begin
    result            := aWeightDelivery;

    if aDocumentID is not null then
      select decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.C_ADV_MATERIAL_MODE
                  , '2', CUS.C_ADV_MATERIAL_MODE
                  , '5', SUP.C_ADV_MATERIAL_MODE
                  , nvl(CUS.C_ADV_MATERIAL_MODE, SUP.C_ADV_MATERIAL_MODE)
                   )
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.CRE_ADV_MATERIAL_MGNT
                  , '2', CUS.CUS_ADV_MATERIAL_MGNT
                  , '5', SUP.CRE_ADV_MATERIAL_MGNT
                  , nvl(CUS.CUS_ADV_MATERIAL_MGNT, SUP.CRE_ADV_MATERIAL_MGNT)
                   )
        into cAdvMaterialMode
           , advMaterialMgnt
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;
    else
      cAdvMaterialMode  := aAdvMaterialMode;
      advMaterialMgnt   := aAdvMaterialMgnt;
    end if;

    cAdvMaterialMode  := nvl(cAdvMaterialMode, '01');

    -- Le teste sur la gestion des avances est supprimé pour rendre indépendant le mode de gestion des avances. Qui
    -- devrait plutôt s'appeller le mode de calcul des montants.
    -- if nvl(advMaterialMgnt, 0) = 1 then
    if cAdvMaterialMode = '01' then   -- Poids livré
      result  := aWeightDelivery;
    elsif cAdvMaterialMode = '02' then   -- Poids livré + perte
      result  := aWeightDelivery + aLoss;
    elsif cAdvMaterialMode = '03' then   -- Poids investi
      result  := aWeightInvest;
    end if;

    -- end if;
    return result;
  end GetAdvanceWeight;

  /**
  * Description
  *   Recherche les cours théorique, facturé ainsi que les montants théorique et facturé
  */
  procedure GetRates(
    aDocumentID                    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAlloyID                       GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialID               DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aDocumentDate                  DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aRateOfExchange                DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aBasePrice                     DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAdminDomain                   DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aThirdMaterialRelationType     PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type
  , aMaterialMgntMode              PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAdvMaterialMgnt               PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type
  , aDicFreeCode1ID                DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDicComplementaryDataID        DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  , aWeightDelivery                DOC_FOOT_ALLOY.DFA_WEIGHT_DELIVERY%type
  , aLoss                          DOC_FOOT_ALLOY.DFA_LOSS%type
  , aWeightInvest                  DOC_FOOT_ALLOY.DFA_WEIGHT_INVEST%type
  , aRateTH                    out DOC_FOOT_ALLOY.DFA_RATE_TH%type
  , aAmountTH                  out DOC_FOOT_ALLOY.DFA_AMOUNT_TH%type
  , aRate                      out DOC_FOOT_ALLOY.DFA_RATE%type
  , aAmount                    out DOC_FOOT_ALLOY.DFA_AMOUNT%type
  )
  is
    dicTypeRateID GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type;
    bFounded      boolean;
  begin
    if (aAdminDomain = '1') then
      dicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_PURCHASE');
    elsif(aAdminDomain = '2') then
      dicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_SALE');
    elsif(aAdminDomain = '3') then
      dicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_STOCK');
    else
      dicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_SALE');
    end if;

    -- 6. Confié (COFIPAC)
    -- 7. Facturé (COFITER)
    if     (aAlloyID is not null)
       and (aThirdMaterialRelationType in('6', '7') ) then
      aRateTH   :=
        GCO_PRECIOUS_MAT_FUNCTIONS.GetUshRate(iAlloyID           => aAlloyID
                                            , iDateRef           => aDocumentDate
                                            , iThirdMatRelType   => aThirdMaterialRelationType
                                            , iDicTypeRateID     => dicTypeRateID
                                            , iDicFreeCode1ID    => aDicFreeCode1ID
                                            , iDicComplDataID    => aDicComplementaryDataID
                                             );
      bFounded  :=(aRateTH is not null);
    else
      -- Renvoie le cours d'une matière de base ou d'un alliage pour une unité
      aRateTH  :=
                 FAL_PRECALC_TOOLS.GetQuotedPrice(aAlloyID, aBasisMaterialID, aDocumentDate, dicTypeRateID, bFounded, aDicFreeCode1ID, aDicComplementaryDataID);
    end if;

    if bFounded then
      aRateTH    := aRateTH / aRateOfExchange * aBasePrice;
      aRate      := aRateTH;
      aAmountTH  := GetAdvanceWeight(aDocumentID, null, null, aWeightDelivery, aLoss, aWeightInvest) * aRateTH;
      aAmount    := aAmountTH;

      if (PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') <> '1') then
        if     (aAdminDomain = '1')
           and (    (aThirdMaterialRelationType = 1)
                or (aThirdMaterialRelationType = 3)
                or (aThirdMaterialRelationType = 4) ) then
          aRate    := 0;
          aAmount  := 0;
        elsif     (aAdminDomain = '2')
              and (aThirdMaterialRelationType = 3) then
          aRate    := 0;
          aAmount  := 0;
        end if;
      else
        if (aThirdMaterialRelationType = 5) then
          aRate    := 0;
          aAmount  := 0;
        end if;
      end if;
    else
      aRateTH    := null;
      aAmountTH  := null;
      aRate      := null;
      aAmount    := null;
    end if;
  end GetRates;

  /**
  * Description
  *   Recherche les cours théorique, facturé ainsi que les montants théorique et facturé pour une matière pied donnée
  */
  procedure GetRatesForOneFootAlloy(
    aFootAlloyID in     DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type
  , aRateDate    in     DOC_FOOT_ALLOY.DFA_RATE_DATE%type
  , aRateTH      out    DOC_FOOT_ALLOY.DFA_RATE_TH%type
  , aAmountTH    out    DOC_FOOT_ALLOY.DFA_AMOUNT_TH%type
  , aRate        out    DOC_FOOT_ALLOY.DFA_RATE%type
  , aAmount      out    DOC_FOOT_ALLOY.DFA_AMOUNT%type
  )
  is
    bStop                      boolean;
    dfaAlloyID                 GCO_ALLOY.GCO_ALLOY_ID%type;
    dicBasisMaterialID         DOC_FOOT_ALLOY.DIC_BASIS_MATERIAL_ID%type;
    dfaWeightDelivery          DOC_FOOT_ALLOY.DFA_WEIGHT_DELIVERY%type;
    dfaLoss                    DOC_FOOT_ALLOY.DFA_LOSS%type;
    dfaWeightInvest            DOC_FOOT_ALLOY.DFA_WEIGHT_INVEST%type;
    dmtDocumentID              DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    dmtCreateFootMat           DOC_DOCUMENT.DMT_CREATE_FOOT_MAT%type;
    dmtRecalcFootMat           DOC_DOCUMENT.DMT_RECALC_FOOT_MAT%type;
    dmtDocumentDate            DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    dmtRateOfExchange          DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    dmtBasePrice               DOC_DOCUMENT.DMT_BASE_PRICE%type;
    cAdminDomain               DOC_GAUGE.C_ADMIN_DOMAIN%type;
    gasWeighingMgm             DOC_GAUGE_STRUCTURED.GAS_WEIGHING_MGM%type;
    gasWeightMat               DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    thirdWeighingMgnt          PAC_CUSTOM_PARTNER.C_WEIGHING_MGNT%type;
    cThirdMaterialRelationType PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cMaterialMgntMode          PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    nAdvMaterialMgnt           PAC_CUSTOM_PARTNER.CUS_ADV_MATERIAL_MGNT%type;
    dicFreeCode1ID             DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type;
    dicComplementaryDataID     DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type;
    gasParentWeightMat         DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
  begin
    bStop  := false;

    begin
      select DFA.GCO_ALLOY_ID
           , DFA.DIC_BASIS_MATERIAL_ID
           , DFA.DFA_WEIGHT_DELIVERY
           , DFA.DFA_LOSS
           , DFA.DFA_WEIGHT_INVEST
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_CREATE_FOOT_MAT
           , DMT.DMT_RECALC_FOOT_MAT
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , GAU.C_ADMIN_DOMAIN
           , GAS.GAS_WEIGHING_MGM
           , GAS.GAS_WEIGHT_MAT
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.C_WEIGHING_MGNT
                  , '2', CUS.C_WEIGHING_MGNT
                  , '5', SUP.C_WEIGHING_MGNT
                  , nvl(CUS.C_WEIGHING_MGNT, SUP.C_WEIGHING_MGNT)
                   ) C_WEIGHING_MGNT
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , '2', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                  , '5', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                  , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                   ) C_THIRD_MATERIAL_RELATION_TYPE
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.C_MATERIAL_MGNT_MODE
                  , '2', CUS.C_MATERIAL_MGNT_MODE
                  , '5', SUP.C_MATERIAL_MGNT_MODE
                  , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                   ) C_MATERIAL_MGNT_MODE
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.CRE_ADV_MATERIAL_MGNT
                  , '2', CUS.CUS_ADV_MATERIAL_MGNT
                  , '5', SUP.CRE_ADV_MATERIAL_MGNT
                  , nvl(CUS.CUS_ADV_MATERIAL_MGNT, SUP.CRE_ADV_MATERIAL_MGNT)
                   ) ADV_MATERIAL_MGNT
           , PER.DIC_FREE_CODE1_ID
           , decode(GAU.C_ADMIN_DOMAIN
                  , '1', SUP.DIC_COMPLEMENTARY_DATA_ID
                  , '2', CUS.DIC_COMPLEMENTARY_DATA_ID
                  , '5', SUP.DIC_COMPLEMENTARY_DATA_ID
                  , nvl(CUS.DIC_COMPLEMENTARY_DATA_ID, SUP.DIC_COMPLEMENTARY_DATA_ID)
                   ) DIC_COMPLEMENTARY_DATA_ID
        into dfaAlloyID
           , dicBasisMaterialID
           , dfaWeightDelivery
           , dfaLoss
           , dfaWeightInvest
           , dmtDocumentID
           , dmtCreateFootMat
           , dmtRecalcFootMat
           , dmtDocumentDate
           , dmtRateOfExchange
           , dmtBasePrice
           , cAdminDomain
           , gasWeighingMgm
           , gasWeightMat
           , thirdWeighingMgnt
           , cThirdMaterialRelationType
           , cMaterialMgntMode
           , nAdvMaterialMgnt
           , dicFreeCode1ID
           , dicComplementaryDataID
        from DOC_FOOT_ALLOY DFA
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
       where DFA.DOC_FOOT_ALLOY_ID = aFootAlloyID
         and DMT.DOC_DOCUMENT_ID = DFA.DOC_FOOT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.GAS_WEIGHT_MAT = 1
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and PER.PAC_PERSON_ID(+) = DMT.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    -- Vérifie si le document courant possède au moins une position déchargée
    if not bStop then
      GetRates(dmtDocumentID
             , dfaAlloyID
             , dicBasisMaterialID
             , nvl(aRateDate, dmtDocumentDate)
             , dmtRateOfExchange
             , dmtBasePrice
             , cAdminDomain
             , cThirdMaterialRelationType
             , cMaterialMgntMode
             , nAdvMaterialMgnt
             , dicFreeCode1ID
             , dicComplementaryDataID
             , dfaWeightDelivery
             , dfaLoss
             , dfaWeightInvest
             , aRateTH
             , aAmountTH
             , aRate
             , aAmount
              );
    else
      aRateTH    := null;
      aAmountTH  := null;
      aRate      := null;
      aAmount    := null;
    end if;
  end GetRatesForOneFootAlloy;

  /**
  * Description
  *   Mise à jour des cours théorique, facturé ainsi que des montants théorique et facturé pour une matière pied donnée
  */
  procedure UpdateRatesForOneFootAlloy(aFootAlloyID in DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type, aRateDate in DOC_FOOT_ALLOY.DFA_RATE_DATE%type)
  is
    dfaRateTH   DOC_FOOT_ALLOY.DFA_RATE_TH%type;
    dfaAmountTH DOC_FOOT_ALLOY.DFA_AMOUNT_TH%type;
    dfaRate     DOC_FOOT_ALLOY.DFA_RATE%type;
    dfaAmount   DOC_FOOT_ALLOY.DFA_AMOUNT%type;
  begin
    if aFootAlloyID is not null then
      GetRatesForOneFootAlloy(aFootAlloyID, aRateDate, dfaRateTH, dfaAmountTH, dfaRate, dfaAmount);

      update DOC_FOOT_ALLOY DFA
         set DFA.DFA_RATE_DATE = aRateDate
           , DFA.DFA_RATE_TH = dfaRateTH
           , DFA.DFA_AMOUNT_TH = dfaAmountTH
           , DFA.DFA_RATE = dfaRate
           , DFA.DFA_AMOUNT = dfaAmount
           , DFA.A_DATEMOD = sysdate
           , DFA.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DFA.DOC_FOOT_ALLOY_ID = aFootAlloyID;
    end if;
  end UpdateRatesForOneFootAlloy;

  /**
  * Description
  *   Recherche du compte poids de la matière pied
  */
  procedure GetStockID(
    aDocumentID                in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAlloyID                   in     GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialID           in     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aStockID                   in out STM_STOCK.STM_STOCK_ID%type
  , aThirdStockID              in     STM_STOCK.STM_STOCK_ID%type default null
  , aDefaultStockID            in     STM_STOCK.STM_STOCK_ID%type default null
  , aThirdID                   in     DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aThirdMaterialRelationType in     PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type default null
  , aAdminDomain               in     DOC_GAUGE.C_ADMIN_DOMAIN%type default null
  , aMaterialMgntMode          in     PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type default null
  )
  is
    bStop                      boolean;
    thirdStockID               STM_STOCK.STM_STOCK_ID%type;
    defaultStockID             STM_STOCK.STM_STOCK_ID%type;
    thirdID                    DOC_DOCUMENT.PAC_THIRD_ID%type;
    thaManaged                 PAC_THIRD_ALLOY.THA_MANAGED%type;
    cThirdMaterialRelationType PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type;
    cAdminDomain               DOC_GAUGE.C_ADMIN_DOMAIN%type;
    cMaterialMgntMode          PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    bStop  := false;

    if    aThirdStockID is null
       or aThirdID is null
       or aThirdMaterialRelationType is null
       or aAdminDomain is null
       or aMaterialMgntMode is null then
      begin
        select decode(GAU.C_ADMIN_DOMAIN, '1', SUP.STM_STOCK_ID, '2', CUS.STM_STOCK_ID, '5', SUP.STM_STOCK_ID, nvl(CUS.STM_STOCK_ID, SUP.STM_STOCK_ID) )
                                                                                                                                                    THIRD_STOCK
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                    , '2', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE)
                    , '5', nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                    , nvl(nvl(DMT.C_THIRD_MATERIAL_RELATION_TYPE, CUS.C_THIRD_MATERIAL_RELATION_TYPE), SUP.C_THIRD_MATERIAL_RELATION_TYPE)
                     ) C_THIRD_MATERIAL_RELATION_TYPE
             , decode(GAU.C_ADMIN_DOMAIN
                    , '1', SUP.C_MATERIAL_MGNT_MODE
                    , '2', CUS.C_MATERIAL_MGNT_MODE
                    , '5', SUP.C_MATERIAL_MGNT_MODE
                    , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                     ) C_MATERIAL_MGNT_MODE
             , DMT.PAC_THIRD_ID
             , GAU.C_ADMIN_DOMAIN
          into thirdStockID
             , cThirdMaterialRelationType
             , cMaterialMgntMode
             , thirdID
             , cAdminDomain
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
    else
      thirdStockID                := aThirdStockID;
      cThirdMaterialRelationType  := aThirdMaterialRelationType;
      cMaterialMgntMode           := aMaterialMgntMode;
      thirdID                     := aThirdID;
      cAdminDomain                := aAdminDomain;
    end if;

    if not bStop then
      -- Recherche le compte poids par défaut
      if aDefaultStockID is null then
        begin
          select STO.STM_STOCK_ID DEFAULT_STOCK
            into defaultStockID
            from STM_STOCK STO
           where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
             and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
        exception
          when no_data_found then
            defaultStockID  := null;
        end;
      else
        defaultStockID  := aDefaultStockID;
      end if;

      -- Recherche l'indicateur de gestion de la matière/alliage courante pour le tiers.
      thaManaged  := 0;

      begin
        if     cMaterialMgntMode = 1
           and aAlloyID is not null then
          if cAdminDomain = '1'
            or cAdminDomain = '5' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_SUPPLIER_PARTNER_ID = thirdID
               and THA.GCO_ALLOY_ID = aAlloyID;
          elsif cAdminDomain = '2' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_CUSTOM_PARTNER_ID = thirdID
               and THA.GCO_ALLOY_ID = aAlloyID;
          else
            thaManaged  := 1;
          end if;
        elsif     cMaterialMgntMode = 2
              and aBasisMaterialID is not null then
          if cAdminDomain = '1'
            or cAdminDomain = '5' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_SUPPLIER_PARTNER_ID = thirdID
               and THA.DIC_BASIS_MATERIAL_ID = aBasisMaterialID;
          elsif cAdminDomain = '2' then
            select nvl(THA.THA_MANAGED, 0)
              into thaManaged
              from PAC_THIRD_ALLOY THA
             where THA.PAC_CUSTOM_PARTNER_ID = thirdID
               and THA.DIC_BASIS_MATERIAL_ID = aBasisMaterialID;
          else
            thaManaged  := 1;
          end if;
        end if;
      exception
        when no_data_found then
          -- Si aucune matière/alliage n'est trouvée pour le tiers, le code de gestion est inactif.
          thaManaged  := null;
      end;

      -- Définission du compte poids en fonction du code de gestion de la matière/alliage et du type de relation tiers.
      -- C'est toujours le compte poids par défaut sauf dans le cas ou la matière/alliage est gérée et que le type
      -- de relation tiers est Facturé, dans ce cas, c'est le compte poids du tiers qui est initialisé.
      -- Si la matière n'est pas présente sur le tiers, ne pas initialiser le compte poids (aucun mvt généré)
      if (thaManaged is null) then
        aStockID  := null;
      elsif     (thaManaged = 1)
            and (cThirdMaterialRelationType <> '1') then
        aStockID  := thirdStockID;
      else
        aStockID  := defaultStockID;
      end if;
    end if;   -- not bStop
  end GetStockID;

  /**
  * Description
  *   Retourne le compte poids de la matière pied
  */
  function GetFootMatStockID(
    iDocumentID                in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iAlloyID                   in GCO_ALLOY.GCO_ALLOY_ID%type
  , iBasisMaterialID           in DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , iPositionAlloyStockID      in DOC_POSITION_ALLOY.STM_STOCK_ID%type
  , iThirdStockID              in STM_STOCK.STM_STOCK_ID%type default null
  , iDefaultStockID            in STM_STOCK.STM_STOCK_ID%type default null
  , iThirdID                   in DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , iThirdMaterialRelationType in PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type default null
  , iAdminDomain               in DOC_GAUGE.C_ADMIN_DOMAIN%type default null
  , iMaterialMgntMode          in PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type default null
  )
    return varchar2
  is
    lvStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    lvStockID  := iPositionAlloyStockID;
    GetStockID(aDocumentID                  => iDocumentID
             , aAlloyID                     => iAlloyID
             , aBasisMaterialID             => iBasisMaterialID
             , aStockID                     => lvStockID
             , aThirdStockID                => iThirdStockID
             , aDefaultStockID              => iDefaultStockID
             , aThirdID                     => iThirdID
             , aThirdMaterialRelationType   => iThirdMaterialRelationType
             , aAdminDomain                 => iAdminDomain
             , aMaterialMgntMode            => iMaterialMgntMode
              );
    return lvStockID;
  end GetFootMatStockID;

  /**
  * Description
  *   Retourne le stock disponible du compte poids de la matière pied
  */
  function GetFootMatStockQuantity(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iFootMatStockID in DOC_FOOT_ALLOY.STM_STOCK_ID%type)
    return number
  is
    lnLocationID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    if iFootMatStockID is null then
      return 0;
    else
      -- Recherche le premier emplacement du compte poids dans l'ordre des classements.
      select LOC.STM_LOCATION_ID
        into lnLocationID
        from STM_LOCATION LOC
       where LOC.STM_STOCK_ID = iFootMatStockID
         and LOC.LOC_CLASSIFICATION = (select min(LOC2.LOC_CLASSIFICATION)
                                         from STM_LOCATION LOC2
                                        where LOC2.STM_STOCK_ID = iFootMatStockID);

      return STM_FUNCTIONS.GetRealStockQuantity(iGoodID, null, lnLocationID, null, null, null, null, null, null, null, null, null, null);
    end if;
  end GetFootMatStockQuantity;

  /**
  * Description
  *   test if document will generate alloy movements
  */
  function documentWithAlloyMovements(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return boolean
  is
    lWeightMat         DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    lMetalAccountMgm   DOC_GAUGE_STRUCTURED.GAS_METAL_ACCOUNT_MGM%type;
    lMovementKindId    DOC_GAUGE_POSITION.STM_MOVEMENT_KIND_ID%type;
    lThirdMetalAccount PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    lMngtMode          PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    if PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') = '1' then
      -- Recherche globale d'informations pour la génération des mouvements
      select nvl(GAS.GAS_WEIGHT_MAT, 0)
           , nvl(GAS.GAS_METAL_ACCOUNT_MGM, 0)
           , nvl(decode(GAU.C_ADMIN_DOMAIN
                      , 1, SUP.CRE_METAL_ACCOUNT
                      , 2, CUS.CUS_METAL_ACCOUNT
                      , 5, SUP.CRE_METAL_ACCOUNT
                      , nvl(CUS.CUS_METAL_ACCOUNT, SUP.CRE_METAL_ACCOUNT)
                       )
               , 0
                ) METAL_ACCOUNT
           , MOK.STM_MOVEMENT_KIND_ID
           , decode(GAU.C_ADMIN_DOMAIN
                  , 1, SUP.C_MATERIAL_MGNT_MODE
                  , 2, CUS.C_MATERIAL_MGNT_MODE
                  , 5, SUP.C_MATERIAL_MGNT_MODE
                  , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                   ) C_MATERIAL_MGNT_MODE
        into lWeightMat
           , lMetalAccountMgm
           , lThirdMetalAccount
           , lMovementKindId
           , lMngtMode
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_POSITION GAP
           , STM_MOVEMENT_KIND MOK
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_CUSTOM_PARTNER CUS
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
         and GAP.GAP_DEFAULT = 1
         and GAP.C_GAUGE_TYPE_POS = '1'
         and (    (    MOK.C_MOVEMENT_SORT = 'SOR'
                   and MOK.MOK_STANDARD_SIGN = 1)
              or (    MOK.C_MOVEMENT_SORT = 'ENT'
                  and MOK.MOK_STANDARD_SIGN = -1) )
         and nvl(GAP.STM_MA_MOVEMENT_KIND_ID, GAP.STM_MOVEMENT_KIND_ID) = MOK.STM_MOVEMENT_KIND_ID
         and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+);

      return     (lWeightMat = 1)
             and (lMetalAccountMgm = 1)
             and (lThirdMetalAccount = 1)
             and (lMovementKindId is not null)
             and (lMngtMode is not null);
    else
      return false;
    end if;
  exception
    when no_data_found then
      return false;
  end documentWithAlloyMovements;
end DOC_FOOT_ALLOY_FUNCTIONS;
