--------------------------------------------------------
--  DDL for Package Body DOC_OTHER_COST_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_OTHER_COST_FUNCTIONS" 
is
  /**
  * function GetTotalRefValue
  * Description
  *   recherche la valeur de référence pour la création des taxes autres couts
  */
  function GetTotalRefValue(
    aDocumentID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSharingMode     in DOC_FOOT_ALLOY.C_SHARING_MODE%type
  , aMatManagMode    in PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAlloyID         in GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialID in DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  )
    return number
  is
    totRefValue number(18, 6) := 0;
  begin
    -- 01 : Valeur brute ht des positions
    if aSharingMode = '01' then
      select sum(nvl(POS_GROSS_VALUE, 0) )
        into totRefValue
        from DOC_POSITION
       where DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05';
    -- 02 : Quantité des positions
    elsif aSharingMode = '02' then
      select sum(nvl(POS_FINAL_QUANTITY, 0) )
        into totRefValue
        from DOC_POSITION
       where DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05';
    -- 03 : Volume net des positions
    elsif aSharingMode = '03' then
      select sum(nvl(POS_FINAL_QUANTITY, 0) * nvl(MEA_NET_VOLUME, 0) )
        into totRefValue
        from DOC_POSITION POS
           , GCO_MEASUREMENT_WEIGHT MEA
       where POS.DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05'
         and MEA.GCO_GOOD_ID = POS.GCO_GOOD_ID;
    -- 04 : Volume brut des positions
    elsif aSharingMode = '04' then
      select sum(nvl(POS_FINAL_QUANTITY, 0) * nvl(MEA_GROSS_VOLUME, 0) )
        into totRefValue
        from DOC_POSITION POS
           , GCO_MEASUREMENT_WEIGHT MEA
       where POS.DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05'
         and MEA.GCO_GOOD_ID = POS.GCO_GOOD_ID;
    -- 05 : Poids net des positions
    elsif aSharingMode = '05' then
      select sum(nvl(POS_NET_WEIGHT, 0) )
        into totRefValue
        from DOC_POSITION
       where DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05';
    -- 06 : Poids brut des positions
    elsif aSharingMode = '06' then
      select sum(nvl(POS_GROSS_WEIGHT, 0) )
        into totRefValue
        from DOC_POSITION
       where DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05';
    -- 07 : Poids matières précieuses
    elsif     aSharingMode = '07'
          and aMatManagMode is not null then
      -- 1 : Alliages
      if aMatManagMode = '1' then
        select sum(DOA.DOA_WEIGHT_DELIVERY)
          into totRefValue
          from DOC_POSITION_ALLOY DOA
             , DOC_POSITION POS
         where DOA.DOC_DOCUMENT_ID = aDocumentID
           and DOA.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and (   DOA.GCO_ALLOY_ID = aAlloyId
                or (    DOA.GCO_ALLOY_ID is not null
                    and aAlloyID is null) )
           and POS.C_DOC_POS_STATUS <> '05';
      -- 2 : Matières de base
      elsif aMatManagMode = '2' then
        select sum(DOA.DOA_WEIGHT_DELIVERY)
          into totRefValue
          from DOC_POSITION_ALLOY DOA
             , DOC_POSITION POS
         where DOA.DOC_DOCUMENT_ID = aDocumentID
           and DOA.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and (   DOA.DIC_BASIS_MATERIAL_ID = aBasisMaterialID
                or (    DOA.DIC_BASIS_MATERIAL_ID is not null
                    and aBasisMaterialID is null)
               )
           and POS.C_DOC_POS_STATUS <> '05';
      end if;
    -- 08 : Valeur nette HT des positions
    elsif aSharingMode = '08' then
      select sum(nvl(POS_NET_VALUE_EXCL, 0) )
        into totRefValue
        from DOC_POSITION
       where DOC_DOCUMENT_ID = aDocumentID
         and C_GAUGE_TYPE_POS <> '6'
         and C_DOC_POS_STATUS <> '05';
    end if;

    return totRefValue;
  end GetTotalRefValue;

  /**
  * procedure GeneratePosOtherCostCharge
  * Description
  *   Génération des taxes de position pour les autres coûts
  * @created fp 24.03.2004
  * @updated sma 11.09.2013
  */
  procedure GeneratePosOtherCostCharge(
    aCurDocumentID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSrcDocumentID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aChargeName       in     PTC_CHARGE.CRG_NAME%type
  , aDicCostFootID    in     DOC_FOOT_ALLOY.DIC_COST_FOOT_ID%type
  , aChargeAmount     in     DOC_FOOT_ALLOY.DFA_AMOUNT%type
  , atotRefValue      in     number
  , aMaterialMgntMode in     PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type
  , aAlloyId          in     GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialId  in     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aSharingMode      in     DOC_FOOT_ALLOY.C_SHARING_MODE%type
  , aGenerated        out    number
  )
  is
    cursor crDocumentInfo(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cChargeName PTC_CHARGE.CRG_NAME%type)
    is
      select GAU.C_ADMIN_DOMAIN
           , CRG.CRG_NAME
           , CHD.CHD_DESCR
           , DMT.DOC_DOCUMENT_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DOC_GAUGE_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.PC_LANG_ID
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
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
        from DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , PTC_CHARGE CRG
           , PTC_CHARGE_DESCRIPTION CHD
       where DMT.DOC_DOCUMENT_ID = cDocumentId
         and CRG.CRG_NAME = cChargeName
         and CHD.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
         and CHD.PC_LANG_ID(+) = DMT.PC_LANG_ID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    tplDocumentInfo crDocumentInfo%rowtype;

    cursor crPositionOtherCost(cDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_GROSS_VALUE
           , POS.POS_NET_VALUE_EXCL
           , POS.POS_FINAL_QUANTITY
           , nvl(POS_FINAL_QUANTITY, 0) * nvl(MEA_NET_VOLUME, 0) MEA_NET_VOLUME
           , nvl(POS_FINAL_QUANTITY, 0) * nvl(MEA_GROSS_VOLUME, 0) MEA_GROSS_VOLUME
           , nvl(POS_NET_WEIGHT, 0) POS_NET_WEIGHT
           , nvl(POS_GROSS_WEIGHT, 0) POS_GROSS_WEIGHT
           , POS.DOC_RECORD_ID
           , POS.PAC_THIRD_ID
           , POS.PAC_THIRD_ACI_ID
        from DOC_POSITION POS
           , GCO_MEASUREMENT_WEIGHT MEA
       where POS.DOC_DOCUMENT_ID = cDocumentID
         and MEA.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
         and POS.C_DOC_POS_STATUS <> '05' -- Status position : annulé
         and POS.C_GAUGE_TYPE_POS <> '6';

    accountInfo     ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    sumCharge       DOC_POSITION_CHARGE.PCH_AMOUNT%type               := 0;
    corrAmountB     DOC_POSITION_CHARGE.PCH_AMOUNT%type               := 0;
    lastId          DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type;
  begin
    open crDocumentInfo(aCurDocumentID, aChargeName);

    fetch crDocumentInfo
     into tplDocumentInfo;

    close crDocumentInfo;

    if tplDocumentInfo.DOC_DOCUMENT_ID is not null then
      -- curseur sur les positions
      for tplPositionOtherCost in crPositionOtherCost(aSrcDocumentID) loop
        declare
          -- déclaré dans la boucle FOR pour éviter de devoir réinitialiser chaque champ du record l'un après l'autre à chaque passage
          recPositionCharge DOC_POSITION_CHARGE%rowtype;
          tmpPositionID     DOC_POSITION.DOC_POSITION_ID%type;
          tmpRecordID       DOC_POSITION.DOC_RECORD_ID%type;
          tmpTHIRD_ID       DOC_POSITION.PAC_THIRD_ID%type;
          tmpTHIRD_ACI_ID   DOC_POSITION.PAC_THIRD_ACI_ID%type;
          tmpPOS_ACS_FIN_ID DOC_POSITION.ACS_FINANCIAL_ACCOUNT_ID%type;
          tmpPOS_ACS_DIV_ID DOC_POSITION.ACS_DIVISION_ACCOUNT_ID%type;
          tmpPOS_ACS_CPN_ID DOC_POSITION.ACS_CPN_ACCOUNT_ID%type;
          tmpPOS_ACS_CDA_ID DOC_POSITION.ACS_CDA_ACCOUNT_ID%type;
          tmpPOS_ACS_PF_ID  DOC_POSITION.ACS_PF_ACCOUNT_ID%type;
          tmpPOS_ACS_PJ_ID  DOC_POSITION.ACS_PJ_ACCOUNT_ID%type;
        begin
          if aCurDocumentID = aSrcDocumentID then
            tmpPositionID    := tplPositionOtherCost.DOC_POSITION_ID;
            tmpRecordID      := tplPositionOtherCost.DOC_RECORD_ID;
            tmpTHIRD_ID      := tplPositionOtherCost.PAC_THIRD_ID;
            tmpTHIRD_ACI_ID  := tplPositionOtherCost.PAC_THIRD_ACI_ID;
          else
            begin
              -- rechercher la position du document courant qui correspond à la décharge de l'ID de la position source
              select POS.DOC_POSITION_ID
                   , POS.DOC_RECORD_ID
                   , POS.PAC_THIRD_ID
                   , POS.PAC_THIRD_ACI_ID
                into tmpPositionID
                   , tmpRecordID
                   , tmpTHIRD_ID
                   , tmpTHIRD_ACI_ID
                from DOC_POSITION POS
                   , DOC_POSITION_DETAIL PDE
               where POS.DOC_DOCUMENT_ID = aCurDocumentID
                 and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                 and PDE.DOC2_DOC_POSITION_DETAIL_ID = (select max(DOC_POSITION_DETAIL_ID)
                                                          from DOC_POSITION_DETAIL
                                                         where DOC_POSITION_ID = tplPositionOtherCost.DOC_POSITION_ID);
            exception
              when no_data_found then
                tmpPositionID  := null;
            end;
          end if;

          if tmpPositionID is not null then
            -- recherche de l'id de la taxe que l'on va créer
            select init_id_Seq.nextval
              into recPositionCharge.DOC_POSITION_CHARGE_ID
              from dual;

            -- Si gestion des comptes financiers ou analytiques
            if    (tplDocumentInfo.GAS_FINANCIAL = 1)
               or (tplDocumentInfo.GAS_ANALYTICAL = 1) then
              -- Rechercher les comptes de la position
              select ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID
                   , ACS_CDA_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID
                   , ACS_PJ_ACCOUNT_ID
                into tmpPOS_ACS_FIN_ID
                   , tmpPOS_ACS_DIV_ID
                   , tmpPOS_ACS_CPN_ID
                   , tmpPOS_ACS_CDA_ID
                   , tmpPOS_ACS_PF_ID
                   , tmpPOS_ACS_PJ_ID
                from DOC_POSITION
               where DOC_POSITION_ID = tmpPositionID;

              -- Utilise les comptes de la taxe
              recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID  := tplDocumentInfo.ACS_FINANCIAL_ACCOUNT_ID;
              recPositionCharge.ACS_DIVISION_ACCOUNT_ID   := tplDocumentInfo.ACS_DIVISION_ACCOUNT_ID;
              recPositionCharge.ACS_CPN_ACCOUNT_ID        := tplDocumentInfo.ACS_CPN_ACCOUNT_ID;
              recPositionCharge.ACS_CDA_ACCOUNT_ID        := tplDocumentInfo.ACS_CDA_ACCOUNT_ID;
              recPositionCharge.ACS_PF_ACCOUNT_ID         := tplDocumentInfo.ACS_PF_ACCOUNT_ID;
              recPositionCharge.ACS_PJ_ACCOUNT_ID         := tplDocumentInfo.ACS_PJ_ACCOUNT_ID;
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
              ACS_I_LIB_LOGISTIC_FINANCIAL.GetDCAccounts(tplDocumentInfo.PTC_CHARGE_ID
                                                       , '30'
                                                       , tplDocumentInfo.C_ADMIN_DOMAIN
                                                       , tplDocumentInfo.DMT_DATE_DOCUMENT
                                                       , tplDocumentInfo.DOC_GAUGE_ID
                                                       , tplDocumentInfo.DOC_DOCUMENT_ID
                                                       , tmpPositionID
                                                       , tmpRecordID
                                                       , tmpTHIRD_ACI_ID
                                                       , tmpPOS_ACS_FIN_ID
                                                       , tmpPOS_ACS_DIV_ID
                                                       , tmpPOS_ACS_CPN_ID
                                                       , tmpPOS_ACS_CDA_ID
                                                       , tmpPOS_ACS_PF_ID
                                                       , tmpPOS_ACS_PJ_ID
                                                       , recPositionCharge.ACS_FINANCIAL_ACCOUNT_ID
                                                       , recPositionCharge.ACS_DIVISION_ACCOUNT_ID
                                                       , recPositionCharge.ACS_CPN_ACCOUNT_ID
                                                       , recPositionCharge.ACS_CDA_ACCOUNT_ID
                                                       , recPositionCharge.ACS_PF_ACCOUNT_ID
                                                       , recPositionCharge.ACS_PJ_ACCOUNT_ID
                                                       , accountInfo
                                                        );

              if (tplDocumentInfo.GAS_ANALYTICAL = 0) then
                recPositionCharge.ACS_CPN_ACCOUNT_ID  := null;
                recPositionCharge.ACS_CDA_ACCOUNT_ID  := null;
                recPositionCharge.ACS_PJ_ACCOUNT_ID   := null;
                recPositionCharge.ACS_PF_ACCOUNT_ID   := null;
              end if;
            end if;

            -- calcul du montant de taxe selon le mode de répartition
            if aSharingMode = '01' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.POS_GROSS_VALUE * aChargeAmount / atotRefValue;
            elsif aSharingMode = '02' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.POS_FINAL_QUANTITY * aChargeAmount / atotRefValue;
            elsif aSharingMode = '03' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.MEA_NET_VOLUME * aChargeAmount / atotRefValue;
            elsif aSharingMode = '04' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.MEA_GROSS_VOLUME * aChargeAmount / atotRefValue;
            elsif aSharingMode = '05' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.POS_NET_WEIGHT * aChargeAmount / atotRefValue;
            elsif aSharingMode = '06' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.POS_GROSS_WEIGHT * aChargeAmount / atotRefValue;
            elsif aSharingMode = '07' then
              if aMaterialMgntMode = '1' then
                select sum(DOA_WEIGHT_DELIVERY * aChargeAmount / atotRefValue)
                  into recPositionCharge.PCH_AMOUNT
                  from DOC_POSITION_ALLOY DOA
                 where (   GCO_ALLOY_ID = aAlloyId
                        or (    aAlloyId is null
                            and GCO_ALLOY_ID is not null) )
                   and DOC_POSITION_ID = tplPositionOtherCost.DOC_POSITION_ID;
              elsif aMaterialMgntMode = '2' then
                select sum(DOA_WEIGHT_DELIVERY * aChargeAmount / atotRefValue)
                  into recPositionCharge.PCH_AMOUNT
                  from DOC_POSITION_ALLOY DOA
                 where (   DIC_BASIS_MATERIAL_ID = aBasisMaterialId
                        or (    aBasisMaterialId is null
                            and DIC_BASIS_MATERIAL_ID is not null) )
                   and DOC_POSITION_ID = tplPositionOtherCost.DOC_POSITION_ID;
              end if;
            elsif aSharingMode = '08' then
              recPositionCharge.PCH_AMOUNT  := tplPositionOtherCost.POS_NET_VALUE_EXCL * aChargeAmount / atotRefValue;
            end if;

            -- calcul du montant fixe en monnaie de base
            select ACS_FUNCTION.ConvertAmountForView(recPositionCharge.PCH_AMOUNT
                                                   , tplDocumentInfo.ACS_FINANCIAL_CURRENCY_ID
                                                   , ACS_FUNCTION.GetLocalCurrencyId
                                                   , tplDocumentInfo.DMT_DATE_DOCUMENT
                                                   , tplDocumentInfo.DMT_RATE_OF_EXCHANGE
                                                   , tplDocumentInfo.DMT_BASE_PRICE
                                                   , 0
                                                    )
              into recPositionCharge.PCH_FIXED_AMOUNT_B
              from dual;

            recPositionCharge.DOC_POSITION_ID            := tmpPositionID;
            recPositionCharge.C_CHARGE_ORIGIN            := 'OC';
            recPositionCharge.C_FINANCIAL_CHARGE         := '03';
            recPositionCharge.PCH_NAME                   := aChargeName;
            recPositionCharge.PCH_DESCRIPTION            :=
                               tplDocumentInfo.CHD_DESCR || ' - ' || COM_DIC_FUNCTIONS.GetDicoDescr('DIC_COST_FOOT', aDicCostFootID, tplDocumentInfo.PC_LANG_ID);
            recPositionCharge.C_CALCULATION_MODE         := '0';
            recPositionCharge.PCH_IN_SERIES_CALCULATION  := tplDocumentInfo.CRG_IN_SERIE_CALCULATION;
            recPositionCharge.PCH_EXCLUSIVE              := tplDocumentInfo.CRG_EXCLUSIVE;
            recPositionCharge.PCH_PRCS_USE               := tplDocumentInfo.CRG_PRCS_USE;
            recPositionCharge.PCH_MODIFY                 := 0;
            recPositionCharge.PTC_CHARGE_ID              := tplDocumentInfo.PTC_CHARGE_ID;
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

            -- compteur de montant total et mémorisation du dernier id (seulement pour les taxes différentes de 0
            if recPositionCharge.PCH_AMOUNT <> 0 then
              DOC_DISCOUNT_CHARGE.InsertPositionCharge(recPositionCharge);
              sumCharge  := sumCharge + recPositionCharge.PCH_AMOUNT;
              lastId     := recPositionCharge.DOC_POSITION_CHARGE_ID;

              -- Màj des flags de la position pour que les montants soient recalculés
              update DOC_POSITION
                 set POS_CREATE_POSITION_CHARGE = 0
                   , POS_UPDATE_POSITION_CHARGE = 1
                   , POS_RECALC_AMOUNTS = 1
               where DOC_POSITION_ID = tmpPositionID;

              -- calcul du montant fixe en monnaie de base
              select ACS_FUNCTION.ConvertAmountForView(aChargeAmount - sumCharge
                                                     , tplDocumentInfo.ACS_FINANCIAL_CURRENCY_ID
                                                     , ACS_FUNCTION.GetLocalCurrencyId
                                                     , tplDocumentInfo.DMT_DATE_DOCUMENT
                                                     , tplDocumentInfo.DMT_RATE_OF_EXCHANGE
                                                     , tplDocumentInfo.DMT_BASE_PRICE
                                                     , 0
                                                      )
                into corrAmountB
                from dual;
            end if;
          end if;
        end;
      end loop;

      -- correction si le total des taxes ne correspond au montant total du coût
      if sumCharge <> aChargeAmount then
        update DOC_POSITION_CHARGE
           set PCH_AMOUNT = PCH_AMOUNT +(aChargeAmount - sumCharge)
             , PCH_FIXED_AMOUNT = PCH_AMOUNT +(aChargeAmount - sumCharge)
             , PCH_FIXED_AMOUNT_B = corrAmountB
         where DOC_POSITION_CHARGE_ID = lastId;
      end if;
    end if;
  end GeneratePosOtherCostCharge;

  /**
  * procedure CreateOtherCostPositions
  * Description
  *   procédure de création des positions factices pour contenir les taxes autres couts
  *     concernant les documents liés de la table DOC_FOOT_ALLOY
  */
  procedure CreateOtherCostPositions(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Création des positions factices par copie, pour la gestion des autres couts
    -- en fonction des documents liés de la table DOC_FOOT_ALLOY
    for tplSrcPos in (select distinct POS.DOC_POSITION_ID
                                    , POS.DOC_DOCUMENT_ID
                                 from DOC_POSITION POS
                                    , DOC_FOOT_ALLOY DFA
                                where DFA.DOC_FOOT_ID = aDocumentID
                                  and DFA.DOC_DOC_DOCUMENT_ID is not null
                                  and DFA.DOC_DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                                  and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10')
                             order by POS.DOC_DOCUMENT_ID
                                    , POS.DOC_POSITION_ID) loop
      declare
        -- Variable pour l'id de la nouvelle position déclaré ici pour ne pas avoir à le réinitialiser chaque fois
        newPosID DOC_POSITION.DOC_POSITION_ID%type;
      begin
        -- Copie de la position
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => newPosID
                                             , aDocumentID               => aDocumentID
                                             , aPosCreateMode            => '205'
                                             , aSrcPositionID            => tplSrcPos.DOC_POSITION_ID
                                             , aBasisQuantity            => 0
                                             , aGoodPrice                => 0
                                             , aGenerateDetail           => 1
                                             , aGenerateCPT              => 1
                                             , aGenerateDiscountCharge   => 0
                                              );
      end;
    end loop;
  end CreateOtherCostPositions;

  /**
  * Description
  *   procédure de génération des taxes de position relatives aux autres coûts
  */
  function GenerateOtherCostCharge(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aGenerated out number)
    return number
  is
    cursor crFootCost(cFootId number)
    is
      select C_SHARING_MODE
           , DIC_COST_FOOT_ID
           , GCO_ALLOY_ID
           , DIC_BASIS_MATERIAL_ID
           , DFA_AMOUNT
           , DOC_FOOT_ID
        from DOC_FOOT_ALLOY
       where DOC_FOOT_ID = cFootId
         and DIC_COST_FOOT_ID is not null
         and DOC_DOC_DOCUMENT_ID is null;

    cursor crFootCostLinkedDoc(cFootId number)
    is
      select C_SHARING_MODE
           , DIC_COST_FOOT_ID
           , GCO_ALLOY_ID
           , DIC_BASIS_MATERIAL_ID
           , DFA_AMOUNT
           , DOC_DOC_DOCUMENT_ID
        from DOC_FOOT_ALLOY
       where DOC_FOOT_ID = cFootId
         and DIC_COST_FOOT_ID is not null
         and DOC_DOC_DOCUMENT_ID is not null;

    adminDomain      DOC_GAUGE.C_ADMIN_DOMAIN%type;
    chargeName       PTC_CHARGE.CRG_NAME%type;
    materialMgntMode PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type;
    thirdId          PAC_THIRD.PAC_THIRD_ID%type;
    totRefValue      number(18, 6)                                    := 0;
    vResult          number(1)                                        := 0;
  begin
    -- recherche du domaine
    select GAU.C_ADMIN_DOMAIN
         , DMT.PAC_THIRD_ID
      into adminDomain
         , thirdId
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = aDocumentID
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

    -- recherche de la liste des taxes selon le domaine
    if thirdId is not null then
      if adminDomain = '1' then
        select C_MATERIAL_MGNT_MODE
          into materialMgntMode
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = thirdId;

        chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_COST_CHARGE_PURCHASE');
      elsif adminDomain = '2' then
        select C_MATERIAL_MGNT_MODE
          into materialMgntMode
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = thirdId;

        chargeName  := PCS.PC_CONFIG.GetConfig('DOC_MAT_COST_CHARGE_SALE');
      end if;
    end if;

    -- Effacer les positions du document courant pour la gestion des autres
    for tplDeletePos in (select DOC_POSITION_ID
                           from DOC_POSITION
                          where DOC_DOCUMENT_ID = aDocumentID
                            and C_POS_CREATE_MODE = '205'
                            and POS_BASIS_QUANTITY = 0) loop
      DOC_DELETE.DeletePosition(tplDeletePos.DOC_POSITION_ID, false);
      -- si des positions sont effacées, alors il faudra recalculer les montants du doc
      vResult  := 1;
    end loop;

    --supression des taxes "Matières premières" déjà existantes
    declare
      lnDelCount integer;
    begin
      delete from DOC_POSITION_CHARGE
            where DOC_DOCUMENT_ID = aDocumentID
              and DOC_DOC_POSITION_CHARGE_ID is null
              and C_CHARGE_ORIGIN = 'OC'
        returning count(*)
             into lnDelCount;

      -- si des taxes ont été effacées, alors il faudra recalculer les montants du doc
      if lnDelCount > 0 then
        vResult  := 1;
      end if;
    end;

    -- Création des taxes autres couts concernant les positions du document courant
    for tplFootCost in crFootCost(aDocumentID) loop
      -- indique qu'on est en présence d'autre couts
      vResult      := 1;
      totRefValue  := GetTotalRefValue(aDocumentID, tplFootCost.C_SHARING_MODE, materialMgntMode, tplFootCost.GCO_ALLOY_ID, tplFootCost.DIC_BASIS_MATERIAL_ID);

      if totRefValue <> 0 then
        GeneratePosOtherCostCharge(aDocumentID
                                 , aDocumentID
                                 , ChargeName
                                 , tplFootCost.DIC_COST_FOOT_ID
                                 , tplFootCost.DFA_AMOUNT
                                 , totRefValue
                                 , materialMgntMode
                                 , tplFootCost.GCO_ALLOY_ID
                                 , tplFootCost.DIC_BASIS_MATERIAL_ID
                                 , tplFootCost.C_SHARING_MODE
                                 , aGenerated
                                  );
      end if;
    end loop;

    -- Création des positions en référence aux documents liés dans les données des autres coûts
    CreateOtherCostPositions(aDocumentID);

    -- Création des taxes autres couts pour les positions crées ci-dessus en se basant sur les positions des documents liés
    for tplFootCostLinkedDoc in crFootCostLinkedDoc(aDocumentID) loop
      -- indique qu'on est en présence d'autre couts
      vResult      := 1;
      totRefValue  :=
        GetTotalRefValue(tplFootCostLinkedDoc.DOC_DOC_DOCUMENT_ID
                       , tplFootCostLinkedDoc.C_SHARING_MODE
                       , materialMgntMode
                       , tplFootCostLinkedDoc.GCO_ALLOY_ID
                       , tplFootCostLinkedDoc.DIC_BASIS_MATERIAL_ID
                        );

      if totRefValue <> 0 then
        GeneratePosOtherCostCharge(aDocumentID
                                 , tplFootCostLinkedDoc.DOC_DOC_DOCUMENT_ID
                                 , ChargeName
                                 , tplFootCostLinkedDoc.DIC_COST_FOOT_ID
                                 , tplFootCostLinkedDoc.DFA_AMOUNT
                                 , totRefValue
                                 , materialMgntMode
                                 , tplFootCostLinkedDoc.GCO_ALLOY_ID
                                 , tplFootCostLinkedDoc.DIC_BASIS_MATERIAL_ID
                                 , tplFootCostLinkedDoc.C_SHARING_MODE
                                 , aGenerated
                                  );
      end if;
    end loop;

    return vResult;
  end GenerateOtherCostCharge;
end DOC_OTHER_COST_FUNCTIONS;
