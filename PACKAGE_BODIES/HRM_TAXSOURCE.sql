--------------------------------------------------------
--  DDL for Package Body HRM_TAXSOURCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_TAXSOURCE" 
/**
 * Package de fonctions utilisables pour le calcul de l'impôt à la source.
 *
 * @version 1.0
 * @date 01.2011
 * @author rhermann
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.


    La déduction ramène le solde pour l'année du ledger, du mois courant et des régularisations pour autant que le nom du GS de déduction soit passé en paramètre

    Pour le canton de Vaud :
        Le salaire déterminant est constitué de la rémunération annualisée perçue avec un barème de ce canton ( hors accessoire )
        Le salaire soumis est constitué de la rémunération effectivement perçue par période d'assujettissement

    Pour le canton du Tessin :
        Le salaire déterminant est constitué de la rémunération annualisée perçue avec un barème de ce canton ( hors accessoire )
        Le salaire soumis est constitué de la rémunération annuelle perçue dans ce canton ramenée au nombre de jours de la période d'assujettissement

    Pour Genève :
        Le salaire déterminant est constitué de la rémunération annualisée perçue par période d'assujettissement
        Le salaire soumis est constitué de la rémunération effectivement perçue par période d'assujettissement

    Pour les cantons mensualisés :
        Le salaire déterminant est constitué de la rémunération du mois ajustée au mois complet le cas échéant
        Le salaire soumis est constitué de la rémunération effectivement perçue du mois
        Les mois précédents ne sont pas recalculés


    En cas de départ : la rémunération perçue ultérieurement est rajoutée au mois du départ, aussi bien pour le déterminant que le soumis

    Les corrections saisies manuellement sont considérées dans le calcul pour autant qu'il y ait une période d'assujettissement qui soit liée, par conséquent il est obligatoire d'avoir une période d'assujettissement à moins qu'il ne s'agissait d'une erreur de canton


    Mise à jour du journal :
        Lorsqu'il y a différence entre le journal et la collection ramenée :
          S'il existe déjà un record pour le mois et le canton :
            - qui n'a pas été déclaré pour le mois :  supprimer les records et les re-créer
            - qui a été déclaré pour le mois : il faut extourner les lignes qui n'ont pas encore été extournées et ajouter un nouveau record avec les nouvelles valeurs
          S'il n'existe pas de record pour le mois et le canton :
            - Ajouter un nouveau record avec les nouvelles valeurs

        Le salaire déterminant doit être mis à jour sur une ligne du journal que si le montant soumis ou la déduction change.

 */
