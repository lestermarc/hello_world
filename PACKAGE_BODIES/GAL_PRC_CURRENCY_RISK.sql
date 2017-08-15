--------------------------------------------------------
--  DDL for Package Body GAL_PRC_CURRENCY_RISK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PRC_CURRENCY_RISK" 
is
  /**
  * Description
  *    Mise à jour du solde d'une tranche virtuelle
  */
  procedure UpdateVirtualBalance(
    iGalCurrencyRiskVirtualId in GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type
  , iDocDocumentID            in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , iActDocumentID            in ACT_DOCUMENT.ACT_DOCUMENT_ID%type default null
  , iDocAmount1               in GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type default null
  , iDocAmount2               in GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type default null
  , iDeltaAmount              in GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type
  )
  is
    ltComp               FWK_I_TYP_DEFINITION.t_crud_def;
    lOldBalance          GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type
                                                := FWK_I_LIB_ENTITY.getNumberFieldFromPk('GAL_CURRENCY_RISK_VIRTUAL', 'GCV_BALANCE', iGalCurrencyRiskVirtualId);
    lNewBalance          GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type;
    lHistoId             GAL_CURRENCY_RISK_V_HISTO.GAL_CURRENCY_RISK_V_HISTO_ID%type;
    ltCRUD_Virtual_Histo FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lNewBalance  := lOldBalance - iDeltaAmount;
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_GAL_ENTITY.gcGalCurrencyRiskVirtual, iot_crud_definition => ltComp
                       , in_main_id            => iGalCurrencyRiskVirtualId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'GCV_BALANCE', lNewBalance);
    FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
    FWK_I_MGT_ENTITY.Release(ltComp);

    for tplVirtual in (select GAL_CURRENCY_RISK_VIRTUAL_ID
                            , GAL_PROJECT_ID
                            , ACS_FINANCIAL_CURRENCY_ID
                         from GAL_CURRENCY_RISK_VIRTUAL
                        where GAL_CURRENCY_RISK_VIRTUAL_ID = iGalCurrencyRiskVirtualId) loop
      if iActDocumentID is not null then
        begin
          -- recherche de l'extourne relative au document comptable
          select   GAL_CURRENCY_RISK_V_HISTO_ID
              into lHistoId
              from GAL_CURRENCY_RISK_V_HISTO
             where ACT_DOCUMENT_ID = iActDocumentID
               and GVH_BALANCE2 is null
               and rownum = 1
          order by GAL_CURRENCY_RISK_V_HISTO_ID desc;
        exception
          when no_data_found then
            lHistoId  := null;
        end;
      else
        lHistoId  := null;
      end if;

      -- Création historique couverture virtuelle
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVHisto, ltCRUD_Virtual_Histo, true);

      if lHistoId is not null then
        FWK_I_MGT_ENTITY.load(ltCRUD_Virtual_Histo, lHistoId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_BALANCE2', lNewBalance);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_DOC_AMOUNT2', iDocAmount2);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_Virtual_Histo);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_PROJECT_ID', tplVirtual.GAL_PROJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_CURRENCY_RISK_VIRTUAL_ID', iGalCurrencyRiskVirtualId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'ACS_FINANCIAL_CURRENCY_ID', tplVirtual.ACS_FINANCIAL_CURRENCY_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'DOC_DOCUMENT_ID', iDocDocumentID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'ACT_DOCUMENT_ID', iActDocumentID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_BALANCE1', lOldBalance);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_DOC_AMOUNT1', iDocAmount1);

        if iDocAmount2 is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_BALANCE2', lNewBalance);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_DOC_AMOUNT2', iDocAmount2);
        end if;

        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Virtual_Histo);
      end if;

      FWK_I_MGT_ENTITY.Release(ltCRUD_Virtual_Histo);
    end loop;
  end UpdateVirtualBalance;

  /**
  * procedure DeleteProjectCurrRisk
  * Description
  *    Effacement des couvertures d'une affaire
  */
  procedure DeleteProjectCurrRisk(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
  begin
    delete from GAL_CURRENCY_RISK_HISTO
          where GAL_PROJECT_ID = iProjectID;

    delete from GAL_CURRENCY_RISK_V_HISTO
          where GAL_PROJECT_ID = iProjectID;

    delete from GAL_CURRENCY_RISK
          where GAL_PROJECT_ID = iProjectID;

    delete from GAL_CURRENCY_RISK_VIRTUAL
          where GAL_PROJECT_ID = iProjectID;
  end DeleteProjectCurrRisk;
end GAL_PRC_CURRENCY_RISK;
