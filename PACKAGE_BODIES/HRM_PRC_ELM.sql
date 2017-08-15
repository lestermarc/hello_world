--------------------------------------------------------
--  DDL for Package Body HRM_PRC_ELM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_ELM" 
as
  /**
  * procedure AddTransmissionRecipients
  * description :
  *    Ajout des destinataires pour une déclaration électronique
  */
  procedure AddTransmissionRecipients(
    iElmTransmissionID   in HRM_ELM_TRANSMISSION.HRM_ELM_TRANSMISSION_ID%type
  , iElmTransmissionType in HRM_ELM_TRANSMISSION.C_ELM_TRANSMISSION_TYPE%type
  )
  is
    ltReciptient FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Transmission de type 1 : Complète
    if iElmTransmissionType = '1' then
      for ltplRecipient in (select   INS.HRM_INSURANCE_ID
                                   , min(COL.HRM_CONTROL_LIST_ID) as HRM_CONTROL_LIST_ID
                                from HRM_INSURANCE INS
                                   , HRM_CONTROL_LIST COL
                               where COL.C_CONTROL_LIST_TYPE in('102', '103', '112', '113', '114', '116')
                                 and INS.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                                 and INS.INS_SWISSDEC_MEMBER = 1
                            group by INS.HRM_INSURANCE_ID
                            union all
                            select   null
                                   , min(HRM_CONTROL_LIST_ID) as HRM_CONTROL_LIST_ID
                                from HRM_CONTROL_LIST
                               where C_CONTROL_LIST_TYPE in('011', '110')
                            group by C_CONTROL_LIST_TYPE) loop
        -- Init des données du tuple HRM_ELM_RECIPIENT
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmElmRecipient, ltReciptient, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_ELM_TRANSMISSION_ID', iElmTransmissionID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'ELM_SELECTED', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_INSURANCE_ID', ltplRecipient.HRM_INSURANCE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_CONTROL_LIST_ID', ltplRecipient.HRM_CONTROL_LIST_ID);
        FWK_I_MGT_ENTITY.InsertEntity(ltReciptient);
        FWK_I_MGT_ENTITY.Release(ltReciptient);
      end loop;
    -- Transmission de type 2 : Mutations AVS/LPP
    elsif iElmTransmissionType = '2' then
      for ltplRecipient in (select   INS.HRM_INSURANCE_ID
                                   , min(COL.HRM_CONTROL_LIST_ID) as HRM_CONTROL_LIST_ID
                                from HRM_INSURANCE INS
                                   , HRM_CONTROL_LIST COL
                               where COL.C_CONTROL_LIST_TYPE in('102', '116')
                                 and INS.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                                 and INS.INS_SWISSDEC_MEMBER = 1
                            group by INS.HRM_INSURANCE_ID) loop
        -- Init des données du tuple HRM_ELM_RECIPIENT
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmElmRecipient, ltReciptient, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_ELM_TRANSMISSION_ID', iElmTransmissionID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'ELM_SELECTED', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_INSURANCE_ID', ltplRecipient.HRM_INSURANCE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_CONTROL_LIST_ID', ltplRecipient.HRM_CONTROL_LIST_ID);
        FWK_I_MGT_ENTITY.InsertEntity(ltReciptient);
        FWK_I_MGT_ENTITY.Release(ltReciptient);
      end loop;
    -- Transmission de type 3 : Synchronisation LPP
    elsif iElmTransmissionType = '3' then
      for ltplRecipient in (select   INS.HRM_INSURANCE_ID
                                   , min(COL.HRM_CONTROL_LIST_ID) as HRM_CONTROL_LIST_ID
                                from HRM_INSURANCE INS
                                   , HRM_CONTROL_LIST COL
                               where COL.C_CONTROL_LIST_TYPE = '116'
                                 and INS.HRM_CONTROL_LIST_ID = COL.HRM_CONTROL_LIST_ID
                                 and INS.INS_SWISSDEC_MEMBER = 1
                            group by INS.HRM_INSURANCE_ID) loop
        -- Init des données du tuple HRM_ELM_RECIPIENT
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmElmRecipient, ltReciptient, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_ELM_TRANSMISSION_ID', iElmTransmissionID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'ELM_SELECTED', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_INSURANCE_ID', ltplRecipient.HRM_INSURANCE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_CONTROL_LIST_ID', ltplRecipient.HRM_CONTROL_LIST_ID);
        FWK_I_MGT_ENTITY.InsertEntity(ltReciptient);
        FWK_I_MGT_ENTITY.Release(ltReciptient);
      end loop;
    -- Transmission de type 4 : Déclaration mensuelle des impôts à la source
    elsif iElmTransmissionType = '4' then
      for ltplRecipient in (select (select min(HRM_CONTROL_LIST_ID)
                                      from HRM_CONTROL_LIST
                                     where C_CONTROL_LIST_TYPE = '111') as HRM_CONTROL_LIST_ID
                                 , TAX.HRM_TAXSOURCE_DEFINITION_ID
                              from HRM_TAXSOURCE_DEFINITION TAX
                             where exists(
                                          select 1
                                            from HRM_TAXSOURCE_LEDGER TXL
                                           where TAX.C_HRM_CANTON = TXL.C_HRM_CANTON
                                             and trunc(TXL.ELM_TAX_PER_END, 'YEAR') = trunc(HRM_ELM.BeginOfPeriod, 'YEAR') )
                                or exists(
                                     select 1
                                       from HRM_EMPLOYEE_TAXSOURCE EMT
                                      where EMT.EMT_CANTON = TAX.C_HRM_CANTON
                                        and trunc(HRM_ELM.BeginOfPeriod, 'YEAR') between trunc(EMT.EMT_FROM, 'YEAR') and nvl(EMT.EMT_TO, HRM_ELM.BeginOfPeriod) ) ) loop
        -- Init des données du tuple HRM_ELM_RECIPIENT
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmElmRecipient, ltReciptient, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_ELM_TRANSMISSION_ID', iElmTransmissionID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'ELM_SELECTED', 1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'ELM_PIV', 1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_CONTROL_LIST_ID', ltplRecipient.HRM_CONTROL_LIST_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltReciptient, 'HRM_TAXSOURCE_DEFINITION_ID', ltplRecipient.HRM_TAXSOURCE_DEFINITION_ID);
        FWK_I_MGT_ENTITY.InsertEntity(ltReciptient);
        FWK_I_MGT_ENTITY.Release(ltReciptient);
      end loop;
    end if;
  end AddTransmissionRecipients;
end HRM_PRC_ELM;
