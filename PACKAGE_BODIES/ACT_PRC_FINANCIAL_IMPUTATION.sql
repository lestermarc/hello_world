--------------------------------------------------------
--  DDL for Package Body ACT_PRC_FINANCIAL_IMPUTATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_FINANCIAL_IMPUTATION" 
is
  /**
  * Description
  *    Création d'une position d'imputation financière de lissage sur la base des paramètres données
  */
  procedure CreateDeferFinImputation(
    in_ActDocumentId         in     ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , in_ActDeferLetteringId   in     ACT_FINANCIAL_IMPUTATION.ACT_LETTERING_ID%type
  , in_AcsPeriodId           in     ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , in_AcsFinancialAccountId in     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type
  , in_AcsDivisionAccountId  in     ACT_FINANCIAL_IMPUTATION.IMF_ACS_DIVISION_ACCOUNT_ID%type
  , in_DocRecordId           in     ACT_FINANCIAL_IMPUTATION.DOC_RECORD_ID%type
  , in_ImfPrimary            in     ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
  , iv_ImfDescription        in     ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , in_ImfAmountLC           in     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , id_ImfTransactionDate    in     ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , ion_ActFinImputationId   in out ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActFinancialImputation, lt_crud_def);

    if ion_ActFinImputationId is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', INIT_ID_SEQ.nextval);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', ion_ActFinImputationId);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_ID', in_ActDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_LETTERING_ID', in_ActDeferLetteringId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_PERIOD_ID', in_AcsPeriodId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_ACCOUNT_ID', in_AcsFinancialAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_ACS_DIVISION_ACCOUNT_ID', in_AcsDivisionAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'DOC_RECORD_ID', in_DocRecordId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GetLocalCurrencyId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_PRIMARY', in_ImfPrimary);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_DESCRIPTION', iv_ImfDescription);

    if in_ImfAmountLC > 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_D', abs(in_ImfAmountLC) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_C', 0);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_D', 0);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_C', abs(in_ImfAmountLC) );
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_VALUE_DATE', id_ImfTransactionDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_TRANSACTION_DATE', id_ImfTransactionDate);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    ion_ActFinImputationId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDeferFinImputation;

  /**
  * Description
  *    Initialisation des imputation financières
  */
  function insertFINANCIAL_IMPUTATION(iot_crud_definition in out nocopy fwk_i_typ_definition.T_CRUD_DEF)
    return varchar2
  is
  begin
    --Columns Default Values
    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_GENRE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_GENRE', 'STD');
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_TYPE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_TYPE', 'MAN');
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_EXCHANGE_RATE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_EXCHANGE_RATE', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_AMOUNT_FC_D') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_AMOUNT_FC_D', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_AMOUNT_FC_C') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_AMOUNT_FC_C', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_BASE_PRICE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_BASE_PRICE', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'C_GENRE_TRANSACTION') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'C_GENRE_TRANSACTION', '1');
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'ACS_FINANCIAL_CURRENCY_ID') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition
                                    , 'ACS_FINANCIAL_CURRENCY_ID'
                                    , fwk_i_mgt_entity_data.getcolumnnumber(iot_crud_definition, 'ACS_ACS_FINANCIAL_CURRENCY_ID')
                                     );
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMF_DEFERRABLE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMF_DEFERRABLE', '0');
    end if;

    --Inserting
    return fwk_i_dml_table.CRUD(iot_crud_definition);
  end insertFINANCIAL_IMPUTATION;

  /**
  * Description
  *    Mise à jour du lien entre les imputations lissées et l'imputation d'origine
  */
  procedure UpdateDeferFinImpLink(
    in_ActFinancialImputationId in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ActDeferLetteringId      in ACT_FINANCIAL_IMPUTATION.ACT_LETTERING_ID%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActFinancialImputation, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinancialImputationId);

    if not in_ActDeferLetteringId is null then
      --Ajout lien de lettrage
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_LETTERING_ID', in_ActDeferLetteringId);
      --Enlever le flag "A lisser"
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_DEFERRABLE', 0);
    else
      --Supprimer le lien de lettrage
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(lt_crud_def, 'ACT_LETTERING_ID');
      --Remettre l'imputation "A lisser"
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_DEFERRABLE', 1);
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end UpdateDeferFinImpLink;

  /**
  * Description
  *    Mise à jour du montant de l'imputation
  */
  procedure UpdateDeferFinImpAmount(
    in_ActFinancialImputationId in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ImfAmountLc              in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActFinancialImputation, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinancialImputationId);

    if not in_ImfAmountLC is null then
      if in_ImfAmountLC > 0 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_D', abs(in_ImfAmountLC) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_C', 0);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_D', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMF_AMOUNT_LC_C', abs(in_ImfAmountLC) );
      end if;
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end UpdateDeferFinImpAmount;

  /**
  * Description
  *    Création des distribution financières
  */
  procedure CreateDeferFinDistribution(
    in_ActFinImputationId   in ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID%type
  , iv_FinDescription       in ACT_FINANCIAL_DISTRIBUTION.FIN_DESCRIPTION%type
  , in_AcsSubSetId          in ACT_FINANCIAL_DISTRIBUTION.ACS_SUB_SET_ID%type
  , in_AcsDivisionAccountId in ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID%type
  , in_ImfAmountLC          in ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_LC_D%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActFinancialDistribution, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_DISTRIBUTION_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_SUB_SET_ID', in_AcsSubSetId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_DIVISION_ACCOUNT_ID', in_AcsDivisionAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_DESCRIPTION', iv_FinDescription);

    if in_ImfAmountLC > 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_D', abs(in_ImfAmountLC) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_C', 0);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_D', 0);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_C', abs(in_ImfAmountLC) );
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDeferFinDistribution;

  /**
  * Description
  *    Mise à jour du montant de l'imputation
  */
  procedure UpdateDeferFinDistribAmount(
    in_ActFinancialImputationId in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_ImfAmountLc              in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActFinancialDistribution, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_DISTRIBUTION_ID',
      FWK_I_LIB_ENTITY.getIdfromPk2('ACT_FINANCIAL_DISTRIBUTION', 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinancialImputationId));

    if not in_ImfAmountLC is null then
      if in_ImfAmountLC > 0 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_D', abs(in_ImfAmountLC) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_C', 0);
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_D', 0);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'FIN_AMOUNT_LC_C', abs(in_ImfAmountLC) );
      end if;
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end UpdateDeferFinDistribAmount;
end ACT_PRC_FINANCIAL_IMPUTATION;
