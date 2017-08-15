--------------------------------------------------------
--  DDL for Package Body ACT_CLAIMS_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_CLAIMS_MANAGEMENT" 
is
-------------------------
  procedure GENERATE_CLAIMS(
    aCUSTOMER                  number
  , aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type
  , aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aPAR_REMIND_DATE           date
  , aACS_SUB_SET_ID            ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aACC_AUX_NUMBER1           ACS_ACCOUNT.ACC_NUMBER%type
  , aACC_AUX_NUMBER2           ACS_ACCOUNT.ACC_NUMBER%type
  , aPAR_BLOCKED_DOCUMENT      number
  , aCLAIMS                    number
  , aCOVER                     number
  )
  is
  begin
    ---- Bloquer les tables temporaires en écriture
    lock table ACT_CLAIMS_PAR_EXCEPTION in exclusive mode nowait;
    lock table ACT_CLAIMS_PAR_EXCEPTION in exclusive mode nowait;
    lock table ACT_CLAIMS in exclusive mode nowait;
    CREATE_CLAIMS_TABLE(aCUSTOMER
                      , aPAR_REMIND_DATE
                      , aACT_JOB_ID
                      , aACS_SUB_SET_ID
                      , aACC_AUX_NUMBER1
                      , aACC_AUX_NUMBER2
                      , aPAR_BLOCKED_DOCUMENT
                      , aCLAIMS
                      , aCOVER
                       );
    CREATE_CLAIMS_DOCUMENTS(aCUSTOMER, aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aPAR_REMIND_DATE);
    CalcInterest(aACT_JOB_ID, aPAR_REMIND_DATE);
    CalcCharge(aACT_JOB_ID);
  end GENERATE_CLAIMS;

-----------------------------
  procedure UpdateGroupKey
  is
    vSqlStmnt varchar2(1000);
  begin
    for tpl_CategGroupKey in (select   RCAT.PAC_REMAINDER_CATEGORY_ID
                                     , RCAT.RCA_GROUP_KEY
                                     , RCAT.C_REM_DOC_GENERATION
                                     , RCAT.C_MORATORIUM_INTEREST
                                  from PAC_REMAINDER_CATEGORY RCAT
                                     , ACT_CLAIMS CLA
                                 where CLA.PAC_REMAINDER_CATEGORY_ID = RCAT.PAC_REMAINDER_CATEGORY_ID
                              group by RCAT.RCA_GROUP_KEY
                                     , RCAT.C_REM_DOC_GENERATION
                                     , RCAT.C_MORATORIUM_INTEREST
                                     , RCAT.PAC_REMAINDER_CATEGORY_ID) loop
      if tpl_CategGroupKey.C_REM_DOC_GENERATION = '2' then
        --Selon clef de regroupement
        vSqlStmnt  :=
          'update ACT_CLAIMS ' ||
          '   set GROUP_KEY = decode(:C_MORATORIUM_INTEREST, ''2'', decode(C_STATUS_EXPIRY, ''1'', ''*'', null), null) || (select min(' ||
          tpl_CategGroupKey.RCA_GROUP_KEY ||
          ') ' ||
          '                      from ACT_FINANCIAL_IMPUTATION IMP ' ||
          '                     where IMP.ACT_FINANCIAL_IMPUTATION_ID = ACT_CLAIMS.ACT_FINANCIAL_IMPUTATION_ID) ' ||
          ' where PAC_REMAINDER_CATEGORY_ID = :PAC_REMAINDER_CATEGORY_ID ';

        execute immediate vSqlStmnt
                    using tpl_CategGroupKey.C_MORATORIUM_INTEREST, tpl_CategGroupKey.PAC_REMAINDER_CATEGORY_ID;
      elsif tpl_CategGroupKey.C_REM_DOC_GENERATION = '3' then
        --Selon échéance (un doc par échéance)
        update ACT_CLAIMS
           set GROUP_KEY =
                 decode(tpl_CategGroupKey.C_MORATORIUM_INTEREST, '2', decode(C_STATUS_EXPIRY, '1', '*', null), null) ||
                 to_char(ACT_EXPIRY_ID)
         where PAC_REMAINDER_CATEGORY_ID = tpl_CategGroupKey.PAC_REMAINDER_CATEGORY_ID;
      elsif     tpl_CategGroupKey.C_MORATORIUM_INTEREST = '2'
            and tpl_CategGroupKey.C_REM_DOC_GENERATION = '1' then
        --Normal (partenaire + monnaie)
        update ACT_CLAIMS
           set GROUP_KEY = decode(C_STATUS_EXPIRY, '1', '*', null)
         where PAC_REMAINDER_CATEGORY_ID = tpl_CategGroupKey.PAC_REMAINDER_CATEGORY_ID;
      elsif tpl_CategGroupKey.C_REM_DOC_GENERATION = '4' then
        --Selon niveau
        update ACT_CLAIMS
           set GROUP_KEY =
                 decode(tpl_CategGroupKey.C_MORATORIUM_INTEREST, '2', decode(C_STATUS_EXPIRY, '1', '*', null), null) ||
                 to_char(NO_RAPP)
         where PAC_REMAINDER_CATEGORY_ID = tpl_CategGroupKey.PAC_REMAINDER_CATEGORY_ID;
      end if;
    end loop;
  end UpdateGroupKey;

  procedure CREATE_CLAIMS_TABLE(
    aCUSTOMER             number
  , aPAR_REMIND_DATE      date
  , aACT_JOB_ID           ACT_JOB.ACT_JOB_ID%type
  , aACS_SUB_SET_ID       ACS_SUB_SET.ACS_SUB_SET_ID%type
  , aACC_AUX_NUMBER1      ACS_ACCOUNT.ACC_NUMBER%type
  , aACC_AUX_NUMBER2      ACS_ACCOUNT.ACC_NUMBER%type
  , aPAR_BLOCKED_DOCUMENT number
  , aCLAIMS               number
  , aCOVER                number
  )
  is
    type ClaimsCursorTyp is ref cursor;

    ClaimsCursor          ClaimsCursorTyp;
    ClaimsCursorRow       ACT_CLAIMS%rowtype;
    DivId                 varchar2(50);
    DivToDelId            ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    ColAccId              varchar2(50);
    ColAccToDelId         ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    intOccur              integer;
    intPos                integer;
    intLastPos            integer;
    vCount                integer;
    vExistDivisions       boolean;
    BYSECTOR              boolean;
    WITHPAIEDEXP          boolean;
    SectorReminderCategId PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type;
    CategType             PAC_REMAINDER_CATEGORY.C_REMAINDER_CAT_TYPE%type;
    TypeInterest          PAC_REMAINDER_CATEGORY.C_MORATORIUM_INTEREST%type;
  -----
  begin
    ------ Compteur à zéro
    delete from ACT_CLAIMS;

    commit;
    --Recherche si la societé gère les divisions
    vExistDivisions  := ACS_FUNCTION.ExistDIVI = 1;

    --Recherche de la catégorie sectoriel
    begin
      select COM.COM_LIST_ID_TEMP_ID
           , RCAT.C_REMAINDER_CAT_TYPE
        into SectorReminderCategId
           , CategType
        from PAC_REMAINDER_CATEGORY RCAT
           , COM_LIST_ID_TEMP COM
       where COM.COM_LIST_ID_TEMP_ID = RCAT.PAC_REMAINDER_CATEGORY_ID
         and COM.LID_CODE = '0';
    exception
      when no_data_found then
        return;
      when too_many_rows then
        CategType  := null;
    end;

    --Flag si type secteur
    BYSECTOR         := CategType = '2';

    --Recherche si calcules d'intérêts sur PO réglés
    select max(RCAT.C_MORATORIUM_INTEREST)
      into TypeInterest
      from PAC_REMAINDER_CATEGORY RCAT
         , COM_LIST_ID_TEMP COM
     where COM.COM_LIST_ID_TEMP_ID = RCAT.PAC_REMAINDER_CATEGORY_ID
       and COM.LID_CODE = '0';

    --Flag si avec PO compensés
    WITHPAIEDEXP     :=    (TypeInterest = '2')
                        or (TypeInterest = '3');

    --Si il n'existe pas de division dans la societé, il faut ajouter un enregistrement avec 0 dans
    -- la table COM_LIST_ID_TEMP afin que la jointure des curseurs ci-dessous puisse fonctionner
    if not vExistDivisions then
      --suppression des éventuelle enregistrements présent (et faux puisque pas de division)
      delete from COM_LIST_ID_TEMP
            where LID_CODE = '1';

      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (0
                 , '1'
                  );
    end if;

    --- Ajout PO
    if BYSECTOR then
      ------ Création table des Postes Ouverts
      if aCLAIMS = 1 then   -- Relances
        if aCUSTOMER = 1 then   -- Clients
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , decode(sign(EXP_AMOUNT_LC)
                         , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                         , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, CAT.PAC_REMAINDER_CATEGORY_ID)
                          ) NO_RAPP
                  , PER_NAME
                  , CAT.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , CUS.C_REMAINDER_LAUNCHING
                  , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                  , CUS.C_PARTNER_CATEGORY
                  , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from COM_LIST_ID_TEMP COM1
                  ,   --Divisions
                    COM_LIST_ID_TEMP COM2
                  ,   --Comptes collectifs
                    COM_LIST_ID_TEMP COM3
                  ,   --Transactions
                    ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_CUSTOM_PARTNER CUS
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET  = 1
                and (    (    EXP_ADAPTED > aPAR_REMIND_DATE
                          and C_TYPE_CATALOGUE in('3', '4', '9') )
                     or (EXP_ADAPTED <= aPAR_REMIND_DATE)
                    )
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'REC'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and COM1.LID_CODE = '1'
                and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                and COM2.LID_CODE = '2'
                and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                and COM3.LID_CODE = '3'
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        else   -- Fournisseurs
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , decode(sign(EXP_AMOUNT_LC)
                         , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                         , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, CAT.PAC_REMAINDER_CATEGORY_ID)
                          ) NO_RAPP
                  , PER_NAME
                  , CAT.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , SUP.C_REMAINDER_LAUNCHING
                  , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                  , SUP.C_PARTNER_CATEGORY
                  , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from COM_LIST_ID_TEMP COM1
                  ,   --Divisions
                    COM_LIST_ID_TEMP COM2
                  ,   --Comptes collectifs
                    COM_LIST_ID_TEMP COM3
                  ,   --Transactions
                    ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_SUPPLIER_PARTNER SUP
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET  = 1
                and (    (    EXP_ADAPTED > aPAR_REMIND_DATE
                          and C_TYPE_CATALOGUE in('3', '4', '9') )
                     or (EXP_ADAPTED <= aPAR_REMIND_DATE)
                    )
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'PAY'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and COM1.LID_CODE = '1'
                and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                and COM2.LID_CODE = '2'
                and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                and COM3.LID_CODE = '3'
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        end if;
      else   -- Relevés de compte
        if aCUSTOMER = 1 then   -- Clients
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , 0 NO_RAPP
                  , PER_NAME
                  , CAT.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , CUS.C_REMAINDER_LAUNCHING
                  , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                  , CUS.C_PARTNER_CATEGORY
                  , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from COM_LIST_ID_TEMP COM1
                  ,   --Divisions
                    COM_LIST_ID_TEMP COM2
                  ,   --Comptes collectifs
                    COM_LIST_ID_TEMP COM3
                  ,   --Transactions
                    ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_CUSTOM_PARTNER CUS
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET  = 1
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'REC'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CAT.PAC_REMAINDER_CATEGORY_ID) = 1
                and COM1.LID_CODE = '1'
                and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                and COM2.LID_CODE = '2'
                and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                and COM3.LID_CODE = '3'
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        else   -- Fournisseurs
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , 0 NO_RAPP
                  , PER_NAME
                  , CAT.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , SUP.C_REMAINDER_LAUNCHING
                  , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                  , SUP.C_PARTNER_CATEGORY
                  , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from COM_LIST_ID_TEMP COM1
                  ,   --Divisions
                    COM_LIST_ID_TEMP COM2
                  ,   --Comptes collectifs
                    COM_LIST_ID_TEMP COM3
                  ,   --Transactions
                    ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_SUPPLIER_PARTNER SUP
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET = 1
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'PAY'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CAT.PAC_REMAINDER_CATEGORY_ID) = 1
                and COM1.LID_CODE = '1'
                and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                and COM2.LID_CODE = '2'
                and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                and COM3.LID_CODE = '3'
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        end if;
      end if;
    else
      ------ Création table des Postes Ouverts
      if aCLAIMS = 1 then   -- Relances
        if aCUSTOMER = 1 then   -- Clients
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , decode(sign(EXP_AMOUNT_LC)
                         , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                         , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, CUS.PAC_REMAINDER_CATEGORY_ID)
                          ) NO_RAPP
                  , PER_NAME
                  , CUS.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , CUS.C_REMAINDER_LAUNCHING
                  , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                  , CUS.C_PARTNER_CATEGORY
                  , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_CUSTOM_PARTNER CUS
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET = 1
                and (    (    EXP_ADAPTED > aPAR_REMIND_DATE
                          and C_TYPE_CATALOGUE in('3', '4', '9') )
                     or (EXP_ADAPTED <= aPAR_REMIND_DATE)
                    )
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                and CUS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'REC'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        else   -- Fournisseurs
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , decode(sign(EXP_AMOUNT_LC)
                         , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                         , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, SUP.PAC_REMAINDER_CATEGORY_ID)
                          ) NO_RAPP
                  , PER_NAME
                  , SUP.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , SUP.C_REMAINDER_LAUNCHING
                  , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                  , SUP.C_PARTNER_CATEGORY
                  , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_SUPPLIER_PARTNER SUP
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET = 1
                and (    (    EXP_ADAPTED > aPAR_REMIND_DATE
                          and C_TYPE_CATALOGUE in('3', '4', '9') )
                     or (EXP_ADAPTED <= aPAR_REMIND_DATE)
                    )
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                and SUP.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'PAY'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        end if;
      else   -- Relevés de compte
        if aCUSTOMER = 1 then   -- Clients
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , 0 NO_RAPP
                  , PER_NAME
                  , CUS.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , CUS.C_REMAINDER_LAUNCHING
                  , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                  , CUS.C_PARTNER_CATEGORY
                  , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_CUSTOM_PARTNER CUS
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET = 1
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                and CUS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'REC'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CUS.PAC_REMAINDER_CATEGORY_ID) = 1
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        else   -- Fournisseurs
          open ClaimsCursor
           for
             select ACC.ACC_NUMBER ACS_AUX_NUMBER
                  , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                  , IMP.PAR_DOCUMENT
                  , IMP.PAR_BLOCKED_DOCUMENT
                  , IMP.ACS_FINANCIAL_CURRENCY_ID
                  , DOC.DOC_DOCUMENT_DATE
                  , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  , DOC.ACT_DOCUMENT_ID
                  , C_TYPE_CATALOGUE
                  , EXP_ADAPTED
                  , EXP_AMOUNT_LC FACTURE_LC
                  , EXP_AMOUNT_FC FACTURE_FC
                  , EXP_AMOUNT_EUR FACTURE_EUR
                  , 0 PAIEMENTS_LC
                  , 0 PAIEMENTS_FC
                  , 0 PAIEMENTS_EUR
                  , 0 COVER_AMOUNT_LC
                  , 0 COVER_AMOUNT_FC
                  , 0 COVER_AMOUNT_EUR
                  , 0 NO_RAPP
                  , PER_NAME
                  , SUP.PAC_REMAINDER_CATEGORY_ID
                  , RCA_HIGHEST_LEVEL
                  , RCA_REMINDER_EXPIRY
                  , C_MAX_CLAIMS_LEVEL
                  , SUP.C_REMAINDER_LAUNCHING
                  , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                  , SUP.C_PARTNER_CATEGORY
                  , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                  , ACC.ACS_SUB_SET_ID
                  , exp.ACT_EXPIRY_ID
                  , exp.C_STATUS_EXPIRY
                  , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                  , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  , null GROUP_KEY
               from ACS_SUB_SET SUB
                  , PAC_REMAINDER_CATEGORY CAT
                  , PAC_PERSON PER
                  , ACS_ACCOUNT ACC
                  , PAC_SUPPLIER_PARTNER SUP
                  , ACJ_CATALOGUE_DOCUMENT CATA
                  , ACT_DOCUMENT DOC
                  , ACS_FINANCIAL_ACCOUNT FACC
                  , ACT_FINANCIAL_IMPUTATION FIMP
                  , ACT_PART_IMPUTATION IMP
                  , ACT_EXPIRY exp
              where to_number(C_STATUS_EXPIRY) = 0
                and EXP_CALC_NET = 1
                and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                and SUP.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                and SUB.C_SUB_SET = 'PAY'
                and (    (    aACS_SUB_SET_ID is not null
                          and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                     or (aACS_SUB_SET_ID is null)
                    )
                and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(SUP.PAC_REMAINDER_CATEGORY_ID) = 1
                and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                and FIMP.ACT_DET_PAYMENT_ID is null
                and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                and FACC.FIN_COLLECTIVE = 1
                and not exists(select 0
                                 from ACT_EXPIRY_PAYMENT EXPAY
                                where EXPAY.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and EXPAY.C_STATUS_PAYMENT = '0');
        end if;
      end if;
    end if;

    fetch ClaimsCursor
     into ClaimsCursorRow;

    while ClaimsCursor%found loop
      insert into ACT_CLAIMS
                  (ACC_AUX_NUMBER
                 , ACS_ACCOUNT_ID
                 , PAR_DOCUMENT
                 , PAR_BLOCKED_DOCUMENT
                 , ACS_FINANCIAL_CURRENCY_ID
                 , DOC_DOCUMENT_DATE
                 , ACJ_CATALOGUE_DOCUMENT_ID
                 , ACT_DOCUMENT_ID
                 , C_TYPE_CATALOGUE
                 , EXP_ADAPTED
                 , FACTURE_LC
                 , FACTURE_FC
                 , FACTURE_EUR
                 , PAIEMENTS_LC
                 , PAIEMENTS_FC
                 , PAIEMENTS_EUR
                 , NO_RAPP
                 , PER_NAME
                 , PAC_REMAINDER_CATEGORY_ID
                 , RCA_HIGHEST_LEVEL
                 , RCA_REMINDER_EXPIRY
                 , C_MAX_CLAIMS_LEVEL
                 , C_REMAINDER_LAUNCHING
                 , PAC_PERSON_ID
                 , C_PARTNER_CATEGORY
                 , WITHOUT_REMIND_DATE
                 , ACS_SUB_SET_ID
                 , ACT_EXPIRY_ID
                 , C_STATUS_EXPIRY
                 , ACT_FINANCIAL_IMPUTATION_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , GROUP_KEY
                  )
           values (ClaimsCursorRow.ACC_AUX_NUMBER
                 , ClaimsCursorRow.ACS_ACCOUNT_ID
                 , ClaimsCursorRow.PAR_DOCUMENT
                 , ClaimsCursorRow.PAR_BLOCKED_DOCUMENT
                 , ClaimsCursorRow.ACS_FINANCIAL_CURRENCY_ID
                 , ClaimsCursorRow.DOC_DOCUMENT_DATE
                 , ClaimsCursorRow.ACJ_CATALOGUE_DOCUMENT_ID
                 , ClaimsCursorRow.ACT_DOCUMENT_ID
                 , ClaimsCursorRow.C_TYPE_CATALOGUE
                 , ClaimsCursorRow.EXP_ADAPTED
                 , ClaimsCursorRow.FACTURE_LC
                 , ClaimsCursorRow.FACTURE_FC
                 , ClaimsCursorRow.FACTURE_EUR
                 , ClaimsCursorRow.PAIEMENTS_LC
                 , ClaimsCursorRow.PAIEMENTS_FC
                 , ClaimsCursorRow.PAIEMENTS_EUR
                 , ClaimsCursorRow.NO_RAPP
                 , ClaimsCursorRow.PER_NAME
                 , ClaimsCursorRow.PAC_REMAINDER_CATEGORY_ID
                 , ClaimsCursorRow.RCA_HIGHEST_LEVEL
                 , ClaimsCursorRow.RCA_REMINDER_EXPIRY
                 , ClaimsCursorRow.C_MAX_CLAIMS_LEVEL
                 , ClaimsCursorRow.C_REMAINDER_LAUNCHING
                 , ClaimsCursorRow.PAC_PERSON_ID
                 , ClaimsCursorRow.C_PARTNER_CATEGORY
                 , ClaimsCursorRow.WITHOUT_REMIND_DATE
                 , ClaimsCursorRow.ACS_SUB_SET_ID
                 , ClaimsCursorRow.ACT_EXPIRY_ID
                 , ClaimsCursorRow.C_STATUS_EXPIRY
                 , ClaimsCursorRow.ACT_FINANCIAL_IMPUTATION_ID
                 , ClaimsCursorRow.ACS_FINANCIAL_ACCOUNT_ID
                 , ClaimsCursorRow.GROUP_KEY
                  );

      commit;

      fetch ClaimsCursor
       into ClaimsCursorRow;
    end loop;

    close ClaimsCursor;

    if WITHPAIEDEXP then
      --- Ajout PO déjà compensé pour calcule des intérêts
      if BYSECTOR then
        ------ Création table des Postes Ouverts
        if aCLAIMS = 1 then   -- Relances
          if aCUSTOMER = 1 then   -- Clients
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) NO_RAPP
                    , PER_NAME
                    , CAT.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , CUS.C_REMAINDER_LAUNCHING
                    , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                    , CUS.C_PARTNER_CATEGORY
                    , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from COM_LIST_ID_TEMP COM1
                    ,   --Divisions
                      COM_LIST_ID_TEMP COM2
                    ,   --Comptes collectifs
                      COM_LIST_ID_TEMP COM3
                    ,   --Transactions
                      ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_CUSTOM_PARTNER CUS
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'REC'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and COM1.LID_CODE = '1'
                  and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                  and COM2.LID_CODE = '2'
                  and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                  and COM3.LID_CODE = '3'
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          else   -- Fournisseurs
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) NO_RAPP
                    , PER_NAME
                    , CAT.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , SUP.C_REMAINDER_LAUNCHING
                    , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                    , SUP.C_PARTNER_CATEGORY
                    , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from COM_LIST_ID_TEMP COM1
                    ,   --Divisions
                      COM_LIST_ID_TEMP COM2
                    ,   --Comptes collectifs
                      COM_LIST_ID_TEMP COM3
                    ,   --Transactions
                      ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_SUPPLIER_PARTNER SUP
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                  and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'PAY'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and COM1.LID_CODE = '1'
                  and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                  and COM2.LID_CODE = '2'
                  and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                  and COM3.LID_CODE = '3'
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          end if;
        else   -- Relevés de compte
          if aCUSTOMER = 1 then   -- Clients
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , 0 NO_RAPP
                    , PER_NAME
                    , CAT.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , CUS.C_REMAINDER_LAUNCHING
                    , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                    , CUS.C_PARTNER_CATEGORY
                    , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from COM_LIST_ID_TEMP COM1
                    ,   --Divisions
                      COM_LIST_ID_TEMP COM2
                    ,   --Comptes collectifs
                      COM_LIST_ID_TEMP COM3
                    ,   --Transactions
                      ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_CUSTOM_PARTNER CUS
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'REC'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CAT.PAC_REMAINDER_CATEGORY_ID) = 1
                  and COM1.LID_CODE = '1'
                  and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                  and COM2.LID_CODE = '2'
                  and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                  and COM3.LID_CODE = '3'
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          else   -- Fournisseurs
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , 0 NO_RAPP
                    , PER_NAME
                    , CAT.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , SUP.C_REMAINDER_LAUNCHING
                    , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                    , SUP.C_PARTNER_CATEGORY
                    , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from COM_LIST_ID_TEMP COM1
                    ,   --Divisions
                      COM_LIST_ID_TEMP COM2
                    ,   --Comptes collectifs
                      COM_LIST_ID_TEMP COM3
                    ,   --Transactions
                      ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_SUPPLIER_PARTNER SUP
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                  and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and CAT.PAC_REMAINDER_CATEGORY_ID = SectorReminderCategId
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'PAY'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CAT.PAC_REMAINDER_CATEGORY_ID) = 1
                  and COM1.LID_CODE = '1'
                  and nvl(ACT_FUNCTIONS.GetCollDivisionId(exp.ACT_EXPIRY_ID), 0) = COM1.COM_LIST_ID_TEMP_ID
                  and COM2.LID_CODE = '2'
                  and FIMP.ACS_FINANCIAL_ACCOUNT_ID = COM2.COM_LIST_ID_TEMP_ID
                  and COM3.LID_CODE = '3'
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = COM3.COM_LIST_ID_TEMP_ID
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          end if;
        end if;
      else
        ------ Création table des Postes Ouverts
        if aCLAIMS = 1 then   -- Relances
          if aCUSTOMER = 1 then   -- Clients
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) NO_RAPP
                    , PER_NAME
                    , CUS.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , CUS.C_REMAINDER_LAUNCHING
                    , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                    , CUS.C_PARTNER_CATEGORY
                    , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_CUSTOM_PARTNER CUS
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and CUS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'REC'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          else   -- Fournisseurs
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) NO_RAPP
                    , PER_NAME
                    , SUP.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , SUP.C_REMAINDER_LAUNCHING
                    , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                    , SUP.C_PARTNER_CATEGORY
                    , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_SUPPLIER_PARTNER SUP
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                  and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and SUP.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'PAY'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          end if;
        else   -- Relevés de compte
          if aCUSTOMER = 1 then   -- Clients
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , CUS.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , 0 NO_RAPP
                    , PER_NAME
                    , CUS.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , CUS.C_REMAINDER_LAUNCHING
                    , CUS.PAC_CUSTOM_PARTNER_ID PAC_PERSON_ID
                    , CUS.C_PARTNER_CATEGORY
                    , CUS.CUS_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_CUSTOM_PARTNER CUS
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                  and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                  and CUS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'REC'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(CUS.PAC_REMAINDER_CATEGORY_ID) = 1
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          else   -- Fournisseurs
            open ClaimsCursor
             for
               select ACC.ACC_NUMBER ACS_AUX_NUMBER
                    , SUP.ACS_AUXILIARY_ACCOUNT_ID ACS_ACCOUNT_ID
                    , IMP.PAR_DOCUMENT
                    , IMP.PAR_BLOCKED_DOCUMENT
                    , IMP.ACS_FINANCIAL_CURRENCY_ID
                    , DOC.DOC_DOCUMENT_DATE
                    , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                    , DOC.ACT_DOCUMENT_ID
                    , C_TYPE_CATALOGUE
                    , EXP_ADAPTED
                    , 0 FACTURE_LC
                    , 0 FACTURE_FC
                    , 0 FACTURE_EUR
                    , 0 PAIEMENTS_LC
                    , 0 PAIEMENTS_FC
                    , 0 PAIEMENTS_EUR
                    , 0 COVER_AMOUNT_LC
                    , 0 COVER_AMOUNT_FC
                    , 0 COVER_AMOUNT_EUR
                    , 0 NO_RAPP
                    , PER_NAME
                    , SUP.PAC_REMAINDER_CATEGORY_ID
                    , RCA_HIGHEST_LEVEL
                    , RCA_REMINDER_EXPIRY
                    , C_MAX_CLAIMS_LEVEL
                    , SUP.C_REMAINDER_LAUNCHING
                    , SUP.PAC_SUPPLIER_PARTNER_ID PAC_PERSON_ID
                    , SUP.C_PARTNER_CATEGORY
                    , SUP.CRE_WITHOUT_REMIND_DATE WITHOUT_REMIND_DATE
                    , ACC.ACS_SUB_SET_ID
                    , exp.ACT_EXPIRY_ID
                    , exp.C_STATUS_EXPIRY
                    , FIMP.ACT_FINANCIAL_IMPUTATION_ID
                    , FIMP.ACS_FINANCIAL_ACCOUNT_ID
                    , null GROUP_KEY
                 from ACS_SUB_SET SUB
                    , PAC_REMAINDER_CATEGORY CAT
                    , PAC_PERSON PER
                    , ACS_ACCOUNT ACC
                    , PAC_SUPPLIER_PARTNER SUP
                    , ACJ_CATALOGUE_DOCUMENT CATA
                    , ACT_DOCUMENT DOC
                    , ACS_FINANCIAL_ACCOUNT FACC
                    , ACT_FINANCIAL_IMPUTATION FIMP
                    , ACT_PART_IMPUTATION IMP
                    , ACT_EXPIRY exp
                where to_number(C_STATUS_EXPIRY) = 1
                  and EXP_CALC_NET = 1
                  and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                  and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
                  and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
                  and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
                  and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                  and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                  and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and SUP.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                  and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                  and SUB.C_SUB_SET = 'PAY'
                  and (    (    aACS_SUB_SET_ID is not null
                            and ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID)
                       or (aACS_SUB_SET_ID is null)
                      )
                  and ACC.ACC_NUMBER between aACC_AUX_NUMBER1 and aACC_AUX_NUMBER2
                  and ACT_CLAIMS_MANAGEMENT.IsReleveCategory(SUP.PAC_REMAINDER_CATEGORY_ID) = 1
                  and FIMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
                  and FIMP.ACT_DET_PAYMENT_ID is null
                  and FACC.ACS_FINANCIAL_ACCOUNT_ID = FIMP.ACS_FINANCIAL_ACCOUNT_ID
                  and FACC.FIN_COLLECTIVE = 1
                  and CAT.C_MORATORIUM_INTEREST in('2', '3')
                  and not exists(select 0
                                   from ACT_REMINDER
                                  where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                    and ACT_REMINDER.REM_STATUS = 1);
          end if;
        end if;
      end if;

      fetch ClaimsCursor
       into ClaimsCursorRow;

      while ClaimsCursor%found loop
        insert into ACT_CLAIMS
                    (ACC_AUX_NUMBER
                   , ACS_ACCOUNT_ID
                   , PAR_DOCUMENT
                   , PAR_BLOCKED_DOCUMENT
                   , ACS_FINANCIAL_CURRENCY_ID
                   , DOC_DOCUMENT_DATE
                   , ACJ_CATALOGUE_DOCUMENT_ID
                   , ACT_DOCUMENT_ID
                   , C_TYPE_CATALOGUE
                   , EXP_ADAPTED
                   , FACTURE_LC
                   , FACTURE_FC
                   , FACTURE_EUR
                   , PAIEMENTS_LC
                   , PAIEMENTS_FC
                   , PAIEMENTS_EUR
                   , NO_RAPP
                   , PER_NAME
                   , PAC_REMAINDER_CATEGORY_ID
                   , RCA_HIGHEST_LEVEL
                   , RCA_REMINDER_EXPIRY
                   , C_MAX_CLAIMS_LEVEL
                   , C_REMAINDER_LAUNCHING
                   , PAC_PERSON_ID
                   , C_PARTNER_CATEGORY
                   , WITHOUT_REMIND_DATE
                   , ACS_SUB_SET_ID
                   , ACT_EXPIRY_ID
                   , C_STATUS_EXPIRY
                   , ACT_FINANCIAL_IMPUTATION_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , GROUP_KEY
                    )
             values (ClaimsCursorRow.ACC_AUX_NUMBER
                   , ClaimsCursorRow.ACS_ACCOUNT_ID
                   , ClaimsCursorRow.PAR_DOCUMENT
                   , ClaimsCursorRow.PAR_BLOCKED_DOCUMENT
                   , ClaimsCursorRow.ACS_FINANCIAL_CURRENCY_ID
                   , ClaimsCursorRow.DOC_DOCUMENT_DATE
                   , ClaimsCursorRow.ACJ_CATALOGUE_DOCUMENT_ID
                   , ClaimsCursorRow.ACT_DOCUMENT_ID
                   , ClaimsCursorRow.C_TYPE_CATALOGUE
                   , ClaimsCursorRow.EXP_ADAPTED
                   , ClaimsCursorRow.FACTURE_LC
                   , ClaimsCursorRow.FACTURE_FC
                   , ClaimsCursorRow.FACTURE_EUR
                   , ClaimsCursorRow.PAIEMENTS_LC
                   , ClaimsCursorRow.PAIEMENTS_FC
                   , ClaimsCursorRow.PAIEMENTS_EUR
                   , ClaimsCursorRow.NO_RAPP
                   , ClaimsCursorRow.PER_NAME
                   , ClaimsCursorRow.PAC_REMAINDER_CATEGORY_ID
                   , ClaimsCursorRow.RCA_HIGHEST_LEVEL
                   , ClaimsCursorRow.RCA_REMINDER_EXPIRY
                   , ClaimsCursorRow.C_MAX_CLAIMS_LEVEL
                   , ClaimsCursorRow.C_REMAINDER_LAUNCHING
                   , ClaimsCursorRow.PAC_PERSON_ID
                   , ClaimsCursorRow.C_PARTNER_CATEGORY
                   , ClaimsCursorRow.WITHOUT_REMIND_DATE
                   , ClaimsCursorRow.ACS_SUB_SET_ID
                   , ClaimsCursorRow.ACT_EXPIRY_ID
                   , ClaimsCursorRow.C_STATUS_EXPIRY
                   , ClaimsCursorRow.ACT_FINANCIAL_IMPUTATION_ID
                   , ClaimsCursorRow.ACS_FINANCIAL_ACCOUNT_ID
                   , ClaimsCursorRow.GROUP_KEY
                    );

        commit;

        fetch ClaimsCursor
         into ClaimsCursorRow;
      end loop;

      close ClaimsCursor;
    end if;

    -- Rollback segment FotoLabo Suisse
    -- set transaction use rollback segment rbs_reprise;
    delete from ACT_CLAIMS CLAIMS
          where not
                   --- Documents bloqués (O/N)
                (        (    (    aPAR_BLOCKED_DOCUMENT = 1
                               and nvl(PAR_BLOCKED_DOCUMENT, 0) = 0)
                          or (aPAR_BLOCKED_DOCUMENT = 0) )
                    --- Elimination des transactions à ignorer
                    and not exists(
                                select ACJ_CATALOGUE_DOCUMENT_ID
                                  from ACT_CLAIMS_TR_EXCEPTION
                                 where ACJ_CATALOGUE_DOCUMENT_ID = CLAIMS.ACJ_CATALOGUE_DOCUMENT_ID
                                   and PAR_SELECTION = 1)
                   );

    commit;

    if aCLAIMS = 1 then
      ------ Mise à jour des dates d'échéance sur la base des relances existantes si la cat. relance l'exige
