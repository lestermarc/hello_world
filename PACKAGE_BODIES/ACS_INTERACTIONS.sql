--------------------------------------------------------
--  DDL for Package Body ACS_INTERACTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_INTERACTIONS" 
is

  procedure InsertMgmInteraction(pCPNAccountId  ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type,
                                 pSubSet        ACS_SUB_SET.C_SUB_SET%type,
                                 pLinkAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    vMGMId ACS_MGM_INTERACTION.ACS_MGM_INTERACTION_ID%type;
  begin
    begin
      /*Réception d'un nouvel Id */
      select INIT_ID_SEQ.NEXTVAL
      into vMGMId
      from dual;

      if pSubSet ='CDA' then
        INSERT INTO ACS_MGM_INTERACTION(
           ACS_MGM_INTERACTION_ID
         , ACS_CPN_ACCOUNT_ID
         , ACS_CDA_ACCOUNT_ID
         , MGM_DEFAULT
         , A_DATECRE
         , A_IDCRE)
        VALUES (
           vMGMId
         , pCPNAccountId
         , pLinkAccountId
         , 0
         , SYSDATE
         , PCS.PC_I_LIB_SESSION.GetUserIni);
       elsif pSubSet ='COS' then
        INSERT INTO ACS_MGM_INTERACTION(
           ACS_MGM_INTERACTION_ID
         , ACS_CPN_ACCOUNT_ID
         , ACS_PF_ACCOUNT_ID
         , MGM_DEFAULT
         , A_DATECRE
         , A_IDCRE)
        VALUES (
           vMGMId
         , pCPNAccountId
         , pLinkAccountId
         , 0
         , SYSDATE
         , PCS.PC_I_LIB_SESSION.GetUserIni);
       elsif pSubSet ='PRO' then
        INSERT INTO ACS_MGM_INTERACTION(
           ACS_MGM_INTERACTION_ID
         , ACS_CPN_ACCOUNT_ID
         , ACS_PJ_ACCOUNT_ID
         , MGM_DEFAULT
         , A_DATECRE
         , A_IDCRE)
        VALUES (
           vMGMId
         , pCPNAccountId
         , pLinkAccountId
         , 0
         , SYSDATE
         , PCS.PC_I_LIB_SESSION.GetUserIni);
       end if;
    exception
      when others then
        vMGMId := 0;
        Raise;
    end;
  end InsertMgmInteraction;


  procedure DeleteMgmInteraction(pCPNAccountId  ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type,
                                 pSubSet        ACS_SUB_SET.C_SUB_SET%type,
                                 pLinkAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
  begin
    begin
      if pSubSet ='CDA' then
        DELETE FROM ACS_MGM_INTERACTION
        WHERE ACS_CPN_ACCOUNT_ID = pCPNAccountId
          AND ACS_CDA_ACCOUNT_ID = pLinkAccountId;
       elsif pSubSet ='COS' then
        DELETE FROM ACS_MGM_INTERACTION
        WHERE ACS_CPN_ACCOUNT_ID = pCPNAccountId
          AND ACS_PF_ACCOUNT_ID = pLinkAccountId;
       elsif pSubSet ='PRO' then
        DELETE FROM ACS_MGM_INTERACTION
        WHERE ACS_CPN_ACCOUNT_ID = pCPNAccountId
          AND ACS_PJ_ACCOUNT_ID  = pLinkAccountId;
       end if;
    exception
      when others then
        Raise;
    end;
  end DeleteMgmInteraction;


  procedure InsertFinInteraction(pFinAccountId  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                 pDivAccountId  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type)
  is
    vFinIntId ACS_INTERACTION.ACS_INTERACTION_ID%type;
  begin
    begin
      /*Réception d'un nouvel Id */
      select INIT_ID_SEQ.NEXTVAL
      into vFinIntId
      from dual;

      INSERT INTO ACS_INTERACTION(
         ACS_INTERACTION_ID
       , ACS_FINANCIAL_ACCOUNT_ID
       , ACS_DIVISION_ACCOUNT_ID
       , INT_PAIR_DEFAULT
       , A_DATECRE
       , A_IDCRE)
      VALUES (
         vFinIntId
       , pFinAccountId
       , pDivAccountId
       , 0
       , SYSDATE
       , PCS.PC_I_LIB_SESSION.GetUserIni);
    exception
      when others then
        vFinIntId := 0;
        Raise;
    end;
  end InsertFinInteraction;


  procedure DeleteFinInteraction(pFinAccountId  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                 pDivAccountId  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type)

  is
  begin
    begin
      DELETE FROM ACS_INTERACTION
      WHERE ACS_FINANCIAL_ACCOUNT_ID = pFinAccountId
        AND ACS_DIVISION_ACCOUNT_ID = pDivAccountId;
    exception
      when others then
        Raise;
    end;
  end DeleteFinInteraction;

  /**
  * function InsertFinMgmInteraction
  * Description : Ajout d'enregistrement d'interaction financière
  */
  procedure InsertFinMgmInteraction(pFinAccountId  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                    pCpnAccountId  ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type)
  is
  begin
    insert into ACS_FIN_MGM_INTERACTION(
       ACS_FIN_MGM_INTERACTION_ID
     , ACS_FINANCIAL_ACCOUNT_ID
     , ACS_CPN_ACCOUNT_ID
     , FMI_DEFAULT
     , FMI_VALID_SINCE
     , FMI_VALID_TO
     , A_DATECRE
     , A_IDCRE)
    values (
       (select GetNewId from dual)
     , pFinAccountId
     , pCpnAccountId
     , 0
     , null
     , null
     , SYSDATE
     , PCS.PC_I_LIB_SESSION.GetUserIni);
  end InsertFinMgmInteraction;

  /**
  * function DeleteFinMgmInteraction
  * Description : Suppression d'enregistrement d'interaction financière
  */
  procedure DeleteFinMgmInteraction(pFinAccountId  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                    pCpnAccountId  ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type)
  is
  begin
    delete
      from ACS_FIN_MGM_INTERACTION
     where ACS_FINANCIAL_ACCOUNT_ID = pFinAccountId
       and ACS_CPN_ACCOUNT_ID = pCpnAccountId;
  end DeleteFinMgmInteraction;

  /**
  * function GetValidDivInteractedAccount
  * Description Recherche des divisions avec contrôle des interactions financières
  */
  function GetValidDivInteractedAccount(pACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type,
                                        pACS_DIVISION_ACCOUNT_ID  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type,
                                        pInteractDate             Date,
                                        pUserRights               number default 1)
             return ID_TABLE_TYPE
  is
    vExistInteract number(1) default 0;
    vResult       ID_TABLE_TYPE;
  begin
    select decode(count(0),0, 0, 1)
    into vExistInteract
    from ACS_INTERACTION INT
    where INT.ACS_FINANCIAL_ACCOUNT_ID = pACS_FINANCIAL_ACCOUNT_ID;
    if vExistInteract = 0 then --pas d'interaction
      select cast(multiset( select DIV.ACS_DIVISION_ACCOUNT_ID
                            from   ACS_ACCOUNT ACC,
                                   ACS_DIVISION_ACCOUNT DIV
                            where  DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID AND
                                   NVL(ACC.ACC_BLOCKED, 0) = 0 and
                                   (((pUserRights = 1) and exists(select 1
                                                              from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GetUserID, pInteractDate)) AUT
                                                              where AUT.COLUMN_VALUE = DIV.ACS_DIVISION_ACCOUNT_ID))
                                   or (pUserRights = 0))
                          ) as ID_TABLE_TYPE
                 )into vResult
                	from dual;
    else --Recherche des interactions valables
      select cast(multiset( select INT.ACS_DIVISION_ACCOUNT_ID
                            from   ACS_INTERACTION INT
                            where  INT.ACS_FINANCIAL_ACCOUNT_ID            = pACS_FINANCIAL_ACCOUNT_ID and
                                   decode(pACS_DIVISION_ACCOUNT_ID, 0, 0, INT.ACS_DIVISION_ACCOUNT_ID) = pACS_DIVISION_ACCOUNT_ID and
                                   ((pInteractDate between INT.INT_VALID_SINCE and INT.INT_VALID_TO) or (INT.INT_VALID_TO is null and INT.INT_VALID_SINCE is null)
                                  or (INT.INT_VALID_SINCE is null and pInteractDate <= INT.INT_VALID_TO) or (INT.INT_VALID_TO is null and pInteractDate >= INT.INT_VALID_SINCE)) and
                                   (((pUserRights = 1) and exists(select 1
                                                              from table(ACS_FUNCTION.TableDivisionsAuthorized(PCS.PC_I_LIB_SESSION.GetUserID, pInteractDate)) AUT
                                                              where AUT.COLUMN_VALUE = INT.ACS_DIVISION_ACCOUNT_ID))
                                   or (pUserRights = 0))
                          ) as ID_TABLE_TYPE
                 )into vResult
                	from dual;
    end if;
    return vResult;
  end GetValidDivInteractedAccount;

end ACS_INTERACTIONS;
