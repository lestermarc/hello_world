--------------------------------------------------------
--  DDL for Package Body GCO_PRC_VERSION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRC_VERSION" 
is
  /**
  * Description
  *    Mise à jour automatique du produit vers la prochaine version. Retourne la valeur de la nouvelle version
  *    ou null si la mise à jour n'a pas pu être faite.
  */
  procedure autoUpdateToNextVersion(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, oVersion out varchar2)
  as
    lCharactId  GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lmaxValue   GCO_CHARACTERIZATION.CHA_MAXIMUM_VALUE%type;
    lNewIncrVal number;
    lNewCharVal GCO_PRODUCT.PDT_VERSION%type;
    lAutoInc    GCO_CHARACTERIZATION.CHA_AUTOMATIC_INCREMENTATION%type;
    ltCRUD_DEF  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    oVersion  := '';

    -- Récupération de la caractérisation de type version correspondant au bien.
    -- Il n'y en a qu'une dans le cadre du versionning.
    select GCO_CHARACTERIZATION_ID
         , CHA_MAXIMUM_VALUE
         , CHA_AUTOMATIC_INCREMENTATION
      into lCharactId
         , lMaxValue
         , lAutoInc
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = iGoodID
       and C_CHARACT_TYPE = GCO_LIB_CONSTANT.gcCharacTypeVersion;

    if lAutoInc = 0 then
      -- pas d'incrémentation automatique
      return;
    end if;

    -- Récupération de la prochaine valeur de caractérisation
    GCO_LIB_CHARACTERIZATION.GetNextCharValue(iCharacterizationID   => lCharactId, iUpdateLastIncrem => 0, oIncremValue => lNewIncrVal
                                            , oCharValue            => lNewCharVal);

    if     nvl(lMaxValue, 0) <> 0
       and lNewIncrVal > nvl(lMaxValue, 0) then
      -- La valeur calculée est > à la valeur max autorisée.
      return;
    end if;

    -- Mise à jour de la version du produit.
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_GCO_ENTITY.gcGcoProduct
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => false
                       , in_main_id            => iGoodID
                       , iv_row_id             => null
                       , iv_primary_col        => 'GCO_GOOD_ID'
                        );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PDT_VERSION', lNewCharVal);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour du dernier incrément utilisé.
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_GCO_ENTITY.gcGcoCharacterization
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => false
                       , in_main_id            => lCharactId
                        );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CHA_LAST_USED_INCREMENT', lNeWIncrVal);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    oVersion  := lNewCharVal;
  exception
    when no_data_found then
      oVersion  := '';
    when too_many_rows then
      oVersion  := '';
    when others then
      raise;
  end autoUpdateToNextVersion;
end GCO_PRC_VERSION;