is
  type rt_period is record(emt_value hrm_employee_taxsource.emt_value%type
           , begin_period date
           , end_period date
           , emt_definitive hrm_employee_taxsource.emt_definitive%type
           , end_period_sal date
           , c_hrm_is_cat hrm_employee_taxsource.c_hrm_is_cat%type
           , emt_canton hrm_employee_taxsource.emt_canton%type
           , emt_hourly_rate hrm_employee_taxsource.emt_hourly_rate%type);

  type tt_periods is table of rt_period index by pls_integer;

  type rt_histo_total is record (regular_normal hrm_history_detail.his_pay_sum_val%type,
                                 regular_fte hrm_history_detail.his_pay_sum_val%type,
                                 sporadic_normal hrm_history_detail.his_pay_sum_val%type,
                                 sporadic_fte hrm_history_detail.his_pay_sum_val%type,
                                 rate hrm_history_detail.his_pay_sum_val%type,
                                 external_alloc hrm_history_detail.his_pay_sum_val%type,
                                 external_alloc_normal hrm_history_detail.his_pay_sum_val%type,
                                 pay_period hrm_history.hit_pay_period%type,
                                 sporadic_100 hrm_history_detail.his_pay_sum_val%type,
                                 regular_100 hrm_history_detail.his_pay_sum_val%type,
                                 submitted hrm_history_detail.his_pay_sum_val%type,
                                 submitted_100 hrm_history_detail.his_pay_sum_val%type
                                  );

  type tt_histo_totals is table of rt_histo_total index by pls_integer;

  type tt_yearly_recap is table of com_list%rowtype index by pls_integer;



  /* Variables de packages initialisées dans le body */
  gd_period_begin date := null;
  gd_period_end   date := null;
  g_debug         boolean := false;
  gd_begin_year   date;
  gd_end_year     date;

  procedure p_log_line(iv_line in varchar2)
  is
  begin
    if g_debug then
        dbms_output.put_line(iv_line);
    end if;
  end;


  /* Fonction retournant les montants historiques liés au calcul de l'impôt pour l'employé dans l'année considérée */
  function p_histo_sums_in_year(
    in_employe_id            in hrm_person.hrm_person_id%type
  , iv_type_regular_normal   in varchar2
  , iv_type_activity_rate    in varchar2
  , iv_type_regular_fte      in varchar2
  , iv_type_sporadic_normal  in varchar2
  , iv_type_sporadic_fte     in varchar2
  , iv_type_rate_only        in varchar2
  , iv_type_rate_only_normal in varchar2
  , iv_version               in varchar2 default 'HRM_HISTORY_DETAIL'
  ) return tt_histo_totals
  is
  lt_total tt_histo_totals;
  ln_x pls_integer:=0;
  begin
    if iv_version = 'HRM_HISTORY_DETAIL' then
        /* Historique tiré des décomptes */
        select   sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_regular_normal) then HIS_PAY_SUM_VAL
                       else 0
                     end) REGULAR_NORMAL
               , sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_regular_fte) then HIS_PAY_SUM_VAL
                       else 0
                     end) REGULAR_FTE
               , sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_sporadic_normal) then HIS_PAY_SUM_VAL
                       else 0
                     end) SPORADIC_NORMAL
               , sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_sporadic_fte) then HIS_PAY_SUM_VAL
                       else 0
                     end) SPORADIC_FTE
               , max(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_activity_rate) then HIS_PAY_SUM_VAL
                       else 0
                     end) RATE
               , sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_rate_only) then HIS_PAY_SUM_VAL
                       else 0
                     end) EXTERNAL_ALLOC
               , sum(case
                       when UPPER(ELR_ROOT_NAME) = UPPER(iv_type_rate_only_normal) then HIS_PAY_SUM_VAL
                       else 0
                     end) EXTERNAL_ALLOC_NORMAL
               , HIS_PAY_PERIOD
               , null
               , null
               , null
               , null
            bulk collect into  lt_total
            from HRM_HISTORY_DETAIL D, hrm_elements_family f, hrm_elements_root r
           where exists(
                   select 1
                     from HRM_HISTORY
                    where HRM_EMPLOYEE_ID = D.HRM_EMPLOYEE_ID
                      and HRM_EMPLOYEE_ID = in_employe_id
                      and HIT_DEFINITIVE = 1
                      and HIT_PAY_PERIOD between gd_begin_year and gd_end_year
                      and HIS_PAY_NUM = HIT_PAY_NUM)
             and f.hrm_elements_root_id = r.hrm_elements_root_id
                 and D.HRM_ELEMENTS_ID = f.HRM_ELEMENTS_ID
                 and elf_is_reference = 1
                 and UPPER(R.ELR_ROOT_NAME) in
                    (UPPER(iv_type_regular_normal)
                      , UPPER(iv_type_activity_rate)
                      , UPPER(iv_type_regular_fte)
                      , UPPER(iv_type_sporadic_normal)
                      , UPPER(iv_type_sporadic_fte)
                      , UPPER(iv_type_rate_only)
                      , UPPER(iv_type_rate_only_normal)
                     )
        group by his_pay_period;

    else
        /* Historique tiré de la journalisation */
        select
            sum(elm_tax_earning-elm_tax_family_income-elm_tax_termination-elm_tax_sporadic) regular_normal,
            sum(elm_tax_family_income) regular_fte,
            sum(elm_tax_termination + elm_tax_sporadic) sporadic_normal,
            0 sporadic_fte /* n'est plus traité */,
            max(elm_tax_rate) rate,
            sum(elm_tax_ext) external_alloc,
            0 external_alloc_normal /* n'est plus traité */,
            elm_tax_per_end pay_period,
            0 submitted,
            0 submitted_100,
            0 sporadic_100,
            0 regular_100
            bulk collect into  lt_total
            from
            hrm_taxsource_ledger l
            where
            hrm_person_id = in_employe_id
            and elm_tax_per_end between gd_begin_year and gd_period_end
            /* Sans prendre les lignes extournées pour que le taux d'activité ne soit pas influencé */
            and not exists(select 1 from hrm_taxsource_ledger
                           where
                           hrm_taxsource_ledger_ext_id = l.hrm_taxsource_ledger_id)
            and c_elm_tax_type != '02'
            group by elm_tax_per_end;


    end if;

    return lt_total;
  end p_histo_sums_in_year;

  /* Fonction retournant le montant de la déduction déjà effectuée dans l'année pour le canton éventuel */
  function p_deducted_histo_amount(in_employe_id in hrm_person.hrm_person_id%type, iv_type_deducted in hrm_elements_root.elr_root_name%type, it_periods in tt_periods, iv_canton in hrm_employee_taxsource.emt_canton%type)
  return hrm_history_detail.his_pay_sum_val%type
  is
  ln_amount hrm_history_detail.his_pay_sum_val%type;
  ln_result hrm_history_detail.his_pay_sum_val%type;
  ln_period_idx pls_integer:=0;
  begin
      if iv_canton is null then
        -- On prend la somme totale de la déduction dans l'année puisqu'aucun canton n'est spécifié
        select   sum(HIS_PAY_SUM_VAL) DEDUCTION
        into ln_result
        from HRM_ELEMENTS_ROOT R
           , HRM_HISTORY_DETAIL D
       where D.HRM_EMPLOYEE_ID = in_employe_id
         and D.HRM_ELEMENTS_ID = R.HRM_ELEMENTS_ID
         and R.ELR_ROOT_NAME = iv_type_deducted
         and exists(
               select 1
                 from HRM_HISTORY
                where HRM_EMPLOYEE_ID = d.hrm_employee_id
                  and HIT_DEFINITIVE = 1
                  and HIT_PAY_PERIOD between  gd_begin_year and gd_end_year
                  and HIT_PAY_NUM = D.HIS_PAY_NUM);
      else
        -- On ne considère que les déductions liées au canton spécifié
          while ln_period_idx < it_periods.count loop
              ln_period_idx := it_periods.next(ln_period_idx);
              if it_periods(ln_period_idx).emt_canton = iv_canton  then
                  select   sum(HIS_PAY_SUM_VAL) DEDUCTION
                    into ln_amount
                    from HRM_ELEMENTS_ROOT R
                       , HRM_HISTORY_DETAIL D
                   where D.HRM_EMPLOYEE_ID = in_employe_id
                     and D.HRM_ELEMENTS_ID = R.HRM_ELEMENTS_ID
                     and R.ELR_ROOT_NAME = iv_type_deducted
                     and exists(
                           select 1
                             from HRM_HISTORY
                            where HRM_EMPLOYEE_ID = d.hrm_employee_id
                              and HIT_DEFINITIVE = 1
                              and HIT_PAY_PERIOD between  it_periods(ln_period_idx).BEGIN_PERIOD and  it_periods(ln_period_idx).END_PERIOD_SAL
                              and HIT_PAY_NUM = D.HIS_PAY_NUM);

                    ln_result:=ln_result+ln_amount;
                 end if;
        end loop;
    end if;

    return nvl(ln_result,0);
    exception when no_data_found then return 0;
  end p_deducted_histo_amount;



  /**
   * Fonction retournant les périodes d'assujettissement de l'année ainsi que les bornes ajustées
   */
  function p_tax_periods(in_employe_id in hrm_person.hrm_person_id%type) return tt_periods
  is
  lt_period tt_periods;
  ln_x pls_integer:=0;
  ld_prev_period date;
  lv_prev_value hrm_employee_taxsource.emt_value%type;
  lv_prev_cat hrm_employee_taxsource.c_hrm_is_cat%type;
  lv_prev_canton hrm_employee_taxsource.emt_canton%type;
  begin
    for tpl in (
    select   EMT_VALUE
           , BEGIN_PERIOD
           , END_PERIOD
           , EMT_DEFINITIVE
           , last_day(P.END_PERIOD_SAL) END_PERIOD_SAL
           , c_hrm_is_cat
           , emt_canton
           , emt_hourly_rate
        from (select HRM_PERSON_ID
                   , EMT_VALUE
                   , EMT_FROM
                   , EMT_DEFINITIVE
                   , c_hrm_is_cat
                   , emt_canton
                   , reference_period_start(emt_value,c_hrm_tax_out, EMT_FROM, EMT_TO) BEGIN_PERIOD
                   , nvl2(EMT_TO, least(EMT_TO, greatest(gd_period_end,emt_from)), greatest(emt_from, gd_period_end)) end_period
                   , reference_period_end(in_employe_id, EMT_FROM, EMT_TO, c_hrm_tax_out) END_PERIOD_SAL
                   ,EMT_HOURLY_RATE
                from HRM_EMPLOYEE_TAXSOURCE
                where HRM_PERSON_ID = in_employe_id
             ) P
       where BEGIN_PERIOD <= gd_period_end
         /* On ne prend pas en compte les déductions liées à des départs l'année précédente
            Ceux-ci doivent être gérés manuellement avec déduction manuelle indépendante et insertion
        manuelle dans le journal.
     */
         and END_PERIOD >=gd_begin_year
    order by emt_from asc ) loop

        if  ln_x > 0 and

           tpl.begin_period-1 = lt_period(ln_x).end_period and
           tpl.emt_canton = lt_period(ln_x).emt_canton
           and nvl(tpl.emt_value, tpl.c_hrm_is_cat) = nvl(lt_period(ln_x).emt_value, lt_period(ln_x).c_hrm_is_cat)
           and nvl(tpl.emt_hourly_rate,0)= nvl(lt_period(ln_x).emt_hourly_rate,0) then

            /* Même canton et même barème, on ne considère dès lors qu'une période puisqu'elles sont contigues
               Par conséquent, on étend simplement la période précédente
             */
            lt_period(ln_x).end_period := tpl.end_period;
            lt_period(ln_x).end_period_sal  := tpl.end_period_sal;

        else

            ln_x := ln_x + 1;

            lt_period(ln_x).emt_value := tpl.emt_value;
            lt_period(ln_x).emt_canton := tpl.emt_canton;
            lt_period(ln_x).emt_definitive := tpl.emt_definitive;
            lt_period(ln_x).begin_period := greatest(tpl.begin_period,gd_begin_year);
            lt_period(ln_x).end_period := least(tpl.end_period, gd_end_year);
            lt_period(ln_x).end_period_sal := tpl.end_period_sal;
            lt_period(ln_x).c_hrm_is_cat := tpl.c_hrm_is_cat;
            lt_period(ln_x).emt_hourly_rate := tpl.emt_hourly_rate;

        end if;

    end loop;


    return lt_period;
  end p_tax_periods;


  /* Détermine si l'employé est naturalisé ou non de manière à stopper la perception de l'impôt immédiatement */
  function naturalized_settled(in_empid in hrm_person.hrm_person_id%type)
    return boolean
  is
    ln_taxout pls_integer;
  begin
    select case
             when exists(select 1
                           from hrm_employee_taxsource
                          where hrm_person_id = in_empid
                            and c_hrm_tax_out in('02', '03') ) then 1
             else 0
           end
      into ln_taxout
      from dual;

    return(ln_taxout = 1);
  end naturalized_settled;


  /* Mode de calcul de l'impôt à la source */
  function tax_mode(iv_value in hrm_employee_taxsource.emt_value%type, in_type in pls_integer)
    return varchar2
  is
    lv_result varchar2(2);
  begin
    if in_type = 1 then
      -- Renvoi du code C_HRM_TAX_CALC_MODE
      select C_HRM_TAX_CALC_MODE
        into lv_result
        from hrm_taxsource_definition
       where c_hrm_canton = iv_value;
    elsif in_type = 2 then
      -- Renvoi du code C_HRM_TAX_PROJECTION
      select C_HRM_TAX_PROJECTION
        into lv_result
        from hrm_taxsource_definition
       where c_hrm_canton = iv_value;
    elsif in_type = 3 then
      -- Renvoi du code C_HRM_TAX_DAYS_COUNT
      select C_HRM_TAX_DAYS_COUNT
        into lv_result
        from hrm_taxsource_definition
       where c_hrm_canton = iv_value;
    end if;

    return lv_result;
  exception
    when no_data_found then
      raise_application_error(-20000, 'La définition du canton manque dans la configuration de l impot');
  end tax_mode;



/**
 * Calcul le nombre d'heures correspondant au montant mensuel.
 * @param iv_canton  Code du canton.
 * @return le nombre d'heures.
 */
  function p_get_hours_per_month(iv_canton in varchar2)
    return number
  is
    ln_result number;
  begin
    select nvl(TAX_MONTHLY_HOURS,0)
      into ln_result
      from hrm_taxsource_definition
     where c_hrm_canton = iv_canton;

    return ln_result;
  exception
    when no_data_found then
      raise_application_error(-20000, 'La définition du canton manque dans la configuration de l impot');
  end p_get_hours_per_month;



  function p_days_between_i(iv_canton in varchar2, id_from in date, id_to in date)
    return number
  is
    lv_mode   varchar2(2);
    ln_result number;
  begin
    select case
             when C_HRM_TAX_DAYS_COUNT = '01' then hrm_date.days_between(id_from, id_to)
             else id_to - id_from+1
           end
      into ln_result
      from hrm_taxsource_definition
     where c_hrm_canton = iv_canton;

    return ln_result;
  exception
    when no_data_found then
      raise_application_error(-20000, 'La définition du canton manque dans la configuration de l impot');
  end p_days_between_i;

    /**
 * Calcul le nombre de jours à prendre en considération par mois
 * @param iv_canton  Code du canton.
 * @param id_from      Date début
 * @param id_to             Date fin
 * @return le nombre de jours entre 2 dates
 */
  function p_days_between(iv_canton in varchar2, id_from in date, id_to in date)
    return number
  is
    ln_result number;
  begin
    -- Nombre de jours dans le mois de début
    ln_result:=least(p_days_between_i(iv_canton, id_from, least(id_to,last_day(id_from))),30);
    -- Ajout du nombre de jours entre le mois d'entrée +1 et le mois de sortie -1
    ln_result:=ln_result + trunc(months_between( id_to, last_day(id_from)+1))*30;
    -- Ajout du nombre de jours dans le mois de sortie
    ln_result:=ln_result + case when last_day(id_from)<>last_day(id_to) then p_days_between_i(iv_canton, trunc(id_to,'month'), id_to) else 0 end;

    return ln_result;

  end p_days_between;