/*      update ACT_CLAIMS PO
        set EXP_ADAPTED = (select max(EXP.EXP_ADAPTED)
                            from ACT_EXPIRY   EXP,
                                  ACT_REMINDER REM
                            where EXP.ACT_DOCUMENT_ID = REM.ACT_DOCUMENT_ID
                              and REM.ACT_EXPIRY_ID   = PO.ACT_EXPIRY_ID
                              and REM.REM_NUMBER      > 0
                          )
        where RCA_REMINDER_EXPIRY = 1
          and exists(select ACT_EXPIRY_ID
                      from ACT_REMINDER REM
                      where REM.ACT_EXPIRY_ID = PO.ACT_EXPIRY_ID
                        and REM.REM_NUMBER    > 0
                    );
*/
      update ACT_CLAIMS PO
         set EXP_ADAPTED =
               (select max(exp.EXP_ADAPTED)
                  from ACJ_CATALOGUE_DOCUMENT CAT
                     , ACT_DOCUMENT DOC
                     , ACT_EXPIRY exp
                     , ACT_REMINDER rem
                 where exp.ACT_DOCUMENT_ID = rem.ACT_DOCUMENT_ID
                   and rem.ACT_EXPIRY_ID = PO.ACT_EXPIRY_ID
                   and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and CAT.C_REMINDER_METHOD = '00'   -- Elimine les relevés de compte
                                                   )
       where RCA_REMINDER_EXPIRY = 1
         and exists(
               select ACT_EXPIRY_ID
                 from ACJ_CATALOGUE_DOCUMENT CAT
                    , ACT_DOCUMENT DOC
                    , ACT_REMINDER rem
                where rem.ACT_EXPIRY_ID = PO.ACT_EXPIRY_ID
                  and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                  and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                  and CAT.C_REMINDER_METHOD = '00'   -- Elimine les relevés de compte
                                                  );

      ------ Elimination des échéances ouvertes qui ne sont pas encore à relancer
      delete from ACT_CLAIMS
            where ACT_CLAIMS_MANAGEMENT.ExpiryDate(EXP_ADAPTED, PAC_REMAINDER_CATEGORY_ID, NO_RAPP) > aPAR_REMIND_DATE
              and C_TYPE_CATALOGUE not in('3', '4', '9');

      commit;
    end if;

    ------ Elimination des échéances avec date 'sans relance jusqu'au' plus petit que la date relance
    delete from ACT_CLAIMS
          where nvl( (select PART.PAR_NO_REMIND_BEFORE
                        from ACT_PART_IMPUTATION PART
                           , ACT_EXPIRY exp
                       where exp.ACT_EXPIRY_ID = ACT_CLAIMS.ACT_EXPIRY_ID
                         and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID)
                  , aPAR_REMIND_DATE - 1
                   ) >= aPAR_REMIND_DATE;

    commit;

    if     aCLAIMS = 1
       and not BYSECTOR then
      ------ Peut-être importera-t-il de retraiter les dates d'échéance avec la moulinette ci-dessus
      ------ Ajout de toutes les échéances ouvertes des partenaires qui atteignent le niveau contentieux sur au moins une des échéances
      if aCUSTOMER = 1 then   -- Clients
        insert into ACT_CLAIMS
                    (ACC_AUX_NUMBER
                   , ACS_ACCOUNT_ID
                   , PAR_DOCUMENT
                   , PAR_BLOCKED_DOCUMENT
                   , ACS_FINANCIAL_CURRENCY_ID
                   , DOC_DOCUMENT_DATE
                   , ACJ_CATALOGUE_DOCUMENT_ID
                   , ACT_DOCUMENT_ID
                   , C_TYPE_CATALOGUE
                   , EXP_ADAPTED
                   , FACTURE_LC
                   , FACTURE_FC
                   , FACTURE_EUR
                   , PAIEMENTS_LC
                   , PAIEMENTS_FC
                   , PAIEMENTS_EUR
                   , NO_RAPP
                   , PER_NAME
                   , PAC_REMAINDER_CATEGORY_ID
                   , RCA_HIGHEST_LEVEL
                   , RCA_REMINDER_EXPIRY
                   , C_MAX_CLAIMS_LEVEL
                   , C_REMAINDER_LAUNCHING
                   , PAC_PERSON_ID
                   , C_PARTNER_CATEGORY
                   , WITHOUT_REMIND_DATE
                   , ACS_SUB_SET_ID
                   , ACT_EXPIRY_ID
                   , C_STATUS_EXPIRY
                    )
          (select ACC.ACC_NUMBER
                , CUS.ACS_AUXILIARY_ACCOUNT_ID
                , IMP.PAR_DOCUMENT
                , IMP.PAR_BLOCKED_DOCUMENT
                , IMP.ACS_FINANCIAL_CURRENCY_ID
                , DOC.DOC_DOCUMENT_DATE
                , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                , DOC.ACT_DOCUMENT_ID
                , C_TYPE_CATALOGUE
                , EXP_ADAPTED
                , EXP_AMOUNT_LC
                , EXP_AMOUNT_FC
                , EXP_AMOUNT_EUR
                , 0
                , 0
                , 0
                , decode(sign(EXP_AMOUNT_LC)
                       , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                       , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, CUS.PAC_REMAINDER_CATEGORY_ID)
                        ) NO_RAPP
                , PER_NAME
                , CUS.PAC_REMAINDER_CATEGORY_ID
                , RCA_HIGHEST_LEVEL
                , RCA_REMINDER_EXPIRY
                , C_MAX_CLAIMS_LEVEL
                , CUS.C_REMAINDER_LAUNCHING
                , CUS.PAC_CUSTOM_PARTNER_ID
                , CUS.C_PARTNER_CATEGORY
                , CUS.CUS_WITHOUT_REMIND_DATE
                , ACC.ACS_SUB_SET_ID
                , exp.ACT_EXPIRY_ID
                , exp.C_STATUS_EXPIRY
             from PAC_REMAINDER_CATEGORY CAT
                , PAC_PERSON PER
                , ACS_ACCOUNT ACC
                , PAC_CUSTOM_PARTNER CUS
                , ACJ_CATALOGUE_DOCUMENT CATA
                , ACT_DOCUMENT DOC
                , ACT_PART_IMPUTATION IMP
                , ACT_EXPIRY exp
            where to_number(C_STATUS_EXPIRY) = 0
              and EXP_CALC_NET = 1
              and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
              and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
              and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
              and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
              and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
              and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
              and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
              and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
              and CUS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
              and ACC.ACS_ACCOUNT_ID in(
                    select PO.ACS_ACCOUNT_ID
                      from PAC_REMAINDER_DETAIL DET
                         , ACT_CLAIMS PO
                     where PO.PAC_REMAINDER_CATEGORY_ID = DET.PAC_REMAINDER_CATEGORY_ID
                       and PO.NO_RAPP = DET.RDE_NO_REMAINDER
                       and DET.RDE_CLAIMS_LEVEL = 1)
              and not exists(select ACT_EXPIRY_ID
                               from ACT_CLAIMS
                              where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID) );
      else   -- Fournisseurs
        insert into ACT_CLAIMS
                    (ACC_AUX_NUMBER
                   , ACS_ACCOUNT_ID
                   , PAR_DOCUMENT
                   , PAR_BLOCKED_DOCUMENT
                   , ACS_FINANCIAL_CURRENCY_ID
                   , DOC_DOCUMENT_DATE
                   , ACJ_CATALOGUE_DOCUMENT_ID
                   , ACT_DOCUMENT_ID
                   , C_TYPE_CATALOGUE
                   , EXP_ADAPTED
                   , FACTURE_LC
                   , FACTURE_FC
                   , FACTURE_EUR
                   , PAIEMENTS_LC
                   , PAIEMENTS_FC
                   , PAIEMENTS_EUR
                   , NO_RAPP
                   , PER_NAME
                   , PAC_REMAINDER_CATEGORY_ID
                   , RCA_HIGHEST_LEVEL
                   , RCA_REMINDER_EXPIRY
                   , C_MAX_CLAIMS_LEVEL
                   , C_REMAINDER_LAUNCHING
                   , PAC_PERSON_ID
                   , C_PARTNER_CATEGORY
                   , WITHOUT_REMIND_DATE
                   , ACS_SUB_SET_ID
                   , ACT_EXPIRY_ID
                   , C_STATUS_EXPIRY
                    )
          (select ACC.ACC_NUMBER
                , SUP.ACS_AUXILIARY_ACCOUNT_ID
                , IMP.PAR_DOCUMENT
                , IMP.PAR_BLOCKED_DOCUMENT
                , IMP.ACS_FINANCIAL_CURRENCY_ID
                , DOC.DOC_DOCUMENT_DATE
                , DOC.ACJ_CATALOGUE_DOCUMENT_ID
                , DOC.ACT_DOCUMENT_ID
                , C_TYPE_CATALOGUE
                , EXP_ADAPTED
                , EXP_AMOUNT_LC
                , EXP_AMOUNT_FC
                , EXP_AMOUNT_EUR
                , 0
                , 0
                , 0
                , decode(sign(EXP_AMOUNT_LC)
                       , 1, ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) + 1
                       , ACT_CLAIMS_MANAGEMENT.NegativeClaimsNumber(exp.ACT_EXPIRY_ID, SUP.PAC_REMAINDER_CATEGORY_ID)
                        ) NO_RAPP
                , PER_NAME
                , SUP.PAC_REMAINDER_CATEGORY_ID
                , RCA_HIGHEST_LEVEL
                , RCA_REMINDER_EXPIRY
                , C_MAX_CLAIMS_LEVEL
                , SUP.C_REMAINDER_LAUNCHING
                , SUP.PAC_SUPPLIER_PARTNER_ID
                , SUP.C_PARTNER_CATEGORY
                , SUP.CRE_WITHOUT_REMIND_DATE
                , ACC.ACS_SUB_SET_ID
                , exp.ACT_EXPIRY_ID
                , exp.C_STATUS_EXPIRY
             from PAC_REMAINDER_CATEGORY CAT
                , PAC_PERSON PER
                , ACS_ACCOUNT ACC
                , PAC_SUPPLIER_PARTNER SUP
                , ACJ_CATALOGUE_DOCUMENT CATA
                , ACT_DOCUMENT DOC
                , ACT_PART_IMPUTATION IMP
                , ACT_EXPIRY exp
            where to_number(C_STATUS_EXPIRY) = 0
              and EXP_CALC_NET = 1
              and exp.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
              and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
              and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
              and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
              and CATA.C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
              and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
              and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
              and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
              and SUP.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
              and ACC.ACS_ACCOUNT_ID in(
                    select PO.ACS_ACCOUNT_ID
                      from PAC_REMAINDER_DETAIL DET
                         , ACT_CLAIMS PO
                     where PO.PAC_REMAINDER_CATEGORY_ID = DET.PAC_REMAINDER_CATEGORY_ID
                       and PO.NO_RAPP = DET.RDE_NO_REMAINDER
                       and DET.RDE_CLAIMS_LEVEL = 1)
              and not exists(select ACT_EXPIRY_ID
                               from ACT_CLAIMS
                              where ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID) );
      end if;

      commit;
    end if;

    if not BYSECTOR then
      if vExistDivisions then
        ----Effacement des relances sur les factures ne figurant pas dans la liste des divisions
        delete from ACT_CLAIMS
              where not exists(
                      select 0
                        from COM_LIST_ID_TEMP COM
                       where COM.COM_LIST_ID_TEMP_ID = ACT_FUNCTIONS.GetCollDivisionId(ACT_CLAIMS.ACT_EXPIRY_ID)
                         and COM.LID_CODE = '1');
      end if;

      select count(*)
        into vCount
        from COM_LIST_ID_TEMP COM
       where COM.LID_CODE = '2';

      if vCount > 0 then
        ----Effacement des relances sur les factures ne figurant pas dans la liste des comptes collectifs
        delete from ACT_CLAIMS
              where ACS_FINANCIAL_ACCOUNT_ID not in(select COM.COM_LIST_ID_TEMP_ID
                                                      from COM_LIST_ID_TEMP COM
                                                     where COM.LID_CODE = '2');
      end if;
    end if;

    if aCLAIMS = 1 then
      ------ Dès qu'un partenaire atteint le niveau contentieux sur une échéance,
      ------ toutes ses échéances ouvertes obtiennent ce niveau contentieux
      update ACT_CLAIMS CLAIMS
         set NO_RAPP =
                   (select RDE_NO_REMAINDER
                      from PAC_REMAINDER_DETAIL DET
                     where DET.PAC_REMAINDER_CATEGORY_ID = CLAIMS.PAC_REMAINDER_CATEGORY_ID
                       and DET.RDE_CLAIMS_LEVEL = 1)
       where ACS_ACCOUNT_ID in(
               select PO.ACS_ACCOUNT_ID
                 from PAC_REMAINDER_DETAIL DET
                    , ACT_CLAIMS PO
                where PO.PAC_REMAINDER_CATEGORY_ID = DET.PAC_REMAINDER_CATEGORY_ID
                  and PO.NO_RAPP = DET.RDE_NO_REMAINDER
                  and DET.RDE_CLAIMS_LEVEL = 1);
    end if;

    if aCLAIMS = 1 then
      ------ Si la cat. relance l'exige, attribution du niveau le plus élevé pour toutes les échéance sélectionnées
      update ACT_CLAIMS PO
         set NO_RAPP =
               (select   max(NO_RAPP)
                    from ACT_CLAIMS PO_GROUP
                   where PO_GROUP.ACS_ACCOUNT_ID = PO.ACS_ACCOUNT_ID
                     and PO_GROUP.PAC_REMAINDER_CATEGORY_ID = PO.PAC_REMAINDER_CATEGORY_ID
                group by ACS_ACCOUNT_ID)
       where NO_RAPP > 0
         and RCA_HIGHEST_LEVEL = 1;
    end if;

    commit;

    if     (aACC_AUX_NUMBER1 <> aACC_AUX_NUMBER2)
       and (aCLAIMS = 1) then
      insert into ACT_AUX_ACCOUNT_FILTER
                  (ACT_AUX_ACCOUNT_FILTER_ID
                 , ACT_JOB_ID
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , C_REMINDER_FILTER
                  )
        (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                , aACT_JOB_ID
                , ACS_ACCOUNT_ID
                , '1'   -- Client bloqué rappel
             from ACT_CLAIMS
            where C_REMAINDER_LAUNCHING = 'NONE'
              and (   WITHOUT_REMIND_DATE is null
                   or WITHOUT_REMIND_DATE >= aPAR_REMIND_DATE)
         group by ACS_ACCOUNT_ID);

      insert into ACT_AUX_ACCOUNT_FILTER
                  (ACT_AUX_ACCOUNT_FILTER_ID
                 , ACT_JOB_ID
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , C_REMINDER_FILTER
                  )
        (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                , aACT_JOB_ID
                , ACS_ACCOUNT_ID
                , '2'   -- Client rappel manuel
             from ACT_CLAIMS
            where C_REMAINDER_LAUNCHING = 'MAN'
         group by ACS_ACCOUNT_ID);

      delete from ACT_CLAIMS
            where C_REMAINDER_LAUNCHING = 'MAN';

      delete from ACT_CLAIMS
            where C_REMAINDER_LAUNCHING = 'NONE'
              and (   WITHOUT_REMIND_DATE is null
                   or WITHOUT_REMIND_DATE >= aPAR_REMIND_DATE);

      commit;
    end if;

    if not BYSECTOR then
      if aCLAIMS = 1 then
        ------ Elimination des partenaires avec catégorie relance non sélectionnée
        insert into ACT_AUX_ACCOUNT_FILTER
                    (ACT_AUX_ACCOUNT_FILTER_ID
                   , ACT_JOB_ID
                   , ACS_AUXILIARY_ACCOUNT_ID
                   , C_REMINDER_FILTER
                    )
          (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                  , aACT_JOB_ID
                  , ACS_ACCOUNT_ID
                  , '6'   -- Catégorie relance non prise en compte
               from PAC_REMAINDER_CATEGORY CAT
                  , ACT_CLAIMS CLAIMS
              where CLAIMS.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
                and CAT.RCA_FAILURE_MANAGEMENT = 1
                and CLAIMS.PAC_REMAINDER_CATEGORY_ID not in(select COM.COM_LIST_ID_TEMP_ID
                                                              from COM_LIST_ID_TEMP COM
                                                             where COM.LID_CODE = '0')
           group by ACS_ACCOUNT_ID);
      end if;

      delete from ACT_CLAIMS
            where PAC_PERSON_ID in(select PAC_PERSON_ID
                                     from ACT_CLAIMS
                                    where PAC_REMAINDER_CATEGORY_ID not in(select COM.COM_LIST_ID_TEMP_ID
                                                                             from COM_LIST_ID_TEMP COM
                                                                            where COM.LID_CODE = '0') );

      commit;
    end if;

    if     aCLAIMS = 1
       and not BYSECTOR then
      ------ Elimination des partenaires à ignorer
      insert into ACT_AUX_ACCOUNT_FILTER
                  (ACT_AUX_ACCOUNT_FILTER_ID
                 , ACT_JOB_ID
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , C_REMINDER_FILTER
                  )
        (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                , aACT_JOB_ID
                , ACS_ACCOUNT_ID
                , '3'   -- Client avec type de transaction ignorant le client
             from ACT_CLAIMS
            where ACJ_CATALOGUE_DOCUMENT_ID in(select ACJ_CATALOGUE_DOCUMENT_ID
                                                 from ACT_CLAIMS_PAR_EXCEPTION
                                                where PAR_SELECTION = 1)
         group by ACS_ACCOUNT_ID);
    end if;

    delete from ACT_CLAIMS
          where PAC_PERSON_ID in(select PAC_PERSON_ID
                                   from ACT_CLAIMS
                                  where ACJ_CATALOGUE_DOCUMENT_ID in(select ACJ_CATALOGUE_DOCUMENT_ID
                                                                       from ACT_CLAIMS_PAR_EXCEPTION
                                                                      where PAR_SELECTION = 1) );

    commit;

    if aCLAIMS = 1 then
      ------ Elimination des partenaires ayant dépassé le niveau le plus élevé sur au moins une des échéances
      insert into ACT_AUX_ACCOUNT_FILTER
                  (ACT_AUX_ACCOUNT_FILTER_ID
                 , ACT_JOB_ID
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , C_REMINDER_FILTER
                  )
        (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                , aACT_JOB_ID
                , ACS_ACCOUNT_ID
                , '4'   -- Niveau supérieur de relance dépassé
             from ACT_CLAIMS PO
            where C_MAX_CLAIMS_LEVEL = '2'   -- Partenaire ignoré
              and not exists(
                        select PAC_REMAINDER_CATEGORY_ID
                             , RDE_NO_REMAINDER
                          from PAC_REMAINDER_DETAIL
                         where PAC_REMAINDER_CATEGORY_ID = PO.PAC_REMAINDER_CATEGORY_ID
                           and RDE_NO_REMAINDER = PO.NO_RAPP)
         group by ACS_ACCOUNT_ID);

      delete from ACT_CLAIMS
            where PAC_PERSON_ID in(
                    select   PAC_PERSON_ID
                        from ACT_CLAIMS PO
                       where C_MAX_CLAIMS_LEVEL = '2'   -- Partenaire ignoré
                         and not exists(
                               select PAC_REMAINDER_CATEGORY_ID
                                    , RDE_NO_REMAINDER
                                 from PAC_REMAINDER_DETAIL
                                where PAC_REMAINDER_CATEGORY_ID = PO.PAC_REMAINDER_CATEGORY_ID
                                  and RDE_NO_REMAINDER = PO.NO_RAPP)
                    group by PAC_PERSON_ID);
    end if;

    if aCLAIMS = 1 then
      ------ Elimination des échéances ayant dépassé le niveau le plus élevé
      ------ Sans mise à jour du code échec partenaire (pour l'instant)
      delete from ACT_CLAIMS CLAIMS
            where C_MAX_CLAIMS_LEVEL = '1'   -- Echéance ignorée
              and not exists(
                    select PAC_REMAINDER_CATEGORY_ID
                         , RDE_NO_REMAINDER
                      from PAC_REMAINDER_DETAIL
                     where PAC_REMAINDER_CATEGORY_ID = CLAIMS.PAC_REMAINDER_CATEGORY_ID
                       and RDE_NO_REMAINDER = CLAIMS.NO_RAPP);
    end if;

    commit;
    ------ Si C_MAX_CLAIMS_LEVEL = '0', mettre à jour les infos manquantes sur la base du détail relance le plus élevé
    ------ Si C_MAX_CLAIMS_LEVEL = '0', mettre à jour les infos manquantes sur la base du détail relance le plus élevé
    ------ Si C_MAX_CLAIMS_LEVEL = '0', mettre à jour les infos manquantes sur la base du détail relance le plus élevé
    ------ Si C_MAX_CLAIMS_LEVEL = '0', mettre à jour les infos manquantes sur la base du détail relance le plus élevé

    -- Calcul des montants payés pour les échéances à relancer
    ACT_CLAIMS_MANAGEMENT.updatePaymentAmounts(aCLAIMS, aCOVER);
    commit;
    --Màj colonne pour rupture
    UpdateGroupKey;

    if aCLAIMS = 1 then
      ------ Eliminer les échéances dont la somme n'atteint pas le seuil requis (défini au niveau détail de la cat. de relance)
      insert into ACT_AUX_ACCOUNT_FILTER
                  (ACT_AUX_ACCOUNT_FILTER_ID
                 , ACT_JOB_ID
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , C_REMINDER_FILTER
                 , FIL_GROUP_KEY
                  )
        (select   ACT_CLAIMS_MANAGEMENT.GetNextId
                , aACT_JOB_ID
                , ACS_ACCOUNT_ID
                , '5'
                ,   -- Seuil du niveau de relance non atteint
                  ACS_FINANCIAL_CURRENCY_ID || ' \ ' || GROUP_KEY
             from ACT_CLAIMS PO
            where C_STATUS_EXPIRY = 0
         group by ACS_ACCOUNT_ID
                , ACS_FINANCIAL_CURRENCY_ID
                , PAC_REMAINDER_CATEGORY_ID
                , GROUP_KEY
           having sum(FACTURE_LC - PAIEMENTS_LC - COVER_AMOUNT_LC) <
                                      ACT_CLAIMS_MANAGEMENT.GetMinAmount(PO.PAC_REMAINDER_CATEGORY_ID, max(PO.NO_RAPP) ) );

      for tpl_DeleteClaims in (select   PAC_PERSON_ID
                                      , ACS_FINANCIAL_CURRENCY_ID
                                      , PAC_REMAINDER_CATEGORY_ID
                                      , GROUP_KEY
                                   from ACT_CLAIMS PO
                                  where C_STATUS_EXPIRY = 0
                               group by PAC_PERSON_ID
                                      , ACS_FINANCIAL_CURRENCY_ID
                                      , PAC_REMAINDER_CATEGORY_ID
                                      , GROUP_KEY
                                 having sum(FACTURE_LC - PAIEMENTS_LC - COVER_AMOUNT_LC) <
                                          ACT_CLAIMS_MANAGEMENT.GetMinAmount(PO.PAC_REMAINDER_CATEGORY_ID
                                                                           , max(PO.NO_RAPP)
                                                                            ) ) loop
        delete from ACT_CLAIMS
              where PAC_PERSON_ID = tpl_DeleteClaims.PAC_PERSON_ID
                and ACS_FINANCIAL_CURRENCY_ID = tpl_DeleteClaims.ACS_FINANCIAL_CURRENCY_ID
                and PAC_REMAINDER_CATEGORY_ID = tpl_DeleteClaims.PAC_REMAINDER_CATEGORY_ID
                and nvl(GROUP_KEY, ' ') = nvl(tpl_DeleteClaims.GROUP_KEY, ' ')
                and C_STATUS_EXPIRY = 0;
      end loop;
    end if;

    if aCLAIMS = 1 then
      ------ Mise à jour Niveau atteint dernière relance pour les comptes auxiliaires relancés
      update ACS_AUXILIARY_ACCOUNT AUX
         set AUX_REMINDER_LEVEL = (select   max(NO_RAPP)
                                       from ACT_CLAIMS
                                      where ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
                                   group by ACS_ACCOUNT_ID)
           , AUX_LAST_REMINDER = aPAR_REMIND_DATE
       where ACS_AUXILIARY_ACCOUNT_ID in(select   ACS_ACCOUNT_ID
                                             from ACT_CLAIMS
                                         group by ACS_ACCOUNT_ID);
    end if;

    ----- Regroupement des partenaires "Membres de groupe" sur le partenaire "Groupe" correspondant
    ------ On conserve les caractéristiques (type de relance, catégorie de relance) du partenaire "Membre de groupe"
    if aCUSTOMER = 1 then
      update ACT_CLAIMS PO
         set (PAC_PERSON_ID, PER_NAME) =
               (select PAC_PERSON_ID
                     , PER_NAME
                  from PAC_PERSON PER
                     , PAC_CUSTOM_PARTNER CUS
                     , ACS_AUXILIARY_ACCOUNT ACC
                 where ACC.ACS_AUXILIARY_ACCOUNT_ID = PO.ACS_ACCOUNT_ID
                   and ACC.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and CUS.C_PARTNER_CATEGORY = '2'
                   and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID)
       where C_PARTNER_CATEGORY = '3'
         and exists(
               select PAC_CUSTOM_PARTNER_ID
                 from PAC_CUSTOM_PARTNER CUS
                    , ACS_AUXILIARY_ACCOUNT ACC
                where ACC.ACS_AUXILIARY_ACCOUNT_ID = PO.ACS_ACCOUNT_ID
                  and ACC.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                  and CUS.C_PARTNER_CATEGORY = '2');
    else
      update ACT_CLAIMS PO
         set (PAC_PERSON_ID, PER_NAME) =
               (select PAC_PERSON_ID
                     , PER_NAME
                  from PAC_PERSON PER
                     , PAC_SUPPLIER_PARTNER SUP
                     , ACS_AUXILIARY_ACCOUNT ACC
                 where ACC.ACS_AUXILIARY_ACCOUNT_ID = PO.ACS_ACCOUNT_ID
                   and ACC.ACS_AUXILIARY_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and SUP.C_PARTNER_CATEGORY = '2'
                   and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID)
       where C_PARTNER_CATEGORY = '3'
         and exists(
               select PAC_SUPPLIER_PARTNER_ID
                 from PAC_SUPPLIER_PARTNER SUP
                    , ACS_AUXILIARY_ACCOUNT ACC
                where ACC.ACS_AUXILIARY_ACCOUNT_ID = PO.ACS_ACCOUNT_ID
                  and ACC.ACS_AUXILIARY_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                  and SUP.C_PARTNER_CATEGORY = '2');
    end if;

    commit;
  end CREATE_CLAIMS_TABLE;

---------------------------------
  procedure UpdateDocAmounts(
    aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aAmountLC               ACT_EXPIRY.EXP_AMOUNT_LC%type
  , aAmountFC               ACT_EXPIRY.EXP_AMOUNT_FC%type
  , aAmountEUR              ACT_EXPIRY.EXP_AMOUNT_EUR%type
  , aExpiryDate             date
  , aUpdateAmountOnly       boolean
  )
  is
    FIN_ACC_S_PAYMENT_ID ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
    vDocumentId          ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    RefBVR               ACT_EXPIRY.EXP_REF_BVR%type;
    BVRCode              ACT_EXPIRY.EXP_BVR_CODE%type;
    tpl_Expiry           ACT_EXPIRY%rowtype;
    vCreate              boolean;
    vDocumentDate        ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;
    vExpiryDate          ACT_EXPIRY.EXP_CALCULATED%type;
    vFinCurrId           ACT_PART_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- Si en mode update -> on ne crée pas de nouvelle échéance
    vCreate  := not aUpdateAmountOnly;

    -- Méthode de paiement du Job courant
    select CAT.ACS_FIN_ACC_S_PAYMENT_ID
         , PART.ACT_DOCUMENT_ID
         , DOC_DOCUMENT_DATE
      into FIN_ACC_S_PAYMENT_ID
         , vDocumentId
         , vDocumentDate
      from ACT_PART_IMPUTATION PART
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
     where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
       and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
       and PART.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID;

    -- Recherche info sur échéance existante
    if aUpdateAmountOnly then
      begin
        select *
          into tpl_Expiry
          from ACT_EXPIRY
         where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
      exception
        when no_data_found then
          -- Si l'échéance n'existe pas malgré que l'on soit en mode update -> on la crée
          vCreate  := true;
        when too_many_rows then
          -- Si plus d'une échéance, on efface tout et on recrée
          delete from ACT_EXPIRY
                where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

          vCreate  := true;
      end;
    end if;

    -- Si création mais pas de date en param. -> calcul de celle-ci
    if     vCreate
       and aExpiryDate is null then
      select vDocumentDate +
             ACT_CLAIMS_MANAGEMENT.MaxExpiryDaysOfCategory(max(PAC_REMAINDER_CATEGORY_ID), max(REM_NUMBER) )
        into vExpiryDate
        from ACT_REMINDER
       where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
    else
      vExpiryDate  := aExpiryDate;
    end if;

    -- Mise à jour N° référence BVR et Ligne de codage BVR selon méthode définie dans la transaction courante
    -- Uniquement si une méthode de paiement est définie sur la transaction courante !
    if FIN_ACC_S_PAYMENT_ID is not null then
      if vCreate then
        -- Recherche réf. si création
        ACS_FUNCTION.Set_BVR_Ref(FIN_ACC_S_PAYMENT_ID, '2', to_char(vDocumentId), RefBVR);
      else
        RefBVR  := tpl_Expiry.EXP_REF_BVR;
      end if;

      select ACS_FINANCIAL_CURRENCY_ID
        into vFinCurrId
        from ACT_PART_IMPUTATION
       where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

      BVRCode  := ACS_FUNCTION.Get_BVR_Coding_Line(FIN_ACC_S_PAYMENT_ID, RefBVR, aAmountLC, ACS_FUNCTION.GetLocalCurrencyID, aAmountFC, vFinCurrId);
    end if;

    if vCreate then
      -- Echéances - ACT_EXPIRY
      insert into ACT_EXPIRY
                  (ACT_EXPIRY_ID
                 , ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , EXP_ADAPTED
                 , EXP_CALCULATED
                 , EXP_INTEREST_VALUE
                 , EXP_AMOUNT_LC
                 , EXP_AMOUNT_FC
                 , EXP_AMOUNT_EUR
                 , EXP_SLICE
                 , EXP_DISCOUNT_LC
                 , EXP_DISCOUNT_FC
                 , EXP_DISCOUNT_EUR
                 , EXP_POURCENT
                 , EXP_CALC_NET
                 , C_STATUS_EXPIRY
                 , EXP_DATE_PMT_TOT
                 , EXP_BVR_CODE
                 , EXP_REF_BVR
                 , ACS_FIN_ACC_S_PAYMENT_ID
                 , EXP_AMOUNT_PROV_LC
                 , EXP_AMOUNT_PROV_FC
                 , A_CONFIRM
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                  )
           values (ACT_CLAIMS_MANAGEMENT.GetNextId
                 , vDocumentId
                 , aACT_PART_IMPUTATION_ID
                 , vExpiryDate
                 , vExpiryDate
                 , vExpiryDate
                 , aAmountLC
                 , aAmountFC
                 , aAmountEUR
                 , 1
                 , 0
                 , 0
                 , 0
                 , 100
                 , 1
                 , '9'
                 , null
                 , BVRCode
                 , RefBVR
                 , FIN_ACC_S_PAYMENT_ID
                 , null
                 , null
                 , null
                 , sysdate
                 , null
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , null
                  );
    else
      -- Màj échéance
      update ACT_EXPIRY
         set EXP_AMOUNT_LC = aAmountLC
           , EXP_AMOUNT_FC = aAmountFC
           , EXP_AMOUNT_EUR = aAmountEUR
           , EXP_DISCOUNT_LC = 0
           , EXP_DISCOUNT_FC = 0
           , EXP_DISCOUNT_EUR = 0
           , EXP_REF_BVR = RefBVR
           , EXP_BVR_CODE = BVRCode
       where ACT_EXPIRY_ID = tpl_Expiry.ACT_EXPIRY_ID;
    end if;

    ------ Mise à jour du montant total document
    update ACT_DOCUMENT
       set DOC_TOTAL_AMOUNT_DC =
                                decode(ACS_FINANCIAL_CURRENCY_ID
                                     , ACS_FUNCTION.GetLocalCurrencyID, aAmountLC
                                     , aAmountFC
                                      )
         , DOC_TOTAL_AMOUNT_EUR = aAmountEUR
     where ACT_DOCUMENT_ID = vDocumentId;
  end UpdateDocAmounts;

---------------------------------
  procedure CREATE_CLAIMS_DOCUMENTS(
    aCUSTOMER                  number
  , aACT_JOB_ID                ACT_JOB.ACT_JOB_ID%type
  , aACJ_CATALOGUE_DOCUMENT_ID number
  , aPAR_REMIND_DATE           date
  )
  is
    cursor ClaimsCursor
    is
      select   *
          from ACT_CLAIMS
      order by ACS_ACCOUNT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , GROUP_KEY;

    ClaimsCursorRow     ClaimsCursor%rowtype;
    USER_INI            PCS.PC_USER.USE_INI%type;
    FinancialYearId     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    FinancialCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    DocumentId          ACT_EXPIRY.ACT_DOCUMENT_ID%type;
    PartImputationId    ACT_EXPIRY.ACT_PART_IMPUTATION_ID%type;
    GroupKey            ACT_CLAIMS.GROUP_KEY%type;
    AccountId           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    AddressId           PAC_ADDRESS.PAC_ADDRESS_ID%type;
    CommunicationId     PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
    CustomerId          PAC_PERSON.PAC_PERSON_ID%type;
    SupplierId          PAC_PERSON.PAC_PERSON_ID%type;
    CurrencyId          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    TotLC               ACT_REMINDER.REM_PAYABLE_AMOUNT_LC%type;
    TotFC               ACT_REMINDER.REM_PAYABLE_AMOUNT_FC%type;
    TotEUR              ACT_REMINDER.REM_PAYABLE_AMOUNT_EUR%type;
    NoRappel            PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type;
    CategoryId          PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type;
    ConditionId         PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    NoRemainder         PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type;
    LangId              PCS.PC_LANG.PC_LANG_ID%type;
    LastDocument        boolean;
    strDocNumber        ACT_DOCUMENT.DOC_NUMBER%type;
    MethodId            ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
  begin
    ------ Id de la monnaie de base
    FinancialCurrencyId  := ACS_FUNCTION.GetLocalCurrencyID;

    ------ Id de l'année du travail courant
    select ACS_FINANCIAL_YEAR_ID
      into FinancialYearId
      from ACT_JOB
     where ACT_JOB_ID = aACT_JOB_ID;

    -- Initiales et langue utilisateur courant
    USER_INI             := PCS.PC_I_LIB_SESSION.GetUserIni;

    update ACT_JOB
       set JOB_ACI_CONTROL_DATE = aPAR_REMIND_DATE
     where ACT_JOB_ID = aACT_JOB_ID;

    -- Recherche s'il existe une méthode de numérotation (optimisation)
    select max(ACJ_NUMBER_METHOD_ID)
      into MethodId
      from ACJ_NUMBER_METHOD;

    open ClaimsCursor;

    fetch ClaimsCursor
     into ClaimsCursorRow;

    LastDocument         := ClaimsCursor%notfound;

    while not LastDocument loop
      GroupKey          := ClaimsCursorRow.GROUP_KEY;
      AccountId         := ClaimsCursorRow.ACS_ACCOUNT_ID;
      CurrencyId        := ClaimsCursorRow.ACS_FINANCIAL_CURRENCY_ID;
      CategoryId        := ClaimsCursorRow.PAC_REMAINDER_CATEGORY_ID;

      if aCustomer = 1 then
        AddressId   := ACT_CLAIMS_MANAGEMENT.GET_CLAIMS_ADDRESS(ClaimsCursorRow.PAC_PERSON_ID, 1);

        select PAC_PAYMENT_CONDITION_ID
          into ConditionId
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = ClaimsCursorRow.PAC_PERSON_ID;

        CustomerId  := ClaimsCursorRow.PAC_PERSON_ID;
        SupplierId  := null;
      else
        AddressId   := ACT_CLAIMS_MANAGEMENT.GET_CLAIMS_ADDRESS(ClaimsCursorRow.PAC_PERSON_ID, 0);

        select PAC_PAYMENT_CONDITION_ID
          into ConditionId
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = ClaimsCursorRow.PAC_PERSON_ID;

        CustomerId  := null;
        SupplierId  := ClaimsCursorRow.PAC_PERSON_ID;
      end if;

      select min(PAC_COMMUNICATION_ID)
        into CommunicationId
        from PAC_COMMUNICATION COM
           , DIC_COMMUNICATION_TYPE TYP
       where COM.PAC_PERSON_ID = ClaimsCursorRow.PAC_PERSON_ID
         and COM.DIC_COMMUNICATION_TYPE_ID = TYP.DIC_COMMUNICATION_TYPE_ID
         and TYP.DCO_DEFAULT1 = 1;

      LangId            := ACT_CLAIMS_MANAGEMENT.GET_LANG_ADDRESS(AddressId);
      TotLC             := 0;
      TotFC             := 0;
      TotEUR            := 0;
      NoRappel          := 0;
      DocumentId        := ACT_CLAIMS_MANAGEMENT.GetNextId;
      PartImputationId  := ACT_CLAIMS_MANAGEMENT.GetNextId;

      -- Permet d'éviter de relancer inutilement la méthode de numérotation sur un grand nombre de documents
      if MethodId is not null then
        -- Génération numéro de document
        ACT_FUNCTIONS.GetDocNumber(aACJ_CATALOGUE_DOCUMENT_ID, FinancialYearId, strDocNumber);
      end if;

      -- Document - ACT_DOCUMENT
      insert into ACT_DOCUMENT
                  (ACT_DOCUMENT_ID
                 , ACT_JOB_ID
                 , PC_USER_ID
                 , DOC_NUMBER
                 , DOC_TOTAL_AMOUNT_DC
                 , DOC_DOCUMENT_DATE
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACJ_CATALOGUE_DOCUMENT_ID
                 , ACT_JOURNAL_ID
                 , ACT_ACT_JOURNAL_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , DOC_ACCOUNT_ID
                 , DOC_CHARGES_LC
                 , ACS_FINANCIAL_YEAR_ID
                 , DOC_COMMENT
                 , DOC_CCP_TAX
                 , DOC_ORDER_NO
                 , DOC_EFFECTIVE_DATE
                 , DOC_EXECUTIVE_DATE
                 , DOC_ESTABL_DATE
                 , C_STATUS_DOCUMENT
                 , COM_OLE_ID
                 , DIC_DOC_SOURCE_ID
                 , DIC_DOC_DESTINATION_ID
                 , ACS_FIN_ACC_S_PAYMENT_ID
                 , A_CONFIRM
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECSTATUS
                 , A_RECLEVEL
                  )
           values (DocumentId
                 , aACT_JOB_ID
                 , null
                 , strDocNumber
                 , null
                 , aPAR_REMIND_DATE
                 , CurrencyId
                 , aACJ_CATALOGUE_DOCUMENT_ID
                 , null
                 , null
                 , null
                 , AccountId
                 , null
                 , FinancialYearId
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , 'PROV'
                 , null
                 , null
                 , null
                 , null
                 , null
                 , sysdate
                 , null
                 , USER_INI
                 , null
                 , null
                 , null
                  );

      insert into ACT_PART_IMPUTATION
                  (ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , PAR_DOCUMENT
                 , PAR_BLOCKED_DOCUMENT
                 , PAC_CUSTOM_PARTNER_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_FINANCIAL_REFERENCE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , PAR_PAIED_LC
                 , PAR_CHARGES_LC
                 , PAR_PAIED_FC
                 , PAR_CHARGES_FC
                 , PAR_EXCHANGE_RATE
                 , PAR_BASE_PRICE
                 , PAC_ADDRESS_ID
                 , PAC_COMMUNICATION_ID
                 , PAR_REMIND_DATE
                 , PAR_REMIND_PRINTDATE
                 , DIC_PRIORITY_PAYMENT_ID
                 , DIC_CENTER_PAYMENT_ID
                 , DIC_LEVEL_PRIORITY_ID
                 , A_CONFIRM
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                  )
           values (DocumentId
                 , PartImputationId
                 , ''
                 ,   -- PAR_DOCUMENT
                   0
                 , CustomerId
                 , ConditionId
                 , SupplierId
                 , null
                 , CurrencyId
                 , FinancialCurrencyId
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , AddressId
                 , CommunicationId
                 , aPAR_REMIND_DATE
                 , null
                 , null
                 , null
                 , null
                 , null
                 , sysdate
                 , null
                 , USER_INI
                 , null
                 , null
                 , null
                  );

      while not LastDocument
       and AccountId = ClaimsCursorRow.ACS_ACCOUNT_ID
       and CurrencyId = ClaimsCursorRow.ACS_FINANCIAL_CURRENCY_ID
       and (    (GroupKey = ClaimsCursorRow.GROUP_KEY)
            or (    GroupKey is null
                and ClaimsCursorRow.GROUP_KEY is null) ) loop
        -- Relances - ACT_REMINDER
        insert into ACT_REMINDER
                    (ACT_REMINDER_ID
                   , ACT_EXPIRY_ID
                   , ACT_DOCUMENT_ID
                   , ACT_PART_IMPUTATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , REM_PAYABLE_AMOUNT_LC
                   , REM_PAYABLE_AMOUNT_FC
                   , REM_PAYABLE_AMOUNT_EUR
                   , REM_NUMBER
                   , REM_COVER_AMOUNT_LC
                   , REM_COVER_AMOUNT_FC
                   , REM_COVER_AMOUNT_EUR
                   , A_CONFIRM
                   , A_DATECRE
                   , A_DATEMOD
                   , A_IDCRE
                   , A_IDMOD
                   , A_RECLEVEL
                   , A_RECSTATUS
                   , REM_STATUS
                   , PAC_REMAINDER_CATEGORY_ID
                   , C_REM_STATUS_CHARGE
                   , C_REM_STATUS_INTEREST
                    )
             values (ACT_CLAIMS_MANAGEMENT.GetNextId
                   , ClaimsCursorRow.ACT_EXPIRY_ID
                   , DocumentId
                   , PartImputationId
                   , CurrencyId
                   , FinancialCurrencyId
                   , nvl(ClaimsCursorRow.FACTURE_LC, 0) -
                     nvl(ClaimsCursorRow.PAIEMENTS_LC, 0) -
                     nvl(ClaimsCursorRow.COVER_AMOUNT_LC, 0)
                   , nvl(ClaimsCursorRow.FACTURE_FC, 0) -
                     nvl(ClaimsCursorRow.PAIEMENTS_FC, 0) -
                     nvl(ClaimsCursorRow.COVER_AMOUNT_FC, 0)
                   , nvl(ClaimsCursorRow.FACTURE_EUR, 0) -
                     nvl(ClaimsCursorRow.PAIEMENTS_EUR, 0) -
                     nvl(ClaimsCursorRow.COVER_AMOUNT_EUR, 0)
                   , ClaimsCursorRow.NO_RAPP
                   , nvl(ClaimsCursorRow.COVER_AMOUNT_LC, 0)
                   , nvl(ClaimsCursorRow.COVER_AMOUNT_FC, 0)
                   , nvl(ClaimsCursorRow.COVER_AMOUNT_EUR, 0)
                   , null
                   , sysdate
                   , null
                   , USER_INI
                   , null
                   , null
                   , null
                   , to_number(ClaimsCursorRow.C_STATUS_EXPIRY)
                   , ClaimsCursorRow.PAC_REMAINDER_CATEGORY_ID
                   , '0'
                   , '0'
                    );

        TotLC         :=
          TotLC +
          nvl(ClaimsCursorRow.FACTURE_LC, 0) -
          nvl(ClaimsCursorRow.PAIEMENTS_LC, 0) -
          nvl(ClaimsCursorRow.COVER_AMOUNT_LC, 0);
        TotFC         :=
          TotFC +
          nvl(ClaimsCursorRow.FACTURE_FC, 0) -
          nvl(ClaimsCursorRow.PAIEMENTS_FC, 0) -
          nvl(ClaimsCursorRow.COVER_AMOUNT_FC, 0);
        TotEUR        :=
          TotEUR +
          nvl(ClaimsCursorRow.FACTURE_EUR, 0) -
          nvl(ClaimsCursorRow.PAIEMENTS_EUR, 0) -
          nvl(ClaimsCursorRow.COVER_AMOUNT_EUR, 0);

        if ClaimsCursorRow.NO_RAPP > NoRappel then
          NoRappel  := ClaimsCursorRow.NO_RAPP;
        end if;

        fetch ClaimsCursor
         into ClaimsCursorRow;

        -- Attention : Si fin de curseur ClaimsCursorRow.* = valeurs précédentes !!!
        LastDocument  := ClaimsCursor%notfound;
/*
        raise_application_error(-20000, 'C: ' || to_char(AccountId) || ' - ' || to_char(ClaimsCursorRow.ACS_ACCOUNT_ID) ||
                                        ' / M: ' || to_char(CurrencyId) || ' - ' ||to_char(ClaimsCursorRow.ACS_FINANCIAL_CURRENCY_ID));
*/
      end loop;

      NoRemainder       := ACT_CLAIMS_MANAGEMENT.MaxDetailOfCategory(CategoryId, NoRappel);

      -- Textes relances - ACT_REMINDER_TEXT
      insert into ACT_REMINDER_TEXT
                  (ACT_REMINDER_TEXT_ID
                 , ACT_DOCUMENT_ID
                 , ACT_PART_IMPUTATION_ID
                 , C_TEXT_TYPE
                 , REM_TEXT
                 , A_DATECRE
                 , A_DATEMOD
                 , A_IDCRE
                 , A_IDMOD
                 , A_RECLEVEL
                 , A_RECSTATUS
                  )
        (select ACT_CLAIMS_MANAGEMENT.GetNextId
              , DocumentId
              , PartImputationId
              , C_TEXT_TYPE
              , TRA_TEXT
              , sysdate
              , null
              , USER_INI
              , null
              , null
              , null
           from PAC_REMAINDER_DETAIL DET
              , PAC_REM_DETAIL_S_TEXT DET_TXT
              , PAC_TEXT TXT
              , PAC_TEXT_TRADUCTION TXT_TRA
          where DET.PAC_REMAINDER_DETAIL_ID = DET_TXT.PAC_REMAINDER_DETAIL_ID
            and DET_TXT.PAC_TEXT_ID = TXT.PAC_TEXT_ID
            and TXT.PAC_TEXT_ID = TXT_TRA.PAC_TEXT_ID
            and DET.PAC_REMAINDER_CATEGORY_ID = CategoryId
            and DET.RDE_NO_REMAINDER = NoRemainder
            and TXT_TRA.PC_LANG_ID = LangId);

      -- Echéances - ACT_EXPIRY
      ------ Mise à jour du montant total document
      UpdateDocAmounts(PartImputationId
                     , TotLC
                     , TotFC
                     , TotEUR
                     , aPAR_REMIND_DATE + ACT_CLAIMS_MANAGEMENT.MaxExpiryDaysOfCategory(CategoryId, NoRappel)
                     , false
                      );
      commit;
    end loop;

    close ClaimsCursor;

  end CREATE_CLAIMS_DOCUMENTS;

------------------------------------
  procedure CLAIMS_EXCEPTION_INITIALIZE(aACJ_JOB_TYPE_ID ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type)
  is
  begin
    delete from ACT_CLAIMS_TR_EXCEPTION;

    delete from ACT_CLAIMS_PAR_EXCEPTION;

    ------ Mise à jour table temporaire des transactions à ignorer (dépend du modèle de travail)
    insert into ACT_CLAIMS_TR_EXCEPTION
                (PAR_SELECTION
               , ACJ_CATALOGUE_DOCUMENT_ID
                )
      (select 1
            , EXC.ACJ_CATALOGUE_DOCUMENT_ID
         from ACJ_JOB_TYPE TYP
            , ACJ_EVENT EVE
            , ACJ_EXPIRY_EXCEPTION EXC
        where TYP.ACJ_JOB_TYPE_ID = EVE.ACJ_JOB_TYPE_ID
          and EVE.ACJ_EVENT_ID = EXC.ACJ_EVENT_ID
          and TYP.ACJ_JOB_TYPE_ID = aACJ_JOB_TYPE_ID);

    ------ Mise à jour table temporaire des partenaires à ignorer (dépend du modèle de travail)
    insert into ACT_CLAIMS_PAR_EXCEPTION
                (PAR_SELECTION
               , ACJ_CATALOGUE_DOCUMENT_ID
                )
      (select 1
            , EXC.ACJ_CATALOGUE_DOCUMENT_ID
         from ACJ_JOB_TYPE TYP
            , ACJ_EVENT EVE
            , ACJ_PARTNER_EXCEPTION EXC
        where TYP.ACJ_JOB_TYPE_ID = EVE.ACJ_JOB_TYPE_ID
          and EVE.ACJ_EVENT_ID = EXC.ACJ_EVENT_ID
          and TYP.ACJ_JOB_TYPE_ID = aACJ_JOB_TYPE_ID);
  end CLAIMS_EXCEPTION_INITIALIZE;

---------------------------
  function GET_CLAIMS_ADDRESS(aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type, aCUSTOMER number)
    return number
  is
    ADDRESS_ID            PAC_ADDRESS.PAC_ADDRESS_ID%type;
    REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type;
  begin
    -- Recherche adresse relance client ou fournisseur
    if aCUSTOMER = 1 then
      select max(PAC_ADDRESS_ID)
           , max(PAC_REMAINDER_CATEGORY_ID)
        into ADDRESS_ID
           , REMAINDER_CATEGORY_ID
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aPAC_PERSON_ID;
    else
      select max(PAC_ADDRESS_ID)
           , max(PAC_REMAINDER_CATEGORY_ID)
        into ADDRESS_ID
           , REMAINDER_CATEGORY_ID
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = aPAC_PERSON_ID;
    end if;

    -- Recherche type adresse catégorie relance client ou fournisseur
    if ADDRESS_ID is null then
      select max(AD.PAC_ADDRESS_ID)
        into ADDRESS_ID
        from PAC_ADDRESS AD
           , PAC_REMAINDER_CATEGORY rem
       where AD.PAC_PERSON_ID = aPAC_PERSON_ID
         and rem.PAC_REMAINDER_CATEGORY_ID = REMAINDER_CATEGORY_ID
         and AD.DIC_ADDRESS_TYPE_ID = rem.DIC_ADDRESS_TYPE_ID;
    end if;

    -- recherche de l'adresse principale
    if ADDRESS_ID is null then
      select max(PAC_ADDRESS_ID)
        into ADDRESS_ID
        from PAC_ADDRESS
       where PAC_PERSON_ID = aPAC_PERSON_ID
         and ADD_PRINCIPAL = 1;
    end if;

    -- Recherche type adresse par défaut client ou fournisseur
    if ADDRESS_ID is null then
      select max(PAC_ADDRESS_ID)
        into ADDRESS_ID
        from PAC_ADDRESS
       where PAC_PERSON_ID = aPAC_PERSON_ID
         and DIC_ADDRESS_TYPE_ID = PAC_PARTNER_MANAGEMENT.GET_ADDRESS_TYPE;
    end if;

    return ADDRESS_ID;
  end GET_CLAIMS_ADDRESS;

----------------------
  procedure SetDocNumber(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type)
  is
    DOCUMENT_ID           ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    FINANCIAL_YEAR_ID     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    strDocNumber          ACT_DOCUMENT.DOC_NUMBER%type;
    MethodId              ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;

    cursor DocToNumber(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type)
    is
      select   ACT_DOCUMENT_ID
             , ACJ_CATALOGUE_DOCUMENT_ID
             , ACS_FINANCIAL_YEAR_ID
          from ACT_DOCUMENT
         where ACT_JOB_ID = aACT_JOB_ID
           and DOC_NUMBER is null
      order by DOC_ORDER_NO;
  begin
    select max(ACJ_NUMBER_METHOD_ID)
      into MethodId
      from ACJ_NUMBER_METHOD;

    -- Permet d'éviter de relancer inutilement la méthode de numérotation sur un grand nombre de documents
    if MethodId is not null then
      open DocToNumber(aACT_JOB_ID);

      fetch DocToNumber
       into DOCUMENT_ID
          , CATALOGUE_DOCUMENT_ID
          , FINANCIAL_YEAR_ID;

      while DocToNumber%found loop
        ACT_FUNCTIONS.GetDocNumber(CATALOGUE_DOCUMENT_ID, FINANCIAL_YEAR_ID, strDocNumber);

        update ACT_DOCUMENT
           set DOC_NUMBER = strDocNumber
         where ACT_DOCUMENT_ID = DOCUMENT_ID;

        fetch DocToNumber
         into DOCUMENT_ID
            , CATALOGUE_DOCUMENT_ID
            , FINANCIAL_YEAR_ID;
      end loop;

      close DocToNumber;
    end if;
  end SetDocNumber;

-------------------------
  function GET_LANG_ADDRESS(aPAC_ADDRESS_ID PAC_ADDRESS.PAC_ADDRESS_ID%type)
    return number
  is
    LANG_ID PCS.PC_LANG.PC_LANG_ID%type;
  begin
    select max(PC_LANG_ID)
      into LANG_ID
      from PAC_ADDRESS
     where PAC_ADDRESS_ID = aPAC_ADDRESS_ID;

    return LANG_ID;
  end GET_LANG_ADDRESS;

---------------------
  function GetMinAmount(
    aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_DETAIL.PAC_REMAINDER_CATEGORY_ID%type
  , aRDE_NO_REMAINDER          PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  )
    return PAC_REMAINDER_DETAIL.RDE_MIN_AMOUNT%type
  is
    MinAmount PAC_REMAINDER_DETAIL.RDE_MIN_AMOUNT%type;
  begin
    begin
      select RDE_MIN_AMOUNT
        into MinAmount
        from PAC_REMAINDER_DETAIL
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
         and RDE_NO_REMAINDER = aRDE_NO_REMAINDER;
    exception
      when others then
        select max(RDE_MIN_AMOUNT)
          into MinAmount
          from PAC_REMAINDER_DETAIL
         where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
           and RDE_NO_REMAINDER = (select max(RDE_NO_REMAINDER)
                                     from PAC_REMAINDER_DETAIL
                                    where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID);
    end;

    if MinAmount is null then
      MinAmount  := -999999999;
    end if;

    return MinAmount;
  end GetMinAmount;

-------------------------
  function IsReleveCategory(aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type)
    return number
  is
    NoRemainder PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type;
    result      number                                       := 0;
  begin
    begin
      select RDE_NO_REMAINDER
        into NoRemainder
        from PAC_REMAINDER_DETAIL
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
         and RDE_NO_REMAINDER = 0;

      if NoRemainder is not null then
        result  := 1;
      end if;
    exception
      when others then
        result  := 0;
    end;

    return result;
  end IsReleveCategory;

-------------------
  function ExpiryDate(
    aEXP_ADAPTED               ACT_EXPIRY.EXP_ADAPTED%type
  , aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  , aNO_RAPP                   PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  )
    return ACT_EXPIRY.EXP_ADAPTED%type
  is
    Days         PAC_REMAINDER_DETAIL.RDE_DAY%type;
    DateOfExpiry ACT_EXPIRY.EXP_ADAPTED%type;
  begin
    begin
      select RDE_DAY
        into Days
        from PAC_REMAINDER_DETAIL
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
         and RDE_NO_REMAINDER = aNO_RAPP;
    exception
      when no_data_found then
        select nvl(max(RDE_DAY), 0)
          into Days
          from PAC_REMAINDER_DETAIL
         where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID;
    end;

    DateOfExpiry  := aEXP_ADAPTED + Days;
    return DateOfExpiry;
  end ExpiryDate;

----------------------------
  function MaxDetailOfCategory(
    aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  , aRDE_NO_REMAINDER          PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  )
    return PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  is
    NoRemainder PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type;
  begin
    select max(RDE_NO_REMAINDER)
      into NoRemainder
      from PAC_REMAINDER_DETAIL
     where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID;

    if    (NoRemainder is null)
       or (aRDE_NO_REMAINDER < NoRemainder) then
      NoRemainder  := aRDE_NO_REMAINDER;
    end if;

    return NoRemainder;
  end MaxDetailOfCategory;

--------------------------------
  function MaxExpiryDaysOfCategory(
    aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  , aRDE_NO_REMAINDER          PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  )
    return PAC_REMAINDER_DETAIL.RDE_EXPIRY_DAYS%type
  is
    ExpiryDays PAC_REMAINDER_DETAIL.RDE_EXPIRY_DAYS%type;
  begin
    begin
      select RDE_EXPIRY_DAYS
        into ExpiryDays
        from PAC_REMAINDER_DETAIL
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
         and RDE_NO_REMAINDER = aRDE_NO_REMAINDER;
    exception
      when no_data_found then
        select max(RDE_EXPIRY_DAYS)
          into ExpiryDays
          from PAC_REMAINDER_DETAIL
         where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID;
    end;

    if ExpiryDays is null then
      ExpiryDays  := 0;
    end if;

    return ExpiryDays;
  end MaxExpiryDaysOfCategory;

------------------------------
  procedure updatePaymentAmounts(aCLAIMS number, aCOVER number)
  is
    cursor ClaimsCursor
    is
      select ACT_EXPIRY_ID
        from ACT_CLAIMS
       where C_STATUS_EXPIRY <> '1';

    ClaimsCursorRow ClaimsCursor%rowtype;
    PaiedLC         ACT_DET_PAYMENT.DET_PAIED_LC%type;
    PaiedFC         ACT_DET_PAYMENT.DET_PAIED_FC%type;
    PaiedEUR        ACT_DET_PAYMENT.DET_PAIED_EUR%type;
    CoveredLC       ACT_COVER_INFORMATION.COV_AMOUNT_LC%type    default 0;
    CoveredFC       ACT_COVER_INFORMATION.COV_AMOUNT_FC%type    default 0;
    CoveredEUR      ACT_COVER_INFORMATION.COV_AMOUNT_EUR%type   default 0;
  -----
  begin
    open ClaimsCursor;

    fetch ClaimsCursor
     into ClaimsCursorRow;

    while ClaimsCursor%found loop
      select nvl(sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0)
                     + nvl(DET_DIFF_EXCHANGE, 0) )
               , 0
                )
           , nvl(sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) ), 0)
           , nvl(sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) ), 0)
        into PaiedLC
           , PaiedFC
           , PaiedEUR
        from ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = ClaimsCursorRow.ACT_EXPIRY_ID;

      if aCOVER = 1 then
        select nvl(sum(COV_AMOUNT_LC), 0)
             , nvl(sum(COV_AMOUNT_FC), 0)
             , nvl(sum(COV_AMOUNT_EUR), 0)
          into CoveredLC
             , CoveredFC
             , CoveredEUR
          from ACT_COVER_INFORMATION COV
             , ACT_COVER_S_EXPIRY exp
         where exp.ACT_EXPIRY_ID = ClaimsCursorRow.ACT_EXPIRY_ID
           and exp.ACT_COVER_INFORMATION_ID = COV.ACT_COVER_INFORMATION_ID;
      end if;

      update ACT_CLAIMS
         set PAIEMENTS_LC = PaiedLC
           , PAIEMENTS_FC = PaiedFC
           , PAIEMENTS_EUR = PaiedEUR
           , COVER_AMOUNT_LC = CoveredLC
           , COVER_AMOUNT_FC = CoveredFC
           , COVER_AMOUNT_EUR = CoveredEUR
       where ACT_EXPIRY_ID = ClaimsCursorRow.ACT_EXPIRY_ID;

      fetch ClaimsCursor
       into ClaimsCursorRow;
    end loop;

    close ClaimsCursor;

    if     (aCOVER = 1)
       and (aCLAIMS = 1) then
      delete from ACT_CLAIMS
            where FACTURE_LC - PAIEMENTS_LC - COVER_AMOUNT_LC <= 0;
    end if;
  end updatePaymentAmounts;

