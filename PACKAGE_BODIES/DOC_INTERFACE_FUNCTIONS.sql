--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_FUNCTIONS" 
is
  /**
  *  procedure CreateNeedProject
  *  Description
  *    Création d'un tuple dans la table DOC_INTERFACE pour la reprise des données "Besoin affaire" GALEi
  */
  procedure CreateNeedProject(
    aInterfaceNumber in DOC_INTERFACE.DOI_NUMBER%type
  , aRecordID        in DOC_INTERFACE.DOC_RECORD_ID%type
  , aReference       in DOC_INTERFACE.DOI_REFERENCE%type
  , aPartnerRef      in DOC_INTERFACE.DOI_PARTNER_REFERENCE%type
  , aHeadingText     in DOC_INTERFACE.DOI_HEADING_TEXT%type
  , aDocumentText    in DOC_INTERFACE.DOI_DOCUMENT_TEXT%type
  )
  is
    vGaugeID DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    -- On vérifie que les variables d'environement soient initialisées avant de lancer la création
    if PCS.PC_I_LIB_SESSION.GetUserId is not null then
      -- Recherche le gabarit contenu dans la config GAL_GAUGE_NEED_PROJECT
      select max(DOC_GAUGE_ID)
        into vGaugeID
        from DOC_GAUGE
       where GAU_DESCRIBE = PCS.PC_CONFIG.GetConfig('GAL_GAUGE_NEED_PROJECT');

      -- ID du gabarit de la config a été trouvé
      if vGaugeID is not null then
        insert into DOC_INTERFACE
                    (DOC_INTERFACE_ID
                   , DOI_NUMBER
                   , DMT_NUMBER
                   , C_DOC_INTERFACE_ORIGIN
                   , C_DOI_INTERFACE_STATUS
                   , DOC_GAUGE_ID
                   , DOC_RECORD_ID
                   , DOI_REFERENCE
                   , DOI_PARTNER_REFERENCE
                   , DOI_HEADING_TEXT
                   , DOI_DOCUMENT_TEXT
                   , PC_USER_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , aInterfaceNumber
               , aInterfaceNumber
               , '006'
               , '02'
               , vGaugeID
               , aRecordID
               , aReference
               , aPartnerRef
               , aHeadingText
               , aDocumentText
               , PCS.PC_I_LIB_SESSION.GetUserId
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from dual;
      end if;
    end if;
  end CreateNeedProject;

  /**
  *  procedure CreateNeedProjectPos
  *  Description
  *    Création d'un tuple dans la table DOC_INTERFACE_POSITION pour la reprise des données "Besoin affaire" GALEi
  */
  procedure CreateNeedProjectPos(
    aInterfaceNumber in DOC_INTERFACE.DOI_NUMBER%type
  , aGoodID          in DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
  , aQuantity        in DOC_INTERFACE_POSITION.DOP_QTY%type
  , aDelay           in DOC_INTERFACE_POSITION.DOP_BASIS_DELAY%type
  )
  is
  begin
    -- On vérifie que les variables d'environement soient initialisées avant de lancer la création
    if PCS.PC_I_LIB_SESSION.GetUserId is not null then
      insert into DOC_INTERFACE_POSITION
                  (DOC_INTERFACE_POSITION_ID
                 , DOC_INTERFACE_ID
                 , C_DOP_INTERFACE_STATUS
                 , DOC_GAUGE_ID
                 , GCO_GOOD_ID
                 , DOP_QTY
                 , DOP_BASIS_DELAY
                 , DOP_INTERMEDIATE_DELAY
                 , DOP_FINAL_DELAY
                 , C_GAUGE_TYPE_POS
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , DOC_INTERFACE_ID
             , '02'
             , DOC_GAUGE_ID
             , aGoodID
             , aQuantity
             , aDelay
             , aDelay
             , aDelay
             , '1'
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_INTERFACE
         where DOI_NUMBER = aInterfaceNumber;
    end if;
  end CreateNeedProjectPos;

  /**
  * procedure resolvepositionStrings
  * Description
  *   Résolution des string en ID pour tout une position DOC_INTERFACE_POSITION
  * @created fp 25.10.2005
  * @lastUpdate
  * @public
  * @param aInterfaceId : id de l'interface à traîter
  * @param aThirdId : id du tiers
  * @param out aErrorFlag : 0 ->ok  / 1->problème
  * @param out aErrorMemo : description de ou des erreurs
  */
  procedure resolvePositionStrings(
    aInterfaceId in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , aThirdId            DOC_INTERFACE.PAC_THIRD_ID%type
  , aErrorFlag   in out number
  , aErrorMemo   out    varchar2
  )
  is
    cursor crPositions(aInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select *
        from DOC_INTERFACE_POSITION
       where DOC_INTERFACE_ID = aInterfaceId;

    vResult number(1) := 1;
  begin
    for tplPosition in crPositions(aInterfaceId) loop
      declare
        vUpdate    boolean   := false;
        vErrorFlag number(1) := 0;
      begin
        tplPosition.DOP_ERROR          := 0;
        tplPosition.DOP_ERROR_MESSAGE  := '';

        -- résolution de l'id du gabarit
        if tplPosition.DOC_GAUGE_ID is null then
          if tplPosition.GAU_DESCRIBE is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select DOC_GAUGE_ID
                into tplPosition.DOC_GAUGE_ID
                from DOC_GAUGE
               where GAU_DESCRIBE = tplPosition.GAU_DESCRIBE;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- recherche du dossier
        if tplPosition.DOC_RECORD_ID is null then
          if tplPosition.DOP_RCO_TITLE is not null then
            begin
              vUpdate  := true;

              select DOC_RECORD_ID
                into tplPosition.DOC_RECORD_ID
                from DOC_RECORD
               where RCO_TITLE = tplPosition.DOP_RCO_TITLE;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          elsif tplPosition.DOP_RCO_NUMBER is not null then
            begin
              vUpdate  := true;

              select DOC_RECORD_ID
                into tplPosition.DOC_RECORD_ID
                from DOC_RECORD
               where RCO_NUMBER = tplPosition.DOP_RCO_NUMBER;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- recherche du représentant
        if tplPosition.PAC_REPRESENTATIVE_ID is null then
          if tplPosition.DOP_REP_DESCR is not null then
            begin
              vUpdate  := true;

              select PAC_REPRESENTATIVE_ID
                into tplPosition.PAC_REPRESENTATIVE_ID
                from PAC_REPRESENTATIVE
               where REP_DESCR = tplPosition.DOP_REP_DESCR;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution de l'id du bien
        if tplPosition.GCO_GOOD_ID is null then
          if tplPosition.DOP_MAJOR_REFERENCE is not null then
            begin
              vUpdate  := true;

              -- recherche selon la référence principale
              select GCO_GOOD_ID
                into tplPosition.GCO_GOOD_ID
                from GCO_GOOD
               where GOO_MAJOR_REFERENCE = tplPosition.DOP_MAJOR_REFERENCE;
            exception
              when no_data_found then
                begin
                  -- recherche selon les données complémentaires d'achat du fournisseur
                  select GCO_GOOD_ID
                    into tplPosition.GCO_GOOD_ID
                    from GCO_COMPL_DATA_PURCHASE
                   where CDA_COMPLEMENTARY_REFERENCE = tplPosition.DOP_MAJOR_REFERENCE
                     and PAC_SUPPLIER_PARTNER_ID = aThirdId;
                exception
                  when no_data_found then
                    begin
                      -- recherche selon les données complémentaires d'achat générales
                      select GCO_GOOD_ID
                        into tplPosition.GCO_GOOD_ID
                        from GCO_COMPL_DATA_PURCHASE
                       where CDA_COMPLEMENTARY_REFERENCE = tplPosition.DOP_MAJOR_REFERENCE
                         and PAC_SUPPLIER_PARTNER_ID is null;
                    exception
                      when no_data_found then
                        aErrorFlag             := 1;
                        vErrorFlag             := 1;
                        tplPosition.DOP_ERROR  := 1;
                      when too_many_rows then
                        aErrorFlag             := 1;
                        vErrorFlag             := 1;
                        tplPosition.DOP_ERROR  := 1;
                    end;
                  when too_many_rows then
                    aErrorFlag             := 1;
                    tplPosition.DOP_ERROR  := 1;
                end;
            end;
          elsif tplPosition.DOP_SECONDARY_REFERENCE is not null then
            begin
              vUpdate  := true;

              -- recherche selon la référence principale
              select GCO_GOOD_ID
                into tplPosition.GCO_GOOD_ID
                from GCO_GOOD
               where GOO_SECONDARY_REFERENCE = tplPosition.DOP_SECONDARY_REFERENCE;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution du code taxe
        if tplPosition.ACS_TAX_CODE_ID is null then
          if tplPosition.DOP_TAX_CODE_DESCR is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select ACS_TAX_CODE_ID
                into tplPosition.ACS_TAX_CODE_ID
                from ACS_TAX_CODE TAX
                   , ACS_ACCOUNT ACC
               where TAX.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID
                 and ACC.ACC_NUMBER = tplPosition.DOP_TAX_CODE_DESCR;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution de l'emplacement
        if tplPosition.STM_LOCATION_ID is null then
          if tplPosition.DOP_LOC_DESCRIPTION1 is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select STM_LOCATION_ID
                   , nvl(tplPosition.STM_STOCK_ID, STM_STOCK_ID)
                into tplPosition.STM_LOCATION_ID
                   , tplPosition.STM_STOCK_ID
                from STM_LOCATION
               where LOC_DESCRIPTION = tplPosition.DOP_LOC_DESCRIPTION1;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution du stock
        if tplPosition.STM_STOCK_ID is null then
          if tplPosition.STM_LOCATION_ID is not null then
            vUpdate  := true;

            -- recherche selon l'emplacement
            select STM_STOCK_ID
              into tplPosition.STM_STOCK_ID
              from STM_LOCATION
             where STM_LOCATION_ID = tplPosition.STM_LOCATION_ID;
          elsif tplPosition.DOP_STO_DESCRIPTION1 is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select STM_STOCK_ID
                into tplPosition.STM_STOCK_ID
                from STM_STOCK
               where STO_DESCRIPTION = tplPosition.DOP_STO_DESCRIPTION1;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution de l'emplacement
        if tplPosition.STM_STM_LOCATION_ID is null then
          if tplPosition.DOP_LOC_DESCRIPTION2 is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select STM_LOCATION_ID
                   , nvl(tplPosition.STM_STM_STOCK_ID, STM_STOCK_ID)
                into tplPosition.STM_STM_LOCATION_ID
                   , tplPosition.STM_STM_STOCK_ID
                from STM_LOCATION
               where LOC_DESCRIPTION = tplPosition.DOP_LOC_DESCRIPTION2;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- résolution du stock
        if tplPosition.STM_STM_STOCK_ID is null then
          if tplPosition.STM_STM_LOCATION_ID is not null then
            vUpdate  := true;

            -- recherche selon l'emplacement
            select STM_STOCK_ID
              into tplPosition.STM_STM_STOCK_ID
              from STM_LOCATION
             where STM_LOCATION_ID = tplPosition.STM_STM_LOCATION_ID;
          elsif tplPosition.DOP_STO_DESCRIPTION2 is not null then
            begin
              vUpdate  := true;

              -- recherche selon la description
              select STM_STOCK_ID
                into tplPosition.STM_STM_STOCK_ID
                from STM_STOCK
               where STO_DESCRIPTION = tplPosition.DOP_STO_DESCRIPTION2;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- recherche du document parent
        if tplPosition.DOC_DOCUMENT_ID is null then
          if tplPosition.DOP_FATHER_DMT_NUMBER is not null then
            begin
              vUpdate  := true;

              select DOC_DOCUMENT_ID
                into tplPosition.DOC_DOCUMENT_ID
                from DOC_DOCUMENT
               where DMT_NUMBER = tplPosition.DOP_FATHER_DMT_NUMBER;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- recherche position parent
        if tplPosition.DOC_POSITION_ID is null then
          if     tplPosition.DOP_FATHER_POS_NUMBER is not null
             and tplPosition.DOC_DOCUMENT_ID is not null then
            begin
              vUpdate  := true;

              -- recherche de la position du parent selon id document et pos_number
              select DOC_POSITION_ID
                into tplPosition.DOC_POSITION_ID
                from DOC_POSITION
               where DOC_DOCUMENT_ID = tplPosition.DOC_DOCUMENT_ID
                 and POS_NUMBER = tplPosition.DOP_FATHER_POS_NUMBER;
            exception
              when no_data_found then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
              when too_many_rows then
                aErrorFlag             := 1;
                vErrorFlag             := 1;
                tplPosition.DOP_ERROR  := 1;
            end;
          end if;
        end if;

        -- si au moins une mise à jour, update du record dans DOC_INTERFACE_POSITION
        if vUpdate then
          update DOC_INTERFACE_POSITION
             set GCO_GOOD_ID = tplPosition.GCO_GOOD_ID
               , DOC_GAUGE_ID = tplPosition.DOC_GAUGE_ID
               , DOC_RECORD_ID = tplPosition.DOC_RECORD_ID
               , PAC_REPRESENTATIVE_ID = tplPosition.PAC_REPRESENTATIVE_ID
               , ACS_TAX_CODE_ID = tplPosition.ACS_TAX_CODE_ID
               , STM_STOCK_ID = tplPosition.STM_STOCK_ID
               , STM_LOCATION_ID = tplPosition.STM_LOCATION_ID
               , STM_STM_STOCK_ID = tplPosition.STM_STM_STOCK_ID
               , STM_STM_LOCATION_ID = tplPosition.STM_STM_LOCATION_ID
               , DOC_DOCUMENT_ID = tplPosition.DOC_DOCUMENT_ID
               , DOC_POSITION_ID = tplPosition.DOC_POSITION_ID
               , DOP_ERROR = tplPosition.DOP_ERROR
               , DOP_ERROR_MESSAGE = tplPosition.DOP_ERROR_MESSAGE
               , C_GAUGE_TYPE_POS = nvl(tplPosition.C_GAUGE_TYPE_POS, '1')
               , C_DOP_INTERFACE_STATUS = decode(vErrorFlag, 0, '02', C_DOP_INTERFACE_STATUS)
           where DOC_INTERFACE_POSITION_ID = tplPosition.DOC_INTERFACE_POSITION_ID;
        end if;
      end;
    end loop;
  end resolvePositionStrings;

  /**
  * Description
  *   Résolution des string en ID pour tout un document DOC_INTERFACE
  */
  procedure resolveStrings(aInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type, aErrorFlag out number, aErrorMemo out varchar2)
  is
    vResult      number(1)               := 1;
    tplInterface DOC_INTERFACE%rowtype;
    vUpdate      boolean                 := false;
  begin
    -- initialisation
    aErrorFlag  := 0;

    -- recherche du tuple d'interface
    select *
      into tplInterface
      from DOC_INTERFACE
     where DOC_INTERFACE_ID = aInterfaceId;

    -- recherche du dossier
    if tplInterface.DOC_GAUGE_ID is null then
      if tplInterface.DOI_GAU_DESCRIBE is not null then
        begin
          vUpdate  := true;

          select DOC_GAUGE_ID
            into tplInterface.DOC_GAUGE_ID
            from DOC_GAUGE
           where GAU_DESCRIBE = tplInterface.DOI_GAU_DESCRIBE;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
/*
      else
        begin
          vUpdate  := true;

          select DOC_GAUGE_ID
            into tplInterface.DOC_GAUGE_ID
            from DOC_GAUGE
           where GAU_MAT_DOC_DEFAULT = 1;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
*/
      end if;
    end if;

    -- recherche du tiers
    if tplInterface.PAC_THIRD_ID is null then
      if tplInterface.DOI_PER_NAME is not null then
        begin
          vUpdate  := true;

          select PAC_PERSON_ID
            into tplInterface.PAC_THIRD_ID
            from PAC_PERSON
           where PER_NAME = tplInterface.DOI_PER_NAME;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      elsif tplInterface.DOI_PER_SHORT_NAME is not null then
        begin
          vUpdate  := true;

          select PAC_PERSON_ID
            into tplInterface.PAC_THIRD_ID
            from PAC_PERSON
           where PER_SHORT_NAME = tplInterface.DOI_PER_SHORT_NAME;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      elsif tplInterface.DOI_PER_KEY1 is not null then
        begin
          vUpdate  := true;

          select PAC_PERSON_ID
            into tplInterface.PAC_THIRD_ID
            from PAC_PERSON
           where PER_KEY1 = tplInterface.DOI_PER_KEY1;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      elsif tplInterface.DOI_PER_KEY2 is not null then
        begin
          vUpdate  := true;

          select PAC_PERSON_ID
            into tplInterface.PAC_THIRD_ID
            from PAC_PERSON
           where PER_KEY2 = tplInterface.DOI_PER_KEY2;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du représentant
    if tplInterface.DOC_DOCUMENT_ID is null then
      if tplInterface.DMT_NUMBER is not null then
        begin
          vUpdate  := true;

          select DOC_DOCUMENT_ID
            into tplInterface.DOC_DOCUMENT_ID
            from DOC_DOCUMENT
           where DMT_NUMBER = tplInterface.DMT_NUMBER;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du dossier
    if tplInterface.DOC_RECORD_ID is null then
      if tplInterface.DOI_RCO_TITLE is not null then
        begin
          vUpdate  := true;

          select DOC_RECORD_ID
            into tplInterface.DOC_RECORD_ID
            from DOC_RECORD
           where RCO_TITLE = tplInterface.DOI_RCO_TITLE;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      elsif tplInterface.DOI_RCO_NUMBER is not null then
        begin
          vUpdate  := true;

          select DOC_RECORD_ID
            into tplInterface.DOC_RECORD_ID
            from DOC_RECORD
           where RCO_NUMBER = tplInterface.DOI_RCO_NUMBER;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du représentant
    if tplInterface.PAC_REPRESENTATIVE_ID is null then
      if tplInterface.DOI_REP_DESCR is not null then
        begin
          vUpdate  := true;

          select PAC_REPRESENTATIVE_ID
            into tplInterface.PAC_REPRESENTATIVE_ID
            from PAC_REPRESENTATIVE
           where REP_DESCR = tplInterface.DOI_REP_DESCR;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche de la condition de livraison
    if tplInterface.PAC_SENDING_CONDITION_ID is null then
      if tplInterface.DOI_SEN_KEY is not null then
        begin
          vUpdate  := true;

          select PAC_SENDING_CONDITION_ID
            into tplInterface.PAC_SENDING_CONDITION_ID
            from PAC_SENDING_CONDITION
           where SEN_KEY = tplInterface.DOI_SEN_KEY;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche de la condition de paiement
    if tplInterface.PAC_PAYMENT_CONDITION_ID is null then
      if tplInterface.DOI_PCO_DESCR is not null then
        begin
          vUpdate  := true;

          select PAC_PAYMENT_CONDITION_ID
            into tplInterface.PAC_PAYMENT_CONDITION_ID
            from PAC_PAYMENT_CONDITION
           where PCO_DESCR = tplInterface.DOI_PCO_DESCR;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du code TVA
    if tplInterface.ACS_VAT_DET_ACCOUNT_ID is null then
      if tplInterface.DOI_VAT_DET_ACCOUNT_DESCR is not null then
        begin
          vUpdate  := true;

          select ACS_VAT_DET_ACCOUNT_ID
            into tplInterface.ACS_VAT_DET_ACCOUNT_ID
            from ACS_VAT_DET_ACCOUNT VAT
               , ACS_ACCOUNT ACC
           where VAT.ACS_VAT_DET_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
             and ACC_NUMBER = tplInterface.DOI_VAT_DET_ACCOUNT_DESCR;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche de la méthode de paiement
    if tplInterface.ACS_FIN_ACC_S_PAYMENT_ID is null then
      if tplInterface.DOI_FIN_PAYMENT_DESCR is not null then
        vUpdate  := true;

        select min(ACS_FIN_ACC_S_PAYMENT_ID)
          into tplInterface.ACS_FIN_ACC_S_PAYMENT_ID
          from ACS_FIN_ACC_S_PAYMENT ACC
             , ACS_PAYMENT_METHOD MET
             , ACS_DESCRIPTION DES
         where MET.ACS_PAYMENT_METHOD_ID = DES.ACS_PAYMENT_METHOD_ID
           and ACC.ACS_PAYMENT_METHOD_ID = MET.ACS_PAYMENT_METHOD_ID
           and DES.DES_DESCRIPTION_SUMMARY = tplInterface.DOI_FIN_PAYMENT_DESCR;

        if tplInterface.ACS_FIN_ACC_S_PAYMENT_ID is null then
          aErrorFlag              := 1;
          tplInterface.DOI_ERROR  := 1;
        end if;
      end if;
    end if;

    -- recherche de la monnaie
    if tplInterface.ACS_FINANCIAL_CURRENCY_ID is null then
      if tplInterface.DOI_CURRENCY is not null then
        begin
          vUpdate  := true;

          select ACS.ACS_FINANCIAL_CURRENCY_ID
            into tplInterface.ACS_FINANCIAL_CURRENCY_ID
            from ACS_FINANCIAL_CURRENCY ACS
               , PCS.PC_CURR CUR
           where ACS.PC_CURR_ID = CUR.PC_CURR_ID
             and CUR.CURRENCY = tplInterface.DOI_CURRENCY;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche de la langue
    if tplInterface.PC_LANG_ID is null then
      if tplInterface.DOI_LANID is not null then
        begin
          vUpdate  := true;

          select PC_LANG_ID
            into tplInterface.PC_LANG_ID
            from PCS.PC_LANG
           where LANID = tplInterface.DOI_LANID;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du pays
    if tplInterface.PC_CNTRY_ID is null then
      if tplInterface.DOI_CNTID1 is not null then
        begin
          vUpdate  := true;

          select PC_CNTRY_ID
            into tplInterface.PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = tplInterface.DOI_CNTID1;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du pays no2
    if tplInterface.PC__PC_CNTRY_ID is null then
      if tplInterface.DOI_CNTID2 is not null then
        begin
          vUpdate  := true;

          select PC_CNTRY_ID
            into tplInterface.PC__PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = tplInterface.DOI_CNTID2;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- recherche du pays no3
    if tplInterface.PC_2_PC_CNTRY_ID is null then
      if tplInterface.DOI_CNTID3 is not null then
        begin
          vUpdate  := true;

          select PC_CNTRY_ID
            into tplInterface.PC_2_PC_CNTRY_ID
            from PCS.PC_CNTRY
           where CNTID = tplInterface.DOI_CNTID3;
        exception
          when no_data_found then
            aErrorFlag              := 1;
            tplInterface.DOI_ERROR  := 1;
        end;
      end if;
    end if;

    -- résolution des textes des positions de l'interface
    resolvePositionStrings(aInterfaceId, tplInterface.PAC_THIRD_ID, aErrorFlag, aErrorMemo);

    -- si au moins une mise à jour, update du record dans DOC_INTERFACE_POSITION
    if vUpdate then
      update DOC_INTERFACE
         set PAC_THIRD_ID = tplInterface.PAC_THIRD_ID
           , PAC_REPRESENTATIVE_ID = tplInterface.PAC_REPRESENTATIVE_ID
           , PAC_SENDING_CONDITION_ID = tplInterface.PAC_SENDING_CONDITION_ID
           , PAC_PAYMENT_CONDITION_ID = tplInterface.PAC_PAYMENT_CONDITION_ID
           , ACS_FINANCIAL_CURRENCY_ID = tplInterface.ACS_FINANCIAL_CURRENCY_ID
           , ACS_VAT_DET_ACCOUNT_ID = tplInterface.ACS_VAT_DET_ACCOUNT_ID
           , ACS_FIN_ACC_S_PAYMENT_ID = tplInterface.ACS_FIN_ACC_S_PAYMENT_ID
           , DOC_RECORD_ID = tplInterface.DOC_RECORD_ID
           , DOC_DOCUMENT_ID = tplInterface.DOC_DOCUMENT_ID
           , DOC_GAUGE_ID = tplInterface.DOC_GAUGE_ID
           , PC_LANG_ID = tplInterface.PC_LANG_ID
           , PC_CNTRY_ID = tplInterface.PC_CNTRY_ID
           , PC__PC_CNTRY_ID = tplInterface.PC__PC_CNTRY_ID
           , PC_2_PC_CNTRY_ID = tplInterface.PC_2_PC_CNTRY_ID
           , DOI_ERROR = tplInterface.DOI_ERROR
           , DOI_ERROR_MESSAGE = tplInterface.DOI_ERROR_MESSAGE
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.getUserIni
           , C_DOI_INTERFACE_STATUS = decode(aErrorFlag, 0, '02', C_DOI_INTERFACE_STATUS)
           , DOI_PROTECTED = 1
       where DOC_INTERFACE_ID = tplInterface.DOC_INTERFACE_ID;
    end if;
  end resolveStrings;
end DOC_INTERFACE_FUNCTIONS;
