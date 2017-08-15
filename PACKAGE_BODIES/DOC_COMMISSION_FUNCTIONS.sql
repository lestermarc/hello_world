--------------------------------------------------------
--  DDL for Package Body DOC_COMMISSION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_COMMISSION_FUNCTIONS" 
is
  /*
  * Description
  *   Créé ou duplifie les commissions d'un document.
  *      Si le document destination est renseigné Alors
  *        Duplication des commissions du doc Old -> doc New
  *      Sinon
  *        Création des commissions pour le NewDocumentID
  */
  procedure GenerateCommissioning(NewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, OldDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    Commission_TARGET number;
    Commission_SOURCE number;
  begin
    -- Recherche le flag "Gestion commission" du gabarit du doc cible
    begin
      select GAS.GAS_COMMISSION_MANAGEMENT
        into Commission_TARGET
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED GAS
       where DOC.DOC_DOCUMENT_ID = NewDocumentID
         and GAS.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID;
    exception
      when no_data_found then
        Commission_TARGET  := 0;
    end;

    -- Recherche le flag "Gestion commission" du gabarit du doc source
    begin
      select GAS.GAS_COMMISSION_MANAGEMENT
        into Commission_SOURCE
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED GAS
       where DOC.DOC_DOCUMENT_ID = OldDocumentID
         and GAS.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID;
    exception
      when no_data_found then
        Commission_SOURCE  := 0;
    end;

    -- Si le gabarit du doc cible gére le commissionement
    if Commission_TARGET = 1 then
      -- Si le gabarit du doc source gére le commissionement
      if Commission_SOURCE = 1 then
        -- Copie du comissionement du doc source
        CopyCommissioning(NewDocumentID, OldDocumentID);
      else
        -- Création du commissionement
        CreateCommissioning(NewDocumentID);
      end if;
    end if;
  end GenerateCommissioning;

  /*
  * Description
  *   Création des commissions pour le Document
  */
  procedure CreateCommissioning(DocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor CommissionInfo(Doc_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select REP.PAC_REP_STRUCTURE_ID PAC_REP_STRUCTURE_ID
           , REP.PAC_PAC_REP_STRUCTURE_ID DOC_DOC_COMMISSION_ID
           , DOC.DOC_DOCUMENT_ID DOC_DOCUMENT_ID
           , REP.DOC_GAUGE_ID DOC_GAUGE_ID
           , REP.ACS_BONUS_TAX_CODE_ID ACS_BONUS_TAX_CODE_ID
           , decode(nvl(PCS.PC_CONFIG.GETCONFIG('DOC_COMM_USE_DOC_CURRENCY'), '0')
                  , '1', nvl(DOC.ACS_FINANCIAL_CURRENCY_ID, REP.ACS_FINANCIAL_CURRENCY_ID)
                  , REP.ACS_FINANCIAL_CURRENCY_ID
                   ) ACS_FINANCIAL_CURRENCY_ID
           , REP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
           , REP.PAC_REP2_ID PAC_REPRESENTATIVE_ID
           , REP.DIC_COMMISSIONING_ID DIC_COMMISSIONING_ID
           , REP.DIC_FREE_REPCODE_ID DIC_FREE_REPCODE_ID
           , REP.DIC_LINK_TYPE_ID DIC_LINK_TYPE_ID
           , REP.GCO_GOOD_ID GCO_GOOD_ID
           , REP.GCO_BONUS_GOOD_ID GCO_BONUS_GOOD_ID
           , REP.C_COMMISSIONING_TYPE C_COMMISSIONING_TYPE
           , REP.REP_END_YEAR_BONUS DCM_BONUS
           , REP.REP_BOOLEAN DCM_BOOLEAN
           , REP.REP_COMMENT DCM_COMMENT
           , REP.REP_DATE DCM_DATE
           , REP.REP_END_YEAR_BONUS_RATE DCM_END_YEAR_BONUS_RATE
           , REP.REP_TEXT DCM_FREE_TEXT
           , REP.REP_EXTR_PAYED_BILL DCM_EXTR_PAYED_BILL
           , nvl(REP.REP_RATE, 0) DCM_RATE
           , REP.REP_SORTING_KEY DCM_SORT
           , REP.REP_SQL DCM_SQL_STATMENT
           , REP.REP_AMOUNT DCM_AMOUNT
           , REP.REP_STORED_PROC DCM_STORED_PROC
           , sysdate A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
        from DOC_DOCUMENT DOC
           , PAC_REP_STRUCTURE REP
       where DOC.DOC_DOCUMENT_ID = Doc_ID
         and REP.PAC_REP1_ID = DOC.PAC_REPRESENTATIVE_ID
         and (   REP.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
              or REP.DOC_GAUGE_ID is null);

    cursor UpdateCommission(Doc_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select REP.PAC_REP_STRUCTURE_ID
           , REP.PAC_PAC_REP_STRUCTURE_ID
        from DOC_DOCUMENT DOC
           , PAC_REP_STRUCTURE REP
       where DOC.DOC_DOCUMENT_ID = Doc_ID
         and REP.PAC_REP1_ID = DOC.PAC_REPRESENTATIVE_ID
         and (   REP.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
              or REP.DOC_GAUGE_ID is null)
         and PAC_PAC_REP_STRUCTURE_ID is not null;

    RowCommission            CommissionInfo%rowtype;
    RowUpdateCom             UpdateCommission%rowtype;
    newDOC_COMMISSION_ID     DOC_COMMISSION.DOC_COMMISSION_ID%type;
    newDOC_DOC_COMMISSION_ID DOC_COMMISSION.DOC_COMMISSION_ID%type;
  begin
    -- Suppression de la table
    vParamsTable.delete;

    -- Curseur contenant les info pour la création des comissions
    open CommissionInfo(DocumentID);

    fetch CommissionInfo
     into RowCommission;

    -- Création des comissions une par une
    while CommissionInfo%found loop
      -- ID de la nouevlle comission
      select INIT_ID_SEQ.nextval
        into newDOC_COMMISSION_ID
        from dual;

      insert into DOC_COMMISSION
                  (DOC_COMMISSION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_GAUGE_ID
                 , ACS_BONUS_TAX_CODE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_TAX_CODE_ID
                 , PAC_REP_STRUCTURE_ID
                 , PAC_REPRESENTATIVE_ID
                 , DIC_COMMISSIONING_ID
                 , DIC_FREE_REPCODE_ID
                 , DIC_LINK_TYPE_ID
                 , GCO_GOOD_ID
                 , GCO_BONUS_GOOD_ID
                 , C_COMMISSIONING_TYPE
                 , DCM_BONUS
                 , DCM_BOOLEAN
                 , DCM_COMMENT
                 , DCM_DATE
                 , DCM_END_YEAR_BONUS_RATE
                 , DCM_FREE_TEXT
                 , DCM_EXTR_PAYED_BILL
                 , DCM_RATE
                 , DCM_SORT
                 , DCM_SQL_STATMENT
                 , DCM_AMOUNT
                 , DCM_STORED_PROC
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (newDOC_COMMISSION_ID
                 , RowCommission.DOC_DOCUMENT_ID
                 , RowCommission.DOC_GAUGE_ID
                 , RowCommission.ACS_BONUS_TAX_CODE_ID
                 , RowCommission.ACS_FINANCIAL_CURRENCY_ID
                 , RowCommission.ACS_TAX_CODE_ID
                 , RowCommission.PAC_REP_STRUCTURE_ID
                 , RowCommission.PAC_REPRESENTATIVE_ID
                 , RowCommission.DIC_COMMISSIONING_ID
                 , RowCommission.DIC_FREE_REPCODE_ID
                 , RowCommission.DIC_LINK_TYPE_ID
                 , RowCommission.GCO_GOOD_ID
                 , RowCommission.GCO_BONUS_GOOD_ID
                 , RowCommission.C_COMMISSIONING_TYPE
                 , RowCommission.DCM_BONUS
                 , RowCommission.DCM_BOOLEAN
                 , RowCommission.DCM_COMMENT
                 , RowCommission.DCM_DATE
                 , RowCommission.DCM_END_YEAR_BONUS_RATE
                 , RowCommission.DCM_FREE_TEXT
                 , RowCommission.DCM_EXTR_PAYED_BILL
                 , RowCommission.DCM_RATE
                 , RowCommission.DCM_SORT
                 , RowCommission.DCM_SQL_STATMENT
                 , RowCommission.DCM_AMOUNT
                 , RowCommission.DCM_STORED_PROC
                 , RowCommission.A_DATECRE
                 , RowCommission.A_IDCRE
                  );

      -- Sauvegarde l'ID de la comission créée
      vParamsTable(RowCommission.PAC_REP_STRUCTURE_ID).NEW_DOC_COMMISSION_ID  := newDOC_COMMISSION_ID;

      -- suivante
      fetch CommissionInfo
       into RowCommission;
    end loop;

    close CommissionInfo;

    -- Mettre à jour les liens de commission des nouveaux records
    open UpdateCommission(DocumentID);

    fetch UpdateCommission
     into RowUpdateCom;

    -- Parcourir le curseur de la structure des comissions pour trouver
    -- les comissions qui doivent avoir un lien sur une autre comission
    while UpdateCommission%found loop
      newDOC_COMMISSION_ID      := vParamsTable(RowUpdateCom.PAC_REP_STRUCTURE_ID).NEW_DOC_COMMISSION_ID;
      newDOC_DOC_COMMISSION_ID  := vParamsTable(RowUpdateCom.PAC_PAC_REP_STRUCTURE_ID).NEW_DOC_COMMISSION_ID;

      -- MäJ du lien comission
      update DOC_COMMISSION
         set DOC_DOC_COMMISSION_ID = newDOC_DOC_COMMISSION_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_COMMISSION_ID = newDOC_COMMISSION_ID;

      -- Suivante
      fetch UpdateCommission
       into RowUpdateCom;
    end loop;

    close UpdateCommission;
  end CreateCommissioning;

  /*
  *  Description
  *     Duplication des commissions du doc Old -> doc New
  */
  procedure CopyCommissioning(NewDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, OldDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor CommissionInfo(Doc_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , ACS_BONUS_TAX_CODE_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_TAX_CODE_ID
             , C_COMMISSIONING_TYPE
             , DCM_BONUS
             , DCM_BOOLEAN
             , DCM_COMMENT
             , DCM_DATE
             , DCM_END_YEAR_BONUS_RATE
             , DCM_FREE_TEXT
             , DCM_EXTR_PAYED_BILL
             , DCM_RATE
             , DCM_SORT
             , DCM_SQL_STATMENT
             , DCM_AMOUNT
             , DCM_STORED_PROC
             , DIC_COMMISSIONING_ID
             , DIC_FREE_REPCODE_ID
             , DIC_LINK_TYPE_ID
             , DOC_COMMISSION_ID OLD_DOC_COMMISSION_ID
             , DOC_DOC_COMMISSION_ID
             , DOC_GAUGE_ID
             , GCO_BONUS_GOOD_ID
             , GCO_GOOD_ID
             , PAC_REP_STRUCTURE_ID
             , PAC_REPRESENTATIVE_ID
          from DOC_COMMISSION
         where DOC_DOCUMENT_ID = Doc_ID
      order by DOC_COMMISSION_ID;

    cursor UpdateCommission(Doc_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select DOC_COMMISSION_ID
           , DOC_DOC_COMMISSION_ID
        from DOC_COMMISSION
       where DOC_DOC_COMMISSION_ID is not null
         and DOC_DOCUMENT_ID = Doc_ID;

    RowCommission            CommissionInfo%rowtype;
    RowUpdateCom             UpdateCommission%rowtype;
    newDOC_COMMISSION_ID     DOC_COMMISSION.DOC_COMMISSION_ID%type;
    newDOC_DOC_COMMISSION_ID DOC_COMMISSION.DOC_COMMISSION_ID%type;
  begin
    -- Suppression de la table
    vParamsTable.delete;

    -- Curseur contenant les info pour la création des comissions
    open CommissionInfo(OldDocumentID);

    fetch CommissionInfo
     into RowCommission;

    -- Création des comissions une par une
    while CommissionInfo%found loop
      -- ID de la nouevlle comission
      select INIT_ID_SEQ.nextval
        into newDOC_COMMISSION_ID
        from dual;

      insert into DOC_COMMISSION
                  (DOC_COMMISSION_ID
                 , DOC_DOC_COMMISSION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_GAUGE_ID
                 , ACS_BONUS_TAX_CODE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_TAX_CODE_ID
                 , PAC_REP_STRUCTURE_ID
                 , PAC_REPRESENTATIVE_ID
                 , DIC_COMMISSIONING_ID
                 , DIC_FREE_REPCODE_ID
                 , DIC_LINK_TYPE_ID
                 , GCO_GOOD_ID
                 , GCO_BONUS_GOOD_ID
                 , C_COMMISSIONING_TYPE
                 , DCM_BONUS
                 , DCM_BOOLEAN
                 , DCM_COMMENT
                 , DCM_DATE
                 , DCM_END_YEAR_BONUS_RATE
                 , DCM_FREE_TEXT
                 , DCM_EXTR_PAYED_BILL
                 , DCM_RATE
                 , DCM_SORT
                 , DCM_SQL_STATMENT
                 , DCM_AMOUNT
                 , DCM_STORED_PROC
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (newDOC_COMMISSION_ID
                 , RowCommission.DOC_DOC_COMMISSION_ID
                 , NewDocumentID
                 , RowCommission.DOC_GAUGE_ID
                 , RowCommission.ACS_BONUS_TAX_CODE_ID
                 , RowCommission.ACS_FINANCIAL_CURRENCY_ID
                 , RowCommission.ACS_TAX_CODE_ID
                 , RowCommission.PAC_REP_STRUCTURE_ID
                 , RowCommission.PAC_REPRESENTATIVE_ID
                 , RowCommission.DIC_COMMISSIONING_ID
                 , RowCommission.DIC_FREE_REPCODE_ID
                 , RowCommission.DIC_LINK_TYPE_ID
                 , RowCommission.GCO_GOOD_ID
                 , RowCommission.GCO_BONUS_GOOD_ID
                 , RowCommission.C_COMMISSIONING_TYPE
                 , RowCommission.DCM_BONUS
                 , RowCommission.DCM_BOOLEAN
                 , RowCommission.DCM_COMMENT
                 , RowCommission.DCM_DATE
                 , RowCommission.DCM_END_YEAR_BONUS_RATE
                 , RowCommission.DCM_FREE_TEXT
                 , RowCommission.DCM_EXTR_PAYED_BILL
                 , RowCommission.DCM_RATE
                 , RowCommission.DCM_SORT
                 , RowCommission.DCM_SQL_STATMENT
                 , RowCommission.DCM_AMOUNT
                 , RowCommission.DCM_STORED_PROC
                 , RowCommission.A_DATECRE
                 , RowCommission.A_IDCRE
                  );

      -- Sauvegarde l'ID de la comission créée
      vParamsTable(RowCommission.OLD_DOC_COMMISSION_ID).NEW_DOC_COMMISSION_ID  := newDOC_COMMISSION_ID;

      -- suivante
      fetch CommissionInfo
       into RowCommission;
    end loop;

    close CommissionInfo;

    -- Mettre à jour les liens de commission des nouveaux records
    open UpdateCommission(NewDocumentID);

    fetch UpdateCommission
     into RowUpdateCom;

    -- Parcourir le curseur de comissions créées pour trouver les liens
    -- sur les comissions du doc source et remplacer ces liens par des
    -- liens sur le doc cible
    while UpdateCommission%found loop
      newDOC_DOC_COMMISSION_ID  := vParamsTable(RowUpdateCom.DOC_DOC_COMMISSION_ID).NEW_DOC_COMMISSION_ID;

      -- MäJ du lien comission
      update DOC_COMMISSION
         set DOC_DOC_COMMISSION_ID = newDOC_DOC_COMMISSION_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_COMMISSION_ID = RowUpdateCom.DOC_COMMISSION_ID;

      -- suivante
      fetch UpdateCommission
       into RowUpdateCom;
    end loop;

    close UpdateCommission;
  end CopyCommissioning;
end DOC_COMMISSION_FUNCTIONS;
