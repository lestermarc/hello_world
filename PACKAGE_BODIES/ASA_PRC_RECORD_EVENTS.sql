--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_EVENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_EVENTS" 
is
  /*
  * Description
  *   G�n�ration de document ( appel de la proc�dure de g�n�ration ASA_RECORD_GENERATE)
  */
  procedure pGenerateDocument(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iTypeGauge    in varchar2
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  , iDocGaugeId   in DOC_GAUGE.DOC_GAUGE_ID%type
  )
  is
    lvErrorMsg    varchar2(4000);
    lDateDocument date;
    lDateValue    date;
    lDateDelivery date;
  begin
    -- Initialisation des valeurs par d�faut
    if iDateDocument is null then
      lDateDocument  := sysdate;
    else
      lDateDocument  := iDateDocument;
    end if;

    if iDateValue is null then
      lDateValue  := sysdate;
    else
      lDateValue  := iDateValue;
    end if;

    if iDateDelivery is null then
      lDateDelivery  := sysdate;
    else
      lDateDelivery  := iDateDelivery;
    end if;

    -- G�n�ration du document
    ASA_RECORD_GENERATE_DOC.GenerateDocuments(aASA_RECORD_ID       => iAsaRecordId
                                            , aTypeGauge           => iTypeGauge
                                            , aDOC_GAUGE_ID        => iDocGaugeId
                                            , aDMT_DATE_DOCUMENT   => lDateDocument
                                            , aDMT_DATE_VALUE      => lDateValue
                                            , aDMT_DATE_DELIVERY   => lDateDelivery
                                            , aAutoNum             => 0
                                            , aGroupedByThird      => 0
                                            , aError               => lvErrorMsg
                                             );

    if lvErrorMsg is not null then
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                        , iv_message       => lvErrorMsg
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'GenerateDoc'
                                         );
    end if;
  end pGenerateDocument;

  /*
  * Description
  *   G�n�ration du document de type 'Offre client'
  */
  procedure pGenerateOffer(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    -- R�cup�ration de donn�es du dossier SAV
    select max(C_ASA_SELECT_PRICE)
      into lCAsaSelectPrice
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordId;

    if     PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_OFFER_GAUGE_NAME2') is not null
       and lCAsaSelectPrice = '2' then
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_OFFER_GAUGE_NAME2');
    else
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_OFFER_GAUGE_NAME');
    end if;

    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyOffer'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateOffer;

  /*
  * Description
  *   G�n�ration du document de type 'Facture relative au frais d'�tablissement du devis'
  */
  procedure pGenerateOfferBill(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig    varchar2(4000);
    lDocGaugeId DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    lvConfig     := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_OFFER_BILL_GAUGE');
    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyOfferBill'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateOfferBill;

  /*
  * Description
  *   G�n�ration du document de type 'Commande Client'
  */
  procedure pGenerateCmdC(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    -- R�cup�ration de donn�es du dossier SAV
    select max(C_ASA_SELECT_PRICE)
      into lCAsaSelectPrice
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordId;

    if     PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_CMDC_GAUGE_NAME2') is not null
       and lCAsaSelectPrice = '2' then
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_CMDC_GAUGE_NAME2');
    else
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_CMDC_GAUGE_NAME');
    end if;

    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyCmdC'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateCmdC;

  /*
  * Description
  *   G�n�ration du document de type 'Commande Fournisseur'
  */
  procedure pGenerateCmdS(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    lvConfig     := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_CMDS_GAUGE_NAME');
    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyCmdS'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateCmdS;

  /*
  * Description
  *   G�n�ration du document de type 'Facture Client'
  */
  procedure pGenerateBill(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    -- R�cup�ration de donn�es du dossier SAV
    select max(C_ASA_SELECT_PRICE)
      into lCAsaSelectPrice
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordId;

    if     PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BILL_GAUGE_NAME2') is not null
       and lCAsaSelectPrice = '2' then
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BILL_GAUGE_NAME2');
    else
      lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BILL_GAUGE_NAME');
    end if;

    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyBill'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateBill;

  /*
  * Description
  *   G�n�ration du document de type 'Notes de cr�dit'
  */
  procedure pGenerateNC(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    lvConfig     := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_NC_GAUGE_NAME');
    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyNC'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateNC;

  /*
  * Description
  *   G�n�ration du document de type 'Bulletin de livraison'
  */
  procedure pGenerateBuLiv(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig         varchar2(4000);
    lDocGaugeId      DOC_GAUGE.DOC_GAUGE_ID%type;
    lCAsaSelectPrice ASA_RECORD.C_ASA_SELECT_PRICE%type;
  begin
    lvConfig     := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BULIV_GAUGE_NAME');
    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig, iGauDescribe);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyBuLiv'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateBuLiv;

  /*
  * Description
  *   G�n�ration du document de type 'Document Attribution'
  */
  procedure pGenerateAttrib(
    iAsaRecordId  in ASA_RECORD.ASA_RECORD_ID%type
  , iGauDescribe  in DOC_GAUGE.GAU_DESCRIBE%type default null
  , iDateDocument in date default null
  , iDateValue    in date default null
  , iDateDelivery in date default null
  )
  is
    lvConfig    varchar2(4000);
    lDocGaugeId DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    lvConfig     := PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_ATTRIB_GAUGE_NAME');
    lDocGaugeId  := ASA_I_LIB_RECORD.getGaugeIdFromConfig(lvConfig);

    if lDocGaugeId > 0 then
      pGenerateDocument(iAsaRecordId    => iAsaRecordId
                      , iTypeGauge      => 'gtyAttrib'
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                      , iDocGaugeId     => lDocGaugeId
                       );
    end if;
  end pGenerateAttrib;

  /*
  * Description
  *   G�n�ration du document
  */
  procedure GenerateDocuments(
    iAsaRecordId       in ASA_RECORD.ASA_RECORD_ID%type
  , iAsaRecordEventsId in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  , iStatus            in ASA_RECORD.C_ASA_REP_STATUS%type
  , iDateDocument      in date default null
  , iDateValue         in date default null
  , iDateDelivery      in date default null
  , iGauDescribe       in DOC_GAUGE.GAU_DESCRIBE%type default null
  )
  is
    -- Donn�es du dossier SAV
    lArePriceDevisMB   ASA_RECORD.ARE_PRICE_DEVIS_MB%type;
    lCAsaRepTypeKind   ASA_RECORD.C_ASA_REP_TYPE_KIND%type;
    lAreGenerateBill   ASA_RECORD.ARE_GENERATE_BILL%type;
    lAreLposCompTask   ASA_RECORD.ARE_LPOS_COMP_TASK%type;
    -- Donn�e de l'�venement
    lAsaRecordEventsId ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type;
    lnCountConfig      number;
    -- gtyOffer     -> offre client
    lbGtyOffer         boolean;
    -- gtyOfferBill -> Facture relative au frais d'�tablissement du devis
    lbGtyOfferBill     boolean;
    -- gtyCmdC      -> Commande Client
    lbGtyCmdC          boolean;
    -- gtyCmdS      -> Commande Fournisseur
    lbGtyCmdS          boolean;
    -- gtyBill      -> Facture Client
    lbGtyBill          boolean;
    -- gtyNC        -> Notes de cr�dit
    lbGtyNC            boolean;
    -- gtyBuLiv     -> Bulletin de livraison
    lbGtyBuLiv         boolean;
    -- gtyAttrib    -> document attribution
    lbGtyAttrib        boolean;
  begin
    -- R�cup�ration des donn�es du dossier SAV
    begin
      select ARE_PRICE_DEVIS_MB
           , C_ASA_REP_TYPE_KIND
           , ARE_GENERATE_BILL
           , ARE_LPOS_COMP_TASK
        into lArePriceDevisMB
           , lCAsaRepTypeKind
           , lAreGenerateBill
           , lAreLposCompTask
        from ASA_RECORD
       where ASA_RECORD_ID = iAsaRecordId;
    exception
      when no_data_found then
        lArePriceDevisMB  := null;
        lCAsaRepTypeKind  := null;
        lAreGenerateBill  := null;
        lAreLposCompTask  := null;
    end;

    -- D�finir en fonction d'une config le traitement
    lbGtyOffer      := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_OFFER_GAUGE_NAME');
    lbGtyOfferBill  := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_OFFER_BILL_GAUGE');
    lbGtyCmdC       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_CMDC_GAUGE_NAME');
    lbGtyCmdS       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_CMDS_GAUGE_NAME');
    lbGtyBill       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_BILL_GAUGE_NAME');
    lbGtyNC         := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_NC_GAUGE_NAME');
    lbGtyAttrib     := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_ATTRIB_GAUGE_NAME');

    -- Si il s'agit d'un facturation pour une offre refus�e, on contr�le
    -- si le montant � facturer est sup�rieur � 0}
    if     lbGtyOfferBill
       and lArePriceDevisMB > 0 then
      pGenerateOfferBill(iAsaRecordId    => iAsaRecordId
                       , iGauDescribe    => iGauDescribe
                       , iDateDocument   => iDateDocument
                       , iDateValue      => iDateValue
                       , iDateDelivery   => iDateDelivery
                        );
    end if;

    -- Si le document � g�n�rer est un document d'attribution mais que l'on ne g�re pas les attributions sur les composants
    -- ou que le dossier de r�paration n'est pas de type r�paration alors on ne g�n�re pas de document }
    if lbGtyAttrib then
      if not(   lCAsaRepTypeKind <> '3'
             or PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_ATTRIB') = 'False') then
        pGenerateAttrib(iAsaRecordId    => iAsaRecordId
                      , iGauDescribe    => iGauDescribe
                      , iDateDocument   => iDateDocument
                      , iDateValue      => iDateValue
                      , iDateDelivery   => iDateDelivery
                       );
      end if;
    end if;

    -- Si le document � g�n�rer est une facture et si la r�paration active a le code
    -- de g�n�ration de facture d�sactiv� (ARE_GENERATE_BILL), alors le type de
    -- document � g�n�rer est un bulletin de livraison}
    if     lbGtyBill
       and lAreGenerateBill = 0
       and PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BULIV_GAUGE_NAME') is not null then
      if lAreLposCompTask = 1 then
        --Contr�le qu'il n'y pas d'option accept�es qui ne sont pas sous garantie
        select count(*)
          into lnCountConfig
          from (select asa_record_id
                  from asa_record_comp
                 where asa_record_id = iAsaRecordId
                   and asa_record_events_id = iAsaRecordEventsId
                   and arc_optional = 1
                   and C_ASA_ACCEPT_OPTION = '2'
                   and arc_guaranty_code = 0
                union
                select asa_record_id
                  from asa_record_task
                 where asa_record_id = iAsaRecordId
                   and asa_record_events_id = iAsaRecordEventsId
                   and ret_optional = 1
                   and C_ASA_ACCEPT_OPTION = '2'
                   and ret_guaranty_code = 0);

        if lnCountConfig = 0 then
          -- si il n'y a pas de facture (garantie) -> g�n�ration d'un bulletin de livraison
          lbGtyBuLiv  := true;
          lbGtyBill   := false;
        end if;
      else
        --si il n'y a pas de facture (garantie) -> g�n�ration d'un bulletin de livraison
        lbGtyBuLiv  := true;
        lbGtyBill   := false;
      end if;
    end if;

    if lbGtyOffer then
      pGenerateOffer(iAsaRecordId    => iAsaRecordId
                   , iGauDescribe    => iGauDescribe
                   , iDateDocument   => iDateDocument
                   , iDateValue      => iDateValue
                   , iDateDelivery   => iDateDelivery
                    );
    end if;

    if lbGtyBill then
      pGenerateBill(iAsaRecordId    => iAsaRecordId
                  , iGauDescribe    => iGauDescribe
                  , iDateDocument   => iDateDocument
                  , iDateValue      => iDateValue
                  , iDateDelivery   => iDateDelivery
                   );
    end if;

    if lbGtyBuLiv then
      pGenerateBuLiv(iAsaRecordId    => iAsaRecordId
                   , iGauDescribe    => iGauDescribe
                   , iDateDocument   => iDateDocument
                   , iDateValue      => iDateValue
                   , iDateDelivery   => iDateDelivery
                    );
    end if;

    if lbGtyCmdC then
      pGenerateCmdC(iAsaRecordId    => iAsaRecordId
                  , iGauDescribe    => iGauDescribe
                  , iDateDocument   => iDateDocument
                  , iDateValue      => iDateValue
                  , iDateDelivery   => iDateDelivery
                   );
    end if;

    if lbGtyCmdS then
      pGenerateCmdS(iAsaRecordId    => iAsaRecordId
                  , iGauDescribe    => iGauDescribe
                  , iDateDocument   => iDateDocument
                  , iDateValue      => iDateValue
                  , iDateDelivery   => iDateDelivery
                   );
    end if;

    if lbGtyNC then
      pGenerateNC(iAsaRecordId    => iAsaRecordId
                , iGauDescribe    => iGauDescribe
                , iDateDocument   => iDateDocument
                , iDateValue      => iDateValue
                , iDateDelivery   => iDateDelivery
                 );
    end if;
  end GenerateDocuments;

  /*
  * Description
  *   G�n�ration d'un ordre de fabrication
  */
  procedure GenerateOF(
    iAsaRecordId     in ASA_RECORD.ASA_RECORD_ID%type
  , iStatus          in ASA_RECORD.C_ASA_REP_STATUS%type
  , iLaunchOF        in number default null
  , iPlanBeginDate   in date default null
  , iFalJobProgramId in FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type default null
  )
  is
    lFalJobProgramId FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
    lFalLot          FAL_LOT.FAL_LOT_ID%type;
    lvErrorMsg       varchar2(4000);
    lnAbordProcess   number(2);
    lbGtyGenOF       boolean;
    lbLaunchOF       boolean;
    ldPlanBeginDate  date;
  begin
    -- D�finir en fonction d'une config si la cr�ation d'un OF doit se faire ou non
    lbGtyGenOF  := ASA_I_LIB_RECORD.isStatusInConfig(iStatus, 'ASA_GENERATE_OF');

    if lbGtyGenOF then
      -- Initialisation des valeurs par g�faut pour la g�n�ration du lot
      if iLaunchOF is null then
        lbLaunchOF  :=(PCS.PC_CONFIG.GetConfig('ASA_LAUNCH_OF') = 'true');
      else
        lbLaunchOF  :=(iLaunchOf = 1);
      end if;

      if iPlanBeginDate is null then
        select ARE_DATE_START_REP
          into ldPlanBeginDate
          from ASA_DELAY_HISTORY
         where ASA_RECORD_ID = iAsaRecordId
           and ADH_SEQ = (select max(ADH_SEQ)
                            from ASA_DELAY_HISTORY
                           where ASA_RECORD_ID = iAsaRecordId);
      else
        ldPlanBeginDate  := iPlanBeginDate;
      end if;

      if iFalJobProgramId is null then
        -- R�cup�ration du programme de fabrication par d�faut dans un context SAV
        lFalJobProgramId  := FWK_I_LIB_ENTITY.getIdfromPk2('FAL_JOB_PROGRAM', 'JOP_SHORT_DESCR', PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_JOB_PROGRAM') );
      else
        lFalJobProgramId  := iFalJobProgramId;
      end if;

      if lFalJobProgramId > 0 then
        -- Cr�ation du lot
        ASA_MANUFACTURING_ORDER.GenerateMO(aASA_RECORD_ID        => iAsaRecordId
                                         , aFAL_JOB_PROGRAM_ID   => lFalJobProgramId
                                         , aBeginDate            => ldPlanBeginDate
                                         , aFAL_LOT_ID           => lFalLot
                                         , aErrorMsg             => lvErrorMsg
                                          );

        if lvErrorMsg is not null then
          FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                            , iv_message       => lvErrorMsg
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'GenerateOF'
                                             );
          lvErrorMsg  := '';
        else
          commit;
        end if;

        -- Lancement du lot
        if     lbLaunchOF
           and lFalLot > 0 then
          -- R�servation du lot
          FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => lFalLot, aLT1_ORACLE_SESSION => DBMS_SESSION.unique_session_id, aErrorMsg => lvErrorMsg);

          if lvErrorMsg is not null then
            FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                              , iv_message       => lvErrorMsg
                                              , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                              , iv_cause         => 'GenerateOF'
                                               );
            lvErrorMsg  := '';
          end if;

          -- Contr�les avant lancement
          FAL_BATCH_LAUNCHING.ControlBeforeLaunch(iSessionId               => ''
                                                , iFalLotId                => lFalLot
                                                , ioMessage                => lvErrorMsg
                                                , ioAbortProcess           => lnAbordProcess
                                                 );

          if lvErrorMsg is not null then
            FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                              , iv_message       => lvErrorMsg
                                              , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                              , iv_cause         => 'GenerateOF'
                                               );
            lvErrorMsg  := '';
          else
            -- Lancement du lot
            FAL_BATCH_LAUNCHING.LaunchBatch(aFalLotId => lFalLot);
          end if;

          -- Release du lot
          FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId => lFalLot);
        end if;
      end if;
    end if;
  end GenerateOF;

  /**
  * procedure CreateRecordEvents
  * Description
  *   Cr�ation d'un �v�nement de flux dans un dossier SAV
  */
  procedure CreateRecordEvents(
    iAsaRecordId      in     ASA_RECORD.ASA_RECORD_ID%type
  , iNewStatus        in     ASA_RECORD_EVENTS.C_ASA_REP_STATUS%type
  , iGenerateOF       in     number default 1
  , iFalJobProgramId  in     FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type default null
  , iLaunchOF         in     number default null
  , iPlanBeginDate    in     date default null
  , iGenerateDocument in     number default 1
  , iDateDocument     in     date default null
  , iDateValue        in     date default null
  , iDateDelivery     in     date default null
  , iGauDescribe      in     DOC_GAUGE.GAU_DESCRIBE%type default null
  , oEventsSeq        out    varchar2
  )
  is
    ltRecordEvents FWK_I_TYP_DEFINITION.t_crud_def;
    lnProtected    ASA_RECORD.ARE_PROTECTED%type;
  begin
    select max(nvl(ARE_PROTECTED, 0) )
      into lnProtected
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordId;

    if lnProtected = 0 then
      -- Cr�ation de l'entit� ASA_RECORD_EVENTS
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordEvents, ltRecordEvents, true);
      -- Init de l'id du dossier SAV
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordEvents, 'ASA_RECORD_ID', iAsaRecordId);
      -- Init du status
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordEvents, 'C_ASA_REP_STATUS', iNewStatus);
      FWK_I_MGT_ENTITY.InsertEntity(ltRecordEvents);

      if iGenerateDocument = 1 then
        -- G�n�ration document
        GenerateDocuments(iAsaRecordId         => iAsaRecordId
                        , iAsaRecordEventsId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecordEvents, 'ASA_RECORD_EVENTS_ID')
                        , iStatus              => iNewStatus
                        , iDateDocument        => iDateDocument
                        , iDateValue           => iDateValue
                        , iDateDelivery        => iDateDelivery
                        , iGauDescribe         => iGauDescribe
                         );
      end if;

      if iGenerateOF = 1 then
        -- G�n�ration OF
        GenerateOF(iAsaRecordId       => iAsaRecordId
                 , iStatus            => iNewStatus
                 , iLaunchOF          => iLaunchOF
                 , iPlanBeginDate     => iPlanBeginDate
                 , iFalJobProgramId   => iFalJobProgramId
                  );
      end if;

      -- Retourner la PK2 de ASA_RECORD_EVENTS cr�e
      oEventsSeq  := to_char(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecordEvents, 'RRE_SEQ') );
      FWK_I_MGT_ENTITY.Release(ltRecordEvents);
    else
      FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                        , iv_message       => PCS.PC_FUNCTIONS.TranslateWord
                                                                                            ('Ce dossier est en attente de r�ception d''un lot de fabrication !')
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateRecordEvents'
                                         );
    end if;
  end CreateRecordEvents;
end ASA_PRC_RECORD_EVENTS;
