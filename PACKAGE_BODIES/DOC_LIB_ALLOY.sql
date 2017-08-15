--------------------------------------------------------
--  DDL for Package Body DOC_LIB_ALLOY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_ALLOY" 
is
  /**
  * Description
  *    Indique si pour un alliage donné, un compte poids autorise une quantité négative
  */
  function StockDeficitControl(iStockId in STM_STOCK.STM_STOCK_ID%type, iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lThirdID         PAC_THIRD.PAC_THIRD_ID%type;
    lnDeficitAllowed integer;
  begin
    -- Contrôle si le stock est un compte poids de type bancaire
    begin
      select PAC_THIRD_ID
        into lThirdID
        from STM_STOCK
       where STM_STOCK_ID = iStockId
         and C_STO_METAL_ACCOUNT_TYPE = 1   -- type de compte bancaire -> autorise le découvert
         and STO_METAL_ACCOUNT = 1;   -- compte poids
    exception
      when no_data_found then
        -- PCS - Une position du stock [STOCK] (emplacement [LOCATION]) pour le bien [GOOD] est en rupture de stock.
        return 1;
    end;

    -- Pas de tiers défini sur le compte poids
    if lThirdID is null then
      -- PCS - La quantité en stock ne peut être négative. Le bien [GOOD] n''est pas lié au compte poids [CPT]
      return 7;
    end if;

    -- control if precious mat is linked to metal account
    begin   --exception supplier - alloy
      select 1
        into lnDeficitAllowed
        from PAC_SUPPLIER_PARTNER SUP
           , PAC_THIRD_ALLOY ALO
           , GCO_ALLOY GAL
       where SUP.PAC_SUPPLIER_PARTNER_ID = lThirdID
         and ALO.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and ALO.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID   -- good is bounded to an alloy .
         and SUP.CRE_METAL_ACCOUNT = 1   -- Supplier manages a metal account
         and SUP.C_MATERIAL_MGNT_MODE = 1   -- Supplier manages metal account in alloys
         and ALO.THA_MANAGED = 1   -- Alloy is managed for this supplier
         and GAL.GCO_GOOD_ID = iGoodId
         and GAL.GAL_DEFICIT_ALLOWED = 1;   -- Déficit autorisé
    exception
      when no_data_found then
        lnDeficitAllowed  := 0;   -- next test
      when others then
        -- par exemple,
        -- 2 alliages avec le même produit lié --> interdit!
        -- Paramétrage du tiers, de l''alliage ou du compte-poids à vérifier. Compte-poids négatif refusé!
        return 2;
    end;   -- exception supplier alloy

    if lnDeficitAllowed = 0 then
      begin   --exception supplier - basis material
        select 1
          into lnDeficitAllowed
          from PAC_SUPPLIER_PARTNER SUP
             , PAC_THIRD_ALLOY ALO
             , GCO_ALLOY GAL
             , GCO_ALLOY_COMPONENT GAC
         where SUP.PAC_SUPPLIER_PARTNER_ID = lThirdID
           and ALO.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and ALO.DIC_BASIS_MATERIAL_ID = GAC.DIC_BASIS_MATERIAL_ID
           and GAC.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
           and SUP.CRE_METAL_ACCOUNT = 1   -- Supplier manages a metal account
           and SUP.C_MATERIAL_MGNT_MODE = 2   -- Supplier manages metal account in basis materials
           and ALO.THA_MANAGED = 1   -- Basis material is managed for this supplier
           and GAC.GAC_RATE = 100   -- Alloy is 100% of the basis material .
           and GAL.GCO_GOOD_ID = iGoodId
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- Déficit autorisé
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- for exemple,
          -- 2 alloy with the same bounded good --> forbidden !
          -- Paramétrage du tiers, de l''alliage ou du compte-poids à vérifier. Compte-poids négatif refusé!
          return 3;
      end;   -- exception supplier basis material
    end if;

    if lnDeficitAllowed = 0 then
      begin   -- exception Customer - alloy .
        select 1
          into lnDeficitAllowed
          from PAC_CUSTOM_PARTNER CUS
             , PAC_THIRD_ALLOY ALO
             , GCO_ALLOY GAL
         where CUS.PAC_CUSTOM_PARTNER_ID = lThirdID
           and ALO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and ALO.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID   -- good is bounded to an alloy .
           and CUS.CUS_METAL_ACCOUNT = 1   -- Customer manages a metal account
           and CUS.C_MATERIAL_MGNT_MODE = 1   -- Customer manages metal account in alloys
           and ALO.THA_MANAGED = 1   -- Alloy is managed for this customer
           and GAL.GCO_GOOD_ID = iGoodId
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- Déficit autorisé
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- 2 alloy with the same bounded good --> forbidden !
          -- Paramétrage du tiers, de l''alliage ou du compte-poids à vérifier. Compte-poids négatif refusé!
          return 4;
      end;   -- exception Customer - alloy
    end if;

    if lnDeficitAllowed = 0 then
      begin   --exception Customer - basis material
        select 1
          into lnDeficitAllowed
          from PAC_CUSTOM_PARTNER CUS
             , PAC_THIRD_ALLOY ALO
             , GCO_ALLOY GAL
             , GCO_ALLOY_COMPONENT GAC
         where CUS.PAC_CUSTOM_PARTNER_ID = lThirdID
           and ALO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and ALO.DIC_BASIS_MATERIAL_ID = GAC.DIC_BASIS_MATERIAL_ID
           and GAC.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
           and CUS.CUS_METAL_ACCOUNT = 1   -- Customer manages a metal account
           and CUS.C_MATERIAL_MGNT_MODE = 2   -- Supplier manages metal account in basis materials
           and ALO.THA_MANAGED = 1   -- Basis material is managed for this Customer
           and GAC.GAC_RATE = 100   -- Alloy is 100% of the basis material .
           and GAL.GCO_GOOD_ID = iGoodId
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- Déficit autorisé
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- for exemple,
          -- 2 alloy with the same bounded good --> forbidden !
          -- PCS - Paramétrage du tiers, de l''alliage ou du compte-poids à vérifier. Compte-poids négatif refusé!
          return 5;
      end;   -- exception Customer basis material
    end if;

    if lnDeficitAllowed = 0 then
      -- PCS - Paramétrage du tiers, de l''alliage ou du compte-poids à vérifier. Compte-poids négatif refusé!'
      return 6;
    end if;

    return 0;
  end StockDeficitControl;

  /**
  * Description
  *   Recherche le cours de la matière précieuse sur le pied de document
  */
  function GetAlloyRate(
    lDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , lAlloyId       in DOC_POSITION_ALLOY.GCO_ALLOY_ID%type
  , lDicBasisMatId in DOC_POSITION_ALLOY.DIC_BASIS_MATERIAL_ID%type
  , lDateRef       in DOC_POSITION_ALLOY.DOA_RATE_DATE%type
  )
    return DOC_FOOT_ALLOY.DFA_RATE%type
  is
    lResult DOC_FOOT_ALLOY.DFA_RATE%type;
  begin
    if lAlloyId is not null then
      -- Gestion d'alliage
      select DFA.DFA_RATE
        into lResult
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = lDocumentID
         and DFA.GCO_ALLOY_ID = lAlloyId
         and nvl(DFA.DFA_RATE_DATE, sysdate) = nvl(lDateRef, sysdate);
    else
      -- Gestion matière pure
      select DFA.DFA_RATE
        into lResult
        from DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = lDocumentID
         and DFA.DIC_BASIS_MATERIAL_ID = lDicBasisMatId
         and nvl(DFA.DFA_RATE_DATE, sysdate) = nvl(lDateRef, sysdate);
    end if;

    return lResult;
  exception
    when no_data_found then
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Problème de parité entre DOC_POSITION_ALLOY et DOC_FOOT_ALLOY.') || lAlloyId || '/' || lDateRef);
  end GetAlloyRate;

  /**
  * Description
  *    Indique si la position peut générer des mouvements de matières précieuses
  */
  function IsAlloyMvtOnPos(lPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lCountAlloy pls_integer;
  begin
    select count(*)
      into lCountAlloy
      from DOC_POSITION_ALLOY DPA
         , DOC_POSITION POS
         , DOC_GAUGE_POSITION GAP
     where DPA.DOC_POSITION_ID = lPositionId
       and POS.DOC_POSITION_ID = DPA.DOC_POSITION_ID
       and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
       and GAP.STM_MA_MOVEMENT_KIND_ID is not null;

    return sign(lCountAlloy);
  end IsAlloyMvtOnPos;
end DOC_LIB_ALLOY;
