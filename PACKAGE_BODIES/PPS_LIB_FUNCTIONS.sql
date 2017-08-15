--------------------------------------------------------
--  DDL for Package Body PPS_LIB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_LIB_FUNCTIONS" 
is
  /**
  * Description
  *    ContrÃ´le le type Nomenclature. S'assure que celui-ci est autorisÃ© pour le bien courant
  */
  function isTypeAuthorized(iCode in PCS.PC_GCLST.GCLCODE%type)
    return number
  is
  begin
    -- if object param PPS_AUTHORIZED_TYPE is not null, we have to test if type is contained in this parameter
    if PCS.PC_I_LIB_SESSION.GetObjectParam('PPS_AUTHORIZED_TYPE') is not null then
      if instr(',' || PCS.PC_I_LIB_SESSION.GetObjectParam('PPS_AUTHORIZED_TYPE') || ',', ',' || iCode || ',') = 0 then
        return 0;
      end if;
    end if;

    return 1;
  end isTypeAuthorized;

  /**
  * Description
  *    Contrôle pour un bien et un type de nomenclature donnés, si une version existe
  */
  function VersionExists(
    iGoodId     PPS_NOM_BOND.GCO_GOOD_ID%type
  , iTypNom  in PPS_NOMENCLATURE.C_TYPE_NOM%type default cTypeNomProd
  , iVersion in PPS_NOMENCLATURE.NOM_VERSION%type
  )
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = iGoodId
       and C_TYPE_NOM = iTypNom
       and NOM_VERSION = iVersion;

    return lResult;
  end VersionExists;

  /**
  * Description
  *    Test if exists default subcontracting nomenclature for a good and a supplier
  */
  function IsDefaultSubCNomenclatureId(
    iGoodId     in GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type
  , iSupplierId in GCO_COMPL_DATA_SUBCONTRACT.PAC_SUPPLIER_PARTNER_ID%type
  )
    return boolean
  is
    ltplNomenclature GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    ltplNomenclature  := GCO_I_LIB_COMPL_DATA.GetDefaultSubCComplData(iGoodId, iSupplierId);
    return ltplNomenclature.PPS_NOMENCLATURE_ID is not null;
  end IsDefaultSubCNomenclatureId;

  /**
  * Description
  *    Check integrity of subcontracting datas, up to know if it's OK for subcontracting purchase
  */
  function checkSubcontractPComplData(iComplDataSubcontractPId in GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type)
    return varchar2
  is
    ltplComplData GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    lResult       varchar2(1000);
  begin
    ltplComplData  := GCO_I_LIB_COMPL_DATA.GetSubCComplDataTuple(iComplDataSubcontractPId);

    if ltplComplData.PPS_NOMENCLATURE_ID is null then
      lResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de nomenclature liée');
    elsif ltplComplData.GCO_GCO_GOOD_ID is null then
      lResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de service lié');
    else
      declare
        lStockId    STM_STOCK.STM_STOCK_ID%type;
        lLocationId STM_LOCATION.STM_LOCATION_ID%type;
      begin
        STM_I_LIB_STOCK.getSubCStockAndLocation(ltplComplData.PAC_SUPPLIER_PARTNER_ID, lStockId, lLocationId);

        if lStockId is null then
          lResult  := PCS.PC_FUNCTIONS.TranslateWord('Le fournisseur na pas de stock de sous-traitance');
        end if;
      end;
    end if;

    return lResult;
  end checkSubcontractPComplData;

  /**
  * procedure GetLastUsedVersion
  * Description
  *    Retourne la dernière version utilisée dans la tracabilité
  * @created fpe 24.02.2012
  * @lastUpdate
  * @public
  * @param iGoodId : bien pur lequel on recherche
  * @param oNomVersion : dernière version utilisée
  * @param oDefault : flag nomenclature par défaut
  */
  procedure GetLastFalUsedVersion(
    iGoodId         PPS_NOM_BOND.GCO_GOOD_ID%type
  , oNomVersion out PPS_NOMENCLATURE.NOM_VERSION%type
  , oNomDefault out PPS_NOMENCLATURE.NOM_DEFAULT%type
  )
  is
    lResult PPS_NOMENCLATURE.NOM_VERSION%type;
  begin
    select HIS_VERSION_ORIGIN_NUM
      into oNomVersion
      from FAL_TRACABILITY
     where FAL_TRACABILITY_ID = (select max(FAL_TRACABILITY_ID)
                                   from FAL_TRACABILITY
                                  where GCO_GOOD_ID = iGoodId
                                    and HIS_VERSION_ORIGIN_NUM is not null
                                    and VersionExists(iGoodID, '2', HIS_VERSION_ORIGIN_NUM) = 1);

    select NOM_DEFAULT
      into oNomDefault
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = iGoodId
       and NOM_VERSION = oNomVersion;
  exception
    when no_data_found then
      null;
  end GetLastFalUsedVersion;

  /**
  * function CheckGoodInNomBond
  * Description
  *    Contrôle si un composant existe dans la nomenclature par défaut
  * @created fp 01.04.2011
  * @lastUpdate
  * @public
  * @param  iNomenclatureId Identifiant de la nomenclature du produit terminé
  * @param iCPGoodId Identifiant du composant à  contrôler
  * @param iTypNom  type de la nomenclature à  contrôler, par défaut = '2' -> nomenclature de production
  * @return 0 = composant inexistant / 1 = composant existe dans la nomenclature
  */
  function checkGoodInNomBond(
    iNomenclatureId    PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type
  , iCPGoodId          PPS_NOM_BOND.GCO_GOOD_ID%type
  , iTypNom         in PPS_NOMENCLATURE.C_TYPE_NOM%type default cTypeNomProd
  )
    return number
  is
    lReturn PPS_NOM_BOND.GCO_GOOD_ID%type;
  begin
    if iCPGoodId is null then
      return 1;
    end if;

    select nvl(max(GCO_GOOD_ID), 0)
      into lReturn
      from PPS_NOM_BOND
     where PPS_NOMENCLATURE_ID = iNomenclatureId
       and gco_good_id = iCPGoodId;

    if lReturn > 0 then
      return 1;
    else
      return 0;
    end if;
  end CheckGoodInNomBond;

  /**
  * Description
  *   retourne l'id de la nomenclature par défaut pour le bien et le type de nomenclature demandés
  */
  function GetDefaultNomenclature(iGoodId in PPS_NOMENCLATURE.GCO_GOOD_ID%type, iTypNom in PPS_NOMENCLATURE.C_TYPE_NOM%type)
    return PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  is
    lResult PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    select PPS_NOMENCLATURE_ID
      into lResult
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = iGoodId
       and C_TYPE_NOM = iTypNom
       and NOM_DEFAULT = 1;

    return lResult;
  exception
    when no_data_found then
      begin
        select max(PPS_NOMENCLATURE_ID)
          into lResult
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = iGoodId
           and C_TYPE_NOM = iTypNom
           and nvl(NOM_VERSION, ' ') = (select nvl(max(NOM_VERSION), ' ')
                                          from PPS_NOMENCLATURE
                                         where GCO_GOOD_ID = iGoodId
                                           and C_TYPE_NOM = iTypNom);

        if lResult is null then
          raise no_data_found;
        else
          return lResult;
        end if;
      exception
        when no_data_found then
          -- si pas trouvé de nomenclature de vente ou d'étude,
          -- on recherche une nomenclature de production
          if iTypNom in(cTypeNomSale, cTypeNomStudy) then
            return GetDefaultNomenclature(iGoodId, cTypeNomProd);
          else
            return null;
          end if;
      end;
  end GetDefaultNomenclature;

  /**
  * Description
  *   Regarde si la nomenclature a des composants et pas seulement des liens textes
  */
  function HasComponents(iNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from PPS_INTERROGATION
     where PPS_NOMENCLATURE_ID = iNomenclatureID
       and C_KIND_COM = '1';

    return lResult;
  end HasComponents;
end PPS_LIB_FUNCTIONS;
