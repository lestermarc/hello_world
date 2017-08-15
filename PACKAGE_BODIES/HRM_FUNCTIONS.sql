--------------------------------------------------------
--  DDL for Package Body HRM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_FUNCTIONS" 
/**
 * Package regroupant des fonctions qui sont utilisable dans les salaires,
 * dans des listes et dans l'interface.
 *
 * @version 1.0
 * @date 12.1999
 * @author jsomers
 * @author spfister
 * @author ireber
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
as
  -- Constante
  DEF_FORMAT_YEARMONTH constant varchar2(4) := '0000';

  -- Cursor for accessing company (PCS.PC_COMP) fields
  cursor gcur_company(in_company_id in pcs.pc_comp.pc_comp_id%type)
  is
    select PC_COMP_ID
         , COM_NAME
         , COM_DESCR
         , COM_SOCIALNAME
         , COM_ADR
         , COM_ZIP
         , COM_CITY
         , COM_PHONE
         , COM_FAX
      from PCS.PC_COMP
     where PC_COMP_ID = in_company_id;

--
-- Intenal implementation
--
  function getCompanyRec
    return gcur_company%rowtype
  is
    -- Record for acessing Company's fields
    lrec_company gcur_company%rowtype;
  begin
    if (   lrec_company.pc_comp_id is null
        or lrec_company.pc_comp_id != pcs.PC_I_LIB_SESSION.GetCompanyid) then
      open gcur_company(pcs.PC_I_LIB_SESSION.GetCompanyid);

      fetch gcur_company
       into lrec_company;

      close gcur_company;
    end if;

    return lrec_company;
  end;

/**
 * Fonction interne de formatage pour les années et les mois au format 'YYMM';
 * @param p1  Nombre de mois séparants deux dates.
 * @return  Le nombre d'année et de mois accolés
 */
  function p_FormatYearMonth(p1 in number)
    return varchar2 deterministic
  is
    ln_year  binary_integer;
    ln_month binary_integer;
  begin
    ln_year   := trunc(p1 / 12);

    if (ln_year > 99) then
      return DEF_FORMAT_YEARMONTH;
    end if;

    ln_month  := p1 mod 12;

    if (ln_month > 12) then
      return DEF_FORMAT_YEARMONTH;
    end if;

    return to_char(ln_year, 'FM00') || to_char(ln_month, 'FM00');
  end;

