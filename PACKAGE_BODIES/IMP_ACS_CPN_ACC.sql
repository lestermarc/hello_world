--------------------------------------------------------
--  DDL for Package Body IMP_ACS_CPN_ACC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_ACS_CPN_ACC" 
as
  lcDomain constant varchar2(15) := 'ACS_CPN';
  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_ACS_CPN_ACCOUNT. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_ACS_CPN_ACCOUNT(
    pACC_NUMBER                    varchar2
  , pDES_DESCRIPTION_SUMMARY_1     varchar2
  , pACS_ACCOUNT_PP                varchar2
  , pACC_DETAIL_PRINTING           varchar2
  , pACC_BLOCKED                   varchar2
  , pACC_BUDGET                    varchar2
  , pC_CDA_IMPUTATION              varchar2
  , pC_PF_IMPUTATION               varchar2
  , pC_PJ_IMPUTATION               varchar2
  , pDES_DESCRIPTION_LARGE_1       varchar2
  , pDES_DESCRIPTION_SUMMARY_2     varchar2
  , pDES_DESCRIPTION_LARGE_2       varchar2
  , pDES_DESCRIPTION_SUMMARY_3     varchar2
  , pDES_DESCRIPTION_LARGE_3       varchar2
  , pFREE1                         varchar2
  , pFREE2                         varchar2
  , pFREE3                         varchar2
  , pFREE4                         varchar2
  , pFREE5                         varchar2
  , pFREE6                         varchar2
  , pFREE7                         varchar2
  , pFREE8                         varchar2
  , pFREE9                         varchar2
  , pFREE10                        varchar2
  , pEXCEL_LINE                    integer
  , pRESULT                    out integer
  )
  is
  begin
    --Insertion dans la table IMP_ACS_CPN_ACCOUNT
    insert into IMP_ACS_CPN_ACCOUNT
                (ID
               , EXCEL_LINE
               , ACS_ACCOUNT_ID
               , ACC_NUMBER
               , ACS_ACCOUNT_PP
               , DES_DESCRIPTION_SUMMARY_1
               , ACC_DETAIL_PRINTING
               , ACC_BLOCKED
               , ACC_BUDGET
               , C_CDA_IMPUTATION
               , C_PF_IMPUTATION
               , C_PJ_IMPUTATION
               , DES_DESCRIPTION_LARGE_1
               , DES_DESCRIPTION_SUMMARY_2
               , DES_DESCRIPTION_LARGE_2
               , DES_DESCRIPTION_SUMMARY_3
               , DES_DESCRIPTION_LARGE_3
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , FREE6
               , FREE7
               , FREE8
               , FREE9
               , FREE10
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , GetNewId
               , trim(pACC_NUMBER)
               , trim(pACS_ACCOUNT_PP)
               , trim(pDES_DESCRIPTION_SUMMARY_1)
               , trim(pACC_DETAIL_PRINTING)
               , trim(pACC_BLOCKED)
               , trim(pACC_BUDGET)
               , trim(pC_CDA_IMPUTATION)
               , trim(pC_PF_IMPUTATION)
               , trim(pC_PJ_IMPUTATION)
               , trim(pDES_DESCRIPTION_LARGE_1)
               , trim(pDES_DESCRIPTION_SUMMARY_2)
               , trim(pDES_DESCRIPTION_LARGE_2)
               , trim(pDES_DESCRIPTION_SUMMARY_3)
               , trim(pDES_DESCRIPTION_LARGE_3)
               , trim(pFREE1)
               , trim(pFREE2)
               , trim(pFREE3)
               , trim(pFREE4)
               , trim(pFREE5)
               , trim(pFREE6)
               , trim(pFREE7)
               , trim(pFREE8)
               , trim(pFREE9)
               , trim(pFREE10)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;
  end IMP_TMP_ACS_CPN_ACCOUNT;

  /**
  * Description
  *    Contrôle des données de la table IMP_ACS_CPN_ACCOUNT_CTRL avant importation.
  */
  procedure IMP_ACS_CPN_ACCOUNT_CTRL
  is
    tmp       varchar2(200);
    tmp_int   integer;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Contrôle de l'existence des langues 'FR', 'GE' et 'EN' dans l'ERP
    IMP_PRC_TOOLS.checkLanguage('FR', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('GE', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('EN', lcDomain, 0, '-');

    --Parcours de toutes les lignes de la table IMP_ACS_FINAICAL_ACCOUNT
    for tdata in (select *
                    from IMP_ACS_CPN_ACCOUNT) loop
--******************************************************************
    --Est-ce qu'il n'a pas de doublon dans les compte CPN
    --et est-ce que tous les enregistrements ont une compte CPN ?
    --******************************************************************
      select count(acc_number)
        into tmp_int
        from IMP_ACS_CPN_ACCOUNT
       where acc_number = tdata.acc_number;

      --Si on a plus d'un enregistrement avec la même numéro d'compte
      if (tmp_int > 1) then
        --Création d'une erreur
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER'));
      end if;

      --Si on a pas d'enregistrement
      if (tmp_int = 0) then
        --Pas de rnuméro d'compte !
        --Création d'une erreur
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER_2'));
      end if;

--*******************************************************
    --Est-ce que un compta analytique exists
    --*******************************************************
      begin
        select acs_accounting.c_type_accounting
          into tmp
          from acs_accounting
         where c_type_accounting = 'MAN';
      exception
        when no_data_found then
          --Création d'une erreur
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_ACCOUNTING'));
      end;

--*******************************************************
    --Est-ce que une type de sous-enmsemble exists
    --*******************************************************
      begin
        select acs_sub_set.c_type_sub_set
          into tmp
          from acs_sub_set
         where c_type_sub_set = 'NAT';
      exception
        when no_data_found then
          --Création d'une erreur
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_SUB_SET'));
      end;

--*******************************************************
    --Est-ce que une sous-enmsemble exists
    --*******************************************************
      begin
        select acs_sub_set.c_sub_set
          into tmp
          from acs_sub_set
         where c_sub_set = 'CPN';
      exception
        when no_data_found then
          --Création d'une erreur
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_SUB_SET'));
      end;

--*******************************************************
    --Est-ce que tous les champs obligatoires sont présents ?
    --*******************************************************
      if (   tdata.ACC_NUMBER is null
          or tdata.DES_DESCRIPTION_SUMMARY_1 is null
          or tdata.ACC_DETAIL_PRINTING is null
          or tdata.ACC_BLOCKED is null
          or tdata.ACC_BUDGET is null
          or tdata.C_CDA_IMPUTATION is null
          or tdata.C_PF_IMPUTATION is null
          or tdata.C_PJ_IMPUTATION is null
         ) then
        --Création d'une erreur
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED'));
      else
        /********************************************************
        * --> Est-ce que le booléen Impression détaillée est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('ACC_DETAIL_PRINTING', nvl(tdata.ACC_DETAIL_PRINTING, '1'), lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le booléen Imputation non autorisée est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('ACC_BLOCKED', nvl(tdata.ACC_BLOCKED, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le booléen Budget non autorisé est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('ACC_BUDGET', nvl(tdata.ACC_BUDGET, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le centre d'analyse est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_CDA_IMPUTATION', tdata.C_CDA_IMPUTATION, '{1,2,3}', lcDomain, tdata.ID, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le porteur est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_PF_IMPUTATION', tdata.C_PF_IMPUTATION, '{1,2,3}', lcDomain, tdata.ID, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le projet est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_PJ_IMPUTATION', tdata.C_PJ_IMPUTATION, '{1,2,3}', lcDomain, tdata.ID, tdata.EXCEL_LINE);

        --> Est-ce que le compte PP existe dans l'ERP ?
        select count(*)
          into tmp_int
          from dual
         where exists(select fin.ACS_FINANCIAL_ACCOUNT_ID
                        from ACS_FINANCIAL_ACCOUNT fin
                           , ACS_ACCOUNT acc
                       where fin.ACS_FINANCIAL_ACCOUNT_ID = acc.ACS_ACCOUNT_ID
                         and acc.ACC_NUMBER = tdata.ACS_ACCOUNT_PP);

        if tmp_int = 0 then   -- Le compte PP doit exister !
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_ACS_ACCOUNT_PP') );
        end if;

--*******************************************************
   --Est-ce que le comptes CPN existe déjà dans les tables de l'ERP ?
   --*******************************************************
        begin
          select acs_cpn_account_id
            into tmp_int
            from acs_cpn_account
               , acs_account
           where acc_number = tdata.acc_number
             and acs_cpn_account.acs_cpn_account_id = acs_account.acs_account_id;

          --Création d'une erreur
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER_3'));
        exception
          when no_data_found then
            null;
        end;

--*******************************************************
    --Est-ce que la monnais local existe?
    --*******************************************************
        begin
          select acs_financial_currency_id
            into tmp_int
            from acs_financial_currency
           where fin_local_currency = 1;
        exception
          when no_data_found then
            --Création d'une erreur
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACS_FINANCIAL_CURRENCY_LOCAL'));
        end;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_ACS_CPN_ACCOUNT_CTRL;

  /**
  * Description
  *    Importation des données des comptes
  */
  procedure IMP_ACS_CPN_ACCOUNT_IMPORT
  is
    tmp integer;
    L1  varchar2(10);
    L2  varchar2(10);
    L3  varchar2(10);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_ACS_CPN_ACCOUNT) loop
      tmp := GetNewId;

      --Insertion des données dans les tables !
      insert into ACS_ACCOUNT
                  (ACS_ACCOUNT_ID
                 , ACS_SUB_SET_ID
                 , ACC_NUMBER
                 , C_VALID
                 , ACC_DETAIL_PRINTING
                 , ACC_BLOCKED
                 , ACC_BUDGET
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (tmp
                 , (select ACS_SUB_SET_ID
                      from ACS_SUB_SET
                     where C_TYPE_SUB_SET = 'NAT')
                 , tdata.ACC_NUMBER
                 , 'VAL'
                 , nvl(tdata.ACC_DETAIL_PRINTING, 1)
                 , nvl(tdata.ACC_BLOCKED, 0)
                 , nvl(tdata.ACC_BUDGET, 1)
                 , IMP_LIB_TOOLS.getImportUserIni
                 , sysdate
                  );

      --select acs_cpn_account_id into tmp from acs_account;
      insert into ACS_CPN_ACCOUNT
                  (ACS_CPN_ACCOUNT_ID
                 , C_CDA_IMPUTATION
                 , C_PF_IMPUTATION
                 , C_PJ_IMPUTATION
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (tmp
                 , tdata.c_cda_imputation
                 , tdata.c_pf_imputation
                 , tdata.c_pj_imputation
                 , IMP_LIB_TOOLS.getImportUserIni
                 , sysdate
                  );

      update ACS_FINANCIAL_ACCOUNT FIN
         set FIN.ACS_CPN_ACCOUNT_ID = tmp
       where exists(select 1
                      from ACS_ACCOUNT ACS
                     where ACS.ACC_NUMBER = tdata.acs_account_pp
                       and FIN.acs_financial_account_id = acs.acs_account_id);

      insert into ACS_CPN_ACCOUNT_CURRENCY
                  (ACS_CPN_ACCOUNT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                  )
           values (tmp
                 , (select acs_financial_currency_id
                      from acs_financial_currency
                     where fin_local_currency = 1)
                  );

      --Correspondance des langues (L1, L2, L3) entre Excel et ProConcept
         --L1 = langue de la société
         --L2 = seconde langue
         --L3 = troisième langue
      select c.PC_LANG_ID
        into L1
        from pcs.PC_COMP c
           , pcs.PC_SCRIP s
       where c.PC_SCRIP_ID = s.PC_SCRIP_ID
         and s.SCRDBOWNER = (select COM_CURRENTSCHEMA
                               from dual);

      case L1
        when '1' then
          L2  := '2';
          L3  := '3';
        when '2' then
          L2  := '1';
          L3  := '3';
        when '3' then
          L2  := '1';
          L3  := '2';
      end case;

      --Insertion des descriptions langue 1 s'il y en a
      if (   tdata.DES_DESCRIPTION_SUMMARY_1 is not null
          or tdata.DES_DESCRIPTION_LARGE_1 is not null) then
        insert into ACS_DESCRIPTION
                    (ACS_DESCRIPTION_ID
                   , ACS_ACCOUNT_ID
                   , PC_LANG_ID
                   , DES_DESCRIPTION_SUMMARY
                   , DES_DESCRIPTION_LARGE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tmp
                   , L1
                   , tdata.DES_DESCRIPTION_SUMMARY_1
                   , tdata.DES_DESCRIPTION_LARGE_1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des descriptions 2 s'il y en a
      if (   tdata.DES_DESCRIPTION_SUMMARY_2 is not null
          or tdata.DES_DESCRIPTION_LARGE_2 is not null) then
        insert into ACS_DESCRIPTION
                    (ACS_DESCRIPTION_ID
                   , ACS_ACCOUNT_ID
                   , PC_LANG_ID
                   , DES_DESCRIPTION_SUMMARY
                   , DES_DESCRIPTION_LARGE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tmp
                   , L2
                   , tdata.DES_DESCRIPTION_SUMMARY_2
                   , tdata.DES_DESCRIPTION_LARGE_2
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des descriptions 3 s'il y en a
      if (   tdata.DES_DESCRIPTION_SUMMARY_3 is not null
          or tdata.DES_DESCRIPTION_LARGE_3 is not null) then
        insert into ACS_DESCRIPTION
                    (ACS_DESCRIPTION_ID
                   , ACS_ACCOUNT_ID
                   , PC_LANG_ID
                   , DES_DESCRIPTION_SUMMARY
                   , DES_DESCRIPTION_LARGE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tmp
                   , L3
                   , tdata.DES_DESCRIPTION_SUMMARY_3
                   , tdata.DES_DESCRIPTION_LARGE_3
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion dans historique
      insert into IMP_HIST_ACS_CPN_ACCOUNT
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , ACS_ACCOUNT_ID
                 , ACC_NUMBER
                 , ACS_ACCOUNT_PP
                 , DES_DESCRIPTION_SUMMARY_1
                 , ACC_DETAIL_PRINTING
                 , ACC_BLOCKED
                 , ACC_BUDGET
                 , C_CDA_IMPUTATION
                 , C_PF_IMPUTATION
                 , C_PJ_IMPUTATION
                 , DES_DESCRIPTION_LARGE_1
                 , DES_DESCRIPTION_SUMMARY_2
                 , DES_DESCRIPTION_LARGE_2
                 , DES_DESCRIPTION_SUMMARY_3
                 , DES_DESCRIPTION_LARGE_3
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , FREE6
                 , FREE7
                 , FREE8
                 , FREE9
                 , FREE10
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetnewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tmp
                 , tdata.ACC_NUMBER
                 , tdata.ACS_ACCOUNT_PP
                 , tdata.DES_DESCRIPTION_SUMMARY_1
                 , tdata.ACC_DETAIL_PRINTING
                 , tdata.ACC_BLOCKED
                 , tdata.ACC_BUDGET
                 , tdata.C_CDA_IMPUTATION
                 , tdata.C_PF_IMPUTATION
                 , tdata.C_PJ_IMPUTATION
                 , tdata.DES_DESCRIPTION_LARGE_1
                 , tdata.DES_DESCRIPTION_SUMMARY_2
                 , tdata.DES_DESCRIPTION_LARGE_2
                 , tdata.DES_DESCRIPTION_SUMMARY_3
                 , tdata.DES_DESCRIPTION_LARGE_3
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , tdata.FREE6
                 , tdata.FREE7
                 , tdata.FREE8
                 , tdata.FREE9
                 , tdata.FREE10
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_ACS_CPN_ACCOUNT_IMPORT;
end IMP_ACS_CPN_ACC;
