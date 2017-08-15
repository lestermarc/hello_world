--------------------------------------------------------
--  DDL for Package Body REP_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_UTILS" 
/**
 * Pacakge utilitaires pour la réplication.
 *
 * @version 1.0
 * @date 03/2003
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  -- package private global constants
  gcv_DEF_DATE_FORMAT CONSTANT VARCHAR2(8) := 'YYYYMMDD';
  gcv_DEF_TIME_FORMAT CONSTANT VARCHAR2(8) := 'HH24MISS';--.FF3';
  gcv_DEF_DATE_TIME_FORMAT CONSTANT VARCHAR2(17) := gcv_DEF_DATE_FORMAT||' '||gcv_DEF_TIME_FORMAT;

  gv_CreationContext VARCHAR2(32767);


/**
 * Package private function to retrieve the default or replacement value
 */
function pFetchValue(
  vId IN gco_transfer_list.gco_transfer_list_id%TYPE,
  vVal IN VARCHAR2,
  vType IN VARCHAR2)
  return VARCHAR2
is
  cursor csReplacement(
    vId IN gco_transfer_list.gco_transfer_list_id%TYPE)
  is
    select XSU_ORIGINAL, XSU_REPLACEMENT, XSU_IS_DEFAULT_VALUE
    from GCO_TRANSFER_SUBST
    where GCO_TRANSFER_LIST_ID = vId;
  bHaveDefault BOOLEAN := FALSE;
  DefVal gco_transfer_subst.xsu_replacement%TYPE;
begin
  for tplReplacement in csReplacement(vId) loop
    -- Recherche de la valeur par défaut
    if (tplReplacement.xsu_is_default_value = 1) then
      bHaveDefault := TRUE;
      DefVal := tplReplacement.xsu_replacement;
    end if;

    case
      -- Validation de la valeur caractères
      when (vType = 'FTSTRING') then
        if (Upper(tplReplacement.xsu_original) = Upper(vVal)) then
          return tplReplacement.xsu_replacement;
        end if;
      -- Validation de la valeur entière
      when (vType in ('FTSMALLINT','FTINTEGER')) then
        if (to_number(tplReplacement.xsu_original) = to_number(vVal)) then
          return tplReplacement.xsu_replacement;
        end if;
      -- Validation de la valeur
      else
        if (tplReplacement.xsu_original = vVal) then
          return tplReplacement.xsu_replacement;
        end if;
    end case;
  end loop;

  -- Si aucune valeur ne correspond, utilisation de la valeur par défaut
  return case when (bHaveDefault)
    then DefVal
    else ''
    end;
end;

/**
 * Package private function to retrieve the replacement value
 */
function pFetchValue(
  vId IN gco_transfer_list.gco_transfer_list_id%TYPE)
  return VARCHAR2
is
  lv_result gco_transfer_subst.xsu_replacement%TYPE;
begin
  select XSU_REPLACEMENT
  into lv_result
  from GCO_TRANSFER_SUBST
  where GCO_TRANSFER_LIST_ID = vId;
  return lv_result;

  exception
    when NO_DATA_FOUND then
      return '';
end;

procedure get_Default_Value(
  vCategId IN gco_good_category.gco_good_category_id%TYPE,
  vTabName IN VARCHAR2,
  vFieldName IN VARCHAR2,
  vTransType IN VARCHAR2,
  vOldValue IN VARCHAR2,
  vNewValue OUT NOCOPY VARCHAR2,
  vDefaultRepl OUT NOCOPY VARCHAR2)
is
  cursor csValues(
    CategId IN gco_good_category.gco_good_category_id%TYPE,
    TabName IN VARCHAR2, FieldName IN VARCHAR2)
  is
    select C_TRANSFER_TYPE, C_DEFAULT_REPL, XLI_SUBSTITUTION, XLI_FIELD_TYPE,
           GCO_TRANSFER_LIST_ID
    from GCO_TRANSFER_LIST
    where
      (GCO_GOOD_CATEGORY_ID = CategId or GCO_GOOD_CATEGORY_ID is null) and
      XLI_TABLE_NAME = TabName and XLI_FIELD_NAME = FieldName
    order by Nvl2(GCO_GOOD_CATEGORY_ID, 1, 0) desc, C_TRANSFER_TYPE;
begin
  vNewValue := '';
  vDefaultRepl := '';
  for tplValues in csValues(vCategId, vTabName, vFieldName) loop
    if (tplValues.c_transfer_type = vTransType) or (tplValues.c_transfer_type = '3') then
      if (tplValues.xli_substitution = 1) then
        vNewValue := pFetchValue(tplValues.gco_transfer_list_id, vOldValue, tplValues.xli_field_type);
      else
        vNewValue := pFetchValue(tplValues.gco_transfer_list_id);
      end if;
      vDefaultRepl := tplValues.c_default_repl;
      return;
    end if;
  end loop;