/**
* Date de fin de la période d'assujettissement effective
*/
  function p_nextintaxdate(id_givenDate in date, in_employee_id in hrm_person.hrm_person_id%type)
    return date
  is
    ld_nexttax date;

  begin
    select   min(emt_from) into ld_nexttax
    from hrm_employee_taxsource
    where hrm_person_id = in_employee_id
    and emt_from > id_givenDate;

    if ld_nexttax is null then
        ld_nexttax := gd_end_year;
    elsif ld_nexttax <> last_day(ld_nexttax) then
        -- En cas d'assujettissement en cours de mois, fin le jour précédent le début du mois
        ld_nexttax  := trunc(ld_nexttax, 'month') - 1;
      else
        -- Si fin d'assujettissement le dernier jour du mois, pas d'ajustement
        ld_nexttax  := ld_nexttax;
      end if;

    return ld_nexttax;
  end p_nextintaxdate;


/**
 * Recherche du dernier numéro de décompte calculé.
 */
  function p_get_last_pay_num(in_employe_id in hrm_person.hrm_person_id%type)
    return integer
  is
    ln_result integer;
  begin
    select nvl(emp_last_pay_num, -1) + 1
      into ln_result
      from hrm_person
     where hrm_person_id = in_employe_id;

    return ln_result;
  end;

/**
 * Suppression du suivi.
 * @param in_employe_id  Identifiant de l'employé.
 * @param in_paynum  Numéro du décompte.
 * @param iv_canton  Code du canton.
 */
  procedure p_delete_log(in_employe_id in hrm_person.hrm_person_id%type, in_pay_num in hrm_history.hit_pay_num%type)
  is
    -- Pas besoin en procédure :
    pragma autonomous_transaction;
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    -- Suppression des records déjà existants
    -- pour l'employé dans la période en cours et sur le même décompte
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_hrm_entity.gcHrmTaxsourceLog, iot_crud_definition => lt_crud_def);
    for tpl in (select rowid
                  from HRM_TAXSOURCE_LOG
                 where HRM_PERSON_ID = in_employe_id
                   and nvl(TAX_PAY_NUM, 0) >= nvl(in_pay_num, 0)
                   ) loop
      lt_crud_def.row_id  := tpl.rowid;
      fwk_i_mgt_entity.DeleteEntity(lt_crud_def);
    end loop;

    fwk_i_mgt_entity.Release(lt_crud_def);
    commit;
  exception
    when others then
      rollback;
      raise;
  end;

