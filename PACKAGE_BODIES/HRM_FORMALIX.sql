--------------------------------------------------------
--  DDL for Package Body HRM_FORMALIX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_FORMALIX" 
/**
 * Fonctions de génération du fichier pour Formalix (IS Genève)
 *
 * @version 1.0
 * @date 07/2006
 * @author ireber
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  -- Définition des infos lié à la société
  TYPE TCompany IS RECORD (
    NoIdent VARCHAR2(5),
    Activity VARCHAR2(2),
    City VARCHAR2(10),
    State VARCHAR2(2),
    RemiseDate DATE);
  -- Définition des informations nécessaire pour générer le document
  TYPE TFormalixParamData IS RECORD (
    ListId hrm_control_list.hrm_control_list_id%TYPE, -- Identifiant de la liste de contrôle
    PeriodFrom DATE,
    PeriodTo DATE,
    Company TCompany);

  -- Format pour les dates et les heures
  DATE_FORMAT CONSTANT VARCHAR2(10) := 'DD.MM.YYYY';
  -- Format pour les nombres
  NUMBER_FORMAT CONSTANT VARCHAR2(13) := 'FM99999990.00';
  NUMBER_FORMAT_INT CONSTANT VARCHAR2(10) := 'FM99999990';
  -- Séparateur de ligne
  SEP_LINE CONSTANT VARCHAR2(1) := CHR(10);
  -- Séparateur de champs
  SEP_FIELD CONSTANT VARCHAR2(1) := ';';

  -- Constante de l'en-tête du fichier
  HEADER_FORMULAR_VERSION CONSTANT VARCHAR2(50) :=
    'Attestation_quittance.jar;1.3.0;2005-09-20';

  -- Colonnes de la société
  HEADER_COL_COMPANY CONSTANT VARCHAR2(2000) :=
    'common/employeur/employ/no_identification;'||
    'common/employeur/employ/code_act;'||
    'common/employeur/employ/nom;'||
    'common/adrsse_empl/adresse_employeur/rue;'||
    'common/adrsse_empl/adresse_employeur/no;'||
    'common/adrsse_empl/adresse_employeur/CP;'||
    'common/adrsse_empl/adresse_employeur/NPA;'||
    'common/adrsse_empl/adresse_employeur/canton;'||
    'common/adrsse_empl/adresse_employeur/localiteemp;'||
    'common/adrsse_empl/adresse_employeur/localite2;'||
    'common/assuj_employ/assujetissement_employeur/annee;'||
    'common/assuj_employ/assujetissement_employeur/debut;'||
    'common/assuj_employ/assujetissement_employeur/fin;'||
    'common/assuj_employ/assujetissement_employeur/remise';

  -- Colonnes par employés
  HEADER_COL_EMPLOYEES CONSTANT VARCHAR2(4000) :=
    'contribuable/contrib/numero_avs;'||
    'contribuable/contrib/nom;'||
    'contribuable/contrib/prenom;'||
    'contribuable/contrib/date_naissance;'||
    'contribuable/contrib/sexe;'||
    'contribuable/contrib/etat_civil;'||
    'contribuable/contrib/concubinage;'||
    'contribuable/contrib/confession;'||
    'contribuable/contrib/trouver_no_avs;'||
    'famille/conjoint/nom;'||
    'famille/conjoint/prenom;'||
    'famille/conjoint/travaille_suisse;'||
    'famille/enfants/nb_enf;'||
    'famille/enfants/naissance1;'||
    'famille/enfants/naissance2;'||
    'famille/enfants/naissance3;'||
    'famille/enfants/naissance4;'||
    'famille/enfants/naissance5;'||
    'domicile/adresse_domicile/rue;'||
    'domicile/adresse_domicile/no;'||
    'domicile/adresse_domicile/CP;'||
    'domicile/adresse_domicile/NPA;'||
    'domicile/adresse_domicile/pays_canton;'||
    'domicile/adresse_domicile/localite;'||
    'domicile/adresse_domicile/localite2;'||
    'activite_prof/type_travail/type_contribuable;'||
    'activite_prof/type_travail/cat_prof;'||
    'activite_prof/lieu_travail/localite;'||
    'assujetissement/periode/du;'||
    'assujetissement/periode/au;'||
    'assujetissement/assujet/nb_travail;'||
    'assujetissement/assujet/nb_abs;'||
    'assujetissement/assujet/taux;'||
    'assujetissement/assujet/bareme;'||
    'retenue/prestations/soumises_impots;'||
    'retenue/prestations/en_capital;'||
    'retenue/prestations/allocations;'||
    'retenue/prestations/frais;'||
    'retenue/retenues/impots_retenus;'||
    'retenue/retenues/cont_eccl;'||
    'retenue/retenues/retenue_tot';

  FormalixParam TFormalixParamData;

  function Generate(pNoIdent IN VARCHAR2, pActivity IN VARCHAR2, pCity IN VARCHAR2, pState IN VARCHAR2,
                    pRemiseDate IN DATE, pPeriodFrom IN DATE, pPeriodTo IN DATE,
                    pListId IN hrm_control_list.hrm_control_list_id%TYPE) return CLOB
  is
    Result CLOB;
  begin
    FormalixParam.Company.NoIdent := pNoIdent;
    FormalixParam.Company.Activity := pActivity;
    FormalixParam.Company.City := pCity;
    FormalixParam.Company.State := pState;
    FormalixParam.Company.RemiseDate := pRemiseDate;
    FormalixParam.ListId := pListId;
    FormalixParam.PeriodFrom := pPeriodFrom;
    FormalixParam.PeriodTo := pPeriodTo;

    Result :=
      HEADER_FORMULAR_VERSION ||SEP_LINE||
      HEADER_COL_COMPANY ||SEP_LINE||
      GetCompany ||SEP_LINE||
      HEADER_COL_EMPLOYEES || -- SEP_LINE|| déja ajouté via GetEmployees
      GetEmployees;
    return Result;
  end;

  function GetCompany return VARCHAR2
  is
    Result VARCHAR2(4000);
  begin
    SELECT
      FormalixParam.Company.NoIdent ||SEP_FIELD||
      FormalixParam.Company.Activity ||SEP_FIELD||
      C.COM_SOCIALNAME ||SEP_FIELD||
      C.COM_ADR ||SEP_FIELD||
      '' ||SEP_FIELD|| -- NO
      '' ||SEP_FIELD|| -- CP
      C.COM_ZIP ||SEP_FIELD||
      FormalixParam.Company.State ||SEP_FIELD||
      case when FormalixParam.Company.State = 'GE' then FormalixParam.Company.City end ||SEP_FIELD||
      case when FormalixParam.Company.State <> 'GE' then COM_CITY end ||SEP_FIELD||
      to_char(HRM_FORMALIX.FormalixParam.PeriodFrom, 'YYYY') ||SEP_FIELD||
      HRM_FORMALIX.Format(FormalixParam.PeriodFrom) ||SEP_FIELD||
      HRM_FORMALIX.Format(FormalixParam.PeriodTo) ||SEP_FIELD||
      HRM_FORMALIX.Format(FormalixParam.Company.RemiseDate)
    INTO Result
    FROM PCS.PC_COMP C
    WHERE PC_COMP_ID = PCS.PC_PUBLIC.GetCompanyId;

    return Result;

    exception
      when NO_DATA_FOUND then
        return null;
  end;

  function GetEmployees return CLOB
  is
    cursor csEmployee
    is
      SELECT
        V.HRM_EMPLOYEE_ID,
        P.EMP_SOCIAL_SECURITYNO NOAVS,
        P.PER_LAST_NAME,
        P.PER_FIRST_NAME,
        P.PER_BIRTH_DATE,
        P.PER_GENDER,
        P.C_CIVIL_STATUS,
        P.C_HRM_GE_COHABITATION,
        P.C_HRM_GE_RELIGION,
        REPLACE(REPLACE(P.PER_HOMESTREET,CHR(10), ', '), CHR(13), ', ') PER_HOMESTREET,
        '' NO,
        '' CP,
        P.PER_HOMEPOSTALCODE,
        P.C_HRM_GE_HOMESTATE,
        case when P.C_HRM_GE_HOMESTATE = 'GE' then P.C_HRM_GE_HOMECITY end GE_HOMECITY,
        case when P.C_HRM_GE_HOMESTATE <> 'GE' then P.PER_HOMECITY end OTHER_HOMECITY,
        P.C_HRM_GE_TAXPAYER,
        P.C_HRM_GE_PROF_CAT,
        P.C_HRM_GE_WORKCITY,
        V.Val30_NbJTrav,
        V.Val37_NbJAbs,
        V.Val32_IsCode,
        V.Val32a_IsRate,
        trunc(V.Val33_Soum) Val33_Soum,
        trunc(V.Val33a_Capital) Val33a_Capital,
        trunc(V.Val33b_Alloc) Val33b_Alloc,
        trunc(V.Val36_Frais) Val36_Frais,
        V.Val34_Impot Val34_Impot,
        V.Val35_Eccl Val35_Eccl
      FROM
        HRM_PERSON p,
        (
        SELECT
          hc.hrm_employee_id,
          sum(case when l.coe_Box = '30'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val30_NbJTrav,
          --max(case when l.coe_Box = '32a' then h.HIS_PAY_SUM_VAL end) Val32a_IsRate,
          substr(max(case when l.coe_Box = '32a' then (to_char(hc.his_pay_num,'FM000')||to_char(h.HIS_PAY_SUM_VAL)) end),4) Val32a_IsRate, -- Uniqu. la dernière valeur
          sum(case when l.coe_Box = '33'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val33_Soum,
          sum(case when l.coe_Box = '33a' then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val33a_Capital,
          sum(case when l.coe_Box = '33b' then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val33b_Alloc,
          sum(case when l.coe_Box = '34'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val34_Impot,
          sum(case when l.coe_Box = '35'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val35_Eccl,
          sum(case when l.coe_Box = '36'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val36_Frais,
          sum(case when l.coe_Box = '37'  then h.HIS_PAY_SUM_VAL * (case when l.coe_inverse = 0 then 1 else -1 end) end) Val37_NbJAbs,
          --max(hc.his_pay_value) Val32_IsCode -- [A VOIR] Prendre uniqu. la dernière valeur =! MAX !!!
          substr(max(case when l.coe_Box = '32' then (to_char(h.his_pay_num,'FM000')||h.his_pay_value) end),4) Val32_IsCode -- Prendre uniqu. la dernière valeur
        FROM
          hrm_history_detail h,   -- historique des valeurs
          hrm_control_elements l, -- éléments pour différentes valeurs
          hrm_history_detail hc,  -- historique du CodeIs
          hrm_control_elements lc  -- élément corresp. au CodeIs
        WHERE
          h.his_pay_num = hc.his_pay_num and
          h.hrm_employee_id = hc.hrm_employee_id and
          h.hrm_elements_id = l.hrm_control_elements_id and
          l.hrm_control_list_id = lc.hrm_control_list_id and
          hc.hrm_elements_id = lc.hrm_control_elements_id and
          lc.coe_box = '32' and instr(replace(hc.his_pay_value, '"'), 'GE') = 1 and
          hc.his_definitive = 1 and
          hc.his_pay_period between FormalixParam.PeriodFrom and FormalixParam.PeriodTo and
          lc.hrm_control_list_Id = FormalixParam.ListId
        GROUP BY
          hc.hrm_employee_id
      ) V
      WHERE P.HRM_PERSON_ID = V.HRM_EMPLOYEE_ID
      ORDER BY P.PER_SEARCH_NAME;

    Result CLOB;
    vLine VARCHAR2(4000);
  begin
    for aEmployee in csEmployee
    loop
      vLine :=
          -- Common
          aEmployee.NOAVS ||SEP_FIELD||
          aEmployee.PER_LAST_NAME ||SEP_FIELD||
          aEmployee.PER_FIRST_NAME ||SEP_FIELD||
          Format(aEmployee.PER_BIRTH_DATE) ||SEP_FIELD||
          decodeSex(aEmployee.PER_GENDER) ||SEP_FIELD||
          decodeCivilStatus(aEmployee.C_CIVIL_STATUS) ||SEP_FIELD||
          aEmployee.C_HRM_GE_COHABITATION ||SEP_FIELD||
          aEmployee.C_HRM_GE_RELIGION ||SEP_FIELD||
          '' ||SEP_FIELD|| -- 'Trouver no AVS' à laisser libre
          -- Family
          GetFamily(aEmployee.HRM_EMPLOYEE_ID) ||SEP_FIELD||
          -- Domicile
          aEmployee.PER_HOMESTREET ||SEP_FIELD||
          aEmployee.NO ||SEP_FIELD||
          aEmployee.CP ||SEP_FIELD||
          aEmployee.PER_HOMEPOSTALCODE ||SEP_FIELD||
          aEmployee.C_HRM_GE_HOMESTATE ||SEP_FIELD||
          aEmployee.GE_HOMECITY ||SEP_FIELD||
          aEmployee.OTHER_HOMECITY ||SEP_FIELD||
          aEmployee.C_HRM_GE_TAXPAYER ||SEP_FIELD||
          aEmployee.C_HRM_GE_PROF_CAT ||SEP_FIELD||
          aEmployee.C_HRM_GE_WORKCITY ||SEP_FIELD||
          -- Assujettissement
          GetInOut(aEmployee.HRM_EMPLOYEE_ID)  ||SEP_FIELD||
          to_char(aEmployee.Val30_NbJTrav) ||SEP_FIELD||
          to_char(aEmployee.Val37_NbJAbs) ||SEP_FIELD||
          to_char(aEmployee.Val32a_IsRate) ||SEP_FIELD||
          decodeIsBareme(aEmployee.Val32_IsCode) ||SEP_FIELD||
          -- Prestations
          FormatInt(aEmployee.Val33_Soum) ||SEP_FIELD||
          FormatInt(aEmployee.Val33a_Capital) ||SEP_FIELD||
          FormatInt(aEmployee.Val33b_Alloc) ||SEP_FIELD||
          FormatInt(aEmployee.Val36_Frais) ||SEP_FIELD||
          -- Retenues
          Format(aEmployee.Val34_Impot) ||SEP_FIELD||
          Format(aEmployee.Val35_Eccl) ||SEP_FIELD||
          Format(aEmployee.Val34_Impot + aEmployee.Val35_Eccl);
      Result := Result||SEP_LINE||vLine;
    end loop;
    return Result;
  end;

  -- FirstIn et LastOut in period
  function GetInOut(vEmpId NUMBER) return VARCHAR2
  is
    DateIn DATE;
    DateOut DATE;
  begin
    select
      Min(IO.INO_IN),
      Max(Nvl(IO.INO_OUT, FormalixParam.PeriodTo))
    into DateIn, DateOut
    from
      HRM_IN_OUT IO
    where
      HRM_EMPLOYEE_ID = vEmpId and C_IN_OUT_CATEGORY = '3' and
      INO_IN <= FormalixParam.PeriodTo and
      ((INO_OUT is null) or (INO_OUT >= FormalixParam.PeriodFrom));

    if DateIn < FormalixParam.PeriodFrom then
      DateIn := FormalixParam.PeriodFrom;
    end if;
    if DateOut > FormalixParam.PeriodTo then
      DateOut := FormalixParam.PeriodTo;
    end if;

    return Format(DateIn) ||SEP_FIELD|| Format(DateOut);

    exception
      when NO_DATA_FOUND then
        return ''||SEP_FIELD||'';
  end;

  function GetFamily(vEmpId NUMBER) return VARCHAR2
  is

    cursor csChildren(pEmpId NUMBER)
    is
      SELECT REL_BIRTH_YEAR
      FROM(
	       SELECT TO_CHAR(REL_BIRTH_DATE, 'YYYY') REL_BIRTH_YEAR
	       FROM HRM_RELATED_TO r
	       WHERE HRM_EMPLOYEE_ID = pEmpId AND
                 C_RELATED_TO_TYPE = '2' AND
	         REL_IS_DEPENDANT = 1 AND
	         HRM_FUNCTIONS.AgeInGivenYear(FormalixParam.PeriodFrom, REL_BIRTH_DATE) < 18
		     ORDER BY REL_BIRTH_YEAR)
      WHERE ROWNUM < 6;

    nbChild NUMBER;
    Result VARCHAR2(4000);

  begin
    -- Conjoint
    begin
      SELECT
        REL_NAME ||SEP_FIELD||
        REL_FIRST_NAME ||SEP_FIELD||
        case when dic_canton_work_id in (
            'GE','VD','VS','AG','AI','AR','BL','BS','BE','FR',
            'GL','GR','LU','JU','NE','NW','OW','SG','SH','SZ',
            'SO','TG','TI','UR','ZG','ZH') then '1' else '0' end
      INTO Result
      FROM HRM_RELATED_TO r
      WHERE C_RELATED_TO_TYPE = '1' AND
        HRM_EMPLOYEE_ID = vEmpId;

      exception
        when NO_DATA_FOUND then
          Result := ''||SEP_FIELD||''||SEP_FIELD;
    end;

    -- Nombre d'enfants
    SELECT COUNT(*) into nbChild
    FROM HRM_RELATED_TO r
    WHERE C_RELATED_TO_TYPE = '2' AND
          REL_IS_DEPENDANT = 1 AND
      HRM_FUNCTIONS.AgeInGivenYear(FormalixParam.PeriodFrom, REL_BIRTH_DATE) < 18 AND
      HRM_EMPLOYEE_ID = vEmpId;

    Result := Result ||SEP_FIELD|| TO_CHAR(nbChild);

    -- Années de naissance des 5 premiers (= 5 plus jeunes enfants)
    if nbChild > 0 then
      for aChildren in csChildren(vEmpId)
      loop
        Result := Result ||SEP_FIELD|| aChildren.REL_BIRTH_YEAR;
      end loop;
    end if;
    -- Compléter avec des séparateurs en fct du nb d'enfants
    if nbChild < 5 then
      Result := Result || RPAD (SEP_FIELD, 5-nbChild, SEP_FIELD);
    end if;

    return Result;
  end;

  function decodeCivilStatus(pCivil_status IN hrm_person.c_civil_status%TYPE) return VARCHAR2
  is
  begin
    return
      case pCivil_status
        when 'Cel' then '1' -- Célibataire
        when 'Mar' then '2' -- Marié(e)
        when 'Div' then '3' -- Divorcé(e)
        when 'Sep' then '4' -- Séparé(e)
        when 'Veu' then '5' -- Veuf(ve)
        else ''
      end;
  end;

  function decodeSex(pSex IN hrm_person.per_gender%TYPE) return VARCHAR2
  is
  begin
    return
      case pSex
        when 'M' then '1' -- Masculin
        when 'F' then '2' -- Féminin
        else ''
      end;
  end;

  function decodeIsBareme(pIsCode IN VARCHAR2) return VARCHAR2
  is
  begin
    return
      case replace(pIsCode, '"')
        when 'GEA'   then '1'
        when 'GEB'   then '2'
        when 'GEB1'  then '3'
        when 'GEB2'  then '4'
        when 'GEB3'  then '5'
        when 'GEB4'  then '6'
        when 'GEB5'  then '7'
        when 'GEB6'  then '8'
        when 'GEB7'  then '9'
        when 'GEB8'  then '10'
        when 'GEB9'  then '11'
        when 'GEB10' then '12'
        when 'GEB11' then '13'
        when 'GEB12' then '14'
        when 'GEB13' then '15'
        when 'GEB14' then '16'
        when 'GEB15' then '17'
        when 'GEI'   then '18'
        when 'GEI1'  then '19'
        when 'GEI2'  then '20'
        when 'GEI3'  then '21'
        when 'GEI4'  then '22'
        when 'GEI5'  then '23'
        when 'GEI6'  then '24'
        when 'GEI7'  then '25'
        when 'GEI8'  then '26'
        when 'GED'   then '27'
        else ''
      end;
  end;

  function Format(D IN DATE) return VARCHAR2
  is
  begin
    return to_char(D, DATE_FORMAT);
  end;

  function Format(N IN NUMBER) return VARCHAR2
  is
  begin
    return to_char(nvl(N,0), NUMBER_FORMAT);
  end;

  function FormatInt(N IN NUMBER) return VARCHAR2
  is
  begin
    return to_char(nvl(N,0), NUMBER_FORMAT_INT);
  end;

END HRM_FORMALIX;
