--------------------------------------------------------
--  DDL for Package Body ACI_ISAG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_ISAG" 
/**
 * Méthodes d'intégration de documents ISE dans ProConcept ERP.
 *
 * ! Warning !
 * Please note, method names and parameter names should not be changed because
 * this package is used by an external tool.
 * ! Warning !
 *
 * @version 2003
 * @date 08.2004
 * @author fperotto
 * @author pyvoirol
 * @author skalayci
 * @author spfister
 */
IS

  -- curseur définissant la structure d'une entête de facture
  cursor crStructureDoc
  is
    select CSO_DATA1
         , CSO_DATA3
         , CSO_KEY
         , CSO_JOIN_KEY
      from ACI_CONVERSION_SOURCE
     where ACI_CONVERSION_ID = 0;

  TYPE Ttbldocument IS TABLE OF crStructureDoc%ROWTYPE INDEX BY BINARY_INTEGER;

  -- curseur définissant la structure d'une imputation
  cursor crStructureImp
  is
    select CSO_DATA1
         , CSO_KEY
         , CSO_DOC_KEY
         , CSO_JOIN_KEY
      from ACI_CONVERSION_SOURCE
     where ACI_CONVERSION_ID = 0;

  TYPE TtblImputation IS TABLE OF crStructureImp%ROWTYPE INDEX BY BINARY_INTEGER;

  /**
   * Initialisation automatique des paramètres de session
   */
  procedure p_init_session
  is
  begin
    --Inititalisation de la variable globale dans PC_LIB_SESSION
    select PC_COMP_ID
         , PC_LANG_ID
      into pcs.PC_LIB_SESSION.company_id
         , pcs.PC_LIB_SESSION.comp_lang_id
      from PCS.V_PC_COMP_OWNER
     where SCRDBOWNER = sys_context('USERENV', 'CURRENT_SCHEMA')
       and SCRDB_LINK is null;

    select max(PC_USER_ID)
         , max(PC_LANG_ID)
      into pcs.PC_LIB_SESSION.user_id
         , pcs.PC_LIB_SESSION.user_lang_id
      from PCS.PC_USER
     where USE_NAME = pcs.pc_config.GetConfigUpper('ACI_INNOSOLV_USER');
  end;

 /**
  * Activation du processus e-facture
  * @param aJobNumber : numéro de Job
  */
  procedure p_ACI_EBPP(in_ConversionId in number)
  is
  begin
    -- Les documents respectant la règle suivante sont traités en premier
    --  o factures (c_type_catalogue = 2)
    --  o dont le montant est supérieur à zéro
    --  o n'étant pas un document d'extourne (dont le numéro partenaire ne contient pas "-X")
    --  o n'étant pas complètement lettré (échéance nette dont le montant à payer est plus grand que le montant payé)
    for tpl_aci_docs in (select   ACI.ACI_DOCUMENT_ID
                                , ACI.ACT_DOCUMENT_ID
                             from ACI_DOCUMENT ACI
                                , ACT_DOCUMENT DOC
                                , ACT_PART_IMPUTATION PAR
                                , ACJ_CATALOGUE_DOCUMENT CAT
                                , V_ACT_EXPIRY_ISAG ISE
                            where ACI.ACI_CONVERSION_ID = in_ConversionId
                              and ACI.C_STATUS_DOCUMENT = 'DEF'
                              and ACI.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                              and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                              and instr(PAR.PAR_DOCUMENT, '-X') = 0
                              and DOC.DOC_TOTAL_AMOUNT_DC > 0
                              and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                              and CAT.C_TYPE_CATALOGUE = '2'
                              and DOC.ACT_DOCUMENT_ID = ISE.ACT_DOCUMENT_ID
                              and ISE.EXP_CALC_NET = 1
                              and (ISE.EXP_AMOUNT_LC - ISE.DET_PAIED_LC) != 0
                         order by ACI.ACT_DOCUMENT_ID asc) loop
      ACI_ISAG.ACI_EBPP_ONE_DOC(tpl_aci_docs.ACT_DOCUMENT_ID, tpl_aci_docs.ACI_DOCUMENT_ID, null, 'ISAG');
    end loop;

    /* documents d'extournes */
    for tpl_aci_reversal in (select ACI.ACI_DOCUMENT_ID
                                  , ACI.ACT_DOCUMENT_ID
                                  , replace(PAR.PAR_DOCUMENT, '-X') PAR_DOCUMENT
                               from ACI_DOCUMENT ACI
                                  , ACT_DOCUMENT DOC
                                  , ACT_PART_IMPUTATION PAR
                                  , ACJ_CATALOGUE_DOCUMENT CAT
                              where ACI.ACI_CONVERSION_ID = in_ConversionId
                                and ACI.C_STATUS_DOCUMENT = 'DEF'
                                and ACI.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                                and instr(PAR.PAR_DOCUMENT, '-X') > 0
                                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                                and CAT.C_TYPE_CATALOGUE = '2') loop
      ACI_PRC_UTL_ISAG.ACI_EBPP_CHECK_REVERSAL(tpl_aci_reversal.ACT_DOCUMENT_ID, in_ConversionId);
    end loop;
  end p_ACI_EBPP;


  procedure ACI_EBPP_ONE_DOC(in_actDocumentId act_document.act_document_id%type
                            ,in_aciDocumentId aci_document.act_document_id%type
                            ,in_comEbankingId com_ebanking.com_ebanking_id%type
                            ,iv_callerCtx varchar2)
  is
    ln_countOfActiveReferences number;
    ln_comEbankingId com_ebanking.com_ebanking_id%type;
    ltpl_ebpp_reference pac_ebpp_reference%ROWTYPE;
  begin
    ln_comEbankingId := in_comEbankingId;

    -- traiter chaque abonnement du document comptable,
    -- la règle veut que chaque document document ne contienne qu'un abonnement
    for tpl_act_docs in (
      select distinct
             PAR.ACT_DOCUMENT_ID
            ,PAR.PAC_CUSTOM_PARTNER_ID
            ,IMF.IMF_NUMBER2
        from ACT_PART_IMPUTATION PAR
            ,ACT_FINANCIAL_IMPUTATION IMF
       where PAR.ACT_DOCUMENT_ID = in_actDocumentId
         and IMF.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
         and IMF.IMF_NUMBER2 is not null
    ) loop
      -- nombre de références actives au total
      ln_countOfActiveReferences := aci_prc_utl_isag.CountActiveEbppReferences(
        in_custom_partner_id => tpl_act_docs.PAC_CUSTOM_PARTNER_ID,
        iv_ebp_external_reference => null,
        iv_count_mode => 'ALL');
      if ln_countOfActiveReferences = 0 then
        if iv_callerCtx = 'ISAG' then
          -- appelé depuis le processus aci_isag.aci_ebpp,
          -- pas de traitement e-factures, le client n'a aucune référence EBPP active
          exit;
        elsif iv_callerCtx = 'CTRL' then
          -- appelé depuis le processus de contrôle
          -- signifie qu'une ligne est présente dans la table com_ebanking
          aci_prc_utl_isag.GenerateComEBanking(
            in_act_document_id => in_actDocumentId,
            in_aci_document_id => in_aciDocumentId,
            in_exchange_system_id => null,
            in_ebpp_reference_id => null,
            iv_callerCtx => iv_callerCtx,
            ion_ebanking_id => ln_comEbankingId);
          com_prc_ebanking_det.InsertEBPPDetail(
            in_ebanking_id => ln_comEbankingId,
            iv_ebanking_status => '000',
            iv_ebanking_error => '300',
            ib_update => TRUE);
        else
          ra('Unknown caller context mode : ' || nvl(iv_callerCtx, 'null value received'));
        end if;
      else
        -- calcul du nombre de références actives pour le contrat
        ln_countOfActiveReferences := aci_prc_utl_isag.CountActiveEbppReferences(
          in_custom_partner_id => tpl_act_docs.PAC_CUSTOM_PARTNER_ID,
          iv_ebp_external_reference => tpl_act_docs.IMF_NUMBER2,
          iv_count_mode => 'EXACT');
        if ln_countOfActiveReferences > 1 then
          -- erreur : le client a plusieurs références actives pour l'abonnement
          aci_prc_utl_isag.GenerateComEBanking(
            in_act_document_id => in_actDocumentId,
            in_aci_document_id => in_aciDocumentId,
            in_exchange_system_id => null,
            in_ebpp_reference_id => null,
            iv_callerCtx => iv_callerCtx,
            ion_ebanking_id => ln_comEbankingId);
          com_prc_ebanking_det.InsertEBPPDetail(
            in_ebanking_id => ln_comEbankingId,
            iv_ebanking_status => '000',
            iv_ebanking_error => '300',
            ib_update => TRUE);
        elsif ln_countOfActiveReferences = 1 then
          -- le client n'a qu'une référence active pour l'abonnement
          aci_prc_utl_isag.FindEbppReference(
            in_custom_partner_id => tpl_act_docs.PAC_CUSTOM_PARTNER_ID,
            iv_search_method => '01',
            iv_ebp_external_reference => tpl_act_docs.IMF_NUMBER2,
            otpl_ebpp_reference => ltpl_ebpp_reference);
          if ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null then
             aci_prc_utl_isag.ValidateExchSys(
              in_ebpp_reference_id => ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID,
              in_exchange_system_id => ltpl_ebpp_reference.PC_EXCHANGE_SYSTEM_ID,
              iv_ecs_bsp => ltpl_ebpp_reference.C_EBPP_BSP,
              in_act_document_id => in_actDocumentId,
              in_aci_document_id => in_aciDocumentId,
              iv_callerCtx => iv_callerCtx);
          else
            -- cas particulier la référence active a changé de statut durant le traitement
            aci_prc_utl_isag.GenerateComEBanking(
              in_act_document_id => in_actDocumentId,
              in_aci_document_id => in_aciDocumentId,
              in_exchange_system_id => ltpl_ebpp_reference.PC_EXCHANGE_SYSTEM_ID,
              in_ebpp_reference_id => null,
              iv_callerCtx => iv_callerCtx,
              ion_ebanking_id => ln_comEbankingId);
            com_prc_ebanking_det.InsertEBPPDetail(
              in_ebanking_id => ln_comEbankingId,
              iv_ebanking_status => '000',
              iv_ebanking_error => '305',
              ib_update => TRUE);
          end if;
        else
          -- le client n'a aucune référence active liée à l'abonnement
          -- recherche de la référence active et valide par défaut
          aci_prc_utl_isag.FindEbppReference(
            in_custom_partner_id => tpl_act_docs.PAC_CUSTOM_PARTNER_ID,
            iv_search_method => '02',
            iv_ebp_external_reference => null,
            otpl_ebpp_reference => ltpl_ebpp_reference);
          if ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null then
            -- référence par défaut trouvée
            aci_prc_utl_isag.ValidateExchSys(
              in_ebpp_reference_id => ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID,
              in_exchange_system_id => ltpl_ebpp_reference.PC_EXCHANGE_SYSTEM_ID,
              iv_ecs_bsp => ltpl_ebpp_reference.C_EBPP_BSP,
              in_act_document_id => in_actDocumentId,
              in_aci_document_id => in_aciDocumentId,
              iv_callerCtx => iv_callerCtx);
          else
            -- recherche d'une référence active sans numéro d'abonnement
            aci_prc_utl_isag.FindEbppReference(
              in_custom_partner_id => tpl_act_docs.PAC_CUSTOM_PARTNER_ID,
              iv_search_method => '03',
              iv_ebp_external_reference => null,
              otpl_ebpp_reference => ltpl_ebpp_reference);
            if ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null then
              aci_prc_utl_isag.ValidateExchSys(
                in_ebpp_reference_id => ltpl_ebpp_reference.PAC_EBPP_REFERENCE_ID,
                in_exchange_system_id => ltpl_ebpp_reference.PC_EXCHANGE_SYSTEM_ID,
                iv_ecs_bsp => ltpl_ebpp_reference.C_EBPP_BSP,
                in_act_document_id => in_actDocumentId,
                in_aci_document_id => in_aciDocumentId,
                iv_callerCtx => iv_callerCtx);
            elsif iv_callerCtx = 'CTRL' then
              aci_prc_utl_isag.GenerateComEBanking(
                in_act_document_id => in_actDocumentId,
                in_aci_document_id => in_aciDocumentId,
                in_exchange_system_id => null,
                in_ebpp_reference_id => null,
                iv_callerCtx => iv_callerCtx,
                ion_ebanking_id => ln_comEbankingId);
              com_prc_ebanking_det.InsertEBPPDetail(
                in_ebanking_id => ln_comEbankingId,
                iv_ebanking_status => '000',
                iv_ebanking_error => '304',
                ib_update => TRUE);
            else
              -- contexte d'appel = ISAG
              -- appelé depuis le processus aci_isag.aci_ebpp,
              -- pas de traitement e-factures, le client n'a aucune référence EBPP active sans numéro de contrat
              Exit;
            end if;
          end if;
        end if;
      end if;
    end loop;
  end ACI_EBPP_ONE_DOC;

  procedure ACI_START(aJobNumber in number)
  is
    ln_ConvTypeId ACI_CONVERSION_TYPE.ACI_CONVERSION_TYPE_ID%type;
    ln_CurrentId  ACI_CONVERSION.ACI_CONVERSION_ID%type;
    lv_IsagType   varchar2(32767);
  begin
    -- initialisation des paramètres de session
    p_init_session;
    lv_IsagType  := PCS.PC_CONFIG.GetConfig('ACI_ISAG_ACT_CONVERSION_TYPE');
    --Id séquentiel pour la table et non plus le numéro de job reçu
    select init_id_seq.nextval
      into ln_CurrentId
      from dual;

    -- création d'une entrée dans ACI_CONVERSION correspondant au job à intégrer
    select ACI_CONVERSION_TYPE_ID
      into ln_ConvTypeId
      from ACI_CONVERSION_TYPE
     where CTY_DESCR = lv_IsagType
       and C_SOURCE_TYPE = '50';

    insert into ACI_CONVERSION
                (ACI_CONVERSION_ID
               , ACI_CONVERSION_TYPE_ID
               , CNV_SOURCE_FILE1
               , CNV_SOURCE_FILE2
               , CNV_TARGET_FILE
               , A_DATECRE
               , A_IDCRE
               , CNV_TRANSFERT_DATE
               , CNV_ISAG_JOB_NUMBER
                )
         values (ln_CurrentId
               , ln_ConvTypeId
               , lv_IsagType ||' '|| aJobNumber
               , null
               , null
               , sysdate
               , 'ISE'
               , null
      	       , aJobNumber
                );

    -- préparation  factures
    aci_isag.ACI_START_02(ln_CurrentId,aJobNumber);
    -- préparation lettrages
    aci_isag.ACI_START_09(ln_CurrentId,aJobNumber);
    commit;
    -- intégration et contrôle des données
    aci_ascii_document.Recover_File(ln_CurrentId);
    -- e-facture
    p_ACI_EBPP(ln_CurrentId);

  end ACI_START;

  procedure ACI_START_02(in_ConversionId in number, in_JobNumber in number)
  is
    tblDocument    Ttbldocument;
    tblImputation  TtblImputation;
    sqlStatement VARCHAR2(32767);
    conversionType ACI_CONVERSION_TYPE.ACI_CONVERSION_TYPE_ID%type;
    startDoc NUMBER;
    lv_DbLinkName varchar2(32767);
  begin
    select init_id_seq.nextval
      into startDoc
      from dual;

    --Récupère le nom du Db link renseigné par la config.
    lv_DbLinkName := pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK');
    -- chargement de la commande de recherche des documents comptables du job à intégrer
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_DOCUMENT');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', lv_DbLinkName);
    -- remplacement du paramètre PER_KEY1
    sqlStatement := Replace(sqlStatement, ':ID_JOB', in_JobNumber);

    -- execution de la commande
    execute immediate sqlStatement
      bulk collect into tblDocument;

    if tblDocument.count > 0 then
      for i in tblDocument.first .. tblDocument.last loop
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_DATA3
                   , CSO_KEY
                   , CSO_JOIN_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , in_ConversionId
                   , tblDocument(i).CSO_DATA1
                   , tblDocument(i).CSO_DATA3
                   , tblDocument(i).CSO_KEY
                   , tblDocument(i).CSO_JOIN_KEY
                   , init_id_seq.nextval - startDoc
                   , '02'
                    );
      end loop;

      -- chargement de la commande de recherche des imputations primaires
      sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_PRIMARY_FIN_IMP');
      -- remplacement du nom du DB_LINK
      sqlStatement := replace(sqlStatement, '[ISAG_DB_LINK]', lv_DbLinkName);
      -- remplacement du paramètre ID_JOB
      sqlStatement := replace(sqlStatement, ':ID_JOB', in_JobNumber);

      -- execution de la commande
      execute immediate sqlStatement
        bulk collect into tblImputation;

      for i in tblImputation.first .. tblImputation.last loop
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_JOIN_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , in_ConversionId
                   , tblImputation(i).CSO_DATA1
                   , tblImputation(i).CSO_KEY
                   , tblImputation(i).CSO_JOIN_KEY
                   , tblImputation(i).CSO_DOC_KEY
                   ,'02'
                    );
      end loop;

      sqlStatement :=  'insert into V_PCS_Beleg_tmp '|| chr(13) ||
                       'select
                          "ID_ERPBeleg",
                          "ID_Job",
                          "ID_Beleg",
                          "ID_Rechnung",
                          "Kundennummer",
                          "Belegart",
                          "ID_Belegart",
                          "ID_ERP_Dokument",
                          "Belegnummer",
                          "Debidatum",
                          "Fibudatum",
                          "Bemerkung",
                          "Zahlungskondition",
                          "Belegreferenz",
                          "ID_Sammelrechnung",
                          "ZahlwegVorschlag",
                          "BelegbetragLW",
                          "BelegbetragFW",
                          "KursFW",
                          "ISOCodeLW",
                          "ISOCodeFW",
                          "Vesrcode",
                          "Firmenzahlstelle",
                          "ID_Firmenzahlstelle",
                          "Zahlungsreferenz",
                          "Division",
                          "AusbuchungsBetragLW",
                          "AusbuchungsBetragFW"' || chr(13) ||
                        ' from dbo."V_PCS_Beleg"@'||lv_DbLinkName|| chr(13) ||
                       '  where "ID_Job" = '|| in_JobNumber ;
      -- execution de la commande
      execute immediate sqlStatement;

      sqlStatement :=  'insert into V_PCS_Belegpos_tmp ( "ID_ERPBeleg", "ID_Job", "ID_Beleg",  "ID_Rechnung", "LaufNr_Belegpos", "Habenkonto",  "HabenKST_KTR1", "HabenKST_KTR2", "BetragLW",
                                "MWSTBetragLW", "MWSTCode", "Positionstext", "Menge", "BetragFW", "MWSTBetragFW", "MWSTSatz", "HabenKST_KTR3", "Geschaeftsbereich")'|| chr(13) ||