------------------
  function GetNextId
    return ACT_AUX_ACCOUNT_FILTER.ACT_AUX_ACCOUNT_FILTER_ID%type
  is
    result ACT_AUX_ACCOUNT_FILTER.ACT_AUX_ACCOUNT_FILTER_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into result
      from dual;

    return result;
  end GetNextId;

  --------
  function NegativeClaimsNumber(
    aACT_EXPIRY_ID             ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_CATEGORY.PAC_REMAINDER_CATEGORY_ID%type
  )
    return ACT_REMINDER.REM_NUMBER%type
  is
    LastNumber ACT_REMINDER.REM_NUMBER%type;
  -----
  begin
    LastNumber  := ACT_FUNCTIONS.LastClaimsNumber(aACT_EXPIRY_ID);

    if    LastNumber > 0
       or ACT_CLAIMS_MANAGEMENT.IsReleveCategory(aPAC_REMAINDER_CATEGORY_ID) = 0 then
      LastNumber  := LastNumber + 1;
    end if;

    return LastNumber;
  end NegativeClaimsNumber;

---------------------
  function GetReminderDetailId(
    aPAC_REMAINDER_CATEGORY_ID PAC_REMAINDER_DETAIL.PAC_REMAINDER_CATEGORY_ID%type
  , aRDE_NO_REMAINDER          PAC_REMAINDER_DETAIL.RDE_NO_REMAINDER%type
  )
    return PAC_REMAINDER_DETAIL.PAC_REMAINDER_DETAIL_ID%type
  is
    result PAC_REMAINDER_DETAIL.PAC_REMAINDER_DETAIL_ID%type;
  begin
    select max(PAC_REMAINDER_DETAIL_ID)
      into result
      from PAC_REMAINDER_DETAIL
     where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
       and RDE_NO_REMAINDER = aRDE_NO_REMAINDER;

    if result is null then
      select max(PAC_REMAINDER_DETAIL_ID)
        into result
        from PAC_REMAINDER_DETAIL
       where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID
         and RDE_NO_REMAINDER = (select max(RDE_NO_REMAINDER)
                                   from PAC_REMAINDER_DETAIL
                                  where PAC_REMAINDER_CATEGORY_ID = aPAC_REMAINDER_CATEGORY_ID);
    end if;

    if result is null then
      raise_application_error(-20000, 'PAC_REMAINDER_DETAIL not found !');
    end if;

    return result;
  end GetReminderDetailId;