--
-- Published implemenation
--
  function HoursToCents(hours in varchar2)
    return integer
  is
    ln_minutes binary_integer;
    ln_hours   binary_integer;
    ln_divider binary_integer;
  begin
    if (hours is null) then
      return 0;
    end if;

    -- loooking for dividers
    ln_divider  := instr(hours, '.');

    if (ln_divider = 0) then
      ln_divider  := instr(hours, ':');
    end if;

    -- if we don't find dividers we suppose that the 2 last digits are minutes
    -- and that previous digits are hours
    if (ln_divider = 0) then
      ln_minutes  := substr(hours, length(hours) - 1, 2);

      if (ln_minutes >= 60) then
        return 0;
      end if;

      ln_hours    := substr(hours, 1, length(hours) - 2);
    else
      -- if we find dividers we suppose we take digits after divider as minutes
      -- and digits before as hours
      ln_minutes  := substr(hours, ln_divider + 1, 2);

      if (ln_minutes >= 60) then
        return 0;
      end if;

      ln_hours    := substr(hours, 1, ln_divider - 1);
    end if;

    return trunc( (ln_minutes / 0.6) + ln_hours * 100);
  exception
    when others then
      return 0;
  end;

  function HoursMinToDays(hours in varchar2, hoursADay in varchar2)
    return number
  is
    cents     binary_integer;
    centsADay binary_integer;
  begin
    centsADay  := hrm_functions.HoursToCents(hoursADay);
    cents      := hrm_functions.HoursToCents(hours);
    return trunc(cents / centsADay, 3);
  end;

  function EmplAgeinYear(vEmp_id in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result binary_integer;
  begin
    select hrm_functions.AgeInYear(PER_BIRTH_DATE)
      into ln_result
      from HRM_PERSON
     where HRM_PERSON_ID = vEmp_id;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function AgeInYear(vBirthdate in date)
    return integer
  is
  begin
    return hrm_functions.AgeInGivenYear(hrm_date.ActivePeriod, vBirthdate);
  end;

  function AgeInPeriod(vBirthdate in date)
    return integer
  is
  begin
    return hrm_functions.AgeInGivenPeriod(hrm_date.ActivePeriod, vBirthdate);
  end;

  function EmplAgeinPeriod(vEmp_id in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select hrm_functions.AgeInPeriod(PER_BIRTH_DATE)
      into ln_result
      from HRM_PERSON
     where HRM_PERSON_ID = vEmp_Id;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function EmplFirstEntry(vEmp_id in hrm_person.hrm_person_id%type)
    return hrm_in_out.ino_in%type
  is
    result hrm_in_out.ino_in%type;
  begin
    select min(INO_IN)
      into result
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = vEmp_id
       and C_IN_OUT_CATEGORY = '3';

    return result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplYearsOfService(vEmp_id in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_between number;
  begin
    select trunc( (sum(hrm_date.days_between(INO_IN, least(nvl(ino_out, hrm_date.ActivePeriodEndDate), hrm_date.ActivePeriodEndDate) ) ) - 1) / 30)
      into ln_between
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = vEmp_id
       and C_IN_OUT_CATEGORY = '3'
       and INO_IN <= hrm_date.ActivePeriodEndDate;

    return trunc(ln_between / 12);
  exception
    when no_data_found then
      return 0;
  end;

  function EmplYearMonthsOfService(vEmp_id in hrm_person.hrm_person_id%type)
    return varchar2
  is
    ln_between number;
  begin
    select trunc( (sum(hrm_date.days_between(INO_IN, least(nvl(ino_out, hrm_date.ActivePeriodEndDate), hrm_date.ActivePeriodEndDate) ) ) - 1) / 30)
      into ln_between
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = vEmp_id
       and C_IN_OUT_CATEGORY = '3'
       and INO_IN <= hrm_date.ActivePeriodEndDate;

    if (ln_between is not null) then
      return p_FormatYearMonth(ln_between);
    end if;

    return DEF_FORMAT_YEARMONTH;
  exception
    when no_data_found then
      return DEF_FORMAT_YEARMONTH;
  end;

  function EmplYearMonthsOfServiceBDate(vEmp_id in hrm_person.hrm_person_id%type, vDateBetween in varchar2)
    return varchar2
  is
    ln_between   number;
    ld_reference date;
  begin
    ld_reference  := to_date(vDateBetween, 'YYYY-MM-DD');

    select trunc( (sum(hrm_date.days_between(INO_IN, least(nvl(ino_out, ld_reference), ld_reference) ) ) - 1) / 30)
      into ln_between
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = vEmp_id
       and C_IN_OUT_CATEGORY = '3'
       and ld_reference >= INO_IN
       and (   ld_reference <= INO_OUT
            or INO_OUT is null);

    if (ln_between is not null) then
      return p_FormatYearMonth(ln_between);
    end if;

    return DEF_FORMAT_YEARMONTH;
  exception
    when no_data_found then
      return DEF_FORMAT_YEARMONTH;
  end;

  function EmplYearMonthsOfServiceWDate(vEmp_id in hrm_person.hrm_person_id%type, vDateTo in varchar2)
    return varchar2
  is
    ln_between   number;
    ld_reference date;
  begin
    ld_reference  := to_date(vDateTo, 'YYYY-MM-DD');

    select trunc( (sum(hrm_date.days_between(INO_IN, least(nvl(ino_out, ld_reference), ld_reference) ) ) - 1) / 30)
      into ln_between
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = vEmp_id
       and C_IN_OUT_CATEGORY = '3'
       and ld_reference >= INO_IN;

    if (ln_between is not null) then
      return p_FormatYearMonth(ln_between);
    end if;

    return DEF_FORMAT_YEARMONTH;
  exception
    when no_data_found then
      return DEF_FORMAT_YEARMONTH;
  end;

  function EmplYearMonthsInGroup(vGroupEntry in date)
    return varchar2
  is
    ln_between number;
  begin
    ln_between  := months_between(hrm_date.ActivePeriodEndDate, last_day(vGroupEntry) );

    if (ln_between is not null) then
      return p_FormatYearMonth(ln_between);
    end if;

    return DEF_FORMAT_YEARMONTH;
  exception
    when no_data_found then
      return DEF_FORMAT_YEARMONTH;
  end;

  function EmplYearMonthsInGroupWDate(vEmp_id in hrm_person.hrm_person_id%type, vDateTo in varchar2)
    return varchar2
  is
    ln_between   number;
    ld_reference date;
  begin
    ld_reference  := last_day(to_date(vDateTo, 'YYYY-MM-DD') );

    select months_between(ld_reference, last_day(emp_group_entry) )
      into ln_between
      from hrm_person
     where hrm_person_id = vEmp_id;

    if (ln_between is not null) then
      return p_FormatYearMonth(ln_between);
    end if;

    return DEF_FORMAT_YEARMONTH;
  exception
    when no_data_found then
      return DEF_FORMAT_YEARMONTH;
  end;

  function SumElem(vEmp_id in hrm_person.hrm_person_id%type, vCode in varchar2, vBeginDate in date, vEndDate in date)
    return number
  is
    ln_result number;
  begin
    if vCode is null then
      return 0.0;
    end if;

    select nvl(sum(H.HIS_PAY_SUM_VAL), 0.0)
      into ln_result
      from HRM_HISTORY_DETAIL H
         , V_HRM_ELEMENTS_SHORT V
     where upper(V.CODE) = upper(vCode)
       and H.HRM_ELEMENTS_ID = V.ELEMID
       and H.HRM_EMPLOYEE_ID = vEmp_id
       and H.HIS_PAY_PERIOD between vBeginDate and vEndDate;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function SumElemInPeriod(vEmp_id in hrm_person.hrm_person_id%type, vCode in varchar2)
    return number
  is
  begin
    return hrm_functions.SumElem(vEmp_Id, vCode, hrm_date.activePeriod, hrm_date.activePeriodEndDate);
  end;

  function SumElemInYear(vEmp_id in hrm_person.hrm_person_id%type, vCode in varchar2)
    return number
  is
  begin
    return hrm_functions.SumElem(vEmp_Id, vCode, hrm_date.beginOfYear, hrm_date.endOfYear);
  end;

  function AgeInGivenYear(vDate in date, vBirthdate in date)
    return integer
  is
    ld_year_date  date;
    ld_year_birth date;
  begin
    if vBirthDate is null then
      return 0;
    end if;

    -- we set the year of the given date
    ld_year_date   := trunc(vDate, 'YYYY');
    -- we set the year of the birth date
    ld_year_birth  := trunc(vBirthDate, 'YYYY');

    -- if birth year is smaller than date year we do calculate
    -- otherwise we send back 0
    if (ld_year_birth < ld_year_date) then
      return to_number(to_char(ld_year_date, 'YYYY') ) - to_number(to_char(ld_year_birth, 'YYYY') );
    end if;

    return 0;
  end;

  function AgeInGivenPeriod(vDate in date, vBirthdate in date)
    return integer
  is
    ln_month_date  binary_integer;
    ln_month_birth binary_integer;
  begin
    if vBirthDate is null then
      return 0;
    end if;

    -- we set the month of the given date
    ln_month_date   := to_number(to_char(vDate, 'fmMM') );
    -- we set the month of the birth date
    ln_month_birth  := to_number(to_char(vBirthDate, 'fmMM') );

    -- if active month is less than birth month we take off one year from
    -- the number of years calculated by function AgeInGivenYear
    if (ln_month_date - ln_month_birth) < 0 then
      return hrm_functions.AgeInGivenYear(vDate, vBirthDate) - 1;
    end if;

    return hrm_functions.AgeInGivenYear(vDate, vBirthDate);
  end;

  function VerifyAvsCode(vDate in date, vBirthdate in date, vSex in varchar2)
    return integer
  is
  begin
    if (hrm_functions.AgeInGivenYear(vDate, vBirthDate) >= 18) then
      if (vDate >= hrm_date.pensionDate(vBirthDate, vSex) ) then
        return 2;
      end if;

      return 1;
    end if;

    return 0;
  exception
    when others then
      raise_application_error(-20111, 'Erreur de calcul du code AVS - package PCS hrm_functions.VerifyAvsCode');
      return 0;
  end;

  function AvsCode(vBirthdate in date, vSex in varchar2)
    return integer
  is
  begin
    return hrm_functions.VerifyAvsCode(hrm_date.ActivePeriod, vBirthdate, vSex);
  end;

  function AvsCode(vEmpId in hrm_person.hrm_person_id%type, vBirthdate in date, vSex in varchar2)
    return integer
  is
    ld_last_leave date;
  begin
    if (hrm_date.get_CalcRetro != 1) then
      select max(INO_OUT)
        into ld_last_leave
        from HRM_IN_OUT
       where HRM_EMPLOYEE_ID = vEmpId
         and C_IN_OUT_STATUS = 'ACT'
         and C_IN_OUT_CATEGORY = '3';

      return hrm_functions.VerifyAvsCode(least(hrm_date.ActivePeriod, nvl(ld_last_leave, hrm_date.ActivePeriod) ), vBirthdate, vSex);
    else
      return hrm_functions.VerifyAvsCode(hrm_date.LastYearOut(vEmpId), vBirthdate, vSex);
    end if;
  end;

  function PensionDate(vBirthdate in date, vSex in varchar2)
    return date
  is
  begin
    return hrm_date.pensionDate(vBirthdate, vSex);
  end;

  function TaxRate(vAmount in number, vTax in varchar2, vCategory in varchar2)
    return number
  is
    ln_result number;
  begin
    if (   vTax is null
        or vCategory is null) then
      return 0.0;
    end if;

    -- we look for tax rate using tax category "JUC0M" and an amount
    select TAX_RATE
      into ln_result
      from (select TAX_RATE
                 , to_number(TAX_IND_Y_MIN, '9999999999D999') TAX_IND_Y_MIN
                 , to_number(TAX_IND_Y_MAX, '9999999999D999') TAX_IND_Y_MAX
              from PCS.PC_TAXSOURCE
             where C_HRM_CANTON = vTax
               and TAX_SCALE = vCategory )
     where trunc(vAmount, 3) between TAX_IND_Y_MIN and TAX_IND_Y_MAX;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function ArrayValue(varray in varchar2, vCriteria in varchar2)
    return number
  is
    ln_result number;
  begin
    if (   varray is null
        or vCriteria is null) then
      return 0.0;
    end if;

    select ARD_VALUE
      into ln_result
      from HRM_ARRAY_DETAIL
     where (   HRM_ARRAY_ID = varray
            or (    length(regexp_substr(HRM_ARRAY_ID, '^\d+(\.\d+)?$') ) > 0
                and to_number(regexp_substr(HRM_ARRAY_ID, '^\d+(\.\d+)?$') ) = to_number(regexp_substr(varray, '^\d+(\.\d+)?$') )
               )
           )
       and (   ARD_IND_X = vCriteria
            or (    length(regexp_substr(ARD_IND_X, '^\d+(\.\d+)?$') ) > 0
                and to_number(regexp_substr(ARD_IND_X, '^\d+(\.\d+)?$') ) = to_number(regexp_substr(vCriteria, '^\d+(\.\d+)?$') )
               )
           );

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function ArrayValue2(varray in varchar2, vCode in varchar2, vCriteria in varchar2)
    return number
  is
    ln_result number;
  begin
    if (   varray is null
        or vCode is null) then
      return 0.0;
    end if;

    select ARD_VALUE
      into ln_result
      from (select ARD_VALUE
                 , to_number(ARD_IND_Y_MIN, '9999999999D999') ARD_IND_Y_MIN
                 , to_number(ARD_IND_Y_MAX, '9999999999D999') ARD_IND_Y_MAX
              from HRM_ARRAY_DETAIL
             where (   HRM_ARRAY_ID = varray
                    or (    length(regexp_substr(HRM_ARRAY_ID, '^\d+(\.\d+)?$') ) > 0
                        and to_number(regexp_substr(HRM_ARRAY_ID, '^\d+(\.\d+)?$') ) = to_number(regexp_substr(varray, '^\d+(\.\d+)?$') )
                       )
                   )
               and (   ARD_IND_X = vCode
                    or (    length(regexp_substr(ARD_IND_X, '^\d+(\.\d+)?$') ) > 0
                        and to_number(regexp_substr(ARD_IND_X, '^\d+(\.\d+)?$') ) = to_number(regexp_substr(vCode, '^\d+(\.\d+)?$') )
                       )
                   ) )
     where to_number(vCriteria) between ARD_IND_Y_MIN and ARD_IND_Y_MAX;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function Get_CharCode(id in hrm_char_code.hrm_object_id%type, DicTypeId in dic_hrm_char_code_typ.dic_hrm_char_code_typ_id%type)
    return hrm_char_code.cha_code%type
  is
    lResult hrm_char_code.cha_code%type;
  begin
    select CHA_CODE
      into lResult
      from HRM_CHAR_CODE
     where HRM_OBJECT_ID = id
       and DIC_HRM_CHAR_CODE_TYP_ID = DicTypeId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  function Get_DateCode(id in hrm_char_code.hrm_object_id%type, DicTypeId in dic_hrm_date_code_typ.dic_hrm_date_code_typ_id%type)
    return varchar2
  is
    lResult varchar2(8);   -- Length('yyyymmdd')
  begin
    select to_char(DAT_CODE, 'yyyymmdd')
      into lResult
      from HRM_DATE_CODE
     where HRM_OBJECT_ID = id
       and DIC_HRM_DATE_CODE_TYP_ID = DicTypeId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  function Get_BooleanCode(id in hrm_char_code.hrm_object_id%type, DicTypeId in dic_hrm_bool_code_typ.dic_hrm_bool_code_typ_id%type)
    return hrm_boolean_code.boo_code%type
  is
    lResult hrm_boolean_code.boo_code%type;
  begin
    select BOO_CODE
      into lResult
      from HRM_BOOLEAN_CODE
     where HRM_OBJECT_ID = id
       and DIC_HRM_BOOL_CODE_TYP_ID = DicTypeId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  function Get_NumberCode(id in hrm_char_code.hrm_object_id%type, DicTypeId in dic_hrm_num_code_typ.dic_hrm_num_code_typ_id%type)
    return hrm_number_code.num_code%type
  is
    lResult hrm_number_code.num_code%type;
  begin
    select NUM_CODE
      into lResult
      from HRM_NUMBER_CODE
     where HRM_OBJECT_ID = id
       and DIC_HRM_NUM_CODE_TYP_ID = DicTypeId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  function Get_ObjectId(ObjectTableName in varchar2)
    return hrm_object.hrm_object_id%type
  is
    ln_result hrm_object.hrm_object_id%type;
  begin
    select HRM_OBJECT_ID
      into ln_result
      from HRM_OBJECT
     where upper(OBJ_TABLENAME) = upper(ObjectTableName);

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function Get_ObjectTableName(ObjectId in hrm_object.hrm_object_id%type)
    return hrm_object.obj_tablename%type
  is
    lv_result hrm_object.obj_tablename%type;
  begin
    select OBJ_TABLENAME
      into lv_result
      from HRM_OBJECT
     where HRM_OBJECT_ID = ObjectId;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function Get_EnvBasicObjectName(ObjectId in hrm_object.hrm_object_id%type)
    return pcs.pc_basic_object.obj_name%type
  is
    lv_result pcs.pc_basic_object.obj_name%type;
  begin
    select OBJ_TABLENAME
      into lv_result
      from HRM_OBJECT
     where HRM_OBJECT_ID = ObjectId;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function Get_EnvBasicObjectDescr(ObjectId in hrm_object.hrm_object_id%type, LangId in pcs.pc_lang.pc_lang_id%type)
    return pcs.pc_table_descr.tde_descr%type
  is
    lv_result pcs.pc_table_descr.tde_descr%type;
  begin
    select TD.TDE_DESCR
      into lv_result
      from PCS.PC_TABLE_DESCR TD
         , PCS.PC_TABLE T
         , HRM_OBJECT O
     where O.HRM_OBJECT_ID = ObjectId
       and T.TABNAME = O.OBJ_TABLENAME
       and TD.PC_TABLE_ID = T.PC_TABLE_ID
       and TD.PC_LANG_ID = LangId;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function getDicoDescr(
    aTable in dico_description.dit_table%type
  , aCode  in dico_description.dit_code%type
  , LangId in pcs.pc_lang.pc_lang_id%type default pcs.PC_I_LIB_SESSION.GetUserLangId
  )
    return dico_description.dit_descr%type
  is
    lv_result dico_description.dit_descr%type;
  begin
    select DIT_DESCR
      into lv_result
      from DICO_DESCRIPTION
     where DIT_TABLE = aTable
       and DIT_CODE = aCode
       and PC_LANG_ID = LangId;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function get_CompanyName
    return pcs.pc_comp.com_name%type
  is
  begin
    return getCompanyRec().com_name;
  end;

  function get_CompanyDescr
    return pcs.pc_comp.com_descr%type
  is
  begin
    return getCompanyRec().com_descr;
  end;

  function get_CompanyCorporateName
    return pcs.pc_comp.com_socialname%type
  is
  begin
    return getCompanyRec().com_socialname;
  end;

  function get_CompanyAddress
    return pcs.pc_comp.com_adr%type
  is
  begin
    return getCompanyRec().com_adr;
  end;

  function get_CompanyPostalCode
    return pcs.pc_comp.com_zip%type
  is
  begin
    return getCompanyRec().com_zip;
  end;

  function get_CompanyCity
    return pcs.pc_comp.com_city%type
  is
  begin
    return getCompanyRec().com_city;
  end;

  function get_CompanyPhone
    return pcs.pc_comp.com_phone%type
  is
  begin
    return getCompanyRec().com_phone;
  end;

  function get_CompanyFax
    return pcs.pc_comp.com_fax%type
  is
  begin
    return getCompanyRec().com_fax;
  end;

  function get_InsuranceNr(aInsurance in hrm_insurance.c_hrm_insurance%type)
    return hrm_insurance.ins_member_nr%type
  is
    lv_result hrm_insurance.ins_member_nr%type;
  begin
    select max(INS_MEMBER_NR)
      into lv_result
      from HRM_INSURANCE
     where C_HRM_INSURANCE = aInsurance;

    return lv_result;
  exception
    when others then
      return null;
  end;

/**
 * @deprecated
 */
  function SoundexEx(S in varchar2, MinLen in integer default 4)
    return varchar2
  is
  begin
    return pcs.pc_soundex.SoundexEx(S, MinLen);
  end;

/**
 * @deprecated
 */
  function SoundexEx(S1 in varchar2, S2 in varchar2)
    return integer
  is
  begin
    return pcs.pc_soundex.SoundexEx(S1, S2);
  end;

  function EmplEstabName(vEmp_id in hrm_person.hrm_person_id%type)
    return hrm_establishment.est_name%type
  is
    lv_result hrm_establishment.est_name%type;
  begin
    select (select EST_NAME
              from HRM_ESTABLISHMENT
             where HRM_ESTABLISHMENT_ID = I.HRM_ESTABLISHMENT_ID)
      into lv_result
      from (select   HRM_ESTABLISHMENT_ID
                from HRM_IN_OUT
               where HRM_EMPLOYEE_ID = vEmp_id
                 and HRM_ESTABLISHMENT_ID is not null
                 and C_IN_OUT_CATEGORY = '3'
                 and hrm_date.ActivePeriod between trunc(INO_IN, 'MM') and hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID)
            order by trunc(INO_IN, 'MM') desc) I
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplEstabAddress(vEmp_id in hrm_person.hrm_person_id%type)
    return hrm_establishment.est_address%type
  is
    lv_result hrm_establishment.est_address%type;
  begin
    select (select EST_ADDRESS
              from HRM_ESTABLISHMENT
             where HRM_ESTABLISHMENT_ID = I.HRM_ESTABLISHMENT_ID)
      into lv_result
      from (select   HRM_ESTABLISHMENT_ID
                from HRM_IN_OUT
               where HRM_EMPLOYEE_ID = vEmp_id
                 and HRM_ESTABLISHMENT_ID is not null
                 and C_IN_OUT_CATEGORY = '3'
                 and hrm_date.ActivePeriod between trunc(INO_IN, 'MM') and hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID)
            order by trunc(INO_IN, 'MM') desc) I
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplEstabZipCity(vEmp_id in hrm_person.hrm_person_id%type)
    return varchar2
  is
    lv_result varchar2(32767);
  begin
    select (select EST_ZIP || ' ' || EST_CITY
              from HRM_ESTABLISHMENT
             where HRM_ESTABLISHMENT_ID = I.HRM_ESTABLISHMENT_ID)
      into lv_result
      from (select   HRM_ESTABLISHMENT_ID
                from HRM_IN_OUT
               where HRM_EMPLOYEE_ID = vEmp_id
                 and HRM_ESTABLISHMENT_ID is not null
                 and C_IN_OUT_CATEGORY = '3'
                 and hrm_date.ActivePeriod between trunc(INO_IN, 'MM') and hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID)
            order by trunc(INO_IN, 'MM') desc) I
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplEstabUrssaf(vEmp_id in hrm_person.hrm_person_id%type)
    return varchar2
  is
    lv_result varchar2(32767);
  begin
    select (select
                   -- do not localize, uniquely for frenchies
                   'URSSAF de ' || EST_URSSAF_NAME || ', ' || 'compte no ' || EST_URSSAF_ACCOUNT || ', ' || 'APE ' || EST_APE
              from HRM_ESTABLISHMENT
             where HRM_ESTABLISHMENT_ID = I.HRM_ESTABLISHMENT_ID)
      into lv_result
      from (select   HRM_ESTABLISHMENT_ID
                from HRM_IN_OUT
               where HRM_EMPLOYEE_ID = vEmp_id
                 and HRM_ESTABLISHMENT_ID is not null
                 and C_IN_OUT_CATEGORY = '3'
                 and hrm_date.ActivePeriod between trunc(INO_IN, 'MM') and hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID)
            order by trunc(INO_IN, 'MM') desc) I
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplEstabSiren(vEmp_id in hrm_person.hrm_person_id%type)
    return varchar2
  is
    lv_result varchar2(32767);
  begin
    select (select EST_SIREN || EST_SIRET
              from HRM_ESTABLISHMENT
             where HRM_ESTABLISHMENT_ID = I.HRM_ESTABLISHMENT_ID)
      into lv_result
      from (select   HRM_ESTABLISHMENT_ID
                from HRM_IN_OUT
               where HRM_EMPLOYEE_ID = vEmp_id
                 and HRM_ESTABLISHMENT_ID is not null
                 and C_IN_OUT_CATEGORY = '3'
                 and hrm_date.ActivePeriod between trunc(INO_IN, 'MM') and hrm_date.NextInOutInDate(INO_IN, HRM_EMPLOYEE_ID)
            order by trunc(INO_IN, 'MM') desc) I
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function EmplEstabCanton(vEmpId in HRM_PERSON.HRM_PERSON_ID%type)
    return HRM_ESTABLISHMENT.C_HRM_CANTON%type
  is
    lv_Result HRM_ESTABLISHMENT.C_HRM_CANTON%type;
  begin
    select EST.C_HRM_CANTON
      into lv_Result
      from HRM_IN_OUT INO
         , HRM_ESTABLISHMENT EST
     where INO.HRM_EMPLOYEE_ID = vEmpId
       and INO.C_IN_OUT_STATUS = 'ACT'
       and INO.C_IN_OUT_CATEGORY = '3'
       and EST.HRM_ESTABLISHMENT_ID = INO.HRM_ESTABLISHMENT_ID;

    return lv_Result;
  exception
    when no_data_found then
      return null;
  end EmplEstabCanton;

  function getTotalForPreviousYear(IsRetro in integer, aEleCode in hrm_elements.ele_code%type, aEmpId in hrm_person.hrm_person_id%type)
    return hrm_history_detail.his_pay_sum_val%type
  is
    ln_result      hrm_history_detail.his_pay_sum_val%type;
    ld_beginofyear date;
    ld_endofyear   date;
  begin
    if (IsRetro = 0) then
      return 0.0;
    end if;

    ld_beginofyear  := add_months(hrm_date.BeginOfYear, -12);
    ld_endofyear    := hrm_date.BeginOfYear - 1;

    select sum(D.HIS_PAY_SUM_VAL)
      into ln_result
      from HRM_HISTORY_DETAIL D
         , HRM_ELEMENTS E
     where E.ELE_CODE = aEleCode
       and D.HRM_ELEMENTS_ID = E.HRM_ELEMENTS_ID
       and D.HRM_EMPLOYEE_ID = aEmpId
       and D.HIS_PAY_PERIOD between ld_beginofyear and ld_endofyear;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

