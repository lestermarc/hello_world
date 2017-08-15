--------------------------------------------------------
--  DDL for Package Body HRM_PRC_ELM_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_ELM_IMPORT" 
/**
 * Package pour importation de données d'une assurance LPP.
 *
 * @version 1.0
 * @date 08/2011
 * @author rhermann
 * @author spfister
 */
is
  gcv_ns       constant varchar2(232)
    :=   -- 76 + 72 + 84
      'xmlns="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer"' ||
      ' xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"' ||
      ' xmlns:ns3="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes"';
  gcv_ns2      constant varchar2(71)  := 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"';
  gcd_value_to constant date          := to_date('31.12.2050', 'dd.mm.yyyy');

/**
 * Procédure de mise à jour de la valeur de la constante de l'employé.
 * @param in_person_id Identifiant de l'employé.
 * @param in_elements_id Identifiant de l'élément de calcul.
 * @param in_elements_type Type d'élément à traiter :
 *                         o 1: Montant
 *                         o 2: Code soumission.
 * @param id_begin Date de début de validité.
 * @param iv_value Valeur à utiliser.
 */
  procedure p_merge_employee_elements(
    in_person_id     in hrm_person.hrm_person_id%type
  , in_elements_id   in hrm_elements.hrm_elements_id%type
  , in_elements_type in binary_integer
  , id_begin         in date
  , iv_value         in varchar2
  )
  is
    ln_employee_const_id hrm_employee_const.hrm_employee_const_id%type   := null;
    ln_code_table_id     hrm_code_table.hrm_code_table_id%type;
  begin
    if (    in_elements_id is not null
        and iv_value is not null
        and id_begin is not null) then
      -- vérification de l'existance de la constante
      begin
        select HRM_EMPLOYEE_CONST_ID
          into ln_employee_const_id
          from HRM_EMPLOYEE_CONST
         where HRM_EMPLOYEE_ID = in_person_id
           and EMC_ACTIVE = 1
           and HRM_CONSTANTS_ID = in_elements_id
           and id_begin between emc_value_from and emc_value_to;
      exception
        when no_data_found then
          null;
      end;

      -- Mise à jour des montants
      if (in_elements_type = 1) then
        if (ln_employee_const_id is not null) then
          update HRM_EMPLOYEE_CONST
             set EMC_NUM_VALUE = trunc(to_number(iv_value), 2)
               , EMC_VALUE_TO = gcd_value_to
           where HRM_EMPLOYEE_CONST_ID = ln_employee_const_id;
        else
          insert into HRM_EMPLOYEE_CONST
                      (HRM_EMPLOYEE_CONST_ID
                     , HRM_EMPLOYEE_ID
                     , HRM_CONSTANTS_ID
                     , EMC_FROM
                     , EMC_TO
                     , EMC_ACTIVE
                     , A_DATECRE
                     , A_IDCRE
                     , EMC_VALUE_FROM
                     , EMC_VALUE_TO
                     , EMC_NUM_VALUE
                      )
               values (hrm_employee_elements_seq.nextval
                     , in_person_id
                     , in_elements_id
                     , id_begin
                     , gcd_value_to
                     , 1
                     , sysdate
                     , 'ELM'
                     , id_begin
                     , gcd_value_to
                     , trunc(to_number(iv_value), 2)
                      );
        end if;
      -- Mise à jour des codes soumission
      elsif(in_elements_type = 2) then
        begin
          select HRM_CODE_TABLE_ID
            into ln_code_table_id
            from HRM_CODE_TABLE
           where HRM_CODE_DIC_ID = (select HRM_CODE_DIC_ID
                                      from HRM_CONSTANTS
                                     where HRM_CONSTANTS_ID = in_elements_id)
             and COD_CODE = iv_value;
        exception
          when no_data_found then
            raise_application_error(-20000, 'Code not found in dictionary :' || iv_value);
        end;

        if (ln_employee_const_id is not null) then
          update HRM_EMPLOYEE_CONST
             set HRM_CODE_TABLE_ID = ln_code_table_id
               , EMC_VALUE_TO = gcd_value_to
           where HRM_EMPLOYEE_CONST_ID = ln_employee_const_id;
        else
          insert into HRM_EMPLOYEE_CONST
                      (HRM_EMPLOYEE_CONST_ID
                     , HRM_EMPLOYEE_ID
                     , HRM_CONSTANTS_ID
                     , EMC_FROM
                     , EMC_TO
                     , EMC_ACTIVE
                     , A_DATECRE
                     , A_IDCRE
                     , EMC_VALUE_FROM
                     , EMC_VALUE_TO
                     , HRM_CODE_TABLE_ID
                      )
               values (hrm_employee_elements_seq.nextval
                     , in_person_id
                     , in_elements_id
                     , id_begin
                     , gcd_value_to
                     , 1
                     , sysdate
                     , 'ELM'
                     , id_begin
                     , gcd_value_to
                     , ln_code_table_id
                      );
        end if;
      end if;
    end if;
  end;