--                       '  select * from dbo."V_PCS_Belegpos"@'||lv_DbLinkName|| chr(13) ||
                       'select
                        "ID_ERPBeleg",
                        "ID_Job",
                        "ID_Beleg",
                        "ID_Rechnung",
                        "LaufNr_Belegpos",
                        "Habenkonto",
                        "HabenKST_KTR1",
                        "HabenKST_KTR2",
                        "BetragLW",
                        "MWSTBetragLW",
                        "MWSTCode",
                        "Positionstext",
                        "Menge",
                        "BetragFW",
                        "MWSTBetragFW",
                        "MWSTSatz",
                        "HabenKST_KTR3",    -- IMPORTANT -- nécessite absolument ISE2012 SP 21 ou 2014 SP10
                        "Geschaeftsbereich"'  || chr(13) || -- IMPORTANT -- nécessite absolument ISE2012 SP 21 ou 2014 SP10
                      ' from dbo."V_PCS_Belegpos"@'||lv_DbLinkName|| chr(13) ||
                      ' where "ID_Job" = '|| in_JobNumber ;
      -- execution de la commande
      execute immediate sqlStatement;

      -- chargement de la commande de recherche des imputation financières
      sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_FIN_IMP_TMP');
      -- remplacement du nom du DB_LINK
      sqlStatement := replace(sqlStatement, '[ISAG_DB_LINK]', lv_DbLinkName );
      -- remplacement du paramètre ID_JOB
      sqlStatement := replace(sqlStatement, ':ID_JOB', in_JobNumber);

      -- execution de la commande
      execute immediate sqlStatement
        bulk collect into tblImputation;

      for i in tblImputation.first .. tblImputation.last loop
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_JOIN_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , in_ConversionId
                   , tblImputation(i).CSO_DATA1
                   , tblImputation(i).CSO_KEY
                   , tblImputation(i).CSO_JOIN_KEY
                   , tblImputation(i).CSO_DOC_KEY
                   ,'02'
                    );
      end loop;
    end if;
  end ACI_START_02;

  procedure ACI_START_09(in_ConversionId in number, in_JobNumber in number)
  is
    tblDocument  Ttbldocument;
    tblMatching  TtblImputation;
    sqlStatement VARCHAR2(32767);
    startDoc NUMBER;
  begin
    select init_id_seq.nextval
      into startDoc
      from dual;

    -- chargement de la commande de recherche des documents comptables du job à intégrer
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_MATCHING_DOCUMENT');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
    -- remplacement du paramètre PER_KEY1
    sqlStatement := Replace(sqlStatement, ':ID_JOB', in_JobNumber);

    -- execution de la commande
    EXECUTE IMMEDIATE
      sqlStatement
      BULK COLLECT INTO tblDocument;

    if tblDocument.count > 0 then
      for i in tblDocument.first .. tblDocument.last loop
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_DATA3
                   , CSO_KEY
                   , CSO_JOIN_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , in_ConversionId
                   , tblDocument(i).CSO_DATA1
                   , tblDocument(i).CSO_DATA3
                   , tblDocument(i).CSO_KEY
                   , tblDocument(i).CSO_JOIN_KEY
                   , init_id_seq.nextval - startDoc
                   ,'02'
                    );
      end loop;

      -- chargement de la commande de recherche des lettrages
      sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_MATCHING');
      -- remplacement du nom du DB_LINK
      sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
      -- remplacement du paramètre ID_JOB
      sqlStatement := Replace(sqlStatement, ':ID_JOB', in_JobNumber);

      -- execution de la commande
      EXECUTE IMMEDIATE
        sqlStatement
        BULK COLLECT INTO tblMatching;

      for i in tblMatching.first .. tblMatching.last loop
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_JOIN_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , in_ConversionId
                   , tblMatching(i).CSO_DATA1
                   , tblMatching(i).CSO_KEY
                   , tblMatching(i).CSO_JOIN_KEY
                   , tblMatching(i).CSO_DOC_KEY
                   ,'02'
                    );
      end loop;
    end if;
  end ACI_START_09;

  procedure ACI_DELETE(aJobNumber in number)
  is
  begin
    -- initialisation des paramètres de session
    p_init_session;

    delete from ACI_DOCUMENT_STATUS
          where ACI_DOCUMENT_ID in(select ACI_DOCUMENT_ID
                                     from ACI_DOCUMENT DOC
                                        , ACI_CONVERSION CSO
                                    where DOC.C_INTERFACE_CONTROL = 2
                                      and DOC.ACI_CONVERSION_ID = CSO.ACI_CONVERSION_ID
                                      and CSO.CNV_ISAG_JOB_NUMBER = aJobNumber);

    delete from ACI_DOCUMENT
          where C_INTERFACE_CONTROL = 2
            and ACI_CONVERSION_ID = (select ACI_CONVERSION_ID
                                       from ACI_CONVERSION
                                      where CNV_ISAG_JOB_NUMBER = aJobNumber);
  end ACI_DELETE;

  procedure PAC(aPerKey1 PAC_PERSON.PER_KEY1%type, aClient number)
  is
    sqlISAG_PERSON varchar2(32767);
    sqlISAG_INSERT varchar2(32767);

    cursor crStructure
    is
      select CSO_DATA1
           , CSO_KEY
           , CSO_JOIN_KEY
        from ACI_CONVERSION_SOURCE
       where ACI_CONVERSION_ID = 0;

    tplStructureP  crStructure%rowtype;
    tplStructureC  crStructure%rowtype;
    conversionID   ACI_CONVERSION.ACI_CONVERSION_ID%type;
    conversionType ACI_CONVERSION_TYPE.ACI_CONVERSION_TYPE_ID%type;
    startDoc       integer;
    ERP_ID1        PAC_PERSON.PAC_PERSON_ID%type;
    ERP_ID2        PAC_CUSTOM_PARTNER.ACS_AUXILIARY_ACCOUNT_ID%type;
    checkPerson    number(1) := 1;
    importError    PCS.PC_GCODES.GCDTEXT1%type;
    nbAddress      integer;
  begin
    -- initialisation des paramètres de session
    p_init_session;
    pcs.PC_LIB_SESSION.EnableReplication;

    select init_id_seq.nextval
      into conversionID
      from dual;

    begin
      select ACI_CONVERSION_TYPE_ID
        into conversionType
        from ACI_CONVERSION_TYPE
       where CTY_DESCR = pcs.pc_config.GetConfig('ACI_ISAG_PAC_CONVERSION_TYPE')
         and C_SOURCE_TYPE = '80';
    exception
      when NO_DATA_FOUND then
        raise_application_error(-20000, pcs.pc_functions.TranslateWord('PCS - Type de conversion manquant ou mal défini.'));
    end;

    insert into ACI_CONVERSION
                (ACI_CONVERSION_ID
               , ACI_CONVERSION_TYPE_ID
               , CNV_SOURCE_FILE1
               , CNV_SOURCE_FILE2
               , CNV_TARGET_FILE
               , A_DATECRE
               , A_IDCRE
               , CNV_TRANSFERT_DATE
                )
         values (conversionId
               , conversionType
               , pcs.pc_config.GetConfig('ACI_ISAG_PAC_CONVERSION_TYPE') || ' ' || aPerKey1
               , null
               , null
               , sysdate
               , 'ISE'
               , null
                );

    begin
      -- chargement de la commande de recherche de la personne dans la base isag
      sqlISAG_PERSON := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_PERSON');
      -- remplacement du nom du DB_LINK
      sqlISAG_PERSON := Replace(sqlISAG_PERSON, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
      -- remplacement du paramètre PER_KEY1
      sqlISAG_PERSON := Replace(sqlISAG_PERSON, ':PER_KEY1', aPerKey1);
      -- remplacement du paramètre AMODE
      sqlISAG_PERSON := Replace(sqlISAG_PERSON, ':AMODE', aClient);

      -- execution de la commande
      EXECUTE IMMEDIATE
        sqlISAG_PERSON
        INTO tplStructureP;

      if aClient in (1, 9) then
        -- chargement de la commande de recherche de la personne dans la base isag
        sqlISAG_PERSON := pcs.pc_functions.GetSql('ACI_CONVERSION_SOURCE', 'ACI_ISAG', 'V_ACI_ISAG_CUSTOMER');
        -- remplacement du nom du DB_LINK
        sqlISAG_PERSON := Replace(sqlISAG_PERSON, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') );
        -- remplacement du paramètre PER_KEY1
        sqlISAG_PERSON := Replace(sqlISAG_PERSON, ':PER_KEY1', aPerKey1);
        -- remplacement du paramètre AMODE
        sqlISAG_PERSON := Replace(sqlISAG_PERSON, ':AMODE', aClient);

        -- execution de la commande
        EXECUTE IMMEDIATE
          sqlISAG_PERSON
          INTO tplStructureC;
      end if;

      if aClient = 9 then
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , conversionID
                   , tplStructureC.CSO_DATA1
                   , tplStructureC.CSO_KEY
                   , 1
                   ,'02'
                    );

        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , conversionID
                   , tplStructureP.CSO_DATA1
                   , tplStructureP.CSO_KEY
                   , 2
                   ,'02'
                    );
      else
        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , conversionID
                   , tplStructureP.CSO_DATA1
                   , tplStructureP.CSO_KEY
                   , 1
                   ,'02'
                    );

        insert into ACI_CONVERSION_SOURCE
                    (ACI_CONVERSION_SOURCE_ID
                   , ACI_CONVERSION_ID
                   , CSO_DATA1
                   , CSO_KEY
                   , CSO_DOC_KEY
                   , CSO_VERSION
                    )
             values (init_id_seq.nextval
                   , conversionID
                   , tplStructureC.CSO_DATA1
                   , tplStructureC.CSO_KEY
                   , 2
                   ,'02'
                    );
      end if;

      ACI_ASCII_PERSON.Recover_File(conversionId, checkPerson);
      commit;
    exception
      when NO_DATA_FOUND then
        checkPerson := 0;
        commit;
    end;

    if checkPerson = 1 then   -- intégration OK
      select max(PAC_CUSTOM_PARTNER_ID)
           , max(ACS_AUXILIARY_ACCOUNT_ID)
        into ERP_ID1
           , ERP_ID2
        from PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER
       where PAC_CUSTOM_PARTNER_ID = PAC_PERSON_ID
         and PER_KEY1 = aPerKey1
         and aClient = 1;

      select count(*)
        into nbAddress
        from PAC_PERSON PER
           , PAC_ADDRESS ADR
       where PER_KEY1 = aPerKey1
         and ADR.PAC_PERSON_ID = PER.PAC_PERSON_ID
         and aClient = 9;

      if nbAddress > 0 then
        importError  :=
          '''' ||
          Replace(pcs.pc_functions.GetDescodeDescr('C_PARTNER_STATUS', '0', pcs.PC_LIB_SESSION.GetCompLangId)
                , ''''
                , ''''''
                 ) ||
          '''';
      else
        importError  := 'null';
      end if;

      sqlISAG_INSERT  :=
        'INSERT INTO "ERPAdressqueue"@'|| pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') ||
        ' ("ID_Subjekt","Mandant","ID_SWSystem","ERP_ID1","ERP_ID2","Fehler","Status") values(' ||
        aPerKey1 ||
        ',''' ||
        pcs.PC_LIB_SESSION.GetCompanyOwner ||
        ''',101,' ||
        nvl(to_char(ERP_ID1), 'null') ||
        ',' ||
        nvl(to_char(ERP_ID2), 'null') ||
        ',' ||
        ImportError ||
        ',null)';

      begin
        EXECUTE IMMEDIATE sqlISAG_INSERT;
      exception
        when OTHERS then
          raise_application_error(-20000, sqlerrm || Chr(10) || sqlISAG_INSERT);
      end;
    else   -- erreur
      importError := aci_ascii_person.getErrorMessage(conversionId);
      importError :=
        importError ||
        ' - ' ||
        replace(pcs.pc_functions.GetDescodeDescr('C_ASCII_FAIL_REASON', importError, pcs.PC_LIB_SESSION.GetCompLangId)
              , ''''
              , ''''''
               );
      sqlISAG_INSERT  :=
        'INSERT INTO "ERPAdressqueue"@'|| pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') ||
        ' ("ID_Subjekt","Mandant","ID_SWSystem","ERP_ID1","ERP_ID2","Fehler","Status") values(' ||
        aPerKey1 ||
        ',''' ||
        pcs.PC_LIB_SESSION.GetCompanyOwner ||
        ''',101,null,null,''' ||
        importError ||
        ''',null)';

      begin
        EXECUTE IMMEDIATE sqlISAG_INSERT;
      exception
        when OTHERS then
          raise_application_error(-20001, sqlerrm || Chr(10) || sqlISAG_INSERT);
      end;
    end if;

    commit;
  end PAC;

  procedure ACI_EXPIRY_LOAD(aJobNumber in number)
  is
    sqlStatement VARCHAR2(32767);
  begin
    -- initialisation des paramètres de session
    -- p_init_session; -- initialisé dans ACI_EXPIRY_DELETE

    -- suppression des éventuelles anciennes extractions
    aci_isag.ACI_EXPIRY_DELETE(aJobNumber);

    -- chargement de la commande de recherche des documents comptables du job à intégrer
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG', 'FILL_ISAG_EXPIRY');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
    -- remplacement du paramètre PER_KEY1
    sqlStatement := Replace(sqlStatement, ':ID_JOB', aJobNumber);

    -- execution de la commande
    EXECUTE IMMEDIATE sqlStatement;
  end ACI_EXPIRY_LOAD;

  procedure ACI_EXPIRY_DELETE(aJobNumber in number)
  is
  begin
    -- initialisation des paramètres de session
    p_init_session;

    delete ACI_ISAG_EXPIRY
     where JOB_ID = aJobNumber;
  end ACI_EXPIRY_DELETE;

  procedure PAC_INVOICE_ADDRESS(aInvoiceId in number, aDateRef in date)
  is
    sqlStatement VARCHAR2(32767);
    strDate             varchar2(20);
    tplACI_ISAG_ADDRESS ACI_ISAG_ADDRESS%rowtype;
  begin
    -- effacement de l'ancienne adresse de la facture
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG', 'DELETE_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
    -- remplacement des paramètres
    sqlStatement := Replace(sqlStatement, ':ID_RECHNUNG', aInvoiceId);

    -- execution de la commande
    EXECUTE IMMEDIATE sqlStatement;

    commit;
    -- création de la nouvelle adresse de la facture
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG', 'INSERT_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));
    -- remplacement des paramètres
    sqlStatement := Replace(sqlStatement, ':ID_RECHNUNG', aInvoiceId);

    select to_char(Round(aDateRef - to_date('01.01.1900','DD.MM.YYYY'), 5) )
      into strDate
      from dual;

    sqlStatement := Replace(sqlStatement, ':DATEREF', strDate);
    sqlStatement := Replace(sqlStatement, ':ID_SWSystem', '101');
    sqlStatement := Replace(sqlStatement, ':InfoparamBez', ''''|| pcs.pc_config.GetConfig('ACI_ISAG_ADDRESS_INFOPARAM') ||'''');

    -- execution de la commande
    EXECUTE IMMEDIATE sqlStatement;

    commit;
    -- recherche l'adresse formattée
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG', 'GET_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') );
    -- remplacement des paramètres
    sqlStatement := Replace(sqlStatement, ':ID_RECHNUNG', aInvoiceId);

    -- execution de la commande
    EXECUTE IMMEDIATE
      sqlStatement
      INTO tplACI_ISAG_ADDRESS;

    -- suppression des éventuelles anciennes valeurs
    delete from ACI_ISAG_ADDRESS
          where ID_RECHNUNG = tplACI_ISAG_ADDRESS.ID_RECHNUNG;

    insert into ACI_ISAG_ADDRESS
                (ID_RECHNUNG
               , GUELTIGAB
               , RECHNUNGSADRESSE
               , VERARBEITET
               , FEHLER
               , LASTDATE
               , ID_SWSYSTEM
               , VERTRAGSPARTNERADRESSE
               , OBJEKTE
               , INFOPARAMBEZ
               , INFOPARAMWERT
               , WBPARAM1
                )
         values (tplACI_ISAG_ADDRESS.ID_RECHNUNG
               , tplACI_ISAG_ADDRESS.GUELTIGAB
               , tplACI_ISAG_ADDRESS.RECHNUNGSADRESSE
               , tplACI_ISAG_ADDRESS.VERARBEITET
               , tplACI_ISAG_ADDRESS.FEHLER
               , tplACI_ISAG_ADDRESS.LASTDATE
               , tplACI_ISAG_ADDRESS.ID_SWSYSTEM
               , tplACI_ISAG_ADDRESS.VERTRAGSPARTNERADRESSE
               , tplACI_ISAG_ADDRESS.OBJEKTE
               , tplACI_ISAG_ADDRESS.INFOPARAMBEZ
               , tplACI_ISAG_ADDRESS.INFOPARAMWERT
               , tplACI_ISAG_ADDRESS.WBPARAM1
                );

    commit;
  end PAC_INVOICE_ADDRESS;

  procedure Init_ISAG_Reminder(aJobId in number)
  is
    sqlStatement VARCHAR2(32767);
  begin
    -- Commit éventuelle transaction avant d'en créer une nouvelle sur ISAG
    commit;
    -- effacement des anciennes adresses des factures
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG2', 'DELETE_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));

    -- execution de la commande
    EXECUTE IMMEDIATE
      sqlStatement
      USING aJobId;

    commit;

    -- effacement anciennes adresses
    delete ACI_ISAG_ADDRESS
     where ACT_JOB_ID = aJobId;

    commit;
  end Init_ISAG_Reminder;

  procedure Process_ISAG_Reminder(aJobId in number, aDateRef in date)
  is
    type tp_LoadDocument is record(
      ID_RECHNUNG     number
    , ACT_DOCUMENT_ID number
    );

    type tp_tbl_LoadDocument is table of tp_LoadDocument;

    tbl_LoadDocument tp_tbl_LoadDocument;
    sqlStatement VARCHAR2(32767);
    strDate          varchar2(20);
  begin
    -- Commit éventuelle transaction avant d'en créer une nouvelle sur ISAG
    commit;
    -- chargement des données à passer à ISAG
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG2', 'LOAD_INVOICE_ADDRESS');

    -- chargement de la table mémoire
    EXECUTE IMMEDIATE
      sqlStatement
      BULK COLLECT INTO tbl_LoadDocument
      USING aJobId;

    -- si aucune de donnée -> on quitte directement
    if tbl_LoadDocument.count = 0 then
      return;
    end if;

    -- création des nouvelles adresses des factures
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG2', 'INSERT_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));

    -- remplacement des paramètres
    select to_char(round(aDateRef - to_date('01.01.1900', 'DD.MM.YYYY'), 5) )
      into strDate
      from dual;

    sqlStatement := Replace(sqlStatement, ':DATEREF', strDate);
    sqlStatement := Replace(sqlStatement, ':ID_SWSystem', '101');
    sqlStatement := Replace(sqlStatement, ':InfoparamBez', ''''|| pcs.pc_config.GetConfig('ACI_ISAG_ADDRESS_INFOPARAM') ||'''');
    sqlStatement := Replace(sqlStatement, ':ACT_JOB_ID', aJobId);

    -- insertion des données
    for i in tbl_LoadDocument.first .. tbl_LoadDocument.last loop
      -- execution de la commande
      EXECUTE IMMEDIATE
        sqlStatement
        USING tbl_LoadDocument(i).ID_RECHNUNG,
              tbl_LoadDocument(i).ACT_DOCUMENT_ID;

      commit;
    end loop;

    -- recherche l'adresse formattée et chargement de ACI_ISAG_ADDRESS
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG2', 'GET_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));

    -- execution de la commande
    EXECUTE IMMEDIATE
      sqlStatement
      USING aJobId;

    commit;
    -- màj des documents
    sqlStatement := pcs.pc_functions.GetSql('ACI_CONVERSION', 'ACI_ISAG2', 'UPDATE_INVOICE_ADDRESS');
    -- remplacement du nom du DB_LINK
    sqlStatement := Replace(sqlStatement, '[ISAG_DB_LINK]', pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK'));

    -- execution de la commande màj du document
    EXECUTE IMMEDIATE
      sqlStatement
      USING aJobId;

    commit;
  end Process_ISAG_Reminder;

  procedure ACS_AUXILIARY_ACC_SUP(pAcsAuxiliaryAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type)
  is
    vSqlISAG VARCHAR2(32767);
    vIDSubject     PAC_PERSON.PER_KEY1%type;
    vMandant       varchar2(20);
    vIDSWSystem    varchar2(3);
    vDatum         varchar2(10);
    vErpID1        varchar2(12);
    vIDSystemrolle varchar2(4);
    vStatus        varchar2(1);
  begin
    -- Ecriture dans ERPAdressqueue avec les valeurs suivantes :
    --   ID_Subjekt : PER_KEY1
    --   Mandant : 'Société' (MAS_F)
    --   ID_SWSystem : 101
    --   Datum : A_DATECRE du compte auxiliaire
    --   ERP_ID1 : PAC_SUPPLIER_PARTNER_ID
    --   ID_Systemrolle : 6003 pour SUP
    --   Status : 1
    select PER.PER_KEY1 IDSubject
         , pcs.PC_LIB_SESSION.GetCompanyOwner Mandant
         , '101' IDSWSystem
         , to_char(AUX.A_DATECRE, 'DD.MM.YYYY') Datum
         , to_char(SUP.PAC_SUPPLIER_PARTNER_ID) ErpID1
         , '6003' IDSystemrolle
         , '1' Status
      into vIDSubject
         , vMandant
         , vIDSWSystem
         , vDatum
         , vErpID1
         , vIDSystemrolle
         , vStatus
      from PAC_PERSON PER
         , PAC_SUPPLIER_PARTNER SUP
         , ACS_AUXILIARY_ACCOUNT AUX
     where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
       and AUX.ACS_AUXILIARY_ACCOUNT_ID = pAcsAuxiliaryAccountId;

    vSqlISAG  :=
      'INSERT INTO "ERPAdressqueue"@'|| pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') ||
      ' ("ID_Subjekt","Mandant","ID_SWSystem","Datum",ERP_ID1","ID_Systemrolle","Status") values(' ||
      vIDSubject ||
      ',''' ||
      vMandant ||
      ''',' ||
      vIDSWSystem ||
      ',' ||
      vDatum ||
      ',' ||
      vErpID1 ||
      ',' ||
      vIDSystemrolle ||
      ',' ||
      vStatus ||
      ')';

    begin
      EXECUTE IMMEDIATE vSqlISAG;
    exception
      when OTHERS then
        raise_application_error(-20000, sqlerrm || Chr(10) || vSqlISAG);
    end;
  end ACS_AUXILIARY_ACC_SUP;

  procedure ACS_AUXILIARY_ACC_CUS(pAcsAuxiliaryAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type)
  is
    vSqlISAG       VARCHAR2(32767);
    vIDSubject     PAC_PERSON.PER_KEY1%type;
    vMandant       varchar2(20);
    vIDSWSystem    varchar2(3);
    vDatum         varchar2(10);
    vErpID1        varchar2(12);
    vIDSystemrolle varchar2(4);
    vStatus        varchar2(1);
  begin
    -- Ecriture dans ERPAdressqueue avec les valeurs suivantes :
    --   ID_Subjekt : PER_KEY1
    --   Mandant : 'Société' (MAS_F)
    --   ID_SWSystem : 101
    --   Datum : A_DATECRE du compte auxiliaire
    --   ERP_ID1 : PAC_CUSTOM_PARTNER_ID
    --   ID_Systemrolle : 6001 pour CUS
    --   Status : 1
    select PER.PER_KEY1 IDSubject
         , pcs.PC_LIB_SESSION.GetCompanyOwner Mandant
         , '101' IDSWSystem
         , to_char(AUX.A_DATECRE, 'DD.MM.YYYY') Datum
         , to_char(CUS.PAC_CUSTOM_PARTNER_ID) ErpID1
         , '6001' IDSystemrolle
         , '1' Status
      into vIDSubject
         , vMandant
         , vIDSWSystem
         , vDatum
         , vErpID1
         , vIDSystemrolle
         , vStatus
      from PAC_PERSON PER
         , PAC_CUSTOM_PARTNER CUS
         , ACS_AUXILIARY_ACCOUNT AUX
     where PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
       and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
       and AUX.ACS_AUXILIARY_ACCOUNT_ID = pAcsAuxiliaryAccountId;

    vSqlISAG  :=
      'INSERT INTO "ERPAdressqueue"@'|| pcs.pc_config.GetConfig('ACI_ISAG_DB_LINK') ||
      ' ("ID_Subjekt","Mandant","ID_SWSystem","Datum",ERP_ID1","ID_Systemrolle","Status") values(' ||
      vIDSubject ||
      ',''' ||
      vMandant ||
      ''',' ||
      vIDSWSystem ||
      ',' ||
      vDatum ||
      ',' ||
      vErpID1 ||
      ',' ||
      vIDSystemrolle ||
      ',' ||
      vStatus ||
      ')';

    begin
      EXECUTE IMMEDIATE vSqlISAG;
    exception
      when OTHERS then
        raise_application_error(-20000, sqlerrm || Chr(10) || vSqlISAG);
    end;
  end ACS_AUXILIARY_ACC_CUS;

  procedure CTRL_RECHNUNG_STORNO
  is
    vACJ_CAT_RECH_ID   number;
    vACJ_CAT_STORNO_ID number;
    vDbLink            varchar2(100);
    vInsertSql VARCHAR2(32767);
  begin
    --Récupération des paramètres de société
    for tplParams in (select ACJ_CAT_DOC_RECH_ID
                           , ACJ_CAT_DOC_STORNO_ID
                           , CTR_DB_LINK
                        from ACI_ISAG_CTRL_PARAM) loop
      vACJ_CAT_RECH_ID    := tplParams.ACJ_CAT_DOC_RECH_ID;
      vACJ_CAT_STORNO_ID  := tplParams.ACJ_CAT_DOC_STORNO_ID;
      vDbLink             := tplParams.CTR_DB_LINK;

      if    vACJ_CAT_RECH_ID is null
         or vACJ_CAT_STORNO_ID is null
         or vDbLink is null then
        raise_application_error(-20090, 'PCS - Les paramètres ACT_JOB_ID et/ou DB_LINK sont manquants');
      end if;

      --Insertion dans la table ACI_ISAG_CTRL_RECHNUNG
      delete ACI_ISAG_CTRL_RECHNUNG;

      commit;

      delete ACI_ISAG_CTRL_STORNO;

      commit;

      delete ACI_ISAG_CTRL_TABLE;

      commit;
      vInsertSql :=
        'INSERT INTO ACI_ISAG_CTRL_RECHNUNG' ||
        '(ID_RECHNUNG,BELEGNUMMER) select "ID_Rechnung" , "Belegnummer"' ||
        'FROM V_ERP_Rechnung@' ||
        vDbLink;

      begin
        EXECUTE IMMEDIATE vInsertSql;
      exception
        when OTHERS then
          raise_application_error(-20010, sqlerrm || Chr(10) || vInsertSql);
          commit;
      end;

      vInsertSql :=
        'INSERT INTO ACI_ISAG_CTRL_STORNO' ||
        '(ID_RECHNUNG,BELEGNUMMER) select "ID_Rechnung" , "Belegnummer"' ||
        'FROM V_ERP_Storno@' ||
        vDbLink;

      begin
        EXECUTE IMMEDIATE vInsertSql;
      exception
        when OTHERS then
          raise_application_error(-20020, sqlerrm || Chr(10) || vInsertSql);
          commit;
      end;

      --Erreur 1 : Factures n'étant pas dans IS-E (aucun ID_Rechnung)
      begin
        insert into ACI_ISAG_CTRL_TABLE
                   (ACT_DOCUMENT_ID
                  , DOC_NUMBER
                  , PAR_DOCUMENT
                  , ID_RECHNUNG
                  , ID_STORNO
                  , BELEGNUMMER
                  , FYE_NO_EXERCICE
                  , PER_NO_PERIOD
                  , PMT
                  , TYP_ERR
                    )
          select DOC.ACT_DOCUMENT_ID
               , DOC.DOC_NUMBER
               , PAR.PAR_DOCUMENT
               , null
               , null
               , null
               , (select YEA.FYE_NO_EXERCICE
                    from ACS_FINANCIAL_YEAR YEA
                   where ACS_FINANCIAL_YEAR_ID = (select min(IMP.IMF_ACS_FINANCIAL_YEAR_ID)
                                                    from ACT_FINANCIAL_IMPUTATION IMP
                                                   where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID) ) FYE_NO_EXERCICE
               , (select PER.PER_NO_PERIOD
                    from ACS_PERIOD PER
                   where PER.ACS_PERIOD_ID = (select min(IMP.ACS_PERIOD_ID)
                                                from ACT_FINANCIAL_IMPUTATION IMP
                                               where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID) ) PER_NO_PERIOD
               , case
                   when (select   sum(act_functions.totalpayment(ACT_EXPIRY_ID, 1) ) TOT_PAYMENT
                             from ACT_EXPIRY
                            where ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                         group by ACT_DOCUMENT_ID) = 0 then 0
                   else 1
                 end PMT
               , 1
            from ACT_DOCUMENT DOC
               , ACT_PART_IMPUTATION PAR
               , ACI_ISAG_CTRL_RECHNUNG ISR
           where DOC.ACJ_CATALOGUE_DOCUMENT_ID = vACJ_CAT_RECH_ID
             and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
             and PAR.PAR_DOCUMENT = ISR.ID_RECHNUNG(+)
             and PAR.PAR_DOCUMENT not like '%-X'
             and ISR.ID_RECHNUNG is null;
      exception
        when OTHERS then
          raise_application_error(-20030, sqlerrm);
          commit;
      end;

      --Erreur 2 : Facture existante dans ISE mais à double dans PCS
      begin
        insert into ACI_ISAG_CTRL_TABLE
                    (ACT_DOCUMENT_ID
                   , DOC_NUMBER
                   , PAR_DOCUMENT
                   , ID_RECHNUNG
                   , ID_STORNO
                   , BELEGNUMMER
                   , FYE_NO_EXERCICE
                   , PER_NO_PERIOD
                   , PMT
                   , TYP_ERR
                    )
          select DOC.ACT_DOCUMENT_ID
               , DOC.DOC_NUMBER
               , PAR.PAR_DOCUMENT
               , null
               , null
               , null
               , (select YEA.FYE_NO_EXERCICE
                    from ACS_FINANCIAL_YEAR YEA
                   where YEA.ACS_FINANCIAL_YEAR_ID = (select min(IMP.IMF_ACS_FINANCIAL_YEAR_ID)
                                                        from ACT_FINANCIAL_IMPUTATION IMP
                                                       where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID) )
                                                                                                        FYE_NO_EXERCICE
               , (select PER.PER_NO_PERIOD
                    from ACS_PERIOD PER
                   where ACS_PERIOD_ID = (select min(FIN.ACS_PERIOD_ID)
                                            from ACT_FINANCIAL_IMPUTATION FIN
                                           where FIN.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID) ) PER_NO_PERIOD
               , case
                   when (select   sum(act_functions.totalpayment(ACT_EXPIRY_ID, 1) ) TOT_PAYMENT
                             from ACT_EXPIRY
                            where ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                         group by ACT_DOCUMENT_ID) = 0 then 0
                   else 1
                 end PMT
               , 2
            from ACT_DOCUMENT DOC
               , ACT_PART_IMPUTATION PAR
               , ACI_ISAG_CTRL_RECHNUNG ISR
           where DOC.ACJ_CATALOGUE_DOCUMENT_ID = vACJ_CAT_RECH_ID
             and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
             and PAR.PAR_DOCUMENT = to_char(ISR.ID_RECHNUNG)
             and ISR.ID_RECHNUNG is not null
             and PAR.PAR_DOCUMENT not like '%-X'
             and DOC.DOC_NUMBER <> trim(to_char(ISR.BELEGNUMMER, '0000000000') );
      exception
        when OTHERS then
          raise_application_error(-20040, sqlerrm);
          commit;
      end;

      --Erreur 3: Facture extournée dans IS-E mais pas d'extourne dans PCS
      begin
        insert into ACI_ISAG_CTRL_TABLE
                    (ACT_DOCUMENT_ID
                   , DOC_NUMBER
                   , PAR_DOCUMENT
                   , ID_RECHNUNG
                   , ID_STORNO
                   , BELEGNUMMER
                   , FYE_NO_EXERCICE
                   , PER_NO_PERIOD
                   , PMT
                   , TYP_ERR
                    )
          select DET.ACT_DOCUMENT_ID
               , null
               , DET.PAR_DOCUMENT
               , null
               , trim(to_char(DET.ID_RECHNUNG) ) || '-X'
               , DET.BELEGNUMMER
               , null
               , null
               , null
               , 3
            from (select ISS.ID_RECHNUNG
                       , ISS.BELEGNUMMER
                       , (select min(PAR.ACT_DOCUMENT_ID)
                            from ACT_PART_IMPUTATION PAR
                           where PAR.PAR_DOCUMENT = trim(to_char(ISS.ID_RECHNUNG) ) ) ACT_DOCUMENT_ID
                       , (select min(DOC.DOC_NUMBER)
                            from ACT_DOCUMENT DOC
                           where DOC.DOC_NUMBER = trim(to_char(ISS.BELEGNUMMER, '0000000000') )
                             and DOC.ACJ_CATALOGUE_DOCUMENT_ID = vACJ_CAT_STORNO_ID) DOC_NUMBER
                       , (select min(PAR.PAR_DOCUMENT)
                            from ACT_PART_IMPUTATION PAR
                           where PAR.PAR_DOCUMENT = trim(to_char(ISS.ID_RECHNUNG) ) || '-X') PAR_DOCUMENT
                    from ACI_ISAG_CTRL_STORNO ISS
                   where ISS.BELEGNUMMER <> 0) DET
           where DET.DOC_NUMBER is null;
      exception
        when OTHERS then
          raise_application_error(-20050, sqlerrm);
          commit;
      end;

      commit;
    end loop;
  end CTRL_RECHNUNG_STORNO;

END ACI_ISAG;
