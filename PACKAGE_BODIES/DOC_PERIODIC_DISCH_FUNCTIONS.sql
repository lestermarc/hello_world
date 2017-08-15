--------------------------------------------------------
--  DDL for Package Body DOC_PERIODIC_DISCH_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PERIODIC_DISCH_FUNCTIONS" 
is
  type TListID is table of DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    index by binary_integer;

  /**
  * procedure ProcessPeriodicDischarge
  * Description
  */
  procedure ProcessPeriodicDischarge(aProfileID in number)
  is
    vProfile         TXMLProfile;
    vPrintOptionList TPrintOptionList;
    vProcessID       DOC_PERIODIC_DISCH_RESULT.DDR_PROCESS_ID%type;
    vPrintJobID      DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type;
    vJobName         varchar2(100);
  begin
    if aProfileID is not null then
      -- Recherche les données xml
      vProfile  := GetProfileValues(aProfileID);

      -- Création des propositions de décharge selon des critères de l'utilisateur
      begin
        GeneratePropositions(vProfile.OBJECT_MODE
                           , vProfile.SOURCE_DOC_GAUGE_ID
                           , vProfile.TARGET_DOC_GAUGE_ID
                           , vProfile.DOC_GAUGE_FLOW_ID
                           , vProfile.DIC_GAUGE_GROUP_ID
                           , vProfile.DDI_ATTRIBS
                           , vProfile.DDI_REDO_ATTRIB
                           , vProfile.DDI_REFRESH_ATTRIB
                           , vProfile.DDI_ONLY_ATTRIB_MANAG_DOC
                           , vProfile.DDI_DOCUMENT_FROM
                           , vProfile.DDI_DOCUMENT_TO
                           , vProfile.DDI_DATE_FROM
                           , vProfile.DDI_DATE_TO
                           , vProfile.DDI_CUSTOMER_FROM
                           , vProfile.DDI_CUSTOMER_TO
                           , vProfile.DDI_CUS_ACI_FROM
                           , vProfile.DDI_CUS_ACI_TO
                           , vProfile.DDI_CUS_DELIVERY_FROM
                           , vProfile.DDI_CUS_DELIVERY_TO
                           , vProfile.CUSTOMER_MIN_AMOUNT
                           , vProfile.GROUP_MIN_AMOUNT
                           , vProfile.CUSTOMER_PERIOD
                           , vProfile.DDI_REPRESENTATIVE_FROM
                           , vProfile.DDI_REPRESENTATIVE_TO
                           , vProfile.DDI_REPR_ACI_FROM
                           , vProfile.DDI_REPR_ACI_TO
                           , vProfile.DDI_REPR_DELIVERY_FROM
                           , vProfile.DDI_REPR_DELIVERY_TO
                           , vProfile.DDI_RECORD_FROM
                           , vProfile.DDI_RECORD_TO
                           , vProfile.DDI_GOOD_FROM
                           , vProfile.DDI_GOOD_TO
                           , vProfile.GCO_GOOD_CATEGORY_ID
                           , vProfile.DDI_BASIS_DELAY_FROM
                           , vProfile.DDI_BASIS_DELAY_TO
                           , vProfile.DDI_INTER_DELAY_FROM
                           , vProfile.DDI_INTER_DELAY_TO
                           , vProfile.DDI_FINAL_DELAY_FROM
                           , vProfile.DDI_FINAL_DELAY_TO
                           , vProfile.SQL_USER_SQLCODE
                            );
        commit;
      exception
        when others then
          raise_application_error(-20931
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Création des propositions de décharge impossible!') ||
                                  co.cLineBreak ||
                                  sqlerrm ||
                                  co.cLineBreak ||
                                  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                 );
      end;

      begin
        -- Recherche un ID pour le processus de décharge lancé
        select INIT_ID_SEQ.nextval
          into vProcessID
          from dual;

        -- Méthode globale pour effectuer la décharge des données envoyées dans la table DOC_POS_DET_COPY_DISCHARGE
        GenerateDischarge(vProfile.OBJECT_MODE
                        , vProfile.CREATE_MODE
                        , vProfile.TARGET_DOC_GAUGE_ID
                        , null
                        , null
                        , vProfile.DDI_DOC_REFERENCE
                        , vProfile.SQL_DISCH_SQLCODE
                        , vProfile.DDI_CONFIRM_DOC
                        , vProfile.DDI_SUMMARY_POS_TEXT
                        , vProfile.DDI_ONE_DOC_BY_DISCH_DOC
                        , 1
                        , vProfile.DDI_ATTRIBS
                        , vProcessID
                         );
        commit;
      exception
        when others then
          raise_application_error(-20932
                                , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la décharge des documents!') ||
                                  co.cLineBreak ||
                                  sqlerrm ||
                                  co.cLineBreak ||
                                  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                 );
      end;

      -- Création d'un job d'impression pour les documents créés
      if (vProfile.DDI_DIRECT_PRINT = 1) then
        -- Commande sql pour l'impression des documents
        if vProfile.SQL_PRINT_SQLCODE is not null then
          -- Remplacement du paramètre
          vProfile.SQL_PRINT_SQLCODE  := replace(vProfile.SQL_PRINT_SQLCODE, '[CO' || '].', '');
          vProfile.SQL_PRINT_SQLCODE  := replace(vProfile.SQL_PRINT_SQLCODE, '[COMPANY_OWNER' || '].', '');
          vProfile.SQL_PRINT_SQLCODE  := replace(vProfile.SQL_PRINT_SQLCODE, ':DDR_PROCESS_ID', vProcessID);

          -- Nom du job d'impression
          select PCS.PC_I_LIB_SESSION.GetUserIni || ' - PERIODIC ' || vProfile.OBJECT_MODE || ' - ' || to_char(sysdate)
            into vJobName
            from dual;

          -- Recherche les données dans le fichier xml concernant l'impression
          vPrintOptionList            := GetProfilePrintValues(aProfileID);

          begin
            -- Création du job d'impression
            CreatePeriodicDischPrintJob(vPrintJobID, vJobName, vProfile.PRT_GROUPED_PRINT, 1, vProfile.SQL_PRINT_SQLCODE, vPrintOptionList);
            commit;
          exception
            when others then
              raise_application_error(-20933
                                    , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de la création du travail d''impression!') ||
                                      co.cLineBreak ||
                                      sqlerrm ||
                                      co.cLineBreak ||
                                      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                     );
          end;
        end if;
      end if;
    end if;
  end ProcessPeriodicDischarge;

  /**
  * function GetProfileValues
  * Description
  *     Renvoi les valeurs stockées dans le fichier xml stocké dans la table des profils
  * @version 2004
  * @created NGV
  */
  function GetProfileValues(aProfileID in number)
    return TXMLProfile
  is
    vClob       clob;
    vXml        xmltype;
    vXmlProfile TXMLProfile;
  begin
    -- Reprend le champ CLOB du profil
    begin
      select PFL_XML_OPTIONS
        into vClob
        from PCS.COM_PROFILE
       where COM_PROFILE_ID = aProfileID;
    exception
      when no_data_found then
        raise_application_error(-20921
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Profil non trouvé!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    -- Création dun type xml à partir du CLOB récupéré
    vXml  := xmltype.CreateXML(vClob);

    begin
      -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
      select extractvalue(vXml, '//OBJECT_MODE')
           , extractvalue(vXml, '//CREATE_MODE')
           , extractvalue(vXml, '//DIC_GAUGE_GROUP_ID')
           , to_number(extractvalue(vXml, '//SOURCE_DOC_GAUGE_ID') )
           , to_number(extractvalue(vXml, '//TARGET_DOC_GAUGE_ID') )
           , to_number(extractvalue(vXml, '//DOC_GAUGE_FLOW_ID') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_DOCUMENT_DATE') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_DATE_VALUE') )
           , extractvalue(vXml, '//DDI_DOC_REFERENCE')
           , to_number(extractvalue(vXml, '//DDI_CONFIRM_DOC') )
           , to_number(extractvalue(vXml, '//DDI_DIRECT_PRINT') )
           , to_number(extractvalue(vXml, '//DDI_ONE_DOC_BY_DISCH_DOC') )
           , to_number(extractvalue(vXml, '//DDI_SUMMARY_POS_TEXT') )
           , to_number(extractvalue(vXml, '//DDI_ATTRIBS') )
           , to_number(extractvalue(vXml, '//DDI_REFRESH_ATTRIB') )
           , to_number(extractvalue(vXml, '//DDI_REDO_ATTRIB') )
           , to_number(extractvalue(vXml, '//DDI_ONLY_ATTRIB_MANAG_DOC') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_DATE_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_DATE_TO') )
           , extractvalue(vXml, '//DDI_DOCUMENT_FROM')
           , extractvalue(vXml, '//DDI_DOCUMENT_TO')
           , extractvalue(vXml, '//DDI_CUSTOMER_FROM')
           , extractvalue(vXml, '//DDI_CUSTOMER_TO')
           , extractvalue(vXml, '//DDI_CUS_ACI_FROM')
           , extractvalue(vXml, '//DDI_CUS_ACI_TO')
           , extractvalue(vXml, '//DDI_CUS_DELIVERY_FROM')
           , extractvalue(vXml, '//DDI_CUS_DELIVERY_TO')
           , extractvalue(vXml, '//DDI_RECORD_FROM')
           , extractvalue(vXml, '//DDI_RECORD_TO')
           , extractvalue(vXml, '//DDI_REPRESENTATIVE_FROM')
           , extractvalue(vXml, '//DDI_REPRESENTATIVE_TO')
           , extractvalue(vXml, '//DDI_REPR_ACI_FROM')
           , extractvalue(vXml, '//DDI_REPR_ACI_TO')
           , extractvalue(vXml, '//DDI_REPR_DELIVERY_FROM')
           , extractvalue(vXml, '//DDI_REPR_ACI_TO')
           , extractvalue(vXml, '//DDI_GOOD_FROM')
           , extractvalue(vXml, '//DDI_GOOD_TO')
           , to_number(extractvalue(vXml, '//GCO_GOOD_CATEGORY_ID') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_BASIS_DELAY_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_BASIS_DELAY_TO') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_INTER_DELAY_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_INTER_DELAY_TO') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_FINAL_DELAY_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(vXml, '//DDI_FINAL_DELAY_TO') )
           , PCS.COM_PROFILE_FUNCTIONS.GetNumberValue(extractvalue(vXml, '//CUSTOMER_MIN_AMOUNT') )
           , PCS.COM_PROFILE_FUNCTIONS.GetNumberValue(extractvalue(vXml, '//GROUP_MIN_AMOUNT') )
           , extractvalue(vXml, '//CUSTOMER_PERIOD')
           , to_number(extractvalue(vXml, '//ASK_SQL_PARAMS') )
           , extractvalue(vXml, '//SQL_USER_TABLE')
           , extractvalue(vXml, '//SQL_USER_GROUP')
           , extractvalue(vXml, '//SQL_USER_COMMAND')
           , PCS.PC_FUNCTIONS.XmlExtractClobValue(vXml, '//SQL_USER_SQLCODE')
           , extractvalue(vXml, '//SQL_DISCH_TABLE')
           , extractvalue(vXml, '//SQL_DISCH_GROUP')
           , extractvalue(vXml, '//SQL_DISCH_COMMAND')
           , PCS.PC_FUNCTIONS.XmlExtractClobValue(vXml, '//SQL_DISCH_SQLCODE')
           , extractvalue(vXml, '//SQL_DISCH_REGROUP')
           , extractvalue(vXml, '//SQL_DISCH_OPTIONS')
           , extractvalue(vXml, '//SQL_PRINT_TABLE')
           , extractvalue(vXml, '//SQL_PRINT_GROUP')
           , extractvalue(vXml, '//SQL_PRINT_COMMAND')
           , PCS.PC_FUNCTIONS.XmlExtractClobValue(vXml, '//SQL_PRINT_SQLCODE')
           , extractvalue(vXml, '//SQL_PRINT_OPTIONS')
           , to_number(extractvalue(vXml, '//PRT_GROUPED_PRINT') )
        into vXmlProfile
        from dual;
    exception
      when others then
        raise_application_error(-20922
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    return vXmlProfile;
  end GetProfileValues;

  /**
  * function GetProfilePrintValues
  * Description
  *     Renvoi les valeurs stockées dans le fichier xml stocké dans la table des profils concernant l'impression
  */
  function GetProfilePrintValues(aProfileID in number)
    return TPrintOptionList
  is
    vCpt             integer;
    vClob            clob;
    vXml             xmltype;
    vPrintOptionList TPrintOptionList;
  begin
    vCpt  := 0;

    -- Reprend le champ CLOB du profil
    begin
      select PFL_XML_OPTIONS
        into vClob
        from PCS.COM_PROFILE
       where COM_PROFILE_ID = aProfileID;
    exception
      when no_data_found then
        raise_application_error(-20923
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Profil non trouvé!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    -- Création dun type xml à partir du CLOB récupéré
    vXml  := xmltype.CreateXML(vClob);

    begin
      while vCpt < 11 loop
        -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
        select to_number(extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_PRINT') )
             , extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_FORM_NAME')
             , to_number(extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_COPIES') )
             , to_number(extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_COLLATE') )
             , extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_PRINTER_NAME')
             , extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_PRINTER_TRAY')
             , extractvalue(vXml, '//PRT_' || lpad(to_char(vCpt), 2, '0') || '_PRINT_SQL')
          into vPrintOptionList(vCpt)
          from dual;

        vCpt  := vCpt + 1;
      end loop;
    exception
      when others then
        raise_application_error(-20924
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    return vPrintOptionList;
  end GetProfilePrintValues;

  /**
  * procedure InitDischargeFlow
  * Description
  *   Renseigment du flux de décharge pour les propositions générées et
  *   effacement des propositions qui n'ont pas de flux de décharge
  */
  procedure InitDischargeFlow(aTgtGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
  is
    vDOC_GAUGE_FLOW_ID    DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
    vDOC_GAUGE_RECEIPT_ID DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type;
  begin
    -- Traiter tous les records dont le flux n'était pas renseigné sur le détail parent
    for tplProcess in (select   GAU.C_ADMIN_DOMAIN
                              , GAU.DOC_GAUGE_ID
                              , DDI.PAC_CUSTOM_PARTNER_ID
                           from DOC_PERIODIC_DISCHARGE DDI
                              , DOC_GAUGE GAU
                          where DDI.DOC_GAUGE_FLOW_ID is null
                            and GAU.DOC_GAUGE_ID = DDI.DOC_GAUGE_ID
                       group by GAU.C_ADMIN_DOMAIN
                              , GAU.DOC_GAUGE_ID
                              , DDI.PAC_CUSTOM_PARTNER_ID) loop
      -- rechercher le flux
      vDOC_GAUGE_FLOW_ID  := DOC_LIB_GAUGE.getFlowId(tplProcess.C_ADMIN_DOMAIN, tplProcess.PAC_CUSTOM_PARTNER_ID);

      -- màj le flux
      if vDOC_GAUGE_FLOW_ID is not null then
        update DOC_PERIODIC_DISCHARGE
           set DOC_GAUGE_FLOW_ID = vDOC_GAUGE_FLOW_ID
         where DOC_GAUGE_FLOW_ID is null
           and DOC_GAUGE_ID = tplProcess.DOC_GAUGE_ID
           and PAC_CUSTOM_PARTNER_ID = tplProcess.PAC_CUSTOM_PARTNER_ID;
      end if;
    end loop;

    -- Traiter tous les records dont le flux était renseigné sur le détail parent
    for tplProcess in (select   GAU.DOC_GAUGE_ID
                              , GAU.C_ADMIN_DOMAIN
                              , DDI.PAC_CUSTOM_PARTNER_ID
                              , DDI.DOC_GAUGE_FLOW_ID
                           from DOC_PERIODIC_DISCHARGE DDI
                              , DOC_GAUGE GAU
                          where DDI.DOC_GAUGE_FLOW_ID is not null
                            and GAU.DOC_GAUGE_ID = DDI.DOC_GAUGE_ID
                       group by GAU.DOC_GAUGE_ID
                              , GAU.C_ADMIN_DOMAIN
                              , DDI.PAC_CUSTOM_PARTNER_ID
                              , DDI.DOC_GAUGE_FLOW_ID) loop
      -- rechercher le flux du gabarit réceptionnable
      select max(GAR.DOC_GAUGE_RECEIPT_ID)
        into vDOC_GAUGE_RECEIPT_ID
        from DOC_GAUGE_RECEIPT GAR
           , DOC_GAUGE_FLOW_DOCUM GAD
       where GAD.DOC_GAUGE_FLOW_ID = tplProcess.DOC_GAUGE_FLOW_ID
         and GAR.DOC_GAUGE_FLOW_DOCUM_ID = GAD.DOC_GAUGE_FLOW_DOCUM_ID
         and GAR.DOC_DOC_GAUGE_ID = tplProcess.DOC_GAUGE_ID
         and GAD.DOC_GAUGE_ID = aTgtGaugeID;

      -- màj le flux réceptionnable
      if vDOC_GAUGE_RECEIPT_ID is not null then
        update DOC_PERIODIC_DISCHARGE
           set DOC_GAUGE_RECEIPT_ID = vDOC_GAUGE_RECEIPT_ID
         where DOC_GAUGE_FLOW_ID = tplProcess.DOC_GAUGE_FLOW_ID
           and DOC_GAUGE_ID = tplProcess.DOC_GAUGE_ID
           and PAC_CUSTOM_PARTNER_ID = tplProcess.PAC_CUSTOM_PARTNER_ID;
      end if;
    end loop;

    -- Effacer tous les détails proposés qui n'ont pas de flux de décharge
    delete from DOC_PERIODIC_DISCHARGE
          where DOC_GAUGE_RECEIPT_ID is null;
  end InitDischargeFlow;

  /**
  * function GetFilterDetail
  * Description
  *     Renvoi la liste des détails déchargeables en fonction des filtres
  *       utilisateur sélectionnés à l'interface
  */
  function GetFilterDetail
    return TTblFilterDetail pipelined
  is
    vRow DOC_PERIODIC_DISCHARGE%rowtype;
  begin
    for tplDetail in (select   DMT.DOC_DOCUMENT_ID
                             , POS.DOC_POSITION_ID
                             , PDE.DOC_POSITION_DETAIL_ID
                             , POS.GCO_GOOD_ID
                             , CUS.PAC_CUSTOM_PARTNER_ID
                             , CUS_ACI.PAC_CUSTOM_PARTNER_ID PAC_CUS_PARTNER_ACI_ID
                             , CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID PAC_CUS_PARTNER_DELIVERY_ID
                             , CUS_ACI.ACS_AUXILIARY_ACCOUNT_ID
                             , DMT.DOC_GAUGE_ID
                             , PDE.DOC_GAUGE_FLOW_ID
                             , null DOC_GAUGE_RECEIPT_ID
                             , GAP_TGT.DOC_GAUGE_POSITION_ID
                          from DOC_DOCUMENT DMT
                             , DOC_GAUGE GAU
                             , DOC_GAUGE_STRUCTURED GAS
                             , PAC_PERSON PER
                             , PAC_PERSON PER_ACI
                             , PAC_PERSON PER_DELIVERY
                             , PAC_CUSTOM_PARTNER CUS
                             , PAC_CUSTOM_PARTNER CUS_ACI
                             , PAC_CUSTOM_PARTNER CUS_DELIVERY
                             , PAC_REPRESENTATIVE REP
                             , PAC_REPRESENTATIVE REP_ACI
                             , PAC_REPRESENTATIVE REP_DELIVERY
                             , DOC_POSITION POS
                             , DOC_RECORD RCO
                             , GCO_GOOD GOO
                             , DOC_POSITION_DETAIL PDE
                             , DOC_GAUGE_POSITION GAP_TGT
                             , DOC_GAUGE_POSITION GAP_SRC
                         where DMT.DMT_PROTECTED = 0
                           and DMT.C_DOCUMENT_STATUS || '' in('02', '03')
                           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                           and GAU.DOC_GAUGE_ID = nvl(UserFilter.SOURCE_DOC_GAUGE_ID, GAU.DOC_GAUGE_ID)
                           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+)
                           and (   GAU.DIC_GAUGE_GROUP_ID = UserFilter.DIC_GAUGE_GROUP_ID
                                or UserFilter.DIC_GAUGE_GROUP_ID is null)
                           and DMT.DMT_NUMBER between nvl(UserFilter.DDI_DOCUMENT_FROM, lpad(' ', 30, chr(1) ) )
                                                  and nvl(UserFilter.DDI_DOCUMENT_TO, lpad(' ', 30, chr(255) ) )
                           and DMT.DMT_DATE_DOCUMENT >= nvl(UserFilter.DDI_DATE_FROM, DMT.DMT_DATE_DOCUMENT)
                           and DMT.DMT_DATE_DOCUMENT <= nvl(UserFilter.DDI_DATE_TO, DMT.DMT_DATE_DOCUMENT)
                           and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                           and CUS.C_PARTNER_STATUS = '1'
                           and PER.PER_NAME between nvl(UserFilter.DDI_CUSTOMER_FROM, lpad(' ', 30, chr(1) ) )
                                                and nvl(UserFilter.DDI_CUSTOMER_TO, lpad(' ', 30, chr(255) ) )
                           and DMT.PAC_THIRD_ACI_ID = CUS_ACI.PAC_CUSTOM_PARTNER_ID
                           and CUS_ACI.PAC_CUSTOM_PARTNER_ID = PER_ACI.PAC_PERSON_ID
                           and CUS_ACI.C_PARTNER_STATUS = '1'
                           and PER_ACI.PER_NAME between nvl(UserFilter.DDI_CUS_ACI_FROM, lpad(' ', 30, chr(1) ) )
                                                    and nvl(UserFilter.DDI_CUS_ACI_TO, lpad(' ', 30, chr(255) ) )
                           and DMT.PAC_THIRD_DELIVERY_ID = CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID
                           and CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID = PER_DELIVERY.PAC_PERSON_ID
                           and CUS_DELIVERY.C_PARTNER_STATUS = '1'
                           and PER_DELIVERY.PER_NAME between nvl(UserFilter.DDI_CUS_DELIVERY_FROM, lpad(' ', 30, chr(1) ) )
                                                         and nvl(UserFilter.DDI_CUS_DELIVERY_TO, lpad(' ', 30, chr(255) ) )
                           and GAP_SRC.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                           and GAP_TGT.DOC_GAUGE_ID = UserFilter.TARGET_DOC_GAUGE_ID
                           and GAP_TGT.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
                           and GAP_TGT.GAP_DEFAULT = 1
                           and GAP_TGT.GAP_INCLUDE_TAX_TARIFF = POS.POS_INCLUDE_TAX_TARIFF
                           and GAP_TGT.GAP_VALUE_QUANTITY = (select GAP_VALUE_QUANTITY
                                                               from DOC_GAUGE_POSITION
                                                              where DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID)
                           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                           and POS.C_DOC_POS_STATUS in('02', '03')
                           and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10')
                           and POS.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
                           and REP.C_PARTNER_STATUS(+) = '1'
                           and (   UserFilter.DDI_REPRESENTATIVE_FROM || UserFilter.DDI_REPRESENTATIVE_TO is null
                                or (REP.REP_DESCR between nvl(UserFilter.DDI_REPRESENTATIVE_FROM, lpad(' ', 30, chr(1) ) )
                                                      and nvl(UserFilter.DDI_REPRESENTATIVE_TO, lpad(' ', 30, chr(255) ) )
                                   )
                               )
                           and POS.PAC_REPR_ACI_ID = REP_ACI.PAC_REPRESENTATIVE_ID(+)
                           and REP_ACI.C_PARTNER_STATUS(+) = '1'
                           and (   UserFilter.DDI_REPR_ACI_FROM || UserFilter.DDI_REPR_ACI_TO is null
                                or (REP_ACI.REP_DESCR between nvl(UserFilter.DDI_REPR_ACI_FROM, lpad(' ', 30, chr(1) ) )
                                                          and nvl(UserFilter.DDI_REPR_ACI_TO, lpad(' ', 30, chr(255) ) )
                                   )
                               )
                           and POS.PAC_REPR_DELIVERY_ID = REP_DELIVERY.PAC_REPRESENTATIVE_ID(+)
                           and REP_DELIVERY.C_PARTNER_STATUS(+) = '1'
                           and (   UserFilter.DDI_REPR_DELIVERY_FROM || UserFilter.DDI_REPR_DELIVERY_TO is null
                                or (REP_DELIVERY.REP_DESCR between nvl(UserFilter.DDI_REPR_DELIVERY_FROM, lpad(' ', 30, chr(1) ) )
                                                               and nvl(UserFilter.DDI_REPR_DELIVERY_TO, lpad(' ', 30, chr(255) ) )
                                   )
                               )
                           and POS.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                           and (   UserFilter.DDI_RECORD_FROM || UserFilter.DDI_RECORD_TO is null
                                or (RCO.RCO_TITLE between nvl(UserFilter.DDI_RECORD_FROM, lpad(' ', 30, chr(1) ) )
                                                      and nvl(UserFilter.DDI_RECORD_TO, lpad(' ', 30, chr(255) ) )
                                   )
                               )
                           and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                           and GOO.GOO_MAJOR_REFERENCE between nvl(UserFilter.DDI_GOOD_FROM, lpad(' ', 30, chr(1) ) )
                                                           and nvl(UserFilter.DDI_GOOD_TO, lpad(' ', 30, chr(255) ) )
                           and GOO.GCO_GOOD_CATEGORY_ID = nvl(UserFilter.GCO_GOOD_CATEGORY_ID, GOO.GCO_GOOD_CATEGORY_ID)
                           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                           and POS.DOC_DOC_POSITION_ID is null
                           and (   PDE.PDE_BALANCE_QUANTITY <> 0
                                or nvl(PDE.PDE_FINAL_QUANTITY, 0) = 0)
                           and (   GAP_SRC.GAP_DELAY = 0
                                or (    GAP_SRC.GAP_DELAY = 1
                                    and PDE.PDE_BASIS_DELAY >= nvl(UserFilter.DDI_BASIS_DELAY_FROM, PDE.PDE_BASIS_DELAY)
                                    and PDE.PDE_BASIS_DELAY <= nvl(UserFilter.DDI_BASIS_DELAY_TO, PDE.PDE_BASIS_DELAY)
                                    and PDE.PDE_INTERMEDIATE_DELAY >= nvl(UserFilter.DDI_INTER_DELAY_FROM, PDE.PDE_INTERMEDIATE_DELAY)
                                    and PDE.PDE_INTERMEDIATE_DELAY <= nvl(UserFilter.DDI_INTER_DELAY_TO, PDE.PDE_INTERMEDIATE_DELAY)
                                    and PDE.PDE_FINAL_DELAY >= nvl(UserFilter.DDI_FINAL_DELAY_FROM, PDE.PDE_FINAL_DELAY)
                                    and PDE.PDE_FINAL_DELAY <= nvl(UserFilter.DDI_FINAL_DELAY_TO, PDE.PDE_FINAL_DELAY)
                                   )
                               )
                      order by DMT.DMT_NUMBER
                             , POS.POS_NUMBER
                             , PDE.DOC_POSITION_DETAIL_ID) loop
      vRow                              := null;
      vRow.DOC_DOCUMENT_ID              := tplDetail.DOC_DOCUMENT_ID;
      vRow.DOC_POSITION_ID              := tplDetail.DOC_POSITION_ID;
      vRow.DOC_POSITION_DETAIL_ID       := tplDetail.DOC_POSITION_DETAIL_ID;
      vRow.GCO_GOOD_ID                  := tplDetail.GCO_GOOD_ID;
      vRow.PAC_CUSTOM_PARTNER_ID        := tplDetail.PAC_CUSTOM_PARTNER_ID;
      vRow.PAC_CUS_PARTNER_ACI_ID       := tplDetail.PAC_CUS_PARTNER_ACI_ID;
      vRow.PAC_CUS_PARTNER_DELIVERY_ID  := tplDetail.PAC_CUS_PARTNER_DELIVERY_ID;
      vRow.ACS_AUXILIARY_ACCOUNT_ID     := tplDetail.ACS_AUXILIARY_ACCOUNT_ID;
      vRow.DOC_GAUGE_ID                 := tplDetail.DOC_GAUGE_ID;
      vRow.DOC_GAUGE_FLOW_ID            := tplDetail.DOC_GAUGE_FLOW_ID;
      vRow.DOC_GAUGE_POSITION_ID        := tplDetail.DOC_GAUGE_POSITION_ID;
      pipe row(vRow);
    end loop;
  end GetFilterDetail;

  /**
  * procedure GeneratePropositions
  * Description
  *     Création des propositions de décharge selon des critères de l'utilisateur
  */
  procedure GeneratePropositions(
    aMode               varchar2   /* BILLING, DELIVERY, BARCODE */
  , aSrcGaugeID         DOC_GAUGE.DOC_GAUGE_ID%type
  , aTgtGaugeID         DOC_GAUGE.DOC_GAUGE_ID%type default null
  , aGaugeFlowID        DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type default null
  , aDicGaugeGroupID    varchar2 default null
  , aAttribs            integer default 0
  , aRedoAttrib         integer default 0
  , aRefreshAttrib      integer default 0
  , aOnlyAttribManagDoc integer default 0
  , aDocumentFrom       varchar2 default null
  , aDocumentTo         varchar2 default null
  , aDocDateFrom        date default null
  , aDocDateTo          date default null
  , aCustomerFrom       varchar2 default null
  , aCustomerTo         varchar2 default null
  , aCusAciFrom         varchar2 default null
  , aCusAciTo           varchar2 default null
  , aCusDeliveryFrom    varchar2 default null
  , aCusDeliveryTo      varchar2 default null
  , aCustomerMinAmount  number default null
  , aGroupMinAmount     number default null
  , aCustomerPeriod     varchar2 default null
  , aRepresentativeFrom varchar2 default null
  , aRepresentativeTo   varchar2 default null
  , aReprAciFrom        varchar2 default null
  , aReprAciTo          varchar2 default null
  , aReprDeliveryFrom   varchar2 default null
  , aReprDeliveryTo     varchar2 default null
  , aRecordFrom         varchar2 default null
  , aRecordTo           varchar2 default null
  , aGoodFrom           varchar2 default null
  , aGoodTo             varchar2 default null
  , aGoodCategoryID     GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type default null
  , aBasisDelayFrom     date default null
  , aBasisDelayTo       date default null
  , aInterDelayFrom     date default null
  , aInterDelayTo       date default null
  , aFinalDelayFrom     date default null
  , aFinalDelayTo       date default null
  , aUserSqlCommand     clob default null
  )
  is
    type TPeriodicList is table of DOC_PERIODIC_DISCHARGE%rowtype
      index by binary_integer;

    vIndex             integer;
    vIndex2            integer;
    vFound             boolean;
    vErrorMsg          varchar2(250);
    vErrorCode         integer;
    vPosID             DOC_POSITION.DOC_POSITION_ID%type;
    vDocumentList      TListID;
    vDocumentFinalList TListID;
    vDetailList        TPeriodicList;
  begin
    UserFilter                            := null;
    UserFilter.OBJECT_MODE                := aMode;
    UserFilter.SOURCE_DOC_GAUGE_ID        := aSrcGaugeID;
    UserFilter.TARGET_DOC_GAUGE_ID        := aTgtGaugeID;
    UserFilter.DOC_GAUGE_FLOW_ID          := aGaugeFlowID;
    UserFilter.DIC_GAUGE_GROUP_ID         := aDicGaugeGroupID;
    UserFilter.DDI_ATTRIBS                := aAttribs;
    UserFilter.DDI_REDO_ATTRIB            := aRedoAttrib;
    UserFilter.DDI_REFRESH_ATTRIB         := aRefreshAttrib;
    UserFilter.DDI_ONLY_ATTRIB_MANAG_DOC  := aOnlyAttribManagDoc;
    UserFilter.DDI_DOCUMENT_FROM          := aDocumentFrom;
    UserFilter.DDI_DOCUMENT_TO            := aDocumentTo;
    UserFilter.DDI_DATE_FROM              := aDocDateFrom;
    UserFilter.DDI_DATE_TO                := aDocDateTo;
    UserFilter.DDI_CUSTOMER_FROM          := aCustomerFrom;
    UserFilter.DDI_CUSTOMER_TO            := aCustomerTo;
    UserFilter.DDI_CUS_ACI_FROM           := aCusAciFrom;
    UserFilter.DDI_CUS_ACI_TO             := aCusAciTo;
    UserFilter.DDI_CUS_DELIVERY_FROM      := aCusDeliveryFrom;
    UserFilter.DDI_CUS_DELIVERY_TO        := aCusDeliveryTo;
    UserFilter.CUSTOMER_MIN_AMOUNT        := aCustomerMinAmount;
    UserFilter.GROUP_MIN_AMOUNT           := aGroupMinAmount;
    UserFilter.CUSTOMER_PERIOD            := aCustomerPeriod;
    UserFilter.DDI_REPRESENTATIVE_FROM    := aRepresentativeFrom;
    UserFilter.DDI_REPRESENTATIVE_TO      := aRepresentativeTo;
    UserFilter.DDI_REPR_ACI_FROM          := aReprAciFrom;
    UserFilter.DDI_REPR_ACI_TO            := aReprAciTo;
    UserFilter.DDI_REPR_DELIVERY_FROM     := aReprDeliveryFrom;
    UserFilter.DDI_REPR_DELIVERY_TO       := aReprDeliveryTo;
    UserFilter.DDI_RECORD_FROM            := aRecordFrom;
    UserFilter.DDI_RECORD_TO              := aRecordTo;
    UserFilter.DDI_GOOD_FROM              := aGoodFrom;
    UserFilter.DDI_GOOD_TO                := aGoodTo;
    UserFilter.GCO_GOOD_CATEGORY_ID       := aGoodCategoryID;
    UserFilter.DDI_BASIS_DELAY_FROM       := aBasisDelayFrom;
    UserFilter.DDI_BASIS_DELAY_TO         := aBasisDelayTo;
    UserFilter.DDI_INTER_DELAY_FROM       := aInterDelayFrom;
    UserFilter.DDI_INTER_DELAY_TO         := aInterDelayTo;
    UserFilter.DDI_FINAL_DELAY_FROM       := aFinalDelayFrom;
    UserFilter.DDI_FINAL_DELAY_TO         := aFinalDelayTo;

    -- Tout d'abord effacer toutes les données dans la table TEMP
    delete from DOC_PERIODIC_DISCHARGE;

    begin
      if aMode = 'BARCODE' then
        insert into DOC_PERIODIC_DISCHARGE
                    (DOC_PERIODIC_DISCHARGE_ID
                   , DOC_DOCUMENT_ID
                   , DOC_POSITION_ID
                   , DOC_POSITION_DETAIL_ID
                   , GCO_GOOD_ID
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_CUS_PARTNER_ACI_ID
                   , PAC_CUS_PARTNER_DELIVERY_ID
                   , ACS_AUXILIARY_ACCOUNT_ID
                   , DOC_GAUGE_ID
                   , DOC_GAUGE_FLOW_ID
                   , DOC_GAUGE_RECEIPT_ID
                   , DOC_GAUGE_POSITION_ID
                   , DOC_BARCODE_ID
                   , DDI_DISCHARGE_QUANTITY
                   , DDI_START_QUANTITY
                   , DDI_DETAIL_AMOUNT
                   , DDI_SELECTION
                    )
          select INIT_TEMP_ID_SEQ.nextval
               , PDE_FLT.DOC_DOCUMENT_ID
               , PDE_FLT.DOC_POSITION_ID
               , PDE_FLT.DOC_POSITION_DETAIL_ID
               , case
                   when DBC.DOC_BARCODE_ID is not null then DBC.GCO_GOOD_ID
                   else PDE_FLT.GCO_GOOD_ID
                 end as GCO_GOOD_ID
               , PDE_FLT.PAC_CUSTOM_PARTNER_ID
               , PDE_FLT.PAC_CUS_PARTNER_ACI_ID
               , PDE_FLT.PAC_CUS_PARTNER_DELIVERY_ID
               , PDE_FLT.ACS_AUXILIARY_ACCOUNT_ID
               , PDE_FLT.DOC_GAUGE_ID
               , PDE_FLT.DOC_GAUGE_FLOW_ID
               , null DOC_GAUGE_RECEIPT_ID
               , PDE_FLT.DOC_GAUGE_POSITION_ID
               , DBC.DOC_BARCODE_ID
               , nvl(DBC.DBA_QUANTITY, 0)
               , nvl(DBC.DBA_QUANTITY, 0)
               , nvl(DBC.DBA_QUANTITY, 0) *
                 (POS.POS_NET_VALUE_EXCL_B /
                  case
                    when nvl(GAP.GAP_VALUE_QUANTITY, 0) = 1 then decode(POS.POS_VALUE_QUANTITY, 0, null, POS.POS_VALUE_QUANTITY)
                    else decode(POS.POS_FINAL_QUANTITY, 0, null, POS.POS_FINAL_QUANTITY)
                  end
                 ) as DETAIL_AMOUNT
               , 1 as DDI_SELECTION
            from table(DOC_PERIODIC_DISCH_FUNCTIONS.GetFilterDetail) PDE_FLT
               , DOC_POSITION_DETAIL PDE
               , DOC_POSITION POS
               , DOC_GAUGE_POSITION GAP
               , (select distinct DOC_DOCUMENT_ID
                             from DOC_BARCODE
                            where C_DOC_BARCODE_STATUS = '30'
                              and (    (DBA_ACCEPT = 1)
                                   or (C_BARCODE_ERROR is null) ) ) DBC_DOC
               , (select *
                    from DOC_BARCODE
                   where C_DOC_BARCODE_STATUS = '30'
                     and (    (DBA_ACCEPT = 1)
                          or (C_BARCODE_ERROR is null) ) ) DBC
           where PDE_FLT.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
             and PDE_FLT.DOC_DOCUMENT_ID = DBC_DOC.DOC_DOCUMENT_ID
             and PDE.DOC_POSITION_DETAIL_ID = DBC.DOC_POSITION_DETAIL_ID(+)
             and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
             and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;
      elsif aMode = 'BILLING' then
        insert into DOC_PERIODIC_DISCHARGE
                    (DOC_PERIODIC_DISCHARGE_ID
                   , DOC_DOCUMENT_ID
                   , DOC_POSITION_ID
                   , DOC_POSITION_DETAIL_ID
                   , GCO_GOOD_ID
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_CUS_PARTNER_ACI_ID
                   , PAC_CUS_PARTNER_DELIVERY_ID
                   , ACS_AUXILIARY_ACCOUNT_ID
                   , DOC_GAUGE_ID
                   , DOC_GAUGE_FLOW_ID
                   , DOC_GAUGE_RECEIPT_ID
                   , DOC_GAUGE_POSITION_ID
                   , DDI_DISCHARGE_QUANTITY
                   , DDI_START_QUANTITY
                   , DDI_DETAIL_AMOUNT
                   , DDI_SELECTION
                    )
          select INIT_TEMP_ID_SEQ.nextval
               , PDE_FLT.DOC_DOCUMENT_ID
               , PDE_FLT.DOC_POSITION_ID
               , PDE_FLT.DOC_POSITION_DETAIL_ID
               , PDE_FLT.GCO_GOOD_ID
               , PDE_FLT.PAC_CUSTOM_PARTNER_ID
               , PDE_FLT.PAC_CUS_PARTNER_ACI_ID
               , PDE_FLT.PAC_CUS_PARTNER_DELIVERY_ID
               , PDE_FLT.ACS_AUXILIARY_ACCOUNT_ID
               , PDE_FLT.DOC_GAUGE_ID
               , PDE_FLT.DOC_GAUGE_FLOW_ID
               , null DOC_GAUGE_RECEIPT_ID
               , PDE_FLT.DOC_GAUGE_POSITION_ID
               , PDE.PDE_BALANCE_QUANTITY
               , PDE.PDE_BALANCE_QUANTITY
               , PDE.PDE_BALANCE_QUANTITY *
                 (POS.POS_NET_VALUE_EXCL_B /
                  case
                    when nvl(GAP.GAP_VALUE_QUANTITY, 0) = 1 then decode(POS.POS_VALUE_QUANTITY, 0, null, POS.POS_VALUE_QUANTITY)
                    else decode(POS.POS_FINAL_QUANTITY, 0, null, POS.POS_FINAL_QUANTITY)
                  end
                 ) as DETAIL_AMOUNT
               , 1 as DDI_SELECTION
            from table(DOC_PERIODIC_DISCH_FUNCTIONS.GetFilterDetail) PDE_FLT
               , DOC_POSITION_DETAIL PDE
               , DOC_POSITION POS
               , DOC_GAUGE_POSITION GAP
               , PAC_CUSTOM_PARTNER CUS_ACI
           where PDE_FLT.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
             and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
             and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
             and CUS_ACI.PAC_CUSTOM_PARTNER_ID = PDE_FLT.PAC_CUS_PARTNER_ACI_ID
             and CUS_ACI.CUS_PERIODIC_INVOICING = 1
             and (   aCustomerPeriod is null
                  or instr(';' || aCustomerPeriod || ';', ';' || nvl(CUS_ACI.DIC_INVOICING_PERIOD_ID, 'NONE') || ';') > 0);
      elsif aMode = 'DELIVERY' then
        insert into DOC_PERIODIC_DISCHARGE
                    (DOC_PERIODIC_DISCHARGE_ID
                   , DOC_DOCUMENT_ID
                   , DOC_POSITION_ID
                   , DOC_POSITION_DETAIL_ID
                   , GCO_GOOD_ID
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_CUS_PARTNER_ACI_ID
                   , PAC_CUS_PARTNER_DELIVERY_ID
                   , ACS_AUXILIARY_ACCOUNT_ID
                   , DOC_GAUGE_ID
                   , DOC_GAUGE_FLOW_ID
                   , DOC_GAUGE_RECEIPT_ID
                   , DOC_GAUGE_POSITION_ID
                   , DDI_DISCHARGE_QUANTITY
                   , DDI_START_QUANTITY
                   , DDI_DETAIL_AMOUNT
                   , DDI_SELECTION
                    )
          select INIT_TEMP_ID_SEQ.nextval
               , PDE_FLT.DOC_DOCUMENT_ID
               , PDE_FLT.DOC_POSITION_ID
               , PDE_FLT.DOC_POSITION_DETAIL_ID
               , PDE_FLT.GCO_GOOD_ID
               , PDE_FLT.PAC_CUSTOM_PARTNER_ID
               , PDE_FLT.PAC_CUS_PARTNER_ACI_ID
               , PDE_FLT.PAC_CUS_PARTNER_DELIVERY_ID
               , PDE_FLT.ACS_AUXILIARY_ACCOUNT_ID
               , PDE_FLT.DOC_GAUGE_ID
               , PDE_FLT.DOC_GAUGE_FLOW_ID
               , null DOC_GAUGE_RECEIPT_ID
               , PDE_FLT.DOC_GAUGE_POSITION_ID
               , PDE.PDE_BALANCE_QUANTITY
               , PDE.PDE_BALANCE_QUANTITY
               , PDE.PDE_BALANCE_QUANTITY *
                 (POS.POS_NET_VALUE_EXCL_B /
                  case
                    when nvl(GAP.GAP_VALUE_QUANTITY, 0) = 1 then decode(POS.POS_VALUE_QUANTITY, 0, null, POS.POS_VALUE_QUANTITY)
                    else decode(POS.POS_FINAL_QUANTITY, 0, null, POS.POS_FINAL_QUANTITY)
                  end
                 ) as DETAIL_AMOUNT
               , 1 as DDI_SELECTION
            from table(DOC_PERIODIC_DISCH_FUNCTIONS.GetFilterDetail) PDE_FLT
               , DOC_POSITION_DETAIL PDE
               , DOC_POSITION POS
               , DOC_GAUGE_POSITION GAP
               , PAC_CUSTOM_PARTNER CUS_DELIV
           where PDE_FLT.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
             and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
             and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
             and CUS_DELIV.PAC_CUSTOM_PARTNER_ID = PDE_FLT.PAC_CUS_PARTNER_DELIVERY_ID
             and CUS_DELIV.CUS_PERIODIC_DELIVERY = 1
             and (   aCustomerPeriod is null
                  or instr(';' || aCustomerPeriod || ';', ';' || nvl(CUS_DELIV.DIC_DELIVERY_PERIOD_ID, 'NONE') || ';') > 0);
      end if;
    exception
      when others then
        raise_application_error(-20901
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la création des propositions de décharge de type bien!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    begin
      -- Utilisation de la cmd user sur la sélection des détails
      if to_char(aUserSqlCommand) is not null then
        declare
          vSQL varchar2(32000);
        begin
          vSQL  :=
            'delete from DOC_PERIODIC_DISCHARGE ' ||
            ' where DOC_POSITION_DETAIL_ID not in (' ||
            'select PDE.DOC_POSITION_DETAIL_ID ' ||
            '  from DOC_POSITION_DETAIL PDE ' ||
            '     , DOC_POSITION POS ' ||
            '     , ( ' ||
            aUserSqlCommand ||
            ' ) USR ' ||
            ' where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID ' ||
            '   and POS.C_DOC_POS_STATUS in (''02'',''03'') ' ||
            '   and USR.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) ';
          vSQL  := replace(vSQL, '[CO' || '].', '');
          vSQL  := replace(vSQL, '[COMPANY_OWNER' || '].', '');

          execute immediate vSQL;
        end;
      end if;
    exception
      when others then
        raise_application_error(-20902
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant le traitement de la commande de sélection utilisateur!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    begin
      -- Traitement du flux de décharge
      InitDischargeFlow(aTgtGaugeID);
    exception
      when others then
        raise_application_error(-20903
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant le traitement du flux de décharge!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;

    -- Protéger les documents qui sont proposés pour la décharge
    ProtectPropDischDocuments(1);

    -- Effacer des propositions de décharge, les documents qui n'ont pas pu
    -- etre protegés ou qui ont été protégés par un autre utilisateur.
    -- Car en effet il est possible qu'un utilisateur ai pu proteger des documents
    -- pendant le laps de temps de notre protection de docs
    delete from DOC_PERIODIC_DISCHARGE DDI
          where DDI.DOC_DOCUMENT_ID =
                  (select DMT.DOC_DOCUMENT_ID
                     from DOC_DOCUMENT DMT
                    where DDI.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                      and (    (DMT.DMT_PROTECTED = 0)
                           or nvl(DMT.DMT_SESSION_ID, 'NULL') <> DBMS_SESSION.unique_session_id) );

    -- Récuperer les id des documents insérés
    select distinct DOC_DOCUMENT_ID
    bulk collect into vDocumentList
               from DOC_PERIODIC_DISCHARGE;

    -- Vérifier qu'il y ai des détails à décharger avant d'effectuer tout traitement
    if vDocumentList.count > 0 then
      -- Mode = Livraison + Attributions
      if     (aMode = 'DELIVERY')
         and (aAttribs = 1) then
        -- Effacement des attribs sur stock pour la reconstruction attribution
        if (aRedoAttrib = 1) then
          begin
            -- Effacer les attribs sur stock avant la reconstruction
            FAL_DELETE_ATTRIBS.Delete_All_Attribs_LogStk;
          exception
            when others then
              raise_application_error(-20904
                                    , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''effacement des attributions!') ||
                                      co.cLineBreak ||
                                      sqlerrm ||
                                      co.cLineBreak ||
                                      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                     );
          end;
        end if;

        -- Reconstruire/Réactualisation les attribs
        if    (aRedoAttrib = 1)
           or (aRefreshAttrib = 1) then
          begin
            -- Définition des codes/messages d'erreur pour les attribs
            -- Reconstruction attribution
            if (aRedoAttrib = 1) then
              vErrorCode  := -20905;
              vErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la reconstruction des attributions!');
            -- Réactualisation attribution
            elsif(aRefreshAttrib = 1) then
              vErrorCode  := -20906;
              vErrorMsg   := PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la réactualisation des attributions!');
            end if;

            -- Reconstruire/Réactualiser l'attrib si
            --   Si flag "Uniquement pour les documents gérant les attributions directes" = 0
            --     OU
            --   Si flag "Uniquement pour les documents gérant les attributions directes" = 1
            --   ET gabarit gére les attribs en automatique
            for tplPos in (select distinct DDI.DOC_POSITION_ID
                                      from DOC_PERIODIC_DISCHARGE DDI
                                         , DOC_GAUGE_STRUCTURED GAS
                                     where DDI.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                                       and (    (aOnlyAttribManagDoc = 0)
                                            or (     (aOnlyAttribManagDoc = 1)
                                                and (GAS.GAS_AUTO_ATTRIBUTION = 1) ) ) ) loop
              -- Reconstruction attribution
              if (aRedoAttrib = 1) then
                FAL_REDO_ATTRIBS.RedoAttribsByDocOrPos(null, tplPos.DOC_POSITION_ID);
              -- Réactualisation attribution
              elsif(aRefreshAttrib = 1) then
                FAL_REDO_ATTRIBS.ReactAttribsByDocOrPos(null, tplPos.DOC_POSITION_ID);
              end if;
            end loop;
          exception
            when others then
              raise_application_error(vErrorCode, vErrorMsg || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
          end;
        end if;

        begin
          -- Prendre en charge le fait qu'un même détail peut avoir plusieurs attributions
          select *
          bulk collect into vDetailList
            from DOC_PERIODIC_DISCHARGE;

          delete from DOC_PERIODIC_DISCHARGE;

          for vIndex in vDetailList.first .. vDetailList.last loop
            insert into DOC_PERIODIC_DISCHARGE
                        (DOC_PERIODIC_DISCHARGE_ID
                       , DOC_DOCUMENT_ID
                       , DOC_POSITION_ID
                       , DOC_POSITION_DETAIL_ID
                       , GCO_GOOD_ID
                       , PAC_CUSTOM_PARTNER_ID
                       , PAC_CUS_PARTNER_ACI_ID
                       , PAC_CUS_PARTNER_DELIVERY_ID
                       , ACS_AUXILIARY_ACCOUNT_ID
                       , DOC_GAUGE_ID
                       , DOC_GAUGE_FLOW_ID
                       , DOC_GAUGE_RECEIPT_ID
                       , DOC_GAUGE_POSITION_ID
                       , DDI_DISCHARGE_QUANTITY
                       , DDI_START_QUANTITY
                       , DDI_DETAIL_AMOUNT
                       , FAL_NETWORK_LINK_ID
                        )
              select INIT_ID_SEQ.nextval
                   , vDetailList(vIndex).DOC_DOCUMENT_ID
                   , vDetailList(vIndex).DOC_POSITION_ID
                   , vDetailList(vIndex).DOC_POSITION_DETAIL_ID
                   , vDetailList(vIndex).GCO_GOOD_ID
                   , vDetailList(vIndex).PAC_CUSTOM_PARTNER_ID
                   , vDetailList(vIndex).PAC_CUS_PARTNER_ACI_ID
                   , vDetailList(vIndex).PAC_CUS_PARTNER_DELIVERY_ID
                   , vDetailList(vIndex).ACS_AUXILIARY_ACCOUNT_ID
                   , vDetailList(vIndex).DOC_GAUGE_ID
                   , vDetailList(vIndex).DOC_GAUGE_FLOW_ID
                   , vDetailList(vIndex).DOC_GAUGE_RECEIPT_ID
                   , vDetailList(vIndex).DOC_GAUGE_POSITION_ID
                   , null DDI_DISCHARGE_QUANTITY
                   , case
                       when PDE.PDE_BALANCE_QUANTITY = 0 then 0
                       when POS.C_GAUGE_TYPE_POS = '1' then decode(nvl(PDT.PDT_STOCK_MANAGEMENT, 0), 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                       when POS.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then least(DOC_ATTRIB_FUNCTIONS.GetAttribComponentsQty(PDE.DOC_POSITION_ID)
                                                                                  , PDE.PDE_BALANCE_QUANTITY
                                                                                   )
                       else PDE.PDE_BALANCE_QUANTITY
                     end DDI_START_QUANTITY
                   , null DDI_DETAIL_AMOUNT
                   , FLN.FAL_NETWORK_LINK_ID
                from DOC_POSITION POS
                   , DOC_POSITION_DETAIL PDE
                   , GCO_GOOD GOO
                   , GCO_PRODUCT PDT
                   , FAL_NETWORK_NEED FAN
                   , FAL_NETWORK_LINK FLN
                   , STM_STOCK_POSITION SPO
               where PDE.DOC_POSITION_DETAIL_ID = vDetailList(vIndex).DOC_POSITION_DETAIL_ID
                 and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                 and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                 and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                 and FLN.STM_STOCK_POSITION_ID(+) is not null
                 and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                 and GOO.GCO_GOOD_ID = vDetailList(vIndex).GCO_GOOD_ID
                 and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);
          end loop;

          -- Liberer la mémoire utilisée par la variable
          vDetailList.delete;

          -- Effacement des détails qui n'on aucune qté attribuée
          -- MAIS il ne faut pas effacer les positions avec des services
          delete from DOC_PERIODIC_DISCHARGE
                where DOC_PERIODIC_DISCHARGE_ID in(
                        select DDI.DOC_PERIODIC_DISCHARGE_ID
                          from DOC_PERIODIC_DISCHARGE DDI
                             , DOC_POSITION POS
                         where DDI.DDI_START_QUANTITY = 0
                           and DDI.DOC_POSITION_ID = POS.DOC_POSITION_ID
                           and POS.C_GAUGE_TYPE_POS not in('4', '5')
                           and (select max(GCO_GOOD_ID)
                                  from GCO_SERVICE
                                 where GCO_GOOD_ID = DDI.GCO_GOOD_ID) is null);

          -- Màj le champs contenant la qté de décharge
          update DOC_PERIODIC_DISCHARGE
             set DDI_DISCHARGE_QUANTITY = DDI_START_QUANTITY;
        exception
          when others then
            raise_application_error(-20907
                                  , PCS.PC_FUNCTIONS.TranslateWord('PCS - Création des propositions de décharge impossible!') ||
                                    co.cLineBreak ||
                                    sqlerrm ||
                                    co.cLineBreak ||
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                   );
        end;
      else   -- Facturation ou  Livraison sans attrib
        -- Si en facturation -> Apliquer le filtre sur les montants min
        if aMode = 'BILLING' then
          begin
            if    (aCustomerMinAmount > 0)
               or (aGroupMinAmount > 0) then
              -- Apliquer le filtre sur les montants min client définis dans l'object
              if aCustomerMinAmount > 0 then
                delete from DOC_PERIODIC_DISCHARGE
                      where PAC_CUS_PARTNER_ACI_ID in(select   PAC_CUS_PARTNER_ACI_ID
                                                          from DOC_PERIODIC_DISCHARGE
                                                      group by PAC_CUS_PARTNER_ACI_ID
                                                        having sum(DDI_DETAIL_AMOUNT) < aCustomerMinAmount);
              end if;

              -- Apliquer le filtre sur les montants min groupe définis dans l'object
              if aGroupMinAmount > 0 then
                delete from DOC_PERIODIC_DISCHARGE
                      where ACS_AUXILIARY_ACCOUNT_ID in(select   ACS_AUXILIARY_ACCOUNT_ID
                                                            from DOC_PERIODIC_DISCHARGE
                                                        group by ACS_AUXILIARY_ACCOUNT_ID
                                                          having sum(DDI_DETAIL_AMOUNT) < aCustomerMinAmount);
              end if;
            else
              -- Règles pour l'effacement des détails à décharger de la table DOC_PERIODIC_DISCHARGE.
              --   Si Délai minimum de facturation dépassé  (sysdate - délai montant minimum > date document) Alors
              --     Garder la position pour la décharge
              --   Sinon
              --     Si Montant minimum de facturation atteint
              --       Garder la position pour la décharge
              --     Sinon
              --       Effacer la position de la décharge
              delete from DOC_PERIODIC_DISCHARGE
                    where DOC_PERIODIC_DISCHARGE_ID in(
                            select DDI.DOC_PERIODIC_DISCHARGE_ID
                              from DOC_PERIODIC_DISCHARGE DDI
                                 , DOC_DOCUMENT DMT
                                 , PAC_CUSTOM_PARTNER CUS
                             where DDI.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                               and DDI.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                               and (   nvl(CUS.CUS_MIN_INVOICING_DELAY, 0) = 0
                                    or trunc(DMT.DMT_DATE_DOCUMENT) > trunc(sysdate) - nvl(CUS.CUS_MIN_INVOICING_DELAY, 0)
                                   )
                               and nvl(CUS.CUS_MIN_INVOICING, 0) > (select sum(DDI_DETAIL_AMOUNT)
                                                                      from DOC_PERIODIC_DISCHARGE
                                                                     where PAC_CUSTOM_PARTNER_ID = DDI.PAC_CUSTOM_PARTNER_ID) );
            end if;
          exception
            when others then
              raise_application_error(-20908
                                    , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de l''application des montants minimums de facturation!') ||
                                      co.cLineBreak ||
                                      sqlerrm ||
                                      co.cLineBreak ||
                                      DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                     );
          end;
        end if;
      end if;

      -- Récuperer les id des documents restants
      select distinct DOC_DOCUMENT_ID
      bulk collect into vDocumentFinalList
                 from DOC_PERIODIC_DISCHARGE;

      -- Déproteger les documents qui ont été extraits initialement, mais
      -- qui selon les critères des attribs ou des montant minimum ont été
      -- exclus par la suite
      begin
        -- Balayer la liste des documents de la sélection initiale
        for vIndex in vDocumentList.first .. vDocumentList.last loop
          vFound  := false;

          -- Balayer la liste des documents retenus pour la décharge
          if vDocumentFinalList.count > 0 then
            for vIndex2 in vDocumentFinalList.first .. vDocumentFinalList.last loop
              if vDocumentFinalList(vIndex2) = vDocumentList(vIndex) then
                vFound  := true;
              end if;
            end loop;
          end if;

          -- Si document n'est plus présent, déprotéger celui-ci
          if not vFound then
            DOC_DOCUMENT_FUNCTIONS.DocumentProtect_AutoTrans(aDocumentID   => vDocumentList(vIndex), aProtect => 0
                                                           , aSessionID    => DBMS_SESSION.unique_session_id);
          end if;
        end loop;

        -- Liberer la mémoire utilisée par la variable
        vDocumentList.delete;
      exception
        when others then
          null;
      end;

      -- Vérifier qu'il y ai des détails à décharger avant d'inserer les positions de type 4 et 5
      if vDocumentFinalList.count > 0 then
        -- Insertion des positions de type 4 et 5
        begin
          -- Insertion dans la table temp des positions de type 4 et 5 des documents qui y figurent déjà
          insert into DOC_PERIODIC_DISCHARGE
                      (DOC_PERIODIC_DISCHARGE_ID
                     , DOC_DOCUMENT_ID
                     , DOC_POSITION_ID
                     , DOC_POSITION_DETAIL_ID
                     , GCO_GOOD_ID
                     , PAC_CUSTOM_PARTNER_ID
                     , PAC_CUS_PARTNER_ACI_ID
                     , PAC_CUS_PARTNER_DELIVERY_ID
                     , ACS_AUXILIARY_ACCOUNT_ID
                     , DOC_GAUGE_ID
                     , DOC_GAUGE_FLOW_ID
                     , DOC_GAUGE_RECEIPT_ID
                     , DOC_GAUGE_POSITION_ID
                     , DDI_DISCHARGE_QUANTITY
                     , DDI_START_QUANTITY
                     , DDI_DETAIL_AMOUNT
                      )
            select INIT_TEMP_ID_SEQ.nextval
                 , DMT.DOC_DOCUMENT_ID
                 , POS.DOC_POSITION_ID
                 , PDE.DOC_POSITION_DETAIL_ID
                 , null GCO_GOOD_ID
                 , CUS.PAC_CUSTOM_PARTNER_ID
                 , CUS_ACI.PAC_CUSTOM_PARTNER_ID PAC_CUS_PARTNER_ACI_ID
                 , CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID PAC_CUS_PARTNER_DELIVERY_ID
                 , CUS_ACI.ACS_AUXILIARY_ACCOUNT_ID
                 , DMT.DOC_GAUGE_ID
                 , PDE.DOC_GAUGE_FLOW_ID
                 , null DOC_GAUGE_RECEIPT_ID
                 , GAP.DOC_GAUGE_POSITION_ID
                 , null PDE_BALANCE_QUANTITY
                 , null PDE_BALANCE_QUANTITY
                 , 0 DETAIL_AMOUNT
              from DOC_DOCUMENT DMT
                 , (select distinct DOC_DOCUMENT_ID
                               from DOC_PERIODIC_DISCHARGE) DDI
                 , DOC_GAUGE GAU
                 , PAC_CUSTOM_PARTNER CUS
                 , PAC_CUSTOM_PARTNER CUS_ACI
                 , PAC_CUSTOM_PARTNER CUS_DELIVERY
                 , DOC_POSITION POS
                 , DOC_POSITION_DETAIL PDE
                 , DOC_GAUGE_POSITION GAP
             where DDI.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
               and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
               and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
               and DMT.PAC_THIRD_ACI_ID = CUS_ACI.PAC_CUSTOM_PARTNER_ID
               and DMT.PAC_THIRD_DELIVERY_ID = CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID
               and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
               and GAP.C_GAUGE_TYPE_POS = POS.C_GAUGE_TYPE_POS
               and GAP.GAP_DEFAULT = 1
               and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
               and POS.C_GAUGE_TYPE_POS in('4', '5')
               and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID;
        exception
          when others then
            raise_application_error(-20909
                                  , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la création des propositions de décharge de type texte ou valeur!') ||
                                    co.cLineBreak ||
                                    sqlerrm ||
                                    co.cLineBreak ||
                                    DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                                   );
        end;
      end if;
    end if;
  end GeneratePropositions;

  /**
  * procedure RegroupDischargeProcess
  * Description
  *   Regroupement de données de décharge par rapport à la commdand d'affichage
  *     de l'utilisateur
  */
  procedure RegroupDischargeProcess(aOracleJob in integer, aSQLCommand in clob)
  is
    type TToUpdateType is ref cursor;   -- define weak REF CURSOR type

    crToUpdate                 TToUpdateType;
    vUpdateSqlCmd              varchar2(32000);
    vDOC_PERIODIC_DISCHARGE_ID DOC_PERIODIC_DISCHARGE.DOC_PERIODIC_DISCHARGE_ID%type;
    vDDI_REGROUP_01            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_01%type;
    vDDI_REGROUP_02            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_02%type;
    vDDI_REGROUP_03            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_03%type;
    vDDI_REGROUP_04            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_04%type;
    vDDI_REGROUP_05            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_05%type;
    vDDI_REGROUP_06            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_06%type;
    vDDI_REGROUP_07            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_07%type;
    vDDI_REGROUP_08            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_08%type;
    vDDI_REGROUP_09            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_09%type;
    vDDI_REGROUP_10            DOC_PERIODIC_DISCHARGE.DDI_REGROUP_10%type;
  begin
    -- commande pour la reprise des données de la cmd utilisateur
    -- (champs de regroupement, champ de tri)
    vUpdateSqlCmd  :=
      'select USR_CMD.DOC_PERIODIC_DISCHARGE_ID  ' ||
      '     , substr(USR_CMD.REGROUP_01, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_02, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_03, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_04, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_05, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_06, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_07, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_08, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_09, 1, 100) ' ||
      '     , substr(USR_CMD.REGROUP_10, 1, 100) ' ||
      '  from DOC_PERIODIC_DISCHARGE MAIN ' ||
      '     , (select REGROUP_01 ' ||
      '             , REGROUP_02 ' ||
      '             , REGROUP_03 ' ||
      '             , REGROUP_04 ' ||
      '             , REGROUP_05 ' ||
      '             , REGROUP_06 ' ||
      '             , REGROUP_07 ' ||
      '             , REGROUP_08 ' ||
      '             , REGROUP_09 ' ||
      '             , REGROUP_10 ' ||
      '             , DOC_PERIODIC_DISCHARGE_ID ' ||
      '             , rownum USER_ROWNUM ' ||
      '          from ( ' ||
      aSQLCommand ||
      ' ) ) USR_CMD ' ||
      '  where USR_CMD.DOC_PERIODIC_DISCHARGE_ID = MAIN.DOC_PERIODIC_DISCHARGE_ID ';

    -- Si en décharge depuis l'interface, il faut seulement tenir compte des positions sélectionnées
    -- Si en décharge depuis job oracle, il faut prendre toutes les positions de la cmd SQL utilisateur
    if aOracleJob = 0 then
      vUpdateSqlCmd  := vUpdateSqlCmd || ' and MAIN.DDI_SELECTION = 1 ';
    end if;

    vUpdateSqlCmd  := vUpdateSqlCmd || ' order by USR_CMD.USER_ROWNUM ';
    -- remplacement des macros
    vUpdateSqlCmd  := replace(vUpdateSqlCmd, '[CO' || '].', '');
    vUpdateSqlCmd  := replace(vUpdateSqlCmd, '[COMPANY_OWNER' || '].', '');

    begin
      open crToUpdate for vUpdateSqlCmd;

      loop
        -- reprendre les données de regroupement et de tri de la cmd sql utilisateur de l'affichage des propositions
        fetch crToUpdate
         into vDOC_PERIODIC_DISCHARGE_ID
            , vDDI_REGROUP_01
            , vDDI_REGROUP_02
            , vDDI_REGROUP_03
            , vDDI_REGROUP_04
            , vDDI_REGROUP_05
            , vDDI_REGROUP_06
            , vDDI_REGROUP_07
            , vDDI_REGROUP_08
            , vDDI_REGROUP_09
            , vDDI_REGROUP_10;

        exit when crToUpdate%notfound;

        -- Màj des champs de regroupement et du champ de tri des propositions de décharge
        update DOC_PERIODIC_DISCHARGE
           set DDI_REGROUP_01 = vDDI_REGROUP_01
             , DDI_REGROUP_02 = vDDI_REGROUP_02
             , DDI_REGROUP_03 = vDDI_REGROUP_03
             , DDI_REGROUP_04 = vDDI_REGROUP_04
             , DDI_REGROUP_05 = vDDI_REGROUP_05
             , DDI_REGROUP_06 = vDDI_REGROUP_06
             , DDI_REGROUP_07 = vDDI_REGROUP_07
             , DDI_REGROUP_08 = vDDI_REGROUP_08
             , DDI_REGROUP_09 = vDDI_REGROUP_09
             , DDI_REGROUP_10 = vDDI_REGROUP_10
             , DDI_ORDER_BY = INIT_TEMP_ID_SEQ.nextval
             , DDI_SELECTION = 1
         where DOC_PERIODIC_DISCHARGE_ID = vDOC_PERIODIC_DISCHARGE_ID;
      end loop;

      commit;
    exception
      when others then
        raise_application_error(-20910
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors du regroupement des propositions à décharger!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;
  end RegroupDischargeProcess;

  /**
  * procedure ConfirmDocument
  * Description
  *   Méthode d'encapsulation de la confirmation de document
  */
  procedure ConfirmDocument(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    vErrorCode varchar2(3)     default null;
    vErrorText varchar2(32000) default null;
  begin
    DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(aDocumentId => aDocumentID, aErrorCode => vErrorCode, aErrorText => vErrorText, aUserConfirmation => 1);
    commit;

    -- Màj la table contenant le résultat de la décharge en indiquant que ce document a été confirmé
    if     vErrorCode is null
       and vErrorCode is null then
      update DOC_PERIODIC_DISCH_RESULT
         set DDR_CONFIRMED = 1
       where DOC_DOCUMENT_ID = aDocumentID;

      commit;
    end if;
  exception
    when others then
      null;
  end ConfirmDocument;

  /**
  * procedure InsertDischargeDetail
  * Description
  *     Insère dans la table DOC_POS_DET_COPY_DISCHARGE un détail de position de la table des propositions
  * @version 2004
  * @created NGV
  */
  procedure InsertDischargeDetail(
    aNewDocumentID   in number
  , aDetailID        in number
  , aGaugeID         in number
  , aThirdID         in number
  , aThirdAciID      in number
  , aThirdDeliveryID in number
  , aCreateMode      in varchar2
  )
  is
    cursor crDischargePde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , DDI.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , DDI.DDI_DISCHARGE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(DDI.DDI_DISCHARGE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aGaugeID, aThirdID) as DCD_BALANCE_FLAG
                    , 0 as DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_PERIODIC_DISCHARGE DDI
                    , DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE GAU
                where DDI.DOC_POSITION_DETAIL_ID = aDetailID
                  and DDI.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);

    tplDischargePde              crDischargePde%rowtype;

    cursor crDischargePdeCPT(cPTPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , POS.POS_NUMBER
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , least(DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1), PDE.PDE_BALANCE_QUANTITY) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(least(DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1), PDE.PDE_BALANCE_QUANTITY)
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aGaugeID, aThirdID) as DCD_BALANCE_FLAG
                    , 0 as DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = cPTPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT           crDischargePdeCPT%rowtype;
    --
    vInsertDcd                   V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt                V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vNewDcdID                    DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    --
    dblQuantityCPT               DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblQuantityCPT_SU            DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    dblGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
  begin
    /* Détail de position à décharger */
    open crDischargePde;

    fetch crDischargePde
     into tplDischargePde;

    /* insertion dans la table de décharge du détail concerné */
    if crDischargePde%found then
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      vInsertDcd.DOC_POS_DET_COPY_DISCHARGE_ID  := vNewDcdID;
      vInsertDcd.DOC_POSITION_DETAIL_ID         := tplDischargePde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID                := aNewDocumentID;
      vInsertDcd.CRG_SELECT                     := tplDischargePde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID              := tplDischargePde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID                := tplDischargePde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID            := tplDischargePde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID     := tplDischargePde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID    := tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                    := tplDischargePde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID                := tplDischargePde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID        := tplDischargePde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID    := tplDischargePde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID            := tplDischargePde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID           := tplDischargePde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_RECORD_ID                  := tplDischargePde.DOC_RECORD_ID;
      vInsertDcd.DOC_DOCUMENT_ID                := tplDischargePde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                   := tplDischargePde.PAC_THIRD_ID;
      vInsertDcd.DOC_GAUGE_ID                   := tplDischargePde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID           := tplDischargePde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID              := tplDischargePde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS               := tplDischargePde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID       := tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY                := tplDischargePde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY         := tplDischargePde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY                := tplDischargePde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY         := tplDischargePde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY             := tplDischargePde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY      := tplDischargePde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY             := tplDischargePde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY           := tplDischargePde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT    := tplDischargePde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU          := tplDischargePde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU   := tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU          := tplDischargePde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY          := tplDischargePde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE             := tplDischargePde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT          := tplDischargePde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                  := tplDischargePde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                  := tplDischargePde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                  := tplDischargePde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                     := tplDischargePde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                     := tplDischargePde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                     := tplDischargePde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                     := tplDischargePde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                     := tplDischargePde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                     := tplDischargePde.PDE_DATE_3;
      vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_QUANTITY                   := tplDischargePde.DCD_QUANTITY;
      vInsertDcd.DCD_QUANTITY_SU                := tplDischargePde.DCD_QUANTITY_SU;
      vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC        := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
      vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE              := aCreateMode;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      /* Traitment des pos cpt si il s'agit d0un posiiton kit ou assemblage */
      if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        dblGreatestSumQuantityCPT     := 0;
        dblGreatestSumQuantityCPT_SU  := 0;

        for tplDischargePdeCPT in crDischargePdeCPT(tplDischargePde.DOC_POSITION_ID) loop
          dblQuantityCPT                              := tplDischargePdeCPT.DCD_QUANTITY;
          dblQuantityCPT_SU                           := tplDischargePdeCPT.DCD_QUANTITY_SU;

          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplDischargePdeCPT.POS_UTIL_COEFF, 0) = 0) then
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
          else
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, dblQuantityCPT / tplDischargePdeCPT.POS_UTIL_COEFF);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, dblQuantityCPT_SU / tplDischargePdeCPT.POS_UTIL_COEFF);
          end if;

          vInsertDcdCpt                               := null;
          vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.NEW_DOCUMENT_ID               := aNewDocumentID;
          vInsertDcdCpt.CRG_SELECT                    := tplDischargePdeCPT.CRG_SELECT;
          vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := tplDischargePde.DOC_GAUGE_FLOW_ID;   -- Flux de la position PT
          vInsertDcdCpt.DOC_POSITION_ID               := tplDischargePdeCPT.DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_ID           := tplDischargePdeCPT.DOC_DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := tplDischargePdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := tplDischargePdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.GCO_GOOD_ID                   := tplDischargePdeCPT.GCO_GOOD_ID;
          vInsertDcdCpt.STM_LOCATION_ID               := tplDischargePdeCPT.STM_LOCATION_ID;
          vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := tplDischargePdeCPT.GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := tplDischargePdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.STM_STM_LOCATION_ID           := tplDischargePdeCPT.STM_STM_LOCATION_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := tplDischargePdeCPT.FAL_SCHEDULE_STEP_ID;
          vInsertDcdCpt.DOC_RECORD_ID                 := tplDischargePdeCPT.DOC_RECORD_ID;
          vInsertDcdCpt.DOC_DOCUMENT_ID               := tplDischargePdeCPT.DOC_DOCUMENT_ID;
          vInsertDcdCpt.PAC_THIRD_ID                  := tplDischargePdeCPT.PAC_THIRD_ID;
          vInsertDcdCpt.DOC_GAUGE_ID                  := tplDischargePdeCPT.DOC_GAUGE_ID;
          vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := tplDischargePdeCPT.DOC_GAUGE_RECEIPT_ID;
          vInsertDcdCpt.DOC_GAUGE_COPY_ID             := tplDischargePdeCPT.DOC_GAUGE_COPY_ID;
          vInsertDcdCpt.C_GAUGE_TYPE_POS              := tplDischargePdeCPT.C_GAUGE_TYPE_POS;
          vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := tplDischargePdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vInsertDcdCpt.PDE_BASIS_DELAY               := tplDischargePdeCPT.PDE_BASIS_DELAY;
          vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := tplDischargePdeCPT.PDE_INTERMEDIATE_DELAY;
          vInsertDcdCpt.PDE_FINAL_DELAY               := tplDischargePdeCPT.PDE_FINAL_DELAY;
          vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := tplDischargePdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vInsertDcdCpt.PDE_BASIS_QUANTITY            := tplDischargePdeCPT.PDE_BASIS_QUANTITY;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vInsertDcdCpt.PDE_FINAL_QUANTITY            := tplDischargePdeCPT.PDE_FINAL_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY          := tplDischargePdeCPT.PDE_BALANCE_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := tplDischargePdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := tplDischargePdeCPT.PDE_BASIS_QUANTITY_SU;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := tplDischargePdeCPT.PDE_FINAL_QUANTITY_SU;
          vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := tplDischargePdeCPT.PDE_MOVEMENT_QUANTITY;
          vInsertDcdCpt.PDE_MOVEMENT_VALUE            := tplDischargePdeCPT.PDE_MOVEMENT_VALUE;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := tplDischargePdeCPT.PDE_DELAY_UPDATE_TEXT;
          vInsertDcdCpt.PDE_DECIMAL_1                 := tplDischargePdeCPT.PDE_DECIMAL_1;
          vInsertDcdCpt.PDE_DECIMAL_2                 := tplDischargePdeCPT.PDE_DECIMAL_2;
          vInsertDcdCpt.PDE_DECIMAL_3                 := tplDischargePdeCPT.PDE_DECIMAL_3;
          vInsertDcdCpt.PDE_TEXT_1                    := tplDischargePdeCPT.PDE_TEXT_1;
          vInsertDcdCpt.PDE_TEXT_2                    := tplDischargePdeCPT.PDE_TEXT_2;
          vInsertDcdCpt.PDE_TEXT_3                    := tplDischargePdeCPT.PDE_TEXT_3;
          vInsertDcdCpt.PDE_DATE_1                    := tplDischargePdeCPT.PDE_DATE_1;
          vInsertDcdCpt.PDE_DATE_2                    := tplDischargePdeCPT.PDE_DATE_2;
          vInsertDcdCpt.PDE_DATE_3                    := tplDischargePdeCPT.PDE_DATE_3;
          vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := tplDischargePdeCPT.PDE_GENERATE_MOVEMENT;
          vInsertDcdCpt.DCD_QUANTITY                  := dblQuantityCPT;
          vInsertDcdCpt.DCD_QUANTITY_SU               := dblQuantityCPT_SU;
          vInsertDcdCpt.DCD_BALANCE_FLAG              := tplDischargePdeCPT.DCD_BALANCE_FLAG;
          vInsertDcdCpt.POS_CONVERT_FACTOR            := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplDischargePdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vInsertDcdCpt.POS_UTIL_COEFF                := tplDischargePdeCPT.POS_UTIL_COEFF;
          vInsertDcdCpt.DCD_VISIBLE                   := tplDischargePdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := aCreateMode;
          vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;

        /**
        * Redéfinit la quantité du produit terminé en fonction de la quantité
        * des composants.
        *
        *   Selon la règle suivante (facture des livraisons CPT) :
        *
        *   Si toutes les quantités des composants sont à 0 alors on initialise
        *   la quantité du produit terminé avec 0, sinon on conserve la quantité
        *   initiale (quantité solde).
        */
        if (dblGreatestSumQuantityCPT = 0) then
          update DOC_POS_DET_COPY_DISCHARGE
             set DCD_QUANTITY = 0
               , DCD_QUANTITY_SU = 0
           where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
        end if;

        close crDischargePdeCPT;
      end if;
    end if;

    close crDischargePde;
  end InsertDischargeDetail;

  /**
  * procedure InsertDischargeDetailAttrib
  * Description
  *     Insère dans la table DOC_POS_DET_COPY_DISCHARGE un détail de position de la table des propositions
  *       en tenant compte des attribution pour les valeurs de caractérisation
  * @version 2004
  * @created NGV
  */
  procedure InsertDischargeDetailAttrib(
    aNewDocumentID   in number
  , aPeriodicDischID in number
  , aGaugeID         in number
  , aThirdID         in number
  , aThirdAciID      in number
  , aThirdDeliveryID in number
  , aCreateMode      in varchar2
  )
  is
    cursor crDischargePde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , DDI.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , SPO.STM_LOCATION_ID
                    , SPO.GCO_CHARACTERIZATION_ID
                    , SPO.GCO_GCO_CHARACTERIZATION_ID
                    , SPO.GCO2_GCO_CHARACTERIZATION_ID
                    , SPO.GCO3_GCO_CHARACTERIZATION_ID
                    , SPO.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , SPO.SPO_CHARACTERIZATION_VALUE_1
                    , SPO.SPO_CHARACTERIZATION_VALUE_2
                    , SPO.SPO_CHARACTERIZATION_VALUE_3
                    , SPO.SPO_CHARACTERIZATION_VALUE_4
                    , SPO.SPO_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , DDI.DDI_DISCHARGE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(DDI.DDI_DISCHARGE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aGaugeID, aThirdID) as DCD_BALANCE_FLAG
                    , 0 as DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , FLN.FAL_NETWORK_LINK_ID
                    , GAP.DOC_DOC_GAUGE_POSITION_ID
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_PERIODIC_DISCHARGE DDI
                    , DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE GAU
                    , DOC_GAUGE_POSITION GAP
                    , FAL_NETWORK_LINK FLN
                    , STM_STOCK_POSITION SPO
                where DDI.DOC_PERIODIC_DISCHARGE_ID = aPeriodicDischID
                  and DDI.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and FLN.FAL_NETWORK_LINK_ID(+) = DDI.FAL_NETWORK_LINK_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+);

    tplDischargePde    crDischargePde%rowtype;

    cursor crDischargePdeCPT(cPTPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , DCD.CRG_SELECT
                    , DCD.DCD_QUANTITY
                    , POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = cPTPositionID
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT crDischargePdeCPT%rowtype;
    --
    vNewDcdID          DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    vInsertDcd         V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
  begin
    /* Détail de position à décharger */
    open crDischargePde;

    fetch crDischargePde
     into tplDischargePde;

    /* insertion dans la table de décharge du détail concerné */
    if crDischargePde%found then
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      vInsertDcd.DOC_POS_DET_COPY_DISCHARGE_ID  := vNewDcdID;
      vInsertDcd.DOC_POSITION_DETAIL_ID         := tplDischargePde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID                := aNewDocumentID;
      vInsertDcd.CRG_SELECT                     := tplDischargePde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID              := tplDischargePde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID                := tplDischargePde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID            := tplDischargePde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID     := tplDischargePde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID    := tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                    := tplDischargePde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID                := tplDischargePde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID        := tplDischargePde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID    := tplDischargePde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID            := tplDischargePde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID           := tplDischargePde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_RECORD_ID                  := tplDischargePde.DOC_RECORD_ID;
      vInsertDcd.DOC_DOCUMENT_ID                := tplDischargePde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                   := tplDischargePde.PAC_THIRD_ID;
      vInsertDcd.DOC_GAUGE_ID                   := tplDischargePde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID           := tplDischargePde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID              := tplDischargePde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS               := tplDischargePde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID       := tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY                := tplDischargePde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY         := tplDischargePde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY                := tplDischargePde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY         := tplDischargePde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY             := tplDischargePde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY      := tplDischargePde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY             := tplDischargePde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY           := tplDischargePde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT    := tplDischargePde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU          := tplDischargePde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU   := tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU          := tplDischargePde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY          := tplDischargePde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE             := tplDischargePde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1   := tplDischargePde.SPO_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2   := tplDischargePde.SPO_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3   := tplDischargePde.SPO_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4   := tplDischargePde.SPO_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5   := tplDischargePde.SPO_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT          := tplDischargePde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                  := tplDischargePde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                  := tplDischargePde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                  := tplDischargePde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                     := tplDischargePde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                     := tplDischargePde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                     := tplDischargePde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                     := tplDischargePde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                     := tplDischargePde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                     := tplDischargePde.PDE_DATE_3;
      vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_QUANTITY                   := tplDischargePde.DCD_QUANTITY;
      vInsertDcd.DCD_QUANTITY_SU                := tplDischargePde.DCD_QUANTITY_SU;
      vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC        := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
      vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.FAL_NETWORK_LINK_ID            := tplDischargePde.FAL_NETWORK_LINK_ID;
      vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE              := aCreateMode;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      /* Traitment des pos cpt s'il s'agit d'une position kit ou assemblage */
      if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        /**
        * Traitement des détails de positions composants.
        */
        for tplDischargePdeCPT in crDischargePdeCPT(tplDischargePde.DOC_POSITION_ID) loop
          if tplDischargePde.DOC_DOC_GAUGE_POSITION_ID is null then
            /* Si aucun gabarit position lié. Les cpts sont toujours inférieurs
               ou égal au PT. Pour garantir cela, il faut inserer dans la vue
               et non directement dans la table. En effet, la vue recalcul la
               quantité du composant en fonction du PT. */
            insert into V_DOC_POS_DET_COPY_DISCHARGE
                        (DOC_POSITION_DETAIL_ID
                       , NEW_DOCUMENT_ID
                       , CRG_SELECT
                       , DOC_GAUGE_FLOW_ID
                       , DOC_POSITION_ID
                       , DOC_DOC_POSITION_ID
                       , DOC_DOC_POSITION_DETAIL_ID
                       , DOC2_DOC_POSITION_DETAIL_ID
                       , GCO_GOOD_ID
                       , STM_LOCATION_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , STM_STM_LOCATION_ID
                       , DIC_PDE_FREE_TABLE_1_ID
                       , DIC_PDE_FREE_TABLE_2_ID
                       , DIC_PDE_FREE_TABLE_3_ID
                       , FAL_SCHEDULE_STEP_ID
                       , DOC_RECORD_ID
                       , DOC_DOCUMENT_ID
                       , PAC_THIRD_ID
                       , DOC_GAUGE_ID
                       , DOC_GAUGE_RECEIPT_ID
                       , DOC_GAUGE_COPY_ID
                       , C_GAUGE_TYPE_POS
                       , DIC_DELAY_UPDATE_TYPE_ID
                       , PDE_BASIS_DELAY
                       , PDE_INTERMEDIATE_DELAY
                       , PDE_FINAL_DELAY
                       , PDE_SQM_ACCEPTED_DELAY
                       , PDE_BASIS_QUANTITY
                       , PDE_INTERMEDIATE_QUANTITY
                       , PDE_FINAL_QUANTITY
                       , PDE_BALANCE_QUANTITY
                       , PDE_BALANCE_QUANTITY_PARENT
                       , PDE_BASIS_QUANTITY_SU
                       , PDE_INTERMEDIATE_QUANTITY_SU
                       , PDE_FINAL_QUANTITY_SU
                       , PDE_MOVEMENT_QUANTITY
                       , PDE_MOVEMENT_VALUE
                       , PDE_CHARACTERIZATION_VALUE_1
                       , PDE_CHARACTERIZATION_VALUE_2
                       , PDE_CHARACTERIZATION_VALUE_3
                       , PDE_CHARACTERIZATION_VALUE_4
                       , PDE_CHARACTERIZATION_VALUE_5
                       , PDE_DELAY_UPDATE_TEXT
                       , PDE_DECIMAL_1
                       , PDE_DECIMAL_2
                       , PDE_DECIMAL_3
                       , PDE_TEXT_1
                       , PDE_TEXT_2
                       , PDE_TEXT_3
                       , PDE_DATE_1
                       , PDE_DATE_2
                       , PDE_DATE_3
                       , PDE_GENERATE_MOVEMENT
                       , DCD_QUANTITY
                       , DCD_QUANTITY_SU
                       , DCD_BALANCE_FLAG
                       , POS_CONVERT_FACTOR
                       , POS_CONVERT_FACTOR_CALC
                       , POS_GROSS_UNIT_VALUE
                       , POS_GROSS_UNIT_VALUE_INCL
                       , POS_UNIT_OF_MEASURE_ID
                       , POS_UTIL_COEFF
                       , FAL_NETWORK_LINK_ID
                       , DCD_VISIBLE
                       , C_PDE_CREATE_MODE
                       , A_DATECRE
                       , A_IDCRE
                       , PDE_ST_PT_REJECT
                       , PDE_ST_CPT_REJECT
                        )
              (select PDE.DOC_POSITION_DETAIL_ID
                    , ANewDocumentID
                    , 1 CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , SPO.STM_LOCATION_ID
                    , SPO.GCO_CHARACTERIZATION_ID
                    , SPO.GCO_GCO_CHARACTERIZATION_ID
                    , SPO.GCO2_GCO_CHARACTERIZATION_ID
                    , SPO.GCO3_GCO_CHARACTERIZATION_ID
                    , SPO.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , SPO.SPO_CHARACTERIZATION_VALUE_1
                    , SPO.SPO_CHARACTERIZATION_VALUE_2
                    , SPO.SPO_CHARACTERIZATION_VALUE_3
                    , SPO.SPO_CHARACTERIZATION_VALUE_4
                    , SPO.SPO_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , least(decode(nvl(PDT.PDT_STOCK_MANAGEMENT, 0), 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                          , tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                           ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(least(decode(nvl(PDT.PDT_STOCK_MANAGEMENT, 0), 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                 , tplDischargePdeCPT.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                  ) *
                                             POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , FLN.FAL_NETWORK_LINK_ID
                    , 0 as DCD_VISIBLE
                    , aCreateMode
                    , sysdate
                    , PCS.PC_I_LIB_SESSION.GetUserIni
                    , tplDischargePdeCPT.PDE_ST_PT_REJECT
                    , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and PDE.PDE_BALANCE_QUANTITY > 0
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
          else
            /* Si un gabarit position est lié. Les cpts sont indépendants du PT.
               Pour garantir cela, il faut inserer directement dans la table.
               En effet, la quantité du composant est toujours le min de la
               quantité attribuée et de la quantité solde. */
            insert into V_DOC_POS_DET_COPY_DISCHARGE
                        (DOC_POSITION_DETAIL_ID
                       , NEW_DOCUMENT_ID
                       , CRG_SELECT
                       , DOC_GAUGE_FLOW_ID
                       , DOC_POSITION_ID
                       , DOC_DOC_POSITION_ID
                       , DOC_DOC_POSITION_DETAIL_ID
                       , DOC2_DOC_POSITION_DETAIL_ID
                       , GCO_GOOD_ID
                       , STM_LOCATION_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , STM_STM_LOCATION_ID
                       , DIC_PDE_FREE_TABLE_1_ID
                       , DIC_PDE_FREE_TABLE_2_ID
                       , DIC_PDE_FREE_TABLE_3_ID
                       , FAL_SCHEDULE_STEP_ID
                       , DOC_RECORD_ID
                       , DOC_DOCUMENT_ID
                       , PAC_THIRD_ID
                       , DOC_GAUGE_ID
                       , DOC_GAUGE_RECEIPT_ID
                       , DOC_GAUGE_COPY_ID
                       , C_GAUGE_TYPE_POS
                       , DIC_DELAY_UPDATE_TYPE_ID
                       , PDE_BASIS_DELAY
                       , PDE_INTERMEDIATE_DELAY
                       , PDE_FINAL_DELAY
                       , PDE_SQM_ACCEPTED_DELAY
                       , PDE_BASIS_QUANTITY
                       , PDE_INTERMEDIATE_QUANTITY
                       , PDE_FINAL_QUANTITY
                       , PDE_BALANCE_QUANTITY
                       , PDE_BALANCE_QUANTITY_PARENT
                       , PDE_BASIS_QUANTITY_SU
                       , PDE_INTERMEDIATE_QUANTITY_SU
                       , PDE_FINAL_QUANTITY_SU
                       , PDE_MOVEMENT_QUANTITY
                       , PDE_MOVEMENT_VALUE
                       , PDE_CHARACTERIZATION_VALUE_1
                       , PDE_CHARACTERIZATION_VALUE_2
                       , PDE_CHARACTERIZATION_VALUE_3
                       , PDE_CHARACTERIZATION_VALUE_4
                       , PDE_CHARACTERIZATION_VALUE_5
                       , PDE_DELAY_UPDATE_TEXT
                       , PDE_DECIMAL_1
                       , PDE_DECIMAL_2
                       , PDE_DECIMAL_3
                       , PDE_TEXT_1
                       , PDE_TEXT_2
                       , PDE_TEXT_3
                       , PDE_DATE_1
                       , PDE_DATE_2
                       , PDE_DATE_3
                       , PDE_GENERATE_MOVEMENT
                       , DCD_QUANTITY
                       , DCD_QUANTITY_SU
                       , DCD_BALANCE_FLAG
                       , POS_CONVERT_FACTOR
                       , POS_CONVERT_FACTOR_CALC
                       , POS_GROSS_UNIT_VALUE
                       , POS_GROSS_UNIT_VALUE_INCL
                       , POS_UNIT_OF_MEASURE_ID
                       , POS_UTIL_COEFF
                       , FAL_NETWORK_LINK_ID
                       , DCD_VISIBLE
                       , C_PDE_CREATE_MODE
                       , A_DATECRE
                       , A_IDCRE
                       , PDE_ST_PT_REJECT
                       , PDE_ST_CPT_REJECT
                        )
              (select PDE.DOC_POSITION_DETAIL_ID
                    , ANewDocumentID
                    , tplDischargePdeCPT.CRG_SELECT
                    , PDE.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , SPO.STM_LOCATION_ID
                    , SPO.GCO_CHARACTERIZATION_ID
                    , SPO.GCO_GCO_CHARACTERIZATION_ID
                    , SPO.GCO2_GCO_CHARACTERIZATION_ID
                    , SPO.GCO3_GCO_CHARACTERIZATION_ID
                    , SPO.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , SPO.SPO_CHARACTERIZATION_VALUE_1
                    , SPO.SPO_CHARACTERIZATION_VALUE_2
                    , SPO.SPO_CHARACTERIZATION_VALUE_3
                    , SPO.SPO_CHARACTERIZATION_VALUE_4
                    , SPO.SPO_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , least(decode(nvl(PDT.PDT_STOCK_MANAGEMENT, 0), 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                          , PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                           ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(least(decode(nvl(PDT.PDT_STOCK_MANAGEMENT, 0), 1, nvl(FLN.FLN_QTY, 0), PDE.PDE_BALANCE_QUANTITY)
                                                 , PDE.PDE_BALANCE_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1)
                                                  ) *
                                             POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , 0 DCD_BALANCE_FLAG
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_CONVERT_FACTOR POS_CONVERT_FACTOR_CALC
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , FLN.FAL_NETWORK_LINK_ID
                    , 0 as DCD_VISIBLE
                    , aCreateMode
                    , sysdate
                    , PCS.PC_I_LIB_SESSION.GetUserIni
                    , tplDischargePdeCPT.PDE_ST_PT_REJECT
                    , tplDischargePdeCPT.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , FAL_NETWORK_LINK FLN
                    , FAL_NETWORK_NEED FAN
                    , STM_STOCK_POSITION SPO
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                where PDE.DOC_POSITION_DETAIL_ID = tplDischargePdeCPT.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and PDE.PDE_BALANCE_QUANTITY > 0
                  and FAN.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                  and FLN.FAL_NETWORK_NEED_ID(+) = FAN.FAL_NETWORK_NEED_ID
                  and FLN.STM_STOCK_POSITION_ID(+) is not null
                  and FLN.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
                  and PDT.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                  and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID);
          end if;
        end loop;
      end if;
    end if;

    close crDischargePde;
  end InsertDischargeDetailAttrib;

  /**
  * procedure InsertDischargeDetailBarcode
  * Description
  *     Insère dans la table DOC_POS_DET_COPY_DISCHARGE un détail de position de la table des propositions
  * @version 2004
  * @created NGV
  */
  procedure InsertDischargeDetailBarcode(
    aNewDocumentID   in number
  , aPeriodicDischID in number
  , aGaugeID         in number
  , aThirdID         in number
  , aThirdAciID      in number
  , aThirdDeliveryID in number
  , aCreateMode      in varchar2
  )
  is
    cursor crDischargePde
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , DDI.DOC_GAUGE_FLOW_ID
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , DDI.GCO_GOOD_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.STM_LOCATION_ID
                        else PDE.STM_LOCATION_ID
                      end STM_LOCATION_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.GCO_CHARACTERIZATION_ID
                        else PDE.GCO_CHARACTERIZATION_ID
                      end GCO_CHARACTERIZATION_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.GCO_GCO_CHARACTERIZATION_ID
                        else PDE.GCO_GCO_CHARACTERIZATION_ID
                      end GCO_GCO_CHARACTERIZATION_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.GCO2_GCO_CHARACTERIZATION_ID
                        else PDE.GCO2_GCO_CHARACTERIZATION_ID
                      end GCO2_GCO_CHARACTERIZATION_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.GCO3_GCO_CHARACTERIZATION_ID
                        else PDE.GCO3_GCO_CHARACTERIZATION_ID
                      end GCO3_GCO_CHARACTERIZATION_ID
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.GCO4_GCO_CHARACTERIZATION_ID
                        else PDE.GCO4_GCO_CHARACTERIZATION_ID
                      end GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.DBA_CHARACTERIZATION_VALUE_1
                        else PDE.PDE_CHARACTERIZATION_VALUE_1
                      end PDE_CHARACTERIZATION_VALUE_1
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.DBA_CHARACTERIZATION_VALUE_2
                        else PDE.PDE_CHARACTERIZATION_VALUE_2
                      end PDE_CHARACTERIZATION_VALUE_2
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.DBA_CHARACTERIZATION_VALUE_3
                        else PDE.PDE_CHARACTERIZATION_VALUE_3
                      end PDE_CHARACTERIZATION_VALUE_3
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.DBA_CHARACTERIZATION_VALUE_4
                        else PDE.PDE_CHARACTERIZATION_VALUE_4
                      end PDE_CHARACTERIZATION_VALUE_4
                    , case
                        when DBC.DOC_BARCODE_ID is not null then DBC.DBA_CHARACTERIZATION_VALUE_5
                        else PDE.PDE_CHARACTERIZATION_VALUE_5
                      end PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , DDI.DDI_DISCHARGE_QUANTITY DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(DDI.DDI_DISCHARGE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 1)
                                                                                                                                                DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aGaugeID, aThirdID) as DCD_BALANCE_FLAG
                    , 0 as DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , decode(POS.C_GAUGE_TYPE_POS, '1', 0, '2', 0, '3', 0, 1) DCD_DEPLOYED_COMPONENTS
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_PERIODIC_DISCHARGE DDI
                    , DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_GAUGE GAU
                    , DOC_BARCODE DBC
                where DDI.DOC_PERIODIC_DISCHARGE_ID = aPeriodicDischID
                  and DDI.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                  and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and DDI.DOC_BARCODE_ID = DBC.DOC_BARCODE_ID(+)
                  and DDI.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);

    tplDischargePde              crDischargePde%rowtype;

    cursor crDischargePdeCPT(cPTPositionID in number)
    is
      select distinct PDE.DOC_POSITION_DETAIL_ID
                    , 1 CRG_SELECT
                    , PDE.DOC_POSITION_ID
                    , POS.DOC_DOC_POSITION_ID
                    , PDE.DOC_DOC_POSITION_DETAIL_ID
                    , PDE.DOC2_DOC_POSITION_DETAIL_ID
                    , POS.GCO_GOOD_ID
                    , POS.POS_NUMBER
                    , PDE.STM_LOCATION_ID
                    , PDE.GCO_CHARACTERIZATION_ID
                    , PDE.GCO_GCO_CHARACTERIZATION_ID
                    , PDE.GCO2_GCO_CHARACTERIZATION_ID
                    , PDE.GCO3_GCO_CHARACTERIZATION_ID
                    , PDE.GCO4_GCO_CHARACTERIZATION_ID
                    , PDE.STM_STM_LOCATION_ID
                    , PDE.DIC_PDE_FREE_TABLE_1_ID
                    , PDE.DIC_PDE_FREE_TABLE_2_ID
                    , PDE.DIC_PDE_FREE_TABLE_3_ID
                    , PDE.FAL_SCHEDULE_STEP_ID
                    , PDE.DOC_RECORD_ID
                    , PDE.DOC_DOCUMENT_ID
                    , PDE.PAC_THIRD_ID
                    , PDE.DOC_GAUGE_ID
                    , 0 DOC_GAUGE_RECEIPT_ID
                    , null DOC_GAUGE_COPY_ID
                    , POS.C_GAUGE_TYPE_POS
                    , PDE.DIC_DELAY_UPDATE_TYPE_ID
                    , PDE.PDE_BASIS_DELAY
                    , PDE.PDE_INTERMEDIATE_DELAY
                    , PDE.PDE_FINAL_DELAY
                    , PDE.PDE_SQM_ACCEPTED_DELAY
                    , PDE.PDE_BASIS_QUANTITY
                    , PDE.PDE_INTERMEDIATE_QUANTITY
                    , PDE.PDE_FINAL_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY
                    , PDE.PDE_BALANCE_QUANTITY_PARENT
                    , PDE.PDE_BASIS_QUANTITY_SU
                    , PDE.PDE_INTERMEDIATE_QUANTITY_SU
                    , PDE.PDE_FINAL_QUANTITY_SU
                    , PDE.PDE_MOVEMENT_QUANTITY
                    , PDE.PDE_MOVEMENT_VALUE
                    , PDE.PDE_CHARACTERIZATION_VALUE_1
                    , PDE.PDE_CHARACTERIZATION_VALUE_2
                    , PDE.PDE_CHARACTERIZATION_VALUE_3
                    , PDE.PDE_CHARACTERIZATION_VALUE_4
                    , PDE.PDE_CHARACTERIZATION_VALUE_5
                    , PDE.PDE_DELAY_UPDATE_TEXT
                    , PDE.PDE_DECIMAL_1
                    , PDE.PDE_DECIMAL_2
                    , PDE.PDE_DECIMAL_3
                    , PDE.PDE_TEXT_1
                    , PDE.PDE_TEXT_2
                    , PDE.PDE_TEXT_3
                    , PDE.PDE_DATE_1
                    , PDE.PDE_DATE_2
                    , PDE.PDE_DATE_3
                    , 0 PDE_GENERATE_MOVEMENT
                    , (DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1) ) DCD_QUANTITY
                    , ACS_FUNCTION.RoundNear(DCD.DCD_QUANTITY * nvl(POS.POS_UTIL_COEFF, 1) * POS.POS_CONVERT_FACTOR
                                           , 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
                                           , 1
                                            ) DCD_QUANTITY_SU
                    , DOC_COPY_DISCHARGE.GetBalanceParentFlag(POS.DOC_POSITION_ID, aGaugeID, aThirdID) as DCD_BALANCE_FLAG
                    , 0 as DCD_VISIBLE
                    , POS.POS_CONVERT_FACTOR
                    , POS.POS_GROSS_UNIT_VALUE
                    , POS.POS_GROSS_UNIT_VALUE_INCL
                    , POS.DIC_UNIT_OF_MEASURE_ID
                    , POS.POS_UTIL_COEFF
                    , sysdate NEW_A_DATECRE
                    , PCS.PC_I_LIB_SESSION.GetUserIni NEW_A_IDCRE
                    , PDE.PDE_ST_PT_REJECT
                    , PDE.PDE_ST_CPT_REJECT
                 from DOC_POSITION_DETAIL PDE
                    , DOC_POSITION POS
                    , DOC_DOCUMENT DMT
                    , PAC_CUSTOM_PARTNER CUS
                    , GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , DOC_POS_DET_COPY_DISCHARGE DCD
                    , DOC_GAUGE GAU
                where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                  and POS.DOC_DOC_POSITION_ID = cPTPositionID
                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
                  and DCD.DOC_POSITION_ID = POS.DOC_DOC_POSITION_ID
                  and DCD.NEW_DOCUMENT_ID = aNewDocumentID
             order by POS.POS_NUMBER
                    , PDE.PDE_BASIS_DELAY
                    , PDE.DOC_POSITION_DETAIL_ID;

    tplDischargePdeCPT           crDischargePdeCPT%rowtype;
    --
    vInsertDcd                   V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vInsertDcdCpt                V_DOC_POS_DET_COPY_DISCHARGE%rowtype;
    vNewDcdID                    DOC_POS_DET_COPY_DISCHARGE.DOC_POS_DET_COPY_DISCHARGE_ID%type;
    --
    dblQuantityCPT               DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblQuantityCPT_SU            DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
    dblGreatestSumQuantityCPT    DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY%type;
    dblGreatestSumQuantityCPT_SU DOC_POS_DET_COPY_DISCHARGE.DCD_QUANTITY_SU%type;
  begin
    /* Détail de position à décharger */
    open crDischargePde;

    fetch crDischargePde
     into tplDischargePde;

    /* insertion dans la table de décharge du détail concerné */
    if crDischargePde%found then
      select init_id_seq.nextval
        into vNewDcdID
        from dual;

      vInsertDcd.DOC_POS_DET_COPY_DISCHARGE_ID  := vNewDcdID;
      vInsertDcd.DOC_POSITION_DETAIL_ID         := tplDischargePde.DOC_POSITION_DETAIL_ID;
      vInsertDcd.NEW_DOCUMENT_ID                := aNewDocumentID;
      vInsertDcd.CRG_SELECT                     := tplDischargePde.CRG_SELECT;
      vInsertDcd.DOC_GAUGE_FLOW_ID              := tplDischargePde.DOC_GAUGE_FLOW_ID;
      vInsertDcd.DOC_POSITION_ID                := tplDischargePde.DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_ID            := tplDischargePde.DOC_DOC_POSITION_ID;
      vInsertDcd.DOC_DOC_POSITION_DETAIL_ID     := tplDischargePde.DOC_DOC_POSITION_DETAIL_ID;
      vInsertDcd.DOC2_DOC_POSITION_DETAIL_ID    := tplDischargePde.DOC2_DOC_POSITION_DETAIL_ID;
      vInsertDcd.GCO_GOOD_ID                    := tplDischargePde.GCO_GOOD_ID;
      vInsertDcd.STM_LOCATION_ID                := tplDischargePde.STM_LOCATION_ID;
      vInsertDcd.GCO_CHARACTERIZATION_ID        := tplDischargePde.GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO_GCO_CHARACTERIZATION_ID    := tplDischargePde.GCO_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO2_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO2_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO3_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO3_GCO_CHARACTERIZATION_ID;
      vInsertDcd.GCO4_GCO_CHARACTERIZATION_ID   := tplDischargePde.GCO4_GCO_CHARACTERIZATION_ID;
      vInsertDcd.STM_STM_LOCATION_ID            := tplDischargePde.STM_STM_LOCATION_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_1_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_1_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_2_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_2_ID;
      vInsertDcd.DIC_PDE_FREE_TABLE_3_ID        := tplDischargePde.DIC_PDE_FREE_TABLE_3_ID;
      vInsertDcd.FAL_SCHEDULE_STEP_ID           := tplDischargePde.FAL_SCHEDULE_STEP_ID;
      vInsertDcd.DOC_RECORD_ID                  := tplDischargePde.DOC_RECORD_ID;
      vInsertDcd.DOC_DOCUMENT_ID                := tplDischargePde.DOC_DOCUMENT_ID;
      vInsertDcd.PAC_THIRD_ID                   := tplDischargePde.PAC_THIRD_ID;
      vInsertDcd.DOC_GAUGE_ID                   := tplDischargePde.DOC_GAUGE_ID;
      vInsertDcd.DOC_GAUGE_RECEIPT_ID           := tplDischargePde.DOC_GAUGE_RECEIPT_ID;
      vInsertDcd.DOC_GAUGE_COPY_ID              := tplDischargePde.DOC_GAUGE_COPY_ID;
      vInsertDcd.C_GAUGE_TYPE_POS               := tplDischargePde.C_GAUGE_TYPE_POS;
      vInsertDcd.DIC_DELAY_UPDATE_TYPE_ID       := tplDischargePde.DIC_DELAY_UPDATE_TYPE_ID;
      vInsertDcd.PDE_BASIS_DELAY                := tplDischargePde.PDE_BASIS_DELAY;
      vInsertDcd.PDE_INTERMEDIATE_DELAY         := tplDischargePde.PDE_INTERMEDIATE_DELAY;
      vInsertDcd.PDE_FINAL_DELAY                := tplDischargePde.PDE_FINAL_DELAY;
      vInsertDcd.PDE_SQM_ACCEPTED_DELAY         := tplDischargePde.PDE_SQM_ACCEPTED_DELAY;
      vInsertDcd.PDE_BASIS_QUANTITY             := tplDischargePde.PDE_BASIS_QUANTITY;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY      := tplDischargePde.PDE_INTERMEDIATE_QUANTITY;
      vInsertDcd.PDE_FINAL_QUANTITY             := tplDischargePde.PDE_FINAL_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY           := tplDischargePde.PDE_BALANCE_QUANTITY;
      vInsertDcd.PDE_BALANCE_QUANTITY_PARENT    := tplDischargePde.PDE_BALANCE_QUANTITY_PARENT;
      vInsertDcd.PDE_BASIS_QUANTITY_SU          := tplDischargePde.PDE_BASIS_QUANTITY_SU;
      vInsertDcd.PDE_INTERMEDIATE_QUANTITY_SU   := tplDischargePde.PDE_INTERMEDIATE_QUANTITY_SU;
      vInsertDcd.PDE_FINAL_QUANTITY_SU          := tplDischargePde.PDE_FINAL_QUANTITY_SU;
      vInsertDcd.PDE_MOVEMENT_QUANTITY          := tplDischargePde.PDE_MOVEMENT_QUANTITY;
      vInsertDcd.PDE_MOVEMENT_VALUE             := tplDischargePde.PDE_MOVEMENT_VALUE;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_1   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_1;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_2   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_2;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_3   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_3;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_4   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_4;
      vInsertDcd.PDE_CHARACTERIZATION_VALUE_5   := tplDischargePde.PDE_CHARACTERIZATION_VALUE_5;
      vInsertDcd.PDE_DELAY_UPDATE_TEXT          := tplDischargePde.PDE_DELAY_UPDATE_TEXT;
      vInsertDcd.PDE_DECIMAL_1                  := tplDischargePde.PDE_DECIMAL_1;
      vInsertDcd.PDE_DECIMAL_2                  := tplDischargePde.PDE_DECIMAL_2;
      vInsertDcd.PDE_DECIMAL_3                  := tplDischargePde.PDE_DECIMAL_3;
      vInsertDcd.PDE_TEXT_1                     := tplDischargePde.PDE_TEXT_1;
      vInsertDcd.PDE_TEXT_2                     := tplDischargePde.PDE_TEXT_2;
      vInsertDcd.PDE_TEXT_3                     := tplDischargePde.PDE_TEXT_3;
      vInsertDcd.PDE_DATE_1                     := tplDischargePde.PDE_DATE_1;
      vInsertDcd.PDE_DATE_2                     := tplDischargePde.PDE_DATE_2;
      vInsertDcd.PDE_DATE_3                     := tplDischargePde.PDE_DATE_3;
      vInsertDcd.PDE_GENERATE_MOVEMENT          := tplDischargePde.PDE_GENERATE_MOVEMENT;
      vInsertDcd.DCD_QUANTITY                   := tplDischargePde.DCD_QUANTITY;
      vInsertDcd.DCD_QUANTITY_SU                := tplDischargePde.DCD_QUANTITY_SU;
      vInsertDcd.DCD_BALANCE_FLAG               := tplDischargePde.DCD_BALANCE_FLAG;
      vInsertDcd.POS_CONVERT_FACTOR             := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_CONVERT_FACTOR_CALC        := tplDischargePde.POS_CONVERT_FACTOR;
      vInsertDcd.POS_GROSS_UNIT_VALUE           := tplDischargePde.POS_GROSS_UNIT_VALUE;
      vInsertDcd.POS_GROSS_UNIT_VALUE_INCL      := tplDischargePde.POS_GROSS_UNIT_VALUE_INCL;
      vInsertDcd.POS_UNIT_OF_MEASURE_ID         := tplDischargePde.DIC_UNIT_OF_MEASURE_ID;
      vInsertDcd.DCD_DEPLOYED_COMPONENTS        := tplDischargePde.DCD_DEPLOYED_COMPONENTS;
      vInsertDcd.DCD_VISIBLE                    := tplDischargePde.DCD_VISIBLE;
      vInsertDcd.C_PDE_CREATE_MODE              := aCreateMode;
      vInsertDcd.A_DATECRE                      := tplDischargePde.NEW_A_DATECRE;
      vInsertDcd.A_IDCRE                        := tplDischargePde.NEW_A_IDCRE;
      vInsertDcd.PDE_ST_PT_REJECT               := tplDischargePde.PDE_ST_PT_REJECT;
      vInsertDcd.PDE_ST_CPT_REJECT              := tplDischargePde.PDE_ST_CPT_REJECT;

      insert into V_DOC_POS_DET_COPY_DISCHARGE
           values vInsertDcd;

      /* Traitment des pos cpt si il s'agit d0un posiiton kit ou assemblage */
      if tplDischargePde.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
        dblGreatestSumQuantityCPT     := 0;
        dblGreatestSumQuantityCPT_SU  := 0;

        for tplDischargePdeCPT in crDischargePdeCPT(tplDischargePde.DOC_POSITION_ID) loop
          dblQuantityCPT                              := tplDischargePdeCPT.DCD_QUANTITY;
          dblQuantityCPT_SU                           := tplDischargePdeCPT.DCD_QUANTITY_SU;

          /* Stock la plus grande quantité des composants après application du
             coefficient d'utilisation */
          if (nvl(tplDischargePdeCPT.POS_UTIL_COEFF, 0) = 0) then
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, 0);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, 0);
          else
            dblGreatestSumQuantityCPT     := greatest(dblGreatestSumQuantityCPT, dblQuantityCPT / tplDischargePdeCPT.POS_UTIL_COEFF);
            dblGreatestSumQuantityCPT_SU  := greatest(dblGreatestSumQuantityCPT_SU, dblQuantityCPT_SU / tplDischargePdeCPT.POS_UTIL_COEFF);
          end if;

          vInsertDcdCpt                               := null;
          vInsertDcdCpt.DOC_POSITION_DETAIL_ID        := tplDischargePdeCPT.DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.NEW_DOCUMENT_ID               := aNewDocumentID;
          vInsertDcdCpt.CRG_SELECT                    := tplDischargePdeCPT.CRG_SELECT;
          vInsertDcdCpt.DOC_GAUGE_FLOW_ID             := tplDischargePde.DOC_GAUGE_FLOW_ID;   -- Flux de la position PT
          vInsertDcdCpt.DOC_POSITION_ID               := tplDischargePdeCPT.DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_ID           := tplDischargePdeCPT.DOC_DOC_POSITION_ID;
          vInsertDcdCpt.DOC_DOC_POSITION_DETAIL_ID    := tplDischargePdeCPT.DOC_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.DOC2_DOC_POSITION_DETAIL_ID   := tplDischargePdeCPT.DOC2_DOC_POSITION_DETAIL_ID;
          vInsertDcdCpt.GCO_GOOD_ID                   := tplDischargePdeCPT.GCO_GOOD_ID;
          vInsertDcdCpt.STM_LOCATION_ID               := tplDischargePdeCPT.STM_LOCATION_ID;
          vInsertDcdCpt.GCO_CHARACTERIZATION_ID       := tplDischargePdeCPT.GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO_GCO_CHARACTERIZATION_ID   := tplDischargePdeCPT.GCO_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO2_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO2_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO3_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO3_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.GCO4_GCO_CHARACTERIZATION_ID  := tplDischargePdeCPT.GCO4_GCO_CHARACTERIZATION_ID;
          vInsertDcdCpt.STM_STM_LOCATION_ID           := tplDischargePdeCPT.STM_STM_LOCATION_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_1_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_1_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_2_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_2_ID;
          vInsertDcdCpt.DIC_PDE_FREE_TABLE_3_ID       := tplDischargePdeCPT.DIC_PDE_FREE_TABLE_3_ID;
          vInsertDcdCpt.FAL_SCHEDULE_STEP_ID          := tplDischargePdeCPT.FAL_SCHEDULE_STEP_ID;
          vInsertDcdCpt.DOC_RECORD_ID                 := tplDischargePdeCPT.DOC_RECORD_ID;
          vInsertDcdCpt.DOC_DOCUMENT_ID               := tplDischargePdeCPT.DOC_DOCUMENT_ID;
          vInsertDcdCpt.PAC_THIRD_ID                  := tplDischargePdeCPT.PAC_THIRD_ID;
          vInsertDcdCpt.DOC_GAUGE_ID                  := tplDischargePdeCPT.DOC_GAUGE_ID;
          vInsertDcdCpt.DOC_GAUGE_RECEIPT_ID          := tplDischargePdeCPT.DOC_GAUGE_RECEIPT_ID;
          vInsertDcdCpt.DOC_GAUGE_COPY_ID             := tplDischargePdeCPT.DOC_GAUGE_COPY_ID;
          vInsertDcdCpt.C_GAUGE_TYPE_POS              := tplDischargePdeCPT.C_GAUGE_TYPE_POS;
          vInsertDcdCpt.DIC_DELAY_UPDATE_TYPE_ID      := tplDischargePdeCPT.DIC_DELAY_UPDATE_TYPE_ID;
          vInsertDcdCpt.PDE_BASIS_DELAY               := tplDischargePdeCPT.PDE_BASIS_DELAY;
          vInsertDcdCpt.PDE_INTERMEDIATE_DELAY        := tplDischargePdeCPT.PDE_INTERMEDIATE_DELAY;
          vInsertDcdCpt.PDE_FINAL_DELAY               := tplDischargePdeCPT.PDE_FINAL_DELAY;
          vInsertDcdCpt.PDE_SQM_ACCEPTED_DELAY        := tplDischargePdeCPT.PDE_SQM_ACCEPTED_DELAY;
          vInsertDcdCpt.PDE_BASIS_QUANTITY            := tplDischargePdeCPT.PDE_BASIS_QUANTITY;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY     := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY;
          vInsertDcdCpt.PDE_FINAL_QUANTITY            := tplDischargePdeCPT.PDE_FINAL_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY          := tplDischargePdeCPT.PDE_BALANCE_QUANTITY;
          vInsertDcdCpt.PDE_BALANCE_QUANTITY_PARENT   := tplDischargePdeCPT.PDE_BALANCE_QUANTITY_PARENT;
          vInsertDcdCpt.PDE_BASIS_QUANTITY_SU         := tplDischargePdeCPT.PDE_BASIS_QUANTITY_SU;
          vInsertDcdCpt.PDE_INTERMEDIATE_QUANTITY_SU  := tplDischargePdeCPT.PDE_INTERMEDIATE_QUANTITY_SU;
          vInsertDcdCpt.PDE_FINAL_QUANTITY_SU         := tplDischargePdeCPT.PDE_FINAL_QUANTITY_SU;
          vInsertDcdCpt.PDE_MOVEMENT_QUANTITY         := tplDischargePdeCPT.PDE_MOVEMENT_QUANTITY;
          vInsertDcdCpt.PDE_MOVEMENT_VALUE            := tplDischargePdeCPT.PDE_MOVEMENT_VALUE;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_1  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_1;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_2  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_2;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_3  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_3;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_4  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_4;
          vInsertDcdCpt.PDE_CHARACTERIZATION_VALUE_5  := tplDischargePdeCPT.PDE_CHARACTERIZATION_VALUE_5;
          vInsertDcdCpt.PDE_DELAY_UPDATE_TEXT         := tplDischargePdeCPT.PDE_DELAY_UPDATE_TEXT;
          vInsertDcdCpt.PDE_DECIMAL_1                 := tplDischargePdeCPT.PDE_DECIMAL_1;
          vInsertDcdCpt.PDE_DECIMAL_2                 := tplDischargePdeCPT.PDE_DECIMAL_2;
          vInsertDcdCpt.PDE_DECIMAL_3                 := tplDischargePdeCPT.PDE_DECIMAL_3;
          vInsertDcdCpt.PDE_TEXT_1                    := tplDischargePdeCPT.PDE_TEXT_1;
          vInsertDcdCpt.PDE_TEXT_2                    := tplDischargePdeCPT.PDE_TEXT_2;
          vInsertDcdCpt.PDE_TEXT_3                    := tplDischargePdeCPT.PDE_TEXT_3;
          vInsertDcdCpt.PDE_DATE_1                    := tplDischargePdeCPT.PDE_DATE_1;
          vInsertDcdCpt.PDE_DATE_2                    := tplDischargePdeCPT.PDE_DATE_2;
          vInsertDcdCpt.PDE_DATE_3                    := tplDischargePdeCPT.PDE_DATE_3;
          vInsertDcdCpt.PDE_GENERATE_MOVEMENT         := tplDischargePdeCPT.PDE_GENERATE_MOVEMENT;
          vInsertDcdCpt.DCD_QUANTITY                  := dblQuantityCPT;
          vInsertDcdCpt.DCD_QUANTITY_SU               := dblQuantityCPT_SU;
          vInsertDcdCpt.DCD_BALANCE_FLAG              := tplDischargePdeCPT.DCD_BALANCE_FLAG;
          vInsertDcdCpt.POS_CONVERT_FACTOR            := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_CONVERT_FACTOR_CALC       := tplDischargePdeCPT.POS_CONVERT_FACTOR;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE          := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE;
          vInsertDcdCpt.POS_GROSS_UNIT_VALUE_INCL     := tplDischargePdeCPT.POS_GROSS_UNIT_VALUE_INCL;
          vInsertDcdCpt.POS_UNIT_OF_MEASURE_ID        := tplDischargePdeCPT.DIC_UNIT_OF_MEASURE_ID;
          vInsertDcdCpt.POS_UTIL_COEFF                := tplDischargePdeCPT.POS_UTIL_COEFF;
          vInsertDcdCpt.DCD_VISIBLE                   := tplDischargePdeCPT.DCD_VISIBLE;
          vInsertDcdCpt.C_PDE_CREATE_MODE             := aCreateMode;
          vInsertDcdCpt.A_DATECRE                     := tplDischargePdeCPT.NEW_A_DATECRE;
          vInsertDcdCpt.A_IDCRE                       := tplDischargePdeCPT.NEW_A_IDCRE;
          vInsertDcdCpt.PDE_ST_PT_REJECT              := tplDischargePdeCPT.PDE_ST_PT_REJECT;
          vInsertDcdCpt.PDE_ST_CPT_REJECT             := tplDischargePdeCPT.PDE_ST_CPT_REJECT;

          insert into V_DOC_POS_DET_COPY_DISCHARGE
               values vInsertDcdCpt;
        end loop;

        /**
        * Redéfinit la quantité du produit terminé en fonction de la quantité
        * des composants.
        *
        *   Selon la règle suivante (facture des livraisons CPT) :
        *
        *   Si toutes les quantités des composants sont à 0 alors on initialise
        *   la quantité du produit terminé avec 0, sinon on conserve la quantité
        *   initiale (quantité solde).
        */
        if (dblGreatestSumQuantityCPT = 0) then
          update DOC_POS_DET_COPY_DISCHARGE
             set DCD_QUANTITY = 0
               , DCD_QUANTITY_SU = 0
           where DOC_POS_DET_COPY_DISCHARGE_ID = vNewDcdID;
        end if;

        close crDischargePdeCPT;
      end if;
    end if;

    close crDischargePde;
  end InsertDischargeDetailBarcode;

  /**
  * procedure GenerateNewDocument
  * Description
  *   Création d'un nouveau document qui accueillera les positions déchargées
  */
  procedure GenerateNewDocument(
    aNewDocumentID out    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSrcDocumentID in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aCreateMode    in     varchar2
  , aGaugeID       in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocDate       in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , aDateValue     in     DOC_DOCUMENT.DMT_DATE_VALUE%type default null
  , aDocReference  in     varchar2
  , aProcessID     in     DOC_PERIODIC_DISCH_RESULT.DDR_PROCESS_ID%type
  )
  is
    vActiveSavepoint boolean default false;
  begin
    savepoint GenerateDocument;
    vActiveSavepoint  := true;

    begin
      -- Création du document cible
        -- Utiliser la réf. document user si elle a été initialisée
        -- Utiliser la date valeur user
      if    (aDocReference is not null)
         or (aDateValue is not null) then
        -- Effacer les données de la variable avant de passer la valeur de la réf. document
        DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO  := 0;

        if aDocReference is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_REFERENCE  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_REFERENCE      := aDocReference;
        end if;

        if aDateValue is not null then
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE      := aDateValue;
        end if;
      else
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO  := 1;
      end if;

      aNewDocumentID  := null;
      -- Décharge document
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => aNewDocumentID
                                           , aMode            => aCreateMode
                                           , aGaugeID         => aGaugeID
                                           , aDocDate         => aDocDate
                                           , aSrcDocumentID   => aSrcDocumentID
                                            );

      -- Ajoute le document créé dans la table du résultat de la décharge
      insert into DOC_PERIODIC_DISCH_RESULT
                  (DOC_PERIODIC_DISCH_RESULT_ID
                 , DOC_DOCUMENT_ID
                 , DDR_SELECTION
                 , DDR_PRINTED
                 , DDR_CONFIRMED
                 , DDR_SESSION_ID
                 , DDR_PROCESS_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , aNewDocumentID
                 , 1
                 , 0
                 , 0
                 , userenv('SESSIONID')
                 , aProcessID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      commit;
    exception
      when others then
        -- Annule la création du document en cas d'erreur incontrôlée
        if vActiveSavepoint then
          rollback to savepoint GenerateDocument;
          vActiveSavepoint  := false;
          aNewDocumentID    := null;
        end if;
    end;
  end GenerateNewDocument;

  /**
  * procedure DischargeNewDocument
  * Description
  *   Effectue la décharge des données (détails) figurent dans table
  *     DOC_POS_DET_COPY_DISCHARGE sur le nouveau document
  */
  procedure DischargeNewDocument(aNewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aPosTextSummary in number)
  is
    /* Liste des positions à décharger */
    cursor crDischarge
    is
      select   DCD.DOC_POSITION_ID
             , DCD.DOC_DOCUMENT_ID
             , DCD.DOC_GAUGE_FLOW_ID
             , DMT.DMT_NUMBER
             , DMT.DMT_DATE_DOCUMENT
          from DOC_POS_DET_COPY_DISCHARGE DCD
             , DOC_DOCUMENT DMT
             , DOC_POSITION POS
         where DCD.NEW_DOCUMENT_ID = aNewDocumentID
           and DCD.CRG_SELECT = 1
           and DCD.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = DCD.DOC_POSITION_ID
           and DCD.DOC_DOC_POSITION_ID is null
      group by DCD.DOC_POSITION_ID
             , DCD.DOC_DOCUMENT_ID
             , DCD.DOC_GAUGE_FLOW_ID
             , DMT.DMT_NUMBER
             , DMT.DMT_DATE_DOCUMENT
      order by min(DCD.DOC_POS_DET_COPY_DISCHARGE_ID);

    tplDischarge     crDischarge%rowtype;
    vInputData       varchar2(32000);
    vTgtPosID        DOC_POSITION.DOC_POSITION_ID%type;
    vDischInfoCode   varchar2(10);
    vSrcDocID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPosID           DOC_POSITION.DOC_POSITION_ID%type;
    vPosBodyText     DOC_POSITION.POS_BODY_TEXT%type;
    vActiveSavepoint boolean                             default false;
  begin
    open crDischarge;

    fetch crDischarge
     into tplDischarge;

    if crDischarge%found then
      -- décharge des positions
      while crDischarge%found loop
        -- Création de la position texte Recapitulative
        if     (aPosTextSummary = 1)
           and (nvl(vSrcDocID, -1) <> tplDischarge.DOC_DOCUMENT_ID) then
          savepoint GeneratePosText;
          vActiveSavepoint  := true;

          begin
            vSrcDocID     := tplDischarge.DOC_DOCUMENT_ID;
            vPosID        := null;
            vPosBodyText  := tplDischarge.DMT_NUMBER || ' - ' || to_char(tplDischarge.DMT_DATE_DOCUMENT, 'dd.mm.yyyy');
            DOC_POSITION_GENERATE.GeneratePosition
                                                (aPositionID       => vPosID
                                               , aDocumentID       => aNewDocumentID
                                               , aTypePos          => '4'
                                               , aPosCreateMode    => '100'   /* Création de position sans possibilté d'indiv (code inaccessible à l'utilisateur) */
                                               , aPosBodyText      => vPosBodyText
                                               , aGenerateDetail   => 1
                                                );
            commit;
          exception
            when others then
              -- Annule la création la création de la position texte en cas d'erreur incontrôlée
              if vActiveSavepoint then
                rollback to savepoint GeneratePosText;
                vActiveSavepoint  := false;
              end if;
          end;
        end if;

        savepoint DischargePos;
        vActiveSavepoint  := true;

        begin
          -- Màj la variable de package contenant le dernier n° de position utilisé pour ce document
          DOC_COPY_DISCHARGE.SETLASTDOCPOSNUMBER(aNewDocumentID);
          -- Décharge de la position
          DOC_COPY_DISCHARGE.DischargePosition(aSourcePositionId      => tplDischarge.DOC_POSITION_ID
                                             , aTargetDocumentId      => aNewDocumentID
                                             , aPdtSourcePositionId   => null
                                             , aPdtTargetPositionId   => null
                                             , aFlowId                => tplDischarge.DOC_GAUGE_FLOW_ID
                                             , aInputIdList           => vInputData
                                             , aTargetPositionId      => vTgtPosID
                                             , aDischargeInfoCode     => vDischInfoCode
                                              );
          commit;
        exception
          when others then
            -- Annule la création la création de la position texte en cas d'erreur incontrôlée
            if vActiveSavepoint then
              rollback to savepoint DischargePos;
              vActiveSavepoint  := false;
            end if;
        end;

        fetch crDischarge
         into tplDischarge;
      end loop;

      begin
        -- Effacement des données de la table de décharge pour le document courant
        delete from DOC_POS_DET_COPY_DISCHARGE
              where NEW_DOCUMENT_ID = aNewDocumentID;

        commit;
      exception
        when others then
          null;
      end;

      begin
        -- Màj les derniers élements du document (statut, montants, etc.)
        DOC_FINALIZE.FinalizeDocument(aNewDocumentID, 1, 1, 1);
        commit;
      exception
        when others then
          null;
      end;
    end if;

    close crDischarge;
  end DischargeNewDocument;

  /**
  * procedure GenerateDischarge
  * Description
  *     Méthode globale pour effectuer la décharge des données envoyées dans la table DOC_POS_DET_COPY_DISCHARGE
  */
  procedure GenerateDischarge(
    aMode           in     varchar2
  , aCreateMode     in     varchar2
  , aGaugeID        in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocDate        in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , aDateValue      in     DOC_DOCUMENT.DMT_DATE_VALUE%type default null
  , aDocReference   in     varchar2
  , aSQLCommand     in     clob
  , aConfirm        in     integer
  , aPosTextSummary in     integer
  , aOneDocToOne    in     integer
  , aOracleJob      in     integer
  , aAttrib         in     integer
  , aProcessID      out    DOC_PERIODIC_DISCH_RESULT.DDR_PROCESS_ID%type
  )
  is
    -- Liste des détails à décharger qui figurent dans la table des propositions
    cursor crDetailList
    is
      select   DDI.DOC_DOCUMENT_ID
             , DDI.DOC_POSITION_DETAIL_ID
             , DDI.DDI_REGROUP_01
             , DDI.DDI_REGROUP_02
             , DDI.DDI_REGROUP_03
             , DDI.DDI_REGROUP_04
             , DDI.DDI_REGROUP_05
             , DDI.DDI_REGROUP_06
             , DDI.DDI_REGROUP_07
             , DDI.DDI_REGROUP_08
             , DDI.DDI_REGROUP_09
             , DDI.DDI_REGROUP_10
             , (case
                  when aOneDocToOne = 1 then 1
                  when(case upper(aMode)
                         when 'DELIVERY' then nvl(CUS_DELIVERY.C_DOC_CREATION, '00')
                         else nvl(CUS_ACI.C_DOC_CREATION_INVOICE, '00')
                       end) = '01' then 1
                  else 0
                end
               ) ONE_DOC_SRC_TO_ONE_TGT
             , DDI.PAC_CUSTOM_PARTNER_ID
             , DDI.PAC_CUS_PARTNER_ACI_ID
             , DDI.PAC_CUS_PARTNER_DELIVERY_ID
             , DDI.DOC_PERIODIC_DISCHARGE_ID
          from DOC_PERIODIC_DISCHARGE DDI
             , PAC_CUSTOM_PARTNER CUS
             , PAC_CUSTOM_PARTNER CUS_ACI
             , PAC_CUSTOM_PARTNER CUS_DELIVERY
         where DDI.DDI_SELECTION = 1
           and DDI.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and DDI.PAC_CUS_PARTNER_ACI_ID = CUS_ACI.PAC_CUSTOM_PARTNER_ID
           and DDI.PAC_CUS_PARTNER_DELIVERY_ID = CUS_DELIVERY.PAC_CUSTOM_PARTNER_ID
      order by DDI.DDI_ORDER_BY;

    vTplOldDetail crDetailList%rowtype;
    vTplNewDetail crDetailList%rowtype;
    vNewDocID     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;

    -- Méthode indiquant le changement de données dont les critères donnent lieu
    -- à la création d'un nouveau document
    function ChangeToNewDocument(aOld in crDetailList%rowtype, aNew in crDetailList%rowtype)
      return integer
    is
    begin
      if    (     (aNew.ONE_DOC_SRC_TO_ONE_TGT = 1)
             and (nvl(aOld.DOC_DOCUMENT_ID, -1) <> aNew.DOC_DOCUMENT_ID) )
         or (nvl(aOld.DDI_REGROUP_01, 'null') <> nvl(aNew.DDI_REGROUP_01, 'null') )
         or (nvl(aOld.DDI_REGROUP_02, 'null') <> nvl(aNew.DDI_REGROUP_02, 'null') )
         or (nvl(aOld.DDI_REGROUP_03, 'null') <> nvl(aNew.DDI_REGROUP_03, 'null') )
         or (nvl(aOld.DDI_REGROUP_04, 'null') <> nvl(aNew.DDI_REGROUP_04, 'null') )
         or (nvl(aOld.DDI_REGROUP_05, 'null') <> nvl(aNew.DDI_REGROUP_05, 'null') )
         or (nvl(aOld.DDI_REGROUP_06, 'null') <> nvl(aNew.DDI_REGROUP_06, 'null') )
         or (nvl(aOld.DDI_REGROUP_07, 'null') <> nvl(aNew.DDI_REGROUP_07, 'null') )
         or (nvl(aOld.DDI_REGROUP_08, 'null') <> nvl(aNew.DDI_REGROUP_08, 'null') )
         or (nvl(aOld.DDI_REGROUP_09, 'null') <> nvl(aNew.DDI_REGROUP_09, 'null') )
         or (nvl(aOld.DDI_REGROUP_10, 'null') <> nvl(aNew.DDI_REGROUP_10, 'null') ) then
        return 1;
      else
        return 0;
      end if;
    end;
  begin
    -- Recherche un ID pour le processus de décharge lancé
    select INIT_ID_SEQ.nextval
      into aProcessID
      from dual;

    -- commande pour la reprise des données de la cmd utilisateur (champs de regroupement, champ de tri)
    RegroupDischargeProcess(aOracleJob, aSQLCommand);

    -- Remplir la table temp de décharge avec les détails sélectionnés de la décharge périodique
    open crDetailList;

    fetch crDetailList
     into vTplNewDetail;

    if crDetailList%found then
      loop
        -- Flag indiquant la création d'un nouveau document
        if ChangeToNewDocument(vTplOldDetail, vTplNewDetail) = 1 then
          vTplOldDetail  := vTplNewDetail;
          -- Création d'un nouveau document
          GenerateNewDocument(aNewDocumentID   => vNewDocID
                            , aSrcDocumentID   => vTplNewDetail.DOC_DOCUMENT_ID
                            , aCreateMode      => aCreateMode
                            , aGaugeID         => aGaugeID
                            , aDocDate         => aDocDate
                            , aDateValue       => aDateValue
                            , aDocReference    => aDocReference
                            , aProcessID       => aProcessID
                             );
        end if;

        if (vNewDocID is not null) then
          begin
            -- Remplissage de la table temp de décharge
            if aMode = 'BARCODE' then
              InsertDischargeDetailBarcode(aNewDocumentID     => vNewDocID
                                         , aPeriodicDischID   => vTplNewDetail.DOC_PERIODIC_DISCHARGE_ID
                                         , aGaugeID           => aGaugeID
                                         , aThirdID           => vTplNewDetail.PAC_CUSTOM_PARTNER_ID
                                         , aThirdAciID        => vTplNewDetail.PAC_CUS_PARTNER_ACI_ID
                                         , aThirdDeliveryID   => vTplNewDetail.PAC_CUS_PARTNER_DELIVERY_ID
                                         , aCreateMode        => aCreateMode
                                          );
            elsif aAttrib = 1 then
              InsertDischargeDetailAttrib(aNewDocumentID     => vNewDocID
                                        , aPeriodicDischID   => vTplNewDetail.DOC_PERIODIC_DISCHARGE_ID
                                        , aGaugeID           => aGaugeID
                                        , aThirdID           => vTplNewDetail.PAC_CUSTOM_PARTNER_ID
                                        , aThirdAciID        => vTplNewDetail.PAC_CUS_PARTNER_ACI_ID
                                        , aThirdDeliveryID   => vTplNewDetail.PAC_CUS_PARTNER_DELIVERY_ID
                                        , aCreateMode        => aCreateMode
                                         );
            else
              InsertDischargeDetail(aNewDocumentID     => vNewDocID
                                  , aDetailID          => vTplNewDetail.DOC_POSITION_DETAIL_ID
                                  , aGaugeID           => aGaugeID
                                  , aThirdID           => vTplNewDetail.PAC_CUSTOM_PARTNER_ID
                                  , aThirdAciID        => vTplNewDetail.PAC_CUS_PARTNER_ACI_ID
                                  , aThirdDeliveryID   => vTplNewDetail.PAC_CUS_PARTNER_DELIVERY_ID
                                  , aCreateMode        => aCreateMode
                                   );
            end if;

            commit;
          exception
            when others then
              null;
          end;
        end if;

        -- Détail suivant
        fetch crDetailList
         into vTplNewDetail;

        if     (vNewDocID is not null)
           and (    (crDetailList%notfound)
                or (ChangeToNewDocument(vTplOldDetail, vTplNewDetail) = 1) ) then
          -- Décharger les positions qui viennent d'êtres insérées dans la table temp de décharge
          DischargeNewDocument(aNewDocumentID => vNewDocID, aPosTextSummary => aPosTextSummary);

          if aConfirm = 1 then
            ConfirmDocument(vNewDocID);
          end if;
        end if;

        exit when crDetailList%notfound;
      end loop;
    end if;

    close crDetailList;

    -- Màj du statut des barcodes traités
    if aMode = 'BARCODE' then
      UpdateBarcodeStatus;
    end if;

    begin
      -- Déprotéger les documents qui sont proposés pour la décharge
      ProtectPropDischDocuments(0);
    exception
      when others then
        raise_application_error(-20911
                              , PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant la déprotection des documents!') ||
                                co.cLineBreak ||
                                sqlerrm ||
                                co.cLineBreak ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                               );
    end;
  end GenerateDischarge;

  /**
  * procedure ProtectPropDischDocuments
  * Description
  *     Protéger/Déprotéger les documents qui sont dans la table des propositions de décharge
  */
  procedure ProtectPropDischDocuments(aProtect in number)
  is
  begin
    -- Effacer les données de la temp, car la protéction des documents l'utilise
    delete from COM_LIST_ID_TEMP;

    for tplDocList in (select distinct DOC_DOCUMENT_ID
                                  from DOC_PERIODIC_DISCHARGE
                              order by 1) loop
      begin
        DOC_DOCUMENT_FUNCTIONS.DocumentProtect_AutoTrans(aDocumentID   => tplDocList.DOC_DOCUMENT_ID
                                                       , aProtect      => aProtect
                                                       , aSessionID    => DBMS_SESSION.unique_session_id
                                                        );
      exception
        when others then
          null;
      end;
    end loop;
  end ProtectPropDischDocuments;

  /**
  *  procedure CreatePeriodicDischPrintJob
  *  Description
  *    Création du job d'impression sur la base des résultats de la décharge périodique figurant dans la table
  *      DOC_PERIODIC_DISCH_RESULT
  */
  procedure CreatePeriodicDischPrintJob(
    aPrintJobID      out    number
  , aJobName         in     varchar2
  , aGroupedPrint    in     integer
  , aDischargeJob    in     integer
  , aPrintSQL        in     clob
  , aPrintOptionList in     TPrintOptionList
  )
  is
    type TDocListType is ref cursor;   -- define weak REF CURSOR type

    crDocList        TDocListType;
    vSQLDocList      varchar2(32000);
    vInsertSQL       varchar2(32000);
    vBasisInsertSQL  varchar2(32000);
    vCounter         varchar2(4);
    vCpt             integer;
    vDOC_DOCUMENT_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vDMT_NUMBER      DOC_DOCUMENT.DMT_NUMBER%type;
    vSingleQuote     varchar2(10)                        default '''';
    vDoubleQuote     varchar2(10)                        default '''''';
  begin
    -- Nouvel Id pour le DOC_PRINT_JOB
    select INIT_ID_SEQ.nextval
      into aPrintJobID
      from dual;

    -- Création du job d'impression
    insert into DOC_PRINT_JOB
                (DOC_PRINT_JOB_ID
               , PJO_NAME
               , PJO_EXECUTED
               , PJO_GROUPED_PRINTING
               , PJO_UPDATE_PRINTING
               , A_DATECRE
               , A_IDCRE
                )
         values (aPrintJobID
               , aJobName
               , 0
               , aGroupedPrint
               , 1
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- Construction de la commande d'insertion des documents à imprimer
    vBasisInsertSQL  :=
      'insert into DOC_PRINT_JOB_DETAIL ' ||
      '  (DOC_PRINT_JOB_DETAIL_ID ' ||
      ' , DOC_PRINT_JOB_ID        ' ||
      ' , DOC_DOCUMENT_ID         ' ||
      ' , DMT_NUMBER              ' ||
      ' , PJD_GROUPED_PRINTING    ' ||
      ' , PJD_UPDATE_PRINTING     ' ||
      ' , PJD_EDIT_NAME0          ' ||
      ' , PJD_PRINTER_NAME0       ' ||
      ' , PJD_PRINTER_TRAY0       ' ||
      ' , PJD_COLLATE_COPIES0     ' ||
      ' , PJD_COPIES0             ' ||
      ' , PJD_EDIT_NAME1          ' ||
      ' , PJD_PRINTER_NAME1       ' ||
      ' , PJD_PRINTER_TRAY1       ' ||
      ' , PJD_COLLATE_COPIES1     ' ||
      ' , PJD_COPIES1             ' ||
      ' , PJD_EDIT_NAME2          ' ||
      ' , PJD_PRINTER_NAME2       ' ||
      ' , PJD_PRINTER_TRAY2       ' ||
      ' , PJD_COLLATE_COPIES2     ' ||
      ' , PJD_COPIES2             ' ||
      ' , PJD_EDIT_NAME3          ' ||
      ' , PJD_PRINTER_NAME3       ' ||
      ' , PJD_PRINTER_TRAY3       ' ||
      ' , PJD_COLLATE_COPIES3     ' ||
      ' , PJD_COPIES3             ' ||
      ' , PJD_EDIT_NAME4          ' ||
      ' , PJD_PRINTER_NAME4       ' ||
      ' , PJD_PRINTER_TRAY4       ' ||
      ' , PJD_COLLATE_COPIES4     ' ||
      ' , PJD_COPIES4             ' ||
      ' , PJD_EDIT_NAME5          ' ||
      ' , PJD_PRINTER_NAME5       ' ||
      ' , PJD_PRINTER_TRAY5       ' ||
      ' , PJD_COLLATE_COPIES5     ' ||
      ' , PJD_COPIES5             ' ||
      ' , PJD_EDIT_NAME6          ' ||
      ' , PJD_PRINTER_NAME6       ' ||
      ' , PJD_PRINTER_TRAY6       ' ||
      ' , PJD_COLLATE_COPIES6     ' ||
      ' , PJD_COPIES6             ' ||
      ' , PJD_EDIT_NAME7          ' ||
      ' , PJD_PRINTER_NAME7       ' ||
      ' , PJD_PRINTER_TRAY7       ' ||
      ' , PJD_COLLATE_COPIES7     ' ||
      ' , PJD_COPIES7             ' ||
      ' , PJD_EDIT_NAME8          ' ||
      ' , PJD_PRINTER_NAME8       ' ||
      ' , PJD_PRINTER_TRAY8       ' ||
      ' , PJD_COLLATE_COPIES8     ' ||
      ' , PJD_COPIES8             ' ||
      ' , PJD_EDIT_NAME9          ' ||
      ' , PJD_PRINTER_NAME9       ' ||
      ' , PJD_PRINTER_TRAY9       ' ||
      ' , PJD_COLLATE_COPIES9     ' ||
      ' , PJD_COPIES9             ' ||
      ' , PJD_EDIT_NAME10         ' ||
      ' , PJD_PRINTER_NAME10      ' ||
      ' , PJD_PRINTER_TRAY10      ' ||
      ' , PJD_COLLATE_COPIES10    ' ||
      ' , PJD_COPIES10            ' ||
      ' , PJD_WORKSTATION         ' ||
      ' , A_DATECRE               ' ||
      ' , A_IDCRE                 ' ||
      ' )                         ' ||
      ' select INIT_ID_SEQ.nextval           ' ||
      '      , [DOC_PRINT_JOB_ID]            ' ||
      '      , [DOC_DOCUMENT_ID]             ' ||
      '      , :DMT_NUMBER                   ' ||
      '      , [PJD_GROUPED_PRINTING]        ' ||
      '      , 1 as PJD_UPDATE_PRINTING      ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_EDIT_NAME00], null))       ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_PRINTER_NAME00], null))    ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_PRINTER_TRAY00], null))    ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_COLLATE_COPIES00], null))  ' ||
      '      , decode([PJD_PRINT_00], 0, null, decode(SQL_00.CONDITION, 1, [PJD_COPIES00], null))          ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_EDIT_NAME01], null))       ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_PRINTER_NAME01], null))    ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_PRINTER_TRAY01], null))    ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_COLLATE_COPIES01], null))  ' ||
      '      , decode([PJD_PRINT_01], 0, null, decode(SQL_01.CONDITION, 1, [PJD_COPIES01], null))          ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_EDIT_NAME02], null))       ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_PRINTER_NAME02], null))    ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_PRINTER_TRAY02], null))    ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_COLLATE_COPIES02], null))  ' ||
      '      , decode([PJD_PRINT_02], 0, null, decode(SQL_02.CONDITION, 1, [PJD_COPIES02], null))          ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_EDIT_NAME03], null))       ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_PRINTER_NAME03], null))    ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_PRINTER_TRAY03], null))    ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_COLLATE_COPIES03], null))  ' ||
      '      , decode([PJD_PRINT_03], 0, null, decode(SQL_03.CONDITION, 1, [PJD_COPIES03], null))          ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_EDIT_NAME04], null))       ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_PRINTER_NAME04], null))    ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_PRINTER_TRAY04], null))    ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_COLLATE_COPIES04], null))  ' ||
      '      , decode([PJD_PRINT_04], 0, null, decode(SQL_04.CONDITION, 1, [PJD_COPIES04], null))          ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_EDIT_NAME05], null))       ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_PRINTER_NAME05], null))    ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_PRINTER_TRAY05], null))    ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_COLLATE_COPIES05], null))  ' ||
      '      , decode([PJD_PRINT_05], 0, null, decode(SQL_05.CONDITION, 1, [PJD_COPIES05], null))          ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_EDIT_NAME06], null))       ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_PRINTER_NAME06], null))    ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_PRINTER_TRAY06], null))    ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_COLLATE_COPIES06], null))  ' ||
      '      , decode([PJD_PRINT_06], 0, null, decode(SQL_06.CONDITION, 1, [PJD_COPIES06], null))          ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_EDIT_NAME07], null))       ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_PRINTER_NAME07], null))    ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_PRINTER_TRAY07], null))    ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_COLLATE_COPIES07], null))  ' ||
      '      , decode([PJD_PRINT_07], 0, null, decode(SQL_07.CONDITION, 1, [PJD_COPIES07], null))          ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_EDIT_NAME08], null))       ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_PRINTER_NAME08], null))    ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_PRINTER_TRAY08], null))    ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_COLLATE_COPIES08], null))  ' ||
      '      , decode([PJD_PRINT_08], 0, null, decode(SQL_08.CONDITION, 1, [PJD_COPIES08], null))          ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_EDIT_NAME09], null))       ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_PRINTER_NAME09], null))    ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_PRINTER_TRAY09], null))    ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_COLLATE_COPIES09], null))  ' ||
      '      , decode([PJD_PRINT_09], 0, null, decode(SQL_09.CONDITION, 1, [PJD_COPIES09], null))          ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_EDIT_NAME10], null))      ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_PRINTER_NAME10], null))   ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_PRINTER_TRAY10], null))   ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_COLLATE_COPIES10], null)) ' ||
      '      , decode([PJD_PRINT_10], 0, null, decode(SQL_10.CONDITION, 1, [PJD_COPIES10], null))         ' ||
      '      , 0                              ' ||
      '      , sysdate                        ' ||
      '      , PCS.PC_I_LIB_SESSION.GetUserIni ' ||
      '  from (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_00]) ) SQL_00 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_01]) ) SQL_01 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_02]) ) SQL_02 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_03]) ) SQL_03 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_04]) ) SQL_04 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_05]) ) SQL_05 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_06]) ) SQL_06 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_07]) ) SQL_07 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_08]) ) SQL_08 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_09]) ) SQL_09 ' ||
      '     , (select nvl(max(1), 0) CONDITION from dual where exists([SQL_COMMAND_10]) ) SQL_10 ';
    /* Remplacement des macros des paramètres par leur valeur respective */
    vBasisInsertSQL  := replace(vBasisInsertSQL, '[DOC_PRINT_JOB_ID]', to_char(aPrintJobID) );
    vBasisInsertSQL  := replace(vBasisInsertSQL, '[PJD_GROUPED_PRINTING]', to_char(aGroupedPrint) );

    /* Paramètres des rapports 0 à 10 */
    for vCpt in 0 .. 10 loop
      vCounter         := lpad(to_char(vCpt), 2, '0');
      vBasisInsertSQL  := replace(vBasisInsertSQL, '[PJD_PRINT_' || vCounter || ']', aPrintOptionList(vCpt).PRT_PRINT);
      vBasisInsertSQL  :=
        replace(vBasisInsertSQL
              , '[PJD_EDIT_NAME' || vCounter || ']'
              , vSingleQuote || replace(aPrintOptionList(vCpt).PRT_FORM_NAME, vSingleQuote, vDoubleQuote) || vSingleQuote
               );
      vBasisInsertSQL  :=
        replace(vBasisInsertSQL
              , '[PJD_PRINTER_NAME' || vCounter || ']'
              , vSingleQuote || replace(aPrintOptionList(vCpt).PRT_PRINTER_NAME, vSingleQuote, vDoubleQuote) || vSingleQuote
               );
      vBasisInsertSQL  :=
        replace(vBasisInsertSQL
              , '[PJD_PRINTER_TRAY' || vCounter || ']'
              , vSingleQuote || replace(aPrintOptionList(vCpt).PRT_PRINTER_TRAY, vSingleQuote, vDoubleQuote) || vSingleQuote
               );
      vBasisInsertSQL  := replace(vBasisInsertSQL, '[PJD_COLLATE_COPIES' || vCounter || ']', aPrintOptionList(vCpt).PRT_COLLATE);
      vBasisInsertSQL  := replace(vBasisInsertSQL, '[PJD_COPIES' || vCounter || ']', aPrintOptionList(vCpt).PRT_COPIES);
      vBasisInsertSQL  := replace(vBasisInsertSQL, '[SQL_COMMAND_' || vCounter || ']', nvl(upper(aPrintOptionList(vCpt).PRT_PRINT_SQL), 'select 1 from dual') );
    end loop;

    -- Liste des documents à imprimmer
    vSQLDocList      :=
      'select DMT.DMT_NUMBER       ' ||
      '     , DMT.DOC_DOCUMENT_ID  ' ||
      '  from DOC_DOCUMENT DMT     ' ||
      '     , ( ' ||
      aPrintSQL ||
      ' ) USER_PRINT_CMD ' ||
      ' where DMT.DOC_DOCUMENT_ID = USER_PRINT_CMD.DOC_DOCUMENT_ID ';

    -- Si pas en job il faut imprimmer que les documents sélectionnés par l'utilisateur
    if aDischargeJob = 0 then
      vSQLDocList  := vSQLDocList || '  and USER_PRINT_CMD.DDR_SELECTION = 1 ';
    end if;

    /* Balayer la liste des documents créés et inserer dans la table de l'impression */
    open crDocList for vSQLDocList;

    loop
      fetch crDocList
       into vDMT_NUMBER
          , vDOC_DOCUMENT_ID;

      exit when crDocList%notfound;
      /* Remplacement du paramètre :DMT_NUMBER de la commande de utilisateur pour la condition d'impression */
      vInsertSQL  := replace(vBasisInsertSQL, ':DMT_NUMBER', vSingleQuote || replace(vDMT_NUMBER, vSingleQuote, vDoubleQuote) || vSingleQuote);
      /* Remplacement du paramètre [DOC_DOCUMENT_ID] */
      vInsertSQL  := replace(vInsertSQL, '[DOC_DOCUMENT_ID]', to_char(vDOC_DOCUMENT_ID) );

      execute immediate vInsertSQL;
    end loop;

    close crDocList;

    -- Effacer le job d'impression si pas de documents à imprimer
    declare
      intCountDocs integer;
    begin
      -- Nbr de documents à imprimer
      select count(DOC_PRINT_JOB_DETAIL_ID)
        into intCountDocs
        from DOC_PRINT_JOB_DETAIL
       where DOC_PRINT_JOB_ID = aPrintJobID;

      if intCountDocs = 0 then
        delete from DOC_PRINT_JOB
              where DOC_PRINT_JOB_ID = aPrintJobID;

        aPrintJobID  := null;
      end if;
    end;
  end CreatePeriodicDischPrintJob;

  procedure UpdateUserPrintOptionList(
    aPrt_00_Print       in integer
  , aPrt_00_FormName    in varchar2
  , aPrt_00_Copies      in integer
  , aPrt_00_Collate     in integer
  , aPrt_00_PrinterName in varchar2
  , aPrt_00_PrinterTray in varchar2
  , aPrt_00_PrintSQL    in varchar2
  , aPrt_01_Print       in integer
  , aPrt_01_FormName    in varchar2
  , aPrt_01_Copies      in integer
  , aPrt_01_Collate     in integer
  , aPrt_01_PrinterName in varchar2
  , aPrt_01_PrinterTray in varchar2
  , aPrt_01_PrintSQL    in varchar2
  , aPrt_02_Print       in integer
  , aPrt_02_FormName    in varchar2
  , aPrt_02_Copies      in integer
  , aPrt_02_Collate     in integer
  , aPrt_02_PrinterName in varchar2
  , aPrt_02_PrinterTray in varchar2
  , aPrt_02_PrintSQL    in varchar2
  , aPrt_03_Print       in integer
  , aPrt_03_FormName    in varchar2
  , aPrt_03_Copies      in integer
  , aPrt_03_Collate     in integer
  , aPrt_03_PrinterName in varchar2
  , aPrt_03_PrinterTray in varchar2
  , aPrt_03_PrintSQL    in varchar2
  , aPrt_04_Print       in integer
  , aPrt_04_FormName    in varchar2
  , aPrt_04_Copies      in integer
  , aPrt_04_Collate     in integer
  , aPrt_04_PrinterName in varchar2
  , aPrt_04_PrinterTray in varchar2
  , aPrt_04_PrintSQL    in varchar2
  , aPrt_05_Print       in integer
  , aPrt_05_FormName    in varchar2
  , aPrt_05_Copies      in integer
  , aPrt_05_Collate     in integer
  , aPrt_05_PrinterName in varchar2
  , aPrt_05_PrinterTray in varchar2
  , aPrt_05_PrintSQL    in varchar2
  , aPrt_06_Print       in integer
  , aPrt_06_FormName    in varchar2
  , aPrt_06_Copies      in integer
  , aPrt_06_Collate     in integer
  , aPrt_06_PrinterName in varchar2
  , aPrt_06_PrinterTray in varchar2
  , aPrt_06_PrintSQL    in varchar2
  , aPrt_07_Print       in integer
  , aPrt_07_FormName    in varchar2
  , aPrt_07_Copies      in integer
  , aPrt_07_Collate     in integer
  , aPrt_07_PrinterName in varchar2
  , aPrt_07_PrinterTray in varchar2
  , aPrt_07_PrintSQL    in varchar2
  , aPrt_08_Print       in integer
  , aPrt_08_FormName    in varchar2
  , aPrt_08_Copies      in integer
  , aPrt_08_Collate     in integer
  , aPrt_08_PrinterName in varchar2
  , aPrt_08_PrinterTray in varchar2
  , aPrt_08_PrintSQL    in varchar2
  , aPrt_09_Print       in integer
  , aPrt_09_FormName    in varchar2
  , aPrt_09_Copies      in integer
  , aPrt_09_Collate     in integer
  , aPrt_09_PrinterName in varchar2
  , aPrt_09_PrinterTray in varchar2
  , aPrt_09_PrintSQL    in varchar2
  , aPrt_10_Print       in integer
  , aPrt_10_FormName    in varchar2
  , aPrt_10_Copies      in integer
  , aPrt_10_Collate     in integer
  , aPrt_10_PrinterName in varchar2
  , aPrt_10_PrinterTray in varchar2
  , aPrt_10_PrintSQL    in varchar2
  )
  is
    vPrintOptionList TPrintOptionList;
  begin
    -- Effacer la variable globale de package
    userPrintOptionList                       := vPrintOptionList;
    -- Affection des paramètres à la variable globale de package
    userPrintOptionList(0).PRT_PRINT          := aPrt_00_Print;
    userPrintOptionList(0).PRT_FORM_NAME      := aPrt_00_FormName;
    userPrintOptionList(0).PRT_COPIES         := aPrt_00_Copies;
    userPrintOptionList(0).PRT_COLLATE        := aPrt_00_Collate;
    userPrintOptionList(0).PRT_PRINTER_NAME   := aPrt_00_PrinterName;
    userPrintOptionList(0).PRT_PRINTER_TRAY   := aPrt_00_PrinterTray;
    userPrintOptionList(0).PRT_PRINT_SQL      := aPrt_00_PrintSQL;
    userPrintOptionList(1).PRT_PRINT          := aPrt_01_Print;
    userPrintOptionList(1).PRT_FORM_NAME      := aPrt_01_FormName;
    userPrintOptionList(1).PRT_COPIES         := aPrt_01_Copies;
    userPrintOptionList(1).PRT_COLLATE        := aPrt_01_Collate;
    userPrintOptionList(1).PRT_PRINTER_NAME   := aPrt_01_PrinterName;
    userPrintOptionList(1).PRT_PRINTER_TRAY   := aPrt_01_PrinterTray;
    userPrintOptionList(1).PRT_PRINT_SQL      := aPrt_01_PrintSQL;
    userPrintOptionList(2).PRT_PRINT          := aPrt_02_Print;
    userPrintOptionList(2).PRT_FORM_NAME      := aPrt_02_FormName;
    userPrintOptionList(2).PRT_COPIES         := aPrt_02_Copies;
    userPrintOptionList(2).PRT_COLLATE        := aPrt_02_Collate;
    userPrintOptionList(2).PRT_PRINTER_NAME   := aPrt_02_PrinterName;
    userPrintOptionList(2).PRT_PRINTER_TRAY   := aPrt_02_PrinterTray;
    userPrintOptionList(2).PRT_PRINT_SQL      := aPrt_02_PrintSQL;
    userPrintOptionList(3).PRT_PRINT          := aPrt_03_Print;
    userPrintOptionList(3).PRT_FORM_NAME      := aPrt_03_FormName;
    userPrintOptionList(3).PRT_COPIES         := aPrt_03_Copies;
    userPrintOptionList(3).PRT_COLLATE        := aPrt_03_Collate;
    userPrintOptionList(3).PRT_PRINTER_NAME   := aPrt_03_PrinterName;
    userPrintOptionList(3).PRT_PRINTER_TRAY   := aPrt_03_PrinterTray;
    userPrintOptionList(3).PRT_PRINT_SQL      := aPrt_03_PrintSQL;
    userPrintOptionList(4).PRT_PRINT          := aPrt_04_Print;
    userPrintOptionList(4).PRT_FORM_NAME      := aPrt_04_FormName;
    userPrintOptionList(4).PRT_COPIES         := aPrt_04_Copies;
    userPrintOptionList(4).PRT_COLLATE        := aPrt_04_Collate;
    userPrintOptionList(4).PRT_PRINTER_NAME   := aPrt_04_PrinterName;
    userPrintOptionList(4).PRT_PRINTER_TRAY   := aPrt_04_PrinterTray;
    userPrintOptionList(4).PRT_PRINT_SQL      := aPrt_04_PrintSQL;
    userPrintOptionList(5).PRT_PRINT          := aPrt_05_Print;
    userPrintOptionList(5).PRT_FORM_NAME      := aPrt_05_FormName;
    userPrintOptionList(5).PRT_COPIES         := aPrt_05_Copies;
    userPrintOptionList(5).PRT_COLLATE        := aPrt_05_Collate;
    userPrintOptionList(5).PRT_PRINTER_NAME   := aPrt_05_PrinterName;
    userPrintOptionList(5).PRT_PRINTER_TRAY   := aPrt_05_PrinterTray;
    userPrintOptionList(5).PRT_PRINT_SQL      := aPrt_05_PrintSQL;
    userPrintOptionList(6).PRT_PRINT          := aPrt_06_Print;
    userPrintOptionList(6).PRT_FORM_NAME      := aPrt_06_FormName;
    userPrintOptionList(6).PRT_COPIES         := aPrt_06_Copies;
    userPrintOptionList(6).PRT_COLLATE        := aPrt_06_Collate;
    userPrintOptionList(6).PRT_PRINTER_NAME   := aPrt_06_PrinterName;
    userPrintOptionList(6).PRT_PRINTER_TRAY   := aPrt_06_PrinterTray;
    userPrintOptionList(6).PRT_PRINT_SQL      := aPrt_06_PrintSQL;
    userPrintOptionList(7).PRT_PRINT          := aPrt_07_Print;
    userPrintOptionList(7).PRT_FORM_NAME      := aPrt_07_FormName;
    userPrintOptionList(7).PRT_COPIES         := aPrt_07_Copies;
    userPrintOptionList(7).PRT_COLLATE        := aPrt_07_Collate;
    userPrintOptionList(7).PRT_PRINTER_NAME   := aPrt_07_PrinterName;
    userPrintOptionList(7).PRT_PRINTER_TRAY   := aPrt_07_PrinterTray;
    userPrintOptionList(7).PRT_PRINT_SQL      := aPrt_07_PrintSQL;
    userPrintOptionList(8).PRT_PRINT          := aPrt_08_Print;
    userPrintOptionList(8).PRT_FORM_NAME      := aPrt_08_FormName;
    userPrintOptionList(8).PRT_COPIES         := aPrt_08_Copies;
    userPrintOptionList(8).PRT_COLLATE        := aPrt_08_Collate;
    userPrintOptionList(8).PRT_PRINTER_NAME   := aPrt_08_PrinterName;
    userPrintOptionList(8).PRT_PRINTER_TRAY   := aPrt_08_PrinterTray;
    userPrintOptionList(8).PRT_PRINT_SQL      := aPrt_08_PrintSQL;
    userPrintOptionList(9).PRT_PRINT          := aPrt_09_Print;
    userPrintOptionList(9).PRT_FORM_NAME      := aPrt_09_FormName;
    userPrintOptionList(9).PRT_COPIES         := aPrt_09_Copies;
    userPrintOptionList(9).PRT_COLLATE        := aPrt_09_Collate;
    userPrintOptionList(9).PRT_PRINTER_NAME   := aPrt_09_PrinterName;
    userPrintOptionList(9).PRT_PRINTER_TRAY   := aPrt_09_PrinterTray;
    userPrintOptionList(9).PRT_PRINT_SQL      := aPrt_09_PrintSQL;
    userPrintOptionList(10).PRT_PRINT         := aPrt_10_Print;
    userPrintOptionList(10).PRT_FORM_NAME     := aPrt_10_FormName;
    userPrintOptionList(10).PRT_COPIES        := aPrt_10_Copies;
    userPrintOptionList(10).PRT_COLLATE       := aPrt_10_Collate;
    userPrintOptionList(10).PRT_PRINTER_NAME  := aPrt_10_PrinterName;
    userPrintOptionList(10).PRT_PRINTER_TRAY  := aPrt_10_PrinterTray;
    userPrintOptionList(10).PRT_PRINT_SQL     := aPrt_10_PrintSQL;
  end UpdateUserPrintOptionList;

  /**
  * procedure UpdateBarcodeStatus
  * Description
  *     Màj du statut des barcodes traités
  * @created NGV 2010
  * @public
  */
  procedure UpdateBarcodeStatus
  is
  begin
    for tplBarcode in (select   DOC_BARCODE_ID
                           from DOC_PERIODIC_DISCHARGE
                          where DDI_SELECTION = 1
                       order by DOC_BARCODE_ID) loop
      update DOC_BARCODE
         set C_DOC_BARCODE_STATUS = '50'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_BARCODE_ID = tplBarcode.DOC_BARCODE_ID;
    end loop;

    for tplBarcodeHeader in (select   DBH.DOC_BARCODE_HEADER_ID
                                 from DOC_PERIODIC_DISCHARGE DDI
                                    , DOC_BARCODE DBC
                                    , DOC_BARCODE_HEADER DBH
                                where DDI.DDI_SELECTION = 1
                                  and DDI.DOC_BARCODE_ID = DBC.DOC_BARCODE_ID
                                  and DBC.DOC_BARCODE_HEADER_ID = DBH.DOC_BARCODE_HEADER_ID
                             group by DBH.DOC_BARCODE_HEADER_ID) loop
      DOC_BARCODE_CONTROL.UpdateHeaderStatus(tplBarcodeHeader.DOC_BARCODE_HEADER_ID);
    end loop;
  end UpdateBarcodeStatus;
end DOC_PERIODIC_DISCH_FUNCTIONS;
