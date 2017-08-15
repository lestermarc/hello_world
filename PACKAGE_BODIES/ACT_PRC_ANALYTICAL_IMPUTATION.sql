--------------------------------------------------------
--  DDL for Package Body ACT_PRC_ANALYTICAL_IMPUTATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_ANALYTICAL_IMPUTATION" 
is
  procedure CreateDeferMgmImputation(
    in_ActDocumentId      in     ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type
  , in_ActFinImputationId in     ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , in_AcsPeriodId        in     ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type
  , in_AcsCpnAccountId    in     ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type
  , in_AcsCdaAccountId    in     ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID%type
  , in_AcsPfAccountId     in     ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID%type
  , in_DocRecordId        in     ACT_MGM_IMPUTATION.DOC_RECORD_ID%type
  , iv_ImmDescription     in     ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type
  , in_ImmAmountLC        in     ACT_MGM_IMPUTATION.IMm_AMOUNT_LC_D%type
  , id_ImmTransactionDate in     ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type
  , on_ActMgmImputationId out    ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActMgmImputation, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_MGM_IMPUTATION_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_FINANCIAL_IMPUTATION_ID', in_ActFinImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_ID', in_ActDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GetLocalCurrencyId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_PERIOD_ID', in_AcsPeriodId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_CPN_ACCOUNT_ID', in_AcsCpnAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_CDA_ACCOUNT_ID', in_AcsCdaAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_PF_ACCOUNT_ID', in_AcsPfAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'DOC_RECORD_ID', in_DocRecordId);

    if in_ImmAmountLC > 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_AMOUNT_LC_D', abs(in_ImmAmountLC) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_AMOUNT_LC_C', 0);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_AMOUNT_LC_D', 0);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_AMOUNT_LC_C', abs(in_ImmAmountLC) );
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_DESCRIPTION', iv_ImmDescription);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_VALUE_DATE', id_ImmTransactionDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'IMM_TRANSACTION_DATE', id_ImmTransactionDate);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    on_ActMgmImputationId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACT_MGM_IMPUTATION_ID');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDeferMgmImputation;

  /**
  * Description
  *    Initialisation des imputation analytiques
  */
  function insertMGM_IMPUTATION(iot_crud_definition in out nocopy fwk_i_typ_definition.T_CRUD_DEF)
    return varchar2
  is
  begin
    --Columns Default Values
    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_GENRE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_GENRE', 'STD');
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_TYPE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_TYPE', 'MAN');
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_EXCHANGE_RATE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_EXCHANGE_RATE', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_AMOUNT_FC_D') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_AMOUNT_FC_D', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_AMOUNT_FC_C') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_AMOUNT_FC_C', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'IMM_BASE_PRICE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'IMM_BASE_PRICE', 0);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'ACS_FINANCIAL_CURRENCY_ID') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition
                                    , 'ACS_FINANCIAL_CURRENCY_ID'
                                    , fwk_i_mgt_entity_data.getcolumnnumber(iot_crud_definition, 'ACS_ACS_FINANCIAL_CURRENCY_ID')
                                     );
    end if;

    --Inserting
    return fwk_i_dml_table.CRUD(iot_crud_definition);
  end insertMGM_IMPUTATION;

  /**
  * Description
  *    Création des distribution analytiques
  */
  procedure CreateDeferMgmDistribution(
    in_ActMgmImputationId in ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID%type
  , iv_MgmDescription     in ACT_FINANCIAL_DISTRIBUTION.FIN_DESCRIPTION%type
  , in_AcsSubSetId        in ACT_FINANCIAL_DISTRIBUTION.ACS_SUB_SET_ID%type
  , in_AcsPjAccountId     in ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID%type
  , in_MgmAmountLC        in ACT_FINANCIAL_DISTRIBUTION.FIN_AMOUNT_LC_D%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActMgmDistribution, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_MGM_DISTRIBUTION_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_MGM_IMPUTATION_ID', in_ActMgmImputationId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_SUB_SET_ID', in_AcsSubSetId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_PJ_ACCOUNT_ID', in_AcsPjAccountId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'MGM_DESCRIPTION', iv_MgmDescription);

    if in_MgmAmountLC > 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'MGM_AMOUNT_LC_D', abs(in_MgmAmountLC) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'MGM_AMOUNT_LC_C', 0);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'MGM_AMOUNT_LC_D', 0);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'MGM_AMOUNT_LC_C', abs(in_MgmAmountLC) );
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDeferMgmDistribution;
end ACT_PRC_ANALYTICAL_IMPUTATION;
