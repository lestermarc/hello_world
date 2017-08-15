--------------------------------------------------------
--  DDL for Package Body ACT_PRC_DEFERRAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_DEFERRAL" 
is
  /**
  * Description
  *    Cette procedure va insérer dans la table temporaire ACT_DEFERRAL_SELECTION les imputations de lissage à extraire.
  */
  procedure CreateSelection(
    in_ActJobId           in ACT_DEFERRAL_SELECTION.ACT_JOB_ID%type
  , in_ActDocumentID      in ACT_DEFERRAL_SELECTION.ACT_DOCUMENT_ID%type
  , in_ActFinImputationId in ACT_DEFERRAL_SELECTION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ActFinAccountIdId  in ACT_DEFERRAL_SELECTION.ACS_FINANCIAL_ACCOUNT_ID%type
  , in_AdsSelect          in ACT_DEFERRAL_SELECTION.ADS_SELECT%type
  , in_AdsReadWrite       in ACT_DEFERRAL_SELECTION.ADS_READ_WRITE%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDeferralSelection, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACT_DEFERRAL_SELECTION_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACT_JOB_ID', in_ActJobId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACT_DOCUMENT_ID', in_ActDocumentID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_ACCOUNT_ID', in_ActFinAccountIdId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ADS_SELECT', in_AdsSelect);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ADS_READ_WRITE', in_AdsReadWrite);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end CreateSelection;

  /**
  * Description
  *    Suppression des position extraites d'un travail comptable
  */
  procedure ClearSelection(in_ActJobId in ACT_DEFERRAL_SELECTION.ACT_JOB_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDeferralSelection, lt_crud_def);

    for tplDeferSelection in (select ACT_DEFERRAL_SELECTION_ID
                                from ACT_DEFERRAL_SELECTION
                               where ACT_JOB_ID = in_ActJobId) loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DEFERRAL_SELECTION_ID', tplDeferSelection.ACT_DEFERRAL_SELECTION_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(lt_crud_def);
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end ClearSelection;

  /**
  * Description
  *    Création d'une position d'imputation de lissage
  */
  procedure CreateImputation(
    in_ActFinImputationId in ACT_DEFERRAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ActDefImputationId in ACT_DEFERRAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , iv_ActDeferIncomplete in ACT_DEFERRAL_IMPUTATION.C_ACT_DEFER_INCOMPLETE%type := '00'
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDeferralImputation, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DEFERRAL_IMPUTATION_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DEFER_FIN_IMP_ID', in_ActDefImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_ACT_DEFER_INCOMPLETE', iv_ActDeferIncomplete);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateImputation;

  /**
  * Description
  *    Suppression des liens en effacement de l'imputation de lissage
  */
  procedure ClearImputation(in_ActFinImputationId in ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDeferralImputation, lt_crud_def);

    for tplDeferImputation in (select ACT_DEFERRAL_IMPUTATION_ID
                                 from ACT_DEFERRAL_IMPUTATION
                                where ACT_DEFER_FIN_IMP_ID = in_ActFinImputationId) loop
      ResetDeferFinImpIncStatus(tplDeferImputation.ACT_DEFERRAL_IMPUTATION_ID);
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DEFERRAL_IMPUTATION_ID', tplDeferImputation.ACT_DEFERRAL_IMPUTATION_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(lt_crud_def);
    end loop;

    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end ClearImputation;

  procedure ResetDeferFinImpIncStatus(in_ActDefImputationId in ACT_DEFERRAL_IMPUTATION.ACT_DEFERRAL_IMPUTATION_ID%type)
  is
    ln_ActReversalImpId ACT_DEFERRAL_IMPUTATION.ACT_DEFERRAL_IMPUTATION_ID%type;
    lv_AcsFinYearId     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    lv_ActDefFinImpId   ACT_DEFERRAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
  begin
    begin
      -- Recherche les éléments de la période actuelle
      select DEF.ACT_FINANCIAL_IMPUTATION_ID
           , JOB.ACS_FINANCIAL_YEAR_ID
        into lv_ActDefFinImpId
           , lv_AcsFinYearId
        from ACT_DEFERRAL_IMPUTATION DEF
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where DEF.ACT_DEFERRAL_IMPUTATION_ID = in_ActDefImputationId
         and IMP.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_DEFER_FIN_IMP_ID
         and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID;

      -- Recherche l'imputation d'extourne
      select ACT_DEFER_FIN_IMP_ID
        into ln_ActReversalImpId
        from ACT_DEFERRAL_IMPUTATION
       where ACT_DEFER_FIN_IMP_ID =
               (select min(IMP.ACT_FINANCIAL_IMPUTATION_ID)
                  from ACT_DEFERRAL_IMPUTATION DEF
                     , ACT_FINANCIAL_IMPUTATION IMP
                     , ACT_JOB JOB
                     , ACT_DOCUMENT DOC
                 where IMP.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_DEFER_FIN_IMP_ID
                   and DEF.ACT_FINANCIAL_IMPUTATION_ID = lv_ActDefFinImpId
                   and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and JOB.ACT_JOB_ID = DOC.ACT_JOB_ID
                   and JOB.ACS_FINANCIAL_YEAR_ID <> lv_AcsFinYearId);

      UpdateDeferFinImpIncStatus(lv_ActDefFinImpId, ln_ActReversalImpId, '01');
    exception
      -- pas de données -> OK, pas d'erreur car lissage sur un excercice
      when no_data_found then
        null;
    end;
  end ResetDeferFinImpIncStatus;

  /**
  * Description
  *    Met à jour le statut de lissage (complet/partiel) pour une imputation d'origine donnée
  */
  procedure UpdateDeferFinImpIncStatus(
    in_ActFinImputationId in ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ActDefImputationId in ACT_DEFERRAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , iv_ActDeferIncomplete in ACT_DEFERRAL_IMPUTATION.C_ACT_DEFER_INCOMPLETE%type := '00'
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDeferralImputation, lt_crud_def);
    for tplDeferImputation in (select ACT_DEFERRAL_IMPUTATION_ID
                                 from ACT_DEFERRAL_IMPUTATION
                                where ACT_FINANCIAL_IMPUTATION_ID = in_ActFinImputationId
                                  and ACT_DEFER_FIN_IMP_ID = nvl(in_ActDefImputationId, ACT_DEFER_FIN_IMP_ID)
                                  and C_ACT_DEFER_INCOMPLETE <> iv_ActDeferIncomplete) loop
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DEFERRAL_IMPUTATION_ID', tplDeferImputation.ACT_DEFERRAL_IMPUTATION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_ACT_DEFER_INCOMPLETE', iv_ActDeferIncomplete);
      FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
      FWK_I_MGT_ENTITY.Release(lt_crud_def);
    end loop;
  end UpdateDeferFinImpIncStatus;

  /**
  * Description
  *    Création d'une position de lettrage pour liaison inter - imputation
  */
  procedure CreateLettering(in_LetIdentification in ACT_LETTERING.LET_IDENTIFICATION%type, on_ActLetteringId out ACT_LETTERING.ACT_LETTERING_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActLettering, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_LETTERING_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'LET_DATE', trunc(sysdate) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'LET_IDENTIFICATION', in_LetIdentification);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    on_ActLetteringId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACT_LETTERING_ID');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateLettering;

  /**
  * Description
  *    Suppression du lettrage
  */
  procedure ClearLettering(in_ActLetteringId in ACT_LETTERING.ACT_LETTERING_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActLettering, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_LETTERING_ID', in_ActLetteringId);
    FWK_I_MGT_ENTITY.DeleteEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end ClearLettering;
end ACT_PRC_DEFERRAL;