end;

/**
 * @deprecated use rep_lib_replicate.GetGoodOfPTCTariff instead
 */
function GetGoodOfPTCTariff(
  TariffId IN ptc_tariff.ptc_tariff_id%TYPE)
  return gco_good.gco_good_id%TYPE
is
  ln_result gco_good.gco_good_id%TYPE;
begin
  select GCO_GOOD_ID
  into ln_result
  from PTC_TARIFF
  where PTC_TARIFF_ID = TariffId;
  return ln_result;

  exception
    when NO_DATA_FOUND then
      return 0.0;
end;


function GetEntityValue(
  EntityId IN NUMBER,
  EntityCode IN VARCHAR2)
  return VARCHAR2
is
  lv_select VARCHAR2(32767);
  lv_from VARCHAR2(32767);
  lv_where VARCHAR2(32767);
  lv_result VARCHAR2(32767);
begin
  if (EntityCode is null or EntityId <= 0) then
    return pcs.pc_functions.TranslateWord('<Inconnu>');
  end if;

  case EntityCode
    when 'ACS_ACCOUNT' then
      lv_select := 'ACC_NUMBER';
    when 'ACS_EVALUATION_METHOD' then
      lv_select := 'EVA_DESCR';
    when 'ACS_INTEREST_CATEG' then
      lv_select := 'ICA_DESCRIPTION';
    when 'ACS_INT_CALC_METHOD' then
      lv_select := 'ICM_DESCRIPTION';

    when 'DOC_RECORD' then
      lv_select := 'RCO_TITLE';
    when 'DOC_RECORD_CATEGORY' then
      lv_select := 'Nvl(RCY_KEY, RCY_DESCR)';
    when 'DOC_RECORD_CAT_LINK_TYPE' then
      lv_select := 'RLT_DESCR';
    when 'DOC_GAUGE_SIGNATORY' then
      lv_select := 'GAG_FUNCTION||''/''||GAG_NAME';

    when 'FAL_FACTORY_FLOOR' then
      lv_select := 'FAC_REFERENCE';
    when 'FAL_SUPPLY_REQUEST' then
      --lv_select := '';
      return '';
    when 'FAL_SCHEDULE_PLAN' then
      lv_select := 'SCH_REF';
    when 'FAL_TASK' then
      lv_select := 'TAS_REF';

    when 'GCO_ALLOY' then
      lv_select := 'GAL_ALLOY_REF';
    when 'GCO_ATTRIBUTE_FIELDS' then
      lv_select := 'GCO_CATEGORY_CODE';
      lv_from := 'GCO_GOOD_CATEGORY';
      lv_where := 'GCO_GOOD_CATEGORY_ID = :ID';
    when 'GCO_GOOD' then
      lv_select := 'GOO_MAJOR_REFERENCE';
    when 'GCO_GOOD_CATEGORY' then
      lv_select := 'GCO_CATEGORY_CODE';
    when 'GCO_PRODUCT' then
      lv_select := 'GOO_MAJOR_REFERENCE';
      lv_from := 'GCO_GOOD';
      lv_where := 'GCO_GOOD_ID = :ID';
    when 'GCO_PRODUCT_GROUP' then
      lv_select := 'PRG_NAME';

    when 'PTC_TARIFF_CATEGORY' then
      lv_select := 'TCA_DESCRIPTION';

    when 'PPS_NOMENCLATURE' then
      lv_select := 'GOO_MAJOR_REFERENCE';
      lv_from := 'GCO_GOOD';
      lv_where := 'GCO_GOOD_ID = (select GCO_GOOD_ID from PPS_NOMENCLATURE'||
                                  ' where PPS_NOMENCLATURE_ID = :ID)';

    when 'PAC_ADDRESS' then
      lv_select := 'Coalesce(PER_KEY1,PER_KEY2,PER_NAME)';
      lv_from := 'PAC_PERSON';
      lv_where := 'PAC_PERSON_ID = :ID';
    when 'PAC_PERSON' then
      lv_select := 'Coalesce(PER_KEY1,PER_KEY2,PER_NAME)';
    when 'PAC_PERSON_ASSOCIATION' then
      lv_select := 'Coalesce(PER_KEY1,PER_KEY2,PER_NAME)';
      lv_from := 'PAC_PERSON';
      lv_where := 'PAC_PERSON_ID = :ID';

    when 'HRM_CONTROL_LIST' then
      lv_select := 'COL_NAME';
    when 'HRM_ELEMENTS_ROOT' then
      lv_select := 'ELR_ROOT_NAME';
    when 'HRM_PERSON' then
      lv_select := 'PER_LAST_NAME||'' ''||PER_FIRST_NAME';

    when 'STM_DISTRIBUTION_UNIT' then
      lv_select := 'DIU_NAME';
    when 'STM_MOVEMENT_KIND' then
      lv_select := 'MOK_ABBREVIATION';
    when 'STM_STOCK' then
      lv_select := 'STO_DESCRIPTION';

   else
      return pcs.pc_functions.TranslateWord('<Inconnu>');
  end case;

  EXECUTE IMMEDIATE
    'select '|| lv_select ||
    ' from '|| Nvl(lv_from, EntityCode) ||
    ' where '|| Nvl(lv_where, EntityCode||'_ID = :ID')
    INTO lv_result
    USING EntityId;

  if (lv_result is null) then
    return pcs.pc_functions.TranslateWord('<Vide>');
  end if;
  return lv_result;

  exception
    when NO_DATA_FOUND then
      return pcs.pc_functions.TranslateWord('<Inconnu>');
    when OTHERS then
      return pcs.pc_functions.TranslateWord('ERREUR');
