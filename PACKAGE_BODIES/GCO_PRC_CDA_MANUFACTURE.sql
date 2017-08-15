--------------------------------------------------------
--  DDL for Package Body GCO_PRC_CDA_MANUFACTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRC_CDA_MANUFACTURE" 
is
  /*
  * function ExistsOtherDefaultCda
  * Description
  *   V�rifie s'il y a une autre donn�e compl. de fabrication que celle pass�e en param
  *     avec le flag d�fault coch�
  */
  function ExistsOtherDefaultCda(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iExcludeCdaID in GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type)
    return boolean
  is
    lnCount integer;
  begin
    -- rechercher les donn�es compl. de fabrication du bien qui sont flagu�es "d�faut"
    -- autres que celle de l'id de donn�e compl. pass� en param
    select count(*)
      into lnCount
      from GCO_COMPL_DATA_MANUFACTURE
     where GCO_GOOD_ID = iGoodID
       and CMA_DEFAULT = 1
       and GCO_COMPL_DATA_MANUFACTURE_ID <> iExcludeCdaID;

    if lnCount = 0 then
      return false;
    else
      return true;
    end if;
  end ExistsOtherDefaultCda;

  /*
  * function ControlData
  * Description
  *   Ctrl la coh�rance des donn�es d'une donn�e compl. de fabrication (insert et update)
  */
  function ControlData(iotComplDataManufacture in out nocopy fwk_i_typ_definition.t_crud_def)
    return boolean
  is
    lnSTM_STOCK_ID    STM_STOCK.STM_STOCK_ID%type;
    lnSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type;
    lResult           boolean                             := true;
    lvMsg             varchar2(32000);
  begin
    -- Si R�gle temporelle d'approvisionnement = 2 (D�lai fixe)
    -- Alors le "D�calage" doit �tre � 0
    if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotComplDataManufacture, 'C_TIME_SUPPLY_RULE') = '2' then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CMA_SHIFT', 0);
    end if;

    -- Si le stock et emplacement sont renseign�s, v�rifier l'int�grit� des 2
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_STOCK_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_LOCATION_ID') then
      lnSTM_LOCATION_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'STM_LOCATION_ID');

      -- Rechercher l'id du stock de l'emplacement sp�cifi�
      select STM_STOCK_ID
        into lnSTM_STOCK_ID
        from STM_LOCATION
       where STM_LOCATION_ID = lnSTM_LOCATION_ID;

      -- Si pas m�me id de stock, �craser avec celui de la recherche ci-dessus
      if lnSTM_STOCK_ID <> FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'STM_STOCK_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'STM_STOCK_ID', lnSTM_STOCK_ID);
      end if;
    else
      -- Un des 2 champs n'est pas renseign�, alors on vide l'autre
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_STOCK_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotComplDataManufacture, 'STM_STOCK_ID');
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_LOCATION_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotComplDataManufacture, 'STM_LOCATION_ID');
      end if;
    end if;

    -- Contr�ler le code EAN
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE') then
      if GCO_EAN.EAN_Ctrl(aGenre     => 7
                        , aEANCode   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE')
                        , aGoodID    => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'GCO_GOOD_ID')
                         ) = 0 then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotComplDataManufacture, 'CDA_COMPLEMENTARY_UCC14_CODE');
      end if;
    end if;

    -- Contr�le si plus d'une donn�e de fabrication par d�faut
    if (nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'CMA_DEFAULT'), 0) = 1) then
      if ExistsOtherDefaultCda(iGoodID         => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'GCO_GOOD_ID')
                             , iExcludeCdaID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'GCO_COMPL_DATA_MANUFACTURE_ID')
                              ) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CMA_DEFAULT', 0);
      end if;
    end if;

    -- Contr�le que la quantit� �conomique soit <> 0 si code quantit� �conomique (2)
    if     (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotComplDataManufacture, 'C_QTY_SUPPLY_RULE') = '2')
       and (nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'CMA_ECONOMICAL_QUANTITY'), 0) <= 0) then
      lResult  := false;
      lvMsg    := PCS.PC_FUNCTIONS.TranslateWord('La quantit� �conomique doit �tre sup�rieure � 0 !');
      RA(lvMsg);
    end if;

    -- Contr�le que le d�lai fixe soit <> 0 si code d�lai fixe (2)
    if     (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotComplDataManufacture, 'C_TIME_SUPPLY_RULE') = '2')
       and (nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'CMA_FIXED_DELAY'), 0) <= 0) then
      lResult  := false;
      lvMsg    := PCS.PC_FUNCTIONS.TranslateWord('Le nombre de p�riodicit� fixe doit �tre sup�rieur � 0 !');
      RA(lvMsg);
    end if;

    -- Contr�le si la quantit� lot standard est plus grande que z�ro
    if (nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'CMA_LOT_QUANTITY'), 0) <= 0) then
      lResult  := false;
      lvMsg    := PCS.PC_FUNCTIONS.TranslateWord('La quantit� lot standard doit �tre sup�rieure � 0 !');
      RA(lvMsg);
    end if;

    -- Contr�le que le % de r�but ne soit pas sup�rieur � 100%
    if (nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'CMA_PERCENT_TRASH'), 0) > 100) then
      lResult  := false;
      lvMsg    := PCS.PC_FUNCTIONS.TranslateWord('Le pourcentage de rebut doit �tre strictement inf�rieur � 100 !');
      RA(lvMsg);
    end if;

    return lResult;
  end ControlData;

  /**
  * procedure InitializeData
  * Description
  *   Init des donn�es de base de la donn�e compl. de fabrication
  */
  procedure InitializeData(iotComplDataManufacture in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnGCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type;
    lnPPS_NOMENCLATURE_ID      PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    lnGCO_SUBSTITUTION_LIST_ID GCO_GOOD.GCO_SUBSTITUTION_LIST_ID%type;
    lvDIC_UNIT_OF_MEASURE_ID   GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lnGOO_NUMBER_OF_DECIMAL    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnSTM_STOCK_ID             STM_STOCK.STM_STOCK_ID%type;
    lnSTM_LOCATION_ID          STM_LOCATION.STM_LOCATION_ID%type;
  begin
    lnGCO_GOOD_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture, 'GCO_GOOD_ID');

    -- Reprendre les infos du bien/produit
    select GOO.GCO_SUBSTITUTION_LIST_ID
         , GOO.DIC_UNIT_OF_MEASURE_ID
         , GOO.GOO_NUMBER_OF_DECIMAL
         , PDT.STM_STOCK_ID
         , PDT.STM_LOCATION_ID
      into lnGCO_SUBSTITUTION_LIST_ID
         , lvDIC_UNIT_OF_MEASURE_ID
         , lnGOO_NUMBER_OF_DECIMAL
         , lnSTM_STOCK_ID
         , lnSTM_LOCATION_ID
      from GCO_GOOD GOO
         , GCO_PRODUCT PDT
     where GOO.GCO_GOOD_ID = lnGCO_GOOD_ID
       and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID;

    -- Init du champ si pas renseign�s et pas forc�s � null
    -- PPS_NOMENCLATURE_ID : Nomenclature
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'PPS_NOMENCLATURE_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'PPS_NOMENCLATURE_ID') then
      -- Rechercher la nomenclature du produit.
      select max(PPS_NOMENCLATURE_ID)
        into lnPPS_NOMENCLATURE_ID
        from (select   PPS_NOMENCLATURE_ID
                  from PPS_NOMENCLATURE
                 where GCO_GOOD_ID = lnGCO_GOOD_ID
                   and C_TYPE_NOM in('2', '3', '4')
              order by C_TYPE_NOM asc
                     , NOM_DEFAULT desc)
       where rownum = 1;

      if lnPPS_NOMENCLATURE_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'PPS_NOMENCLATURE_ID', lnPPS_NOMENCLATURE_ID);
      end if;
    end if;

    -- CMA_FIXED_DELAY : Nombre de p�riodicit� fixe
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CMA_FIXED_DELAY')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'CMA_FIXED_DELAY')
       and (PCS.PC_CONFIG.GetConfig('GCO_CManu_FIXED_DELAY') is not null) then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CMA_FIXED_DELAY', PCS.PC_CONFIG.GetConfig('GCO_CManu_FIXED_DELAY') );
    end if;

    -- CMA_MANUFACTURING_DELAY : Dur�e de fabrication si planif. "Selon produit"
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CMA_MANUFACTURING_DELAY')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'CMA_MANUFACTURING_DELAY')
       and (PCS.PC_CONFIG.GetConfig('GCO_CManu_MANU_DELAY') is not null) then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CMA_MANUFACTURING_DELAY', PCS.PC_CONFIG.GetConfig('GCO_CManu_MANU_DELAY') );
    end if;

    -- DIC_UNIT_OF_MEASURE_ID : Unit� de mesure
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'DIC_UNIT_OF_MEASURE_ID') then
      -- Reprendre l'unit� de mesure du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'DIC_UNIT_OF_MEASURE_ID', lvDIC_UNIT_OF_MEASURE_ID);
    end if;

    -- CDA_NUMBER_OF_DECIMAL : Nbr d�cimales g�r�es
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CDA_NUMBER_OF_DECIMAL') then
      -- Reprendre le nbr d�cimales g�r�es du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CDA_NUMBER_OF_DECIMAL', lnGOO_NUMBER_OF_DECIMAL);
    end if;

    -- GCO_SUBSTITUTION_LIST_ID : Liste de substitution
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'GCO_SUBSTITUTION_LIST_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'GCO_SUBSTITUTION_LIST_ID')
       and (lnGCO_SUBSTITUTION_LIST_ID is not null) then
      -- Reprendre la Liste de substitution du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'GCO_SUBSTITUTION_LIST_ID', lnGCO_SUBSTITUTION_LIST_ID);
    end if;

    -- STM_STOCK_ID : Stock
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_STOCK_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'STM_STOCK_ID')
       and (lnSTM_STOCK_ID is not null) then
      -- Reprendre le Stock du produit
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'STM_STOCK_ID', lnSTM_STOCK_ID);
    end if;

    -- STM_LOCATION_ID : Emplacement de stock
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_STOCK_ID') then
      -- si le stock n'est pas renseign�, effacer l'emplacement de stock
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotComplDataManufacture, 'STM_LOCATION_ID');
    elsif     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'STM_LOCATION_ID')
          and (lnSTM_LOCATION_ID is not null) then
      -- Reprendre l'Emplacement de stock du produit
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'STM_LOCATION_ID', lnSTM_LOCATION_ID);
    end if;

    -- CDA_CONVERSION_FACTOR : Facteur de conversion
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CDA_CONVERSION_FACTOR') then
      -- si nul, forcer la valeur � 1 car ce champ est obligatoire
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CDA_CONVERSION_FACTOR', 1);
    end if;

    -- C_QTY_SUPPLY_RULE : R�gle quantitative d'approvisionnement
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'C_QTY_SUPPLY_RULE') then
      -- si nul, forcer la valeur � '1' car ce champ est obligatoire
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'C_QTY_SUPPLY_RULE', '1');
    end if;

    -- C_TIME_SUPPLY_RULE : R�gle temporelle d'appro
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'C_TIME_SUPPLY_RULE') then
      -- si nul, forcer la valeur � '1' car ce champ est obligatoire
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'C_TIME_SUPPLY_RULE', '1');
    end if;

    -- C_ECONOMIC_CODE : Code quantit� �conomique
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'C_ECONOMIC_CODE') then
      -- si nul, forcer la valeur � '1' car ce champ est obligatoire
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'C_ECONOMIC_CODE', '1');
    end if;

    -- CMA_LOT_QUANTITY : Quantit� lot standard
    if     FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CMA_LOT_QUANTITY')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotComplDataManufacture, 'CMA_LOT_QUANTITY') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CMA_LOT_QUANTITY', 1);
    end if;

    -- G�n�rer les codes EAN
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE') then
      declare
        lvEANCODE   GCO_COMPL_DATA_MANUFACTURE.CDA_COMPLEMENTARY_EAN_CODE%type;
        lvUCC14CODE GCO_COMPL_DATA_MANUFACTURE.CDA_COMPLEMENTARY_UCC14_CODE%type;
        lvError     varchar2(100);
      begin
        GCO_BARCODE_FUNCTIONS.GetEANUCC14Codes(iAdminDomain        => '7'
                                             , iGoodID             => lnGCO_GOOD_ID
                                             , iDicUnitOfMeasure   => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotComplDataManufacture, 'DIC_UNIT_OF_MEASURE_ID')
                                             , ioEANCode           => lvEANCODE
                                             , oUCC14Code          => lvUCC14CODE
                                             , oError              => lvError
                                              );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE', lvEANCODE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotComplDataManufacture, 'CDA_COMPLEMENTARY_UCC14_CODE', lvUCC14CODE);
      end;
    end if;
  end InitializeData;

  /**
  * procedure UpdateGoodManufacture
  * Description
  *   M�j du flag sur le bien indiquant qu'il poss�de ou pas des donn�es compl. de fabrication
  */
  procedure UpdateGoodManufacture(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lnCMA_EXISTS           integer;
    lnGCO_DATA_MANUFACTURE GCO_GOOD.GCO_DATA_MANUFACTURE%type;
    ltGood                 FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- V�rifier que la valeur du flag sur le bien indiquant la pr�sence ou pas
    -- de donn�es compl. de fabrication correspond au contenu de la table
    -- des donn�es compl.
    select   sign(count(CMA.GCO_GOOD_ID) )
           , GOO.GCO_DATA_MANUFACTURE
        into lnCMA_EXISTS
           , lnGCO_DATA_MANUFACTURE
        from GCO_GOOD GOO
           , GCO_COMPL_DATA_MANUFACTURE CMA
       where GOO.GCO_GOOD_ID = iGoodID
         and GOO.GCO_GOOD_ID = CMA.GCO_GOOD_ID(+)
    group by GOO.GCO_DATA_MANUFACTURE;

    -- La valeur du flag du bien n'est pas correcte
    if lnCMA_EXISTS <> lnGCO_DATA_MANUFACTURE then
        -- m�j du flag sur le bien
      -- Cr�ation de l'entit� GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', iGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_MANUFACTURE', lnGCO_DATA_MANUFACTURE);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);
    end if;
  end UpdateGoodManufacture;

  /**
  * function CreateCdaManufacture
  * Description
  *   Ajout d'une donn�e compl. de fabrication
  */
  function CreateCdaManufacture(
    iGoodID            in GCO_COMPL_DATA_MANUFACTURE.GCO_GOOD_ID%type
  , iDicFabConditionID in GCO_COMPL_DATA_MANUFACTURE.DIC_FAB_CONDITION_ID%type default null
  , iNomenclatureID    in GCO_COMPL_DATA_MANUFACTURE.PPS_NOMENCLATURE_ID%type default null
  , iSchedulePlanID    in GCO_COMPL_DATA_MANUFACTURE.FAL_SCHEDULE_PLAN_ID%type default null
  )
    return number
  is
    ltCDAManuf   fwk_i_typ_definition.t_crud_def;
    lnCDAManufID GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoComplDataManufacture, ltCDAManuf, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCDAManuf, 'GCO_GOOD_ID', iGoodID);

    if iDicFabConditionID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCDAManuf, 'DIC_FAB_CONDITION_ID', iDicFabConditionID);
    end if;

    if iNomenclatureID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCDAManuf, 'PPS_NOMENCLATURE_ID', iNomenclatureID);
    end if;

    if iSchedulePlanID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCDAManuf, 'FAL_SCHEDULE_PLAN_ID', iSchedulePlanID);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCDAManuf);
    lnCDAManufID  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCDAManuf, 'GCO_COMPL_DATA_MANUFACTURE_ID');
    FWK_I_MGT_ENTITY.Release(ltCDAManuf);
    return lnCDAManufID;
  end CreateCdaManufacture;
end GCO_PRC_CDA_MANUFACTURE;
