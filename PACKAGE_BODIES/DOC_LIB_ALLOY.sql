--------------------------------------------------------
--  DDL for Package Body DOC_LIB_ALLOY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_ALLOY" 
is
  /**
  * Description
  *    Indique si pour un alliage donn�, un compte poids autorise une quantit� n�gative
  */
  function StockDeficitControl(iStockId in STM_STOCK.STM_STOCK_ID%type, iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lThirdID         PAC_THIRD.PAC_THIRD_ID%type;
    lnDeficitAllowed integer;
  begin
    -- Contr�le si le stock est un compte poids de type bancaire
    begin
      select PAC_THIRD_ID
        into lThirdID
        from STM_STOCK
       where STM_STOCK_ID = iStockId
         and C_STO_METAL_ACCOUNT_TYPE = 1   -- type de compte bancaire -> autorise le d�couvert
         and STO_METAL_ACCOUNT = 1;   -- compte poids
    exception
      when no_data_found then
        -- PCS - Une position du stock [STOCK] (emplacement [LOCATION]) pour le bien [GOOD] est en rupture de stock.
        return 1;
    end;

    -- Pas de tiers d�fini sur le compte poids
    if lThirdID is null then
      -- PCS - La quantit� en stock ne peut �tre n�gative. Le bien [GOOD] n''est pas li� au compte poids [CPT]
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
         and GAL.GAL_DEFICIT_ALLOWED = 1;   -- D�ficit autoris�
    exception
      when no_data_found then
        lnDeficitAllowed  := 0;   -- next test
      when others then
        -- par exemple,
        -- 2 alliages avec le m�me produit li� --> interdit!
        -- Param�trage du tiers, de l''alliage ou du compte-poids � v�rifier. Compte-poids n�gatif refus�!
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
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- D�ficit autoris�
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- for exemple,
          -- 2 alloy with the same bounded good --> forbidden !
          -- Param�trage du tiers, de l''alliage ou du compte-poids � v�rifier. Compte-poids n�gatif refus�!
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
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- D�ficit autoris�
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- 2 alloy with the same bounded good --> forbidden !
          -- Param�trage du tiers, de l''alliage ou du compte-poids � v�rifier. Compte-poids n�gatif refus�!
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
           and GAL.GAL_DEFICIT_ALLOWED = 1;   -- D�ficit autoris�
      exception
        when no_data_found then
          lnDeficitAllowed  := 0;   -- next test
        when others then
          -- for exemple,
          -- 2 alloy with the same bounded good --> forbidden !
          -- PCS - Param�trage du tiers, de l''alliage ou du compte-poids � v�rifier. Compte-poids n�gatif refus�!
          return 5;
      end;   -- exception Customer basis material
    end if;

    if lnDeficitAllowed = 0 then
      -- PCS - Param�trage du tiers, de l''alliage ou du compte-poids � v�rifier. Compte-poids n�gatif refus�!'
      return 6;
    end if;

    return 0;
  end StockDeficitControl;

  /**
  * Description
  *   Recherche le cours de la mati�re pr�cieuse sur le pied de document
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
      -- Gestion mati�re pure
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
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Probl�me de parit� entre DOC_POSITION_ALLOY et DOC_FOOT_ALLOY.') || lAlloyId || '/' || lDateRef);
  end GetAlloyRate;

  /**
  * Description
  *    Indique si la position peut g�n�rer des mouvements de mati�res pr�cieuses
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
