--------------------------------------------------------
--  DDL for Package Body DOC_JOURNAL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_JOURNAL_FUNCTIONS" 
as
  /**
  * function MustJournalize
  * Description
  *   Recherche sur le gabarit si le flag "Journaliser le document" est coché
  */
  function MustJournalize(aGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return integer
  is
    intMustJournalize integer;
  begin
    select nvl(max(GAS_DOC_JOURNALIZING), 0)
      into intMustJournalize
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = aGaugeID;

    return intMustJournalize;
  end MustJournalize;

  /**
  * function MustPosJournalize
  * Description
  *   Vérifie si la position doit être journalisée
  *   Les positions journalisées sont celles du type : 1, 7, 8, 10, 81, 91
  */
  function MustPosJournalize(
    aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeID    in DOC_GAUGE.DOC_GAUGE_ID%type
  , aTypePos    in DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type
  , aGapID      in DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type
  , aPTPosID    in DOC_POSITION.DOC_DOC_POSITION_ID%type
  )
    return integer
  is
    vMustPosJournalize integer default 0;
    vContinue          boolean default true;
  begin
    -- On doit vérifier que l'entête du document soit dans la table de journalisation de l'entete
    declare
      vDocID DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    begin
      select DOC_DOCUMENT_ID
        into vDocID
        from DOC_JOURNAL_HEADER
       where DOC_DOCUMENT_ID = aDocumentID;
    exception
      when no_data_found then
        vContinue  := false;
    end;

    -- Recherche sur le gabarit si le flag "Journaliser le document" est coché
    if     (vContinue)
       and (MustJournalize(aGaugeID) = 1) then
      -- Les positions journalisées sont celles du type : 1, 7, 8, 10, 81, 91
      if aTypePos in('7', '8', '10', '81', '91', '21') then
        vMustPosJournalize  := 1;
      elsif aTypePos = 1 then
        if aPTPosID is null then
          vMustPosJournalize  := 1;
        else
          -- Seules les positions composant de type 81 et 91 sont journalisées
          select decode(max(GAP_PT.C_GAUGE_TYPE_POS), '8', 1, '9', 1, 0)
            into vMustPosJournalize
            from DOC_GAUGE_POSITION GAP_CPT
               , DOC_GAUGE_POSITION GAP_PT
           where GAP_CPT.DOC_GAUGE_POSITION_ID = aGapID
             and GAP_CPT.DOC_DOC_GAUGE_POSITION_ID = GAP_PT.DOC_GAUGE_POSITION_ID;
        end if;
      end if;
    end if;

    return vMustPosJournalize;
  end MustPosJournalize;

  function MustPosJournalize(aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return integer
  is
    vMustPosJournalize integer                                         default 0;
    vDocumentID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vGaugeID           DOC_GAUGE.DOC_GAUGE_ID%type;
    vTypePos           DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    vGapID             DOC_GAUGE_POSITION.DOC_GAUGE_POSITION_ID%type;
    vPTPosID           DOC_POSITION.DOC_DOC_POSITION_ID%type;
  begin
    select POS.DOC_DOCUMENT_ID
         , DMT.DOC_GAUGE_ID
         , POS.C_GAUGE_TYPE_POS
         , POS.DOC_GAUGE_POSITION_ID
         , POS.DOC_DOC_POSITION_ID
      into vDocumentID
         , vGaugeID
         , vTypePos
         , vGapID
         , vPTPosID
      from DOC_POSITION POS
         , DOC_DOCUMENT DMT
     where POS.DOC_POSITION_ID = aPositionID
       and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

    vMustPosJournalize  := MustPosJournalize(vDocumentID, vGaugeID, vTypePos, vGapID, vPTPosID);
    return vMustPosJournalize;
  end;

  /**
  * procedure JournalizeDocument
  * Description
  *   Méthode pour journaliser le document
  */
  procedure JournalizeDocument(aCode in varchar2, aOldDoc in DOC_DOCUMENT%rowtype, aNewDoc in DOC_DOCUMENT%rowtype)
  is
    type TDOC_POSITION is table of DOC_POSITION%rowtype;

    tblPositions      TDOC_POSITION;
    intIndex          integer;
    ltplJournalHeader DOC_JOURNAL_HEADER%rowtype;
  begin
    -- Effacement document
    if aCode = 'DELETE' then
      update DOC_JOURNAL_HEADER
         set DJN_DMT_IDDEL = PCS.PC_I_LIB_SESSION.GetUserIni
           , DJN_DMT_DATEDEL = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_DOCUMENT_ID = aOldDoc.DOC_DOCUMENT_ID;
    -- Modif document
    elsif aCode = 'UPDATE' then
      -- Reprendre le tuple du DOC_JOURNAL_HEADER à màj
      select *
        into ltplJournalHeader
        from DOC_JOURNAL_HEADER
       where DOC_DOCUMENT_ID = aNewDoc.DOC_DOCUMENT_ID;

      ltplJournalHeader.DMT_NUMBER               := aNewDoc.DMT_NUMBER;
      ltplJournalHeader.DJN_LAST_DMT_DATE        := aNewDoc.DMT_DATE_DOCUMENT;
      ltplJournalHeader.DJN_LAST_VALUE_DATE      := aNewDoc.DMT_DATE_VALUE;
      ltplJournalHeader.DJN_LAST_DELIVERY_DATE   := aNewDoc.DMT_DATE_DELIVERY;
      ltplJournalHeader.DJN_LAST_PARTNER_DATE    := aNewDoc.DMT_DATE_PARTNER_DOCUMENT;
      -- date 1ere Confirmation du document
      ltplJournalHeader.DJN_FIRST_CONFIRM_DATE   := case
                                                     when aNewDoc.C_DOCUMENT_STATUS = '01' then null
                                                     else nvl(ltplJournalHeader.DJN_FIRST_CONFIRM_DATE, sysdate)
                                                   end;
      -- date dernière Confirmation du document
      ltplJournalHeader.DJN_LAST_CONFIRM_DATE    := case
                                                     when aNewDoc.C_DOCUMENT_STATUS = '01' then null
                                                     else nvl(ltplJournalHeader.DJN_LAST_CONFIRM_DATE, sysdate)
                                                   end;
      -- date 1ere liquidation du document
      ltplJournalHeader.DJN_FIRST_FINISHED_DATE  := case
                                                     when aNewDoc.C_DOCUMENT_STATUS = '04' then nvl(ltplJournalHeader.DJN_LAST_FINISHED_DATE, sysdate)
                                                     else null
                                                   end;
      -- Situation Document liquidé qui redevient activé (ex: recharge du doc parent lors de l'effacement d'une position fille déchargée)
      -- VOIR decode pour le champs DJN_LAST_FINISHED_DATE
      ltplJournalHeader.DJN_LAST_FINISHED_DATE   :=
                case
                  when aNewDoc.C_DOCUMENT_STATUS = '04' then sysdate
                  when aNewDoc.C_DOCUMENT_STATUS = '05' then ltplJournalHeader.DJN_LAST_FINISHED_DATE
                  else null
                end;

      -- Dossier
      if nvl(ltplJournalHeader.DOC_RECORD_ID, -1) <> nvl(aNewDoc.DOC_RECORD_ID, -1) then
        ltplJournalHeader.DOC_RECORD_ID  := aNewDoc.DOC_RECORD_ID;

        select max(RCO_TITLE)
          into ltplJournalHeader.RCO_TITLE
          from DOC_RECORD
         where DOC_RECORD_ID = aNewDoc.DOC_RECORD_ID;
      end if;

      -- Partenaire
      if nvl(ltplJournalHeader.PAC_THIRD_ID, -1) <> nvl(aNewDoc.PAC_THIRD_ID, -1) then
        ltplJournalHeader.PAC_THIRD_ID  := aNewDoc.PAC_THIRD_ID;

        select max(PER_NAME)
             , max(PER_KEY1)
          into ltplJournalHeader.THI_PER_NAME
             , ltplJournalHeader.THI_PER_KEY1
          from PAC_PERSON
         where PAC_PERSON_ID = aNewDoc.PAC_THIRD_ID;
      end if;

      -- Partenaire facturation
      if nvl(ltplJournalHeader.PAC_THIRD_ACI_ID, -1) <> nvl(aNewDoc.PAC_THIRD_ACI_ID, -1) then
        ltplJournalHeader.PAC_THIRD_ACI_ID  := aNewDoc.PAC_THIRD_ACI_ID;

        select max(PER_NAME)
             , max(PER_KEY1)
          into ltplJournalHeader.THI_ACI_PER_NAME
             , ltplJournalHeader.THI_ACI_PER_KEY1
          from PAC_PERSON
         where PAC_PERSON_ID = aNewDoc.PAC_THIRD_ACI_ID;
      end if;

      -- Partenaire livraison
      if nvl(ltplJournalHeader.PAC_THIRD_DELIVERY_ID, -1) <> nvl(aNewDoc.PAC_THIRD_DELIVERY_ID, -1) then
        ltplJournalHeader.PAC_THIRD_DELIVERY_ID  := aNewDoc.PAC_THIRD_DELIVERY_ID;

        select max(PER_NAME)
             , max(PER_KEY1)
          into ltplJournalHeader.THI_DELIVERY_PER_NAME
             , ltplJournalHeader.THI_DELIVERY_PER_KEY1
          from PAC_PERSON
         where PAC_PERSON_ID = aNewDoc.PAC_THIRD_DELIVERY_ID;
      end if;

      -- Partenaire tarification
      if nvl(ltplJournalHeader.PAC_THIRD_TARIFF_ID, -1) <> nvl(aNewDoc.PAC_THIRD_TARIFF_ID, -1) then
        ltplJournalHeader.PAC_THIRD_TARIFF_ID  := aNewDoc.PAC_THIRD_TARIFF_ID;

        select max(PER_NAME)
             , max(PER_KEY1)
          into ltplJournalHeader.THI_TARIFF_PER_NAME
             , ltplJournalHeader.THI_TARIFF_PER_KEY1
          from PAC_PERSON
         where PAC_PERSON_ID = aNewDoc.PAC_THIRD_TARIFF_ID;
      end if;

      -- Représentant
      if nvl(ltplJournalHeader.PAC_REPRESENTATIVE_ID, -1) <> nvl(aNewDoc.PAC_REPRESENTATIVE_ID, -1) then
        ltplJournalHeader.PAC_REPRESENTATIVE_ID  := aNewDoc.PAC_REPRESENTATIVE_ID;

        select max(REP_DESCR)
          into ltplJournalHeader.REP_DESCR
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPRESENTATIVE_ID;
      end if;

      -- Représentant facturation
      if nvl(ltplJournalHeader.PAC_REPR_ACI_ID, -1) <> nvl(aNewDoc.PAC_REPR_ACI_ID, -1) then
        ltplJournalHeader.PAC_REPR_ACI_ID  := aNewDoc.PAC_REPR_ACI_ID;

        select max(REP_DESCR)
          into ltplJournalHeader.REP_ACI_DESCR
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPR_ACI_ID;
      end if;

      -- Représentant livraison
      if nvl(ltplJournalHeader.PAC_REPR_DELIVERY_ID, -1) <> nvl(aNewDoc.PAC_REPR_DELIVERY_ID, -1) then
        ltplJournalHeader.PAC_REPR_DELIVERY_ID  := aNewDoc.PAC_REPR_DELIVERY_ID;

        select max(REP_DESCR)
          into ltplJournalHeader.REP_DELIVERY_DESCR
          from PAC_REPRESENTATIVE
         where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPR_DELIVERY_ID;
      end if;

      -- Monnaie
      if nvl(ltplJournalHeader.ACS_FINANCIAL_CURRENCY_ID, -1) <> nvl(aNewDoc.ACS_FINANCIAL_CURRENCY_ID, -1) then
        ltplJournalHeader.ACS_FINANCIAL_CURRENCY_ID  := aNewDoc.ACS_FINANCIAL_CURRENCY_ID;

        select max(CUR.CURRENCY)
          into ltplJournalHeader.CURRENCY
          from ACS_FINANCIAL_CURRENCY FIN
             , PCS.PC_CURR CUR
         where FIN.PC_CURR_ID = CUR.PC_CURR_ID
           and FIN.ACS_FINANCIAL_CURRENCY_ID = aNewDoc.ACS_FINANCIAL_CURRENCY_ID;
      end if;

      -- Compte finance
      if nvl(ltplJournalHeader.ACS_FINANCIAL_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_FINANCIAL_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_FINANCIAL_ACCOUNT_ID  := aNewDoc.ACS_FINANCIAL_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_FIN_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_FINANCIAL_ACCOUNT_ID;
      end if;

      -- Compte division
      if nvl(ltplJournalHeader.ACS_DIVISION_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_DIVISION_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_DIVISION_ACCOUNT_ID  := aNewDoc.ACS_DIVISION_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_DIV_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_DIVISION_ACCOUNT_ID;
      end if;

      -- Compte charge par nature
      if nvl(ltplJournalHeader.ACS_CPN_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_CPN_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_CPN_ACCOUNT_ID  := aNewDoc.ACS_CPN_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_CPN_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_CPN_ACCOUNT_ID;
      end if;

      -- Compte centre d'analyse
      if nvl(ltplJournalHeader.ACS_CDA_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_CDA_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_CDA_ACCOUNT_ID  := aNewDoc.ACS_CDA_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_CDA_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_CDA_ACCOUNT_ID;
      end if;

      -- Compte porteur
      if nvl(ltplJournalHeader.ACS_PF_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_PF_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_PF_ACCOUNT_ID  := aNewDoc.ACS_PF_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_PF_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_PF_ACCOUNT_ID;
      end if;

      -- Compte projet
      if nvl(ltplJournalHeader.ACS_PJ_ACCOUNT_ID, -1) <> nvl(aNewDoc.ACS_PJ_ACCOUNT_ID, -1) then
        ltplJournalHeader.ACS_PJ_ACCOUNT_ID  := aNewDoc.ACS_PJ_ACCOUNT_ID;

        select max(ACC_NUMBER)
          into ltplJournalHeader.DJN_PJ_ACCOUNT
          from ACS_ACCOUNT
         where ACS_ACCOUNT_ID = aNewDoc.ACS_PJ_ACCOUNT_ID;
      end if;

      ltplJournalHeader.DJN_DMT_IDMOD            := aNewDoc.A_IDMOD;
      ltplJournalHeader.DJN_DMT_DATEMOD          := aNewDoc.A_DATEMOD;
      ltplJournalHeader.A_IDMOD                  := PCS.PC_I_LIB_SESSION.GetUserIni;
      ltplJournalHeader.A_DATEMOD                := sysdate;

      update DOC_JOURNAL_HEADER
         set row = ltplJournalHeader
       where DOC_JOURNAL_HEADER_ID = ltplJournalHeader.DOC_JOURNAL_HEADER_ID;

      -- Si modification date valeur, date document
      --    Si la monnaie ou cours de change a été modifié aussi, on ne fait pas la journalisation des positions ci-dessous
      --      car celle-ci sera faite à la suite de la modif des montants en MB sur les positions
      --   REMARQUE (le cours de change peut être changé avec l'outil de réevalutation des documents )
      -- Effectuer :
      --   1 - écriture d'extourne de toutes les positions du document
      --   2 - ecriture de journalisation de toutes les positions du document à la date valeur/document
      if     (    (aNewDoc.DMT_DATE_DOCUMENT <> aOldDoc.DMT_DATE_DOCUMENT)
              or (aNewDoc.DMT_DATE_VALUE <> aOldDoc.DMT_DATE_VALUE) )
         and not(    (aNewDoc.ACS_FINANCIAL_CURRENCY_ID <> aOldDoc.ACS_FINANCIAL_CURRENCY_ID)
                 or (aNewDoc.DMT_RATE_OF_EXCHANGE <> aOldDoc.DMT_RATE_OF_EXCHANGE)
                 or (aNewDoc.DMT_BASE_PRICE <> aOldDoc.DMT_BASE_PRICE)
                ) then
        select *
        bulk collect into tblPositions
          from DOC_POSITION
         where DOC_DOCUMENT_ID = aNewDoc.DOC_DOCUMENT_ID
           and C_GAUGE_TYPE_POS not in('2', '3', '4', '5', '6', '9', '71', '101');

        if tblPositions.count > 0 then
          --
          -- Stocker les infos du document dans une variable globale
          -- pour effectuer les écritures des positions
          -- parce que le select sur le document n'est pas possible
          -- puisque l'on est dans le trigger d'update du document
          vDOC_INFO.USE_INFORMATION           := 1;
          vDOC_INFO.OLD_DMT_NUMBER            := aOldDoc.DMT_NUMBER;
          vDOC_INFO.OLD_DMT_DATE_DOCUMENT     := aOldDoc.DMT_DATE_DOCUMENT;
          vDOC_INFO.OLD_DMT_DATE_VALUE        := aOldDoc.DMT_DATE_VALUE;
          vDOC_INFO.OLD_DMT_RATE_OF_EXCHANGE  := aOldDoc.DMT_RATE_OF_EXCHANGE;
          vDOC_INFO.OLD_DMT_BASE_PRICE        := aOldDoc.DMT_BASE_PRICE;
          vDOC_INFO.OLD_DOC_GAUGE_ID          := aOldDoc.DOC_GAUGE_ID;
          vDOC_INFO.NEW_DMT_NUMBER            := aNewDoc.DMT_NUMBER;
          vDOC_INFO.NEW_DMT_DATE_DOCUMENT     := aNewDoc.DMT_DATE_DOCUMENT;
          vDOC_INFO.NEW_DMT_DATE_VALUE        := aNewDoc.DMT_DATE_VALUE;
          vDOC_INFO.NEW_DMT_RATE_OF_EXCHANGE  := aNewDoc.DMT_RATE_OF_EXCHANGE;
          vDOC_INFO.NEW_DMT_BASE_PRICE        := aNewDoc.DMT_BASE_PRICE;
          vDOC_INFO.NEW_DOC_GAUGE_ID          := aNewDoc.DOC_GAUGE_ID;

          -- Balayer les positions du document courant pour effectuer les écritures
          for intIndex in tblPositions.first .. tblPositions.last loop
            if MustPosJournalize(aNewDoc.DOC_DOCUMENT_ID
                               , aNewDoc.DOC_GAUGE_ID
                               , tblPositions(intIndex).C_GAUGE_TYPE_POS
                               , tblPositions(intIndex).DOC_GAUGE_POSITION_ID
                               , tblPositions(intIndex).DOC_DOC_POSITION_ID
                                ) = 1 then
              JournalizePosition(aCode => 'UPDATE', aOldPos => tblPositions(intIndex), aNewPos => tblPositions(intIndex) );
            end if;
          end loop;

          /* Effectuer les écritures sur les positions source de décharge
             des positions du document courant suite à la modification de
             la date valeur sur le document courant      */
          JournalizeSrcPositions(aNewDoc.DOC_DOCUMENT_ID);
          --
          vDOC_INFO.USE_INFORMATION           := 0;
        end if;
      end if;
    elsif aCode = 'INSERT' then
      insert into DOC_JOURNAL_HEADER
                  (DOC_JOURNAL_HEADER_ID
                 , DOC_DOCUMENT_ID
                 , DMT_NUMBER
                 , DIC_DOC_JOURNAL_1_ID
                 , DIC_DOC_JOURNAL_2_ID
                 , DIC_DOC_JOURNAL_3_ID
                 , DIC_DOC_JOURNAL_4_ID
                 , DIC_DOC_JOURNAL_5_ID
                 , DIC_PROJECT_CONSOL_1_ID
                 , C_PROJECT_CONSOLIDATION
                 , C_DOC_JOURNAL_CALCULATION
                 , PAC_THIRD_ID
                 , THI_PER_NAME
                 , THI_PER_KEY1
                 , PAC_THIRD_ACI_ID
                 , THI_ACI_PER_NAME
                 , THI_ACI_PER_KEY1
                 , PAC_THIRD_DELIVERY_ID
                 , THI_DELIVERY_PER_NAME
                 , THI_DELIVERY_PER_KEY1
                 , PAC_THIRD_TARIFF_ID
                 , THI_TARIFF_PER_NAME
                 , THI_TARIFF_PER_KEY1
                 , DOC_GAUGE_ID
                 , GAU_DESCRIBE
                 , C_GAUGE_TITLE
                 , C_GAUGE_TYPE
                 , C_ADMIN_DOMAIN
                 , DOC_RECORD_ID
                 , RCO_TITLE
                 , PAC_REPRESENTATIVE_ID
                 , REP_DESCR
                 , PAC_REPR_ACI_ID
                 , REP_ACI_DESCR
                 , PAC_REPR_DELIVERY_ID
                 , REP_DELIVERY_DESCR
                 , ACS_FINANCIAL_CURRENCY_ID
                 , CURRENCY
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , DJN_FIN_ACCOUNT
                 , DJN_DIV_ACCOUNT
                 , DJN_CPN_ACCOUNT
                 , DJN_CDA_ACCOUNT
                 , DJN_PF_ACCOUNT
                 , DJN_PJ_ACCOUNT
                 , DJN_FIRST_DMT_DATE
                 , DJN_LAST_DMT_DATE
                 , DJN_FIRST_VALUE_DATE
                 , DJN_LAST_VALUE_DATE
                 , DJN_FIRST_PARTNER_DATE
                 , DJN_LAST_PARTNER_DATE
                 , DJN_FIRST_DELIVERY_DATE
                 , DJN_LAST_DELIVERY_DATE
                 , DJN_FIRST_CONFIRM_DATE
                 , DJN_LAST_CONFIRM_DATE
                 , DJN_FIRST_FINISHED_DATE
                 , DJN_LAST_FINISHED_DATE
                 , DJN_DMT_DATECRE
                 , DJN_DMT_DATEMOD
                 , DJN_DMT_DATEDEL
                 , DJN_DMT_IDCRE
                 , DJN_DMT_IDMOD
                 , DJN_DMT_IDDEL
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval DOC_JOURNAL_HEADER_ID
             , aNewDoc.DOC_DOCUMENT_ID
             , aNewDoc.DMT_NUMBER
             , GAS.DIC_DOC_JOURNAL_1_ID
             , GAS.DIC_DOC_JOURNAL_2_ID
             , GAS.DIC_DOC_JOURNAL_3_ID
             , GAS.DIC_DOC_JOURNAL_4_ID
             , GAS.DIC_DOC_JOURNAL_5_ID
             , GAS.DIC_PROJECT_CONSOL_1_ID
             , GAS.C_PROJECT_CONSOLIDATION
             , GAS.C_DOC_JOURNAL_CALCULATION
             , aNewDoc.PAC_THIRD_ID
             , THI.PER_NAME
             , THI.PER_KEY1
             , aNewDoc.PAC_THIRD_ACI_ID
             , THI_ACI.PER_NAME
             , THI_ACI.PER_KEY1
             , aNewDoc.PAC_THIRD_DELIVERY_ID
             , THI_DELIVERY.PER_NAME
             , THI_DELIVERY.PER_KEY1
             , aNewDoc.PAC_THIRD_TARIFF_ID
             , THI_TARIFF.PER_NAME
             , THI_TARIFF.PER_KEY1
             , aNewDoc.DOC_GAUGE_ID
             , GAU.GAU_DESCRIBE
             , GAS.C_GAUGE_TITLE
             , GAU.C_GAUGE_TYPE
             , GAU.C_ADMIN_DOMAIN
             , aNewDoc.DOC_RECORD_ID
             , RCO.RCO_TITLE
             , aNewDoc.PAC_REPRESENTATIVE_ID
             , REP.REP_DESCR
             , aNewDoc.PAC_REPR_ACI_ID
             , REP_ACI.REP_DESCR
             , aNewDoc.PAC_REPR_DELIVERY_ID
             , REP_DELIVERY.REP_DESCR
             , aNewDoc.ACS_FINANCIAL_CURRENCY_ID
             , CUR.CURRENCY
             , aNewDoc.ACS_FINANCIAL_ACCOUNT_ID
             , aNewDoc.ACS_DIVISION_ACCOUNT_ID
             , aNewDoc.ACS_CPN_ACCOUNT_ID
             , aNewDoc.ACS_CDA_ACCOUNT_ID
             , aNewDoc.ACS_PF_ACCOUNT_ID
             , aNewDoc.ACS_PJ_ACCOUNT_ID
             , FIN.ACC_NUMBER
             , DIV.ACC_NUMBER
             , CPN.ACC_NUMBER
             , CDA.ACC_NUMBER
             , PF.ACC_NUMBER
             , PJ.ACC_NUMBER
             , aNewDoc.DMT_DATE_DOCUMENT   -- DJN_FIRST_DMT_DATE
             , aNewDoc.DMT_DATE_DOCUMENT   -- DJN_LAST_DMT_DATE
             , aNewDoc.DMT_DATE_VALUE   -- DJN_FIRST_VALUE_DATE
             , aNewDoc.DMT_DATE_VALUE   -- DJN_LAST_VALUE_DATE
             , aNewDoc.DMT_DATE_PARTNER_DOCUMENT   -- DJN_FIRST_PARTNER_DATE
             , aNewDoc.DMT_DATE_PARTNER_DOCUMENT   -- DJN_LAST_PARTNER_DATE
             , aNewDoc.DMT_DATE_DELIVERY   -- DJN_FIRST_DELIVERY_DATE
             , aNewDoc.DMT_DATE_DELIVERY   -- DJN_LAST_DELIVERY_DATE
             , case
                 when aNewDoc.C_DOCUMENT_STATUS = '01' then null
                 else sysdate
               end as DJN_FIRST_CONFIRM_DATE
             , case
                 when aNewDoc.C_DOCUMENT_STATUS = '01' then null
                 else sysdate
               end as DJN_LAST_CONFIRM_DATE
             , case
                 when aNewDoc.C_DOCUMENT_STATUS = '04' then sysdate
                 else null
               end as DJN_FIRST_FINISHED_DATE
             , case
                 when aNewDoc.C_DOCUMENT_STATUS = '04' then sysdate
                 else null
               end as DJN_LAST_FINISHED_DATE
             , aNewDoc.A_DATECRE   -- DJN_DMT_DATECRE
             , null   -- DJN_DMT_DATEMOD
             , null   -- DJN_DMT_DATEDEL
             , aNewDoc.A_IDCRE   -- DJN_DMT_IDCRE
             , null   -- DJN_DMT_IDMOD
             , null   -- DJN_DMT_IDDEL
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , ACS_FINANCIAL_CURRENCY ACS
             , PCS.PC_CURR CUR
             , (select max(PER_NAME) PER_NAME
                     , max(PER_KEY1) PER_KEY1
                  from PAC_PERSON
                 where PAC_PERSON_ID = aNewDoc.PAC_THIRD_ID) THI
             , (select max(PER_NAME) PER_NAME
                     , max(PER_KEY1) PER_KEY1
                  from PAC_PERSON
                 where PAC_PERSON_ID = aNewDoc.PAC_THIRD_ACI_ID) THI_ACI
             , (select max(PER_NAME) PER_NAME
                     , max(PER_KEY1) PER_KEY1
                  from PAC_PERSON
                 where PAC_PERSON_ID = aNewDoc.PAC_THIRD_DELIVERY_ID) THI_DELIVERY
             , (select max(PER_NAME) PER_NAME
                     , max(PER_KEY1) PER_KEY1
                  from PAC_PERSON
                 where PAC_PERSON_ID = aNewDoc.PAC_THIRD_TARIFF_ID) THI_TARIFF
             , (select max(RCO_TITLE) RCO_TITLE
                  from DOC_RECORD
                 where DOC_RECORD_ID = aNewDoc.DOC_RECORD_ID) RCO
             , (select max(REP_DESCR) REP_DESCR
                  from PAC_REPRESENTATIVE
                 where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPRESENTATIVE_ID) REP
             , (select max(REP_DESCR) REP_DESCR
                  from PAC_REPRESENTATIVE
                 where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPR_ACI_ID) REP_ACI
             , (select max(REP_DESCR) REP_DESCR
                  from PAC_REPRESENTATIVE
                 where PAC_REPRESENTATIVE_ID = aNewDoc.PAC_REPR_DELIVERY_ID) REP_DELIVERY
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_FINANCIAL_ACCOUNT_ID) FIN
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_DIVISION_ACCOUNT_ID) DIV
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_CPN_ACCOUNT_ID) CPN
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_CDA_ACCOUNT_ID) CDA
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_PF_ACCOUNT_ID) PF
             , (select max(ACC_NUMBER) ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = aNewDoc.ACS_PJ_ACCOUNT_ID) PJ
         where GAU.DOC_GAUGE_ID = aNewDoc.DOC_GAUGE_ID
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and ACS.ACS_FINANCIAL_CURRENCY_ID = aNewDoc.ACS_FINANCIAL_CURRENCY_ID
           and ACS.PC_CURR_ID = CUR.PC_CURR_ID;
    end if;
  end JournalizeDocument;

  /**
  * procedure JournalizePosition
  * Description
  *   Méthode pour journaliser la position
  * @version 2005
  * @created NGV
  */
  procedure JournalizePosition(aCode in varchar2, aOldPos in DOC_POSITION%rowtype, aNewPos in DOC_POSITION%rowtype)
  is
  begin
    -- Confirmation de la position
    if (aCode = 'CONFIRM') then
      CreateDetail_Confirm(aOldPos, aNewPos);
    end if;

    DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
    DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := null;

    -- Recherche l'id de la position source de la décharge (s'il y a eu décharge).
    select max(PDE_SRC.DOC_POSITION_ID)
      into DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID
      from DOC_POSITION_DETAIL PDE_TGT
         , DOC_POSITION_DETAIL PDE_SRC
     where PDE_TGT.DOC_POSITION_ID = nvl(aNewPos.DOC_POSITION_ID, aOldPos.DOC_POSITION_ID)
       and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID;

    -- Ecriture d'extourne
    if    (aCode = 'BALANCE')
       or (aCode = 'BAL_EXT')
       or (aCode = 'CANCEL')
       or (aCode = 'DELETE')
       or (aCode = 'DEL_TGT')
       or (aCode = 'DISCHARGED')
       or (aCode = 'UPDATE')
       or (aCode = 'UPD_TGT') then
      CreateDetailExt(aCode => aCode, aOldPos => aOldPos, aNewPos => aNewPos);
    end if;

    -- Ecriture
    if    (aCode = 'BALANCE')
       or (aCode = 'BAL_EXT')
       or (aCode = 'CANCEL')
       or (aCode = 'DEL_TGT')
       or (aCode = 'DISCHARGED')
       or (aCode = 'INSERT')
       or (aCode = 'INS_DISCH')
       or (aCode = 'UPDATE')
       or (aCode = 'UPD_TGT') then
      CreateDetail(aCode => aCode, aOldPos => aOldPos, aNewPos => aNewPos);
    end if;

    DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
    DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := null;
  end JournalizePosition;

  /**
  * procedure CreateDetail
  * Description
  *
  */
  procedure CreateDetail(
    aCode          in varchar2
  , aOldPos        in DOC_POSITION%rowtype
  , aNewPos        in DOC_POSITION%rowtype
  , aDetailProv    in integer default 0
  , aForceStatus   in varchar2 default null
  , aForceQuantity in integer default 0
  , aQuantity      in DOC_JOURNAL_DETAIL.DJD_JOURNAL_QTY%type default null
  , aDateCre       in DOC_JOURNAL_DETAIL.A_DATECRE%type default null
  , aIdCre         in DOC_JOURNAL_DETAIL.A_IDCRE%type default null
  )
  is
    vDetail               DOC_JOURNAL_DETAIL%rowtype;
    vDetailProv           DOC_JOURNAL_DETAIL_PROV%rowtype;
    vQuantity             DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vGasBalanceStatus     integer;
    vDMT_NUMBER           DOC_DOCUMENT.DMT_NUMBER%type;
    vDMT_DATE_DOCUMENT    DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vDMT_DATE_VALUE       DOC_DOCUMENT.DMT_DATE_VALUE%type;
    vDMT_RATE_OF_EXCHANGE DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    vDMT_BASE_PRICE       DOC_DOCUMENT.DMT_BASE_PRICE%type;
    vDOC_GAUGE_ID         DOC_DOCUMENT.DOC_GAUGE_ID%type;
    vValueDate            date                                     default null;
    vDocumentDate         date                                     default null;
  begin
    if vDOC_INFO.USE_INFORMATION = 1 then
      vDMT_NUMBER            := vDOC_INFO.NEW_DMT_NUMBER;
      vDMT_DATE_DOCUMENT     := vDOC_INFO.NEW_DMT_DATE_DOCUMENT;
      vDMT_DATE_VALUE        := vDOC_INFO.NEW_DMT_DATE_VALUE;
      vDMT_RATE_OF_EXCHANGE  := vDOC_INFO.NEW_DMT_RATE_OF_EXCHANGE;
      vDMT_BASE_PRICE        := vDOC_INFO.NEW_DMT_BASE_PRICE;
      vDOC_GAUGE_ID          := vDOC_INFO.NEW_DOC_GAUGE_ID;
    else
      select DMT_NUMBER
           , DMT_DATE_DOCUMENT
           , DMT_DATE_VALUE
           , DMT_RATE_OF_EXCHANGE
           , DMT_BASE_PRICE
           , DOC_GAUGE_ID
        into vDMT_NUMBER
           , vDMT_DATE_DOCUMENT
           , vDMT_DATE_VALUE
           , vDMT_RATE_OF_EXCHANGE
           , vDMT_BASE_PRICE
           , vDOC_GAUGE_ID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aNewPos.DOC_DOCUMENT_ID;
    end if;

    if aForceQuantity = 1 then
      vQuantity  := aQuantity;
    else
      if    (aCode = 'BALANCE')
         or (aCode = 'BAL_EXT') then
        vQuantity  := aOldPos.POS_BALANCE_QUANTITY - aNewPos.POS_BALANCE_QUANTITY;
      else
        -- Recherche si gabarit a le statut à solder
        select nvl(max(GAS_BALANCE_STATUS), 0)
          into vGasBalanceStatus
          from DOC_GAUGE_STRUCTURED
         where DOC_GAUGE_ID = nvl(aNewPos.DOC_GAUGE_ID, vDOC_GAUGE_ID);

        if vGasBalanceStatus = 0 then
          vQuantity  := aNewPos.POS_FINAL_QUANTITY;
        else
          vQuantity  := aNewPos.POS_BALANCE_QUANTITY;
        end if;
      end if;
    end if;

    if aCode in('DISCHARGED', 'DEL_TGT', 'UPD_TGT', 'CONF_TGT') then
      -- Ces écritures sont faites sur la position père
      DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
      DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := DISCH_TGT_POS_ID;

      -- La date valeur journalisation pour la position déchargée,
      --  doit etre la date valeur du doc de la pos fille
      select max(DMT_DATE_VALUE)
           , max(DMT_DATE_DOCUMENT)
        into vValueDate
           , vDocumentDate
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = DISCH_TGT_DOC_ID;
    elsif aCode in('BALANCE', 'BAL_EXT') then
      -- Pour le solde des positions, utiliser la date du solde
      select trunc(nvl(aNewPos.POS_DATE_BALANCED, sysdate) )
        into vValueDate
        from dual;

      vDocumentDate  := vValueDate;
    end if;

    select INIT_ID_SEQ.nextval
         , DJN.DOC_JOURNAL_HEADER_ID
         , aCode
         , GAS.DIC_DOC_JOURNAL_1_ID
         , GAS.DIC_DOC_JOURNAL_2_ID
         , GAS.DIC_DOC_JOURNAL_3_ID
         , GAS.DIC_DOC_JOURNAL_4_ID
         , GAS.DIC_DOC_JOURNAL_5_ID
         , GAS.DIC_PROJECT_CONSOL_1_ID
         , GAS.C_PROJECT_CONSOLIDATION
         , GAS.C_DOC_JOURNAL_CALCULATION
         , decode(GAS.C_DOC_JOURNAL_CALCULATION, 'REMOVE', -1, 1)
         , aNewPos.DOC_DOCUMENT_ID
         , vDMT_NUMBER
         , vDMT_DATE_DOCUMENT
         , vDMT_DATE_VALUE
         , aNewPos.DOC_GAUGE_ID
         , GAU.GAU_DESCRIBE
         , GAS.C_GAUGE_TITLE
         , GAU.C_GAUGE_TYPE
         , GAU.C_ADMIN_DOMAIN
         , aNewPos.PAC_THIRD_ID
         , THI.PER_NAME
         , THI.PER_KEY1
         , aNewPos.PAC_THIRD_ACI_ID
         , THI_ACI.PER_NAME
         , THI_ACI.PER_KEY1
         , aNewPos.PAC_THIRD_DELIVERY_ID
         , THI_DELIVERY.PER_NAME
         , THI_DELIVERY.PER_KEY1
         , aNewPos.PAC_THIRD_TARIFF_ID
         , THI_TARIFF.PER_NAME
         , THI_TARIFF.PER_KEY1
         , aNewPos.PAC_PERSON_ID
         , PER.PER_NAME
         , PER.PER_KEY1
         , aNewPos.HRM_PERSON_ID
         , HRM.PER_FIRST_NAME
         , HRM.PER_LAST_NAME
         , aNewPos.FAM_FIXED_ASSETS_ID
         , FIX.FIX_NUMBER
         , aNewPos.DOC_POSITION_ID
         , DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID
         , DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID
         , aNewPos.POS_NUMBER
         , aNewPos.POS_REFERENCE
         , aNewPos.C_GAUGE_TYPE_POS
         , aNewPos.GCO_GOOD_ID
         , GOO.GOO_MAJOR_REFERENCE
         , aNewPos.POS_SHORT_DESCRIPTION
         , aNewPos.POS_LONG_DESCRIPTION
         , aNewPos.STM_STOCK_ID
         , STO.STO_DESCRIPTION
         , aNewPos.STM_LOCATION_ID
         , LOC.LOC_DESCRIPTION
         , aNewPos.DOC_RECORD_ID
         , RCO.RCO_TITLE
         , aNewPos.PAC_REPRESENTATIVE_ID
         , REP.REP_DESCR
         , aNewPos.PAC_REPR_ACI_ID
         , REP_ACI.REP_DESCR
         , aNewPos.PAC_REPR_DELIVERY_ID
         , REP_DELIVERY.REP_DESCR
         , aNewPos.ACS_FINANCIAL_ACCOUNT_ID
         , aNewPos.ACS_DIVISION_ACCOUNT_ID
         , aNewPos.ACS_CPN_ACCOUNT_ID
         , aNewPos.ACS_CDA_ACCOUNT_ID
         , aNewPos.ACS_PF_ACCOUNT_ID
         , aNewPos.ACS_PJ_ACCOUNT_ID
         , FIN.ACC_NUMBER
         , DIV.ACC_NUMBER
         , CPN.ACC_NUMBER
         , CDA.ACC_NUMBER
         , PF.ACC_NUMBER
         , PJ.ACC_NUMBER
         , aNewPos.C_FAM_TRANSACTION_TYP
         , aNewPos.POS_IMF_NUMBER_2
         , aNewPos.POS_IMF_NUMBER_3
         , aNewPos.POS_IMF_NUMBER_4
         , aNewPos.POS_IMF_NUMBER_5
         , aNewPos.POS_IMF_TEXT_1
         , aNewPos.POS_IMF_TEXT_2
         , aNewPos.POS_IMF_TEXT_3
         , aNewPos.POS_IMF_TEXT_4
         , aNewPos.POS_IMF_TEXT_5
         , aNewPos.DIC_IMP_FREE1_ID
         , aNewPos.DIC_IMP_FREE2_ID
         , aNewPos.DIC_IMP_FREE3_ID
         , aNewPos.DIC_IMP_FREE4_ID
         , aNewPos.DIC_IMP_FREE5_ID
         , DBMS_TRANSACTION.local_transaction_id
         , 0   --DJD_REVERSAL_ENTRY
         , vQuantity
         , nvl(vValueDate, vDMT_DATE_VALUE)   -- DJD_JOURNAL_VALUE_DATE
         , nvl(vDocumentDate, vDMT_DATE_DOCUMENT)   -- DJD_JOURNAL_DOCUMENT_DATE
         , aNewPos.POS_GROSS_UNIT_VALUE
         , aNewPos.POS_GROSS_UNIT_VALUE_INCL
         , aNewPos.POS_NET_UNIT_VALUE
         , aNewPos.POS_NET_UNIT_VALUE_INCL
         , aNewPos.POS_GROSS_UNIT_VALUE * vQuantity
         , decode(aNewPos.POS_FINAL_QUANTITY, 0, 0,(aNewPos.POS_GROSS_VALUE_B / aNewPos.POS_FINAL_QUANTITY) * vQuantity)
         , aNewPos.POS_GROSS_UNIT_VALUE_INCL * vQuantity
         , decode(aNewPos.POS_FINAL_QUANTITY, 0, 0,(aNewPos.POS_GROSS_VALUE_INCL_B / aNewPos.POS_FINAL_QUANTITY) * vQuantity)
         , aNewPos.POS_NET_UNIT_VALUE * vQuantity
         , decode(aNewPos.POS_FINAL_QUANTITY, 0, 0,(aNewPos.POS_NET_VALUE_EXCL_B / aNewPos.POS_FINAL_QUANTITY) * vQuantity)
         , aNewPos.POS_NET_UNIT_VALUE_INCL * vQuantity
         , decode(aNewPos.POS_FINAL_QUANTITY, 0, 0,(aNewPos.POS_NET_VALUE_INCL_B / aNewPos.POS_FINAL_QUANTITY) * vQuantity)
         , aOldPos.POS_BASIS_QUANTITY
         , aNewPos.POS_BASIS_QUANTITY
         , aOldPos.POS_INTERMEDIATE_QUANTITY
         , aNewPos.POS_INTERMEDIATE_QUANTITY
         , aOldPos.POS_FINAL_QUANTITY
         , aNewPos.POS_FINAL_QUANTITY
         , aOldPos.POS_BALANCE_QUANTITY
         , aNewPos.POS_BALANCE_QUANTITY
         , aOldPos.POS_BASIS_QUANTITY_SU
         , aNewPos.POS_BASIS_QUANTITY_SU
         , aOldPos.POS_INTERMEDIATE_QUANTITY_SU
         , aNewPos.POS_INTERMEDIATE_QUANTITY_SU
         , aOldPos.POS_FINAL_QUANTITY_SU
         , aNewPos.POS_FINAL_QUANTITY_SU
         , round(aOldPos.POS_BALANCE_QUANTITY * aOldPos.POS_CONVERT_FACTOR, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
         , round(aNewPos.POS_BALANCE_QUANTITY * aNewPos.POS_CONVERT_FACTOR, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
         , aNewPos.POS_CONVERT_FACTOR
         , nvl(aForceStatus, aNewPos.C_DOC_POS_STATUS)
         , aOldPos.C_DOC_POS_STATUS
         , nvl(aForceStatus, aNewPos.C_DOC_POS_STATUS)
         , vDMT_RATE_OF_EXCHANGE
         , vDMT_BASE_PRICE
         , aNewPos.POS_IMPUTATION
         , nvl(aDateCre, sysdate)
         , nvl(aIdCre, PCS.PC_I_LIB_SESSION.GetUserIni)
      into vDetail.DOC_JOURNAL_DETAIL_ID
         , vDetail.DOC_JOURNAL_HEADER_ID
         , vDetail.C_DOC_JOURNAL_DETAIL
         , vDetail.DIC_DOC_JOURNAL_1_ID
         , vDetail.DIC_DOC_JOURNAL_2_ID
         , vDetail.DIC_DOC_JOURNAL_3_ID
         , vDetail.DIC_DOC_JOURNAL_4_ID
         , vDetail.DIC_DOC_JOURNAL_5_ID
         , vDetail.DIC_PROJECT_CONSOL_1_ID
         , vDetail.C_PROJECT_CONSOLIDATION
         , vDetail.C_DOC_JOURNAL_CALCULATION
         , vDetail.DJD_COEFF
         , vDetail.DOC_DOCUMENT_ID
         , vDetail.DMT_NUMBER
         , vDetail.DMT_DATE_DOCUMENT
         , vDetail.DMT_DATE_VALUE
         , vDetail.DOC_GAUGE_ID
         , vDetail.GAU_DESCRIBE
         , vDetail.C_ADMIN_DOMAIN
         , vDetail.C_GAUGE_TITLE
         , vDetail.C_GAUGE_TYPE
         , vDetail.PAC_THIRD_ID
         , vDetail.THI_PER_NAME
         , vDetail.THI_PER_KEY1
         , vDetail.PAC_THIRD_ACI_ID
         , vDetail.THI_ACI_PER_NAME
         , vDetail.THI_ACI_PER_KEY1
         , vDetail.PAC_THIRD_DELIVERY_ID
         , vDetail.THI_DELIVERY_PER_NAME
         , vDetail.THI_DELIVERY_PER_KEY1
         , vDetail.PAC_THIRD_TARIFF_ID
         , vDetail.THI_TARIFF_PER_NAME
         , vDetail.THI_TARIFF_PER_KEY1
         , vDetail.PAC_PERSON_ID
         , vDetail.PER_PER_NAME
         , vDetail.PER_PER_KEY1
         , vDetail.HRM_PERSON_ID
         , vDetail.HRM_PER_FIRST_NAME
         , vDetail.HRM_PER_LAST_NAME
         , vDetail.FAM_FIXED_ASSETS_ID
         , vDetail.FIX_NUMBER
         , vDetail.DOC_POSITION_ID
         , vDetail.TGT_DOC_POSITION_ID
         , vDetail.SRC_DOC_POSITION_ID
         , vDetail.POS_NUMBER
         , vDetail.POS_REFERENCE
         , vDetail.C_GAUGE_TYPE_POS
         , vDetail.GCO_GOOD_ID
         , vDetail.GOO_MAJOR_REFERENCE
         , vDetail.POS_SHORT_DESCRIPTION
         , vDetail.POS_LONG_DESCRIPTION
         , vDetail.STM_STOCK_ID
         , vDetail.STO_DESCRIPTION
         , vDetail.STM_LOCATION_ID
         , vDetail.LOC_DESCRIPTION
         , vDetail.DOC_RECORD_ID
         , vDetail.RCO_TITLE
         , vDetail.PAC_REPRESENTATIVE_ID
         , vDetail.REP_DESCR
         , vDetail.PAC_REPR_ACI_ID
         , vDetail.REP_ACI_DESCR
         , vDetail.PAC_REPR_DELIVERY_ID
         , vDetail.REP_DELIVERY_DESCR
         , vDetail.ACS_FINANCIAL_ACCOUNT_ID
         , vDetail.ACS_DIVISION_ACCOUNT_ID
         , vDetail.ACS_CPN_ACCOUNT_ID
         , vDetail.ACS_CDA_ACCOUNT_ID
         , vDetail.ACS_PF_ACCOUNT_ID
         , vDetail.ACS_PJ_ACCOUNT_ID
         , vDetail.DJD_FIN_ACCOUNT
         , vDetail.DJD_DIV_ACCOUNT
         , vDetail.DJD_CPN_ACCOUNT
         , vDetail.DJD_CDA_ACCOUNT
         , vDetail.DJD_PF_ACCOUNT
         , vDetail.DJD_PJ_ACCOUNT
         , vDetail.C_FAM_TRANSACTION_TYP
         , vDetail.POS_IMF_NUMBER_2
         , vDetail.POS_IMF_NUMBER_3
         , vDetail.POS_IMF_NUMBER_4
         , vDetail.POS_IMF_NUMBER_5
         , vDetail.POS_IMF_TEXT_1
         , vDetail.POS_IMF_TEXT_2
         , vDetail.POS_IMF_TEXT_3
         , vDetail.POS_IMF_TEXT_4
         , vDetail.POS_IMF_TEXT_5
         , vDetail.DIC_IMP_FREE1_ID
         , vDetail.DIC_IMP_FREE2_ID
         , vDetail.DIC_IMP_FREE3_ID
         , vDetail.DIC_IMP_FREE4_ID
         , vDetail.DIC_IMP_FREE5_ID
         , vDetail.DJD_TRANSACTION_ID
         , vDetail.DJD_REVERSAL_ENTRY
         , vDetail.DJD_JOURNAL_QTY
         , vDetail.DJD_JOURNAL_VALUE_DATE
         , vDetail.DJD_JOURNAL_DOCUMENT_DATE
         , vDetail.POS_GROSS_UNIT_VALUE
         , vDetail.POS_GROSS_UNIT_VALUE_INCL
         , vDetail.POS_NET_UNIT_VALUE
         , vDetail.POS_NET_UNIT_VALUE_INCL
         , vDetail.POS_GROSS_VALUE
         , vDetail.POS_GROSS_VALUE_B
         , vDetail.POS_GROSS_VALUE_INCL
         , vDetail.POS_GROSS_VALUE_INCL_B
         , vDetail.POS_NET_VALUE_EXCL
         , vDetail.POS_NET_VALUE_EXCL_B
         , vDetail.POS_NET_VALUE_INCL
         , vDetail.POS_NET_VALUE_INCL_B
         , vDetail.DJD_OLD_POS_BASIS_QTY
         , vDetail.DJD_NEW_POS_BASIS_QTY
         , vDetail.DJD_OLD_POS_INTER_QTY
         , vDetail.DJD_NEW_POS_INTER_QTY
         , vDetail.DJD_OLD_POS_FINAL_QTY
         , vDetail.DJD_NEW_POS_FINAL_QTY
         , vDetail.DJD_OLD_POS_BALANCE_QTY
         , vDetail.DJD_NEW_POS_BALANCE_QTY
         , vDetail.DJD_OLD_POS_BASIS_QTY_SU
         , vDetail.DJD_NEW_POS_BASIS_QTY_SU
         , vDetail.DJD_OLD_POS_INTER_QTY_SU
         , vDetail.DJD_NEW_POS_INTER_QTY_SU
         , vDetail.DJD_OLD_POS_FINAL_QTY_SU
         , vDetail.DJD_NEW_POS_FINAL_QTY_SU
         , vDetail.DJD_OLD_POS_BALANCE_QTY_SU
         , vDetail.DJD_NEW_POS_BALANCE_QTY_SU
         , vDetail.POS_CONVERT_FACTOR
         , vDetail.C_DOC_POS_STATUS
         , vDetail.DJD_OLD_C_DOC_POS_STATUS
         , vDetail.DJD_NEW_C_DOC_POS_STATUS
         , vDetail.DMT_RATE_OF_EXCHANGE
         , vDetail.DMT_BASE_PRICE
         , vDetail.POS_IMPUTATION
         , vDetail.A_DATECRE
         , vDetail.A_IDCRE
      from DOC_JOURNAL_HEADER DJN
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aNewPos.PAC_THIRD_ID) THI
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aNewPos.PAC_THIRD_ACI_ID) THI_ACI
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aNewPos.PAC_THIRD_DELIVERY_ID) THI_DELIVERY
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aNewPos.PAC_THIRD_TARIFF_ID) THI_TARIFF
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aNewPos.PAC_PERSON_ID) PER
         , (select max(PER_FIRST_NAME) PER_FIRST_NAME
                 , max(PER_LAST_NAME) PER_LAST_NAME
              from HRM_PERSON
             where HRM_PERSON_ID = aNewPos.HRM_PERSON_ID) HRM
         , (select max(FIX_NUMBER) FIX_NUMBER
              from FAM_FIXED_ASSETS
             where FAM_FIXED_ASSETS_ID = aNewPos.FAM_FIXED_ASSETS_ID) FIX
         , (select max(GOO_MAJOR_REFERENCE) GOO_MAJOR_REFERENCE
                 , max(GOO_NUMBER_OF_DECIMAL) GOO_NUMBER_OF_DECIMAL
              from GCO_GOOD
             where GCO_GOOD_ID = aNewPos.GCO_GOOD_ID) GOO
         , (select max(STO_DESCRIPTION) STO_DESCRIPTION
              from STM_STOCK
             where STM_STOCK_ID = aNewPos.STM_STOCK_ID) STO
         , (select max(LOC_DESCRIPTION) LOC_DESCRIPTION
              from STM_LOCATION
             where STM_LOCATION_ID = aNewPos.STM_LOCATION_ID) LOC
         , (select max(RCO_TITLE) RCO_TITLE
              from DOC_RECORD
             where DOC_RECORD_ID = aNewPos.DOC_RECORD_ID) RCO
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aNewPos.PAC_REPRESENTATIVE_ID) REP
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aNewPos.PAC_REPR_ACI_ID) REP_ACI
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aNewPos.PAC_REPR_DELIVERY_ID) REP_DELIVERY
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_FINANCIAL_ACCOUNT_ID) FIN
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_DIVISION_ACCOUNT_ID) DIV
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_CPN_ACCOUNT_ID) CPN
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_CDA_ACCOUNT_ID) CDA
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_PF_ACCOUNT_ID) PF
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aNewPos.ACS_PJ_ACCOUNT_ID) PJ
     where DJN.DOC_DOCUMENT_ID = aNewPos.DOC_DOCUMENT_ID
       and GAU.DOC_GAUGE_ID = nvl(aNewPos.DOC_GAUGE_ID, vDOC_GAUGE_ID)
       and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    if vDetail.DJD_JOURNAL_QTY <> 0 then
      if    (aDetailProv = 1)
         or (aNewPos.C_DOC_POS_STATUS = '01') then
        vDetailProv  := GetDetailProvStruct(vDetail);

        insert into DOC_JOURNAL_DETAIL_PROV
             values vDetailProv;
      else
        insert into DOC_JOURNAL_DETAIL
             values vDetail;
      end if;
    end if;
  exception
    when no_data_found then
      null;
  end CreateDetail;

  /**
  * procedure CreateDetailExt
  * Description
  *
  */
  procedure CreateDetailExt(
    aCode          in varchar2
  , aOldPos        in DOC_POSITION%rowtype
  , aNewPos        in DOC_POSITION%rowtype
  , aDetailProv    in integer default 0
  , aForceStatus   in varchar2 default null
  , aForceQuantity in integer default 0
  , aQuantity      in DOC_JOURNAL_DETAIL.DJD_JOURNAL_QTY%type default null
  , aDateCre       in DOC_JOURNAL_DETAIL.A_DATECRE%type default null
  , aIdCre         in DOC_JOURNAL_DETAIL.A_IDCRE%type default null
  )
  is
    vDetail               DOC_JOURNAL_DETAIL%rowtype;
    vDetailProv           DOC_JOURNAL_DETAIL_PROV%rowtype;
    nBalanceQty           DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vGasBalanceStatus     integer;
    vValueDate            date                                     default null;
    vDocumentDate         date                                     default null;
    vDMT_NUMBER           DOC_DOCUMENT.DMT_NUMBER%type;
    vDMT_DATE_DOCUMENT    DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vDMT_DATE_VALUE       DOC_DOCUMENT.DMT_DATE_VALUE%type;
    vDMT_RATE_OF_EXCHANGE DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    vDMT_BASE_PRICE       DOC_DOCUMENT.DMT_BASE_PRICE%type;
    vDOC_GAUGE_ID         DOC_DOCUMENT.DOC_GAUGE_ID%type;
  begin
    if vDOC_INFO.USE_INFORMATION = 1 then
      vDMT_NUMBER            := vDOC_INFO.OLD_DMT_NUMBER;
      vDMT_DATE_DOCUMENT     := vDOC_INFO.OLD_DMT_DATE_DOCUMENT;
      vDMT_DATE_VALUE        := vDOC_INFO.OLD_DMT_DATE_VALUE;
      vDMT_RATE_OF_EXCHANGE  := vDOC_INFO.OLD_DMT_RATE_OF_EXCHANGE;
      vDMT_BASE_PRICE        := vDOC_INFO.OLD_DMT_BASE_PRICE;
      vDOC_GAUGE_ID          := vDOC_INFO.OLD_DOC_GAUGE_ID;
    else
      select DMT_NUMBER
           , DMT_DATE_DOCUMENT
           , DMT_DATE_VALUE
           , DMT_RATE_OF_EXCHANGE
           , DMT_BASE_PRICE
           , DOC_GAUGE_ID
        into vDMT_NUMBER
           , vDMT_DATE_DOCUMENT
           , vDMT_DATE_VALUE
           , vDMT_RATE_OF_EXCHANGE
           , vDMT_BASE_PRICE
           , vDOC_GAUGE_ID
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aOldPos.DOC_DOCUMENT_ID;
    end if;

    -- Confirmation de la position fille
    if aForceQuantity = 1 then
      nBalanceQty  := aQuantity;
    else
      -- Recherche si gabarit a le statut à solder
      select nvl(max(GAS_BALANCE_STATUS), 0)
        into vGasBalanceStatus
        from DOC_GAUGE_STRUCTURED
       where DOC_GAUGE_ID = nvl(aOldPos.DOC_GAUGE_ID, vDOC_GAUGE_ID);

      -- Utiliser la qté de la position si statut à confirmer ou
      -- gabarit ne gère pas le statut à solder
      -- Sinon utiliser la qté solde
      if    (aNewPos.C_DOC_POS_STATUS = '01')
         or (vGasBalanceStatus = 0) then
        nBalanceQty  := aOldPos.POS_FINAL_QUANTITY * -1;
      else
        nBalanceQty  := aOldPos.POS_BALANCE_QUANTITY * -1;
      end if;
    end if;

    if aCode in('DISCHARGED', 'DEL_TGT', 'UPD_TGT', 'CONF_TGT') then
      -- Ces écritures sont faites sur la position père
      DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
      DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := DISCH_TGT_POS_ID;

      -- La date valeur journalisation pour la position déchargée,
      --  doit etre la date valeur du doc de la pos fille
      select max(DMT_DATE_VALUE)
           , max(DMT_DATE_DOCUMENT)
        into vValueDate
           , vDocumentDate
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = DISCH_TGT_DOC_ID;
    elsif aCode in('BALANCE', 'BAL_EXT') then
      -- Pour le solde des positions, utiliser la date du solde
      select trunc(nvl(aOldPos.POS_DATE_BALANCED, sysdate) )
        into vValueDate
        from dual;

      vDocumentDate  := vValueDate;
    end if;

    select INIT_ID_SEQ.nextval
         , DJN.DOC_JOURNAL_HEADER_ID
         , aCode
         , GAS.DIC_DOC_JOURNAL_1_ID
         , GAS.DIC_DOC_JOURNAL_2_ID
         , GAS.DIC_DOC_JOURNAL_3_ID
         , GAS.DIC_DOC_JOURNAL_4_ID
         , GAS.DIC_DOC_JOURNAL_5_ID
         , GAS.DIC_PROJECT_CONSOL_1_ID
         , GAS.C_PROJECT_CONSOLIDATION
         , GAS.C_DOC_JOURNAL_CALCULATION
         , decode(GAS.C_DOC_JOURNAL_CALCULATION, 'REMOVE', -1, 1)
         , aOldPos.DOC_DOCUMENT_ID
         , vDMT_NUMBER
         , vDMT_DATE_DOCUMENT
         , vDMT_DATE_VALUE
         , aOldPos.DOC_GAUGE_ID
         , GAU.GAU_DESCRIBE
         , GAS.C_GAUGE_TITLE
         , GAU.C_GAUGE_TYPE
         , GAU.C_ADMIN_DOMAIN
         , aOldPos.PAC_THIRD_ID
         , THI.PER_NAME
         , THI.PER_KEY1
         , aOldPos.PAC_THIRD_ACI_ID
         , THI_ACI.PER_NAME
         , THI_ACI.PER_KEY1
         , aOldPos.PAC_THIRD_DELIVERY_ID
         , THI_DELIVERY.PER_NAME
         , THI_DELIVERY.PER_KEY1
         , aOldPos.PAC_THIRD_TARIFF_ID
         , THI_TARIFF.PER_NAME
         , THI_TARIFF.PER_KEY1
         , aOldPos.PAC_PERSON_ID
         , PER.PER_NAME
         , PER.PER_KEY1
         , aOldPos.HRM_PERSON_ID
         , HRM.PER_FIRST_NAME
         , HRM.PER_LAST_NAME
         , aOldPos.FAM_FIXED_ASSETS_ID
         , FIX.FIX_NUMBER
         , aOldPos.DOC_POSITION_ID
         , DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID
         , DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID
         , aOldPos.POS_NUMBER
         , aOldPos.POS_REFERENCE
         , aOldPos.POS_SHORT_DESCRIPTION
         , aOldPos.POS_LONG_DESCRIPTION
         , aOldPos.STM_STOCK_ID
         , STO.STO_DESCRIPTION
         , aOldPos.STM_LOCATION_ID
         , LOC.LOC_DESCRIPTION
         , aOldPos.C_GAUGE_TYPE_POS
         , aOldPos.GCO_GOOD_ID
         , GOO.GOO_MAJOR_REFERENCE
         , aOldPos.DOC_RECORD_ID
         , RCO.RCO_TITLE
         , aOldPos.PAC_REPRESENTATIVE_ID
         , REP.REP_DESCR
         , aOldPos.PAC_REPR_ACI_ID
         , REP_ACI.REP_DESCR
         , aOldPos.PAC_REPR_DELIVERY_ID
         , REP_DELIVERY.REP_DESCR
         , aOldPos.ACS_FINANCIAL_ACCOUNT_ID
         , aOldPos.ACS_DIVISION_ACCOUNT_ID
         , aOldPos.ACS_CPN_ACCOUNT_ID
         , aOldPos.ACS_CDA_ACCOUNT_ID
         , aOldPos.ACS_PF_ACCOUNT_ID
         , aOldPos.ACS_PJ_ACCOUNT_ID
         , FIN.ACC_NUMBER
         , DIV.ACC_NUMBER
         , CPN.ACC_NUMBER
         , CDA.ACC_NUMBER
         , PF.ACC_NUMBER
         , PJ.ACC_NUMBER
         , aOldPos.C_FAM_TRANSACTION_TYP
         , aOldPos.POS_IMF_NUMBER_2
         , aOldPos.POS_IMF_NUMBER_3
         , aOldPos.POS_IMF_NUMBER_4
         , aOldPos.POS_IMF_NUMBER_5
         , aOldPos.POS_IMF_TEXT_1
         , aOldPos.POS_IMF_TEXT_2
         , aOldPos.POS_IMF_TEXT_3
         , aOldPos.POS_IMF_TEXT_4
         , aOldPos.POS_IMF_TEXT_5
         , aOldPos.DIC_IMP_FREE1_ID
         , aOldPos.DIC_IMP_FREE2_ID
         , aOldPos.DIC_IMP_FREE3_ID
         , aOldPos.DIC_IMP_FREE4_ID
         , aOldPos.DIC_IMP_FREE5_ID
         , DBMS_TRANSACTION.local_transaction_id
         , 1   --DJD_REVERSAL_ENTRY
         , nBalanceQty   -- DJD_JOURNAL_QTY
         , nvl(vValueDate, vDMT_DATE_VALUE)   -- DJD_JOURNAL_VALUE_DATE
         , nvl(vDocumentDate, vDMT_DATE_DOCUMENT)   -- DJD_JOURNAL_DOCUMENT_DATE
         , aOldPos.POS_GROSS_UNIT_VALUE
         , aOldPos.POS_GROSS_UNIT_VALUE_INCL
         , aOldPos.POS_NET_UNIT_VALUE
         , aOldPos.POS_NET_UNIT_VALUE_INCL
         , aOldPos.POS_GROSS_UNIT_VALUE * nBalanceQty   -- POS_GROSS_VALUE
         , decode(aOldPos.POS_FINAL_QUANTITY, 0, 0,(aOldPos.POS_GROSS_VALUE_B / aOldPos.POS_FINAL_QUANTITY) * nBalanceQty)   -- POS_GROSS_VALUE_B
         , aOldPos.POS_GROSS_UNIT_VALUE_INCL * nBalanceQty   -- POS_GROSS_VALUE_INCL
         , decode(aOldPos.POS_FINAL_QUANTITY, 0, 0,(aOldPos.POS_GROSS_VALUE_INCL_B / aOldPos.POS_FINAL_QUANTITY) * nBalanceQty)   -- POS_GROSS_VALUE_INCL_B
         , aOldPos.POS_NET_UNIT_VALUE * nBalanceQty   -- POS_NET_VALUE_EXCL
         , decode(aOldPos.POS_FINAL_QUANTITY, 0, 0,(aOldPos.POS_NET_VALUE_EXCL_B / aOldPos.POS_FINAL_QUANTITY) * nBalanceQty)   -- POS_NET_VALUE_EXCL_B
         , aOldPos.POS_NET_UNIT_VALUE_INCL * nBalanceQty   -- POS_NET_VALUE_INCL
         , decode(aOldPos.POS_FINAL_QUANTITY, 0, 0,(aOldPos.POS_NET_VALUE_INCL_B / aOldPos.POS_FINAL_QUANTITY) * nBalanceQty)   -- POS_NET_VALUE_INCL_B
         , aOldPos.POS_BASIS_QUANTITY
         , aNewPos.POS_BASIS_QUANTITY
         , aOldPos.POS_INTERMEDIATE_QUANTITY
         , aNewPos.POS_INTERMEDIATE_QUANTITY
         , aOldPos.POS_FINAL_QUANTITY
         , aNewPos.POS_FINAL_QUANTITY
         , aOldPos.POS_BALANCE_QUANTITY
         , aNewPos.POS_BALANCE_QUANTITY
         , aOldPos.POS_BASIS_QUANTITY_SU
         , aNewPos.POS_BASIS_QUANTITY_SU
         , aOldPos.POS_INTERMEDIATE_QUANTITY_SU
         , aNewPos.POS_INTERMEDIATE_QUANTITY_SU
         , aOldPos.POS_FINAL_QUANTITY_SU
         , aNewPos.POS_FINAL_QUANTITY_SU
         , round(aOldPos.POS_BALANCE_QUANTITY * aOldPos.POS_CONVERT_FACTOR, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
         , round(aNewPos.POS_BALANCE_QUANTITY * aNewPos.POS_CONVERT_FACTOR, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) )
         , aOldPos.POS_CONVERT_FACTOR
         , nvl(aForceStatus, aOldPos.C_DOC_POS_STATUS)
         , aOldPos.C_DOC_POS_STATUS
         , nvl(aForceStatus, aOldPos.C_DOC_POS_STATUS)
         , vDMT_RATE_OF_EXCHANGE
         , vDMT_BASE_PRICE
         , aOldPos.POS_IMPUTATION
         , nvl(aDateCre, sysdate)
         , nvl(aIdCre, PCS.PC_I_LIB_SESSION.GetUserIni)
      into vDetail.DOC_JOURNAL_DETAIL_ID
         , vDetail.DOC_JOURNAL_HEADER_ID
         , vDetail.C_DOC_JOURNAL_DETAIL
         , vDetail.DIC_DOC_JOURNAL_1_ID
         , vDetail.DIC_DOC_JOURNAL_2_ID
         , vDetail.DIC_DOC_JOURNAL_3_ID
         , vDetail.DIC_DOC_JOURNAL_4_ID
         , vDetail.DIC_DOC_JOURNAL_5_ID
         , vDetail.DIC_PROJECT_CONSOL_1_ID
         , vDetail.C_PROJECT_CONSOLIDATION
         , vDetail.C_DOC_JOURNAL_CALCULATION
         , vDetail.DJD_COEFF
         , vDetail.DOC_DOCUMENT_ID
         , vDetail.DMT_NUMBER
         , vDetail.DMT_DATE_DOCUMENT
         , vDetail.DMT_DATE_VALUE
         , vDetail.DOC_GAUGE_ID
         , vDetail.GAU_DESCRIBE
         , vDetail.C_ADMIN_DOMAIN
         , vDetail.C_GAUGE_TITLE
         , vDetail.C_GAUGE_TYPE
         , vDetail.PAC_THIRD_ID
         , vDetail.THI_PER_NAME
         , vDetail.THI_PER_KEY1
         , vDetail.PAC_THIRD_ACI_ID
         , vDetail.THI_ACI_PER_NAME
         , vDetail.THI_ACI_PER_KEY1
         , vDetail.PAC_THIRD_DELIVERY_ID
         , vDetail.THI_DELIVERY_PER_NAME
         , vDetail.THI_DELIVERY_PER_KEY1
         , vDetail.PAC_THIRD_TARIFF_ID
         , vDetail.THI_TARIFF_PER_NAME
         , vDetail.THI_TARIFF_PER_KEY1
         , vDetail.PAC_PERSON_ID
         , vDetail.PER_PER_NAME
         , vDetail.PER_PER_KEY1
         , vDetail.HRM_PERSON_ID
         , vDetail.HRM_PER_FIRST_NAME
         , vDetail.HRM_PER_LAST_NAME
         , vDetail.FAM_FIXED_ASSETS_ID
         , vDetail.FIX_NUMBER
         , vDetail.DOC_POSITION_ID
         , vDetail.TGT_DOC_POSITION_ID
         , vDetail.SRC_DOC_POSITION_ID
         , vDetail.POS_NUMBER
         , vDetail.POS_REFERENCE
         , vDetail.POS_SHORT_DESCRIPTION
         , vDetail.POS_LONG_DESCRIPTION
         , vDetail.STM_STOCK_ID
         , vDetail.STO_DESCRIPTION
         , vDetail.STM_LOCATION_ID
         , vDetail.LOC_DESCRIPTION
         , vDetail.C_GAUGE_TYPE_POS
         , vDetail.GCO_GOOD_ID
         , vDetail.GOO_MAJOR_REFERENCE
         , vDetail.DOC_RECORD_ID
         , vDetail.RCO_TITLE
         , vDetail.PAC_REPRESENTATIVE_ID
         , vDetail.REP_DESCR
         , vDetail.PAC_REPR_ACI_ID
         , vDetail.REP_ACI_DESCR
         , vDetail.PAC_REPR_DELIVERY_ID
         , vDetail.REP_DELIVERY_DESCR
         , vDetail.ACS_FINANCIAL_ACCOUNT_ID
         , vDetail.ACS_DIVISION_ACCOUNT_ID
         , vDetail.ACS_CPN_ACCOUNT_ID
         , vDetail.ACS_CDA_ACCOUNT_ID
         , vDetail.ACS_PF_ACCOUNT_ID
         , vDetail.ACS_PJ_ACCOUNT_ID
         , vDetail.DJD_FIN_ACCOUNT
         , vDetail.DJD_DIV_ACCOUNT
         , vDetail.DJD_CPN_ACCOUNT
         , vDetail.DJD_CDA_ACCOUNT
         , vDetail.DJD_PF_ACCOUNT
         , vDetail.DJD_PJ_ACCOUNT
         , vDetail.C_FAM_TRANSACTION_TYP
         , vDetail.POS_IMF_NUMBER_2
         , vDetail.POS_IMF_NUMBER_3
         , vDetail.POS_IMF_NUMBER_4
         , vDetail.POS_IMF_NUMBER_5
         , vDetail.POS_IMF_TEXT_1
         , vDetail.POS_IMF_TEXT_2
         , vDetail.POS_IMF_TEXT_3
         , vDetail.POS_IMF_TEXT_4
         , vDetail.POS_IMF_TEXT_5
         , vDetail.DIC_IMP_FREE1_ID
         , vDetail.DIC_IMP_FREE2_ID
         , vDetail.DIC_IMP_FREE3_ID
         , vDetail.DIC_IMP_FREE4_ID
         , vDetail.DIC_IMP_FREE5_ID
         , vDetail.DJD_TRANSACTION_ID
         , vDetail.DJD_REVERSAL_ENTRY
         , vDetail.DJD_JOURNAL_QTY
         , vDetail.DJD_JOURNAL_VALUE_DATE
         , vDetail.DJD_JOURNAL_DOCUMENT_DATE
         , vDetail.POS_GROSS_UNIT_VALUE
         , vDetail.POS_GROSS_UNIT_VALUE_INCL
         , vDetail.POS_NET_UNIT_VALUE
         , vDetail.POS_NET_UNIT_VALUE_INCL
         , vDetail.POS_GROSS_VALUE
         , vDetail.POS_GROSS_VALUE_B
         , vDetail.POS_GROSS_VALUE_INCL
         , vDetail.POS_GROSS_VALUE_INCL_B
         , vDetail.POS_NET_VALUE_EXCL
         , vDetail.POS_NET_VALUE_EXCL_B
         , vDetail.POS_NET_VALUE_INCL
         , vDetail.POS_NET_VALUE_INCL_B
         , vDetail.DJD_OLD_POS_BASIS_QTY
         , vDetail.DJD_NEW_POS_BASIS_QTY
         , vDetail.DJD_OLD_POS_INTER_QTY
         , vDetail.DJD_NEW_POS_INTER_QTY
         , vDetail.DJD_OLD_POS_FINAL_QTY
         , vDetail.DJD_NEW_POS_FINAL_QTY
         , vDetail.DJD_OLD_POS_BALANCE_QTY
         , vDetail.DJD_NEW_POS_BALANCE_QTY
         , vDetail.DJD_OLD_POS_BASIS_QTY_SU
         , vDetail.DJD_NEW_POS_BASIS_QTY_SU
         , vDetail.DJD_OLD_POS_INTER_QTY_SU
         , vDetail.DJD_NEW_POS_INTER_QTY_SU
         , vDetail.DJD_OLD_POS_FINAL_QTY_SU
         , vDetail.DJD_NEW_POS_FINAL_QTY_SU
         , vDetail.DJD_OLD_POS_BALANCE_QTY_SU
         , vDetail.DJD_NEW_POS_BALANCE_QTY_SU
         , vDetail.POS_CONVERT_FACTOR
         , vDetail.C_DOC_POS_STATUS
         , vDetail.DJD_OLD_C_DOC_POS_STATUS
         , vDetail.DJD_NEW_C_DOC_POS_STATUS
         , vDetail.DMT_RATE_OF_EXCHANGE
         , vDetail.DMT_BASE_PRICE
         , vDetail.POS_IMPUTATION
         , vDetail.A_DATECRE
         , vDetail.A_IDCRE
      from DOC_JOURNAL_HEADER DJN
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aOldPos.PAC_THIRD_ID) THI
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aOldPos.PAC_THIRD_ACI_ID) THI_ACI
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aOldPos.PAC_THIRD_DELIVERY_ID) THI_DELIVERY
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aOldPos.PAC_THIRD_TARIFF_ID) THI_TARIFF
         , (select max(PER_NAME) PER_NAME
                 , max(PER_KEY1) PER_KEY1
              from PAC_PERSON
             where PAC_PERSON_ID = aOldPos.PAC_PERSON_ID) PER
         , (select max(PER_FIRST_NAME) PER_FIRST_NAME
                 , max(PER_LAST_NAME) PER_LAST_NAME
              from HRM_PERSON
             where HRM_PERSON_ID = aOldPos.HRM_PERSON_ID) HRM
         , (select max(FIX_NUMBER) FIX_NUMBER
              from FAM_FIXED_ASSETS
             where FAM_FIXED_ASSETS_ID = aOldPos.FAM_FIXED_ASSETS_ID) FIX
         , (select max(GOO_MAJOR_REFERENCE) GOO_MAJOR_REFERENCE
                 , max(GOO_NUMBER_OF_DECIMAL) GOO_NUMBER_OF_DECIMAL
              from GCO_GOOD
             where GCO_GOOD_ID = aOldPos.GCO_GOOD_ID) GOO
         , (select max(STO_DESCRIPTION) STO_DESCRIPTION
              from STM_STOCK
             where STM_STOCK_ID = aOldPos.STM_STOCK_ID) STO
         , (select max(LOC_DESCRIPTION) LOC_DESCRIPTION
              from STM_LOCATION
             where STM_LOCATION_ID = aOldPos.STM_LOCATION_ID) LOC
         , (select max(RCO_TITLE) RCO_TITLE
              from DOC_RECORD
             where DOC_RECORD_ID = aOldPos.DOC_RECORD_ID) RCO
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aOldPos.PAC_REPRESENTATIVE_ID) REP
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aOldPos.PAC_REPR_ACI_ID) REP_ACI
         , (select max(REP_DESCR) REP_DESCR
              from PAC_REPRESENTATIVE
             where PAC_REPRESENTATIVE_ID = aOldPos.PAC_REPR_DELIVERY_ID) REP_DELIVERY
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_FINANCIAL_ACCOUNT_ID) FIN
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_DIVISION_ACCOUNT_ID) DIV
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_CPN_ACCOUNT_ID) CPN
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_CDA_ACCOUNT_ID) CDA
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_PF_ACCOUNT_ID) PF
         , (select max(ACC_NUMBER) ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = aOldPos.ACS_PJ_ACCOUNT_ID) PJ
     where DJN.DOC_DOCUMENT_ID = aOldPos.DOC_DOCUMENT_ID
       and GAU.DOC_GAUGE_ID = nvl(aOldPos.DOC_GAUGE_ID, vDOC_GAUGE_ID)
       and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;

    if vDetail.DJD_JOURNAL_QTY <> 0 then
      if    (aDetailProv = 1)
         or (aOldPos.C_DOC_POS_STATUS = '01') then
        vDetailProv  := GetDetailProvStruct(vDetail);

        insert into DOC_JOURNAL_DETAIL_PROV
             values vDetailProv;
      else
        insert into DOC_JOURNAL_DETAIL
             values vDetail;
      end if;
    end if;
  exception
    when no_data_found then
      null;
  end CreateDetailExt;

  /**
  * procedure CreateDetail_Confirm
  * Description
  *   Création des détails de journalisation lors de la confirmation
  *     et écritures sur les positions père liées à la confirmation de la position fille
  */
  procedure CreateDetail_Confirm(aOldPos in DOC_POSITION%rowtype, aNewPos in DOC_POSITION%rowtype)
  is
    tplPos        DOC_POSITION%rowtype;
    vDetailID     DOC_JOURNAL_DETAIL.DOC_JOURNAL_DETAIL_ID%type;
    vDetailProvID DOC_JOURNAL_DETAIL_PROV.DOC_JOURNAL_DETAIL_PROV_ID%type;
    vQuantity     DOC_JOURNAL_DETAIL.DJD_JOURNAL_QTY%type;
    vDetail       DOC_JOURNAL_DETAIL%rowtype;
    vDetailProv   DOC_JOURNAL_DETAIL_PROV%rowtype;
  begin
    DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
    DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := null;

    -- Recherche l'id de la position source de la décharge (s'il y a eu décharge).
    select max(PDE_SRC.DOC_POSITION_ID)
      into DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID
      from DOC_POSITION_DETAIL PDE_TGT
         , DOC_POSITION_DETAIL PDE_SRC
     where PDE_TGT.DOC_POSITION_ID = aNewPos.DOC_POSITION_ID
       and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID;

    -- Ecriture d'extourne
    CreateDetailExt(aCode => 'CONFIRM', aOldPos => aOldPos, aNewPos => aNewPos);
    -- Ecriture
    CreateDetail(aCode => 'CONFIRM', aOldPos => aOldPos, aNewPos => aNewPos);

    -- Effectuer les écritures sur la position père
    if DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID is not null then
      DOC_JOURNAL_FUNCTIONS.CURRENT_TRANSACTION  := DBMS_TRANSACTION.local_transaction_id;
      DOC_JOURNAL_FUNCTIONS.DISCH_TGT_POS_ID     := aNewPos.DOC_POSITION_ID;
      DOC_JOURNAL_FUNCTIONS.DISCH_TGT_DOC_ID     := aNewPos.DOC_DOCUMENT_ID;

      -- Infos de la position source doivent être recherchées dans la table
      -- DOC_JOURNAL_DETAIL ou DOC_JOURNAL_DETAIL_PROV parce que l'on est dans le trigger de la position
      select max(DOC_JOURNAL_DETAIL_ID) DETAIL_ID
        into vDetailID
        from DOC_JOURNAL_DETAIL
       where DOC_POSITION_ID = DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID;

      select max(DOC_JOURNAL_DETAIL_PROV_ID) DETAIL_ID
        into vDetailProvID
        from DOC_JOURNAL_DETAIL_PROV
       where DOC_POSITION_ID = DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID;

      -- Info trouvée
      if nvl(vDetailID, vDetailProvID) is not null then
        -- Récuperer les données du tuple
        if nvl(vDetailProvID, 0) > nvl(vDetailID, 0) then
          select *
            into vDetailProv
            from DOC_JOURNAL_DETAIL_PROV
           where DOC_JOURNAL_DETAIL_PROV_ID = vDetailProvID;
        else
          select *
            into vDetail
            from DOC_JOURNAL_DETAIL
           where DOC_JOURNAL_DETAIL_ID = vDetailID;

          vDetailProv  := GetDetailProvStruct(vDetail);
        end if;

        select vDetailProv.DOC_POSITION_ID
             , vDetailProv.DOC_DOCUMENT_ID
             , vDetailProv.GCO_GOOD_ID
             , vDetailProv.DOC_GAUGE_ID
             , vDetailProv.DOC_RECORD_ID
             , vDetailProv.ACS_FINANCIAL_ACCOUNT_ID
             , vDetailProv.ACS_DIVISION_ACCOUNT_ID
             , vDetailProv.ACS_CPN_ACCOUNT_ID
             , vDetailProv.ACS_CDA_ACCOUNT_ID
             , vDetailProv.ACS_PF_ACCOUNT_ID
             , vDetailProv.ACS_PJ_ACCOUNT_ID
             , vDetailProv.PAC_THIRD_ID
             , vDetailProv.PAC_THIRD_ACI_ID
             , vDetailProv.PAC_THIRD_DELIVERY_ID
             , vDetailProv.PAC_THIRD_TARIFF_ID
             , vDetailProv.PAC_REPRESENTATIVE_ID
             , vDetailProv.PAC_REPR_ACI_ID
             , vDetailProv.PAC_REPR_DELIVERY_ID
             , vDetailProv.PAC_PERSON_ID
             , vDetailProv.FAM_FIXED_ASSETS_ID
             , vDetailProv.HRM_PERSON_ID
             , vDetailProv.POS_NUMBER
             , vDetailProv.POS_REFERENCE
             , vDetailProv.POS_SHORT_DESCRIPTION
             , vDetailProv.POS_LONG_DESCRIPTION
             , vDetailProv.STM_STOCK_ID
             , vDetailProv.STM_LOCATION_ID
             , vDetailProv.C_GAUGE_TYPE_POS
             , vDetailProv.C_DOC_POS_STATUS
             , vDetailProv.C_FAM_TRANSACTION_TYP
             , vDetailProv.POS_IMF_NUMBER_2
             , vDetailProv.POS_IMF_NUMBER_3
             , vDetailProv.POS_IMF_NUMBER_4
             , vDetailProv.POS_IMF_NUMBER_5
             , vDetailProv.POS_IMF_TEXT_1
             , vDetailProv.POS_IMF_TEXT_2
             , vDetailProv.POS_IMF_TEXT_3
             , vDetailProv.POS_IMF_TEXT_4
             , vDetailProv.POS_IMF_TEXT_5
             , vDetailProv.DIC_IMP_FREE1_ID
             , vDetailProv.DIC_IMP_FREE2_ID
             , vDetailProv.DIC_IMP_FREE3_ID
             , vDetailProv.DIC_IMP_FREE4_ID
             , vDetailProv.DIC_IMP_FREE5_ID
             , vDetailProv.DJD_NEW_POS_BASIS_QTY
             , vDetailProv.DJD_NEW_POS_INTER_QTY
             , vDetailProv.DJD_NEW_POS_FINAL_QTY
             , vDetailProv.DJD_NEW_POS_BALANCE_QTY
             , vDetailProv.POS_CONVERT_FACTOR
             , vDetailProv.DJD_NEW_POS_BASIS_QTY_SU
             , vDetailProv.DJD_NEW_POS_INTER_QTY_SU
             , vDetailProv.DJD_NEW_POS_FINAL_QTY_SU
             , vDetailProv.POS_GROSS_UNIT_VALUE
             , vDetailProv.POS_GROSS_UNIT_VALUE_INCL
             , vDetailProv.POS_NET_UNIT_VALUE
             , vDetailProv.POS_NET_UNIT_VALUE_INCL
             , abs(vDetailProv.POS_GROSS_VALUE) * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs(vDetailProv.POS_GROSS_VALUE_INCL) * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs(vDetailProv.POS_NET_VALUE_EXCL) * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs(vDetailProv.POS_NET_VALUE_INCL) * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs( (vDetailProv.POS_GROSS_VALUE_B / vDetailProv.DJD_JOURNAL_QTY) * vDetailProv.DJD_NEW_POS_FINAL_QTY) * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs( (vDetailProv.POS_GROSS_VALUE_INCL_B / vDetailProv.DJD_JOURNAL_QTY) * vDetailProv.DJD_NEW_POS_FINAL_QTY) *
               sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs( (vDetailProv.POS_NET_VALUE_EXCL_B / vDetailProv.DJD_JOURNAL_QTY) * vDetailProv.DJD_NEW_POS_FINAL_QTY)
               * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , abs( (vDetailProv.POS_NET_VALUE_INCL_B / vDetailProv.DJD_JOURNAL_QTY) * vDetailProv.DJD_NEW_POS_FINAL_QTY)
               * sign(vDetailProv.POS_GROSS_UNIT_VALUE)
             , vDetailProv.POS_IMPUTATION
          into tplPos.DOC_POSITION_ID
             , tplPos.DOC_DOCUMENT_ID
             , tplPos.GCO_GOOD_ID
             , tplPos.DOC_GAUGE_ID
             , tplPos.DOC_RECORD_ID
             , tplPos.ACS_FINANCIAL_ACCOUNT_ID
             , tplPos.ACS_DIVISION_ACCOUNT_ID
             , tplPos.ACS_CPN_ACCOUNT_ID
             , tplPos.ACS_CDA_ACCOUNT_ID
             , tplPos.ACS_PF_ACCOUNT_ID
             , tplPos.ACS_PJ_ACCOUNT_ID
             , tplPos.PAC_THIRD_ID
             , tplPos.PAC_THIRD_ACI_ID
             , tplPos.PAC_THIRD_DELIVERY_ID
             , tplPos.PAC_THIRD_TARIFF_ID
             , tplPos.PAC_REPRESENTATIVE_ID
             , tplPos.PAC_REPR_ACI_ID
             , tplPos.PAC_REPR_DELIVERY_ID
             , tplPos.PAC_PERSON_ID
             , tplPos.FAM_FIXED_ASSETS_ID
             , tplPos.HRM_PERSON_ID
             , tplPos.POS_NUMBER
             , tplPos.POS_REFERENCE
             , tplPos.POS_SHORT_DESCRIPTION
             , tplPos.POS_LONG_DESCRIPTION
             , tplPos.STM_STOCK_ID
             , tplPos.STM_LOCATION_ID
             , tplPos.C_GAUGE_TYPE_POS
             , tplPos.C_DOC_POS_STATUS
             , tplPos.C_FAM_TRANSACTION_TYP
             , tplPos.POS_IMF_NUMBER_2
             , tplPos.POS_IMF_NUMBER_3
             , tplPos.POS_IMF_NUMBER_4
             , tplPos.POS_IMF_NUMBER_5
             , tplPos.POS_IMF_TEXT_1
             , tplPos.POS_IMF_TEXT_2
             , tplPos.POS_IMF_TEXT_3
             , tplPos.POS_IMF_TEXT_4
             , tplPos.POS_IMF_TEXT_5
             , tplPos.DIC_IMP_FREE1_ID
             , tplPos.DIC_IMP_FREE2_ID
             , tplPos.DIC_IMP_FREE3_ID
             , tplPos.DIC_IMP_FREE4_ID
             , tplPos.DIC_IMP_FREE5_ID
             , tplPos.POS_BASIS_QUANTITY
             , tplPos.POS_INTERMEDIATE_QUANTITY
             , tplPos.POS_FINAL_QUANTITY
             , tplPos.POS_BALANCE_QUANTITY
             , tplPos.POS_CONVERT_FACTOR
             , tplPos.POS_BASIS_QUANTITY_SU
             , tplPos.POS_INTERMEDIATE_QUANTITY_SU
             , tplPos.POS_FINAL_QUANTITY_SU
             , tplPos.POS_GROSS_UNIT_VALUE
             , tplPos.POS_GROSS_UNIT_VALUE_INCL
             , tplPos.POS_NET_UNIT_VALUE
             , tplPos.POS_NET_UNIT_VALUE_INCL
             , tplPos.POS_GROSS_VALUE
             , tplPos.POS_GROSS_VALUE_INCL
             , tplPos.POS_NET_VALUE_EXCL
             , tplPos.POS_NET_VALUE_INCL
             , tplPos.POS_GROSS_VALUE_B
             , tplPos.POS_GROSS_VALUE_INCL_B
             , tplPos.POS_NET_VALUE_EXCL_B
             , tplPos.POS_NET_VALUE_INCL_B
             , tplPos.POS_IMPUTATION
          from dual;

        -- Recherche la qté sur la position fille
        select nvl(sum(PDE_FINAL_QUANTITY), 0) + nvl(sum(PDE_BALANCE_QUANTITY_PARENT), 0)
          into vQuantity
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = aNewPos.DOC_POSITION_ID;

        DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
        DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := aNewPos.DOC_POSITION_ID;
        -- Ecriture d'extourne
        CreateDetailExt(aCode            => 'CONF_TGT'
                      , aOldPos          => tplPos
                      , aNewPos          => tplPos
                      , aDetailProv      => 1
                      , aForceStatus     => '04'
                      , aForceQuantity   => 1
                      , aQuantity        => vQuantity * -1
                       );
        -- Ecriture
        CreateDetail(aCode            => 'CONF_TGT'
                   , aOldPos          => tplPos
                   , aNewPos          => tplPos
                   , aDetailProv      => 0
                   , aForceStatus     => '04'
                   , aForceQuantity   => 1
                   , aQuantity        => vQuantity
                    );
        SRC_DOC_POSITION_ID                        := null;
        TGT_DOC_POSITION_ID                        := null;
        DOC_JOURNAL_FUNCTIONS.CURRENT_TRANSACTION  := null;
      end if;
    end if;
  end CreateDetail_Confirm;

  /**
  * procedure OnPosDetailDelete
  * Description
  *   Journalisation sur la position source lors de l'effacement d'un détail issu d'une décharge
  */
  procedure OnPosDetailDelete(aDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    vSrcPdeID   DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vSrcPosID   DOC_POSITION.DOC_POSITION_ID%type;
    tplPos      DOC_POSITION%rowtype;
    vQuantity   DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    vDetailProv integer                                           default 0;
    vDocID      DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPosID      DOC_POSITION.DOC_POSITION_ID%type;
    vPosStatus  DOC_POSITION.C_DOC_POS_STATUS%type;
  begin
    -- Qté de journal -> Qté du détail - qté soldée sur parent
    select PDE.DOC_DOC_POSITION_DETAIL_ID
         , (PDE.PDE_FINAL_QUANTITY + PDE_BALANCE_QUANTITY) * -1
         , POS.DOC_POSITION_ID
         , POS.C_DOC_POS_STATUS
         , POS.DOC_DOCUMENT_ID
      into vSrcPdeID
         , vQuantity
         , vPosID
         , vPosStatus
         , vDocID
      from DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where PDE.DOC_POSITION_DETAIL_ID = aDetailID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID;

    if vSrcPdeID is not null then
      -- Rechercher l'id de la position source
      select DOC_POSITION_ID
        into vSrcPosID
        from DOC_POSITION_DETAIL
       where DOC_POSITION_DETAIL_ID = vSrcPdeID;

      DOC_JOURNAL_FUNCTIONS.CURRENT_TRANSACTION  := DBMS_TRANSACTION.local_transaction_id;
      DOC_JOURNAL_FUNCTIONS.DISCH_SRC_POS_ID     := vSrcPosID;
      DOC_JOURNAL_FUNCTIONS.DISCH_TGT_POS_ID     := vPosID;
      DOC_JOURNAL_FUNCTIONS.DISCH_TGT_DOC_ID     := vDocID;
      DOC_JOURNAL_FUNCTIONS.DISCH_CODE           := 'DELETE';

      -- Vérifier si l'on doit faire la journalisation de la position père
      if DOC_JOURNAL_FUNCTIONS.MustPosJournalize(vSrcPosID) = 1 then
        -- Rechercher les infos de la position père
        select *
          into tplPos
          from DOC_POSITION
         where DOC_POSITION_ID = vSrcPosID;

        -- si la position a le statut à confirmer, il faut journaliser dans la table provisoire
        if vPosStatus = '01' then
          vDetailProv  := 1;
        end if;

        DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
        DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := vPosID;
        -- Ecriture d'extourne
        DOC_JOURNAL_FUNCTIONS.CreateDetailExt(aCode            => 'DEL_TGT'
                                            , aOldPos          => tplPos
                                            , aNewPos          => tplPos
                                            , aDetailProv      => vDetailProv
                                            , aForceStatus     => '04'
                                            , aForceQuantity   => 1
                                            , aQuantity        => vQuantity
                                             );
        DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
        DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := null;
      end if;
    end if;
  end OnPosDetailDelete;

  /*
  * procedure JournalizeSrcPositions
  * Description
  *   Effectuer les écritures sur les positions source de décharge
  *     des positions du document courant suite à la modification de
  *     la date valeur sur le document courant
  */
  procedure JournalizeSrcPositions(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    type TDOC_JOURNAL_DETAIL is table of DOC_JOURNAL_DETAIL%rowtype;

    type TDOC_JOURNAL_DETAIL_PROV is table of DOC_JOURNAL_DETAIL_PROV%rowtype;

    tabDetailList     TDOC_JOURNAL_DETAIL;
    tabDetailListProv TDOC_JOURNAL_DETAIL_PROV;
    tplDetail         DOC_JOURNAL_DETAIL%rowtype;
    tplDetailProv     DOC_JOURNAL_DETAIL_PROV%rowtype;

    -- Liste des positions du document courant qui sont issues de décharge
    cursor crPositions
    is
      (select distinct POS_TGT.DOC_POSITION_ID TGT_POS_ID
                     , PDE_SRC.DOC_POSITION_ID SRC_POS_ID
                     , PDE_SRC.DOC_DOCUMENT_ID SRC_DOC_ID
                  from DOC_POSITION POS_TGT
                     , DOC_POSITION_DETAIL PDE_TGT
                     , DOC_POSITION_DETAIL PDE_SRC
                 where POS_TGT.DOC_DOCUMENT_ID = aDocumentID
                   and POS_TGT.DOC_POSITION_ID = PDE_TGT.DOC_POSITION_ID
                   and PDE_TGT.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID);

    vIndex            integer;
    vDJD_ID           DOC_JOURNAL_DETAIL.DOC_JOURNAL_DETAIL_ID%type;
    vDJP_ID           DOC_JOURNAL_DETAIL_PROV.DOC_JOURNAL_DETAIL_PROV_ID%type;
    vTransactionID    DOC_JOURNAL_DETAIL.DJD_TRANSACTION_ID%type;
  begin
    -- Liste des positions du document courant qui sont issues de décharge
    for tplPositions in crPositions loop
      -- Vérifier si la position source a déjà été journalisée
      -- en ce qui concerne la décharge de la position fille et en sortir l'id de la dernière écriture
      -- Vérification dans la table DOC_JOURNAL_DETAIL et DOC_JOURNAL_DETAIL_PROV
      select max(DOC_JOURNAL_DETAIL_ID)
        into vDJD_ID
        from DOC_JOURNAL_DETAIL
       where DOC_DOCUMENT_ID = tplPositions.SRC_DOC_ID
         and DOC_POSITION_ID = tplPositions.SRC_POS_ID
         and TGT_DOC_POSITION_ID = tplPositions.TGT_POS_ID;

      select max(DOC_JOURNAL_DETAIL_PROV_ID)
        into vDJP_ID
        from DOC_JOURNAL_DETAIL_PROV
       where DOC_DOCUMENT_ID = tplPositions.SRC_DOC_ID
         and DOC_POSITION_ID = tplPositions.SRC_POS_ID
         and TGT_DOC_POSITION_ID = tplPositions.TGT_POS_ID;

      -- La position source a déjà été journalisée
      -- En ce qui concerne la décharge de la position fille
      if nvl(vDJD_ID, vDJP_ID) is not null then
        -- Récupérer l'id de la transaction de la dernière écriture concernant le lien de décharge
        if nvl(vDJD_ID, 0) > nvl(vDJP_ID, 0) then
          select DJD_TRANSACTION_ID
            into vTransactionID
            from DOC_JOURNAL_DETAIL
           where DOC_JOURNAL_DETAIL_ID = vDJD_ID;
        else
          select DJD_TRANSACTION_ID
            into vTransactionID
            from DOC_JOURNAL_DETAIL_PROV
           where DOC_JOURNAL_DETAIL_PROV_ID = vDJP_ID;
        end if;

        -- Récuperer toutes les écritures sur le document père qui concernent le lien de décharge
        -- qui sont dans la dernière transaction concernant le lien de décharge
        select   *
        bulk collect into tabDetailList
            from DOC_JOURNAL_DETAIL
           where DOC_DOCUMENT_ID = tplPositions.SRC_DOC_ID
             and DOC_POSITION_ID = tplPositions.SRC_POS_ID
             and TGT_DOC_POSITION_ID = tplPositions.TGT_POS_ID
             and DJD_TRANSACTION_ID = vTransactionID
        order by DOC_JOURNAL_DETAIL_ID;

        -- Récuperer toutes les écritures sur le document père qui concernent le lien de décharge
        -- qui sont dans la dernière transaction concernant le lien de décharge
        select   *
        bulk collect into tabDetailListProv
            from DOC_JOURNAL_DETAIL_PROV
           where DOC_DOCUMENT_ID = tplPositions.SRC_DOC_ID
             and DOC_POSITION_ID = tplPositions.SRC_POS_ID
             and TGT_DOC_POSITION_ID = tplPositions.TGT_POS_ID
             and DJD_TRANSACTION_ID = vTransactionID
        order by DOC_JOURNAL_DETAIL_PROV_ID;

        -- Liste des écritures "définitives" pour la dernière transaction
        if tabDetailList.count > 0 then
          for vIndex in tabDetailList.first .. tabDetailList.last loop
            tplDetail                            := tabDetailList(vIndex);

            -- Création de l'écriture "inverse" à l'ancienne date valeur du document cible
            select INIT_ID_SEQ.nextval
              into tplDetail.DOC_JOURNAL_DETAIL_ID
              from dual;

            tplDetail.C_DOC_JOURNAL_DETAIL       := 'TGT_DATE';

            if tabDetailList(vIndex).DJD_REVERSAL_ENTRY = 0 then
              tplDetail.DJD_REVERSAL_ENTRY  := 1;
            else
              tplDetail.DJD_REVERSAL_ENTRY  := 0;
            end if;

            tplDetail.DJD_JOURNAL_QTY            := tabDetailList(vIndex).DJD_JOURNAL_QTY * -1;
            tplDetail.DJD_JOURNAL_VALUE_DATE     := vDOC_INFO.OLD_DMT_DATE_VALUE;
            tplDetail.DJD_JOURNAL_DOCUMENT_DATE  := vDOC_INFO.OLD_DMT_DATE_DOCUMENT;
            tplDetail.POS_GROSS_VALUE            := tabDetailList(vIndex).POS_GROSS_VALUE * -1;
            tplDetail.POS_GROSS_VALUE_B          := tabDetailList(vIndex).POS_GROSS_VALUE_B * -1;
            tplDetail.POS_GROSS_VALUE_INCL       := tabDetailList(vIndex).POS_GROSS_VALUE_INCL * -1;
            tplDetail.POS_GROSS_VALUE_INCL_B     := tabDetailList(vIndex).POS_GROSS_VALUE_INCL_B * -1;
            tplDetail.POS_NET_VALUE_EXCL         := tabDetailList(vIndex).POS_NET_VALUE_EXCL * -1;
            tplDetail.POS_NET_VALUE_EXCL_B       := tabDetailList(vIndex).POS_NET_VALUE_EXCL_B * -1;
            tplDetail.POS_NET_VALUE_INCL         := tabDetailList(vIndex).POS_NET_VALUE_INCL * -1;
            tplDetail.POS_NET_VALUE_INCL_B       := tabDetailList(vIndex).POS_NET_VALUE_INCL_B * -1;
            tplDetail.A_DATECRE                  := sysdate;
            tplDetail.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;

            insert into DOC_JOURNAL_DETAIL
                 values tplDetail;

            tplDetail                            := tabDetailList(vIndex);

            -- Création de l'écriture à la nouvelle date valeur du document cible
            select INIT_ID_SEQ.nextval
              into tplDetail.DOC_JOURNAL_DETAIL_ID
              from dual;

            tplDetail.C_DOC_JOURNAL_DETAIL       := 'TGT_DATE';
            tplDetail.DJD_JOURNAL_VALUE_DATE     := vDOC_INFO.NEW_DMT_DATE_VALUE;
            tplDetail.DJD_JOURNAL_DOCUMENT_DATE  := vDOC_INFO.NEW_DMT_DATE_DOCUMENT;
            tplDetail.A_DATECRE                  := sysdate;
            tplDetail.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;

            insert into DOC_JOURNAL_DETAIL
                 values tplDetail;
          end loop;
        end if;

        -- Liste des écritures "provisoires" pour la dernière transaction
        if tabDetailListProv.count > 0 then
          for vIndex in tabDetailListProv.first .. tabDetailListProv.last loop
            tplDetailProv                            := tabDetailListProv(vIndex);

            -- Création de l'écriture "inverse" à l'ancienne date valeur du document cible
            select INIT_ID_SEQ.nextval
              into tplDetailProv.DOC_JOURNAL_DETAIL_PROV_ID
              from dual;

            tplDetailProv.C_DOC_JOURNAL_DETAIL       := 'TGT_DATE';

            if tabDetailListProv(vIndex).DJD_REVERSAL_ENTRY = 0 then
              tplDetailProv.DJD_REVERSAL_ENTRY  := 1;
            else
              tplDetailProv.DJD_REVERSAL_ENTRY  := 0;
            end if;

            tplDetailProv.DJD_JOURNAL_QTY            := tabDetailListProv(vIndex).DJD_JOURNAL_QTY * -1;
            tplDetailProv.DJD_JOURNAL_VALUE_DATE     := vDOC_INFO.OLD_DMT_DATE_VALUE;
            tplDetailProv.DJD_JOURNAL_DOCUMENT_DATE  := vDOC_INFO.OLD_DMT_DATE_DOCUMENT;
            tplDetailProv.POS_GROSS_VALUE            := tabDetailListProv(vIndex).POS_GROSS_VALUE * -1;
            tplDetailProv.POS_GROSS_VALUE_B          := tabDetailListProv(vIndex).POS_GROSS_VALUE_B * -1;
            tplDetailProv.POS_GROSS_VALUE_INCL       := tabDetailListProv(vIndex).POS_GROSS_VALUE_INCL * -1;
            tplDetailProv.POS_GROSS_VALUE_INCL_B     := tabDetailListProv(vIndex).POS_GROSS_VALUE_INCL_B * -1;
            tplDetailProv.POS_NET_VALUE_EXCL         := tabDetailListProv(vIndex).POS_NET_VALUE_EXCL * -1;
            tplDetailProv.POS_NET_VALUE_EXCL_B       := tabDetailListProv(vIndex).POS_NET_VALUE_EXCL_B * -1;
            tplDetailProv.POS_NET_VALUE_INCL         := tabDetailListProv(vIndex).POS_NET_VALUE_INCL * -1;
            tplDetailProv.POS_NET_VALUE_INCL_B       := tabDetailListProv(vIndex).POS_NET_VALUE_INCL_B * -1;
            tplDetailProv.A_DATECRE                  := sysdate;
            tplDetailProv.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;

            insert into DOC_JOURNAL_DETAIL_PROV
                 values tplDetailProv;

            tplDetailProv                            := tabDetailListProv(vIndex);

            -- Création de l'écriture à la nouvelle date valeur du document cible
            select INIT_ID_SEQ.nextval
              into tplDetailProv.DOC_JOURNAL_DETAIL_PROV_ID
              from dual;

            tplDetailProv.C_DOC_JOURNAL_DETAIL       := 'TGT_DATE';
            tplDetailProv.DJD_JOURNAL_VALUE_DATE     := vDOC_INFO.NEW_DMT_DATE_VALUE;
            tplDetailProv.DJD_JOURNAL_DOCUMENT_DATE  := vDOC_INFO.NEW_DMT_DATE_DOCUMENT;
            tplDetailProv.A_DATECRE                  := sysdate;
            tplDetailProv.A_IDCRE                    := PCS.PC_I_LIB_SESSION.GetUserIni;

            insert into DOC_JOURNAL_DETAIL_PROV
                 values tplDetailProv;
          end loop;
        end if;
      end if;
    end loop;
  end JournalizeSrcPositions;

  /**
  * procedure RedoDocJournal
  * Description
  *   Reconstruction du journal pour un document
  */
  procedure RedoDocJournal(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    type TPOS_TGT is record(
      DOC_POSITION_ID  DOC_POSITION.DOC_POSITION_ID%type
    , C_DOC_POS_STATUS DOC_POSITION.C_DOC_POS_STATUS%type
    , DISCH_QUANTITY   DOC_POSITION.POS_FINAL_QUANTITY%type
    , DOC_DOCUMENT_ID  DOC_DOCUMENT.DOC_DOCUMENT_ID%type
    , DMT_DATE_VALUE   DOC_DOCUMENT.DMT_DATE_VALUE%type
    , A_DATECRE        DOC_POSITION.A_DATECRE%type
    , A_IDCRE          DOC_POSITION.A_IDCRE%type
    );

    type TBL_POS_TGT is table of TPOS_TGT;

    tblPosTgt    TBL_POS_TGT;
    tplDoc       DOC_DOCUMENT%rowtype;
    tplPosition  DOC_POSITION%rowtype;
    vPos         DOC_POSITION%rowtype;
    vJournalCode DOC_JOURNAL_DETAIL.C_DOC_JOURNAL_DETAIL%type;
    vQuantity    DOC_JOURNAL_DETAIL.DJD_JOURNAL_QTY%type;
    vDetailProv  integer                                        default 0;
    vSumBalQty   DOC_POSITION.POS_BALANCE_QUANTITY%type;
    vDateCre     DOC_JOURNAL_DETAIL.A_DATECRE%type;
    vIdCre       DOC_JOURNAL_DETAIL.A_IDCRE%type;
  begin
    -- Infos sur le document
    select *
      into tplDoc
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentID;

    -- Vérifier si le document doit être journalisé
    if MustJournalize(tplDoc.DOC_GAUGE_ID) = 1 then
      -- Effacer l'entête journal et les écritures (grâce au delete cascade) du document
      delete from DOC_JOURNAL_HEADER
            where DOC_DOCUMENT_ID = aDocumentID;

      -- Recréer l'entête journal pour notre document
      JournalizeDocument('INSERT', tplDoc, tplDoc);

      -- Màj la date de l'écriture journalisation à la date de création du document
      update DOC_JOURNAL_HEADER
         set A_DATECRE = DJN_DMT_DATECRE
           , A_IDCRE = DJN_DMT_IDCRE
       where DOC_DOCUMENT_ID = aDocumentID;

      -- Listes des positions du document qui peuvent être journalisées
      for tplPosition in (select   *
                              from DOC_POSITION
                             where DOC_DOCUMENT_ID = aDocumentID
                               and C_GAUGE_TYPE_POS in('1', '7', '8', '10', '81', '91', '21')
                          order by POS_NUMBER) loop
        -- Vérifier si la position doit être journalisée
        if MustPosJournalize(tplPosition.DOC_POSITION_ID) = 1 then
          vPos      := tplPosition;

          -- Vérifier si la position a été déchargée
          -- Listes des positions cible (décharge) de la position courante
          select distinct POS_TGT.DOC_POSITION_ID
                        , POS_TGT.C_DOC_POS_STATUS
                        , sum(nvl(PDE_TGT.PDE_FINAL_QUANTITY, 0) + nvl(PDE_TGT.PDE_BALANCE_QUANTITY_PARENT, 0) )
                        , POS_TGT.DOC_DOCUMENT_ID
                        , DMT_TGT.DMT_DATE_VALUE
                        , POS_TGT.A_DATECRE
                        , POS_TGT.A_IDCRE
          bulk collect into tblPosTgt
                     from DOC_POSITION_DETAIL PDE_SRC
                        , DOC_POSITION_DETAIL PDE_TGT
                        , DOC_POSITION POS_TGT
                        , DOC_DOCUMENT DMT_TGT
                    where PDE_SRC.DOC_POSITION_ID = vPos.DOC_POSITION_ID
                      and PDE_SRC.DOC_POSITION_DETAIL_ID = PDE_TGT.DOC_DOC_POSITION_DETAIL_ID
                      and POS_TGT.DOC_POSITION_ID = PDE_TGT.DOC_POSITION_ID
                      and POS_TGT.DOC_DOCUMENT_ID = DMT_TGT.DOC_DOCUMENT_ID
                 group by POS_TGT.DOC_POSITION_ID
                        , POS_TGT.C_DOC_POS_STATUS
                        , POS_TGT.DOC_DOCUMENT_ID
                        , DMT_TGT.DMT_DATE_VALUE
                        , POS_TGT.A_DATECRE
                        , POS_TGT.A_IDCRE
                 order by DMT_TGT.DMT_DATE_VALUE
                        , POS_TGT.DOC_POSITION_ID;

          -- si position crée par décharge
          if substr(vPos.C_POS_CREATE_MODE, 1, 1) = '3' then
            vJournalCode  := 'INS_DISCH';
          else
            vJournalCode  := 'INSERT';
          end if;

          -- Date de création de l'écriture comme la date de création de la position
          vDateCre  := vPos.A_DATECRE;
          vIdCre    := vPos.A_IDCRE;

          -- La position n'a pas été déchargée
          if tblPosTgt.count = 0 then
            -- Qté journal
            vQuantity  := vPos.POS_FINAL_QUANTITY;

            -- Position soldée par l'utilisateur
            if vPos.POS_BALANCED = 1 then
              -- Valeurs pour la 1ère écriture de la position
              vPos.POS_BALANCE_QUANTITY  := vPos.POS_FINAL_QUANTITY;
              vPos.C_DOC_POS_STATUS      := '02';
              -- Effectuer l'écriture de création de la position
              DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => vJournalCode
                                               , aOldPos          => vPos
                                               , aNewPos          => vPos
                                               , aDetailProv      => 0
                                               , aForceStatus     => '02'
                                               , aForceQuantity   => 1
                                               , aQuantity        => vQuantity
                                               , aDateCre         => vDateCre
                                               , aIdCre           => vIdCre
                                                );

              -- Vérifier s'il s'agit d'un solde ou solde avec extourne
              select case
                       when nvl(max(SMO_EXTOURNE_MVT), 0) = 1 then 'BAL_EXT'
                       else 'BALANCE'
                     end
                into vJournalCode
                from STM_STOCK_MOVEMENT
               where DOC_POSITION_ID = vPos.DOC_POSITION_ID;

              -- Effectuer l'extourne de la position courante au statut '02'
              vQuantity                  := vPos.POS_FINAL_QUANTITY * -1;
              vPos.POS_BALANCE_QUANTITY  := vPos.POS_FINAL_QUANTITY;
              -- Date de création de l'écriture comme la date du solde de la position
              vDateCre                   := nvl(vPos.POS_DATE_BALANCED, nvl(vPos.A_DATEMOD, vPos.A_DATECRE) );
              vIdCre                     := nvl(vPos.A_IDMOD, vPos.A_IDCRE);
              DOC_JOURNAL_FUNCTIONS.CreateDetailExt(aCode            => vJournalCode
                                                  , aOldPos          => vPos
                                                  , aNewPos          => vPos
                                                  , aDetailProv      => 0
                                                  , aForceStatus     => '02'
                                                  , aForceQuantity   => 1
                                                  , aQuantity        => vQuantity
                                                  , aDateCre         => vDateCre
                                                  , aIdCre           => vIdCre
                                                   );
              -- Effectuer l'écriture de solde de la position
              vQuantity                  := vPos.POS_FINAL_QUANTITY;
              vPos.POS_BALANCE_QUANTITY  := 0;
              DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => vJournalCode
                                               , aOldPos          => vPos
                                               , aNewPos          => vPos
                                               , aDetailProv      => 0
                                               , aForceStatus     => '04'
                                               , aForceQuantity   => 1
                                               , aQuantity        => vQuantity
                                               , aDateCre         => vDateCre
                                               , aIdCre           => vIdCre
                                                );
            else   -- La position n'a pas été soldée par l'utilisateur
              -- Effectuer l'écriture de création de la position
              DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => vJournalCode
                                               , aOldPos          => vPos
                                               , aNewPos          => vPos
                                               , aDetailProv      => 0
                                               , aForceQuantity   => 1
                                               , aQuantity        => vQuantity
                                               , aDateCre         => vDateCre
                                               , aIdCre           => vIdCre
                                                );
            end if;
          -- S'il y a eu décharge, il faut effectuer les écritures liées à ces décharges
          elsif tblPosTgt.count > 0 then
            -- Qté journal
            vQuantity                  := vPos.POS_FINAL_QUANTITY;
            -- Valeurs pour la 1ère écriture de la position
            vPos.POS_BALANCE_QUANTITY  := vPos.POS_FINAL_QUANTITY;
            vPos.C_DOC_POS_STATUS      := '02';
            -- Effectuer l'écriture de la position courante
            DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => vJournalCode
                                             , aOldPos          => vPos
                                             , aNewPos          => vPos
                                             , aDetailProv      => 0
                                             , aForceQuantity   => 1
                                             , aQuantity        => vQuantity
                                             , aDateCre         => vDateCre
                                             , aIdCre           => vIdCre
                                              );
            -- Variable contenant la variation de la qté solde de la position
            vSumBalQty                 := vPos.POS_FINAL_QUANTITY;

            -- Balayer les positions cible (qui ont déchargé la position courante)
            for vIndex in tblPosTgt.first .. tblPosTgt.last loop
              -- Indiquer quelle est la position cible
              DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
              DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := tblPosTgt(vIndex).DOC_POSITION_ID;
              DOC_JOURNAL_FUNCTIONS.DISCH_TGT_POS_ID     := tblPosTgt(vIndex).DOC_POSITION_ID;
              DOC_JOURNAL_FUNCTIONS.DISCH_TGT_DOC_ID     := tblPosTgt(vIndex).DOC_DOCUMENT_ID;
              -- Qté solde de la position source
              vSumBalQty                                 := vSumBalQty - tblPosTgt(vIndex).DISCH_QUANTITY;
              -- Date de création de l'écriture comme la date de la décharge de la position
              vDateCre                                   := tblPosTgt(vIndex).A_DATECRE;
              vIdCre                                     := tblPosTgt(vIndex).A_IDCRE;

              -- 1ère position cible, traitement spécifique
              if vIndex = 1 then
                -- Effectuer l'extourne de la position courante au statut '02'
                vQuantity                  := vPos.POS_FINAL_QUANTITY * -1;
                vPos.POS_BALANCE_QUANTITY  := vSumBalQty;
                DOC_JOURNAL_FUNCTIONS.CreateDetailExt(aCode            => 'DISCHARGED'
                                                    , aOldPos          => vPos
                                                    , aNewPos          => vPos
                                                    , aDetailProv      => 0
                                                    , aForceStatus     => '02'
                                                    , aForceQuantity   => 1
                                                    , aQuantity        => vQuantity
                                                    , aDateCre         => vDateCre
                                                    , aIdCre           => vIdCre
                                                     );

                -- Si la 1ere décharge a effectué une décharge partielle
                -- Créer une écriture avec la qté solde au statut '03'
                if tblPosTgt(vIndex).DISCH_QUANTITY <> tplPosition.POS_FINAL_QUANTITY then
                  vQuantity                  := tplPosition.POS_FINAL_QUANTITY - tblPosTgt(vIndex).DISCH_QUANTITY;
                  vPos.POS_BALANCE_QUANTITY  := vSumBalQty;
                  -- Effectuer l'écriture de la qté solde au statut '03' de la position courante
                  DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => 'DISCHARGED'
                                                   , aOldPos          => vPos
                                                   , aNewPos          => vPos
                                                   , aDetailProv      => 0
                                                   , aForceStatus     => '03'
                                                   , aForceQuantity   => 1
                                                   , aQuantity        => vQuantity
                                                   , aDateCre         => vDateCre
                                                   , aIdCre           => vIdCre
                                                    );
                end if;
              else
                -- Effectuer l'extourne de la position avec la qté déchargée
                vQuantity                  := tblPosTgt(vIndex).DISCH_QUANTITY * -1;
                vPos.POS_BALANCE_QUANTITY  := vSumBalQty;
                -- Ce n'est plus la 1ere position décharge (cible)
                -- Effectuer l'extourne de la position avec la qté déchargée
                DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => 'DISCHARGED'
                                                 , aOldPos          => vPos
                                                 , aNewPos          => vPos
                                                 , aDetailProv      => 0
                                                 , aForceStatus     => '03'
                                                 , aForceQuantity   => 1
                                                 , aQuantity        => vQuantity
                                                 , aDateCre         => vDateCre
                                                 , aIdCre           => vIdCre
                                                  );
              end if;

              -- Création de l'écriture au statut '04' correspondant à la qté déchargée
              --
              -- Ecriture dans table provisoire selon statut de la position cible
              if tblPosTgt(vIndex).C_DOC_POS_STATUS = '01' then
                vDetailProv  := 1;
              else
                vDetailProv  := 0;
              end if;

              -- Qté déchargée
              vQuantity                                  := tblPosTgt(vIndex).DISCH_QUANTITY;
              vPos.POS_BALANCE_QUANTITY                  := vSumBalQty;
              -- Effectuer l'écriture au statut '04' avec la qté déchargée par la pos cible
              DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => 'DISCHARGED'
                                               , aOldPos          => vPos
                                               , aNewPos          => vPos
                                               , aDetailProv      => vDetailProv
                                               , aForceStatus     => '04'
                                               , aForceQuantity   => 1
                                               , aQuantity        => vQuantity
                                               , aDateCre         => vDateCre
                                               , aIdCre           => vIdCre
                                                );
              DOC_JOURNAL_FUNCTIONS.SRC_DOC_POSITION_ID  := null;
              DOC_JOURNAL_FUNCTIONS.TGT_DOC_POSITION_ID  := null;
              DOC_JOURNAL_FUNCTIONS.DISCH_TGT_POS_ID     := null;
            end loop;

            -- Position soldée par l'utilisateur
            if     (vPos.POS_BALANCED = 1)
               and (vSumBalQty > 0) then
              -- Vérifier s'il s'agit d'un solde ou solde avec extourne
              select case
                       when nvl(max(SMO_EXTOURNE_MVT), 0) = 1 then 'BAL_EXT'
                       else 'BALANCE'
                     end
                into vJournalCode
                from STM_STOCK_MOVEMENT
               where DOC_POSITION_ID = vPos.DOC_POSITION_ID;

              -- Effectuer l'extourne de la position courante au statut '03'
              vQuantity                  := vSumBalQty * -1;
              vPos.POS_BALANCE_QUANTITY  := vSumBalQty;
              -- Date de création de l'écriture comme la date du solde de la position
              vDateCre                   := nvl(vPos.POS_DATE_BALANCED, nvl(vPos.A_DATEMOD, vPos.A_DATECRE) );
              vIdCre                     := nvl(vPos.A_IDMOD, vPos.A_IDCRE);
              DOC_JOURNAL_FUNCTIONS.CreateDetailExt(aCode            => vJournalCode
                                                  , aOldPos          => vPos
                                                  , aNewPos          => vPos
                                                  , aDetailProv      => 0
                                                  , aForceStatus     => '03'
                                                  , aForceQuantity   => 1
                                                  , aQuantity        => vQuantity
                                                  , aDateCre         => vDateCre
                                                  , aIdCre           => vIdCre
                                                   );
              -- Effectuer l'écriture de solde de la position
              vQuantity                  := vSumBalQty;
              vPos.POS_BALANCE_QUANTITY  := 0;
              DOC_JOURNAL_FUNCTIONS.CreateDetail(aCode            => vJournalCode
                                               , aOldPos          => vPos
                                               , aNewPos          => vPos
                                               , aDetailProv      => 0
                                               , aForceStatus     => '04'
                                               , aForceQuantity   => 1
                                               , aQuantity        => vQuantity
                                               , aDateCre         => vDateCre
                                               , aIdCre           => vIdCre
                                                );
            end if;
          end if;
        end if;
      end loop;
    end if;
  end RedoDocJournal;

  function GetDetailProvStruct(aDetail in DOC_JOURNAL_DETAIL%rowtype)
    return DOC_JOURNAL_DETAIL_PROV%rowtype
  is
    ltplDetailProv DOC_JOURNAL_DETAIL_PROV%rowtype;
  begin
    ltplDetailProv.DOC_JOURNAL_DETAIL_PROV_ID  := aDetail.DOC_JOURNAL_DETAIL_ID;
    -- Assignation de TOUS les champs de la table DOC_JOURNAL_DETAIL_PROV
    --   Champs triés par ordre alphabetique
    ltplDetailProv.ACS_CDA_ACCOUNT_ID          := aDetail.ACS_CDA_ACCOUNT_ID;
    ltplDetailProv.ACS_CPN_ACCOUNT_ID          := aDetail.ACS_CPN_ACCOUNT_ID;
    ltplDetailProv.ACS_DIVISION_ACCOUNT_ID     := aDetail.ACS_DIVISION_ACCOUNT_ID;
    ltplDetailProv.ACS_FINANCIAL_ACCOUNT_ID    := aDetail.ACS_FINANCIAL_ACCOUNT_ID;
    ltplDetailProv.ACS_PF_ACCOUNT_ID           := aDetail.ACS_PF_ACCOUNT_ID;
    ltplDetailProv.ACS_PJ_ACCOUNT_ID           := aDetail.ACS_PJ_ACCOUNT_ID;
    ltplDetailProv.A_CONFIRM                   := aDetail.A_CONFIRM;
    ltplDetailProv.A_DATECRE                   := aDetail.A_DATECRE;
    ltplDetailProv.A_DATEMOD                   := aDetail.A_DATEMOD;
    ltplDetailProv.A_IDCRE                     := aDetail.A_IDCRE;
    ltplDetailProv.A_IDMOD                     := aDetail.A_IDMOD;
    ltplDetailProv.A_RECLEVEL                  := aDetail.A_RECLEVEL;
    ltplDetailProv.A_RECSTATUS                 := aDetail.A_RECSTATUS;
    ltplDetailProv.C_ADMIN_DOMAIN              := aDetail.C_ADMIN_DOMAIN;
    ltplDetailProv.C_DOC_JOURNAL_CALCULATION   := aDetail.C_DOC_JOURNAL_CALCULATION;
    ltplDetailProv.C_DOC_JOURNAL_DETAIL        := aDetail.C_DOC_JOURNAL_DETAIL;
    ltplDetailProv.C_DOC_POS_STATUS            := aDetail.C_DOC_POS_STATUS;
    ltplDetailProv.C_FAM_TRANSACTION_TYP       := aDetail.C_FAM_TRANSACTION_TYP;
    ltplDetailProv.C_GAUGE_TITLE               := aDetail.C_GAUGE_TITLE;
    ltplDetailProv.C_GAUGE_TYPE                := aDetail.C_GAUGE_TYPE;
    ltplDetailProv.C_GAUGE_TYPE_POS            := aDetail.C_GAUGE_TYPE_POS;
    ltplDetailProv.C_PROJECT_CONSOLIDATION     := aDetail.C_PROJECT_CONSOLIDATION;
    ltplDetailProv.DIC_DOC_JOURNAL_1_ID        := aDetail.DIC_DOC_JOURNAL_1_ID;
    ltplDetailProv.DIC_DOC_JOURNAL_2_ID        := aDetail.DIC_DOC_JOURNAL_2_ID;
    ltplDetailProv.DIC_DOC_JOURNAL_3_ID        := aDetail.DIC_DOC_JOURNAL_3_ID;
    ltplDetailProv.DIC_DOC_JOURNAL_4_ID        := aDetail.DIC_DOC_JOURNAL_4_ID;
    ltplDetailProv.DIC_DOC_JOURNAL_5_ID        := aDetail.DIC_DOC_JOURNAL_5_ID;
    ltplDetailProv.DIC_IMP_FREE1_ID            := aDetail.DIC_IMP_FREE1_ID;
    ltplDetailProv.DIC_IMP_FREE2_ID            := aDetail.DIC_IMP_FREE2_ID;
    ltplDetailProv.DIC_IMP_FREE3_ID            := aDetail.DIC_IMP_FREE3_ID;
    ltplDetailProv.DIC_IMP_FREE4_ID            := aDetail.DIC_IMP_FREE4_ID;
    ltplDetailProv.DIC_IMP_FREE5_ID            := aDetail.DIC_IMP_FREE5_ID;
    ltplDetailProv.DIC_PROJECT_CONSOL_1_ID     := aDetail.DIC_PROJECT_CONSOL_1_ID;
    ltplDetailProv.DJD_CDA_ACCOUNT             := aDetail.DJD_CDA_ACCOUNT;
    ltplDetailProv.DJD_COEFF                   := aDetail.DJD_COEFF;
    ltplDetailProv.DJD_CPN_ACCOUNT             := aDetail.DJD_CPN_ACCOUNT;
    ltplDetailProv.DJD_DIV_ACCOUNT             := aDetail.DJD_DIV_ACCOUNT;
    ltplDetailProv.DJD_FIN_ACCOUNT             := aDetail.DJD_FIN_ACCOUNT;
    ltplDetailProv.DJD_JOURNAL_DOCUMENT_DATE   := aDetail.DJD_JOURNAL_DOCUMENT_DATE;
    ltplDetailProv.DJD_JOURNAL_QTY             := aDetail.DJD_JOURNAL_QTY;
    ltplDetailProv.DJD_JOURNAL_VALUE_DATE      := aDetail.DJD_JOURNAL_VALUE_DATE;
    ltplDetailProv.DJD_NEW_C_DOC_POS_STATUS    := aDetail.DJD_NEW_C_DOC_POS_STATUS;
    ltplDetailProv.DJD_NEW_POS_BALANCE_QTY     := aDetail.DJD_NEW_POS_BALANCE_QTY;
    ltplDetailProv.DJD_NEW_POS_BALANCE_QTY_SU  := aDetail.DJD_NEW_POS_BALANCE_QTY_SU;
    ltplDetailProv.DJD_NEW_POS_BASIS_QTY       := aDetail.DJD_NEW_POS_BASIS_QTY;
    ltplDetailProv.DJD_NEW_POS_BASIS_QTY_SU    := aDetail.DJD_NEW_POS_BASIS_QTY_SU;
    ltplDetailProv.DJD_NEW_POS_FINAL_QTY       := aDetail.DJD_NEW_POS_FINAL_QTY;
    ltplDetailProv.DJD_NEW_POS_FINAL_QTY_SU    := aDetail.DJD_NEW_POS_FINAL_QTY_SU;
    ltplDetailProv.DJD_NEW_POS_INTER_QTY       := aDetail.DJD_NEW_POS_INTER_QTY;
    ltplDetailProv.DJD_NEW_POS_INTER_QTY_SU    := aDetail.DJD_NEW_POS_INTER_QTY_SU;
    ltplDetailProv.DJD_OLD_C_DOC_POS_STATUS    := aDetail.DJD_OLD_C_DOC_POS_STATUS;
    ltplDetailProv.DJD_OLD_POS_BALANCE_QTY     := aDetail.DJD_OLD_POS_BALANCE_QTY;
    ltplDetailProv.DJD_OLD_POS_BALANCE_QTY_SU  := aDetail.DJD_OLD_POS_BALANCE_QTY_SU;
    ltplDetailProv.DJD_OLD_POS_BASIS_QTY       := aDetail.DJD_OLD_POS_BASIS_QTY;
    ltplDetailProv.DJD_OLD_POS_BASIS_QTY_SU    := aDetail.DJD_OLD_POS_BASIS_QTY_SU;
    ltplDetailProv.DJD_OLD_POS_FINAL_QTY       := aDetail.DJD_OLD_POS_FINAL_QTY;
    ltplDetailProv.DJD_OLD_POS_FINAL_QTY_SU    := aDetail.DJD_OLD_POS_FINAL_QTY_SU;
    ltplDetailProv.DJD_OLD_POS_INTER_QTY       := aDetail.DJD_OLD_POS_INTER_QTY;
    ltplDetailProv.DJD_OLD_POS_INTER_QTY_SU    := aDetail.DJD_OLD_POS_INTER_QTY_SU;
    ltplDetailProv.DJD_PF_ACCOUNT              := aDetail.DJD_PF_ACCOUNT;
    ltplDetailProv.DJD_PJ_ACCOUNT              := aDetail.DJD_PJ_ACCOUNT;
    ltplDetailProv.DJD_PROJECT_CONSOLIDATION   := aDetail.DJD_PROJECT_CONSOLIDATION;
    ltplDetailProv.DJD_REVERSAL_ENTRY          := aDetail.DJD_REVERSAL_ENTRY;
    ltplDetailProv.DJD_TRANSACTION_ID          := aDetail.DJD_TRANSACTION_ID;
    ltplDetailProv.DMT_BASE_PRICE              := aDetail.DMT_BASE_PRICE;
    ltplDetailProv.DMT_DATE_DOCUMENT           := aDetail.DMT_DATE_DOCUMENT;
    ltplDetailProv.DMT_DATE_VALUE              := aDetail.DMT_DATE_VALUE;
    ltplDetailProv.DMT_NUMBER                  := aDetail.DMT_NUMBER;
    ltplDetailProv.DMT_RATE_OF_EXCHANGE        := aDetail.DMT_RATE_OF_EXCHANGE;
    ltplDetailProv.DOC_DOCUMENT_ID             := aDetail.DOC_DOCUMENT_ID;
    ltplDetailProv.DOC_GAUGE_ID                := aDetail.DOC_GAUGE_ID;
    --ltplDetailProv.DOC_JOURNAL_DETAIL_PROV_ID := aDetail.DOC_JOURNAL_DETAIL_PROV_ID;
    ltplDetailProv.DOC_JOURNAL_HEADER_ID       := aDetail.DOC_JOURNAL_HEADER_ID;
    ltplDetailProv.DOC_POSITION_ID             := aDetail.DOC_POSITION_ID;
    ltplDetailProv.DOC_RECORD_ID               := aDetail.DOC_RECORD_ID;
    ltplDetailProv.FAM_FIXED_ASSETS_ID         := aDetail.FAM_FIXED_ASSETS_ID;
    ltplDetailProv.FIX_NUMBER                  := aDetail.FIX_NUMBER;
    ltplDetailProv.GAU_DESCRIBE                := aDetail.GAU_DESCRIBE;
    ltplDetailProv.GCO_GOOD_ID                 := aDetail.GCO_GOOD_ID;
    ltplDetailProv.GOO_MAJOR_REFERENCE         := aDetail.GOO_MAJOR_REFERENCE;
    ltplDetailProv.HRM_PERSON_ID               := aDetail.HRM_PERSON_ID;
    ltplDetailProv.HRM_PER_FIRST_NAME          := aDetail.HRM_PER_FIRST_NAME;
    ltplDetailProv.HRM_PER_LAST_NAME           := aDetail.HRM_PER_LAST_NAME;
    ltplDetailProv.LOC_DESCRIPTION             := aDetail.LOC_DESCRIPTION;
    ltplDetailProv.PAC_PERSON_ID               := aDetail.PAC_PERSON_ID;
    ltplDetailProv.PAC_REPRESENTATIVE_ID       := aDetail.PAC_REPRESENTATIVE_ID;
    ltplDetailProv.PAC_REPR_ACI_ID             := aDetail.PAC_REPR_ACI_ID;
    ltplDetailProv.PAC_REPR_DELIVERY_ID        := aDetail.PAC_REPR_DELIVERY_ID;
    ltplDetailProv.PAC_THIRD_ACI_ID            := aDetail.PAC_THIRD_ACI_ID;
    ltplDetailProv.PAC_THIRD_CDA_ID            := aDetail.PAC_THIRD_CDA_ID;
    ltplDetailProv.PAC_THIRD_DELIVERY_ID       := aDetail.PAC_THIRD_DELIVERY_ID;
    ltplDetailProv.PAC_THIRD_ID                := aDetail.PAC_THIRD_ID;
    ltplDetailProv.PAC_THIRD_TARIFF_ID         := aDetail.PAC_THIRD_TARIFF_ID;
    ltplDetailProv.PAC_THIRD_VAT_ID            := aDetail.PAC_THIRD_VAT_ID;
    ltplDetailProv.PER_PER_KEY1                := aDetail.PER_PER_KEY1;
    ltplDetailProv.PER_PER_NAME                := aDetail.PER_PER_NAME;
    ltplDetailProv.POS_CONVERT_FACTOR          := aDetail.POS_CONVERT_FACTOR;
    ltplDetailProv.POS_GROSS_UNIT_VALUE        := aDetail.POS_GROSS_UNIT_VALUE;
    ltplDetailProv.POS_GROSS_UNIT_VALUE_INCL   := aDetail.POS_GROSS_UNIT_VALUE_INCL;
    ltplDetailProv.POS_GROSS_VALUE             := aDetail.POS_GROSS_VALUE;
    ltplDetailProv.POS_GROSS_VALUE_B           := aDetail.POS_GROSS_VALUE_B;
    ltplDetailProv.POS_GROSS_VALUE_INCL        := aDetail.POS_GROSS_VALUE_INCL;
    ltplDetailProv.POS_GROSS_VALUE_INCL_B      := aDetail.POS_GROSS_VALUE_INCL_B;
    ltplDetailProv.POS_IMF_NUMBER_2            := aDetail.POS_IMF_NUMBER_2;
    ltplDetailProv.POS_IMF_NUMBER_3            := aDetail.POS_IMF_NUMBER_3;
    ltplDetailProv.POS_IMF_NUMBER_4            := aDetail.POS_IMF_NUMBER_4;
    ltplDetailProv.POS_IMF_NUMBER_5            := aDetail.POS_IMF_NUMBER_5;
    ltplDetailProv.POS_IMF_TEXT_1              := aDetail.POS_IMF_TEXT_1;
    ltplDetailProv.POS_IMF_TEXT_2              := aDetail.POS_IMF_TEXT_2;
    ltplDetailProv.POS_IMF_TEXT_3              := aDetail.POS_IMF_TEXT_3;
    ltplDetailProv.POS_IMF_TEXT_4              := aDetail.POS_IMF_TEXT_4;
    ltplDetailProv.POS_IMF_TEXT_5              := aDetail.POS_IMF_TEXT_5;
    ltplDetailProv.POS_IMPUTATION              := aDetail.POS_IMPUTATION;
    ltplDetailProv.POS_LONG_DESCRIPTION        := aDetail.POS_LONG_DESCRIPTION;
    ltplDetailProv.POS_NET_UNIT_VALUE          := aDetail.POS_NET_UNIT_VALUE;
    ltplDetailProv.POS_NET_UNIT_VALUE_INCL     := aDetail.POS_NET_UNIT_VALUE_INCL;
    ltplDetailProv.POS_NET_VALUE_EXCL          := aDetail.POS_NET_VALUE_EXCL;
    ltplDetailProv.POS_NET_VALUE_EXCL_B        := aDetail.POS_NET_VALUE_EXCL_B;
    ltplDetailProv.POS_NET_VALUE_INCL          := aDetail.POS_NET_VALUE_INCL;
    ltplDetailProv.POS_NET_VALUE_INCL_B        := aDetail.POS_NET_VALUE_INCL_B;
    ltplDetailProv.POS_NUMBER                  := aDetail.POS_NUMBER;
    ltplDetailProv.POS_REFERENCE               := aDetail.POS_REFERENCE;
    ltplDetailProv.POS_SHORT_DESCRIPTION       := aDetail.POS_SHORT_DESCRIPTION;
    ltplDetailProv.RCO_TITLE                   := aDetail.RCO_TITLE;
    ltplDetailProv.REP_ACI_DESCR               := aDetail.REP_ACI_DESCR;
    ltplDetailProv.REP_DELIVERY_DESCR          := aDetail.REP_DELIVERY_DESCR;
    ltplDetailProv.REP_DESCR                   := aDetail.REP_DESCR;
    ltplDetailProv.SRC_DOC_POSITION_ID         := aDetail.SRC_DOC_POSITION_ID;
    ltplDetailProv.STM_LOCATION_ID             := aDetail.STM_LOCATION_ID;
    ltplDetailProv.STM_STOCK_ID                := aDetail.STM_STOCK_ID;
    ltplDetailProv.STO_DESCRIPTION             := aDetail.STO_DESCRIPTION;
    ltplDetailProv.TGT_DOC_POSITION_ID         := aDetail.TGT_DOC_POSITION_ID;
    ltplDetailProv.THI_ACI_PER_KEY1            := aDetail.THI_ACI_PER_KEY1;
    ltplDetailProv.THI_ACI_PER_NAME            := aDetail.THI_ACI_PER_NAME;
    ltplDetailProv.THI_DELIVERY_PER_KEY1       := aDetail.THI_DELIVERY_PER_KEY1;
    ltplDetailProv.THI_DELIVERY_PER_NAME       := aDetail.THI_DELIVERY_PER_NAME;
    ltplDetailProv.THI_PER_KEY1                := aDetail.THI_PER_KEY1;
    ltplDetailProv.THI_PER_NAME                := aDetail.THI_PER_NAME;
    ltplDetailProv.THI_TARIFF_PER_KEY1         := aDetail.THI_TARIFF_PER_KEY1;
    ltplDetailProv.THI_TARIFF_PER_NAME         := aDetail.THI_TARIFF_PER_NAME;
    return ltplDetailProv;
  end GetDetailProvStruct;
end DOC_JOURNAL_FUNCTIONS;
