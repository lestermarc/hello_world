--------------------------------------------------------
--  DDL for Package Body COM_DEMAT_MAIN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_DEMAT_MAIN" 
is
  /**
   * Description
   *   procedure générique initialisant tous les XMLs de la société prêt à être traités
   */
  procedure call_init_proc(aExchangeDataKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type)
  is
    p_sysExchangeData  PCS.PC_EXCHANGE_SYSTEM%rowtype;
    p_currDataId  PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type;

    cursor cr_ExchangeDataIn(
        c_SysExchangeDataId PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type)
    is
      select EDI.PC_EXCHANGE_DATA_IN_ID
        from PCS.PC_EXCHANGE_DATA_IN EDI
       where EDI.PC_EXCHANGE_SYSTEM_ID = c_SysExchangeDataId
         and EDI.C_EDI_PROCESS_STATUS in('01', '02')
      order by EDI.PC_EXCHANGE_DATA_IN_ID asc;

  begin

    -- Récupération du système d'échange de données
    p_sysExchangeData := p_getSysExchange(aExchangeDataKey);

    -- Récupération de l'ensemble des documents XML entrants de la société active à traités
    open cr_ExchangeDataIn(p_sysExchangeData.PC_EXCHANGE_SYSTEM_ID);
    loop
      fetch cr_ExchangeDataIn into p_currDataId;
      exit when cr_ExchangeDataIn%notfound;

      begin
        -- Traiter le XML courant
        p_launch_proc(p_currDataId, p_sysExchangeData.ECS_PROC_XML_INIT_DATAS);
        commit;

      exception when others then rollback;
      end;

    end loop;
    close cr_ExchangeDataIn;

  end call_init_proc;

  /**
   * Description
   *   procedure générique intégrant tous les XMLs de la société prêt à être traités
   */
  procedure call_integration_proc(aExchangeDataKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type)
  is
    p_sysExchangeData   PCS.PC_EXCHANGE_SYSTEM%rowtype;
    p_currDataId        PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type;
    p_DocInterfaceId    DOC_INTERFACE.DOC_INTERFACE_ID%type;

    cursor cr_FinDataIn(
        c_SysExchangeDataId PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type
      , c_CompanyId PCS.PC_COMP.PC_COMP_ID%type)
    is
      select   EDI.PC_EXCHANGE_DATA_IN_ID
          from PCS.PC_EXCHANGE_DATA_IN EDI
         where EDI.PC_EXCHANGE_SYSTEM_ID = c_SysExchangeDataId
           and (    (    EDI.PC_COMP_ACT_ID = c_CompanyId
                     and EDI.PC_COMP_DOC_ID is null)
                or (    EDI.PC_COMP_ACT_ID is not null
                    and EDI.PC_COMP_DOC_ID = c_CompanyId)
               )
           and EDI.ACI_DOCUMENT_ID is null
           and EDI.C_EDI_STATUS_ACT = '0'
      order by EDI.PC_EXCHANGE_DATA_IN_ID asc;

    cursor cr_LogDataIn(
        c_SysExchangeDataId PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type
      , c_CompanyId PCS.PC_COMP.PC_COMP_ID%type)
    is
      select   EDI.PC_EXCHANGE_DATA_IN_ID
          from PCS.PC_EXCHANGE_DATA_IN EDI
         where EDI.PC_EXCHANGE_SYSTEM_ID = c_SysExchangeDataId
           and EDI.PC_COMP_DOC_ID = c_CompanyId
           and (    (EDI.PC_COMP_ACT_ID is null)
                or (    EDI.PC_COMP_ACT_ID is not null
                    and EDI.ACT_DOCUMENT_ID is not null) )
           and EDI.C_EDI_STATUS_DOC = '0'
      order by EDI.PC_EXCHANGE_DATA_IN_ID asc;

  begin
    -- Récupération du système d'échange de données
    p_sysExchangeData := p_getSysExchange(aExchangeDataKey);

    -- Récupération des documents XML finance à traités
    open cr_FinDataIn(p_sysExchangeData.PC_EXCHANGE_SYSTEM_ID, PCS.PC_I_LIB_SESSION.getCompanyId);
    loop
      fetch cr_FinDataIn into p_currDataId;
      exit when cr_FinDataIn%notfound;

      begin
        -- Lancer la procédure d'intégration finance
        p_launch_proc(p_currDataId, p_sysExchangeData.ECS_PROC_FIN_INTEGRATION);
        commit;

      exception when others then rollback;
      end;
    end loop;
    close cr_FinDataIn;

    -- Récupération des documents XML logistique à traités
    open cr_LogDataIn(p_sysExchangeData.PC_EXCHANGE_SYSTEM_ID, PCS.PC_I_LIB_SESSION.getCompanyId);
    loop
      fetch cr_LogDataIn into p_currDataId;
      exit when cr_LogDataIn%notfound;

      begin
        -- Lancer la fonction d'intégration logistique
        p_DocInterfaceId := p_launch_func(p_currDataId, p_sysExchangeData.ECS_PROC_LOG_INTEGRATION);

        if p_DocInterfaceId is not null and p_sysExchangeData.ECS_PROC_LOG_MATCHING is not null then
          -- Lancer la procédure de rapprochement
          p_launch_proc(p_currDataId, p_sysExchangeData.ECS_PROC_LOG_MATCHING);
        end if;

        commit;
      exception when others then rollback;
      end;
    end loop;
    close cr_LogDataIn;
  end call_integration_proc;

  /**
   * Description
   *   retourne l'id du système d'échange de données en fonctiond de la clé
   */
  function p_getSysExchange(aExchangeDataKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type)
    return PCS.PC_EXCHANGE_SYSTEM%rowtype
  is
    result  PCS.PC_EXCHANGE_SYSTEM%rowtype;
  begin
    -- Récupération du système d'échange de données
    select *
      into result
      from PCS.PC_EXCHANGE_SYSTEM ECS
     where ECS.C_ECS_BSP = '10'
       and ECS.ECS_KEY = aExchangeDataKey
       and ECS.PC_COMP_ID = PCS.PC_I_LIB_SESSION.getCompanyId;

    return result;
  end p_getSysExchange;

  /**
   * Description
   *   procedure privée lockant le document courrant et appelant la procédure
   *   passée en paramètre
   */
  procedure p_launch_proc(
      aCurrDataId in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type
    , aSysDataInitProc in varchar2)
  is
    pTmpId  PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type;
  begin
    -- Tentative de vérouillage du document XML
    select     EDI.PC_EXCHANGE_DATA_IN_ID
          into pTmpId
          from PCS.PC_EXCHANGE_DATA_IN EDI
         where EDI.PC_EXCHANGE_DATA_IN_ID = aCurrDataId
    for update nowait;

    -- Appel à la procédure
    execute immediate
      'begin '||
        aSysDataInitProc||'('||aCurrDataId||');'||
      'end;';

    -- Si on a pas réussi à vérouiller, on ressort sans rien faire
    exception
    when RESOURCE_BUSY then null;
  end p_launch_proc;

  /**
   *   fonction privée lockant le document courrant et appelant la fonction
   *   passée en paramètre
   */
  function p_launch_func(
      aCurrDataId in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type
    , aSysDataInitProc in varchar2)
    return number
  is
    pTmpId  PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type;
    result number(12);
  begin
    -- Tentative de vérouillage du document XML
    select     EDI.PC_EXCHANGE_DATA_IN_ID
          into pTmpId
          from PCS.PC_EXCHANGE_DATA_IN EDI
         where EDI.PC_EXCHANGE_DATA_IN_ID = aCurrDataId
    for update nowait;

    -- Appel à la fonction
    execute immediate
      'begin '||
        ':result := '||aSysDataInitProc||'('||aCurrDataId||');'||
      'end;' using out result;

    return result;

    -- Si on a pas réussi à vérouiller, on ressort sans rien faire
    exception
    when RESOURCE_BUSY then return null;
  end p_launch_func;

end COM_DEMAT_MAIN;