/**
 * Insertion du suivi
 */
  procedure p_insert_log(iot_crud_def in out nocopy fwk_i_typ_definition.T_CRUD_DEF)
  is
    -- Appel en procédure donc inutile :
    pragma autonomous_transaction;
  begin
    -- insertion dans la table sur laquelle se base le rapport de contrôle
    fwk_i_mgt_entity.InsertEntity(iot_crud_def);
    commit;
  exception
    when others then
      rollback;
      raise;
  end;



  /* Fonction retournant les sommes des valeurs entre les dates */
  procedure p_sums_in_interval(
    in_employe_id              in hrm_person.hrm_person_id%type
  , in_amount_regular_normal   in number
  , in_amount_regular_fte      in number
  , in_amount_sporadic_normal  in number
  , in_amount_sporadic_fte     in number
  , in_amount_activity_rate    in number
  , in_amount_rate_only        in number
  , in_amount_rate_only_normal in number default 0
  , iv_canton                  in varchar2
  , id_begin_period            in date
  , id_end_period_sal          in date
  , it_totals                  in tt_histo_totals
  , in_extrapolation           in pls_integer
  , on_submitted               out number
  , on_amountrate              out number
  , on_sporadic                out number
   )
  is
  lt_sums rt_histo_total;
  ln_tot_idx      pls_integer:=0;
  begin
    lt_sums.submitted     := 0;
    lt_sums.SUBMITTED_100 := 0;
    lt_sums.REGULAR_100   := 0;
    lt_sums.SPORADIC_100  := 0;
    lt_sums.SPORADIC_FTE  := 0;
    lt_sums.SPORADIC_NORMAL := 0;
    lt_sums.EXTERNAL_ALLOC :=0;

     /* Recherche des montants dans l'historique */
     while ln_tot_idx < it_totals.count loop
        ln_tot_idx := it_totals.next(ln_tot_idx);

        if it_totals(ln_tot_idx).pay_period between id_begin_period and id_end_period_sal then
          lt_sums.submitted := lt_sums.submitted+
                                       it_totals(ln_tot_idx).REGULAR_NORMAL +
                                       it_totals(ln_tot_idx).REGULAR_FTE +
                                       it_totals(ln_tot_idx).SPORADIC_NORMAL +
                                       it_totals(ln_tot_idx).SPORADIC_FTE;

          lt_sums.SUBMITTED_100 :=lt_sums.SUBMITTED_100 + ( (it_totals(ln_tot_idx).REGULAR_NORMAL + it_totals(ln_tot_idx).SPORADIC_NORMAL + it_totals(ln_tot_idx).EXTERNAL_ALLOC_NORMAL)
                 * case
                   when tax_mode(iv_canton, 2) = '02' then 100 / case it_totals(ln_tot_idx).RATE
                                                             when 0 then 100
                                                             else it_totals(ln_tot_idx).RATE
                                                           end
                   else 1
                 end
                ) +
               it_totals(ln_tot_idx).REGULAR_FTE +
               it_totals(ln_tot_idx).SPORADIC_FTE +
               it_totals(ln_tot_idx).EXTERNAL_ALLOC;

          lt_sums.REGULAR_100 :=lt_sums.REGULAR_100+(it_totals(ln_tot_idx).REGULAR_NORMAL *
                                             case
                                               when tax_mode(iv_canton, 2) = '02' then 100 / case it_totals(ln_tot_idx).RATE
                                                                                         when 0 then 100
                                                                                         else it_totals(ln_tot_idx).RATE
                                                                                       end
                                               else 1
                                             end) + it_totals(ln_tot_idx).REGULAR_FTE;

          lt_sums.SPORADIC_100 := lt_sums.SPORADIC_100+ (it_totals(ln_tot_idx).SPORADIC_NORMAL *
                                         case
                                           when tax_mode(iv_canton, 2) = '02' then 100 / case it_totals(ln_tot_idx).RATE
                                                                                     when 0 then 100
                                                                                     else it_totals(ln_tot_idx).RATE
                                                                                   end
                                           else 1
                                         end) + it_totals(ln_tot_idx).SPORADIC_FTE;

          lt_sums.SPORADIC_FTE :=lt_sums.SPORADIC_FTE + it_totals(ln_tot_idx).SPORADIC_FTE;

          lt_sums.SPORADIC_NORMAL :=lt_sums.SPORADIC_NORMAL + it_totals(ln_tot_idx).SPORADIC_NORMAL;


          lt_sums.EXTERNAL_ALLOC :=lt_sums.EXTERNAL_ALLOC + it_totals(ln_tot_idx).EXTERNAL_ALLOC_NORMAL * case
                 when tax_mode(iv_canton, 2) = '02' then 100 / case it_totals(ln_tot_idx).RATE
                                                           when 0 then 100
                                                           else it_totals(ln_tot_idx).RATE
                                                         end
                 else 1
               end + it_totals(ln_tot_idx).EXTERNAL_ALLOC;


        end if;

     end loop;



    /* Rémunération de la période courante */
    on_submitted := nvl(lt_sums.submitted,0)+ case
        when gd_period_end between id_BEGIN_PERIOD and id_END_PERIOD_SAL then in_amount_regular_normal +
                                                                                 in_amount_sporadic_normal+                                                                                +
                                                                                in_amount_regular_fte +
                                                                                in_amount_sporadic_fte
        else 0
      end;

    -- Montant soumis ramené à un taux d'occupation de 100%
    on_amountrate       :=
      nvl(lt_sums.SUBMITTED_100, 0) +
      -- Ajout des montants du décompte sur la période valable uniquement
      case
        when gd_period_end between id_BEGIN_PERIOD and id_END_PERIOD_SAL then (in_amount_regular_normal +
                                                                                 in_amount_sporadic_normal +
                                                                                 in_amount_rate_only_normal
                                                                                ) *
                                                                                case
                                                                                  when in_extrapolation = 1
                                                                                  and in_amount_activity_rate <> 0 then 100 / in_amount_activity_rate
                                                                                  else 1
                                                                                end +
                                                                                in_amount_regular_fte +
                                                                                in_amount_sporadic_fte +
                                                                                in_amount_rate_only
        else 0
      end;


    -- Montant à ne pas annualiser ( pas de conversion pour les barèmes D et V )
    on_sporadic  :=
      nvl(lt_sums.SPORADIC_100, 0) +
      -- Ajout des montants du décompte sur la période valable uniquement
      case
        when gd_period_end between id_BEGIN_PERIOD and id_END_PERIOD_SAL then (in_amount_sporadic_normal *
                                                                                 case
                                                                                   when in_extrapolation = 1
                                                                                   and in_amount_activity_rate <> 0 then 100 / in_amount_activity_rate
                                                                                   else 1
                                                                                 end
                                                                                ) +
                                                                                in_amount_sporadic_fte
        else 0
      end;
  end p_sums_in_interval;

  /**
 * Procédure de calcul de la taxe annuelle pour le canton de Vaud
 */
  function p_annual_deterministic_sal_vd(
    in_employe_id              in hrm_person.hrm_person_id%type
  , in_amount_regular_normal   in number
  , in_amount_activity_rate    in number
  , in_amount_regular_fte      in number
  , in_amount_sporadic_normal  in number
  , in_amount_sporadic_fte     in number
  , in_amount_rate_only        in number
  , iv_canton                  in varchar2
  , in_amount_rate_only_normal in number default 0
  , ion_amount_estimated_revenue in out number
  , it_periods                 in tt_periods
  , it_totals                  in tt_histo_totals
  , in_extrapolation           in pls_integer
  , on_sporadic_100            out number
  , on_regular_100             out number
  )
    return number
  is
    ln_result            number       := 0.0;
    ln_end_year_base     number       := 0;
    ln_end_year_sporadic number       := 0;
    lt_sums              rt_histo_total;
    ln_days              binary_integer      := 0;
    ln_period_idx        pls_integer:=0;
    ln_amount            number := 0;
    ln_submitted         number;
    ln_amountrate        number;
    ln_sporadic_amount   number;
    ld_last_period       date;

  begin
    -- Recherche du salaire annuel déterminant.
    -- Les périodes de barème accessoire ne sont pas prises en compte dans le calcul du revenu annuel déterminant
     while ln_period_idx < it_periods.count loop
      ln_period_idx := it_periods.next(ln_period_idx);


      /* On ne calcule le revenu que pour le canton concerné */
      if it_periods(ln_period_idx).emt_canton = iv_canton
         and substr(it_periods(ln_period_idx).emt_value, 3, 1) <> 'D'
         and it_periods(ln_period_idx).emt_hourly_rate = 0 then
        p_sums_in_interval(in_employe_id => in_employe_id
                                  , in_amount_regular_normal   => in_amount_regular_normal
                                  , in_amount_regular_fte      => in_amount_regular_fte
                                  , in_amount_sporadic_normal  => in_amount_sporadic_normal
                                  , in_amount_sporadic_fte     => in_amount_sporadic_fte
                                  , in_amount_activity_rate    => in_amount_activity_rate
                                  , in_amount_rate_only        => in_amount_rate_only
                                  , in_amount_rate_only_normal => in_amount_rate_only_normal
                                  , iv_canton                  => it_periods(ln_period_idx).emt_canton
                                  , id_begin_period            => it_periods(ln_period_idx).begin_period
                                  , id_end_period_sal          => it_periods(ln_period_idx).end_period_sal
                                  , it_totals                  => it_totals
                                  , in_extrapolation           => in_extrapolation
                                  , on_submitted               => ln_submitted
                                  , on_amountrate              => ln_amountrate
                                  , on_sporadic                => ln_sporadic_amount);

         ln_amount := ln_submitted + ln_amount;
         ln_end_year_base := ln_end_year_base + ln_amountrate - ln_sporadic_amount;
         ln_end_year_sporadic := ln_end_year_sporadic + ln_sporadic_amount;

        --Cumul du nombre de jours des périodes
        ln_days               := ln_days + p_days_between(iv_canton, it_periods(ln_period_idx).begin_period, it_periods(ln_period_idx).END_PERIOD);
        ld_last_period        := it_periods(ln_period_idx).end_period_sal;
       end if;
     end loop;


    if (ln_days > 0) then
      -- Extrapolation du montant cumulé sur une base annuelle en fonction du nombre de jours assujettis
      on_regular_100 := (ln_end_year_base *  360 / ln_days
                        );

      -- On prend le salaire estimé uniquement s'il est inférieur au soumis et qu'il est lié à la période et pas à un autre canton
      if ln_amount < ion_amount_estimated_revenue and gd_period_end <= ld_last_period then --p_nextintaxdate(ld_last_period, in_employe_id) then
          ln_result := ion_amount_estimated_revenue;
      else
          ln_result  := on_regular_100 + ln_end_year_sporadic;
          ion_amount_estimated_revenue := 0;
      end if;
    else
      ln_result  := 0.0;
    end if;

    /* Valeurs de retour pour avoir ces éléments dans la table de log */
    on_sporadic_100 := ln_end_year_sporadic;

    return ln_result;
  end p_annual_deterministic_sal_vd;


  /* Fonction retournant le salaire déterminant entre les dates */
  function p_ascertain_revenue(
    in_employe_id              in hrm_person.hrm_person_id%type
  , in_amount_regular_normal   in number
  , in_amount_activity_rate    in number
  , in_amount_regular_fte      in number
  , in_amount_sporadic_normal  in number
  , in_amount_sporadic_fte     in number
  , in_amount_rate_only        in number
  , iv_canton                  in varchar2
  , in_amount_rate_only_normal in number default 0
  , id_begin_period            in date
  , id_end_period_sal          in date
  , id_end_period              in date
  , in_extrapolation           in number
  , in_mode                    in number
  , ion_amount_estimated_revenue in out number
  , iv_emt_value               in varchar2
  , it_totals                  in tt_histo_totals
  , on_sporadic                out number
  , on_amountrate              out number
  ) return number
  is
  ln_determ_recap number;
  ln_amountrate number;
  ln_sporadic_amount number;
  lt_sums rt_histo_total;
  ln_amount number;
  begin
    p_sums_in_interval(in_employe_id => in_employe_id
      , in_amount_regular_normal   => in_amount_regular_normal
      , in_amount_regular_fte      => in_amount_regular_fte
      , in_amount_sporadic_normal  => in_amount_sporadic_normal
      , in_amount_sporadic_fte     => in_amount_sporadic_fte
      , in_amount_activity_rate    => in_amount_activity_rate
      , in_amount_rate_only        => in_amount_rate_only
      , in_amount_rate_only_normal => in_amount_rate_only_normal
      , iv_canton                  => iv_canton
      , id_begin_period            => id_begin_period
      , id_end_period_sal          => id_end_period_sal
      , it_totals                  => it_totals
      , in_extrapolation           => in_extrapolation
      , on_submitted               => ln_amount
      , on_amountrate              => ln_amountrate
      , on_sporadic                => ln_sporadic_amount);

    -- Recherche du taux à appliquer en cas de présence d'un salaire annuel estimé pour autant qu'il soit supérieur au montant soumis
    if nvl(ion_amount_estimated_revenue,0)<>0 and ion_amount_estimated_revenue > ln_amount then
        ln_determ_recap := ion_amount_estimated_revenue;

    elsif in_mode = 3 then
      -- Cantons pratiquant la régularisation par période d'assujettissement
      ln_determ_recap  := ln_sporadic_amount + (ln_amountrate - ln_sporadic_amount) / p_days_between(iv_canton, id_BEGIN_PERIOD, id_END_PERIOD) *  360;
      ion_amount_estimated_revenue := 0;
    else
      -- Pas d'annualisation ( ni de conversion pour les barèmes D )
      ln_determ_recap  :=
        ((ln_sporadic_amount * 12 ) +
        ( (ln_amountrate - ln_sporadic_amount) /
         case
           when substr(iv_EMT_VALUE, 3, 1) <> 'D' then p_days_between(iv_canton, id_BEGIN_PERIOD, id_END_PERIOD)
           else 30
         end
        ) *
        360);

      ion_amount_estimated_revenue :=0;

    end if;

    /* Valeurs de retour pour avoir ces éléments dans la table de log */
    on_sporadic := ln_sporadic_amount;
    on_amountrate := ln_amountrate;

    return ln_determ_recap;
  end p_ascertain_revenue;



  /**
  * Taux d'imposition
  */
  function p_tax_rate(iv_canton in varchar2, iv_bareme in varchar2, in_montant_mensuel in number)
    return number
  is
  begin
    return hrm_functions.TaxRate(in_montant_mensuel, iv_canton, iv_bareme) / 100;
  end;

  /* Gestion des retenues minimales en CHF figurant dans les fichiers importés */
  function p_tax_minimal_amount(iv_canton in varchar2, iv_bareme in varchar2, in_montant_mensuel in number)
    return number
  is
  ln_result number := 0.0;
  begin
    if iv_bareme is null or in_montant_mensuel is null then
        return 0.0;
    end if;

    select TAX_AMOUNT
      into ln_result
      from (select TAX_AMOUNT
                 , to_number(TAX_IND_Y_MIN, '9999999999D999') TAX_IND_Y_MIN
                 , to_number(TAX_IND_Y_MAX, '9999999999D999') TAX_IND_Y_MAX
              from PCS.PC_TAXSOURCE
             where C_HRM_CANTON = iv_canton
               and TAX_SCALE = iv_bareme )
     where trunc(in_montant_mensuel, 3) between TAX_IND_Y_MIN and TAX_IND_Y_MAX;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;


  /* Nombre de jours annuels pour le calcul du soumis TI */
  function p_annual_days_in_canton(in_employe_id in number, iv_canton in varchar2) return number
  is
  ln_days number:=0;
  begin
    for tpl in ( select emt_from, emt_to from hrm_employee_taxsource
                 where hrm_person_id = in_employe_id
                 and emt_canton = iv_canton
                 and gd_begin_year between trunc(emt_from,'Y') and least(gd_period_begin,nvl(emt_to, gd_period_begin))) loop
        ln_days := ln_days + p_days_between(iv_canton, greatest(tpl.emt_from, gd_begin_year), least(nvl(tpl.emt_to,gd_end_year),gd_period_end));
    end loop;

    return ln_days;
  end p_annual_days_in_canton;


