--------------------------------------------------------
--  DDL for Package Body GCO_BARCODE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_BARCODE_FUNCTIONS" 
is
  type typModulo is table of integer
    index by varchar2(1);

  type typModuloInv is table of varchar2(1)
    index by binary_integer;

  tblModulo    typModulo;
  tblModuloInv typModuloInv;

--END VERSION

  /**
  * procedure GetEANUCC14Codes
  * Description
  *   Génération du code EAN et du code UCC14
  */
  procedure GetEANUCC14Codes(
    iAdminDomain      in     varchar2
  , iGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , iDicUnitOfMeasure in     GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , ioEANCode         in out GCO_GOOD.GOO_EAN_CODE%type
  , oUCC14Code        out    GCO_GOOD.GOO_EAN_UCC14_CODE%type
  , oError            out    varchar2
  )
  is
    lvUMECode     DIC_UNIT_OF_MEASURE.UME_BARCODE_CODE%type;
    lnUCC14Active GCO_GOOD_CATEGORY.CAT_EAN_GOO_UCC14%type;
    lvUnitMeasure DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type;
  begin
    -- Génération du code EAN du domaine
    if ioEANCode is null then
      ioEANCode  := GCO_EAN.EAN_gen(aGenre => to_number(iAdminDomain), aGoodID => iGoodID);
    end if;

    if GCO_EAN.EAN_Ctrl(aGenre => to_number(iAdminDomain), aEANCode => ioEANCode, aGoodID => iGoodID) <> 1 then
      ioEANCode  := null;
      oError     := '105';
    else
      -- Vérifie activation du code UCC-14 selon domaine
      select decode(iAdminDomain
                  , '0', CAT_EAN_GOO_UCC14
                  , '1', CAT_EAN_STK_UCC14
                  , '2', CAT_EAN_INV_UCC14
                  , '3', CAT_EAN_PUR_UCC14
                  , '4', CAT_EAN_SAL_UCC14
                  , '5', CAT_EAN_ASA_UCC14
                  , '6', CAT_EAN_SUB_UCC14
                  , '7', CAT_EAN_FAL_UCC14
                  , '8', CAT_EAN_DIU_UCC14
                   )
           , nvl(iDicUnitOfMeasure, GOO.DIC_UNIT_OF_MEASURE_ID)
        into lnUCC14Active
           , lvUnitMeasure
        from GCO_GOOD GOO
           , GCO_GOOD_CATEGORY CAT
       where GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
         and GOO.GCO_GOOD_ID = iGoodID;

      if lnUCC14Active = 1 then
        GetUCC14Code(iDicUnitOfMeasure => lvUnitMeasure, iEANCode => ioEANCode, oUCC14Code => oUCC14Code, oError => oError);
      end if;
    end if;
  end GetEANUCC14Codes;

  /**
  * procedure GetUCC14Code
  * Description
  *   Génération du code UCC14
  */
  procedure GetUCC14Code(
    iDicUnitOfMeasure in     DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_ID%type
  , iEANCode          in     varchar2
  , oUCC14Code        out    varchar2
  , oError            out    varchar2
  )
  is
    lvUMECode DIC_UNIT_OF_MEASURE.UME_BARCODE_CODE%type;
  begin
    oUCC14Code  := null;
    oError      := null;

    -- Recherche le code barre sur l'unité de mesure
    select max(UME_BARCODE_CODE)
      into lvUMECode
      from DIC_UNIT_OF_MEASURE
     where DIC_UNIT_OF_MEASURE_ID = iDicUnitOfMeasure;

    if lvUMECode is null then
      oError  := '003';   -- Erreur "Code unité de mesure inexistant"
    else
      if iEANCode is not null then
        oUCC14Code  := lvUMECode || substr(iEANCode, 1, 12);
        oUCC14Code  := oUCC14Code || ACS_FUNCTION.modulo10(oUCC14Code);
      else
        oError  := '104';   -- Erreur "Code EAN inexistant"
      end if;
    end if;
  end GetUCC14Code;

  /*---------------------------------------------------------------------*/
/* Renvoie des codes EAN et UCC14 du domaine                           */
/*---------------------------------------------------------------------*/
  procedure GetEAN_UCC14(
    paDomain      in     number
  , paGoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , paComplDataId in     GCO_COMPL_DATA_STOCK.GCO_COMPL_DATA_STOCK_ID%type
  , paEANCode     in out GCO_GOOD.GOO_EAN_CODE%type
  , paUCC14Code   out    GCO_GOOD.GOO_EAN_UCC14_CODE%type
  , paError       out    varchar2
  )
  is
  begin
    -- Génération du code EAN du domaine
    if paEANCode is null then
      paEANCode  := GCO_EAN.EAN_gen(paDomain, paGoodId);
    end if;

    if GCO_EAN.EAN_Ctrl(paDomain, paEANCode, paGoodId) <> 1 then
      paEANCode  := null;
      paError    := '105';
    else
      GetUCC14(paDomain, paGoodId, paComplDataId, paEANCode, paUCC14Code, paError);
    end if;
  end GetEAN_UCC14;

