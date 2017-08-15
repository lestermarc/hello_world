--------------------------------------------------------
--  DDL for Package Body ACT_INTEREST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_INTEREST" 
is
-----------------------------------------------------------------------------------------------------------------------
  procedure CreateInterestDocument(
    pJobId       ACT_JOB.ACT_JOB_ID%type
  , pDocDate     ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  , pTranDate    ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , pValueDate   ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , pRoundType   ACS_INT_CALC_METHOD.C_ROUND_TYPE%type
  , pRoundAmount ACS_INT_CALC_METHOD.ICM_ROUND_AMOUNT%type
  , pLabel_D     ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type
  , pLabel_C     ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type
  )
  is
    /*D�tail int�r�t du travail regroup� par compte financier /division /taux*/
    cursor InterestDetailCursor(pJobId ACT_JOB.ACT_JOB_ID%type)
    is
      select   sum(IDE_NBR_D) IDE_NBR_D
             , sum(IDE_NBR_C) IDE_NBR_C
             , max(IDE_VALUE_DATE) IDE_VALUE_DATE
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , IDE_INTEREST_RATE_D
             , IDE_INTEREST_RATE_C
          from ACT_INTEREST_DETAIL
         where ACT_JOB_ID = pJobId
      group by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , IDE_INTEREST_RATE_D
             , IDE_INTEREST_RATE_C
      order by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , nvl(ACS_FINANCIAL_CURRENCY_ID, 0)
             , IDE_INTEREST_RATE_D
             , IDE_INTEREST_RATE_C;

    vInterestDetail InterestdetailCursor%rowtype;   --R�ceptionne les enregistrements du curseur
    vIntCategory    ACS_METHOD_ELEM.ACS_INTEREST_CATEG_ID%type;
    vCalcMethodId   ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type;   --M�thode de calcul des int�r�ts
    vDocGeneration  ACS_INT_CALC_METHOD.C_INT_DOC_GENERATION%type;   --Code de g�n�ration de document de la m�thode
    vIntAccId       ACS_INT_CALC_METHOD.ACS_INTEREST_ACC_ID%type;   --Compte d'imputation int�r�t
    vIntAccId_D     ACS_INT_CALC_METHOD.ACS_ASSETS_INT_ACC_ID%type;   --Compte d'imputation int�r�t actif
    vIntAccId_C     ACS_INT_CALC_METHOD.ACS_LIABIL_INT_ACC_ID%type;   --Compte d'imputation int�r�t passif
    vIntAccId_T     ACS_INT_CALC_METHOD.ACS_ADV_TAX_ACC_ID%type;   --Compte d'imputation imp�t anticip�
    vDocCatId       ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID%type;   --Catalogue document
    vFinYearId      ACT_JOB.ACS_FINANCIAL_YEAR_ID%type;   --Ann�e comptable du travail
    vblnAdvTax      number(1);   --Indique gestion imp�t anticip�
    vPrevFinAccId   ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;   --Compte financier du pr�c�dent d�tail
    vPrevDivAccId   ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;   --Compte division du pr�c�dent d�tail
    vPrevFinCurId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --Monnaie comptable du pr�c�dent d�tail
    vCurrFinAccId   ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;   --Compte financier courant
    vCurrDivAccId   ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;   --Compte division courant
    vCurrFinCurId   ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;   --Monnaie comptable courant
    vDocumentId     ACT_DOCUMENT.ACT_DOCUMENT_ID%type;   --Id document cr��
    vIntNetAmount   ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type;   --Montant int�r�t net
    vTaxRate        ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type;   --taux d'imp�t anticip�
    vIntAmount_D    ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type;   --Montant d'int�r�t actif
    vIntAmount_C    ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_C%type;   --Montant d'int�r�t passif
    vIntTotAmount_D ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type;   --Montant total d'int�r�t actif
    vIntTotAmount_C ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_C%type;   --Montant total d'int�r�t passif
    vPrimary        number(1);   --Imputation primaire
    vLabel_D        ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type;
    vLabel_C        ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type;
  begin
    --Recherche des comptes d'imputation sur la m�thode de calcul
    select nvl(MET.ACS_INT_CALC_METHOD_ID, 0)
         , nvl(MET.C_INT_DOC_GENERATION, 0)
         , nvl(MET.ACS_INTEREST_ACC_ID, 0)
         , nvl(MET.ACS_ASSETS_INT_ACC_ID, 0)
         , nvl(MET.ACS_LIABIL_INT_ACC_ID, 0)
         , nvl(MET.ACS_ADV_TAX_ACC_ID, 0)
      into vCalcMethodId
         , vDocGeneration
         , vIntAccId
         , vIntAccId_D
         , vIntAccId_C
         , vIntAccId_T
      from ACS_INT_CALC_METHOD MET
     where exists(select 1
                    from ACT_CALC_PERIOD PER
                   where PER.ACT_JOB_ID = pJobId
                     and MET.ACS_INT_CALC_METHOD_ID = PER.ACS_INT_CALC_METHOD_ID);

    --Recherche type de document --> premier type valable
    select CAT.ACJ_CATALOGUE_DOCUMENT_ID
         , JOB.ACS_FINANCIAL_YEAR_ID
      into vDocCatId
         , vFinYearId
      from ACJ_JOB_TYPE_S_CATALOGUE CAT
         , ACT_JOB JOB
     where JOB.ACT_JOB_ID = pJobId
       and CAT.ACJ_JOB_TYPE_ID = JOB.ACJ_JOB_TYPE_ID
       and CAT.JCA_AVAILABLE = 1
       and rownum = 1;

    /*Cr�ation des journaux du travail*/
    CreateJobJournal(pJobId, vDocCatId, vFinYearId);
    /*Parcours des position d�tails int�r�t*/
    vPrevFinAccId  := 0;
    vPrevDivAccId  := 0;
    vPrevFinCurId  := 0;
    vIntNetAmount  := 0;

    open InterestDetailCursor(pJobId);

    fetch InterestDetailCursor
     into vInterestDetail;

    while InterestDetailCursor%found loop
      --Cr�ation d'un nouveau document
      --  Lors du premier passage
      --  Lors du changement du couple financier /division si le code de g�n�ration est un document par couple financier/division (0)
      vCurrFinAccId    := nvl(vInterestDetail.ACS_FINANCIAL_ACCOUNT_ID, 0);
      vCurrDivAccId    := nvl(vInterestDetail.ACS_DIVISION_ACCOUNT_ID, 0);
      vCurrFinCurId    := nvl(vInterestDetail.ACS_FINANCIAL_CURRENCY_ID, 0);

      if    (vPrevFinAccId <> vCurrFinAccId)
         or (vPrevDivAccId <> vCurrDivAccId)
         or (vPrevFinCurId <> vCurrFinCurId) then
        vIntNetAmount    :=(vIntTotAmount_C - vIntTotAmount_D);

        if     (vIntNetAmount is not null)
           and (vIntNetAmount > 0)
           and (vblnAdvTax = 1) then
          vLabel_D  :=
            PCS.PC_FUNCTIONS.TRANSLATEWORD('Imp�t anticip�') ||
            ' ' ||
            to_char(vTaxRate, 'fm999999990D00999') ||
            ' %  /  ' ||
            to_char(vIntNetAmount, 'fm' || lpad('D0099', length(vIntNetAmount) + 5, '9') );
          vLabel_C  :=
            PCS.PC_FUNCTIONS.TRANSLATEWORD('Imp�t anticip�') ||
            ' ' ||
            to_char(vTaxRate, 'fm999999990D00999') ||
            ' %  /  ' ||
            to_char(vIntNetAmount, 'fm' || lpad('D0099', length(vIntNetAmount) + 5, '9') );
          CreateImputation(vDocumentId   --Document courant
                         , vDocCatId   --Catalogue document
                         , pTranDate   --Date de transaction
                         , pValueDate   --Date valeur
                         , vPrevFinAccId   --Compte financier d�tail int�r�t
                         , vPrevDivAccId   --Compte division d�tail int�r�t
                         , case
                             when vPrevFinCurId = 0 then null
                             else vPrevFinCurId   -- Monnaie comptable d�tail int�r�t
                           end
                         , vblnAdvTax   --Gestion imp�t anticip�
                         , vIntAccId   --Compte d'imputation int�r�t
                         , vIntAccId_D   --Compte d'imputation int�r�t actif
                         , vIntAccId_C   --Compte d'imputation int�r�t passif
                         , vIntAccId_T   --Compte d'imputation imp�t anticip�
                         , vIntAmount_D   --Montant int�r�t d�bit
                         , vIntAmount_C   --Montant int�r�t cr�dit
                         , vIntNetAmount   --Montant int�r�t net
                         , vTaxRate   --Taux imp�t
                         , 1   --Imputation imp�t anticip�
                         , vPrimary
                         , vLabel_D
                         , vLabel_C
                          );
        end if;

        vIntTotAmount_D  := 0;
        vIntTotAmount_C  := 0;

        if    (     (vDocGeneration = 0)
               and (    (vPrevDivAccId <> vCurrDivAccId)
                    or (vPrevFinAccId <> vCurrFinAccId) )
              )   --G�n�ration 0 -> un doc /compte / division ET changement de division
           or (     (vDocGeneration = 1)
               and (vPrevFinAccId <> vCurrFinAccId)
              )   --G�n�ration 1 -> un doc / compte ET changement de compte fin                          --
           or (vDocumentId is null) then   --Premier passage ...Document n'est pas encore cr��
          if not vDocumentId is null then
            UpdateDocAmount(vDocumentId);
            --Mise � jour des cumuls
            ACT_DOC_TRANSACTION.DocImputations(vDocumentId, 0);
          end if;

          vDocumentId    :=
            CreateInterestDocHeader(pJobId
                                  , vDocCatId
                                  , vFinYearId
                                  , case
                                      when vCurrFinCurId = 0 then null
                                      else vCurrFinCurId
                                    end
                                  , pDocDate
                                   );
          vIntNetAmount  := 0;
          vPrimary       := 1;
        end if;

        vPrevFinAccId    := vCurrFinAccId;
        vPrevDivAccId    := vCurrDivAccId;
        vPrevFinCurId    := vCurrFinCurId;
        --Recherche des comptes d'imputation sur les �l�ments de calcul pour le couple financier/division
        --les comptes d'imputation de la m�thode calcul�s + haut seront remplac�s par ceux des �l�ments
        --si ceux-ci sont initialis�s
        GetElementDefaultAccount(vCalcMethodId
                               , vCurrFinAccId
                               , vCurrDivAccId
                               , case
                                   when vCurrFinCurId = 0 then null
                                   else vCurrFinCurId
                                 end
                               , vIntAccId
                               , vIntAccId_D
                               , vIntAccId_C
                               , vIntAccId_T
                               , vIntCategory
                                );
        vTaxRate         := GetAdvTaxRate(vIntCategory, pValueDate);

        if vIntAccId_T <> -1 then
          vblnAdvTax  := 1;
        else
          vblnAdvTax  := 0;
        end if;
      end if;

      --Calcul des montants d'int�r�t
      vIntAmount_D     :=(vInterestDetail.IDE_NBR_D * vInterestDetail.IDE_INTEREST_RATE_D / 360);
      vIntAmount_C     :=(vInterestDetail.IDE_NBR_C * vInterestDetail.IDE_INTEREST_RATE_C / 360);

      --Arrondi selon valeurs saisies dans le travail
      if pRoundType = '1' then   -- Arrondi commercial
        vIntAmount_D  := ACS_FUNCTION.RoundNear(vIntAmount_D, 0.05, 0);
        vIntAmount_C  := ACS_FUNCTION.RoundNear(vIntAmount_C, 0.05, 0);
      elsif pRoundType = '2' then   -- Arrondi inf�rieur
        vIntAmount_D  := ACS_FUNCTION.RoundNear(vIntAmount_D, pRoundAmount, -1);
        vIntAmount_C  := ACS_FUNCTION.RoundNear(vIntAmount_C, pRoundAmount, -1);
      elsif pRoundType = '3' then   -- Arrondi au plus pr�s
        vIntAmount_D  := ACS_FUNCTION.RoundNear(vIntAmount_D, pRoundAmount, 0);
        vIntAmount_C  := ACS_FUNCTION.RoundNear(vIntAmount_C, pRoundAmount, 0);
      elsif pRoundType = '4' then   -- Arrondi sup�rieur
        vIntAmount_D  := ACS_FUNCTION.RoundNear(vIntAmount_D, pRoundAmount, 1);
        vIntAmount_C  := ACS_FUNCTION.RoundNear(vIntAmount_C, pRoundAmount, 1);
      end if;

      --Calcul du montant document (Somme des montants d�bits)
      vIntTotAmount_D  := vIntTotAmount_D + vIntAmount_D;
      vIntTotAmount_C  := vIntTotAmount_C + vIntAmount_C;
      vLabel_D         := pLabel_D || ' ' || to_char(vInterestDetail.IDE_INTEREST_RATE_D, 'fm999999990D00999') || '%';   --Libell� int�r�t actif
      vLabel_C         := pLabel_C || ' ' || to_char(vInterestDetail.IDE_INTEREST_RATE_C, 'fm999999990D00999') || '%';   --Libell� int�r�t passif

      if    (vIntAmount_D <> 0)
         or (vIntAmount_C <> 0) then   --Montant d'int�r�t existe....Cr�ation des imputations
        CreateImputation(vDocumentId   --Document courant
                       , vDocCatId   --Catalogue document
                       , pTranDate   --Date de transaction
                       , pValueDate   --Date valeur
                       , vCurrFinAccId   --Compte financier d�tail int�r�t
                       , vCurrDivAccId   --Compte division d�tail int�r�t
                       , case
                           when vCurrFinCurId = 0 then null
                           else vCurrFinCurId   -- Monnaie comptable d�tail int�r�t
                         end
                       , vblnAdvTax   --Gestion imp�t anticip�
                       , vIntAccId   --Compte d'imputation int�r�t
                       , vIntAccId_D   --Compte d'imputation int�r�t actif
                       , vIntAccId_C   --Compte d'imputation int�r�t passif
                       , vIntAccId_T   --Compte d'imputation imp�t anticip�
                       , vIntAmount_D   --Montant int�r�t d�bit
                       , vIntAmount_C   --Montant int�r�t cr�dit
                       , vIntNetAmount   --Montant int�r�t net
                       , vTaxRate   --Taux imp�t
                       , 0
                       , vPrimary
                       , vLabel_D
                       , vLabel_C
                        );
        vPrimary  := 0;
      end if;

      fetch InterestDetailCursor
       into vInterestDetail;
    end loop;

    vIntNetAmount  :=(vIntTotAmount_C - vIntTotAmount_D);

    if     (vIntNetAmount > 0)
       and (vblnAdvTax = 1) then
      vLabel_D  :=
        PCS.PC_FUNCTIONS.TRANSLATEWORD('Imp�t anticip�') ||
        ' ' ||
        to_char(vTaxRate, 'fm999999990D00999') ||
        ' %  /  ' ||
        to_char(vIntNetAmount, 'fm' || lpad('D0099', length(vIntNetAmount) + 5, '9') );
      vLabel_C  :=
        PCS.PC_FUNCTIONS.TRANSLATEWORD('Imp�t anticip�') ||
        ' ' ||
        to_char(vTaxRate, 'fm999999990D00999') ||
        ' %  /  ' ||
        to_char(vIntNetAmount, 'fm' || lpad('D0099', length(vIntNetAmount) + 5, '9') );
      CreateImputation(vDocumentId   --Document courant
                     , vDocCatId   --Catalogue document
                     , pTranDate   --Date de transaction
                     , pValueDate   --Date valeur
                     , vCurrFinAccId   --Compte financier d�tail int�r�t
                     , vCurrDivAccId   --Compte division d�tail int�r�t
                     , case
                         when vCurrFinCurId = 0 then null
                         else vCurrFinCurId   -- Monnaie comptable d�tail int�r�t
                       end
                     , vblnAdvTax   --Gestion imp�t anticip�
                     , vIntAccId   --Compte d'imputation int�r�t
                     , vIntAccId_D   --Compte d'imputation int�r�t actif
                     , vIntAccId_C   --Compte d'imputation int�r�t passif
                     , vIntAccId_T   --Compte d'imputation imp�t anticip�
                     , vIntAmount_D   --Montant int�r�t d�bit
                     , vIntAmount_C   --Montant int�r�t cr�dit
                     , vIntNetAmount   --Montant int�r�t net
                     , vTaxRate   --Taux imp�t
                     , 1   --Imputation imp�t anticip�
                     , vPrimary
                     , vLabel_D
                     , vLabel_C
                      );
    end if;

    --tenir compte des calcul de la derni�re position
    if not vDocumentId is null then
      UpdateDocAmount(vDocumentId);
      --Mise � jour des cumuls
      ACT_DOC_TRANSACTION.DocImputations(vDocumentId, 0);
    end if;
  end CreateInterestDocument;

