--------------------------------------------------------
--  DDL for Package Body PAC_THIRD_ALLOY_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_THIRD_ALLOY_FUNCTIONS" 
is
  /**
  * procedure GenerateAllSupplierAlloy
  * Description
  *     Création des matières précieuses pour tous les fournisseurs ayant le mode de gestion des matières défini
  */
  procedure GenerateAllSupplierAlloy
  is
    cursor crSupplierList
    is
      select PAC_SUPPLIER_PARTNER_ID
           , C_MATERIAL_MGNT_MODE
        from PAC_SUPPLIER_PARTNER
       where C_MATERIAL_MGNT_MODE is not null;
  begin
    for tplSupplierList in crSupplierList loop
      GenerateSupplierAlloy(tplSupplierList.PAC_SUPPLIER_PARTNER_ID, tplSupplierList.C_MATERIAL_MGNT_MODE);
    end loop;
  end GenerateAllSupplierAlloy;

  /**
  * procedure GenerateAllCustomerAlloy
  * Description
  *     Création des matières précieuses pour tous les clients ayant le mode de gestion des matières défini
  */
  procedure GenerateAllCustomerAlloy
  is
    cursor crCustomerList
    is
      select PAC_CUSTOM_PARTNER_ID
           , C_MATERIAL_MGNT_MODE
        from PAC_CUSTOM_PARTNER
       where C_MATERIAL_MGNT_MODE is not null;
  begin
    for tplCustomerList in crCustomerList loop
      GenerateCustomerAlloy(tplCustomerList.PAC_CUSTOM_PARTNER_ID, tplCustomerList.C_MATERIAL_MGNT_MODE);
    end loop;
  end GenerateAllCustomerAlloy;

  /**
  * procedure GenerateSupplierAlloy
  * Description
  *     Création des matières précieuses pour tous le fournisseur passé en param et pour le mode de gestion spécifié
  *       Mode de gestion :  1 = Alliages ; 2 = Matières de base
  */
  procedure GenerateSupplierAlloy(pSupplierID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type, pManagMode PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type)
  is
    tmpManagMode PAC_SUPPLIER_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    -- Recherche du mode de gention du fournisseur, si pas passé en param
    if pManagMode is not null then
      tmpManagMode  := pManagMode;
    else
      begin
        select C_MATERIAL_MGNT_MODE
          into tmpManagMode
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = pSupplierID;
      exception
        when no_data_found then
          tmpManagMode  := '';
      end;
    end if;

    -- Mode : Alliages
    if tmpManagMode = '1' then
      insert into PAC_THIRD_ALLOY
                  (PAC_THIRD_ALLOY_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , GCO_ALLOY_ID
                 , THA_MANAGED
                 , THA_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , pSupplierID
             , GAL.GCO_ALLOY_ID
             , nvl(PCS.PC_CONFIG.GetConfig('PAC_THIRD_ALLOY_INIT_MANAGED'), 1)
             , null
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from (select GCO_ALLOY_ID
                  from GCO_ALLOY
                minus
                select GCO_ALLOY_ID
                  from PAC_THIRD_ALLOY
                 where PAC_SUPPLIER_PARTNER_ID = pSupplierID) GAL;
    -- Mode : Matières de base
    elsif tmpManagMode = '2' then
      insert into PAC_THIRD_ALLOY
                  (PAC_THIRD_ALLOY_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , DIC_BASIS_MATERIAL_ID
                 , THA_MANAGED
                 , THA_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , pSupplierID
             , BMT.DIC_BASIS_MATERIAL_ID
             , nvl(PCS.PC_CONFIG.GetConfig('PAC_THIRD_ALLOY_INIT_MANAGED'), 1)
             , null
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from (select DIC_BASIS_MATERIAL_ID
                  from DIC_BASIS_MATERIAL
                minus
                select DIC_BASIS_MATERIAL_ID
                  from PAC_THIRD_ALLOY
                 where PAC_SUPPLIER_PARTNER_ID = pSupplierID) BMT;
    end if;
  end GenerateSupplierAlloy;

  /**
  * procedure GenerateCustomerAlloy
  * Description
  *     Création des matières précieuses pour tous le client passé en param et pour le mode de gestion spécifié
  *       Mode de gestion :  1 = Alliages ; 2 = Matières de base
  */
  procedure GenerateCustomerAlloy(
    pCustomerID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , pManagMode  PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type default null
  )
  is
    tmpManagMode PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
  begin
    -- Recherche du mode de gention du client, si pas passé en param
    if pManagMode is not null then
      tmpManagMode  := pManagMode;
    else
      begin
        select C_MATERIAL_MGNT_MODE
          into tmpManagMode
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = pCustomerID;
      exception
        when no_data_found then
          tmpManagMode  := '';
      end;
    end if;

    -- Mode : Alliages
    if tmpManagMode = '1' then
      insert into PAC_THIRD_ALLOY
                  (PAC_THIRD_ALLOY_ID
                 , PAC_CUSTOM_PARTNER_ID
                 , GCO_ALLOY_ID
                 , THA_MANAGED
                 , THA_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , pCustomerID
             , GAL.GCO_ALLOY_ID
             , nvl(PCS.PC_CONFIG.GetConfig('PAC_THIRD_ALLOY_INIT_MANAGED'), 1)
             , null
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from (select GCO_ALLOY_ID
                  from GCO_ALLOY
                minus
                select GCO_ALLOY_ID
                  from PAC_THIRD_ALLOY
                 where PAC_CUSTOM_PARTNER_ID = pCustomerID) GAL;
    -- Mode : Matières de base
    elsif tmpManagMode = '2' then
      insert into PAC_THIRD_ALLOY
                  (PAC_THIRD_ALLOY_ID
                 , PAC_CUSTOM_PARTNER_ID
                 , DIC_BASIS_MATERIAL_ID
                 , THA_MANAGED
                 , THA_NUMBER
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , pCustomerID
             , BMT.DIC_BASIS_MATERIAL_ID
             , nvl(PCS.PC_CONFIG.GetConfig('PAC_THIRD_ALLOY_INIT_MANAGED'), 1)
             , null
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from (select DIC_BASIS_MATERIAL_ID
                  from DIC_BASIS_MATERIAL
                minus
                select DIC_BASIS_MATERIAL_ID
                  from PAC_THIRD_ALLOY
                 where PAC_CUSTOM_PARTNER_ID = pCustomerID) BMT;
    end if;
  end GenerateCustomerAlloy;

  /**
  * Description
  *   Retourne le numéro de la matière de base ou de l'alliage pour un tiers donné
  */
  function GetMatNumber(
    iThirdID         in PAC_THIRD.PAC_THIRD_ID%type
  , iBasisMaterialID in DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , iAlloyID         in GCO_ALLOY.GCO_ALLOY_ID%type
  , iAdminDomain     in DOC_GAUGE.C_ADMIN_DOMAIN%type
  )
    return number
  is
    lnLocationID STM_LOCATION.STM_LOCATION_ID%type;
    lnNumber     PAC_THIRD_ALLOY.THA_NUMBER%type;
  begin
    if iThirdID is null then
      return null;
    else
      -- Recherche le premier emplacement du compte poids dans l'ordre des classements.
      if iAdminDomain in('1', '5') then
        if iBasisMaterialID is not null then
          select THA.THA_NUMBER
            into lnNumber
            from PAC_THIRD_ALLOY THA
           where THA.DIC_BASIS_MATERIAL_ID = iBasisMaterialID
             and THA.PAC_SUPPLIER_PARTNER_ID = iThirdID;
        else
          select THA.THA_NUMBER
            into lnNumber
            from PAC_THIRD_ALLOY THA
           where THA.GCO_ALLOY_ID = iAlloyID
             and THA.PAC_SUPPLIER_PARTNER_ID = iThirdID;
        end if;

        return lnNumber;
      elsif iAdminDomain = '2' then
        if iBasisMaterialID is not null then
          select THA.THA_NUMBER
            into lnNumber
            from PAC_THIRD_ALLOY THA
           where THA.DIC_BASIS_MATERIAL_ID = iBasisMaterialID
             and THA.PAC_CUSTOM_PARTNER_ID = iThirdID;
        else
          select THA.THA_NUMBER
            into lnNumber
            from PAC_THIRD_ALLOY THA
           where THA.GCO_ALLOY_ID = iAlloyID
             and THA.PAC_CUSTOM_PARTNER_ID = iThirdID;
        end if;

        return lnNumber;
      else
        return null;
      end if;
    end if;
  end GetMatNumber;

  /**
  * fonction : GetMetalAccount
  * Description : Fonction de recherche des compte poids, domaine achat/vente
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iThirdId: Tiers
  * @param   iAdminDomain: Domaine (Achat/vente)
  * @return  Stock Compte poids
  */
  function GetMetalAccount(iThirdId in number, iAdminDomain in varchar2)
    return number
  is
    lnStockId number;
  begin
    -- Domaine des achats, recherche du compte-poids fournisseur
    if iAdminDomain in('1', '5') then
      begin
        select STM_STOCK_ID
          into lnStockId
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = iThirdId
           and CRE_METAL_ACCOUNT = 1
           and STM_STOCK_ID is not null;

        return lnStockId;
      exception
        when no_data_found then
          return null;
      end;
    -- Domaine des achats, recherche du compte-poids Client
    elsif iAdminDomain = '2' then
      begin
        select STM_STOCK_ID
          into lnStockId
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = iThirdId
           and CUS_METAL_ACCOUNT = 1
           and STM_STOCK_ID is not null;

        return lnStockId;
      exception
        when no_data_found then
          return null;
      end;
    else
      return null;
    end if;
  end GetMetalAccount;
end PAC_THIRD_ALLOY_FUNCTIONS;