/** @deprecated */
  function getYearTotalDeduction(
    EmpId                in hrm_person.hrm_person_id%type
  , LiabledRootName      in hrm_elements_root.elr_root_name%type
  , CurrentLiabledAmount in number
  )
    return number
  is
  begin
    return hrm_taxsource.tax_amount_gross(in_employe_id => EmpId, iv_type_regular_normal => LiabledRootName, in_amount_regular_normal => CurrentLiabledAmount);
  end;

  function getPeriodTotalDeduction(
    EmpId                in hrm_person.hrm_person_id%type
  , LiabledRootName      in hrm_elements_root.elr_root_name%type
  , CurrentLiabledAmount in number
  )
    return number
  is
    cursor lcur_tax_period(id in hrm_person.hrm_person_id%type, RootName in hrm_elements_root.elr_root_name%type)
    is
      select EMT_VALUE
           , BEGIN_PERIOD
           , END_PERIOD
           , (select sum(HIS_PAY_SUM_VAL)
                from HRM_HISTORY_DETAIL D
               where HRM_EMPLOYEE_ID = P.HRM_PERSON_ID
                 and HIS_PAY_PERIOD between P.BEGIN_PERIOD and last_day(P.END_PERIOD)
                 and exists(select 1
                              from HRM_ELEMENTS_ROOT
                             where HRM_ELEMENTS_ID = D.HRM_ELEMENTS_ID
                               and ELR_ROOT_NAME = RootName) ) SUBMISSION
        from (select T.HRM_PERSON_ID
                   , T.EMT_VALUE
                   , least(I.INO_OUT, T.EMT_FROM) BEGIN_PERIOD
                   , T.EMT_TO END_PERIOD
                from (select HRM_PERSON_ID
                           , EMT_VALUE
                           , greatest(EMT_FROM, hrm_date.ActivePeriod) EMT_FROM
                           , nvl2(EMT_TO, least(EMT_TO, hrm_date.ActivePeriodEndDate), hrm_date.ActivePeriodEndDate) EMT_TO
                        from HRM_EMPLOYEE_TAXSOURCE
                       where EMT_DEFINITIVE = 0) T
                   , (select HRM_EMPLOYEE_ID
                           , nvl2(INO_OUT, least(trunc(INO_OUT, 'month'), hrm_date.ActivePeriod), hrm_date.ActivePeriod) INO_OUT
                        from HRM_IN_OUT
                       where C_IN_OUT_STATUS = 'ACT'
                         and C_IN_OUT_CATEGORY = '3') I
               where I.HRM_EMPLOYEE_ID = T.HRM_PERSON_ID) P
       where HRM_PERSON_ID = id;

    ln_amount        number;
    ln_annual_amount number;
    ln_result        number := 0.0;
  begin
    for tpl in lcur_tax_period(EmpId, LiabledRootName) loop

      -- Annualisation du montant soumis de la période
      if hrm_date.Days_Between(tpl.begin_period, tpl.end_period) > 0 then

        ln_amount         := nvl(tpl.submission, 0.0) + case
                             when lcur_tax_period%rowcount > 1 then 0.0
                             else CurrentLiabledAmount
                           end;

        ln_annual_amount  := ln_amount / hrm_date.Days_Between(tpl.begin_period, tpl.end_period) * 360;
        -- Recherche du taux en fonction du montant annuel divisé par 12 ( tabelles mensuelles )
        -- et incrémentation de la déduction totale
        ln_result         := ln_result + ln_amount * hrm_functions.TaxRate(ln_annual_amount / 12, substr(tpl.emt_value, 1, 2), tpl.emt_value) / 100;
      end if;
    end loop;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  function getTaxForPeriodOnly(EmpId in hrm_person.hrm_person_id%type, period in date, amount in number)
    return number
  is
    lv_taxarray hrm_employee_taxsource.emt_value%type;
  begin
    select EMT_VALUE
      into lv_taxarray
      from (select EMT_VALUE
                 , EMT_FROM
                 , last_day(nvl(EMT_TO, period + 1) ) EMT_TO
              from HRM_EMPLOYEE_TAXSOURCE
             where HRM_PERSON_ID = EmpId)
     where period between EMT_FROM and EMT_TO;

    return amount * hrm_functions.TaxRate(amount, substr(lv_taxarray, 1, 2), lv_taxarray) / 100;
  exception
    when no_data_found then
      return 0.0;
  end;

  function getTaxASRectifTax(EmpId in hrm_person.hrm_person_id%type)
    return number
  is
    ln_result number := 0.0;
  begin
    select sum(amount)
      into ln_result
      from (select nvl(ELM_EXT.elm_tax_source, 0) + nvl(ELM_CORR.elm_tax_source, 0) amount
              from
                   -- records extournés
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_source
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '02'
                       and elm_tax_hit_pay_num is null
                       and hrm_person_id = EmpId) ELM_EXT
                 ,
                   -- records correctifs
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_source
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '01'
                       and elm_tax_hit_pay_num is null
                       and hrm_taxsource_ledger_ext_id is not null
                       and hrm_person_id = EmpId) ELM_CORR
             where ELM_EXT.hrm_taxsource_ledger_ext_id = ELM_CORR.hrm_taxsource_ledger_ext_id
            union all
            select nvl(elm_tax_source, 0) amount
              from hrm_taxsource_ledger
             where c_elm_tax_type in('03', '04')
               and elm_tax_hit_pay_num is null
               and hrm_person_id = EmpId);

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end getTaxASRectifTax;

  function getTaxASRectifEarning(EmpId in hrm_person.hrm_person_id%type)
    return number
  is
    ln_result number := 0.0;
  begin
    select sum(amount)
      into ln_result
      from (select nvl(ELM_EXT.elm_tax_earning, 0) + nvl(ELM_CORR.elm_tax_earning, 0) amount
              from
                   -- records extournés
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_earning
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '02'
                       and elm_tax_hit_pay_num is null
                       and hrm_person_id = EmpId) ELM_EXT
                 ,
                   -- records correctifs
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_earning
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '01'
                       and elm_tax_hit_pay_num is null
                       and hrm_taxsource_ledger_ext_id is not null
                       and hrm_person_id = EmpId) ELM_CORR
             where ELM_EXT.hrm_taxsource_ledger_ext_id = ELM_CORR.hrm_taxsource_ledger_ext_id
            union all
            select nvl(elm_tax_earning, 0) amount
              from hrm_taxsource_ledger
             where c_elm_tax_type in('03', '04')
               and elm_tax_hit_pay_num is null
               and hrm_person_id = EmpId);

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end getTaxASRectifEarning;

  function getTaxASRectifAscertainEarning(EmpId in hrm_person.hrm_person_id%type)
    return number
  is
    ln_result number := 0.0;
  begin
    select sum(amount)
      into ln_result
      from (select nvl(ELM_EXT.elm_tax_ascertain_earning, 0) + nvl(ELM_CORR.elm_tax_ascertain_earning, 0) amount
              from
                   -- records extournés
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_ascertain_earning
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '02'
                       and elm_tax_hit_pay_num is null
                       and hrm_person_id = EmpId) ELM_EXT
                 ,
                   -- records correctifs
                   (select hrm_taxsource_ledger_ext_id
                         , elm_tax_ascertain_earning
                      from hrm_taxsource_ledger
                     where c_elm_tax_type = '01'
                       and elm_tax_hit_pay_num is null
                       and hrm_taxsource_ledger_ext_id is not null
                       and hrm_person_id = EmpId) ELM_CORR
             where ELM_EXT.hrm_taxsource_ledger_ext_id = ELM_CORR.hrm_taxsource_ledger_ext_id
            union all
            select nvl(elm_tax_ascertain_earning, 0) amount
              from hrm_taxsource_ledger
             where c_elm_tax_type in('03', '04')
               and elm_tax_hit_pay_num is null
               and hrm_person_id = EmpId);

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end getTaxASRectifAscertainEarning;

  function getTaxCode(EmpId in hrm_person.hrm_person_id%type, period in date)
    return varchar2
  is
    vTaxValue hrm_employee_taxsource.emt_value%type;
    vTaxDef   hrm_employee_taxsource.emt_definitive%type;
  begin
    -- Dernier barème valable pour la période
    select EMT_VALUE
         , EMT_DEFINITIVE
      into vTaxValue
         , vTaxDef
      from (select   coalesce(EMT_VALUE, EMT_VALUE_SPECIAL, C_HRM_IS_CAT) EMT_VALUE
                   , EMT_DEFINITIVE
                from (select EMT_VALUE
                           , EMT_VALUE_SPECIAL
                           , C_HRM_IS_CAT
                           , EMT_DEFINITIVE
                           , EMT_FROM
                           , trunc(EMT_FROM, 'MM') EMT_BEGIN
                           , nvl(HRM_DATE.ENDEMPTAXDATE(EMT_FROM, EMT_TO, HRM_PERSON_ID), hrm_date.activeperiodenddate) EMT_END
                        from HRM_EMPLOYEE_TAXSOURCE
                       where HRM_PERSON_ID = EmpId)
               where period between EMT_BEGIN and EMT_END
            order by EMT_FROM desc)
     where rownum = 1;

    -- Vérifier que celui-ci ne soit pas clos.
    if (vTaxDef = 0) then
      return vTaxValue;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function getTaxCodeYear(EmpId in hrm_person.hrm_person_id%type, Canton in hrm_employee_taxsource.emt_canton%type, TaxYear in varchar2)
    return varchar2
  is
    lv_result    hrm_employee_taxsource.emt_value%type;
    ld_BeginYear date;
  begin
    ld_BeginYear  := to_date('0101' || TaxYear, 'ddmmyyyy');

    -- Dernier barème valable pour l'année et le canton
    select EMT_VALUE
      into lv_result
      from (select   EMT_VALUE
                from (select coalesce(EMT_VALUE, EMT_VALUE_SPECIAL, C_HRM_IS_CAT) EMT_VALUE
                           , emt_from
                           , trunc(EMT_FROM, 'Y') EMT_BEGIN
                           , nvl(EMT_TO, ld_BeginYear) EMT_END
                        from HRM_EMPLOYEE_TAXSOURCE
                       where HRM_PERSON_ID = EmpId
                         and EMT_CANTON = Canton)
               where ld_BeginYear between EMT_BEGIN and EMT_END
            order by EMT_FROM desc)
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function get_SalaryNumber(EmpId in hrm_person.hrm_person_id%type)
    return varchar2
  is
    lv_result dic_salary_number.dic_salary_number_id%type;
  begin
    select DIC_SALARY_NUMBER_ID
      into lv_result
      from (select   DIC_SALARY_NUMBER_ID
                from HRM_CONTRACT
               where HRM_EMPLOYEE_ID = EmpId
                 and
                     -- Valable pour la période courante, (dernier antérieur si inexistant)
                     CON_BEGIN <= hrm_date.ActivePeriodEndDate
            order by CON_BEGIN desc)
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function get_FinRef(EmpId in hrm_person.hrm_person_id%type)
    return number
  is
    ln_Result number(2);
  begin
    select count(*)
      into ln_Result
      from HRM_FINANCIAL_REF
     where HRM_EMPLOYEE_ID = EmpId
       and FIN_SEQUENCE = 0
       and (HRM_DATE.ACTIVEPERIODENDDATE between FIN_START_DATE and nvl(FIN_END_DATE, HRM_DATE.ACTIVEPERIODENDDATE) );

    return ln_Result;
  end;
end HRM_FUNCTIONS;
