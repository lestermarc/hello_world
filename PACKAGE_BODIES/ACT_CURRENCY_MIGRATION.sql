--------------------------------------------------------
--  DDL for Package Body ACT_CURRENCY_MIGRATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_CURRENCY_MIGRATION" 
is

  /**
  * Description
  * Description
  *         Fonction qui vérifie que toutes les monnaies subdivision de l'Euro soient flaguées IN
  *         recherche parmi les monnaies suivantes
  *         'ITL','DEM','FRF','BEF','ATS','ESP','FIM','IEP','LUF','NLG','PTE','GRD'
  */
  function TestInCurrencies(aDateRef IN date default sysdate) return number
  is
    result number(1);
  begin
    select abs(sign(count(*))-1) into result
      from v_acs_financial_currency
      where CURRENCY IN ('ITL','DEM','FRF','BEF','ATS','ESP','FIM','IEP','LUF','NLG','PTE','GRD')
        and fin_euro_from > aDateRef;
    return result;
  end;

  /**
  * Description
  *           Corrige les imputations qui ont un taux de change mais pas de diviseur.
  *           Recalcul du duvuseur par règle de trois et arrondi à l'entier le plus proche.
  */
  procedure CorrectBasePrice
  is
  begin
    update act_financial_imputation
       set imf_base_price = round(((imf_amount_lc_c+imf_amount_lc_d)/(imf_amount_fc_c+imf_amount_fc_d))/imf_exchange_rate)
     where imf_base_price = 0 and not imf_exchange_Rate  = 0;
  end;

  /**
  * Description : Procedure globale de migration des documents vers une nouvelle monnaie de base
  */
  procedure ConvertFinancialTransactions(old_currency_id IN number,
                                         new_currency_id IN number,
                                         exchange_rate IN number,
                                         base_price IN number)
  is
    cursor exercise_cursor is
      select ACS_FINANCIAL_YEAR_ID, C_STATE_FINANCIAL_YEAR
        from ACS_FINANCIAL_YEAR
       order by FYE_START_DATE;
    exercise_tuple exercise_cursor%rowtype;
    Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Div_Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Div_Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Cpn_Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Cpn_Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Cda_Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Cda_Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Pf_Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Pf_Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Pj_Gain_Id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    Pj_Loss_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
    Continue number(1);
  begin

    select
       ACS_GAIN_EXCH_COMP_ID,
       ACS_LOSS_EXCH_COMP_ID,
       fac1.ACS_CPN_ACCOUNT_ID,
       fac2.ACS_CPN_ACCOUNT_ID,
       ACS_CDA_COMP_GAIN_ID,
       ACS_CDA_COMP_LOSS_ID,
       decode(ACS_CDA_COMP_GAIN_ID,null,ACS_PF_COMP_GAIN_ID),
       decode(ACS_CDA_COMP_LOSS_ID,null,ACS_PF_COMP_LOSS_ID),
       ACS_PJ_COMP_GAIN_ID,
       ACS_PJ_COMP_LOSS_ID
     into
       Gain_Id,
       Loss_Id,
       Cpn_Gain_Id,
       Cpn_Loss_id,
       Cda_Gain_Id,
       Cda_Loss_id,
       Pf_Gain_Id,
       Pf_Loss_id,
       Pj_Gain_Id,
       Pj_Loss_id
      from acs_financial_currency, acs_financial_account fac1, acs_financial_account fac2
     where acs_financial_currency_id = new_currency_id
       and fac1.acs_financial_account_id (+) = ACS_GAIN_EXCH_COMP_ID
       and fac2.acs_financial_account_id (+) = ACS_LOSS_EXCH_COMP_ID;

    if Gain_Id is null OR Loss_Id is null then
      raise_application_error(-20001,'PCS - Round difference accounts must be declared for the new base currency');
    end if;

    -- recherche du sosu-ensemble par défaut pour les division
    SELECT MAX(ACS_SUB_SET_ID) INTO sub_set_id FROM ACS_SUB_SET WHERE C_TYPE_SUB_SET = 'DIVI';

    -- recherche des comptes division par défaut des comptes de gain et de pertes
    Div_Gain_Id := ACS_FUNCTION.GetDivisionOfAccount(gain_id, Div_Gain_id, sysdate);
    Div_Loss_Id := ACS_FUNCTION.GetDivisionOfAccount(Loss_id, Div_Loss_id, sysdate);

    open exercise_cursor;

    fetch exercise_cursor into exercise_tuple;

    while exercise_cursor%found loop

      DropExerciseCumul(exercise_tuple.acs_financial_year_id);
      DropReportingDoc(exercise_tuple.acs_financial_year_id);

      ActivateExercise(exercise_tuple.acs_financial_year_id);

      continue := 1;

      while continue = 1 loop

        ConvertExerciseDocuments(exercise_tuple.acs_financial_year_id,
                                 old_currency_id,
                                 new_currency_id,
                                 exchange_rate,
                                 base_price,
                                 Gain_Id,
                                 Loss_id,
                                 Div_Gain_Id,
                                 Div_Loss_Id,
                                 sub_set_id,
                                 Cpn_Gain_Id,
                                 Cpn_Loss_id,
                                 Cda_Gain_Id,
                                 Cda_Loss_id,
                                 Pf_Gain_Id,
                                 Pf_Loss_id,
                                 Pj_Gain_Id,
                                 Pj_Loss_id,
                                 Continue);

      end loop;

      fetch exercise_cursor into exercise_tuple;

    end loop;

    close exercise_cursor;

