--------------------------------------------------------
--  DDL for Package Body CML_INVOICING_PREPARATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CML_INVOICING_PREPARATION" 
is
  /**
  * function GetExtractParamsInfo
  * Description
  *    Extraction des donn�es relatives aux filtres pour la g�n�ration
  *      des propositions � facturer
  */
  function GetExtractParamsInfo(aParams in clob)
    return TExtractParamsInfo
  is
    vParamsInfo TExtractParamsInfo;
    vXML        xmltype;
  begin
    vXML  := xmltype.CreateXML(aParams);

    select extractvalue(vXML, '//INJ_PROFILE_NAME') INJ_PROFILE_NAME
         , extractvalue(vXML, '//DIC_CML_INVOICE_REGROUPING_ID') DIC_CML_INVOICE_REGROUPING_ID
         , extractvalue(vXML, '//INJ_MODEL_FROM') INJ_MODEL_FROM
         , extractvalue(vXML, '//INJ_MODEL_TO') INJ_MODEL_TO
         , extractvalue(vXML, '//INJ_CONTRACT_FROM') INJ_CONTRACT_FROM
         , extractvalue(vXML, '//INJ_CONTRACT_TO') INJ_CONTRACT_TO
         , extractvalue(vXML, '//INJ_CUSTOMER_FROM') INJ_CUSTOMER_FROM
         , extractvalue(vXML, '//INJ_CUSTOMER_TO') INJ_CUSTOMER_TO
         , extractvalue(vXML, '//INJ_RECORD_FROM') INJ_RECORD_FROM
         , extractvalue(vXML, '//INJ_RECORD_TO') INJ_RECORD_TO
         , extractvalue(vXML, '//INJ_RECORD_CATEGORY_FROM') INJ_RECORD_CATEGORY_FROM
         , extractvalue(vXML, '//INJ_RECORD_CATEGORY_TO') INJ_RECORD_CATEGORY_TO
         , extractvalue(vXML, '//INJ_INSTALLATION_MODEL_FROM') INJ_INSTALLATION_MODEL_FROM
         , extractvalue(vXML, '//INJ_INSTALLATION_MODEL_TO') INJ_INSTALLATION_MODEL_TO
         , extractvalue(vXML, '//INJ_INSTALLATION_FROM') INJ_INSTALLATION_FROM
         , extractvalue(vXML, '//INJ_INSTALLATION_TO') INJ_INSTALLATION_TO
         , to_number(extractvalue(vXML, '//INJ_INVOICE_GAUGE_ID') ) INJ_INVOICE_GAUGE_ID
         , to_number(extractvalue(vXML, '//INJ_CREDIT_NOTE_GAUGE_ID') ) INJ_CREDIT_NOTE_GAUGE_ID
         , to_number(extractvalue(vXML, '//INJ_EVENTS_INVOICING') ) INJ_EVENTS_INVOICING
         , to_number(extractvalue(vXML, '//INJ_CONS_SURPLUSES_INVOICING') ) INJ_CONS_SURPLUSES_INVOICING
         , to_number(extractvalue(vXML, '//INJ_ESTIM_LACK_STMT_INVOICING') ) INJ_ESTIM_LACK_STMT_INVOICING
         , to_number(extractvalue(vXML, '//INJ_DEPOSIT_INVOICING') ) INJ_DEPOSIT_INVOICING
         , to_number(extractvalue(vXML, '//INJ_ONLY_FIRST_INVOICE') ) INJ_ONLY_FIRST_INVOICE
         , to_number(extractvalue(vXML, '//INJ_PERIODIC_INVOICE') ) INJ_PERIODIC_INVOICE
         , to_number(extractvalue(vXML, '//INJ_LAST_INVOICE') ) INJ_LAST_INVOICE
         , to_number(extractvalue(vXML, '//INJ_MIN_INVOICE_AMOUNT') ) INJ_MIN_INVOICE_AMOUNT
         , to_date(extractvalue(vXML, '//INJ_EXTRACTION_DATE'), 'DD.MM.YYYY') INJ_EXTRACTION_DATE
         , to_date(extractvalue(vXML, '//INJ_DOCUMENT_DATE'), 'DD.MM.YYYY') INJ_DOCUMENT_DATE
         , to_date(extractvalue(vXML, '//INJ_DATE_VALUE'), 'DD.MM.YYYY') INJ_DATE_VALUE
         , to_date(extractvalue(vXML, '//INJ_DATE_DELIVERY'), 'DD.MM.YYYY') INJ_DATE_DELIVERY
         , PCS.PC_FUNCTIONS.XmlExtractClobValue(vXML, '//INJ_USER_CPO_SQL_SQLCODE') INJ_USER_CPO_SQL_SQLCODE
      into vParamsInfo
      from dual;

    return vParamsInfo;
  end GetExtractParamsInfo;

  /**
  * procedure DeleteJobProcess
  * Description
  *    Effacement des propositions pour la facturation des contrats
  */
  procedure DeleteJobProcess(aJobID in number)
  is
    lPositionProtect number;
  begin
    -- D�protection des positions qui ont �t� extraites et de celles qui sont
    -- li�es au job de facturation (dans le cas ou l'objet de facturation aurait plant�)
    for tplPos in (select CML_POSITION_ID
                     from CML_INVOICING_PROCESS
                    where CML_INVOICING_JOB_ID = aJobID
                   union
                   select CML_POSITION_ID
                     from CML_POSITION
                    where CML_INVOICING_JOB_ID = aJobID) loop
      CML_CONTRACT_FUNCTIONS.PositionProtect_AutoTrans(iPositionId   => tplPos.CML_POSITION_ID
                                                     , iProtect      => 0
                                                     , iSessionId    => DBMS_SESSION.unique_session_id
                                                     , iShowError    => 0
                                                     , oUpdated      => lPositionProtect
                                                      );
    end loop;

    -- Effacement des donn�es dans la table d'extraction
    delete from CML_INVOICING_PROCESS
          where CML_INVOICING_JOB_ID = aJobID
            and DOC_POSITION_ID is null;

    -- Effacement des donn�es dans la table de s�lection de l'extraction
    delete from COM_LIST_ID_TEMP;
  end DeleteJobProcess;

  /**
  * procedure JobUnprotectUnusedPos
  * Description
  *    D�prot�ger les positions qui ne figurent plus dans le job de facturation
  */
  procedure JobUnprotectUnusedPos(aJobID in number)
  is
    lPositionProtect number;
  begin
    -- D�protection des positions qui ont �t� extraites
    for tplPos in (select CML_POSITION_ID
                     from CML_POSITION
                    where CPO_PROTECTED = 1
                      and CML_INVOICING_JOB_ID = aJobID
                      and CML_POSITION_ID not in(select distinct CML_POSITION_ID
                                                            from CML_INVOICING_PROCESS
                                                           where CML_INVOICING_JOB_ID = aJobID) ) loop
      CML_CONTRACT_FUNCTIONS.PositionProtect_AutoTrans(iPositionId   => tplPos.CML_POSITION_ID
                                                     , iProtect      => 0
                                                     , iSessionId    => DBMS_SESSION.unique_session_id
                                                     , iShowError    => 0
                                                     , oUpdated      => lPositionProtect
                                                      );
    end loop;
  end JobUnprotectUnusedPos;

  procedure PrepareRegroup(aJobID in number, aSQLText in clob)
  is
    type TInvProcessList is ref cursor;   -- define weak REF CURSOR type

    crInvProcessList          TInvProcessList;
    vCML_INVOICING_PROCESS_ID CML_INVOICING_PROCESS.CML_INVOICING_PROCESS_ID%type;
    vINP_REGROUP_01           CML_INVOICING_PROCESS.INP_REGROUP_01%type;
    vINP_REGROUP_02           CML_INVOICING_PROCESS.INP_REGROUP_02%type;
    vINP_REGROUP_03           CML_INVOICING_PROCESS.INP_REGROUP_03%type;
    vINP_REGROUP_04           CML_INVOICING_PROCESS.INP_REGROUP_04%type;
    vINP_REGROUP_05           CML_INVOICING_PROCESS.INP_REGROUP_05%type;
    vINP_REGROUP_06           CML_INVOICING_PROCESS.INP_REGROUP_06%type;
    vINP_REGROUP_07           CML_INVOICING_PROCESS.INP_REGROUP_07%type;
    vINP_REGROUP_08           CML_INVOICING_PROCESS.INP_REGROUP_08%type;
    vINP_REGROUP_09           CML_INVOICING_PROCESS.INP_REGROUP_09%type;
    vINP_REGROUP_10           CML_INVOICING_PROCESS.INP_REGROUP_10%type;
    vSQL                      varchar2(32000);
    vRegroupID                CML_INVOICING_PROCESS.INP_REGROUP_ID%type;
  begin
    update CML_INVOICING_PROCESS
       set INP_SELECTION = 0
         , INP_REGROUP_ID = null
         , INP_ORDER_BY = null
         , INP_REGROUP_01 = null
         , INP_REGROUP_02 = null
         , INP_REGROUP_03 = null
         , INP_REGROUP_04 = null
         , INP_REGROUP_05 = null
         , INP_REGROUP_06 = null
         , INP_REGROUP_07 = null
         , INP_REGROUP_08 = null
         , INP_REGROUP_09 = null
         , INP_REGROUP_10 = null
         , A_RECSTATUS = null
     where CML_INVOICING_JOB_ID = aJobID
       and DOC_POSITION_ID is null;

    vSQL  :=
      'select CML_INVOICING_PROCESS_ID ' ||
      ', INP_REGROUP_01 ' ||
      ', INP_REGROUP_02 ' ||
      ', INP_REGROUP_03 ' ||
      ', INP_REGROUP_04 ' ||
      ', INP_REGROUP_05 ' ||
      ', INP_REGROUP_06 ' ||
      ', INP_REGROUP_07 ' ||
      ', INP_REGROUP_08 ' ||
      ', INP_REGROUP_09 ' ||
      ', INP_REGROUP_10 ' ||
      ' from ( ' ||
      aSQLText ||
      ')';

    open crInvProcessList for vSQL;

    loop
      fetch crInvProcessList
       into vCML_INVOICING_PROCESS_ID
          , vINP_REGROUP_01
          , vINP_REGROUP_02
          , vINP_REGROUP_03
          , vINP_REGROUP_04
          , vINP_REGROUP_05
          , vINP_REGROUP_06
          , vINP_REGROUP_07
          , vINP_REGROUP_08
          , vINP_REGROUP_09
          , vINP_REGROUP_10;

      exit when crInvProcessList%notfound;

      update CML_INVOICING_PROCESS
         set INP_SELECTION = 1
           , INP_REGROUP_01 = vINP_REGROUP_01
           , INP_REGROUP_02 = vINP_REGROUP_02
           , INP_REGROUP_03 = vINP_REGROUP_03
           , INP_REGROUP_04 = vINP_REGROUP_04
           , INP_REGROUP_05 = vINP_REGROUP_05
           , INP_REGROUP_06 = vINP_REGROUP_06
           , INP_REGROUP_07 = vINP_REGROUP_07
           , INP_REGROUP_08 = vINP_REGROUP_08
           , INP_REGROUP_09 = vINP_REGROUP_09
           , INP_REGROUP_10 = vINP_REGROUP_10
           , INP_ORDER_BY = INIT_ID_SEQ.nextval
       where CML_INVOICING_PROCESS_ID = vCML_INVOICING_PROCESS_ID
         and DOC_POSITION_ID is null;
    end loop;

    for tplProcess in (select   INP_REGROUP_01
                              , INP_REGROUP_02
                              , INP_REGROUP_03
                              , INP_REGROUP_04
                              , INP_REGROUP_05
                              , INP_REGROUP_06
                              , INP_REGROUP_07
                              , INP_REGROUP_08
                              , INP_REGROUP_09
                              , INP_REGROUP_10
                           from (select   INP_REGROUP_01
                                        , INP_REGROUP_02
                                        , INP_REGROUP_03
                                        , INP_REGROUP_04
                                        , INP_REGROUP_05
                                        , INP_REGROUP_06
                                        , INP_REGROUP_07
                                        , INP_REGROUP_08
                                        , INP_REGROUP_09
                                        , INP_REGROUP_10
                                        , min(INP_ORDER_BY) INP_ORDER_BY
                                     from CML_INVOICING_PROCESS
                                    where CML_INVOICING_JOB_ID = aJobID
                                      and INP_SELECTION = 1
                                      and DOC_POSITION_ID is null
                                 group by INP_REGROUP_01
                                        , INP_REGROUP_02
                                        , INP_REGROUP_03
                                        , INP_REGROUP_04
                                        , INP_REGROUP_05
                                        , INP_REGROUP_06
                                        , INP_REGROUP_07
                                        , INP_REGROUP_08
                                        , INP_REGROUP_09
                                        , INP_REGROUP_10)
                       order by INP_ORDER_BY) loop
      select init_id_seq.nextval
        into vRegroupID
        from dual;

      update CML_INVOICING_PROCESS
         set INP_REGROUP_ID = vRegroupID
       where CML_INVOICING_JOB_ID = aJobID
         and INP_SELECTION = 1
         and DOC_POSITION_ID is null
         and nvl(INP_REGROUP_01, 'NULL') = nvl(tplProcess.INP_REGROUP_01, 'NULL')
         and nvl(INP_REGROUP_02, 'NULL') = nvl(tplProcess.INP_REGROUP_02, 'NULL')
         and nvl(INP_REGROUP_03, 'NULL') = nvl(tplProcess.INP_REGROUP_03, 'NULL')
         and nvl(INP_REGROUP_04, 'NULL') = nvl(tplProcess.INP_REGROUP_04, 'NULL')
         and nvl(INP_REGROUP_05, 'NULL') = nvl(tplProcess.INP_REGROUP_05, 'NULL')
         and nvl(INP_REGROUP_06, 'NULL') = nvl(tplProcess.INP_REGROUP_06, 'NULL')
         and nvl(INP_REGROUP_07, 'NULL') = nvl(tplProcess.INP_REGROUP_07, 'NULL')
         and nvl(INP_REGROUP_08, 'NULL') = nvl(tplProcess.INP_REGROUP_08, 'NULL')
         and nvl(INP_REGROUP_09, 'NULL') = nvl(tplProcess.INP_REGROUP_09, 'NULL')
         and nvl(INP_REGROUP_10, 'NULL') = nvl(tplProcess.INP_REGROUP_10, 'NULL');
    end loop;
  end PrepareRegroup;

  /**
  * procedure GenerateJobProcess
  * Description
  *    G�n�ration des propositions pour la facturation des contrats
  */
  procedure GenerateJobProcess(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type, aParams in clob)
  is
    nPositions       number(5);
    vParamsInfo      TExtractParamsInfo;
    vSQL_Command     varchar2(32000);
    lPositionProtect number;
  begin
    vParamsInfo  := GetExtractParamsInfo(aParams => aParams);
    -- Effacement des propositions pour la facturation des contrats
    DeleteJobProcess(aJobID => aJobID);

    -- Effacement des donn�es de la table utilis�e pour le cmd sql filtre de l'utilisateur
    delete from COM_LIST_ID_TEMP_CD;

    -- Tenir compte de la cmd sql de l'utilisateur
    if vParamsInfo.INJ_USER_CPO_SQL_SQLCODE is null then
      insert into COM_LIST_ID_TEMP_CD
                  (COM_LIST_ID_TEMP_CD_ID
                  )
        select CPO.CML_POSITION_ID
          from CML_POSITION CPO
             , CML_DOCUMENT CCO
         where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
           and CCO.C_CML_CONTRACT_STATUS = '01'
           and nvl(CPO.CPO_PROTECTED, 0) = 0;
    else
      vSQL_Command  :=
        'insert into COM_LIST_ID_TEMP_CD (COM_LIST_ID_TEMP_CD_ID) ' ||
        ' select distinct CPO.CML_POSITION_ID from (' ||
        vParamsInfo.INJ_USER_CPO_SQL_SQLCODE ||
        ' ) USR_CMD, CML_POSITION CPO, CML_DOCUMENT CCO ' ||
        ' where USR_CMD.CML_POSITION_ID = CPO.CML_POSITION_ID ' ||
        '   and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID ' ||
        '   and CCO.C_CML_CONTRACT_STATUS = ''01'' ' ||
        '   and nvl(CPO.CPO_PROTECTED, 0) = 0 ';

      execute immediate vSQL_Command;
    end if;

    -- Insertion des positions de contrat correspondant aux filtres de s�lection
    -- dans une table temporaire pour ne pas avoir a faire la cmd sql pour chaque
    -- position de contrat
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
                )
      select CML_POSITION_ID
        from (select distinct CPO.CML_POSITION_ID
                            , CCO.CCO_NUMBER
                            , CPO.CPO_SEQUENCE
                         from CML_DOCUMENT CCO
                            , CML_POSITION CPO
                            , COM_LIST_ID_TEMP_CD LCD
                            , PAC_CUSTOM_PARTNER CUS
                            , PAC_CUSTOM_PARTNER CUS_ACI
                            , PAC_PERSON PER
                            , DOC_RECORD RCO
                            , CML_POSITION_MACHINE CPM
                        where CCO.C_CML_CONTRACT_STATUS = '01'
                          and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
                          and CPO.CML_POSITION_ID = LCD.COM_LIST_ID_TEMP_CD_ID
                          and nvl(CPO.CPO_PROTECTED, 0) = 0
                          -- Filtre sur le Regroupement facture
                          and (   CPO.DIC_CML_INVOICE_REGROUPING_ID = vParamsInfo.DIC_CML_INVOICE_REGROUPING_ID
                               or vParamsInfo.DIC_CML_INVOICE_REGROUPING_ID is null
                              )
                          -- Filtre sur les Mod�les ou les contrats
                          and (    (    CCO.CCO_MODEL = 1
                                    and (CCO.CCO_NUMBER between nvl(vParamsInfo.INJ_MODEL_FROM, CCO.CCO_NUMBER) and nvl(vParamsInfo.INJ_MODEL_TO
                                                                                                                      , CCO.CCO_NUMBER)
                                        )
                                   )
                               or (    CCO.CCO_MODEL = 0
                                   and (CCO.CCO_NUMBER between nvl(vParamsInfo.INJ_CONTRACT_FROM, CCO.CCO_NUMBER)
                                                           and nvl(vParamsInfo.INJ_CONTRACT_TO, CCO.CCO_NUMBER)
                                       )
                                  )
                              )
                          -- Client et Client facturation sont Actifs en Logistique
                          and CCO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                          and CUS.C_PARTNER_STATUS = '1'
                          and CUS_ACI.PAC_CUSTOM_PARTNER_ID = nvl(CCO.PAC_CUSTOM_PARTNER_ACI_ID, nvl(CUS.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID) )
                          and CUS_ACI.C_PARTNER_STATUS = '1'
                          -- Filtre sur les Clients
                          and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                          and (PER.PER_NAME between nvl(vParamsInfo.INJ_CUSTOMER_FROM, PER.PER_NAME) and nvl(vParamsInfo.INJ_CUSTOMER_TO, PER.PER_NAME) )
                          -- Filtre sur les Dossiers
                          and CPO.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                          and (   vParamsInfo.INJ_RECORD_FROM || vParamsInfo.INJ_RECORD_TO is null
                               or (RCO.RCO_TITLE between nvl(vParamsInfo.INJ_RECORD_FROM, RCO.RCO_TITLE) and nvl(vParamsInfo.INJ_RECORD_TO, RCO.RCO_TITLE) )
                              )
                          -- Filtre sur les installations
                          and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID(+)
                          and (    (    vParamsInfo.INJ_RECORD_CATEGORY_FROM is null
                                    and vParamsInfo.INJ_RECORD_CATEGORY_TO is null
                                    and vParamsInfo.INJ_INSTALLATION_MODEL_FROM is null
                                    and vParamsInfo.INJ_INSTALLATION_MODEL_TO is null
                                    and vParamsInfo.INJ_INSTALLATION_FROM is null
                                    and vParamsInfo.INJ_INSTALLATION_TO is null
                                   )
                               or CPM.DOC_RCO_MACHINE_ID in(
                                    select distinct RCO.DOC_RECORD_ID
                                               from DOC_RECORD RCO
                                              where RCO.C_RCO_TYPE = '11'
                                                and nvl(RCO.C_RCO_STATUS, '0') = '0'
                                                and (   vParamsInfo.INJ_INSTALLATION_TO || vParamsInfo.INJ_INSTALLATION_FROM is null
                                                     or (RCO.RCO_TITLE between nvl(vParamsInfo.INJ_INSTALLATION_FROM, RCO.RCO_TITLE)
                                                                           and nvl(vParamsInfo.INJ_INSTALLATION_TO, RCO.RCO_TITLE)
                                                        )
                                                    )
                                                and RCO.RCO_MACHINE_GOOD_ID in(
                                                      select distinct GOO.GCO_GOOD_ID
                                                                 from GCO_GOOD GOO
                                                                    , GCO_COMPL_DATA_EXTERNAL_ASA CEA
                                                                    , DOC_RECORD_CATEGORY RCY
                                                                where GOO.GCO_GOOD_ID = CEA.GCO_GOOD_ID
                                                                  and (   vParamsInfo.INJ_INSTALLATION_MODEL_FROM || vParamsInfo.INJ_INSTALLATION_MODEL_TO is null
                                                                       or (GOO.GOO_MAJOR_REFERENCE between nvl(vParamsInfo.INJ_INSTALLATION_MODEL_FROM
                                                                                                             , GOO.GOO_MAJOR_REFERENCE
                                                                                                              )
                                                                                                       and nvl(vParamsInfo.INJ_INSTALLATION_MODEL_TO
                                                                                                             , GOO.GOO_MAJOR_REFERENCE
                                                                                                              )
                                                                          )
                                                                      )
                                                                  and CEA.DOC_RECORD_CATEGORY_ID = RCY.DOC_RECORD_CATEGORY_ID
                                                                  and (   vParamsInfo.INJ_RECORD_CATEGORY_FROM || vParamsInfo.INJ_RECORD_CATEGORY_TO is null
                                                                       or (RCY.RCY_KEY between nvl(vParamsInfo.INJ_RECORD_CATEGORY_FROM, RCY.RCY_KEY)
                                                                                           and nvl(vParamsInfo.INJ_RECORD_CATEGORY_TO, RCY.RCY_KEY)
                                                                          )
                                                                      )
                                                                  and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
                                                                  and not exists(select PSG.GCO_GOOD_ID
                                                                                   from GCO_PSEUDO_GOOD PSG
                                                                                  where PSG.GCO_GOOD_ID = GOO.GCO_GOOD_ID) ) )
                              )
                     order by CCO.CCO_NUMBER
                            , CPO.CPO_SEQUENCE);

    -- Protection des positions
    for tplPos in (select   COM_LIST_ID_TEMP_ID
                       from COM_LIST_ID_TEMP
                   order by COM_LIST_ID_TEMP_ID) loop
      begin
        CML_CONTRACT_FUNCTIONS.PositionProtect_AutoTrans(iPositionId   => tplPos.COM_LIST_ID_TEMP_ID
                                                       , iProtect      => 1
                                                       , iSessionId    => DBMS_SESSION.unique_session_id
                                                       , iShowError    => 0
                                                       , iInvJobId     => aJobID
                                                       , oUpdated      => lPositionProtect
                                                        );
      exception
        when others then
          update COM_LIST_ID_TEMP
             set LID_FREE_NUMBER_1 = -1
           where COM_LIST_ID_TEMP_ID = tplPos.COM_LIST_ID_TEMP_ID;
      end;
    end loop;

    -- Effacer de la liste les positions qui n'ont pu �tre prot�g�es
    delete from COM_LIST_ID_TEMP
          where LID_FREE_NUMBER_1 = -1;

    -- V�rifier s'il y a des contrats qui correspondent aux filtres de s�lection
    select count(*)
      into nPositions
      from COM_LIST_ID_TEMP;

    -- Il y a des contrats � facturer qui r�pondent aux filtres de s�lection
    if nPositions > 0 then
      /* S�quence de facturation :
           1. Facturation des Evenements
           2. Facturation p�riodique
           3. Facturation des d�pots
           4. Facture finale
         Rappel :
           si Fact. finale = True ->
                Fact. P�riodique = False et Fact. Evenements = False

              Fact. p�riodique = True ->
                Fact. finale = False
      */

      -- 1. Facturation des Evenements OU facturation des evenements d'exc�dents consom.
      if    (vParamsInfo.INJ_EVENTS_INVOICING = 1)
         or (vParamsInfo.INJ_CONS_SURPLUSES_INVOICING = 1) then
        PrepareEventsInvoice(aJobID => aJobID, aExtractParamsInfo => vParamsInfo);
      end if;

      -- 2. Facturation p�riodique
      if vParamsInfo.INJ_PERIODIC_INVOICE = 1 then
        PreparePeriodicInvoice(aJobID => aJobID, aExtractParamsInfo => vParamsInfo);
      end if;

      -- 3. Facturation des d�pots
      if vParamsInfo.INJ_DEPOSIT_INVOICING = 1 then
        PrepareDepositInvoice(aJobID => aJobID, aExtractParamsInfo => vParamsInfo);
      end if;

      -- 4. Facture finale
      if vParamsInfo.INJ_LAST_INVOICE = 1 then
        PrepareFinalInvoice(aJobID => aJobID, aExtractParamsInfo => vParamsInfo);
      end if;

      -- D�prot�ger les positions qui n'ont pas �t� prises en compte dans l'extraction
      for tplPos in (select   COM_LIST_ID_TEMP_ID
                         from COM_LIST_ID_TEMP
                        where COM_LIST_ID_TEMP_ID not in(select distinct CML_POSITION_ID
                                                                    from CML_INVOICING_PROCESS
                                                                   where CML_INVOICING_JOB_ID = aJobID)
                     order by COM_LIST_ID_TEMP_ID) loop
        CML_CONTRACT_FUNCTIONS.PositionProtect_AutoTrans(iPositionId   => tplPos.COM_LIST_ID_TEMP_ID
                                                       , iProtect      => 0
                                                       , iSessionId    => DBMS_SESSION.unique_session_id
                                                       , iShowError    => 0
                                                       , oUpdated      => lPositionProtect
                                                        );
      end loop;

      -- Effacer les donn�es de la table de s�lection de l'extraction
      delete from COM_LIST_ID_TEMP;
    end if;
  end GenerateJobProcess;

  /**
  * procedure InsertCML_INVOICING_PROCESS
  * Description
  *    Insertion d'une proposition de facturation dans la table CML_INVOICING_PROCESS
  */
  procedure InsertCML_INVOICING_PROCESS(aRow in CML_INVOICING_PROCESS%rowtype)
  is
    vRow CML_INVOICING_PROCESS%rowtype;
  begin
    vRow  := aRow;

    select INIT_ID_SEQ.nextval
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , sysdate
         , (case
              when aRow.INP_AMOUNT < 0 then 'CREDIT_NOTE'
              else 'INVOICE'
            end) INP_DOCUMENT_TYPE
      into vRow.CML_INVOICING_PROCESS_ID
         , vRow.A_IDCRE
         , vRow.A_DATECRE
         , vRow.INP_DOCUMENT_TYPE
      from dual;

    insert into CML_INVOICING_PROCESS
         values vRow;
  end InsertCML_INVOICING_PROCESS;

  /**
  * function InsertCML_EVENTS
  * Description
  *    Insertion d'un ligne dans la table CML_EVENTS
  */
  function InsertCML_EVENTS(aRow in CML_EVENTS%rowtype)
    return CML_EVENTS.CML_EVENTS_ID%type
  is
    vRow CML_EVENTS%rowtype;
  begin
    vRow  := aRow;

    -- No de s�quence
    select nvl(max(CEV_SEQUENCE), 0) + to_number(PCS.PC_CONFIG.GETCONFIG('CML_POSITION_INCREMENT') )
      into vRow.CEV_SEQUENCE
      from CML_EVENTS
     where CML_POSITION_ID = vRow.CML_POSITION_ID;

    -- Init ID et cr�ation
    select INIT_ID_SEQ.nextval
         , PCS.PC_I_LIB_SESSION.GetUserIni
         , sysdate
      into vRow.CML_EVENTS_ID
         , vRow.A_IDCRE
         , vRow.A_DATECRE
      from dual;

    insert into CML_EVENTS
         values vRow;

    return vRow.CML_EVENTS_ID;
  end InsertCML_EVENTS;

  /**
  * procedure PrepareEventsInvoice
  * Description
  *    Proposition des �v�nemens � facturer
  */
  procedure PrepareEventsInvoice(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type, aExtractParamsInfo in TExtractParamsInfo)
  is
  begin
    -- Liste des positions pour lesquelles ont doit proposer les �v�nements
    for tplPos in (select distinct CPO.CML_DOCUMENT_ID
                                 , CPO.CML_POSITION_ID
                              from CML_POSITION CPO
                                 , COM_LIST_ID_TEMP LID
                             where LID.COM_LIST_ID_TEMP_ID = CPO.CML_POSITION_ID
                               and CPO.C_CML_POS_STATUS in('02', '03', '04', '06')
                          order by CPO.CML_DOCUMENT_ID
                                 , CPO.CML_POSITION_ID) loop
      -- G�n�ration des �v�nements exc�dents consommation
      if aExtractParamsInfo.INJ_CONS_SURPLUSES_INVOICING = 1 then
        PrepareSurplusesConsom(aJobID           => aJobID
                             , aPositionID      => tplPos.CML_POSITION_ID
                             , aExtractDate     => aExtractParamsInfo.INJ_EXTRACTION_DATE
                             , aEstimLackStmt   => aExtractParamsInfo.INJ_ESTIM_LACK_STMT_INVOICING
                              );
      end if;

      -- Insertion des �v�nements � facturer
      InsertEventsInvoice(aJobID                    => aJobID
                        , aPositionID               => tplPos.CML_POSITION_ID
                        , aExtractDate              => aExtractParamsInfo.INJ_EXTRACTION_DATE
                        , aEventsInvoice            => aExtractParamsInfo.INJ_EVENTS_INVOICING
                        , aSurplusesConsomInvoice   => aExtractParamsInfo.INJ_CONS_SURPLUSES_INVOICING
                         );
      -- Renouvellement des avoirs des prestations
      ServiceRenewal(aPositionID => tplPos.CML_POSITION_ID, aExtractDate => aExtractParamsInfo.INJ_EXTRACTION_DATE);
    end loop;
  end PrepareEventsInvoice;

  /**
  * procedure InsertEventsInvoice
  * Description
  *    Insertion des �v�nements � facturer dans la table des
  *      propositions de facturation
  */
  procedure InsertEventsInvoice(
    aJobID                  in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type
  , aPositionID             in CML_POSITION.CML_POSITION_ID%type
  , aExtractDate            in date
  , aEventsInvoice          in number
  , aSurplusesConsomInvoice in number
  )
  is
    cfgDefaultEventsIndiceCode varchar2(10);
    vAmount                    CML_EVENTS.CEV_AMOUNT%type;
    vIndiceVariable            CML_POSITION.CPO_INDICE_VARIABLE%type;
    vIndiceVarDate             CML_POSITION.CPO_INDICE_V_DATE%type;
    vInvProcess                CML_INVOICING_PROCESS%rowtype;
  begin
    -- Config CML_DEFAULT_EVENTS_INDICE_CODE
    --    Valeur par d�faut du code d'exploitation des indices lors de la facturation des �v�nements
    select upper(nvl(PCS.PC_CONFIG.GETCONFIG('CML_DEFAULT_EVENTS_INDICE_CODE'), 'FALSE') )
      into cfgDefaultEventsIndiceCode
      from dual;

    -- Liste des �v�nements � facturer
    for tplEvents in (select   CEV.CML_DOCUMENT_ID
                             , CEV.CML_POSITION_ID
                             , CEV.CML_EVENTS_ID
                             , CEV.CML_CML_EVENTS_ID
                             , CEV.C_CML_EVENT_TYPE
                             , nvl(CEV.CEV_USE_INDICE, 0) CEV_USE_INDICE
                             , CEV.CEV_AMOUNT
                             , CEV.ACS_FINANCIAL_CURRENCY_ID
                             , CEV.GCO_GOOD_ID
                             , CEV.CEV_QTY
                             , CEV.CEV_COUNTER_BEGIN_QTY
                             , CEV.CEV_COUNTER_END_QTY
                             , CEV.CEV_FREE_QTY
                             , CEV.CEV_INVOICING_QTY
                             , CEV.CEV_GROSS_CONSUMED_QTY
                             , CEV.CEV_NET_CONSUMED_QTY
                             , CEV.CEV_BALANCE_QTY
                             , CPO.C_CML_POS_INDICE_V_VALID
                             , CPO.CPO_INDICE_VARIABLE
                             , CPO.CPO_INDICE_V_DATE
                             , CPO.DIC_CML_INVOICE_REGROUPING_ID
                             , CPO.CPO_INDICE
                             , CCO.PAC_CUSTOM_PARTNER_ID
                             , nvl(CCO.PAC_CUSTOM_PARTNER_ACI_ID, nvl(CUS.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID) ) PAC_CUSTOM_PARTNER_ACI_ID
                             , CCO.PAC_PAYMENT_CONDITION_ID
                          from CML_EVENTS CEV
                             , CML_POSITION CPO
                             , CML_DOCUMENT CCO
                             , PAC_CUSTOM_PARTNER CUS
                         where CPO.CML_POSITION_ID = aPositionID
                           and CPO.CML_POSITION_ID = CEV.CML_POSITION_ID
                           and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
                           and CCO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                           and CEV.DOC_POSITION_ID is null
                           and CEV.CEV_DATE <= aExtractDate
                           and CEV.CML_EVENTS_ID not in(select distinct CML_EVENTS_ID
                                                                   from CML_INVOICING_PROCESS
                                                                  where CML_INVOICING_JOB_ID = aJobID
                                                                    and CML_POSITION_ID = aPositionID)
                           and (    (aEventsInvoice = 1)
                                or (     (aEventsInvoice = 0)
                                    and (aSurplusesConsomInvoice = 1)
                                    and (CEV.C_CML_EVENT_TYPE = '5') ) )
                      order by CEV.CEV_SEQUENCE) loop
      -- Utilisation de la variable locale pour le calcul du montant
      vAmount                                    := tplEvents.CEV_AMOUNT;

      -- Config CML_DEFAULT_EVENTS_INDICE_CODE = False
      -- Validit� indice variable position = '00'
      -- Adaptation montant par indice = False
      if    (cfgDefaultEventsIndiceCode = 'FALSE')
         or (tplEvents.C_CML_POS_INDICE_V_VALID = '00')
         or (tplEvents.CEV_USE_INDICE = 0) then
        -- Pas d'adaptation du montant � facturer
        -- Reprendre les indices actuels de la position
        vIndiceVariable  := tplEvents.CPO_INDICE_VARIABLE;
        vIndiceVarDate   := tplEvents.CPO_INDICE_V_DATE;
      else
        -- Application de l'indice des prix sur le montant � facturer
        ApplyVariableIndice(aPositionID => aPositionID, aInvoiceAmount => vAmount, aIndiceVariable => vIndiceVariable, aIndiceVarDate => vIndiceVarDate);
      end if;

      -- Pour les �v�nements note de cr�dit, inverser le montant
      if tplEvents.C_CML_EVENT_TYPE in('3', '4') then
        vAmount  := vAmount * -1;
      end if;

      -- Init des donn�es � ins�rer comme proposition de facturation
      vInvProcess.CML_INVOICING_JOB_ID           := aJobID;
      vInvProcess.C_INVOICING_PROCESS_TYPE       := 'EVENTS';
      vInvProcess.CML_DOCUMENT_ID                := tplEvents.CML_DOCUMENT_ID;
      vInvProcess.CML_POSITION_ID                := tplEvents.CML_POSITION_ID;
      vInvProcess.CML_EVENTS_ID                  := tplEvents.CML_EVENTS_ID;
      vInvProcess.C_CML_EVENT_TYPE               := tplEvents.C_CML_EVENT_TYPE;
      vInvProcess.PAC_CUSTOM_PARTNER_ID          := tplEvents.PAC_CUSTOM_PARTNER_ID;
      vInvProcess.PAC_CUSTOM_PARTNER_ACI_ID      := tplEvents.PAC_CUSTOM_PARTNER_ACI_ID;
      vInvProcess.PAC_PAYMENT_CONDITION_ID       := tplEvents.PAC_PAYMENT_CONDITION_ID;
      vInvProcess.INP_AMOUNT                     := vAmount;
      vInvProcess.INP_INDICE_VARIABLE            := vIndiceVariable;
      vInvProcess.INP_INDICE_V_DATE              := vIndiceVarDate;
      vInvProcess.ACS_FINANCIAL_CURRENCY_ID      := tplEvents.ACS_FINANCIAL_CURRENCY_ID;
      vInvProcess.GCO_GOOD_ID                    := tplEvents.GCO_GOOD_ID;
      vInvProcess.INP_BEGIN_PERIOD_DATE          := null;
      vInvProcess.INP_END_PERIOD_DATE            := null;
      vInvProcess.INP_NEXT_DATE                  := null;
      vInvProcess.INP_INDICE                     := tplEvents.CPO_INDICE;
      vInvProcess.INP_COUNTER_BEGIN_QTY          := tplEvents.CEV_COUNTER_BEGIN_QTY;
      vInvProcess.INP_COUNTER_END_QTY            := tplEvents.CEV_COUNTER_END_QTY;
      vInvProcess.INP_FREE_QTY                   := tplEvents.CEV_FREE_QTY;
      vInvProcess.INP_INVOICING_QTY              := nvl(tplEvents.CEV_INVOICING_QTY, tplEvents.CEV_QTY);
      vInvProcess.INP_GROSS_CONSUMED_QTY         := tplEvents.CEV_GROSS_CONSUMED_QTY;
      vInvProcess.INP_NET_CONSUMED_QTY           := tplEvents.CEV_NET_CONSUMED_QTY;
      vInvProcess.INP_BALANCE_QTY                := tplEvents.CEV_BALANCE_QTY;
      vInvProcess.CML_CML_EVENTS_ID              := tplEvents.CML_CML_EVENTS_ID;
      vInvProcess.DIC_CML_INVOICE_REGROUPING_ID  := tplEvents.DIC_CML_INVOICE_REGROUPING_ID;
      --
      -- Insertion d'une proposition de facturation dans la table CML_INVOICING_PROCESS
      InsertCML_INVOICING_PROCESS(aRow => vInvProcess);
    end loop;
  end InsertEventsInvoice;

  /**
  * procedure PrepareSurplusesConsom
  * Description
  *    G�n�ration des �v�nements exc�dents consommation
  */
  procedure PrepareSurplusesConsom(
    aJobID         in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type
  , aPositionID    in CML_POSITION.CML_POSITION_ID%type
  , aExtractDate   in date
  , aEstimLackStmt in number
  )
  is
    vInstallationCount      integer                                                  default 0;
    vDetailMachineCount     integer                                                  default 0;
    vCounterStmtListID      TCST_ID_TABLE;
    vCountCounterStmtList   integer                                                  default 0;
    vCpt                    integer                                                  default 0;
    --
    vGrossGlobalConsomm     ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    vNetGlobalConsomm       ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    vGlobalFreeQty          ASA_COUNTER_STATEMENT.CST_STATEMENT_FREE_QUANTITY%type   default 0;
    vSumPonderation         CML_POSITION_MACHINE.CPM_WEIGHT%type                     default 0;
    --
    vFreeQty                ASA_COUNTER_STATEMENT.CST_STATEMENT_FREE_QUANTITY%type   default 0;
    vCounterStmtBegin       ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    vCounterStmtBeginDate   ASA_COUNTER_STATEMENT.CST_STATEMENT_DATE%type;
    vCounterStmtEnd         ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    vCounterStmtEndDate     ASA_COUNTER_STATEMENT.CST_STATEMENT_DATE%type;
    vCounterStmtID          varchar2(32000)                                          default null;
    vGrossQty               ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    vNetQty                 ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type        default 0;
    --
    vRowTemp                CML_EVENTS%rowtype;
    vRowCML_EVENTS          CML_EVENTS%rowtype;
    vGlobalEventID          CML_EVENTS.CML_EVENTS_ID%type                            default null;
    vEventID                CML_EVENTS.CML_EVENTS_ID%type                            default null;
    --
    bContinue               boolean                                                  default false;
    bCreateEvent            boolean;
    vInRenewalPeriod        number(1)                                                default 0;
    vCML_COUNTER_STMT_MARGE integer                                                  default 0;
    vBeginRenewalPeriod     date;
    vCountEvents            integer                                                  default 0;
  begin
    -- Liste des installations de la position
    select count(DOC_RCO_MACHINE_ID)
      into vInstallationCount
      from CML_POSITION_MACHINE
     where CML_POSITION_ID = aPositionID;

    if vInstallationCount > 0 then
      -- Rechercher la config. d�finissant le d�calage de d�but de p�riode de
      -- renouvellement, pour la recherche des compteurs valides dans cette p�riode
      begin
        select to_number(PCS.PC_CONFIG.GETCONFIG('CML_COUNTER_STMT_MARGE') )
          into vCML_COUNTER_STMT_MARGE
          from dual;
      exception
        when others then
          null;
      end;

      -- Liste des prestations
      --  Type '1' = Droit de consom.
      --  Code Renouvellement
      --    1 : Avoir �puisable renouvable
      --    2 : Avoir �puisable non-renouvable
      --    4 : Avoir �puisable - Renouvellement cumul�
      --  Code de traitement de type :
      --    300 : Facturation des exc�dents obligatoire OU
      --    400 : Facturation des exc�dents possible
      --  Code de traitment actif pour le mois de la date d'extraction
      for tplServiceDetail in (select distinct CPD.CML_POSITION_SERVICE_DETAIL_ID
                                             , CPD.ASA_COUNTER_TYPE_ID
                                             , nvl(CPD.CPD_BALANCE_QTY, 0) CPD_BALANCE_QTY
                                             , nvl(CPD.CPD_UNIT_VALUE, 0) CPD_UNIT_VALUE
                                             , nvl(CPD.CPD_CONSUMED_QTY, 0) CPD_CONSUMED_QTY
                                             , nvl(CPD.CPD_PERIOD_QTY, 0) CPD_PERIOD_QTY
                                             , GOO.GCO_GOOD_ID
                                             , CPS.CPS_FREE_DESCRIPTION
                                             , CCO.CML_DOCUMENT_ID
                                             , CCO.PAC_CUSTOM_PARTNER_ID
                                             , CPO.ACS_FINANCIAL_CURRENCY_ID
                                             , CTT.CTT_DESCR
                                             , CPD.CML_POSITION_SERVICE_ID
                                          from CML_POSITION_SERVICE CPS
                                             , CML_POSITION_SERVICE_DETAIL CPD
                                             , CML_POSITION CPO
                                             , CML_DOCUMENT CCO
                                             , GCO_GOOD GOO
                                             , CML_PROCESSING CPR
                                             , ASA_COUNTER_TYPE CTT
                                         where CPO.CML_POSITION_ID = aPositionID
                                           and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
                                           and CPO.CML_POSITION_ID = CPS.CML_POSITION_ID
                                           and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
                                           and CTT.ASA_COUNTER_TYPE_ID = CPD.ASA_COUNTER_TYPE_ID
                                           and CPS.GCO_CML_SERVICE_ID = GOO.GCO_GOOD_ID
                                           and GOO.C_SERVICE_KIND = '1'
                                           and CPD.C_SERVICE_RENEWAL in('1', '2', '4')
                                           and CPD.CML_POSITION_SERVICE_DETAIL_ID = CPR.CML_POSITION_SERVICE_DETAIL_ID
                                           and CPR.C_CML_PROCESSING_TYPE in('300', '400')
                                           and (    (instr(CPR.CPR_MONTHS, to_char(aExtractDate, 'MM') ) > 0)
                                                or (CPD.CPD_EXPIRY_DATE < trunc(aExtractDate) ) )
                                      order by CPD.CML_POSITION_SERVICE_ID
                                             , CPD.CML_POSITION_SERVICE_DETAIL_ID) loop
        -- Liste des machines associ�es au contrat position qui ont un compteur
        -- type compteur de la prestation courante
        select count(CMD.CML_POSITION_MACHINE_DETAIL_ID)
          into vDetailMachineCount
          from CML_POSITION_MACHINE CPM
             , CML_POSITION_MACHINE_DETAIL CMD
             , ASA_COUNTER COU
         where CPM.CML_POSITION_ID = aPositionID
           and CPM.CML_POSITION_MACHINE_ID = CMD.CML_POSITION_MACHINE_ID
           and COU.ASA_COUNTER_TYPE_ID = tplServiceDetail.ASA_COUNTER_TYPE_ID
           and COU.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID;

        -- Nb de compteurs � facturer
        if vDetailMachineCount = 1 then
          vGlobalEventID  := null;
          bContinue       := true;
        -- Nb de compteurs � facturer
        elsif vDetailMachineCount > 1 then
          vGrossGlobalConsomm     := 0;
          vNetGlobalConsomm       := 0;
          vGlobalFreeQty          := 0;
          vSumPonderation         := 0;

          -- Liste des installations pour le calcul des compteurs
          for tplInstallationList in (select CMD.CML_POSITION_MACHINE_DETAIL_ID
                                           , CPM.CPM_WEIGHT
                                        from CML_POSITION_MACHINE CPM
                                           , CML_POSITION_MACHINE_DETAIL CMD
                                           , ASA_COUNTER COU
                                       where CPM.CML_POSITION_ID = aPositionID
                                         and CPM.CML_POSITION_MACHINE_ID = CMD.CML_POSITION_MACHINE_ID
                                         and COU.ASA_COUNTER_TYPE_ID = tplServiceDetail.ASA_COUNTER_TYPE_ID
                                         and COU.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID) loop
            -- Calcul de la consommation compteur
            CalculateConsommStmt(aDetailMachineID        => tplInstallationList.CML_POSITION_MACHINE_DETAIL_ID
                               , aServiceDetailID        => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
                               , aCustomerID             => tplServiceDetail.PAC_CUSTOM_PARTNER_ID
                               , aEstimLackStmt          => aEstimLackStmt
                               , aExtractDate            => aExtractDate
                               , aFreeQty                => vFreeQty
                               , aCounterStmtBegin       => vCounterStmtBegin
                               , aCounterStmtBeginDate   => vCounterStmtBeginDate
                               , aCounterStmtEnd         => vCounterStmtEnd
                               , aCounterStmtEndDate     => vCounterStmtEndDate
                               , aCounterStmtListID      => vCounterStmtListID
                               , aGrossQty               => vGrossQty
                               , aNetQty                 => vNetQty
                               , aInRenewalPeriod        => vInRenewalPeriod
                                );
            vGrossGlobalConsomm    := vGrossGlobalConsomm + vGrossQty;
            vNetGlobalConsomm      := vNetGlobalConsomm + vNetQty;
            vGlobalFreeQty         := vGlobalFreeQty + vFreeQty;
            vSumPonderation        := vSumPonderation + tplInstallationList.CPM_WEIGHT;
            vCountCounterStmtList  := vCountCounterStmtList + vCounterStmtListID.count;
            vCounterStmtListID.delete;
          end loop;

          vRowCML_EVENTS.CEV_QTY  := greatest(vNetGlobalConsomm - tplServiceDetail.CPD_BALANCE_QTY, 0);
          bCreateEvent            := false;

          -- Si en p�riode de renouvellement et qu'il y a des �tats compteur
          -- v�rifier s'il n'y pas d�j� eu un �v�nement factur� pour la m�me p�riode
          -- si c'est le cas, il ne faut pas g�n�rer un nouvel �v�nement s'il
          -- n'y a rien � facturer
          if (    vInRenewalPeriod = 1
              and vCountCounterStmtList > 0) then
            -- Trouver la date de d�but de la p�riode de renouvellement actuelle
            vBeginRenewalPeriod  :=
              CML_CONTRACT_FUNCTIONS.GetRenewalPeriodDate(aDate               => aExtractDate
                                                        , aServiceDetailID    => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
                                                        , aCounterStmtMarge   => vCML_COUNTER_STMT_MARGE
                                                         );

            -- V�rifier si �v�nement d�j� factur�
            select count(CEV.CML_EVENTS_ID)
              into vCountEvents
              from CML_EVENTS CEV
                 , ASA_COUNTER_STATEMENT CST
             where CEV.CML_POSITION_ID = aPositionID
               and CEV.CML_POSITION_SERVICE_DETAIL_ID = tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
               and CEV.C_CML_EVENT_TYPE = '5'
               and CEV.CEV_RENEWAL_GENERATED = 1
               and CEV.CML_EVENTS_ID = CST.CML_EVENTS_ID
               and CST.CST_STATEMENT_DATE between vBeginRenewalPeriod and aExtractDate;

            if vCountEvents = 0 then
              bCreateEvent  := true;
            end if;
          end if;

          -- On ins�re l'�v�nement uniquement s'il y a eu consommation
          if    (vRowCML_EVENTS.CEV_QTY > 0)
             or (bCreateEvent) then
            bContinue                                      := true;
            -- Init des donn�es � ins�rer comme Evenement
            vRowCML_EVENTS.CML_POSITION_ID                 := aPositionID;
            vRowCML_EVENTS.CML_DOCUMENT_ID                 := tplServiceDetail.CML_DOCUMENT_ID;
            vRowCML_EVENTS.CML_POSITION_SERVICE_DETAIL_ID  := tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID;
            vRowCML_EVENTS.CML_POSITION_MACHINE_DETAIL_ID  := null;
            vRowCML_EVENTS.C_CML_EVENT_TYPE                := '5';
            vRowCML_EVENTS.C_CML_EVENT_DOC_GEN             := '2';
            vRowCML_EVENTS.CEV_DATE                        := trunc(aExtractDate);
            vRowCML_EVENTS.GCO_GOOD_ID                     := tplServiceDetail.GCO_GOOD_ID;
            vRowCML_EVENTS.CEV_TEXT                        := tplServiceDetail.CPS_FREE_DESCRIPTION || ' - ' || tplServiceDetail.CTT_DESCR;
            vRowCML_EVENTS.CEV_UNIT_SALE_PRICE             := tplServiceDetail.CPD_UNIT_VALUE;
            vRowCML_EVENTS.CEV_AMOUNT                      := vRowCML_EVENTS.CEV_QTY * vRowCML_EVENTS.CEV_UNIT_SALE_PRICE;
            vRowCML_EVENTS.ACS_FINANCIAL_CURRENCY_ID       := tplServiceDetail.ACS_FINANCIAL_CURRENCY_ID;
            vRowCML_EVENTS.CEV_UNIT_COST_PRICE             := 0;
            vRowCML_EVENTS.CEV_COST_PRICE                  := 0;
            vRowCML_EVENTS.CEV_USE_INDICE                  := 0;
            vRowCML_EVENTS.CEV_COUNTER_BEGIN_QTY           := null;
            vRowCML_EVENTS.CEV_COUNTER_BEGIN_DATE          := null;
            vRowCML_EVENTS.CEV_COUNTER_END_QTY             := null;
            vRowCML_EVENTS.CEV_COUNTER_END_DATE            := null;
            vRowCML_EVENTS.CEV_FREE_QTY                    := greatest(vGlobalFreeQty, 0);
            vRowCML_EVENTS.CEV_GROSS_CONSUMED_QTY          := greatest(vGrossGlobalConsomm, 0);
            vRowCML_EVENTS.CEV_NET_CONSUMED_QTY            := greatest(vNetGlobalConsomm, 0);
            vRowCML_EVENTS.CEV_BALANCE_QTY                 := tplServiceDetail.CPD_BALANCE_QTY;
            vRowCML_EVENTS.CEV_INVOICING_QTY               := vRowCML_EVENTS.CEV_QTY;
            vRowCML_EVENTS.CEV_BEF_INV_COUNTER_STMT        := null;
            vRowCML_EVENTS.CEV_BEF_INV_PERIOD_QTY          := tplServiceDetail.CPD_PERIOD_QTY;
            vRowCML_EVENTS.CEV_BEF_INV_CONSUMED_QTY        := tplServiceDetail.CPD_CONSUMED_QTY;
            vRowCML_EVENTS.CEV_BEF_INV_BALANCE_QTY         := tplServiceDetail.CPD_BALANCE_QTY;
            vRowCML_EVENTS.CEV_GLOBAL_EVENT                := 1;
            vRowCML_EVENTS.CEV_RENEWAL_GENERATED           := 0;
            vRowCML_EVENTS.CML_POS_SERV_DET_HISTORY_ID     := null;

            -- Si en p�riode de renouvellement, v�rifier si c'est ce �v�nement
            -- qui va d�clencher le renouvellement ou bien s'il a d�j� �t�
            -- effectu� par un autre �v�nement
            if     (vInRenewalPeriod = 1)
               and (bCreateEvent) then
              -- Il n'y a pas eu d'�v�nement qui a g�n�r� le renouvellement
                -- Insertion d'un historique du d�tail de prestation
              vRowCML_EVENTS.CML_POS_SERV_DET_HISTORY_ID  := InsertCML_POS_SERV_DET_HISTORY(aServDetailID => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID);
              vRowCML_EVENTS.CEV_RENEWAL_GENERATED        := 1;
            end if;

            --
            -- Insertion d'un ligne dans la table CML_EVENTS
            vGlobalEventID                                 := InsertCML_EVENTS(aRow => vRowCML_EVENTS);
          end if;
        end if;

        -- On ins�re l'�v�nement uniquement s'il y a eu consommation
        if bContinue then
          -- Liste des installations pour le calcul des compteurs
          for tplInstallationList in (select CMD.CML_POSITION_MACHINE_DETAIL_ID
                                           , CPM.CPM_WEIGHT
                                        from CML_POSITION_MACHINE CPM
                                           , CML_POSITION_MACHINE_DETAIL CMD
                                           , ASA_COUNTER COU
                                       where CPM.CML_POSITION_ID = aPositionID
                                         and CPM.CML_POSITION_MACHINE_ID = CMD.CML_POSITION_MACHINE_ID
                                         and COU.ASA_COUNTER_TYPE_ID = tplServiceDetail.ASA_COUNTER_TYPE_ID
                                         and COU.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID) loop
            -- Effacer la table temp contenant la liste des id des �tats compteurs
            vCounterStmtListID.delete;
            -- Calcul de la consommation compteur
            CalculateConsommStmt(aDetailMachineID        => tplInstallationList.CML_POSITION_MACHINE_DETAIL_ID
                               , aServiceDetailID        => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
                               , aCustomerID             => tplServiceDetail.PAC_CUSTOM_PARTNER_ID
                               , aEstimLackStmt          => aEstimLackStmt
                               , aExtractDate            => aExtractDate
                               , aFreeQty                => vFreeQty
                               , aCounterStmtBegin       => vCounterStmtBegin
                               , aCounterStmtBeginDate   => vCounterStmtBeginDate
                               , aCounterStmtEnd         => vCounterStmtEnd
                               , aCounterStmtEndDate     => vCounterStmtEndDate
                               , aCounterStmtListID      => vCounterStmtListID
                               , aGrossQty               => vGrossQty
                               , aNetQty                 => vNetQty
                               , aInRenewalPeriod        => vInRenewalPeriod
                                );
            -- Effacement des donn�es de la variable pour l'insertion d'un CML_EVENTS
            vRowCML_EVENTS  := vRowTemp;

            -- Nb de compteurs � facturer
            if vDetailMachineCount = 1 then
              vRowCML_EVENTS.CEV_QTY                   := greatest(vNetQty - tplServiceDetail.CPD_BALANCE_QTY, 0);
              vRowCML_EVENTS.CEV_BALANCE_QTY           := tplServiceDetail.CPD_BALANCE_QTY;
              vRowCML_EVENTS.CEV_BEF_INV_PERIOD_QTY    := tplServiceDetail.CPD_PERIOD_QTY;
              vRowCML_EVENTS.CEV_BEF_INV_CONSUMED_QTY  := tplServiceDetail.CPD_CONSUMED_QTY;
              vRowCML_EVENTS.CEV_BEF_INV_BALANCE_QTY   := tplServiceDetail.CPD_BALANCE_QTY;
              vRowCML_EVENTS.CEV_FREE_QTY              := greatest(vFreeQty, 0);
              vRowCML_EVENTS.CEV_GROSS_CONSUMED_QTY    := greatest(vGrossQty, 0);
              vRowCML_EVENTS.CEV_NET_CONSUMED_QTY      := greatest(vNetQty, 0);
            -- Nb de compteurs � facturer
            elsif vDetailMachineCount > 1 then
              vRowCML_EVENTS.CEV_QTY                   :=
                                         greatest( ( (vNetGlobalConsomm - tplServiceDetail.CPD_BALANCE_QTY) / vSumPonderation) * tplInstallationList.CPM_WEIGHT
                                                , 0);
              vRowCML_EVENTS.CML_CML_EVENTS_ID         := vGlobalEventID;
              vRowCML_EVENTS.CEV_BALANCE_QTY           := null;
              vRowCML_EVENTS.CEV_BEF_INV_PERIOD_QTY    := null;
              vRowCML_EVENTS.CEV_BEF_INV_CONSUMED_QTY  := null;
              vRowCML_EVENTS.CEV_BEF_INV_BALANCE_QTY   := null;
              vRowCML_EVENTS.CEV_FREE_QTY              := greatest(vGlobalFreeQty, 0);
              vRowCML_EVENTS.CEV_GROSS_CONSUMED_QTY    := greatest(vGrossGlobalConsomm, 0);
              vRowCML_EVENTS.CEV_NET_CONSUMED_QTY      := greatest(vNetGlobalConsomm, 0);
            end if;

            bCreateEvent    := false;

            -- Si en p�riode de renouvellement et qu'il y a des �tats compteur
            -- v�rifier s'il n'y pas d�j� eu un �v�nement factur� pour la m�me p�riode
            -- si c'est le cas, il ne faut pas g�n�rer un nouvel �v�nement s'il
            -- n'y a rien � facturer
            if     (vInRenewalPeriod = 1)
               and (vCounterStmtListID.count > 0) then
              -- Trouver la date de d�but de la p�riode de renouvellement actuelle
              vBeginRenewalPeriod  :=
                CML_CONTRACT_FUNCTIONS.GetRenewalPeriodDate(aDate               => aExtractDate
                                                          , aServiceDetailID    => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
                                                          , aCounterStmtMarge   => vCML_COUNTER_STMT_MARGE
                                                           );

              -- V�rifier si �v�nement d�j� factur�
              select count(CEV.CML_EVENTS_ID)
                into vCountEvents
                from CML_EVENTS CEV
                   , ASA_COUNTER_STATEMENT CST
               where CEV.CML_POSITION_ID = aPositionID
                 and CEV.CML_POSITION_SERVICE_DETAIL_ID = tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID
                 and CEV.C_CML_EVENT_TYPE = '5'
                 and CEV.CEV_RENEWAL_GENERATED = 1
                 and CEV.CML_EVENTS_ID = CST.CML_EVENTS_ID
                 and CST.CST_STATEMENT_DATE between vBeginRenewalPeriod and aExtractDate;

              if vCountEvents = 0 then
                bCreateEvent  := true;
              end if;
            end if;

            -- On ins�re l'�v�nement uniquement s'il y a qt� � facturer ou
            -- si en p�riode de renouvellement et qu'il y a des compteurs
            if    (vRowCML_EVENTS.CEV_QTY > 0)
               or (bCreateEvent) then
              -- Init des donn�es � ins�rer comme Evenement
              vRowCML_EVENTS.CML_POSITION_ID                 := aPositionID;
              vRowCML_EVENTS.CML_DOCUMENT_ID                 := tplServiceDetail.CML_DOCUMENT_ID;
              vRowCML_EVENTS.CML_POSITION_SERVICE_DETAIL_ID  := tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID;
              vRowCML_EVENTS.CML_POSITION_MACHINE_DETAIL_ID  := tplInstallationList.CML_POSITION_MACHINE_DETAIL_ID;
              vRowCML_EVENTS.C_CML_EVENT_TYPE                := '5';
              vRowCML_EVENTS.C_CML_EVENT_DOC_GEN             := '2';
              vRowCML_EVENTS.CEV_DATE                        := trunc(aExtractDate);
              vRowCML_EVENTS.GCO_GOOD_ID                     := tplServiceDetail.GCO_GOOD_ID;
              vRowCML_EVENTS.CEV_TEXT                        := tplServiceDetail.CPS_FREE_DESCRIPTION || ' - ' || tplServiceDetail.CTT_DESCR;
              vRowCML_EVENTS.CEV_UNIT_SALE_PRICE             := tplServiceDetail.CPD_UNIT_VALUE;
              vRowCML_EVENTS.CEV_AMOUNT                      := vRowCML_EVENTS.CEV_QTY * vRowCML_EVENTS.CEV_UNIT_SALE_PRICE;
              vRowCML_EVENTS.ACS_FINANCIAL_CURRENCY_ID       := tplServiceDetail.ACS_FINANCIAL_CURRENCY_ID;
              vRowCML_EVENTS.CEV_UNIT_COST_PRICE             := 0;
              vRowCML_EVENTS.CEV_COST_PRICE                  := 0;
              vRowCML_EVENTS.CEV_USE_INDICE                  := 0;
              vRowCML_EVENTS.CEV_INVOICING_QTY               := vRowCML_EVENTS.CEV_QTY;
              vRowCML_EVENTS.CEV_COUNTER_BEGIN_QTY           := vCounterStmtBegin;
              vRowCML_EVENTS.CEV_COUNTER_BEGIN_DATE          := vCounterStmtBeginDate;
              vRowCML_EVENTS.CEV_COUNTER_END_QTY             := vCounterStmtEnd;
              vRowCML_EVENTS.CEV_COUNTER_END_DATE            := vCounterStmtEndDate;
              vRowCML_EVENTS.CEV_BEF_INV_COUNTER_STMT        := vCounterStmtBegin;
              vRowCML_EVENTS.CEV_RENEWAL_GENERATED           := 0;
              vRowCML_EVENTS.CML_POS_SERV_DET_HISTORY_ID     := null;

              -- Insertion d'un historique du d�tail de prestation
              -- si cet �v�nement a g�n�r� au renouvellement des avoirs
              if     (vInRenewalPeriod = 1)
                 and (vDetailMachineCount = 1)
                 and (bCreateEvent) then
                -- Il n'y a pas eu d'�v�nement qui a g�n�r� le renouvellement
                  -- Insertion d'un historique du d�tail de prestation
                vRowCML_EVENTS.CML_POS_SERV_DET_HISTORY_ID  := InsertCML_POS_SERV_DET_HISTORY(aServDetailID   => tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID);
                vRowCML_EVENTS.CEV_RENEWAL_GENERATED        := 1;
              end if;

              --
              -- Insertion d'un ligne dans la table CML_EVENTS
              vEventID                                       := InsertCML_EVENTS(aRow => vRowCML_EVENTS);

              --
              -- M�j de l'�tat compteur derni�re facture de l'installation
              update CML_POSITION_MACHINE_DETAIL
                 set CMD_LAST_INVOICE_STATEMENT = vCounterStmtEnd
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where CML_POSITION_MACHINE_DETAIL_ID = tplInstallationList.CML_POSITION_MACHINE_DETAIL_ID;

              --
              -- M�j du statut de l'�tat compteur
              if vCounterStmtListID.count > 0 then
                for vCpt in vCounterStmtListID.first .. vCounterStmtListID.last loop
                  update ASA_COUNTER_STATEMENT
                     set C_COUNTER_STATEMENT_STATUS = '3'
                       , CML_EVENTS_ID = vEventID
                       , A_DATEMOD = sysdate
                       , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   where ASA_COUNTER_STATEMENT_ID = vCounterStmtListID(vCpt);
                end loop;
              end if;

              -- 1 seul compteur � facturer
              if vDetailMachineCount = 1 then
                --
                -- M�j qt� consomm�e et qt� solde de la prestation
                update CML_POSITION_SERVICE_DETAIL
                   set CPD_CONSUMED_QTY = CPD_CONSUMED_QTY + greatest(vNetQty, 0)
                     , CPD_BALANCE_QTY = greatest(CPD_BALANCE_QTY - vNetQty, 0)
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where CML_POSITION_SERVICE_DETAIL_ID = tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID;
              end if;
            end if;
          end loop;

          -- Plusieurs compteurs � facturer
          if vDetailMachineCount > 1 then
            -- Le d�tail prestation est m�j avec la consommation globale
            --
            -- M�j qt� consomm�e et qt� solde de la prestation
            update CML_POSITION_SERVICE_DETAIL
               set CPD_CONSUMED_QTY = CPD_CONSUMED_QTY + greatest(vNetGlobalConsomm, 0)
                 , CPD_BALANCE_QTY = greatest(CPD_BALANCE_QTY - vNetGlobalConsomm, 0)
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where CML_POSITION_SERVICE_DETAIL_ID = tplServiceDetail.CML_POSITION_SERVICE_DETAIL_ID;
          end if;
        end if;
      end loop;
    end if;
  end PrepareSurplusesConsom;

  /**
  * procedure ApplyVariableIndice
  * Description
  *    Application de l'indice des prix sur le montant � facturer
  */
  procedure ApplyVariableIndice(
    aPositionID     in     CML_POSITION.CML_POSITION_ID%type
  , aInvoiceAmount  in out CML_EVENTS.CEV_AMOUNT%type
  , aIndiceVariable out    CML_POSITION.CPO_INDICE_VARIABLE%type
  , aIndiceVarDate  out    CML_POSITION.CPO_INDICE_V_DATE%type
  )
  is
    -- Rechercher informations sur la position
    cursor crCpo
    is
      select CPO_BEGIN_CONTRACT_DATE
           , CPO_NEXT_DATE
           , nvl(C_CML_POS_INDICE_V_VALID, '00') C_CML_POS_INDICE_V_VALID
           , nvl(CPO_INDICE, 0) CPO_INDICE
           , nvl(CPO_INDICE_VARIABLE, 0) CPO_INDICE_VARIABLE
           , trunc(CPO_INDICE_V_DATE) CPO_INDICE_V_DATE
           , DIC_CML_INDICE_ID
        from CML_POSITION
       where CML_POSITION_ID = aPositionID;

    tplCpoRow           crCpo%rowtype;
    vIndiceEndValidDate date;
    bApplyIndice        boolean;
  begin
    -- Rechercher informations sur la position
    open crCpo;

    fetch crCpo
     into tplCpoRow;

    close crCpo;

    -- Initialiser les variables de retour avec la valeur actuelle de la position
    aIndiceVariable  := tplCpoRow.CPO_INDICE_VARIABLE;
    aIndiceVarDate   := tplCpoRow.CPO_INDICE_V_DATE;

    -- Montant � facturer <> 0
    -- Indice co�t de la vie renseign� et validit� de l'indice <> "Aucun"
    if     (aInvoiceAmount <> 0)
       and (tplCpoRow.CPO_INDICE <> 0)
       and (tplCpoRow.C_CML_POS_INDICE_V_VALID <> '00') then
      -- Date prochaine �cheance pas renseign�e
      if     (tplCpoRow.CPO_NEXT_DATE is null)
         and (tplCpoRow.CPO_INDICE_VARIABLE is null) then
        -- 1ere Facturation
        -- Pas d'application � l'indice des prix
        -- Indice variable = Indice de base
        -- Date init indice variable = Date d�but contrat
        aIndiceVariable  := tplCpoRow.CPO_INDICE;
        aIndiceVarDate   := tplCpoRow.CPO_BEGIN_CONTRACT_DATE;
      else
        -- Calcul de la date de validit� de l'indice variable
        -- Validit� de l'indice de calcul = C_CML_POS_INDICE_V_VALID
        -- 00 = Aucun
        -- 01 = Mensuel
        -- 03 = Trimestriel
        -- 06 = Semestriel
        -- 12 = Annuel
        vIndiceEndValidDate  := add_months(tplCpoRow.CPO_INDICE_V_DATE, to_number(tplCpoRow.C_CML_POS_INDICE_V_VALID) ) - 1;

        -- V�rifier si l'indice variable est toujours valable par rapport � la prochaine �ch�ance
        if     (vIndiceEndValidDate is not null)
           and (vIndiceEndValidDate >= nvl(tplCpoRow.CPO_NEXT_DATE, tplCpoRow.CPO_BEGIN_CONTRACT_DATE) ) then
          aIndiceVariable  := tplCpoRow.CPO_INDICE_VARIABLE;
          aIndiceVarDate   := tplCpoRow.CPO_INDICE_V_DATE;
        else
          -- Rechercher un nouvel indice
          -- Rechercher la valeur de l'indice valide pour la prochaine �ch�ance
          begin
            select CIN_INDICE_RATE
              into aIndiceVariable
              from CML_INDICE
             where nvl(DIC_CML_INDICE_ID, '[NULL]') = nvl(tplCpoRow.DIC_CML_INDICE_ID, '[NULL]')
               and CIN_VALIDITY_DATE =
                     (select max(CIN_VALIDITY_DATE)
                        from CML_INDICE
                       where nvl(DIC_CML_INDICE_ID, '[NULL]') = nvl(tplCpoRow.DIC_CML_INDICE_ID, '[NULL]')
                         and CIN_VALIDITY_DATE <= nvl(tplCpoRow.CPO_NEXT_DATE, tplCpoRow.CPO_BEGIN_CONTRACT_DATE) );
          exception
            when no_data_found then
              aIndiceVariable  := null;
          end;

          -- Pas d'indice => pas de date d'initialisation de l'indice
          if aIndiceVariable is null then
            aIndiceVariable  := tplCpoRow.CPO_INDICE_VARIABLE;
          end if;

          aIndiceVarDate  := nvl(tplCpoRow.CPO_NEXT_DATE, tplCpoRow.CPO_BEGIN_CONTRACT_DATE);
        end if;

        -- Indexation du montant si l'indice a chang�
        if     (aIndiceVariable is not null)
           and (aIndiceVariable <> tplCpoRow.CPO_INDICE) then
          aInvoiceAmount  := (aInvoiceAmount / tplCpoRow.CPO_INDICE) * aIndiceVariable;
        end if;
      end if;
    end if;
  end ApplyVariableIndice;

  /**
  * procedure CalculateConsommStmt
  * Description
  *    Calcul de la consommation compteur
  */
  procedure CalculateConsommStmt(
    aDetailMachineID      in     CML_POSITION_MACHINE_DETAIL.CML_POSITION_MACHINE_DETAIL_ID%type
  , aServiceDetailID      in     CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type
  , aCustomerID           in     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aEstimLackStmt        in     number
  , aExtractDate          in     date
  , aFreeQty              out    ASA_COUNTER_STATEMENT.CST_STATEMENT_FREE_QUANTITY%type
  , aCounterStmtBegin     out    ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type
  , aCounterStmtBeginDate out    ASA_COUNTER_STATEMENT.CST_STATEMENT_DATE%type
  , aCounterStmtEnd       out    ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type
  , aCounterStmtEndDate   out    ASA_COUNTER_STATEMENT.CST_STATEMENT_DATE%type
  , aCounterStmtListID    out    TCST_ID_TABLE
  , aGrossQty             out    number
  , aNetQty               out    number
  , aInRenewalPeriod      out    number
  )
  is
    -- Liste des compteurs valid�s
    cursor crCounterStmtList(cPeriodBeginDate in date)
    is
      select   CST.CST_STATEMENT_DATE
             , nvl(CST.CST_STATEMENT_QUANTITY, 0) CST_STATEMENT_QUANTITY
             , nvl(CST.CST_STATEMENT_FREE_QUANTITY, 0) CST_STATEMENT_FREE_QUANTITY
             , CST.ASA_COUNTER_STATEMENT_ID
          from ASA_COUNTER_STATEMENT CST
             , CML_POSITION_MACHINE_DETAIL CMD
             , CML_POSITION_MACHINE CML
             , CML_POSITION CPO
             , CML_DOCUMENT CCO
         where CMD.CML_POSITION_MACHINE_DETAIL_ID = aDetailMachineID
           and CST.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID
           and CST.C_COUNTER_STATEMENT_STATUS = '1'
           and CST.PAC_CUSTOM_PARTNER_ID = CCO.PAC_CUSTOM_PARTNER_ID
           and CST.CST_STATEMENT_DATE between nvl(cPeriodBeginDate, CST.CST_STATEMENT_DATE) and trunc(aExtractDate)
           and CMD.CML_POSITION_MACHINE_ID = CML.CML_POSITION_MACHINE_ID
           and CML.CML_POSITION_ID = CPO.CML_POSITION_ID
           and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
      order by CST.CST_STATEMENT_DATE;

    tplCounterStmtList      crCounterStmtList%rowtype;
    bCounterExist           boolean                                               default false;
    vCML_COUNTER_STMT_MARGE integer                                               default 0;
    vBeginRenewalPeriod     date;
    vCounterStmtID          ASA_COUNTER_STATEMENT.ASA_COUNTER_STATEMENT_ID%type   default null;
    vCpt                    integer                                               default 0;
  begin
    aFreeQty             := 0;
    aCounterStmtEnd      := 0;
    aCounterStmtEndDate  := null;
    aGrossQty            := 0;
    aNetQty              := 0;
    aInRenewalPeriod     := 0;

    -- V�rifier si en p�riode de renouvellement des avoirs
    begin
      select abs(sign(nvl(max(CPD.CML_POSITION_SERVICE_DETAIL_ID), 0) ) )
        into aInRenewalPeriod
        from CML_POSITION_SERVICE CPS
           , CML_POSITION_SERVICE_DETAIL CPD
           , GCO_GOOD GOO
           , CML_PROCESSING CPR
       where CPD.CML_POSITION_SERVICE_DETAIL_ID = aServiceDetailID
         and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
         and CPS.GCO_CML_SERVICE_ID = GOO.GCO_GOOD_ID
         and GOO.C_SERVICE_KIND = '1'
         and CPD.C_SERVICE_RENEWAL in('1', '4')
         and CPD.CML_POSITION_SERVICE_DETAIL_ID = CPR.CML_POSITION_SERVICE_DETAIL_ID
         and CPR.C_CML_PROCESSING_TYPE = '200'
         and (    (instr(CPR.CPR_MONTHS, to_char(aExtractDate, 'MM') ) > 0)
              or (CPD.CPD_EXPIRY_DATE < trunc(aExtractDate) ) );
    exception
      when no_data_found then
        aInRenewalPeriod  := 0;
    end;

    -- Si en p�riode de renouvellement
    if aInRenewalPeriod = 1 then
      -- En p�riode de renouvellement

      -- Rechercher la config. d�finissant le d�calage de d�but de p�riode de
      -- renouvellement, pour la recherche des compteurs valides dans cette p�riode
      begin
        select to_number(PCS.PC_CONFIG.GETCONFIG('CML_COUNTER_STMT_MARGE') )
          into vCML_COUNTER_STMT_MARGE
          from dual;
      exception
        when others then
          null;
      end;

      -- Trouver la date de d�but de la p�riode de renouvellement
      vBeginRenewalPeriod  :=
          CML_CONTRACT_FUNCTIONS.GetRenewalPeriodDate(aDate               => aExtractDate, aServiceDetailID => aServiceDetailID
                                                    , aCounterStmtMarge   => vCML_COUNTER_STMT_MARGE);
    else
      -- Pas en p�riode de renouvellement
      -- Rechercher tous les compteurs valid�s jusqu'� la date d'extraction
      vBeginRenewalPeriod  := null;
    end if;

    -- Pas en p�riode de renouvellement
    -- V�rifier s'il y a des compteurs valid�s
    open crCounterStmtList(vBeginRenewalPeriod);

    fetch crCounterStmtList
     into tplCounterStmtList;

    -- Compteurs
    if crCounterStmtList%found then
      bCounterExist  := true;
    else
      -- Pas de compteurs valid�s pour l'installation demand�e

      -- Estimation des compteurs manquants
      if (aEstimLackStmt = 1) then
        GenerateEstimStmt(aDetailMachineID   => aDetailMachineID
                        , aServiceDetailID   => aServiceDetailID
                        , aCustomerID        => aCustomerID
                        , aExtractDate       => aExtractDate
                        , aCounterStmtID     => vCounterStmtID
                        , aStmtQty           => aCounterStmtEnd
                         );
      end if;

      -- Un compteur a �t� cr�� par l'estimation des compteurs
      if vCounterStmtID is not null then
        bCounterExist  := true;
      else
        bCounterExist  := false;
      end if;
    end if;

    close crCounterStmtList;

    -- Calcul de la consommation si compteur existe
    if bCounterExist then
      vCpt  := 0;

      -- Balayer les compteurs valid�s
      for tplCounterStmtList in crCounterStmtList(null) loop
        -- Adition des qt�s gratuites
        aFreeQty                  := aFreeQty + tplCounterStmtList.CST_STATEMENT_FREE_QUANTITY;

        -- Sauvegarder les donn�es du dernier compteur (le plus r�cent) � facturer
        if tplCounterStmtList.CST_STATEMENT_DATE >= nvl(aCounterStmtEndDate, tplCounterStmtList.CST_STATEMENT_DATE) then
          aCounterStmtEnd      := tplCounterStmtList.CST_STATEMENT_QUANTITY;
          aCounterStmtEndDate  := tplCounterStmtList.CST_STATEMENT_DATE;
        end if;

        vCpt                      := vCpt + 1;
        aCounterStmtListID(vCpt)  := tplCounterStmtList.ASA_COUNTER_STATEMENT_ID;
      end loop;

      -- Etat compteur derni�re facture ou �tat compteur d�but contat
      select nvl(CMD.CMD_LAST_INVOICE_STATEMENT, CMD.CMD_INITIAL_STATEMENT)
        into aCounterStmtBegin
        from CML_POSITION_MACHINE_DETAIL CMD
       where CMD.CML_POSITION_MACHINE_DETAIL_ID = aDetailMachineID;

      -- Rechercher Date derni�re facture
      select max(CST.CST_STATEMENT_DATE)
        into aCounterStmtBeginDate
        from ASA_COUNTER_STATEMENT CST
           , CML_POSITION_MACHINE_DETAIL CMD
           , CML_POSITION_MACHINE CML
           , CML_POSITION CPO
           , CML_DOCUMENT CCO
       where CMD.CML_POSITION_MACHINE_DETAIL_ID = aDetailMachineID
         and CST.ASA_COUNTER_ID = CMD.ASA_COUNTER_ID
         and CST.C_COUNTER_STATEMENT_STATUS = '3'
         and CST.PAC_CUSTOM_PARTNER_ID = CCO.PAC_CUSTOM_PARTNER_ID
         and CMD.CML_POSITION_MACHINE_ID = CML.CML_POSITION_MACHINE_ID
         and CML.CML_POSITION_ID = CPO.CML_POSITION_ID
         and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID;

      -- Si pas de Date derni�re facture, utiliser Date d�but contrat
      if aCounterStmtBeginDate is null then
        select CPO.CPO_BEGIN_CONTRACT_DATE
          into aCounterStmtBeginDate
          from CML_POSITION_MACHINE_DETAIL CMD
             , CML_POSITION_MACHINE CML
             , CML_POSITION CPO
         where CMD.CML_POSITION_MACHINE_DETAIL_ID = aDetailMachineID
           and CMD.CML_POSITION_MACHINE_ID = CML.CML_POSITION_MACHINE_ID
           and CML.CML_POSITION_ID = CPO.CML_POSITION_ID;
      end if;

      -- Calcul de la qt� consomm�e brutte et nette
      if aCounterStmtBegin is not null then
        aGrossQty  := aCounterStmtEnd - aCounterStmtBegin;
        aNetQty    := aGrossQty - aFreeQty;
      end if;
    end if;
  end CalculateConsommStmt;

  /**
  * procedure GenerateEstimStmt
  * Description
  *    Appel de la m�thode d'estimation des compteurs Indiv et cr�ation d'un
  *    �tat compteur si quantit� renvoy�e par l'utilisateur <> null
  */
  procedure GenerateEstimStmt(
    aDetailMachineID in     CML_POSITION_MACHINE_DETAIL.CML_POSITION_MACHINE_DETAIL_ID%type
  , aServiceDetailID in     CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type
  , aCustomerID      in     CML_DOCUMENT.PAC_CUSTOM_PARTNER_ID%type
  , aExtractDate     in     date
  , aCounterStmtID   out    ASA_COUNTER_STATEMENT.ASA_COUNTER_STATEMENT_ID%type
  , aStmtQty         out    ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type
  )
  is
    vASA_COUNTER_ESTIM_PROC varchar2(2000);
    vSQL_Command            varchar2(32000);
  begin
    aCounterStmtID           := null;
    aStmtQty                 := null;
    -- Config ASA_COUNTER_ESTIM_PROC
    --   Nom de la proc�dure PL/SQL utilisateur � lancer pour l'estimation des compteurs
    vASA_COUNTER_ESTIM_PROC  := PCS.PC_CONFIG.GETCONFIG('ASA_COUNTER_ESTIM_PROC');

    if vASA_COUNTER_ESTIM_PROC is not null then
      -- Cr�ation d'un �tat compteur par estimation pour le compteur associ�
      vSQL_Command  :=
        'begin ' ||
        chr(10) ||
        ' :STM_QTY := ' ||
        vASA_COUNTER_ESTIM_PROC ||
        '(:DETAIL_MACHINE_ID, :SERVICE_DETAIL_ID, :EXTRACT_DATE, :CUSTOMER_ID);' ||
        chr(10) ||
        'end;';

      execute immediate vSQL_Command
                  using out aStmtQty, in aDetailMachineID, in aServiceDetailID, in aExtractDate, in aCustomerID;

      -- Cr�ation d'un �tat compteur si quantit� estim�e <> null
      if aStmtQty is not null then
        select INIT_ID_SEQ.nextval
          into aCounterStmtID
          from dual;

        -- Cr�ation de l'�tat compteur
        insert into ASA_COUNTER_STATEMENT
                    (ASA_COUNTER_STATEMENT_ID
                   , ASA_COUNTER_ID
                   , C_COUNTER_STATEMENT_STATUS
                   , CST_STATEMENT_DATE
                   , CST_STATEMENT_QUANTITY
                   , CST_STATEMENT_FREE_QUANTITY
                   , PAC_CUSTOM_PARTNER_ID
                   , DIC_COUNTER_ACQUIRE_MODE_ID
                   , A_IDCRE
                   , A_DATECRE
                    )
          select aCounterStmtID
               , CMD.ASA_COUNTER_ID
               , '1'
               , aExtractDate
               , aStmtQty
               , 0
               , aCustomerID
               , (select min(DIC_COUNTER_ACQUIRE_MODE_ID)
                    from DIC_COUNTER_ACQUIRE_MODE
                   where DAM_ESTIMATED = 1)
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
            from CML_POSITION_MACHINE_DETAIL CMD
           where CMD.CML_POSITION_MACHINE_DETAIL_ID = aDetailMachineID;
      end if;
    end if;
  end GenerateEstimStmt;

  /**
  * procedure PreparePeriodicInvoice
  * Description
  *    Proposition des montants p�riodiques � facturer
  */
  procedure PreparePeriodicInvoice(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type, aExtractParamsInfo in TExtractParamsInfo)
  is
  begin
    for tplPos in (select   CML_POSITION_ID
                       from CML_POSITION CPO
                          , COM_LIST_ID_TEMP LID
                      where LID.COM_LIST_ID_TEMP_ID = CPO.CML_POSITION_ID
                        -- Pas de code traitement de facturation
                        and CPO.C_CML_POS_TREATMENT <> '00'
                        and (    (    aExtractParamsInfo.INJ_ONLY_FIRST_INVOICE = 0
                                  and trunc(nvl(CPO.CPO_NEXT_DATE, CPO.CPO_BEGIN_CONTRACT_DATE) ) <= aExtractParamsInfo.INJ_EXTRACTION_DATE
                                  and (   -- Actif ou Actif prolong�
                                          (CPO.C_CML_POS_STATUS in('02', '03') )
                                       -- R�sili�
                                       or (    CPO.C_CML_POS_STATUS = '06'
                                           and trunc(nvl(CPO.CPO_RESILIATION_DATE, aExtractParamsInfo.INJ_EXTRACTION_DATE) ) >
                                                                                                                          aExtractParamsInfo.INJ_EXTRACTION_DATE
                                          )
                                       -- Suspendu
                                       or (    CPO.C_CML_POS_STATUS = '07'
                                           and trunc(nvl(CPO.CPO_SUSPENSION_DATE, aExtractParamsInfo.INJ_EXTRACTION_DATE) ) >
                                                                                                                          aExtractParamsInfo.INJ_EXTRACTION_DATE
                                          )
                                      )
                                 )
                             -- 1ere Facture uniquement
                             or (    aExtractParamsInfo.INJ_ONLY_FIRST_INVOICE = 1
                                 and CPO.C_CML_POS_STATUS = '02'
                                 and CPO.CPO_NEXT_DATE is null
                                 and trunc(CPO.CPO_BEGIN_CONTRACT_DATE) <= aExtractParamsInfo.INJ_EXTRACTION_DATE
                                )
                            )
                   order by CPO.CML_DOCUMENT_ID
                          , CPO.CML_POSITION_ID) loop
      -- Insertion des montants � facturer
      PrepareAmountInvoice(aJobID => aJobID, aPositionID => tplPos.CML_POSITION_ID, aExtractDate => aExtractParamsInfo.INJ_EXTRACTION_DATE);
    end loop;
  end PreparePeriodicInvoice;

  /**
  * procedure PrepareAmountInvoice
  * Description
  *    Insertion des montants � facturer
  * @created NGV - Mars 2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure PrepareAmountInvoice(
    aJobID       in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type
  , aPositionID  in CML_POSITION.CML_POSITION_ID%type
  , aExtractDate in date
  )
  is
    cursor crPosInfo
    is
      select CPO.ACS_FINANCIAL_CURRENCY_ID
           , CPO.C_CML_INVOICE_UNIT
           , CPO.C_CML_POS_STATUS
           , CPO.C_CML_TIME_UNIT
           , CPO.CPO_BEGIN_CONTRACT_DATE
           , CPO.CPO_END_CONTRACT_DATE
           , CPO.CPO_END_EXTENDED_DATE
           , CPO.CPO_SUSPENSION_DATE
           , CPO.CPO_RESILIATION_DATE
           , CPO.CPO_DEPOT_AMOUNT
           , CPO.CPO_DEPOT_BILL_DATE
           , CPO.CPO_DEPOT_CN_DATE
           , CPO.CPO_DEPOT_GOOD_ID
           , CPO.CPO_EXTEND_PERIOD_PRICE
           , CPO.CPO_INIT_PERIOD_PRICE
           , CPO.CPO_MULTIYEAR
           , CPO.CPO_NEXT_DATE
           , CPO.CPO_PENALITY_AMOUNT
           , CPO.CPO_PENALITY_BILL_DATE
           , CPO.CPO_PENALITY_GOOD_ID
           , CPO.CPO_POS_GOOD_ID
           , CPO.CPO_PRORATA
        from CML_POSITION CPO
       where CPO.CML_POSITION_ID = aPositionID;

    tplPosInfo              crPosInfo%rowtype;
    vContractPrice          CML_POSITION.CPO_INIT_PERIOD_PRICE%type;
    vInvoicingAmount        number(16, 2);
    vRenewalBeginDate       date;
    vBeginPeriodDate        date;
    vEndPeriodDate          date;
    vInvoicingDate          date;
    vSaveInvDate            date;
    vNextDate               date;
    vNbMonths               number(16, 4);
    bContinue               boolean;
    vCountService           integer                                   default 0;
    vCountEvents            integer                                   default 0;
    vCML_COUNTER_STMT_MARGE integer                                   default 0;
    vPosExpired             number(1)                                 default 0;
  begin
    open crPosInfo;

    fetch crPosInfo
     into tplPosInfo;

    if crPosInfo%found then
      -- Statut Actif , Actif prolong� , Suspendu ou R�sili�
      if tplPosInfo.C_CML_POS_STATUS in('02', '03', '06', '07') then
        -- Date prochaine �ch�ance
        if tplPosInfo.CPO_NEXT_DATE is null then
          -- Facture initiale
          vBeginPeriodDate  := tplPosInfo.CPO_BEGIN_CONTRACT_DATE;
          bContinue         := true;
        else
          -- Facture p�riodique
          vBeginPeriodDate  := tplPosInfo.CPO_NEXT_DATE;

          -- Recherche si existe une prestation de nature 1 et de type 1 dont
          -- le code de traitement '200' est activ� pour le mois � analyser
          select count(CPD.CML_POSITION_SERVICE_DETAIL_ID)
            into vCountService
            from CML_POSITION_SERVICE CPS
               , CML_POSITION_SERVICE_DETAIL CPD
               , GCO_GOOD GOO
               , CML_PROCESSING CPR
           where CPS.CML_POSITION_ID = aPositionID
             and CPS.GCO_CML_SERVICE_ID = GOO.GCO_GOOD_ID
             and GOO.C_SERVICE_KIND in('1', '2')
             and CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
             and CPD.C_SERVICE_RENEWAL in('1', '4')
             and CPD.CML_POSITION_SERVICE_DETAIL_ID = CPR.CML_POSITION_SERVICE_DETAIL_ID
             and CPR.C_CML_PROCESSING_TYPE = '200'
             and (    (instr(CPR.CPR_MONTHS, to_char(aExtractDate, 'MM') ) > 0)
                  or (CPD.CPD_EXPIRY_DATE < trunc(aExtractDate) ) );

          -- Pas de prestation ci-dessus mentionn�e
          if vCountService = 0 then
            bContinue  := true;
          else
            -- Rechercher la config. d�finissant le d�calage de d�but de p�riode de
            -- renouvellement, pour la recherche des compteurs valides dans cette p�riode
            begin
              select to_number(PCS.PC_CONFIG.GETCONFIG('CML_COUNTER_STMT_MARGE') )
                into vCML_COUNTER_STMT_MARGE
                from dual;
            exception
              when others then
                null;
            end;

            -- Rechercher la date de d�but de p�riode de renouvellement
            vRenewalBeginDate  := add_months(last_day(tplPosInfo.CPO_NEXT_DATE) + 1, -1) - vCML_COUNTER_STMT_MARGE;

            -- Contr�le si existe un �v�nement non-factur� de type '5'
            --  en relation avec un �tat compteur de la p�riode de renouvellement
            select count(CEV.CML_EVENTS_ID)
              into vCountEvents
              from CML_EVENTS CEV
                 , ASA_COUNTER_STATEMENT CST
             where CEV.CML_POSITION_ID = aPositionID
               and CEV.DOC_POSITION_ID is null
               and CEV.C_CML_EVENT_TYPE = '5'
               and CEV.CML_EVENTS_ID = CST.CML_EVENTS_ID
               and CST.CST_STATEMENT_DATE between vRenewalBeginDate and aExtractDate;

            if vCountEvents = 0 then
              -- Pas possible de facturer un forfait avec renouvellement
              -- prestation, si pas de compteur disponnible
              bContinue  := false;
            else
              bContinue  := true;
            end if;
          end if;
        end if;

        if bContinue then
          -- Recherche de la prochaine date de facturation
          -- Unit� prorata = Jour
          if tplPosInfo.C_CML_TIME_UNIT = '1' then
            -- Prochaine date de facturation, sans recadrer au d�but du mois
            select min(NEXT_INVOICING_DATE)
              into vEndPeriodDate
              from (select add_months(trunc(vBeginPeriodDate), MTH.MONTH_NUMBER) NEXT_INVOICING_DATE
                         , CPR.CPR_MONTHS
                      from CML_PROCESSING CPR
                         , (select no MONTH_NUMBER
                              from PCS.PC_NUMBER
                             where no <= 48) MTH
                     where CPR.CML_POSITION_ID = aPositionID
                       and CPR.C_CML_PROCESSING_TYPE = '100')
             where instr(CPR_MONTHS, to_char(NEXT_INVOICING_DATE, 'MM') ) > 0
               and NEXT_INVOICING_DATE > aExtractDate;

            -- P�riodicit� sur plusieurs ann�es = Non
            if tplPosInfo.CPO_MULTIYEAR = 0 then
              -- La fin de p�riode de facturation est recadr�e au 1er jour du mois
              select trunc(vEndPeriodDate, 'MM')
                into vEndPeriodDate
                from dual;
            end if;
          else
            -- Unit� prorata = Mois
            select min(NEXT_INVOICING_DATE)
              into vEndPeriodDate
              from (select to_date('01.' || MTH.MONTH_NUMBER || '.' || YEA.YEAR_NUMBER, 'DD.MM.YYYY') NEXT_INVOICING_DATE
                      from CML_PROCESSING CPR
                         , (select lpad(to_char(no), 2, '0') MONTH_NUMBER
                              from PCS.PC_NUMBER
                             where no <= 12) MTH
                         , (select no YEAR_NUMBER
                              from PCS.PC_NUMBER
                             where no >= to_number(to_char(vBeginPeriodDate, 'YYYY') )
                               and no <= to_number(to_char(vBeginPeriodDate, 'YYYY') ) + 4) YEA
                     where CPR.CML_POSITION_ID = aPositionID
                       and CPR.C_CML_PROCESSING_TYPE = '100'
                       and instr(CPR.CPR_MONTHS, MTH.MONTH_NUMBER) > 0)
             where NEXT_INVOICING_DATE > aExtractDate;
          end if;

          -- Tenir compte date de suspension/r�siliation
          select min(END_PERIOD_DATE)
            into vInvoicingDate
            from (select vEndPeriodDate END_PERIOD_DATE
                    from dual
                  union
                  select case
                           when nvl(tplPosInfo.CPO_END_EXTENDED_DATE, tplPosInfo.CPO_END_CONTRACT_DATE) is not null then nvl
                                                                                                                            (tplPosInfo.CPO_END_EXTENDED_DATE
                                                                                                                           , tplPosInfo.CPO_END_CONTRACT_DATE
                                                                                                                            ) +
                                                                                                                         1
                           else null
                         end END_PERIOD_DATE
                    from dual
                  union
                  select case
                           when tplPosInfo.CPO_SUSPENSION_DATE is not null then tplPosInfo.CPO_SUSPENSION_DATE + 1
                           else null
                         end END_PERIOD_DATE
                    from dual
                  union
                  select case
                           when tplPosInfo.CPO_RESILIATION_DATE is not null then tplPosInfo.CPO_RESILIATION_DATE + 1
                           else null
                         end END_PERIOD_DATE
                    from dual);

          -- Facturation d'une p�riode qui chevauche une p�riode standard et
          -- une p�riode de prolongation
          if     (vBeginPeriodDate < nvl(tplPosInfo.CPO_END_CONTRACT_DATE, vBeginPeriodDate) )
             and (vInvoicingDate - 1 > nvl(tplPosInfo.CPO_END_CONTRACT_DATE, vInvoicingDate - 1) )
             and (tplPosInfo.CPO_END_EXTENDED_DATE is not null) then
            vSaveInvDate      := vInvoicingDate;
            --
            vContractPrice    := tplPosInfo.CPO_INIT_PERIOD_PRICE;
            vInvoicingDate    := tplPosInfo.CPO_END_CONTRACT_DATE + 1;
            vNextDate         := vInvoicingDate;

            -- Si la date de facturation est plus petite que la date d�but p�riode
            -- cela veut dire que l'on est en train d'effectuer un remboursement.
            if vInvoicingDate < vBeginPeriodDate then
              -- Remboursement
              --
              -- R�cuperer le nbr mois pour le remboursement
              vNbMonths  := CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate);

              -- Si Code prorata pas coch�
              if (tplPosInfo.CPO_PRORATA = 0) then
                -- Arrondir le nbr de moi � l'entier inf�rieur
                vNbMonths  := trunc(vNbMonths);
              end if;
            else
              -- Facturation
              --
              -- Unit� prorata = Jour
              if tplPosInfo.C_CML_TIME_UNIT = '1' then
                -- R�cuperer le nbr mois pour la facturation
                vNbMonths  := CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate - 1);
              else   -- Unit� prorata = Mois
                -- R�cuperer le nbr mois pour la facturation
                vNbMonths  := round(CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate) );
              end if;
            end if;

            -- Montant = Nbr Mois * Prix (exprim� dans la bonne unit�)
            vInvoicingAmount  := vNbMonths *(vContractPrice / to_number(tplPosInfo.C_CML_INVOICE_UNIT) );
            -- Insertion d'une position pour facturation
            InsertPositionInvoice(aJobID                 => aJobID
                                , aPositionID            => aPositionID
                                , aProcessType           => 'FIXEDPRICE'
                                , aGoodID                => tplPosInfo.CPO_POS_GOOD_ID
                                , aAmount                => vInvoicingAmount
                                , aCurrencyID            => tplPosInfo.ACS_FINANCIAL_CURRENCY_ID
                                , aExtractDate           => aExtractDate
                                , aBeginLastPeriodDate   => vBeginPeriodDate
                                , aEndLastPeriodDate     => vInvoicingDate - 1
                                , aNextDate              => vNextDate
                                 );
            vBeginPeriodDate  := tplPosInfo.CPO_END_CONTRACT_DATE + 1;
            vInvoicingDate    := vSaveInvDate;
          end if;

          -- Date fin de p�riode
          vEndPeriodDate    := vInvoicingDate - 1;

          -- Contrat r�sili� ET date de facturation est au-delas de la date de r�siliation
          -- Cela veut dire que l'on veut effectuer un remboursement d'une p�riode d�j� factur�e
          if     (tplPosInfo.C_CML_POS_STATUS = '06')
             and (tplPosInfo.CPO_RESILIATION_DATE < vInvoicingDate)
             and (vBeginPeriodDate > vEndPeriodDate) then
            -- Ici les dates sont invers�es volontairement pour avoir un montant
            -- n�gatif (remboursement)
            vEndPeriodDate    := vInvoicingDate;
            vBeginPeriodDate  := vBeginPeriodDate - 1;
          end if;

          -- Si en p�riode de prolongation, utiliser le prix de p�riode prolongation
          -- Sinon utiliser prix p�riode initiale
          if (tplPosInfo.CPO_END_CONTRACT_DATE < vBeginPeriodDate) then
            vContractPrice  := tplPosInfo.CPO_EXTEND_PERIOD_PRICE;
          else
            vContractPrice  := tplPosInfo.CPO_INIT_PERIOD_PRICE;
          end if;

          -- Date de prochaine �ch�ance
          vNextDate         := vInvoicingDate;

          -- Si date de facturation est au-del� de la date pr�vue de fin de contrat
          -- Si facturation de la derni�re p�riode du contrat, alors position devient �chue
          if    (     (nvl(tplPosInfo.CPO_END_EXTENDED_DATE, tplPosInfo.CPO_END_CONTRACT_DATE) is not null)
                 and (vInvoicingDate > nvl(tplPosInfo.CPO_END_EXTENDED_DATE, tplPosInfo.CPO_END_CONTRACT_DATE) )
                )
             or (vInvoicingDate > nvl(tplPosInfo.CPO_RESILIATION_DATE, vInvoicingDate) ) then
            vPosExpired  := 1;
          end if;

          -- Si la date de facturation est plus petite que la date d�but p�riode
          -- cela veut dire que l'on est en train d'effectuer un remboursement.
          if vInvoicingDate < vBeginPeriodDate then
            -- Remboursement
            --
            -- R�cuperer le nbr mois pour le remboursement
            vNbMonths  := CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate);

            -- Si Code prorata pas coch�
            if (tplPosInfo.CPO_PRORATA = 0) then
              -- Arrondir le nbr de moi � l'entier inf�rieur
              vNbMonths  := trunc(vNbMonths);
            end if;
          else
            -- Facturation
            --
            -- Unit� prorata = Jour
            if tplPosInfo.C_CML_TIME_UNIT = '1' then
              -- Ne pas facturer, si la position est r�sili�e et que la date de fin est au-delas de la date de r�siliation
              if     (tplPosInfo.C_CML_POS_STATUS = '06')
                 and (vEndPeriodDate > tplPosInfo.CPO_RESILIATION_DATE) then
                -- Ne pas facturer
                vNbMonths  := 0;
              else
                -- R�cuperer le nbr mois pour la facturation
                vNbMonths  := CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate - 1);
              end if;
            else   -- Unit� prorata = Mois
              -- R�cuperer le nbr mois pour la facturation
              vNbMonths  := round(CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vBeginPeriodDate, vInvoicingDate) );
            end if;
          end if;

          -- Montant = Nbr Mois * Prix (exprim� dans la bonne unit�)
          vInvoicingAmount  := vNbMonths *(vContractPrice / to_number(tplPosInfo.C_CML_INVOICE_UNIT) );

          -- Facturer uniquement si montant � facturer est different de 0
          if not(     (vPosExpired = 1)
                 and (vInvoicingAmount = 0) ) then
            -- Insertion d'une position pour facturation
            InsertPositionInvoice(aJobID                 => aJobID
                                , aPositionID            => aPositionID
                                , aProcessType           => 'FIXEDPRICE'
                                , aGoodID                => tplPosInfo.CPO_POS_GOOD_ID
                                , aAmount                => vInvoicingAmount
                                , aCurrencyID            => tplPosInfo.ACS_FINANCIAL_CURRENCY_ID
                                , aExtractDate           => aExtractDate
                                , aBeginLastPeriodDate   => vBeginPeriodDate
                                , aEndLastPeriodDate     => vEndPeriodDate
                                , aNextDate              => vNextDate
                                , aPosExpired            => vPosExpired
                                 );
          end if;
        end if;
      end if;
    end if;

    close crPosInfo;
  end PrepareAmountInvoice;

  /**
  * procedure InsertPositionInvoice
  * Description
  *    Insertion d'une position � facturer dans la table des
  *      propositions de facturation
  */
  procedure InsertPositionInvoice(
    aJobID               in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type
  , aPositionID          in CML_POSITION.CML_POSITION_ID%type
  , aProcessType         in CML_INVOICING_PROCESS.C_INVOICING_PROCESS_TYPE%type
  , aGoodID              in GCO_GOOD.GCO_GOOD_ID%type
  , aAmount              in number
  , aCurrencyID          in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aExtractDate         in date
  , aBeginLastPeriodDate in date
  , aEndLastPeriodDate   in date
  , aNextDate            in date
  , aPosExpired          in number default 0
  )
  is
    cursor crPosInfo
    is
      select CPO.CML_DOCUMENT_ID
           , CPO.CML_POSITION_ID
           , CPO.C_CML_POS_STATUS
           , CPO.CPO_NEXT_DATE
           , CPO.CPO_INDICE
           , CPO.CPO_INDICE_VARIABLE
           , CPO.CPO_INDICE_V_DATE
           , CPO.C_CML_POS_INDICE_V_VALID
           , CPO.DIC_CML_INVOICE_REGROUPING_ID
           , CCO.PAC_CUSTOM_PARTNER_ID
           , nvl(CCO.PAC_CUSTOM_PARTNER_ACI_ID, nvl(CUS.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID) ) PAC_CUSTOM_PARTNER_ACI_ID
           , CCO.PAC_PAYMENT_CONDITION_ID
        from CML_POSITION CPO
           , CML_DOCUMENT CCO
           , PAC_CUSTOM_PARTNER CUS
       where CPO.CML_POSITION_ID = aPositionID
         and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
         and CCO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID;

    tplPosInfo              crPosInfo%rowtype;
    cfgDefaultPosIndiceCode varchar2(10);
    vAmount                 CML_INVOICING_PROCESS.INP_AMOUNT%type;
    vIndiceVariable         CML_POSITION.CPO_INDICE_VARIABLE%type   default null;
    vIndiceVarDate          CML_POSITION.CPO_INDICE_V_DATE%type;
    vInvProcess             CML_INVOICING_PROCESS%rowtype;
  begin
    open crPosInfo;

    fetch crPosInfo
     into tplPosInfo;

    if crPosInfo%found then
      -- Config CML_DEFAULT_POS_INDICE_CODE
      --    Valeur par d�faut du code d'exploitation des indices lors de la facturation des forfaits
      select upper(nvl(PCS.PC_CONFIG.GETCONFIG('CML_DEFAULT_POS_INDICE_CODE'), 'FALSE') )
        into cfgDefaultPosIndiceCode
        from dual;

      -- Utilisation de la variable locale pour le calcul du montant
      vAmount                                    := aAmount;

      -- Application de l'indice des prix
      if     (cfgDefaultPosIndiceCode = 'TRUE')
         and (tplPosInfo.C_CML_POS_INDICE_V_VALID <> '00') then
        -- Application de l'indice des prix sur le montant � facturer
        ApplyVariableIndice(aPositionID => aPositionID, aInvoiceAmount => vAmount, aIndiceVariable => vIndiceVariable, aIndiceVarDate => vIndiceVarDate);
      else
        -- Pas d'adaptation du montant � facturer
        -- Reprendre les indices actuels de la position
        vIndiceVariable  := tplPosInfo.CPO_INDICE_VARIABLE;
        vIndiceVarDate   := tplPosInfo.CPO_INDICE_V_DATE;
      end if;

      vInvProcess.CML_INVOICING_JOB_ID           := aJobID;
      vInvProcess.C_INVOICING_PROCESS_TYPE       := aProcessType;
      vInvProcess.CML_DOCUMENT_ID                := tplPosInfo.CML_DOCUMENT_ID;
      vInvProcess.CML_POSITION_ID                := tplPosInfo.CML_POSITION_ID;
      vInvProcess.PAC_CUSTOM_PARTNER_ID          := tplPosInfo.PAC_CUSTOM_PARTNER_ID;
      vInvProcess.PAC_CUSTOM_PARTNER_ACI_ID      := tplPosInfo.PAC_CUSTOM_PARTNER_ACI_ID;
      vInvProcess.PAC_PAYMENT_CONDITION_ID       := tplPosInfo.PAC_PAYMENT_CONDITION_ID;
      vInvProcess.INP_AMOUNT                     := vAmount;
      vInvProcess.ACS_FINANCIAL_CURRENCY_ID      := aCurrencyID;
      vInvProcess.GCO_GOOD_ID                    := aGoodID;
      vInvProcess.INP_BEGIN_PERIOD_DATE          := aBeginLastPeriodDate;
      vInvProcess.INP_END_PERIOD_DATE            := aEndLastPeriodDate;

      -- S'assurer que la date de d�but est < que la date de fin
      if     (aBeginLastPeriodDate is not null)
         and (aEndLastPeriodDate is not null)
         and (aBeginLastPeriodDate > aEndLastPeriodDate) then
        vInvProcess.INP_BEGIN_PERIOD_DATE  := aEndLastPeriodDate;
        vInvProcess.INP_END_PERIOD_DATE    := aBeginLastPeriodDate;
      end if;

      vInvProcess.INP_NEXT_DATE                  := aNextDate;
      vInvProcess.INP_INDICE                     := tplPosInfo.CPO_INDICE;
      vInvProcess.INP_OLD_INDICE_VARIABLE        := tplPosInfo.CPO_INDICE_VARIABLE;
      vInvProcess.INP_OLD_INDICE_V_DATE          := tplPosInfo.CPO_INDICE_V_DATE;
      vInvProcess.INP_INDICE_VARIABLE            := vIndiceVariable;
      vInvProcess.INP_INDICE_V_DATE              := vIndiceVarDate;
      vInvProcess.INP_COUNTER_BEGIN_QTY          := null;
      vInvProcess.INP_COUNTER_END_QTY            := null;
      vInvProcess.INP_FREE_QTY                   := null;
      vInvProcess.INP_INVOICING_QTY              := 1;
      vInvProcess.INP_GROSS_CONSUMED_QTY         := null;
      vInvProcess.INP_NET_CONSUMED_QTY           := null;
      vInvProcess.INP_BALANCE_QTY                := null;
      vInvProcess.INP_POS_EXPIRED                := aPosExpired;
      vInvProcess.DIC_CML_INVOICE_REGROUPING_ID  := tplPosInfo.DIC_CML_INVOICE_REGROUPING_ID;
      --
      -- Insertion d'une proposition de facturation dans la table CML_INVOICING_PROCESS
      InsertCML_INVOICING_PROCESS(aRow => vInvProcess);
    end if;

    close crPosInfo;
  end InsertPositionInvoice;

  /**
  * procedure PrepareFinalInvoice
  * Description
  *    Proposition des factures finales
  * @created NGV - Mars 2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure PrepareFinalInvoice(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type, aExtractParamsInfo in TExtractParamsInfo)
  is
    vInvoicingAmount number(16, 2);
  begin
    -- Factures finales
    for tplPos in (select   CPO.CML_POSITION_ID
                          , CPO.CPO_PENALITY_AMOUNT
                          , CPO.CPO_PENALITY_BILL_DATE
                          , CPO.CPO_PENALITY_GOOD_ID
                          , CPO.CPO_BEGIN_CONTRACT_DATE
                          , CPO.ACS_FINANCIAL_CURRENCY_ID
                          , CPO.CPO_DEPOT_GOOD_ID
                          , CPO.CPO_DEPOT_AMOUNT
                          , CPO.CPO_DEPOT_BILL_DATE
                          , CPO.CPO_DEPOT_CN_DATE
                       from CML_POSITION CPO
                          , COM_LIST_ID_TEMP LID
                      where LID.COM_LIST_ID_TEMP_ID = CPO.CML_POSITION_ID
                        and (    (    CPO.C_CML_POS_STATUS = '04'
                                  and nvl(CPO.CPO_END_EXTENDED_DATE, CPO.CPO_END_CONTRACT_DATE) <= aExtractParamsInfo.INJ_EXTRACTION_DATE
                                 )
                             or (    CPO.C_CML_POS_STATUS = '06'
                                 and CPO.CPO_RESILIATION_DATE <= aExtractParamsInfo.INJ_EXTRACTION_DATE)
                            )
                   order by CPO.CML_DOCUMENT_ID
                          , CPO.CML_POSITION_ID) loop
      -- G�n�ration des �v�nements exc�dents consommation
      PrepareSurplusesConsom(aJobID           => aJobID
                           , aPositionID      => tplPos.CML_POSITION_ID
                           , aExtractDate     => aExtractParamsInfo.INJ_EXTRACTION_DATE
                           , aEstimLackStmt   => aExtractParamsInfo.INJ_ESTIM_LACK_STMT_INVOICING
                            );
      --
      -- Insertion des montants � facturer
      PrepareAmountInvoice(aJobID => aJobID, aPositionID => tplPos.CML_POSITION_ID, aExtractDate => aExtractParamsInfo.INJ_EXTRACTION_DATE);

      --
      -- Facturation de la p�nalit� si renseign�e et pas encore factur�e
      if     (nvl(tplPos.CPO_PENALITY_AMOUNT, 0) <> 0)
         and (tplPos.CPO_PENALITY_BILL_DATE is null) then
        -- Insertion d'une position pour facturation
        InsertPositionInvoice(aJobID                 => aJobID
                            , aPositionID            => tplPos.CML_POSITION_ID
                            , aProcessType           => 'PENALITY'
                            , aGoodID                => tplPos.CPO_PENALITY_GOOD_ID
                            , aAmount                => tplPos.CPO_PENALITY_AMOUNT
                            , aCurrencyID            => tplPos.ACS_FINANCIAL_CURRENCY_ID
                            , aExtractDate           => aExtractParamsInfo.INJ_EXTRACTION_DATE
                            , aBeginLastPeriodDate   => tplPos.CPO_BEGIN_CONTRACT_DATE
                            , aEndLastPeriodDate     => null
                            , aNextDate              => null
                             );
      end if;

      -- Rembourser le montant d�p�t si :
      --   Montant d�p�t contrat renseign�
      --   Date facture d�p�t renseign�e
      --   Date note de cr�dit du d�p�t vide
      if     (nvl(tplPos.CPO_DEPOT_AMOUNT, 0) <> 0)
         and (tplPos.CPO_DEPOT_BILL_DATE is not null)
         and (tplPos.CPO_DEPOT_CN_DATE is null) then
        -- Montant � cr�diter = Montant d�p�t contrat * -1
        vInvoicingAmount  := tplPos.CPO_DEPOT_AMOUNT * -1;
        -- Insertion d'une position pour facturation
        InsertPositionInvoice(aJobID                 => aJobID
                            , aPositionID            => tplPos.CML_POSITION_ID
                            , aProcessType           => 'DEPOSIT'
                            , aGoodID                => tplPos.CPO_DEPOT_GOOD_ID
                            , aAmount                => vInvoicingAmount
                            , aCurrencyID            => tplPos.ACS_FINANCIAL_CURRENCY_ID
                            , aExtractDate           => aExtractParamsInfo.INJ_EXTRACTION_DATE
                            , aBeginLastPeriodDate   => tplPos.CPO_BEGIN_CONTRACT_DATE
                            , aEndLastPeriodDate     => null
                            , aNextDate              => null
                             );
      end if;

      -- Insertion des �v�nements � facturer
      InsertEventsInvoice(aJobID                    => aJobID
                        , aPositionID               => tplPos.CML_POSITION_ID
                        , aExtractDate              => aExtractParamsInfo.INJ_EXTRACTION_DATE
                        , aEventsInvoice            => 1
                        , aSurplusesConsomInvoice   => 1
                         );
    end loop;
  end PrepareFinalInvoice;

  /**
  * procedure PrepareDepositInvoice
  * Description
  *    Proposition de la facturation des d�p�ts
  */
  procedure PrepareDepositInvoice(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type, aExtractParamsInfo in TExtractParamsInfo)
  is
  begin
    -- Factures finales
    for tplPos in (select   CML_POSITION_ID
                       from CML_POSITION CPO
                          , COM_LIST_ID_TEMP LID
                      where LID.COM_LIST_ID_TEMP_ID = CPO.CML_POSITION_ID
                        and CPO.C_CML_POS_STATUS in('02', '03')
                        and CPO.CPO_DEPOT_BILL_DATE is null
                        and nvl(CPO.CPO_DEPOT_AMOUNT, 0) <> 0
                   order by CPO.CML_DOCUMENT_ID
                          , CPO.CML_POSITION_ID) loop
      -- Insertion des d�p�ts � facturer
      InsertDepositInvoice(aJobID => aJobID, aPositionID => tplPos.CML_POSITION_ID, aExtractDate => aExtractParamsInfo.INJ_EXTRACTION_DATE);
    end loop;
  end PrepareDepositInvoice;

  /**
  * procedure InsertDepositInvoice
  * Description
  *    Insertion des d�p�ts � facturer dans la table des
  *      propositions de facturation
  */
  procedure InsertDepositInvoice(
    aJobID       in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type
  , aPositionID  in CML_POSITION.CML_POSITION_ID%type
  , aExtractDate in date
  )
  is
    cursor crPosInfo
    is
      select CPO.CML_DOCUMENT_ID
           , CPO.CML_POSITION_ID
           , CPO.ACS_FINANCIAL_CURRENCY_ID
           , CPO.DIC_CML_INVOICE_REGROUPING_ID
           , CCO.PAC_CUSTOM_PARTNER_ID
           , nvl(CCO.PAC_CUSTOM_PARTNER_ACI_ID, nvl(CUS.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID) ) PAC_CUSTOM_PARTNER_ACI_ID
           , CCO.PAC_PAYMENT_CONDITION_ID
           , CPO.CPO_DEPOT_AMOUNT
           , CPO.CPO_DEPOT_GOOD_ID
        from CML_POSITION CPO
           , CML_DOCUMENT CCO
           , PAC_CUSTOM_PARTNER CUS
       where CPO.CML_POSITION_ID = aPositionID
         and CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
         and CCO.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID;

    tplPosInfo  crPosInfo%rowtype;
    vInvProcess CML_INVOICING_PROCESS%rowtype;
  begin
    open crPosInfo;

    fetch crPosInfo
     into tplPosInfo;

    if crPosInfo%found then
      vInvProcess.CML_INVOICING_JOB_ID           := aJobID;
      vInvProcess.C_INVOICING_PROCESS_TYPE       := 'DEPOSIT';
      vInvProcess.CML_DOCUMENT_ID                := tplPosInfo.CML_DOCUMENT_ID;
      vInvProcess.CML_POSITION_ID                := tplPosInfo.CML_POSITION_ID;
      vInvProcess.PAC_CUSTOM_PARTNER_ID          := tplPosInfo.PAC_CUSTOM_PARTNER_ID;
      vInvProcess.PAC_CUSTOM_PARTNER_ACI_ID      := tplPosInfo.PAC_CUSTOM_PARTNER_ACI_ID;
      vInvProcess.PAC_PAYMENT_CONDITION_ID       := tplPosInfo.PAC_PAYMENT_CONDITION_ID;
      vInvProcess.ACS_FINANCIAL_CURRENCY_ID      := tplPosInfo.ACS_FINANCIAL_CURRENCY_ID;
      vInvProcess.GCO_GOOD_ID                    := tplPosInfo.CPO_DEPOT_GOOD_ID;
      vInvProcess.INP_AMOUNT                     := tplPosInfo.CPO_DEPOT_AMOUNT;
      vInvProcess.DIC_CML_INVOICE_REGROUPING_ID  := tplPosInfo.DIC_CML_INVOICE_REGROUPING_ID;
      --
      -- Insertion d'une proposition de facturation dans la table CML_INVOICING_PROCESS
      InsertCML_INVOICING_PROCESS(aRow => vInvProcess);
    end if;

    close crPosInfo;
  end InsertDepositInvoice;

  /**
  * procedure ServiceRenewal
  * Description
  *    Renouvellement des avoirs de prestation
  * @created NGV - Mars 2006
  * @lastUpdate
  * @public
  * @param
  */
  procedure ServiceRenewal(aPositionID in CML_POSITION.CML_POSITION_ID%type, aExtractDate in date)
  is
    vCPD_PERIOD_QTY       CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vCPD_EXPIRY_DATE      CML_POSITION_SERVICE_DETAIL.CPD_EXPIRY_DATE%type;
    vCOEFF                CML_POSITION_SERVICE_DETAIL.CPD_PERIOD_QTY%type;
    vNextRenewalPeriod    date;
    vCurrentRenewalPeriod date;
  begin
    -- Liste des prestations :
    --   "Type de prestation "  1 et 2
    --   Code Renouvellement
    --     1 : Avoir �puisable renouvable
    --     4 : Avoir �puisable - Renouvellement cumul�
    --   qui poss�dent un compteur valide dispo pour la facturation
    --     dont le "Type de traitement" = 200 est actif pour le mois analys�
    --     ou
    --     la date d'�ch�ance de l'avoir de la prestation est < � la date d'extraction
    for tplService in (select CPD.CML_POSITION_SERVICE_DETAIL_ID
                            , CPD.CPD_RENEWABLE_QTY
                            , CPD.CPD_PRORATA
                            , CPD.C_CML_TIME_UNIT
                            , CPD.C_SERVICE_RENEWAL
                            , nvl(CPD.CPD_BALANCE_QTY, 0) CPD_BALANCE_QTY
                            , CPO.CPO_END_CONTRACT_DATE
                            , CPO.CPO_END_EXTENDED_DATE
                            , CPO.CPO_SUSPENSION_DATE
                            , CPO.CPO_RESILIATION_DATE
                            , nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) GOO_NUMBER_OF_DECIMAL
                         from CML_POSITION CPO
                            , CML_POSITION_SERVICE CPS
                            , CML_POSITION_SERVICE_DETAIL CPD
                            , CML_PROCESSING CPR
                            , GCO_GOOD GOO
                        where CPO.CML_POSITION_ID = aPositionID
                          and CPO.CML_POSITION_ID = CPS.CML_POSITION_ID
                          and CPS.GCO_CML_SERVICE_ID = GOO.GCO_GOOD_ID
                          and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
                          and GOO.C_SERVICE_KIND in('1', '2')
                          and CPD.C_SERVICE_RENEWAL in('1', '4')
                          and CPD.CML_POSITION_SERVICE_DETAIL_ID = CPR.CML_POSITION_SERVICE_DETAIL_ID
                          and CPR.C_CML_PROCESSING_TYPE = '200'
                          and (    (instr(CPR.CPR_MONTHS, to_char(aExtractDate, 'MM') ) > 0)
                               or (CPD.CPD_EXPIRY_DATE < trunc(aExtractDate) ) )
                          and (select count(*)
                                 from CML_EVENTS
                                where CML_POSITION_ID = aPositionID
                                  and DOC_POSITION_ID is null
                                  and C_CML_EVENT_TYPE = '5'
                                  and CEV_RENEWAL_GENERATED = 1) > 0) loop
      /* Explications sur la recherche des dates
         pour la date de la p�riode actuelle on va utiliser le 1er jour du mois suivant
         Exemple
          Avoirs renouvelable 2x par ann�e (en janvier et Juillet)
          Donc si en janvier, pour le renouvellement on calcule le nbr de mois
          qu'il y a entre le 1. f�vrier et le 31 juillet

          A ce chiffre, on doit rajouter la valeur 1 car oracle nous renvoie
          5 avec la fonction months_between
      */

      -- Trouver la date de d�but de la p�riode de renouvellement actuelle
      vCurrentRenewalPeriod  :=
                              CML_CONTRACT_FUNCTIONS.GetRenewalPeriodDate(aDate              => aExtractDate
                                                                        , aServiceDetailID   => tplService.CML_POSITION_SERVICE_DETAIL_ID);
      -- Rechercher la date du prochain renouvellement
      vNextRenewalPeriod     :=
            CML_CONTRACT_FUNCTIONS.GetRenewalPeriodDate(aDate              => aExtractDate, aServiceDetailID => tplService.CML_POSITION_SERVICE_DETAIL_ID
                                                      , aBackPeriod        => 0);

      -- Date de l'�ch�ance de l'avoir
      select min(EXPIRY_DATE)
        into vCPD_EXPIRY_DATE
        from (select last_day(vNextRenewalPeriod) EXPIRY_DATE
                from dual
              union
              select case
                       when nvl(tplService.CPO_END_EXTENDED_DATE, tplService.CPO_END_CONTRACT_DATE) is not null then nvl(tplService.CPO_END_EXTENDED_DATE
                                                                                                                       , tplService.CPO_END_CONTRACT_DATE
                                                                                                                        )
                       else null
                     end EXPIRY_DATE
                from dual
              union
              select case
                       when tplService.CPO_SUSPENSION_DATE is not null then tplService.CPO_SUSPENSION_DATE
                       else null
                     end EXPIRY_DATE
                from dual
              union
              select case
                       when tplService.CPO_RESILIATION_DATE is not null then tplService.CPO_RESILIATION_DATE
                       else null
                     end EXPIRY_DATE
                from dual);

      -- Calcul de la date du prochain renouvellement ou fin de contrat ou fin prolong. contrat
      -- On ajoute 1 � la date fin ou date fin prolong contrat, pour que l'on ai des chiffres ronds
      -- Ex : months_between(31.12.2006, 01.01.2006) = 11.9677419354839
      --      months_between(01.01.2007, 01.01.2006) = 12
      select min(NEXT_RENEWAL_PERIOD)
        into vNextRenewalPeriod
        from (select vNextRenewalPeriod NEXT_RENEWAL_PERIOD
                from dual
              union
              select case
                       when nvl(tplService.CPO_END_EXTENDED_DATE, tplService.CPO_END_CONTRACT_DATE) is not null then nvl(tplService.CPO_END_EXTENDED_DATE
                                                                                                                       , tplService.CPO_END_CONTRACT_DATE
                                                                                                                        ) +
                                                                                                                     1
                       else null
                     end NEXT_RENEWAL_PERIOD
                from dual
              union
              select case
                       when tplService.CPO_SUSPENSION_DATE is not null then tplService.CPO_SUSPENSION_DATE + 1
                       else null
                     end NEXT_RENEWAL_PERIOD
                from dual
              union
              select case
                       when tplService.CPO_RESILIATION_DATE is not null then tplService.CPO_RESILIATION_DATE + 1
                       else null
                     end NEXT_RENEWAL_PERIOD
                from dual);

      -- Utilisation du prorata
      if tplService.CPD_PRORATA = 1 then
        -- Unit� prorata = Jour
        if tplService.C_CML_TIME_UNIT = '1' then
          vCOEFF  := CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vNextRenewalPeriod, vCurrentRenewalPeriod - 1);
        else
          -- Unit� prorata = Mois
          --  Utilisation de la fonction months_between pour trouver les mois entre les 2 p�riodes
          --  Pour la date de d�part on va toujours prendre le 1er du mois
          vCurrentRenewalPeriod  := add_months(last_day(vCurrentRenewalPeriod) + 1, -1);
          vCOEFF                 := trunc(CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(vCurrentRenewalPeriod, vNextRenewalPeriod) );
        end if;

        -- Qt� p�riode
        vCPD_PERIOD_QTY  := (tplService.CPD_RENEWABLE_QTY / 12) * vCOEFF;
      else
        -- Qt� p�riode = Qt� renouvellable anuellement
        vCPD_PERIOD_QTY  := tplService.CPD_RENEWABLE_QTY;
      end if;

      -- Arrondir la qt� au nbr de d�cimales du service
      vCPD_PERIOD_QTY        := ACS_FUNCTION.RoundNear(vCPD_PERIOD_QTY, 1 / power(10, tplService.GOO_NUMBER_OF_DECIMAL), 0);

      -- Code 4 : Avoir �puisable - Renouvellement cumul�
      if tplService.C_SERVICE_RENEWAL = '4' then
        vCPD_PERIOD_QTY  := tplService.CPD_BALANCE_QTY + vCPD_PERIOD_QTY;
      end if;

      -- M�j de la prestation
      update CML_POSITION_SERVICE_DETAIL
         set CPD_PERIOD_QTY = vCPD_PERIOD_QTY
           , CPD_BALANCE_QTY = vCPD_PERIOD_QTY
           , CPD_CONSUMED_QTY = 0
           , CPD_EXPIRY_DATE = vCPD_EXPIRY_DATE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_SERVICE_DETAIL_ID = tplService.CML_POSITION_SERVICE_DETAIL_ID;
    end loop;
  end ServiceRenewal;

  /**
  * function InsertCML_POS_SERV_DET_HISTORY
  * Description
  *    Insertion d'un historique de d�tail de prestation dans la table CML_POS_SERV_DET_HISTORY
  */
  function InsertCML_POS_SERV_DET_HISTORY(aServDetailID in CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type)
    return CML_POS_SERV_DET_HISTORY.CML_POS_SERV_DET_HISTORY_ID%type
  is
    vID CML_POS_SERV_DET_HISTORY.CML_POS_SERV_DET_HISTORY_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into vID
      from dual;

    insert into CML_POS_SERV_DET_HISTORY
                (CML_POS_SERV_DET_HISTORY_ID
               , CML_POSITION_SERVICE_DETAIL_ID
               , CML_POSITION_SERVICE_ID
               , GCO_GOOD_ID
               , ASA_COUNTER_TYPE_ID
               , C_SERVICE_RENEWAL
               , C_CML_TIME_UNIT
               , DIC_TARIFF_ID
               , CPD_SQL_CONDITION
               , CPD_RENEWABLE_QTY
               , CPD_PERIOD_QTY
               , CPD_CONSUMED_QTY
               , CPD_BALANCE_QTY
               , CPD_EXPIRY_DATE
               , CPD_PRORATA
               , CPD_UNIT_VALUE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select vID CML_POS_SERV_DET_HISTORY_ID
           , CML_POSITION_SERVICE_DETAIL_ID
           , CML_POSITION_SERVICE_ID
           , GCO_GOOD_ID
           , ASA_COUNTER_TYPE_ID
           , C_SERVICE_RENEWAL
           , C_CML_TIME_UNIT
           , DIC_TARIFF_ID
           , CPD_SQL_CONDITION
           , CPD_RENEWABLE_QTY
           , CPD_PERIOD_QTY
           , CPD_CONSUMED_QTY
           , CPD_BALANCE_QTY
           , CPD_EXPIRY_DATE
           , CPD_PRORATA
           , CPD_UNIT_VALUE
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
        from CML_POSITION_SERVICE_DETAIL
       where CML_POSITION_SERVICE_DETAIL_ID = aServDetailID;

    return vID;
  end InsertCML_POS_SERV_DET_HISTORY;

  /**
  * procedure GenerateResiliationRepayment
  * Description
  *    Cr�ation d'un �v�nement pour le remboursement d'un forfait d�j� pay�
  *    suite � la r�siliation de la position
  */
  procedure GenerateResiliationRepayment(aPositionID in CML_POSITION.CML_POSITION_ID%type)
  is
    cursor crPosInfo
    is
      select CML_DOCUMENT_ID
           , CPO_RESILIATION_DATE
           , CPO_NEXT_DATE
           , CPO_END_CONTRACT_DATE
           , CPO_END_EXTENDED_DATE
           , ACS_FINANCIAL_CURRENCY_ID
           , CPO_INIT_PERIOD_PRICE * -1 CPO_INIT_PERIOD_PRICE
           , CPO_EXTEND_PERIOD_PRICE * -1 CPO_EXTEND_PERIOD_PRICE
        from CML_POSITION
       where CML_POSITION_ID = aPositionID;

    tplPosInfo     crPosInfo%rowtype;
    vEventID       CML_EVENTS.CML_EVENTS_ID%type             default null;
    vRowCML_EVENTS CML_EVENTS%rowtype;
    vRowTemp       CML_EVENTS%rowtype;
    datSTART       date;
    vPRICE         CML_POSITION.CPO_INIT_PERIOD_PRICE%type;
  begin
    open crPosInfo;

    -- Calculer le montant � rembourser au client
    -- Prorata calcul� entre la date de r�siliation et la date prochaine �ch�ance -1
    if crPosInfo%found then
      fetch crPosInfo
       into tplPosInfo;

      -- Remboursement uniquement si p�riode est pay� ->
      --   date de r�siliation est inf�rieure � la date prochaine �ch�ance
      if (tplPosInfo.CPO_RESILIATION_DATE < tplPosInfo.CPO_NEXT_DATE) then
        -- Init des donn�es � ins�rer comme Evenement
        vRowTemp.CML_POSITION_ID            := aPositionID;
        vRowTemp.CML_DOCUMENT_ID            := tplPosInfo.CML_DOCUMENT_ID;
        vRowTemp.C_CML_EVENT_TYPE           := '3';
        vRowTemp.C_CML_EVENT_DOC_GEN        := '2';
        vRowTemp.GCO_GOOD_ID                := PCS.PC_CONFIG.GETCONFIG('CML_GOOD_REF_POS');
        vRowTemp.ACS_FINANCIAL_CURRENCY_ID  := tplPosInfo.ACS_FINANCIAL_CURRENCY_ID;
        vRowTemp.CEV_RENEWAL_GENERATED      := 0;
        datSTART                            := tplPosInfo.CPO_RESILIATION_DATE;

        -- Si la r�siliation se trouve avant la fin du contrat mais que celui-ci
        -- avait d�j� �t� prolong� et que la p�riode de prolongation a �t� pay�e
        -- On doit effectuer un 1er remboursement au tarif initial et ensuite
        -- un 2eme au tarif prolongation
        if     (tplPosInfo.CPO_END_CONTRACT_DATE is not null)
           and (tplPosInfo.CPO_END_CONTRACT_DATE > tplPosInfo.CPO_RESILIATION_DATE)
           and (tplPosInfo.CPO_END_CONTRACT_DATE < tplPosInfo.CPO_NEXT_DATE) then
          -- Init des donn�es � ins�rer comme Evenement
          vRowCML_EVENTS             := vRowTemp;
          -- Prix de la p�riode initiale
          vPRICE                     := tplPosInfo.CPO_INIT_PERIOD_PRICE;
          -- Texte du remboursement
          vRowCML_EVENTS.CEV_TEXT    :=
            PCS.PC_FUNCTIONS.TranslateWord('D�compte en votre faveur : ') ||
            to_char(datSTART, 'DD.MM.YYYY') ||
            ' - ' ||
            to_char(tplPosInfo.CPO_END_CONTRACT_DATE - 1, 'DD.MM.YYYY');
          -- Montant = au prorata entre la r�siliation et la fin du contrat
          vRowCML_EVENTS.CEV_AMOUNT  := vPRICE * CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(datSTART, tplPosInfo.CPO_END_CONTRACT_DATE);
          --
          -- Insertion d'un ligne dans la table CML_EVENTS
          vEventID                   := InsertCML_EVENTS(aRow => vRowCML_EVENTS);
          -- Initialisation de la date de d�part pour la 2eme p�riode � facturer
          datSTART                   := tplPosInfo.CPO_END_CONTRACT_DATE + 1;
        end if;

        -- Init des donn�es de l'�v�nement
        vRowCML_EVENTS                      := vRowTemp;

        -- Utilisation du prix initial ou prix en p�riode prolongation
        if datSTART < tplPosInfo.CPO_END_CONTRACT_DATE then
          vPRICE  := tplPosInfo.CPO_INIT_PERIOD_PRICE;
        else
          vPRICE  := tplPosInfo.CPO_EXTEND_PERIOD_PRICE;
        end if;

        -- Texte du remboursement
        vRowCML_EVENTS.CEV_TEXT             :=
          PCS.PC_FUNCTIONS.TranslateWord('D�compte en votre faveur : ') ||
          to_char(datSTART, 'DD.MM.YYYY') ||
          ' - ' ||
          to_char(tplPosInfo.CPO_NEXT_DATE - 1, 'DD.MM.YYYY');
        -- Montant = au prorata entre la (r�siliation ou fin de contrat pr�vue) et la prochaine �ch�ance
        vRowCML_EVENTS.CEV_AMOUNT           := vPRICE * CML_CONTRACT_FUNCTIONS.CmlMonthsBetween(datSTART, tplPosInfo.CPO_NEXT_DATE - 1);
        -- Insertion d'un ligne dans la table CML_EVENTS
        vEventID                            := InsertCML_EVENTS(aRow => vRowCML_EVENTS);
      end if;
    end if;

    close crPosInfo;
  end GenerateResiliationRepayment;

  /**
  * function GetDescriptionInvoicingJob
  * Description
  *    Renvoi la description de la facturation
  */
  function GetDescriptionInvoicingJob(aJobID in CML_INVOICING_JOB.CML_INVOICING_JOB_ID%type)
    return CML_INVOICING_JOB.INJ_DESCRIPTION%type
  is
    lv_invoicing_description CML_INVOICING_JOB.INJ_DESCRIPTION%type;
  begin
    select max(INJ_DESCRIPTION)
      into lv_invoicing_description
      from CML_INVOICING_JOB
     where CML_INVOICING_JOB_ID = aJobID;

    return lv_invoicing_description;
  end GetDescriptionInvoicingJob;
end CML_INVOICING_PREPARATION;