/*---------------------------------------------------------------------*/
/* Génération du code EAN-UCC14                                        */
/*---------------------------------------------------------------------*/
  procedure GetUCC14(
    paDomain      in     number
  , paGoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , paComplDataId in     GCO_COMPL_DATA_STOCK.GCO_COMPL_DATA_STOCK_ID%type
  , paEANCode     in     GCO_GOOD.GOO_EAN_CODE%type
  , paUCC14Code   out    GCO_GOOD.GOO_EAN_UCC14_CODE%type
  , paError       out    varchar2
  )
  is
    vUMECode     DIC_UNIT_OF_MEASURE.UME_BARCODE_CODE%type;
    vEANCode     GCO_GOOD.GOO_EAN_CODE%type;
    vDomainTable varchar2(50);
    curId        GCO_GOOD.GCO_GOOD_ID%type;
    vUCC14Active GCO_GOOD_CATEGORY.CAT_EAN_GOO_UCC14%type;
  begin
    -- Vérifie activation du code UCC-14 selon domaine
    select decode(paDomain
                , 0, CAT_EAN_GOO_UCC14
                , 1, CAT_EAN_STK_UCC14
                , 2, CAT_EAN_INV_UCC14
                , 3, CAT_EAN_PUR_UCC14
                , 4, CAT_EAN_SAL_UCC14
                , 5, CAT_EAN_ASA_UCC14
                , 6, CAT_EAN_SUB_UCC14
                , 7, CAT_EAN_FAL_UCC14
                , 8, CAT_EAN_DIU_UCC14
                 )
      into vUCC14Active
      from GCO_GOOD GOO
         , GCO_GOOD_CATEGORY CAT
     where GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
       and GOO.GCO_GOOD_ID = paGoodId;

    if vUCC14Active = 1 then
      paUCC14Code  := null;
      paError      := null;

      if    (paComplDataId is null)
         or (paComplDataId = 0) then
        curId  := paGoodId;
      else
        curId  := paComplDataId;
      end if;

      if paDomain = 0 then
        vDomainTable  := 'GCO_GOOD';   -- produit
      elsif paDomain = 1 then
        vDomainTable  := 'GCO_COMPL_DATA_STOCK';   -- stock
      elsif paDomain = 2 then
        vDomainTable  := 'GCO_COMPL_DATA_INVENTORY';   -- inventaire
      elsif paDomain = 3 then
        vDomainTable  := 'GCO_COMPL_DATA_PURCHASE';   -- achat
      elsif paDomain = 4 then
        vDomainTable  := 'GCO_COMPL_DATA_SALE';   -- vente
      elsif paDomain = 5 then
        vDomainTable  := 'GCO_GOOD';   -- SAV
        curId         := paGoodId;
      elsif paDomain = 6 then
        vDomainTable  := 'GCO_COMPL_DATA_SUBCONTRACT';   -- sous-traitance
      elsif paDomain = 7 then
        vDomainTable  := 'GCO_COMPL_DATA_MANUFACTURE';   -- fabrication
      elsif paDomain = 8 then
        vDomainTable  := 'GCO_COMPL_DATA_DISTRIB';   -- distribution
      end if;

      -- Recherche du code unité de mesure
      execute immediate 'select UME.UME_BARCODE_CODE from DIC_UNIT_OF_MEASURE UME, ' ||
                        vDomainTable ||
                        ' TBL where TBL.DIC_UNIT_OF_MEASURE_ID = UME.DIC_UNIT_OF_MEASURE_ID' ||
                        ' and TBL.' ||
                        vDomainTable ||
                        '_ID = ' ||
                        curId
                   into vUMECode;

      if vUMECode is null then
        paError  := '003';   -- Erreur "Code unité de mesure inexistant"
      else
        if paEANCode is not null then
          paUCC14Code  := vUMECode || substr(paEANCode, 1, 12);
          paUCC14Code  := paUCC14Code || ACS_FUNCTION.modulo10(paUCC14Code);
        else
          paError  := '104';   -- Erreur "Code EAN inexistant"
        end if;
      end if;
    end if;
  end GetUCC14;

