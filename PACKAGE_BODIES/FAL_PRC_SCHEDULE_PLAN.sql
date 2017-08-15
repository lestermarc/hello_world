--------------------------------------------------------
--  DDL for Package Body FAL_PRC_SCHEDULE_PLAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_SCHEDULE_PLAN" 
is
  /**
  * procedure p_initTaskData
  * Description
  *    Contrôle et initialisation des données manquantes avant insertion d'un lien opération standard
  *    sur gamme opératoire.
  * @author AGA
  * @created SEP.2011
  * @lastUpdate age 08.10.2012
  * @public
  * @param   iotListStepLink : voir définition type fwk_i_typ_definition.CRUD_DEF_T
  */
  procedure p_initTaskData(iotListStepLink in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lCSchedulePlanning FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type;
  begin
    select C_SCHEDULE_PLANNING
      into lCSchedulePlanning
      from FAL_SCHEDULE_PLAN
     where FAL_SCHEDULE_PLAN_ID = FWK_TYP_FAL_ENTITY.gttListStepLink(iotListStepLink.entity_id).FAL_SCHEDULE_PLAN_ID;

    for tplData in (select *
                      from FAL_TASK
                     where FAL_TASK_ID = FWK_TYP_FAL_ENTITY.gttListStepLink(iotListStepLink.entity_id).FAL_TASK_ID) loop
      /* Type d'opération (principale / secondaire / successeur / ...) */
      if FWK_I_MGT_ENTITY_DATA.isNull(iotListStepLink, 'C_OPERATION_TYPE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'C_OPERATION_TYPE', 1);
      end if;

      /* Type d'opération (interne / externe) */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'C_TASK_TYPE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'C_TASK_TYPE', tplData.C_TASK_TYPE);
      end if;

      /* Description courte */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_SHORT_DESCR') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_SHORT_DESCR', tplData.TAS_SHORT_DESCR);
      end if;

      /* Description longue */
      if     not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_LONG_DESCR')
         and upper(PCS.PC_CONFIG.GetConfig('FAL_INI_LONG_DESCR_FOR_TASK') ) = 'TRUE' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_LONG_DESCR', tplData.TAS_LONG_DESCR);
      end if;

      /* Description libre */
      if     not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_FREE_DESCR')
         and upper(PCS.PC_CONFIG.GetConfig('FAL_INI_FREE_DESCR_FOR_TASK') ) = 'TRUE' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_FREE_DESCR', tplData.TAS_FREE_DESCR);
      end if;

      /* Procédure d'éxécution */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_OPERATION_PROCEDURE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_OPERATION_PROCEDURE_ID', tplData.PPS_OPERATION_PROCEDURE_ID);
      end if;

      /* Procédure de controle */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_PPS_OPERATION_PROCEDURE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_PPS_OPERATION_PROCEDURE_ID', tplData.PPS_PPS_OPERATION_PROCEDURE_ID);
      end if;

      /* Outils */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS1_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS1_ID', tplData.PPS_TOOLS1_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS2_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS2_ID', tplData.PPS_TOOLS2_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS3_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS3_ID', tplData.PPS_TOOLS3_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS4_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS4_ID', tplData.PPS_TOOLS4_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS5_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS5_ID', tplData.PPS_TOOLS5_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS6_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS6_ID', tplData.PPS_TOOLS6_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS7_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS7_ID', tplData.PPS_TOOLS7_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS8_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS8_ID', tplData.PPS_TOOLS8_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS9_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS9_ID', tplData.PPS_TOOLS9_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS10_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS10_ID', tplData.PPS_TOOLS10_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS11_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS11_ID', tplData.PPS_TOOLS11_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS12_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS12_ID', tplData.PPS_TOOLS12_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS13_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS13_ID', tplData.PPS_TOOLS13_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS14_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS14_ID', tplData.PPS_TOOLS14_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PPS_TOOLS15_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PPS_TOOLS15_ID', tplData.PPS_TOOLS15_ID);
      end if;

      /* Qte Ref Montant */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_QTY_REF_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF_AMOUNT', 1);
      end if;

      /* Montant */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_AMOUNT', nvl(tplData.TAS_AMOUNT, 0) );
      end if;

      /* Diviseur Montant */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_DIVISOR_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_DIVISOR_AMOUNT', nvl(tplData.TAS_DIVISOR_AMOUNT, 1) );
      end if;

      /* Qte Ref Travail */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_QTY_REF_WORK') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF_WORK', 1);
      end if;

      /* Travail */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_WORK_TIME') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_TIME', 0);
      end if;

      /* Code Imputation */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'C_TASK_IMPUTATION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'C_TASK_IMPUTATION', nvl(tplData.C_TASK_IMPUTATION, 1) );
      end if;

      /* Qte Fixe Réglage Quel que soit le type d'opération finalement */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_QTY_FIX_ADJUSTING') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_FIX_ADJUSTING', 0);
      end if;

      /* Transfert Quel que soit le type d'opération finalement */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_TRANSFERT_TIME') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_TRANSFERT_TIME', 0);
      end if;

      /* Planification */
      if lCSchedulePlanning = '1' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PLAN_RATE', 0);
      elsif FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_PLAN_RATE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PLAN_RATE', nvl(tplData.TAS_PLAN_RATE, 1) );
      end if;

      /* Durée Proportionelle */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_PLAN_PROP') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PLAN_PROP', nvl(tplData.TAS_PLAN_PROP, 1) );
      end if;

      /* Reglage */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_ADJUSTING_TIME') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_TIME', 0);
      end if;

      /* Unité de fabrication */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_UNIT_OF_MEASURE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_UNIT_OF_MEASURE_ID', tplData.DIC_UNIT_OF_MEASURE_ID);
      end if;

      /* Facteur de conversion */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_CONVERSION_FACTOR') then
        if (nvl(tplData.TAS_CONVERSION_FACTOR, 0) <> 0) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_CONVERSION_FACTOR', tplData.TAS_CONVERSION_FACTOR);
        else
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_CONVERSION_FACTOR', 1);
        end if;
      end if;

      /* Codes libres */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE_ID', tplData.DIC_FREE_TASK_CODE_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE2_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE2_ID', tplData.DIC_FREE_TASK_CODE2_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE3_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE3_ID', tplData.DIC_FREE_TASK_CODE3_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE4_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE4_ID', tplData.DIC_FREE_TASK_CODE4_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE5_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE5_ID', tplData.DIC_FREE_TASK_CODE5_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE6_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE6_ID', tplData.DIC_FREE_TASK_CODE6_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE7_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE7_ID', tplData.DIC_FREE_TASK_CODE7_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE8_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE8_ID', tplData.DIC_FREE_TASK_CODE8_ID);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'DIC_FREE_TASK_CODE9_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'DIC_FREE_TASK_CODE9_ID', tplData.DIC_FREE_TASK_CODE9_ID);
      end if;

      /* Numériques libres */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_FREE_NUM1') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_FREE_NUM1', tplData.TAS_FREE_NUM1);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_FREE_NUM2') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_FREE_NUM2', tplData.TAS_FREE_NUM2);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_FREE_NUM3') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_FREE_NUM3', tplData.TAS_FREE_NUM3);
      end if;

      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_FREE_NUM4') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_FREE_NUM4', tplData.TAS_FREE_NUM4);
      end if;

      /* Flag pesée matière précieuse. Si valeur op. std nulle, on prend la valeur par défaut du lien op. std <--> gamme. */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WEIGH') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WEIGH', nvl(tplData.TAS_WEIGH, 1) );
      end if;

      /* Flag pesée obligatoire. Si valeur op. std nulle, on prend la valeur par défaut du lien op. std <--> gamme. */
      if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WEIGH_MANDATORY') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WEIGH_MANDATORY', nvl(tplData.TAS_WEIGH_MANDATORY, 0) );
      end if;

      /* Si opération interne */
      if tplData.C_TASK_TYPE = '1' then
        /* Atelier */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'FAL_FACTORY_FLOOR_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'FAL_FACTORY_FLOOR_ID', tplData.FAL_FACTORY_FLOOR_ID);
        end if;

        /* Opérateur */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'FAL_FAL_FACTORY_FLOOR_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'FAL_FAL_FACTORY_FLOOR_ID', tplData.FAL_FAL_FACTORY_FLOOR_ID);
        end if;

        /* Fournisseur */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PAC_SUPPLIER_PARTNER_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'PAC_SUPPLIER_PARTNER_ID');
        end if;

        /* Service */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'GCO_GCO_GOOD_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'GCO_GCO_GOOD_ID');
        end if;

        /* Si les taux sont nuls et sans valeur par défaut on leur donne une valeur */
        /* Tx. M.O. */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_ADJUSTING_RATE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_RATE', nvl(tplData.TAS_ADJUSTING_RATE, 2) );
        end if;

        /* Tx. Mach. */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WORK_RATE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_RATE', nvl(tplData.TAS_WORK_RATE, 1) );
        end if;

        /* Temps d'ouverture machine */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_OPEN_TIME_MACHINE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_OPEN_TIME_MACHINE', tplData.TAS_OPEN_TIME_MACHINE);
        end if;

        /* Transfert */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_TRANSFERT_TIME') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_TRANSFERT_TIME', tplData.TAS_TRANSFERT_TIME);
        end if;

        /* Détails de réalisation */
        /* Ressources affectées */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_NUM_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_FLOOR', nvl(tplData.TAS_NUM_FLOOR, 1) );
        end if;

        /* Coûts machine réglage (Boolean) */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_ADJUSTING_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_FLOOR', nvl(tplData.TAS_ADJUSTING_FLOOR, 1) );
        end if;

        /* Coûts main d'oeuvre réglage (Boolean) */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_ADJUSTING_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_OPERATOR', nvl(tplData.TAS_ADJUSTING_OPERATOR, 1) );
        end if;

        /* Nb opérateurs Réglage */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_NUM_ADJUST_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_ADJUST_OPERATOR', nvl(tplData.TAS_NUM_ADJUST_OPERATOR, 1) );
        end if;

        /* % opérateur Réglage */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_PERCENT_ADJUST_OPER') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PERCENT_ADJUST_OPER', nvl(tplData.TAS_PERCENT_ADJUST_OPER, 100) );
        end if;

        /* Coûts machine travail (Boolean) */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WORK_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_FLOOR', nvl(tplData.TAS_WORK_FLOOR, 1) );
        end if;

        /* Coûts main d'oeuvre travail (Boolean) */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WORK_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_OPERATOR', nvl(tplData.TAS_WORK_OPERATOR, 1) );
        end if;

        /* Nb opérateurs Travail */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_NUM_WORK_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_WORK_OPERATOR', nvl(tplData.TAS_NUM_WORK_OPERATOR, 1) );
        end if;

        /* % opérateur Travail */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_PERCENT_WORK_OPER') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PERCENT_WORK_OPER', nvl(tplData.TAS_PERCENT_WORK_OPER, 100) );
        end if;
      /* Opération externe */
      else
        /* Atelier */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'FAL_FACTORY_FLOOR_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'FAL_FACTORY_FLOOR_ID');
        end if;

        /* Opérateur */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'FAL_FAL_FACTORY_FLOOR_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'FAL_FAL_FACTORY_FLOOR_ID');
        end if;

        /* Fournisseur */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'PAC_SUPPLIER_PARTNER_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PAC_SUPPLIER_PARTNER_ID', tplData.PAC_SUPPLIER_PARTNER_ID);
        end if;

        /* Service */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'GCO_GCO_GOOD_ID') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'GCO_GCO_GOOD_ID', tplData.GCO_GCO_GOOD_ID);
        end if;

        /* si opération externe alors taux=vide */
        /* Tx. M.O. */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_ADJUSTING_RATE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'SCS_ADJUSTING_RATE');
        end if;

        /* Tx. Mach. */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_WORK_RATE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'SCS_WORK_RATE');
        end if;

        /* Temps d'ouverture machine */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_OPEN_TIME_MACHINE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'SCS_OPEN_TIME_MACHINE');
        end if;

        /* Temps de transfert */
        if not FWK_I_MGT_ENTITY_DATA.isModified(iotListStepLink, 'SCS_TRANSFERT_TIME') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'SCS_TRANSFERT_TIME');
        end if;

        /* Détails de réalisation */
        /* Ressources affectées */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_NUM_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_FLOOR', 1);
        end if;

        /* Coûts machine réglage (Boolean) */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_ADJUSTING_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_FLOOR', 1);
        end if;

        /* Coûts main d'oeuvre réglage (Boolean) */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_ADJUSTING_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_ADJUSTING_OPERATOR', 1);
        end if;

        /* Nb opérateurs Réglage */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_NUM_ADJUST_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_ADJUST_OPERATOR', 1);
        end if;

        /* % opérateur Réglage */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_PERCENT_ADJUST_OPER') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PERCENT_ADJUST_OPER', 100);
        end if;

        /* Coûts machine travail (Boolean) */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_WORK_FLOOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_FLOOR', 1);
        end if;

        /* Coûts main d'oeuvre travail (Boolean) */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_WORK_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_WORK_OPERATOR', 1);
        end if;

        /* Nb opérateurs Travail */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_NUM_WORK_OPERATOR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_NUM_WORK_OPERATOR', 1);
        end if;

        /* % opérateur Travail */
        if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'SCS_PERCENT_WORK_OPER') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PERCENT_WORK_OPER', 100);
        end if;
      end if;
    end loop;
  end p_initTaskData;

  /**
  * Description
  *    Création d'une gamme opératoire.
  */
  function createSchedulePlan(
    iC_SCHEDULE_PLANNING in FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type
  , iSCH_REF             in FAL_SCHEDULE_PLAN.SCH_REF%type
  , iSCH_SHORT_DESCR     in FAL_SCHEDULE_PLAN.SCH_SHORT_DESCR%type
  , iSCH_LONG_DESCR      in FAL_SCHEDULE_PLAN.SCH_LONG_DESCR%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalSchedulePlan, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_SCHEDULE_PLANNING', iC_SCHEDULE_PLANNING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_REF', iSCH_REF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_SHORT_DESCR', iSCH_SHORT_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_LONG_DESCR', iSCH_LONG_DESCR);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'FAL_SCHEDULE_PLAN_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end createSchedulePlan;

  /**
  * Description
  *    Création d'un enregistrement dans la table FAL_LIST_STEP_LINK (lien entre la gamme et une opération standard)
  */
  function createListStepLink(
    iFAL_SCHEDULE_PLAN_ID  in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , iFAL_TASK_ID           in FAL_TASK.FAL_TASK_ID%type
  , iC_TASK_TYPE           in FAL_LIST_STEP_LINK.C_TASK_TYPE%type
  , iSCS_ADJUSTING_TIME    in FAL_LIST_STEP_LINK.SCS_ADJUSTING_TIME%type
  , iSCS_QTY_FIX_ADJUSTING in FAL_LIST_STEP_LINK.SCS_QTY_FIX_ADJUSTING%type
  , iSCS_WORK_TIME         in FAL_LIST_STEP_LINK.SCS_WORK_TIME%type
  , iSCS_QTY_REF_WORK      in FAL_LIST_STEP_LINK.SCS_QTY_REF_WORK%type
  , iSCS_AMOUNT            in FAL_LIST_STEP_LINK.SCS_AMOUNT%type
  , iSCS_QTY_REF_AMOUNT    in FAL_LIST_STEP_LINK.SCS_QTY_REF_AMOUNT%type
  , iSCS_DIVISOR_AMOUNT    in FAL_LIST_STEP_LINK.SCS_DIVISOR_AMOUNT%type
  )
    return FAL_LIST_STEP_LINK.FAL_LIST_STEP_LINK_ID%type
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    FAL_LIST_STEP_LINK.FAL_LIST_STEP_LINK_ID%type;
  begin
    -- création d'une opération
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalListStepLink, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_SCHEDULE_PLAN_ID', iFAL_SCHEDULE_PLAN_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_TASK_ID', iFAL_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_TASK_TYPE', iC_TASK_TYPE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_ADJUSTING_TIME', iSCS_ADJUSTING_TIME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_QTY_FIX_ADJUSTING', iSCS_QTY_FIX_ADJUSTING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_WORK_TIME', iSCS_WORK_TIME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_QTY_REF_WORK', iSCS_QTY_REF_WORK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_AMOUNT', iSCS_AMOUNT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_QTY_REF_AMOUNT', iSCS_QTY_REF_AMOUNT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_DIVISOR_AMOUNT', iSCS_DIVISOR_AMOUNT);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'FAL_LIST_STEP_LINK_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end createListStepLink;

  /**
  * Description
  *    Contrôle avant mise à jour de l'entête de gamme
  */
  procedure checkSchedulePlanData(iotSchedulePlan in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplSchedulePlan FWK_TYP_FAL_ENTITY.tSchedulePlan := FWK_TYP_FAL_ENTITY.gttSchedulePlan(iotSchedulePlan.entity_id);
    lMessage         varchar2(200);

    procedure internalSetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || co.cLineBreak || iMess;
      end if;
    end internalSetMessage;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotSchedulePlan, 'FAL_SCHEDULE_PLAN_ID') then
      lMessage  := 'FAL_SCHEDULE_PLAN_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckSchedulePlanData'
                                         );
    end if;

    -- initialisation valeurs par défaut
    if ltplSchedulePlan.C_SCHEDULE_PLANNING is null then
      ltplSchedulePlan.C_SCHEDULE_PLANNING  := PCS.PC_CONFIG.GetConfig('FAL_SCHEDULE_PLANNING');
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotSchedulePlan, 'C_SCHEDULE_PLANNING', ltplSchedulePlan.C_SCHEDULE_PLANNING);
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckSchedulePlanData'
                                         );
    end if;
  end CheckSchedulePlanData;

  /**
  * Description
  *    Contrôle avant mise à jour du lien avec opération
  */
  procedure checkListStepLinkData(iotListStepLink in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplListStepLink FWK_TYP_FAL_ENTITY.tListStepLink := FWK_TYP_FAL_ENTITY.gttListStepLink(iotListStepLink.entity_id);
    lMessage         varchar2(200);
    lSCS_STEP_NUMBER number;
    lFloorId         number;
    lSupplierId      number;
    lPrevious        number;
    lScsQtyRefWork   number;
    lTaskNumbering   number;

    procedure internalSetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || co.cLineBreak || iMess;
      end if;
    end internalSetMessage;
  begin
    /* L'ID de la gamme opératoire est obligatoire */
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotListStepLink, 'FAL_SCHEDULE_PLAN_ID') then
      lMessage  := 'FAL_SCHEDULE_PLAN_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckListStepLinkData'
                                         );
    end if;

    select nvl(max(SCS_STEP_NUMBER), 0)
      into lSCS_STEP_NUMBER
      from FAL_LIST_STEP_LINK
     where FAL_SCHEDULE_PLAN_ID = ltplListStepLink.FAL_SCHEDULE_PLAN_ID;

    lTaskNumbering  := PCS.PC_CONFIG.GetConfig('PPS_Task_Numbering');

    -- initialisation des valeurs par défaut
    if ltplListStepLink.FAL_SCHEDULE_STEP_ID is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'FAL_SCHEDULE_STEP_ID', ltplListStepLink.FAL_LIST_STEP_LINK_ID);
    end if;

    if ltplListStepLink.SCS_STEP_NUMBER is null then
      if lSCS_STEP_NUMBER = 0 then
        ltplListStepLink.C_RELATION_TYPE  := '1';   -- 1ère op
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'C_RELATION_TYPE', ltplListStepLink.C_RELATION_TYPE);
        lSCS_STEP_NUMBER                  := lTaskNumbering;
      else
        lSCS_STEP_NUMBER  := trunc(lSCS_STEP_NUMBER / lTaskNumbering) * lTaskNumbering + lTaskNumbering;
      end if;

      ltplListStepLink.SCS_STEP_NUMBER  := lSCS_STEP_NUMBER;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_STEP_NUMBER', ltplListStepLink.SCS_STEP_NUMBER);
    end if;

    if ltplListStepLink.SCS_PLAN_PROP is null then
      ltplListStepLink.SCS_PLAN_PROP  := 1;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_PLAN_PROP', ltplListStepLink.SCS_PLAN_PROP);
    end if;

    -- traitement des mises à jour
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'FAL_TASK_ID') then
      P_initTaskData(iotListStepLink);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'C_OPERATION_TYPE') then
      if ltplListStepLink.C_OPERATION_TYPE = '4' then
        internalSetMessage('C_OPERATION_TYPE : Value not allowed');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'C_RELATION_TYPE') then
      if     ltplListStepLink.C_RELATION_TYPE <> '1'
         and lSCS_STEP_NUMBER = lTaskNumbering then
        internalSetMessage('Error with C_RELATION_TYPE value mus be ''1'' for the first operation');
      end if;

      if ltplListStepLink.C_RELATION_TYPE not in('2', '4', '5') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotListStepLink, 'SCS_DELAY');
      end if;

      if ltplListStepLink.C_RELATION_TYPE = '3' then
        select FAL_FACTORY_FLOOR_ID
             , PAC_SUPPLIER_PARTNER_ID
          into lFloorId
             , lSupplierId
          from FAL_LIST_STEP_LINK
         where FAL_SCHEDULE_PLAN_ID = ltplListStepLink.FAL_SCHEDULE_PLAN_ID
           and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                    from FAL_LIST_STEP_LINK
                                   where SCS_STEP_NUMBER < ltplListStepLink.SCS_STEP_NUMBER
                                     and FAL_SCHEDULE_PLAN_ID = ltplListStepLink.FAL_SCHEDULE_PLAN_ID);

        if ltplListStepLink.C_TASK_TYPE = '1' then
          lPrevious  := lFloorId;
        else
          lPrevious  := lSupplierId;
        end if;

        if lPrevious = 0 then
          internalSetMessage('Error with C_RELATION_TYPE value : ''3''');
        else
          if ltplListStepLink.C_TASK_TYPE = '1' then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'FAL_FACTORY_FLOOR_ID', lFloorId);
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'PAC_SUPPLIER_PARTNER_ID', lSupplierId);
          end if;
        end if;
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_DELAY') then
      if ltplListStepLink.SCS_DELAY < 0 then
        internalSetMessage('SCS_DELAY value not allowed');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_QTY_REF_WORK') then
      if ltplListStepLink.SCS_QTY_REF_WORK = 0 then
        internalSetMessage('SCS_QTY_REF_WORK value not allowed : 0');
      else
        if ltplListStepLink.SCS_CONVERSION_FACTOR <> 0 then
          ltplListStepLink.SCS_QTY_REF2_WORK  := ltplListStepLink.SCS_QTY_REF_WORK * ltplListStepLink.SCS_CONVERSION_FACTOR;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF2_WORK', ltplListStepLink.SCS_QTY_REF2_WORK);
        end if;
      end if;
    elsif FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_CONVERSION_FACTOR') then
      if ltplListStepLink.SCS_CONVERSION_FACTOR = 0 then
        internalSetMessage('SCS_CONVERSION_FACTOR value not allowed : 0');
      else
        ltplListStepLink.SCS_QTY_REF2_WORK  := ltplListStepLink.SCS_QTY_REF_WORK * ltplListStepLink.SCS_CONVERSION_FACTOR;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF2_WORK', ltplListStepLink.SCS_QTY_REF2_WORK);
      end if;
    elsif FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_QTY_REF2_WORK') then
      if ltplListStepLink.SCS_QTY_REF2_WORK = 0 then
        internalSetMessage('SCS_QTY_REF2_WORK value not allowed : 0');
      else
        if ltplListStepLink.SCS_CONVERSION_FACTOR = 0 then
          ltplListStepLink.SCS_QTY_REF_WORK  := trunc(ltplListStepLink.SCS_QTY_REF2_WORK);
        else
          ltplListStepLink.SCS_QTY_REF_WORK  := trunc(ltplListStepLink.SCS_QTY_REF2_WORK / ltplListStepLink.SCS_CONVERSION_FACTOR);
        end if;

        if ltplListStepLink.SCS_QTY_REF_WORK = 0 then
          ltplListStepLink.SCS_QTY_REF_WORK  := 1;
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF_WORK', ltplListStepLink.SCS_QTY_REF_WORK);
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_QTY_REF_AMOUNT') then
      if     (ltplListStepLink.SCS_QTY_REF_AMOUNT = 0)
         and ltplListStepLink.SCS_DIVISOR_AMOUNT = 1 then
        internalSetMessage('SCS_QTY_REF_AMOUNT value not allowed : 0 (SCS_DIVISOR_AMOUNT = 1)');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotListStepLink, 'SCS_DIVISOR_AMOUNT') then
      if     (ltplListStepLink.SCS_QTY_REF_AMOUNT = 0)
         and ltplListStepLink.SCS_DIVISOR_AMOUNT = 1 then
        ltplListStepLink.SCS_QTY_REF_AMOUNT  := 1;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotListStepLink, 'SCS_QTY_REF_AMOUNT', ltplListStepLink.SCS_QTY_REF_AMOUNT);
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckListStepLinkData'
                                         );
    end if;
  end checkListStepLinkData;

  /**
  * Description
  *    Copie d'une gamme opératoire
  */
  procedure duplicateSchedulePlan(
    iSrcSchedulePlanID in     FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , iNewRef            in     FAL_SCHEDULE_PLAN.SCH_REF%type default null
  , oNewSchedulePlanID out    FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  )
  as
    ltCRUD_SchedulePlan FWK_I_TYP_DEFINITION.t_crud_def;
    lNewRef             FAL_SCHEDULE_PLAN.SCH_REF%type;
  begin
    oNewSchedulePlanID  := getNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_FAL_ENTITY.gcFalSchedulePlan
                       , iot_crud_definition   => ltCRUD_SchedulePlan
                       , iv_primary_col        => 'FAL_SCHEDULE_PLAN_ID'
                       , ib_initialize         => false
                        );
    /* Copie la nouvelle gamme opératoire */
    FWK_I_MGT_ENTITY.prepareDuplicate(iot_crud_definition => ltCRUD_SchedulePlan, ib_initialize => true, in_main_id => iSrcSchedulePlanID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_SchedulePlan, 'FAL_SCHEDULE_PLAN_ID', oNewSchedulePlanID);
    /* Si la référence est nulle, on ajouter un numéroteur ((1), (2), etc.. derrière l'ancienne référence) */
    lNewRef             := iNewRef;

    if lNewRef is null then
      lNewRef  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_SchedulePlan, 'SCH_REF');
      lNewRef  := FWK_I_LIB_ENTITY.getDuplicateValPk2(iv_entity_name   => FWK_TYP_FAL_ENTITY.gcFalSchedulePlan, iv_column_name => 'SCH_REF'
                                                    , iv_value         => lNewRef);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_SchedulePlan, 'SCH_REF', lNewRef);
    /* Il ne doit exister qu'une seule opération standard pour la sous-traitance achat */
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_SchedulePlan, 'SCH_GENERIC_SUBCONTRACT', 0);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_SchedulePlan);
    FWK_I_MGT_ENTITY.Release(ltCRUD_SchedulePlan);
    /* Copie des liens d'opérations de la gamme opératoire. */
    DupOperationOfGammeOnGamme(iSrcSchedulePlanID => iSrcSchedulePlanID, iNewSchedulePlanID => oNewSchedulePlanID);
  end duplicateSchedulePlan;

  /**
  * Description
  *    Copie les sur les opérations d'une gamme vers une autre.
  */
  procedure dupOperationOfGammeOnGamme(
    iSrcSchedulePlanID in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  , iNewSchedulePlanID in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  )
  is
    cursor crFal_List_Step_Link(iSrcSchedulePlanID number)
    is
      select   *
          from FAL_LIST_STEP_LINK
         where FAL_SCHEDULE_PLAN_ID = iSrcSchedulePlanID
      order by SCS_STEP_NUMBER;

    lNewScheduleStepID FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    for tplFal_List_Step_Link in crFal_List_Step_Link(iSrcSchedulePlanID) loop
      -- recréer l'opération lu de la gamme d'origine vers la gamme finale
      -- Obtenir un nouvel ID pour l'opération
      lNewScheduleStepID  := GetNewID;

      insert into FAL_LIST_STEP_LINK
                  (FAL_SCHEDULE_STEP_ID
                 , FAL_SCHEDULE_PLAN_ID
                 , C_TASK_TYPE
                 , SCS_STEP_NUMBER
                 , SCS_WORK_TIME
                 , SCS_QTY_REF_WORK
                 , SCS_WORK_RATE
                 , SCS_AMOUNT
                 , SCS_QTY_REF_AMOUNT
                 , SCS_DIVISOR_AMOUNT
                 , SCS_PLAN_RATE
                 , SCS_SHORT_DESCR
                 , SCS_LONG_DESCR
                 , SCS_FREE_DESCR
                 , PAC_SUPPLIER_PARTNER_ID
                 , PPS_OPERATION_PROCEDURE_ID
                 , PPS_PPS_OPERATION_PROCEDURE_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FAL_TASK_ID
                 , PPS_TOOLS1_ID
                 , PPS_TOOLS2_ID
                 , GCO_GCO_GOOD_ID
                 , C_OPERATION_TYPE
                 , SCS_ADJUSTING_TIME
                 , DIC_FREE_TASK_CODE2_ID
                 , DIC_FREE_TASK_CODE_ID
                 , SCS_PLAN_PROP
                 , C_TASK_IMPUTATION
                 , SCS_TRANSFERT_TIME
                 , SCS_QTY_FIX_ADJUSTING
                 , SCS_ADJUSTING_RATE
                 , C_RELATION_TYPE
                 , SCS_DELAY
                 , FAL_FAL_FACTORY_FLOOR_ID
                 , PPS_TOOLS3_ID
                 , PPS_TOOLS4_ID
                 , PPS_TOOLS5_ID
                 , PPS_TOOLS6_ID
                 , PPS_TOOLS7_ID
                 , PPS_TOOLS8_ID
                 , PPS_TOOLS9_ID
                 , PPS_TOOLS10_ID
                 , PPS_TOOLS11_ID
                 , PPS_TOOLS12_ID
                 , PPS_TOOLS13_ID
                 , PPS_TOOLS14_ID
                 , PPS_TOOLS15_ID
                 , DIC_FREE_TASK_CODE3_ID
                 , DIC_FREE_TASK_CODE4_ID
                 , DIC_FREE_TASK_CODE5_ID
                 , DIC_FREE_TASK_CODE6_ID
                 , DIC_FREE_TASK_CODE7_ID
                 , DIC_FREE_TASK_CODE8_ID
                 , DIC_FREE_TASK_CODE9_ID
                 , SCS_NUM_FLOOR
                 , SCS_ADJUSTING_FLOOR
                 , SCS_ADJUSTING_OPERATOR
                 , SCS_NUM_ADJUST_OPERATOR
                 , SCS_PERCENT_ADJUST_OPER
                 , SCS_WORK_FLOOR
                 , SCS_WORK_OPERATOR
                 , SCS_NUM_WORK_OPERATOR
                 , SCS_PERCENT_WORK_OPER
                 , DIC_UNIT_OF_MEASURE_ID
                 , SCS_CONVERSION_FACTOR
                 , SCS_QTY_REF2_WORK
                 , SCS_FREE_NUM1
                 , SCS_FREE_NUM2
                 , SCS_FREE_NUM3
                 , SCS_FREE_NUM4
                 , SCS_WEIGH
                 , SCS_WEIGH_MANDATORY
                 , SCS_OPEN_TIME_MACHINE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (lNewScheduleStepID   -- Nouvel Id d'opération
                 , iNewSchedulePlanID   -- Id de la gamme de destination
                 , tplFal_List_Step_Link.C_TASK_TYPE
                 , tplFal_List_Step_Link.SCS_STEP_NUMBER
                 , tplFal_List_Step_Link.SCS_WORK_TIME
                 , tplFal_List_Step_Link.SCS_QTY_REF_WORK
                 , tplFal_List_Step_Link.SCS_WORK_RATE
                 , tplFal_List_Step_Link.SCS_AMOUNT
                 , tplFal_List_Step_Link.SCS_QTY_REF_AMOUNT
                 , tplFal_List_Step_Link.SCS_DIVISOR_AMOUNT
                 , tplFal_List_Step_Link.SCS_PLAN_RATE
                 , tplFal_List_Step_Link.SCS_SHORT_DESCR
                 , tplFal_List_Step_Link.SCS_LONG_DESCR
                 , tplFal_List_Step_Link.SCS_FREE_DESCR
                 , tplFal_List_Step_Link.PAC_SUPPLIER_PARTNER_ID
                 , tplFal_List_Step_Link.PPS_OPERATION_PROCEDURE_ID
                 , tplFal_List_Step_Link.PPS_PPS_OPERATION_PROCEDURE_ID
                 , tplFal_List_Step_Link.FAL_FACTORY_FLOOR_ID
                 , tplFal_List_Step_Link.FAL_TASK_ID
                 , tplFal_List_Step_Link.PPS_TOOLS1_ID
                 , tplFal_List_Step_Link.PPS_TOOLS2_ID
                 , tplFal_List_Step_Link.GCO_GCO_GOOD_ID
                 , tplFal_List_Step_Link.C_OPERATION_TYPE
                 , tplFal_List_Step_Link.SCS_ADJUSTING_TIME
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE2_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE_ID
                 , tplFal_List_Step_Link.SCS_PLAN_PROP
                 , tplFal_List_Step_Link.C_TASK_IMPUTATION
                 , tplFal_List_Step_Link.SCS_TRANSFERT_TIME
                 , tplFal_List_Step_Link.SCS_QTY_FIX_ADJUSTING
                 , tplFal_List_Step_Link.SCS_ADJUSTING_RATE
                 , tplFal_List_Step_Link.C_RELATION_TYPE
                 , tplFal_List_Step_Link.SCS_DELAY
                 , tplFal_List_Step_Link.FAL_FAL_FACTORY_FLOOR_ID
                 , tplFal_List_Step_Link.PPS_TOOLS3_ID
                 , tplFal_List_Step_Link.PPS_TOOLS4_ID
                 , tplFal_List_Step_Link.PPS_TOOLS5_ID
                 , tplFal_List_Step_Link.PPS_TOOLS6_ID
                 , tplFal_List_Step_Link.PPS_TOOLS7_ID
                 , tplFal_List_Step_Link.PPS_TOOLS8_ID
                 , tplFal_List_Step_Link.PPS_TOOLS9_ID
                 , tplFal_List_Step_Link.PPS_TOOLS10_ID
                 , tplFal_List_Step_Link.PPS_TOOLS11_ID
                 , tplFal_List_Step_Link.PPS_TOOLS12_ID
                 , tplFal_List_Step_Link.PPS_TOOLS13_ID
                 , tplFal_List_Step_Link.PPS_TOOLS14_ID
                 , tplFal_List_Step_Link.PPS_TOOLS15_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE3_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE4_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE5_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE6_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE7_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE8_ID
                 , tplFal_List_Step_Link.DIC_FREE_TASK_CODE9_ID
                 , tplFal_List_Step_Link.SCS_NUM_FLOOR
                 , tplFal_List_Step_Link.SCS_ADJUSTING_FLOOR
                 , tplFal_List_Step_Link.SCS_ADJUSTING_OPERATOR
                 , tplFal_List_Step_Link.SCS_NUM_ADJUST_OPERATOR
                 , tplFal_List_Step_Link.SCS_PERCENT_ADJUST_OPER
                 , tplFal_List_Step_Link.SCS_WORK_FLOOR
                 , tplFal_List_Step_Link.SCS_WORK_OPERATOR
                 , tplFal_List_Step_Link.SCS_NUM_WORK_OPERATOR
                 , tplFal_List_Step_Link.SCS_PERCENT_WORK_OPER
                 , tplFal_List_Step_Link.DIC_UNIT_OF_MEASURE_ID
                 , tplFal_List_Step_Link.SCS_CONVERSION_FACTOR
                 , tplFal_List_Step_Link.SCS_QTY_REF2_WORK
                 , tplFal_List_Step_Link.SCS_FREE_NUM1
                 , tplFal_List_Step_Link.SCS_FREE_NUM2
                 , tplFal_List_Step_Link.SCS_FREE_NUM3
                 , tplFal_List_Step_Link.SCS_FREE_NUM4
                 , tplFal_List_Step_Link.SCS_WEIGH
                 , tplFal_List_Step_Link.SCS_WEIGH_MANDATORY
                 , tplFal_List_Step_Link.SCS_OPEN_TIME_MACHINE
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      -- Duplication des Listes de Machines Utilisables
      FAL_TASK_LIST.DUPLICATE_LMU_ON_DUPL_GAMME(tplFal_List_Step_Link.FAL_SCHEDULE_STEP_ID, lNewScheduleStepID);
    end loop;

    -- Lors de cette opération on considère bien entendu qu'il n'y pas de notion d'historique de modification
    -- pour les opérations de la gamme destination. On supprime donc les enregistrements de la table
    -- FAl_SCHEDULE_PLAN_HISTO pour la gamme de destination.
    delete from FAL_SCHEDULE_PLAN_HISTO
          where FAL_SCHEDULE_PLAN_ID = iNewSchedulePlanID;
  end DupOperationOfGammeOnGamme;
end FAL_PRC_SCHEDULE_PLAN;
