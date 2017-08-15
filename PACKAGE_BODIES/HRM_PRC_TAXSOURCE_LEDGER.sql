--------------------------------------------------------
--  DDL for Package Body HRM_PRC_TAXSOURCE_LEDGER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_TAXSOURCE_LEDGER" 
as
  /**
  * procedure p_UpdatePayNumTaxSourceLedger
  * description :
  *    Attribue un décompte aux journalisations qui n'ont pas encore de décompte défini
  */
  procedure p_UpdatePayNumTaxSourceLedger(iLedgerId in HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin

      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', iLedgerId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM', iPayNum);
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
  end P_UpdatePayNumTaxSourceLedger;

  /**
  * procedure ReverseTaxSourceLedger
  * description :
  *    Extourne d'une ligne de journalisation de l'impôt à la source
  *    Le type permet d'indiquer de quel type doit être la correction, ceci pour faire en sorte que les manipulations
  *    effectuées manuellement ne soient pas traitées de la même manière que ce qui est automatique.
  *    Ainsi, une correction manuelle aura le type '04' alors qu'une correction automatique le code '01'. Ceci permet d'automatiser l'annulation de définitif en ne supprimant pas les éléments manuels
  */
  procedure p_ReverseTaxSourceLedger(
    iTaxSourceLedgerID  in     HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  , iType               in     HRM_TAXSOURCE_LEDGER.C_ELM_TAX_TYPE%TYPE
  , oReverseLedgerID    out    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  , oCorrectionLedgerID out    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  )
  is
    ltTaxSourceLedger   FWK_I_TYP_DEFINITION.t_crud_def;
    ltplTaxSourceLedger FWK_TYP_HRM_ENTITY.tTaxSourceLedger;
  begin
    -- Création de la ligne d'extourne par copie de l'originale
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.PrepareDuplicate(ltTaxSourceLedger, true, iTaxSourceLedgerID);
    -- Récuper les données sous forme de tuple (pour une manipulation plus aisée)
    ltplTaxSourceLedger  := FWK_TYP_HRM_ENTITY.gttTaxSourceLedger(ltTaxSourceLedger.entity_id);
    -- Type :  Correction DPI
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_ELM_TAX_TYPE', '02');
    -- Lien sur la ligne originale
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_EXT_ID', iTaxSourceLedgerID);
    -- Inversion des montant
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_ASCERTAIN_EARNING', ltplTaxSourceLedger.ELM_TAX_ASCERTAIN_EARNING * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_BOARD', ltplTaxSourceLedger.ELM_TAX_BOARD * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHARGES_EFFECTIVE', ltplTaxSourceLedger.ELM_TAX_CHARGES_EFFECTIVE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHARGES_LUMP', ltplTaxSourceLedger.ELM_TAX_CHARGES_LUMP * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHURCH', ltplTaxSourceLedger.ELM_TAX_CHURCH * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CORR_ASCERTAIN_TAXABLE', ltplTaxSourceLedger.ELM_TAX_CORR_ASCERTAIN_TAXABLE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CORR_TAX', ltplTaxSourceLedger.ELM_TAX_CORR_TAX * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CORR_TAXABLE', ltplTaxSourceLedger.ELM_TAX_CORR_TAXABLE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_DECL_ASCERTAIN_TAXABLE', ltplTaxSourceLedger.ELM_TAX_DECL_ASCERTAIN_TAXABLE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_DECL_TAX', ltplTaxSourceLedger.ELM_TAX_DECL_TAX * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_DECL_TAXABLE', ltplTaxSourceLedger.ELM_TAX_DECL_TAXABLE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EARNING', ltplTaxSourceLedger.ELM_TAX_EARNING * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_FAMILY_INCOME', ltplTaxSourceLedger.ELM_TAX_FAMILY_INCOME * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_OWNERSHIP_RIGHTS', ltplTaxSourceLedger.ELM_TAX_OWNERSHIP_RIGHTS * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SOURCE', ltplTaxSourceLedger.ELM_TAX_SOURCE * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SPORADIC', ltplTaxSourceLedger.ELM_TAX_SPORADIC * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_TERMINATION', ltplTaxSourceLedger.ELM_TAX_TERMINATION * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_DAYS', ltplTaxSourceLedger.ELM_TAX_DAYS * -1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_RATE', ltplTaxSourceLedger.ELM_TAX_RATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EXT', ltplTaxSourceLedger.ELM_TAX_EXT * -1);
    -- Champs à ne pas reprendre
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_CONF_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM');
    -- Insertion
    FWK_I_MGT_ENTITY.InsertEntity(ltTaxSourceLedger);
    -- Récupérer l'id de la ligne d'extourne
    oReverseLedgerID     := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID');
    FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    --
    --
    -- Création de la ligne de correction par copie de l'originale
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.PrepareDuplicate(ltTaxSourceLedger, true, iTaxSourceLedgerID);
    -- Lien sur la ligne originale
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_EXT_ID', iTaxSourceLedgerID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_ELM_TAX_TYPE', iType);
    -- Champs à ne pas reprendre
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_CONF_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM');
    FWK_I_MGT_ENTITY.InsertEntity(ltTaxSourceLedger);
    -- Récupérer l'id de la ligne de correction
    oCorrectionLedgerID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID');
    FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
  end p_ReverseTaxSourceLedger;


  /**
  * procedure InsertTaxSourceLedger
  * description :
  *    Ajout d'une ligne de journalisation de l'impôt à la source
  */
  procedure InsertTaxSourceLedger(
    iEmployeeID        in     HRM_PERSON.HRM_PERSON_ID%type
  , iPayNum            in     HRM_HISTORY_DETAIL.HIS_PAY_NUM%type
  , oTaxSourceLedgerID out    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  )
  is
    /* Contient les données du décompte courant ainsi que différents codes pour la journalisation. */
    cursor lcrTaxSourceLedger
    is
      select his.*
           , EMT.EMT_CANTON
           , EMT.EMT_VALUE
           , EMT.EMT_VALUE_SPECIAL
           , EMT.C_HRM_IS_CAT
           , EMT.EMT_TO
           , case
               when exist_indate = 0
               and emt_from > add_months(HRM_DATE.ACTIVEPERIODENDDATE, -1) then c_hrm_tax_in
             end c_hrm_tax_in
           , case
               when exist_indate = 0
               and emt_from > add_months(HRM_DATE.ACTIVEPERIODENDDATE, -1) then c_hrm_tax_in2
             end c_hrm_tax_in2
           , case
               when exist_indate = 0
               and emt_from > add_months(HRM_DATE.ACTIVEPERIODENDDATE, -1) then c_hrm_tax_in3
             end c_hrm_tax_in3
           , case
               when exist_indate = 0
               and emt_from > add_months(HRM_DATE.ACTIVEPERIODENDDATE, -1) then c_hrm_tax_in4
             end c_hrm_tax_in4
           , case
               when exist_outdate = 0
               and emt_to <= HRM_DATE.ACTIVEPERIODENDDATE then c_hrm_tax_out
             end c_hrm_tax_out
           , case
               when exist_indate = 0
               and emt_from > add_months(HRM_DATE.ACTIVEPERIODENDDATE, -1) then emt_from
             end ELM_TAX_IN_DATE
           , case
               when exist_outdate = 0
               and emt_to <= HRM_DATE.ACTIVEPERIODENDDATE then emt_to
             end ELM_TAX_OUT_DATE
           , PC_OFS_CITY_ID
           , EMT_SPECIAL_CODE ELM_TAX_SPECIAL_CODE
        from (select sum(case
                           when COE.COE_BOX = 'A' then HIS.HIS_PAY_SUM_VAL
                           else 0
                         end) as AMOUNT_A
                   , sum(case
                           when COE.COE_BOX = 'B' then(HIS.HIS_PAY_SUM_VAL * -1)
                           else 0
                         end) as AMOUNT_B
                   , sum(case
                           when COE.COE_BOX = 'REF' then HIS.HIS_PAY_SUM_VAL
                           else 0
                         end) as AMOUNT_REF
                   , sum(case
                           when coe_box = 'C' then his_pay_sum_val
                           else 0
                         end) ChurchTaxCumulative
                   , sum(case
                           when coe_box = 'D' then his_pay_sum_val
                           else 0
                         end) TerminationPayCumulative
                   , sum(case
                           when coe_box = 'E' then his_pay_sum_val
                           else 0
                         end) SporadicBenefitsCumulative
                   , sum(case
                           when coe_box = 'F' then his_pay_sum_val
                           else 0
                         end) OwnershipRightsCumulative
                   , sum(case
                           when coe_box = 'G' then his_pay_sum_val
                           else 0
                         end) BoardOfDirectorsRemuneration
                   , sum(case
                           when coe_box = 'H' then his_pay_sum_val
                           else 0
                         end) FamilyIncomeCumulative
                   , sum(case
                           when coe_box = 'I' then his_pay_sum_val
                           else 0
                         end) ChargesEffectiveCumulative
                   , sum(case
                           when coe_box = 'J' then his_pay_sum_val
                           else 0
                         end) ChargesLumpSumCumulative
                   ,
                     --max(case when coe_box = '' then his_pay_sum_val else 0 end) GrantAtSourceCode,
                     sum(case
                           when coe_box = 'DAYS' then his_pay_sum_val
                           else 0
                         end) WorkDaysCumulativeCH
                   , sum(case
                           when coe_box = 'EXT' then his_pay_sum_val
                           else 0
                         end) EXTERNAL_REVENUE
                   , max(case
                           when coe_box = 'RATE' then his_pay_sum_val
                           else 0
                         end) ACTIVITY_RATE
                from HRM_HISTORY_DETAIL HIS
                   , HRM_CONTROL_ELEMENTS COE
                   , HRM_CONTROL_LIST COL
               where HIS.HRM_ELEMENTS_ID = COE.HRM_CONTROL_ELEMENTS_ID
                 and COE.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                 and COL.C_CONTROL_LIST_TYPE = '111'
                 and HIS.HRM_EMPLOYEE_ID = iEmployeeID
                 and HIS.HIS_PAY_NUM = iPayNum) his
           , (select t.*
                   , case
                       when exists(select 1
                                     from hrm_taxsource_ledger l
                                    where l.hrm_person_id = t.hrm_person_id
                                      and elm_tax_in_date = emt_from
                                      and elm_tax_per_end <= HRM_DATE.ACTIVEPERIODENDDATE) then 1
                       else 0
                     end exist_indate
                   , case
                       when exists(select 1
                                     from hrm_taxsource_ledger l
                                    where l.hrm_person_id = t.hrm_person_id
                                      and elm_tax_out_date = emt_to
                                      and elm_tax_per_end <= HRM_DATE.ACTIVEPERIODENDDATE) then 1
                       else 0
                     end exist_outdate
                from hrm_employee_taxsource t) EMT
       where emt.hrm_person_id = iEmployeeID
         and HRM_DATE.ACTIVEPERIODENDDATE between EMT_FROM and HRM_TAXSOURCE.REFERENCE_PERIOD_END(EMT.HRM_PERSON_ID, EMT_FROM, EMT_TO, C_HRM_TAX_OUT);

    ltplTaxSourceLedger           lcrTaxSourceLedger%rowtype;
    ltTaxSourceLedger             FWK_I_TYP_DEFINITION.t_crud_def;
    -- Periode du décompte actuel
    ldCurrPeriod                  HRM_EMPLOYEE_TAXSOURCE.EMT_TO%type;
    -- montants du soumis, déterminant et de l'impôt pour le mois curant
    lCurrTaxAtSource              HRM_TAXSOURCE_LEDGER.ELM_TAX_SOURCE%type;
    lCurrTaxableEarning           HRM_TAXSOURCE_LEDGER.ELM_TAX_EARNING%type;
    lCurrAscertainedTaxableEaring HRM_TAXSOURCE_LEDGER.ELM_TAX_ASCERTAIN_EARNING%type;
    -- somme des montants du soumis, déterminant et de l'impôt déjà déclarés
    lSumLedgerTaxAtSource         HRM_TAXSOURCE_LEDGER.ELM_TAX_SOURCE%type;
    lSumTaxableEarning            HRM_TAXSOURCE_LEDGER.ELM_TAX_EARNING%type;
    lSumAscertainedTaxableEaring  HRM_TAXSOURCE_LEDGER.ELM_TAX_ASCERTAIN_EARNING%type;
    -- Ligne d'extourne et de correction d'une ligne du mois déclaré dans les données complémentaires
    lCurrMonthReverseLedgerID     HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
    lCurrMonthCorrectionLedgerID  HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
  begin
    oTaxSourceLedgerID  := null;

    open lcrTaxSourceLedger;

    fetch lcrTaxSourceLedger
     into ltplTaxSourceLedger;

    -- Test s'il y a des données complémentaires à prendre en considération
    if HRM_LIB_HISTORY.HasAdditionalData(iEmployeeID, iPayNum) = 1 then

      begin
        -- Recherche du mois auquel sont liées les valeurs du décompte courant
        -- Normalement le mois courant, mais pour les personnes sorties, c'est le mois de départ
        select least(nvl(last_day(EMT_TO), to_date('31.12.2999', 'dd.mm.yyyy') ), HRM_DATE.ACTIVEPERIODENDDATE)
          into ldCurrPeriod
          from HRM_EMPLOYEE_TAXSOURCE EMT
         where HRM_PERSON_ID = iEmployeeID
           and HRM_DATE.ACTIVEPERIODENDDATE between EMT_FROM and HRM_TAXSOURCE.REFERENCE_PERIOD_END(HRM_PERSON_ID, EMT_FROM, EMT_TO, C_HRM_TAX_OUT);
      exception
        when no_data_found then
          ldCurrPeriod := hrm_date.activeperiodenddate;
      end;

      -- boucle sur les périodes de l'XML présent pour le décompte. Contient tous les mois impactés par le décompte
      for ltplXmlAdditionalData in (select to_date(PERIOD, 'YYYYMMDD') PERIOD
                                         , TAXATSOURCE
                                         , TAXABLEEARNING
                                         , ASCERTAINEDTAXABLEEARNING
                                         , CANTON
                                      from hrm_history,
                                           XMLTABLE (
                                              '//HRM_TAXSOURCE/HRM_TAX_PERIOD'
                                              PASSING XMLTYPE (HIT_ADDITIONAL_DATA)
                                              COLUMNS PERIOD VARCHAR2 (8) PATH '/HRM_TAX_PERIOD/MONTH',
                                                      TAXATSOURCE NUMBER
                                                            PATH '/HRM_TAX_PERIOD/TAXATSOURCE',
                                                      TAXABLEEARNING NUMBER
                                                            PATH '/HRM_TAX_PERIOD/TAXABLEEARNING',
                                                      ASCERTAINEDTAXABLEEARNING NUMBER
                                                            PATH '/HRM_TAX_PERIOD/ASCERTAINEDTAXABLEEARNING',
                                                      CANTON VARCHAR2(10) PATH '/HRM_TAX_PERIOD/CANTON'
                                                      ) tc
                                     where hrm_employee_id = iEmployeeID
                                       and hit_pay_num = iPayNum) loop

        -- récupère la somme des montants déclarés issus de la journalisation
        select nvl(sum(ELM_TAX_SOURCE), 0)
             , nvl(sum(ELM_TAX_EARNING), 0)
             , nvl(sum(ELM_TAX_ASCERTAIN_EARNING), 0)
          into lSumLedgerTaxAtSource
             , lSumTaxableEarning
             , lSumAscertainedTaxableEaring
          from hrm_taxsource_ledger
         where hrm_person_id = iEmployeeID
           and elm_tax_per_end = ltplXmlAdditionalData.PERIOD
           and c_hrm_canton = ltplXmlAdditionalData.CANTON;

        -- s'il y a une différence entre le journal et le xml
        if    (ltplXmlAdditionalData.TAXATSOURCE <> lSumLedgerTaxAtSource)
           or (ltplXmlAdditionalData.TAXABLEEARNING <> lSumTaxableEarning)
           or (ltplXmlAdditionalData.ASCERTAINEDTAXABLEEARNING <> lSumAscertainedTaxableEaring) then
          lCurrMonthCorrectionLedgerID  := 0;

          -- Extourne toutes les lignes du journal pour le mois concerné et insertion des corrections
          for ltplCurrMonthLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                        from hrm_taxsource_ledger ELMP
                                       where hrm_person_id = iEmployeeID
                                         and ELM_TAX_PER_END = ltplXmlAdditionalData.period
                                         and c_hrm_canton = ltplXmlAdditionalData.canton
                                         and c_elm_tax_type != '02'
                                         and not exists(select 1
                                                          from hrm_taxsource_ledger ELMC
                                                         where ELMC.HRM_TAXSOURCE_LEDGER_EXT_ID = ELMP.HRM_TAXSOURCE_LEDGER_ID) ) loop
            lCurrMonthCorrectionLedgerID :=0;
            p_ReverseTaxSourceLedger(ltplCurrMonthLedger.HRM_TAXSOURCE_LEDGER_ID, '01',lCurrMonthReverseLedgerID, lCurrMonthCorrectionLedgerID);

            -- Liaison au décompte courant pour éviter un problème à l'annulation de définitif
            P_UpdatePayNumTaxSourceLedger(lCurrMonthReverseLedgerID, iPaynum);
            P_UpdatePayNumTaxSourceLedger(lCurrMonthCorrectionLedgerID, iPaynum);

            -- Mise à jour des montants de la correction à 0 car c'est la dernière ligne du mois qui impactée
            UpdateTaxSourceLedgerAmount(lCurrMonthCorrectionLedgerID, 0, 0, 0);
          end loop;

          -- Mise à jour des montants de l'impôt, soumis et déterminant sur la dernière ligne de correction
          -- en fonction de l'XML si ce n'est pas le mois actuel
          if ltplXmlAdditionalData.PERIOD <> ldCurrPeriod then
            if lCurrMonthCorrectionLedgerID = 0 then
              raise_application_error(-20115, pcs.pc_functions.translateword('Veuillez compléter le journal de l''impôt à la source du mois') || ' ' || TO_CHAR(ltplXmlAdditionalData.PERIOD, 'MM') || '/' || TO_CHAR(ltplXmlAdditionalData.PERIOD, 'YYYY'));
            else
              UpdateTaxSourceLedgerAmount(lCurrMonthCorrectionLedgerID
                                        , ltplXmlAdditionalData.TAXATSOURCE
                                        , ltplXmlAdditionalData.TAXABLEEARNING
                                        , ltplXmlAdditionalData.ASCERTAINEDTAXABLEEARNING
                                         );
            end if;
          else
            /* Définition des montants pour le mois courant à insérer plus tard */
            lCurrTaxAtSource               := ltplXmlAdditionalData.TAXATSOURCE;
            lCurrTaxableEarning            := ltplXmlAdditionalData.TAXABLEEARNING;
            lCurrAscertainedTaxableEaring  := ltplXmlAdditionalData.ASCERTAINEDTAXABLEEARNING;
          end if;
        end if;
      end loop;
    else
      -- Pas de correction depuis le XML, on prend les valeurs du curseur
      lCurrTaxAtSource               := ltplTaxSourceLedger.AMOUNT_B;
      lCurrTaxableEarning            := ltplTaxSourceLedger.AMOUNT_A;
      lCurrAscertainedTaxableEaring  := ltplTaxSourceLedger.AMOUNT_REF;
    end if;

    if lcrTaxSourceLedger%found then
      -- Init des données du tuple HRM_TAXSOURCE_LEDGER
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_PERSON_ID', iEmployeeID);
      -- Canton
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_CANTON', ltplTaxSourceLedger.EMT_CANTON);
      -- Date de fin de période
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger
                                    , 'ELM_TAX_PER_END'
                                    , least(nvl(last_day(case when ltplTaxSourceLedger.EMT_TO < hrm_date.BeginOfYear
                                                         then HRM_DATE.ActivePeriodEndDate
                                                         else ltplTaxSourceLedger.EMT_TO end), HRM_DATE.ActivePeriodEndDate), HRM_DATE.ActivePeriodEndDate)
                                     );
      -- Type de taxe : Déclaré
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_ELM_TAX_TYPE', '01');
      --
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE', ltplTaxSourceLedger.EMT_VALUE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_IS_CAT', ltplTaxSourceLedger.C_HRM_IS_CAT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE_OPEN', ltplTaxSourceLedger.EMT_VALUE_SPECIAL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM', iPayNum);
      -- Position A
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EARNING', nvl(lCurrTaxableEarning, 0) );
      -- Position B
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SOURCE', nvl(lCurrTaxAtSource, 0) );
      -- Position REF
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_ASCERTAIN_EARNING', nvl(lCurrAscertainedTaxableEaring, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHURCH', nvl(ltplTaxSourceLedger.ChurchTaxCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_TERMINATION', nvl(ltplTaxSourceLedger.TerminationPayCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SPORADIC', nvl(ltplTaxSourceLedger.SporadicBenefitsCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_OWNERSHIP_RIGHTS', nvl(ltplTaxSourceLedger.OwnershipRightsCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_BOARD', nvl(ltplTaxSourceLedger.BoardOfDirectorsRemuneration, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_FAMILY_INCOME', nvl(ltplTaxSourceLedger.FamilyIncomeCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHARGES_EFFECTIVE', nvl(ltplTaxSourceLedger.ChargesEffectiveCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CHARGES_LUMP', nvl(ltplTaxSourceLedger.ChargesLumpSumCumulative, 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_DAYS', nvl(ltplTaxSourceLedger.WorkDaysCumulativeCH, 0) );
      -- Mutations
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_IN', ltplTaxSourceLedger.C_HRM_TAX_IN);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_IN2', ltplTaxSourceLedger.C_HRM_TAX_IN2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_IN3', ltplTaxSourceLedger.C_HRM_TAX_IN3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_IN4', ltplTaxSourceLedger.C_HRM_TAX_IN4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_OUT', ltplTaxSourceLedger.C_HRM_TAX_OUT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_IN_DATE', ltplTaxSourceLedger.ELM_TAX_IN_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_OUT_DATE', ltplTaxSourceLedger.ELM_TAX_OUT_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'PC_OFS_CITY_ID', ltplTaxSourceLedger.PC_OFS_CITY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SPECIAL_CODE', ltplTaxSourceLedger.ELM_TAX_SPECIAL_CODE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_RATE', ltplTaxSourceLedger.ACTIVITY_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EXT', ltplTaxSourceLedger.EXTERNAL_REVENUE);
      FWK_I_MGT_ENTITY.InsertEntity(ltTaxSourceLedger);
      -- Id de la journalisation crée
      oTaxSourceLedgerID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID');
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end if;

    close lcrTaxSourceLedger;
  end InsertTaxSourceLedger;

  procedure InsertTaxSourceLedgerACI(
    iEmployeeID                  in HRM_PERSON.HRM_PERSON_ID%type
  , iElmRecipientID              in HRM_TAXSOURCE_LEDGER.HRM_ELM_RECIPIENT_ID%type
  , iHRMCanton                   in HRM_TAXSOURCE_LEDGER.C_HRM_CANTON%type
  , iEndPeriodDate               in date
  , iOldTaxAtSource              in HRM_TAXSOURCE_LEDGER.ELM_TAX_SOURCE%type
  , iOldTaxableEarning           in HRM_TAXSOURCE_LEDGER.ELM_TAX_EARNING%type
  , iOldAscertainedTaxableEaring in HRM_TAXSOURCE_LEDGER.ELM_TAX_ASCERTAIN_EARNING%type
  , iNewTaxAtSource              in HRM_TAXSOURCE_LEDGER.ELM_TAX_SOURCE%type
  , iNewTaxableEarning           in HRM_TAXSOURCE_LEDGER.ELM_TAX_EARNING%type
  , iNewAscertainedTaxableEaring in HRM_TAXSOURCE_LEDGER.ELM_TAX_ASCERTAIN_EARNING%type
  )
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
    l_reversed        HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
    l_ofsCity         HRM_TAXSOURCE_LEDGER.PC_OFS_CITY_ID%type;
    l_taxCode         HRM_TAXSOURCE_LEDGER.ELM_TAX_CODE%type;
    l_isCat           HRM_TAXSOURCE_LEDGER.C_HRM_IS_CAT%type;
    l_taxCodeOpen     HRM_TAXSOURCE_LEDGER.ELM_TAX_CODE_OPEN%type;
  begin
    select L.HRM_TAXSOURCE_LEDGER_ID
         , L.PC_OFS_CITY_ID
         , L.ELM_TAX_CODE
         , L.C_HRM_IS_CAT
         , L.ELM_TAX_CODE_OPEN
      into l_reversed
         , l_ofsCity
         , l_taxCode
         , l_isCat
         , l_taxCodeOpen
      from HRM_TAXSOURCE_LEDGER L
     where L.HRM_TAXSOURCE_LEDGER_ID =
                         (select max(TSL.HRM_TAXSOURCE_LEDGER_ID)
                            from HRM_TAXSOURCE_LEDGER TSL
                           where HRM_PERSON_ID = iEmployeeID
                             and C_HRM_CANTON = iHRMCanton
                             and C_ELM_TAX_TYPE in('01', '04')
                             --and  NOT EXISTS(SELECT 1 FROM HRM_TAXSOURCE_LEDGER L2  WHERE L2.HRM_TAXSOURCE_LEDGER_EXT_ID = TSL.HRM_TAXSOURCE_LEDGER_ID )
                             and ELM_TAX_PER_END = iEndPeriodDate);

    -- Init des données du tuple HRM_TAXSOURCE_LEDGER pour la soumission
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_PERSON_ID', iEmployeeID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_ID', iElmRecipientID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_CANTON', iHRMCanton);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_PER_END', iEndPeriodDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_ELM_TAX_TYPE', '03');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EARNING', iOldTaxableEarning);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SOURCE', iOldTaxAtSource);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_ASCERTAIN_EARNING', iOldAscertainedTaxableEaring);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_EXT_ID', l_reversed);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'PC_OFS_CITY_ID', l_ofsCity);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE', l_taxCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_IS_CAT', l_isCat);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE_OPEN', l_taxCodeOpen);
    FWK_I_MGT_ENTITY.InsertEntity(ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger, true);
    -- Init des données du tuple HRM_TAXSOURCE_LEDGER pour la correction
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_PERSON_ID', iEmployeeID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_ID', iElmRecipientID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_CANTON', iHRMCanton);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_PER_END', iEndPeriodDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_ELM_TAX_TYPE', '03');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EARNING', iNewTaxableEarning);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SOURCE', iNewTaxAtSource);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_ASCERTAIN_EARNING', iNewAscertainedTaxableEaring);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_EXT_ID', l_reversed);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'PC_OFS_CITY_ID', l_ofsCity);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE', l_taxCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_IS_CAT', l_isCat);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_CODE_OPEN', l_taxCodeOpen);
    FWK_I_MGT_ENTITY.InsertEntity(ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
  exception
    when no_data_found then
      raise_application_error(-20000, pcs.pc_functions.translateword('Intégration impossible, l''enregistrement original est introuvable.') );
  end;

  /**
  * procedure UpdatePayNumTaxSourceLedger
  * description :
  *    Attribue un décompte aux journalisations qui n'ont pas encore de décompte défini pour les corrections automatiques
  */
  procedure UpdatePayNumTaxSourceLedger(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                  from hrm_taxsource_ledger l1
                                 where elm_tax_hit_pay_num is null
                                   and hrm_person_id = iEmployeeID
                                   and (   c_elm_tax_type != '01'
                                        or exists(select 1
                                                    from hrm_taxsource_ledger l2
                                                   where l2.HRM_TAXSOURCE_LEDGER_EXT_ID = l1.HRM_TAXSOURCE_LEDGER_ID) ) ) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM', iPayNum);
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end loop;
  end UpdatePayNumTaxSourceLedger;

  /**
  * procedure UpdateTaxSourceLedgerAmount
  * description :
  *    Met à jour les montant de l'impôt, du soumis et du déterminant
  */
  procedure UpdateTaxSourceLedgerAmount(
    iTaxSourceLedgerID           in HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  , iNewTaxAtSource              in HRM_TAXSOURCE_LEDGER.ELM_TAX_SOURCE%type
  , iNewTaxableEarning           in HRM_TAXSOURCE_LEDGER.ELM_TAX_EARNING%type
  , iNewAscertainedTaxableEaring in HRM_TAXSOURCE_LEDGER.ELM_TAX_ASCERTAIN_EARNING%type
  )
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', iTaxSourceLedgerID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_SOURCE', iNewTaxAtSource);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_EARNING', iNewTaxableEarning);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'ELM_TAX_ASCERTAIN_EARNING', iNewAscertainedTaxableEaring);
    FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
    FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
  end UpdateTaxSourceLedgerAmount;

  /**
  * procedure DeletePayNumTaxSourceLedger
  * description :
  *    Effacement des lignes de journalisation de l'impôt à la source pour un certain décompte
  */
  procedure DeletePayNumTaxSourceLedger(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type, iPayNum in HRM_HISTORY_DETAIL.HIS_PAY_NUM%type)
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin

    /* Suppression des records */
    for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                 from HRM_TAXSOURCE_LEDGER l1
                                 where HRM_PERSON_ID = iEmployeeID
                                   and ELM_TAX_HIT_PAY_NUM = iPayNum
                                   /* Ne supprimer que les types générés automatiquement, ne pas supprimer les éléments corrigés manuellement par l'utilisateur */
                                   and (C_ELM_TAX_TYPE = '01'
                                        or (C_ELM_TAX_TYPE = '02'
                                            -- corrections pour lesquelles il y a un élément de correction avec le même identifiant
                                            and exists(select 1
                                                    from hrm_taxsource_ledger l2
                                                   where l1.HRM_TAXSOURCE_LEDGER_EXT_ID = l2.HRM_TAXSOURCE_LEDGER_ext_ID
                                                   and l2.c_elm_tax_type = '01')
                                           )
                                       )
                                   -- Non extournés dans un autre décompte
                                   and not exists(select 1
                                                    from hrm_taxsource_ledger l2
                                                   where l2.HRM_TAXSOURCE_LEDGER_EXT_ID = l1.HRM_TAXSOURCE_LEDGER_ID
                                                   and l2.elm_tax_hit_pay_num <> iPayNum)) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end loop;

    -- On remet également les corrections d'impôts à null
    for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                  from hrm_taxsource_ledger l1
                                 where elm_tax_hit_pay_num = iPayNum
                                   and hrm_person_id = iEmployeeID
                                   and (   c_elm_tax_type != '01'
                                        or exists(select 1
                                                    from hrm_taxsource_ledger l2
                                                   where l2.HRM_TAXSOURCE_LEDGER_EXT_ID = l1.HRM_TAXSOURCE_LEDGER_ID) ) ) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'ELM_TAX_HIT_PAY_NUM');
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end loop;
  end DeletePayNumTaxSourceLedger;

  /**
  * procedure DeleteTaxSourceLedger
  * description :
  *    Effacement de la ligne de journalisation de l'impôt à la source
  *      (s'il s'agit d'une ligne d'extourne ou de correction, on efface aussi l'autre ligne liée)
  */
  procedure DeleteTaxSourceLedger(iTaxSourceLedgerID in HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type)
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
    lOriginLedgerID   HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
    lEmployeeID       HRM_PERSON.HRM_PERSON_ID%type;
  begin
    -- Recherche s'il y a un id de la ligne origine
    select max(HRM_TAXSOURCE_LEDGER_EXT_ID)
         , max(HRM_PERSON_ID)
      into lOriginLedgerID
         , lEmployeeID
      from HRM_TAXSOURCE_LEDGER
     where HRM_TAXSOURCE_LEDGER_ID = iTaxSourceLedgerID;

    -- Il y a un lien avec une ligne origine
    if lOriginLedgerID is not null then
      -- Effacer les 2 lignes qui ont le lien avec la ligne origine
      for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                    from HRM_TAXSOURCE_LEDGER
                                   where HRM_PERSON_ID = lEmployeeID
                                     and HRM_TAXSOURCE_LEDGER_EXT_ID = lOriginLedgerID) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltTaxSourceLedger);
        FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
      end loop;
    else
      -- Pas de lien avec une ligne origine
      -- Effacer uniquement la ligne dont l'id a été passé en param
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', iTaxSourceLedgerID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end if;
  end DeleteTaxSourceLedger;

  /**
  * procedure ReverseTaxSourceLedger
  * description :
  *    Extourne d'une ligne de journalisation de l'impôt à la source
  */
  procedure ReverseTaxSourceLedger(
    iTaxSourceLedgerID  in     HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  , oReverseLedgerID    out    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  , oCorrectionLedgerID out    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type
  )
  is
  begin
    p_ReverseTaxSourceLedger(iTaxSourceLedgerID,'04', oReverseLedgerID, oCorrectionLedgerID);
  end ReverseTaxSourceLedger;

  /**
  * procedure ReverseOutgoingEmployee
  * description :
  *    Extourne toutes les lignes du journal concernant l'employé pour la période de sortie.
  * @created rba 08.12.2014
  * @public
  * @param iEmployeeID : Employé
  */
  procedure ReverseOutgoingEmployee(iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type)
  is
    ltTaxSourceLedger  FWK_I_TYP_DEFINITION.t_crud_def;
    reverseLedgerID    HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
    correctionLedgerID HRM_TAXSOURCE_LEDGER.HRM_TAXSOURCE_LEDGER_ID%type;
  begin
    for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                  from hrm_taxsource_ledger ELMP
                                 where hrm_person_id = iEmployeeID
                                   and ELM_TAX_PER_END = (select max(EMT_TO)
                                                            from HRM_EMPLOYEE_TAXSOURCE
                                                           where HRM_PERSON_ID = iEmployeeID
                                                             and EMT_TO < hrm_date.ActivePeriod)
                                   and not exists(select 1
                                                    from hrm_taxsource_ledger ELMC
                                                   where ELMC.HRM_TAXSOURCE_LEDGER_EXT_ID = ELMP.HRM_TAXSOURCE_LEDGER_ID) ) loop
      ReverseTaxSourceLedger(ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID, reverseLedgerID, correctionLedgerID);
    end loop;
  end ReverseOutgoingEmployee;

  /**
  * procedure PrepareConfessionUpdate
  * description :
  *    Insertion dans une table temp la liste des employés à qui il manque
  *      la confession dans la journalisation de l'impôt à la source pour une période donnée
  */
  procedure PrepareConfessionUpdate(iEndPeriodDate in date)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'TAXSOURCE_LEDGER-CONFESSION';

    for ltplEmployee in (select   TSL.HRM_PERSON_ID
                             from HRM_TAXSOURCE_LEDGER TSL
                            where TSL.ELM_TAX_PER_END = iEndPeriodDate
                              and (   TSL.ELM_TAX_CODE like '%Y'
                                   or TSL.C_HRM_IS_CAT is not null)
                              and TSL.C_HRM_TAX_CONFESSION is null
                              and not exists(
                                    select 1
                                      from HRM_TAXSOURCE_LEDGER TSL2
                                     where TSL2.HRM_PERSON_ID = TSL.HRM_PERSON_ID
                                       and TSL2.ELM_TAX_PER_END <= iEndPeriodDate
                                       and TSL2.C_HRM_TAX_CONFESSION is not null)
                         group by TSL.HRM_PERSON_ID) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', ltplEmployee.HRM_PERSON_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'TAXSOURCE_LEDGER-CONFESSION');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_1', iEndPeriodDate);
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;
  end PrepareConfessionUpdate;

  /**
  * procedure UpdateConfessionListTmp
  * description :
  *    Mise à jour de la confession dans une ligne de la table temp
  */
  procedure UpdateConfessionListTmp(
    iComListIdTempID  in COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID%type
  , iHrmTaxConfession in HRM_TAXSOURCE_LEDGER.C_HRM_TAX_CONFESSION%type
  )
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iComListIdTempID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iHrmTaxConfession);
    FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end UpdateConfessionListTmp;

  /**
  * procedure UpdateConfession
  * description :
  *    Mise à jour de la confession dans la journalisation de l'impôt à la source pour une période donnée
  *      selon la préparation faite par la procédure PrepareConfessionUpdate
  */
  procedure UpdateConfession
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplTaxSourceLedger in (select LID.LID_FREE_CHAR_1 as C_HRM_TAX_CONFESSION
                                     , TSL.HRM_TAXSOURCE_LEDGER_ID
                                  from HRM_TAXSOURCE_LEDGER TSL
                                     , COM_LIST_ID_TEMP LID
                                 where LID.LID_CODE = 'TAXSOURCE_LEDGER-CONFESSION'
                                   and LID.COM_LIST_ID_TEMP_ID = TSL.HRM_PERSON_ID
                                   and LID.LID_FREE_DATE_1 = TSL.ELM_TAX_PER_END
                                   and (   TSL.ELM_TAX_CODE like '%Y'
                                        or TSL.C_HRM_IS_CAT is not null)
                                   and TSL.C_HRM_TAX_CONFESSION is null
                                   and LID.LID_FREE_CHAR_1 is not null) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'C_HRM_TAX_CONFESSION', ltplTaxSourceLedger.C_HRM_TAX_CONFESSION);
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end loop;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'TAXSOURCE_LEDGER-CONFESSION';
  end UpdateConfession;

  /**
  * procedure CleanElmReceipientConfId
  * description :
  *    Réinitialise (à NULL) les entrées de journalisation d'une transmission en erreur
  */
  procedure CleanElmReceipientConfId(iHrmELMRecipientConfID in HRM_TAXSOURCE_LEDGER.HRM_ELM_RECIPIENT_CONF_ID%type)
  is
    ltTaxSourceLedger FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplTaxSourceLedger in (select HRM_TAXSOURCE_LEDGER_ID
                                     , HRM_ELM_RECIPIENT_CONF_ID
                                  from HRM_TAXSOURCE_LEDGER
                                 where HRM_ELM_RECIPIENT_CONF_ID = iHrmELMRecipientConfID) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmTaxSourceLedger, ltTaxSourceLedger);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSourceLedger, 'HRM_TAXSOURCE_LEDGER_ID', ltplTaxSourceLedger.HRM_TAXSOURCE_LEDGER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltTaxSourceLedger, 'HRM_ELM_RECIPIENT_CONF_ID');
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSourceLedger);
      FWK_I_MGT_ENTITY.Release(ltTaxSourceLedger);
    end loop;
  end CleanElmReceipientConfId;
end HRM_PRC_TAXSOURCE_LEDGER;