/*---------------------------------------------------------------------*/
/* Génération des code EAN et UCC14 du domaine                         */
/*---------------------------------------------------------------------*/
  procedure GenerateEAN_UCC14(
    paDomain      in     number
  , paGoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , paComplDataId in     GCO_COMPL_DATA_STOCK.GCO_COMPL_DATA_STOCK_ID%type
  , paError       out    varchar2
  , paEAN         in     GCO_GOOD.GOO_EAN_CODE%type default null
  )
  is
    vEAN         GCO_GOOD.GOO_EAN_CODE%type;
    vUCC14       GCO_GOOD.GOO_EAN_UCC14_CODE%type;
    vDomainTable varchar2(30);
  begin
    vEAN  := paEAN;
    GetEAN_UCC14(paDomain, paGoodId, paComplDataId, vEAN, VUCC14, paError);

    if (paDomain = 0) then
      update GCO_GOOD
         set GOO_EAN_CODE = vEAN
           , GOO_EAN_UCC14_CODE = vUCC14
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_GOOD_ID = paGoodId;
    else
      if paDomain = 1 then
        vDomainTable  := 'GCO_COMPL_DATA_STOCK';   -- stock
      elsif paDomain = 2 then
        vDomainTable  := 'GCO_COMPL_DATA_INVENTORY';   -- inventaire
      elsif paDomain = 3 then
        vDomainTable  := 'GCO_COMPL_DATA_PURCHASE';   -- achat
      elsif paDomain = 4 then
        vDomainTable  := 'GCO_COMPL_DATA_SALE';   -- vente
      elsif paDomain = 5 then
        vDomainTable  := 'GCO_COMPL_DATA_ASS';   -- SAV
      elsif paDomain = 6 then
        vDomainTable  := 'GCO_COMPL_DATA_SUBCONTRACT';   -- sous-traitance
      elsif paDomain = 7 then
        vDomainTable  := 'GCO_COMPL_DATA_MANUFACTURE';   -- fabrication
      elsif paDomain = 8 then
        vDomainTable  := 'GCO_COMPL_DATA_DISTRIB';   -- distribution
      end if;

      if vEAN is not null then
        execute immediate 'update ' ||
                          vDomainTable ||
                          ' set CDA_COMPLEMENTARY_EAN_CODE = ' ||
                          vEAN ||
                          ', A_DATEMOD = sysdate' ||
                          ', A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni' ||
                          ' where ' ||
                          vDomainTable ||
                          '_ID = ' ||
                          paComplDataId;
      end if;

      if vUCC14 is not null then
        execute immediate 'update ' ||
                          vDomainTable ||
                          ' set CDA_COMPLEMENTARY_UCC14_CODE = ' ||
                          vUCC14 ||
                          ', A_DATEMOD = sysdate' ||
                          ', A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni' ||
                          ' where ' ||
                          vDomainTable ||
                          '_ID = ' ||
                          paComplDataId;
      end if;
    end if;
  end GenerateEAN_UCC14;