---------------------
  function IsInterestOrChargeDisabled(aACT_REMINDER_ID ACT_REMINDER.ACT_REMINDER_ID%type, aCheckInterest number)
    return number
  is
    --RemindCateg PAC_REMAINDER_CATEGORY.C_REMAINDER_CAT_TYPE %type;
    NoCharge   number(1);
    NoInterest number(1);
  begin
/*
    select CAT.C_REMAINDER_CAT_TYPE
      into RemindCateg
      from PAC_REMAINDER_CATEGORY CAT
        , ACT_REMINDER rem
    where ACT_REMINDER_ID = aACT_REMINDER_ID
      and CAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID;

    if RemindCateg = '2' then
      select nvl(min(SCAT.RSC_NO_CHARGE_MGM), 0)
          , nvl(min(SCAT.RSC_NO_INTEREST_MGM), 0)
        into NoCharge
          , NoInterest
        from PAC_REMAINDER_S_CATALOGUE SCAT
          , ACT_DOCUMENT DOC
          , ACT_EXPIRY exp
          , ACT_REMINDER rem
      where ACT_REMINDER_ID = aACT_REMINDER_ID
        and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
        and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
        and SCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
        and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;
    else
      select nvl(min(CUS.CUS_NO_REM_CHARGE), 0)
          , nvl(min(CUS.CUS_NO_MORATORIUM_INTEREST), 0)
        into NoCharge
          , NoInterest
        from PAC_CUSTOM_PARTNER CUS
          , ACT_PART_IMPUTATION PAR
          , ACT_REMINDER rem
      where ACT_REMINDER_ID = aACT_REMINDER_ID
        and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
        and CUS.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID;
    end if;
*/
    select decode(nvl(min(RCAT.C_REMAINDER_CHARGE_TYPE), '0'), '0', 1, 0)
         , decode(nvl(min(RCAT.C_MORATORIUM_INTEREST), '0'), '0', 1, 0)
      into NoCharge
         , NoInterest
      from PAC_REMAINDER_CATEGORY RCAT
         , ACT_REMINDER rem
     where ACT_REMINDER_ID = aACT_REMINDER_ID
       and rem.PAC_REMAINDER_CATEGORY_ID = RCAT.PAC_REMAINDER_CATEGORY_ID;

    if    (    aCheckInterest != 0
           and NoInterest = 0)
       or (    aCheckInterest = 0
           and NoCharge = 0) then
      select nvl(min(CUS.CUS_NO_REM_CHARGE), 0)
           , nvl(min(CUS.CUS_NO_MORATORIUM_INTEREST), 0)
        into NoCharge
           , NoInterest
        from PAC_CUSTOM_PARTNER CUS
           , ACT_PART_IMPUTATION PAR
           , ACT_REMINDER rem
       where ACT_REMINDER_ID = aACT_REMINDER_ID
         and PAR.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
         and CUS.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID;
    end if;

    if    (    aCheckInterest != 0
           and NoInterest = 0)
       or (    aCheckInterest = 0
           and NoCharge = 0) then
      select nvl(min(SCAT.RSC_NO_CHARGE_MGM), 0)
           , nvl(min(SCAT.RSC_NO_INTEREST_MGM), 0)
        into NoCharge
           , NoInterest
        from PAC_REMAINDER_S_CATALOGUE SCAT
           , ACT_DOCUMENT DOC
           , ACT_EXPIRY exp
           , ACT_REMINDER rem
       where ACT_REMINDER_ID = aACT_REMINDER_ID
         and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
         and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
         and SCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
         and SCAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;
    end if;

    if    (    aCheckInterest != 0
           and NoInterest = 0)
       or (    aCheckInterest = 0
           and NoCharge = 0) then
      select nvl(min(PART.PAR_NO_REMIND_CHARGE), 0)
           , nvl(min(PART.PAR_NO_REMIND_INTEREST), 0)
        into NoCharge
           , NoInterest
        from ACT_PART_IMPUTATION PART
           , ACT_EXPIRY exp
           , ACT_REMINDER rem
       where ACT_REMINDER_ID = aACT_REMINDER_ID
         and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
         and PART.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID;
    end if;

    if aCheckInterest != 0 then
      return NoInterest;
    else
      return NoCharge;
    end if;
  end IsInterestOrChargeDisabled;

  procedure UpdateDocumentChargeOrInterest(
    aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aUpdateCharge           out    boolean
  , aUpdateInterest         out    boolean
  )
  is
    vCharge   PAC_REMAINDER_CATEGORY.RCA_DOC_AMOUNT_CHARGE%type;
    vInterest PAC_REMAINDER_CATEGORY.RCA_DOC_AMOUNT_INTEREST%type;
  begin
    select min(RCAT.RCA_DOC_AMOUNT_CHARGE)
         , min(RCAT.RCA_DOC_AMOUNT_INTEREST)
      into vCharge
         , vInterest
      from PAC_REMAINDER_CATEGORY RCAT
         , ACT_REMINDER rem
     where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
       and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID;

    aUpdateCharge    := vCharge = 1;
    aUpdateInterest  := vInterest = 1;
  end UpdateDocumentChargeOrInterest;

  procedure CalcDocAmounts(
    aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aAmountLC               out    ACT_EXPIRY.EXP_AMOUNT_LC%type
  , aAmountFC               out    ACT_EXPIRY.EXP_AMOUNT_FC%type
  , aAmountEUR              out    ACT_EXPIRY.EXP_AMOUNT_EUR%type
  , aUpdateDocCharge               boolean default null
  , aUpdateDocinterest             boolean default null
  )
  is
    vChargeLC   ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    vChargeFC   ACT_PART_IMPUTATION.PAR_CHARGES_FC%type;
    vInterestLC ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
    vInterestFC ACT_PART_IMPUTATION.PAR_INTEREST_FC%type;
    vCharge     boolean                                    := false;
    vInterest   boolean                                    := false;
  begin
    select nvl(sum(REM_PAYABLE_AMOUNT_LC), 0)
         , nvl(sum(REM_PAYABLE_AMOUNT_FC), 0)
         , nvl(sum(REM_PAYABLE_AMOUNT_EUR), 0)
      into aAmountLC
         , aAmountFC
         , aAmountEUR
      from ACT_REMINDER
     where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

    --Recherche si màj montant document
    if    aUpdateDocCharge is not null
       or aUpdateDocinterest is not null then
      if aUpdateDocCharge is not null then
        vCharge  := aUpdateDocCharge;
      end if;

      if aUpdateDocinterest is not null then
        vInterest  := aUpdateDocinterest;
      end if;
    else
      UpdateDocumentChargeOrInterest(aACT_PART_IMPUTATION_ID, vCharge, vInterest);
    end if;

    if    vCharge
       or vInterest then
      select sum(nvl(PAR_CHARGES_LC, 0) )
           , sum(nvl(PAR_CHARGES_FC, 0) )
           , sum(nvl(PAR_INTEREST_LC, 0) )
           , sum(nvl(PAR_INTEREST_FC, 0) )
        into vChargeLC
           , vChargeFC
           , vInterestLC
           , vInterestFC
        from ACT_PART_IMPUTATION
       where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

      if vCharge then
        aAmountLC  := aAmountLC + vChargeLC;
        aAmountFC  := aAmountFC + vChargeFC;
      end if;

      if vInterest then
        aAmountLC  := aAmountLC + vInterestLC;
        aAmountFC  := aAmountFC + vInterestFC;
      end if;
    end if;
  end CalcDocAmounts;