-----------------------------------------------------------------------------------------------------------------------
  function CreateInterestDocHeader(
    pJobId     ACT_JOB.ACT_JOB_ID%type
  , pDocCatId  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFinCurId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pDocDate   ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  )
    return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  is
    cursor GetJournalCursor(pJobId ACT_JOB.ACT_JOB_ID%type, pTypeAcc ACS_ACCOUNTING.C_TYPE_ACCOUNTING%type)
    is
      select JOU1.ACT_JOURNAL_ID
        from ACT_JOURNAL JOU1
       where JOU1.ACT_JOB_ID = pJobId
         and exists(select 1
                      from ACS_ACCOUNTING ACS
                     where ACS.C_TYPE_ACCOUNTING = pTypeAcc
                       and JOU1.ACS_ACCOUNTING_ID = ACS.ACS_ACCOUNTING_ID);

    vNewId        ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;
    vDocNumber    ACT_DOCUMENT.DOC_NUMBER%type;
    vFinJournalId ACT_DOCUMENT.ACT_JOURNAL_ID%type;
    vAnaJournalId ACT_DOCUMENT.ACT_ACT_JOURNAL_ID%type;
  begin
    --R�ception nouvel Id
    select init_id_seq.nextval
      into vNewId
      from dual;

    --Recherche journal financier
    open GetJournalCursor(pJobId, 'FIN');

    fetch GetJournalCursor
     into vFinJournalId;

    close GetJournalCursor;

    --Recherche journal analytique
    open GetJournalCursor(pJobId, 'MAN');

    fetch GetJournalCursor
     into vAnaJournalId;

    close GetJournalCursor;

    ACT_FUNCTIONS.GetDocNumber(pDocCatId, pFinYearId, vDocNumber);

    insert into ACT_DOCUMENT
                (ACT_DOCUMENT_ID
               , ACT_JOB_ID   --Travail
               , ACT_JOURNAL_ID   --Journal financier
               , ACT_ACT_JOURNAL_ID   --Journal analytique
               , ACS_FINANCIAL_CURRENCY_ID   --Monnaie
               , ACS_FINANCIAL_YEAR_ID   --Ann�e
               , ACJ_CATALOGUE_DOCUMENT_ID   --Catalogue
               , DOC_DOCUMENT_DATE   --Date
               , DOC_NUMBER   --Num�ro
               , DOC_TOTAL_AMOUNT_DC   --Montant
               , DOC_TOTAL_AMOUNT_EUR
               , PC_USER_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (vNewId
               , pJobId
               , vFinJournalId
               , vAnaJournalId
               , nvl(pFinCurId, ACS_FUNCTION.GetLocalCurrencyID)
               , pFinYearId
               , pDocCatId
               , pDocDate
               , vDocNumber
               , 0
               , 0
               , PCS.PC_I_LIB_SESSION.GetuserId
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    insert into ACT_DOCUMENT_STATUS
                (ACT_DOCUMENT_STATUS_ID
               , ACT_DOCUMENT_ID
               , DOC_OK
                )
         values (init_id_seq.nextval
               , vNewId
               , 0
                );

    return vNewId;
  end CreateInterestDocHeader;

-----------------------------------------------------------------------------------------------------------------------
  procedure CreateJobJournal(
    pJobId     ACT_JOB.ACT_JOB_ID%type
  , pDocCatId  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
  is
    cursor JournalCursor(pDocCatId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
    is
      select decode(ACJ_SUB_SET_CAT.C_METHOD_CUMUL, 'DIR', 'PROV', 'BRO') C_ETAT_JOURNAL
           , ACJ_SUB_SET_CAT.C_SUB_SET
           , ACS_ACCOUNTING.C_TYPE_ACCOUNTING
           , ACS_ACCOUNTING.ACS_ACCOUNTING_ID
        from ACJ_SUB_SET_CAT
           , ACS_SUB_SET
           , ACS_ACCOUNTING
       where ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID = pDocCatId
         and ACS_SUB_SET.C_SUB_SET = ACJ_SUB_SET_CAT.C_SUB_SET
         and ACS_ACCOUNTING.ACS_ACCOUNTING_ID = ACS_SUB_SET.ACS_ACCOUNTING_ID;

    vJournal        JournalCursor%rowtype;   --R�ceptionne les donn�es du curseur
    vNewId          ACT_JOURNAL.ACT_JOURNAL_ID%type;
    vJournalId      ACT_JOURNAL.ACT_JOURNAL_ID%type;
    vJournalNum     ACT_JOURNAL.JOU_NUMBER%type;
    vJournalDesr    ACT_JOB.JOB_DESCRIPTION%type;
    vJournalStateId ACT_ETAT_JOURNAL.ACT_ETAT_JOURNAL_ID%type;
  begin
    open JournalCursor(pDocCatId);

    fetch JournalCursor
     into vJournal;

    while JournalCursor%found loop
      --D�termine existence du sous-ensemble CPN dans le catalogue
      if     (Analytical = 0)
         and (vJournal.C_SUB_SET = 'CPN') then
        Analytical  := 1;
      end if;

      --R�ception journal selon type de comptabilit� du travail courant
      select nvl(max(ACT_JOURNAL_ID), 0)
        into vJournalId
        from ACT_JOURNAL
       where ACT_JOB_ID = pJobId
         and ACS_ACCOUNTING_ID = vJournal.ACS_ACCOUNTING_ID;

      --Le journal n'existe pas --> cr�ation
      if vJournalId = 0 then
        select nvl(max(JOU_NUMBER), 0)
          into vJournalNum
          from ACT_JOURNAL
         where ACS_FINANCIAL_YEAR_ID = pFinYearId
           and ACS_ACCOUNTING_ID = vJournal.ACS_ACCOUNTING_ID;

        --R�ception description du travail
        select JOB_DESCRIPTION
          into vJournalDesr
          from ACT_JOB
         where ACT_JOB_ID = pJobId;

        --R�ception nouvel Id
        select init_id_seq.nextval
          into vJournalId
          from dual;

        insert into ACT_JOURNAL
                    (ACT_JOURNAL_ID
                   , ACT_JOB_ID
                   , C_TYPE_JOURNAL
                   , ACS_ACCOUNTING_ID
                   , JOU_DESCRIPTION
                   , JOU_NUMBER
                   , PC_USER_ID
                   , ACS_FINANCIAL_YEAR_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vJournalId
                   , pJobId
                   , 'MAN'
                   , vJournal.ACS_ACCOUNTING_ID
                   , vJournalDesr
                   , vJournalNum + 1
                   , PCS.PC_I_LIB_SESSION.GetUserId
                   , pFinYearId
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;

      --R�ception  de l'�tat du journal du type de comptabilit� courant
      select nvl(max(ACT_ETAT_JOURNAL_ID), 0)
        into vJournalStateId
        from ACT_ETAT_JOURNAL
       where ACT_JOURNAL_ID = vJournalId
         and C_SUB_SET = vJournal.C_SUB_SET;

      --Pas d'�tat --> Cr�ation
      if vJournalStateId = 0 then
        --R�ception nouvel Id
        select init_id_seq.nextval
          into vJournalStateId
          from dual;

        insert into ACT_ETAT_JOURNAL
                    (ACT_ETAT_JOURNAL_ID
                   , ACT_JOURNAL_ID
                   , C_SUB_SET
                   , A_DATECRE
                   , A_IDCRE
                   , C_ETAT_JOURNAL
                    )
             values (vJournalStateId
                   , vJournalId
                   , vJournal.C_SUB_SET
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , vJournal.C_ETAT_JOURNAL
                    );
      end if;

      fetch JournalCursor
       into vJournal;
    end loop;
  end CreateJobJournal;

-----------------------------------------------------------------------------------------------------------------------
  procedure CreateImputation(
    pDocumentId    ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , pDocCatId      ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pTranDate      ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , pValueDate     ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , pFinAccId      ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId      ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pAdvTax        number
  , pIntAccId      ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , pIntAccId_D    ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , pIntAccId_C    ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , pIntAccId_T    ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
  , pAmount_D      ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type
  , pAmount_C      ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_C%type
  , pIntNetAmount  ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type
  , pTaxRate       ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type
  , pTaxImputation number
  , pPrimary       number
  , pLabel_D       ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type
  , pLabel_C       ACS_INT_CALC_METHOD.ICM_LIABIL_INT_LBL%type
  )
  is
    --Curseur de recherch sur le document courant
    cursor DocumentCursor(pDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select DOC.*
        from ACT_DOCUMENT DOC
       where ACT_DOCUMENT_ID = pDocumentId;

    vDocument     DocumentCursor%rowtype;   --R�ceptionne les enregistrements du curseur des documents
    vFinAccId     ACS_ACCOUNT.ACS_ACCOUNT_ID%type;   --Compte financier de l'imputation
    vDivAccId     ACS_ACCOUNT.ACS_ACCOUNT_ID%type;   --Compte division de l'imputation
    vDefFinAcc    ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type;   --Variables de r�ception des donn�es des comptes / d�faut
    vDefDivAcc    ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type;
    vDefCpnAcc    ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type;
    vDefCdaAcc    ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type;
    vDefPfAcc     ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type;
    vDefPjAcc     ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type;
    vDefQtyAcc    ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type;
    vDefHrmPerson ACS_DEF_ACCOUNT_VALUES.DEF_HRM_PERSON%type;
    vDefNum1      ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER1%type;
    vDefNum2      ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER2%type;
    vDefNum3      ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER3%type;
    vDefNum4      ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER4%type;
    vDefNum5      ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER5%type;
    vDefText1     ACS_DEF_ACCOUNT_VALUES.DEF_TEXT1%type;
    vDefText2     ACS_DEF_ACCOUNT_VALUES.DEF_TEXT2%type;
    vDefText3     ACS_DEF_ACCOUNT_VALUES.DEF_TEXT3%type;
    vDefText4     ACS_DEF_ACCOUNT_VALUES.DEF_TEXT4%type;
    vDefText5     ACS_DEF_ACCOUNT_VALUES.DEF_TEXT5%type;
    vDefDicFree1  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE1%type;
    vDefDicFree2  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE2%type;
    vDefDicFree3  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE3%type;
    vDefDicFree4  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE4%type;
    vDefDicFree5  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE5%type;
    vDefDate1     ACS_DEF_ACCOUNT_VALUES.DEF_DATE1%type;
    vDefDate2     ACS_DEF_ACCOUNT_VALUES.DEF_DATE2%type;
    vDefDate3     ACS_DEF_ACCOUNT_VALUES.DEF_DATE3%type;
    vDefDate4     ACS_DEF_ACCOUNT_VALUES.DEF_DATE4%type;
    vDefDate5     ACS_DEF_ACCOUNT_VALUES.DEF_DATE5%type;
    vPeriodId     ACS_PERIOD.ACS_PERIOD_ID%type;

    procedure InsertImputation(
      pFinCurId ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
    , pAmountD  ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type
    , pAmountC  ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_C%type
    , pPrimary  number
    )
    is
      cursor InteractionCdaAccCursor(
        pDefCdaAcc ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
      , pCpnAccId  ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
      , pRefDate   ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
      )
      is
        select   nvl(ACS_FUNCTION.GetCDAAccountId(pDefCdaAcc), ACS_CDA_ACCOUNT_ID)
            from ACS_MGM_INTERACTION
           where ACS_CPN_ACCOUNT_ID = pCpnAccId
             and (    (    MGM_VALID_SINCE is null
                       and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE <= pRefDate
                      and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE is null
                      and MGM_VALID_TO >= pRefDate)
                  or (pRefDate between MGM_VALID_SINCE and MGM_VALID_TO)
                 )
        order by MGM_DEFAULT;

      cursor InteractionPfAccCursor(
        pDefPfAcc ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
      , pCpnAccId ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
      , pRefDate  ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
      )
      is
        select   nvl(ACS_FUNCTION.GetPfAccountId(pDefPfAcc), ACS_PF_ACCOUNT_ID)
            from ACS_MGM_INTERACTION
           where ACS_CPN_ACCOUNT_ID = pCpnAccId
             and (    (    MGM_VALID_SINCE is null
                       and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE <= pRefDate
                      and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE is null
                      and MGM_VALID_TO >= pRefDate)
                  or (pRefDate between MGM_VALID_SINCE and MGM_VALID_TO)
                 )
        order by MGM_DEFAULT;

      cursor InteractionPjAccCursor(
        pDefPjAcc ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
      , pCpnAccId ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
      , pRefDate  ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
      )
      is
        select   nvl(ACS_FUNCTION.GetPjAccountId(pDefPjAcc), ACS_PJ_ACCOUNT_ID)
            from ACS_MGM_INTERACTION
           where ACS_CPN_ACCOUNT_ID = pCpnAccId
             and (    (    MGM_VALID_SINCE is null
                       and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE <= pRefDate
                      and MGM_VALID_TO is null)
                  or (    MGM_VALID_SINCE is null
                      and MGM_VALID_TO >= pRefDate)
                  or (pRefDate between MGM_VALID_SINCE and MGM_VALID_TO)
                 )
        order by MGM_DEFAULT;

      vFinImputationId   ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
      vDistributionId    ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_DISTRIBUTION_ID%type;
      vLabel             ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
      vMgmImputationId   ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
      vMgmDistributionId ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
      vCPNAccId          ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type;
      vCDAAccId          ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID%type;
      vPFAccId           ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID%type;
      vPJAccId           ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID%type;
      vQTYAccId          ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type;
      vHrmPersonId       ACT_MGM_IMPUTATION.HRM_PERSON_ID%type;
      vGoodId            ACT_MGM_IMPUTATION.GCO_GOOD_ID%type;
      vRecordId          ACT_MGM_IMPUTATION.DOC_RECORD_ID%type;
      vFamFixedId        ACT_MGM_IMPUTATION.FAM_FIXED_ASSETS_ID%type;
      vPersonId          ACT_MGM_IMPUTATION.PAC_PERSON_ID%type;
      vCdaImputation     ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
      vPfImputation      ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
      vPjImputation      ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
      vPjSubSetId        ACT_MGM_DISTRIBUTION.ACS_SUB_SET_ID%type;
      vCGenreTransaction ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION%type;
      vIsME              number;   -- -1=> monnaie �trang�re pas renseign�e, 0 => monnaie �trang�re correspond � la monnaie de base, 1 => monnaie �trang�re
      vConvAmountD       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;   -- montant converti en MB selon le montant ME
      vConvAmountC       ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;   -- montant converti en MB selon le montant ME
      vExchangeRate      ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;   -- cours de change
      vBasePrice         ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;   -- Diviseur

      function GetEmployeeId(pEmpNum HRM_PERSON.EMP_NUMBER%type)
        return HRM_PERSON.HRM_PERSON_ID%type
      is
        vResult HRM_PERSON.HRM_PERSON_ID%type;
      begin
        begin
          select nvl(HRM_PERSON_ID, 0)
            into vResult
            from HRM_PERSON
           where (   EMP_STATUS = 'SUS'
                  or EMP_STATUS = 'ACT')
             and PER_IS_EMPLOYEE = 1
             and EMP_NUMBER = pEmpNum
             and rownum = 1;
        exception
          when no_data_found then
            vResult  := null;
        end;

        return vResult;
      end GetEmployeeId;

      function GetCataloguePerType(pDocCatId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
        return ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type
      is
        vResult ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
      begin
        begin
          select C_TYPE_PERIOD
            into vResult
            from ACJ_CATALOGUE_DOCUMENT
           where ACJ_CATALOGUE_DOCUMENT_ID = pDocCatId;
        exception
          when no_data_found then
            vResult  := null;
        end;

        return vResult;
      end GetCataloguePerType;
    begin
      if pAmount_D <> 0 then
        vLabel  := pLabel_D;
      else
        vLabel  := pLabel_C;
      end if;

      vHrmPersonId  := GetEmployeeId(vDefHrmPerson);
      vPeriodId     := ACS_FUNCTION.GetPeriodID(pTranDate, GetCataloguePerType(pDocCatId) );
      vIsME         := GetFinCurIdType(pFinCurId);

      if vIsME = 1 then
        select nvl(max(LID_FREE_NUMBER_1), 0) IMF_EXCHANGE_RATE
             , nvl(max(LID_FREE_NUMBER_2), 0) IMF_BASE_PRICE
          into vExchangeRate
             , vBasePrice
          from COM_LIST_ID_TEMP
         where COM_LIST_ID_TEMP_ID = pFinCurId;

        if vBasePrice > 0 then
          vConvAmountD  := pAmountD * vExchangeRate / vBasePrice;
          vConvAmountC  := pAmountC * vExchangeRate / vBasePrice;
        else
          vConvAmountD  := 0;
          vConvAmountC  := 0;
        end if;
      else
        vConvAmountD   := 0;
        vConvAmountC   := 0;
        vExchangeRate  := 0;
        vBasePrice     := 0;
      end if;

      if pTaxImputation = 0 then
        vCGenreTransaction  := '5';
      elsif pTaxImputation = 1 then
        vCGenreTransaction  := '0';
      end if;

      select init_id_seq.nextval
        into vFinImputationId
        from dual;

      insert into ACT_FINANCIAL_IMPUTATION
                  (ACT_FINANCIAL_IMPUTATION_ID
                 , ACS_PERIOD_ID
                 , ACT_DOCUMENT_ID
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , IMF_TYPE
                 , IMF_PRIMARY
                 , IMF_DESCRIPTION
                 , IMF_AMOUNT_LC_D
                 , IMF_AMOUNT_LC_C
                 , IMF_EXCHANGE_RATE
                 , IMF_BASE_PRICE
                 , IMF_AMOUNT_FC_D
                 , IMF_AMOUNT_FC_C
                 , IMF_VALUE_DATE
                 , ACS_TAX_CODE_ID
                 , IMF_TRANSACTION_DATE
                 , ACS_AUXILIARY_ACCOUNT_ID
                 , ACT_DET_PAYMENT_ID
                 , IMF_GENRE
                 , ACS_FINANCIAL_CURRENCY_ID   -- ME
                 , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                 , C_GENRE_TRANSACTION
                 , A_DATECRE
                 , A_IDCRE
                 , ACT_PART_IMPUTATION_ID
                 , IMF_AMOUNT_EUR_D
                 , IMF_AMOUNT_EUR_C
                 , IMF_COMPARE_DATE
                 , IMF_CONTROL_DATE
                 , IMF_COMPARE_TEXT
                 , IMF_CONTROL_TEXT
                 , IMF_COMPARE_USE_INI
                 , IMF_CONTROL_USE_INI
                 , IMF_TEXT1
                 , IMF_TEXT2
                 , IMF_TEXT3
                 , IMF_TEXT4
                 , IMF_TEXT5
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , GCO_GOOD_ID
                 , HRM_PERSON_ID
                 , DOC_RECORD_ID
                 , IMF_NUMBER
                 , IMF_NUMBER2
                 , IMF_NUMBER3
                 , IMF_NUMBER4
                 , IMF_NUMBER5
                 , FAM_FIXED_ASSETS_ID
                 , PAC_PERSON_ID
                 , C_FAM_TRANSACTION_TYP
                  )
           values (vFinImputationId
                 , vPeriodId
                 , pDocumentId
                 , vFinAccId
                 , 'MAN'
                 , pPrimary
                 , vLabel
                 , decode(vIsME, 1, vConvAmountD, pAmountD)
                 , decode(vIsME, 1, vConvAmountC, pAmountC)
                 , decode(vIsME, 1, vExchangeRate, 0)
                 , decode(vIsME, 1, vBasePrice, 0)
                 , decode(vIsME, 1, pAmountD, 0)
                 , decode(vIsME, 1, pAmountC, 0)
                 , pValueDate
                 , null
                 , pTranDate
                 , null
                 , null
                 , 'STD'
                 , nvl(pFinCurId, vDocument.ACS_FINANCIAL_CURRENCY_ID)
                 , ACS_FUNCTION.GetLocalCurrencyID
                 , vCGenreTransaction
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , null
                 , 0
                 , 0
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , vDEFTEXT1
                 , vDEFTEXT2
                 , vDEFTEXT3
                 , vDEFTEXT4
                 , vDEFTEXT5
                 , vDEFDICFREE1
                 , vDEFDICFREE2
                 , vDEFDICFREE3
                 , vDEFDICFREE4
                 , vDEFDICFREE5
                 , null
                 , vHrmPersonId
                 , null
                 , vDEFNUM1
                 , vDEFNUM2
                 , vDEFNUM3
                 , vDEFNUM4
                 , vDEFNUM5
                 , null
                 , null
                 , null
                  );

      if ExistDivision <> 0 then
        select init_id_seq.nextval
          into vDistributionId
          from dual;

        insert into ACT_FINANCIAL_DISTRIBUTION
                    (ACT_FINANCIAL_DISTRIBUTION_ID
                   , ACT_FINANCIAL_IMPUTATION_ID
                   , FIN_DESCRIPTION
                   , FIN_AMOUNT_LC_D
                   , FIN_AMOUNT_FC_D
                   , FIN_AMOUNT_LC_C
                   , FIN_AMOUNT_FC_C
                   , ACS_SUB_SET_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , A_DATECRE
                   , A_IDCRE
                   , FIN_AMOUNT_EUR_D
                   , FIN_AMOUNT_EUR_C
                    )
             values (vDistributionId
                   , vFinImputationId
                   , vLabel
                   , decode(vIsME, 1, vConvAmountD, pAmountD)
                   , decode(vIsME, 1, pAmountD, 0)
                   , decode(vIsME, 1, vConvAmountC, pAmountC)
                   , decode(vIsME, 1, pAmountC, 0)
                   , ExistDivision
                   , vDivAccId
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                   , 0
                   , 0
                    );
      end if;

      --Imputation analytiques uniquement si le catalogue le g�re
      if Analytical = 1 then
        --V�rifier la gestion de l'analytique du compte financier
        select nvl(max(ACS_CPN_ACCOUNT_ID), 0)
          into vCPNAccId
          from ACS_FINANCIAL_ACCOUNT
         where ACS_FINANCIAL_ACCOUNT_ID = vFinAccId;

        if vCPNAccId <> 0 then   --Le cpn est initialis�
          --C'est le CPN des comptes / d�faut qui sera prise pour l'imputation si existant
          --sinon le Cpn d�finissant l'imputation analytique
          select nvl(ACS_FUNCTION.GetCPNAccountId(vDefCpnAcc), vCPNAccId)
            into vCPNAccId
            from dual;

          select C_CDA_IMPUTATION
               , C_PF_IMPUTATION
               , C_PJ_IMPUTATION   --recherche des autorisations du CPN
            into vCdaImputation
               , vPfImputation
               , vPjImputation
            from ACS_CPN_ACCOUNT
           where ACS_CPN_ACCOUNT_ID = vCPNAccId;

          if vCdaImputation <> '3' then   --CDA est g�r�
            if vCdaImputation = '1' then   --CDA obligatoire
              /*R�ception du cda des comptes/d�faut ou des interactions */
              open InteractionCdaAccCursor(vDefCdaAcc, vCPNAccId, pValueDate);

              fetch InteractionCdaAccCursor
               into vCdaAccId;

              close InteractionCdaAccCursor;

              /*CDA pas initialis� dans les cpt/def,ni dans les interactions */
              /*R�ception du compte CDA correspondant au min(acc_number)     */
              if vCdaAccId is null then
                select ACS_ACCOUNT_ID
                  into vCdaAccId
                  from ACS_ACCOUNT ACC
                     , ACS_CDA_ACCOUNT CDA
                 where CDA.ACS_CDA_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                           from ACS_ACCOUNT ACC
                                              , ACS_CDA_ACCOUNT CDA
                                          where CDA.ACS_CDA_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID);
              end if;
            elsif vCdaImputation = '2' then   --CDA autoris�
              /*pas de recherche en cascade ...prise en compte uniquement du cda du compte/d�faut si initialis�*/
              vCdaAccId  := ACS_FUNCTION.GetCDAAccountId(vDefCdaAcc);
            end if;
          end if;

          if vPfImputation <> '3' then   --PF est g�r�
            if vPfImputation = '1' then   --PF obligatoire
              /*R�ception du PF des comptes/d�faut ou des interactions */
              open InteractionPfAccCursor(vDefPfAcc, vCPNAccId, pValueDate);

              fetch InteractionPfAccCursor
               into vPfAccId;

              close InteractionPfAccCursor;

              /*PF pas initialis� dans les cpt/def,ni dans les interactions */
              /*R�ception du compte PF correspondant au min(acc_number)     */
              if vPfAccId is null then
                select ACS_ACCOUNT_ID
                  into vPfAccId
                  from ACS_ACCOUNT ACC
                     , ACS_PF_ACCOUNT PF
                 where PF.ACS_PF_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                           from ACS_ACCOUNT ACC
                                              , ACS_PF_ACCOUNT PF
                                          where PF.ACS_PF_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID);
              end if;
            elsif vPfImputation = '2' then   --CDA autoris�
              /*pas de recherche en cascade ...prise en compte uniquement du PF du compte/d�faut si initialis�*/
              vPfAccId  := ACS_FUNCTION.GetPfAccountId(vDefPfAcc);
            end if;
          end if;

          if vPjImputation <> '3' then   --PJ est g�r�
            if vPjImputation = '1' then   --PJ obligatoire
              /*R�ception du PJ des comptes/d�faut ou des interactions */
              open InteractionPjAccCursor(vDefPjAcc, vCPNAccId, pValueDate);

              fetch InteractionPjAccCursor
               into vPjAccId;

              close InteractionPjAccCursor;

              /*PJ pas initialis� dans les cpt/def,ni dans les interactions */
              /*R�ception du compte PJ correspondant au min(acc_number)     */
              if vPjAccId is null then
                select ACS_ACCOUNT_ID
                  into vPjAccId
                  from ACS_ACCOUNT ACC
                     , ACS_PJ_ACCOUNT PJ
                 where PJ.ACS_PJ_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACC_NUMBER = (select min(ACC_NUMBER)
                                           from ACS_ACCOUNT ACC
                                              , ACS_PJ_ACCOUNT PJ
                                          where PJ.ACS_PJ_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID);
              end if;
            elsif vPjImputation = '2' then   --CDA autoris�
              /*pas de recherche en cascade ...prise en compte uniquement du PF du compte/d�faut si initialis�*/
              vPjAccId  := ACS_FUNCTION.GetPjAccountId(vDefPjAcc);
            end if;
          end if;

          if     (vCdaImputation = '2')
             and (vPfImputation = '2')
             and   --CDA possible + PF possible Et valeurs nulles
                 (vCdaAccId is null)
             and (vPfAccId is null) then
            Raise_application_error(-20001
                                  , ' PCS - ' ||
                                    PCS.PC_FUNCTIONS.TRANSLATEWORD('Un compte CDA ou PF au moins est obligatoire')
                                   );
          end if;

          vQTYAccId  := ACS_FUNCTION.GetQtyAccountId(vDefQtyAcc);

          select init_id_seq.nextval
            into vMgmImputationId
            from dual;

          insert into ACT_MGM_IMPUTATION
                      (ACT_MGM_IMPUTATION_ID
                     , ACS_FINANCIAL_CURRENCY_ID   --ME
                     , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                     , ACS_PERIOD_ID
                     , ACS_CPN_ACCOUNT_ID
                     , ACS_CDA_ACCOUNT_ID
                     , ACS_PF_ACCOUNT_ID
                     , ACS_QTY_UNIT_ID
                     , ACT_DOCUMENT_ID
                     , ACT_FINANCIAL_IMPUTATION_ID
                     , C_FAM_TRANSACTION_TYP
                     , IMM_TYPE
                     , IMM_GENRE
                     , IMM_PRIMARY
                     , IMM_DESCRIPTION
                     , IMM_AMOUNT_LC_D
                     , IMM_AMOUNT_LC_C
                     , IMM_EXCHANGE_RATE
                     , IMM_BASE_PRICE
                     , IMM_AMOUNT_FC_D
                     , IMM_AMOUNT_FC_C
                     , IMM_VALUE_DATE
                     , IMM_TRANSACTION_DATE
                     , IMM_QUANTITY_D
                     , IMM_QUANTITY_C
                     , IMM_AMOUNT_EUR_D
                     , IMM_AMOUNT_EUR_C
                     , IMM_TEXT1
                     , IMM_TEXT2
                     , IMM_TEXT3
                     , IMM_TEXT4
                     , IMM_TEXT5
                     , DIC_IMP_FREE1_ID
                     , DIC_IMP_FREE2_ID
                     , DIC_IMP_FREE3_ID
                     , DIC_IMP_FREE4_ID
                     , DIC_IMP_FREE5_ID
                     , IMM_NUMBER
                     , IMM_NUMBER2
                     , IMM_NUMBER3
                     , IMM_NUMBER4
                     , IMM_NUMBER5
                     , HRM_PERSON_ID
                     , GCO_GOOD_ID
                     , DOC_RECORD_ID
                     , FAM_FIXED_ASSETS_ID
                     , PAC_PERSON_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (vMgmImputationId
                     , nvl(pFinCurId, vDocument.ACS_FINANCIAL_CURRENCY_ID)
                     , ACS_FUNCTION.GetLocalCurrencyID
                     , vPeriodId
                     , vCPNAccId
                     , vCDAAccId
                     , vPFAccId
                     , vQTYAccId
                     , pDocumentId
                     , vFinImputationId
                     , null
                     , 'MAN'
                     , 'STD'
                     , pPrimary
                     , vLabel
                     , decode(vIsME, 1, vConvAmountD, pAmountD)
                     , decode(vIsME, 1, vConvAmountC, pAmountC)
                     , vExchangeRate
                     , vBasePrice
                     , decode(vIsME, 1, pAmountD, 0)
                     , decode(vIsME, 1, pAmountC, 0)
                     , pValueDate
                     , pTranDate
                     , 0
                     , 0
                     , 0
                     , 0
                     , vDEFTEXT1
                     , vDEFTEXT2
                     , vDEFTEXT3
                     , vDEFTEXT4
                     , vDEFTEXT5
                     , vDEFDICFREE1
                     , vDEFDICFREE2
                     , vDEFDICFREE3
                     , vDEFDICFREE4
                     , vDEFDICFREE5
                     , vDEFNUM1
                     , vDEFNUM2
                     , vDEFNUM3
                     , vDEFNUM4
                     , vDEFNUM5
                     , vHrmPersonId
                     , vGoodId
                     , vRecordId
                     , vFamFixedId
                     , vPersonId
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          if     (vPjAccId <> 0)
             and (not vPjAccId is null) then
            select nvl(max(ACS_SUB_SET_ID), 0)
              into vPjSubSetId
              from ACS_SUB_SET
             where C_TYPE_SUB_SET = 'COM'
               and C_SUB_SET = 'PRO';

            select init_id_seq.nextval
              into vMgmDistributionId
              from dual;

            insert into ACT_MGM_DISTRIBUTION
                        (ACT_MGM_DISTRIBUTION_ID
                       , ACT_MGM_IMPUTATION_ID
                       , ACS_PJ_ACCOUNT_ID
                       , ACS_SUB_SET_ID
                       , MGM_DESCRIPTION
                       , MGM_AMOUNT_LC_D
                       , MGM_AMOUNT_FC_D
                       , MGM_AMOUNT_LC_C
                       , MGM_AMOUNT_FC_C
                       , MGM_QUANTITY_D
                       , MGM_QUANTITY_C
                       , MGM_AMOUNT_EUR_D
                       , MGM_AMOUNT_EUR_C
                       , MGM_TEXT1
                       , MGM_TEXT2
                       , MGM_TEXT3
                       , MGM_TEXT4
                       , MGM_TEXT5
                       , MGM_NUMBER
                       , MGM_NUMBER2
                       , MGM_NUMBER3
                       , MGM_NUMBER4
                       , MGM_NUMBER5
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (vMgmDistributionId
                       , vMgmImputationId
                       , vPjAccId
                       , vPjSubSetId
                       , vLabel
                       , decode(vIsME, 1, vConvAmountD, pAmountD)
                       , decode(vIsME, 1, pAmountD, 0)
                       , decode(vIsME, 1, vConvAmountC, pAmountC)
                       , decode(vIsME, 1, pAmountC, 0)
                       , 0
                       , 0
                       , 0
                       , 0
                       , vDEFTEXT1
                       , vDEFTEXT2
                       , vDEFTEXT3
                       , vDEFTEXT4
                       , vDEFTEXT5
                       , vDEFNUM1
                       , vDEFNUM2
                       , vDEFNUM3
                       , vDEFNUM4
                       , vDEFNUM5
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end if;
        end if;
      end if;
    end InsertImputation;

    procedure GetDefaultDatas(
      pCatalogueId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
    ,   --Catalogue document
      pAccountId   ACS_DEFAULT_ACCOUNT.ACS_DEFAULT_ACCOUNT_ID%type
    ,   --Compte /d�faut
      pDate        date
    )   --Date
    is
      cursor CatManagedValues(pCatalogueId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
      is
        select C_DATA_TYP
             , MDA_MANDATORY
             , MDA_MANDATORY_PRIMARY
          from ACJ_IMP_MANAGED_DATA
             , acj_catalogue_document
         where ACJ_IMP_MANAGED_DATA.ACJ_CATALOGUE_DOCUMENT_ID = pCatalogueId
           and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_IMP_MANAGED_DATA.ACJ_CATALOGUE_DOCUMENT_ID
           and ACJ_CATALOGUE_DOCUMENT.CAT_IMP_INFORMATION = 1;

      CatManagedDatas CatManagedValues%rowtype;
      vDico1          boolean;
      vDico2          boolean;
      vDico3          boolean;
      vDico4          boolean;
      vDico5          boolean;
      vNum1           boolean;
      vNum2           boolean;
      vNum3           boolean;
      vNum4           boolean;
      vNum5           boolean;
      vText1          boolean;
      vText2          boolean;
      vText3          boolean;
      vText4          boolean;
      vText5          boolean;
      vDate1          boolean;
      vDate2          boolean;
      vDate3          boolean;
      vDate4          boolean;
      vDate5          boolean;
      vRecord         boolean;
      vFixed          boolean;
      vGood           boolean;
      vHrmPer         boolean;
      vPacPer         boolean;
    begin
      --Initialisation des valeurs de retour
      vDefFinAcc     := '';
      vDefNum1       := '';
      vDefText1      := '';
      vDefDicFree1   := '';
      vDefDate1      := '';
      vDefDivAcc     := '';
      vDefNum2       := '';
      vDefText2      := '';
      vDefDicFree2   := '';
      vDefDate2      := '';
      vDefCpnAcc     := '';
      vDefNum3       := '';
      vDefText3      := '';
      vDefDicFree3   := '';
      vDefDate3      := '';
      vDefCdaAcc     := '';
      vDefNum4       := '';
      vDefText4      := '';
      vDefDicFree4   := '';
      vDefDate4      := '';
      vDefPfAcc      := '';
      vDefNum5       := '';
      vDefText5      := '';
      vDefDicFree5   := '';
      vDefDate5      := '';
      vDefPjAcc      := '';
      vDefQtyAcc     := '';
      vDefHrmPerson  := '';
      vDico1         := false;
      vNum1          := false;
      vText1         := false;
      vDate1         := false;
      vRecord        := false;
      vDico2         := false;
      vNum2          := false;
      vText2         := false;
      vDate2         := false;
      vFixed         := false;
      vDico3         := false;
      vNum3          := false;
      vText3         := false;
      vDate3         := false;
      vGood          := false;
      vDico4         := false;
      vNum4          := false;
      vText4         := false;
      vDate4         := false;
      vHrmPer        := false;
      vDico5         := false;
      vNum5          := false;
      vText5         := false;
      vDate5         := false;
      vPacPer        := false;
      --R�ception des comptes et autres donn�es des comptes / d�faut
      ACS_DEF_ACCOUNT.GetAccountOfHeader(pAccountId
                                       , pDate
                                       , 0
                                       , vDefFinAcc
                                       , vDefDivAcc
                                       , vDefCpnAcc
                                       , vDefCdaAcc
                                       , vDefPfAcc
                                       , vDefPjAcc
                                       , vDefQtyAcc
                                       , vDefHrmPerson
                                       , vDefNum1
                                       , vDefNum2
                                       , vDefNum3
                                       , vDefNum4
                                       , vDefNum5
                                       , vDefText1
                                       , vDefText2
                                       , vDefText3
                                       , vDefText4
                                       , vDefText5
                                       , vDefDicFree1
                                       , vDefDicFree2
                                       , vDefDicFree3
                                       , vDefDicFree4
                                       , vDefDicFree5
                                       , vDefDate1
                                       , vDefDate2
                                       , vDefDate3
                                       , vDefDate4
                                       , vDefDate5
                                        );

      --Suivant la gestion du catalogue document on remet � vide les donn�es non g�r�es
      open CatManagedValues(pCatalogueId);

      fetch CatManagedValues
       into CatManagedDatas;

      while CatManagedValues%found loop
        vDico1   :=    vDico1
                    or CatManagedDatas.C_DATA_TYP = 'DICO1';
        vDico2   :=    vDico2
                    or CatManagedDatas.C_DATA_TYP = 'DICO2';
        vDico3   :=    vDico3
                    or CatManagedDatas.C_DATA_TYP = 'DICO3';
        vDico4   :=    vDico4
                    or CatManagedDatas.C_DATA_TYP = 'DICO4';
        vDico5   :=    vDico5
                    or CatManagedDatas.C_DATA_TYP = 'DICO5';
        vNum1    :=    vNum1
                    or CatManagedDatas.C_DATA_TYP = 'NUMBER';
        vNum2    :=    vNum2
                    or CatManagedDatas.C_DATA_TYP = 'NUMBER2';
        vNum3    :=    vNum3
                    or CatManagedDatas.C_DATA_TYP = 'NUMBER3';
        vNum4    :=    vNum4
                    or CatManagedDatas.C_DATA_TYP = 'NUMBER4';
        vNum5    :=    vNum5
                    or CatManagedDatas.C_DATA_TYP = 'NUMBER5';
        vText1   :=    vText1
                    or CatManagedDatas.C_DATA_TYP = 'TEXT1';
        vText2   :=    vText2
                    or CatManagedDatas.C_DATA_TYP = 'TEXT2';
        vText3   :=    vText3
                    or CatManagedDatas.C_DATA_TYP = 'TEXT3';
        vText4   :=    vText4
                    or CatManagedDatas.C_DATA_TYP = 'TEXT4';
        vText5   :=    vText5
                    or CatManagedDatas.C_DATA_TYP = 'TEXT5';
        vRecord  :=    vRecord
                    or CatManagedDatas.C_DATA_TYP = 'DOC_RECORD';
        vFixed   :=    vFixed
                    or CatManagedDatas.C_DATA_TYP = 'FAM_FIXED';
        vGood    :=    vGood
                    or CatManagedDatas.C_DATA_TYP = 'GCO_GOOD';
        vHrmPer  :=    vHrmPer
                    or CatManagedDatas.C_DATA_TYP = 'HRM_PERSON';
        vPacPer  :=    vPacPer
                    or CatManagedDatas.C_DATA_TYP = 'PAC_PERSON';

        fetch CatManagedValues
         into CatManagedDatas;
      end loop;

      close CatManagedValues;

      if not vDico1 then
        vDefDicFree1  := '';
      end if;

      if not vDico2 then
        vDefDicFree2  := '';
      end if;

      if not vDico3 then
        vDefDicFree3  := '';
      end if;

      if not vDico4 then
        vDefDicFree4  := '';
      end if;

      if not vDico5 then
        vDefDicFree5  := '';
      end if;

      if not vNum1 then
        vDefNum1  := '';
      end if;

      if not vNum2 then
        vDefNum2  := '';
      end if;

      if not vNum3 then
        vDefNum3  := '';
      end if;

      if not vNum4 then
        vDefNum4  := '';
      end if;

      if not vNum5 then
        vDefNum5  := '';
      end if;

      if not vText1 then
        vDefText1  := '';
      end if;

      if not vText2 then
        vDefText2  := '';
      end if;

      if not vText3 then
        vDefText3  := '';
      end if;

      if not vText4 then
        vDefText4  := '';
      end if;

      if not vText5 then
        vDefText5  := '';
      end if;

      if not vHrmPer then
        vDefHrmPerson  := '';
      end if;
    end GetDefaultDatas;
  begin
    open DocumentCursor(pDocumentId);

    fetch DocumentCursor
     into vDocument;

    if vDocument.ACT_DOCUMENT_ID is not null then   --Document existe
      if pTaxImputation = 0 then
        if pIntAccId <> 0 then   --Compte d'int�r�t de la m�thode (El�ment) est saisi
          GetDefaultDatas(pDocCatId, pIntAccId, pValueDate);   --R�ception comptes/d�faut pour compte d'imputation int�r�t
          vFinAccId  := ACS_FUNCTION.GETFINANCIALACCOUNTID(vDefFinAcc);
          vDivAccId  := ACS_FUNCTION.GETDIVISIONACCOUNTID(vDefDivAcc);

          if vFinAccId is null then
            vFinAccId  := pFinAccId;
          end if;

          if vDivAccId is null then
            vDivAccId  := pDivAccId;
          end if;
        else   --Compte d'int�r�t n'est pas saisie dans la m�thode (El�ment)
          vFinAccId  := pFinAccId;   --Compte pris en compte = Compte sur lequel on calcule l'int�r�t
          vDivAccId  := pDivAccId;
        end if;

        InsertImputation(pFinCurId, pAmount_D, pAmount_C, pPrimary);   --Cr�ation imputation financi�re int�ret passif/ actif

        if pAmount_D <> 0 then   --Montant au d�bit
          GetDefaultDatas(pDocCatId, pIntAccId_D, pValueDate);   --R�ception comptes/d�faut pour compte d'imputation int�r�t actif
        elsif pAmount_C <> 0 then   --Montant au cr�dit
          GetDefaultDatas(pDocCatId, pIntAccId_C, pValueDate);   --R�ception comptes/d�faut pour compte d'imputation int�r�t passif
        end if;

        vFinAccId  := ACS_FUNCTION.GETFINANCIALACCOUNTID(vDefFinAcc);
        vDivAccId  := ACS_FUNCTION.GETDIVISIONACCOUNTID(vDefDivAcc);

        if vFinAccId is null then
          vFinAccId  := pFinAccId;
        end if;

        if vDivAccId is null then
          vDivAccId  := pDivAccId;
        end if;

        vDivAccId  := ACS_FUNCTION.GetDivisionOfAccount(vFinAccId, vDivAccId, pTranDate);   --Validation de la division
        InsertImputation(pFinCurId, pAmount_C, pAmount_D, 0);   --Cr�ation imputation financi�re int�ret
      elsif pTaxImputation = 1 then
        --Deux imputations imp�t anticip� n�cessaires ..
        --1� Compte de calcul au d�bit
        --2� Compte d'imp�t anticip� au cr�dit
        if pIntAccId <> 0 then   --Compte d'int�r�t de la m�thode (El�ment) est saisi
          GetDefaultDatas(pDocCatId, pIntAccId, pValueDate);   --R�ception comptes/d�faut pour compte d'imputation int�r�t
          vFinAccId  := ACS_FUNCTION.GETFINANCIALACCOUNTID(vDefFinAcc);
          vDivAccId  := ACS_FUNCTION.GETDIVISIONACCOUNTID(vDefDivAcc);

          if vFinAccId is null then
            vFinAccId  := pFinAccId;
          end if;

          if vDivAccId is null then
            vDivAccId  := pDivAccId;
          end if;
        else   --Compte d'int�r�t n'est pas saisie dans la m�thode (El�ment)
          vFinAccId  := pFinAccId;   --Compte pris en compte = Compte sur lequel on calcule l'int�r�t
          vDivAccId  := pDivAccId;
        end if;

        InsertImputation(pFinCurId, pIntNetAmount * pTaxRate / 100, 0, 0);   --Cr�ation imputation imp�t sur le compte de calcul

        if pIntAccId_T <> 0 then   --Compte d'imp�t anticip� de la m�thode (El�ment) est saisi
          GetDefaultDatas(pDocCatId, pIntAccId_T, pValueDate);   --R�ception comptes/d�faut pour compte d'imputation imp�t anticip�
          vFinAccId  := ACS_FUNCTION.GETFINANCIALACCOUNTID(vDefFinAcc);
          vDivAccId  := ACS_FUNCTION.GETDIVISIONACCOUNTID(vDefDivAcc);
        end if;

        if vFinAccId is null then
          vFinAccId  := pFinAccId;
        end if;

        if vDivAccId is null then
          vDivAccId  := pDivAccId;
        end if;

        vDivAccId  := ACS_FUNCTION.GetDivisionOfAccount(vFinAccId, vDivAccId, pTranDate);   --Validation de la division
        InsertImputation(pFinCurId, 0, pIntNetAmount * pTaxRate / 100, 0);   --Cr�ation imputation imp�t sur le compte d'imp�t
      end if;
    end if;
  end CreateImputation;

-----------------------------------------------------------------------------------------------------------------------
  procedure CreateInterestDetailPosition(
    pJobId           ACT_JOB.ACT_JOB_ID%type
  , pIntCalcMethodId ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type
  , pStartPeriodId   ACS_PERIOD.ACS_PERIOD_ID%type
  , pEndPeriodId     ACS_PERIOD.ACS_PERIOD_ID%type
  )
  is
    /*Recherche des comptes financiers /divisions des �l�ments de m�thode de la m�thode de calcul*/
    cursor MethodAccountsCursor(pIntCalcMethodId ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type)
    is
      select   *
          from (select MEL.ACS_FINANCIAL_ACCOUNT_ID
                     , DIV.ACS_DIVISION_ACCOUNT_ID
                     , MEL.ACS_FINANCIAL_CURRENCY_ID
                     , MEL.ACS_INTEREST_CATEG_ID
                     , ACC.ACC_NUMBER
                  from ACS_METHOD_ELEM MEL
                     , ACS_DIVISION_ACCOUNT DIV
                     , ACS_ACCOUNT ACC
                 where MEL.ACS_INT_CALC_METHOD_ID = pIntCalcMethodId
                   and ACC.ACS_ACCOUNT_ID = MEL.ACS_FINANCIAL_ACCOUNT_ID
                   and DIV.ACS_DIVISION_ACCOUNT_ID =
                         decode(MEL.ACS_DIVISION_ACCOUNT_ID
                              , null, DIV.ACS_DIVISION_ACCOUNT_ID
                              , MEL.ACS_DIVISION_ACCOUNT_ID
                               )
                   and ExistDivision <> 0
                union all
                select MEL.ACS_FINANCIAL_ACCOUNT_ID
                     , MEL.ACS_DIVISION_ACCOUNT_ID
                     , MEL.ACS_FINANCIAL_CURRENCY_ID
                     , MEL.ACS_INTEREST_CATEG_ID
                     , ACC.ACC_NUMBER
                  from ACS_METHOD_ELEM MEL
                     , ACS_ACCOUNT ACC
                 where MEL.ACS_INT_CALC_METHOD_ID = pIntCalcMethodId
                   and ACC.ACS_ACCOUNT_ID = MEL.ACS_FINANCIAL_ACCOUNT_ID
                   and ExistDivision = 0)
      order by 1
             , 2
             , nvl(3, 0);

    vMethodAccounts    MethodAccountsCursor%rowtype;   --Variable de r�ception des enregistrements du curseur
    vMethodCumulType   varchar2(100);   --R�ceptionne les types de cumul g�r�s
    vBeginPerNum       ACS_PERIOD.PER_NO_PERIOD%type;   --Num�ro de p�riode de la p�riode de d�but
    vBeginPerStartDate ACS_PERIOD.PER_START_DATE%type;   --Date de d�but de la p�riode de d�but
    vEndPerNum         ACS_PERIOD.PER_NO_PERIOD%type;   --Num�ro de p�riode de la p�riode de fin
    vEndPerEndDate     ACS_PERIOD.PER_START_DATE%type;   --Date de fin de la p�riode de fin
    vExeNum            ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;   --Num�ro d'exercice
    vExeId             ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;   --Id Exercice
    vPreviousBalanceId ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;   --Id D�tail du solde du calcul pr�c�dent
    vLastImpDate       ACS_PERIOD.PER_START_DATE%type;
    vFirstBreakdown    boolean;

    /* Fonction de contr�le d'existence pour le couple compte-division-monnaie dans TOUS les d�comptes d'int�r�ts*/
    function IsFirstInterestDetail(
      pFinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
    , pDivAccId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
    , pFinCurID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    )
      return boolean
    is
      vCount number;
    begin
      select count(0)
        into vCount
        from ACT_INTEREST_DETAIL
       where ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
         and (    (    ExistDivision = 0
                   and ACS_DIVISION_ACCOUNT_ID is null)
              or (    ExistDivision <> 0
                  and pDivAccId is not null
                  and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
              or (pDivAccId is null)
             )
         and (    (     (pFinCurId is null)
                   and ACS_FINANCIAL_CURRENCY_ID is null)
              or (    pFinCurId is not null
                  and nvl(ACS_FINANCIAL_CURRENCY_ID, 0) = pFinCurId)
             );

      return(vCount = 0);
    end IsFirstInterestDetail;
  begin
    /*R�ception des types de cumul pris en compte par la m�thode*/
    vMethodCumulType  := GetMethodCumulType(pIntCalcMethodId);

    /*R�ception des informations de la p�riode*/
    select PER1.PER_NO_PERIOD
         , PER1.PER_START_DATE
         , ACS_FUNCTION.GETFINANCIALYEARNO(PER1.PER_START_DATE)
         , ACS_FUNCTION.GetFinancialYearID(PER1.PER_START_DATE)
         , PER2.PER_NO_PERIOD
         , PER2.PER_END_DATE
      into vBeginPerNum
         , vBeginPerStartDate
         , vExeNum
         , vExeId
         , vEndPerNum
         , vEndPerEndDate
      from ACS_PERIOD PER1
         , ACS_PERIOD PER2
     where PER1.ACS_PERIOD_ID = pStartPeriodId
       and PER2.ACS_PERIOD_ID = pEndPeriodId;

    /*Parcours des couples financier / division � traiter des �l�ements de m�thode de la m�thode*/
    open MethodAccountsCursor(pIntCalcMethodId);

    fetch MethodAccountsCursor
     into vMethodAccounts;

    while MethodAccountsCursor%found loop
      /*Initialisation des variables globales de la vue utilis�e
        Si premier d�compte pour le couple fin-div-cur, initialiser la vue avec l'exercice pour avoir les reports
      */
      vFirstBreakdown  :=
        IsFirstInterestDetail(vMethodAccounts.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                            , vMethodAccounts.ACS_DIVISION_ACCOUNT_ID   --Compte division
                            , vMethodAccounts.ACS_FINANCIAL_CURRENCY_ID   --Monnaie comptable
                             );

      if vFirstBreakdown then
        SetV_ACT_IMPUTATION(vMethodAccounts.ACC_NUMBER, vMethodAccounts.ACC_NUMBER, vExeId);
      else
        SetV_ACT_IMPUTATION(vMethodAccounts.ACC_NUMBER, vMethodAccounts.ACC_NUMBER, '0');
      end if;

      /*Cr�ation d�tail int�r�t pour solde de d�part*/
      CreateBalancePosition(pJobId   --Travail en cours
                          , vMethodAccounts.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                          , vMethodAccounts.ACS_DIVISION_ACCOUNT_ID   --Compte division
                          , vMethodAccounts.ACS_FINANCIAL_CURRENCY_ID   --Monnaie comptable
                          , pIntCalcMethodId   --M�thode
                          , vExeId   --Exercice
                          , vExeNum   --Num. exercice
                          , vBeginPerNum   --Num�ro de la p�riode de d�but de calcul
                          , vBeginPerStartDate   --Date de d�but de la p�riode de d�but de calcul
                          , vMethodCumulType   --Types de cumul pris en compte
                          , vFirstBreakdown
                           );
      /*   Cr�ation des d�tails int�r�ts pour imputations financi�res */
      vLastImpDate     :=
        InterestDetImputation(pJobId   --Travail comptable
                            , vMethodAccounts.ACS_DIVISION_ACCOUNT_ID   --Compte division
                            , vMethodAccounts.ACS_FINANCIAL_CURRENCY_ID   --Monnaie comptable
                            , vExeNum   --Num. exercice
                            , vBeginPerStartDate   --Date d�but de calcul
                            , vEndPerNum   --Num p�riode de fin de calcul
                            , vEndPerEndDate   --Date fin de la p�riode de fin de calcul
                            , vMethodCumulType   --Types de cumul g�r�s
                            , pIntCalcMethodId   --M�thode de calcul
                            , vMethodAccounts.ACS_INTEREST_CATEG_ID   --Cat�gorie d'int�r�t
                             );
      /* Simulation des d�tails int�r�ts pour changements de taux*/
      InterestDetSimulation(pJobId
                          , vMethodAccounts.ACS_FINANCIAL_ACCOUNT_ID
                          , vMethodAccounts.ACS_DIVISION_ACCOUNT_ID
                          , vMethodAccounts.ACS_FINANCIAL_CURRENCY_ID
                          , vLastImpDate
                          , vEndPerEndDate
                          , vMethodAccounts.ACS_INTEREST_CATEG_ID
                           );
      InterestDetUpdate(pJobId   --Travail comptable
                      , vMethodAccounts.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
                      , vMethodAccounts.ACS_DIVISION_ACCOUNT_ID   --Monnaie comptable
                      , vMethodAccounts.ACS_FINANCIAL_CURRENCY_ID   --Compte division
                      , vMethodAccounts.ACS_INTEREST_CATEG_ID   --Cat�gorie d'int�r�t
                      , vBeginPerStartDate   --Date d�but de calcul
                      , vEndPerEndDate   --Date fin de calcul
                       );

      fetch MethodAccountsCursor
       into vMethodAccounts;
    end loop;

    close MethodAccountsCursor;

    --Suppression des lignes � 0 suite au produit cart�sien
    DeleteNullDetPosition(pJobId);
  end CreateInterestDetailPosition;

-----------------------------------------------------------------------------------------------------------------------
  procedure CreateBalancePosition(
    pJobId           ACT_INTEREST_DETAIL.ACT_JOB_ID%type
  , pFinAccId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId        ACT_INTEREST_DETAIL.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
  , pMethodId        ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type
  , pFinYearId       ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , pPerStartNum     ACS_PERIOD.PER_NO_PERIOD%type
  , pPerStartDate    ACS_PERIOD.PER_START_DATE%type
  , pMethodCumulType varchar2
  , pFirstBreakdown  boolean
  )
  is
    /*Recherche du report car c'est la toute premi�re fois que le couple compte-div-monnaie est inclu dans un d�compte d'int�r�t
    */
    cursor FirstReportBalance(
      pDivAccId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type   --Division du couple � traiter
    , pFinCurId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type   -- monnaie � traiter
    , pIsME            number
    , pMethodCumulType varchar2   --Types de cumul g�r�s
    , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type   --Num�ro d'exercice
    , pPerStartNum     ACS_PERIOD.PER_NO_PERIOD%type   --Num�ro de p�riode de la p�riode de d�but calcul
    )
    is
      select Balance.ReportAmount
        from (select decode(pIsME
                          , 1, sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C)
                          , sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C)
                           ) ReportAmount
                from V_ACT_ACC_IMP_REPORT V
               where (    (    ExistDivision = 0
                           and V.ACS_DIVISION_ACCOUNT_ID is null)
                      or (    ExistDivision <> 0
                          and pDivAccId is not null
                          and V.ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                      or (pDivAccId is null)
                     )
                 and (    (pFinCurId is null)
                      or (    pFinCurId is not null
                          and V.ACS_FINANCIAL_CURRENCY_ID = pFinCurId) )
                 and instr(pMethodCumulType, V.C_TYPE_CUMUL) > 0
                 and (exists(select 1
                              from ACT_JOURNAL
                             where C_TYPE_JOURNAL = 'OPB'
                               and ACT_JOURNAL_ID = V.ACT_JOURNAL_ID)
                      or
                      V.ACT_DOCUMENT_ID = 0) ) Balance;

    /*Calcul du solde au jour de d�but de calcul pour les imputations
      ayant la date transaction > jour d�but calcul MAIS avec la date valeur ant�rieure
      au d�but de calcul....Cas du premier calcul pour un compte nouvellement cr��
    */
    cursor FirstImputationBalance(
      pDivAccId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type   --Division du couple � traiter
    , pFinCurId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type   -- monnaie � traiter
    , pIsME            number
    , pMethodCumulType varchar2   --Types de cumul g�r�s
    , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type   --Num�ro d'exercice
    , pPerStartNum     ACS_PERIOD.PER_NO_PERIOD%type   --Num�ro de p�riode de la p�riode de d�but calcul
    )
    is
      select Balance.ReportAmount
        from (select decode(pIsME, 1, sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) )
                                                                                                           ReportAmount
                from V_ACT_ACC_IMP_REPORT
               where (    (    ExistDivision = 0
                           and ACS_DIVISION_ACCOUNT_ID is null)
                      or (    ExistDivision <> 0
                          and pDivAccId is not null
                          and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                      or (pDivAccId is null)
                     )
                 and (    (pFinCurId is null)
                      or (    pFinCurId is not null
                          and ACS_FINANCIAL_CURRENCY_ID = pFinCurId) )
                 and instr(pMethodCumulType, C_TYPE_CUMUL) > 0
                 and to_number(ACS_FUNCTION.GETFINANCIALYEARNO(IMF_TRANSACTION_DATE) ||
                               lpad(ACS_FUNCTION.GETPERIODNO(IMF_TRANSACTION_DATE, 2), 9, '0')
                              ) > to_number(pExerciseNum || lpad(pPerStartNum, 9, '0') )
                 and to_number(ACS_FUNCTION.GETFINANCIALYEARNO(IMF_VALUE_DATE) ||
                               lpad(ACS_FUNCTION.GETPERIODNO(IMF_VALUE_DATE, 2), 9, '0')
                              ) < to_number(pExerciseNum || lpad(pPerStartNum, 9, '0') ) ) Balance;

    /*Calcul du solde au jour de d�but de calcul pour les imputations*/
    cursor ImputationBalance(
      pDivAccId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type   --Division du couple � traiter
    , pFinCurId        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type   -- Monnaie du couple � traiter
    , pIsME            number
    , pMethodCumulType varchar2   --Types de cumul g�r�s
    , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type   --Num�ro d'exercice
    , pPerStartNum     ACS_PERIOD.PER_NO_PERIOD%type   --Num�ro de p�riode de la p�riode de d�but calcul
    )
    is
      select Balance.ReportAmount
        from (select decode(pIsME, 1, sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) )
                                                                                                           ReportAmount
                from V_ACT_ACC_IMP_REPORT
               where (    (    ExistDivision = 0
                           and ACS_DIVISION_ACCOUNT_ID is null)
                      or (    ExistDivision <> 0
                          and pDivAccId is not null
                          and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                      or (pDivAccId is null)
                     )
                 and (    (pFinCurId is null)
                      or (    pFinCurId is not null
                          and ACS_FINANCIAL_CURRENCY_ID = pFinCurId) )
                 and instr(pMethodCumulType, C_TYPE_CUMUL) > 0
                 and to_number(ACS_FUNCTION.GETFINANCIALYEARNO(IMF_TRANSACTION_DATE) ||
                               lpad(ACS_FUNCTION.GETPERIODNO(IMF_TRANSACTION_DATE, 2), 9, '0')
                              ) < to_number(pExerciseNum || lpad(pPerStartNum, 9, '0') ) ) Balance;

    /*Recherche du solde du pr�c�dent calcul pour le couple compte financier/division/monnaie
      - Solde de la derni�re �criture des d�tails pour le couple du moment que des p�riodes de calcul
        existent pour la m�thode et l'ann�e*/
    cursor PreviousBalanceCursor(
      pFinAccId  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
    , pDivAccId  ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
    , pFinCurId  ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
    , pMethodId  ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type
    , pFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
    )
    is
      select   DET.IDE_BALANCE_AMOUNT
          from ACT_INTEREST_DETAIL DET
         where DET.ACS_FINANCIAL_ACCOUNT_ID = pFinAccid
           and (    (    ExistDivision = 0
                     and DET.ACS_DIVISION_ACCOUNT_ID is null)
                or (    ExistDivision <> 0
                    and pDivAccId is not null
                    and DET.ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                or (pDivAccId is null)
               )
           and (    (     (pFinCurId is null)
                     and ACS_FINANCIAL_CURRENCY_ID is null)
                or (    pFinCurId is not null
                    and DET.ACS_FINANCIAL_CURRENCY_ID = pFinCurId)
               )
           and exists(select 1
                        from ACT_CALC_PERIOD PER
                       where per.ACS_INT_CALC_METHOD_ID = pMethodId)
           and not exists(
                 select 1
                   from ACT_FINANCIAL_IMPUTATION IMP
                      , ACT_FINANCIAL_IMPUTATION FIN
                  where FIN.ACT_FINANCIAL_IMPUTATION_ID = DET.ACT_FINANCIAL_IMPUTATION_ID
                    and IMP.ACT_DOCUMENT_ID = FIN.ACT_DOCUMENT_ID
                    and IMP.C_GENRE_TRANSACTION = '5')
      order by DET.IDE_VALUE_DATE desc
             , nvl(DET.IDE_TRANSACTION_DATE, DET.IDE_VALUE_DATE) desc
             , DET.ACT_INTEREST_DETAIL_ID desc;

    vBalanceAmount ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;   --R�ceptionne le montant solde
    vDetailId      ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;   --id de la position d�tail de solde cr��e
    vAmount_D      ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;   --Montant d�bit
    vAmount_C      ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;   --Montant Cr�dit
    vIsME          number;
  begin
    vIsME               := GetFinCurIDType(pFinCurId);

    if pFirstBreakdown then
      open FirstReportBalance(pDivAccId, pFinCurId, vIsME, pMethodCumulType, pExerciseNum, pPerStartNum);

      fetch FirstReportBalance
       into vBalanceAmount;

      close FirstReportBalance;
    else
      open PreviousBalanceCursor(pFinAccId, pDivAccId, pFinCurID, pMethodId, pFinYearId);

      fetch PreviousBalanceCursor
       into vBalanceAmount;

      close PreviousBalanceCursor;

      if vBalanceAmount is null then
        open ImputationBalance(pDivAccId, pFinCurId, vIsME, pMethodCumulType, pExerciseNum, pPerStartNum);

        fetch ImputationBalance
         into vBalanceAmount;

        close ImputationBalance;

        if vBalanceAmount is null then
          open FirstImputationBalance(pDivAccId, pFinCurId, vIsME, pMethodCumulType, pExerciseNum, pPerStartNum);

          fetch FirstImputationBalance
           into vBalanceAmount;

          close FirstImputationBalance;
        end if;
      end if;
    end if;

    CalculationBalance  := 0;
    vAmount_D           := 0;
    vAmount_C           := 0;

    if sign(vBalanceAmount) = 1 then
      vAmount_D           := abs(vBalanceAmount);
      CalculationBalance  := vBalanceAmount;
    elsif sign(vBalanceAmount) = -1 then
      vAmount_C           := abs(vBalanceAmount);
      CalculationBalance  := vBalanceAmount;
    end if;

    vDetailId           :=
      CreateDetPosition(null   --Imputation financi�re
                      , pJobId   --Travail comptable
                      , pFinAccId   --Compte financier de la m�thode
                      , pDivAccId   --Compte division g�r�(s)
                      , pFinCurId   -- Monnaie comptable
                      , pPerStartDate   --Date valeur
                      , null   --Date transaction
                      , vAmount_D   --Montant d�bit
                      , vAmount_C   --Montant cr�dit
                      , 0   --Solde
                      , 0   --Taux int�r�t d�bit
                      , 0   --Taux int�r�t cr�dit
                      , 0   --Nombre de jours d�bit
                      , 0   --Nombre de jours cr�dit
                      , 0   --Nombre d�bit
                      , 0   --Nombre cr�dit
                       );
  end CreateBalancePosition;

-----------------------------------------------------------------------------------------------------------------------
  function InterestDetImputation(
    pJobId           ACT_JOB.ACT_JOB_ID%type
  , pDivAccId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurId        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , pPerStartDate    ACS_PERIOD.PER_START_DATE%type
  , pPerEndNum       ACS_PERIOD.PER_NO_PERIOD%type
  , pPerEndDate      ACS_PERIOD.PER_END_DATE%type
  , pMethodCumulType varchar2
  , pIntCalcMethodId ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type
  , pIntCategoryId   ACS_INTEREST_CATEG.ACS_INTEREST_CATEG_ID%type
  )
    return ACS_PERIOD.PER_START_DATE%type
  is
    /*S�lection des imputations financi�res
      Avec comptes divisions null (si PAS de division g�r�s) ou
        comptes divisions correspondants � ceux de la m�thode (si division g�r�s)
      Avec monnaie null ( en MB) ou
        avec monnaie correspondante � celle de la m�thode
      Dont num.exercice + num.P�riode de la date de transaction <= num.exercice + num.P�riode de fin de calcul
      Dont Date Valeur <= Date fin de la p�riode de fin de calcul
      Avec types de cumul correspondants � ceux de la m�thode
      Qui n'existent pas d�j� dans D�tail int�r�t
      pour les p�riodes de type 2
      + les montants de report o� le type de p�riode = report

      ou si c'est le premier d�compte d'int�r�t pour le couple compte-division-monnaie,
        rechercher les �critures � partir du premier jour de l'exercice comptable sur la date de transaction
    */
    cursor ImputationCursor(
      pDivAccId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
    , pFinCurId        ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    , pExerciseNum     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
    , pPerEndNum       ACS_PERIOD.PER_NO_PERIOD%type
    , pPerEndDate      ACS_PERIOD.PER_END_DATE%type
    , pMethodCumulType varchar2
    )
    is
      select   V.*
          from V_ACT_ACC_IMP_REPORT V
         where (    (    ExistDivision = 0
                     and V.ACS_DIVISION_ACCOUNT_ID is null)
                or (    ExistDivision <> 0
                    and pDivAccId is not null
                    and V.ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                or (pDivAccId is null)
               )
           and (    (pFinCurId is null)
                or (    pFinCurId is not null
                    and V.ACS_FINANCIAL_CURRENCY_ID = pFinCurId) )
           and to_number(ACS_FUNCTION.GETFINANCIALYEARNO(V.IMF_TRANSACTION_DATE) ||
                         lpad(ACS_FUNCTION.GETPERIODNO(V.IMF_TRANSACTION_DATE, 2), 9, '0')
                        ) <= to_number(pExerciseNum || lpad(pPerEndNum, 9, '0') )
           and V.IMF_VALUE_DATE <= pPerEndDate
           and instr(pMethodCumulType, V.C_TYPE_CUMUL) > 0
           and not exists(select 1
                            from ACT_INTEREST_DETAIL DET
                           where DET.ACT_FINANCIAL_IMPUTATION_ID = V.ACT_FINANCIAL_IMPUTATION_ID)
           and exists(select 1
                        from ACT_CALC_PERIOD CAL
                       where CAL.ACS_PERIOD_ID = V.ACS_PERIOD_ID
                        and CAL.ACS_INT_CALC_METHOD_ID = pIntCalcMethodId)
           and ACS_FUNCTION.GetPeriodType(V.ACS_PERIOD_ID) = 2
      order by V.IMF_VALUE_DATE
             , V.IMF_TRANSACTION_DATE
             , V.ACT_FINANCIAL_IMPUTATION_ID;

    vImputation   ImputationCursor%rowtype;
    vDetailId     ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;
    vPerStartDate ACS_PERIOD.PER_START_DATE%type;
    vIsME         number;
  begin
    vPerStartDate  := pPerStartDate;
    vIsME          := GetFinCurIDType(pFinCurId);

    open ImputationCursor(pDivAccId, pFinCurId, pExerciseNum, pPerEndNum, pPerEndDate, pMethodCumulType);

    fetch ImputationCursor
     into vImputation;

    while ImputationCursor%found loop
      vDetailId      :=
        CreateDetPosition(vImputation.ACT_FINANCIAL_IMPUTATION_ID   --Imputation financi�re
                        , pJobId   --Travail comptable
                        , vImputation.ACS_FINANCIAL_ACCOUNT_ID   --Compte financier de l'imputation
                        , vImputation.ACS_DIVISION_ACCOUNT_ID   --Compte division de l'imputation
                        , pFinCurId   -- Monnaie comptable
                        , vImputation.IMF_VALUE_DATE   --Date valeur
                        , vImputation.IMF_TRANSACTION_DATE   --Date transaction
                        , case
                            when vIsME = 1 then vImputation.IMF_AMOUNT_FC_D
                            else vImputation.IMF_AMOUNT_LC_D --Montant d�bit
                          end
                        , case
                            when vIsME = 1 then vImputation.IMF_AMOUNT_FC_C
                            else vImputation.IMF_AMOUNT_LC_C --Montant cr�dit
                          end
                        , 0   --Solde
                        , 0   --Taux int�r�t d�bit
                        , 0   --Taux int�r�t cr�dit
                        , 0   --Nombre de jours d�bit
                        , 0   --Nombre de jours cr�dit
                        , 0   --Nombre d�bit
                        , 0   --Nombre cr�dit
                         );
      InterestDetSimulation(pJobId
                          , vImputation.ACS_FINANCIAL_ACCOUNT_ID
                          , vImputation.ACS_DIVISION_ACCOUNT_ID
                          , pFinCurId
                          , vPerStartDate
                          , vImputation.IMF_VALUE_DATE
                          , pIntCategoryId
                           );
      vPerStartDate  := vImputation.IMF_VALUE_DATE;

      fetch ImputationCursor
       into vImputation;
    end loop;

    close ImputationCursor;

    return vPerStartDate;
  end InterestDetImputation;

-----------------------------------------------------------------------------------------------------------------------
  procedure InterestDetSimulation(
    pJobId         ACT_JOB.ACT_JOB_ID%type
  , pFinAccId      ACT_INTEREST_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId      ACT_INTEREST_DETAIL.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurId      ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
  , pDateFrom      ACS_PERIOD.PER_START_DATE%type
  , pDateTo        ACS_PERIOD.PER_START_DATE%type
  , pIntCategoryId ACS_INTEREST_CATEG.ACS_INTEREST_CATEG_ID%type
  )
  is
    /* S�lection des diff�rents taux  durant la p�riode consid�r�e*/
    cursor IntervalRateCursor
    is
      select   *
          from ACS_INTEREST_ELEM
         where C_INT_RATE_TYPE = decode(sign(CalculationBalance), 1, 1, 2)
           and IEL_VALID_FROM > pDateFrom
           and IEL_VALID_FROM < pDateTo
           and ACS_INTEREST_CATEG_ID = pIntCategoryId
      order by IEL_VALID_FROM asc;

    vIntervalRate IntervalRateCursor%rowtype;
    vDetailId     ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;

    /* Fonction de retour de la position existante pour le compte division financier et date valeur du changement de taux*/
    function ExistRatePosition(pReportDate ACS_PERIOD.PER_START_DATE%type)
      return boolean
    is
      vResult ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;
    begin
      begin
        select nvl(ACT_INTEREST_DETAIL_ID, 0)
          into vResult
          from ACT_INTEREST_DETAIL
         where trunc(IDE_VALUE_DATE) = trunc(pReportDate)
           and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
           and (    (    ExistDivision = 0
                     and ACS_DIVISION_ACCOUNT_ID is null)
                or (    ExistDivision <> 0
                    and not pDivAccId is null
                    and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                or (pDivAccId is null)
               )
           and (    (     (pFinCurId is null)
                     and ACS_FINANCIAL_CURRENCY_ID is null)
                or (    pFinCurId is not null
                    and nvl(ACS_FINANCIAL_CURRENCY_ID, 0) = pFinCurId)
               );
      exception
        when others then
          vResult  := 0;
      end;

      return(vResult <> 0);
    end ExistRatePosition;
  begin
    open IntervalRateCursor;

    fetch IntervalRateCursor
     into vIntervalRate;

    while IntervalRateCursor%found loop
      --Cr�ation simulation uniquement si pas de report � la m�me date
      if not ExistRatePosition(vIntervalRate.IEL_VALID_FROM) then
        vDetailId  :=
          CreateDetPosition(null   --Imputation financi�re
                          , pJobId   --Travail comptable
                          , pFinAccId   --Compte financier de l'imputation
                          , pDivAccId   --Compte division de l'imputation
                          , pFinCurId   --Monnaie comptable
                          , vIntervalRate.IEL_VALID_FROM   --Date valeur
                          , vIntervalRate.IEL_VALID_FROM   --Date transaction
                          , 0   --Montant d�bit
                          , 0   --Montant cr�dit
                          , 0   --Solde
                          , 0   --Taux int�r�t d�bit
                          , 0   --Taux int�r�t cr�dit
                          , 0   --Nombre de jours d�bit
                          , 0   --Nombre de jours cr�dit
                          , 0   --Nombre d�bit
                          , 0   --Nombre cr�dit
                           );
      end if;

      fetch IntervalRateCursor
       into vIntervalRate;
    end loop;
  end InterestDetSimulation;

-----------------------------------------------------------------------------------------------------------------------
  procedure InterestDetUpdate(
    pJobId             ACT_JOB.ACT_JOB_ID%type
  , pFinAccId          ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId          ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurID          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , pInterestCategory  ACS_INTEREST_CATEG.ACS_INTEREST_CATEG_ID%type
  , pStartPerStartDate ACS_PERIOD.PER_START_DATE%type
  , pEndPerEndDate     ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor InterestDetailCursor(
      pJobId    ACT_JOB.ACT_JOB_ID%type
    , pFinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
    , pDivAccId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
    , pFinCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    )
    is
      select   *
          from ACT_INTEREST_DETAIL
         where (    (    ExistDivision = 0
                     and ACS_DIVISION_ACCOUNT_ID is null)
                or (    ExistDivision <> 0
                    and not pDivAccId is null
                    and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
                or (pDivAccId is null)
               )
           and (    (     (pFinCurID is null)
                     and ACS_FINANCIAL_CURRENCY_ID is null)
                or (     (pFinCurId is not null)
                    and ACS_FINANCIAL_CURRENCY_ID = pFinCurId)
               )
           and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
           and ACT_JOB_ID = pJobId
      order by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , nvl(ACS_FINANCIAL_CURRENCY_ID, 0)
             , IDE_VALUE_DATE
             , nvl(IDE_TRANSACTION_DATE, IDE_VALUE_DATE)
             , ACT_INTEREST_DETAIL_ID;

    vInterestDetail  InterestdetailCursor%rowtype;
    vRate_D          ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type;
    vRate_C          ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_C%type;
    vCurrentDetailId ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;
    vValueDate       ACT_INTEREST_DETAIL.IDE_VALUE_DATE%type;
    vDays_D          number;
    vDays_C          number;
    vBalanceAmount   ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;
    vDetailAmount    ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;
    vFinAccId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type;
    vDivAccId        ACT_INTEREST_DETAIL.ACS_DIVISION_ACCOUNT_ID%type;
    vFinCurID        ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type;
    vNbrD            number;
    vNbrC            number;
    vErrorCod        number;
    vAddOneDay       boolean;   --Indique l'ajout d'un jour suppl�mentaire
    vIsInterestImp   boolean;   --Indique si imputation provient d'un document de type "int�r�t"
    vValueDateTmp    ACT_INTEREST_DETAIL.IDE_VALUE_DATE%type;   --R�ceptionne la date valeur pour traitement temporaire
    vFirstDetail     boolean;   --Indique premier d�compte

    /**
    *  Fonction indique si l'imputation financi�re donn�e fait partie d'un document de type 5
    *  i.e si le document est un document de d�compte d'int�r�t
    **/
    function IsInterestDocument(pFinImputationId ACT_INTEREST_DETAIL.ACT_FINANCIAL_IMPUTATION_ID%type)
      return number
    is
      vResult number;
    begin
      select count(IMP.ACT_FINANCIAL_IMPUTATION_ID)
        into vResult
        from ACT_FINANCIAL_IMPUTATION IMP
       where exists(
                  select 1
                    from ACT_FINANCIAL_IMPUTATION FIN
                   where FIN.ACT_FINANCIAL_IMPUTATION_ID = pFinImputationId
                     and IMP.ACT_DOCUMENT_ID = FIN.ACT_DOCUMENT_ID)
         and IMP.C_GENRE_TRANSACTION = '5';

      return vResult;
    end IsInterestDocument;

    /**
    *  Indique si la position de d�tail est le premier d�compte (toute p�riode confondue) du tuple Compte - Dvision - monnaie
    **/
    function IsAccountFirstDetail(
      pJobId    ACT_JOB.ACT_JOB_ID%type
    , pFinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
    , pDivAccId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
    , pFinCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
    )
      return number
    is
      vResult number;
    begin
      select nvl(max(ACT_INTEREST_DETAIL_ID), 0)
        into vResult
        from ACT_INTEREST_DETAIL
       where (    (    ExistDivision = 0
                   and ACS_DIVISION_ACCOUNT_ID is null)
              or (    ExistDivision <> 0
                  and not pDivAccId is null
                  and ACS_DIVISION_ACCOUNT_ID = pDivAccId)
              or (pDivAccId is null)
             )
         and (    (     (pFinCurId is null)
                   and ACS_FINANCIAL_CURRENCY_ID is null)
              or (    pFinCurId is not null
                  and ACS_FINANCIAL_CURRENCY_ID = pFinCurId)
             )
         and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
         and ACT_JOB_ID <> pJobId;

      return vResult;
    end IsAccountFirstDetail;
  begin
    /**
    * 1�) Parcours des d�tails pr�c�demment cr��s par groupe <Compte financier / division / monnaie>
    * ==> cod� par l'initalisation de la date valeur et du solde lors de changement de compte
    * 2�) Initialisation flag vAddOneDay  si le d�tail pr�c�dent est le report i.e signifie que la ligne en cours est la premi�re du groupe fin/div/cur
    *     Initalisation du flag vIsInterestImp pour les d�tails pr�c�dent la date de report
    * 3�) Mise � jour des taux D et C selon le cot� du montant report pour les dates pr�c�dent le report et selon le solde
    *     de la ligne pour les autres.
    * 4�) Calcul du nombre de jour D / C selon le cot� du montant solde (montant report)
    *           Pour les mouvement pr�c�dent le report : La date valeur est ramen� � la date report uniquement pour le calcul du jour
    *           Pour les mouvements suivant le report  : Ajout d'un jour suppl�mentaire pour la premi�re position.
    **/
    vBalanceAmount  := 0;
    vFinAccId       := 0;
    vDivAccId       := 0;
    vFinCurId       := 0;
    vAddOneDay      := false;
    vFirstDetail    := false;

    /**
    * Parcours des d�tails pr�c�demment cr��s par groupe <Compte financier / division / monnaie comptable>
    **/
    open InterestDetailCursor(pJobId, pFinAccId, pDivAccId, pFinCurId);

    fetch InterestDetailCursor
     into vInterestDetail;

    while InterestDetailCursor%found loop
      vDays_D           := 0;
      vDays_C           := 0;
      vNbrD             := 0;
      vNbrC             := 0;
      vRate_D           := 0;
      vRate_C           := 0;

      if    (vFinAccId <> vInterestDetail.ACS_FINANCIAL_ACCOUNT_ID)
         or (vDivAccId <> vInterestDetail.ACS_DIVISION_ACCOUNT_ID)
         or (vFinCurId <> nvl(vInterestDetail.ACS_FINANCIAL_CURRENCY_ID, 0) ) then
        vFinAccId       := vInterestDetail.ACS_FINANCIAL_ACCOUNT_ID;
        vDivAccId       := vInterestDetail.ACS_DIVISION_ACCOUNT_ID;
        vFinCurId       := nvl(vInterestDetail.ACS_FINANCIAL_CURRENCY_ID, 0);
        vValueDate      := null;
        vBalanceAmount  := 0;
        vFirstDetail    := IsAccountFirstDetail(pJobId, pFinAccId, pDivAccId, pFinCurId) = 0;
--         if vFirstDetail then
--           update ACT_INTEREST_DETAIL
--              set IDE_AMOUNT_LC_D = 0.0
--                , IDE_AMOUNT_LC_C = 0.0
--                , IDE_AMOUNT_FC_D = 0.0
--                , IDE_AMOUNT_FC_C = 0.0
--            where ACS_FINANCIAL_ACCOUNT_ID = vFinAccId
--              and ACS_DIVISION_ACCOUNT_ID = vDivAccId
--              and nvl(ACS_FINANCIAL_CURRENCY_ID, 0) = vFinCurId
--              and ACT_JOB_ID = pJobId
--              and ACT_FINANCIAL_IMPUTATION_ID is null;
--         end if;
      end if;

      /**
      *  Calcul du nombre de jour D / C selon le cot� du montant solde (montant report)
      *           Pour les mouvement pr�c�dent le report : La date valeur est ramen� � la date report uniquement pour le calcul du jour
      *           Pour les mouvements suivant le report  : Ajout d'un jour suppl�mentaire pour la premi�re position.
      **/
      if (vValueDate is not null) then
        if (vValueDate < pStartPerStartDate) then
          if vIsInterestImp then
            vValueDateTmp  := vValueDate;
            vValueDate     := pStartPerStartDate - 1;
          end if;

          if sign(CalculationBalance) = 1 then
            vDays_D  := GetDays(vValueDate, pStartPerStartDate - 1);
            vNbrD    := round(vDetailAmount * vDays_D / 100);
          elsif sign(CalculationBalance) = -1 then
            vDays_C  := GetDays(vValueDate, pStartPerStartDate - 1);
            vNbrC    := round(vDetailAmount * vDays_C / 100) *(-1);
          end if;

          if vIsInterestImp then
            vValueDate  := vValueDateTmp;
          end if;
        elsif(vValueDate <> vInterestDetail.IDE_VALUE_DATE) then
          if sign(vBalanceAmount) >= 0 then
            vDays_D  := GetDays(vValueDate, vInterestDetail.IDE_VALUE_DATE);

            if vAddOneDay then
              vDays_D     := vDays_D + 1;
              vAddOneDay  := false;
            end if;

            vNbrD    := abs(round(vBalanceAmount * vDays_D / 100) );
          elsif sign(vBalanceAmount) = -1 then
            vDays_C  := GetDays(vValueDate, vInterestDetail.IDE_VALUE_DATE);

            if vAddOneDay then
              vDays_C     := vDays_C + 1;
              vAddOneDay  := false;
            end if;

            vNbrC    := abs(round(vBalanceAmount * vDays_C / 100) );
          end if;
        end if;

        update ACT_INTEREST_DETAIL
           set IDE_DAYS_NBR_D = vDays_D
             , IDE_DAYS_NBR_C = vDays_C
             , IDE_NBR_D = vNbrD
             , IDE_NBR_C = vNbrC
         where ACT_INTEREST_DETAIL_ID = vCurrentDetailId;
      end if;

      /**
      * Initialisation flag vAddOneDay  si le d�tail est le report i.e signifie que lors du passage dans la boucle de calcul
      * du jour on traitera la premi�re ligne du groupe fin/div
      * Initalisation du flag vIsInterestImp pour les d�tails pr�c�dent la date de report
      **/
      vValueDate        := vInterestDetail.IDE_VALUE_DATE;
      vCurrentDetailId  := vInterestDetail.ACT_INTEREST_DETAIL_ID;

      if GetFinCurIdType(pFinCurId) = 1 then
        vDetailAmount  := vInterestDetail.IDE_AMOUNT_FC_D - vInterestDetail.IDE_AMOUNT_FC_C;
      else
        vDetailAmount  := vInterestDetail.IDE_AMOUNT_LC_D - vInterestDetail.IDE_AMOUNT_LC_C;
      end if;

      if not(     (vFirstDetail)
             and (vInterestDetail.ACT_FINANCIAL_IMPUTATION_ID is null) ) then
        vBalanceAmount  := vBalanceAmount + vDetailAmount;
      elsif     vFirstDetail
            and vInterestDetail.IDE_TRANSACTION_DATE is null -- Si null c'est un report, sinon c'est une simulation au changement de taux
            and vInterestDetail.ACT_FINANCIAL_IMPUTATION_ID is null then   -- Ligne report premier d�compte d'int�r�t pour un compte (premier d�compte en 2007 alors qu'il existe des �critures dans les exercices pr�c�dants)
        vBalanceAmount  := vDetailAmount;
      end if;

      if (vValueDate < pStartPerStartDate) then
        vIsInterestImp  := IsInterestDocument(vInterestDetail.ACT_FINANCIAL_IMPUTATION_ID) <> 0;
      end if;

      if vInterestDetail.IDE_TRANSACTION_DATE is null then
        vAddOneDay  := true;
      end if;

      /**
      *  Mise � jour des taux D et C selon le cot� du montant report pour les dates pr�c�dent le report et selon le solde
      *  de la ligne pour les autres.
      **/
      if     (vValueDate <= pStartPerStartDate - 1)
         and (not vInterestDetail.IDE_TRANSACTION_DATE is null) then
        if sign(CalculationBalance) = 1 then
          vRate_D  := ACT_INTEREST.GetInterestRate(pInterestCategory, vInterestDetail.IDE_VALUE_DATE, 1, vErrorCod);
        elsif sign(CalculationBalance) = -1 then
          vRate_C  := ACT_INTEREST.GetInterestRate(pInterestCategory, vInterestDetail.IDE_VALUE_DATE, 2, vErrorCod);
        end if;
      else
        if sign(vBalanceAmount) = 1 then
          vRate_D  := ACT_INTEREST.GetInterestRate(pInterestCategory, vInterestDetail.IDE_VALUE_DATE, 1, vErrorCod);
        elsif sign(vBalanceAmount) = -1 then
          vRate_C  := ACT_INTEREST.GetInterestRate(pInterestCategory, vInterestDetail.IDE_VALUE_DATE, 2, vErrorCod);
        end if;
      end if;

      update ACT_INTEREST_DETAIL
         set IDE_BALANCE_AMOUNT = vBalanceAmount
           , IDE_INTEREST_RATE_D = decode(vErrorCod, 0, vRate_D, null)
           , IDE_INTEREST_RATE_C = decode(vErrorCod, 0, vRate_C, null)
           , A_RECLEVEL = decode(vErrorCod, 0, null, vErrorCod)
       where ACT_INTEREST_DETAIL_ID = vInterestDetail.ACT_INTEREST_DETAIL_ID;

      fetch InterestDetailCursor
       into vInterestDetail;
    end loop;

    vDays_D         := 0;
    vDays_C         := 0;
    vNbrD           := 0;
    vNbrC           := 0;

    /**
    *  Calcul du nombre de jour D / C selon le cot� du montant solde (montant report)
    *           Pour les mouvement pr�c�dent le report : La date valeur est ramen� � la date report uniquement pour le calcul du jour
    *           Pour les mouvements suivant le report  : Ajout d'un jour suppl�mentaire pour la premi�re position.
    **/
    if (vValueDate < pStartPerStartDate - 1) then
      if vIsInterestImp then
        vValueDateTmp  := vValueDate;
        vValueDate     := pStartPerStartDate;
      end if;

      if sign(CalculationBalance) = 1 then
        vDays_D  := GetDays(vValueDate, pEndPerEndDate);
        vNbrD    := round(vDetailAmount * vDays_D / 100);
      elsif sign(CalculationBalance) = -1 then
        vDays_C  := GetDays(vValueDate, pEndPerEndDate);
        vNbrC    := round(vDetailAmount * vDays_C / 100) *(-1);
      end if;

      if vIsInterestImp then
        vValueDate  := vValueDateTmp;
      end if;
    else
      if sign(vBalanceAmount) >= 0 then
        vDays_D  := GetDays(vValueDate, pEndPerEndDate);

        if vAddOneDay then
          vDays_D     := vDays_D + 1;
          vAddOneDay  := false;
        end if;

        vNbrD    := abs(round(vBalanceAmount * vDays_D / 100) );
      elsif sign(vBalanceAmount) = -1 then
        vDays_C  := GetDays(vValueDate, pEndPerEndDate);

        if vAddOneDay then
          vDays_C     := vDays_C + 1;
          vAddOneDay  := false;
        end if;

        vNbrC    := abs(round(vBalanceAmount * vDays_C / 100) );
      end if;
    end if;

    update ACT_INTEREST_DETAIL
       set IDE_DAYS_NBR_D = vDays_D
         , IDE_DAYS_NBR_C = vDays_C
         , IDE_NBR_D = vNbrD
         , IDE_NBR_C = vNbrC
     where ACT_INTEREST_DETAIL_ID = vCurrentDetailId;

    close InterestDetailCursor;
  end InterestDetUpdate;

-----------------------------------------------------------------------------------------------------------------------
  function GetMethodCumulType(pIntCalcMethodId ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type)
    return varchar2
  is
    /*Recherche des types de cumul de la m�thode de calcul*/
    cursor CumulTypeCursor(pIntCalcMethodId ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type)
    is
      select C_TYPE_CUMUL
        from ACS_CALC_CUMUL_TYPE
       where ACS_INT_CALC_METHOD_ID = pIntCalcMethodId;

    vCalcCumulType   CumulTypeCursor%rowtype;   --Variable de r�ception des enregistrements du curseur
    vMethodCumulType varchar2(100);   --R�ceptionne les types de cumul g�r�s
  begin
    /*R�ception des type de cumul de la m�thode de calcul*/
    vMethodCumulType  := '';

    open CumulTypeCursor(pIntCalcMethodId);

    fetch CumulTypeCursor
     into vCalcCumulType;

    while CumulTypeCursor%found loop
      vMethodCumulType  := vMethodCumulType || vCalcCumulType.C_TYPE_CUMUL || ',';

      fetch CumulTypeCursor
       into vCalcCumulType;
    end loop;

    close CumulTypeCursor;

    return vMethodCumulType;
  end GetMethodCumulType;

-----------------------------------------------------------------------------------------------------------------------
  function GetDays(pBeginDate ACS_PERIOD.PER_START_DATE%type, pEndDate ACS_PERIOD.PER_START_DATE%type)
    return number
  is
    vBeginDateMonth        number;   --R�ceptionne le mois de la date de d�but
    vEndDateMonth          number;   --R�ceptionne le mois de la date de fin
    vBeginDateDay          number;   --R�ception le jour de la date de d�but
    vEndDateDay            number;   --R�ception le jour de la date de fin
    vBeginDateMonthLastDay number;   --R�ception le dernier jour du mois de la date de d�but
    vEndDateMonthLastDay   number;   --R�ception le dernier jour du mois de la date de fin
    vBeginDateYear         number;
    vEndDateYear           number;
    vBegin                 ACS_PERIOD.PER_START_DATE%type;
    vEnd                   ACS_PERIOD.PER_START_DATE%type;
    vDays                  number;   --R�ceptionne le nombre de jours calcul� entre date d�but et fin
  begin
    select to_number(to_char(pBeginDate, 'MM') )
         , to_number(to_char(pEndDate, 'MM') )
         , to_number(to_char(pBeginDate, 'DD') )
         , to_number(to_char(pEndDate, 'DD') )
         , to_number(to_char(last_day(pBeginDate), 'DD') )
         , to_number(to_char(last_day(pEndDate), 'DD') )
         , to_number(to_char(pBeginDate, 'YYYY') )
         , to_number(to_char(pEndDate, 'YYYY') )
      into vBeginDateMonth
         , vEndDateMonth
         , vBeginDateDay
         , vEndDateDay
         , vBeginDateMonthLastDay
         , vEndDateMonthLastDay
         , vBeginDateYear
         , vEndDateYear
      from dual;

    --Force le nb de jours � 30 si date = dernier jour du mois
    if (vBeginDateDay = vBeginDateMonthLastDay) then
      vBeginDateDay  := 30;
    end if;

    if (vEndDateDay = vEndDateMonthLastDay) then
      vEndDateDay  := 30;
    end if;

    -- date d�but et date fin sont dans le m�me mois
    if     (vBeginDateMonth = vEndDateMonth)
       and (vBeginDateYear = vEndDateYear) then
      vDays  := vEndDateDay - vBeginDateDay;
    else
      --                             |           nombre de jours par mois complet s�parant les deux dates                |
      --       |jours du mois d�but  | |mois complet s�parant les 2 dates  |   |12 mois par ann�e de diff�rence    |     |jours du mois fin|
      vDays  :=
        30 -
        vBeginDateDay +
        ( ( (vEndDateMonth - vBeginDateMonth) - 1 +( (vEndDateYear - vBeginDateYear) * 12) ) * 30) +
        vEndDateDay;
    end if;

    return vDays;
  end GetDays;

-----------------------------------------------------------------------------------------------------------------------
  function GetAdvTaxRate(
    pInterestCategory ACS_INTEREST_CATEG.ACS_INTEREST_CATEG_ID%type
  , pRefDate          ACT_INTEREST_DETAIL.IDE_VALUE_DATE%type
  )
    return ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type
  is
    vRate ACS_ADV_TAX_ELEM.ATE_ADV_TAX_RATE%type;
  begin
    begin
      select decode(result.ATE_ADV_TAX_RATE, null, 0, result.ATE_ADV_TAX_RATE)
        into vRate
        from (select rownum num
                   , Rate.ATE_ADV_TAX_RATE
                from (select   nvl(ATE_ADV_TAX_RATE, 0) ATE_ADV_TAX_RATE
                          from ACS_ADV_TAX_ELEM
                         where ACS_INTEREST_CATEG_ID = pInterestCategory
                           and pRefDate >= ATE_VALID_FROM
                      order by ATE_VALID_FROM desc) Rate) result
       where num = 1;
    exception
      when no_data_found then
        vRate  := 0;
    end;

    return vRate;
  end;

-----------------------------------------------------------------------------------------------------------------------
  function GetInterestRate(
    pInterestCategory        ACS_INTEREST_CATEG.ACS_INTEREST_CATEG_ID%type
  , pRefDate                 ACT_INTEREST_DETAIL.IDE_VALUE_DATE%type
  , pType                    ACS_INTEREST_ELEM.C_INT_RATE_TYPE%type
  , pErrorCod         in out number
  )
    return ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type
  is
    vRate ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type;
  begin
    pErrorCod  := 0;

    begin
      select decode(result.IEL_APPLIED_RATE, null, 0, result.IEL_APPLIED_RATE)
        into vRate
        from (select rownum num
                   , Rate.IEL_APPLIED_RATE
                from (select   nvl(IEL_APPLIED_RATE, 0) IEL_APPLIED_RATE
                          from ACS_INTEREST_ELEM
                         where ACS_INTEREST_CATEG_ID = pInterestCategory
                           and pRefDate >= IEL_VALID_FROM
                           and C_INT_RATE_TYPE = pType
                      order by IEL_VALID_FROM desc) Rate) result
       where num = 1;
    exception
      when no_data_found then
        pErrorCod  := pType;
        vRate      := 0;
    end;

    return vRate;
  end GetInterestRate;

-----------------------------------------------------------------------------------------------------------------------
  procedure GetElementDefaultAccount(
    pMethodId           ACS_INT_CALC_METHOD.ACS_INT_CALC_METHOD_ID%type
  , pFinAccId           ACT_INTEREST_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type   --Compte financier
  , pDivAccId           ACT_INTEREST_DETAIL.ACS_DIVISION_ACCOUNT_ID%type   --Compte Division
  , pFinCurId           ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type   -- Monnaie comptable
  , pIntAccId    in out ACS_INT_CALC_METHOD.ACS_INTEREST_ACC_ID%type   --Comptes/d�faut Imputation int�r�ts
  , pIntAccId_D  in out ACS_INT_CALC_METHOD.ACS_ASSETS_INT_ACC_ID%type   --Comptes/d�faut Imputation int�r�ts actif
  , pIntAccId_C  in out ACS_INT_CALC_METHOD.ACS_LIABIL_INT_ACC_ID%type   --Comptes/d�faut Imputation int�r�ts passif
  , pIntAccId_T  in out ACS_INT_CALC_METHOD.ACS_ADV_TAX_ACC_ID%type   --Comptes/d�faut Imputation imp�t anticip�
  , pIntCategory in out ACS_METHOD_ELEM.ACS_INTEREST_CATEG_ID%type
  )
  is
  begin
    --R�ception des comptes d'imputation des �l�ments de m�thode.
    --Si pas d'en-t�te de compte /d�faut de l'�l�ment on retourne le param�tre d'entr�e
    select nvl(decode(ELE.ACS_INTEREST_ACC_ID, null, pIntAccId, ELE.ACS_INTEREST_ACC_ID), 0)
         , nvl(decode(ELE.ACS_ASSETS_INT_ACC_ID, null, pIntAccId_D, ELE.ACS_ASSETS_INT_ACC_ID), 0)
         , nvl(decode(ELE.ACS_LIABIL_INT_ACC_ID, null, pIntAccId_C, ELE.ACS_LIABIL_INT_ACC_ID), 0)
         , nvl(decode(MEL_ADV_TAX_SUBJECT
                    , 1, decode(ELE.ACS_ADV_TAX_ACC_ID, null, pIntAccId_T, ELE.ACS_ADV_TAX_ACC_ID)
                    , -1
                     )
             , 0
              )
         , ACS_INTEREST_CATEG_ID
      into pIntAccId
         , pIntAccId_D
         , pIntAccId_C
         , pIntAccId_T
         , pIntCategory
      from ACS_METHOD_ELEM ELE
     where ACS_INT_CALC_METHOD_ID = pMethodId
       and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
       and (    (ACS_DIVISION_ACCOUNT_ID = pDivAccId)
            or (ACS_DIVISION_ACCOUNT_ID is null) )
       and (    (     (pFinCurId is null)
                 and ACS_FINANCIAL_CURRENCY_ID is null)
            or (    pFinCurId is not null
                and ACS_FINANCIAL_CURRENCY_ID = pFinCurId)
           );
  end GetElementDefaultAccount;

-----------------------------------------------------------------------------------------------------------------------
  function CreateDetPosition(
    pFinImputationId ACT_INTEREST_DETAIL.ACT_FINANCIAL_IMPUTATION_ID%type
  , pJobId           ACT_INTEREST_DETAIL.ACT_JOB_ID%type
  , pFinAccId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId        ACT_INTEREST_DETAIL.ACS_DIVISION_ACCOUNT_ID%type
  , pFinCurId        ACT_INTEREST_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
  , pValueDate       ACT_INTEREST_DETAIL.IDE_VALUE_DATE%type
  , pTransactionDate ACT_INTEREST_DETAIL.IDE_TRANSACTION_DATE%type
  , pAmountD         ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_D%type
  , pAmountC         ACT_INTEREST_DETAIL.IDE_AMOUNT_LC_C%type
  , pBalance         ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type
  , pRateD           ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_D%type
  , pRateC           ACT_INTEREST_DETAIL.IDE_INTEREST_RATE_C%type
  , pDaysD           ACT_INTEREST_DETAIL.IDE_DAYS_NBR_D%type
  , pDaysC           ACT_INTEREST_DETAIL.IDE_DAYS_NBR_C%type
  , pNumberD         ACT_INTEREST_DETAIL.IDE_NBR_D%type
  , pNumberC         ACT_INTEREST_DETAIL.IDE_NBR_C%type
  )
    return ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type
  is
    vNewId ACT_INTEREST_DETAIL.ACT_INTEREST_DETAIL_ID%type;
    vIsME  number;
  begin
    select init_id_seq.nextval
      into vNewId
      from dual;

    vIsME  := GetFinCurIdType(pFinCurId);

    insert into ACT_INTEREST_DETAIL
                (ACT_INTEREST_DETAIL_ID
               , ACT_FINANCIAL_IMPUTATION_ID   --Imputation financi�re
               , ACT_JOB_ID   --Travail comptable
               , ACS_FINANCIAL_ACCOUNT_ID   --Compte financier
               , ACS_DIVISION_ACCOUNT_ID   --Compte division
               , ACS_FINANCIAL_CURRENCY_ID   -- Monnaie comptable
               , IDE_VALUE_DATE   --Date valeur
               , IDE_TRANSACTION_DATE   --Date transaction
               , IDE_AMOUNT_LC_D   --Montant d�bit
               , IDE_AMOUNT_LC_C   --Montant cr�dit
               , IDE_AMOUNT_FC_D   --Montant d�bit ME
               , IDE_AMOUNT_FC_C   --Montant cr�dit ME
               , IDE_BALANCE_AMOUNT   --Solde
               , IDE_INTEREST_RATE_D   --Taux int�r�t d�bit
               , IDE_INTEREST_RATE_C   --Taux int�r�t cr�dit
               , IDE_DAYS_NBR_D   --Nombre de jours d�bit
               , IDE_DAYS_NBR_C   --Nombre de jours cr�dit
               , IDE_NBR_D   --Nombre d�bit
               , IDE_NBR_C   --Nombre cr�dit
               , A_DATECRE
               , A_IDCRE
                )
         values (vNewId
               , pFinImputationId
               , pJobId
               , pFinAccId
               , pDivAccId
               , pFinCurId
               , pValueDate
               , pTransactionDate
               , decode(vIsME, 1, 0, pAmountD)
               , decode(vIsME, 1, 0, pAmountC)
               , decode(vIsME, 1, pAmountD, 0)
               , decode(vIsME, 1, pAmountC, 0)
               , pBalance
               , pRateD
               , pRateC
               , pDaysD
               , pDaysC
               , pNumberD
               , pNumberC
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return vNewId;
  end CreateDetPosition;

-----------------------------------------------------------------------------------------------------------------------
  procedure DeleteInterestDetail(pJobId ACT_JOB.ACT_JOB_ID%type)
  is
  begin
    delete from ACT_INTEREST_DETAIL
          where ACT_JOB_ID = pJobId;

    delete from ACT_CALC_PERIOD
          where ACT_JOB_ID = pJobId;
  end DeleteInterestDetail;

-----------------------------------------------------------------------------------------------------------------------
  procedure DeleteNullDetPosition(pJobId ACT_JOB.ACT_JOB_ID%type)
  is
  begin
    delete from ACT_INTEREST_DETAIL
          where ACT_JOB_ID = pJobId
            and ACT_FINANCIAL_IMPUTATION_ID is null
            and IDE_AMOUNT_LC_C = 0
            and IDE_AMOUNT_LC_D = 0
            and nvl(IDE_AMOUNT_FC_C, 0) = 0
            and nvl(IDE_AMOUNT_FC_D, 0) = 0
            and IDE_NBR_D = 0
            and IDE_NBR_C = 0;
  end DeleteNullDetPosition;

-----------------------------------------------------------------------------------------------------------------------
  procedure UpdateDocAmount(pDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
    vAmountLCD ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    vAmountLCC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    vAmountFCD ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    vAmountFCC ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type;
    vDocAmount ACT_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
  begin
    select nvl(max(IMF_AMOUNT_LC_D), 0)
         , nvl(max(IMF_AMOUNT_LC_C), 0)
         , nvl(max(IMF_AMOUNT_FC_D), 0)
         , nvl(max(IMF_AMOUNT_FC_C), 0)
      into vAmountLCD
         , vAmountLCC
         , vAmountFCD
         , vAmountFCC
      from ACT_FINANCIAL_IMPUTATION
     where ACT_DOCUMENT_ID = pDocumentId
       and IMF_PRIMARY + 0 = 1;

    if vAmountFCD <> 0 then
      vDocAmount  := vAmountFCD;
    elsif vAmountFCC <> 0 then
      vDocAmount  := vAmountFCC;
    elsif vAmountLCD <> 0 then
      vDocAmount  := vAmountLCD;
    else
      vDocAmount  := vAmountLCC;
    end if;

    update ACT_DOCUMENT
       set DOC_TOTAL_AMOUNT_DC = vDocAmount
     where ACT_DOCUMENT_ID = pDocumentId;
  end UpdateDocAmount;

-----------------------------------------------------------------------------------------------------------------------
  function GetInterestBalanceAmount(
    pJobId    ACT_JOB.ACT_JOB_ID%type
  , pFinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , pType     number
  )
    return ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type
  is
    cursor InterestDetail
    is
      select   IDE_BALANCE_AMOUNT
          from ACT_INTEREST_DETAIL
         where ACT_JOB_ID = pJobId
           and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
           and (   ACS_DIVISION_ACCOUNT_ID = pDivAccId
                or pDivAccId is null)
      order by IDE_VALUE_DATE desc
             , nvl(IDE_TRANSACTION_DATE, IDE_VALUE_DATE) desc
             , nvl(ACT_FINANCIAL_IMPUTATION_ID, 0) desc;

    vAmount ACT_INTEREST_DETAIL.IDE_BALANCE_AMOUNT%type;
  begin
    if pType = 0 then
      open InterestDetail;

      fetch InterestDetail
       into vAmount;

      close InterestDetail;
    elsif pType = 1 then
      select nvl(sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
        into vAmount
        from V_ACT_INTEREST_DOCUMENT
       where ACT_JOB_ID = pJobId
         and ACS_FINANCIAL_ACCOUNT_ID = pFinAccId
         and (   ACS_DIVISION_ACCOUNT_ID = pDivAccId
              or pDivAccId is null);
    end if;

    return vAmount;
  end GetInterestBalanceAmount;

-----------------------------------------------------------------------------------------------------------------------
  function GetFinCurIDType(pFinCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type)
    return number
  is
  begin
    -- Lorsque la monnaie �trang�re n'est pas renseign�e: retour -1 => prise en compte de TOUS les montants MB
    -- Lorsque la monnaie �trang�re est la monnaie de base: retour 0 => prise en compte des montants MB pour la monnaie de base
    -- Lorsque la monnaie �tang�re est renseign�e et <> de la monnaie de base: retour 1 => prise en compte des montants ME pour la monnaie �trang�re
    if pFinCurId is null then
      return -1;
    elsif ACS_FUNCTION.GetLocalCurrencyID = pFinCurId then
      return 0;
    else
      return 1;
    end if;
  end GetFinCurIDType;
/**********************************************************************************************************************/
begin
  CalculationBalance  := 0;
  Analytical          := 0;

  begin
    select ACS_SUB_SET_ID
      into ExistDivision
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';
  exception
    when no_data_found then
      ExistDivision  := 0;
  end;
end ACT_INTEREST;