/**
 * Taxation horaire
 * Aucune annualisation n'a lieu
 */
  function p_taxation_horaire(
    in_employe_id             in hrm_person.hrm_person_id%type
  , in_amount_regular_normal  in number
  , in_amount_sporadic_normal in number
  , in_amount_regular_fte     in number
  , in_amount_sporadic_fte    in number
  , in_amount_hourly_rate     in number
  , it_periods                in tt_periods
  , ob_calculated             out boolean
  )
    return number
  is
    lt_crud_def            fwk_i_typ_definition.T_CRUD_DEF;
    ln_period_idx          pls_integer:=0;
    ln_taxrate             number;
    ln_result              number                   := 0.0;
    ln_get_hours_per_month number;
  begin
    /* Parcours des périodes d'assujettissement */
    while ln_period_idx < it_periods.count loop
      ln_period_idx := it_periods.next(ln_period_idx);

      /* Traitement uniquement de la période d'assujettissement liée au mois courant */
      if gd_period_begin between trunc(it_periods(ln_period_idx).end_period_sal,'month') and it_periods(ln_period_idx).end_period_sal  then

        ln_get_hours_per_month  := p_get_hours_per_month(substr(it_periods(ln_period_idx).EMT_VALUE, 1, 2) );
        if ln_get_hours_per_month > 0 then
            ln_taxrate              := p_tax_rate(substr(it_periods(ln_period_idx).EMT_VALUE, 1, 2), it_periods(ln_period_idx).EMT_VALUE, in_amount_hourly_rate * ln_get_hours_per_month);
            ln_result               := (in_amount_regular_normal + in_amount_regular_fte + in_amount_sporadic_normal + in_amount_sporadic_fte) * ln_taxrate;
            ob_calculated           := true;

            fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_hrm_entity.gcHrmTaxsourceLog, iot_crud_definition => lt_crud_def, ib_initialize => true);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'HRM_PERSON_ID', in_employe_id);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_PAY_NUM', p_get_last_pay_num(in_employe_id) );
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_FROM', it_periods(ln_period_idx).BEGIN_PERIOD);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TO', it_periods(ln_period_idx).END_PERIOD);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_SCALE', it_periods(ln_period_idx).EMT_VALUE);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_PERIOD', gd_period_end);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_BASE', in_amount_regular_normal);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_ANNUAL', in_amount_hourly_rate * ln_get_hours_per_month * 12);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_RATE', ln_taxrate);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_AMOUNT', ln_result);
            fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_HOURLY_RATE', in_amount_hourly_rate);
            p_insert_log(lt_crud_def);
            fwk_i_mgt_entity.Release(lt_crud_def);
        end if;
      end if;
    end loop;

    return ln_result;
  end p_taxation_horaire;


  function p_ti_amount (
      in_employe_id              in hrm_person.hrm_person_id%type
      , in_amount_regular_normal   in number
      , in_amount_regular_fte      in number
      , in_amount_sporadic_normal  in number
      , in_amount_sporadic_fte     in number
      , iv_canton                  in varchar2
      , it_totals                  in tt_histo_totals
      , it_periods                 in tt_periods
      ) return number
  is
  ln_result number:=0;
  ln_amount number;
  ln_amountrate number;
  ln_sporadic_amount number;
  ln_period_idx pls_integer:=0;
  begin
     while ln_period_idx < it_periods.count loop
      ln_period_idx := it_periods.next(ln_period_idx);

      /* On ne calcule le revenu que pour le canton concerné */
      if it_periods(ln_period_idx).emt_canton = iv_canton then
        p_sums_in_interval(in_employe_id => in_employe_id
                                  , in_amount_regular_normal   => in_amount_regular_normal
                                  , in_amount_regular_fte      => in_amount_regular_fte
                                  , in_amount_sporadic_normal  => in_amount_sporadic_normal
                                  , in_amount_sporadic_fte     => in_amount_sporadic_fte
                                  , in_amount_activity_rate    => 0
                                  , in_amount_rate_only        => 0
                                  , in_amount_rate_only_normal => 0
                                  , iv_canton                  => it_periods(ln_period_idx).emt_canton
                                  , id_begin_period            => it_periods(ln_period_idx).begin_period
                                  , id_end_period_sal          => it_periods(ln_period_idx).end_period_sal
                                  , it_totals                  => it_totals
                                  , in_extrapolation           => 0
                                  , on_submitted               => ln_amount
                                  , on_amountrate              => ln_amountrate
                                  , on_sporadic                => ln_sporadic_amount);
         ln_result := ln_result + ln_amount;
       end if;
     end loop;

     return ln_result;

  end p_ti_amount;



  procedure p_save_recap(ix_recap in xmltype)
  is
    lx xmltype;
  begin
    select xmlElement("HRM_TAXSOURCE",ix_recap) into lx from dual;
    HRM_PRC_HISTORY.AddSessionAdditionalData(lx);
  end p_save_recap;