/*---------------------------------------------------------------------*/
/* Génération des code EAN et UCC14 de tous les domaines du bien       */
/*---------------------------------------------------------------------*/
  procedure GenerateAllEAN(paGoodId in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crCDAStock(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_STOCK_ID
        from GCO_COMPL_DATA_STOCK CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDAInventory(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_INVENTORY_ID
        from GCO_COMPL_DATA_INVENTORY CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDAPurchase(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDASale(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_SALE_ID
        from GCO_COMPL_DATA_SALE CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDASAV(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_ASS_ID
        from GCO_COMPL_DATA_ASS CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDASubcontract(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_SUBCONTRACT_ID
        from GCO_COMPL_DATA_SUBCONTRACT CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDAManufacture(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_MANUFACTURE_ID
        from GCO_COMPL_DATA_MANUFACTURE CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    cursor crCDADistribution(pGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select CDA.GCO_COMPL_DATA_DISTRIB_ID
        from GCO_COMPL_DATA_DISTRIB CDA
       where CDA.GCO_GOOD_ID = pGoodId;

    tplCDAStock        crCDAStock%rowtype;
    tplCDAInventory    crCDAInventory%rowtype;
    tplCDAPurchase     crCDAPurchase%rowtype;
    tplCDASale         crCDASale%rowtype;
    tplCDASAV          crCDASAV%rowtype;
    tplCDASubcontract  crCDASubcontract%rowtype;
    tplCDAManufacture  crCDAManufacture%rowtype;
    tplCDADistribution crCDADistribution%rowtype;
    vError             varchar2(3);
    vDomain            number;
    vEANCode           GCO_GOOD.GOO_EAN_CODE%type;
  begin
    -- Génération code EAN et UCC14 domaine "Stock"
    vDomain  := 1;

    open crCDAStock(paGoodId);

    fetch crCDAStock
     into tplCDAStock;

    while crCDAStock%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDAStock.GCO_COMPL_DATA_STOCK_ID, vError);

      fetch crCDAStock
       into tplCDAStock;
    end loop;

    close crCDAStock;

    -- Génération code EAN et UCC14 domaine "Inventaire"
    vDomain  := 2;

    open crCDAInventory(paGoodId);

    fetch crCDAInventory
     into tplCDAInventory;

    while crCDAInventory%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDAInventory.GCO_COMPL_DATA_INVENTORY_ID, vError);

      fetch crCDAInventory
       into tplCDAInventory;
    end loop;

    close crCDAInventory;

    -- Génération code EAN et UCC14 domaine "Achat"
    vDomain  := 3;

    open crCDAPurchase(paGoodId);

    fetch crCDAPurchase
     into tplCDAPurchase;

    while crCDAPurchase%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDAPurchase.GCO_COMPL_DATA_PURCHASE_ID, vError);

      fetch crCDAPurchase
       into tplCDAPurchase;
    end loop;

    close crCDAPurchase;

    -- Génération code EAN et UCC14 domaine "Vente"
    vDomain  := 4;

    open crCDASale(paGoodId);

    fetch crCDASale
     into tplCDASale;

    while crCDASale%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDASale.GCO_COMPL_DATA_Sale_ID, vError);

      fetch crCDASale
       into tplCDASale;
    end loop;

    close crCDASale;

    -- Génération code EAN et UCC14 domaine "SAV"
    vDomain  := 5;

    open crCDASAV(paGoodId);

    fetch crCDASAV
     into tplCDASAV;

    while crCDASAV%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDASAV.GCO_COMPL_DATA_ASS_ID, vError);

      fetch crCDASAV
       into tplCDASAV;
    end loop;

    close crCDASAV;

    -- Génération code EAN et UCC14 domaine "Sous-traitance"
    vDomain  := 6;

    open crCDASubcontract(paGoodId);

    fetch crCDASubcontract
     into tplCDASubcontract;

    while crCDASubcontract%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDASubcontract.GCO_COMPL_DATA_SUBCONTRACT_ID, vError);

      fetch crCDASubcontract
       into tplCDASubcontract;
    end loop;

    close crCDASubcontract;

    -- Génération code EAN et UCC14 domaine "Fabrication"
    vDomain  := 7;

    open crCDAManufacture(paGoodId);

    fetch crCDAManufacture
     into tplCDAManufacture;

    while crCDAManufacture%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDAManufacture.GCO_COMPL_DATA_MANUFACTURE_ID, vError);

      fetch crCDAManufacture
       into tplCDAManufacture;
    end loop;

    close crCDAManufacture;

    -- Génération code EAN et UCC14 domaine "Distribution"
    vDomain  := 8;

    open crCDADistribution(paGoodId);

    fetch crCDADistribution
     into tplCDADistribution;

    while crCDADistribution%found loop
      GenerateEAN_UCC14(vDomain, paGoodId, tplCDADistribution.GCO_COMPL_DATA_DISTRIB_ID, vError);

      fetch crCDADistribution
       into tplCDADistribution;
    end loop;

    close crCDADistribution;
  end GenerateAllEAN;

/*---------------------------------------------------------------------*/
/* Contrôle du code UCC14                                              */
/*---------------------------------------------------------------------*/
  function ControlUCC14(paEANCode in GCO_GOOD.GOO_EAN_CODE%type, paUCC14Code in GCO_GOOD.GOO_EAN_UCC14_CODE%type, paGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    vUCC14   varchar2(14);
    vUMECode DIC_UNIT_OF_MEASURE.UME_BARCODE_CODE%type;
  begin
    select UME.UME_BARCODE_CODE
      into vUMECode
      from DIC_UNIT_OF_MEASURE UME
         , GCO_GOOD GOO
     where UME.DIC_UNIT_OF_MEASURE_ID = GOO.DIC_UNIT_OF_MEASURE_ID
       and GOO.GCO_GOOD_ID = paGoodID;

    vUCC14  := vUMECode || substr(paEANCode, 1, 12);
    vUCC14  := vUCC14 || ACS_FUNCTION.modulo10(vUCC14);

    if vUCC14 = paUCC14Code then
      return 1;
    else
      return 0;
    end if;
  end ControlUCC14;

/*---------------------------------------------------------------------*/
/* Génération du code HIBC primaire                                    */
/*---------------------------------------------------------------------*/
  procedure GenerateHIBC(
    paGoodId    in     GCO_GOOD.GCO_GOOD_ID%type
  , paHIBC      out    GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type
  , paError     out    varchar2
  , paForcePCN  in     varchar2 default null
  , paForceHIBC in     varchar2 default null
  )
  is
    vLIC PCS.PC_COMP.COM_HIBC_LIC%type;
    vPCN GCO_GOOD.GOO_HIBC_REFERENCE%type;
    vUM  DIC_UNIT_OF_MEASURE.UME_BARCODE_CODE%type;
  begin
    paHIBC  := paForceHIBC;

    if paHIBC is not null then
      paError  := ControlHIBC(paHIBC);
    end if;

    if    paHIBC is null
       or paError is not null then
      vLIC  := GetHIBC_LIC;

      if vLIC is null then
        paError  := '002';   -- N° d'adhérent incorrect ou manquant
      else
        -- Recherche de la référence HIBC (PCN) du produit
        vPCN  := paForcePCN;

        if vPCN is null then
          -- Recherche méthode de génération PCN
          getPCN(paGoodId, vPCN);
        end if;

        -- Contrôle de cohérence du PCN
        if (length(vPCN) > 18) then
          paerror  := '005';   -- Longueur maximale du code barres dépassée.
        elsif(vPCN is null) then
          paError  := '004';   -- Réf HIBC du produit incorrecte ou manquante
        else
          -- Recherche du code de conditionnement (UM)
          select UME.UME_BARCODE_CODE
            into vUM
            from DIC_UNIT_OF_MEASURE UME
               , GCO_GOOD GOO
           where GOO.DIC_UNIT_OF_MEASURE_ID = UME.DIC_UNIT_OF_MEASURE_ID
             and GOO.GCO_GOOD_ID = paGoodId;

          if vUM is null then
            paError  := '003';   -- Code UM incorrect ou manquant
          else
            -- Génération du code HIBC primaire du produit
            paHIBC   := '+' || vLIC || vPCN || vUM;
            paHIBC   := paHIBC || Modulo43(paHIBC);
            paError  := ControlHIBC(paHIBC);

            if paError is null then
              update GCO_GOOD
                 set GOO_HIBC_PRIMARY_CODE = paHIBC
                   , GOO_HIBC_REFERENCE = vPCN
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where GCO_GOOD_ID = paGoodId;
            end if;
          end if;
        end if;
      end if;
    end if;
  end GenerateHIBC;

/*---------------------------------------------------------------------*/
/* Calcul du modulo43                                                  */
/*---------------------------------------------------------------------*/
  function Modulo43(aValue in varchar2)
    return varchar2
  is
    vResult number;
    i       number(2);
  begin
    vResult  := 0;

    begin
      for i in 1 .. length(aValue) loop
        vResult  := vResult + tblModulo(substr(aValue, i, 1) );
      end loop;

      return tblModuloInv(vResult mod 43);
    exception
      when no_data_found then
        return null;
    end;

--END VERSION
    return null;
--END VERSION
  end;

/*---------------------------------------------------------------------*/
/* Contrôle du LIC HIBC et renvoie du numéro                           */
/*---------------------------------------------------------------------*/
  function GetHIBC_LIC
    return PCS.PC_COMP.COM_HIBC_LIC%type
  is
    vLIC PCS.PC_COMP.COM_HIBC_LIC%type;
  begin
    -- N° d'adhérent HIBC de la société active
    begin
      select COM.COM_HIBC_LIC
        into vLIC
        from PCS.PC_COMP COM
       where COM.PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;
    exception
      when no_data_found then
        vLIC  := null;
    end;

    -- Test de cohérence du N°
    if     pcs.pcstonumber(substr(vLIC, 1, 1) ) is null
       and (upper(substr(vLIC, 1, 1) ) = substr(vLIC, 1, 1) )
       and (pcs.pcstonumber(substr(vLIC, 2, 3) ) is not null) then
      return vLIC;
    else
      return null;
    end if;
  end GetHIBC_LIC;

/*---------------------------------------------------------------------*/
/* Contrôle du code HIBC                                               */
/*---------------------------------------------------------------------*/
  function ControlHIBC(paHIBCCode in GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type)
    return varchar2
  is
    i       integer;
    blnTest boolean;
  begin
    if substr(paHIBCCode, 1, 1) <> '+' then
      return '001';   -- le premier caractère doit être un +
    else
      if    pcs.pcstonumber(substr(paHIBCCode, 2, 1) ) is not null
         or (upper(substr(paHIBCCode, 2, 1) ) <> substr(paHIBCCode, 2, 1) ) then
        return '002';   -- le deuxième caractère doit être une lettre majuscule
      else
        if pcs.pcstonumber(substr(paHIBCCode, 3, 3) ) is null then
          return '002';   -- les 3,4 et 5e caractères doivent être numériques
        else
          if pcs.pcstonumber(substr(paHIBCCode, length(paHIBCCode) - 1, 1) ) is null then
            return '003';   -- l'avant-dernier caractère doit être un numérique
          else
            blnTest  := true;
            i        := 5;

            while blnTest
             and i < length(paHIBCCode) - 2 loop
              i        := i + 1;
              blnTest  :=     ascii(substr(paHIBCCode, i, 1) ) <= 90
                          and ascii(substr(paHIBCCode, i, 1) ) >= 48;
            end loop;

            if    (upper(substr(paHIBCCode, 6, length(paHIBCCode) - 7) ) <>(substr(paHIBCCode, 6, length(paHIBCCode) - 7) ) )
               or (i <> length(paHIBCCode) - 2) then
              return '004';   -- caractère 6 à antépénultième doit être A-Z/0-9 et longueur de la chaîne <=13
            else
              if length(paHIBCCode) > 25 then
                return '005';   -- le code HIBC doit être <=25 caractères
              else
                if substr(paHIBCCode, length(paHIBCCode), 1) <> modulo43(substr(paHIBCCode, 1, length(paHIBCCode) - 1) ) then
                  return '006';   -- le dernier caractère doit être égal au modulo43 de la chaìne moins le dernier caractère
                else
                  return null;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end ControlHIBC;

/*---------------------------------------------------------------------*/
/* Formatage du code HIBC                                              */
/*---------------------------------------------------------------------*/
  function FormatHIBC(paHIBC in GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type)
    return varchar2
  is
  begin
    return '*' || paHIBC || '*';
  end;

/*---------------------------------------------------------------------*/
/* Numérotation automatique du PCN                                     */
/*---------------------------------------------------------------------*/
  procedure GetPCN(paGoodId in GCO_GOOD.GCO_GOOD_ID%type, paPCN out GCO_GOOD.GOO_HIBC_REFERENCE%type)
  is
  begin
    begin
      GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(paGoodId, 'GCO_GOOD_CATEGORY_BARCODE', paPCN);
    exception
      when others then
        null;
    end;
  end GetPCN;

/*---------------------------------------------------------------------*/
/* HIBC secondaire : Génération du code                                */
/*---------------------------------------------------------------------*/
  function GetHIBCSecondaryRef(
    paGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , paQty        in varchar2
  , paQtyFormat  in varchar2
  , paCaract     in varchar2
  , paDate       in date
  , paDateFormat in varchar2
  , paMode       in number default 0
  )
    return varchar2
  is
    vErrorValue       varchar2(3);
    vHIBCSecondaryRef varchar2(50);
  begin
    GenHIBCSecondaryRef(paGoodId, paQty, paQtyFormat, paCaract, paDate, paDateFormat, paMode, vHIBCSecondaryRef, vErrorValue);

    if vErrorValue is null then
      return vHIBCSecondaryRef;
    else
      return 'Error ' || vErrorValue;
    end if;
  end;

  procedure GenHIBCSecondaryRef(
    paGoodId           in     GCO_GOOD.GCO_GOOD_ID%type
  , paQty              in     varchar2
  , paQtyFormat        in     varchar2
  , paCaract           in     varchar2
  , paDate             in     date
  , paDateFormat       in     varchar2
  , paMode             in     number default 0
  , paHIBCSecondaryRef out    varchar2
  , paErrorValue       out    varchar2
  )
  is
    vHIBCPrimaryRef            GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    vHIBCSerialNumberSeparator varchar(1);
  begin
    -- initialisation des variables
    paHIBCSecondaryRef  := null;
    paErrorValue        := null;
    -- Formatage de la quantité
    CtrlFormatQty(paQty, paQtyFormat, paMode, paHIBCSecondaryRef, paErrorValue);

    if paErrorValue is null then
      -- Formatage de la date
      CtrlFormatDate(paDate, paDateFormat, paCaract, paMode, paHIBCSecondaryRef, paErrorValue);

      if paErrorValue is null then
        -- Formatage de la valeur de caractérisation
        CtrlFormatCaract(paCaract, paMode, paHIBCSecondaryRef, paErrorValue);

        if paErrorValue is null then
          -- recherche du code HIBC primaire
          begin
            select GOO.GOO_HIBC_PRIMARY_CODE
              into vHIBCPrimaryRef
              from GCO_GOOD GOO
             where GOO.GCO_GOOD_ID = paGoodId;
          exception
            when no_data_found then
              vHIBCPrimaryRef  := null;
          end;

          if vHIBCPrimaryRef is null then
            paErrorValue  := '103';   -- code HIBC primaire inexistant
          else
            -- ajout du + après $$ si numéro de série
            begin
              select '+'
                into vHIBCSerialNumberSeparator
                from gco_characterization
               where c_charact_type = 3
                 and gco_good_id = paGoodId;
            exception
              when no_data_found then
                vHIBCSerialNumberSeparator  := null;
            end;

            if vHIBCSerialNumberSeparator = '+' then
              paHIBCSecondaryRef  :=
                    substr(paHIBCSecondaryRef, 1, instr(paHIBCSecondaryRef, '$', -1) ) || '+'
                    || substr(paHIBCSecondaryRef, instr(paHIBCSecondaryRef, '$', -1) + 1);
            end if;

            if paMode = 0 then
              paHIBCSecondaryRef  := paHIBCSecondaryRef || substr(vHIBCPrimaryRef, -1);
            elsif paMode = 1 then
              -- Le caractère de contrôle du primary doit tomber
              paHIBCSecondaryRef  := substr(vHIBCPrimaryRef, 1, length(vHIBCPrimaryRef) - 1) || '/' || paHIBCSecondaryRef;
            end if;

            paHIBCSecondaryRef  := paHIBCSecondaryRef || Modulo43(paHIBCSecondaryRef);
          end if;
        end if;
      end if;
    end if;
  end GenHIBCSecondaryRef;

/*---------------------------------------------------------------------*/
/* HIBC secondaire : Formatage de la quantité                          */
/*---------------------------------------------------------------------*/
  procedure CtrlFormatQty(paQty in varchar2, paQtyFormat in varchar2, paMode in number, paHIBCSecondaryRef in out varchar2, paErrorValue out varchar2)
  is
  begin
    paHIBCSecondaryRef  := null;
    paErrorValue        := null;

    if paQty is not null then
      if paQtyFormat = '8' then
        -- quantité formatée sur 2 caractères
        if length(paQty) > 2 then
          paErrorValue  := '100';   -- Format quantité incompatible
        else
          if paMode = 0 then
            paHIBCSecondaryRef  := '+';
          end if;

          paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paQtyFormat || lpad(paQty, 2, '0');
        end if;
      elsif paQtyFormat = '9' then
        -- quantité formatée sur 5 caractères
        if length(paQty) > 5 then
          paErrorValue  := '100';   -- Format quantité incompatible
        else
          if paMode = 0 then
            paHIBCSecondaryRef  := '+';
          end if;

          paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paQtyFormat || lpad(paQty, 5, '0');
        end if;
      else
        paErrorValue  := '100';   -- Format quantité incompatible
      end if;
    end if;
  end CtrlFormatQty;

/*---------------------------------------------------------------------*/
/* HIBC secondaire : Formatage de la date                              */
/*---------------------------------------------------------------------*/
  procedure CtrlFormatDate(
    paDate             in     date
  , paDateFormat       in     varchar2
  , paCaract           in     varchar2
  , paMode             in     number
  , paHIBCSecondaryRef in out varchar2
  , paErrorValue       out    varchar2
  )
  is
  begin
    if paHIBCSecondaryRef is null then
      -- pas de quantité dans le code HIBC
      if paMode = 0 then
        paHIBCSecondaryRef  := '+';
      end if;

      if paDate is not null then
        if paCaract is not null then
          if paDateFormat = '0' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || to_char(paDate, 'YYDDD');
          elsif paDateFormat = '1' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || to_char(paDate, 'MMYY');
          elsif paDateFormat = '2' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat || to_char(paDate, 'MMDDYY');
          elsif paDateFormat = '3' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat || to_char(paDate, 'YYMMDD');
          elsif paDateFormat = '4' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat || to_char(paDate, 'YYMMDDHH24');
          elsif paDateFormat = '5' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat || to_char(paDate, 'YYDDD');
          elsif paDateFormat = '6' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat || to_char(paDate, 'YYDDDHH24');
          elsif paDateFormat = '7' then
            paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat;
          else
            paErrorValue  := '101';   -- format date incompatible
          end if;
        else
          -- pas de lot dans le code HIBC
          paErrorValue  := '102';   -- format de lot incompatible
        end if;
      else
        -- pas de date dans le code HIBC
        if paDateFormat = '7' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || '$$' || paDateFormat;
        elsif paDateFormat is null then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || '$';
        else
          paErrorValue  := '101';   -- format de date incompatible
        end if;
      end if;
    else
      if paDate is null then
        if paCaract is not null then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || '7';
        end if;
      else
        if paDateFormat = '0' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || to_char(paDate, 'YYDDD');
        elsif paDateFormat = '1' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || to_char(paDate, 'MMYY');
        elsif paDateFormat = '2' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat || to_char(paDate, 'MMDDYY');
        elsif paDateFormat = '3' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat || to_char(paDate, 'YYMMDD');
        elsif paDateFormat = '4' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat || to_char(paDate, 'YYMMDDHH24');
        elsif paDateFormat = '5' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat || to_char(paDate, 'YYDDD');
        elsif paDateFormat = '6' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat || to_char(paDate, 'YYDDDHH24');
        elsif paDateFormat = '7' then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paDateFormat;
        else
          paErrorValue  := '101';   -- format date incompatible
        end if;
      end if;
    end if;
  end CtrlFormatDate;

/*---------------------------------------------------------------------*/
/* HIBC secondaire : Formatage de la valeur de caractérisation         */
/*---------------------------------------------------------------------*/
  procedure CtrlFormatCaract(paCaract in varchar2, paMode in number, paHIBCSecondaryRef in out varchar2, paErrorValue out varchar2)
  is
  begin
    if paCaract is not null then
      if length(paCaract) > 20 then
        paErrorValue  := '102';   -- Format lot incompatible
      else
        if paHIBCSecondaryRef is not null then
          paHIBCSecondaryRef  := paHIBCSecondaryRef || paCaract;
        else
          if paMode = 0 then
            paHIBCSecondaryRef  := '+';
          end if;

          paHIBCSecondaryRef  := paHIBCSecondaryRef || '$' || paCaract;
        end if;
      end if;
    else
      if paHIBCSecondaryRef is null then
        paErrorValue  := '102';   -- Format lot incompatible
      end if;
    end if;
  end CtrlFormatCaract;

/*---------------------------------------------------------------------*/
/* Table de valeurs assignée au caractère pour le calcul du  modulo43  */
/*---------------------------------------------------------------------*/
  procedure initModuloTable
  is
  begin
    tblModulo('0')    := 0;
    tblModulo('1')    := 1;
    tblModulo('2')    := 2;
    tblModulo('3')    := 3;
    tblModulo('4')    := 4;
    tblModulo('5')    := 5;
    tblModulo('6')    := 6;
    tblModulo('7')    := 7;
    tblModulo('8')    := 8;
    tblModulo('9')    := 9;
    tblModulo('A')    := 10;
    tblModulo('B')    := 11;
    tblModulo('C')    := 12;
    tblModulo('D')    := 13;
    tblModulo('E')    := 14;
    tblModulo('F')    := 15;
    tblModulo('G')    := 16;
    tblModulo('H')    := 17;
    tblModulo('I')    := 18;
    tblModulo('J')    := 19;
    tblModulo('K')    := 20;
    tblModulo('L')    := 21;
    tblModulo('M')    := 22;
    tblModulo('N')    := 23;
    tblModulo('O')    := 24;
    tblModulo('P')    := 25;
    tblModulo('Q')    := 26;
    tblModulo('R')    := 27;
    tblModulo('S')    := 28;
    tblModulo('T')    := 29;
    tblModulo('U')    := 30;
    tblModulo('V')    := 31;
    tblModulo('W')    := 32;
    tblModulo('X')    := 33;
    tblModulo('Y')    := 34;
    tblModulo('Z')    := 35;
    tblModulo('-')    := 36;
    tblModulo('.')    := 37;
    tblModulo(' ')    := 38;
    tblModulo('$')    := 39;
    tblModulo('/')    := 40;
    tblModulo('+')    := 41;
    tblModulo('%')    := 42;
    tblModuloInv(0)   := '0';
    tblModuloInv(1)   := '1';
    tblModuloInv(2)   := '2';
    tblModuloInv(3)   := '3';
    tblModuloInv(4)   := '4';
    tblModuloInv(5)   := '5';
    tblModuloInv(6)   := '6';
    tblModuloInv(7)   := '7';
    tblModuloInv(8)   := '8';
    tblModuloInv(9)   := '9';
    tblModuloInv(10)  := 'A';
    tblModuloInv(11)  := 'B';
    tblModuloInv(12)  := 'C';
    tblModuloInv(13)  := 'D';
    tblModuloInv(14)  := 'E';
    tblModuloInv(15)  := 'F';
    tblModuloInv(16)  := 'G';
    tblModuloInv(17)  := 'H';
    tblModuloInv(18)  := 'I';
    tblModuloInv(19)  := 'J';
    tblModuloInv(20)  := 'K';
    tblModuloInv(21)  := 'L';
    tblModuloInv(22)  := 'M';
    tblModuloInv(23)  := 'N';
    tblModuloInv(24)  := 'O';
    tblModuloInv(25)  := 'P';
    tblModuloInv(26)  := 'Q';
    tblModuloInv(27)  := 'R';
    tblModuloInv(28)  := 'S';
    tblModuloInv(29)  := 'T';
    tblModuloInv(30)  := 'U';
    tblModuloInv(31)  := 'V';
    tblModuloInv(32)  := 'W';
    tblModuloInv(33)  := 'X';
    tblModuloInv(34)  := 'Y';
    tblModuloInv(35)  := 'Z';
    tblModuloInv(36)  := '-';
    tblModuloInv(37)  := '.';
    tblModuloInv(38)  := ' ';
    tblModuloInv(39)  := '$';
    tblModuloInv(40)  := '/';
    tblModuloInv(41)  := '+';
    tblModuloInv(42)  := '%';
  end;
begin
  initModuloTable;
--END VERSION
end GCO_BARCODE_FUNCTIONS;
