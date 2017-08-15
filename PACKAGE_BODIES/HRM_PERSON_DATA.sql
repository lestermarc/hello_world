--------------------------------------------------------
--  DDL for Package Body HRM_PERSON_DATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PERSON_DATA" 
/**
 * Package de gestion des personnes et des employés
 *
 * @version 1.0
 * @date 03.03.2000
 * @author jsomers
 * @author spfister
 * @author ireber
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
as
  gd_first_entry date;
  gd_last_entry  date;
  gd_last_leave  date;

  -- Cusor for accessing Person (HRM_PERSON) fields
  cursor gcur_person(in_person_id in hrm_person.hrm_person_id%type)
  is
    select *
      from hrm_person
     where hrm_person_id = in_person_id;

  -- Record for acessing Person's fields
  grec_person    gcur_person%rowtype;

  procedure set_PersonData(personID in hrm_person.hrm_person_id%type)
  is
  begin
    gd_first_entry  := null;
    gd_last_entry   := null;
    gd_last_leave   := null;
    grec_person     := null;
    HRM_I_PRC_HISTORY.ClearSessionAdditionalData();

    if gcur_person%isopen then
      close gcur_person;
    end if;

    open gcur_person(personId);

    fetch gcur_person
     into grec_person;

    close gcur_person;

    -- Première et dernière entrée
    select min(INO_IN)
         , max(INO_IN)
      into gd_first_entry
         , gd_last_entry
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = personID
       and C_IN_OUT_CATEGORY = '3';

    -- Dernière sortie active
    select max(INO_OUT)
      into gd_last_leave
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = personID
       and C_IN_OUT_STATUS = 'ACT'
       and C_IN_OUT_CATEGORY = '3';
  exception
    when others then
      gd_first_entry  := null;
      gd_last_entry   := null;
      gd_last_leave   := null;
      grec_person     := null;
      HRM_I_PRC_HISTORY.ClearSessionAdditionalData();
  end;

  function get_PersonDataId
    return hrm_person.hrm_person_id%type
  is
  begin
    return grec_person.HRM_PERSON_ID;
  end;

  function get_Politness
    return varchar2
  is
  begin
    return grec_person.PER_TITLE;
  end;

  function get_DicPolitness
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_PERSON_POLITNESS', grec_person.PER_TITLE, grec_person.PC_LANG_ID);
  end;

  function get_EmpNumber
    return varchar2
  is
  begin
    return grec_person.EMP_NUMBER;
  end;

  function get_Name
    return varchar2
  is
  begin
    return grec_person.PER_LAST_NAME;
  end;

  function get_FirstName
    return varchar2
  is
  begin
    return grec_person.PER_FIRST_NAME;
  end;

  function get_FullName
    return varchar2
  is
  begin
    return grec_person.PER_FULLNAME;
  end;

  function get_NameAndFirstName
    return varchar2
  is
  begin
    return trim(grec_person.PER_LAST_NAME || ' ' || grec_person.PER_FIRST_NAME);
  end;

  function get_FirstNameAndName
    return varchar2
  is
  begin
    return trim(grec_person.PER_FIRST_NAME || ' ' || grec_person.PER_LAST_NAME);
  end;

  function get_TaxAddress
    return varchar2
  is
  begin
    if grec_person.PER_TAXSTREET is null then
      return case grec_person.PER_MAIL_ADD_SELECTOR
        when 0 then grec_person.PER_BUSINESSSTREET
        when 1 then grec_person.PER_HOMESTREET
        when 2 then grec_person.PER_OTHERSTREET
      end;
    else
      return grec_person.PER_TAXSTREET;
    end if;
  end;

  function get_TaxCity
    return varchar2
  is
  begin
    if grec_person.PER_TAXCITY is null then
      return case grec_person.PER_MAIL_ADD_SELECTOR
        when 0 then grec_person.PER_BUSINESSCITY
        when 1 then grec_person.PER_HOMECITY
        when 2 then grec_person.PER_OTHERCITY
      end;
    else
      return grec_person.PER_TAXCITY;
    end if;
  end;

  function get_TaxPostalCode
    return varchar2
  is
  begin
    if grec_person.PER_TAXPOSTALCODE is null then
      return case grec_person.PER_MAIL_ADD_SELECTOR
        when 0 then grec_person.PER_BUSINESSPOSTALCODE
        when 1 then grec_person.PER_HOMEPOSTALCODE
        when 2 then grec_person.PER_OTHERPOSTALCODE
      end;
    else
      return grec_person.PER_TAXPOSTALCODE;
    end if;
  end;

  function get_TaxPostalCodeCity
    return varchar2
  is
  begin
    if grec_person.PER_TAXPOSTALCODE is null then
      return case grec_person.PER_MAIL_ADD_SELECTOR
        when 0 then trim(grec_person.PER_BUSINESSPOSTALCODE || ' ' || grec_person.PER_BUSINESSCITY)
        when 1 then trim(grec_person.PER_HOMEPOSTALCODE || ' ' || grec_person.PER_HOMECITY)
        when 2 then trim(grec_person.PER_OTHERPOSTALCODE || ' ' || grec_person.PER_OTHERCITY)
      end;
    else
      return trim(grec_person.per_taxPostalCode || ' ' || grec_person.per_taxCity);
    end if;
  end;

  function get_TaxCountry
    return varchar2
  is
  begin
    if grec_person.PER_TAXPOSTALCODE is null then
      return case grec_person.PER_MAIL_ADD_SELECTOR
        when 0 then grec_person.PER_BUSINESSCOUNTRY
        when 1 then grec_person.PER_HOMECOUNTRY
        when 2 then grec_person.PER_OTHERCOUNTRY
      end;
    else
      return grec_person.PER_TAXCOUNTRY;
    end if;
  end;

  function get_DefaultAddress
    return varchar2
  is
  begin
    return case grec_person.PER_MAIL_ADD_SELECTOR
      when 0 then grec_person.PER_BUSINESSSTREET
      when 1 then grec_person.PER_HOMESTREET
      when 2 then grec_person.PER_OTHERSTREET
      when 3 then grec_person.PER_TAXSTREET
    end;
  end;

  function get_DefaultCity
    return varchar2
  is
  begin
    return case grec_person.PER_MAIL_ADD_SELECTOR
      when 0 then grec_person.PER_BUSINESSCITY
      when 1 then grec_person.PER_HOMECITY
      when 2 then grec_person.PER_OTHERCITY
      when 3 then grec_person.PER_TAXCITY
    end;
  end;

  function get_DefaultPostalCode
    return varchar2
  is
  begin
    return case grec_person.PER_MAIL_ADD_SELECTOR
      when 0 then grec_person.PER_BUSINESSPOSTALCODE
      when 0 then grec_person.PER_BUSINESSPOSTALCODE
      when 1 then grec_person.PER_HOMEPOSTALCODE
      when 2 then grec_person.PER_OTHERPOSTALCODE
      when 3 then grec_person.PER_TAXPOSTALCODE
    end;
  end;

  function get_DefaultPostalCodeCity
    return varchar2
  is
  begin
    return trim(hrm_person_data.get_DefaultPostalCode || ' ' || hrm_person_data.get_DefaultCity);
  end;

  function get_DefaultCountry
    return varchar2
  is
  begin
    return case grec_person.PER_MAIL_ADD_SELECTOR
      when 0 then grec_person.PER_BUSINESSCOUNTRY
      when 1 then grec_person.PER_HOMECOUNTRY
      when 2 then grec_person.PER_OTHERCOUNTRY
      when 3 then grec_person.PER_TAXCOUNTRY
    end;
  end;

  function get_BusinessAddress
    return varchar2
  is
  begin
    return grec_person.PER_BUSINESSSTREET;
  end;

  function get_BusinessCity
    return varchar2
  is
  begin
    return grec_person.PER_BUSINESSCITY;
  end;

  function get_BusinessPostalCode
    return varchar2
  is
  begin
    return grec_person.PER_BUSINESSPOSTALCODE;
  end;

  function get_BusinessPostalCodeCity
    return varchar2
  is
  begin
    return trim(grec_person.PER_BUSINESSPOSTALCODE || ' ' || grec_person.PER_BUSINESSCITY);
  end;

  function get_BusinessCountry
    return varchar2
  is
  begin
    return grec_person.PER_BUSINESSCOUNTRY;
  end;

  function get_BirthDate
    return date
  is
  begin
    return grec_person.PER_BIRTH_DATE;
  end;

  function get_GroupEntry
    return date
  is
  begin
    return grec_person.EMP_GROUP_ENTRY;
  end;

  function get_FirstEntry
    return date
  is
  begin
    return gd_first_entry;
  end;

  function get_LastEntry
    return date
  is
  begin
    return gd_last_entry;
  end;

  function get_LastLeave
    return date
  is
  begin
    return gd_last_leave;
  end;

  function get_Department
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_DEPARTMENT', grec_person.DIC_DEPARTMENT_ID, grec_person.PC_LANG_ID);
  end;

  function get_CodeDepartment
    return varchar2
  is
  begin
    return grec_person.DIC_DEPARTMENT_ID;
  end;

  function get_CompanyDescr
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyDescr;
  end;

  function get_CompanyName
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyName;
  end;

  function get_CompanyCorporateName
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyCorporateName;
  end;

  function get_CompanyAddress
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyAddress;
  end;

  function get_CompanyPostalCode
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyPostalCode;
  end;

  function get_CompanyCity
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyCity;
  end;

  function get_CompanyPhone
    return varchar2
  is
  begin
    return hrm_functions.get_CompanyPhone;
  end;

  function get_CompanyFax
    return varchar2
  is
  begin
    return hrm_functions.get_Companyfax;
  end;

  function get_AgeInYear
    return integer
  is
  begin
    return hrm_functions.AgeInYear(grec_person.PER_BIRTH_DATE);
  end;

  function get_AgeInPeriod
    return integer
  is
  begin
    return hrm_functions.AgeInPeriod(grec_person.PER_BIRTH_DATE);
  end;

  function get_AgeInGroup
    return integer
  is
  begin
    return hrm_functions.AgeInPeriod(grec_person.EMP_GROUP_ENTRY);
  end;

  function get_AvsCode
    return integer
  is
  begin
    return hrm_functions.AvsCode(grec_person.HRM_PERSON_ID, grec_person.PER_BIRTH_DATE, grec_person.PER_GENDER);
  end;

  function get_PensionMonths
    return integer
  is
  begin
    return hrm_date.pensionMonths(grec_person.HRM_PERSON_ID, grec_person.PER_BIRTH_DATE, grec_person.PER_GENDER);
  end;

  function get_YearPensionMonths
    return integer
  is
  begin
    return hrm_date.YearPensionMonths(grec_person.HRM_PERSON_ID, grec_person.PER_BIRTH_DATE, grec_person.PER_GENDER);
  end;

  function get_YearsOfService
    return integer
  is
  begin
    return hrm_functions.EmplYearsOfService(grec_person.HRM_PERSON_ID);
  end;

  function get_YearMonthsOfService
    return varchar2
  is
  begin
    return hrm_functions.EmplYearMonthsOfService(grec_person.HRM_PERSON_ID);
  end;

  function get_YearMonthsInGroup
    return varchar2
  is
  begin
    return hrm_functions.EmplYearMonthsInGroup(grec_person.EMP_GROUP_ENTRY);
  end;

  function get_Sex
    return varchar2
  is
  begin
    return grec_person.PER_GENDER;
  end;

  function get_ACDaysToPay
    return integer
  is
  begin
    return hrm_date.days_SinceBPeriod(grec_person.HRM_PERSON_ID, hrm_date.ACTIVEPERIOD);
  end;

  function get_ACDaysToPayFR
    return integer
  is
  begin
    return hrm_date.AC_Days_SinceLastPayFR(grec_person.HRM_PERSON_ID);
  end;

  function get_ACDaysSinceBeginOfYear
    return integer
  is
  begin
    return hrm_date.days_SinceBYear(grec_person.HRM_PERSON_ID, hrm_date.ActivePeriod);
  end;

  function get_ACDaysSinceBeginOfYearFR
    return integer
  is
  begin
    return hrm_date.AC_Days_SinceBeginOfYearFR(grec_person.HRM_PERSON_ID);
  end;

  function get_DaysToPay
    return integer
  is
  begin
    return hrm_date.Ndays_SinceBPeriod(grec_person.HRM_PERSON_ID, hrm_date.ActivePeriod);
  end;

  function get_DaysSinceBeginOfYear
    return integer
  is
  begin
    return hrm_date.Ndays_SinceBYear(grec_person.HRM_PERSON_ID, hrm_date.ActivePeriod);
  end;

  function arrayValue(varray in varchar2, vCriteria in varchar2)
    return number
  is
  begin
    return hrm_functions.arrayValue(varray, vCriteria);
  end;

  function arrayValue2(varray in varchar2, vCode in varchar2, vCriteria in varchar2)
    return number
  is
  begin
    return hrm_functions.arrayValue2(varray, vCode, vCriteria);
  end;

  function TaxAmountGross(
    iv_type_regular_normal      in varchar2
  , in_amount_regular_normal    in number
  , iv_type_sporadic_normal     in varchar2 default ''
  , in_amount_sporadic_normal   in number default 0
  , iv_type_regular_fte         in varchar2 default ''
  , in_amount_regular_fte       in number default 0
  , iv_type_sporadic_fte        in varchar2 default ''
  , in_amount_sporadic_fte      in number default 0
  , iv_type_activity_rate       in varchar2 default ''
  , in_amount_activity_rate     in number default 0
  , iv_type_rate_only           in varchar2 default ''
  , in_amount_rate_only         in number default 0
  , in_amount_hourly_rate       in number default 0
  , in_amount_estimated_revenue in number default 0
  , iv_canton                   in varchar2 default ''
  , iv_type_rate_only_normal    in varchar2 default ''
  , in_amount_rate_only_normal  in number default 0
  )
    return number
  is
  begin
    return hrm_taxsource.tax_amount_gross(in_employe_id                 => grec_person.HRM_PERSON_ID
                                        , iv_type_regular_normal        => iv_type_regular_normal
                                        , in_amount_regular_normal      => in_amount_regular_normal
                                        , iv_type_sporadic_normal       => iv_type_sporadic_normal
                                        , in_amount_sporadic_normal     => in_amount_sporadic_normal
                                        , iv_type_regular_fte           => iv_type_regular_fte
                                        , in_amount_regular_fte         => in_amount_regular_fte
                                        , iv_type_sporadic_fte          => iv_type_sporadic_fte
                                        , in_amount_sporadic_fte        => in_amount_sporadic_fte
                                        , iv_type_activity_rate         => iv_type_activity_rate
                                        , in_amount_activity_rate       => in_amount_activity_rate
                                        , iv_type_rate_only             => iv_type_rate_only
                                        , in_amount_rate_only           => in_amount_rate_only
                                        , in_amount_hourly_rate         => in_amount_hourly_rate
                                        , in_amount_estimated_revenue   => in_amount_estimated_revenue
                                        , iv_canton                     => iv_canton
                                        , iv_type_rate_only_normal      => iv_type_rate_only_normal
                                        , in_amount_rate_only_normal    => in_amount_rate_only_normal
                                         );
  end;

  function TaxAmountNet(
    iv_type_regular_normal      in varchar2
  , in_amount_regular_normal    in number
  , iv_type_sporadic_normal     in varchar2 default ''
  , in_amount_sporadic_normal   in number default 0
  , iv_type_regular_fte         in varchar2 default ''
  , in_amount_regular_fte       in number default 0
  , iv_type_sporadic_fte        in varchar2 default ''
  , in_amount_sporadic_fte      in number default 0
  , iv_type_activity_rate       in varchar2 default ''
  , in_amount_activity_rate     in number default 0
  , iv_type_rate_only           in varchar2 default ''
  , in_amount_rate_only         in number default 0
  , in_amount_hourly_rate       in number default 0
  , in_amount_estimated_revenue in number default 0
  , iv_canton                   in varchar2 default ''
  , iv_type_deduction           in varchar2 default ''
  , iv_type_rate_only_normal    in varchar2 default ''
  , in_amount_rate_only_normal  in number default 0
  )
    return number
  is
  begin
    return hrm_taxsource.tax_amount_net(in_employe_id                 => grec_person.HRM_PERSON_ID
                                      , iv_type_regular_normal        => iv_type_regular_normal
                                      , in_amount_regular_normal      => in_amount_regular_normal
                                      , iv_type_sporadic_normal       => iv_type_sporadic_normal
                                      , in_amount_sporadic_normal     => in_amount_sporadic_normal
                                      , iv_type_regular_fte           => iv_type_regular_fte
                                      , in_amount_regular_fte         => in_amount_regular_fte
                                      , iv_type_sporadic_fte          => iv_type_sporadic_fte
                                      , in_amount_sporadic_fte        => in_amount_sporadic_fte
                                      , iv_type_activity_rate         => iv_type_activity_rate
                                      , in_amount_activity_rate       => in_amount_activity_rate
                                      , iv_type_rate_only             => iv_type_rate_only
                                      , in_amount_rate_only           => in_amount_rate_only
                                      , in_amount_hourly_rate         => in_amount_hourly_rate
                                      , in_amount_estimated_revenue   => in_amount_estimated_revenue
                                      , iv_canton                     => iv_canton
                                      , iv_type_rate_only_normal      => iv_type_rate_only_normal
                                      , in_amount_rate_only_normal    => in_amount_rate_only_normal
                                      , iv_type_deduction             => iv_type_deduction
                                       );
  end;

  function taxRate(vAmount in number, vTax in varchar2, vCategory in varchar2)
    return number
  is
  begin
    return hrm_functions.taxRate(vAmount, vTax, vCategory);
  end;

  function taxAddressByLine(vLineNumber integer)
    return varchar2
  is
  begin
    if (vLineNumber > 0) then
      return pcs.ExtractLine(hrm_person_data.get_TaxAddress, vLineNumber);
    end if;

    return null;
  end;

  function defaultAddressByLine(vLineNumber integer)
    return varchar2
  is
  begin
    if (vLineNumber > 0) then
      return pcs.ExtractLine(hrm_person_data.get_DefaultAddress, vLineNumber);
    end if;

    return null;
  end;

  function get_ChildBenefitsForPeriod
    return number
  is
  begin
    return hrm_var.ChildBenefitsForPeriod(grec_person.HRM_PERSON_ID);
  end;

  function childBenefitsByTypeForPeriod(vType in dic_allowance_type.dic_allowance_type_id%type)
    return number
  is
  begin
    return hrm_var.ChildBenefitsByTypeForPeriod(grec_person.HRM_PERSON_ID, vType);
  end;

  function ChildrenAllowance(in_type in integer, iv_array in varchar2)
    return number
  is
  begin
    return hrm_var.ChildrenAllowance(grec_person.HRM_PERSON_ID, in_type, iv_array);
  end;

  function get_IsFinalPay
    return integer
  is
  begin
    return hrm_var.IsFinalPay(grec_person.HRM_PERSON_ID);
  end;

  function get_SalaryNumber
    return varchar2
  is
  begin
    return hrm_functions.get_SalaryNumber(grec_person.HRM_PERSON_ID);
  end;

  function get_Confession
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_CONFESSION', grec_person.DIC_CONFESSION_ID, grec_person.PC_LANG_ID);
  end;

  function get_CantonWork
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_CANTON_WORK', grec_person.DIC_CANTON_WORK_ID, grec_person.PC_LANG_ID);
  end;

  function get_WorkRegion
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_WORKREGION', grec_person.DIC_WORKREGION_ID, grec_person.PC_LANG_ID);
  end;

  function get_WorkPlace
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_WORKPLACE', grec_person.DIC_WORKPLACE_ID, grec_person.PC_LANG_ID);
  end;

  function get_WorkPermit
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_WORK_PERMIT', hrm_person_data.get_CodeWorkPermit, grec_person.PC_LANG_ID);
  end;

  function get_CodeConfession
    return varchar2
  is
  begin
    return grec_person.DIC_CONFESSION_ID;
  end;

  function get_CodeCantonWork
    return varchar2
  is
  begin
    return grec_person.DIC_CANTON_WORK_ID;
  end;

  function get_CodeWorkRegion
    return varchar2
  is
  begin
    return grec_person.DIC_WORKREGION_ID;
  end;

  function get_CodeWorkPlace
    return varchar2
  is
  begin
    return grec_person.DIC_WORKPLACE_ID;
  end;

  function get_CodeWorkPermit
    return varchar2
  is
    lv_result dic_work_permit.dwp_descr%type;
  begin
    select DIC_WORK_PERMIT_ID
      into lv_result
      from (select DIC_WORK_PERMIT_ID
                 , trunc(WOP_VALID_FROM, 'MM') WOP_VALID_FROM
                 , nvl(WOP_VALID_TO, hrm_date.ActivePeriod) WOP_VALID_TO
              from HRM_EMPLOYEE_WK_PERMIT
             where HRM_PERSON_ID = grec_person.HRM_PERSON_ID)
     where hrm_date.ActivePeriod between WOP_VALID_FROM and WOP_VALID_TO;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end;

  function get_CodeActivity
    return varchar2
  is
  begin
    return grec_person.DIC_JOB_ACTIVITY_ID;
  end;

  function get_Activity
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_JOB_ACTIVITY', grec_person.DIC_JOB_ACTIVITY_ID, grec_person.PC_LANG_ID);
  end;

  function get_CodeResponsability
    return varchar2
  is
  begin
    return grec_person.DIC_RESPONSABILITY_ID;
  end;

  function get_Responsability
    return varchar2
  is
  begin
    return hrm_functions.getDicoDescr('DIC_RESPONSABILITY', grec_person.DIC_RESPONSABILITY_ID, grec_person.PC_LANG_ID);
  end;

  function get_IsFirstSalaryInYear
    return integer
  is
  begin
    return hrm_var.IsFirstSalaryInYear(grec_person.HRM_PERSON_ID);
  end;

  function sumElem(vCode in varchar2, vBeginDate in date, vEndDate in date)
    return number
  is
  begin
    return hrm_functions.sumElem(grec_person.HRM_PERSON_ID, vCode, vBeginDate, vEndDate);
  end;

  function sumElemInPeriod(vCode in varchar2)
    return number
  is
  begin
    return hrm_functions.sumElemInPeriod(grec_person.HRM_PERSON_ID, vCode);
  end;

  function sumElemInYear(vCode in varchar2)
    return number
  is
  begin
    return hrm_functions.sumElemInYear(grec_person.HRM_PERSON_ID, vCode);
  end;

  function getTotalForPreviousYear(IsRetro in integer, aEleCode in hrm_elements.ele_code%type)
    return number
  is
  begin
    return hrm_functions.getTotalForPreviousYear(IsRetro, aEleCode, grec_person.HRM_PERSON_ID);
  end;

/** @deprecated */
  function getYearTotalDeduction(LiabledRootName in hrm_elements_root.elr_root_name%type, CurrentLiabledAmount in number)
    return number
  is
  begin
    return hrm_taxsource.tax_amount_gross(in_employe_id              => grec_person.HRM_PERSON_ID
                                        , iv_type_regular_normal     => LiabledRootName
                                        , in_amount_regular_normal   => CurrentLiabledAmount
                                         );
  end;

  function getPeriodTotalDeduction(LiabledRootName in hrm_elements_root.elr_root_name%type, CurrentLiabledAmount in number)
    return number
  is
  begin
    return hrm_functions.getPeriodTotalDeduction(grec_person.HRM_PERSON_ID, LiabledRootName, CurrentLiabledAmount);
  end;

  function getTaxForPeriodOnly(amount in number)
    return number
  is
  begin
    return hrm_functions.getTaxForPeriodOnly(grec_person.HRM_PERSON_ID, hrm_date.ActivePeriod, amount);
  end;

  function getTaxASRectifTax
    return number
  is
  begin
    return hrm_functions.getTaxASRectifTax(grec_person.HRM_PERSON_ID);
  end getTaxASRectifTax;

  function getTaxASRectifEarning
    return number
  is
  begin
    return hrm_functions.getTaxASRectifEarning(grec_person.HRM_PERSON_ID);
  end getTaxASRectifEarning;

  function getTaxASRectifAscertainEarning
    return number
  is
  begin
    return hrm_functions.getTaxASRectifAscertainEarning(grec_person.HRM_PERSON_ID);
  end getTaxASRectifAscertainEarning;

  function getTaxCode
    return varchar2
  is
  begin
    return hrm_functions.getTaxCode(grec_person.HRM_PERSON_ID, hrm_date.ActivePeriod);
  end;

  function xmlValue(vTag in varchar2)
    return varchar2
  is
  begin
    return hrm_xml.xmlValue(grec_person.HRM_PERSON_ID, vTag);
  end;

  function FreeBoolean(vCode in varchar2)
    return varchar2
  is
  begin
    return hrm_functions.get_BooleanCode(grec_person.HRM_PERSON_ID, vCode);
  end;

  function FreeChar(vCode in varchar2)
    return varchar2
  is
  begin
    return hrm_functions.get_CharCode(grec_person.HRM_PERSON_ID, vCode);
  end;

  function FreeDate(vCode in varchar2)
    return varchar2
  is
  begin
    return hrm_functions.get_DateCode(grec_person.HRM_PERSON_ID, vCode);
  end;

  function FreeNumber(vCode in varchar2)
    return varchar2
  is
  begin
    return hrm_functions.get_NumberCode(grec_person.HRM_PERSON_ID, vCode);
  end;

  function get_ActivePeriodBeginDate
    return date
  is
  begin
    return hrm_date.activePeriod;
  end;

  function get_ActivePeriodEndDate
    return date
  is
  begin
    return hrm_date.activePeriodEndDate;
  end;

  function get_DaysInPeriod
    return integer
  is
  begin
    --  return to_number(to_char(hrm_date.activeperiodenddate,'dd'));
    -- Calcul compatible pour le calcul des décomptes et le calcul du budget
    return hrm_date.activeperiodenddate - hrm_date.activeperiod + 1;
  end;