/**
 * Taxation standard
 */
  function p_regular_taxation(
    in_employe_id               in hrm_person.hrm_person_id%type
  , in_amount_regular_normal    in number
  , in_amount_sporadic_normal   in number
  , in_amount_regular_fte       in number
  , in_amount_sporadic_fte      in number
  , in_amount_activity_rate     in number
  , in_amount_rate_only         in number
  , in_amount_hourly_rate       in number
  , in_amount_estimated_revenue in number
  , iv_type_in                  in varchar2
  , in_amount_rate_only_normal  in number default 0
  , in_amount_forced_deduction  in number default 0
  , iv_canton                   in hrm_employee_taxsource.emt_canton%type
  , it_periods                  in tt_periods
  , it_totals                   in tt_histo_totals
  )
    return number
  is
    lt_crud_def         fwk_i_typ_definition.T_CRUD_DEF;
    ln_amountrate       number;
    ln_amount           number;
    ln_sporadic_amount  number;
    ln_determ           number;
    ln_determ_recap     number;
    ln_determ_monthly   number;
    ln_taxrate          number;
    ln_tax              number;
    ln_tax_amount       number;
    ln_result           number                   := 0.0;
    lv_canton           varchar2(2);
    ln_mode             integer;
    lb_tax_final        boolean;
    ln_extrapolation    integer;
    ld_period           date;
    ln_ti_amount        number := 0.0;
    ln_ti_amount_days   number := 0.0;
    ln_ledger_taxable   number;
    ln_ledger_ascertain number;
    ln_ledger_tax       number;
    ln_current          number;
    ln_period_idx       pls_integer:=0;
    lx_recap            xmltype;
    ln_estimated        number;

  begin


    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_hrm_entity.gcHrmTaxsourceLog, iot_crud_definition => lt_crud_def);
    --fwk_i_mgt_entity.Init(lt_crud_def, true);

    /* Parcours des périodes d'assujettissement */
    while ln_period_idx < it_periods.count loop
      ln_period_idx := it_periods.next(ln_period_idx);
      -- On ne prend que les périodes d'assujettissements liées au canton éventuellement défini
      if iv_canton is null or iv_canton =  it_periods(ln_period_idx).emt_canton then
          -- Boucle sur les périodes d'assujettissements de l'employé
          lb_tax_final     := false;
          ln_determ_recap  := 0.0;
          lv_canton        := it_periods(ln_period_idx).emt_canton;
          ln_taxrate       := null;

          /* Recherche du mode de calcul */
          if tax_mode(lv_canton, 1) = '02'
             and substr(it_periods(ln_period_idx).EMT_VALUE, 3, 1) <> 'D'
             and it_periods(ln_period_idx).emt_hourly_rate = 0 then
            ln_mode  := 3;   -- Régularisation sur toute l'année par période d'assujettissement, soumis effectif
          elsif tax_mode(lv_canton, 1) in ( '03','04')
                and substr(it_periods(ln_period_idx).EMT_VALUE, 3, 1) <> 'D'
                and it_periods(ln_period_idx).emt_hourly_rate = 0 then
            ln_mode  := 2;   -- Régularisation sur toute l'année, toutes périodes confondues, soumis effectif ou Tessin
          else
            ln_mode  := 0;   -- Pas d'annualisation
          end if;


          /* Détermination si le salaire doit être extrapolé à 100% en cas de travail à temps partiel */
          if     tax_mode(lv_canton, 2) = '02'
             and substr(it_periods(ln_period_idx).EMT_VALUE, 3, 1) <> 'D'
             and it_periods(ln_period_idx).emt_hourly_rate = 0 then
            ln_extrapolation  := 1;
          else
            ln_extrapolation  := 0;
          end if;


          /* Recherche du taux d'impôt en fonction du salaire déterminant */
          if it_periods(ln_period_idx).c_hrm_is_cat is not null then
              /* Imposition selon régime particulier */
              select case it_periods(ln_period_idx).c_hrm_is_cat
                       -- Accord spécial avec la France => pas de prélèvement
                     when '01' then 0
                       -- Honoraire CA
                     when '02' then tax_board
                       -- Participations
                     when '03' then tax_shares
                     end
                into ln_taxrate
                from hrm_taxsource_definition
               where c_hrm_canton = it_periods(ln_period_idx).emt_canton;

               ln_determ_recap:=null;

          elsif ln_mode = 2 then
            /* Salaire déterminant correspondant à l'extrapolation des revenus annuels réalisés dans le canton */
            ln_estimated := in_amount_estimated_revenue;
            ln_determ_recap  :=
              p_annual_deterministic_sal_vd(in_employe_id
                                          , in_amount_regular_normal
                                          , in_amount_activity_rate
                                          , in_amount_regular_fte
                                          , in_amount_sporadic_normal
                                          , in_amount_sporadic_fte
                                          , in_amount_rate_only
                                          , lv_canton
                                          , in_amount_rate_only_normal
                                          , ln_estimated
                                          , it_periods
                                          , it_totals
                                          , ln_extrapolation
                                          , ln_sporadic_amount
                                          , ln_amountrate
                                           );


           ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);

          elsif ln_mode = 3 and it_periods.count=ln_period_idx then
           /* Recherche du salaire déterminant par période d'assujettissement */
            ln_estimated := in_amount_estimated_revenue;
            ln_determ_recap  :=
              p_ascertain_revenue(in_employe_id
                                          , in_amount_regular_normal
                                          , in_amount_activity_rate
                                          , in_amount_regular_fte
                                          , in_amount_sporadic_normal
                                          , in_amount_sporadic_fte
                                          , in_amount_rate_only
                                          , lv_canton
                                          , in_amount_rate_only_normal
                                          , it_periods(ln_period_idx).begin_period
                                          , it_periods(ln_period_idx).end_period_sal
                                          , it_periods(ln_period_idx).end_period
                                          , ln_extrapolation
                                          , ln_mode
                                          , ln_estimated
                                          , it_periods(ln_period_idx).emt_value
                                          , it_totals
                                          , ln_sporadic_amount
                                          , ln_amountrate
                                           );
            ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
          end if;


          /*
          Pour le canton du Tessin, le soumis correspond au salaire annuel au protata des jours de la période sur le dernier décompte
          */
          if tax_mode(lv_canton, 1)='04' then
            if ln_ti_amount = 0 then
              /* Recherche du salaire annuel effectif */
              ln_ti_amount :=   p_ti_amount(      in_employe_id=> in_employe_id
                                                  , in_amount_regular_normal   =>in_amount_regular_normal
                                                  , in_amount_regular_fte      =>in_amount_regular_fte
                                                  , in_amount_sporadic_normal  =>in_amount_sporadic_normal
                                                  , in_amount_sporadic_fte     =>in_amount_sporadic_fte
                                                  , iv_canton                  =>it_periods(ln_period_idx).emt_canton
                                                  , it_totals                  => it_totals
                                                  , it_periods                 => it_periods);

            end if;


            -- Montant ramené au nombre de jours assujettis dans le canton
            ln_ti_amount_days := ln_ti_amount* least(1,p_days_between(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).begin_period, it_periods(ln_period_idx).end_period)/p_annual_days_in_canton(in_employe_id, it_periods(ln_period_idx).emt_canton)) ;

          end if;

          /* Montant du décompte actuel à ventiler sur la bonne période d'assujettissement et le bon mois */
          if gd_period_end between it_periods(ln_period_idx).begin_period and it_periods(ln_period_idx).end_period_sal then
           ln_current := nvl(in_amount_regular_normal,0) + nvl(in_amount_regular_fte,0) + nvl(in_amount_sporadic_fte,0)+ nvl(in_amount_sporadic_normal,0);
          else
           ln_current := 0;
          end if;

          /*
            On veut les montants mensuels, il faut donc effectuer une boucle sur les mois entre les dates de début et de fin
            On prend les fins de périodes pour avoir les montants effectifs
          */
          -- Initialisation du mois de départ, on débute avec la dernière période d'assujettissement
          ld_period := last_day(it_periods(ln_period_idx).begin_period);


          /* Parcours des mois jusqu'au mois actif respectivement la date de fin d'assujettissement */
          while ld_period <= least(gd_period_end, last_day(it_periods(ln_period_idx).end_period)) loop
                /* Recherche des éléments du journal pour la période de manière à faire les corrections */
                begin
                  select NVL(sum(nvl(elm_tax_earning, 0) ),0) taxable
                         , NVL(sum(nvl(elm_tax_ascertain_earning, 0) ),0) certain_taxable
                         , NVL(sum(nvl(elm_tax_source, 0) ),0) tax
                      into ln_ledger_taxable, ln_ledger_ascertain, ln_ledger_tax
                      from hrm_taxsource_ledger l
                     where  hrm_person_id = in_employe_id
                       and elm_tax_per_end = ld_period
                       and c_hrm_canton = it_periods(ln_period_idx).emt_canton;

                exception when no_data_found then
                    ln_ledger_taxable := 0;
                    ln_ledger_ascertain :=0;
                    ln_ledger_tax := 0;
                end;



                /* Régularisation du soumis avec les valeurs du décompte actuel */
                if tax_mode(lv_canton, 1) = '04' and ld_period between it_periods(ln_period_idx).begin_period and it_periods(ln_period_idx).end_period_sal then
                  -- Pour le Tessin, on régularise le montant trouvé précédemment ( soumis moyen par période d'assujettissement ) en fonction du nombre de jours assujettis dans le mois
                  ln_amount := ln_ti_amount_days * least(1,p_days_between(lv_canton, greatest(trunc(ld_period,'month'),it_periods(ln_period_idx).begin_period), least(it_periods(ln_period_idx).end_period, ld_period))/p_days_between(lv_canton,it_periods(ln_period_idx).begin_period, it_periods(ln_period_idx).end_period) );

                  ln_tax_amount       := (ln_amount * ln_taxrate);
                elsif ln_mode = 0 then
                    ln_amountrate:=0;
                     -- Pour les cantons mensualisés, on traite les personnes présentes dans le mois courant, pour les personnes parties dans le mois de départ. Les mois antérieurs ne sont pas touchés
                    if it_periods.count = ln_period_idx and ld_period = least(gd_period_end, last_day(it_periods(ln_period_idx).end_period))
                        and it_periods(ln_period_idx).emt_hourly_rate = 0 then

                               /* Recherche du salaire déterminant par période d'assujettissement */
                               ln_estimated := in_amount_estimated_revenue;
                                ln_determ_recap  :=
                                  p_ascertain_revenue(in_employe_id=> in_employe_id
                                                      ,in_amount_regular_normal=> in_amount_regular_normal
                                                      , in_amount_activity_rate=>in_amount_activity_rate
                                                      , in_amount_regular_fte=>in_amount_regular_fte
                                                      , in_amount_sporadic_normal=>in_amount_sporadic_normal
                                                      , in_amount_sporadic_fte=>in_amount_sporadic_fte
                                                      , in_amount_rate_only=>in_amount_rate_only
                                                      , iv_canton=>lv_canton
                                                      , in_amount_rate_only_normal=>in_amount_rate_only_normal
                                                      /* En cas de départ, les décomptes ultérieurs vont sur la période de départ */
                                                      , id_begin_period=> case when last_day(it_periods(ln_period_idx).end_period) > ld_period then
                                                                                greatest(trunc(ld_period,'month'),it_periods(ln_period_idx).begin_period)
                                                                            else
                                                                                greatest(trunc(it_periods(ln_period_idx).end_period,'month'), it_periods(ln_period_idx).begin_period)
                                                                            end
                                                      , /* En cas de départ, on ramène le montant au mois de sortie */
                                                        id_end_period_sal=>case when last_day(it_periods(ln_period_idx).end_period) > ld_period then ld_period else it_periods(ln_period_idx).end_period_sal end
                                                      , id_end_period=>least(ld_period,it_periods(ln_period_idx).end_period)
                                                      , in_extrapolation=>ln_extrapolation
                                                      , in_mode=>ln_mode
                                                      , ion_amount_estimated_revenue=>ln_estimated
                                                      , iv_emt_value=>it_periods(ln_period_idx).emt_value
                                                      , it_totals=>it_totals
                                                      , on_sporadic=>ln_sporadic_amount
                                                      , on_amountrate=>ln_amountrate
                                                       );

                            ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                            -- Pour les personnes parties, on additionne au décompte du dernier mois
                            ln_amount := ln_ledger_taxable + ln_current;
                            ln_current := 0;

                            -- En cas de déduction du mois forcée
                            if in_amount_forced_deduction > 0 then
                                ln_tax_amount       := in_amount_forced_deduction;
                            else

                                if ln_taxrate = 0 then
                                    -- Traitement particulier pour prendre en compte la valeur minimale le cas échéant
                                    ln_tax_amount       := p_tax_minimal_amount(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                                else
                                    ln_tax_amount       := (ln_amount * ln_taxrate);
                                end if;
                            end if;

                     else
                       -- Aucun effet sur le mois parsé
                       ln_amount := ln_ledger_taxable;
                       ln_tax_amount := ln_ledger_tax;
                       ln_determ_recap := ln_ledger_ascertain*12;
                       ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                    end if;
                 else
                    -- Pour les cantons annualisés VD/GE/FR/VS... on ajoute le montant sur le dernier mois ( dernière période d'assujettissement, mois courant ou sortie )

                    ln_amount := ln_ledger_taxable;

                    if ln_mode=3 then
                        if it_periods.count = ln_period_idx then
                            if ld_period = least(gd_period_end, last_day(it_periods(ln_period_idx).end_period))  then
                                ln_amount := ln_amount +  ln_current;
                                ln_current := 0;
                            end if;
                            -- Déterminant déjà calculé par période puisque période courante
                            ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                            ln_tax_amount       := (ln_amount * ln_taxrate);
                        else
                            ln_determ_recap := ln_ledger_ascertain*12;
                            ln_tax_amount := ln_ledger_tax;
                            ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                        end if;
                    else
                        -- VD
                         if it_periods.count = ln_period_idx and ld_period = least(gd_period_end, last_day(it_periods(ln_period_idx).end_period))  then
                                ln_amount := ln_amount +  ln_current;
                                ln_current := 0;
                         end if;
                         -- Déterminant déjà calculé par période puisque période courante
                         ln_taxrate  := p_tax_rate(it_periods(ln_period_idx).emt_canton, it_periods(ln_period_idx).EMT_VALUE, ln_determ_recap/12);
                         ln_tax_amount:= (ln_amount * ln_taxrate);
                    end if;

                 end if;

                /* Arrondis */
                -- Dans le log, on veut le montant annuel du déterminant
                ln_amount := acs_function.pcsround(ln_amount,'1');
                ln_tax_amount := acs_function.pcsround(ln_tax_amount,'1');
                ln_determ_monthly := acs_function.pcsround(ln_determ_recap/12,'1');


                /* Génération du xml qui sera passé dans HRM_HISTORY */

                select xmlconcat(
                         xmlelement("HRM_TAX_PERIOD",
                            XmlElement("MONTH", to_char(ld_period,'yyyymmdd')),
                            XmlElement("TAXABLEEARNING", to_char(ln_amount,'FM999999999.00')),
                            XmlElement("ASCERTAINEDTAXABLEEARNING", to_char(ln_determ_monthly,'FM999999999.00')),
                            XmlElement("TAXATSOURCE", to_char(ln_tax_amount,'FM999999999.00')),
                            XmlElement("TAX_SCALE", it_periods(ln_period_idx).EMT_VALUE),
                            XmlElement("TAX_FROM", to_char(it_periods(ln_period_idx).BEGIN_PERIOD,'yyyymmdd')),
                            XmlElement("TAX_TO", to_char(it_periods(ln_period_idx).END_PERIOD,'yyyymmdd')),
                            XmlElement("TAX_TO_ADJUSTED", to_char(it_periods(ln_period_idx).END_PERIOD_SAL,'yyyymmdd')),
                            XmlElement("CANTON", it_periods(ln_period_idx).emt_canton)
                         )
                         , lx_recap
                       ) into lx_recap from dual;


                /* Cumul de la taxe déduction faite des éléments déjà dans le journal = déduction nette ou brute */
                ln_result           := ln_result + ln_tax_amount;

                /* Insertion dans la table de log */
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'HRM_PERSON_ID', in_employe_id);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_PAY_NUM', p_get_last_pay_num(in_employe_id) );
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_FROM', it_periods(ln_period_idx).BEGIN_PERIOD);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TO', it_periods(ln_period_idx).END_PERIOD);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TO_COMP', it_periods(ln_period_idx).END_PERIOD_SAL);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_SCALE', it_periods(ln_period_idx).EMT_VALUE);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_PERIOD', ld_period);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_BASE',  ln_amount);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_BASE_100', ln_amountrate);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_SPORADIC', ln_sporadic_amount);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_ANNUAL', ln_determ_recap);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_TAXED_ANNUAL_ESTIMATED', ln_estimated);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_RATE', ln_taxrate);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_AMOUNT', ln_tax_amount);
                fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TAX_FINAL', 0);
                p_insert_log(lt_crud_def);
                fwk_i_mgt_entity.clear(lt_crud_def);

              ld_period := add_months(ld_period,1);
          end loop;
      end if;
    end loop;


    fwk_i_mgt_entity.Release(lt_crud_def);

    /* Sauvegarde des données pour mise à jour du journal */
    p_save_recap(lx_recap);

    return ln_result;
  end p_regular_taxation;