end;


function GetReplicatorDateFormat
  return VARCHAR2
is
begin
  return gcv_DEF_DATE_TIME_FORMAT;
end;

function DateToReplicatorDate(
  DateValue IN DATE)
  return VARCHAR2
is
begin
  if (DateValue is not null) then
    if ((Trunc(DateValue) - DateValue) = 0) then
      return to_char(DateValue, gcv_DEF_DATE_FORMAT);
    else
      return to_char(DateValue, gcv_DEF_DATE_TIME_FORMAT);
    end if;
  end if;
  return null;
end;

function ReplicatorDateToDate(
  DateValue IN VARCHAR2)
  return DATE
is
begin
  if (DateValue is not null) then
    return to_date(DateValue, gcv_DEF_DATE_TIME_FORMAT);
  end if;
  return null;
end;

function FormatReplicatorDateToDate(
  DateValue IN DATE)
  return VARCHAR2
is
begin
  return rep_utils.FormatReplicatorDateToDate(rep_utils.DateToReplicatorDate(DateValue));
end;
function FormatReplicatorDateToDate(
  DateValue IN VARCHAR2)
  return VARCHAR2
is
  npos BINARY_INTEGER;
begin
  if (DateValue is not null) then
    -- Traitement du cas particulier: '20070129 000000'
    npos := Instr(DateValue, ' ');
    if (npos > 0) then
      if (to_number(Substr(DateValue, npos+1)) != 0) then
        return 'TO_DATE('''||DateValue||''','''||gcv_DEF_DATE_TIME_FORMAT||''')';
      else
        return 'TO_DATE('''||Substr(DateValue, 1, npos)||''','''||gcv_DEF_DATE_FORMAT||''')';
      end if;
    end if;
    return 'TO_DATE('''||DateValue||''','''||gcv_DEF_DATE_FORMAT||''')';
  end if;
  return null;
end;

function IsTypeReplicable(
  iv_data_type IN VARCHAR2)
  return INTEGER
is
begin
  return case
    when iv_data_type in ('VARCHAR2','NVARCHAR2','RAW','CHAR','NCHAR',
                          'NUMBER','BINARY_FLOAT','BINARY_DOUBLE',
                          'DATE','TIMESTAMP')
      then 1
      else 0
    end;
end;

/**
 * Cette fonction sert à initialiser la variable locale gv_CreationContext
 * pour des raisons de performances.
 * L'appel de la méthode ne doit pas être fait à l'initialisation du package,
 * car la fonction COM_CurrentSchema peut ne pas aboutir à ce moment là.
 */
function GetCreationContext
  return VARCHAR2
is
begin
  if (gv_CreationContext is null) then
    gv_CreationContext :=
        ' by user '|| User ||
        ' from '|| sys_context('USERENV', 'HOST') ||
        ' on database '|| sys_context('USERENV', 'DB_UNIQUE_NAME') ||
        ' (instance '|| sys_context('USERENV', 'INSTANCE_NAME')||')' ||
        ' with module '|| sys_context('USERENV', 'MODULE') ||
        ' on schema '|| COM_CurrentSchema;
  end if;
  return 'generated at '|| to_char(SysTimestamp,'YYYY/MM/DD HH24:MI:SS.FF4')|| gv_CreationContext;
end;

END REP_UTILS;