-- Contract fonctions
  function ValidateBeginContractDate(
    BeginDate  in date
  , InOutId    in hrm_in_out.hrm_in_out_id%type
  , ContractId in hrm_contract.hrm_contract_id%type
  , PersonId   in hrm_person.hrm_person_id%type
  )
    return date
  is
    ld_result date;
  begin
    --Date du parent (entrée / sortie)
    select case
             when BeginDate between INO_IN and INO_OUT then BeginDate
             when BeginDate > INO_OUT then INO_OUT
             when BeginDate < INO_IN then INO_IN
           end
      into ld_result
      from HRM_IN_OUT INO
     where INO.HRM_IN_OUT_ID = InOutId;

/*  -- La plus petite date de début supérieure (MinInBeginDate)
  -- La plus grande date de début inférieur (MaxEndDate)
  select Max(CON_BEGIN)-1, Min(CON_END)+1
  into MinBeginDate, MaxEndDate
  from HRM_CONTRACT
  where HRM_EMPLOYEE_ID = PersonId and
    HRM_IN_OUT_ID = InOutId and
    HRM_CONTRACT_ID != ContractId and
    CON_BEGIN <= BeginDate and
    (CON_END >= BeginDate or CON_END is null);

  if (MaxEndDate is null) then
    if (MinBeginDate is null or MinBeginDate > BeginDate) then
      return BeginDate;
    else
      return MinBeginDate;
    end if;
  else
    return MaxEndDate;
  end if;
*/
    return ld_result;
  exception
    when others then
      return null;
  end;

  function ValidateEndContractDate(
    EndDate    in date
  , InOutId    in hrm_in_out.hrm_in_out_id%type
  , ContractId in hrm_contract.hrm_contract_id%type
  , PersonId   in hrm_person.hrm_person_id%type
  )
    return date
  is
    ld_result date;
  begin
    select case
             when EndDate between INO_IN and INO_OUT then EndDate
             when EndDate > INO_OUT then INO_OUT
             when EndDate < INO_IN then INO_IN
           end
      into ld_result
      from HRM_IN_OUT INO
     where INO.HRM_IN_OUT_ID = InOutId;

