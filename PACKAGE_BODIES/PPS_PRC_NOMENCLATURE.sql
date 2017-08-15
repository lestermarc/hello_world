--------------------------------------------------------
--  DDL for Package Body PPS_PRC_NOMENCLATURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_PRC_NOMENCLATURE" 
is
  /**
  * function CreateNomenclature
  * Description
  *   Création d'une nomenclature
  */
  function CreateNomenclature(
    iGoodID  in GCO_GOOD.GCO_GOOD_ID%type
  , iTypeNom in PPS_NOMENCLATURE.C_TYPE_NOM%type default null
  , iVersion in PPS_NOMENCLATURE.NOM_VERSION%type default null
  , iRefQty  in PPS_NOMENCLATURE.NOM_REF_QTY%type default null
  )
    return number
  is
    ltNom   FWK_I_TYP_DEFINITION.t_crud_def;
    lnNomID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsNomenclature, ltNom, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNom, 'GCO_GOOD_ID', iGoodID);

    if iTypeNom is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNom, 'C_TYPE_NOM', iTypeNom);
    end if;

    if iVersion is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNom, 'NOM_VERSION', iVersion);
    end if;

    if iRefQty is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNom, 'NOM_REF_QTY', iRefQty);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltNom);
    lnNomID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNom, 'PPS_NOMENCLATURE_ID');
    FWK_I_MGT_ENTITY.Release(ltNom);
    return lnNomID;
  end CreateNomenclature;

  /**
  * function CreateNomBond
  * Description
  *   Ajout d'un composant à une nomenclature
  */
  function CreateNomBond(
    iNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , iGoodID         in GCO_GOOD.GCO_GOOD_ID%type
  , iUtilCoeff      in PPS_NOM_BOND.COM_UTIL_COEFF%type default null
  )
    return number
  is
    ltCom   FWK_I_TYP_DEFINITION.t_crud_def;
    lnComID PPS_NOM_BOND.PPS_NOM_BOND_ID%type;
  begin
    -- création d'un composant
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsNomBond, ltCom, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCom, 'PPS_NOMENCLATURE_ID', iNomenclatureID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCom, 'GCO_GOOD_ID', iGoodID);

    if iUtilCoeff is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCom, 'COM_UTIL_COEFF', iUtilCoeff);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCom);
    lnComID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCom, 'PPS_NOM_BOND_ID');
    FWK_I_MGT_ENTITY.Release(ltCom);
    return lnComID;
  end CreateNomBond;

  /**
  * procedure CheckNomenclatureData
  * Description
  *    Contrôle avant mise à jour du bien
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotNomenclature : Dossier SAV
  */
  procedure CheckNomenclatureData(iotNomenclature in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplNomenclature       FWK_TYP_PPS_ENTITY.tNomenclature            := FWK_TYP_PPS_ENTITY.gttNomenclature(iotNomenclature.entity_id);
    lMessage               varchar2(200);
    lInitNomenclatureGroup varchar2(100);
    ltype                  varchar2(100);
    lDecim                 number;
    lPDT_MARK_NOMENCLATURE GCO_PRODUCT.PDT_MARK_NOMENCLATURE%type;
    lId                    PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomenclature, 'GCO_GOOD_ID') then
      lMessage  := 'GCO_GOOD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomenclatureData'
                                         );
    end if;

    -- initialisation valeurs par défaut
    if ltplNomenclature.C_TYPE_NOM is null then
      ltplNomenclature.C_TYPE_NOM  := '2';   -- fabrication
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'C_TYPE_NOM', ltplNomenclature.C_TYPE_NOM);
    end if;

    if ltplNomenclature.NOM_REF_QTY is null then
      ltplNomenclature.NOM_REF_QTY  := 1;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'NOM_REF_QTY', ltplNomenclature.NOM_REF_QTY);
    end if;

    if ltplNomenclature.NOM_DEFAULT is null then
      ltplNomenclature.NOM_DEFAULT  := 1;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'NOM_DEFAULT', ltplNomenclature.NOM_DEFAULT);
    end if;

    if ltplNomenclature.C_REMPLACEMENT_NOM is null then
      ltplNomenclature.C_REMPLACEMENT_NOM  := '2';   --stock
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'C_REMPLACEMENT_NOM', ltplNomenclature.C_REMPLACEMENT_NOM);
    end if;

    -- traitement des mise à jour
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomenclature, 'GCO_GOOD_ID') then
      select PDT_MARK_NOMENCLATURE
        into lPDT_MARK_NOMENCLATURE
        from GCO_PRODUCT
       where GCO_GOOD_ID = ltplNomenclature.GCO_GOOD_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'NOM_MARK_NOMENCLATURE ', lPDT_MARK_NOMENCLATURE);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomenclature, 'NOM_REF_QTY') then
      update PPS_NOM_BOND
         set COM_REF_QTY = ltplNomenclature.NOM_REF_QTY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PPS_NOMENCLATURE_ID = ltplNomenclature.PPS_NOMENCLATURE_ID
         and COM_REF_QTY <> ltplNomenclature.NOM_REF_QTY;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomenclature, 'C_TYPE_NOM') then
      if PPS_LIB_FUNCTIONS.isTypeAuthorized(ltplNomenclature.C_TYPE_NOM) = '0' then
        SetMessage('C_TYPE_NOM value not authorized');
      end if;

      select nvl(max(PPS_NOMENCLATURE_ID), 0)
        into lId
        from PPS_NOMENCLATURE
       where GCO_GOOD_ID = ltplNomenclature.GCO_GOOD_ID
         and C_TYPE_NOM = ltplNomenclature.C_TYPE_NOM;

      if     (lId <> 0)
         and not(ltplNomenclature.C_TYPE_NOM in('2', '5', '8') ) then
        SetMessage('Only one nomenclature is allowed for this type' || ' - Type = ' || ltplNomenclature.C_TYPE_NOM);
      else
        select nvl(max(GCO_GOOD_ID), 0)
          into lId
          from PPS_CONFIGURABLE_PRODUCT
         where GCO_GOOD_ID = ltplNomenclature.GCO_GOOD_ID;

        if     lId = 0
           and ltplNomenclature.C_TYPE_NOM = '1' then
          SetMessage('Sale nomenclature not allowed (no configurable product)');
        elsif     lId <> 0
              and ltplNomenclature.C_TYPE_NOM = '6' then
          SetMessage('Replacement nomenclature not allowed (configurable product)');
        end if;
      end if;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotNomenclature, 'NOM_DEFAULT')
       and (FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomenclature, 'NOM_DEFAULT') = 1) then
      select nvl(max(PPS_NOMENCLATURE_ID), 0)
        into lId
        from PPS_NOMENCLATURE NOM
       where GCO_GOOD_ID = ltplNomenclature.GCO_GOOD_ID
         and PPS_NOMENCLATURE_ID <> ltplNomenclature.PPS_NOMENCLATURE_ID
         and NOM_DEFAULT = 1
         and C_TYPE_NOM = ltplNomenclature.C_TYPE_NOM;

      if lId <> 0 then
        SetMessage('Only one default nomenclature is allowed');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomenclature, 'C_REMPLACEMENT_NOM') then
      if ltplNomenclature.C_REMPLACEMENT_NOM = '1' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomenclature, 'NOM_BEG_VALID', sysdate);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotNomenclature, 'NOM_BEG_VALID');
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomenclatureData'
                                         );
    end if;
  end CheckNomenclatureData;

  /**
  * procedure CheckNomBondData
  * Description
  *    Contrôle avant mise à jour du bien
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotNomBond : Dossier SAV
  */
  procedure CheckNomBondData(iotNomBond in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    lMessage        varchar2(200);
    lNomGoodID      PPS_NOMENCLATURE.GCO_GOOD_ID%type;
    lNOM_REF_QTY    PPS_NOMENCLATURE.NOM_REF_QTY%type;
    lC_TYPE_NOM     PPS_NOMENCLATURE.C_TYPE_NOM%type;
    lDischarge      PPS_NOM_BOND.C_DISCHARGE_COM%type;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end SetMessage;

    procedure InitGoodData
    is
      lFilter  varchar2(10);
      lnGoodID PPS_NOM_BOND.GCO_GOOD_ID%type;
    begin
      lnGoodID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomBond, 'GCO_GOOD_ID');

      if lC_TYPE_NOM = '1' then
        lFilter  := ',1,2,';
      elsif lC_TYPE_NOM = '2' then
        lFilter  := ',2,';
      elsif lC_TYPE_NOM = '4' then
        lFilter  := ',2,4,';
      elsif lC_TYPE_NOM = '5' then
        lFilter  := ',2,5,';
      elsif lC_TYPE_NOM = '6' then
        lFilter  := ',2,';
      elsif lC_TYPE_NOM = '7' then
        lFilter  := ',7,';
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'PPS_PPS_NOMENCLATURE_ID') then
        for ltplNom in (select   PPS_NOMENCLATURE_ID
                            from PPS_NOMENCLATURE
                           where GCO_GOOD_ID = lnGoodID
                             and instr(lFilter, C_TYPE_NOM) > 0
                             and NOM_DEFAULT = 1
                        order by case
                                   when C_TYPE_NOM = lC_TYPE_NOM then '0'
                                   else C_TYPE_NOM
                                 end asc) loop
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'PPS_PPS_NOMENCLATURE_ID', ltplNom.PPS_NOMENCLATURE_ID);
          exit;   -- If exists, we need only the first record found.
        end loop;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotNomBond, 'STM_STOCK_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotNomBond, 'STM_LOCATION_ID');

      for tplData in (select A.PDT_STOCK_MANAGEMENT
                           , A.STM_STOCK_ID
                           , A.STM_LOCATION_ID
                           , D.GOO_NUMBER_OF_DECIMAL
                           , B.DES_SHORT_DESCRIPTION
                           , B.DES_LONG_DESCRIPTION
                           , C.C_REMPLACEMENT_NOM
                           , D.GOO_STD_PERCENT_WASTE
                           , D.GOO_STD_FIXED_QUANTITY_WASTE
                           , D.GOO_STD_QTY_REFERENCE_LOSS
                           , D.GCO_GOOD_ID
                        from GCO_PRODUCT A
                           , GCO_DESCRIPTION B
                           , PPS_NOMENCLATURE C
                           , GCO_GOOD D
                       where A.GCO_GOOD_ID = lnGoodID
                         and D.GCO_GOOD_ID = A.GCO_GOOD_ID
                         and B.GCO_GOOD_ID(+) = A.GCO_GOOD_ID
                         and B.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.getCompLangId
                         and B.C_DESCRIPTION_TYPE(+) = '01'
                         and C.GCO_GOOD_ID(+) = A.GCO_GOOD_ID
                         and C.NOM_DEFAULT(+) = 1
                         and C.C_TYPE_NOM(+) = '6') loop
        if PCS.PC_CONFIG.GetConfig('PPS_DefltSearch_STOCK') = '1' then
          if not(    tplData.STM_STOCK_ID is null
                 and tplData.STM_LOCATION_ID is null) then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'STM_STOCK_ID', tplData.STM_STOCK_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'STM_LOCATION_ID', tplData.STM_LOCATION_ID);
          else
            for tplStock in (select   A.STM_STOCK_ID
                                    , B.STM_LOCATION_ID
                                 from STM_STOCK A
                                    , STM_LOCATION B
                                where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('GCO_DefltSTOCK')
                                  and B.STM_STOCK_ID = A.STM_STOCK_ID
                             order by LOC_CLASSIFICATION) loop
              FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'STM_STOCK_ID', tplStock.STM_STOCK_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'STM_LOCATION_ID', tplStock.STM_LOCATION_ID);
              exit;
            end loop;
          end if;
        end if;

        if (PCS.PC_CONFIG.GetConfig('PPS_Ini_Short_Descr') = '1') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_TEXT', tplData.DES_SHORT_DESCRIPTION);
        end if;

        if (PCS.PC_CONFIG.GetConfig('PPS_Ini_Long_Descr') = '1') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_RES_TEXT', tplData.DES_LONG_DESCRIPTION);
        end if;

        if tplData.C_REMPLACEMENT_NOM is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_REMPLACEMENT_NOM', tplData.C_REMPLACEMENT_NOM);
        end if;

        if tplData.GOO_STD_PERCENT_WASTE is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_PERCENT_WASTE', tplData.GOO_STD_PERCENT_WASTE);
        end if;

        if tplData.GOO_STD_FIXED_QUANTITY_WASTE is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_FIXED_QUANTITY_WASTE', tplData.GOO_STD_FIXED_QUANTITY_WASTE);
        end if;

        if tplData.GOO_STD_QTY_REFERENCE_LOSS is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_QTY_REFERENCE_LOSS', tplData.GOO_STD_QTY_REFERENCE_LOSS);
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomBond, 'COM_UTIL_COEFF') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond
                                        , 'COM_UTIL_COEFF'
                                        , round(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomBond, 'COM_UTIL_COEFF'), tplData.GOO_NUMBER_OF_DECIMAL)
                                         );
        end if;
      end loop;
    end InitGoodData;
  begin
    lNomenclatureID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomBond, 'PPS_NOMENCLATURE_ID');

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'PPS_NOMENCLATURE_ID') then
      lMessage  := 'PPS_NOMENCLATURE_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomBondData'
                                         );
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'PPS_NOM_BOND_ID') then
      lMessage  := 'PPS_NOM_BOND_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomBondData'
                                         );
    end if;

    -- Informations de la nomenclature du composant courant
    select GCO_GOOD_ID
         , nvl(NOM_REF_QTY, 1)
         , C_TYPE_NOM
      into lNomGoodID
         , lNOM_REF_QTY
         , lC_TYPE_NOM
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = lNomenclatureID;

    if lNomGoodID = FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomBond, 'GCO_GOOD_ID') then
      lMessage  := 'PPS_NOMENCLATURE.GCO_GOOD_ID = PPS_NOM_BOND.GCO_GOOD_ID not allowed';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomBondData'
                                         );
    end if;

    -- initialisation des valeurs par défaut
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_REF_QTY') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_REF_QTY', lNOM_REF_QTY);
    end if;

    -- Séquence
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_SEQ') then
      declare
        lCOM_SEQ PPS_NOM_BOND.COM_SEQ%type;
      begin
        -- Nouvelle séquence
        select (nvl(max(COM_SEQ), 0) + PCS.PC_CONFIG.GetConfig('PPS_Com_Numbering') )
          into lCOM_SEQ
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = lNomenclatureID;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_SEQ', lCOM_SEQ);
      end;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'C_TYPE_COM') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_TYPE_COM', '1');
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'C_REMPLACEMENT_NOM') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_REMPLACEMENT_NOM', '2');
    end if;

    -- lire la config pour la décharge, n'accepter que les valeurs de 1 à 5, sinon mettre 1
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'C_DISCHARGE_COM') then
      lDischarge  := PCS.PC_CONFIG.GetConfig('PPS_DISCHARGE_COM');

      if lDischarge in('1', '2', '3', '4', '5') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_DISCHARGE_COM', lDischarge);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_DISCHARGE_COM', '1');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'C_KIND_COM') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'C_KIND_COM', '1');
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_RES_NUM') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_RES_NUM', 0);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_UTIL_COEFF') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_UTIL_COEFF', 1);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_PDIR_COEFF') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_PDIR_COEFF', 1);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_REC_PCENT') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_REC_PCENT', 0);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_INTERVAL') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_INTERVAL', 0);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_REMPLACEMENT') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_REMPLACEMENT', 0);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_VAL') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_VAL', 1);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotNomBond, 'COM_SUBSTITUT') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_SUBSTITUT', 0);
    end if;

    -- traitement des mise à jour
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotNomBond, 'GCO_GOOD_ID') then
      InitGoodData;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotNomBond, 'COM_REMPLACEMENT')
       and (FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotNomBond, 'COM_REMPLACEMENT') = 1)
       and (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotNomBond, 'C_KIND_COM') = '3') then
      SetMessage('Activation of COM_REPLACEMENT not allowed');
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotNomBond, 'C_REMPLACEMENT_NOM')
       and (lC_TYPE_NOM = '6')
       and (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotNomBond, 'C_REMPLACEMENT_NOM') = '2') then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotNomBond, 'COM_BEG_VALID');
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotNomBond, 'C_KIND_COM')
       and (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotNomBond, 'C_KIND_COM') = '3') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotNomBond, 'COM_REMPLACEMENT', 0);
    end if;

    -- traitement des mises à jour
    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckNomBondData'
                                         );
    end if;
  end CheckNomBondData;
end PPS_PRC_NOMENCLATURE;
