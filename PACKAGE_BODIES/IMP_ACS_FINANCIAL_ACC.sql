--------------------------------------------------------
--  DDL for Package Body IMP_ACS_FINANCIAL_ACC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_ACS_FINANCIAL_ACC" 
as
  lcDomain constant varchar2(15) := 'ACS';

  /**
  * procedure IMP_TMP_ACS_FINANCIAL_ACCOUNT
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_ACS_FINANCIAL_ACCOUNT. Cette procédure est appelée depuis Excel
  * @created Team QI
  * @lastUpdate
  * @public
  */
  procedure IMP_TMP_ACS_FINANCIAL_ACCOUNT(
    pACC_NUMBER                      varchar2
  , pDES_DESCRIPTION_SUMMARY_1       varchar2
  , pSSE_CPN_FIN                     varchar2
  , pACC_DETAIL_PRINTING             varchar2
  , pACC_BLOCKED                     varchar2
  , pACC_BUDGET                      varchar2
  , pC_BALANCE_SHEET_PROFIT_LOSS     varchar2
  , pC_BALANCE_DISPLAY               varchar2
  , pFIN_COLLECTIVE                  varchar2
  , pFIN_VAT_POSSIBLE                varchar2
  , pFIN_LIQUIDITY                   varchar2
  , pDES_DESCRIPTION_LARGE_1         varchar2
  , pDES_DESCRIPTION_SUMMARY_2       varchar2
  , pDES_DESCRIPTION_LARGE_2         varchar2
  , pDES_DESCRIPTION_SUMMARY_3       varchar2
  , pDES_DESCRIPTION_LARGE_3         varchar2
  , pACS_FINANCIAL_CURRENCY_ID       varchar2
  , pFREE1                           varchar2
  , pFREE2                           varchar2
  , pFREE3                           varchar2
  , pFREE4                           varchar2
  , pFREE5                           varchar2
  , pFREE6                           varchar2
  , pFREE7                           varchar2
  , pFREE8                           varchar2
  , pFREE9                           varchar2
  , pFREE10                          varchar2
  , pEXCEL_LINE                      integer
  , pRESULT                      out integer
  )
  is
  begin
    --Insertion dans la table IMP_ACS_FINANCIAL_ACCOUNT
    insert into IMP_ACS_FINANCIAL_ACCOUNT
                (id
               , EXCEL_LINE
               , ACS_ACCOUNT_ID
               , ACC_NUMBER
               , DES_DESCRIPTION_SUMMARY_1
               , SSE_CPN_FIN
               , ACC_DETAIL_PRINTING
               , ACC_BLOCKED
               , ACC_BUDGET
               , C_BALANCE_SHEET_PROFIT_LOSS
               , C_BALANCE_DISPLAY
               , FIN_COLLECTIVE
               , FIN_VAT_POSSIBLE
               , FIN_LIQUIDITY
               , DES_DESCRIPTION_LARGE_1
               , DES_DESCRIPTION_SUMMARY_2
               , DES_DESCRIPTION_LARGE_2
               , DES_DESCRIPTION_SUMMARY_3
               , DES_DESCRIPTION_LARGE_3
               , ACS_FINANCIAL_CURRENCY_ID
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
               , trim(pDES_DESCRIPTION_SUMMARY_1)
               , trim(pSSE_CPN_FIN)
               , trim(pACC_DETAIL_PRINTING)
               , trim(pACC_BLOCKED)
               , trim(pACC_BUDGET)
               , trim(pC_BALANCE_SHEET_PROFIT_LOSS)
               , trim(pC_BALANCE_DISPLAY)
               , trim(pFIN_COLLECTIVE)
               , trim(pFIN_VAT_POSSIBLE)
               , trim(pFIN_LIQUIDITY)
               , trim(pDES_DESCRIPTION_LARGE_1)
               , trim(pDES_DESCRIPTION_SUMMARY_2)
               , trim(pDES_DESCRIPTION_LARGE_2)
               , trim(pDES_DESCRIPTION_SUMMARY_3)
               , trim(pDES_DESCRIPTION_LARGE_3)
               , trim(pACS_FINANCIAL_CURRENCY_ID)
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
  end IMP_TMP_ACS_FINANCIAL_ACCOUNT;

  /**
  * Description
  *    Contrôle des données de la table ACS_FINANCIAL_ACCOUNT avant importation.
  */
  procedure IMP_ACS_FINANCIAL_ACCOUNT_CTRL
  is
    tmp                            varchar2(200);
    tmp_int                        integer;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Contrôle de l'existence des langues 'FR', 'GE' et 'EN' dans l'ERP
    IMP_PRC_TOOLS.checkLanguage('FR', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('GE', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('EN', lcDomain, 0, '-');

    --Parcours de toutes les lignes de la table IMP_ACS_FINAICAL_ACCOUNT
    for tdata in (select *
                    from IMP_ACS_FINANCIAL_ACCOUNT) loop
--******************************************************************
    --Est-ce qu'il n'a pas de doublon dans les compte financiers
    --et est-ce que tous les enregistrements ont une compte financiers ?
    --******************************************************************
      select count(acc_number)
        into tmp_int
        from IMP_ACS_FINANCIAL_ACCOUNT
       where acc_number = tdata.acc_number;

      --Si on a plus d'un enregistrement avec la même numéro d'compte
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER') );
      end if;

      --Si on a pas d'enregistrement
      if (tmp_int = 0) then
        --Pas de numéro de compte !
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER_2') );
      end if;

--*******************************************************
    --Est-ce que un compta financiers exists
    --*******************************************************
      begin
        select acs_accounting.c_type_accounting
          into tmp
          from acs_accounting
         where c_type_accounting = 'FIN';
      exception
        when no_data_found then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_ACCOUNTING') );
      end;

--*******************************************************
    --Est-ce que une type de sous-enmsemble exists
    --*******************************************************
      begin
        select acs_sub_set.c_type_sub_set
          into tmp
          from acs_sub_set
         where c_type_sub_set = 'LED';
      exception
        when no_data_found then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_SUB_SET') );
      end;

--*******************************************************
    --Est-ce que une sous-ensemble exists
    --*******************************************************
      begin
        select acs_sub_set.c_sub_set
          into tmp
          from acs_sub_set
         where c_sub_set = 'ACC';
      exception
        when no_data_found then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_SUB_SET') );
      end;

      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont présents ?
      *******************************************************/
      if (   tdata.acc_number is null
          or tdata.des_description_summary_1 is null
          or tdata.acc_detail_printing is null
          or tdata.sse_cpn_fin is null
          or tdata.acc_blocked is null
          or tdata.acc_budget is null
          or tdata.c_balance_sheet_profit_loss is null
          or tdata.c_balance_display is null
          or tdata.fin_collective is null
          or tdata.FIN_VAT_POSSIBLE is null
          or tdata.fin_liquidity is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
--*******************************************************
   --Est-ce que la Utilisation débit crédit est correct?
 --*******************************************************
        if tdata.c_balance_display not in('D', 'C') then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_C_DEBIT_CREDIT') );
        end if;

--*******************************************************
   --Est-ce que le comptes existe déjà dans les tables de l'ERP ?
   --*******************************************************
        begin
          select acs_financial_account_id
            into tmp_int
            from acs_financial_account
               , acs_account
           where acc_number = tdata.acc_number
             and acs_financial_account.acs_financial_account_id = acs_account.acs_account_id;

          IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER_3') );
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
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACS_FINANCIAL_CURRENCY_LOCAL') );
        end;

--*******************************************************
    --Est-ce que le monnais étrangers existe?
    --*******************************************************
        begin
          select pc_curr.currency
            into tmp
            from pcs.pc_curr
               , acs_financial_currency
           where pc_curr.currency = tdata.acs_financial_currency_id
             and pc_curr.pc_curr_id = acs_financial_currency.pc_curr_id;
        exception
          when no_data_found then
            if tdata.acs_financial_currency_id is not null then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACS_FINANCIAL_CURRENCY') );
            end if;
        end;

---Contrôle pour la création des CPN en direct
--*******************************************************
    --Est-ce que une sous-enmsemble exists
    --*******************************************************
        begin
          select acs_sub_set.c_sub_set
            into tmp
            from acs_sub_set
           where c_sub_set = 'CPN';

          if     (tdata.sse_cpn_fin = 1)
             and tmp is null then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_SUB_SET') );
          end if;
        end;

--******************************************************************************************
    --Est-ce que le compte financier est plus grand ou égale le premier compte pour le résulat?
    --******************************************************************************************
        begin
          select acc_number
            into tmp
            from IMP_ACS_FINANCIAL_ACCOUNT
           where acs_account_id = tdata.acs_account_id
             and acc_number >= (select sse_first_pp
                                  from acs_sub_set
                                 where c_type_sub_set = 'LED');
        exception
          when no_data_found then
            if (tdata.sse_cpn_fin = 1) then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACS_SSE_FIRST_PP') );
            end if;
        end;

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

          if     (tdata.sse_cpn_fin = 1)
             and tmp_int is not null then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.ID, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_ACC_NUMBER_4') );
          end if;
        exception
          when no_data_found then
            null;
        end;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_ACS_FINANCIAL_ACCOUNT_CTRL;

  /**
  * Description
  *    Importation des données des comptes financiers
  */
  procedure IMP_ACS_FIN_ACCOUNT_IMPORT
  is
    tmp     integer;
    L1      varchar2(10);
    L2      varchar2(10);
    L3      varchar2(10);
    tmp_cpn varchar2(200);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_ACS_FINANCIAL_ACCOUNT) loop
      tmp      := GetNewId;

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
                 , (select acs_sub_set_id
                      from acs_sub_set
                     where c_type_sub_set = 'LED')
                 , tdata.acc_number
                 , 'VAL'
                 , tdata.acc_detail_printing
                 , tdata.acc_blocked
                 , tdata.acc_budget
                 , IMP_LIB_TOOLS.getImportUserIni
                 , sysdate
                  );

      --select acs_account_id into tmp from acs_account;
      insert into ACS_FINANCIAL_ACCOUNT
                  (ACS_FINANCIAL_ACCOUNT_ID
                 , C_BALANCE_SHEET_PROFIT_LOSS
                 , C_BALANCE_DISPLAY
                 , FIN_COLLECTIVE
                 , FIN_VAT_POSSIBLE
                 , FIN_LIQUIDITY
                 , C_DEBIT_CREDIT
                 , A_IDCRE
                 , A_DATECRE
                  )
           values (tmp
                 , tdata.c_balance_sheet_profit_loss
                 , tdata.c_balance_display
                 , tdata.fin_collective
                 , tdata.fin_vat_possible
                 , tdata.fin_liquidity
                 , 'B'
                 , IMP_LIB_TOOLS.getImportUserIni
                 , sysdate
                  );

      insert into ACS_FIN_ACCOUNT_S_FIN_CURR
                  (ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , FSC_DEFAULT
                  )
           values (tmp
                 , (select acs_financial_currency_id
                      from acs_financial_currency
                     where fin_local_currency = 1)
                 , 0
                  );

      if (tdata.ACS_FINANCIAL_CURRENCY_ID is not null) then
        insert into ACS_FIN_ACCOUNT_S_FIN_CURR
                    (ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , FSC_DEFAULT
                    )
             values (tmp
                   , (select c.acs_financial_currency_id
                        from pcs.pc_curr p
                           , acs_financial_currency c
                       where p.pc_curr_id = c.pc_curr_id
                         and p.currency = tdata.ACS_FINANCIAL_CURRENCY_ID)
                   , 1
                    );
      end if;

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

      --Insertion des CPN si le SSE_CPN_FIN = 1
      tmp_cpn  := GetNewId;

      if (tdata.sse_cpn_fin = 1) then
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
             values (tmp_cpn
                   , (select acs_sub_set_id
                        from acs_sub_set
                       where c_type_sub_set = 'NAT')
                   , tdata.acc_number
                   , 'VAL'
                   , tdata.acc_detail_printing
                   , tdata.acc_blocked
                   , tdata.acc_budget
                   , IMP_LIB_TOOLS.getImportUserIni
                   , sysdate
                    );

        insert into ACS_CPN_ACCOUNT
                    (ACS_CPN_ACCOUNT_ID
                   , C_CDA_IMPUTATION
                   , C_PF_IMPUTATION
                   , C_PJ_IMPUTATION
                   , A_IDCRE
                   , A_DATECRE
                    )
             values (tmp_cpn
                   , (select c_cda_imputation
                        from acs_sub_set
                       where c_sub_set = 'CPN')
                   , (select c_pf_imputation
                        from acs_sub_set
                       where c_sub_set = 'CPN')
                   , (select c_pj_imputation
                        from acs_sub_set
                       where c_sub_set = 'CPN')
                   , IMP_LIB_TOOLS.getImportUserIni
                   , sysdate
                    );

        update ACS_FINANCIAL_ACCOUNT FIN
           set FIN.ACS_CPN_ACCOUNT_ID = tmp_cpn
         where exists(select 1
                        from ACS_ACCOUNT ACS
                       where ACS.ACC_NUMBER = tdata.acc_number
                         and FIN.acs_financial_account_id = acs.acs_account_id);

        insert into ACS_CPN_ACCOUNT_CURRENCY
                    (ACS_CPN_ACCOUNT_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                    )
             values (tmp_cpn
                   , (select acs_financial_currency_id
                        from acs_financial_currency
                       where fin_local_currency = 1)
                    );

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
                     , tmp_cpn
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
                     , tmp_cpn
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
                     , tmp_cpn
                     , L3
                     , tdata.DES_DESCRIPTION_SUMMARY_3
                     , tdata.DES_DESCRIPTION_LARGE_3
                     , sysdate
                     , IMP_LIB_TOOLS.getImportUserIni
                      );
        end if;
      end if;

      --Insertion dans historique
      insert into IMP_HIST_ACS_FINANCIAL_ACCOUNT
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , ACS_ACCOUNT_ID
                 , ACC_NUMBER
                 , DES_DESCRIPTION_SUMMARY_1
                 , SSE_CPN_FIN
                 , ACC_DETAIL_PRINTING
                 , ACC_BLOCKED
                 , ACC_BUDGET
                 , C_BALANCE_SHEET_PROFIT_LOSS
                 , C_BALANCE_DISPLAY
                 , FIN_COLLECTIVE
                 , FIN_VAT_POSSIBLE
                 , FIN_LIQUIDITY
                 , DES_DESCRIPTION_LARGE_1
                 , DES_DESCRIPTION_SUMMARY_2
                 , DES_DESCRIPTION_LARGE_2
                 , DES_DESCRIPTION_SUMMARY_3
                 , DES_DESCRIPTION_LARGE_3
                 , ACS_FINANCIAL_CURRENCY_ID
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
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tmp
                 , tdata.ACC_NUMBER
                 , tdata.DES_DESCRIPTION_SUMMARY_1
                 , tdata.SSE_CPN_FIN
                 , tdata.ACC_DETAIL_PRINTING
                 , tdata.ACC_BLOCKED
                 , tdata.ACC_BUDGET
                 , tdata.C_BALANCE_SHEET_PROFIT_LOSS
                 , tdata.C_BALANCE_DISPLAY
                 , tdata.FIN_COLLECTIVE
                 , tdata.FIN_VAT_POSSIBLE
                 , tdata.FIN_LIQUIDITY
                 , tdata.DES_DESCRIPTION_LARGE_1
                 , tdata.DES_DESCRIPTION_SUMMARY_2
                 , tdata.DES_DESCRIPTION_LARGE_2
                 , tdata.DES_DESCRIPTION_SUMMARY_3
                 , tdata.DES_DESCRIPTION_LARGE_3
                 , tdata.ACS_FINANCIAL_CURRENCY_ID
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
  end IMP_ACS_FIN_ACCOUNT_IMPORT;
end IMP_ACS_FINANCIAL_ACC;