--
-- public declaration
--
  function tax_code(in_employe_id in hrm_person.hrm_person_id%type, id_period in date default null)
    return varchar2
  is
    lv_result varchar2(10);
    ld_period date;
  begin
    ld_period  := nvl(id_period, gd_period_begin);

    -- retourne le premier code IS valable pour la période active ou à la date de sortie
    select EMT_VALUE
      into lv_result
      from (select   T.EMT_VALUE
                from HRM_EMPLOYEE_TAXSOURCE T
                   , HRM_IN_OUT I
               where T.HRM_PERSON_ID = in_employe_id
                 and I.HRM_EMPLOYEE_ID = T.HRM_PERSON_ID
                 and I.C_IN_OUT_STATUS = 'ACT'
                 and least(nvl(I.INO_OUT, ld_period), ld_period) between trunc(T.EMT_FROM, 'month') and last_day(nvl(T.EMT_TO, ld_period) )
            order by EMT_FROM desc)
     where rownum = 1;

    return lv_result;
  exception
    when no_data_found then
      return null;
  end tax_code;

  /* Procédure de vérification des enregistrements du journal qui doivent
     figurer dans une période d'assujettissement s'ils ne sont pas à 0
  */
  procedure p_check_wrong_ledger_periods(in_empid in hrm_person.hrm_person_id%type)
  is
  pragma autonomous_transaction;
  lv_text varchar2(255);
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
  select
    case when exists(select sum(elm_tax_source) deduction, elm_tax_per_end from hrm_taxsource_ledger l
                                where
                                hrm_person_id = in_empid
                                and elm_tax_per_end between hrm_date.beginofyear and hrm_date.endofyear
                                and not exists(select 1 from hrm_employee_taxsource t
                                                 where t.hrm_person_id = l.hrm_person_id
                                                 and elm_tax_per_end between emt_from and last_day(nvl(emt_to, hrm_date.activeperiodenddate)))
                                group by elm_tax_per_end, hrm_person_id
                                having sum(elm_tax_source)<>0
                          )
        then pcs.pc_functions.translateword('Déductions IS dans le journal hors période d''assujettissement')
    end into lv_text
    from dual;

    /* Insertion dans la table des erreurs en cas de problème */
    if lv_text is not null then
        fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_hrm_entity.gcHrmErrorsLog, iot_crud_definition => lt_crud_def);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'HRM_EMPLOYEE_ID', in_empid);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'HRM_ELEMENTS_ID', 0);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ELO_MESSAGE', lv_text);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ELO_DATE', sysdate);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ELO_TYPE', 1);
        p_insert_log(lt_crud_def);
        fwk_i_mgt_entity.release(lt_crud_def);
        commit;
    end if;
  end;


  /* Taxation brute sans tenir compte de la déduction éventuellement déjà opérée */
  function tax_amount_gross(
    in_employe_id               in hrm_person.hrm_person_id%type
  , iv_type_regular_normal      in varchar2 default ''
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
  , in_amount_forced_deduction  in number default 0
  )
    return number
  is
  begin
     return tax_amount_net(    in_employe_id=>in_employe_id
                              , iv_type_regular_normal=> iv_type_regular_normal
                              , in_amount_regular_normal=>in_amount_regular_normal
                              , iv_type_sporadic_normal=>iv_type_sporadic_normal
                              , in_amount_sporadic_normal=>in_amount_sporadic_normal
                              , iv_type_regular_fte=>iv_type_regular_fte
                              , in_amount_regular_fte=>in_amount_regular_fte
                              , iv_type_sporadic_fte=>iv_type_sporadic_fte
                              , in_amount_sporadic_fte=>in_amount_sporadic_fte
                              , iv_type_activity_rate=>iv_type_activity_rate
                              , in_amount_activity_rate=>in_amount_activity_rate
                              , iv_type_rate_only=>iv_type_rate_only
                              , in_amount_rate_only=>in_amount_rate_only
                              , in_amount_hourly_rate=>in_amount_hourly_rate
                              , in_amount_estimated_revenue=>in_amount_estimated_revenue
                              , iv_canton=>''
                              , iv_type_deduction=>''
                              , iv_type_rate_only_normal=>iv_type_rate_only_normal
                              , in_amount_rate_only_normal=>in_amount_rate_only_normal
                              , iv_version=>null
                              , in_amount_forced_deduction=>in_amount_forced_deduction);
  end tax_amount_gross;


  /* Taxation nette en tenant compte des montants déjà perçus */
  function tax_amount_net(
    in_employe_id               in hrm_person.hrm_person_id%type
  , iv_type_regular_normal      in varchar2 default ''
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
  , iv_version                  in varchar2 default null
  , in_amount_forced_deduction  in number default 0
  )
    return number
  is
    ln_pay_num integer;
    lt_periods tt_periods;
    lt_histo_totals tt_histo_totals;
    ln_result number;
    lt_recap tt_yearly_recap;
    lb_hourly_tax boolean := false;
  begin

    lt_periods := p_tax_periods(in_employe_id);

    if lt_periods.count > 0 then

        -- Pour les employés devenus permis C ou naturalisé, il n'y a plus de déduction