--
-- Public methods
--
  procedure create_table_codes(in_recipient_id in hrm_elm_recipient.hrm_elm_recipient_id%type)
  is
    l_table_id hrm_code_table.hrm_code_table_id%type;
  begin
    for tpl_codes in (select HRM_CONTROL_LIST_ID
                           , extractvalue(column_value, '//ns2:BVG-LPP-Code', gcv_ns2) CODE
                           , extractvalue(column_value, '//ns2:Description', gcv_ns2) DESCRIPTION
                        from HRM_ELM_RECIPIENT
                           , table(xmlsequence(extract(xmltype(ELM_LPP_RESPONSE_XML), '//CodeDescriptions/*', gcv_ns) ) ) P
                       where HRM_ELM_RECIPIENT_ID = in_recipient_id) loop
      for tpl_dico in (select R.HRM_CODE_DIC_ID
                         from HRM_CONTROL_ELEMENTS CE
                            , HRM_ELEMENTS_ROOT R
                        where hrm_control_list_id = tpl_codes.HRM_CONTROL_LIST_ID
                          and COE_BOX in('CODE', 'CODE2')
                          and R.HRM_ELEMENTS_ID = CE.HRM_CONTROL_ELEMENTS_ID) loop
        insert into HRM_CODE_TABLE
                    (HRM_CODE_TABLE_ID
                   , HRM_CODE_DIC_ID
                   , COD_CODE
                   , COD_DEFAULT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , tpl_dico.HRM_CODE_DIC_ID
               , tpl_codes.CODE
               , 0
               , sysdate
               , 'ELM'
            from dual
           where not exists(select 1
                              from HRM_CODE_TABLE
                             where COD_CODE = tpl_codes.CODE
                               and HRM_CODE_DIC_ID = tpl_dico.HRM_CODE_DIC_ID);

        insert into HRM_CODE_DESCR
                    (HRM_CODE_TABLE_ID
                   , PC_LANG_ID
                   , COD_DESCR
                   , A_DATECRE
                   , A_IDCRE
                    )
          select T.HRM_CODE_TABLE_ID
               , L.PC_LANG_ID
               , tpl_codes.DESCRIPTION
               , sysdate
               , 'ELM'
            from PCS.PC_LANG L
               , HRM_CODE_TABLE T
           where LANUSED = 1
             and T.HRM_CODE_DIC_ID = tpl_dico.HRM_CODE_DIC_ID
             and not exists(select 1
                              from HRM_CODE_DESCR
                             where PC_LANG_ID = L.PC_LANG_ID
                               and HRM_CODE_TABLE_ID = T.HRM_CODE_TABLE_ID);
      end loop;
    end loop;
  end;

  procedure import_contributions(in_recipient_id in hrm_elm_recipient.hrm_elm_recipient_id%type)
  is
    ln_person_id   hrm_person.hrm_person_id%type;
    l_code_1       hrm_control_elements.hrm_control_elements_id%type;
    l_code_2       hrm_control_elements.hrm_control_elements_id%type;
    l_empl_cont_1  hrm_control_elements.hrm_control_elements_id%type;
    l_empl_cont_2  hrm_control_elements.hrm_control_elements_id%type;
    l_pat_cont_1   hrm_control_elements.hrm_control_elements_id%type;
    l_pat_cont_2   hrm_control_elements.hrm_control_elements_id%type;
    l_third_cont_1 hrm_control_elements.hrm_control_elements_id%type;
    l_third_cont_2 hrm_control_elements.hrm_control_elements_id%type;
    lv_status      hrm_person.emp_status%type;
    ld_std_valid   varchar2(10);
  begin
    begin
      -- Recherche des constantes liées aux positionnements nécessaires
      select (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'CODE')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'CODE2')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'EMPLOYEE')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'EMPLOYEE2')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'EMPLOYER')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'EMPLOYER2')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'THIRD')
           , (select HRM_CONTROL_ELEMENTS_ID
                from HRM_CONTROL_ELEMENTS
               where HRM_CONTROL_LIST_ID = R.HRM_CONTROL_LIST_ID
                 and COE_BOX = 'THIRD2')
        into l_code_1
           , l_code_2
           , l_empl_cont_1
           , l_empl_cont_2
           , l_pat_cont_1
           , l_pat_cont_2
           , l_third_cont_1
           , l_third_cont_2
        from hrm_elm_recipient r
       where hrm_elm_recipient_id = in_recipient_id;
    exception
      when too_many_rows then
        raise_application_error(-20000,   --'Several identical positions found for CODE/CODE2/EMPLOYEE/EMPLOYEE2/EMPLOYER/EMPLOYER2/THIRD/THIRD2');
                                'Several identical positions found for CODE, EMPLOYEE, EMPLOYER, THIRD');
      when no_data_found then
        raise_application_error(-20000, 'No list defined');
    end;

    -- Vérifications pour ne pas engendrer de dysfonctionnements
    if (nvl(l_code_1, -1) = nvl(l_code_2, -1) ) then
      raise_application_error(-20000, pcs.pc_functions.translateword('Les positions CODE et CODE2 ne peuvent pas faire référence à la même constante') );
    elsif(nvl(l_empl_cont_1, -1) = nvl(l_empl_cont_2, -1) ) then
      raise_application_error(-20000, pcs.pc_functions.translateword('Les positions EMPLOYEE et EMPLOYEE2 ne peuvent pas faire référence à la même constante') );
    elsif nvl(l_pat_cont_1, -1) = nvl(l_pat_cont_2, -1) then
      raise_application_error(-20000, pcs.pc_functions.translateword('Les positions EMPLOYER et EMPLOYER2 ne peuvent pas faire référence à la même constante') );
