--------------------------------------------------------
--  DDL for Package Body HRM_PRC_CONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_CONTRACT" 
as
  /**
   *  Procédure InsertContract
   */
  procedure InsertContract(iHRM_IN_OUT_ID in HRM_IN_OUT.HRM_IN_OUT_ID%type, iHRM_EMPLOYEE_ID in HRM_IN_OUT.HRM_EMPLOYEE_ID%type)
  is
    lvINO_IN            HRM_IN_OUT.INO_IN%type;
    lvINO_OUT           HRM_IN_OUT.INO_OUT%type;
    lvEST_HOURS_WEEK    HRM_ESTABLISHMENT.EST_HOURS_WEEK%type;
    lvEST_LESSONS_WEEK  HRM_ESTABLISHMENT.EST_LESSONS_WEEK%type;
    lnCON_ACTIVITY_RATE HRM_CONTRACT.CON_ACTIVITY_RATE%type;
    ltcrud_def          FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Reporter les dates d'entrée-sortie sur le contrat
    select INO_IN
         , INO_OUT
      into lvINO_IN
         , lvINO_OUT
      from HRM_IN_OUT
     where HRM_IN_OUT_ID = iHRM_IN_OUT_ID;

    --Ajout d'un contrat
    FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmContract, ltcrud_def, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'HRM_IN_OUT_ID', iHRM_IN_OUT_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'HRM_EMPLOYEE_ID', iHRM_EMPLOYEE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'CON_BEGIN', lvINO_IN);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'CON_END', lvINO_OUT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'C_CONTRACT_STATUS', 'ACT');   -- Enregistrement est actif
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'C_CONTRACT_TYPE', '100');   -- CDI avec salaire annuel
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'A_DATECRE', sysdate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
    FWK_I_MGT_ENTITY.InsertEntity(ltcrud_def);
    -- Mise à jour des heures et périodes selon taux d'activité (attention à la valeur par défaut de PC_FLDSC utilisée pour le calcul => le faire après l'insert)
    lnCON_ACTIVITY_RATE  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltcrud_def, 'CON_ACTIVITY_RATE');
    HRM_LIB_ESTABLISHMENT.GetEstablishmentHours(iHRM_IN_OUT_ID, lvEST_HOURS_WEEK, lvEST_LESSONS_WEEK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'CON_WEEKLY_HOURS', lnCON_ACTIVITY_RATE * lvEST_HOURS_WEEK / 100);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'CON_WEEKLY_LESSONS', lnCON_ACTIVITY_RATE * lvEST_LESSONS_WEEK / 100);
    FWK_I_MGT_ENTITY.UpdateEntity(ltcrud_def);
    FWK_I_MGT_ENTITY.Release(ltcrud_def);
  end InsertContract;

  /**
   * Procédure UpdateContractEndDate
   */
  procedure UpdateContractEndDate(iHRM_IN_OUT_ID in HRM_IN_OUT.HRM_IN_OUT_ID%type, iRefDate HRM_CONTRACT.CON_END%type, iNewDate HRM_CONTRACT.CON_END%type)
  is
    ltcrud_def FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplContract in (select HRM_CONTRACT_ID
                             , CON_END
                             , C_CONTRACT_TYPE
                          from HRM_CONTRACT
                         where HRM_IN_OUT_ID = iHRM_IN_OUT_ID) loop
      -- Mettre à jour si la date de fin de l'entrée-sortie était synchrone avec celle de fin du contrat
      -- Un contrat '200', '210', '220' n'accepte pas de date de fin null
      if     (nvl(tplContract.CON_END, to_date('01011899', 'ddmmyyyy')) = nvl(iRefDate, to_date('01011899', 'ddmmyyyy')))
         and not(     (    (tplContract.C_CONTRACT_TYPE = '200')
                       or (tplContract.C_CONTRACT_TYPE = '210')
                       or (tplContract.C_CONTRACT_TYPE = '220') )
                 and (iNewDate is null) ) then
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmContract, ltcrud_def, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'HRM_CONTRACT_ID', tplContract.HRM_CONTRACT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltcrud_def, 'CON_END', iNewDate);
        FWK_I_MGT_ENTITY.UpdateEntity(ltcrud_def);
        FWK_I_MGT_ENTITY.Release(ltcrud_def);
      end if;
    end loop;
  end UpdateContractEndDate;
end HRM_PRC_CONTRACT;
