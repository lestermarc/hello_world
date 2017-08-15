--------------------------------------------------------
--  DDL for Package Body REP_LIB_REPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LIB_REPLICATE" 
/**
 * Package utilitaire autour de la réplication.
 *
 * @version 1.0
 * @date 08.2012
 * @author spfister
 */
is
  function can_trigger_replicate(iv_config_name in varchar2)
    return integer
  is
  begin
    if (    pcs.PC_I_LIB_SESSION.isReplicationEnabled = 1
        and pcs.pc_config.GetConfigUpper(iv_config_name, pcs.PC_I_LIB_SESSION.GetCompanyId) = 'TRUE') then
      return 1;
    end if;

    return 0;
  end;

  function IsBOMReplicable(in_nomenclature_id in pps_nomenclature.pps_nomenclature_id%type, in_check_deleted in integer default 1)
    return integer
  is
    ln_active integer := 0;
  begin
    if (in_check_deleted = 1) then
      -- S'assurer que la nomencluture existe encore
      -- dans le cas du delete de la nomenclature, les éléments correspondants
      -- de la table PPS_NOM_BOND sont effacés
      -- lorsque cette fonction est appelée par trigger, on n'a pas le droit
      -- d'accéder à la table.
      select count(*)
        into ln_active
        from dual
       where exists(select 1
                      from PPS_NOMENCLATURE
                     where PPS_NOMENCLATURE_ID = in_nomenclature_id);
    end if;

    if (   ln_active > 0
        or in_check_deleted = 0) then
      select count(*)
        into ln_active
        from dual
       where exists(
               select 1
                 from GCO_GOOD
                where GCO_GOOD_ID = (select GCO_GOOD_ID
                                       from PPS_NOMENCLATURE
                                      where PPS_NOMENCLATURE_ID = in_nomenclature_id)
                  and C_GOOD_STATUS in(GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended) );

      return ln_active;
    end if;

    return 0;
  exception
    when others then
      return 0;
  end;

  function IsCategoryReplicable(in_category_id in gco_good_category.gco_good_category_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from dual
     where exists(select 1
                    from GCO_GOOD_CATEGORY
                   where GCO_GOOD_CATEGORY_ID = in_category_id
                     and C_REPLICATION_TYPE = '1');

    return ln_result;
  end;

  function IsGoodReplicable(in_good_id in gco_good.gco_good_id%type)
    return integer
  is
    ln_result integer;
  begin
    -- Vérifier que le bien n'est pas en train d'être effacé
    --   Ce test est fait pour éviter une exception table is muttating suite à l'effacement d'un bien
    if GCO_LIB_FUNCTIONS.IsGoodDeleting(iGoodID => in_good_id) = 1 then
      ln_result  := 0;
    else
      select count(*)
        into ln_result
        from dual
       where exists(
               select 1
                 from GCO_GOOD_CATEGORY
                where GCO_GOOD_CATEGORY_ID =
                         (select GCO_GOOD_CATEGORY_ID
                            from GCO_GOOD
                           where GCO_GOOD_ID = in_good_id
                             and C_GOOD_STATUS in(GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended) )
                  and C_REPLICATION_TYPE = '1');
    end if;

    return ln_result;
  end;

  function GetGoodOfPTCTariff(in_tariff_id in ptc_tariff.ptc_tariff_id%type)
    return gco_good.gco_good_id%type
  is
    ln_result gco_good.gco_good_id%type;
  begin
    select GCO_GOOD_ID
      into ln_result
      from PTC_TARIFF
     where PTC_TARIFF_ID = in_tariff_id;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;
end REP_LIB_REPLICATE;