--  elsif (Nvl(l_third_cont_1,-1) = Nvl(l_third_cont_2,-1)) then
--    raise_application_error(-20000,
--      pcs.pc_functions.translateword('Les positions THIRD et THIRD2 ne peuvent pas faire référence à la même constante'));
    elsif(nvl(l_third_cont_1, -1) = nvl(l_pat_cont_1, -2) ) then
      raise_application_error(-20000, pcs.pc_functions.translateword('Les positions EMPLOYER et THIRD ne peuvent pas faire référence à la même constante') );
    end if;

    -- Date de validité générale
    select extractvalue(xmltype(ELM_LPP_RESPONSE_XML), '//ns2:GeneralValidAsOf', gcv_ns2)
      into ld_std_valid
      from HRM_ELM_RECIPIENT
     where HRM_ELM_RECIPIENT_ID = in_recipient_id;

    -- Boucle sur les éléments du fragment xml de réponse de l'assurance
    for tpl_Contribution in
      (select nvl(extractvalue(column_value, '//ns2:SV-AS-Number', gcv_ns2), extractvalue(column_value, '//ns2:AHV-AVS-Number', gcv_ns2) ) NO_AVS
            , extractvalue(column_value, '//ns2:Firstname', gcv_ns2) FIRST_NAME
            , extractvalue(column_value, '//ns2:Lastname', gcv_ns2) LAST_NAME
            , extractvalue(column_value, '//ns2:DateOfBirth', gcv_ns2) BIRTH_DATE
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][1]/ns2:BVG-LPP-Code', gcv_ns2) CODE1
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][2]/ns2:BVG-LPP-Code', gcv_ns2) CODE2
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][1]/ns2:ValidAsOf', gcv_ns2) VALID1
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][2]/ns2:ValidAsOf', gcv_ns2) VALID2
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][1]/ns2:EmployeeContribution', gcv_ns2) EMPLOYEE_CONTRIBUTION1
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][2]/ns2:EmployeeContribution', gcv_ns2) EMPLOYEE_CONTRIBUTION2
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][1]/ns2:EmployerContribution', gcv_ns2) EMPLOYER_CONTRIBUTION1
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][2]/ns2:EmployerContribution', gcv_ns2) EMPLOYER_CONTRIBUTION2
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][1]/ns2:ThirdPartyContribution', gcv_ns2)
                                                                                                                                      THIRD_PARTY_CONTRIBUTION1
            , extractvalue(column_value, '//ns2:Contributions/ns2:Contribution[not(ns2:Unknown)][2]/ns2:ThirdPartyContribution', gcv_ns2)
                                                                                                                                      THIRD_PARTY_CONTRIBUTION2
         from table(xmlsequence(extract( (select xmltype(ELM_LPP_RESPONSE_XML)
                                            from HRM_ELM_RECIPIENT
                                           where HRM_ELM_RECIPIENT_ID = in_recipient_id), '//ns2:Identified/ns2:Person', gcv_ns) ) ) P) loop
      ln_person_id  := null;

      begin
        select HRM_PERSON_ID
             , emp_status
          into ln_person_id
             , lv_status
          from HRM_PERSON
         where tpl_Contribution.NO_AVS = EMP_SOCIAL_SECURITYNO2;
      exception
        when no_data_found then
          null;
      end;

      if (ln_person_id is null) then
        begin
          select HRM_PERSON_ID
               , emp_status
            into ln_person_id
               , lv_status
            from HRM_PERSON
           where upper(tpl_Contribution.FIRST_NAME) = upper(PER_FIRST_NAME)
             and upper(tpl_Contribution.LAST_NAME) = upper(PER_LAST_NAME)
             and hrm_lib_elm.ToDate(tpl_Contribution.BIRTH_DATE) = PER_BIRTH_DATE
             and PER_IS_EMPLOYEE = 1;
        exception
          when too_many_rows then
            raise_application_error(-20000
                                  , 'Several ' || tpl_Contribution.FIRST_NAME || ' ' || tpl_Contribution.LAST_NAME || ' ' || tpl_Contribution.BIRTH_DATE
                                    || ' found'
                                   );
          when no_data_found then
            raise_application_error(-20000
                                  , tpl_Contribution.FIRST_NAME || ' ' || tpl_Contribution.LAST_NAME || ' ' || tpl_Contribution.BIRTH_DATE || ' not found'
                                   );
        end;
      end if;

      if lv_status in('ACT', 'SUS') then
        p_merge_employee_elements(ln_person_id, l_code_1, 2, hrm_date.activeperiod, tpl_Contribution.CODE1);
        p_merge_employee_elements(ln_person_id, l_code_2, 2, hrm_date.activeperiod, tpl_Contribution.CODE2);
        p_merge_employee_elements(ln_person_id
                                , l_empl_cont_1
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID1, ld_std_valid) )
                                , tpl_Contribution.EMPLOYEE_CONTRIBUTION1 / 12
                                 );
        p_merge_employee_elements(ln_person_id
                                , l_empl_cont_2
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID2, ld_std_valid) )
                                , tpl_Contribution.EMPLOYEE_CONTRIBUTION2 / 12
                                 );
        p_merge_employee_elements(ln_person_id
                                , l_pat_cont_1
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID1, ld_std_valid) )
                                , tpl_Contribution.EMPLOYER_CONTRIBUTION1 / 12
                                 );
        p_merge_employee_elements(ln_person_id
                                , l_pat_cont_2
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID2, ld_std_valid) )
                                , tpl_Contribution.EMPLOYER_CONTRIBUTION2 / 12
                                 );
        p_merge_employee_elements(ln_person_id
                                , l_third_cont_1
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID1, ld_std_valid) )
                                , tpl_Contribution.THIRD_PARTY_CONTRIBUTION1 / 12
                                 );
        p_merge_employee_elements(ln_person_id
                                , l_third_cont_2
                                , 1
                                , hrm_lib_elm.ToDate(nvl(tpl_Contribution.VALID2, ld_std_valid) )
                                , tpl_Contribution.THIRD_PARTY_CONTRIBUTION2 / 12
                                 );
      end if;
    end loop;
  end;
end HRM_PRC_ELM_IMPORT;