/*
    ConvertExerciseCovers(null,
                          old_currency_id,
                          new_currency_id,
                          exchange_rate,
                          base_price);
*/

  end;


  procedure SetCurrencyAccounts(new_currency_id IN number)
  is
  begin

    select
       ACS_GAIN_EXCH_COMP_ID,
       ACS_LOSS_EXCH_COMP_ID,
       fac1.ACS_CPN_ACCOUNT_ID,
       fac2.ACS_CPN_ACCOUNT_ID,
       ACS_CDA_COMP_GAIN_ID,
       ACS_CDA_COMP_LOSS_ID,
       decode(ACS_CDA_COMP_GAIN_ID,null,ACS_PF_COMP_GAIN_ID),
       decode(ACS_CDA_COMP_LOSS_ID,null,ACS_PF_COMP_LOSS_ID),
       ACS_PJ_COMP_GAIN_ID,
       ACS_PJ_COMP_LOSS_ID
     into
       pGain_Id,
       pLoss_Id,
       pCpn_Gain_Id,
       pCpn_Loss_id,
       pCda_Gain_Id,
       pCda_Loss_id,
       pPf_Gain_Id,
       pPf_Loss_id,
       pPj_Gain_Id,
       pPj_Loss_id
      from acs_financial_currency, acs_financial_account fac1, acs_financial_account fac2
     where acs_financial_currency_id = new_currency_id
       and fac1.acs_financial_account_id (+) = ACS_GAIN_EXCH_COMP_ID
       and fac2.acs_financial_account_id (+) = ACS_LOSS_EXCH_COMP_ID;

    if pGain_Id is null OR pLoss_Id is null then
      raise_application_error(-20001,'PCS - Round difference accounts must be declared for the new base currency');
    end if;

    -- recherche du sosu-ensemble par défaut pour les division
    SELECT MAX(ACS_SUB_SET_ID) INTO psub_set_id FROM ACS_SUB_SET WHERE C_TYPE_SUB_SET = 'DIVI';

    -- recherche des comptes division par défaut des comptes de gain et de pertes
    pDiv_Gain_Id := ACS_FUNCTION.GetDivisionOfAccount(pgain_id, pDiv_Gain_id, sysdate);
    pDiv_Loss_Id := ACS_FUNCTION.GetDivisionOfAccount(pLoss_id, pDiv_Loss_id, sysdate);

  end;


  /**
  * Description
  *        suppression du report d'exercice
  *        supression du cumul
  *        activation de l'exercice
  */
  procedure PrepareExerciseConversion(financial_year_id in number,
                                      new_currency_id in number)
  is
  begin

    SetCurrencyAccounts(new_currency_id);

    DropExerciseCumul(financial_year_id);
    DropReportingDoc(financial_year_id);

    ActivateExercise(financial_year_id);

    open Document(financial_year_id);
    fetch Document into current_document_id;

  end;

  /**
  * Description : Procedure globale de migration des documents vers une nouvelle monnaie de base
  */
  procedure ConvertExerciseTransactions(financial_year_id in number,
                                        old_currency_id IN number,
                                        new_currency_id IN number,
                                        exchange_rate IN number,
                                        base_price IN number,
                                        continue out number)
  is
  begin


    ConvertExerciseDocuments(financial_year_id,
                             old_currency_id,
                             new_currency_id,
                             exchange_rate,
                             base_price,
                             pGain_Id,
                             pLoss_id,
                             pDiv_Gain_Id,
                             pDiv_Loss_Id,
                             psub_set_id,
                             pCpn_Gain_Id,
                             pCpn_Loss_id,
                             pCda_Gain_Id,
                             pCda_Loss_id,
                             pPf_Gain_Id,
                             pPf_Loss_id,
                             pPj_Gain_Id,
                             pPj_Loss_id,
                             continue);

  end;


  /**
  * Description : Supression des cumuls par exercice
  */
  procedure DropExerciseCumul(Exercise_id IN number)
  is
  begin

    delete from ACT_TOTAL_BY_PERIOD where ACS_PERIOD_ID in (select ACS_PERIOD_ID
                                                              from ACS_PERIOD
                                                             where ACS_FINANCIAL_YEAR_ID = Exercise_id);

  end;

  /**
  * Description : Supression des documents de report
  */
  procedure DropReportingDoc(Exercise_id IN number)
  is
  begin

    -- Effacement des documents dont le journal est lié à un type de catalogue de report
    delete from ACT_DOCUMENT
      where (exists (select cat.ACJ_CATALOGUE_DOCUMENT_ID
                      from ACJ_CATALOGUE_DOCUMENT cat, ACT_JOURNAL jou, ACT_JOB job, ACJ_JOB_TYPE_S_CATALOGUE jca
                     where jou.ACT_JOURNAL_ID = ACT_DOCUMENT.ACT_JOURNAL_ID
                       and job.ACT_JOB_ID = jou.ACT_JOB_ID
                       and job.ACJ_JOB_TYPE_ID = jca.ACJ_JOB_TYPE_ID
                       and cat.ACJ_CATALOGUE_DOCUMENT_ID = jca.ACJ_CATALOGUE_DOCUMENT_ID
                       and cat.C_TYPE_CATALOGUE = '7')
         or exists (select cat.ACJ_CATALOGUE_DOCUMENT_ID
                      from ACJ_CATALOGUE_DOCUMENT cat, ACT_JOURNAL jou, ACT_JOB job, ACJ_JOB_TYPE_S_CATALOGUE jca
                     where jou.ACT_JOURNAL_ID = ACT_DOCUMENT.ACT_ACT_JOURNAL_ID
                       and job.ACT_JOB_ID = jou.ACT_JOB_ID
                       and job.ACJ_JOB_TYPE_ID = jca.ACJ_JOB_TYPE_ID
                       and cat.ACJ_CATALOGUE_DOCUMENT_ID = jca.ACJ_CATALOGUE_DOCUMENT_ID
                       and cat.C_TYPE_CATALOGUE = '7'))
             and ACS_FINANCIAL_YEAR_ID = Exercise_Id;

    -- Changement de l'etat des journaux de report (passage à provisoire)
    update ACT_ETAT_JOURNAL
        set C_ETAT_JOURNAL = 'PROV'
      where ACT_JOURNAL_ID in (select ACT_JOURNAL_ID
                               from ACJ_CATALOGUE_DOCUMENT cat, ACT_JOURNAL jou, ACT_JOB job, ACJ_JOB_TYPE_S_CATALOGUE jca
                              where jou.ACT_JOURNAL_ID = ACT_ETAT_JOURNAL.ACT_JOURNAL_ID
                                and jou.ACS_FINANCIAL_YEAR_ID = exercise_id
                                and job.ACT_JOB_ID = jou.ACT_JOB_ID
                                and job.ACJ_JOB_TYPE_ID = jca.ACJ_JOB_TYPE_ID
                                and cat.ACJ_CATALOGUE_DOCUMENT_ID = jca.ACJ_CATALOGUE_DOCUMENT_ID
                                and cat.C_TYPE_CATALOGUE = '7');

    -- Change de l'état du travail 'Ouverture/bouclement exercice' (passage à "à faire" TODO)
    update ACT_JOB
       set C_JOB_STATE = 'TODO'
     where ACJ_JOB_TYPE_ID in (select ACJ_JOB_TYPE_ID
                                 from ACJ_EVENT
                                where ACJ_EVENT.ACJ_JOB_TYPE_ID = ACT_JOB.ACJ_JOB_TYPE_ID
                                  and C_TYPE_EVENT = '6')
       and ACS_FINANCIAL_YEAR_ID = exercise_id;

  end;


  /**
  * Description  : Activation de l'exercice passé en paramètre
  */
  procedure ActivateExercise(Exercise_id IN number)
  is
  begin

    update ACS_FINANCIAL_YEAR
      set C_STATE_FINANCIAL_YEAR = 'ACT'
     where ACS_FINANCIAL_YEAR_ID = Exercise_id;

  end;

  /**
  * Description  Procedure de conversion des documents comptables par exercice
  */
  procedure ConvertExerciseDocuments(Exercise_id IN number,
                                     old_currency_id IN number,
                                     new_currency_id IN number,
                                     exchange_rate IN number,
                                     base_price IN number,
                                     Gain_Id IN number,
                                     Loss_id IN Number,
                                     Div_Gain_Id IN number,
                                     Div_Loss_Id IN number,
                                     sub_set_id IN number,
                                     Cpn_Gain_Id IN number,
                                     Cpn_Loss_id IN number,
                                     Cda_Gain_Id IN number,
                                     Cda_Loss_id IN number,
                                     Pf_Gain_Id IN number,
                                     Pf_Loss_id IN number,
                                     Pj_Gain_Id IN number,
                                     Pj_Loss_id IN number,
                                     Continue out number)
  is
    i integer;
  begin

    i := 1;
    Continue := 1;

    while Continue = 1 and i <= 100 loop

      ConvertDocument(current_document_id,
                      old_currency_id,
                      new_currency_id,
                      exchange_rate,
                      base_price,
                      Gain_Id,
                      Loss_id,
                      Div_Gain_Id,
                      Div_Loss_id,
                      sub_set_id,
                      Cpn_Gain_Id,
                      Cpn_Loss_id,
                      Cda_Gain_Id,
                      Cda_Loss_id,
                      Pf_Gain_Id,
                      Pf_Loss_id,
                      Pj_Gain_Id,
                      Pj_Loss_id);

      i := i + 1;
      fetch Document into current_document_id;

      if Document%notfound then
        close Document;
        Continue := 0;
      end if;

    end loop;

  end;

  /**
  * Description  Procedure de conversion des couvertures par exercice
  *
  * @author Fabrice Perotto
  * @version Date 24.01.2001
  * @public
  * @param Exercise_Id  : id de l'exercice comptable (ACS_FINANCIAL_YEAR_ID)
  * @param old_currency_id : id de l'ancienne monnaie de base
  * @param new_currency_id : id de la nouvelle monnaie de base
  * @param exchange_rate   : taux de change
  * @param base_price      : diviseur taux de change
  */
  procedure ConvertExerciseCovers(Exercise_id IN number,
                                  old_currency_id IN number,
                                  new_currency_id IN number,
                                  exchange_rate IN number,
                                  base_price IN number)
  is
  begin

    update ACT_COVER_INFORMATION
      set COV_AMOUNT_LC = decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,COV_AMOUNT_FC,ACS_FUNCTION.RoundNear(COV_AMOUNT_LC*base_price/exchange_rate,0.01)),
          COV_AMOUNT_FC = decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,COV_AMOUNT_LC,new_currency_id,0, COV_AMOUNT_FC),
          ACS_ACS_FINANCIAL_CURRENCY_ID = new_currency_id;
  end;


  /**
  * Description Conversion par document
  */
  procedure ConvertDocument(Document_id IN number,
                            old_currency_id IN number,
                            new_currency_id IN number,
                            exchange_rate IN number,
                            base_price IN number,
                            Gain_Id IN number,
                            Loss_id IN Number,
                            Div_Gain_Id IN number,
                            Div_Loss_Id IN number,
                            sub_set_id IN number,
                            Cpn_Gain_Id IN number,
                            Cpn_Loss_id IN number,
                            Cda_Gain_Id IN number,
                            Cda_Loss_id IN number,
                            Pf_Gain_Id IN number,
                            Pf_Loss_id IN number,
                            Pj_Gain_Id IN number,
                            Pj_Loss_id IN number)
  is
  begin

    -- Utilisation du recstatus en tant que champ libre dans le traitement
    -- afin de déterminer si l'imputation ou le document a été traitée ou non
    update ACT_DOCUMENT
       set A_RECSTATUS = 1
     where ACT_DOCUMENT_ID = Document_id;

    update ACT_FINANCIAL_IMPUTATION
       set A_RECSTATUS = null
     where ACT_DOCUMENT_ID = Document_id;

    -- Echéances
    ConvertExpiry(Document_id,
                  old_currency_id,
                  new_currency_id,
                  exchange_rate,
                  base_price);

    -- Détails paiements
    ConvertDetPayment(Document_id,
                      old_currency_id,
                      new_currency_id,
                      exchange_rate,
                      base_price);

    -- Imputations partenaires
    ConvertPartImputation(Document_id,
                          old_currency_id,
                          new_currency_id,
                          exchange_rate,
                          base_price);

    -- Imputations financières non liées à un paiement ou une échéance ou à des frais
    ConvertFinancialImputation(Document_id,
                               old_currency_id,
                               new_currency_id,
                               exchange_rate,
                               base_price);

    -- Imputation analytiques non liées à une financière
    ConvertIsolatedMgmImputation(Document_id,
                                 old_currency_id,
                                 new_currency_id,
                                 exchange_rate,
                                 base_price,
                                 0);

    -- Relances
    ConvertReminder(Document_id,
                    old_currency_id,
                    new_currency_id,
                    exchange_rate,
                    base_price);

    ControlImputationTotals(Document_ID,
                            Gain_Id,
                            Loss_id,
                            Div_Gain_Id,
                            Div_Loss_id,
                            sub_set_id,
                            Cpn_Gain_Id,
                            Cpn_Loss_id,
                            Cda_Gain_Id,
                            Cda_Loss_id,
                            Pf_Gain_Id,
                            Pf_Loss_id,
                            Pj_Gain_Id,
                            Pj_Loss_id);

    -- Calcul des cumuls
    update ACT_DOCUMENT_STATUS
       set DOC_OK = 0
     where ACT_DOCUMENT_ID = Document_Id;
    ACT_DOC_TRANSACTION.DocImputations(Document_Id,0);

  end;


  /**
  * Description Convertion des échéances et des imputations liées
  */
  procedure ConvertExpiry(Document_id IN number,
                          old_currency_id IN number,
                          new_currency_id IN number,
                          exchange_rate IN number,
                          base_price IN number)
  is

    -- curseur sur les échéances d'un documents (avec montants convertis
    cursor expiry(Document_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
         exp.ACT_EXPIRY_ID,
         exp.ACT_PART_IMPUTATION_ID,
         exp.EXP_CALC_NET,
         decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,EXP_AMOUNT_LC,new_currency_id,0, EXP_AMOUNT_FC) EXP_AMOUNT_FC,
         decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,EXP_AMOUNT_PROV_LC,new_currency_id,0, EXP_AMOUNT_PROV_FC) EXP_AMOUNT_PROV_FC,
         decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,EXP_DISCOUNT_LC,new_currency_id,0, EXP_DISCOUNT_FC) EXP_DISCOUNT_FC,
         decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,EXP_AMOUNT_FC,ACS_FUNCTION.RoundNear(EXP_AMOUNT_LC*base_price/exchange_rate,0.01)) EXP_AMOUNT_LC,
         decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,EXP_AMOUNT_PROV_FC,ACS_FUNCTION.RoundNear(EXP_AMOUNT_PROV_LC*base_price/exchange_rate,0.01)) EXP_AMOUNT_PROV_LC,
         decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,EXP_DISCOUNT_FC,ACS_FUNCTION.RoundNear(EXP_DISCOUNT_LC*base_price/exchange_rate,0.01)) EXP_DISCOUNT_LC
      from act_expiry exp, act_part_imputation part
       where exp.act_document_id = Document_id
         and exp.ACT_PART_IMPUTATION_ID = PART.ACT_PART_IMPUTATION_ID;
    expiry_tuple expiry%rowtype;

    -- Curseur sur les imputations financières liées à une imputation partenaire, avec montants convertis
    -- tri croissant sur le montant pour traîter le plus grand montant en dernier
    cursor FinImpExp_cursor(part_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select ACT_FINANCIAL_IMPUTATION_ID,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_C,new_currency_id,0, IMF_AMOUNT_FC_C) IMF_AMOUNT_FC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_D,new_currency_id,0, IMF_AMOUNT_FC_D) IMF_AMOUNT_FC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(exchange_rate,           -- monnaie document pas monnaie IN
                                                                  0,0,  -- si le taux passé en paramètre est à 0 -> taux de change = 0
                                                                  decode(fin.IMF_EXCHANGE_RATE,
                                                                         0,(1/(exchange_rate/base_price))*cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                         ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price  -- cas 2 monnaie non euro --> rapport de taux de change
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0, (1/(exchange_rate/base_price))*cur.fin_base_price,    -- document dans l'ancienne monnaie de base -> inverse du taux
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,
                                     ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_EXCHANGE_RATE,

                 decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(fin.IMF_EXCHANGE_RATE,           -- monnaie document pas monnaie IN
                                                                  0,cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                  decode(imf_base_price,
                                                                         0,0,cur.fin_base_price  -- si le diviseur passé en paramètre est 0 -> taux de change = 0, sinon -> 1
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0,cur.fin_base_price,    -- document dans l'ancienne monnaie de base
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,cur.FIN_BASE_PRICE
									 )
                              )
                       )
                )
         IMF_BASE_PRICE,
         fin.ACS_FINANCIAL_CURRENCY_ID,
         new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
        from ACT_FINANCIAL_IMPUTATION fin, ACS_FINANCIAL_ACCOUNT acc, ACS_FINANCIAL_CURRENCY cur
       where fin.ACT_PART_IMPUTATION_ID = part_id
         and fin.ACT_DET_PAYMENT_ID is null
         and acc.ACS_FINANCIAL_ACCOUNT_ID = fin.ACS_FINANCIAL_ACCOUNT_ID
         and acc.FIN_COLLECTIVE = 1
         and cur.acs_financial_currency_id = fin.acs_financial_currency_id
        order by ABS(IMF_AMOUNT_LC_C+IMF_AMOUNT_LC_D);
    FinImpExp_tuple FinImpExp_cursor%rowtype;

    -- Curseur donnant le total des échéances par Imputation partenaire du document
    cursor ExpByPart(Document_Id number) is
      select sum(exp_amount_lc) exp_amount_lc, act_part_imputation_id
        from ACT_EXPIRY
       where EXP_CALC_NET = 1
         and ACT_DOCUMENT_ID = Document_Id
       group by ACT_PART_IMPUTATION_ID;
    part_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    solde ACT_EXPIRY.EXP_AMOUNT_LC%type;

  begin

    -- 1) Conversion de toutes les échéances du document
    open expiry(Document_id, old_currency_id, new_currency_id, exchange_rate, base_price);

    fetch expiry into expiry_tuple;

    while expiry%found loop

      update ACT_EXPIRY
         set EXP_AMOUNT_LC = expiry_tuple.EXP_AMOUNT_LC,
             EXP_AMOUNT_PROV_LC = expiry_tuple.EXP_AMOUNT_PROV_LC,
             EXP_DISCOUNT_LC = expiry_tuple.EXP_DISCOUNT_LC,
             EXP_AMOUNT_FC = expiry_tuple.EXP_AMOUNT_FC,
             EXP_AMOUNT_PROV_FC = expiry_tuple.EXP_AMOUNT_PROV_FC,
             EXP_DISCOUNT_FC = expiry_tuple.EXP_DISCOUNT_FC,
             A_RECSTATUS = 1
       where ACT_EXPIRY_ID = expiry_tuple.ACT_EXPIRY_ID;


      fetch expiry into expiry_tuple;

    end loop;

    close expiry;


    -- 2) Total des échéance par Imputation partenaire
    open ExpByPart(Document_Id);

    fetch ExpByPart into solde, part_id;

    while ExpByPart%found loop

      open FinImpExp_cursor(part_id,
                            old_currency_id,
                            new_currency_id,
                            exchange_rate,
                            base_price);

      fetch FinImpExp_cursor into FinImpExp_tuple;

      -- tant qu'il y a des imputations liées à l'échéance traîtée
      if FinImpExp_cursor%found then

        -- raise_application_error(-20000,to_char(solde));

        -- conversion des Distributions financières liées
        ConvertFinancialDistribution(FinImpExp_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                                     old_currency_id,
                                     new_currency_id,
                                     exchange_rate,
                                     base_price,
                                     solde);

        -- conversion des imputations analytiques liées
        ConvertMgmImputation(Document_id,
                             FinImpExp_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                             old_currency_id,
                             new_currency_id,
                             exchange_rate,
                             base_price,
                             solde);

        -- Convertion détail TVA
        ConvertDetTax(FinImpExp_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                      old_currency_id,
                      new_currency_id,
                      exchange_rate,
                      base_price,
                      sign(FinImpExp_tuple.IMF_AMOUNT_LC_D) * ABS(expiry_tuple.EXP_AMOUNT_LC)-sign(FinImpExp_tuple.IMF_AMOUNT_LC_C) * ABS(expiry_tuple.EXP_AMOUNT_LC));

        -- mise à jour du montant LC de la dernière imputation avec le montant solde
        update ACT_FINANCIAL_IMPUTATION
           set IMF_AMOUNT_LC_C               = sign(FinImpExp_tuple.IMF_AMOUNT_LC_C) * ABS(solde),
               IMF_AMOUNT_LC_D               = sign(FinImpExp_tuple.IMF_AMOUNT_LC_D) * ABS(solde),
               IMF_AMOUNT_FC_C               = FinImpExp_tuple.IMF_AMOUNT_FC_C              ,
               IMF_AMOUNT_FC_D               = FinImpExp_tuple.IMF_AMOUNT_FC_D              ,
               IMF_EXCHANGE_RATE             = FinImpExp_tuple.IMF_EXCHANGE_RATE            ,
               IMF_BASE_PRICE                = FinImpExp_tuple.IMF_BASE_PRICE               ,
               ACS_ACS_FINANCIAL_CURRENCY_ID = FinImpExp_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
               A_RECSTATUS                   = 1
          where ACT_FINANCIAL_IMPUTATION_ID = FinImpExp_tuple.ACT_FINANCIAL_IMPUTATION_ID;

        close FinImpExp_Cursor;

      end if;

      fetch ExpByPart into solde, part_id;

    end loop;

    close ExpByPart;

  end;

  /**
  * Description  Convertion des détails payment et des imputations financières liées par document
  */
  procedure ConvertDetPayment(Document_id IN number,
                              old_currency_id IN number,
                              new_currency_id IN number,
                              exchange_rate IN number,
                              base_price IN number)
  is
    cursor det_payment(Document_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
        det.ACT_DET_PAYMENT_ID,
        det.ACT_PART_IMPUTATION_ID,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,DET_PAIED_LC,new_currency_id,0,     DET_PAIED_FC)     DET_PAIED_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,DET_CHARGES_LC,new_currency_id,0,   DET_CHARGES_FC)   DET_CHARGES_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,DET_DISCOUNT_LC,new_currency_id,0,  DET_DISCOUNT_FC)  DET_DISCOUNT_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,DET_DEDUCTION_LC,new_currency_id,0, DET_DEDUCTION_FC) DET_DEDUCTION_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,DET_PAIED_FC,    ACS_FUNCTION.RoundNear(DET_PAIED_LC     *base_price/exchange_rate,0.01)) DET_PAIED_LC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,DET_CHARGES_FC,  ACS_FUNCTION.RoundNear(DET_CHARGES_LC   *base_price/exchange_rate,0.01)) DET_CHARGES_LC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,DET_DISCOUNT_FC, ACS_FUNCTION.RoundNear(DET_DISCOUNT_LC  *base_price/exchange_rate,0.01)) DET_DISCOUNT_LC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,DET_DEDUCTION_FC,ACS_FUNCTION.RoundNear(DET_DEDUCTION_LC *base_price/exchange_rate,0.01)) DET_DEDUCTION_LC,
        ACS_FUNCTION.RoundNear(ConvertAmountForView(DET_DIFF_EXCHANGE, old_currency_id, new_currency_id, trunc(sysdate),exchange_rate,base_price,0),0.01) DET_DIFF_EXCHANGE
       from act_det_payment det, act_part_imputation part
      where det.act_document_id = Document_id
        and part.act_part_imputation_id = det.act_part_imputation_id;
    det_payment_tuple det_payment%rowtype;

    solde ACT_EXPIRY.EXP_AMOUNT_LC%type;
    genre_transaction ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION%type;
  begin

    open det_payment(Document_id,
                     old_currency_id,
                     new_currency_id,
                     exchange_rate,
                     base_price);

    fetch det_payment into det_payment_tuple;

    while det_payment%found loop

      -- mise à jour des montants
      update ACT_DET_PAYMENT
        set DET_PAIED_LC     = det_payment_tuple.DET_PAIED_LC    ,
            DET_CHARGES_LC   = det_payment_tuple.DET_CHARGES_LC  ,
            DET_DISCOUNT_LC  = det_payment_tuple.DET_DISCOUNT_LC ,
            DET_DEDUCTION_LC = det_payment_tuple.DET_DEDUCTION_LC,
            DET_PAIED_FC     = det_payment_tuple.DET_PAIED_FC    ,
            DET_CHARGES_FC   = det_payment_tuple.DET_CHARGES_FC  ,
            DET_DISCOUNT_FC  = det_payment_tuple.DET_DISCOUNT_FC ,
            DET_DEDUCTION_FC = det_payment_tuple.DET_DEDUCTION_FC,
            DET_DIFF_EXCHANGE= det_payment_tuple.DET_DIFF_EXCHANGE,
            A_RECSTATUS                   = 1
       where ACT_DET_PAYMENT_ID = det_payment_tuple.ACT_DET_PAYMENT_ID;

      -- à vérifier avec MRO
      solde := ABS(det_payment_tuple.DET_PAIED_LC+det_payment_tuple.DET_DISCOUNT_LC+det_payment_tuple.DET_DEDUCTION_LC+det_payment_tuple.DET_DIFF_EXCHANGE);
      genre_transaction := '1';
      ConvertPaymentImputation(Document_Id,
                               det_payment_tuple.ACT_DET_PAYMENT_ID,
                               old_currency_id,
                               new_currency_id,
                               exchange_rate,
                               base_price,
                               genre_transaction,
                               solde);

      solde := ABS(det_payment_tuple.DET_DISCOUNT_LC);
      genre_transaction := '2';
      ConvertPaymentImputation(Document_Id,
                               det_payment_tuple.ACT_DET_PAYMENT_ID,
                               old_currency_id,
                               new_currency_id,
                               exchange_rate,
                               base_price,
                               genre_transaction,
                               solde);

      solde := ABS(det_payment_tuple.DET_DEDUCTION_LC);
      genre_transaction := '3';
      ConvertPaymentImputation(Document_Id,
                               det_payment_tuple.ACT_DET_PAYMENT_ID,
                               old_currency_id,
                               new_currency_id,
                               exchange_rate,
                               base_price,
                               genre_transaction,
                               solde);

      solde := ABS(det_payment_tuple.DET_DIFF_EXCHANGE);
      genre_transaction := '4';
      ConvertPaymentImputation(Document_Id,
                               det_payment_tuple.ACT_DET_PAYMENT_ID,
                               old_currency_id,
                               new_currency_id,
                               exchange_rate,
                               base_price,
                               genre_transaction,
                               solde);

      fetch det_payment into det_payment_tuple;

    end loop;

    close det_payment;

  end;

  /**
  * Description  Convertion des impuations financières liées par document
  */
  procedure ConvertPaymentImputation(Document_Id IN number,
                                     DetPayment_id IN number,
                                     old_currency_id IN number,
                                     new_currency_id IN number,
                                     exchange_rate IN number,
                                     base_price IN number,
                                     genre_transaction IN varchar2,
                                     parity_amount IN number)
  is
    -- Curseur sur les imputations financières liées à un détail paiement, avec montants convertis
    -- tri croissant sur le montant pour traîter le plus grand montant en dernier
    cursor FinImpDet(det_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number, genre_transaction varchar2) is
      select ACT_FINANCIAL_IMPUTATION_ID,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_C,new_currency_id,0, IMF_AMOUNT_FC_C) IMF_AMOUNT_FC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_D,new_currency_id,0, IMF_AMOUNT_FC_D) IMF_AMOUNT_FC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(exchange_rate,           -- monnaie document pas monnaie IN
                                                                  0,0,  -- si le taux passé en paramètre est à 0 -> taux de change = 0
                                                                  decode(fin.IMF_EXCHANGE_RATE,
                                                                         0,(1/(exchange_rate/base_price))*cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                         ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price  -- cas 2 monnaie non euro --> rapport de taux de change
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0, (1/(exchange_rate/base_price))*cur.fin_base_price,    -- document dans l'ancienne monnaie de base -> inverse du taux
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,
                                     ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_EXCHANGE_RATE,

                 decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(fin.IMF_EXCHANGE_RATE,           -- monnaie document pas monnaie IN
                                                                  0,cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                  decode(imf_base_price,
                                                                         0,0,cur.fin_base_price  -- si le diviseur passé en paramètre est 0 -> taux de change = 0, sinon -> 1
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0,cur.fin_base_price,    -- document dans l'ancienne monnaie de base
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_BASE_PRICE,
         fin.ACS_FINANCIAL_CURRENCY_ID,
         new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
        from ACT_FINANCIAL_IMPUTATION fin, ACS_FINANCIAL_CURRENCY cur
       where fin.ACT_DET_PAYMENT_ID = det_id
         --and fin.C_GENRE_TRANSACTION in ('1','2','3','4','7')
         and fin.C_GENRE_TRANSACTION = genre_transaction
         and cur.ACS_FINANCIAL_CURRENCY_ID = fin.ACS_FINANCIAL_CURRENCY_ID
        order by ABS(IMF_AMOUNT_LC_C+IMF_AMOUNT_LC_D);
    FinImpDet_tuple FinImpDet%rowtype;
    tax_amount ACT_DET_TAX.TAX_LIABLED_AMOUNT%type;
  begin

    open FinImpDet(DetPayment_Id,
                   old_currency_id,
                   new_currency_id,
                   exchange_rate,
                   base_price,
                   genre_transaction);

    fetch FinImpDet into FinImpDet_tuple;

    while FinImpDet%found loop


      -- dans le cas ou c'est la dernière imputation, on met le solde

      -- conversion des Distributions financières liées
      ConvertFinancialDistribution(FinImpDet_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                                   old_currency_id,
                                   new_currency_id,
                                   exchange_rate,
                                   base_price,
                                   parity_amount);

      -- conversion des imputations analytiques liées
      ConvertMgmImputation(Document_Id,
                           FinImpDet_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                           old_currency_id,
                           new_currency_id,
                           exchange_rate,
                           base_price,
                           parity_amount);

      select decode(sign(parity_amount),0,FinImpDet_tuple.IMF_AMOUNT_LC_D,sign(FinImpDet_tuple.IMF_AMOUNT_LC_C)*ABS(parity_amount)) - decode(sign(parity_amount),0,FinImpDet_tuple.IMF_AMOUNT_LC_C,sign(FinImpDet_tuple.IMF_AMOUNT_LC_C)*ABS(parity_amount))
        into tax_amount
        from dual;

      -- Convertion détail TVA
      ConvertDetTax(FinImpDet_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                    old_currency_id,
                    new_currency_id,
                    exchange_rate,
                    base_price,
                    tax_amount);

      -- mise à jour du montant LC de la dernière imputation avec le montant solde
      update ACT_FINANCIAL_IMPUTATION
         set IMF_AMOUNT_LC_C               = decode(parity_amount,0,FinImpDet_tuple.IMF_AMOUNT_LC_C,decode(sign(FinImpDet_tuple.IMF_AMOUNT_LC_C),0,0,sign(FinImpDet_tuple.IMF_AMOUNT_LC_C)*ABS(parity_amount))),
             IMF_AMOUNT_LC_D               = decode(parity_amount,0,FinImpDet_tuple.IMF_AMOUNT_LC_D,decode(sign(FinImpDet_tuple.IMF_AMOUNT_LC_D),0,0,sign(FinImpDet_tuple.IMF_AMOUNT_LC_D)*ABS(parity_amount))),
             IMF_AMOUNT_FC_C               = FinImpDet_tuple.IMF_AMOUNT_FC_C              ,
             IMF_AMOUNT_FC_D               = FinImpDet_tuple.IMF_AMOUNT_FC_D              ,
             IMF_EXCHANGE_RATE             = FinImpDet_tuple.IMF_EXCHANGE_RATE            ,
             IMF_BASE_PRICE                = FinImpDet_tuple.IMF_BASE_PRICE               ,
             ACS_ACS_FINANCIAL_CURRENCY_ID = FinImpDet_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
             A_RECSTATUS                   = 1
        where ACT_FINANCIAL_IMPUTATION_ID = FinImpDet_tuple.ACT_FINANCIAL_IMPUTATION_ID;

      fetch FinImpDet into FinImpDet_tuple;

    end loop;

    close FinImpDet;

  end;

  /**
  * Description  Convertion des relances
  */
  procedure ConvertReminder(Document_id IN number,
                            old_currency_id IN number,
                            new_currency_id IN number,
                            exchange_rate IN number,
                            base_price IN number)
  is
    cursor reminder(Document_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
        ACT_REMINDER_ID,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,REM_PAYABLE_AMOUNT_LC,new_currency_id,0,  REM_PAYABLE_AMOUNT_FC)   REM_PAYABLE_AMOUNT_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,REM_COVER_AMOUNT_LC,new_currency_id,0,REM_COVER_AMOUNT_FC) REM_COVER_AMOUNT_FC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,REM_PAYABLE_AMOUNT_FC,    ACS_FUNCTION.RoundNear(REM_PAYABLE_AMOUNT_LC*base_price/exchange_rate,0.01)) REM_PAYABLE_AMOUNT_LC,
        decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,REM_COVER_AMOUNT_FC,  ACS_FUNCTION.RoundNear(REM_COVER_AMOUNT_LC*base_price/exchange_rate,0.01)) REM_COVER_AMOUNT_LC,
        new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
      from ACT_REMINDER
       where ACT_DOCUMENT_ID = Document_Id;
     reminder_tuple reminder%rowtype;
  begin

    open reminder(Document_id,
                  old_currency_id,
                  new_currency_id,
                  exchange_rate,
                  base_price);

    fetch reminder into reminder_tuple;

    while reminder%found loop

      -- mise à jour des relances
      update ACT_REMINDER
        set REM_PAYABLE_AMOUNT_LC = reminder_tuple.REM_PAYABLE_AMOUNT_LC,
            REM_PAYABLE_AMOUNT_FC = reminder_tuple.REM_PAYABLE_AMOUNT_FC,
            REM_COVER_AMOUNT_LC   = reminder_tuple.REM_COVER_AMOUNT_LC,
            REM_COVER_AMOUNT_FC   = reminder_tuple.REM_COVER_AMOUNT_FC,
            ACS_ACS_FINANCIAL_CURRENCY_ID = reminder_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
            A_RECSTATUS                   = 1
       where ACT_REMINDER_ID = reminder_tuple.ACT_REMINDER_ID;

      fetch reminder into reminder_tuple;

    end loop;

    close reminder;

  end;


  /**
  * Description  Convertion des imputations partenaires et des imputations financières
  *              liées par document.
  */
  procedure ConvertPartImputation(Document_id IN number,
                                  old_currency_id IN number,
                                  new_currency_id IN number,
                                  exchange_rate IN number,
                                  base_price IN number)
  is
    cursor part_imputation(Document_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select part.ACT_PART_IMPUTATION_ID,
        decode(part.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,PAR_PAIED_LC,new_currency_id,0,  PAR_PAIED_FC)   PAR_PAIED_FC,
        decode(part.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,PAR_CHARGES_LC,new_currency_id,0,PAR_CHARGES_FC) PAR_CHARGES_FC,
        decode(part.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,PAR_PAIED_FC,    ACS_FUNCTION.RoundNear(PAR_PAIED_LC*base_price/exchange_rate,0.01)) PAR_PAIED_LC,
        decode(part.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,PAR_CHARGES_FC,  ACS_FUNCTION.RoundNear(PAR_CHARGES_LC*base_price/exchange_rate,0.01)) PAR_CHARGES_LC,
        decode(part.ACS_FINANCIAL_CURRENCY_ID,
               new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
               DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                      ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(part.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                          1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                          DECODE(exchange_rate,           -- monnaie document pas monnaie IN
                                                                 0,0,  -- si le taux passé en paramètre est à 0 -> taux de change = 0
                                                                 decode(PAR_EXCHANGE_RATE,
                                                                        0,1/(exchange_rate/base_price),  -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                        (PAR_EXCHANGE_RATE/PAR_BASE_PRICE)/(exchange_rate/base_price)  -- cas 2 monnaie non euro --> rapport de taux de change
                                                                                                                                 )
                                                                                                                  )
                                                                                                    ),
                      DECODE(PAR_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                             0, 1/(exchange_rate/base_price),    -- document dans l'ancienne monnaie de base -> inverse du taux
                             decode(PAR_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                    0,0,
                                    (PAR_EXCHANGE_RATE/PAR_BASE_PRICE)/(exchange_rate/base_price)
                                                                        )
                             )
                      )
               )
        PAR_EXCHANGE_RATE,

                decode(part.ACS_FINANCIAL_CURRENCY_ID,
               new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
               DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                      ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(part.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                          1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                          DECODE(PAR_EXCHANGE_RATE,           -- monnaie document pas monnaie IN
                                                                 0,1,  -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                 decode(PAR_base_price,
                                                                        0,0,1  -- si le diviseur passé en paramètre est 0 -> taux de change = 0, sinon -> 1
                                                                                                                                 )
                                                                                                                  )
                                                                                                    ),
                      DECODE(PAR_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                             0,1,    -- document dans l'ancienne monnaie de base
                             decode(PAR_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                    0,0,1
                                                                        )
                             )
                      )
               )
        PAR_BASE_PRICE,
        new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
      from act_part_imputation part, acs_financial_currency cur
       where part.act_document_id = Document_id
         and cur.acs_financial_currency_id = part.acs_financial_currency_id;
    part_imputation_tuple part_imputation%rowtype;

    -- Curseur sur les imputations financières liées à un détail paiement, avec montants convertis
    -- tri croissant sur le montant pour traîter le plus grand montant en dernier
    cursor FinImpCharges(part_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select ACT_FINANCIAL_IMPUTATION_ID,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_C,new_currency_id,0, IMF_AMOUNT_FC_C) IMF_AMOUNT_FC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_D,new_currency_id,0, IMF_AMOUNT_FC_D) IMF_AMOUNT_FC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_C,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_D,
         decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(exchange_rate,           -- monnaie document pas monnaie IN
                                                                  0,0,  -- si le taux passé en paramètre est à 0 -> taux de change = 0
                                                                  decode(fin.IMF_EXCHANGE_RATE,
                                                                         0,(1/(exchange_rate/base_price))*cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                         ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price  -- cas 2 monnaie non euro --> rapport de taux de change
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0, (1/(exchange_rate/base_price))*cur.fin_base_price,    -- document dans l'ancienne monnaie de base -> inverse du taux
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,
                                     ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_EXCHANGE_RATE,

                 decode(fin.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(fin.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(fin.IMF_EXCHANGE_RATE,           -- monnaie document pas monnaie IN
                                                                  0,cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                  decode(imf_base_price,
                                                                         0,0,cur.fin_base_price  -- si le diviseur passé en paramètre est 0 -> taux de change = 0, sinon -> 1
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0,cur.fin_base_price,    -- document dans l'ancienne monnaie de base
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_BASE_PRICE,
         fin.ACS_FINANCIAL_CURRENCY_ID,
         new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
        from ACT_FINANCIAL_IMPUTATION fin, ACS_FINANCIAL_CURRENCY cur
       where fin.ACT_PART_IMPUTATION_ID = part_id
         and C_GENRE_TRANSACTION = '6'
         and fin.acs_financial_currency_id = cur.acs_financial_currency_id
        order by ABS(IMF_AMOUNT_LC_C+IMF_AMOUNT_LC_D);
    FinImpCharges_tuple FinImpCharges%rowtype;

  begin

    open part_imputation(Document_id,
                         old_currency_id,
                         new_currency_id,
                         exchange_rate,
                         base_price);

    fetch part_imputation into part_imputation_tuple;

    while part_imputation%found loop

      update ACT_PART_IMPUTATION
        set -- PAR_PAIED_FC    = part_imputation_tuple.PAR_PAIED_FC  ,
            -- PAR_PAIED_LC    = part_imputation_tuple.PAR_PAIED_LC  ,
            PAR_CHARGES_FC  = part_imputation_tuple.PAR_CHARGES_FC,
            PAR_CHARGES_LC  = part_imputation_tuple.PAR_CHARGES_LC,
            ACS_ACS_FINANCIAL_CURRENCY_ID = part_imputation_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
            A_RECSTATUS                   = 1
       where ACT_PART_IMPUTATION_ID = part_imputation_tuple.ACT_PART_IMPUTATION_ID;

      open FinImpCharges(part_imputation_tuple.ACT_PART_IMPUTATION_ID,
                         old_currency_id,
                         new_currency_id,
                         exchange_rate,
                         base_price);

      fetch FinImpCharges into FinImpCharges_tuple;

      if FinImpCharges%found then

        -- conversion des Distributions financières liées
        ConvertFinancialDistribution(FinImpCharges_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                                     old_currency_id,
                                     new_currency_id,
                                     exchange_rate,
                                     base_price,
                                     part_imputation_tuple.PAR_CHARGES_LC);

        -- conversion des imputations analytiques liées
        ConvertMgmImputation(Document_Id,
                             FinImpCharges_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                             old_currency_id,
                             new_currency_id,
                             exchange_rate,
                             base_price,
                             part_imputation_tuple.PAR_CHARGES_LC);

        -- Convertion détail TVA
        ConvertDetTax(FinImpCharges_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                      old_currency_id,
                      new_currency_id,
                      exchange_rate,
                      base_price,
                      part_imputation_tuple.PAR_CHARGES_LC);

        -- mise à jour du montant LC de la dernière imputation avec le montant solde
        update ACT_FINANCIAL_IMPUTATION
           set IMF_AMOUNT_LC_C               = decode(sign(FinImpCharges_tuple.IMF_AMOUNT_LC_C),0,FinImpCharges_tuple.IMF_AMOUNT_LC_C,sign(FinImpCharges_tuple.IMF_AMOUNT_LC_C)*ABS(part_imputation_tuple.PAR_CHARGES_LC))                  ,
               IMF_AMOUNT_LC_D               = decode(sign(FinImpCharges_tuple.IMF_AMOUNT_LC_D),0,FinImpCharges_tuple.IMF_AMOUNT_LC_D,sign(FinImpCharges_tuple.IMF_AMOUNT_LC_D)*ABS(part_imputation_tuple.PAR_CHARGES_LC))                  ,
               IMF_AMOUNT_FC_C               = FinImpCharges_tuple.IMF_AMOUNT_FC_C              ,
               IMF_AMOUNT_FC_D               = FinImpCharges_tuple.IMF_AMOUNT_FC_D              ,
               IMF_EXCHANGE_RATE             = FinImpCharges_tuple.IMF_EXCHANGE_RATE            ,
               IMF_BASE_PRICE                = FinImpCharges_tuple.IMF_BASE_PRICE               ,
               ACS_ACS_FINANCIAL_CURRENCY_ID = FinImpCharges_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
               A_RECSTATUS                   = 1
          where ACT_FINANCIAL_IMPUTATION_ID = FinImpCharges_tuple.ACT_FINANCIAL_IMPUTATION_ID;

      end if;

      close FinImpCharges;

      fetch part_imputation into part_imputation_tuple;

    end loop;

    close part_imputation;

  exception
    when others then
      raise_application_error(-20044,'document_id: '||to_char(document_id)||' exchange_rate : '||to_char(exchange_rate)||' base_price : '||to_char(base_price));
  end;

  /**
  * Description  Conversion des imputations financières non liées par document
  */
  procedure ConvertFinancialImputation(Document_id IN number,
                                       old_currency_id IN number,
                                       new_currency_id IN number,
                                       exchange_rate IN number,
                                       base_price IN number)
  is
    -- Curseur sur les imputations financières non liées à des paiements ou des échéances
    cursor Imputation(document_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select ACT_FINANCIAL_IMPUTATION_ID,
         decode(cur.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_C,new_currency_id,0, IMF_AMOUNT_FC_C) IMF_AMOUNT_FC_C,
         decode(cur.ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMF_AMOUNT_LC_D,new_currency_id,0, IMF_AMOUNT_FC_D) IMF_AMOUNT_FC_D,
         decode(cur.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_C,
         decode(cur.ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMF_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMF_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMF_AMOUNT_LC_D,
         decode(cur.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(cur.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(exchange_rate,           -- monnaie document pas monnaie IN
                                                                  0,0,  -- si le taux passé en paramètre est à 0 -> taux de change = 0
                                                                  decode(fin.IMF_EXCHANGE_RATE,
                                                                         0,(1/(exchange_rate/base_price))*cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> inverse du taux
                                                                         ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price  -- cas 2 monnaie non euro --> rapport de taux de change
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0, (1/(exchange_rate/base_price))*cur.fin_base_price,    -- document dans l'ancienne monnaie de base -> inverse du taux
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,
                                     ((IMF_EXCHANGE_RATE/IMF_BASE_PRICE)/(exchange_rate/base_price))*cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_EXCHANGE_RATE,

                 decode(cur.ACS_FINANCIAL_CURRENCY_ID,
                new_currency_id,0,        -- nouvelle monnaie de base = monnaie document --> pas de taux de change
                DECODE(new_currency_id,   -- nouvelle monnaie différente de la monnaie du document
                       ACS_FUNCTION.GetEuroCurrency,decode(ACS_FUNCTION.IsFinCurrInEuro(cur.ACS_FINANCIAL_CURRENCY_ID,sysdate),  -- nouvelle monaie est l'Euro
                                                           1,0,                           -- monnaie document est monnaie IN --> taux de change à 0
                                                           DECODE(fin.IMF_EXCHANGE_RATE,           -- monnaie document pas monnaie IN
                                                                  0,cur.fin_base_price,  -- document dans l'ancienne monnaie de base -> diviseur = 1
                                                                  decode(imf_base_price,
                                                                         0,0,cur.fin_base_price  -- si le diviseur passé en paramètre est 0 -> taux de change = 0, sinon -> 1
																  )
														   )
												     ),
                       DECODE(fin.IMF_EXCHANGE_RATE,  -- nouvelle monnaie non euro
                              0,cur.fin_base_price,    -- document dans l'ancienne monnaie de base
                              decode(imf_base_price,  -- document monnaie étrangère différente nouvelle monnaie
                                     0,0,cur.fin_base_price
									 )
                              )
                       )
                )
         IMF_BASE_PRICE,
         IMF_PRIMARY,
         cur.ACS_FINANCIAL_CURRENCY_ID,
         new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
        from ACT_FINANCIAL_IMPUTATION fin, ACS_FINANCIAL_CURRENCY cur
       where fin.ACT_DOCUMENT_ID = document_id
         and fin.A_RECSTATUS is null
         and cur.acs_financial_currency_id = fin.acs_financial_currency_id;
    Imputation_tuple Imputation%rowtype;

  begin

    open Imputation(Document_id,
                    old_currency_id,
                    new_currency_id,
                    exchange_rate,
                    base_price);

    fetch Imputation into Imputation_tuple;

    while Imputation%found loop

      -- conversion des Distributions financières liées
      ConvertFinancialDistribution(Imputation_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                                   old_currency_id,
                                   new_currency_id,
                                   exchange_rate,
                                   base_price,
                                   Imputation_tuple.IMF_AMOUNT_LC_C+Imputation_tuple.IMF_AMOUNT_LC_D);

      -- conversion des imputations analytiques liées
      ConvertMgmImputation(Document_Id,
                           Imputation_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                           old_currency_id,
                           new_currency_id,
                           exchange_rate,
                           base_price,
                           Imputation_tuple.IMF_AMOUNT_LC_C+Imputation_tuple.IMF_AMOUNT_LC_D);

      -- Convertion détail TVA
      ConvertDetTax(Imputation_tuple.ACT_FINANCIAL_IMPUTATION_ID,
                    old_currency_id,
                    new_currency_id,
                    exchange_rate,
                    base_price,
                    Imputation_tuple.IMF_AMOUNT_LC_D-Imputation_tuple.IMF_AMOUNT_LC_C);

      update ACT_FINANCIAL_IMPUTATION
         set IMF_AMOUNT_LC_C               = Imputation_tuple.IMF_AMOUNT_LC_C              ,
             IMF_AMOUNT_LC_D               = Imputation_tuple.IMF_AMOUNT_LC_D              ,
             IMF_AMOUNT_FC_C               = Imputation_tuple.IMF_AMOUNT_FC_C              ,
             IMF_AMOUNT_FC_D               = Imputation_tuple.IMF_AMOUNT_FC_D              ,
             IMF_EXCHANGE_RATE             = Imputation_tuple.IMF_EXCHANGE_RATE            ,
             IMF_BASE_PRICE                = Imputation_tuple.IMF_BASE_PRICE               ,
             ACS_ACS_FINANCIAL_CURRENCY_ID = Imputation_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
             A_RECSTATUS                   = 1
        where ACT_FINANCIAL_IMPUTATION_ID = Imputation_tuple.ACT_FINANCIAL_IMPUTATION_ID;


      fetch Imputation into Imputation_tuple;

    end loop;

    close Imputation;

  end;

  /**
  * Description Conversion des distributions par imputation financière
  */
  procedure ConvertFinancialDistribution(Imputation_id IN number,
                                         old_currency_id IN number,
                                         new_currency_id IN number,
                                         exchange_rate IN number,
                                         base_price IN number,
                                         imp_tot IN number)
  is
    cursor Distribution(fin_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
          dis.ACT_FINANCIAL_DISTRIBUTION_ID,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,FIN_AMOUNT_LC_C,new_currency_id,0, FIN_AMOUNT_FC_C) FIN_AMOUNT_FC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,FIN_AMOUNT_LC_D,new_currency_id,0, FIN_AMOUNT_FC_D) FIN_AMOUNT_FC_D,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,FIN_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(FIN_AMOUNT_LC_C*base_price/exchange_rate,0.01)) FIN_AMOUNT_LC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,FIN_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(FIN_AMOUNT_LC_D*base_price/exchange_rate,0.01)) FIN_AMOUNT_LC_D
       from act_financial_distribution dis, act_financial_imputation fin
      where dis.act_financial_imputation_id = fin_id
        and fin.act_financial_imputation_id = dis.act_financial_imputation_id;
    distribution_tuple distribution%rowtype;
  begin

    open Distribution(Imputation_id,
                      old_currency_id,
                      new_currency_id,
                      exchange_rate,
                      base_price);

    fetch Distribution into distribution_tuple;

    if distribution%found then

      update ACT_FINANCIAL_DISTRIBUTION
         set FIN_AMOUNT_LC_C = distribution_tuple.FIN_AMOUNT_LC_C,
             FIN_AMOUNT_LC_D = distribution_tuple.FIN_AMOUNT_LC_D,
             FIN_AMOUNT_FC_C = distribution_tuple.FIN_AMOUNT_FC_C,
             FIN_AMOUNT_FC_D = distribution_tuple.FIN_AMOUNT_FC_C,
             A_RECSTATUS                   = 1
       where ACT_FINANCIAL_DISTRIBUTION_ID = distribution_tuple.ACT_FINANCIAL_DISTRIBUTION_ID;

    end if;

    close distribution;

  end;

  /**
  * Description Conversion des décomptes TVA par imputation financière
  */
  procedure ConvertDetTax(Imputation_Id IN number,
                          old_currency_id IN number,
                          new_currency_id IN number,
                          exchange_rate IN number,
                          base_price IN number,
                          liabled_amount IN number)
  is
    cursor DetTax(fin_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
          tax.ACT_DET_TAX_ID,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,TAX_VAT_AMOUNT_LC,new_currency_id,0, TAX_VAT_AMOUNT_FC) TAX_VAT_AMOUNT_FC,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,TAX_VAT_AMOUNT_FC,ACS_FUNCTION.RoundNear(TAX_VAT_AMOUNT_LC*base_price/exchange_rate,0.01)) TAX_VAT_AMOUNT_LC
       from act_det_tax tax, act_financial_imputation fin
      where tax.act_financial_imputation_id = fin_id
        and fin.act_financial_imputation_id = tax.act_financial_imputation_id;
    DetTax_tuple DetTax%rowtype;
  begin

    open DetTax(Imputation_id,
                old_currency_id,
                new_currency_id,
                exchange_rate,
                base_price);

    fetch DetTax into DetTax_tuple;

    while DetTax%found loop

      update ACT_DET_TAX
        set TAX_LIABLED_AMOUNT = liabled_amount,
            TAX_VAT_AMOUNT_LC = DetTax_tuple.TAX_VAT_AMOUNT_LC,
            TAX_VAT_AMOUNT_FC = DetTax_tuple.TAX_VAT_AMOUNT_FC,
            A_RECSTATUS                   = 1
       where ACT_DET_TAX_ID = DetTax_tuple.ACT_DET_TAX_ID;

      fetch DetTax into DetTax_tuple;
    end loop;

    close DetTax;

  end;

  /**
  * Description Conversion des imputations analytiques par imputation financière
  */
  procedure ConvertIsolatedMgmImputation(Document_Id IN number,
                                         old_currency_id IN number,
                                         new_currency_id IN number,
                                         exchange_rate IN number,
                                         base_price IN number,
                                         imp_tot IN number)
  is
    cursor MgmImputation(doc_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
          mgm.ACT_MGM_IMPUTATION_ID,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMM_AMOUNT_LC_C,new_currency_id,0, IMM_AMOUNT_FC_C) IMM_AMOUNT_FC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMM_AMOUNT_LC_D,new_currency_id,0, IMM_AMOUNT_FC_D) IMM_AMOUNT_FC_D,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMM_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMM_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMM_AMOUNT_LC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMM_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMM_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMM_AMOUNT_LC_D,
          new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
       from act_mgm_imputation mgm
      where mgm.act_document_id = doc_id
   order by ABS(IMM_AMOUNT_LC_C+IMM_AMOUNT_LC_D);
    MgmImputation_tuple MgmImputation%rowtype;
    solde ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    tot_mgm ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
    diff_fin_mgm ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
    last_imp ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin

    open MgmImputation(Document_id,
                       old_currency_id,
                       new_currency_id,
                       exchange_rate,
                       base_price);

    fetch MgmImputation into MgmImputation_tuple;

    while MgmImputation%found loop

      last_imp := MgmImputation_tuple.ACT_MGM_IMPUTATION_ID;

      update ACT_MGM_IMPUTATION
         set IMM_AMOUNT_LC_C = MgmImputation_tuple.IMM_AMOUNT_LC_C,
             IMM_AMOUNT_LC_D = MgmImputation_tuple.IMM_AMOUNT_LC_D,
             IMM_AMOUNT_FC_C = MgmImputation_tuple.IMM_AMOUNT_FC_C,
             IMM_AMOUNT_FC_D = MgmImputation_tuple.IMM_AMOUNT_FC_C,
             ACS_ACS_FINANCIAL_CURRENCY_ID = MgmImputation_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
             A_RECSTATUS                   = 1
       where ACT_MGM_IMPUTATION_ID = MgmImputation_tuple.ACT_MGM_IMPUTATION_ID;

      ConvertMgmDistribution(MgmImputation_tuple.ACT_MGM_IMPUTATION_ID,
                             old_currency_id,
                             new_currency_id,
                             exchange_rate,
                             base_price,
                             MgmImputation_tuple.IMM_AMOUNT_LC_D-MgmImputation_tuple.IMM_AMOUNT_LC_C);


      fetch MgmImputation into MgmImputation_tuple;

    end loop;

    close MgmImputation;

  end;


  /**
  * Description Conversion des imputations analytiques par imputation financière
  */
  procedure ConvertMgmImputation(Document_Id IN number,
                                 FinImputation_Id IN number,
                                 old_currency_id IN number,
                                 new_currency_id IN number,
                                 exchange_rate IN number,
                                 base_price IN number,
                                 imp_tot IN number)
  is
    cursor MgmImputation(fin_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
          mgm.ACT_MGM_IMPUTATION_ID,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMM_AMOUNT_LC_C,new_currency_id,0, IMM_AMOUNT_FC_C) IMM_AMOUNT_FC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,IMM_AMOUNT_LC_D,new_currency_id,0, IMM_AMOUNT_FC_D) IMM_AMOUNT_FC_D,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMM_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(IMM_AMOUNT_LC_C*base_price/exchange_rate,0.01)) IMM_AMOUNT_LC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,IMM_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(IMM_AMOUNT_LC_D*base_price/exchange_rate,0.01)) IMM_AMOUNT_LC_D,
          new_currency_id ACS_ACS_FINANCIAL_CURRENCY_ID
       from act_mgm_imputation mgm
      where mgm.act_financial_imputation_id = fin_id
         -- or (mgm.act_financial_imputation_id is null and fin_id is null)
   order by ABS(IMM_AMOUNT_LC_C+IMM_AMOUNT_LC_D);
    MgmImputation_tuple MgmImputation%rowtype;
    solde ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    tot_mgm ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type;
    diff_fin_mgm ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
    last_imp ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin

    open MgmImputation(FinImputation_id,
                       old_currency_id,
                       new_currency_id,
                       exchange_rate,
                       base_price);

    fetch MgmImputation into MgmImputation_tuple;

    while MgmImputation%found loop

      last_imp := MgmImputation_tuple.ACT_MGM_IMPUTATION_ID;

      update ACT_MGM_IMPUTATION
         set IMM_AMOUNT_LC_C = MgmImputation_tuple.IMM_AMOUNT_LC_C,
             IMM_AMOUNT_LC_D = MgmImputation_tuple.IMM_AMOUNT_LC_D,
             IMM_AMOUNT_FC_C = MgmImputation_tuple.IMM_AMOUNT_FC_C,
             IMM_AMOUNT_FC_D = MgmImputation_tuple.IMM_AMOUNT_FC_C,
             ACS_ACS_FINANCIAL_CURRENCY_ID = MgmImputation_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID,
             A_RECSTATUS                   = 1
       where ACT_MGM_IMPUTATION_ID = MgmImputation_tuple.ACT_MGM_IMPUTATION_ID;

      ConvertMgmDistribution(MgmImputation_tuple.ACT_MGM_IMPUTATION_ID,
                             old_currency_id,
                             new_currency_id,
                             exchange_rate,
                             base_price,
                             MgmImputation_tuple.IMM_AMOUNT_LC_D-MgmImputation_tuple.IMM_AMOUNT_LC_C);


      fetch MgmImputation into MgmImputation_tuple;

    end loop;

    close MgmImputation;

    select SUM(IMM_AMOUNT_LC_D)-SUM(IMM_AMOUNT_LC_C) into tot_mgm
      from ACT_MGM_IMPUTATION
     where ACT_FINANCIAL_IMPUTATION_ID = FinImputation_Id;

    diff_fin_mgm := tot_mgm - imp_tot;

    if diff_fin_mgm <> 0 then

       update ACT_MGM_IMPUTATION
         set IMM_AMOUNT_LC_C = decode(sign(IMM_AMOUNT_LC_C),0,0,IMM_AMOUNT_LC_C-diff_fin_mgm),
             IMM_AMOUNT_LC_D = decode(sign(IMM_AMOUNT_LC_D),0,0,IMM_AMOUNT_LC_D-diff_fin_mgm),
             A_RECSTATUS                   = 1
       where ACT_MGM_IMPUTATION_ID = last_imp;

       update ACT_MGM_DISTRIBUTION
         set MGM_AMOUNT_LC_C = decode(sign(MGM_AMOUNT_LC_C),0,0,MGM_AMOUNT_LC_C-diff_fin_mgm),
             MGM_AMOUNT_LC_D = decode(sign(MGM_AMOUNT_LC_D),0,0,MGM_AMOUNT_LC_D-diff_fin_mgm),
             A_RECSTATUS                   = 1
        where ACT_MGM_DISTRIBUTION_ID = (select MAX(ACT_MGM_DISTRIBUTION_ID) from ACT_MGM_DISTRIBUTION
                                         where ACT_MGM_IMPUTATION_ID = last_imp);

    end if;


  end;

  /**
  * Description Conversion des distributions analytiques par imputation analytique
  */
  procedure ConvertMgmDistribution(MgmImputation_Id IN number,
                                   old_currency_id IN number,
                                   new_currency_id IN number,
                                   exchange_rate IN number,
                                   base_price IN number,
                                   imp_tot IN number)
  is
    cursor MgmDistribution(mgm_id number, old_currency_id number, new_currency_id number, exchange_rate number, base_price number) is
      select
          dis.ACT_MGM_DISTRIBUTION_ID,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,MGM_AMOUNT_LC_C,new_currency_id,0, MGM_AMOUNT_FC_C) MGM_AMOUNT_FC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,ACS_ACS_FINANCIAL_CURRENCY_ID,MGM_AMOUNT_LC_D,new_currency_id,0, MGM_AMOUNT_FC_D) MGM_AMOUNT_FC_D,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,MGM_AMOUNT_FC_C,ACS_FUNCTION.RoundNear(MGM_AMOUNT_LC_C*base_price/exchange_rate,0.01)) MGM_AMOUNT_LC_C,
          decode(ACS_FINANCIAL_CURRENCY_ID,new_currency_id,MGM_AMOUNT_FC_D,ACS_FUNCTION.RoundNear(MGM_AMOUNT_LC_D*base_price/exchange_rate,0.01)) MGM_AMOUNT_LC_D
       from act_mgm_distribution dis, act_mgm_imputation imp
      where imp.act_mgm_imputation_id = mgm_id
        and dis.act_mgm_imputation_id = imp.act_mgm_imputation_id
   order by ABS(MGM_AMOUNT_LC_C+MGM_AMOUNT_LC_D);
    MgmDistribution_tuple MgmDistribution%rowtype;
    last_dis ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
    tot_dis ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
    diff_imp_dis ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type;
  begin

    open MgmDistribution(MgmImputation_id,
                         old_currency_id,
                         new_currency_id,
                         exchange_rate,
                         base_price);

    fetch MgmDistribution into MgmDistribution_tuple;

    while MgmDistribution%found loop

      last_dis := MgmDistribution_tuple.ACT_MGM_DISTRIBUTION_ID;

      update ACT_MGM_DISTRIBUTION
         set MGM_AMOUNT_LC_C = MgmDistribution_tuple.MGM_AMOUNT_LC_C,
             MGM_AMOUNT_LC_D = MgmDistribution_tuple.MGM_AMOUNT_LC_D,
             MGM_AMOUNT_FC_C = MgmDistribution_tuple.MGM_AMOUNT_FC_C,
             MGM_AMOUNT_FC_D = MgmDistribution_tuple.MGM_AMOUNT_FC_C,
             A_RECSTATUS                   = 1
       where ACT_MGM_DISTRIBUTION_ID = MgmDistribution_tuple.ACT_MGM_DISTRIBUTION_ID;

      fetch MgmDistribution into MgmDistribution_tuple;

    end loop;

    close MgmDistribution;

    select SUM(MGM_AMOUNT_LC_D)-SUM(MGM_AMOUNT_LC_C) into tot_dis
      from ACT_MGM_DISTRIBUTION
     where ACT_MGM_IMPUTATION_ID = MgmImputation_Id;

    diff_imp_dis := imp_tot - tot_dis;

    if diff_imp_dis <> 0 then

       update ACT_MGM_DISTRIBUTION
         set MGM_AMOUNT_LC_C = decode(sign(MgmDistribution_tuple.MGM_AMOUNT_LC_C),0,0,MgmDistribution_tuple.MGM_AMOUNT_LC_C-diff_imp_dis),
             MGM_AMOUNT_LC_D = decode(sign(MgmDistribution_tuple.MGM_AMOUNT_LC_D),0,0,MgmDistribution_tuple.MGM_AMOUNT_LC_D-diff_imp_dis),
             A_RECSTATUS                   = 1
       where ACT_MGM_DISTRIBUTION_ID = last_dis;

    end if;

  end;

  procedure ControlImputationTotals(Document_ID IN number,
                                    Gain_Id IN number,
                                    Loss_id IN Number,
                                    Div_Gain_Id IN number,
                                    Div_Loss_id IN Number,
                                    sub_set_id IN number,
                                    Cpn_Gain_Id IN number,
                                    Cpn_Loss_id IN number,
                                    Cda_Gain_Id IN number,
                                    Cda_Loss_id IN number,
                                    Pf_Gain_Id IN number,
                                    Pf_Loss_id IN number,
                                    Pj_Gain_Id IN number,
                                    Pj_Loss_id IN number)
  is
    change_difference ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    fin_imp_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    mgm_imp_id ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin
    select SUM(IMF_AMOUNT_LC_D-IMF_AMOUNT_LC_C) into change_difference
      from ACT_FINANCIAL_IMPUTATION
     where ACT_DOCUMENT_ID = Document_Id;

    if change_difference <> 0 then

      update act_document set A_RECSTATUS = 2 where ACT_DOCUMENT_ID = Document_Id;

      select init_id_seq.nextval into fin_imp_id from dual;

      insert into ACT_FINANCIAL_IMPUTATION(
        ACT_FINANCIAL_IMPUTATION_ID,
        ACT_DOCUMENT_ID,
        ACT_PART_IMPUTATION_ID,
        ACS_PERIOD_ID,
        ACS_FINANCIAL_CURRENCY_ID,
        ACS_ACS_FINANCIAL_CURRENCY_ID,
        IMF_BASE_PRICE,
        IMF_EXCHANGE_RATE,
        IMF_TRANSACTION_DATE,
        IMF_VALUE_DATE,
        IMF_PRIMARY,
        IMF_GENRE,
        IMF_TYPE,
        IMF_DESCRIPTION,
        ACS_FINANCIAL_ACCOUNT_ID,
        IMF_AMOUNT_LC_D,
        IMF_AMOUNT_LC_C,
        IMF_AMOUNT_FC_D,
        IMF_AMOUNT_FC_C,
        C_GENRE_TRANSACTION,
        A_RECSTATUS,
        A_DATECRE,
        A_IDCRE)
      select
        fin_imp_id,
        ACT_DOCUMENT_ID,
        ACT_PART_IMPUTATION_ID,
        ACS_PERIOD_ID,
        ACS_FINANCIAL_CURRENCY_ID,
        ACS_ACS_FINANCIAL_CURRENCY_ID,
        0,
        0,
        IMF_TRANSACTION_DATE,
        IMF_VALUE_DATE,
        0,
        'STD',
        'MAN',
        'Currency conversion, round difference',
        decode(sign(change_difference),1,Gain_Id,-1,Loss_id),
        decode(sign(change_difference),-1,-Change_difference,0),
        decode(sign(change_difference),1,Change_difference,0),
        0,
        0,
        '7', --C_GENRE_TRANSACTION,
        2,
        sysdate,
        PCS.PC_I_LIB_SESSION.GetUserIni
      from ACT_FINANCIAL_IMPUTATION
      where ACT_FINANCIAL_IMPUTATION_ID =
                  (SELECT MIN(ACT_FINANCIAL_IMPUTATION_ID) from ACT_FINANCIAL_IMPUTATION where ACT_DOCUMENT_ID = Document_ID);

      if sub_set_id is not null then

        insert into ACT_FINANCIAL_DISTRIBUTION(
           ACT_FINANCIAL_DISTRIBUTION_ID,
           ACT_FINANCIAL_IMPUTATION_ID,
           FIN_DESCRIPTION,
           ACS_SUB_SET_ID,
           ACS_DIVISION_ACCOUNT_ID,
           FIN_AMOUNT_LC_C,
           FIN_AMOUNT_LC_D,
           FIN_AMOUNT_FC_C,
           FIN_AMOUNT_FC_D,
           A_RECSTATUS,
           A_DATECRE,
           A_IDCRE)
        values(
           init_id_seq.nextval,
           fin_imp_id,
           'Currency conversion, round difference',
           sub_set_id,
           decode(sign(change_difference),1,div_gain_id,-1,div_loss_id),
           decode(sign(change_difference),-1,-Change_difference,0),
           decode(sign(change_difference),1,Change_difference,0),
           0,
           0,
           2,
           sysdate,
           PCS.PC_I_LIB_SESSION.GetUserIni);

      end if;

      if (cda_gain_id is not null or
          cda_loss_id is not null or
          pf_gain_id  is not null or
          pf_loss_id  is not null or
          pj_gain_id  is not null or
          pj_loss_id  is not null)  then

        select init_id_seq.nextval into mgm_imp_id from dual;

        insert into ACT_MGM_IMPUTATION(
          ACT_MGM_IMPUTATION_ID,
          ACT_FINANCIAL_IMPUTATION_ID,
          ACT_DOCUMENT_ID,
          ACS_PERIOD_ID,
          ACS_FINANCIAL_CURRENCY_ID,
          ACS_ACS_FINANCIAL_CURRENCY_ID,
          IMM_PRIMARY,
          IMM_TYPE,
          IMM_GENRE,
          IMM_DESCRIPTION,
          IMM_TRANSACTION_DATE,
          IMM_VALUE_DATE,
          ACS_CPN_ACCOUNT_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          IMM_AMOUNT_LC_D,
          IMM_AMOUNT_LC_C,
          IMM_AMOUNT_FC_D,
          IMM_AMOUNT_FC_C,
          A_RECSTATUS,
          A_DATECRE,
          A_IDCRE
         )
        SELECT
          mgm_imp_id,
          fin_imp_id,
          ACT_DOCUMENT_ID,
          ACS_PERIOD_ID,
          ACS_FINANCIAL_CURRENCY_ID,
          ACS_ACS_FINANCIAL_CURRENCY_ID,
          0,
          IMM_TYPE,
          IMM_GENRE,
          'Currency conversion, round difference',
          IMM_TRANSACTION_DATE,
          IMM_VALUE_DATE,
          decode(sign(change_difference),1,cpn_gain_Id,-1,cpn_Loss_id),
          decode(sign(change_difference),1,cda_gain_Id,-1,cda_Loss_id),
          decode(sign(change_difference),1,pf_gain_Id,-1,pf_Loss_id),
          decode(sign(change_difference),-1,-Change_difference,0),
          decode(sign(change_difference),1,Change_difference,0),
          0,
          0,
          2,
          sysdate,
          PCS.PC_I_LIB_SESSION.GetUserIni
        from ACT_MGM_IMPUTATION
        where ACT_MGM_IMPUTATION_ID =
                  (SELECT MIN(ACT_MGM_IMPUTATION_ID) from ACT_MGM_IMPUTATION where ACT_DOCUMENT_ID = Document_Id);

        if (pj_gain_id  is not null or
            pj_loss_id  is not null) and sub_set_id is not null then

          insert into ACT_MGM_DISTRIBUTION(
             ACT_MGM_DISTRIBUTION_ID,
             ACT_MGM_IMPUTATION_ID,
             ACS_PJ_ACCOUNT_ID,
             ACS_SUB_SET_ID,
             MGM_DESCRIPTION,
             MGM_AMOUNT_LC_D,
             MGM_AMOUNT_LC_C,
             MGM_AMOUNT_FC_D,
             MGM_AMOUNT_FC_C,
             A_RECSTATUS,
             A_DATECRE,
             A_IDCRE)
           values(
             init_id_seq.nextval,
             mgm_imp_id,
             decode(sign(change_difference),1,pj_gain_Id,-1,pj_Loss_id),
             sub_set_id,
             'Currency conversion, round difference',
             decode(sign(change_difference),-1,-Change_difference,0),
             decode(sign(change_difference),1,Change_difference,0),
             0,
             0,
             2,
             sysdate,
             PCS.PC_I_LIB_SESSION.GetUserIni);

        end if;

      end if;

    end if;

  end;

  /**
  * Description  Convertion des budgets et recalcul des totaux
  */
  procedure ConvertBudget(old_currency_id IN number,
                          new_currency_id IN number,
                          exchange_rate IN number,
                          base_price IN number)
  is
  begin

    update ACB_PERIOD_AMOUNT
      set  PER_AMOUNT_D = ACS_FUNCTION.RoundNear(PER_AMOUNT_D*base_price/exchange_rate,0.01),
           PER_AMOUNT_C = ACS_FUNCTION.RoundNear(PER_AMOUNT_C*base_price/exchange_rate,0.01);

    update acb_global_budget main
      set (GLO_AMOUNT_D, GLO_AMOUNT_C) =
         (select SUM(PER_AMOUNT_D), SUM(PER_AMOUNT_C)
            from ACB_PERIOD_AMOUNT
           where ACB_GLOBAL_BUDGET_ID = main.ACB_GLOBAL_BUDGET_ID);


  end;

  function CountPaymentProblems return number
  is
    result integer;
  begin

    -- Recherche du nombre de documents posant problème
    select
       count(*) into result
     from
      (select
              exp.act_expiry_id,
              exp.exp_discount_lc,
              exp.exp_amount_lc,
              act_functions.TOTALPAYMENT(exp.act_expiry_id,1) det_paied_lc
         from
              act_expiry exp
        where
              exp.c_status_expiry = 1 and
              exp.exp_calc_net = 1) ctrl
    where
      abs(ctrl.exp_amount_lc - ctrl.det_paied_lc) <> 0;

   return result;

  end;

  /**
  * Description
  *      Fonction de correction d'arrondi des paiements suite à la conversion
  */
  procedure ControlPaymentTotal(new_currency_id IN number, aContinue OUT number)
  is
    det_payment_id ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type;
    document_id ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    financial_imputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    part_imputation_id ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    coll_imputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    mgm_imputation_id ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
    already_diff number(1);
    imp_amount act_financial_imputation.imf_amount_lc_c%type;
    amount_lc_c act_financial_imputation.imf_amount_lc_c%type;
    amount_lc_d act_financial_imputation.imf_amount_lc_d%type;
    sub_set ACJ_SUB_SET_CAT.C_SUB_SET%type;
    financial_account_id ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    auxiliary_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    division_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    coll_division_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    third_id PAC_THIRD.PAC_THIRD_ID%type;
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
    cpn_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    cda_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    pf_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    pj_account_id ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin

    if not problems%isopen then
      open problems;
    end if;

    fetch problems into problems_tuple;

    -- recherche du sosu-ensemble par défaut pour les division
    SELECT MAX(ACS_SUB_SET_ID) INTO sub_set_id FROM ACS_SUB_SET WHERE C_TYPE_SUB_SET = 'DIVI';

    if problems%found then

      -- recherche du dernier detail paiement sur lequel on doit imputer la différence de change
      select max(act_det_payment_id) into det_payment_id
        from act_det_payment
       where act_expiry_id = problems_tuple.act_expiry_id;

      -- recherche l'id du document de paiement et si on a déjà une différence de change
      select
          act_document_id,
          act_part_imputation_id,
          sign(abs(det_diff_exchange)),
          problems_tuple.calc_diff
        into
          document_id,
          part_imputation_id,
          already_diff,
          imp_amount
        from act_det_payment
       where act_det_payment_id = det_payment_id;

      -- recherche de l'id de l'imputation financière à modifier
      select MAX(act_financial_imputation_id) into financial_imputation_id
        from act_financial_imputation
       where act_det_payment_id = det_payment_id
         and c_genre_transaction = '4'
         and acs_auxiliary_account_id is not null;

      -- recherche de l'id de l'imputation financière à modifier compte collectif
      select MAX(act_financial_imputation_id) into coll_imputation_id
        from act_financial_imputation
       where act_det_payment_id = det_payment_id
         and c_genre_transaction = '4'
         and acs_auxiliary_account_id is null;

      -- recherche du type de sous-ensemble
      select MAX(b.c_sub_set), max(NVL(PAC_CUSTOM_PARTNER_ID,PAC_SUPPLIER_PARTNER_ID)) into sub_set, third_id
        from act_document a, acj_sub_set_cat b, act_part_imputation c
       where a.act_document_id = document_id
         and c.act_part_imputation_id = part_imputation_id
         and a.acj_catalogue_document_id = b.acj_catalogue_document_id
         and b.c_sub_set in ('REC','PAY');

      -- mise à jour des montants de paiement
      update act_det_payment
        set det_diff_exchange = det_diff_exchange + imp_amount
       where act_det_payment_id = det_payment_id;

      -- mise à jour du status du document de paiement
      update act_document
         set a_recstatus = 2
       where act_document_id = document_id;

      -- recherche de l'id de l'imputation financière à modifier
      select MAX(act_financial_imputation_id) into financial_imputation_id
        from act_financial_imputation
       where act_det_payment_id = det_payment_id
         and c_genre_transaction = '4'
         and acs_auxiliary_account_id is not null;

      -- recherche de l'id de l'imputation financière à modifier compte collectif
      select MAX(act_financial_imputation_id) into coll_imputation_id
        from act_financial_imputation
       where act_det_payment_id = det_payment_id
         and c_genre_transaction = '4'
         and acs_auxiliary_account_id is null;

      -- si la nouvelle différence de change = 0
      if imp_amount = 0 then
        -- effacement des imputations financière et des distribution et de l'analytique lié (effacement en cascade)
        delete from act_financial_imputation where act_financial_imputation_id in (financial_imputation_id, coll_imputation_id);
      else

        -- définition des montants débit crédit
        if sub_set = 'REC' then
          if imp_amount > 0 then
            amount_lc_c := abs(imp_amount);
            amount_lc_d := 0;
          else
            amount_lc_c := 0;
            amount_lc_d := abs(imp_amount);
          end if;
        elsif sub_set = 'PAY' then
          if imp_amount > 0 then
            amount_lc_c := 0;
            amount_lc_d := abs(imp_amount);
          else
            amount_lc_c := abs(imp_amount);
            amount_lc_d := 0;
          end if;
        end if;

        -- si on avait déjà une différence de change, on met à jour les imputations existantes
        if already_diff = 1 then

          ---------------------
          -- compte collectif
          ---------------------

          -- mise à jour de l'imputation financière liée au paiement
          update ACT_FINANCIAL_IMPUTATION
             set IMF_AMOUNT_LC_C = amount_lc_c,
                 IMF_AMOUNT_LC_D = amount_lc_d,
                 A_RECSTATUS = 2
           where ACT_FINANCIAL_IMPUTATION_ID = coll_imputation_id;

          update ACT_FINANCIAL_DISTRIBUTION
             set FIN_AMOUNT_LC_C = amount_lc_c,
                 FIN_AMOUNT_LC_D = amount_lc_d,
                 A_RECSTATUS = 2
           where act_financial_imputation_id = coll_imputation_id;

          -------------------------
          -- difference de change
          -------------------------

          -- mise à jour de l'imputation financière liée au paiement
          update ACT_FINANCIAL_IMPUTATION
             set IMF_AMOUNT_LC_C = amount_lc_d,
                 IMF_AMOUNT_LC_D = amount_lc_c,
                 A_RECSTATUS = 2
           where ACT_FINANCIAL_IMPUTATION_ID = financial_imputation_id;

          update ACT_FINANCIAL_DISTRIBUTION
             set FIN_AMOUNT_LC_C = amount_lc_d,
                 FIN_AMOUNT_LC_D = amount_lc_c,
                 A_RECSTATUS = 2
           where act_financial_imputation_id = financial_imputation_id;

          -- recherche d'éventuelles imputations analytiques
          select max(ACT_MGM_IMPUTATION_ID) into mgm_imputation_id
            from ACT_MGM_IMPUTATION
           where act_financial_imputation_id = financial_imputation_id;

          -- si on a de l'analytique
          if mgm_imputation_id is not null then

            update ACT_MGM_IMPUTATION
               set IMM_AMOUNT_LC_C = amount_lc_d,
                   IMM_AMOUNT_LC_D = amount_lc_c,
                   A_RECSTATUS = 2
            where ACT_MGM_IMPUTATION_ID = mgm_imputation_id;

            update ACT_MGM_DISTRIBUTION
               set MGM_AMOUNT_LC_C = amount_lc_d,
                   MGM_AMOUNT_LC_D = amount_lc_c,
                   A_RECSTATUS = 2
            where ACT_MGM_IMPUTATION_ID = mgm_imputation_id;

          end if;

        -- pas encore de différence de change
        else

          -- diff de change

          -- recherche des comptes dans la monnaie
          select decode(sub_set,'REC',decode(sign(imp_amount),1,ACS_GAIN_EXCH_COMP_ID,ACS_LOSS_EXCH_COMP_ID),
                                'PAY',decode(sign(imp_amount),1,ACS_GAIN_EXCH_DEBT_ID,ACS_LOSS_EXCH_DEBT_ID)),
                 decode(sub_set,'REC',decode(sign(imp_amount),1,ACS_CDA_COMP_GAIN_ID,ACS_CDA_COMP_LOSS_ID),
                                'PAY',decode(sign(imp_amount),1,ACS_CDA_GAIN_EXCH_DEBT_ID,ACS_CDA_LOSS_EXCH_DEBT_ID)),
                 decode(sub_set,'REC',decode(sign(imp_amount),1,ACS_PF_COMP_GAIN_ID,ACS_PF_COMP_LOSS_ID),
                                'PAY',decode(sign(imp_amount),1,ACS_PF_GAIN_EXCH_DEBT_ID,ACS_PF_LOSS_EXCH_DEBT_ID)),
                 decode(sub_set,'REC',decode(sign(imp_amount),1,ACS_PJ_COMP_GAIN_ID,ACS_PJ_COMP_LOSS_ID),
                                'PAY',decode(sign(imp_amount),1,ACS_PJ_GAIN_EXCH_DEBT_ID,ACS_PJ_LOSS_EXCH_DEBT_ID))
             into financial_account_id, cda_account_id, pf_account_id, pj_account_id
            from ACS_FINANCIAL_CURRENCY
            where ACS_FINANCIAL_CURRENCY_ID = new_currency_id;


          -- recherche de l'id pour l'imputation financière
          select init_id_seq.nextval into financial_imputation_id from dual;
          begin
          -- création de l'imputation de diff de change
          insert into ACT_FINANCIAL_IMPUTATION(
            ACT_FINANCIAL_IMPUTATION_ID,
            ACT_DOCUMENT_ID,
            ACT_PART_IMPUTATION_ID,
            ACT_DET_PAYMENT_ID,
            ACS_PERIOD_ID,
            ACS_FINANCIAL_CURRENCY_ID,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            IMF_BASE_PRICE,
            IMF_EXCHANGE_RATE,
            IMF_TRANSACTION_DATE,
            IMF_VALUE_DATE,
            IMF_PRIMARY,
            IMF_GENRE,
            IMF_TYPE,
            IMF_DESCRIPTION,
            ACS_FINANCIAL_ACCOUNT_ID,
            IMF_AMOUNT_LC_D,
            IMF_AMOUNT_LC_C,
            IMF_AMOUNT_FC_D,
            IMF_AMOUNT_FC_C,
            C_GENRE_TRANSACTION,
            A_RECSTATUS,
            A_DATECRE,
            A_IDCRE)
          select
            financial_imputation_id,
            ACT_DOCUMENT_ID,
            ACT_PART_IMPUTATION_ID,
            det_payment_id,
            ACS_PERIOD_ID,
            ACS_FINANCIAL_CURRENCY_ID,
            ACS_ACS_FINANCIAL_CURRENCY_ID,
            0,
            0,
            IMF_TRANSACTION_DATE,
            IMF_VALUE_DATE,
            0,
            'STD',
            'MAN',
            'Currency conversion, difference of exchange',
            financial_account_id,
            amount_lc_c,
            amount_lc_d,
            0,
            0,
            '7', --C_GENRE_TRANSACTION,
            2,
            sysdate,
            PCS.PC_I_LIB_SESSION.GetUserIni
          from ACT_FINANCIAL_IMPUTATION
          where ACT_FINANCIAL_IMPUTATION_ID =
                      (SELECT MIN(ACT_FINANCIAL_IMPUTATION_ID) from ACT_FINANCIAL_IMPUTATION where ACT_PART_IMPUTATION_ID = part_imputation_id);
          exception
            when others then
              raise_application_error(-20000,to_char(financial_account_id)||'/'||to_char(part_imputation_id));
          end;

          if sub_set_id is not null then

            -- recherche du compte division
            division_account_id := ACS_FUNCTION.GetDivisionOfAccount(financial_account_id, division_account_id, sysdate);

            -- création de la distribution financière
            insert into ACT_FINANCIAL_DISTRIBUTION(
               ACT_FINANCIAL_DISTRIBUTION_ID,
               ACT_FINANCIAL_IMPUTATION_ID,
               FIN_DESCRIPTION,
               ACS_SUB_SET_ID,
               ACS_DIVISION_ACCOUNT_ID,
               FIN_AMOUNT_LC_D,
               FIN_AMOUNT_LC_C,
               FIN_AMOUNT_FC_D,
               FIN_AMOUNT_FC_C,
               A_RECSTATUS,
               A_DATECRE,
               A_IDCRE)
            values(
               init_id_seq.nextval,
               financial_imputation_id,
               'Currency conversion, difference of exchange',
               sub_set_id,
               division_account_id,
               amount_lc_c,
               amount_lc_d,
               0,
               0,
               2,
               sysdate,
               PCS.PC_I_LIB_SESSION.GetUserIni);

          end if;


          -- si on a de l'analytique
          if  cda_account_id is not null or
              pf_account_id  is not null or
              pj_account_id  is not null then

            -- recherche du compte CPN
            Cpn_Account_Id := ACT_CREATION_SBVR.GetCPNAccOfFINAcc(financial_account_id);

            select init_id_seq.nextval into mgm_imputation_id from dual;

            -- création de l'imputation analytique
            insert into ACT_MGM_IMPUTATION(
              ACT_MGM_IMPUTATION_ID,
              ACT_FINANCIAL_IMPUTATION_ID,
              ACT_DOCUMENT_ID,
              ACS_PERIOD_ID,
              ACS_FINANCIAL_CURRENCY_ID,
              ACS_ACS_FINANCIAL_CURRENCY_ID,
              IMM_PRIMARY,
              IMM_TYPE,
              IMM_GENRE,
              IMM_DESCRIPTION,
              IMM_TRANSACTION_DATE,
              IMM_VALUE_DATE,
              ACS_CPN_ACCOUNT_ID,
              ACS_CDA_ACCOUNT_ID,
              ACS_PF_ACCOUNT_ID,
              IMM_AMOUNT_LC_D,
              IMM_AMOUNT_LC_C,
              IMM_AMOUNT_FC_D,
              IMM_AMOUNT_FC_C,
              A_RECSTATUS,
              A_DATECRE,
              A_IDCRE
             )
            SELECT
              mgm_imputation_id,
              financial_imputation_id,
              ACT_DOCUMENT_ID,
              ACS_PERIOD_ID,
              ACS_FINANCIAL_CURRENCY_ID,
              ACS_ACS_FINANCIAL_CURRENCY_ID,
              0,
              IMM_TYPE,
              IMM_GENRE,
              'Currency conversion, difference of exchange',
              IMM_TRANSACTION_DATE,
              IMM_VALUE_DATE,
              cpn_Account_id,
              cda_account_id,
              pf_account_id,
              amount_lc_c,
              amount_lc_d,
              0,
              0,
              2,
              sysdate,
              PCS.PC_I_LIB_SESSION.GetUserIni
            from ACT_MGM_IMPUTATION
            where ACT_MGM_IMPUTATION_ID =
                      (SELECT MIN(ACT_MGM_IMPUTATION_ID) from ACT_MGM_IMPUTATION where ACT_DOCUMENT_ID = document_id);

            -- si projet défini
            if pj_account_id  is not null and sub_set_id is not null then

              -- création de la distribution analytique
              insert into ACT_MGM_DISTRIBUTION(
                 ACT_MGM_DISTRIBUTION_ID,
                 ACT_MGM_IMPUTATION_ID,
                 ACS_PJ_ACCOUNT_ID,
                 ACS_SUB_SET_ID,
                 MGM_DESCRIPTION,
                 MGM_AMOUNT_LC_D,
                 MGM_AMOUNT_LC_C,
                 MGM_AMOUNT_FC_D,
                 MGM_AMOUNT_FC_C,
                 A_RECSTATUS,
                 A_DATECRE,
                 A_IDCRE)
               values(
                 init_id_seq.nextval,
                 mgm_imputation_id,
                 pj_account_id,
                 sub_set_id,
                 'Currency conversion, difference of exchange',
                 amount_lc_c,
                 amount_lc_d,
                 0,
                 0,
                 2,
                 sysdate,
                 PCS.PC_I_LIB_SESSION.GetUserIni);

              end if;

            end if;

          end if;


          ---------------------------
          -- collectif
          ---------------------------

          if sub_set = 'REC' then
            select acs_auxiliary_account_id into auxiliary_account_id
              from PAC_CUSTOM_PARTNER
             where pac_custom_partner_id = third_id;
          elsif sub_set = 'PAY' then
            select acs_auxiliary_account_id into auxiliary_account_id
              from PAC_SUPPLIER_PARTNER
             where pac_supplier_partner_id = third_id;
          end if;

          -- recherche de l'id pour l'imputation financière
          select init_id_seq.nextval into financial_imputation_id from dual;

          -- recherche compte financier
          financial_account_id := ACT_CREATION_SBVR.GetFinAccount_id(auxiliary_account_id, problems_tuple.origin_document_id);

          begin
            -- création de l'imputation sur compte collectif
            insert into ACT_FINANCIAL_IMPUTATION(
              ACT_FINANCIAL_IMPUTATION_ID,
              ACT_DOCUMENT_ID,
              ACT_PART_IMPUTATION_ID,
              ACT_DET_PAYMENT_ID,
              ACS_PERIOD_ID,
              ACS_FINANCIAL_CURRENCY_ID,
              ACS_ACS_FINANCIAL_CURRENCY_ID,
              IMF_BASE_PRICE,
              IMF_EXCHANGE_RATE,
              IMF_TRANSACTION_DATE,
              IMF_VALUE_DATE,
              IMF_PRIMARY,
              IMF_GENRE,
              IMF_TYPE,
              IMF_DESCRIPTION,
              ACS_FINANCIAL_ACCOUNT_ID,
              ACS_AUXILIARY_ACCOUNT_ID,
              IMF_AMOUNT_LC_C,
              IMF_AMOUNT_LC_D,
              IMF_AMOUNT_FC_C,
              IMF_AMOUNT_FC_D,
              C_GENRE_TRANSACTION,
              A_RECSTATUS,
              A_DATECRE,
              A_IDCRE)
            select
              financial_imputation_id,
              ACT_DOCUMENT_ID,
              ACT_PART_IMPUTATION_ID,
              det_payment_id,
              ACS_PERIOD_ID,
              ACS_FINANCIAL_CURRENCY_ID,
              ACS_ACS_FINANCIAL_CURRENCY_ID,
              0,
              0,
              IMF_TRANSACTION_DATE,
              IMF_VALUE_DATE,
              0,
              'STD',
              'MAN',
              'Currency conversion, difference of exchange',
              financial_account_id,
              auxiliary_account_id,
              amount_lc_c,
              amount_lc_d,
              0,
              0,
              '7', --C_GENRE_TRANSACTION,
              2,
              sysdate,
              PCS.PC_I_LIB_SESSION.GetUserIni
            from ACT_FINANCIAL_IMPUTATION
            where ACT_FINANCIAL_IMPUTATION_ID =
                        (SELECT MIN(ACT_FINANCIAL_IMPUTATION_ID) from ACT_FINANCIAL_IMPUTATION where ACT_PART_IMPUTATION_ID = part_imputation_id);
          exception
            when others then
              raise_application_error(-20000,to_char(financial_account_id));
          end;

          if sub_set_id is not null then

            -- recherche du compte division
            coll_division_account_id := ACS_FUNCTION.GetDivisionOfAccount(financial_account_id, coll_division_account_id, sysdate);

            -- création de la distribution
            insert into ACT_FINANCIAL_DISTRIBUTION(
               ACT_FINANCIAL_DISTRIBUTION_ID,
               ACT_FINANCIAL_IMPUTATION_ID,
               FIN_DESCRIPTION,
               ACS_SUB_SET_ID,
               ACS_DIVISION_ACCOUNT_ID,
               FIN_AMOUNT_LC_C,
               FIN_AMOUNT_LC_D,
               FIN_AMOUNT_FC_C,
               FIN_AMOUNT_FC_D,
               A_RECSTATUS,
               A_DATECRE,
               A_IDCRE)
            values(
               init_id_seq.nextval,
               financial_imputation_id,
              'Currency conversion, difference of exchange',
               sub_set_id,
               coll_division_account_id,
               amount_lc_c,
               amount_lc_d,
               0,
               0,
               2,
               sysdate,
               PCS.PC_I_LIB_SESSION.GetUserIni);

        end if;

      end if;

      aContinue := 1;

    -- plus de tuple dans le curseur "problems"
    else
      aContinue := 0;
      close problems;
    end if;

  end;











  -----------------------------------------
  procedure ConvertAmount(aAmount        in number,
                          aFromFinCurrId in number,
                          aToFinCurrId   in number,
                          aDate          in Date,
                          aExchangeRate  in number,
                          aBasePrice     in number,
                          aRound         in number,
                          aAmountEUR     in out number,
                          aAmountConvert in out number,
                          aRateType      in number default 1)
  is
    ExchangeRateFound number(1);
    BaseChange number(1);
    FixedRateEUR_ME number (1);
    FixedRateEUR_MB number (1);
    RateExchange ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%Type;
    BasePrice ACS_PRICE_CURRENCY.PCU_BASE_PRICE%Type;
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%Type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%Type;
    CONST_RoundAmountEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%Type;
    CONST_RoundTypeEUR number (1);
  begin
    --{** Valeur et type d'arrondi pour l'Euro **}


    -- début Modification par rapport à ACS_FUNCTION
    CONST_RoundAmountEUR  := 0;   -- pas d'arrondi
    -- fin Modification par rapport à ACS_FUNCTION


    CONST_RoundTypeEUR    := 0;       --Arrondi au plus près

    aAmountConvert := aAmount;

    if aFromFinCurrId = ACS_FUNCTION.GetEuroCurrency then
      aAmountEUR := aAmount;
    else
      aAmountEUR := 0;
    end if;

    if aFromFinCurrId <> aToFinCurrId then
      if aFromFinCurrId = ACS_FUNCTION.GetLocalCurrencyID then
      --{*** Conversion MB -> ME ***}
        ExchangeRateFound := ACS_FUNCTION.GetRateOfExchangeEUR( aToFinCurrId, aRateType, aDate,
                                                                RateExchange, BasePrice, BaseChange,
                                                                RateExchangeEUR_ME, FixedRateEUR_ME,
                                                                RateExchangeEUR_MB, FixedRateEUR_MB );

        if (aExchangeRate <> 0) and (aBasePrice <> 0) then
          RateExchange := aExchangeRate;
          BasePrice := aBasePrice;
          BaseChange := 1;
        end if;

        if FixedRateEUR_MB = 1 then
          aAmountEUR := aAmount / RateExchangeEUR_MB;
        elsif (FixedRateEUR_ME = 1) or (aToFinCurrId = ACS_FUNCTION.GetEuroCurrency) then
          if BaseChange = 1 then
            aAmountEUR := aAmount / RateExchange * BasePrice;
          else
            aAmountEUR := aAmount * RateExchange / BasePrice;
          end if;
        end if;

        if aToFinCurrId = ACS_FUNCTION.GetEuroCurrency then
          aAmountConvert := ACS_FUNCTION.RoundNear(aAmountEUR, CONST_RoundAmountEUR, CONST_RoundTypeEUR);
        elsif (FixedRateEUR_ME = 0) and (FixedRateEUR_MB = 0) then
          if BaseChange = 1 then
            aAmountConvert := aAmount / RateExchange * BasePrice;
          else
            aAmountConvert := aAmount * RateExchange / BasePrice;
          end if;
        else
          if FixedRateEUR_ME = 1 then
            aAmountConvert := aAmountEUR * RateExchangeEUR_ME;
          else
            if BaseChange = 1 then
              aAmountConvert := aAmountEUR / RateExchange * BasePrice;
            else
              aAmountConvert := aAmountEUR * RateExchange / BasePrice;
            end if;
           end if;
        end if;
      else
      --{*** Conversion ME -> MB ***}
        ExchangeRateFound := ACS_FUNCTION.GetRateOfExchangeEUR( aFromFinCurrId, aRateType, aDate,
                                RateExchange, BasePrice, BaseChange,
                                RateExchangeEUR_ME, FixedRateEUR_ME,
                                RateExchangeEUR_MB, FixedRateEUR_MB );

        if (aExchangeRate <> 0) and (aBasePrice <> 0) then
          RateExchange := aExchangeRate;
          BasePrice := aBasePrice;
          BaseChange := 1;
        end if;

        if FixedRateEUR_ME = 1 then
          aAmountEUR := aAmount / RateExchangeEUR_ME;
        elsif (FixedRateEUR_MB = 1) or (aToFinCurrId = ACS_FUNCTION.GetEuroCurrency) then
          if BaseChange = 1 then
            aAmountEUR := aAmount * RateExchange / BasePrice;
          else
            aAmountEUR := aAmount / RateExchange * BasePrice;
          end if;
        end if;

        if aToFinCurrId = ACS_FUNCTION.GetEuroCurrency then
          aAmountConvert := ACS_FUNCTION.RoundNear(aAmountEUR, CONST_RoundAmountEUR, CONST_RoundTypeEUR);
        elsif (FixedRateEUR_ME = 0) and (FixedRateEUR_MB = 0) then
          if BaseChange = 1 then
            aAmountConvert := aAmount * RateExchange / BasePrice;
          else
            aAmountConvert := aAmount / RateExchange * BasePrice;
          end if;
        else
          if FixedRateEUR_MB = 1 then
            aAmountConvert := aAmountEUR * RateExchangeEUR_MB;
          else
            if BaseChange = 1 then
              aAmountConvert := aAmountEUR * RateExchange / BasePrice;
            else
              aAmountConvert := aAmountEUR / RateExchange * BasePrice;
            end if;
          end if;
        end if;
      end if;

    elsif aFromFinCurrId = ACS_FUNCTION.GetLocalCurrencyID then
      ExchangeRateFound := ACS_FUNCTION.GetRateOfExchangeEUR( aFromFinCurrId, aRateType, aDate,
                                                              RateExchange, BasePrice, BaseChange,
                                                              RateExchangeEUR_ME, FixedRateEUR_ME,
                                                              RateExchangeEUR_MB, FixedRateEUR_MB );

      if FixedRateEUR_MB = 1 then
        aAmountEUR := aAmount / RateExchangeEUR_MB;
      end if;

    end if;

    --{*** Arrondi selon table des monnaies ***}
    if aRound = 1 then
      aAmountConvert := ACS_FUNCTION.RoundAmount(aAmountConvert, aToFinCurrId);
    end if;

    aAmountEUR := ACS_FUNCTION.RoundNear(aAmountEUR, CONST_RoundAmountEUR, CONST_RoundTypeEUR);

  exception
    when ZERO_DIVIDE then
      aAmountEUR     := 0;
      aAmountConvert := 0;
  end;


  -----------------------------------------
  function ConvertAmountForView(aAmount        in number,
                          aFromFinCurrId in number,
                          aToFinCurrId   in number,
                          aDate          in Date,
                          aExchangeRate  in number,
                          aBasePrice     in number,
                          aRound         in number,
                          aRateType      in number default 1) return number
  is
    AmountEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%Type;
    AmountConvert ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%Type;
  begin
    ConvertAmount(aAmount,
                  aFromFinCurrId,
                  aToFinCurrId,
                  aDate,
                  aExchangeRate,
                  aBasePrice,
                  aRound,
                  AmountEUR,
                  AmountConvert,
                  aRateType);

    return AmountConvert;

  end;


end;
