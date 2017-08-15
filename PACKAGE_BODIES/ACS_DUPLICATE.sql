--------------------------------------------------------
--  DDL for Package Body ACS_DUPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_DUPLICATE" 
is
  /**
  * Description
  *        Procédure de copie des monnaies comptables
  */
  procedure DuplicateFinCurrency(
    pSourceId     in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pNewPCCurrID  in     PCS.PC_CURR.PC_CURR_ID%type
  , pDuplicatedID out    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  )
  is
  begin
    --Réception d'un nouvel Id de monnaie
    select INIT_ID_SEQ.nextval
      into pDuplicatedID
      from dual;

    --Copie de la monnaie
    insert into ACS_FINANCIAL_CURRENCY
                (ACS_FINANCIAL_CURRENCY_ID
               , PC_CURR_ID
               , ACS_LOSS_EXCH_EFFECT_ID
               , ACS_GAIN_EXCH_EFFECT_ID
               , ACS_LOSS_EXCH_COMP_ID
               , ACS_GAIN_EXCH_COMP_ID
               , FIN_LOCAL_CURRENCY
               , FIN_HRM_CURRENCY
               , FIN_BASE_PRICE
               , FIN_ROUNDED_AMOUNT
               , C_ROUND_TYPE
               , C_PRICE_METHOD
               , ACS_PJ_COMP_LOSS_ID
               , ACS_PJ_EFF_GAIN_ID
               , ACS_PJ_COMP_GAIN_ID
               , ACS_PF_EFF_GAIN_ID
               , ACS_PF_COMP_LOSS_ID
               , ACS_PF_COMP_GAIN_ID
               , ACS_CDA_EFF_LOSS_ID
               , ACS_CDA_EFF_GAIN_ID
               , ACS_CDA_COMP_LOSS_ID
               , ACS_PJ_EFF_LOSS_ID
               , ACS_PF_EFF_LOSS_ID
               , ACS_CDA_COMP_GAIN_ID
               , FIN_EURO_FROM
               , FIN_EURO_RATE
               , ACS_PAY_EFF_GAIN_ID
               , ACS_PAY_EFF_LOSS_ID
               , ACS_PAY_PJ_EFF_LOSS_ID
               , ACS_PAY_PJ_EFF_GAIN_ID
               , ACS_PAY_PF_EFF_LOSS_ID
               , ACS_PAY_PF_EFF_GAIN_ID
               , ACS_PAY_CDA_EFF_LOSS_ID
               , ACS_PAY_CDA_EFF_GAIN_ID
               , C_ROUND_TYPE_DOC
               , FIN_ROUNDED_AMOUNT_DOC
               , ACS_GAIN_EXCH_DEBT_ID
               , ACS_LOSS_EXCH_DEBT_ID
               , ACS_PJ_LOSS_EXCH_DEBT_ID
               , ACS_PJ_GAIN_EXCH_DEBT_ID
               , ACS_PF_GAIN_EXCH_DEBT_ID
               , ACS_PF_LOSS_EXCH_DEBT_ID
               , ACS_CDA_GAIN_EXCH_DEBT_ID
               , ACS_CDA_LOSS_EXCH_DEBT_ID
               , ACS_GAIN_EXCH_EFFECT_F_ID
               , ACS_CDA_EFF_GAIN_F_ID
               , ACS_PF_EFF_GAIN_F_ID
               , ACS_PJ_EFF_GAIN_F_ID
               , ACS_LOSS_EXCH_EFFECT_F_ID
               , ACS_CDA_EFF_LOSS_F_ID
               , ACS_PF_EFF_LOSS_F_ID
               , ACS_PJ_EFF_LOSS_F_ID
               , ACS_PAY_EFF_GAIN_F_ID
               , ACS_PAY_CDA_EFF_GAIN_F_ID
               , ACS_PAY_PF_EFF_GAIN_F_ID
               , ACS_PAY_PJ_EFF_GAIN_F_ID
               , ACS_PAY_EFF_LOSS_F_ID
               , ACS_PAY_CDA_EFF_LOSS_F_ID
               , ACS_PAY_PF_EFF_LOSS_F_ID
               , ACS_PAY_PJ_EFF_LOSS_F_ID
               , FIN_VALID_TO
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
               , A_CONFIRM
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select pDuplicatedID
           , pNewPCCurrID
           , ACS_LOSS_EXCH_EFFECT_ID
           , ACS_GAIN_EXCH_EFFECT_ID
           , ACS_LOSS_EXCH_COMP_ID
           , ACS_GAIN_EXCH_COMP_ID
           , 0
           , 0
           , FIN_BASE_PRICE
           , FIN_ROUNDED_AMOUNT
           , C_ROUND_TYPE
           , C_PRICE_METHOD
           , ACS_PJ_COMP_LOSS_ID
           , ACS_PJ_EFF_GAIN_ID
           , ACS_PJ_COMP_GAIN_ID
           , ACS_PF_EFF_GAIN_ID
           , ACS_PF_COMP_LOSS_ID
           , ACS_PF_COMP_GAIN_ID
           , ACS_CDA_EFF_LOSS_ID
           , ACS_CDA_EFF_GAIN_ID
           , ACS_CDA_COMP_LOSS_ID
           , ACS_PJ_EFF_LOSS_ID
           , ACS_PF_EFF_LOSS_ID
           , ACS_CDA_COMP_GAIN_ID
           , FIN_EURO_FROM
           , FIN_EURO_RATE
           , ACS_PAY_EFF_GAIN_ID
           , ACS_PAY_EFF_LOSS_ID
           , ACS_PAY_PJ_EFF_LOSS_ID
           , ACS_PAY_PJ_EFF_GAIN_ID
           , ACS_PAY_PF_EFF_LOSS_ID
           , ACS_PAY_PF_EFF_GAIN_ID
           , ACS_PAY_CDA_EFF_LOSS_ID
           , ACS_PAY_CDA_EFF_GAIN_ID
           , C_ROUND_TYPE_DOC
           , FIN_ROUNDED_AMOUNT_DOC
           , ACS_GAIN_EXCH_DEBT_ID
           , ACS_LOSS_EXCH_DEBT_ID
           , ACS_PJ_LOSS_EXCH_DEBT_ID
           , ACS_PJ_GAIN_EXCH_DEBT_ID
           , ACS_PF_GAIN_EXCH_DEBT_ID
           , ACS_PF_LOSS_EXCH_DEBT_ID
           , ACS_CDA_GAIN_EXCH_DEBT_ID
           , ACS_CDA_LOSS_EXCH_DEBT_ID
           , ACS_GAIN_EXCH_EFFECT_F_ID
           , ACS_CDA_EFF_GAIN_F_ID
           , ACS_PF_EFF_GAIN_F_ID
           , ACS_PJ_EFF_GAIN_F_ID
           , ACS_LOSS_EXCH_EFFECT_F_ID
           , ACS_CDA_EFF_LOSS_F_ID
           , ACS_PF_EFF_LOSS_F_ID
           , ACS_PJ_EFF_LOSS_F_ID
           , ACS_PAY_EFF_GAIN_F_ID
           , ACS_PAY_CDA_EFF_GAIN_F_ID
           , ACS_PAY_PF_EFF_GAIN_F_ID
           , ACS_PAY_PJ_EFF_GAIN_F_ID
           , ACS_PAY_EFF_LOSS_F_ID
           , ACS_PAY_CDA_EFF_LOSS_F_ID
           , ACS_PAY_PF_EFF_LOSS_F_ID
           , ACS_PAY_PJ_EFF_LOSS_F_ID
           , FIN_VALID_TO
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , null
           , A_CONFIRM
           , A_RECLEVEL
           , A_RECSTATUS
        from ACS_FINANCIAL_CURRENCY
       where ACS_FINANCIAL_CURRENCY_ID = pSourceId;
  end DuplicateFinCurrency;

  /**
  * Description
  *        Procédure de copie des méthodes de compte par défaut
  */
  procedure DuplicateDefaultAccount(
    pSourceId     in     ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , pDuplicatedID out    ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  )
  is
    vDupDefAccValID ACS_DEF_ACCOUNT_VALUES.ACS_DEF_ACCOUNT_VALUES_ID%type;

    procedure DuplicateDefMovSql(
      pSourceId       ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
    , pDupDefAccValID ACS_DEF_ACCOUNT_VALUES.ACS_DEF_ACCOUNT_VALUES_ID%type
    , pFieldName      varchar2
    )
    is
      vSql                 varchar2(4000);
      vNewDefMovementSqlId ACS_DEF_MOVEMENT_SQL.ACS_DEF_MOVEMENT_SQL_ID%type;
      vSrcDefMovementSqlId ACS_DEF_MOVEMENT_SQL.ACS_DEF_MOVEMENT_SQL_ID%type;
    begin
      /* Recherche du mouvement pour la colonne pFieldName
         Création d'un mouvement selon le mouvement source
         Mise à jour de la table ACS_DEF_ACCOUNT_VALUES avec le nouveau mouvement créé pour la colonne pFieldName
      */
      vSql  :=
        'select ' || pFieldName
        || ' from ACS_DEF_ACCOUNT_VALUES where ACS_DEFAULT_ACCOUNT_ID = :ACS_DEFAULT_ACCOUNT_ID';

      execute immediate vSql
                   into vSrcDefMovementSqlId
                  using pSourceId;

      if vSrcDefMovementSqlId is not null then
        -- Recherche ID de mouvement
        select INIT_ID_SEQ.nextval
          into vNewDefMovementSqlId
          from dual;

        -- Création d'un mouvement
        vSql  :=
          'insert into ACS_DEF_MOVEMENT_SQL(ACS_DEF_MOVEMENT_SQL_ID, MOV_SQL)' ||
          ' select :NEW_ACS_DEF_MOVEMENT_SQL_ID, MOV_SQL FROM ACS_DEF_MOVEMENT_SQL where ACS_DEF_MOVEMENT_SQL_ID = :SRC_ACS_DEF_MOVEMENT_SQL_ID';

        execute immediate vSql
                    using vNewDefMovementSqlId, vSrcDefMovementSqlId;

        -- Mise à jour de la table des valeurs avec le nouveau mouvement
        vSql  :=
          'update ACS_DEF_ACCOUNT_VALUES set ' ||
          pFieldName ||
          ' = :NEW_ACS_DEF_MOVEMENT_SQL_ID where ACS_DEF_ACCOUNT_VALUES_ID = :ACS_DEF_ACCOUNT_VALUES_ID';

        execute immediate vSql
                    using vNewDefMovementSqlId, pDupDefAccValID;
      end if;
    end DuplicateDefMovSql;
  begin
    --Réception d'un nouvel Id de méthode
    select INIT_ID_SEQ.nextval
      into pDuplicatedID
      from dual;

    -- Copie de la méthode source
    insert into ACS_DEFAULT_ACCOUNT
                (ACS_DEFAULT_ACCOUNT_ID
               , C_ADMIN_DOMAIN
               , C_DEFAULT_ELEMENT_TYPE
               , DEF_DESCR
               , DEF_COMMENT
               , DEF_CONDITION
               , DEF_DEFAULT
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select pDuplicatedID
           , C_ADMIN_DOMAIN
           , C_DEFAULT_ELEMENT_TYPE
           , DEF_DESCR
           , DEF_COMMENT
           , DEF_CONDITION
           , 0
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
        from ACS_DEFAULT_ACCOUNT
       where ACS_DEFAULT_ACCOUNT_ID = pSourceId;

    --Copie des valeurs de la méthode
    --Les mouvements sont créés après la copie
    select INIT_ID_SEQ.nextval
      into vDupDefAccValID
      from dual;

    insert into ACS_DEF_ACCOUNT_VALUES
                (ACS_DEF_ACCOUNT_VALUES_ID
               , ACS_DEFAULT_ACCOUNT_ID
               , DEF_SINCE
               , DEF_TO
               , DEF_FIN_ACCOUNT
               , DEF_DIV_ACCOUNT
               , DEF_CDA_ACCOUNT
               , DEF_PF_ACCOUNT
               , DEF_PJ_ACCOUNT
               , DEF_QTY_ACCOUNT
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , ACS_SQL_ACC_ID
               , ACS_SQL_DIV_ID
               , ACS_SQL_CPN_ID
               , ACS_SQL_CDA_ID
               , ACS_SQL_PJ_ID
               , ACS_SQL_PF_ID
               , ACS_SQL_QTY_ID
               , ACS_HRM_PERSON_SQL_ID
               , ACS_NUMBER1_SQL_ID
               , ACS_NUMBER2_SQL_ID
               , ACS_NUMBER3_SQL_ID
               , ACS_NUMBER4_SQL_ID
               , ACS_NUMBER5_SQL_ID
               , ACS_TEXT1_SQL_ID
               , ACS_TEXT2_SQL_ID
               , ACS_TEXT3_SQL_ID
               , ACS_TEXT4_SQL_ID
               , ACS_TEXT5_SQL_ID
               , ACS_FREE1_SQL_ID
               , ACS_FREE2_SQL_ID
               , ACS_FREE3_SQL_ID
               , ACS_FREE4_SQL_ID
               , ACS_FREE5_SQL_ID
               , DEF_HRM_PERSON
               , DEF_NUMBER1
               , DEF_NUMBER2
               , DEF_NUMBER3
               , DEF_NUMBER4
               , DEF_NUMBER5
               , DEF_TEXT1
               , DEF_TEXT2
               , DEF_TEXT3
               , DEF_TEXT4
               , DEF_TEXT5
               , DEF_DIC_IMP_FREE1
               , DEF_DIC_IMP_FREE2
               , DEF_DIC_IMP_FREE3
               , DEF_DIC_IMP_FREE4
               , DEF_DIC_IMP_FREE5
               , DEF_CPN_ACCOUNT
                )
      select vDupDefAccValID
           , pDuplicatedId
           , DEF_SINCE
           , DEF_TO
           , DEF_FIN_ACCOUNT
           , DEF_DIV_ACCOUNT
           , DEF_CDA_ACCOUNT
           , DEF_PF_ACCOUNT
           , DEF_PJ_ACCOUNT
           , DEF_QTY_ACCOUNT
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
           , null   --ACS_SQL_ACC_ID
           , null   --ACS_SQL_DIV_ID
           , null   --ACS_SQL_CPN_ID
           , null   --ACS_SQL_CDA_ID
           , null   --ACS_SQL_PJ_ID
           , null   --ACS_SQL_PF_ID
           , null   --ACS_SQL_QTY_ID
           , null   --ACS_HRM_PERSON_SQL_ID
           , null   --ACS_NUMBER1_SQL_ID
           , null   --ACS_NUMBER2_SQL_ID
           , null   --ACS_NUMBER3_SQL_ID
           , null   --ACS_NUMBER4_SQL_ID
           , null   --ACS_NUMBER5_SQL_ID
           , null   --ACS_TEXT1_SQL_ID
           , null   --ACS_TEXT2_SQL_ID
           , null   --ACS_TEXT3_SQL_ID
           , null   --ACS_TEXT4_SQL_ID
           , null   --ACS_TEXT5_SQL_ID
           , null   --ACS_FREE1_SQL_ID
           , null   --ACS_FREE2_SQL_ID
           , null   --ACS_FREE3_SQL_ID
           , null   --ACS_FREE4_SQL_ID
           , null   --ACS_FREE5_SQL_ID
           , DEF_HRM_PERSON
           , DEF_NUMBER1
           , DEF_NUMBER2
           , DEF_NUMBER3
           , DEF_NUMBER4
           , DEF_NUMBER5
           , DEF_TEXT1
           , DEF_TEXT2
           , DEF_TEXT3
           , DEF_TEXT4
           , DEF_TEXT5
           , DEF_DIC_IMP_FREE1
           , DEF_DIC_IMP_FREE2
           , DEF_DIC_IMP_FREE3
           , DEF_DIC_IMP_FREE4
           , DEF_DIC_IMP_FREE5
           , DEF_CPN_ACCOUNT
        from ACS_DEF_ACCOUNT_VALUES
       where ACS_DEFAULT_ACCOUNT_ID = pSourceId;

    --Copie des mouvements
    -- Création et mise à jour des mouvements
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_ACC_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_DIV_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_CPN_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_CDA_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_PJ_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_PF_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_SQL_QTY_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_HRM_PERSON_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_NUMBER1_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_NUMBER2_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_NUMBER3_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_NUMBER4_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_NUMBER5_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_TEXT1_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_TEXT2_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_TEXT3_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_TEXT4_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_TEXT5_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_FREE1_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_FREE2_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_FREE3_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_FREE4_SQL_ID');
    DuplicateDefMovSql(pSourceId, vDupDefAccValID, 'ACS_FREE5_SQL_ID');
  end DuplicateDefaultAccount;

  /**
  * Description
  *        Procédure de copie des méthodes de déplacement de compte
  */
  procedure DuplicateDefaultAccMov(
    pSourceId     in     ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type
  , pDuplicatedID out    ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type
  )
  is
    vDupDefAccMovValID ACS_DEF_ACC_MOV_VALUES.ACS_DEF_ACC_MOV_VALUES_ID%type;

    procedure DuplicateDefAccMovSql(
      pSourceId          ACS_DEF_ACC_MOVEMENT.ACS_DEF_ACC_MOVEMENT_ID%type
    , pDupDefAccMovValID ACS_DEF_ACC_MOV_VALUES.ACS_DEF_ACC_MOV_VALUES_ID%type
    , pFieldName         varchar2
    )
    is
      vSql                 varchar2(4000);
      vNewDefMovementSqlId ACS_DEF_MOVEMENT_SQL.ACS_DEF_MOVEMENT_SQL_ID%type;
      vSrcDefMovementSqlId ACS_DEF_MOVEMENT_SQL.ACS_DEF_MOVEMENT_SQL_ID%type;
    begin
      /* Recherche du mouvement pour la colonne pFieldName
         Création d'un mouvement selon le mouvement source
         Mise à jour de la table ACS_DEF_ACCOUNT_VALUES avec le nouveau mouvement créé pour la colonne pFieldName
      */
      vSql  :=
        'select ' ||
        pFieldName ||
        ' from ACS_DEF_ACC_MOV_VALUES where ACS_DEF_ACC_MOVEMENT_ID = :ACS_DEF_ACC_MOVEMENT_ID';

      execute immediate vSql
                   into vSrcDefMovementSqlId
                  using pSourceId;

      if vSrcDefMovementSqlId is not null then
        -- Recherche ID de mouvement
        select INIT_ID_SEQ.nextval
          into vNewDefMovementSqlId
          from dual;

        -- Création d'un mouvement
        vSql  :=
          'insert into ACS_DEF_MOVEMENT_SQL(ACS_DEF_MOVEMENT_SQL_ID, MOV_SQL)' ||
          ' select :NEW_ACS_DEF_MOVEMENT_SQL_ID, MOV_SQL FROM ACS_DEF_MOVEMENT_SQL where ACS_DEF_MOVEMENT_SQL_ID = :SRC_ACS_DEF_MOVEMENT_SQL_ID';

        execute immediate vSql
                    using vNewDefMovementSqlId, vSrcDefMovementSqlId;

        -- Mise à jour de la table des valeurs avec le nouveau mouvement
        vSql  :=
          'update ACS_DEF_ACC_MOV_VALUES set ' ||
          pFieldName ||
          ' = :NEW_ACS_DEF_MOVEMENT_SQL_ID where ACS_DEF_ACC_MOV_VALUES_ID = :ACS_DEF_ACC_MOV_VALUES_ID';

        execute immediate vSql
                    using vNewDefMovementSqlId, pDupDefAccMovValID;
      end if;
    end DuplicateDefAccMovSql;
  begin
    --Réception d'un nouvel Id de méthode
    select INIT_ID_SEQ.nextval
      into pDuplicatedID
      from dual;

    -- Copie de la méthode source
    insert into ACS_DEF_ACC_MOVEMENT
                (ACS_DEF_ACC_MOVEMENT_ID
               , C_ACTOR
               , C_ADMIN_DOMAIN
               , C_DEFAULT_ELEMENT_TYPE
               , MOV_DESCR
               , MOV_COMMENT
               , MOV_CONDITION
               , MOV_CONDITION_ELEMENT
               , MOV_CUMUL
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select pDuplicatedID
           , C_ACTOR
           , C_ADMIN_DOMAIN
           , C_DEFAULT_ELEMENT_TYPE
           , MOV_DESCR
           , MOV_COMMENT
           , MOV_CONDITION
           , MOV_CONDITION_ELEMENT
           , MOV_CUMUL
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
        from ACS_DEF_ACC_MOVEMENT
       where ACS_DEF_ACC_MOVEMENT_ID = pSourceId;

    --Copie des valeurs de la méthode
    --Les mouvements sont créés après la copie
    select INIT_ID_SEQ.nextval
      into vDupDefAccMovValID
      from dual;

    insert into ACS_DEF_ACC_MOV_VALUES
                (ACS_DEF_ACC_MOV_VALUES_ID
               , ACS_DEF_ACC_MOVEMENT_ID
               , MOV_SINCE
               , MOV_TO
               , MOV_ACCOUNT_VALUE
               , MOV_DIVISION_VALUE
               , MOV_CPN_VALUE
               , MOV_CDA_VALUE
               , MOV_PF_VALUE
               , MOV_PJ_VALUE
               , MOV_QTY_VALUE
               , ACS_SQL_ACC_ID
               , ACS_SQL_DIV_ID
               , ACS_SQL_CPN_ID
               , ACS_SQL_CDA_ID
               , ACS_SQL_PF_ID
               , ACS_SQL_PJ_ID
               , ACS_SQL_QTY_ID
               , A_CONFIRM
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , ACS_HRM_PERSON_SQL_ID
               , ACS_NUMBER1_SQL_ID
               , ACS_NUMBER2_SQL_ID
               , ACS_NUMBER3_SQL_ID
               , ACS_NUMBER4_SQL_ID
               , ACS_NUMBER5_SQL_ID
               , ACS_TEXT1_SQL_ID
               , ACS_TEXT2_SQL_ID
               , ACS_TEXT3_SQL_ID
               , ACS_TEXT4_SQL_ID
               , ACS_TEXT5_SQL_ID
               , ACS_FREE1_SQL_ID
               , ACS_FREE2_SQL_ID
               , ACS_FREE3_SQL_ID
               , ACS_FREE4_SQL_ID
               , ACS_FREE5_SQL_ID
               , MOV_HRM_PERSON
               , MOV_NUMBER1
               , MOV_NUMBER2
               , MOV_NUMBER3
               , MOV_NUMBER4
               , MOV_NUMBER5
               , MOV_TEXT1
               , MOV_TEXT2
               , MOV_TEXT3
               , MOV_TEXT4
               , MOV_TEXT5
               , MOV_DIC_IMP_FREE1
               , MOV_DIC_IMP_FREE2
               , MOV_DIC_IMP_FREE3
               , MOV_DIC_IMP_FREE4
               , MOV_DIC_IMP_FREE5
                )
      select vDupDefAccMovValID
           , pDuplicatedId
           , MOV_SINCE
           , MOV_TO
           , MOV_ACCOUNT_VALUE
           , MOV_DIVISION_VALUE
           , MOV_CPN_VALUE
           , MOV_CDA_VALUE
           , MOV_PF_VALUE
           , MOV_PJ_VALUE
           , MOV_QTY_VALUE
           , null   --ACS_SQL_ACC_ID
           , null   --ACS_SQL_DIV_ID
           , null   --ACS_SQL_CPN_ID
           , null   --ACS_SQL_CDA_ID
           , null   --ACS_SQL_PF_ID
           , null   --ACS_SQL_PJ_ID
           , null   --ACS_SQL_QTY_ID
           , A_CONFIRM
           , sysdate
           , null
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , null
           , A_RECLEVEL
           , A_RECSTATUS
           , null   --ACS_HRM_PERSON_SQL_ID
           , null   --ACS_NUMBER1_SQL_ID
           , null   --ACS_NUMBER2_SQL_ID
           , null   --ACS_NUMBER3_SQL_ID
           , null   --ACS_NUMBER4_SQL_ID
           , null   --ACS_NUMBER5_SQL_ID
           , null   --ACS_TEXT1_SQL_ID
           , null   --ACS_TEXT2_SQL_ID
           , null   --ACS_TEXT3_SQL_ID
           , null   --ACS_TEXT4_SQL_ID
           , null   --ACS_TEXT5_SQL_ID
           , null   --ACS_FREE1_SQL_ID
           , null   --ACS_FREE2_SQL_ID
           , null   --ACS_FREE3_SQL_ID
           , null   --ACS_FREE4_SQL_ID
           , null   --ACS_FREE5_SQL_ID
           , MOV_HRM_PERSON
           , MOV_NUMBER1
           , MOV_NUMBER2
           , MOV_NUMBER3
           , MOV_NUMBER4
           , MOV_NUMBER5
           , MOV_TEXT1
           , MOV_TEXT2
           , MOV_TEXT3
           , MOV_TEXT4
           , MOV_TEXT5
           , MOV_DIC_IMP_FREE1
           , MOV_DIC_IMP_FREE2
           , MOV_DIC_IMP_FREE3
           , MOV_DIC_IMP_FREE4
           , MOV_DIC_IMP_FREE5
        from ACS_DEF_ACC_MOV_VALUES
       where ACS_DEF_ACC_MOVEMENT_ID = pSourceId;

    --Copie des mouvements
    -- Création et mise à jour des mouvements
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_ACC_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_DIV_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_CPN_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_CDA_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_PJ_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_PF_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_SQL_QTY_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_HRM_PERSON_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_NUMBER1_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_NUMBER2_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_NUMBER3_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_NUMBER4_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_NUMBER5_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_TEXT1_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_TEXT2_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_TEXT3_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_TEXT4_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_TEXT5_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_FREE1_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_FREE2_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_FREE3_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_FREE4_SQL_ID');
    DuplicateDefAccMovSql(pSourceId, vDupDefAccMovValID, 'ACS_FREE5_SQL_ID');
  end DuplicateDefaultAccMov;
end ACS_DUPLICATE;
