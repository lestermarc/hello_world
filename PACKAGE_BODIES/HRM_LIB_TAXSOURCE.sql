--------------------------------------------------------
--  DDL for Package Body HRM_LIB_TAXSOURCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_LIB_TAXSOURCE" 
as
  /**
  * procedure IsTaxCodeValid
  * description :
  *    Indique si la liste d�di�e � l'imp�t � la source est d�finie correctement
  */
  function IsTaxCodeValid(iTaxCode in varchar2, iCivilStatus in varchar2, iPermit in varchar2, iCountry in varchar2)
    return pls_integer
  is
    lnResult pls_integer := 0;
  begin
    --RA('IsTaxCodeValid - iTaxCode = ' || iTaxCode);
    -- Bar�mes autoris�s pour les non-mari�s
    if     iTaxCode in('A', 'D', 'L', 'O', 'P', 'H')
       and iCivilStatus in('Cel', 'Sep', 'Veu', 'Div', 'Cnc', 'Pab', 'Pde', 'Pdi') then
      lnResult  := 1;
    -- Bar�mes autoris�s pour les mari�s
    elsif     iTaxCode in('B', 'C', 'D', 'F', 'M', 'N')
          and iCivilStatus in('Mar', 'Pen') then
      lnResult  := 1;
    end if;

    -- Interdiction aux non permis G d'avoir les bar�mes sp�ciaux
    if     iPermit <> 'G'
       and iTaxCode in('F', 'L', 'M', 'N', 'O', 'P') then
      lnResult  := 0;
    end if;

    -- Interdiction d'avoir les bar�mes de vrais frontaliers pour les personnes non domicili�es en Allemagne
    if     nvl(HRM_COUNTRY_FCT.GetCountryCode(iCountry), 'CH') <> 'DE'
       and iTaxCode in('L', 'M', 'N', 'O', 'P') then
      lnResult  := 0;
    -- Interdiction d'avoir le bar�me F pour les personnes domicili�es en Suisse
    elsif     iTaxCode = 'F'
          and nvl(HRM_COUNTRY_FCT.GetCountryCode(iCountry), 'CH') = 'CH' then
      lnResult  := 0;
    end if;

    return lnResult;
  end IsTaxCodeValid;

  /**
  * function CheckEmployeeTaxSource
  * Description
  *   Contr�le des d�finitions d'imp�ts � la source d'un employ�
  */
  function CheckEmployeeTaxSource(iPersonID in HRM_PERSON.HRM_PERSON_ID%type, iEmplTaxSourceID in HRM_EMPLOYEE_TAXSOURCE.HRM_EMPLOYEE_TAXSOURCE_ID%type)
    return varchar2
  is
    lvResult varchar2(1000) := '';
    lnExists integer;
  begin
    -- Contr�le des donn�es du conjoint
    select sign(count(*) )
      into lnExists
      from HRM_PERSON PER
     where PER.PER_IS_EMPLOYEE = 1
       and PER.HRM_PERSON_ID = iPersonID
       and PER.C_CIVIL_STATUS in('Mar', 'Pen')
       and not exists(select 1
                        from HRM_RELATED_TO REL
                       where REL.HRM_EMPLOYEE_ID = PER.HRM_PERSON_ID);

    if lnExists = 1 then
      lvResult  := lvResult || PCS.PC_FUNCTIONS.TranslateWord('Donn�es du conjoint manquantes') || '.' || chr(10);
    end if;

    -- Contr�le du bar�me
    select sign(count(*) )
      into lnExists
      from HRM_EMPLOYEE_TAXSOURCE TAX
         , HRM_PERSON PER
     where PER.HRM_PERSON_ID = iPersonID
       and PER.PER_IS_EMPLOYEE = 1
       and TAX.HRM_PERSON_ID = PER.HRM_PERSON_ID
       and TAX.HRM_EMPLOYEE_TAXSOURCE_ID = iEmplTaxSourceID
       and (    ( (case
                     when TAX.EMT_VALUE is null then 0
                     else 1
                   end + case
                     when TAX.EMT_VALUE_SPECIAL is null then 0
                     else 1
                   end + case
                     when TAX.C_HRM_IS_CAT is null then 0
                     else 1
                   end) <> 1
                )
            or (     (TAX.EMT_VALUE is not null)
                and HRM_LIB_TAXSOURCE.IsTaxCodeValid(substr(TAX.EMT_VALUE, 3, 1)
                                                   , PER.C_CIVIL_STATUS
                                                   , GetEmployeePermit(PER.HRM_PERSON_ID, TAX.EMT_FROM)
                                                   , PER.PER_HOMECOUNTRY
                                                    ) = 0
               )
           );

    if lnExists = 1 then
      lvResult  := lvResult || PCS.PC_FUNCTIONS.TranslateWord('Bar�me invalide') || '.' || chr(10);
    end if;

    -- Contr�le de la commune OFS
    select sign(count(*) )
      into lnExists
      from HRM_EMPLOYEE_TAXSOURCE TAX
     where TAX.HRM_EMPLOYEE_TAXSOURCE_ID = iEmplTaxSourceID
       and TAX.PC_OFS_CITY_ID <> GetEmployeeOFSCityByAdress(iPersonID);

    if lnExists = 1 then
      select sign(count(*) )
        into lnExists
        from HRM_PERSON PER
       where PER.HRM_PERSON_ID = iPersonID
         and hrm_country_fct.SearchCountryCode(PER.PER_HOMECOUNTRY) = 'CH';

      if lnExists = 1 then
        lvResult  := lvResult || PCS.PC_FUNCTIONS.TranslateWord('La commune OFS ne correspond pas au code postal du domicile de l''employ�') || '.' || chr(10);
      else
        lvResult  := lvResult || PCS.PC_FUNCTIONS.TranslateWord('La commune OFS ne correspond pas au code postal de l''�tablissement') || '.' || chr(10);
      end if;
    end if;

    return lvResult;
  end CheckEmployeeTaxSource;

  /**
  * function GetEmployeePermit
  * Description
  *   Recherche le permis de travail d'un employ� en fonction d'une date
  */
  function GetEmployeePermit(iPersonID in HRM_PERSON.HRM_PERSON_ID%type, iDate in date)
    return HRM_EMPLOYEE_WK_PERMIT.DIC_WORK_PERMIT_ID%type
  is
    lvPermit HRM_EMPLOYEE_WK_PERMIT.DIC_WORK_PERMIT_ID%type;
  begin
    -- Recherche du permis dans la p�riode "Valable du" et "Valable au"
    select DIC_WORK_PERMIT_ID
      into lvPermit
      from HRM_EMPLOYEE_WK_PERMIT
     where HRM_PERSON_ID = iPersonID
       and iDate between WOP_VALID_FROM and nvl(WOP_VALID_TO, iDate);

    return lvPermit;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      raise_application_error(-20000, pcs.pc_public.translateword('L''employ� a plusieurs permis valables pour la p�riode'));
  end GetEmployeePermit;

  /**
  * function GetEmployeeOFSCityByAdress
  * Description
  *   Recherche la commune ofs en fonction du domicile de la personne pour une personne
  *   vivant en suisse, sinon donne la commune de l'�tablissement de l'ES active
  */
  function GetEmployeeOFSCityByAdress(iPersonID in HRM_PERSON.HRM_PERSON_ID%type)
    return HRM_EMPLOYEE_TAXSOURCE.PC_OFS_CITY_ID%type
  is
    lvCity HRM_EMPLOYEE_TAXSOURCE.PC_OFS_CITY_ID%type;
  begin
    select case
             -- Si la personne vit en Suisse
           when hrm_country_fct.SearchCountryCode(PER.PER_HOMECOUNTRY) = 'CH' then (select max(OFS.PC_OFS_CITY_ID)
                                                                                      from PCS.PC_OFS_CITY OFS
                                                                                     where ',' || trim(OFS.OFS_RELATED_ZIP) || ',' like
                                                                                                                     '%,' || trim(PER.PER_HOMEPOSTALCODE)
                                                                                                                     || ',%')
             -- sinon on se base sur la commune de l'�tablissement de l'E/S active
           else (select EST.PC_OFS_CITY_ID
                   from HRM_IN_OUT INO
                      , HRM_ESTABLISHMENT EST
                  where INO.HRM_EMPLOYEE_ID = iPersonID
                    and EST.HRM_ESTABLISHMENT_ID = INO.HRM_ESTABLISHMENT_ID
                    and C_IN_OUT_STATUS = 'ACT')
           end PC_OFS_CITY_ID
      into lvCity
      from HRM_PERSON PER
     where PER.HRM_PERSON_ID = iPersonID;

    return lvCity;
  exception
    when no_data_found then
      return null;
    when too_many_rows then
      return null;
  end;

  /**
  * function GetPreviousCanton
  * Description
  *   Recherche du canton de la periode d'assujettissement imm�diatement pr�c�dente en fonction du d�but actuel
  *   (date de d�but = date de fin pr�c�dente + 1)
  * @public
  * @param iPersonID : Personne
  * @param iDate     : Date d�but period assujettissement
  * @Return Canton
  */
  function GetPreviousCanton(iPersonID in HRM_PERSON.HRM_PERSON_ID%type, iDate in HRM_EMPLOYEE_TAXSOURCE.EMT_FROM%type)
    return HRM_EMPLOYEE_TAXSOURCE.EMT_CANTON%type
  is
    lvCanton HRM_EMPLOYEE_TAXSOURCE.EMT_CANTON%type;
  begin
    select EMT_CANTON
      into lvCanton
      from HRM_EMPLOYEE_TAXSOURCE
     where HRM_PERSON_ID = iPersonID
       and iDate - 1 = EMT_TO;

    return lvCanton;
  exception
    when no_data_found then
      return null;
    when too_many_rows then   -- Ne devrait pas arriver, y a un ctrl de chevauchement
      return null;
  end GetPreviousCanton;

  /**
  * function HasActiveTaxSource
  * description :
  *    Indique si l'utilisateur � une p�riode d'assujetissement valable dans la periode active.
  * @created rba 05.12.2014
  * @public
  * @return 0 : aucune p�riode d'assujetissement valable
  *         1 : p�riode d'assujetissement valable existante
  */
  function HasActiveTaxSource(iPersonID in HRM_PERSON.HRM_PERSON_ID%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from HRM_EMPLOYEE_TAXSOURCE
     where HRM_PERSON_ID = iPersonID
       and EMT_FROM <= hrm_date.ActivePeriodEndDate
       and (   EMT_TO is null
            or EMT_TO >= hrm_date.ActivePeriod);

    return lnResult;
  end HasActiveTaxSource;

  /**
  * function HasTaxSourceEndedPeriod
  *    Recherche si l'utilisateur a une p�riode d'assujetissement termin�e pour une date de sortie donn�e
  * @return 0 : aucune p�riode d'assujetissement trouv�e
  *         1 : p�riode d'assujetissement ouverte existante
  */
  function HasTaxSourceEndedPeriod(iPersonID in HRM_PERSON.HRM_PERSON_ID%type, iInoOutDate HRM_IN_OUT.INO_OUT%type)
    return integer
  is
    vResult integer;
  begin
    select sign(count(1) )
      into vResult
      from HRM_EMPLOYEE_TAXSOURCE
     where HRM_PERSON_ID = iPersonId
       and nvl(EMT_TO, iInoOutDate) > iInoOutDate;

    return vResult;
  end HasTaxSourceEndedPeriod;
end HRM_LIB_TAXSOURCE;