--        if naturalized_settled(in_employe_id) then
--          return 0.0;
--        end if;

        -- recherche du dernier numéro de décompte de l'employé
        ln_pay_num  := p_get_last_pay_num(in_employe_id);

        -- suppression du log de l'entrée éventuellement déjà existante
        p_delete_log(in_employe_id, ln_pay_num);

        -- Extraction des données nécessaires de l'historique de l'année
        lt_histo_totals := p_histo_sums_in_year(IN_EMPLOYE_ID => in_employe_id,
                                        IV_TYPE_REGULAR_NORMAL =>IV_TYPE_REGULAR_NORMAL,
                                        IV_TYPE_ACTIVITY_RATE => IV_TYPE_ACTIVITY_RATE,
                                        IV_TYPE_REGULAR_FTE => IV_TYPE_REGULAR_FTE,
                                        IV_TYPE_SPORADIC_NORMAL => IV_TYPE_SPORADIC_NORMAL ,
                                        IV_TYPE_SPORADIC_FTE => IV_TYPE_SPORADIC_FTE ,
                                        IV_TYPE_RATE_ONLY => IV_TYPE_RATE_ONLY ,
                                        IV_TYPE_RATE_ONLY_NORMAL => IV_TYPE_RATE_ONLY_NORMAL
                                        , iv_version => iv_version);


        -- traitement particulier des employés à l'heure, aucune annualisation on ne tient compte que des
        -- valeurs en paramètre ainsi que de la période d'assujettissement
        if in_amount_hourly_rate <> 0  then
          ln_result:= p_taxation_horaire(in_employe_id
                                  , in_amount_regular_normal
                                  , in_amount_sporadic_normal
                                  , in_amount_regular_fte
                                  , in_amount_sporadic_fte
                                  , in_amount_hourly_rate
                                  , lt_periods
                                  , lb_hourly_tax
                                   );
        end if;

        /* Si la taxation horaire retourne 0 ou n'a pas été appelée */
        if not(lb_hourly_tax) then
          ln_result:= p_regular_taxation(in_employe_id=>in_employe_id
                                  , in_amount_regular_normal=>in_amount_regular_normal
                                  , in_amount_sporadic_normal=>in_amount_sporadic_normal
                                  , in_amount_regular_fte=>in_amount_regular_fte
                                  , in_amount_sporadic_fte=>in_amount_sporadic_fte
                                  , in_amount_activity_rate=> case
                                      when in_amount_activity_rate = 0 then 100
                                      else in_amount_activity_rate
                                    end
                                  , in_amount_rate_only=>in_amount_rate_only
                                  , in_amount_hourly_rate=>in_amount_hourly_rate
                                  , in_amount_estimated_revenue =>in_amount_estimated_revenue
                                  , iv_type_in =>'DEDUCTION'
                                  , in_amount_rate_only_normal=>in_amount_rate_only_normal
                                  , it_periods=>lt_periods
                                  , it_totals=>lt_histo_totals
                                  , iv_canton => iv_canton
                                  , in_amount_forced_deduction => in_amount_forced_deduction
                                   );


           if nvl(length(iv_type_deduction),0) > 0 then
            /* Déduction de l'impôt déjà perçu */
            ln_result := ln_result + p_deducted_histo_amount(in_employe_id => in_employe_id, iv_type_deducted => iv_type_deduction, it_periods=> lt_periods, iv_canton => iv_canton);
           end if;
        end if;

    else
        /* Remboursement de l'impôt prélevé si aucun canton n'a été renseigné
           et qu'aucune période d'assujettissement n'existe
        */
        if iv_canton is null and nvl(length(iv_type_deduction),0) > 0 then
            ln_result := p_deducted_histo_amount(in_employe_id => in_employe_id, iv_type_deducted => iv_type_deduction, it_periods=> lt_periods, iv_canton => iv_canton);
        end if;
    end if;

    /*
    Vérification de la présence dans le journal de lignes hors période d'assujettissement
    Dans ce cas, elles ne sont pas prises en compte dans le calcul et par conséquent, on remonte une erreur
    */
    p_check_wrong_ledger_periods(in_employe_id);

    return ln_result;

  end tax_amount_net;



  /* Montant de taxe déjà perçue dans l'année */
  function deducted_tax_for_period(in_employe_id in hrm_person.hrm_person_id%type, iv_type_deducted in varchar2)
    return number
  is
    ln_result     number                    := 0;
    ln_period_idx        pls_integer:=0;
    lt_periods   tt_periods;
    ln_amount number;
  begin
    -- Recherche des périodes d'assujettissement et des salaires y relatifs
    -- pour le calcul de la déduction totale
     lt_periods := p_tax_periods(in_employe_id);

     return p_deducted_histo_amount(in_employe_id => in_employe_id, iv_type_deducted => iv_type_deducted, it_periods=> lt_periods, iv_canton=>null);
  end deducted_tax_for_period;


  /* Ajustement de la date de début d'assujettissement */
  function reference_period_start( iv_emt_value in varchar2, iv_tax_out in varchar2, id_from in date, id_to in date)
    return date
  is
    ld_result date;
  begin

    if id_to is not null and id_to < gd_begin_year then
        ld_result:=greatest(id_from, trunc(id_to,'month'));

    else
        ld_result:= greatest(id_from, gd_begin_year);
    end if;


    return ld_result;
  exception
    when no_data_found then
      return gd_period_begin;
  end reference_period_start;


  /* Ajustement de la fin d'assujettissement */
  function reference_period_end(in_employee_id in hrm_person.hrm_person_id%type, id_from in date, id_to in date, iv_tax_out in varchar2)
    return date
  is
    ld_result date;
  begin

    if id_to is null then
        ld_result := case when gd_period_end >= id_from then gd_period_end else gd_end_year end;

    else
        if iv_tax_out in ('01','04') then
            ld_result := least(gd_period_end, p_nextintaxdate(id_from, in_employee_id));
        else
            -- Pour les naturalisés / permis C, on s'arrête à la fin du mois
            ld_result := last_day(id_to);
        end if;
    end if;

    return ld_result;
  exception
    when no_data_found then
      return gd_period_end;
  end reference_period_end;

  procedure set_debug(ib in boolean default true)
  is
  begin
   g_debug := ib;
  end;




begin
  hrm_date.PeriodDates(gd_period_begin, gd_period_end);
  gd_begin_year :=trunc(gd_period_end, 'Y');
  gd_end_year := add_months(trunc(gd_period_end, 'Y'),12)-1;
end HRM_TAXSOURCE;
