--------------------------------------------------------
--  DDL for Package Body ACT_PRC_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_DOCUMENT" 
is
  /**
  * Description
  *    Création du journal comptable selon paramètres donnés
  */
  procedure CreateJournal(
    in_ActJobId           in     ACT_JOURNAL.ACT_JOB_ID%type
  , in_ActAccountingId    in     ACT_JOURNAL.ACS_ACCOUNTING_ID%type
  , in_AcsFinancialYearId in     ACT_JOURNAL.ACS_FINANCIAL_YEAR_ID%type
  , iv_JouDescription     in     ACT_JOURNAL.JOU_DESCRIPTION%type
  , iv_JouNumber          in     ACT_JOURNAL.JOU_NUMBER%type
  , on_ActJournalId       out    ACT_JOURNAL.ACT_JOURNAL_ID%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActJournal, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_JOURNAL_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_JOB_ID', in_ActJobId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ACCOUNTING_ID', in_ActAccountingId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_YEAR_ID', in_AcsFinancialYearId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_TYPE_JOURNAL', 'MAN');
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'JOU_DESCRIPTION', iv_JouDescription);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'JOU_NUMBER', iv_JouNumber);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'PC_USER_ID', PCS.PC_I_LIB_SESSION.GetUserId);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    on_ActJournalId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACT_JOURNAL_ID');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateJournal;

  /**
  * Description
  *    Création de l'état journal
  */
  procedure CreateJournalState(
    in_ActJournalId in ACT_ETAT_JOURNAL.ACT_JOURNAL_ID%type
  , iv_CSubSet      in ACT_ETAT_JOURNAL.C_SUB_SET%type
  , iv_CEtatJournal in ACT_ETAT_JOURNAL.C_ETAT_JOURNAL%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActEtatJournal, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_ETAT_JOURNAL_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_JOURNAL_ID', in_ActJournalId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_SUB_SET', iv_CSubSet);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_ETAT_JOURNAL', iv_CEtatJournal);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateJournalState;

/**
  * Description
  *    Création d'un document comptable sur la base des paramètres données
  */
  procedure CreateDocument(
    in_ActJobId               in     ACT_DOCUMENT.ACT_JOB_ID%type
  , in_ActJournalId           in     ACT_DOCUMENT.ACT_JOURNAL_ID%type
  , in_ActActJournalId        in     ACT_DOCUMENT.ACT_ACT_JOURNAL_ID%type
  , in_AcjCatalogueDocumentId in     ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , in_AcsFinancialYearId     in     ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type
  , on_ActDocumentId          out    ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , on_DocNumber              out    ACT_DOCUMENT.DOC_NUMBER%type
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDocument, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_JOB_ID', in_ActJobId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_JOURNAL_ID', in_ActJournalId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_ACT_JOURNAL_ID', in_ActActJournalId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_YEAR_ID', in_AcsFinancialYearId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACJ_CATALOGUE_DOCUMENT_ID', in_AcjCatalogueDocumentId);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    on_ActDocumentId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(lt_crud_def, 'ACT_DOCUMENT_ID');
    on_DocNumber      := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(lt_crud_def, 'DOC_NUMBER');
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDocument;

  /**
  * Description
  *    Initialisation des document comptables en ajout
  */
  function insertDOCUMENT(iot_crud_definition in out nocopy fwk_i_typ_definition.T_CRUD_DEF)
    return varchar2
  is
    lv_DocNumber varchar2(30);
  begin
    --Columns Default Values
    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'DOC_NUMBER') then
      ACT_FUNCTIONS.GetDocNumber(fwk_i_mgt_entity_data.getcolumnnumber(iot_crud_definition, 'ACJ_CATALOGUE_DOCUMENT_ID')
                               , fwk_i_mgt_entity_data.getcolumnnumber(iot_crud_definition, 'ACS_FINANCIAL_YEAR_ID')
                               , lv_DocNumber
                                );
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'DOC_NUMBER', lv_DocNumber);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'DOC_DOCUMENT_DATE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'DOC_DOCUMENT_DATE', trunc(sysdate) );
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'ACS_FINANCIAL_CURRENCY_ID') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GetLocalCurrencyId);
    end if;

    if fwk_i_mgt_entity_data.isnull(iot_crud_definition, 'C_CURR_RATE_COVER_TYPE') then
      fwk_i_mgt_entity_data.setcolumn(iot_crud_definition, 'C_CURR_RATE_COVER_TYPE', '00');
    end if;

    --Inserting
    return fwk_i_dml_table.CRUD(iot_crud_definition);
  end;

  /**
  * Description
  *    Mise à jour du montant total document du document donné en paramètre
  */
  procedure UpdateDocument(in_ActDocumentId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type, in_DocTotalAmount in ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDocument, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_ID', in_ActDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'DOC_TOTAL_AMOUNT_DC', in_DocTotalAmount);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end UpdateDocument;

  /**
  * Description
  *    Création d'un enrgistrement de statut de document comptable
  */
  procedure CreateDocStatus(in_ActDocumentId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACT_ENTITY.gcActDocumentStatus, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_STATUS_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACT_DOCUMENT_ID', in_ActDocumentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'DOC_OK', 0);
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end CreateDocStatus;
end ACT_PRC_DOCUMENT;