/*  -- La plus grande date de sortie inférieur
  select min(CON_BEGIN)-1
  into MaxEndDate
  from HRM_CONTRACT
  where HRM_EMPLOYEE_ID = PersonId and
    HRM_IN_OUT_ID = InOutId and
    HRM_CONTRACT_ID != ContractId and
    (CON_BEGIN <= EndDate or EndDate is null) and
    (CON_END > EndDate or CON_END is null);

  if (MaxEndDate is null or MaxEndDate > EndDate) then
    return EndDate;
  else
    return MaxEndDate;
  end if;
*/
    return ld_result;
  exception
    when others then
      return null;
  end;

-- In/Out fonctions
  procedure ValidateInDate(
    InDate     in out nocopy date
  , InOutId    in            hrm_in_out.hrm_in_out_id%type
  , PersonId   in            hrm_person.hrm_person_id%type
  , HistoryErr out nocopy    integer
  )
  is
    MaxOutDate   date;
    MinInDate    date;
    MinHistoDate date;
    PrevOutDate  date;
  begin
    HistoryErr  := 0;

    -- La plus petite date d'entrée supérieure (MinInDate)
    -- La plus grande date de sortie inférieur (MaxOutDate)
    select max(INO_IN) - 1
         , min(INO_OUT) + 1
      into MinInDate
         , MaxOutDate
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = PersonId
       and HRM_IN_OUT_ID != InOutId
       and C_IN_OUT_CATEGORY = '3'
       and INO_IN <= InDate
       and (   INO_OUT >= InDate
            or INO_OUT is null);

    -- La sortie précédente
    select trunc(max(INO_OUT), 'MM')
      into PrevOutDate
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = PersonId
       and C_IN_OUT_CATEGORY = '3'
       and INO_OUT < InDate;

    -- Date du premier décompte inférieur
    select trunc(min(HIT_PAY_PERIOD), 'MM')
      into MinHistoDate
      from HRM_HISTORY H
     where HRM_EMPLOYEE_ID = PersonId
       and trunc(HIT_PAY_PERIOD, 'MM') < trunc(Indate, 'MM')
       and (   trunc(HIT_PAY_PERIOD, 'MM') > PrevOutDate
            or PrevOutDate is null)
       and not exists(
             select 1
               from HRM_IN_OUT
              where HRM_EMPLOYEE_ID = PersonId
                and HRM_IN_OUT_ID != InOutId
                and C_IN_OUT_CATEGORY = '3'
                and (    (trunc(H.HIT_PAY_PERIOD, 'MM') between trunc(INO_IN, 'MM') and trunc(INO_OUT, 'MM') )
                     or (    INO_OUT is null
                         and trunc(INO_IN, 'MM') <= trunc(H.HIT_PAY_PERIOD, 'MM') )
                    ) );

    if (MaxOutDate is null) then
      if (   MinInDate is null
          or MinInDate > InDate) then
        if (   MinHistoDate is null
            or MinHistoDate > InDate) then
          InDate  := InDate;
        else
          HistoryErr  := 1;   -- Pas de problèmes de chevauchement, mais incohérence avec décomptes
          InDate      := MinHistoDate;
        end if;
      else
        InDate  := MinInDate;
      end if;
    else
      InDate  := MaxOutDate;
    end if;
  exception
    when others then
      InDate  := null;
  end;

  procedure ValidateOutDate(
    OutDate    in out nocopy date
  , InOutId    in            hrm_in_out.hrm_in_out_id%type
  , PersonId   in            hrm_person.hrm_person_id%type
  , HistoryErr out nocopy    integer
  )
  is
    NextInDate   date;
    MaxOutDate   date;
    MaxHistoDate date;
  begin
    HistoryErr  := 0;

    -- La plus grande date de sortie inférieur
    select min(INO_IN) - 1
      into MaxOutDate
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = PersonId
       and HRM_IN_OUT_ID != InOutId
       and C_IN_OUT_CATEGORY = '3'
       and (   INO_IN <= OutDate
            or OutDate is null)
       and (   INO_OUT > OutDate
            or INO_OUT is null);

    -- La prochaine entrée
    select trunc(min(INO_IN), 'MM')
      into NextInDate
      from HRM_IN_OUT io
     where HRM_EMPLOYEE_ID = PersonId
       and C_IN_OUT_CATEGORY = '3'
       and INO_IN > OutDate;

    -- Date du dernier décompte supérieur non compris dans un interval
    select last_day(max(HIT_PAY_PERIOD) )
      into MaxHistoDate
      from HRM_HISTORY H
     where HRM_EMPLOYEE_ID = PersonId
       and trunc(HIT_PAY_PERIOD, 'MM') > trunc(OutDate, 'MM')
       and (   trunc(HIT_PAY_PERIOD, 'MM') < NextInDate
            or NextInDate is null)
       and not exists(
             select 1
               from HRM_IN_OUT
              where HRM_EMPLOYEE_ID = PersonId
                and HRM_IN_OUT_ID != InOutId
                and C_IN_OUT_CATEGORY = '3'
                and (    (trunc(H.HIT_PAY_PERIOD, 'MM') between trunc(INO_IN, 'MM') and trunc(INO_OUT, 'MM') )
                     or (    INO_OUT is null
                         and trunc(INO_IN, 'MM') <= trunc(H.HIT_PAY_PERIOD, 'MM') )
                    ) );

    if (   MaxOutDate is null
        or MaxOutDate > OutDate) then
      if (   MaxHistoDate is null
          or MaxHistoDate < OutDate) then
        OutDate  := OutDate;
      else
        HistoryErr  := 1;   -- Pas de problèmes de chevauchement, mais incohérence avec décomptes
        OutDate     := MaxHistoDate;
      end if;
    else
      OutDate  := MaxOutDate;
    end if;
  exception
    when others then
      OutDate  := null;
  end;

  function VerifyYearEntry(PersonId in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select count(*)
      into ln_result
      from HRM_IN_OUT
     where HRM_EMPLOYEE_ID = PersonId
       and C_IN_OUT_CATEGORY = '3'
       and trunc(INO_OUT, 'MM') >= hrm_date.BeginOfYear;

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function ValidatePermitDate(
    idFromDate   in date
  , idToDate     in date
  , inPersonId   in HRM_EMPLOYEE_WK_PERMIT.HRM_PERSON_ID%type
  , inWkPermitId in HRM_EMPLOYEE_WK_PERMIT.HRM_EMPLOYEE_WK_PERMIT_ID%type default null
  )
    return integer
  is
    ln_result integer;
    ld_maxdate date;
  begin
    select to_date('31129999', 'DDMMYYYY')
      into ld_maxdate
      from dual;

    select count(*)
      into ln_result
      from HRM_EMPLOYEE_WK_PERMIT P
     where HRM_PERSON_ID = inPersonId
       and (   inWkPermitId is null
            or HRM_EMPLOYEE_WK_PERMIT_ID <> inWkPermitId)
       and (    (    nvl(WOP_VALID_TO, ld_maxdate) >= idFromDate
                 and WOP_VALID_FROM <= idFromDate)
            or (    nvl(WOP_VALID_TO, ld_maxdate) >= idFromDate
                and WOP_VALID_FROM <= nvl(idToDate, ld_maxdate))
            or (    nvl(WOP_VALID_TO, ld_maxdate) >= idFromDate
                and nvl(WOP_VALID_TO, ld_maxdate) <= nvl(idToDate, ld_maxdate))
           );

    return ln_result;
  exception
    when no_data_found then
      return 0;
  end;

  function exchangeRate(vCurrency in pcs.pc_curr.currency%type, vType in integer)
    return number
  is
  begin
    return hrm_var.exchangeRate(vCurrency, vType);
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

  function get_EstabName
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabName(grec_person.HRM_PERSON_ID);
  end;

  function get_EstabAddress
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabAddress(grec_person.HRM_PERSON_ID);
  end;

  function get_EstabZipCity
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabZipCity(grec_person.HRM_PERSON_ID);
  end;

  function get_EstabUrssaf
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabUrssaf(grec_person.HRM_PERSON_ID);
  end;

  function get_EstabSiren
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabSiren(grec_person.HRM_PERSON_ID);
  end;

  function get_EstabCanton
    return varchar2
  is
  begin
    return hrm_functions.EmplEstabCanton(grec_person.HRM_PERSON_ID);
  end;
end HRM_PERSON_DATA;
