--------------------------------------------------------
--  DDL for Package Body ACJ_DUPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACJ_DUPLICATE" 
is
  /**
  * Description
  *        Procédure de copie des catalogues de transactions
  */
  procedure DuplicateCatalogue(
    pSourceId     in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pDuplicatedId out    ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  )
  is
    vCntFieldLength constant number(2)                             := 30;   --longueur max de la clé
    vLastNumber              number(3)                             := 2;
    vSrcCatKey               ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type;
  begin
    -- Recherche du numéro dans la clé originale
    -- Si copie d'un enregistrement original (sans parenthèse) => prendre 2
    -- sinon rechercher le chiffre entre () et ajouter 1
    select CAT_KEY
      into vSrcCatKey
      from ACJ_CATALOGUE_DOCUMENT
     where ACJ_CATALOGUE_DOCUMENT_ID = pSourceId;

    --Recherche du plus grand numéro de copie entre () correspondant à la clé
    if instr(vSrcCatKey, '(', -1) > 0 then
      vSrcCatKey  := substr(vSrcCatKey, 1, instr(vSrcCatKey, '(', -1) - 1);
    end if;

    begin
      select nvl(max(to_number(substr(CAT_KEY
                                    , instr(CAT_KEY, '(', -1) + 1
                                    , instr(CAT_KEY, ')', -1) - 1 - instr(CAT_KEY, '(', -1)
                                     )
                              ) +
                     1
                    )
               , 2
                ) LAST_NUMBER
        into vLastNumber
        from ACJ_CATALOGUE_DOCUMENT
       where CAT_KEY like vSrcCatKey || '(' || '%';
    exception
      when invalid_number then   --Il est possible que les dernières parenthèses ne contiennent pas un chiffre
        vLastNumber  := 2;
    end;

    --Réception d'un nouvel Id
    select INIT_ID_SEQ.nextval
      into pDuplicatedID
      from dual;

    --Contrôle de la nouvelle longueur de clé avec l'ajout du nouveau numéro
    insert into ACJ_CATALOGUE_DOCUMENT
                (ACJ_CATALOGUE_DOCUMENT_ID
               , CAT_KEY
               , C_TYPE_CATALOGUE
               , CAT_DESCRIPTION
               , CAT_FIN_TRANSACTION
               , CAT_COM_TRANSACTION
               , CAT_CAE_TRANSACTION
               , C_TYPE_PERIOD
               , CAT_EXT_VAT
               , CAT_EXT_VAT_DISCOUNT
               , DIC_EXTERNAL_PROCESS_ID
               , ACS_FIN_ACC_S_PAYMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , CAT_EXT_TRANSACTION
               , C_REMINDER_METHOD
               , CAT_DOC_SHOW
               , CAT_PART_SHOW
               , DIC_TYPE_MOVEMENT_ID
               , CAT_REPORT
               , CAT_COVER_INFORMATION
               , CAT_IMP_INFORMATION
               , CAT_MGM_SIMPLIFIED
               , CAT_FREE_DATA
               , CAT_LINK
               , C_ADMIN_DOMAIN
               , CAT_SERVICES_INPUT
               , ACJ_DESCRIPTION_TYPE_ID
               , DIC_OPERATION_TYP_ID
               , DIC_ACJ_CAT_FREE_COD1_ID
               , DIC_ACJ_CAT_FREE_COD2_ID
               , DIC_ACJ_CAT_FREE_COD3_ID
               , DIC_ACJ_CAT_FREE_COD4_ID
               , DIC_ACJ_CAT_FREE_COD5_ID
               , DIC_ACJ_CAT_FREE_COD6_ID
               , DIC_ACJ_CAT_FREE_COD7_ID
               , DIC_ACJ_CAT_FREE_COD8_ID
               , DIC_ACJ_CAT_FREE_COD9_ID
               , DIC_ACJ_CAT_FREE_COD10_ID
               , CAT_DISCOUNT_PROP
               , CAT_PART_LETT_DISCOUNT
               , CAT_PART_LETT_DIFF_EXCHANGE
               , CAT_AUTO_LETTRING
               , CAT_STORED_PROC_B_DELETE
               , CAT_STORED_PROC_A_DELETE
               , CAT_STORED_PROC_B_EDIT
               , CAT_STORED_PROC_A_EDIT
               , CAT_STORED_PROC_B_VALIDATE
               , CAT_STORED_PROC_A_VALIDATE
               , CAT_ENFORCED_ACCOUNT
               , CAT_AUTO_PART_LETT
               , DIC_PROJECT_CONSOL_1_ID
               , C_PROJECT_CONSOLIDATION
               , C_MATCHING_TOLERANCE
               , PAC_PAYMENT_CONDITION_ID
               , DIC_BLOCKED_REASON_ID
               , CAT_BLOCKED_DOC
               , CAT_EXPENSE_RECEIPT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_CONFIRM
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select pDuplicatedID
           , case
               when length(vSrcCatKey || '(' || to_char(vLastNumber) || ')') > vCntFieldLength then substr
                                                                                                      (vSrcCatKey
                                                                                                     , 1
                                                                                                     , vCntFieldLength -
                                                                                                       length
                                                                                                         ('(' ||
                                                                                                          to_char
                                                                                                            (vLastNumber
                                                                                                            ) ||
                                                                                                          ')'
                                                                                                         )
                                                                                                      ) ||
                                                                                                    '(' ||
                                                                                                    to_char
                                                                                                         (vLastNumber) ||
                                                                                                    ')'
               else vSrcCatKey || '(' || to_char(vLastNumber) || ')'
             end
           , C_TYPE_CATALOGUE
           , CAT_DESCRIPTION
           , CAT_FIN_TRANSACTION
           , CAT_COM_TRANSACTION
           , CAT_CAE_TRANSACTION
           , C_TYPE_PERIOD
           , CAT_EXT_VAT
           , CAT_EXT_VAT_DISCOUNT
           , DIC_EXTERNAL_PROCESS_ID
           , ACS_FIN_ACC_S_PAYMENT_ID
           , ACS_FINANCIAL_ACCOUNT_ID
           , CAT_EXT_TRANSACTION
           , C_REMINDER_METHOD
           , CAT_DOC_SHOW
           , CAT_PART_SHOW
           , DIC_TYPE_MOVEMENT_ID
           , CAT_REPORT
           , CAT_COVER_INFORMATION
           , CAT_IMP_INFORMATION
           , CAT_MGM_SIMPLIFIED
           , CAT_FREE_DATA
           , CAT_LINK
           , C_ADMIN_DOMAIN
           , CAT_SERVICES_INPUT
           , ACJ_DESCRIPTION_TYPE_ID
           , DIC_OPERATION_TYP_ID
           , DIC_ACJ_CAT_FREE_COD1_ID
           , DIC_ACJ_CAT_FREE_COD2_ID
           , DIC_ACJ_CAT_FREE_COD3_ID
           , DIC_ACJ_CAT_FREE_COD4_ID
           , DIC_ACJ_CAT_FREE_COD5_ID
           , DIC_ACJ_CAT_FREE_COD6_ID
           , DIC_ACJ_CAT_FREE_COD7_ID
           , DIC_ACJ_CAT_FREE_COD8_ID
           , DIC_ACJ_CAT_FREE_COD9_ID
           , DIC_ACJ_CAT_FREE_COD10_ID
           , CAT_DISCOUNT_PROP
           , CAT_PART_LETT_DISCOUNT
           , CAT_PART_LETT_DIFF_EXCHANGE
           , CAT_AUTO_LETTRING
           , CAT_STORED_PROC_B_DELETE
           , CAT_STORED_PROC_A_DELETE
           , CAT_STORED_PROC_B_EDIT
           , CAT_STORED_PROC_A_EDIT
           , CAT_STORED_PROC_B_VALIDATE
           , CAT_STORED_PROC_A_VALIDATE
           , CAT_ENFORCED_ACCOUNT
           , CAT_AUTO_PART_LETT
           , DIC_PROJECT_CONSOL_1_ID
           , C_PROJECT_CONSOLIDATION
           , C_MATCHING_TOLERANCE
           , PAC_PAYMENT_CONDITION_ID
           , DIC_BLOCKED_REASON_ID
           , CAT_BLOCKED_DOC
           , CAT_EXPENSE_RECEIPT
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_CONFIRM
           , A_RECLEVEL
           , A_RECSTATUS
        from ACJ_CATALOGUE_DOCUMENT
       where ACJ_CATALOGUE_DOCUMENT_ID = pSourceId;

    -- copie de la table ACJ_SUB_SET_CAT
    insert into ACJ_SUB_SET_CAT
                (ACJ_SUB_SET_CAT_ID
               , ACJ_CATALOGUE_DOCUMENT_ID
               , C_TYPE_CUMUL
               , C_METHOD_CUMUL
               , C_SUB_SET
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , SUB_DEFERED
               , SUB_DOC_NUMBER_CTRL
               , SUB_CPN_CHOICE
                )
      select INIT_ID_SEQ.nextval
           , pDuplicatedID
           , C_TYPE_CUMUL
           , C_METHOD_CUMUL
           , C_SUB_SET
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
           , SUB_DEFERED
           , SUB_DOC_NUMBER_CTRL
           , SUB_CPN_CHOICE
        from ACJ_SUB_SET_CAT
       where ACJ_CATALOGUE_DOCUMENT_ID = pSourceID;

    -- copie de la table ACJ_JOB_TYPE_S_CATALOGUE
    insert into ACJ_JOB_TYPE_S_CATALOGUE
                (ACJ_JOB_TYPE_S_CATALOGUE_ID
               , ACJ_JOB_TYPE_ID
               , ACJ_CATALOGUE_DOCUMENT_ID
               , JCA_DEFAULT
               , JCA_AVAILABLE
               , JCA_COPY_POSSIBLE
               , JCA_EXT_POSSIBLE
                )
      select INIT_ID_SEQ.nextval
           , ACJ_JOB_TYPE_ID
           , pDuplicatedID
           , 0
           , JCA_AVAILABLE
           , JCA_COPY_POSSIBLE
           , JCA_EXT_POSSIBLE
        from ACJ_JOB_TYPE_S_CATALOGUE
       where ACJ_CATALOGUE_DOCUMENT_ID = pSourceID;

    -- copie de la table ACJ_IMP_MANAGED_DATA
    insert into ACJ_IMP_MANAGED_DATA
                (ACJ_IMP_MANAGED_DATA_ID
               , ACJ_CATALOGUE_DOCUMENT_ID
               , C_DATA_TYP
               , MDA_MANDATORY
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , MDA_MANDATORY_PRIMARY
                )
      select INIT_ID_SEQ.nextval
           , pDuplicatedID
           , C_DATA_TYP
           , MDA_MANDATORY
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
           , MDA_MANDATORY_PRIMARY
        from ACJ_IMP_MANAGED_DATA
       where ACJ_CATALOGUE_DOCUMENT_ID = pSourceID;
  end DuplicateCatalogue;

  /**
  * Description
  *        Procédure de copie des modèles de travaux
  */
  procedure DuplicateJobType(
    pSourceId     in     ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type
  , pDuplicatedId out    ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type
  )
  is
    vCntFieldLength constant number(2)                     := 30;   --longueur max de la clé
    vLastNumber              number(3)                     := 2;
    vSrcTypKey               ACJ_JOB_TYPE.TYP_KEY%type;
    vDuplicatedEventId       ACJ_EVENT.ACJ_EVENT_ID%type;
  begin
    -- Recherche du numéro dans la clé originale
    -- Si copie d'un enregistrement original (sans parenthèse) => prendre 2
    -- sinon rechercher le chiffre entre () et ajouter 1
    select TYP_KEY
      into vSrcTypKey
      from ACJ_JOB_TYPE
     where ACJ_JOB_TYPE_ID = pSourceId;

    --Recherche du plus grand numéro de copie entre () correspondant à la clé
    if instr(vSrcTypKey, '(', -1) > 0 then
      vSrcTypKey  := substr(vSrcTypKey, 1, instr(vSrcTypKey, '(', -1) - 1);
    end if;

    begin
      select nvl(max(to_number(substr(TYP_KEY
                                    , instr(TYP_KEY, '(', -1) + 1
                                    , instr(TYP_KEY, ')', -1) - 1 - instr(TYP_KEY, '(', -1)
                                     )
                              ) +
                     1
                    )
               , 2
                ) LAST_NUMBER
        into vLastNumber
        from ACJ_JOB_TYPE
       where TYP_KEY like vSrcTypKey || '(' || '%';
    exception
      when invalid_number then   --Il est possible que les dernières parenthèses ne contiennent pas un chiffre
        vLastNumber  := 2;
    end;

    --Réception d'un nouvel Id
    select INIT_ID_SEQ.nextval
      into pDuplicatedID
      from dual;

    --Copie du modèle
    insert into ACJ_JOB_TYPE
                (ACJ_JOB_TYPE_ID
               , TYP_KEY
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , TYP_DESCRIPTION
               , C_VALID
               , PC_USER_ID
               , C_ACI_GROUP_TYPE
               , C_ACI_CADENCE
               , C_ACI_FINANCIAL_LINK
               , TYP_SUPPLIER_PERMANENT
               , TYP_ACI_DETAIL
               , TYP_RESTRICT_PERIOD
               , TYP_AVAILABLE
               , TYP_ZERO_DOCUMENT
               , TYP_ZERO_POSITION
               , TYP_DEBIT_CREDIT_GROUP
               , TYP_REPORT
               , TYP_ACI_DOC_UPDATE
               , C_JOB_STATE
               , DIC_ACJ_TYP_FREE_COD1_ID
               , DIC_ACJ_TYP_FREE_COD2_ID
               , DIC_ACJ_TYP_FREE_COD3_ID
               , DIC_ACJ_TYP_FREE_COD4_ID
               , DIC_ACJ_TYP_FREE_COD5_ID
               , DIC_ACJ_TYP_FREE_COD6_ID
               , DIC_ACJ_TYP_FREE_COD7_ID
               , DIC_ACJ_TYP_FREE_COD8_ID
               , DIC_ACJ_TYP_FREE_COD9_ID
               , DIC_ACJ_TYP_FREE_COD10_ID
               , TYP_JOURNALIZE_ACCOUNTING
               , DIC_JOURNAL_TYPE_ID
               , TYP_INIT_JOB_DESCR
               , TYP_CLO_PER_ACC
               , TYP_STORED_PROC_TODO
               , TYP_STORED_PROC_PEND
               , TYP_STORED_PROC_FINT
               , TYP_STORED_PROC_TERM
               , TYP_STORED_PROC_DEF
                )
      select pDuplicatedID
           , case
               when length(vSrcTypKey || '(' || to_char(vLastNumber) || ')') > vCntFieldLength then substr
                                                                                                      (vSrcTypKey
                                                                                                     , 1
                                                                                                     , vCntFieldLength -
                                                                                                       length
                                                                                                         ('(' ||
                                                                                                          to_char
                                                                                                            (vLastNumber
                                                                                                            ) ||
                                                                                                          ')'
                                                                                                         )
                                                                                                      ) ||
                                                                                                    '(' ||
                                                                                                    to_char
                                                                                                         (vLastNumber) ||
                                                                                                    ')'
               else vSrcTypKey || '(' || to_char(vLastNumber) || ')'
             end
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
           , TYP_DESCRIPTION
           , C_VALID
           , PC_USER_ID
           , C_ACI_GROUP_TYPE
           , C_ACI_CADENCE
           , C_ACI_FINANCIAL_LINK
           , TYP_SUPPLIER_PERMANENT
           , TYP_ACI_DETAIL
           , TYP_RESTRICT_PERIOD
           , TYP_AVAILABLE
           , TYP_ZERO_DOCUMENT
           , TYP_ZERO_POSITION
           , TYP_DEBIT_CREDIT_GROUP
           , TYP_REPORT
           , TYP_ACI_DOC_UPDATE
           , C_JOB_STATE
           , DIC_ACJ_TYP_FREE_COD1_ID
           , DIC_ACJ_TYP_FREE_COD2_ID
           , DIC_ACJ_TYP_FREE_COD3_ID
           , DIC_ACJ_TYP_FREE_COD4_ID
           , DIC_ACJ_TYP_FREE_COD5_ID
           , DIC_ACJ_TYP_FREE_COD6_ID
           , DIC_ACJ_TYP_FREE_COD7_ID
           , DIC_ACJ_TYP_FREE_COD8_ID
           , DIC_ACJ_TYP_FREE_COD9_ID
           , DIC_ACJ_TYP_FREE_COD10_ID
           , TYP_JOURNALIZE_ACCOUNTING
           , DIC_JOURNAL_TYPE_ID
           , TYP_INIT_JOB_DESCR
           , TYP_CLO_PER_ACC
           , TYP_STORED_PROC_TODO
           , TYP_STORED_PROC_PEND
           , TYP_STORED_PROC_FINT
           , TYP_STORED_PROC_TERM
           , TYP_STORED_PROC_DEF
        from ACJ_JOB_TYPE
       where ACJ_JOB_TYPE_ID = pSourceId;

    --Copie des autorisations par utilisateur ACJ_AUTORIZED_JOB_TYPE
    insert into ACJ_AUTORIZED_JOB_TYPE
                (ACJ_JOB_TYPE_ID
               , PC_USER_ID
               , AUT_DEF_AUTHORIZED
               , AUT_CLO_PER_ACC
               , AUT_CREATE
               , AUT_MODIFY
               , AUT_DELETE
               , AUT_SERIE_PERIOD_JOB_CREATE
                )
      select pDuplicatedId
           , PC_USER_ID
           , AUT_DEF_AUTHORIZED
           , AUT_CLO_PER_ACC
           , AUT_CREATE
           , AUT_MODIFY
           , AUT_DELETE
           , AUT_SERIE_PERIOD_JOB_CREATE
        from ACJ_AUTORIZED_JOB_TYPE
       where ACJ_JOB_TYPE_ID = pSourceId;

    for tplEvent in (select *
                       from ACJ_EVENT
                      where ACJ_JOB_TYPE_ID = pSourceId) loop
      select INIT_ID_SEQ.nextval
        into vDuplicatedEventId
        from dual;

      --Copie des tâches ACJ_EVENT
      insert into ACJ_EVENT
                  (ACJ_EVENT_ID
                 , ACJ_JOB_TYPE_ID
                 , A_CONFIRM
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , C_TYPE_EVENT
                 , EVE_NOSEQUENCE
                 , EVE_DESCRIPTION
                 , EVE_VAT_METHOD
                 , EVE_REC_PAY_TOT_DISPLAY
                 , EVE_ACC_TOT_DISPLAY
                 , EVE_ACC_BUDGET_DISPLAY
                 , EVE_PROCEDURE
                 , EVE_DEFAULT_FIN_REF
                 , EVE_MGM_CTRL_DEB_CRE
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , C_TYPE_SUPPORT
                 , EVE_VAL_DATE_BY_DOC_DATE
                 , EVE_CHK_VALUE_DATE
                 , EVE_DEFAULT_VALUE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , EVE_REMAINDER_CALC_DAYS
                 , EVE_MGM_RECORD
                 , PC_REPORT_ID
                 , EVE_MAN_DOCUMENT_DATE
                 , EVE_OFFSETS_ENTRY_D_C
                 , EVE_MULTI_USERS
                 , EVE_BALANCE_DISP
                  )
           values (vDuplicatedEventId
                 , pDuplicatedId
                 , tplEvent.A_CONFIRM
                 , sysdate
                 , null
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , null
                 , tplEvent.A_RECLEVEL
                 , tplEvent.A_RECSTATUS
                 , tplEvent.C_TYPE_EVENT
                 , tplEvent.EVE_NOSEQUENCE
                 , tplEvent.EVE_DESCRIPTION
                 , tplEvent.EVE_VAT_METHOD
                 , tplEvent.EVE_REC_PAY_TOT_DISPLAY
                 , tplEvent.EVE_ACC_TOT_DISPLAY
                 , tplEvent.EVE_ACC_BUDGET_DISPLAY
                 , tplEvent.EVE_PROCEDURE
                 , tplEvent.EVE_DEFAULT_FIN_REF
                 , tplEvent.EVE_MGM_CTRL_DEB_CRE
                 , tplEvent.ACS_FINANCIAL_ACCOUNT_ID
                 , tplEvent.C_TYPE_SUPPORT
                 , tplEvent.EVE_VAL_DATE_BY_DOC_DATE
                 , tplEvent.EVE_CHK_VALUE_DATE
                 , tplEvent.EVE_DEFAULT_VALUE
                 , tplEvent.ACS_FINANCIAL_CURRENCY_ID
                 , tplEvent.EVE_REMAINDER_CALC_DAYS
                 , tplEvent.EVE_MGM_RECORD
                 , tplEvent.PC_REPORT_ID
                 , tplEvent.EVE_MAN_DOCUMENT_DATE
                 , tplEvent.EVE_OFFSETS_ENTRY_D_C
                 , tplEvent.EVE_MULTI_USERS
                 , tplEvent.EVE_BALANCE_DISP
                  );

      insert into ACJ_AUTORIZED_EVENT
                  (ACJ_EVENT_ID
                 , PC_USER_ID
                  )
        select vDuplicatedEventId
             , PC_USER_ID
          from ACJ_AUTORIZED_EVENT
         where ACJ_EVENT_ID = tplEvent.ACJ_EVENT_ID;
    end loop;

    -- Copie des catalogues autorisés
    insert into ACJ_JOB_TYPE_S_CATALOGUE
                (ACJ_JOB_TYPE_S_CATALOGUE_ID
               , ACJ_JOB_TYPE_ID
               , ACJ_CATALOGUE_DOCUMENT_ID
               , JCA_DEFAULT
               , JCA_AVAILABLE
               , JCA_COPY_POSSIBLE
               , JCA_EXT_POSSIBLE
                )
      select INIT_ID_SEQ.nextval
           , pDuplicatedId
           , ACJ_CATALOGUE_DOCUMENT_ID
           , JCA_DEFAULT
           , JCA_AVAILABLE
           , JCA_COPY_POSSIBLE
           , JCA_EXT_POSSIBLE
        from ACJ_JOB_TYPE_S_CATALOGUE
       where ACJ_JOB_TYPE_ID = pSourceId;

    -- Copie des comptes financiers autorisés
    insert into ACJ_JOB_TYPE_S_FIN_ACC
                (ACJ_JOB_TYPE_S_FIN_ACC_ID
               , ACJ_JOB_TYPE_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select INIT_ID_SEQ.nextval
           , pDuplicatedId
           , ACS_FINANCIAL_ACCOUNT_ID
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
        from ACJ_JOB_TYPE_S_FIN_ACC
       where ACJ_JOB_TYPE_ID = pSourceId;

    -- Copie des divisions autorisées
    insert into ACJ_JOB_TYPE_S_FIN_DIV
                (ACJ_JOB_TYPE_S_FIN_DIV_ID
               , ACJ_JOB_TYPE_ID
               , ACS_DIVISION_ACCOUNT_ID
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select INIT_ID_SEQ.nextval
           , pDuplicatedId
           , ACS_DIVISION_ACCOUNT_ID
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
        from ACJ_JOB_TYPE_S_FIN_DIV
       where ACJ_JOB_TYPE_ID = pSourceId;
  end DuplicateJobType;
end ACJ_DUPLICATE;
