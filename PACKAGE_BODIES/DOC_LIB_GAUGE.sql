--------------------------------------------------------
--  DDL for Package Body DOC_LIB_GAUGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_GAUGE" 
is
  /**
  * Description
  *   Table function which return all possible flows for a domain and a third
  *
  */
  function GetPossibleFlows(iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for ltplFlow in (select DOC_GAUGE_FLOW_ID
                       from DOC_GAUGE_FLOW
                      where C_ADMIN_DOMAIN = iAdminDomain
                        and GCO_GOOD_ID is null
                        and (   PAC_THIRD_ID = iThirdID
                             or PAC_THIRD_ID is null) ) loop
      pipe row(ltplFlow.DOC_GAUGE_FLOW_ID);
    end loop;
  end GetPossibleFlows;

  /**********************************************************************
  * Description : Recherche l'ID du Flux actif selon un domaine et un tiers
  */
  function GetFlowID(iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    return DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type
  is
    cursor lcurFlow(
      iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type
    , iThirdID     in PAC_THIRD.PAC_THIRD_ID%type
    , lStatus      in DOC_GAUGE_FLOW.C_GAF_FLOW_STATUS%type
    )
    is
      select   DOC_GAUGE_FLOW_ID
          from DOC_GAUGE_FLOW
         where C_ADMIN_DOMAIN = iAdminDomain
           and GCO_GOOD_ID is null
           and (   PAC_THIRD_ID = iThirdID
                or PAC_THIRD_ID is null)
           and C_GAF_FLOW_STATUS = lStatus
      order by PAC_THIRD_ID nulls last;

    lParams PCS.PC_OBJECT.OBJ_PARAMS%type;
    lStatus DOC_GAUGE_FLOW.C_GAF_FLOW_STATUS%type;
    lResult DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    /*Si le paramètre d'objet "DOC_GAUGE_FLOW_TEST" existe et qu'il est = 1, lStatus vaudra 1 (flux en préparation).
      Dans tous les autres cas, lStatus vaudra 2 (flux actif)*/
    lParams  := PCS.PC_I_LIB_SESSION.GetObjectParams;

    select nvl(max(PARAM_VALUE), '2')
      into lStatus
      from (select trim(upper(substr(LINE, 1, instr(LINE, '=') - 1) ) ) PARAM_NAME
                 , trim(substr(LINE, instr(LINE, '=') + 1) ) PARAM_VALUE
              from (select EXTRACTLINE(lParams, no, ';') LINE
                      from PCS.PC_NUMBER
                     where no < 100)
             where LINE is not null)
     where PARAM_NAME = 'DOC_GAUGE_FLOW_TEST'
       and PARAM_VALUE = '1';

    --Récupération du flux
    open lcurFlow(iAdminDomain, iThirdID, lStatus);

    fetch lcurFlow
     into lResult;

    close lcurFlow;

    return lResult;
  end GetFlowID;

  /**********************************************************************
  * Description : Recherche l'ID des flux potentiels selon un domaine et un tiers (Actif ou archivé)
  */
  function GetAllPotentialFlow(iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    return varchar2
  is
    cursor lcurFlowIDs(iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type)
    is
      select DOC_GAUGE_FLOW_ID
        from DOC_GAUGE_FLOW
       where C_ADMIN_DOMAIN = iAdminDomain
         and GCO_GOOD_ID is null
         and (    (PAC_THIRD_ID = iThirdID)
              or (PAC_THIRD_ID is null) );

    ltplFlowIDs lcurFlowIDs%rowtype;
    lResult     varchar2(2000);
  begin
    lResult  := GetFlowID(iAdminDomain, iThirdID);

    open lcurFlowIDs(iAdminDomain, iThirdID);

    fetch lcurFlowIDs
     into ltplFlowIDs;

    while lcurFlowIDs%found loop
      lResult  := lResult || ',' || ltplFlowIDs.DOC_GAUGE_FLOW_ID;

      fetch lcurFlowIDs
       into ltplFlowIDs;
    end loop;

    close lcurFlowIDs;

    return lResult;
  end GetAllPotentialFlow;

  /**********************************************************************
  * Description : Recherche l'ID des flux ayant un lien entre la source et la destination spécifiées
  */
  function GetAllFlow(iGaugeSrc in DOC_GAUGE.DOC_GAUGE_ID%type, iGaugeDst in DOC_GAUGE.DOC_GAUGE_ID%type, iReceiptLink in number)
    return varchar2
  is
    cursor lcurReceiptFlowIDs(iGaugeSrc in DOC_GAUGE.DOC_GAUGE_ID%type, iGaugeDst in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAD.doc_gauge_flow_id
        from doc_gauge_flow_docum GAD
           , doc_gauge_receipt GAR
       where GAR.doc_doc_gauge_id = iGaugeSrc
         and GAR.doc_gauge_flow_docum_id = GAD.doc_gauge_flow_docum_id
         and GAD.doc_gauge_id = iGaugeDst;

    cursor lcurCopyFlowIDs(iGaugeSrc in DOC_GAUGE.DOC_GAUGE_ID%type, iGaugeDst in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAD.doc_gauge_flow_id
        from doc_gauge_flow_docum GAD
           , doc_gauge_copy GAC
       where GAC.doc_doc_gauge_id = iGaugeSrc
         and GAC.doc_gauge_flow_docum_id = GAD.doc_gauge_flow_docum_id
         and GAD.doc_gauge_id = iGaugeDst;

    ltplReceiptFlowIDs lcurReceiptFlowIDs%rowtype;
    ltplCopyFlowIDs    lcurCopyFlowIDs%rowtype;
    lResult            varchar2(2000);
  begin
    if iReceiptLink = 1 then
      open lcurReceiptFlowIDs(iGaugeSrc, iGaugeDst);

      fetch lcurReceiptFlowIDs
       into ltplReceiptFlowIDs;

      if lcurReceiptFlowIDs%found then
        lResult  := ',' || ltplReceiptFlowIDs.DOC_GAUGE_FLOW_ID;

        fetch lcurReceiptFlowIDs
         into ltplReceiptFlowIDs;

        while lcurReceiptFlowIDs%found loop
          lResult  := lResult || ',' || ltplReceiptFlowIDs.DOC_GAUGE_FLOW_ID;

          fetch lcurReceiptFlowIDs
           into ltplReceiptFlowIDs;
        end loop;

        close lcurReceiptFlowIDs;
      end if;
    else
      open lcurCopyFlowIDs(iGaugeSrc, iGaugeDst);

      fetch lcurCopyFlowIDs
       into ltplCopyFlowIDs;

      if lcurCopyFlowIDs%found then
        lResult  := ',' || ltplCopyFlowIDs.DOC_GAUGE_FLOW_ID;

        fetch lcurCopyFlowIDs
         into ltplCopyFlowIDs;

        while lcurCopyFlowIDs%found loop
          lResult  := lResult || ',' || ltplCopyFlowIDs.DOC_GAUGE_FLOW_ID;

          fetch lcurCopyFlowIDs
           into ltplCopyFlowIDs;
        end loop;

        close lcurCopyFlowIDs;
      end if;
    end if;

    return lResult;
  end getAllFlow;

  /**********************************************************************
  * Description : Indique le détail de position passé en paramètre peut être déchargé/copié, en fonction du gabarit source et cible
  * (private function)
  */
  function CanCreate(
    iGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iReceiptLink in number
  )
    return number
  is
    lPosDetailGaugeFlowId number(12);
    lResult               number(1);
  begin
    select DOC_GAUGE_FLOW_ID
      into lPosDetailGaugeFlowId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_DETAIL_ID = iPosDetailId;

    if lPosDetailGaugeFlowId is null then
      select getFlowId(GAU.C_ADMIN_DOMAIN, PDE.PAC_THIRD_ID)
        into lPosDetailGaugeFlowId
        from DOC_GAUGE GAU
           , DOC_POSITION_DETAIL PDE
       where GAU.DOC_GAUGE_ID = iGaugeSrc
         and PDE.DOC_POSITION_DETAIL_ID = iPosDetailId;
    end if;

    if instr(',' || trim(DOC_LIB_GAUGE.GETALLFLOW(iGaugeSrc, iGaugeDst, iReceiptLink) ) || ',', ',' || lPosDetailGaugeFlowId || ',') > 0 then
      lResult  := 1;
    else
      lResult  := 0;
    end if;

    return lResult;
  end CanCreate;

  /**********************************************************************
  * Description : Indique le détail de position passé en paramètre peut être déchargé, en fonction du gabarit source et cible
  */
  function CanReceipt(
    iGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  )
    return number
  is
  begin
    return CanCreate(iGaugeSrc, iGaugeDst, iPosDetailId, 1);
  end CanReceipt;

  /**********************************************************************
  * Description : Indique le détail de position passé en paramètre peut être copié, en fonction du gabarit source et cible
  */
  function CanCopy(
    iGaugeSrc    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iGaugeDst    in DOC_GAUGE.DOC_GAUGE_ID%type
  , iPosDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  )
    return number
  is
  begin
    return CanCreate(iGaugeSrc, iGaugeDst, iPosDetailId, 0);
  end CanCopy;

  /**
  * Description
  *   Recherche le gabarit père du détail de position déchargé
  */
  function GetDischargeFatherGaugeID(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return DOC_GAUGE.DOC_GAUGE_ID%type
  is
    lResult DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    select PDEF.DOC_GAUGE_ID
      into lResult
      from DOC_POSITION_DETAIL PDES
         , DOC_POSITION_DETAIL PDEF
     where PDES.DOC_POSITION_DETAIL_ID = iPositionDetailId
       and PDEF.DOC_POSITION_DETAIL_ID = PDES.DOC_DOC_POSITION_DETAIL_ID;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetDischargeFatherGaugeID;

  /**********************************************************************
  * Description : Recherche l'ID du DOC_GAUGE_RECEIPT
  */
  function GetGaugeReceiptID(
    iSourceGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type
  , iTargetGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type
  , iThirdID       in PAC_THIRD.PAC_THIRD_ID%type
  , iFlowID        in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type default null
  )
    return DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  is
    lReceiptID DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type;
    lFlowID    DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    -- Utilisation du flux passé en param
    if iFlowID is not null then
      lFlowID  := iFlowID;
    else
      -- Recherche du flux selon domaine, tiers
      select DOC_LIB_GAUGE.GetFlowID(C_ADMIN_DOMAIN, iThirdID)
        into lFlowID
        from DOC_GAUGE
       where DOC_GAUGE_ID = iSourceGaugeId;
    end if;

    select GAR.DOC_GAUGE_RECEIPT_ID
      into lReceiptID
      from DOC_GAUGE_FLOW_DOCUM GAD
         , DOC_GAUGE_RECEIPT GAR
     where GAD.DOC_GAUGE_FLOW_ID = lFlowID
       and GAD.DOC_GAUGE_ID = iTargetGaugeId
       and GAR.DOC_GAUGE_FLOW_DOCUM_ID = GAD.DOC_GAUGE_FLOW_DOCUM_ID
       and GAR.DOC_DOC_GAUGE_ID = iSourceGaugeId;

    return lReceiptID;
  exception
    when no_data_found then
      return null;
  end GetGaugeReceiptID;

  /**
  * Description
  *   Recherche l'ID du DOC_GAUGE_RECEIPT actuel
  */
  function GetGaugeReceiptID(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  is
    lnSrcGaugeID DOC_GAUGE.DOC_GAUGE_ID%type;
    lFlowID      DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    lnTgtGaugeID DOC_GAUGE.DOC_GAUGE_ID%type;
    lnThirdID    PAC_THIRD.PAC_THIRD_ID%type;
  begin
    select PDE_SRC.DOC_GAUGE_ID
         , PDE_SRC.DOC_GAUGE_FLOW_ID
         , PDE_TGT.DOC_GAUGE_ID
         , PDE_TGT.PAC_THIRD_ID
      into lnSrcGaugeID
         , lFlowID
         , lnTgtGaugeID
         , lnThirdID
      from DOC_POSITION_DETAIL PDE_SRC
         , DOC_POSITION_DETAIL PDE_TGT
     where PDE_TGT.DOC_POSITION_DETAIL_ID = iPositionDetailId
       and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE_TGT.DOC_DOC_POSITION_DETAIL_ID;

    return GetGaugeReceiptId(iSourceGaugeId => lnSrcGaugeID, iTargetGaugeId => lnTgtGaugeID, iThirdID => lnThirdID, iFlowID => lFlowID);
  exception
    when no_data_found then
      return null;
  end GetGaugeReceiptID;

  /**
  * Description
  *   Recherche le gabarit père du détail de position copié
  */
  function GetCopyFatherGaugeID(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return DOC_GAUGE.DOC_GAUGE_ID%type
  is
    lResult DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    select PDEF.DOC_GAUGE_ID
      into lResult
      from DOC_POSITION_DETAIL PDES
         , DOC_POSITION_DETAIL PDEF
     where PDES.DOC_POSITION_DETAIL_ID = iPositionDetailId
       and PDEF.DOC_POSITION_DETAIL_ID = PDES.DOC2_DOC_POSITION_DETAIL_ID;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetCopyFatherGaugeID;

  /**********************************************************************
  * Description : Recherche l'ID du DOC_GAUGE_COPY
  */
  function GetGaugeCopyID(
    iSourceGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type
  , iTargetGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type
  , iThirdID       in PAC_THIRD.PAC_THIRD_ID%type
  , iFlowID        in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type default null
  )
    return DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  is
    lCopyID DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type;
    lFlowID DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    -- Utilisation du flux passé en param
    if iFlowID is not null then
      lFlowID  := iFlowID;
    else
      -- Recherche du flux selon domaine, tiers
      select DOC_LIB_GAUGE.GetFlowID(C_ADMIN_DOMAIN, iThirdID)
        into lFlowID
        from DOC_GAUGE
       where DOC_GAUGE_ID = iSourceGaugeId;
    end if;

    select GAC.DOC_GAUGE_COPY_ID
      into lCopyID
      from DOC_GAUGE_FLOW_DOCUM GAD
         , DOC_GAUGE_COPY GAC
     where GAD.DOC_GAUGE_FLOW_ID = lFlowID
       and GAD.DOC_GAUGE_ID = iTargetGaugeId
       and GAC.DOC_GAUGE_FLOW_DOCUM_ID = GAD.DOC_GAUGE_FLOW_DOCUM_ID
       and GAC.DOC_DOC_GAUGE_ID = iSourceGaugeId;

    return lCopyID;
  exception
    when no_data_found then
      return null;
  end GetGaugeCopyID;

  /**
  * Description
  *   Recherche l'ID du DOC_GAUGE_COPY actuel
  */
  function GetGaugeCopyID(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  is
  begin
    return GetGaugeCopyID(iSourceGaugeId   => GetCopyFatherGaugeID(iPositionDetailId)
                        , iTargetGaugeId   => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'DOC_GAUGE_ID', iPositionDetailId)
                        , iThirdID         => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'PAC_THIRD_ID', iPositionDetailId)
                         );
  end GetGaugeCopyID;

  /**********************************************************************
  * Description : Recherche un flag sur le gabarit récéptionnable
  */
  function GetGaugeReceiptFlag(iReceiptID in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type, iFieldName in varchar2)
    return number
  is
    lFlag     number(1);
    lCursorId integer;
    lIgnore   integer;
    lSqlCmd   varchar2(2000);
  begin
    begin
      lSqlCmd    := 'SELECT ' || iFieldName || '  FROM DOC_GAUGE_RECEIPT ' || ' WHERE DOC_GAUGE_RECEIPT_ID = ' || iReceiptID;
      -- Ouverture du curseur
      lCursorId  := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(lCursorId, lSqlCmd, DBMS_SQL.v7);
      DBMS_SQL.DEFINE_COLUMN(lCursorId, 1, lFlag);
      -- Exécution de la fonction
      lIgnore    := DBMS_SQL.execute(lCursorId);

      -- Récupére la variable en retour de la fonction
      if DBMS_SQL.FETCH_ROWS(lCursorId) > 0 then
        DBMS_SQL.column_value(lCursorId, 1, lFlag);
      end if;

      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(lCursorId);
    exception
      when others then
        lFlag  := 0;
    end;

    return lFlag;
  end GetGaugeReceiptFlag;

/***********************************************************************/
/* Description : Recherche un flag sur le gabarit copiable             */
  function GetGaugeCopyFlag(iCopyID in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type, iFieldName in varchar2)
    return number
  is
    lFlag     number(1);
    lCursorId integer;
    lIgnore   integer;
    lSqlCmd   varchar2(2000);
  begin
    begin
      lSqlCmd    := 'SELECT ' || iFieldName || '  FROM DOC_GAUGE_COPY ' || ' WHERE DOC_GAUGE_COPY_ID = ' || iCopyID;
      -- Ouverture du curseur
      lCursorId  := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(lCursorId, lSqlCmd, DBMS_SQL.v7);
      DBMS_SQL.DEFINE_COLUMN(lCursorId, 1, lFlag);
      -- Exécution de la fonction
      lIgnore    := DBMS_SQL.execute(lCursorId);

      -- Récupére la variable en retour de la fonction
      if DBMS_SQL.FETCH_ROWS(lCursorId) > 0 then
        DBMS_SQL.column_value(lCursorId, 1, lFlag);
      end if;

      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(lCursorId);
    exception
      when others then
        lFlag  := 0;
    end;

    return lFlag;
  end GetGaugeCopyFlag;

/***********************************************************************/
/* Description : Recherche du nombre de copies supplémentaires         */
  function GetCopySupp(iGaugeId DOC_GAUGE.DOC_GAUGE_ID%type, iDmtNumber DOC_DOCUMENT.DMT_NUMBER%type, iFormNb number, iTarget varchar2)
    return number
  is
    lAppliCopySupp DOC_GAUGE.C_APPLI_COPY_SUPP%type;
    lStrField      varchar2(50);
    lStrSQL        varchar2(5000);
    lIntFormNum    number;
    lResult        number;
  begin
    -- Recherche du descode correspondant au formulaire passé en paramètre
    if iTarget = 'PAC' then
      lStrField  := 'gau_par_copy_sup_';
    else
      lStrField  := 'appli_copy_supp';
    end if;

    -- Formulaire 0 des documents ou du SAV
    if     (iFormNb = 0)
       and (iTarget <> 'PAC') then
      select c_appli_copy_supp
        into lAppliCopySupp
        from doc_gauge
       where doc_gauge_id = iGaugeId;
    end if;

    if iFormNb <> 0 then
      if iTarget = 'PAC' then
        lIntFormNum  := iFormNb + 1;
      else
        lIntFormNum  := iFormNb;
      end if;

      execute immediate 'select ' || lStrField || to_char(lIntFormNum) || ' from doc_gauge where doc_gauge_id = ' || to_char(iGaugeId)
                   into lAppliCopySupp;
    end if;

    if lAppliCopySupp <> 0 then
      -- Gestion des documents
      if iTarget = 'DOC' then
        lStrSQL  :=
          'select DECODE(GAU.C_ADMIN_DOMAIN,1, SUP.CRE_SUP_COPY' ||
          lAppliCopySupp ||
          '                                  , CUS.CUS_SUP_COPY' ||
          lAppliCopySupp ||
          ') ' ||
          '  from DOC_GAUGE GAU                                      ' ||
          '     , PAC_CUSTOM_PARTNER CUS                             ' ||
          '     , PAC_SUPPLIER_PARTNER SUP                           ' ||
          '     , DOC_DOCUMENT DOC                                   ' ||
          ' where DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID                ' ||
          '   and DOC.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID (+)   ' ||
          '   and DOC.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID (+) ' ||
          '   and GAU.DOC_GAUGE_ID = ' ||
          to_char(iGaugeId) ||
          '   and DOC.DMT_NUMBER   = ' ||
          '''' ||
          iDmtNumber ||
          '''';
      else
        -- Gestion des colis
        if iTarget = 'PAR' then
          lStrSQL  :=
            'select CUS.CUS_SUP_COPY' ||
            lAppliCopySupp ||
            '  from PAC_CUSTOM_PARTNER CUS ' ||
            '     , DOC_PACKING_LIST DOC   ' ||
            ' where CUS.PAC_CUSTOM_PARTNER_ID = DOC.PAC_THIRD_ID ' ||
            '   and DOC.PAL_NUMBER = ' ||
            '''' ||
            iDmtNumber ||
            '''';
        else
          -- Gestion des dossiers SAV
          if iTarget = 'ASA' then
            lStrSQL  :=
              'select CUS.CUS_SUP_COPY' ||
              lAppliCopySupp ||
              '  from DOC_GAUGE GAU                                         ' ||
              '     , PAC_CUSTOM_PARTNER CUS                                ' ||
              '     , ASA_RECORD ASA                                        ' ||
              ' where ASA.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID                   ' ||
              '   and ASA.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID ' ||
              '   and GAU.DOC_GAUGE_ID = ' ||
              to_char(iGaugeId) ||
              '   and ASA.ARE_NUMBER   = ' ||
              '''' ||
              iDmtNumber ||
              '''';
          end if;
        end if;
      end if;

      execute immediate lStrSQL
                   into lResult;
    else
      lResult  := 0;
    end if;

    return lResult;
  end GetCopySupp;

  /*
  * Description : Recherche l'ID du DOC_GAUGE_RECEIPT
  */
  function IsGaugeReceiptable(iTestGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from DOC_GAUGE_RECEIPT GAR
     where GAR.DOC_DOC_GAUGE_ID = iTestGaugeID;

    return lResult;
  end IsGaugeReceiptable;

  /**
  * function GetGaugeSrcListDischarge
  * Description
  *    Renvoi la liste de tous les gabarits déchargeables (source) pour le
  *    gabarit passé en paramètre (gabarit cible)
  */
  function GetGaugeSrcListDischarge(
    iGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type
  , iFlowID  in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type default null
  , iThirdID in PAC_THIRD.PAC_THIRD_ID%type default null
  )
    return ID_TABLE_TYPE
  is
    lGaugeList   ID_TABLE_TYPE                           := ID_TABLE_TYPE();
    lAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lFlowID      DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    lFlowID  := iFlowID;

    -- Si le flux n'a pas été passé en param, rechercher le flux en fonction du gabarit et du tiers
    if lFlowID is null then
      select C_ADMIN_DOMAIN
        into lAdminDomain
        from DOC_GAUGE
       where DOC_GAUGE_ID = iGaugeID;

      lFlowID  := DOC_LIB_GAUGE.GetFlowID(iAdminDomain => lAdminDomain, iThirdID => iThirdID);
    end if;

    -- Liste des gabarits source en décharge du gabarit courant
    for tplSrcGauges in (select GAR.DOC_DOC_GAUGE_ID DOC_GAUGE_ID
                           from DOC_GAUGE_FLOW_DOCUM GAF
                              , DOC_GAUGE_RECEIPT GAR
                          where GAF.DOC_GAUGE_FLOW_ID = lFlowID
                            and GAR.DOC_GAUGE_FLOW_DOCUM_ID = GAF.DOC_GAUGE_FLOW_DOCUM_ID
                            and GAF.DOC_GAUGE_ID = iGaugeID) loop
      lGaugeList.extend;
      lGaugeList(lGaugeList.last)  := tplSrcGauges.DOC_GAUGE_ID;
    end loop;

    return lGaugeList;
  end GetGaugeSrcListDischarge;

  /**
  * Description
  *   retourne 1 si on a affaire à un gabarit TTC
  */
  function isGaugeTTC(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    result number(1);
  begin
    -- Recherche si au moins un gabarit position est geré TTC
    select nvl(max(GAP.GAP_INCLUDE_TAX_TARIFF), 0)
      into result
      from DOC_GAUGE_POSITION GAP
     where GAP.DOC_GAUGE_ID = iGaugeId;

    return result;
  end isGaugeTTC;

  /**
  * Description
  *   retourne 1 si on a affaire à une note de débit
  */
  function isDebitNote(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    lResult number(1);
  begin
    select count(*)
      into lResult
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = iGaugeId
       and C_GAUGE_TITLE = '5'
       and GAS_FINANCIAL_CHARGE = 1;

    return lResult;
  end isDebitNote;

  /**
  * Description
  *   retourne 1 si on a affaire à une note de débit
  */
  function IsDebitNote(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return number
  is
    lResult number(1);
  begin
    if iDetailId is not null then
      return IsDebitNote(iGaugeId => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'DOC_GAUGE_ID', iDetailId) );
    else
      return 0;
    end if;
  end IsDebitNote;

  /**
  * Description
  *   retourne 1 si on a affaire à une note de crédit
  */
  function isCreditNote(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    lResult number(1);
  begin
    select count(*)
      into lResult
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = iGaugeId
       and C_GAUGE_TITLE = '9';

    return lResult;
  end isCreditNote;

  /**
  * Description
  *   retourne 1 si on a affaire à une note de débit
  */
  function IsCreditNote(iDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return number
  is
    lResult number(1);
  begin
    if iDetailId is not null then
      return IsCreditNote(iGaugeId => FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION_DETAIL', 'DOC_GAUGE_ID', iDetailId) );
    else
      return 0;
    end if;
  end IsCreditNote;

  /**
  * Description
  *     Retourne l'ID de la nature de l'opération selon le gabarit structuré.
  */
  function getTypeMovementID(iGaugeID in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type
  as
    lDicTypeMovementID DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
  begin
    select DIC_TYPE_MOVEMENT_ID
      into lDicTypeMovementID
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = iGaugeID;

    return lDicTypeMovementID;
  exception
    when no_data_found then
      return null;
  end getTypeMovementID;

  /**
  * Description
  *   Indique si un gabarit provoque des mouvements financiers
  */
  function WillGenerateFinancialMoves(iGaugeID in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if PCS.PC_CONFIG.GetBooleanConfig('DOC_FINANCIAL_IMPUTATION') then
      for ltplGauge in (select GAS_FINANCIAL_CHARGE
                             , GAS_ANAL_CHARGE
                             , ACJ_JOB_TYPE_S_CATALOGUE_ID
                          from DOC_GAUGE_STRUCTURED
                         where DOC_GAUGE_ID = iGaugeID) loop
        if     (   ltplGauge.GAS_FINANCIAL_CHARGE = 1
                or ltplGauge.GAS_ANAL_CHARGE = 1)
           and ltplGauge.ACJ_JOB_TYPE_S_CATALOGUE_ID is not null then
          -- conditions remplies pour transfert en finance
          return 1;
        else
          return 0;
        end if;
      end loop;

      -- si pas trouvé le gabarit, on retourne 0
      return 0;
    else
      -- transfert finance non actif (configuration)
      return 0;
    end if;
  end WillGenerateFinancialMoves;
end DOC_LIB_GAUGE;
