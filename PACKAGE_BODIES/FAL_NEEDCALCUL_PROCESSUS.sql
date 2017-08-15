--------------------------------------------------------
--  DDL for Package Body FAL_NEEDCALCUL_PROCESSUS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_NEEDCALCUL_PROCESSUS" 
is
  -- C_PROP_TYPE
  ptStandard       char         := '1';
  ptStockObtention char         := '2';
  ptPlanDirecteur  char         := '3';
  ptTransfertStock char         := '4';
  -- Configurations
  cfgFAL_TOLERANCE varchar2(10) := PCS.PC_CONFIG.GetConfig('FAL_TOLERANCE');

  -- TPropositionDefinition = record décrivant un item de la table FAL_PROP_DEF
  type TPropositionDefinition is record(
    aPropDefID  FAL_PROP_DEF.FAL_PROP_DEF_ID%type
  , cPrefixProp FAL_PROP_DEF.C_PREFIX_PROP%type
  , aGaugeID    FAL_PROP_DEF.DOC_GAUGE_ID%type
  , aNumber     integer
  );

  function GetFAL_PIC_IDOfFAL_PIC_LINE_ID(aFAL_PIC_LINE_ID FAL_PIC_LINE.FAL_PIC_LINE_ID%type)
    return FAL_PIC_LINE.FAL_PIC_ID%type
  is
    id FAL_PIC_LINE.FAL_PIC_ID%type;
  begin
    select FAL_PIC_ID
      into id
      from FAL_PIC_LINE
     where FAL_PIC_LINE_ID = aFAL_PIC_LINE_ID;

    return id;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * procedure : Get3DelaisOnFAL_SUPPLY_REQUEST
  * Description : Prise en compte des 3 délais saisi par l'utilisateur dans les demandes d'appros.
  *               sélectionné selon les paramètres données
  * @created
  * @lastUpdate ECA
  * @public
  */
  procedure Get3DelaisOnFAL_SUPPLY_REQUEST(
    aFAL_SUPPLY_REQUEST_ID     FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  , OutBasisDelay          out date
  , OutIntermediateDelay   out date
  , OutFinalDelay          out date
  )
  is
  begin
    select FSR_BASIS_DELAY
         , FSR_INTERMEDIATE_DELAY
         , FSR_DELAY
      into OutBasisDelay
         , OutIntermediateDelay
         , OutFinalDelay
      from FAL_SUPPLY_REQUEST
     where FAL_SUPPLY_REQUEST_ID = aFAL_SUPPLY_REQUEST_ID;
  end;

  /**
  * procedure : GetPropositionDefinition
  * Description : Retourner sous forme de record TPropositionDefinition un record de FAL_PROP_DEF
  *               sélectionné selon les paramètres données
  * @created
  * @lastUpdate ECA
  * @public
  */
  function GetPropositionDefinition(aTypeProp varchar, aSupplyMode varchar)
    return TPropositionDefinition
  is
    Resultat TPropositionDefinition;
  begin
    Resultat.aPropDefID   := 0;
    Resultat.cPrefixProp  := null;
    Resultat.aGaugeID     := 0;
    Resultat.aNumber      := 0;

    if trim(aSupplyMode) is null then
      select FAL_PROP_DEF_ID
           , C_PREFIX_PROP
           , nvl(DOC_GAUGE_ID, 0)
           , FPR_METER
        into Resultat.aPropDefID
           , Resultat.cPrefixProp
           , Resultat.aGaugeID
           , Resultat.aNumber
        from FAL_PROP_DEF
       where C_PROP_TYPE = aTypeProp;
    else
      select FAL_PROP_DEF_ID
           , C_PREFIX_PROP
           , nvl(DOC_GAUGE_ID, 0)
           , FPR_METER
        into Resultat.aPropDefID
           , Resultat.cPrefixProp
           , Resultat.aGaugeID
           , Resultat.aNumber
        from FAL_PROP_DEF
       where C_PROP_TYPE = aTypeProp
         and C_SUPPLY_MODE = aSupplyMode;
    end if;

    return Resultat;
  exception
    when no_data_found then
      return Resultat;
  end;

  /**
  * procedure : IncFPRMeter
  * Description : Incrémenter de 1 le champ FPR_METER de la table FAL_PROP_DEF pour l'ID donné
  *
  * @created
  * @lastUpdate ECA
  * @public
  */
  procedure IncFPRMeter(aPropDefID FAL_PROP_DEF.FAL_PROP_DEF_ID%type)
  is
  begin
    if aPropDefID <> 0 then
      update FAL_PROP_DEF
         set FPR_METER = nvl(FPR_METER, 0) + 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_PROP_DEF_ID = aPropDefID;
    end if;
  end;

  /**
  * procedure : Processus_CreatePropApproLog
  * Description : Création de proposition d'approvisionnement logistique
  *
  * @created
  * @lastUpdate ECA
  * @public
  */
  procedure Processus_CreatePropApproLog(
    aPropID                  out FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , cSupplyMode                  GCO_PRODUCT.C_SUPPLY_MODE%type
  , SupplierID                   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , ControlDelay                 integer
  , SupplyDelay                  integer
  , ConversionFactor             number
  , aTypeProp                    varchar
  , aNeedID                      FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  , aGoodID                      GCO_GOOD.GCO_GOOD_ID%type
  , aOriginStockID               STM_STOCK.STM_STOCK_ID%type
  , aOriginLocationID            STM_LOCATION.STM_LOCATION_ID%type
  , aTargetStockID               STM_STOCK.STM_STOCK_ID%type
  , aTargetLocationID            STM_LOCATION.STM_LOCATION_ID%type
  , aNeedDate                    date
  , aQteDemande                  number
  , aQteRebutPlannifie           number
  , aCharacterizations_ID1       GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID2       GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID3       GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID4       GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID5       GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_VA1       FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , aCharacterizations_VA2       FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , aCharacterizations_VA3       FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , aCharacterizations_VA4       FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , aCharacterizations_VA5       FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , aText                        varchar
  , aPlanDirecteurId             FAL_PIC.FAL_PIC_ID%type
  , aSupplyRequestID             FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  , bPlanifOnBeginDate           integer
  , aDOC_RECORD_ID               DOC_RECORD.DOC_RECORD_ID%type
  , IsCallByNeedCalculation      integer default 0
  , aFAL_PIC_LINE_ID             number default null
  , aGOO_SECONDARY_REFERENCE     varchar2 default null
  , aDES_SHORT_DESCR             varchar2 default null
  , aSecurityDelay               integer default 0
  )
  is
    I                       integer;
    aDocRecordID            DOC_RECORD.DOC_RECORD_ID%type;
    aFalPicLineID           FAL_PIC_LINE.FAL_PIC_LINE_ID%type;
    aFAL_PIC_ID             FAL_PIC.FAL_PIC_ID%type;
    aSupplierID             PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    vThirdAciID             PAC_THIRD.PAC_THIRD_ID%type;
    vThirdDeliveryID        PAC_THIRD.PAC_THIRD_ID%type;
    vThirdTariffID          PAC_THIRD.PAC_THIRD_ID%type;
    aGoodShortDescription   GCo_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    aGoodSecondaryReference GCo_GOOD.GOO_SECONDARY_REFERENCE%type;
    aPropDef                TPropositionDefinition;
    aFinalDelay             date;
    aIntermediateDelay      date;
    aBasisDelay             date;
    aConvertFactor          number;
    aDefaultCalendar        number;
    cGaugeTitle             DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aGaugeID                FAL_DOC_PROP.DOC_GAUGE_ID%type;
    liFalDocProp            FAL_DOC_PROP%rowtype;
  begin
    -- Recherche du calendrier par défaut
    aDefaultCalendar := FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar;

    -- Définir le nouvel ID
    aPropID := GetNewId;

    -- Récupérer la définition de proposition. Initialisations particulières dans
    -- le cadre de proposition de transfert de stock
    if aTypeProp = ptTransfertStock then
      aPropDef        := GetPropositionDefinition(aTypeProp, '');
      aSupplierID     := 0;
      aConvertFactor  := 1;
    else
      aPropDef        := GetPropositionDefinition(aTypeProp, cSupplyMode);
      aSupplierID     := SupplierID;
      aConvertFactor  := ConversionFactor;
    end if;

    -- Incrémenter le numéro de proposition
    aPropDef.aNumber                           := nvl(aPropDef.aNumber, 0) + 1;

    -- Appel depuis le CB, les infos sont déjà connues, on ne va pas les rechercher
    if IsCallByNeedCalculation = 1 then
      -- Récupérer la référence secondaire et description courte du produit ...
      aGoodSecondaryReference  := aGOO_SECONDARY_REFERENCE;
      aGoodShortDescription    := aDES_SHORT_DESCR;
      aDocRecordId             := FAL_TOOLS.NIFZ(aDOC_RECORD_ID);
      aFalPicLineID            := FAL_TOOLS.NIFZ(aFAL_PIC_LINE_ID);
    else
      -- Récupérer la référence secondaire et description courte du produit ...
      aGoodSecondaryReference  := FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aGoodID);
      aGoodShortDescription    := FAL_TOOLS.GetGOO_SHORT_DESCRIPTION(aGoodID);

      -- Déterminer le dossier ...
      if aDOC_RECORD_ID <> 0 then
        aDocRecordId  := aDOC_RECORD_ID;
      else
        if nvl(aNeedID, 0) = 0 then
          aDocRecordID  := null;
        else
          select DOC_RECORD_ID
            into aDocRecordID
            from FAL_NETWORK_NEED
           where FAL_NETWORK_NEED_ID = aNeedID;
        end if;
      end if;

      -- Déterminer le FAL_PIC_LINE
      aFalPicLineID            := FAL_TOOLS.GetPicLineByNeed(aNeedId);
    end if;

    -- Prise en compte des 3 délais saisi par l'utilisateur dans les demandes d'appros.
    if aSupplyRequestID = 0 then
      if aTypeProp = ptTransfertStock then
        aFinalDelay         := aNeedDate;
        aIntermediateDelay  := aNeedDate;
        aBasisDelay         := aNeedDate;
      else
        if bPlanifOnBeginDate = 0 then
          -- Déterminer le délai Final
          if nvl(to_number(cfgFAL_TOLERANCE), 0) + aSecurityDelay > 0 then
            aFinalDelay  :=
              FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(null
                                                           , null
                                                           , null
                                                           , null
                                                           , null
                                                           , aDefaultCalendar
                                                           , aNeedDate
                                                           , nvl(to_number(cfgFAL_TOLERANCE), 0) + aSecurityDelay
                                                            );
          else
            aFinalDelay  := aNeedDate;
          end if;

          -- Déterminer le délai Intermédiaire
          if nvl(ControlDelay, 0) > 0 then
            aIntermediateDelay  := FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(null, null, null, null, null, aDefaultCalendar, aFinalDelay, ControlDelay);
          else
            aIntermediateDelay  := aFinalDelay;
          end if;

          -- Déterminer le délai de base ...
          if nvl(SupplyDelay, 0) > 0 then
            aBasisDelay  := FAL_SCHEDULE_FUNCTIONS.GetDecalageBackwardDate(null, aSupplierID, null, null, null, null, aIntermediateDelay, SupplyDelay);
          else
            aBasisDelay  := aIntermediateDelay;
          end if;
        else
          -- Déterminer le délai de base ...
          aBasisDelay  := aNeedDate;

          -- Déterminer le délai Intermédiaire ...
          if nvl(SupplyDelay, 0) > 0 then
            aIntermediateDelay  :=
              FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_Factory_Floor_Id      => null
                                                          , aPac_Supplier_Partner_Id   => null
                                                          , aPac_Custom_Partner_Id     => null
                                                          , aPac_Department_Id         => null
                                                          , aHrm_Person_Id             => null
                                                          , aCalendarId                => aDefaultCalendar
                                                          , aFromDate                  => aBasisDelay
                                                          , aDecalage                  => SupplyDelay
                                                           );
          else
            aIntermediateDelay  := aBasisDelay;
          end if;

          -- Déterminer le délai Final ...
          if nvl(ControlDelay, 0) > 0 then
            aFinalDelay  :=
              FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_Factory_Floor_Id      => null
                                                          , aPac_Supplier_Partner_Id   => null
                                                          , aPac_Custom_Partner_Id     => null
                                                          , aPac_Department_Id         => null
                                                          , aHrm_Person_Id             => null
                                                          , aCalendarId                => aDefaultCalendar
                                                          , aFromDate                  => aIntermediateDelay
                                                          , aDecalage                  => ControlDelay
                                                           );
          else
            aFinalDelay  := aIntermediateDelay;
          end if;
        end if;
      end if;
    -- Demande d'approvisionnement : Initialisation avec les délais saisis par l'utilisateur.
    else
      Get3DelaisOnFAL_SUPPLY_REQUEST(aSupplyRequestID, aBasisDelay, aIntermediateDelay, aFinalDelay);
    end if;

    -- Recherche des partenaires du tiers
    DOC_DOCUMENT_FUNCTIONS.GetThirdPartners(aThirdID           => FAL_TOOLS.NIFZ(aSupplierID)
                                          , aGaugeID           => FAL_TOOLS.NIFZ(aPropDef.aGaugeID)
                                          , aAdminDomain       => '1'
                                          , aThirdAciID        => vThirdAciID
                                          , aThirdDeliveryID   => vThirdDeliveryID
                                          , aThirdTariffID     => vThirdTariffID
                                           );

    -- Déterminer le FAL_PIC_ID
    if nvl(aFalPicLineID, 0) > 0 then
      begin
        select FAL_PIC_ID
          into aFAL_PIC_ID
          from FAL_PIC_LINE
         where FAL_PIC_LINE_ID = aFalPicLineID;
      exception
        when no_data_found then
          aFAL_PIC_ID  := null;
      end;
    else
      aFAL_PIC_ID  := null;
    end if;

    -- Création du record de proposition
    liFalDocProp.FAL_DOC_PROP_ID               := aPropID;
    liFalDocProp.C_PREFIX_PROP                 := aPropDef.cPrefixProp;
    liFalDocProp.FDP_NUMBER                    := aPropDef.aNumber;
    liFalDocProp.DOC_GAUGE_ID                  := FAL_TOOLS.NIFZ(aPropDef.aGaugeID);
    liFalDocProp.PAC_SUPPLIER_PARTNER_ID       := FAL_TOOLS.NIFZ(aSupplierID);
    liFalDocProp.PAC_THIRD_ACI_ID              := vThirdAciID;
    liFalDocProp.PAC_THIRD_DELIVERY_ID         := vThirdDeliveryID;
    liFalDocProp.PAC_THIRD_TARIFF_ID           := vThirdTariffID;
    liFalDocProp.GCO_GOOD_ID                   := aGoodId;
    liFalDocProp.FDP_SECOND_REF                := aGoodSecondaryReference;
    liFalDocProp.FDP_PSHORT_DESCR              := aGoodShortDescription;
    liFalDocProp.FDP_BASIS_QTY                 := aQteDemande;
    liFalDocProp.FDP_INTERMEDIATE_QTY          := aQteRebutPlannifie;
    liFalDocProp.FDP_FINAL_QTY                 := nvl(aQteDemande, 0) + nvl(aQteRebutPlannifie, 0);
    liFalDocProp.FDP_FINAL_DELAY               := aFinalDelay;
    liFalDocProp.FDP_INTERMEDIATE_DELAY        := aIntermediateDelay;
    liFalDocProp.FDP_BASIS_DELAY               := aBasisDelay;
    liFalDocProp.FDP_CONVERT_FACTOR            := aConvertFactor;
    liFalDocProp.DOC_RECORD_ID                 := FAL_TOOLS.NIFZ(aDocRecordID);
    liFalDocProp.FAL_PIC_LINE_ID               := FAL_TOOLS.NIFZ(aFalPicLIneID);
    liFalDocProp.STM_STOCK_ID                  := FAL_TOOLS.NIFZ(aOriginStockID);
    liFalDocProp.STM_LOCATION_ID               := FAL_TOOLS.NIFZ(aOriginLocationID);
    liFalDocProp.STM_STM_STOCK_ID              := FAL_TOOLS.NIFZ(aTargetStockID);
    liFalDocProp.STM_STM_LOCATION_ID           := FAL_TOOLS.NIFZ(aTargetLocationID);
    liFalDocProp.GCO_CHARACTERIZATION1_ID      := FAL_TOOLS.NIFZ(aCharacterizations_ID1);
    liFalDocProp.GCO_CHARACTERIZATION2_ID      := FAL_TOOLS.NIFZ(aCharacterizations_ID2);
    liFalDocProp.GCO_CHARACTERIZATION3_ID      := FAL_TOOLS.NIFZ(aCharacterizations_ID3);
    liFalDocProp.GCO_CHARACTERIZATION4_ID      := FAL_TOOLS.NIFZ(aCharacterizations_ID4);
    liFalDocProp.GCO_CHARACTERIZATION5_ID      := FAL_TOOLS.NIFZ(aCharacterizations_ID5);
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_1  := FAL_TOOLS.OnNoZeroOrNullSetWithValue(aCharacterizations_ID1, aCharacterizations_VA1);
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_2  := FAL_TOOLS.OnNoZeroOrNullSetWithValue(aCharacterizations_ID2, aCharacterizations_VA2);
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_3  := FAL_TOOLS.OnNoZeroOrNullSetWithValue(aCharacterizations_ID3, aCharacterizations_VA3);
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_4  := FAL_TOOLS.OnNoZeroOrNullSetWithValue(aCharacterizations_ID4, aCharacterizations_VA4);
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_5  := FAL_TOOLS.OnNoZeroOrNullSetWithValue(aCharacterizations_ID5, aCharacterizations_VA5);
    liFalDocProp.FDP_TEXTE                     := aText;
    liFalDocProp.FAL_SUPPLY_REQUEST_ID         := FAL_TOOLS.NIFZ(aSupplyRequestID);
    liFalDocProp.FAL_PIC_ID                    := aFAL_PIC_ID;
    liFalDocProp.A_DATECRE                     := sysdate;
    liFalDocProp.A_IDCRE                       := PCS.PC_I_LIB_SESSION.GetUserIni;
    InsertFalDocProp(liFalDocProp);
    -- Incrémenter le compteur ...
    IncFPRMeter(aPropDef.aPropDefID);
  end;

  /**
  * Procedure : InsertFalDocProp
  * Description : Création de proposition d'achat
  *
  * @created
  * @lastUpdate ECA
  * @public

  */
  procedure InsertFalDocProp(iFalDocProp FAL_DOC_PROP%rowtype)
  is
  begin
    insert into FAL_DOC_PROP
                (FAL_DOC_PROP_ID
               , C_PREFIX_PROP
               , FDP_NUMBER
               , DOC_GAUGE_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PAC_THIRD_TARIFF_ID
               , GCO_GOOD_ID
               , FDP_SECOND_REF
               , FDP_PSHORT_DESCR
               , FDP_BASIS_QTY
               , FDP_INTERMEDIATE_QTY
               , FDP_FINAL_QTY
               , FDP_FINAL_DELAY
               , FDP_INTERMEDIATE_DELAY
               , FDP_BASIS_DELAY
               , FDP_CONVERT_FACTOR
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_STOCK_ID
               , STM_STM_LOCATION_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FDP_CHARACTERIZATION_VALUE_1
               , FDP_CHARACTERIZATION_VALUE_2
               , FDP_CHARACTERIZATION_VALUE_3
               , FDP_CHARACTERIZATION_VALUE_4
               , FDP_CHARACTERIZATION_VALUE_5
               , FDP_TEXTE
               , FAL_SUPPLY_REQUEST_ID
               , FAL_PIC_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (iFalDocProp.FAL_DOC_PROP_ID
               , iFalDocProp.C_PREFIX_PROP
               , iFalDocProp.FDP_NUMBER
               , iFalDocProp.DOC_GAUGE_ID
               , iFalDocProp.PAC_SUPPLIER_PARTNER_ID
               , iFalDocProp.PAC_THIRD_ACI_ID
               , iFalDocProp.PAC_THIRD_DELIVERY_ID
               , iFalDocProp.PAC_THIRD_TARIFF_ID
               , iFalDocProp.GCO_GOOD_ID
               , iFalDocProp.FDP_SECOND_REF
               , iFalDocProp.FDP_PSHORT_DESCR
               , iFalDocProp.FDP_BASIS_QTY
               , iFalDocProp.FDP_INTERMEDIATE_QTY
               , iFalDocProp.FDP_FINAL_QTY
               , iFalDocProp.FDP_FINAL_DELAY
               , iFalDocProp.FDP_INTERMEDIATE_DELAY
               , iFalDocProp.FDP_BASIS_DELAY
               , iFalDocProp.FDP_CONVERT_FACTOR
               , iFalDocProp.DOC_RECORD_ID
               , iFalDocProp.FAL_PIC_LINE_ID
               , iFalDocProp.STM_STOCK_ID
               , iFalDocProp.STM_LOCATION_ID
               , iFalDocProp.STM_STM_STOCK_ID
               , iFalDocProp.STM_STM_LOCATION_ID
               , iFalDocProp.GCO_CHARACTERIZATION1_ID
               , iFalDocProp.GCO_CHARACTERIZATION2_ID
               , iFalDocProp.GCO_CHARACTERIZATION3_ID
               , iFalDocProp.GCO_CHARACTERIZATION4_ID
               , iFalDocProp.GCO_CHARACTERIZATION5_ID
               , iFalDocProp.FDP_CHARACTERIZATION_VALUE_1
               , iFalDocProp.FDP_CHARACTERIZATION_VALUE_2
               , iFalDocProp.FDP_CHARACTERIZATION_VALUE_3
               , iFalDocProp.FDP_CHARACTERIZATION_VALUE_4
               , iFalDocProp.FDP_CHARACTERIZATION_VALUE_5
               , iFalDocProp.FDP_TEXTE
               , iFalDocProp.FAL_SUPPLY_REQUEST_ID
               , iFalDocProp.FAL_PIC_ID
               , iFalDocProp.A_DATECRE
               , iFalDocProp.A_IDCRE
                );
  end InsertFalDocProp;
end;
