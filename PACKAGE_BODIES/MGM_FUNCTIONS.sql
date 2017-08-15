--------------------------------------------------------
--  DDL for Package Body MGM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MGM_FUNCTIONS" 
is
  /**
  * procedure GetTransferCodes
  * Description  R�ception des codes de l'unit� de mesure
  **/
  procedure GetTransferCodes(pTransferUnitId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,           /*Unit� de mesure    */
                             pOrigin           in out MGM_TRANSFER_UNIT.C_MGM_UNIT_ORIGIN%type,       /* Source unit�      */
                             pExploitationType in out MGM_TRANSFER_UNIT.C_MGM_UNIT_EXPLOITATION%type  /*Type exploitation  */
                            )
  is
  begin
    begin
      /**
        La g�n�ration des valeurs par d�faut selon les unit�s de transfert appliqu�
        ne se font que pour le types saisie libre (00)
      **/
      select C_MGM_UNIT_ORIGIN, C_MGM_UNIT_EXPLOITATION
      into pOrigin, pExploitationType
      from MGM_TRANSFER_UNIT
      where MGM_TRANSFER_UNIT_ID = pTransferUnitId;
    exception
      when no_data_found then
        pOrigin           := '';
        pExploitationType := '';
    end;
  end GetTransferCodes;


  /**
  * procedure CreateTransferUnitDefaultValues
  * Description  Fonction de cr�ation des nombres d'unit�s de mesure selon
  *             les unit�s de transfert appliqu� de l'Unit� de mesure donn�
  **/
  procedure CreateTransferUnitDefValues(pTransferUnitId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,    /*Unit� de mesure    */
                                        pFinancialYearId  ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type   /*Exercice           */
                                        )
  is
    vOrigin           MGM_TRANSFER_UNIT.C_MGM_UNIT_ORIGIN%type;
    vExploitationType MGM_TRANSFER_UNIT.C_MGM_UNIT_EXPLOITATION%type;
  begin
    GetTransferCodes(pTransferUnitId,vOrigin,vExploitationType);
    /** P�riodes comptables **/
    if vExploitationType in ('2','3') then
      insert into MGM_UNIT_VALUES (
          MGM_UNIT_VALUES_ID,
          MGM_TRANSFER_UNIT_ID,
          ACS_FINANCIAL_YEAR_ID,
          ACS_PERIOD_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_PJ_ACCOUNT_ID,
          FAL_FACTORY_FLOOR_ID,
          GCO_GOOD_ID,
          MUV_NUMBER,
          A_DATECRE,
          A_IDCRE)
      select INIT_ID_SEQ.NEXTVAL,
             TYP.MGM_TRANSFER_UNIT_ID,
             PER.ACS_FINANCIAL_YEAR_ID,
             PER.ACS_PERIOD_ID,
             APP.ACS_CDA_ACCOUNT_ID,
             APP.ACS_PF_ACCOUNT_ID,
             APP.ACS_PJ_ACCOUNT_ID,
             APP.FAL_FACTORY_FLOOR_ID,
             APP.GCO_GOOD_ID,
             0,
             SYSDATE,
             PCS.PC_I_LIB_SESSION.GetUserIni
      from MGM_APPLIED_UNIT APP,
           MGM_USAGE_TYPE TYP,
           ACS_PERIOD PER
      where TYP.MGM_TRANSFER_UNIT_ID  = pTransferUnitId
        and TYP.MGM_USAGE_TYPE_ID     = APP.MGM_USAGE_TYPE_ID
        and TYP.C_USAGE_TYPE          = '1'
        and PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
        and PER.C_TYPE_PERIOD         = '2';
    /** Exercice comptable **/
    elsif vExploitationType = '4' then
      insert into MGM_UNIT_VALUES (
          MGM_UNIT_VALUES_ID,
          MGM_TRANSFER_UNIT_ID,
          ACS_FINANCIAL_YEAR_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_PJ_ACCOUNT_ID,
          FAL_FACTORY_FLOOR_ID,
          GCO_GOOD_ID,
          MUV_NUMBER,
          A_DATECRE,
          A_IDCRE)
      select INIT_ID_SEQ.NEXTVAL,
             TYP.MGM_TRANSFER_UNIT_ID,
             pFinancialYearId,
             APP.ACS_CDA_ACCOUNT_ID,
             APP.ACS_PF_ACCOUNT_ID,
             APP.ACS_PJ_ACCOUNT_ID,
             APP.FAL_FACTORY_FLOOR_ID,
             APP.GCO_GOOD_ID,
             0,
             SYSDATE,
             PCS.PC_I_LIB_SESSION.GetUserIni
      from MGM_APPLIED_UNIT APP, MGM_USAGE_TYPE TYP
      where TYP.MGM_TRANSFER_UNIT_ID  = pTransferUnitId
      AND TYP.MGM_USAGE_TYPE_ID       = APP.MGM_USAGE_TYPE_ID
      AND TYP.C_USAGE_TYPE            ='1';
    /** Sans p�riodes **/
    elsif vExploitationType = '1' then
      insert into MGM_UNIT_VALUES (
          MGM_UNIT_VALUES_ID,
          MGM_TRANSFER_UNIT_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_PJ_ACCOUNT_ID,
          FAL_FACTORY_FLOOR_ID,
          GCO_GOOD_ID,
          MUV_NUMBER,
          A_DATECRE,
          A_IDCRE)
      select INIT_ID_SEQ.NEXTVAL,
             TYP.MGM_TRANSFER_UNIT_ID,
             APP.ACS_CDA_ACCOUNT_ID,
             APP.ACS_PF_ACCOUNT_ID,
             APP.ACS_PJ_ACCOUNT_ID,
             APP.FAL_FACTORY_FLOOR_ID,
             APP.GCO_GOOD_ID,
             0,
             SYSDATE,
             PCS.PC_I_LIB_SESSION.GetUserIni
      from MGM_APPLIED_UNIT APP, MGM_USAGE_TYPE TYP
      where TYP.MGM_TRANSFER_UNIT_ID = pTransferUnitId
        and TYP.MGM_USAGE_TYPE_ID    = APP.MGM_USAGE_TYPE_ID
        and TYP.C_USAGE_TYPE = '1';
    end if;
  end CreateTransferUnitDefValues;

  /**
  * Description  Recherche d'une position de nombre d'unit� de mesure selon les axes donn�s
  **/
  function ExistUnitValuesPos(pTransferUnitId  MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,
                              pExerciseid      MGM_UNIT_VALUES.ACS_FINANCIAL_YEAR_ID%type,
                              pPeriodId        MGM_UNIT_VALUES.ACS_PERIOD_ID%type,
                              pBudVersionId    MGM_UNIT_VALUES.ACB_BUDGET_VERSION_ID%type,
                              pCdaAccId        MGM_UNIT_VALUES.ACS_CDA_ACCOUNT_ID%type,
                              pPfAccId         MGM_UNIT_VALUES.ACS_PF_ACCOUNT_ID%type,
                              pPjAccId         MGM_UNIT_VALUES.ACS_PJ_ACCOUNT_ID%type,
                              pFactoryId       MGM_UNIT_VALUES.FAL_FACTORY_FLOOR_ID%type,
                              pGoodId          MGM_UNIT_VALUES.GCO_GOOD_ID%type
                             ) return number
  is
    vResult          number(1);
  begin
    select DECODE (MAX(MGM_UNIT_VALUES_ID),NULL,0,1)
    into vResult
    from MGM_UNIT_VALUES
    where MGM_TRANSFER_UNIT_ID  = pTransferUnitId
      and ACS_FINANCIAL_YEAR_ID   = pExerciseId
      and ( ((pPeriodId <> 0) and (ACS_PERIOD_ID = pPeriodId)) or
            ((pPeriodId  = 0) and (ACS_PERIOD_ID is null))
           )
      and ( ((pBudVersionId <> 0) and (ACB_BUDGET_VERSION_ID = pBudVersionId)) or
            ((pBudVersionId  = 0) and (ACB_BUDGET_VERSION_ID is null))
           )
      and ( ((pCdaAccId <> 0 ) and (ACS_CDA_ACCOUNT_ID = pCdaAccId)) or
            ((pCdaAccId  = 0 ) and (ACS_CDA_ACCOUNT_ID is null))
           )
      and ( ((pPfAccId <> 0 )  and (ACS_PF_ACCOUNT_ID = pPfAccId)) or
            ((pPfAccId  = 0 )  and (ACS_PF_ACCOUNT_ID is null))
           )
      and ( ((pPJAccId <> 0 )  and (ACS_PJ_ACCOUNT_ID = pPJAccId)) or
            ((pPJAccId  = 0 )  and (ACS_PJ_ACCOUNT_ID is null))
           )
      and ( ((pFactoryId <> 0 )  and (FAL_FACTORY_FLOOR_ID = pFactoryId)) or
            ((pFactoryId  = 0 )  and (FAL_FACTORY_FLOOR_ID is null))
           )
      and ( ((pGoodId <> 0 )  and (GCO_GOOD_ID = pGoodId)) or
            ((pGoodId  = 0 )  and (GCO_GOOD_ID is null))
           );
    return vResult;
  end  ExistUnitValuesPos;

  /**
  * Description  Ajout / cr�ation d'une position de valeur d'unit� de mesure
  **/
  procedure CreateUnitValuesPosition(pTransferUnitId  MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,
                                     pExerciseid      MGM_UNIT_VALUES.ACS_FINANCIAL_YEAR_ID%type,
                                     pPeriodId        MGM_UNIT_VALUES.ACS_PERIOD_ID%type,
                                     pBudVersionId    MGM_UNIT_VALUES.ACB_BUDGET_VERSION_ID%type,
                                     pCdaAccId        MGM_UNIT_VALUES.ACS_CDA_ACCOUNT_ID%type,
                                     pPfAccId         MGM_UNIT_VALUES.ACS_PF_ACCOUNT_ID%type,
                                     pPjAccId         MGM_UNIT_VALUES.ACS_PJ_ACCOUNT_ID%type,
                                     pFactoryId       MGM_UNIT_VALUES.FAL_FACTORY_FLOOR_ID%type,
                                     pGoodId          MGM_UNIT_VALUES.GCO_GOOD_ID%type,
                                     pMuvNumber       MGM_UNIT_VALUES.MUV_NUMBER%type
                                    )
  is
  begin
    insert into MGM_UNIT_VALUES(MGM_UNIT_VALUES_ID,
                                MGM_TRANSFER_UNIT_ID,
                                ACS_FINANCIAL_YEAR_ID,
                                ACS_PERIOD_ID,
                                ACS_CDA_ACCOUNT_ID,
                                ACS_PF_ACCOUNT_ID,
                                ACS_PJ_ACCOUNT_ID,
                                ACB_BUDGET_VERSION_ID,
                                FAL_FACTORY_FLOOR_ID,
                                GCO_GOOD_ID,
                                MUV_NUMBER,
                                A_DATECRE,
                                A_IDCRE)
    select INIT_ID_SEQ.nextval,
           pTransferUnitId,
           pExerciseid,
           pPeriodId,
           decode(pCdaAccId     ,0,nulL,pCdaAccId    ),
           decode(pPfAccId      ,0,nulL,pPfAccId     ),
           decode(pPjAccId      ,0,nulL,pPjAccId     ),
           decode(pBudVersionId ,0,nulL,pBudVersionId),
           decode(pFactoryId    ,0,nulL,pFactoryId   ),
           decode(pGoodId       ,0,nulL,pGoodId      ),
           pMuvNumber,
           SYSDATE,
           PCS.PC_I_LIB_SESSION.GetUserIni
    from  dual;
  end CreateUnitValuesPosition;

  /**
  * Description  Modification du nombre de la position qui correpondant aux axes donn�s
  **/
  procedure UpdateUnitValuesNumber(pTransferUnitId  MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,
                                   pExerciseid      MGM_UNIT_VALUES.ACS_FINANCIAL_YEAR_ID%type,
                                   pPeriodId        MGM_UNIT_VALUES.ACS_PERIOD_ID%type,
                                   pBudVersionId    MGM_UNIT_VALUES.ACB_BUDGET_VERSION_ID%type,
                                   pCdaAccId        MGM_UNIT_VALUES.ACS_CDA_ACCOUNT_ID%type,
                                   pPfAccId         MGM_UNIT_VALUES.ACS_PF_ACCOUNT_ID%type,
                                   pPjAccId         MGM_UNIT_VALUES.ACS_PJ_ACCOUNT_ID%type,
                                   pFactoryId       MGM_UNIT_VALUES.FAL_FACTORY_FLOOR_ID%type,
                                   pGoodId          MGM_UNIT_VALUES.GCO_GOOD_ID%type,
                                   pMuvNumber       MGM_UNIT_VALUES.MUV_NUMBER%type
                                   )
  is
  begin
    update MGM_UNIT_VALUES
    set MUV_NUMBER = pMuvNumber,
        A_DATEMOD  = SYSDATE,
        A_IDMOD    = PCS.PC_I_LIB_SESSION.GetUserIni
    where MGM_TRANSFER_UNIT_ID    = pTransferUnitId
      and ACS_FINANCIAL_YEAR_ID   = pExerciseId
      and ( ((pPeriodId <> 0) and (ACS_PERIOD_ID = pPeriodId)) or
            ((pPeriodId  = 0) and (ACS_PERIOD_ID is null))
           )
      and ( ((pBudVersionId <> 0) and (ACB_BUDGET_VERSION_ID = pBudVersionId)) or
            ((pBudVersionId  = 0) and (ACB_BUDGET_VERSION_ID is null))
           )
      and ( ((pCdaAccId <> 0 ) and (ACS_CDA_ACCOUNT_ID = pCdaAccId)) or
            ((pCdaAccId  = 0 ) and (ACS_CDA_ACCOUNT_ID is null))
           )
      and ( ((pPfAccId <> 0 )  and (ACS_PF_ACCOUNT_ID = pPfAccId)) or
            ((pPfAccId  = 0 )  and (ACS_PF_ACCOUNT_ID is null))
           )
      and ( ((pPJAccId <> 0 )  and (ACS_PJ_ACCOUNT_ID = pPJAccId)) or
            ((pPJAccId  = 0 )  and (ACS_PJ_ACCOUNT_ID is null))
           )
      and ( ((pFactoryId <> 0 )  and (FAL_FACTORY_FLOOR_ID = pFactoryId)) or
            ((pFactoryId  = 0 )  and (FAL_FACTORY_FLOOR_ID is null))
           )
      and ( ((pGoodId <> 0 )  and (GCO_GOOD_ID = pGoodId)) or
            ((pGoodId  = 0 )  and (GCO_GOOD_ID is null))
           );
  end UpdateUnitValuesNumber;

end MGM_FUNCTIONS;