---------------------
  procedure UpdateDocChargeAndInterest(
    aACT_PART_IMPUTATION_ID in ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aUpdateDocCharge           boolean default true
  , aUpdateDocinterest         boolean default true
  )
  is
    vCharge    boolean;
    vInterest  boolean;
    vAmountLC  ACT_EXPIRY.EXP_AMOUNT_LC%type;
    vAmountFC  ACT_EXPIRY.EXP_AMOUNT_FC%type;
    vAmountEUR ACT_EXPIRY.EXP_AMOUNT_EUR%type;
  begin
    UpdateDocumentChargeOrInterest(aACT_PART_IMPUTATION_ID, vCharge, vInterest);

    if    (    vCharge
           and aUpdateDocCharge)
       or (    vInterest
           and aUpdateDocinterest) then
      CalcDocAmounts(aACT_PART_IMPUTATION_ID, vAmountLC, vAmountFC, vAmountEUR, vCharge, vInterest);
      --Màj montant document et échéance
      UpdateDocAmounts(aACT_PART_IMPUTATION_ID, vAmountLC, vAmountFC, vAmountEUR, null, true);
    end if;
  end UpdateDocChargeAndInterest;

  procedure UpdatePartImputationInterest(
    aACT_JOB_ID             ACT_JOB.ACT_JOB_ID%type
  , aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type default null
  )
  is
    InterestLC ACT_PART_IMPUTATION.PAR_INTEREST_LC%type;
    InterestFC ACT_PART_IMPUTATION.PAR_INTEREST_FC%type;
  begin
    --Remise à null des montants avant màj
    if aACT_PART_IMPUTATION_ID is not null then
      update ACT_PART_IMPUTATION PART
         set PAR_INTEREST_LC = null
           , PAR_INTEREST_FC = null
       where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
    elsif aACT_JOB_ID is not null then
      update ACT_PART_IMPUTATION PART
         set PAR_INTEREST_LC = null
           , PAR_INTEREST_FC = null
       where PART.ACT_DOCUMENT_ID in(select ACT_DOCUMENT_ID
                                       from ACT_DOCUMENT DOC
                                      where (   DOC.ACT_JOB_ID = aACT_JOB_ID
                                             or aACT_JOB_ID is null) );
    end if;

    for tpl_PartImputation in (select   rem.ACT_PART_IMPUTATION_ID
                                      , sum(nvl(rem.REM_INTEREST_AMOUNT_RC, 0) ) REM_INTEREST_AMOUNT_RC
                                      , nvl(min(RCAT.RCA_INTEREST_RC), 0) RCA_INTEREST_RC
                                      , min(PART.ACS_ACS_FINANCIAL_CURRENCY_ID) ACS_ACS_FINANCIAL_CURRENCY_ID
                                      , min(PART.ACS_FINANCIAL_CURRENCY_ID) ACS_FINANCIAL_CURRENCY_ID
                                   from PAC_REMAINDER_CATEGORY RCAT
                                      , ACT_PART_IMPUTATION PART
                                      , ACT_REMINDER rem
                                      , ACT_DOCUMENT DOC
                                  where (   PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
                                         or aACT_PART_IMPUTATION_ID is null
                                        )
                                    and (   DOC.ACT_JOB_ID = aACT_JOB_ID
                                         or aACT_JOB_ID is null)
                                    and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                    and PART.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
                                    and rem.PAC_REMAINDER_CATEGORY_ID = RCAT.PAC_REMAINDER_CATEGORY_ID
                                    and rem.C_REM_STATUS_INTEREST = '2'
                               group by rem.ACT_PART_IMPUTATION_ID) loop
      --Calcule des montants
      InterestLC  := null;
      InterestFC  := null;

      if    tpl_PartImputation.RCA_INTEREST_RC = 0
         or (    tpl_PartImputation.RCA_INTEREST_RC = 1
             and tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID = tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID
            ) then
        InterestLC  := tpl_PartImputation.REM_INTEREST_AMOUNT_RC;
      /* Pas de màj
      if tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID != tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID then
        InterestFC := ACS_FUNCTION.ConvertAmountForView(InterestLC, tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID, tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID, nvl(aPAR_REMIND_DATE, SysDate), null, null, 1);
      else
        InterestFC := 0;
      end if;
      */
      else
        InterestFC  := tpl_PartImputation.REM_INTEREST_AMOUNT_RC;
      --InterestLC := ACS_FUNCTION.ConvertAmountForView(InterestFC, tpl_PartImputation.ACS_FINANCIAL_CURRENCY_ID, tpl_PartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID, nvl(aPAR_REMIND_DATE, SysDate), null, null, 1);
      end if;

      --Màj imputation parttenaire
      update ACT_PART_IMPUTATION
         set PAR_INTEREST_LC = InterestLC
           , PAR_INTEREST_FC = InterestFC
       where ACT_PART_IMPUTATION_ID = tpl_PartImputation.ACT_PART_IMPUTATION_ID;

      --Màj si nécessaire du montant document et échéances
      UpdateDocChargeAndInterest(tpl_PartImputation.ACT_PART_IMPUTATION_ID, false, true);
    end loop;
  end UpdatePartImputationInterest;

  procedure GetInterestStartDates(
    aACT_EXPIRY_ID           ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aC_INTEREST_REF_DATE     PAC_REMAINDER_CATEGORY.C_INTEREST_REF_DATE%type
  , aValueDate           out date
  , aTransactionDate     out date
  )
  is
    vFirstAccStmntId ACT_REMINDER.ACT_REMINDER_ID%type;
  begin
    if aC_INTEREST_REF_DATE in('3', '4') then
      select min(ACT_REMINDER_ID)
        into vFirstAccStmntId
        from (select   rem.ACT_REMINDER_ID
                     , DOC.DOC_DOCUMENT_DATE
                     , DOC.ACT_DOCUMENT_ID
                  from ACJ_CATALOGUE_DOCUMENT CAT
                     , ACT_DOCUMENT DOC
                     , ACT_EXPIRY exp
                     , ACT_REMINDER rem
                 where rem.ACT_EXPIRY_ID = aACT_EXPIRY_ID
                   and rem.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                   and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and rem.REM_NUMBER = 0
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and CAT.C_TYPE_CATALOGUE = '8'
                   and CAT.C_REMINDER_METHOD = '01'
              order by DOC.DOC_DOCUMENT_DATE
                     , DOC.ACT_DOCUMENT_ID)
       where rownum = 1;

      if vFirstAccStmntId is not null then
        select decode(aC_INTEREST_REF_DATE, '3', exp.EXP_ADAPTED, DOC.DOC_DOCUMENT_DATE)
             , decode(aC_INTEREST_REF_DATE, '3', nvl(exp.EXP_INTEREST_VALUE, exp.EXP_ADAPTED), DOC.DOC_DOCUMENT_DATE)
          into aTransactionDate
             , aValueDate
          from ACT_DOCUMENT DOC
             , ACT_EXPIRY exp
             , ACT_REMINDER rem
         where rem.ACT_REMINDER_ID = vFirstAccStmntId
           and rem.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and exp.EXP_CALC_NET = 1;
      end if;
    end if;

    if vFirstAccStmntId is null then
      select decode(aC_INTEREST_REF_DATE, '2', IMP.IMF_TRANSACTION_DATE, exp.EXP_ADAPTED)
           , decode(aC_INTEREST_REF_DATE, '2', IMP.IMF_VALUE_DATE, nvl(exp.EXP_INTEREST_VALUE, exp.EXP_ADAPTED) )
        into aTransactionDate
           , aValueDate
        from ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_EXPIRY exp
       where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and IMP.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and FIN.FIN_COLLECTIVE = 1;
    end if;
  end GetInterestStartDates;

  procedure CalcInterest(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type, aPAR_REMIND_DATE date)
  is
    --curseur sur les échéances ouvertes et donc relancées
    cursor csr_InitDetailsPO(JobId number)
    is
      select   case
                 when rem.ACS_FINANCIAL_CURRENCY_ID = rem.ACS_ACS_FINANCIAL_CURRENCY_ID
                  or nvl(RCAT.RCA_INTEREST_RC, 0) = 0 then nvl(DET_PAIED_LC, 0) +
                                                           nvl(DET_DISCOUNT_LC, 0) +
                                                           nvl(DET_DEDUCTION_LC, 0) +
                                                           nvl(DET_DIFF_EXCHANGE, 0)
                 else nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0)
               end PAIED_RC
             , case
                 when rem.ACS_FINANCIAL_CURRENCY_ID = rem.ACS_ACS_FINANCIAL_CURRENCY_ID
                  or nvl(RCAT.RCA_INTEREST_RC, 0) = 0 then nvl(exp.EXP_AMOUNT_LC, 0)
                 else nvl(exp.EXP_AMOUNT_FC, 0)
               end AMOUNT_RC
             , rem.ACT_REMINDER_ID
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_TRANSACTION_DATE
             , rem.ACT_EXPIRY_ID
             , PAY.ACT_DET_PAYMENT_ID
             , RDET.PAC_REMAINDER_DETAIL_ID
             , nvl(decode(RDET.ACS_INTEREST_CATEG_ID
                        , null, RCAT.RCA_INTEREST_WAITING_DAYS
                        , RDET.RDE_INTEREST_WAITING_DAYS
                         )
                 , 0
                  ) RDE_INTEREST_WAITING_DAYS
             , nvl(RDET.ACS_INTEREST_CATEG_ID, RCAT.ACS_INTEREST_CATEG_ID) ACS_INTEREST_CATEG_ID
             , RCAT.C_INTEREST_REF_DATE
          from ACT_ETAT_JOURNAL JOU
             , ACT_DOCUMENT DOC2
             , PAC_REMAINDER_DETAIL RDET
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_EXPIRY exp
             , ACT_DET_PAYMENT PAY
             , PAC_REMAINDER_CATEGORY RCAT
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC1
         where DOC1.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC1.ACT_DOCUMENT_ID
           and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and PAY.ACT_EXPIRY_ID(+) = rem.ACT_EXPIRY_ID
           and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
           and PAY.ACT_DOCUMENT_ID = DOC2.ACT_DOCUMENT_ID(+)
           and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID(+)
           and IMP.C_GENRE_TRANSACTION(+) = '1'
           and RDET.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RDET.PAC_REMAINDER_DETAIL_ID =
                                ACT_CLAIMS_MANAGEMENT.GetReminderDetailId(rem.PAC_REMAINDER_CATEGORY_ID, rem.REM_NUMBER)
           and DOC2.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
           and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                     and JOU.C_SUB_SET = 'REC')
                or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                    and JOU.C_SUB_SET = 'PAY')
                or (IMP.ACT_PART_IMPUTATION_ID is null)
               )
           and rem.REM_STATUS = 0
           and ACT_CLAIMS_MANAGEMENT.IsInterestOrChargeDisabled(rem.ACT_REMINDER_ID, 1) = 0
           and RCAT.C_MORATORIUM_INTEREST = '1'
      order by rem.ACT_REMINDER_ID
             , IMP.IMF_VALUE_DATE;

    tpl_InitDetailsPO    csr_InitDetailsPO%rowtype;

    --curseur sur les échéances soldées et donc pas relancée
    cursor csr_InitDetailsPay(JobId number)
    is
      select   case
                 when rem.ACS_FINANCIAL_CURRENCY_ID = rem.ACS_ACS_FINANCIAL_CURRENCY_ID
                  or nvl(RCAT.RCA_INTEREST_RC, 0) = 0 then nvl(DET_PAIED_LC, 0) +
                                                           nvl(DET_DISCOUNT_LC, 0) +
                                                           nvl(DET_DEDUCTION_LC, 0) +
                                                           nvl(DET_DIFF_EXCHANGE, 0)
                 else nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0)
               end PAIED_RC
             , case
                 when rem.ACS_FINANCIAL_CURRENCY_ID = rem.ACS_ACS_FINANCIAL_CURRENCY_ID
                  or nvl(RCAT.RCA_INTEREST_RC, 0) = 0 then nvl(exp.EXP_AMOUNT_LC, 0)
                 else nvl(exp.EXP_AMOUNT_FC, 0)
               end AMOUNT_RC
             , rem.ACT_REMINDER_ID
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_TRANSACTION_DATE
             , rem.ACT_EXPIRY_ID
             , RDET.PAC_REMAINDER_DETAIL_ID
             , nvl(decode(RDET.ACS_INTEREST_CATEG_ID
                        , null, RCAT.RCA_INTEREST_WAITING_DAYS
                        , RDET.RDE_INTEREST_WAITING_DAYS
                         )
                 , 0
                  ) RDE_INTEREST_WAITING_DAYS
             , nvl(RDET.ACS_INTEREST_CATEG_ID, RCAT.ACS_INTEREST_CATEG_ID) ACS_INTEREST_CATEG_ID
             , RCAT.C_INTEREST_REF_DATE
          from ACT_ETAT_JOURNAL JOU
             , ACT_DOCUMENT DOC2
             , PAC_REMAINDER_DETAIL RDET
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_EXPIRY exp
             , ACT_DET_PAYMENT PAY
             , PAC_REMAINDER_CATEGORY RCAT
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC1
         where DOC1.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC1.ACT_DOCUMENT_ID
           and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and PAY.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
           and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
           and PAY.ACT_DOCUMENT_ID = DOC2.ACT_DOCUMENT_ID
           and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
           and IMP.C_GENRE_TRANSACTION = '1'
           and IMP.ACT_PART_IMPUTATION_ID IS NOT NULL
           and RDET.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RDET.PAC_REMAINDER_DETAIL_ID =
                                ACT_CLAIMS_MANAGEMENT.GetReminderDetailId(rem.PAC_REMAINDER_CATEGORY_ID, rem.REM_NUMBER)
           and DOC2.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                     and JOU.C_SUB_SET = 'REC')
                or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                    and JOU.C_SUB_SET = 'PAY')
               )
           and rem.REM_STATUS = 1
           and ACT_CLAIMS_MANAGEMENT.IsInterestOrChargeDisabled(rem.ACT_REMINDER_ID, 1) = 0
           and RCAT.C_MORATORIUM_INTEREST in('2', '3')
      order by rem.ACT_REMINDER_ID
             , IMP.IMF_VALUE_DATE;

    --Liste des taux d'intérêts entre le début et la fin d'une tranche
    cursor csr_InterestRate(InterestCategId number, DateSince date, DateTo date)
    is
      select   IEL.IEL_VALID_FROM
             , IEL.IEL_APPLIED_RATE
             , IEL.IEL_MAX_AMOUNT
             , IEL.IEL_OVER_AMOUNT_RATE
          from ACS_INTEREST_ELEM IEL
         where IEL.ACS_INTEREST_CATEG_ID = InterestCategId
           and IEL.C_INT_RATE_TYPE = '1'
           and (   IEL.IEL_VALID_FROM between DateSince and DateTo
                or (IEL.IEL_VALID_FROM =
                      (select max(IEL_VALID_FROM)
                         from ACS_INTEREST_ELEM
                        where ACS_INTEREST_CATEG_ID = InterestCategId
                          and C_INT_RATE_TYPE = '1'
                          and IEL_VALID_FROM <= DateSince)
                   )
               )
      order by IEL.IEL_VALID_FROM;

    tpl_InterestRate     csr_InterestRate%rowtype;

    --Champ mis en cache (tableau) pour màj des taux et montant
    cursor csr_ReminderInterest(JobId number)
    is
      select   RIN.ACT_REMINDER_INTEREST_ID
             , RIN.ACT_REMINDER_ID
             , RIN.RIT_VALUE_DATE
             , RIN.RIT_TRANSACTION_DATE
             , RIN.RIT_DAYS_NBR
             , RIN.RIT_AMOUNT_LEFT_RC
             , nvl(RDET.ACS_INTEREST_CATEG_ID, RCAT.ACS_INTEREST_CATEG_ID) ACS_INTEREST_CATEG_ID
          from PAC_REMAINDER_DETAIL RDET
             , PAC_REMAINDER_CATEGORY RCAT
             , ACT_PART_IMPUTATION PAR
             , ACT_REMINDER_INTEREST RIN
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC
         where DOC.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RIN.ACT_REMINDER_ID = rem.ACT_REMINDER_ID
           and rem.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
           and RDET.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RDET.PAC_REMAINDER_DETAIL_ID =
                                ACT_CLAIMS_MANAGEMENT.GetReminderDetailId(rem.PAC_REMAINDER_CATEGORY_ID, rem.REM_NUMBER)
      order by RIN.ACT_REMINDER_ID;

    type Ttbl_ReminderInterest is table of csr_ReminderInterest%rowtype;

    tbl_ReminderInterest Ttbl_ReminderInterest;

    --Màj du total interêt de ACT_REMINDER
    cursor csr_UpdateTotReminder(JobId number)
    is
      select   RIT.ACT_REMINDER_ID
             , ACS_FUNCTION.PCSROUND(sum(nvl(RIT.RIT_AMOUNT_INTEREST_RC, 0) )
                                   , min(cat.C_ROUND_TYPE)
                                   , min(cat.RCA_ROUND_AMOUNT)
                                    ) AMOUNT_RC
             , nvl(decode(min(RDET.ACS_INTEREST_CATEG_ID)
                        , null, min(CAT.RCA_MIN_INTEREST_AMOUNT)
                        , min(RDET.RDE_MIN_INTEREST_AMOUNT)
                         )
                 , 0
                  ) RDE_MIN_INTEREST_AMOUNT
          from PAC_REMAINDER_DETAIL RDET
             , PAC_REMAINDER_CATEGORY CAT
             , ACT_REMINDER_INTEREST RIT
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC
         where DOC.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and rem.PAC_REMAINDER_CATEGORY_ID = CAT.PAC_REMAINDER_CATEGORY_ID
           and RIT.ACT_REMINDER_ID = rem.ACT_REMINDER_ID
           and RDET.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RDET.PAC_REMAINDER_DETAIL_ID =
                                ACT_CLAIMS_MANAGEMENT.GetReminderDetailId(rem.PAC_REMAINDER_CATEGORY_ID, rem.REM_NUMBER)
      group by RIT.ACT_REMINDER_ID;

    RefDate              date;
    RefDateValue         date;
    RefDateTransaction   date;
    Amount               ACT_REMINDER_INTEREST.RIT_AMOUNT_LEFT_RC%type;
    Rate                 ACS_INTEREST_ELEM.IEL_APPLIED_RATE%type;
    lastReminderId       ACT_REMINDER.ACT_REMINDER_ID%type;
    Days                 integer;
    i                    integer;
    status               ACT_REMINDER.C_REM_STATUS_INTEREST%type;
  begin
    lastReminderId  := 0;

    for tpl_InitDetailsPay in csr_InitDetailsPay(aACT_JOB_ID) loop
      --insertion de l'historique du PO payé dans les détails
      if lastReminderId != tpl_InitDetailsPay.ACT_REMINDER_ID then
        GetInterestStartDates(tpl_InitDetailsPay.ACT_EXPIRY_ID
                            , tpl_InitDetailsPay.C_INTEREST_REF_DATE
                            , RefDateValue
                            , RefDateTransaction
                             );
        --RefDate := tpl_InitDetailsPay.EXP_ADAPTED + tpl_InitDetailsPay.RDE_INTEREST_WAITING_DAYS;  -- !!! tenir compte du descode date ref
        RefDateValue    := RefDateValue + tpl_InitDetailsPay.RDE_INTEREST_WAITING_DAYS;
        Amount          := tpl_InitDetailsPay.AMOUNT_RC;
        lastReminderId  := tpl_InitDetailsPay.ACT_REMINDER_ID;
      end if;

      -- Si date réf est plus grande que la date du paiement -> on ne tient pas compte de cette tranche
      if RefDateValue < tpl_InitDetailsPay.IMF_VALUE_DATE then
        insert into ACT_REMINDER_INTEREST
                    (ACT_REMINDER_INTEREST_ID
                   , ACT_REMINDER_ID
                   , RIT_VALUE_DATE
                   , RIT_TRANSACTION_DATE
                   , RIT_AMOUNT_LEFT_RC
                   , RIT_AMOUNT_INTEREST_RC
                   , RIT_INTEREST_RATE
                   , RIT_DAYS_NBR
                   , RIT_NBR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , tpl_InitDetailsPay.ACT_REMINDER_ID
                   , RefDateValue
                   , RefDateTransaction
                   , Amount
                   , null
                   , null
                   , tpl_InitDetailsPay.IMF_VALUE_DATE - RefDateValue
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        RefDateValue        := tpl_InitDetailsPay.IMF_VALUE_DATE;
        RefDateTransaction  := tpl_InitDetailsPay.IMF_TRANSACTION_DATE;
      end if;

      Amount          := Amount - tpl_InitDetailsPay.PAIED_RC;
      lastReminderId  := tpl_InitDetailsPay.ACT_REMINDER_ID;
    end loop;

    lastReminderId  := null;

    open csr_InitDetailsPO(aACT_JOB_ID);

    fetch csr_InitDetailsPO
     into tpl_InitDetailsPO;

    while csr_InitDetailsPO%found loop
      --insertion de l'historique du PO dans les détails
      if lastReminderId is null then
        GetInterestStartDates(tpl_InitDetailsPO.ACT_EXPIRY_ID
                            , tpl_InitDetailsPO.C_INTEREST_REF_DATE
                            , RefDateValue
                            , RefDateTransaction
                             );
        --RefDate := tpl_InitDetailsPO.EXP_ADAPTED + tpl_InitDetailsPO.RDE_INTEREST_WAITING_DAYS;  -- !!! tenir compte du descode date ref
        RefDateValue    := RefDateValue + tpl_InitDetailsPO.RDE_INTEREST_WAITING_DAYS;
        Amount          := tpl_InitDetailsPO.AMOUNT_RC;
        lastReminderId  := tpl_InitDetailsPO.ACT_REMINDER_ID;
      end if;

      --si on a des paiements -> insertion d'une ligne par paiement,
      --si pas de paiement ou que date réf plus grande que date du premier paiement-> l'insertion se fait plus loin
      if     tpl_InitDetailsPO.ACT_DET_PAYMENT_ID is not null
         and RefDateValue < tpl_InitDetailsPO.IMF_VALUE_DATE then
        insert into ACT_REMINDER_INTEREST
                    (ACT_REMINDER_INTEREST_ID
                   , ACT_REMINDER_ID
                   , RIT_VALUE_DATE
                   , RIT_TRANSACTION_DATE
                   , RIT_AMOUNT_LEFT_RC
                   , RIT_AMOUNT_INTEREST_RC
                   , RIT_INTEREST_RATE
                   , RIT_DAYS_NBR
                   , RIT_NBR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , tpl_InitDetailsPO.ACT_REMINDER_ID
                   , RefDateValue
                   , RefDateTransaction
                   , Amount
                   , null
                   , null
                   , tpl_InitDetailsPO.IMF_VALUE_DATE - RefDateValue
                   , null
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        RefDateValue        := tpl_InitDetailsPO.IMF_VALUE_DATE;
        RefDateTransaction  := tpl_InitDetailsPO.IMF_TRANSACTION_DATE;
        Amount              := Amount - tpl_InitDetailsPO.PAIED_RC;
        lastReminderId      := tpl_InitDetailsPO.ACT_REMINDER_ID;
      end if;

      fetch csr_InitDetailsPO
       into tpl_InitDetailsPO;

      --changement de PO ou dernier PO
      if    csr_InitDetailsPO%notfound
         or tpl_InitDetailsPO.ACT_REMINDER_ID != lastReminderId then
        -- Si date réf est plus grande que la date du paiement -> on ne tient pas compte de cette tranche
        if RefDateValue < aPAR_REMIND_DATE then
          insert into ACT_REMINDER_INTEREST
                      (ACT_REMINDER_INTEREST_ID
                     , ACT_REMINDER_ID
                     , RIT_VALUE_DATE
                     , RIT_TRANSACTION_DATE
                     , RIT_AMOUNT_LEFT_RC
                     , RIT_AMOUNT_INTEREST_RC
                     , RIT_INTEREST_RATE
                     , RIT_DAYS_NBR
                     , RIT_NBR
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (INIT_ID_SEQ.nextval
                     , lastReminderId
                     , RefDateValue
                     , RefDateTransaction
                     , Amount
                     , null
                     , null
                     , aPAR_REMIND_DATE - RefDateValue
                     , null
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;

        lastReminderId  := null;
      end if;
    end loop;

    close csr_InitDetailsPO;

    --ACT_REMINDER_INTEREST contient maintenant l'historique des paiements pour chaques échéances (une ligne par paiement).
    --Il faut maintenant splitter ces lignes en fonction des taux d'intêrets et calculer les montants de celles-ci.
    -- Chargement de la table des tranches actuelles
    open csr_ReminderInterest(aACT_JOB_ID);

    fetch csr_ReminderInterest
    bulk collect into tbl_ReminderInterest;

    close csr_ReminderInterest;

    i               := tbl_ReminderInterest.first;

    while i is not null loop
      -- chargement du premier taux de la tranche
      open csr_InterestRate(tbl_ReminderInterest(i).ACS_INTEREST_CATEG_ID
                          , tbl_ReminderInterest(i).RIT_VALUE_DATE
                          , tbl_ReminderInterest(i).RIT_VALUE_DATE + tbl_ReminderInterest(i).RIT_DAYS_NBR
                           );

      fetch csr_InterestRate
       into tpl_InterestRate;

      -- si il exite au moins un taux, on l'insere comme nouvelle tranche.
      while csr_InterestRate%found loop
        -- date réference (début) = soit date de début du premier taux, soit date de début de la tranche
        RefDate  := greatest(tpl_InterestRate.IEL_VALID_FROM, tbl_ReminderInterest(i).RIT_VALUE_DATE);
        Rate     := tpl_InterestRate.IEL_APPLIED_RATE;

        -- recherche du prochain taux
        fetch csr_InterestRate
         into tpl_InterestRate;

        if csr_InterestRate%found then
          -- si il reste encore des taux -> date prochain taux - date dernier taux
          Days  := tpl_InterestRate.IEL_VALID_FROM - RefDate;
        else
          -- si dernier taux -> date fin tranche - date dernier taux
          Days  := (tbl_ReminderInterest(i).RIT_VALUE_DATE + tbl_ReminderInterest(i).RIT_DAYS_NBR) - RefDate;
        end if;

        -- insertion d'une tranche pour le taux
        insert into ACT_REMINDER_INTEREST
                    (ACT_REMINDER_INTEREST_ID
                   , ACT_REMINDER_ID
                   , RIT_VALUE_DATE
                   , RIT_TRANSACTION_DATE
                   , RIT_AMOUNT_LEFT_RC
                   , RIT_AMOUNT_INTEREST_RC
                   , RIT_INTEREST_RATE
                   , RIT_DAYS_NBR
                   , RIT_NBR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , tbl_ReminderInterest(i).ACT_REMINDER_ID
                   , RefDate
                   , tbl_ReminderInterest(i).RIT_TRANSACTION_DATE +
                     (RefDate - tbl_ReminderInterest(i).RIT_VALUE_DATE
                     )   -- ??? Quelle méthode pour calculer la date transaction ???
                   , tbl_ReminderInterest(i).RIT_AMOUNT_LEFT_RC
                   , (Rate / 100) * tbl_ReminderInterest(i).RIT_AMOUNT_LEFT_RC / 360 * Days
                   , Rate
                   , Days
                   , tbl_ReminderInterest(i).RIT_AMOUNT_LEFT_RC * Days / 100
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end loop;

      close csr_InterestRate;

      --Effacement de la ligne à l'origine du split par taux
      delete from ACT_REMINDER_INTEREST
            where ACT_REMINDER_INTEREST_ID = tbl_ReminderInterest(i).ACT_REMINDER_INTEREST_ID;

      i  := tbl_ReminderInterest.next(i);
    end loop;

    --Màj de la table des relances avec le total des intêrets
    for tpl_UpdateTotReminder in csr_UpdateTotReminder(aACT_JOB_ID) loop
      --Contrôle si montant > montant minimum et màj du satus en fonction
      --??? Prendre la valeur absolue pour les intérêts négatif ???
      if abs(tpl_UpdateTotReminder.AMOUNT_RC) >= abs(tpl_UpdateTotReminder.RDE_MIN_INTEREST_AMOUNT) then
        status  := '2';
      else
        status  := '1';
      end if;

      update ACT_REMINDER
         set REM_INTEREST_AMOUNT_RC = tpl_UpdateTotReminder.AMOUNT_RC
           , C_REM_STATUS_INTEREST = status
       where ACT_REMINDER_ID = tpl_UpdateTotReminder.ACT_REMINDER_ID;
    end loop;

    --Màj imputations partenaire
    UpdatePartImputationInterest(aACT_JOB_ID);
  end CalcInterest;

---------------------
  procedure CalcPartImputationChargeAmount(
    aACT_PART_IMPUTATION_ID in     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aPAR_CHARGE_LC          in out ACT_PART_IMPUTATION.PAR_CHARGES_LC%type
  , aPAR_CHARGE_FC          in out ACT_PART_IMPUTATION.PAR_CHARGES_FC%type
  )
  is
    amountRC            ACT_REMINDER.REM_CHARGE_AMOUNT_RC%type;
    ReminderCategCharge PAC_REMAINDER_CATEGORY.C_REMAINDER_CHARGE_TYPE%type;
    ChargeRC            PAC_REMAINDER_CATEGORY.RCA_CHARGE_RC%type;
    RemFinCurrIdLC      ACT_REMINDER.REM_CHARGE_AMOUNT_RC%type;
    RemFinCurrIdFC      ACT_REMINDER.REM_CHARGE_AMOUNT_RC%type;
  begin
    --Recherche du type de frais
    begin
      select   nvl(min(RCAT.C_REMAINDER_CHARGE_TYPE), '0')
             , nvl(min(RCAT.RCA_CHARGE_RC), 0)
             , min(PART.ACS_ACS_FINANCIAL_CURRENCY_ID)
             , min(PART.ACS_FINANCIAL_CURRENCY_ID)
          into ReminderCategCharge
             , ChargeRC
             , RemFinCurrIdLC
             , RemFinCurrIdFC
          from PAC_REMAINDER_CATEGORY RCAT
             , ACT_PART_IMPUTATION PART
             , ACT_REMINDER rem
         where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and PART.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
           and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and rem.C_REM_STATUS_CHARGE = '2'
      group by rem.PAC_REMAINDER_CATEGORY_ID;
    exception
      when no_data_found then
        ReminderCategCharge  := '0';
        ChargeRC             := 1;
    end;

    if ReminderCategCharge = '1' then
      --Total frais
      select sum(nvl(rem.REM_CHARGE_AMOUNT_RC, 0) )
        into amountRC
        from PAC_REMAINDER_CATEGORY RCAT
           , ACT_REMINDER rem
       where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
         and rem.C_REM_STATUS_CHARGE = '2';
    elsif ReminderCategCharge = '2' then
      --Total frais par niveau
      select sum(REM_CHARGE_AMOUNT_RC)
        into amountRC
        from (select   ACT_PART_IMPUTATION_ID
                     , max(nvl(rem.REM_CHARGE_AMOUNT_RC, 0) ) REM_CHARGE_AMOUNT_RC
                  from ACT_REMINDER rem
                 where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
                   and rem.C_REM_STATUS_CHARGE = '2'
              group by ACT_PART_IMPUTATION_ID
                     , REM_NUMBER);
    elsif    ReminderCategCharge = '3'
          or ReminderCategCharge = '4' then
      --Frais du niveau le plus haut/bas
      select decode(ReminderCategCharge
                  , '3', min(nvl(REM1.REM_CHARGE_AMOUNT_RC, 0) )
                  , max(nvl(REM2.REM_CHARGE_AMOUNT_RC, 0) )
                   )
        into amountRC
        from ACT_REMINDER REM1
           , ACT_REMINDER REM2
           , (select min(rem.REM_NUMBER) MIN_REM_NUMBER
                   , max(rem.REM_NUMBER) MAX_REM_NUMBER
                from ACT_REMINDER rem
               where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID) MINMAXREM
       where REM1.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and REM2.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and REM1.C_REM_STATUS_CHARGE = '2'
         and REM2.C_REM_STATUS_CHARGE = '2'
         and MINMAXREM.MIN_REM_NUMBER = REM1.REM_NUMBER
         and MINMAXREM.MAX_REM_NUMBER = REM2.REM_NUMBER;
    end if;

    aPAR_CHARGE_LC  := null;
    aPAR_CHARGE_FC  := null;

    if    ChargeRC = 0
       or (    ChargeRC = 1
           and RemFinCurrIdLC = RemFinCurrIdFC) then
      aPAR_CHARGE_LC  := amountRC;
    /* Pas de màj
    if RemFinCurrIdLC != RemFinCurrIdFC then
      aPAR_CHARGE_FC := ACS_FUNCTION.ConvertAmountForView(aPAR_CHARGE_LC, RemFinCurrIdLC, RemFinCurrIdFC, nvl(aPAR_REMIND_DATE, SysDate), null, null, 1);
    else
      aPAR_CHARGE_FC := 0;
    end if;
    */
    else
      aPAR_CHARGE_FC  := amountRC;
    --aPAR_CHARGE_LC := ACS_FUNCTION.ConvertAmountForView(aPAR_CHARGE_FC, RemFinCurrIdFC, RemFinCurrIdLC, nvl(aPAR_REMIND_DATE, SysDate), null, null, 1);
    end if;
  end CalcPartImputationChargeAmount;

  procedure UpdatePartImputationCharge(
    aACT_JOB_ID             ACT_JOB.ACT_JOB_ID%type
  , aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type default null
  )
  is
    ChargeLC ACT_PART_IMPUTATION.PAR_CHARGES_LC%type;
    ChargeFC ACT_PART_IMPUTATION.PAR_CHARGES_FC%type;
  begin
    --Remise à null des montants avant màj
    if aACT_PART_IMPUTATION_ID is not null then
      update ACT_PART_IMPUTATION PART
         set PAR_CHARGES_LC = null
           , PAR_CHARGES_FC = null
       where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;
    elsif aACT_JOB_ID is not null then
      update ACT_PART_IMPUTATION PART
         set PAR_CHARGES_LC = null
           , PAR_CHARGES_FC = null
       where PART.ACT_DOCUMENT_ID in(select ACT_DOCUMENT_ID
                                       from ACT_DOCUMENT DOC
                                      where (   DOC.ACT_JOB_ID = aACT_JOB_ID
                                             or aACT_JOB_ID is null) );
    end if;

    for tpl_PartImputation in (select PAR.ACT_PART_IMPUTATION_ID
                                 from ACT_PART_IMPUTATION PAR
                                    , ACT_REMINDER rem
                                    , ACT_DOCUMENT DOC
                                where (   PAR.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
                                       or aACT_PART_IMPUTATION_ID is null
                                      )
                                  and (   DOC.ACT_JOB_ID = aACT_JOB_ID
                                       or aACT_JOB_ID is null)
                                  and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                  and rem.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                  and rem.C_REM_STATUS_CHARGE = '2') loop
      --Calcule des montants frais
      CalcPartImputationChargeAmount(tpl_PartImputation.ACT_PART_IMPUTATION_ID, ChargeLC, ChargeFC);

      --Màj imputation parttenaire
      update ACT_PART_IMPUTATION
         set PAR_CHARGES_LC = ChargeLC
           , PAR_CHARGES_FC = ChargeFC
       where ACT_PART_IMPUTATION_ID = tpl_PartImputation.ACT_PART_IMPUTATION_ID;

      --Màj si nécessaire du montant document et échéances
      UpdateDocChargeAndInterest(tpl_PartImputation.ACT_PART_IMPUTATION_ID, true, false);
    end loop;
  end UpdatePartImputationCharge;

  procedure CalcCharge(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type)
  is
    --curseur sur les relances et leur frais respectif
    cursor csr_ReminderDetails(JobId number)
    is
      select   rem.ACT_REMINDER_ID
             , max(CHA.RCH_AMOUNT) RCH_AMOUNT
             , max(RCAT.ACS_TAX_CODE_ID) ACS_TAX_CODE_ID
          from PAC_REMAINDER_CHARGE CHA
             , PAC_REMAINDER_DETAIL RDET
             , PAC_REMAINDER_CATEGORY RCAT
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC1
         where DOC1.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC1.ACT_DOCUMENT_ID
           and RCAT.PAC_REMAINDER_CATEGORY_ID = rem.PAC_REMAINDER_CATEGORY_ID
           and RDET.PAC_REMAINDER_DETAIL_ID =
                                ACT_CLAIMS_MANAGEMENT.GetReminderDetailId(rem.PAC_REMAINDER_CATEGORY_ID, rem.REM_NUMBER)
           and CHA.PAC_REMAINDER_DETAIL_ID = RDET.PAC_REMAINDER_DETAIL_ID
           and CHA.ACS_FINANCIAL_CURRENCY_ID =
                 decode(nvl(RCAT.RCA_INTEREST_RC, 0)
                      , 0, rem.ACS_ACS_FINANCIAL_CURRENCY_ID
                      , rem.ACS_FINANCIAL_CURRENCY_ID
                       )
           and ACT_CLAIMS_MANAGEMENT.IsInterestOrChargeDisabled(rem.ACT_REMINDER_ID, 0) = 0
           and rem.REM_STATUS = 0
      group by rem.ACT_REMINDER_ID;

    type Ttbl_ReminderDetails is table of csr_ReminderDetails%rowtype;

    tbl_ReminderDetails Ttbl_ReminderDetails;
  begin
    --Chargement de la table des relance em mémoire
    open csr_ReminderDetails(aACT_JOB_ID);

    fetch csr_ReminderDetails
    bulk collect into tbl_ReminderDetails;

    close csr_ReminderDetails;

    --Màj des frais avec le plus grand montant de frais pour la monnaie et le détail de relance
    if tbl_ReminderDetails.count > 0 then
      for inds in tbl_ReminderDetails.first .. tbl_ReminderDetails.last loop
        update ACT_REMINDER
           set REM_CHARGE_AMOUNT_RC = tbl_ReminderDetails(inds).RCH_AMOUNT
             , C_REM_STATUS_CHARGE = '2'
             , ACS_TAX_CODE_ID = tbl_ReminderDetails(inds).ACS_TAX_CODE_ID
         where ACT_REMINDER_ID = tbl_ReminderDetails(inds).ACT_REMINDER_ID;
      end loop;
    end if;

    --Màj imputations partenaire
    UpdatePartImputationCharge(aACT_JOB_ID);
  end CalcCharge;

  procedure UpdateReminderDocAmount(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
  is
    vCharge    boolean;
    vInterest  boolean;
    vAmountLC  ACT_EXPIRY.EXP_AMOUNT_LC%type;
    vAmountFC  ACT_EXPIRY.EXP_AMOUNT_FC%type;
    vAmountEUR ACT_EXPIRY.EXP_AMOUNT_EUR%type;
  begin
    UpdatePartImputationInterest(null, aACT_PART_IMPUTATION_ID);
    UpdatePartImputationCharge(null, aACT_PART_IMPUTATION_ID);
    CleanUpReminderInterest(aACT_PART_IMPUTATION_ID);
    UpdateDocumentChargeOrInterest(aACT_PART_IMPUTATION_ID, vCharge, vInterest);
    CalcDocAmounts(aACT_PART_IMPUTATION_ID, vAmountLC, vAmountFC, vAmountEUR, vCharge, vInterest);
    --Màj montant document et échéance
    UpdateDocAmounts(aACT_PART_IMPUTATION_ID, vAmountLC, vAmountFC, vAmountEUR, null, true);
  end UpdateReminderDocAmount;

  procedure LoadReminderExpCharges(aACT_JOB_ID ACT_JOB.ACT_JOB_ID%type)
  is
    cursor csr_Reminder(JobId number)
    is
      select   DOC.ACT_JOB_ID
             , par.PAC_SUPPLIER_PARTNER_ID
             , par.PAC_CUSTOM_PARTNER_ID
             , PAR2.PAR_DOCUMENT
             , rem.*
          from ACT_PART_IMPUTATION PAR2
             , ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
             , ACT_REMINDER rem
             , ACT_DOCUMENT DOC
         where DOC.ACT_JOB_ID = JobId
           and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and par.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = rem.ACT_EXPIRY_ID
           and PAR2.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and (    (    rem.C_REM_STATUS_CHARGE = '2'
                     and nvl(rem.REM_CHARGE_AMOUNT_RC, 0) != 0)
                or (    rem.C_REM_STATUS_INTEREST = '2'
                    and nvl(rem.REM_INTEREST_AMOUNT_RC, 0) != 0)
               )
      order by rem.ACT_DOCUMENT_ID
             , rem.ACT_REMINDER_ID;
  begin
    for tpl_Reminder in csr_Reminder(aACT_JOB_ID) loop
      --Chargement de la table
      insert into ACT_REMINDER_EXP_CHARGES
                  (ACT_REMINDER_EXP_CHARGES_ID
                 , ACT_JOB_ID
                 , ACT_DOCUMENT_ID
                 , ACT_EXPIRY_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_CUSTOM_PARTNER_ID
                 , ACT_REMINDER_ID
                 , PAC_REMAINDER_CATEGORY_ID
                 , ACS_TAX_CODE_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , ACS_ACS_FINANCIAL_CURRENCY_ID
                 , REM_NUMBER
                 , REM_CHARGE_AMOUNT_RC
                 , REM_INTEREST_AMOUNT_RC
                 , C_REM_EXP_CHARGES_STATUS
                 , PAR_DOCUMENT
                  )
           values (INIT_ID_SEQ.nextval
                 , tpl_Reminder.ACT_JOB_ID
                 , tpl_Reminder.ACT_DOCUMENT_ID
                 , tpl_Reminder.ACT_EXPIRY_ID
                 , tpl_Reminder.PAC_SUPPLIER_PARTNER_ID
                 , tpl_Reminder.PAC_CUSTOM_PARTNER_ID
                 , tpl_Reminder.ACT_REMINDER_ID
                 , tpl_Reminder.PAC_REMAINDER_CATEGORY_ID
                 , tpl_Reminder.ACS_TAX_CODE_ID
                 , tpl_Reminder.ACS_FINANCIAL_CURRENCY_ID
                 , tpl_Reminder.ACS_ACS_FINANCIAL_CURRENCY_ID
                 , tpl_Reminder.REM_NUMBER
                 , decode(tpl_Reminder.C_REM_STATUS_CHARGE, '2', tpl_Reminder.REM_CHARGE_AMOUNT_RC, 0)
                 , decode(tpl_Reminder.C_REM_STATUS_INTEREST, '2', tpl_Reminder.REM_INTEREST_AMOUNT_RC, 0)
                 , '0'
                 , tpl_Reminder.PAR_DOCUMENT
                  );

      --Màj statut relance à '3'
      update ACT_REMINDER
         set C_REM_STATUS_CHARGE = decode(C_REM_STATUS_CHARGE, '2', '3', C_REM_STATUS_CHARGE)
           , C_REM_STATUS_INTEREST = decode(C_REM_STATUS_INTEREST, '2', '3', C_REM_STATUS_INTEREST)
       where ACT_REMINDER_ID = tpl_Reminder.ACT_REMINDER_ID;
    end loop;
  end LoadReminderExpCharges;

  procedure CleanUpReminderInterest(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
  is
  begin
    -- Effacement des détails intérets pour les relances avec C_REM_STATUS_INTEREST = '0' (sans)
    delete from ACT_REMINDER_INTEREST
          where ACT_REMINDER_ID in(
                  select rem.ACT_REMINDER_ID
                    from ACT_REMINDER rem
                   where rem.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
                     and nvl(rem.C_REM_STATUS_INTEREST, '0') = '0');
  end CleanUpReminderInterest;
end ACT_CLAIMS_MANAGEMENT;
