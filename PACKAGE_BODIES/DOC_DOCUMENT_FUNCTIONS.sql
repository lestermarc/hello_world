--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_FUNCTIONS" 
is
  /**
  * procedure pChangeDocumentCurrRate(
  * Description
  *    Procedure de correction du taux de change d'un document (recalcul des
  *    montants en monnaie de base)
  * @created fp 26.09.2007
  * @lastUpdate
  * @private
  * @param aDocumentId : Id du document à traiter
  * @param aDmtNumber : Numéro du document
  * @param aDocStatus : status du document
  * @param aDmtProtected : flag de protection
  * @param aDmtSessionId : Session ID de la session "protectrice"
  * @param aNewCurrRate : nouveaux taux de change
  * @param aNewBasePrice : nouveau diviseur
  * @param aAllowFinished : autorise de traiter un document liquidé (par défaut à False)
  *                         cela a pour effet de supprimer les documents financiers
  * @param aRateType : 0 : le taux des 2 monnaies, 1 : taux monnaie étrangère , 2 : taux monnaie TVA
  */
  procedure pChangeDocumentCurrRate(
    aDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDmtNumber     in DOC_DOCUMENT.DMT_NUMBER%type
  , aDocStatus     in DOC_DOCUMENT.C_DOCUMENT_STATUS%type
  , aDmtProtected  in DOC_DOCUMENT.DMT_PROTECTED%type
  , aDmtSessionId  in DOC_DOCUMENT.DMT_SESSION_ID%type
  , aNewCurrRate   in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aNewBasePrice  in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAllowFinished in boolean default false
  , aRateType      in varchar2 default 1
  )
  is
    vModified number(1);
  begin
    -- controle que le document ne soit pas liquidé
    if     aDocStatus = '04'
       and not aAllowFinished then
      raise_application_error(-20000
                            , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document liquidé, traitement impossible : [DOCNO]'), '[DOCNO]', aDmtNumber) );
    elsif aDocStatus = '05' then
      raise_application_error(-20000, replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document effacé, traitement impossible : [DOCNO]'), '[DOCNO]', aDmtNumber) );
    end if;

    -- contrôle que le document ne soit pas protégé
    if     aDmtProtected = 1
       and aDmtSessionId is not null
       and (aDmtSessionId <> DBMS_SESSION.unique_session_id)
       and (COM_FUNCTIONS.IS_SESSION_ALIVE(aDmtSessionId) = 1) then
      raise_application_error(-20000
                            , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document protégé ou en cours d''édition, traitement impossible : [DOCNO]')
                                    , '[DOCNO]'
                                    , aDmtNumber
                                     )
                             );
    else
      update DOC_DOCUMENT
         set DMT_PROTECTED = 1
           , DMT_RATE_OF_EXCHANGE = case
                                     when aRateType in(0, 1) then aNewCurrRate
                                     else DMT_RATE_OF_EXCHANGE
                                   end
           , DMT_BASE_PRICE = case
                               when aRateType in(0, 1) then aNewBasePrice
                               else DMT_BASE_PRICE
                             end
           , DMT_VAT_EXCHANGE_RATE = case
                                      when aRateType in(0, 2) then aNewCurrRate
                                      else DMT_VAT_EXCHANGE_RATE
                                    end
           , DMT_VAT_BASE_PRICE = case
                                   when aRateType in(0, 2) then aNewBasePrice
                                   else DMT_VAT_BASE_PRICE
                                 end
           , DMT_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
       where DOC_DOCUMENT_ID = aDocumentId;

      DOC_PRC_VAT.RemoveVatCorrectionAmount(aDocumentId, 1, 1, vModified);
    end if;

    -- Suppression des documents comptables
    if     aAllowFinished
       and aDocStatus = '04' then
      -- Effacement ACI_DOCUMENT
      delete from ACI_DOCUMENT
            where DOC_DOCUMENT_ID = aDocumentId;

      -- Effacement ACT_DOCUMENT
      delete from ACT_DOCUMENT
            where DOC_DOCUMENT_ID = aDocumentId;

      -- Réactiver le document
      DOC_FUNCTIONS.ReactiveDocument(aDocumentId);
    end if;

    -- Maj des flags pour le recalcul de tous les montants monnaie de base dans les tables liées au document
    -- Cours de change du document ne doit pas être réévalué car il vient d'être ci-haut avec l'update
    DOC_PRC_DOCUMENT.SetFlagsRateModified(iDocumentID => aDocumentID, iDocRevaluationRate => 0);
    -- Mise à jour des totaux
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, vModified);
    -- Reinitialisation des montants du document (report des nouveaux montants de taxe)
    DOC_DOCUMENT_FUNCTIONS.ReinitDocumentPrice(aDocumentId => aDocumentId, aReinitUnitPrice => 0);
  end pChangeDocumentCurrRate;

  /*
  * Description : Contrôle de la validation de la date du document
  */
  procedure ValidateDocumentDate(
    aDate       in     date
  , aCtrlType   in     varchar2
  , ErrorTitle  out    varchar2
  , ErrorMsg    out    varchar2
  , ConfirmFail out    varchar2
  , CtrlOK      out    integer
  )
  is
    PeriodExercise_List varchar2(2000);
  begin
    CtrlOK       := 1;
    ErrorTitle   := '';
    ErrorMsg     := '';
    ConfirmFail  := '';

    -- Type de contrôle
    --  0 : Date valide
    --  1 : Période FIN et LOG
    --  2 : Exercice FIN et LOG
    --  3 : Période LOG
    --  4 : Exercice LOG
    --  5 : Période FIN
    --  6 : Exercice FIN
    if aCtrlType = '0' then   -- Date Valide
      if    (aDate < to_date('01.01.1900', 'DD.MM.YYYY') )
         or (aDate > to_date('31.12.2199', 'DD.MM.YYYY') ) then
        ConfirmFail  := '106';
        ErrorTitle   := PCS.PC_FUNCTIONS.TranslateWord('Gestion comptable');
        ErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('La date document doit s''inscrire entre le 1.1.1900 et le 31.12.2199');
      end if;
    end if;

    if     (ConfirmFail is null)
       and (aCtrlType in('1', '3') ) then   -- Période LOG
      -- Ctrl Période LOG
      PeriodExercise_List  := DateInActivePeriod(aDate, 'LOG');

      -- Pas dans Période LOG
      if PeriodExercise_List is not null then
        ConfirmFail  := '109';
        ErrorTitle   := PCS.PC_FUNCTIONS.TranslateWord('Gestion de stock');
        ErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('La date document doit s''inscrire dans une période active !') || PeriodExercise_List;
      end if;
    end if;

    if     (ConfirmFail is null)
       and (aCtrlType in('1', '5') ) then   -- Période FIN
      -- Ctrl Période FIN
      PeriodExercise_List  := DateInActivePeriod(aDate, 'FIN');

      -- Pas dans Période FIN
      if PeriodExercise_List is not null then
        ConfirmFail  := '110';
        ErrorTitle   := PCS.PC_FUNCTIONS.TranslateWord('Gestion comptable');
        ErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('La date document doit s''inscrire dans une période active !') || PeriodExercise_List;
      end if;
    end if;

    if     (ConfirmFail is null)
       and (aCtrlType in('2', '4') ) then   -- Exercice LOG
      -- Ctrl Exercice LOG
      PeriodExercise_List  := DateInActiveExercise(aDate, 'LOG');

      -- Pas dans Exercice LOG
      if PeriodExercise_List is not null then
        ConfirmFail  := '107';
        ErrorTitle   := PCS.PC_FUNCTIONS.TranslateWord('Gestion de stock');
        ErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('La date document doit s''inscrire dans un exercice actif !') || PeriodExercise_List;
      end if;
    end if;

    if     (ConfirmFail is null)
       and (aCtrlType in('2', '6') ) then   -- Exercice FIN
      -- Ctrl Exercice FIN
      PeriodExercise_List  := DateInActiveExercise(aDate, 'FIN');

      -- Pas dans Exercice FIN
      if PeriodExercise_List is not null then
        ConfirmFail  := '108';
        ErrorTitle   := PCS.PC_FUNCTIONS.TranslateWord('Gestion comptable');
        ErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('La date document doit s''inscrire dans un exercice actif !') || PeriodExercise_List;
      end if;
    end if;

    if ConfirmFail is not null then
      CtrlOK  := 0;
    end if;
  end ValidateDocumentDate;

  /*
  * Description : Contrôle si la date est dans une période active (FIN ou LOG)
  */
  function DateInActivePeriod(aDate in date, aCtrlType in varchar2)
    return varchar2
  is
    cursor crLogPeriod(cDate date)
    is
      select   trunc(PER_STARTING_PERIOD) as PER_STARTING_PERIOD
             , trunc(PER_ENDING_PERIOD) as PER_ENDING_PERIOD
             , case
                 when trunc(cDate) between trunc(PER_STARTING_PERIOD) and trunc(PER_ENDING_PERIOD) then 1
                 else 0
               end IN_PERIOD
          from STM_PERIOD
         where C_PERIOD_STATUS = '02'
      order by IN_PERIOD desc
             , PER_STARTING_PERIOD;

    cursor crFinPeriod(cDate date)
    is
      select   trunc(PER_START_DATE) as PER_START_DATE
             , trunc(PER_END_DATE) as PER_END_DATE
             , case
                 when trunc(cDate) between trunc(PER_START_DATE) and trunc(PER_END_DATE) then 1
                 else 0
               end IN_PERIOD
          from ACS_PERIOD
         where C_STATE_PERIOD = 'ACT'
           and C_TYPE_PERIOD = '2'
      order by IN_PERIOD desc
             , PER_START_DATE;

    type tTable is table of varchar2(2000)
      index by binary_integer;

    PeriodList        varchar2(2000);
    tplLogPeriod      crLogPeriod%rowtype;
    tplFinPeriod      crFinPeriod%rowtype;
    i                 number;
    PeriodBeforeTable tTable;
    PeriodAfterTable  tTable;
  begin
    i  := 0;

    if aCtrlType = 'LOG' then
      -- Curseur sur les Péeriodes LOG
      open crLogPeriod(aDate);

      fetch crLogPeriod
       into tplLogPeriod;

      -- Périodes existantes
      if crLogPeriod%found then
        -- La date est dans une période active
        if tplLogPeriod.IN_PERIOD = 1 then
          PeriodList  := '';
        else   -- La date n'est PAS dans une période active
          PeriodList  := PeriodList || co.cLineBreak;

          -- Lister les périodes actives
          while crLogPeriod%found loop
            PeriodList  :=
              PeriodList ||
              co.cLineBreak ||
              to_char(tplLogPeriod.PER_STARTING_PERIOD, 'DD.MM.YYYY') ||
              ' / ' ||
              to_char(tplLogPeriod.PER_ENDING_PERIOD, 'DD.MM.YYYY');

            fetch crLogPeriod
             into tplLogPeriod;
          end loop;
        end if;
      else
        PeriodList  := PCS.PC_FUNCTIONS.TranslateWord('Aucune période existante');
      end if;

      close crLogPeriod;
    else
      -- Curseur sur les Périodes FIN
      open crFinPeriod(aDate);

      fetch crFinPeriod
       into tplFinPeriod;

      -- Periodes existantes
      if crFinPeriod%found then
        -- La date est dans une période active
        if tplFinPeriod.IN_PERIOD = 1 then
          PeriodList  := '';
        else   -- La date n'est PAS dans une période active
          PeriodList  := PeriodList || co.cLineBreak;

          -- Lister les périodes actives
          while crFinPeriod%found loop
            -- Stockage des périodes selon si elles sont avant ou après la date donnée
            if tplFinPeriod.PER_START_DATE < aDate then
              PeriodBeforeTable(PeriodBeforeTable.count)  :=
                                                 to_char(tplFinPeriod.PER_START_DATE, 'DD.MM.YYYY') || ' / '
                                                 || to_char(tplFinPeriod.PER_END_DATE, 'DD.MM.YYYY');
            else
              PeriodAfterTable(PeriodAfterTable.count)  :=
                                                 to_char(tplFinPeriod.PER_START_DATE, 'DD.MM.YYYY') || ' / '
                                                 || to_char(tplFinPeriod.PER_END_DATE, 'DD.MM.YYYY');
            end if;

            fetch crFinPeriod
             into tplFinPeriod;
          end loop;

          -- ajout des 6 périodes (au maximum) suivant la date donnée
          i           := PeriodAfterTable.first;

          loop
            exit when i is null
                  or i = 6;
            PeriodList  := PeriodList || PeriodAfterTable(i) || co.cLineBreak;
            i           := PeriodAfterTable.next(i);
          end loop;

          -- ajout des périodes précédant la date donnée
          i           := PeriodBeforeTable.last;

          loop
            if PeriodAfterTable.count >= 6 then
              exit when i is null
                    or (PeriodBeforeTable.last - i) = 6;
            else
              exit when i is null
                    or (PeriodBeforeTable.last - i) = 12 - PeriodAfterTable.count;
            end if;

            PeriodList  := co.cLineBreak || PeriodBeforeTable(i) || PeriodList;
            i           := PeriodBeforeTable.prior(i);
          end loop;
        end if;
      else
        PeriodList  := PCS.PC_FUNCTIONS.TranslateWord('Aucune période existante');
      end if;

      close crFinPeriod;
    end if;

    return PeriodList;
  end DateInActivePeriod;

  /*
  * Description : Contrôle si la date est dans un exercice actif (FIN ou LOG)
  */
  function DateInActiveExercise(aDate in date, aCtrlType in varchar2)
    return varchar2
  is
    cursor crLogExercise(cDate date)
    is
      select   trunc(EXE_STARTING_EXERCISE) as EXE_STARTING_EXERCISE
             , trunc(EXE_ENDING_EXERCISE) as EXE_ENDING_EXERCISE
             , case
                 when trunc(cDate) between trunc(EXE_STARTING_EXERCISE) and trunc(EXE_ENDING_EXERCISE) then 1
                 else 0
               end IN_EXERCISE
          from STM_EXERCISE
         where C_EXERCISE_STATUS = '02'
      order by IN_EXERCISE desc
             , EXE_STARTING_EXERCISE;

    cursor crFinExercise(cDate date)
    is
      select   trunc(FYE_START_DATE) as FYE_START_DATE
             , trunc(FYE_END_DATE) as FYE_END_DATE
             , case
                 when trunc(cDate) between trunc(FYE_START_DATE) and trunc(FYE_END_DATE) then 1
                 else 0
               end IN_EXERCISE
          from ACS_FINANCIAL_YEAR
         where C_STATE_FINANCIAL_YEAR = 'ACT'
      order by IN_EXERCISE desc
             , FYE_START_DATE;

    ExerciseList   varchar2(2000);
    tplLogExercise crLogExercise%rowtype;
    tplFinExercise crFinExercise%rowtype;
  begin
    if aCtrlType = 'LOG' then
      -- Curseur sur les Exercises LOG
      open crLogExercise(aDate);

      fetch crLogExercise
       into tplLogExercise;

      -- Exercises existants
      if crLogExercise%found then
        -- La date est dans un exercice actif
        if tplLogExercise.IN_EXERCISE = 1 then
          ExerciseList  := '';
        else   -- La date n'est PAS dans un exercice actif
          ExerciseList  := ExerciseList || co.cLineBreak;

          -- Lister les exercices actifs
          while crLogExercise%found loop
            ExerciseList  :=
              ExerciseList ||
              co.cLineBreak ||
              to_char(tplLogExercise.EXE_STARTING_EXERCISE, 'DD.MM.YYYY') ||
              ' / ' ||
              to_char(tplLogExercise.EXE_ENDING_EXERCISE, 'DD.MM.YYYY');

            fetch crLogExercise
             into tplLogExercise;
          end loop;
        end if;
      else
        ExerciseList  := PCS.PC_FUNCTIONS.TranslateWord('Aucun exercice existant');
      end if;

      close crLogExercise;
    else
      -- Curseur sur les Exercises FIN
      open crFinExercise(aDate);

      fetch crFinExercise
       into tplFinExercise;

      -- Exercises existants
      if crFinExercise%found then
        -- La date est dans un exercice actif
        if tplFinExercise.IN_EXERCISE = 1 then
          ExerciseList  := '';
        else   -- La date n'est PAS dans un exercice actif
          ExerciseList  := ExerciseList || co.cLineBreak;

          -- Lister les exercices actifs
          while crFinExercise%found loop
            ExerciseList  :=
              ExerciseList || co.cLineBreak || to_char(tplFinExercise.FYE_START_DATE, 'DD.MM.YYYY') || ' / '
              || to_char(tplFinExercise.FYE_END_DATE, 'DD.MM.YYYY');

            fetch crFinExercise
             into tplFinExercise;
          end loop;
        end if;
      else
        ExerciseList  := PCS.PC_FUNCTIONS.TranslateWord('Aucun exercice existant');
      end if;

      close crFinExercise;
    end if;

    return ExerciseList;
  end DateInActiveExercise;

  /**
  * Description
  *   Procedure de création des remise/taxes de type Groupe de bien
  *   et mise à jour des montants des positions modifiées
  */
  procedure CreateGroupChargeAndUpdatePos(aDocumentId in doc_document.doc_document_id%type, aForce in boolean default false)
  is
    cursor crPosToRecalc(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   POS.DOC_POSITION_ID
          from DOC_POSITION POS
         where POS.DOC_DOCUMENT_ID = cDocumentId
           and POS.POS_RECALC_AMOUNTS = 1
           and POS.POS_PARENT_CHARGE = 0
      order by POS_NUMBER;

    created              number(1);
    dateref              date;
    currencyId           ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    rateOfExchange       DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    basePrice            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    langId               DOC_DOCUMENT.PC_LANG_ID%type;
    mustUpdateFootCharge DOC_DOCUMENT.DMT_RECALC_FOOT_CHARGE%type;
  begin
    if PCS.PC_CONFIG.GetConfig('PTC_CUMULATIVE_DISCOUNT_CHARGE') = '1' then
      -- recherche d'infos sur le document
      select DMT_RECALC_FOOT_CHARGE
           , DMT_DATE_DOCUMENT
           , ACS_FINANCIAL_CURRENCY_ID
           , DMT_RATE_OF_EXCHANGE
           , DMT_BASE_PRICE
           , PC_LANG_ID
        into mustUpdateFootCharge
           , dateRef
           , currencyId
           , rateOfExchange
           , basePrice
           , langId
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentId;

      if mustUpdateFootCharge = 1 then
        -- Effacement des remises/taxes de type groupe, sur les positions
        -- dont les remises/taxes sont non déchargées
        delete from DOC_POSITION_CHARGE
              where DOC_DOCUMENT_ID = aDocumentID
                and DOC_POSITION_ID in(select DOC_POSITION_ID
                                         from DOC_POSITION
                                        where DOC_DOCUMENT_ID = aDocumentID
                                          and POS_PARENT_CHARGE = 0)
                and PCH_DISCHARGED = 0
                and PCH_CUMULATIVE = 1;

        -- création des remises/taxes de groupe
        DOC_DISCOUNT_CHARGE.CreateGroupPositionCharge(aDocumentId, dateref, currencyId, rateOfExchange, basePrice, langId, created);

        -- recalcul des montants des positions sur les positions touchées par les remises de groupe
        for tplPosToRecalc in crPosToRecalc(aDocumentId) loop
          DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(tplPosToRecalc.DOC_POSITION_ID, aForce);
        end loop;
      end if;
    end if;
  end CreateGroupChargeAndUpdatePos;

  /**
  * Description
  *   Force la recréation des remises/taxes de groupe et le recalcul des montants
  *   des positions et du total du document
  */
  procedure RedoGroupChargeAndUpdatePos(aDocumentId in doc_document.doc_document_id%type)
  is
  begin
    if PCS.PC_CONFIG.GetConfig('PTC_CUMULATIVE_DISCOUNT_CHARGE') = '1' then
      -- Enlève le lien indiquant que les remises/taxes ont été déchargées
      update DOC_POSITION_CHARGE
         set PCH_DISCHARGED = 0
       where DOC_DOCUMENT_ID = aDocumentId;

      -- Enlève le lien indiquant que les remises/taxes ont été déchargées
      update DOC_POSITION
         set POS_PARENT_CHARGE = 0
       where DOC_DOCUMENT_ID = aDocumentId;

      -- Force le recalcul des remises/taxes de pied
      update DOC_DOCUMENT
         set DMT_RECALC_FOOT_CHARGE = 1
       where DOC_DOCUMENT_ID = aDocumentId;

      CreateGroupChargeAndUpdatePos(aDocumentId);
    end if;
  end RedoGroupChargeAndUpdatePos;

  /**
  * Description
  *    Recalcul des remises/taxes et des montants des positions flaguées
  */
  procedure RecalcModifPosChargeAndAmount(aDocumentId in doc_document.doc_document_id%type, aForce in boolean default false)
  is
    cursor crPos2Recalc(cDocumentId doc_document.doc_document_id%type)
    is
      select DOC_POSITION_ID
        from DOC_POSITION
       where DOC_DOCUMENT_ID = cDocumentId
         and (   POS_CREATE_POSITION_CHARGE = 1
              or POS_UPDATE_POSITION_CHARGE = 1
              or POS_RECALC_AMOUNTS = 1);
  begin
    for tplPos2Recalc in crPos2Recalc(aDocumentId) loop
      DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(tplPos2Recalc.DOC_POSITION_ID, aForce);
    end loop;
  end RecalcModifPosChargeAndAmount;

  /**
  * Description
  *   Recalcul des montants des positions du document en fonction  de la date passée en paramètre (date document si vide)
  */
  procedure ReinitDocumentPrice(
    aDocumentId           in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDateSeek             in date default null
  , aReinitUnitPrice      in number default 1
  , aReInitPositionCharge in number default 0
  , aReInitFootCharge     in number default 0
  , aPartial              in number default 0
  , aFinalize             in number default 1
  , aHistoryId            in number default null
  )
  is
    -- liste des positions à traiter, les positions type 8 sont traitées en dernier
    cursor crPositions(aDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aPartial number)
    is
      select   POS.DOC_POSITION_ID
             , POS.DOC_DOC_POSITION_ID
          from DOC_POSITION POS
             , DOC_GAUGE GAU
         where POS.DOC_DOCUMENT_ID = aDocumentId
           and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
           and (   POS.C_DOC_POS_STATUS in('01', '02')
                or (    aPartial = 1
                    and POS.C_DOC_POS_STATUS = '03') )
           and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '81', '91', '10')
      order by decode(POS.C_GAUGE_TYPE_POS, '8', 'b' || C_GAUGE_TYPE_POS, 'a' || C_GAUGE_TYPE_POS);

    vParentTypPos DOC_POSITION.C_GAUGE_TYPE_POS%type;
    vDocStatus    DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    vDmtProtected DOC_DOCUMENT.DMT_PROTECTED%type;
    vDmtNumber    DOC_DOCUMENT.DMT_NUMBER%type;
    vDmtSessionId DOC_DOCUMENT.DMT_SESSION_ID%type;
    vModified     number(1);
  begin
    -- recherche status et vérification protection
    select C_DOCUMENT_STATUS
         , DMT_PROTECTED
         , DMT_SESSION_ID
         , DMT_NUMBER
      into vDocStatus
         , vDmtProtected
         , vDmtSessionId
         , vDmtNumber
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    -- controle que le document ne soit pas liquidé
    if vDocStatus = '04' then
      raise_application_error(-20000
                            , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document liquidé, traitement impossible : [DOCNO]'), '[DOCNO]', vDmtNumber) );
    end if;

    -- contrôle que le document ne soit pas protégé si on est en mode finalize
    if aFinalize = 1 then
      if     vDmtProtected = 1
         and (vDmtSessionId <> DBMS_SESSION.unique_session_id) then
        raise_application_error(-20000
                              , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Document protégé ou en cours d''édition, traitement impossible : [DOCNO]')
                                      , '[DOCNO]'
                                      , vDmtNumber
                                       )
                               );
      else
        update DOC_DOCUMENT
           set DMT_PROTECTED = 1
             , DMT_TARIFF_DATE = decode(aDateSeek, DMT_DATE_DOCUMENT, null, aDateSeek)
         where DOC_DOCUMENT_ID = aDocumentId
           and (vDmtSessionId <> DBMS_SESSION.unique_session_id);

        DOC_PRC_VAT.RemoveVatCorrectionAmount(aDocumentId, 1, 1, vModified);
      end if;
    end if;

    -- traitement des positions seulement si reacalcul des prix ou reinit des taxes
    if    (aReinitUnitPrice = 1)
       or (aReInitPositionCharge = 1) then
      -- traitement de chaque position liée à un bien
      for tplPosition in crPositions(aDocumentId, aPartial) loop
        -- si la position est un composant, recherche du type de position du parent
        if tplPosition.DOC_DOC_POSITION_ID is not null then
          select C_GAUGE_TYPE_POS
            into vParentTypPos
            from DOC_POSITION
           where DOC_POSITION_ID = tplPosition.DOC_DOC_POSITION_ID;
        else
          vParentTypPos  := '0';   -- signifie qu'il n'y a pas de position parent
        end if;

        -- Si le type de la position parent est 7 ou 10, alors on ne traite pas la position
        if vParentTypPos not in('7', '10') then
          DOC_POSITION_FUNCTIONS.ReInitPositionPrice(tplPosition.DOC_POSITION_ID
                                                   , aDateSeek
                                                   , aReinitUnitPrice
                                                   , aReinitPositionCharge
                                                   , aHistoryId
                                                   , 1   -- appel depuis la réinitialisation des documents
                                                    );
        end if;
      end loop;
    end if;

    -- Effacement des remises/taxes de pieds si le paramètre le demande
    if aReInitFootCharge = 1 then
      declare
        intDMT_DISCH_FCH integer;
      begin
        for tplFootCharge in (select DOC_FOOT_CHARGE_ID
                                from DOC_FOOT_CHARGE
                               where DOC_FOOT_ID = aDocumentID
                                 and C_FINANCIAL_CHARGE in('02', '03') ) loop
          DOC_DELETE.DeleteFootCharge(tplFootCharge.DOC_FOOT_CHARGE_ID);
        end loop;

        -- Regarder s'il y a des positions déchargées
        select decode(count(distinct PDE_SRC.DOC_DOCUMENT_ID), 0, 0, 1)
          into intDMT_DISCH_FCH
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION_DETAIL PDE_SRC
         where PDE.DOC_DOCUMENT_ID = aDocumentID
           and PDE.DOC_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
           and PDE.DOC_GAUGE_RECEIPT_ID is not null;

        update DOC_DOCUMENT
           set DMT_CREATE_FOOT_CHARGE = 1
             , DMT_RECALC_FOOT_CHARGE = 0
             , DMT_DISCHARGE_FOOT_CHARGE = intDMT_DISCH_FCH
         where DOC_DOCUMENT_ID = aDocumentId;
      end;
    end if;

    -- recalcul du total du document si demandé
    if aFinalize = 1 then
      FinalizeDocument(aDocumentId);
    end if;
  end ReinitDocumentPrice;

  /**
  * procedure ControlAndInitPreEntry
  * Description
  *    Contrôle et initialise les données pour la création avec présaisie
  */
  procedure ControlAndInitPreEntry(
    aActDocumentID       in     DOC_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDocThirdID          in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aAciThirdID          in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aGaugeID             in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aAciCompany          in     DOC_DOCUMENT.COM_NAME_ACI%type
  , aPE_ThirdID          out    PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPE_DocNumber        out    ACT_DOCUMENT.DOC_NUMBER%type
  , aPE_DocDate          out    ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aPE_CurrencyID       out    ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aPE_ExchRate         out    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aPE_BasePrice        out    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aPE_ValueDate        out    ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aPE_TransactionDate  out    ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aPE_PartnerNumber    out    ACT_PART_IMPUTATION.PAR_DOCUMENT%type
  , aPE_PayConditionID   out    ACT_PART_IMPUTATION.PAC_PAYMENT_CONDITION_ID%type
  , aPE_FinRefID         out    ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID%type
  , aPE_BlockedDoc       out    ACT_PART_IMPUTATION.PAR_BLOCKED_DOCUMENT%type
  , aPE_DicBlockedReason out    ACT_PART_IMPUTATION.DIC_BLOCKED_REASON_ID%type
  , aPE_RefBVR           out    ACT_EXPIRY.EXP_REF_BVR%type
  )
  is
    cursor crPreEntryInfo(cActDocumentID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   ACT.DOC_DOCUMENT_DATE
             , ACT.DOC_NUMBER
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , decode(IMF.ACS_FINANCIAL_CURRENCY_ID, nvl(IMF.ACS_ACS_FINANCIAL_CURRENCY_ID, IMF.ACS_FINANCIAL_CURRENCY_ID), 1, IMF.IMF_EXCHANGE_RATE)
                                                                                                                                              IMF_EXCHANGE_RATE
             , decode(IMF.ACS_FINANCIAL_CURRENCY_ID, nvl(IMF.ACS_ACS_FINANCIAL_CURRENCY_ID, IMF.ACS_FINANCIAL_CURRENCY_ID), 1, IMF.IMF_BASE_PRICE)
                                                                                                                                                 IMF_BASE_PRICE
             , IMF.IMF_VALUE_DATE
             , IMF.IMF_TRANSACTION_DATE
             , PAR.PAR_DOCUMENT
             , PAR.PAC_PAYMENT_CONDITION_ID
             , PAR.PAC_FINANCIAL_REFERENCE_ID
             , PAR.PAR_BLOCKED_DOCUMENT
             , PAR.DIC_BLOCKED_REASON_ID
             , exp.EXP_REF_BVR
             , PAR.PAC_SUPPLIER_PARTNER_ID
          from ACT_DOCUMENT ACT
             , ACT_PART_IMPUTATION PAR
             , ACT_FINANCIAL_IMPUTATION IMF
             , ACT_EXPIRY exp
         where ACT.ACT_DOCUMENT_ID = aActDocumentID
           and ACT.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
           and ACT.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
           and ACT.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
      order by IMF.IMF_PRIMARY desc;

    tplPreEntryInfo crPreEntryInfo%rowtype;
    GasThirdMode    DOC_GAUGE_STRUCTURED.C_DOC_PRE_ENTRY_THIRD%type;
    TestCurrency    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if aAcicompany is null then
      -- Recherche d'informations sur la pré-saisie
      select C_DOC_PRE_ENTRY_THIRD
        into GasThirdMode
        from DOC_GAUGE_STRUCTURED
       where DOC_GAUGE_ID = aGaugeID;

      -- Recherche d'informations sur la pré-saisie
      open crPreEntryInfo(aActDocumentID);

      fetch crPreEntryInfo
       into tplPreEntryInfo;

      aPE_DocNumber         := tplPreEntryInfo.DOC_NUMBER;
      aPE_DocDate           := tplPreEntryInfo.DOC_DOCUMENT_DATE;
      aPE_CurrencyID        := tplPreEntryInfo.ACS_FINANCIAL_CURRENCY_ID;
      aPE_ExchRate          := tplPreEntryInfo.IMF_EXCHANGE_RATE;
      aPE_BasePrice         := tplPreEntryInfo.IMF_BASE_PRICE;
      aPE_ValueDate         := tplPreEntryInfo.IMF_VALUE_DATE;
      aPE_TransactionDate   := tplPreEntryInfo.IMF_TRANSACTION_DATE;
      aPE_PartnerNumber     := tplPreEntryInfo.PAR_DOCUMENT;
      aPE_PayConditionID    := tplPreEntryInfo.PAC_PAYMENT_CONDITION_ID;
      aPE_FinRefID          := tplPreEntryInfo.PAC_FINANCIAL_REFERENCE_ID;
      aPE_BlockedDoc        := tplPreEntryInfo.PAR_BLOCKED_DOCUMENT;
      aPE_DicBlockedReason  := tplPreEntryInfo.DIC_BLOCKED_REASON_ID;
      aPE_RefBVR            := tplPreEntryInfo.EXP_REF_BVR;
      aPE_ThirdID           := tplPreEntryInfo.PAC_SUPPLIER_PARTNER_ID;

      close crPreEntryInfo;

      -- Contrôle cohérence tiers/document logistique et tiers/document finance
      if     (aDocThirdID is not null)
         and (GasThirdMode = '1')
         and (aAciThirdID <> nvl(aPE_ThirdID, -1) ) then
        RAISE_APPLICATION_ERROR(-20000
                              , 'PCS - ' || PCS.PC_FUNCTIONS.TranslateWord('Le tiers du document et le tiers du document comptable ne coïncident pas !')
                               );
      end if;

      -- Contrôle que la monnaie de la pré-saisie soit disponnible pour le tiers en logistique
      begin
        select AUX.ACS_FINANCIAL_CURRENCY_ID
          into TestCurrency
          from ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , PAC_SUPPLIER_PARTNER SUP
         where SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = nvl(aDocThirdID, aPE_ThirdID)
           and AUX.ACS_FINANCIAL_CURRENCY_ID = aPE_CurrencyID
           and SUP.C_PARTNER_STATUS = '1';
      exception
        when no_data_found then
          RAISE_APPLICATION_ERROR(-20000
                                , 'PCS - ' || PCS.PC_FUNCTIONS.TranslateWord('La monnaie du document comptable n''est pas autorisée pour le tiers sélectionné.')
                                 );
      end;
    else
      declare
        vPerKey1           PAC_PERSON.PER_KEY1%type;
        vAciPerKey1        PAC_PERSON.PER_KEY1%type;
        vGauDescribe       DOC_GAUGE.GAU_DESCRIBE%type;
        vPE_PerKey1        PAC_PERSON.PER_KEY1%type;
        vPE_CurrName       PCS.PC_CURR.CURRNAME%type;
        vPE_PcoDescr       PAC_PAYMENT_CONDITION.PCO_DESCR%type;
        vPE_AccountNumber  PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type;
        vPE_AccountControl PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_CONTROL%type;
        vPE_TypeReference  PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
        vScrOwner          PCS.PC_SCRIP.SCRDBOWNER%type;
        vScrDbLink         PCS.PC_SCRIP.SCRDB_LINK%type;
        vProcName          varchar2(62);
        vSql               varchar2(20000);
      begin
        if aDocThirdId is null then
          vPerKey1  := null;
        else
          select PER_KEY1
            into vPerKey1
            from PAC_PERSON
           where PAC_PERSON_ID = aDocThirdID;
        end if;

        if aAciThirdId is null then
          vAciPerKey1  := vPerKey1;
        else
          select PER_KEY1
            into vAciPerKey1
            from PAC_PERSON
           where PAC_PERSON_ID = aAciThirdID;
        end if;

        select GAU_DESCRIBE
          into vGauDescribe
          from DOC_GAUGE
         where DOC_GAUGE_ID = aGaugeId;

        select SCRDBOWNER
             , SCRDB_LINK
          into vScrOwner
             , vScrDbLink
          from PCS.PC_COMP COM
             , PCS.PC_SCRIP SCR
         where COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID
           and COM_NAME = aAciCompany;

        if vScrDbLink is null then
          vProcname  := '.DOC_DOCUMENT_FUNCTIONS.ControlAndInitPreEntry';
        else
          vProcname  := '.DOC_DOCUMENT_FUNCTIONS.ControlAndInitPreEntry@' || vScrDbLink;
        end if;

        vSql  :=
          'begin' ||
          co.cLineBreak ||
          vScrOwner ||
          vProcName ||
          '(:aActDocumentID' ||
          ', :vPerKey1' ||
          ', :vAciPerKey1' ||
          ', :vGauDescribe' ||
          ', :vPE_PerKey1' ||
          ', :aPE_DocNumber' ||
          ', :aPE_DocDate' ||
          ', :vPE_CurrName' ||
          ', :aPE_ExchRate' ||
          ', :aPE_BasePrice' ||
          ', :aPE_ValueDate' ||
          ', :aPE_TransactionDate' ||
          ', :aPE_PartnerNumber' ||
          ', :aPE_BlockedDoc' ||
          ', :aPE_DicBlockedReason' ||
          ', :vPE_PcoDescr' ||
          ', :vPE_AccountNumber' ||
          ', :vPE_AccountControl' ||
          ', :vPE_TypeReference' ||
          ', :aPE_RefBVR' ||
          ');' ||
          co.cLineBreak ||
          'end;';

        execute immediate vSql
                    using in     aActDocumentID
                        , in     vPerKey1
                        , in     vAciPerKey1
                        , in     vGauDescribe
                        , out    vPE_PerKey1
                        , out    aPE_DocNumber
                        , out    aPE_DocDate
                        , out    vPE_CurrName
                        , out    aPE_ExchRate
                        , out    aPE_BasePrice
                        , out    aPE_ValueDate
                        , out    aPE_TransactionDate
                        , out    aPE_PartnerNumber
                        , out    aPE_BlockedDoc
                        , out    aPE_DicBlockedReason
                        , out    vPE_PcoDescr
                        , out    vPE_AccountNumber
                        , out    vPE_AccountControl
                        , out    vPE_TypeReference
                        , out    aPE_RefBVR;

        select PAC_PERSON_ID
          into aPE_ThirdID
          from PAC_PERSON
         where PER_KEY1 = vPE_PerKey1;

        select ACS_FINANCIAL_CURRENCY_ID
          into aPE_CurrencyID
          from ACS_FINANCIAL_CURRENCY FIC
             , PCS.PC_CURR CUR
         where FIC.PC_CURR_ID = CUR.PC_CURR_ID
           and CURRNAME = vPE_CurrName;

        select PAC_PAYMENT_CONDITION_ID
          into aPE_PayConditionID
          from PAC_PAYMENT_CONDITION
         where PCO_DESCR = vPE_PcoDescr;

        if vPE_TypeReference is not null then
          select PAC_FINANCIAL_REFERENCE_ID
            into aPE_FinRefID
            from PAC_FINANCIAL_REFERENCE
           where nvl(FRE_ACCOUNT_NUMBER, 0) = nvl(vPE_AccountNumber, 0)
             and nvl(FRE_ACCOUNT_CONTROL, 0) = nvl(vPE_AccountControl, 0)
             and C_TYPE_REFERENCE = vPE_TypeReference
             and PAC_SUPPLIER_PARTNER_ID = aPe_ThirdId;
        end if;
      end;
    end if;
  end ControlAndInitPreEntry;

  /**
  * procedure ControlAndInitPreEntry
  * Description
  *    Contrôle et initialise les données pour la création avec présaisie
  */
  procedure ControlAndInitPreEntry(
    aActDocumentID       in     DOC_DOCUMENT.ACT_DOCUMENT_ID%type
  , aPerKey1             in     PAC_PERSON.PER_KEY1%type
  , aAciPerKey1          in     PAC_PERSON.PER_KEY1%type
  , aGauDescribe         in     DOC_GAUGE.GAU_DESCRIBE%type
  , aPE_PerKey1          out    PAC_PERSON.PER_KEY1%type
  , aPE_DocNumber        out    ACT_DOCUMENT.DOC_NUMBER%type
  , aPE_DocDate          out    ACT_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aPE_CurrName         out    PCS.PC_CURR.CURRNAME%type
  , aPE_ExchRate         out    ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aPE_BasePrice        out    ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aPE_ValueDate        out    ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aPE_TransactionDate  out    ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aPE_PartnerNumber    out    ACT_PART_IMPUTATION.PAR_DOCUMENT%type
  , aPE_BlockedDoc       out    ACT_PART_IMPUTATION.PAR_BLOCKED_DOCUMENT%type
  , aPE_DicBlockedReason out    ACT_PART_IMPUTATION.DIC_BLOCKED_REASON_ID%type
  , aPE_PcoDescr         out    PAC_PAYMENT_CONDITION.PCO_DESCR%type
  , aPE_AccountNumber    out    PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type
  , aPE_AccountControl   out    PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_CONTROL%type
  , aPe_TypeReference    out    PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type
  , aPE_RefBVR           out    ACT_EXPIRY.EXP_REF_BVR%type
  )
  is
    vDocThirdID        DOC_DOCUMENT.PAC_THIRD_ID%type;
    vAciThirdID        DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    vGaugeID           DOC_GAUGE.DOC_GAUGE_ID%type;
    vPE_ThirdID        PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    vPE_CurrencyID     ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    vPE_PayConditionID ACT_PART_IMPUTATION.PAC_PAYMENT_CONDITION_ID%type;
    vPE_FinRefID       ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID%type;
  begin
    -- Conversion du nom du tiers en ID
    if aPerKey1 is not null then
      begin
        select PAC_PERSON_ID
          into vDocThirdId
          from PAC_PERSON
         where PER_KEY1 = aPerKey1;
      exception
        when no_data_found then
          raise_application_error(-20000
                                , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le tiers (PER_KEY1) [PER_KEY1] n''existe pas'), '[PER_KEY1]', aPerKey1) );
      end;
    end if;

    -- Conversion du nom du tiers finance en ID
    if aAciPerKey1 is not null then
      begin
        select PAC_PERSON_ID
          into vAciThirdId
          from PAC_PERSON
         where PER_KEY1 = aAciPerKey1;
      exception
        when no_data_found then
          raise_application_error(-20000
                                , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le tiers finance (PER_KEY1) [PER_KEY1] n''existe pas')
                                        , '[PER_KEY1]'
                                        , aAciPerKey1
                                         )
                                 );
      end;
    else
      vAciThirdId  := vDocThirdId;
    end if;

    -- Conversion du nom de gabarit en ID
    begin
      select DOC_GAUGE_ID
        into vGaugeId
        from DOC_GAUGE
       where GAU_DESCRIBE = aGauDescribe;
    exception
      when no_data_found then
        raise_application_error(-20000
                              , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Le gabarit [GAU_DESCRIBE] n''existe pas'), '[GAU_DESCRIBE]', aGauDescribe)
                               );
    end;

    ControlAndInitPreEntry(aActDocumentID
                         , vDocThirdID
                         , vAciThirdID
                         , vGaugeID
                         , null   --aAciCompany
                         , vPE_ThirdID
                         , aPE_DocNumber
                         , aPE_DocDate
                         , vPE_CurrencyID
                         , aPE_ExchRate
                         , aPE_BasePrice
                         , aPE_ValueDate
                         , aPE_TransactionDate
                         , aPE_PartnerNumber
                         , vPE_PayConditionID
                         , vPE_FinRefID
                         , aPE_BlockedDoc
                         , aPE_DicBlockedReason
                         , aPE_RefBVR
                          );

    select PER_KEY1
      into aPE_PerKey1
      from PAC_PERSON
     where PAC_PERSON_ID = vPE_ThirdID;

    select CURRNAME
      into aPE_CurrName
      from ACS_FINANCIAL_CURRENCY FIC
         , PCS.PC_CURR CUR
     where CUR.PC_CURR_ID = FIC.PC_CURR_ID
       and FIC.ACS_FINANCIAL_CURRENCY_ID = vPE_CurrencyID;

    select PCO_DESCR
      into aPE_PcoDescr
      from PAC_PAYMENT_CONDITION
     where PAC_PAYMENT_CONDITION_ID = vPE_PayConditionID;

    if vPE_FinRefID is not null then
      select FRE_ACCOUNT_NUMBER
           , FRE_ACCOUNT_CONTROL
           , C_TYPE_REFERENCE
        into aPE_AccountNumber
           , aPE_AccountControl
           , aPE_TypeReference
        from PAC_FINANCIAL_REFERENCE
       where PAC_FINANCIAL_REFERENCE_ID = vPE_FinRefID;
    end if;
  end ControlAndInitPreEntry;

  /**
  * Description
  *    Recherche un numéro de document
  */
  procedure GetDocumentNumber(
    aGaugeID          in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aGaugeNumberingID in out DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type
  , aDocNumber        in out DOC_DOCUMENT.DMT_NUMBER%type
  )
  is
    pragma autonomous_transaction;

    cursor NumberInfo(aGaugeID number)
    is
      select GAU.GAU_NUMBERING
           , GAU.DOC_GAUGE_NUMBERING_ID
           , GAN.GAN_INCREMENT
           , GAN.GAN_MODIFY_NUMBER
           , GAN.GAN_FREE_NUMBER
           , GAN.GAN_PREFIX
           , GAN.GAN_SUFFIX
           , 'ID-' || INIT_ID_SEQ.nextval UNIQUE_VALUE
        from DOC_GAUGE GAU
           , DOC_GAUGE_NUMBERING GAN
       where GAU.DOC_GAUGE_ID = aGaugeID
         and GAU.DOC_GAUGE_NUMBERING_ID = GAN.DOC_GAUGE_NUMBERING_ID;

    cursor NumberInfo2(aGaugeNumberingID number)
    is
      select 1 GAU_NUMBERING
           , GAN.DOC_GAUGE_NUMBERING_ID
           , GAN.GAN_INCREMENT
           , GAN.GAN_MODIFY_NUMBER
           , GAN.GAN_FREE_NUMBER
           , GAN.GAN_PREFIX
           , GAN.GAN_SUFFIX
           , 'ID-' || INIT_ID_SEQ.nextval UNIQUE_VALUE
        from DOC_GAUGE_NUMBERING GAN
       where GAN.DOC_GAUGE_NUMBERING_ID = aGaugeNumberingId;

    DocNumbering            NumberInfo%rowtype;
    vGAU_NUMBERING          DOC_GAUGE.GAU_NUMBERING%type;
    vDOC_GAUGE_NUMBERING_ID DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type;
    vGAN_INCREMENT          DOC_GAUGE_NUMBERING.GAN_INCREMENT%type;
    vGAN_MODIFY_NUMBER      DOC_GAUGE_NUMBERING.GAN_MODIFY_NUMBER%type;
    vGAN_FREE_NUMBER        DOC_GAUGE_NUMBERING.GAN_FREE_NUMBER%type;
    vGAN_PREFIX             DOC_GAUGE_NUMBERING.GAN_PREFIX%type;
    vGAN_SUFFIX             DOC_GAUGE_NUMBERING.GAN_SUFFIX%type;
    vGAN_LAST_NUMBER        DOC_GAUGE_NUMBERING.GAN_LAST_NUMBER%type;
    vGAN_RANGE_NUMBER       DOC_GAUGE_NUMBERING.GAN_RANGE_NUMBER%type;
    vGAN_NUMBER             DOC_GAUGE_NUMBERING.GAN_NUMBER%type;
    vFormatedNumber         DOC_DOCUMENT.DMT_NUMBER%type;
    vDocFreeNumber          DOC_DOCUMENT.DMT_NUMBER%type;
    vDocFreeNumberID        DOC_FREE_NUMBER.DOC_FREE_NUMBER_ID%type;
    vDocId                  DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    ValueUnique             DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vIsFreeNumber           number(1);
  begin
    if aGaugeId is not null then
      open NumberInfo(aGaugeID);

      fetch NumberInfo
       into DocNumbering;

      close NumberInfo;
    else
      open NumberInfo2(aGaugeNumberingID);

      fetch NumberInfo2
       into DocNumbering;

      close NumberInfo2;
    end if;

    vGAU_NUMBERING           := DocNumbering.GAU_NUMBERING;
    vDOC_GAUGE_NUMBERING_ID  := DocNumbering.DOC_GAUGE_NUMBERING_ID;
    vGAN_INCREMENT           := DocNumbering.GAN_INCREMENT;
    vGAN_MODIFY_NUMBER       := DocNumbering.GAN_MODIFY_NUMBER;
    vGAN_FREE_NUMBER         := DocNumbering.GAN_FREE_NUMBER;
    vGAN_PREFIX              := DocNumbering.GAN_PREFIX;
    vGAN_SUFFIX              := DocNumbering.GAN_SUFFIX;
    aDocNumber               := DocNumbering.UNIQUE_VALUE;
    aGaugeNumberingID        := DocNumbering.DOC_GAUGE_NUMBERING_ID;

    -- test s'il existe des numéro libre pour le gabarit de numérotation
    select sign(count(*) )
      into vIsFreeNumber
      from DOC_FREE_NUMBER
     where DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID;

    if vGAU_NUMBERING = 1 then   -- Numérotation
      if vGAN_INCREMENT = 1 then   -- Incrémentation automatique = OUI
        select     lpad(GAN.GAN_LAST_NUMBER + GAN.GAN_RANGE_NUMBER, greatest(length(GAN.GAN_LAST_NUMBER + GAN.GAN_RANGE_NUMBER), nvl(GAN.GAN_NUMBER, 0) ), '0')
              into vFormatedNumber
              from DOC_GAUGE_NUMBERING GAN
             where GAN.DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID
        for update;

        aDocNumber  := vGAN_PREFIX || vFormatedNumber || vGAN_SUFFIX;

        -- Numéro modifiable OU PAs de gestion des numéros libres
        if    (vGAN_MODIFY_NUMBER = 1)
           or (     (vGAN_FREE_NUMBER <> 1)
               and (vIsFreeNumber = 0) ) then
          -- MAJ du dernier n° de doc utilisé
          update DOC_GAUGE_NUMBERING
             set GAN_LAST_NUMBER = GAN_LAST_NUMBER + GAN_RANGE_NUMBER
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , A_DATEMOD = sysdate
           where DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID;

          DOC_FUNCTIONS.CreateHistoryInformation(null
                                               , null   -- DOC_POSITION_ID
                                               , aDocNumber   -- no de document
                                               , 'PLSQL'   -- DUH_TYPE
                                               , 'Getting a new document number : ' || aDocNumber
                                               , 'DOC_GAUGE_ID : ' ||
                                                 aGaugeId ||
                                                 co.cLineBreak ||
                                                 'DOC_GAUGE_NUMBERING_ID : ' ||
                                                 vDOC_GAUGE_NUMBERING_ID   -- description libre
                                               , null   -- status document
                                               , null   -- status position
                                                );
        else
          -- Recherche du 1er n° libre non réservé pour MAJ
          begin
            select     DOF.DOF_NUMBER
                     , DOF.DOC_FREE_NUMBER_ID
                  into vDocFreeNumber
                     , vDocFreeNumberID
                  from DOC_FREE_NUMBER DOF
                 where DOF.DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID
                   and DOF.DOF_NUMBER = (select min(DOF_NUMBER)
                                           from DOC_FREE_NUMBER
                                          where DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID
                                            and COM_FUNCTIONS.IS_SESSION_ALIVE(DOF_SESSION_ID) = 0)
            for update;
          exception
            when no_data_found then
              vDocFreeNumber    := null;
              vDocFreeNumberID  := null;
          end;

          if vDocFreeNumber is null then   -- Pas trouvé du numéro libre
            -- Création numéro libre
            insert into DOC_FREE_NUMBER
                        (DOC_FREE_NUMBER_ID
                       , DOC_GAUGE_NUMBERING_ID
                       , DOF_NUMBER
                       , DOF_CREATING
                       , DOF_SESSION_ID
                        )
                 values (INIT_ID_SEQ.nextval
                       , vDOC_GAUGE_NUMBERING_ID
                       , aDocNumber
                       , 1
                       , DBMS_SESSION.UNIQUE_SESSION_ID
                        );

            -- MAJ du dernier n° de doc utilisé
            update DOC_GAUGE_NUMBERING
               set GAN_LAST_NUMBER = GAN_LAST_NUMBER + GAN_RANGE_NUMBER
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 , A_DATEMOD = sysdate
             where DOC_GAUGE_NUMBERING_ID = vDOC_GAUGE_NUMBERING_ID;

            DOC_FUNCTIONS.CreateHistoryInformation(null
                                                 , null
                                                 ,   -- DOC_POSITION_ID
                                                   aDocNumber
                                                 ,   -- no de document
                                                   'PLSQL'
                                                 ,   -- DUH_TYPE
                                                   'Getting a new document number : ' || aDocNumber
                                                 , 'DOC_GAUGE_ID : ' || aGaugeId || co.cLineBreak || 'DOC_GAUGE_NUMBERING_ID : ' || vDOC_GAUGE_NUMBERING_ID
                                                 ,   -- description libre
                                                   null
                                                 ,   -- status document
                                                   null
                                                  );   -- status position
          else   -- Utilisation du numéro libre trouvé
            aDocNumber  := vDocFreeNumber;

            -- Réservation du numéro libre
            update DOC_FREE_NUMBER
               set DOF_CREATING = 1
                 , DOF_SESSION_ID = DBMS_SESSION.UNIQUE_SESSION_ID
             where DOC_FREE_NUMBER_ID = vDocFreeNumberID;

            DOC_FUNCTIONS.CreateHistoryInformation(null
                                                 , null
                                                 ,   -- DOC_POSITION_ID
                                                   aDocNumber
                                                 ,   -- no de document
                                                   'PLSQL'
                                                 ,   -- DUH_TYPE
                                                   'Reuse of a free document number : ' || aDocNumber
                                                 , 'DOC_GAUGE_ID : ' || aGaugeId || co.cLineBreak || 'DOC_FREE_NUMBER_ID : ' || vDocFreeNumberID
                                                 ,   -- description libre
                                                   null
                                                 ,   -- status document
                                                   null
                                                  );   -- status position
          end if;
        end if;
      else   -- Incrémentation automatique = NON
        aDocNumber  := vGAN_PREFIX || '          ' || vGAN_SUFFIX;
      end if;
    end if;

    -- si le numéro de document n'est pas vide
    if     aGaugeId is not null
       and (vGAN_INCREMENT = 1)
       and aDocNumber is not null then
      begin
        -- vérifie l'existance du numéro de document dans la table des documents
        select DOC_DOCUMENT_ID
          into vDocId
          from DOC_DOCUMENT
         where DMT_NUMBER = aDocNumber;
      exception
        when no_data_found then
          begin
            select ASA_RECORD_ID
              into vDocId
              from ASA_RECORD
             where ARE_NUMBER = aDocNumber;
          exception
            when no_data_found then
              begin
                -- Insertion seulement si le numéro de document n'existe pas déjà dans DOC ou SAV
                insert into DOC_MISSING_NUMBER
                            (DOC_MISSING_NUMBER_ID
                           , DOC_GAUGE_NUMBERING_ID
                           , STM_EXERCISE_ID
                           , DOC_GAUGE_ID
                           , DMN_NUMBER
                           , DMN_CREATING
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (INIT_ID_SEQ.nextval
                           , aGaugeNumberingId
                           , STM_FUNCTIONS.GetActiveExercise
                           , aGaugeId
                           , aDocNumber
                           , 1
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );
              exception
                when dup_val_on_index then
                  null;
              end;
          end;
      end;
    end if;

    commit;   -- à cause de la transaction autonome
  end GetDocumentNumber;

  /**
  *   Get document currency
  */
  function GetDocumentCurrency(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  is
    lResult DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche de la monnaie du document
    select ACS_FINANCIAL_CURRENCY_ID
      into lResult
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentId;

    return lResult;
  end GetDocumentCurrency;

  procedure freeSessionNumbers
  is
  begin
    update DOC_FREE_NUMBER
       set DOF_CREATING = 0
         , DOF_SESSION_ID = 0
     where DOF_SESSION_ID = DBMS_SESSION.unique_session_id;

    insert into DOC_FREE_NUMBER
                (DOC_FREE_NUMBER_ID
               , DOC_GAUGE_NUMBERING_ID
               , DOF_NUMBER
               , DOF_SESSION_ID
               , DOF_CREATING
                )
      select DMN.DOC_MISSING_NUMBER_ID
           , DMN.DOC_GAUGE_NUMBERING_ID
           , DMN.DMN_NUMBER
           , DMN.DMN_SESSION_ID
           , 0
        from DOC_MISSING_NUMBER DMN
           , DOC_GAUGE_NUMBERING GAN
       where DMN.DMN_SESSION_ID = DBMS_SESSION.unique_session_id
         and DMN.DOC_GAUGE_NUMBERING_ID = GAN.DOC_GAUGE_NUMBERING_ID
         and GAN.GAN_FREE_NUMBER = 1
         and not exists(select DOF_NUMBER
                          from DOC_FREE_NUMBER
                         where DOF_NUMBER = DMN.DMN_NUMBER);

    delete from DOC_MISSING_NUMBER
          where DMN_SESSION_ID = DBMS_SESSION.unique_session_id;
  end freeSessionNumbers;

  procedure FreeSessionNumbers_AutoTrans
  is
    pragma autonomous_transaction;
  begin
    DOC_DOCUMENT_FUNCTIONS.freeSessionNumbers;
    commit;   /* Car on utilise une transaction autonome */
  end FreeSessionNumbers_AutoTrans;

  procedure GetDocAddress(
    aAddressID     in     PAC_ADDRESS.PAC_ADDRESS_ID%type default null
  , aAddressTypeID in     DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type default null
  , aThirdID       in     DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aAddressInfo   out    DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO
  )
  is
    --  Curseur ADRESSE *******
    cursor crAddress(cAddressID in number)
    is
      select ADR.PC_LANG_ID
           , ADR.ADD_PRINCIPAL
           , ADR.DIC_ADDRESS_TYPE_ID
           , ADR.PAC_ADDRESS_ID
           , ADR.PC_CNTRY_ID
           , ADR.ADD_ADDRESS1
           , ADR.ADD_ZIPCODE
           , ADR.ADD_CITY
           , ADR.ADD_STATE
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_ACTIVITY
           , ADR.ADD_CARE_OF
           , ADR.ADD_PO_BOX
           , ADR.ADD_PO_BOX_NBR
           , ADR.ADD_COUNTY
        from PAC_ADDRESS ADR
           , PAC_PERSON PER
       where ADR.PAC_ADDRESS_ID = cAddressID
         and ADR.PAC_PERSON_ID = PER.PAC_PERSON_ID;

    tplAddress      crAddress%rowtype;

    cursor crGetAddressID(cThirdID in number, cAddressTypeID in varchar2)
    is
      select   PAC_ADDRESS_ID
          from PAC_ADDRESS
         where PAC_PERSON_ID = cThirdID
           and C_PARTNER_STATUS = '1'
      order by (case nvl(cAddressTypeID, 'NULL')
                  when DIC_ADDRESS_TYPE_ID then 1
                  else 0
                end) desc
             , nvl(ADD_PRINCIPAL, 0) desc
             , nvl(ADD_PRIORITY, 0) asc;

    vPAC_ADDRESS_ID PAC_ADDRESS.PAC_ADDRESS_ID%type;
  begin
    -- L'ID de l'adresse est connue
    if aAddressID is not null then
      vPAC_ADDRESS_ID  := aAddressID;
    else
      -- Rechercher l'ID de l'adresse selon tiers et type d'adresse
      open crGetAddressID(aThirdID, aAddressTypeID);

      fetch crGetAddressID
       into vPAC_ADDRESS_ID;

      close crGetAddressID;
    end if;

    -- Récuperer toutes les infos des adresses
    if vPAC_ADDRESS_ID is not null then
      open crAddress(vPAC_ADDRESS_ID);

      fetch crAddress
       into tplAddress;

      close crAddress;

      aAddressInfo.PAC_ADDRESS_ID  := tplAddress.PAC_ADDRESS_ID;
      aAddressInfo.PC_LANG_ID      := tplAddress.PC_LANG_ID;
      aAddressInfo.PC_CNTRY_ID     := tplAddress.PC_CNTRY_ID;
      aAddressInfo.DMT_ADDRESS     := tplAddress.ADD_ADDRESS1;
      aAddressInfo.DMT_POSTCODE    := tplAddress.ADD_ZIPCODE;
      aAddressInfo.DMT_TOWN        := tplAddress.ADD_CITY;
      aAddressInfo.DMT_STATE       := tplAddress.ADD_STATE;
      aAddressInfo.DMT_NAME        := tplAddress.PER_NAME;
      aAddressInfo.DMT_FORENAME    := tplAddress.PER_FORENAME;
      aAddressInfo.DMT_ACTIVITY    := tplAddress.PER_ACTIVITY;
      aAddressInfo.DMT_CARE_OF     := tplAddress.ADD_CARE_OF;
      aAddressInfo.DMT_PO_BOX      := tplAddress.ADD_PO_BOX;
      aAddressInfo.DMT_PO_BOX_NBR  := tplAddress.ADD_PO_BOX_NBR;
      aAddressInfo.DMT_COUNTY      := tplAddress.ADD_COUNTY;
      aAddressInfo.DMT_CONTACT     := null;
    end if;
  end GetDocAddress;

  procedure GetDocAddress(
    aAddressID     in     PAC_ADDRESS.PAC_ADDRESS_ID%type default null
  , aAddressTypeID in     DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type default null
  , aThirdID       in     DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aPacAddressID  out    DOC_DOCUMENT.PAC_ADDRESS_ID%type
  , aPcLangID      out    DOC_DOCUMENT.PC_LANG_ID%type
  , aPcCntryID     out    DOC_DOCUMENT.PC_CNTRY_ID%type
  , aAddress       out    DOC_DOCUMENT.DMT_ADDRESS1%type
  , aZipCode       out    DOC_DOCUMENT.DMT_POSTCODE1%type
  , aCity          out    DOC_DOCUMENT.DMT_TOWN1%type
  , aState         out    DOC_DOCUMENT.DMT_STATE1%type
  , aName          out    DOC_DOCUMENT.DMT_NAME1%type
  , aForename      out    DOC_DOCUMENT.DMT_FORENAME1%type
  , aActivity      out    DOC_DOCUMENT.DMT_ACTIVITY1%type
  , aCareOf        out    DOC_DOCUMENT.DMT_CARE_OF1%type
  , aPoBox         out    DOC_DOCUMENT.DMT_PO_BOX1%type
  , aPoBoxNbr      out    DOC_DOCUMENT.DMT_PO_BOX_NBR1%type
  , aCounty        out    DOC_DOCUMENT.DMT_COUNTY1%type
  , aContact       out    DOC_DOCUMENT.DMT_CONTACT1%type
  )
  is
    vDOC_ADDRESS_INFO DOC_DOCUMENT_FUNCTIONS.TDOC_ADDRESS_INFO;
  begin
    GetDocAddress(aAddressID => aAddressID, aAddressTypeID => aAddressTypeID, aThirdID => aThirdID, aAddressInfo => vDOC_ADDRESS_INFO);
    --
    aPacAddressID  := vDOC_ADDRESS_INFO.PAC_ADDRESS_ID;
    aPcLangID      := vDOC_ADDRESS_INFO.PC_LANG_ID;
    aPcCntryID     := vDOC_ADDRESS_INFO.PC_CNTRY_ID;
    aAddress       := vDOC_ADDRESS_INFO.DMT_ADDRESS;
    aZipCode       := vDOC_ADDRESS_INFO.DMT_POSTCODE;
    aCity          := vDOC_ADDRESS_INFO.DMT_TOWN;
    aState         := vDOC_ADDRESS_INFO.DMT_STATE;
    aName          := vDOC_ADDRESS_INFO.DMT_NAME;
    aForename      := vDOC_ADDRESS_INFO.DMT_FORENAME;
    aActivity      := vDOC_ADDRESS_INFO.DMT_ACTIVITY;
    aCareOf        := vDOC_ADDRESS_INFO.DMT_CARE_OF;
    aPoBox         := vDOC_ADDRESS_INFO.DMT_PO_BOX;
    aPoBoxNbr      := vDOC_ADDRESS_INFO.DMT_PO_BOX_NBR;
    aCounty        := vDOC_ADDRESS_INFO.DMT_COUNTY;
    aContact       := vDOC_ADDRESS_INFO.DMT_CONTACT;
  end GetDocAddress;

  /***********************************************************************
  * Description
  *     Recherche la monnaie du tiers selon le domaine
  */
  function GetAdminDomainCurrencyId(aAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type, aThirdId in DOC_DOCUMENT.PAC_THIRD_ID%type)
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    CurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type   := 0;
    bSupplier  boolean;
    bCustomer  boolean;

    cursor customer_curr(aThirdId number)
    is
      select   min(CUR.ACS_FINANCIAL_CURRENCY_ID) ACS_FINANCIAL_CURRENCY_ID
          from ACS_FINANCIAL_CURRENCY CUR
             , ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , PAC_CUSTOM_PARTNER CUS
         where CUS.PAC_CUSTOM_PARTNER_ID = aThirdId
           and CUS.C_PARTNER_STATUS = '1'
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
           and CUR.ACS_FINANCIAL_CURRENCY_ID = AUX.ACS_FINANCIAL_CURRENCY_ID
      group by CUR.FIN_LOCAL_CURRENCY
             , AUX.ASC_DEFAULT
        having not(    CUR.FIN_LOCAL_CURRENCY = 0
                   and AUX.ASC_DEFAULT = 0
                   and count(*) > 1)
      order by AUX.ASC_DEFAULT desc
             , CUR.FIN_LOCAL_CURRENCY;

    cursor supplier_curr(aThirdId number)
    is
      select   min(CUR.ACS_FINANCIAL_CURRENCY_ID) ACS_FINANCIAL_CURRENCY_ID
          from ACS_FINANCIAL_CURRENCY CUR
             , ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , PAC_SUPPLIER_PARTNER SUP
         where SUP.PAC_SUPPLIER_PARTNER_ID = aThirdId
           and SUP.C_PARTNER_STATUS = '1'
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
           and CUR.ACS_FINANCIAL_CURRENCY_ID = AUX.ACS_FINANCIAL_CURRENCY_ID
      group by CUR.FIN_LOCAL_CURRENCY
             , AUX.ASC_DEFAULT
        having not(    CUR.FIN_LOCAL_CURRENCY = 0
                   and AUX.ASC_DEFAULT = 0
                   and count(*) > 1)
      order by AUX.ASC_DEFAULT desc
             , CUR.FIN_LOCAL_CURRENCY;
  begin
    -- Cascade de prise en compte de la monnaie client/fournisseur
    --  Si Monnaie par défaut cochée Alors
    --    utiliser la monnaie par défaut
    --  Sinon
    --    S'il y a 2 monnaies (la monnaie de base et une monnaie étrangère) Alors
    --      utiliser la monnaie étrangère
    --    Sinon (plus que 2 monnaies définies)
    --      utiliser la monnaie de base
    if (aAdminDomain = cAdminDomainSale)
     or (aAdminDomain = cAdminDomainAfterSale) then
      bCustomer  := true;
      bSupplier  := false;
    elsif    (aAdminDomain = cAdminDomainPurchase)
          or (aAdminDomain = cAdminDomainSubContract) then
      bCustomer  := false;
      bSupplier  := true;
    else
      bCustomer  := true;
      bSupplier  := true;
    end if;

    if bCustomer then
      open customer_curr(aThirdId);

      fetch customer_curr
       into CurrencyId;

      close customer_curr;
    end if;

    if  (     (bSupplier)
             and (CurrencyId = 0) ) then
      open supplier_curr(aThirdId);

      fetch supplier_curr
       into CurrencyId;

      close supplier_curr;
    end if;

    -- Si pas trouvé de monnaie, prendre la monnaie de base
    if (CurrencyId = 0) then
      select ACS_FINANCIAL_CURRENCY_ID
        into CurrencyId
        from ACS_FINANCIAL_CURRENCY
       where FIN_LOCAL_CURRENCY = 1;
    end if;

    return CurrencyId;
  end GetAdminDomainCurrencyID;

  /***********************************************************************
  * Description
  *     Recherche la monnaie du tiers selon le gabarit
  */
  function GetThirdCurrencyID(aGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type, aThirdId in DOC_DOCUMENT.PAC_THIRD_ID%type)
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    AdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type;
    CurrencyID  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select C_ADMIN_DOMAIN
      into AdminDomain
      from DOC_GAUGE
     where DOC_GAUGE_ID = aGaugeId;

    CurrencyId  := DOC_DOCUMENT_FUNCTIONS.GetAdminDomainCurrencyID(AdminDomain, aThirdId);
    return CurrencyID;
  end GetThirdCurrencyID;

  /***********************************************************************
  * Description
  *    Recherche les informations liées au tiers pour la création du document
  */
  procedure GetPartnerInfo(
    aThirdID            in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aGaugeID            in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aLocalCurrencyID    in out DOC_DOCUMENT.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aVATCurrencyID      in out DOC_DOCUMENT.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aTariffID           in out DOC_DOCUMENT.DIC_TARIFF_ID%type
  , aPayConditionID     in out DOC_DOCUMENT.PAC_PAYMENT_CONDITION_ID%type
  , aSendConditionID    in out DOC_DOCUMENT.PAC_SENDING_CONDITION_ID%type
  , aRepresentativeID   in out DOC_DOCUMENT.PAC_REPRESENTATIVE_ID%type
  , aFinReferenceID     in out DOC_DOCUMENT.PAC_FINANCIAL_REFERENCE_ID%type
  , aTypeSubmissionID   in out DOC_DOCUMENT.DIC_TYPE_SUBMISSION_ID%type
  , aIncoterms          in out DOC_DOCUMENT.C_INCOTERMS%type
  , aIncotermsPlace     in out DOC_DOCUMENT.DMT_INCOTERMS_PLACE%type
  , aVatDetAccountID    in out DOC_DOCUMENT.ACS_VAT_DET_ACCOUNT_ID%type
  , aAcsFinAccPaymentID in out DOC_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aBVRGenerMethod     in out DOC_FOOT.C_BVR_GENERATION_METHOD%type
  , aDistChannelID      in out DOC_DOCUMENT.PAC_DISTRIBUTION_CHANNEL_ID%type
  , aSaleTerritoryID    in out DOC_DOCUMENT.PAC_SALE_TERRITORY_ID%type
  )
  is
    cursor PartnerInfo(aThirdID number, aGaugeID number)
    is
      select   CUR.ACS_FINANCIAL_CURRENCY_ID LOCAL_CURR
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, VAT_SUP.ACS_FINANCIAL_CURRENCY_ID
                    , 2, VAT_CUS.ACS_FINANCIAL_CURRENCY_ID
                    , 5, VAT_SUP.ACS_FINANCIAL_CURRENCY_ID
                    , nvl(VAT_CUS.ACS_FINANCIAL_CURRENCY_ID, VAT_SUP.ACS_FINANCIAL_CURRENCY_ID)
                     ) VAT_CURRENCY_ID
             , decode(GAU.C_ADMIN_DOMAIN, 1, SUP.DIC_TARIFF_ID, 2, CUS.DIC_TARIFF_ID, 5, SUP.DIC_TARIFF_ID, nvl(CUS.DIC_TARIFF_ID, SUP.DIC_TARIFF_ID) )
                                                                                                                                                  DIC_TARIFF_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.PAC_PAYMENT_CONDITION_ID
                    , 2, CUS.PAC_PAYMENT_CONDITION_ID
                    , 5, SUP.PAC_PAYMENT_CONDITION_ID
                    , nvl(CUS.PAC_PAYMENT_CONDITION_ID, SUP.PAC_PAYMENT_CONDITION_ID)
                     ) PAC_PAYMENT_CONDITION_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.PAC_SENDING_CONDITION_ID
                    , 2, CUS.PAC_SENDING_CONDITION_ID
                    , 5, SUP.PAC_SENDING_CONDITION_ID
                    , nvl(CUS.PAC_SENDING_CONDITION_ID, SUP.PAC_SENDING_CONDITION_ID)
                     ) PAC_SENDING_CONDITION_ID
             , decode(GAU.C_ADMIN_DOMAIN, 1, null, 2, CUS.PAC_REPRESENTATIVE_ID, 5, null, CUS.PAC_REPRESENTATIVE_ID) PAC_REPRESENTATIVE_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.ACS_FIN_ACC_S_PAYMENT_ID
                    , 2, CUS.ACS_FIN_ACC_S_PAYMENT_ID
                    , 5, SUP.ACS_FIN_ACC_S_PAYMENT_ID
                    , nvl(CUS.ACS_FIN_ACC_S_PAYMENT_ID, SUP.ACS_FIN_ACC_S_PAYMENT_ID)
                     ) ACS_FIN_ACC_S_PAYMENT_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.DIC_TYPE_SUBMISSION_ID
                    , 2, CUS.DIC_TYPE_SUBMISSION_ID
                    , 5, SUP.DIC_TYPE_SUBMISSION_ID
                    , nvl(CUS.DIC_TYPE_SUBMISSION_ID, SUP.DIC_TYPE_SUBMISSION_ID)
                     ) DIC_TYPE_SUBMISSION_ID
             , decode(GAU.C_ADMIN_DOMAIN, 1, SUP.C_INCOTERMS, 2, CUS.C_INCOTERMS, 5, SUP.C_INCOTERMS, nvl(CUS.C_INCOTERMS, SUP.C_INCOTERMS) ) C_INCOTERMS
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.CRE_INCOTERMS_PLACE
                    , 2, CUS.CUS_INCOTERMS_PLACE
                    , 5, SUP.CRE_INCOTERMS_PLACE
                    , nvl(CUS.CUS_INCOTERMS_PLACE, SUP.CRE_INCOTERMS_PLACE)
                     ) INCOTERMS_PLACE
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.ACS_VAT_DET_ACCOUNT_ID
                    , 2, CUS.ACS_VAT_DET_ACCOUNT_ID
                    , 5, SUP.ACS_VAT_DET_ACCOUNT_ID
                    , nvl(CUS.ACS_VAT_DET_ACCOUNT_ID, SUP.ACS_VAT_DET_ACCOUNT_ID)
                     ) ACS_VAT_DET_ACCOUNT_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, FRE_SUP.PAC_FINANCIAL_REFERENCE_ID
                    , 2, FRE_CUS.PAC_FINANCIAL_REFERENCE_ID
                    , 5, FRE_SUP.PAC_FINANCIAL_REFERENCE_ID
                    , nvl(FRE_CUS.PAC_FINANCIAL_REFERENCE_ID, FRE_SUP.PAC_FINANCIAL_REFERENCE_ID)
                     ) PAC_FINANCIAL_REFERENCE_ID
             , decode(GAU.C_ADMIN_DOMAIN, 1, null, 2, CUS.C_BVR_GENERATION_METHOD, 5, null, CUS.C_BVR_GENERATION_METHOD) C_BVR_GENERATION_METHOD
             , decode(GAU.C_ADMIN_DOMAIN, 1, null, 2, CUS.PAC_DISTRIBUTION_CHANNEL_ID, 5, null, CUS.PAC_DISTRIBUTION_CHANNEL_ID) PAC_DISTRIBUTION_CHANNEL_ID
             , decode(GAU.C_ADMIN_DOMAIN, 1, null, 2, CUS.PAC_SALE_TERRITORY_ID, 5, null, CUS.PAC_SALE_TERRITORY_ID) PAC_SALE_TERRITORY_ID
          from DOC_GAUGE GAU
             , PAC_THIRD THI
             , PAC_CUSTOM_PARTNER CUS
             , PAC_SUPPLIER_PARTNER SUP
             , PAC_FINANCIAL_REFERENCE FRE_CUS
             , PAC_FINANCIAL_REFERENCE FRE_SUP
             , ACS_FINANCIAL_CURRENCY CUR
             , ACS_VAT_DET_ACCOUNT VAT_CUS
             , ACS_VAT_DET_ACCOUNT VAT_SUP
         where GAU.DOC_GAUGE_ID = aGaugeID
           and CUR.FIN_LOCAL_CURRENCY = 1
           and THI.PAC_THIRD_ID = aThirdID
           and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
           and CUS.C_PARTNER_STATUS(+) = '1'
           and CUS.PAC_CUSTOM_PARTNER_ID = FRE_CUS.PAC_CUSTOM_PARTNER_ID(+)
           and CUS.ACS_VAT_DET_ACCOUNT_ID = VAT_CUS.ACS_VAT_DET_ACCOUNT_ID(+)
           and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and SUP.C_PARTNER_STATUS(+) = '1'
           and SUP.PAC_SUPPLIER_PARTNER_ID = FRE_SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and SUP.ACS_VAT_DET_ACCOUNT_ID = VAT_SUP.ACS_VAT_DET_ACCOUNT_ID(+)
      order by FRE_CUS.FRE_DEFAULT desc
             , FRE_SUP.FRE_DEFAULT desc;

    Info PartnerInfo%rowtype;
  begin
    open PartnerInfo(aThirdID, aGaugeID);

    fetch PartnerInfo
     into Info;

    aLocalCurrencyID     := Info.LOCAL_CURR;
    aVATCurrencyID       := Info.VAT_CURRENCY_ID;
    aTariffID            := Info.DIC_TARIFF_ID;
    aPayConditionID      := Info.PAC_PAYMENT_CONDITION_ID;
    aSendConditionID     := Info.PAC_SENDING_CONDITION_ID;
    aAcsFinAccPaymentID  := Info.ACS_FIN_ACC_S_PAYMENT_ID;
    aTypeSubmissionID    := Info.DIC_TYPE_SUBMISSION_ID;
    aIncoterms           := Info.C_INCOTERMS;
    aIncotermsPlace      := Info.INCOTERMS_PLACE;
    aVatDetAccountID     := Info.ACS_VAT_DET_ACCOUNT_ID;
    aFinReferenceID      := Info.PAC_FINANCIAL_REFERENCE_ID;
    aBVRGenerMethod      := Info.C_BVR_GENERATION_METHOD;
    aDistChannelID       := Info.PAC_DISTRIBUTION_CHANNEL_ID;
    aSaleTerritoryID     := Info.PAC_SALE_TERRITORY_ID;

    -- Vérifier que le Représentant soit "Actif logistique et finance"
    select decode(sum(C_PARTNER_STATUS), '1', Info.PAC_REPRESENTATIVE_ID, null)
      into aRepresentativeID
      from PAC_REPRESENTATIVE
     where PAC_REPRESENTATIVE_ID = Info.PAC_REPRESENTATIVE_ID;

    close PartnerInfo;
  end GetPartnerInfo;

  /**
  * procedure GetThirdPartners
  * Description
  *   Recherche les partenaires facturation, livraison et tarification liés au
  *   tiers selon le gabarit et la gestion des clients/fournisseurs
  */
  procedure GetThirdPartners(
    aThirdID         in     PAC_THIRD.PAC_THIRD_ID%type
  , aGaugeID         in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , aAdminDomain     in     DOC_GAUGE.C_ADMIN_DOMAIN%type default null
  , aThirdAciID      out    PAC_THIRD.PAC_THIRD_ID%type
  , aThirdDeliveryID out    PAC_THIRD.PAC_THIRD_ID%type
  , aThirdTariffID   out    PAC_THIRD.PAC_THIRD_ID%type
  )
  is
  begin
    -- Tiers gabarit si partenaire non initialisé
    -- Partenaire facturation
    ---- 1.Partenaire facturation du gabarit
    ---- 2.Partenaire facturation du partenaire donneur d’ordre
    ---- 3.Partenaire donneur d’ordre
    -- Partenaire livraison
    ---- 1.Partenaire livraison du gabarit
    ---- 2.Si domaine « Vente » ou « SAV » => Partenaire donneur d’ordre
    ----   Sinon  Partenaire livraison = vide
    -- Partenaire tarification
    ---- 1.Partenaire tarification du partenaire donneur d’ordre
    ---- 2.Partenaire donneur d’ordre
    begin
      select nvl(GAU.PAC_THIRD_ACI_ID
               , nvl(case
                       when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_1_ID
                       when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_1_ID
                       else nvl(CUS.PAC_PAC_THIRD_1_ID, SUP.PAC_PAC_THIRD_1_ID)
                     end
                   , THI.PAC_THIRD_ID
                    )
                ) PAC_THIRD_ACI_ID
           , nvl(GAU.PAC_THIRD_DELIVERY_ID, case
                   when GAU.C_ADMIN_DOMAIN in('2', '7') then THI.PAC_THIRD_ID
                   else null
                 end) PAC_THIRD_DELIVERY_ID
           , nvl(case
                   when GAU.C_ADMIN_DOMAIN in('1', '5') then SUP.PAC_PAC_THIRD_2_ID
                   when GAU.C_ADMIN_DOMAIN in('2', '7') then CUS.PAC_PAC_THIRD_2_ID
                   else nvl(CUS.PAC_PAC_THIRD_2_ID, SUP.PAC_PAC_THIRD_2_ID)
                 end
               , THI.PAC_THIRD_ID
                ) PAC_THIRD_TARIFF_ID
        into aThirdAciID
           , aThirdDeliveryID
           , aThirdTariffID
        from PAC_THIRD THI
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , (select max(PAC_THIRD_ID) PAC_THIRD_ID
                   , max(PAC_THIRD_ACI_ID) PAC_THIRD_ACI_ID
                   , max(PAC_THIRD_DELIVERY_ID) PAC_THIRD_DELIVERY_ID
                   , nvl(max(C_ADMIN_DOMAIN), aAdminDomain) C_ADMIN_DOMAIN
                from DOC_GAUGE
               where DOC_GAUGE_ID = aGaugeID
                 and C_GAUGE_STATUS = '2') GAU
       where THI.PAC_THIRD_ID = nvl(aThirdID, GAU.PAC_THIRD_ID)
         and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.C_PARTNER_STATUS(+) = '1'
         and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.C_PARTNER_STATUS(+) = '1';
    exception
      when no_data_found then
        aThirdAciID       := null;
        aThirdDeliveryID  := null;
        aThirdTariffID    := null;
    end;
  end GetThirdPartners;

   /**
    * Description
    *    Recherche des conditions de paiement
  */
  function getPaymentCondition(aThirdID in DOC_DOCUMENT.PAC_THIRD_ID%type, aGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return DOC_DOCUMENT.PAC_PAYMENT_CONDITION_ID%type
  is
    vResult DOC_DOCUMENT.PAC_PAYMENT_CONDITION_ID%type;
  begin
    select nvl(GAS.PAC_PAYMENT_CONDITION_ID
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.PAC_PAYMENT_CONDITION_ID
                    , 2, CUS.PAC_PAYMENT_CONDITION_ID
                    , 5, SUP.PAC_PAYMENT_CONDITION_ID
                    , nvl(CUS.PAC_PAYMENT_CONDITION_ID, SUP.PAC_PAYMENT_CONDITION_ID)
                     )
              )
      into vResult
      from DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GAS
         , PAC_THIRD THI
         , PAC_CUSTOM_PARTNER CUS
         , PAC_SUPPLIER_PARTNER SUP
     where GAU.DOC_GAUGE_ID = aGaugeID
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and THI.PAC_THIRD_ID = aThirdID
       and THI.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
       and CUS.C_PARTNER_STATUS(+) = '1'
       and THI.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
       and SUP.C_PARTNER_STATUS(+) = '1';

    return vResult;
  exception
    when no_data_found then
      return null;
  end getPaymentCondition;

  /***********************************************************************
  * procedure GetFinancialInfo
  * Description
  *     Recherche des comptes financier et division
  * @created NGV
  * @lastUpdate
  * @public
  */
  procedure GetFinancialInfo(
    pThirdID      in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , pGaugeID      in     DOC_GAUGE.DOC_GAUGE_ID%type
  , pDocumentId   in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , pRecordId     in     DOC_RECORD.DOC_RECORD_ID%type
  , pDocDate      in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , pFinAccountID in out DOC_DOCUMENT.ACS_FINANCIAL_ACCOUNT_ID%type
  , pDivAccountID in out DOC_DOCUMENT.ACS_DIVISION_ACCOUNT_ID%type
  , pCpnAccountId in out DOC_DOCUMENT.ACS_CPN_ACCOUNT_ID%type
  , pCdaAccountId in out DOC_DOCUMENT.ACS_CDA_ACCOUNT_ID%type
  , pPfAccountId  in out DOC_DOCUMENT.ACS_PF_ACCOUNT_ID%type
  , pPjAccountId  in out DOC_DOCUMENT.ACS_PJ_ACCOUNT_ID%type
  )
  is
    lnGaugeFinancialAccountId DOC_GAUGE_STRUCTURED.ACS_FINANCIAL_ACCOUNT_ID%type;
    lnGaugeDivisionAccountId  DOC_GAUGE_STRUCTURED.ACS_DIVISION_ACCOUNT_ID%type;
    lnFinancialAccountId      ACS_AUXILIARY_ACCOUNT.ACS_INVOICE_COLL_ID%type;
    lnDivisionAccountId       ACS_AUXILIARY_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    lvAdminDomain             DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lnFinancialCharge         DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    lnAnalyticalCharge        DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    lnVisiblAccount           DOC_GAUGE_STRUCTURED.GAS_VISIBLE_COUNT%type;
  begin
    /* Recherche des comptes financier et division  selon la cascade
       1° Comptes définis dans le gabarit si celui-ci a l'imputation financière activée et / ou si les comptes visibles
       2' Comptes par défaut + Méthode de déplacement de comptes
       3° Comptes définis au niveau du tiers (Client / fournisseur) selon le domaine du gabarit
       4° Comptes définis dans les configs
    */
    -- Recherche des comptes dans le gabarit
    begin
      select decode(nvl(GAS.GAS_FINANCIAL_CHARGE, 0) + nvl(GAS.GAS_VISIBLE_COUNT, 0), 0, null, GAS.ACS_FINANCIAL_ACCOUNT_ID) ACS_FINANCIAL_ACCOUNT_ID
           , decode(nvl(GAS.GAS_FINANCIAL_CHARGE, 0) + nvl(GAS.GAS_VISIBLE_COUNT, 0), 0, null, GAS.ACS_DIVISION_ACCOUNT_ID) ACS_DIVISION_ACCOUNT_ID
           , GAU.C_ADMIN_DOMAIN
           , GAS.GAS_FINANCIAL_CHARGE
           , GAS.GAS_ANAL_CHARGE
           , GAS.GAS_VISIBLE_COUNT
        into lnGaugeFinancialAccountId
           , lnGaugeDivisionAccountId
           , lvAdminDomain
           , lnFinancialCharge
           , lnAnalyticalCharge
           , lnVisiblAccount
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = pGaugeID
         and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;
    exception
      when no_data_found then
        null;
    end;

    if pThirdID is not null then
      -- Recherche les comptes du tiers et dans les configurations
      begin
        select decode(nvl(GAS.GAS_FINANCIAL_CHARGE, 0) + nvl(GAS.GAS_VISIBLE_COUNT, 0)
                    , 0, null
                    , decode(GAU.C_ADMIN_DOMAIN
                           , 1, nvl(AUX_SUP.ACS_INVOICE_COLL_ID, ACS_FUNCTION.GetFinancialAccountID(PCS.PC_CONFIG.GETCONFIG('FIN_DOC_FINANCIAL_ACCOUNT') ) )
                           , 2, nvl(AUX_CUS.ACS_INVOICE_COLL_ID, ACS_FUNCTION.GetFinancialAccountID(PCS.PC_CONFIG.GETCONFIG('FIN_DOC_FINANCIAL_ACCOUNT') ) )
                           , 5, nvl(AUX_SUP.ACS_INVOICE_COLL_ID, ACS_FUNCTION.GetFinancialAccountID(PCS.PC_CONFIG.GETCONFIG('FIN_DOC_FINANCIAL_ACCOUNT') ) )
                           , nvl(nvl(AUX_CUS.ACS_INVOICE_COLL_ID, AUX_SUP.ACS_INVOICE_COLL_ID)
                               , ACS_FUNCTION.GetFinancialAccountID(PCS.PC_CONFIG.GETCONFIG('FIN_DOC_FINANCIAL_ACCOUNT') )
                                )
                            )
                     ) ACS_INVOICE_COLL_ID
             , decode(nvl(GAS.GAS_FINANCIAL_CHARGE, 0) + nvl(GAS.GAS_VISIBLE_COUNT, 0)
                    , 0, null
                    , decode(GAU.C_ADMIN_DOMAIN
                           , 1, nvl(AUX_SUP.ACS_DIVISION_ACCOUNT_ID, ACS_FUNCTION.GetDivisionAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_DIVISION_ACCOUNT') ) )
                           , 2, nvl(AUX_CUS.ACS_DIVISION_ACCOUNT_ID, ACS_FUNCTION.GetDivisionAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_DIVISION_ACCOUNT') ) )
                           , 5, nvl(AUX_SUP.ACS_DIVISION_ACCOUNT_ID, ACS_FUNCTION.GetDivisionAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_DIVISION_ACCOUNT') ) )
                           , nvl(nvl(AUX_CUS.ACS_DIVISION_ACCOUNT_ID, AUX_SUP.ACS_DIVISION_ACCOUNT_ID)
                               , ACS_FUNCTION.GetDivisionAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_DIVISION_ACCOUNT') )
                                )
                            )
                     ) ACS_DIVISION_ACCOUNT_ID2
          into lnFinancialAccountId
             , lnDivisionAccountId
          from DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , PAC_THIRD THI
             , PAC_CUSTOM_PARTNER CUS
             , PAC_SUPPLIER_PARTNER SUP
             , ACS_AUXILIARY_ACCOUNT AUX_CUS
             , ACS_AUXILIARY_ACCOUNT AUX_SUP
         where GAU.DOC_GAUGE_ID = pGaugeID
           and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
           and THI.PAC_THIRD_ID = pThirdID
           and CUS.PAC_CUSTOM_PARTNER_ID(+) = THI.PAC_THIRD_ID
           and AUX_CUS.ACS_AUXILIARY_ACCOUNT_ID(+) = CUS.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.C_PARTNER_STATUS(+) = '1'
           and SUP.PAC_SUPPLIER_PARTNER_ID(+) = THI.PAC_THIRD_ID
           and SUP.C_PARTNER_STATUS(+) = '1'
           and AUX_SUP.ACS_AUXILIARY_ACCOUNT_ID(+) = SUP.ACS_AUXILIARY_ACCOUNT_ID;
      exception
        when no_data_found then
          lnFinancialAccountId  := ACS_FUNCTION.GetFinancialAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_FINANCIAL_ACCOUNT') );
          lnDivisionAccountId   := ACS_FUNCTION.GetDivisionAccountID(PCS.PC_CONFIG.GetConfig('FIN_DOC_DIVISION_ACCOUNT') );
      end;
    end if;

    -- Verifier que le gabarit gère les comptes
    if    lnFinancialCharge = 1
       or lnAnalyticalCharge = 1
       or lnVisiblAccount = 1 then
      -- Initialisation selon comptes du gabarit
      if pFinAccountId is null then
        pFinAccountID  := lnGaugeFinancialAccountId;
      end if;

      if pDivAccountId is null then
        pDivAccountID  := lnGaugeDivisionAccountId;
      end if;

      -- Si le compte financier du gabarit est null ou que le compte division du gabarit est null
      -- l'analytique n'est pas pris en compte
      if    pFinAccountId is null
         or pDivAccountId is null
         or pCpnAccountId is null
         or pCdaAccountId is null
         or pPfAccountId is null
         or pPjAccountId is null then
        ----
        -- Recherche des comptes non définis selon méthode des comptes par défault
        -- et ensuite des déplacements de comptes pour l'élement Compte collectif document logistique
        --
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetHeaderAccounts(pGaugeId
                                                     , ACS_I_LIB_LOGISTIC_FINANCIAL.cgEtCollectiveAccLogisticsDoc
                                                     , lvAdminDomain
                                                     , pDocdate
                                                     , pGaugeId
                                                     , pDocumentId
                                                     , pRecordId
                                                     , pThirdId
                                                     , pFinAccountId
                                                     , pDivAccountId
                                                     , pCpnAccountId
                                                     , pCdaAccountId
                                                     , pPfAccountId
                                                     , pPjAccountId
                                                     , pFinAccountId
                                                     , pDivAccountId
                                                     , pCpnAccountId
                                                     , pCdaAccountId
                                                     , pPfAccountId
                                                     , pPjAccountId
                                                      );

        ----
        -- Recherche des comptes non définis selon méthode des comptes par défault
        -- et ensuite des déplacements de comptes pour l'élement Imputation comptable (en-tête document)
        --
        -- Attention : ne doit plus être utilisé en logistique. C'est un type d'élement uniquement utilisé en compta.
        --
        --ACS_I_LIB_LOGISTIC_FINANCIAL.GetHeaderAccounts(pGaugeId
        --                               , ACS_I_LIB_LOGISTIC_FINANCIAL.gcEtAccEntryDocHeader
        --                               , lvAdminDomain
        --                               , pDocdate
        --                               , pGaugeId
        --                               , pDocumentId
        --                               , pRecordId
        --                               , pThirdId
        --                               , pFinAccountId
        --                               , pDivAccountId
        --                               , pCpnAccountId
        --                               , pCdaAccountId
        --                               , pPfAccountId
        --                               , pPjAccountId
        --                               , pFinAccountId
        --                               , pDivAccountId
        --                               , pCpnAccountId
        --                               , pCdaAccountId
        --                               , pPfAccountId
        --                               , pPjAccountId
        --                                );

        -- Récupération du compte financier (celui du tiers, sinon celui de la configuration)
        if pFinAccountId is null then
          pFinAccountID  := lnFinancialAccountId;
        end if;

        /* Vérification du couple compte financier / compte division
           la fct retourne  FinInfo.ACS_DIVISION_ACCOUNT_ID2  (compte du tiers, sinon celui de la configuration) si celui-ci est valide sinon le premier
           compte division selon la cascade définie dans l'ACS
        */
        if pDivAccountId is null then
          pDivAccountID  := ACS_FUNCTION.GetDivisionOfAccount(pFinAccountId, lnDivisionAccountId, pDocDate, ACS_I_LIB_LOGISTIC_FINANCIAL.GetDivisionUserId);
        end if;
      end if;

      /**
      * Méthode de détermination du compte financier et du compte division pour
      * toutes les imputations gèrées dans un document. Dans le cas de l'en-tête,
      * aucune recherche de config. ou autre n'est fait dans la procèdure. L'appel
      * est uniquement là pour avoir une uniformité dans la recherche des comptes.
      * En bref, cet appel ne sert à rien.
      */
      ACS_I_LIB_LOGISTIC_FINANCIAL.DefineFinancialImputation(iCode                  => 1
                                                           , iGaugeId               => pGaugeId   /* Gabarit. Utilisé pour contrôler la gestion des comptes. */
                                                           , iAdminDomain           => lvAdminDomain
                                                           , ioFinancialAccountId   => pFinAccountId
                                                           , ioDivisionAccountId    => pDivAccountId
                                                           , ioCPNAccountId         => pCpnAccountId
                                                           , ioCDAAccountId         => pCdaAccountId
                                                           , ioPFAccountId          => pPfAccountId
                                                           , ioPJAccountId          => pPjAccountId
                                                            );
      ----
      -- Inscrit éventuellement le résultat de la recherche des comptes dans la
      -- table DOC_UPDATE_HISTORY
      --
      ACS_I_LIB_LOGISTIC_FINANCIAL.WriteInformation(pDocumentId, 'Document ' || pGaugeId);
      /**
      *
      * Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      * charge par nature sont autorisées.
      */
      ACS_I_LIB_LOGISTIC_FINANCIAL.CheckAccountPermission(pFinAccountId, pDivAccountID, pCpnAccountId, pCdaAccountId, pPfAccountId, pPjAccountId, pDocdate);
    end if;

    -- Si le gabarit n'autorise pas les comptes financiers
    if     lnFinancialCharge = 0
       and lnVisiblAccount = 0 then
      pFinAccountId  := null;
      pDivAccountId  := null;
    end if;

    -- Si le gabarit n'autorise pas les comptes analytiques
    if     lnAnalyticalCharge = 0
       and lnVisiblAccount = 0 then
      pCdaAccountId  := null;
      pCpnAccountId  := null;
      pPfAccountId   := null;
      pPjAccountId   := null;
    end if;
  end GetFinancialInfo;

  /**
  * Description
  *   Recherche de l'id du texte de pied numéro N sur le tiers puis sur le gabarit
  */
  function GetFootTextId(aFootTextNum in number, aGaugeId in DOC_DOCUMENT.DOC_GAUGE_ID%type, aThirdId in DOC_DOCUMENT.PAC_THIRD_ID%type)
    return DOC_FOOT.PC_APPLTXT_ID%type
  is
    vFootText1 DOC_FOOT.PC_APPLTXT_ID%type;
    vFootText2 DOC_FOOT.PC_APPLTXT_ID%type;
    vFootText3 DOC_FOOT.PC_APPLTXT_ID%type;
    vFootText4 DOC_FOOT.PC_APPLTXT_ID%type;
    vFootText5 DOC_FOOT.PC_APPLTXT_ID%type;
  begin
    vFootText1  := null;
    vFootText2  := null;
    vFootText3  := null;
    vFootText4  := null;
    vFootText5  := null;

    select decode(GAU.GAU_APPLTXT_3
                , 1, nvl(decode(GAU.C_ADMIN_DOMAIN
                              , '1', SUP.PC_APPLTXT_ID
                              , '2', CUS.PC_APPLTXT_ID
                              , '5', SUP.PC_APPLTXT_ID
                              , nvl(CUS.PC_APPLTXT_ID, SUP.PC_APPLTXT_ID)
                               )
                       , GAU.PC_3_PC_APPLTXT_ID
                        )
                , null
                 )
         , decode(GAU.GAU_APPLTXT_4
                , 1, nvl(decode(GAU.C_ADMIN_DOMAIN
                              , '1', SUP.PC__PC_APPLTXT_ID
                              , '2', CUS.PC__PC_APPLTXT_ID
                              , '5', SUP.PC__PC_APPLTXT_ID
                              , nvl(CUS.PC__PC_APPLTXT_ID, SUP.PC__PC_APPLTXT_ID)
                               )
                       , GAU.PC_4_PC_APPLTXT_ID
                        )
                , null
                 )
         , decode(GAU.GAU_APPLTXT_5
                , 1, nvl(decode(GAU.C_ADMIN_DOMAIN
                              , '1', SUP.PC_2_PC_APPLTXT_ID
                              , '2', CUS.PC_2_PC_APPLTXT_ID
                              , '5', SUP.PC_2_PC_APPLTXT_ID
                              , nvl(CUS.PC_2_PC_APPLTXT_ID, SUP.PC_2_PC_APPLTXT_ID)
                               )
                       , GAU.PC_5_PC_APPLTXT_ID
                        )
                , null
                 )
         , decode(GAU.GAU_APPLTXT_6
                , 1, nvl(decode(GAU.C_ADMIN_DOMAIN
                              , '1', SUP.PC_3_PC_APPLTXT_ID
                              , '2', CUS.PC_3_PC_APPLTXT_ID
                              , '5', SUP.PC_3_PC_APPLTXT_ID
                              , nvl(CUS.PC_3_PC_APPLTXT_ID, SUP.PC_3_PC_APPLTXT_ID)
                               )
                       , GAU.PC_6_PC_APPLTXT_ID
                        )
                , null
                 )
         , decode(GAU.GAU_APPLTXT_7
                , 1, nvl(decode(GAU.C_ADMIN_DOMAIN
                              , '1', SUP.PC_4_PC_APPLTXT_ID
                              , '2', CUS.PC_4_PC_APPLTXT_ID
                              , '5', SUP.PC_4_PC_APPLTXT_ID
                              , nvl(CUS.PC_4_PC_APPLTXT_ID, SUP.PC_4_PC_APPLTXT_ID)
                               )
                       , GAU.PC_7_PC_APPLTXT_ID
                        )
                , null
                 )
      into vFootText1
         , vFootText2
         , vFootText3
         , vFootText4
         , vFootText5
      from DOC_GAUGE GAU
         , (select sum(PC_APPLTXT_ID) PC_APPLTXT_ID
                 , sum(PC__PC_APPLTXT_ID) PC__PC_APPLTXT_ID
                 , sum(PC_2_PC_APPLTXT_ID) PC_2_PC_APPLTXT_ID
                 , sum(PC_3_PC_APPLTXT_ID) PC_3_PC_APPLTXT_ID
                 , sum(PC_4_PC_APPLTXT_ID) PC_4_PC_APPLTXT_ID
              from PAC_CUSTOM_PARTNER
             where PAC_CUSTOM_PARTNER_ID = aThirdId) CUS
         , (select sum(PC_APPLTXT_ID) PC_APPLTXT_ID
                 , sum(PC__PC_APPLTXT_ID) PC__PC_APPLTXT_ID
                 , sum(PC_2_PC_APPLTXT_ID) PC_2_PC_APPLTXT_ID
                 , sum(PC_3_PC_APPLTXT_ID) PC_3_PC_APPLTXT_ID
                 , sum(PC_4_PC_APPLTXT_ID) PC_4_PC_APPLTXT_ID
              from PAC_SUPPLIER_PARTNER
             where PAC_SUPPLIER_PARTNER_ID = aThirdId) SUP
     where GAU.DOC_GAUGE_ID = aGaugeId;

    if aFootTextNum = 1 then
      return vFootText1;
    elsif aFootTextNum = 2 then
      return vFootText2;
    elsif aFootTextNum = 3 then
      return vFootText3;
    elsif aFootTextNum = 4 then
      return vFootText4;
    elsif aFootTextNum = 5 then
      return vFootText5;
    end if;
  end GetFootTextId;

  /**
  * Description
  *   Logistic document confirmation
  */
  procedure ConfirmDocument(
    aDocumentId       in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aErrorCode        out    varchar2
  , aErrorText        out    varchar2
  , aUserConfirmation in     number default 1
  )
  is
    cursor crDOCUMENT(cDocumentID number)
    is
      select DMT.DMT_PROTECTED
           , DMT.DMT_NUMBER
           , DMT.PAC_THIRD_ID
           , nvl(DMT.DMT_ONLY_AMOUNT_BILL_BOOK, 0) DMT_ONLY_AMOUNT_BILL_BOOK
           , GAU.DOC_GAUGE_ID
           , GAU.C_ADMIN_DOMAIN
           , GAU.C_GAUGE_TYPE
           , GAU.GAU_CONFIRM_STATUS
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_DATE_VALUE
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.C_DOC_CREATE_MODE
           , GAS.C_CREDIT_LIMIT
           , DMT.C_DOCUMENT_STATUS
           , nvl(DMT.C_CREDIT_LIMIT_CHECK, '0') C_CREDIT_LIMIT_CHECK
           , nvl(DMT.DMT_CONFIRMED, 0) DMT_CONFIRMED
           , DMT.ACT_DOCUMENT_ID
           , DMT.COM_NAME_ACI
           , GAS.C_DOC_PRE_ENTRY
           , FOO.FOO_DOCUMENT_TOTAL_AMOUNT
           , FOO.DIC_TYPE_DOC_CUSTOM_ID
           , FOO.C_DIRECTION_NUMBER
           , DMT.PAC_SENDING_CONDITION_ID
           , GAS.GAS_BALANCE_STATUS
           , GAS.GAS_FINANCIAL_CHARGE
           , GAS.GAS_ANAL_CHARGE
           , GAS.C_TYPE_EDI GAS_C_TYPE_EDI
           , GAS.C_CONTROLE_DATE_DOCUM
           , GAS.C_START_CONTROL_DATE
           , GAS.GAS_EDI_EXPORT_METHOD
           , GAS.GAS_AUTO_ATTRIBUTION
           , GAS.GAS_WEIGHT_MAT
           , GAS.GAS_STORED_PROC_CONFIRM
           , GAS.GAS_STORED_PROC_AFTER_CONFIRM
           , GAS.GAS_INSTALLATION_MGM
           , GAS.GAS_INSTALLATION_REQUIRED
           , GAS.C_BUDGET_CONTROL
           , GAS.C_BUDGET_CALCULATION_MODE
           , GAS.C_BUDGET_CONSUMPTION_TYPE
           , GAS.DIC_GAU_NATURE_CODE_ID
           , GAS.GAS_CHECK_INVOICE_EXPIRY_LINK
           , nvl(GAS.GAS_CASH_MULTIPLE_TRANSACTION, 0) GAS_CASH_MULTIPLE_TRANSACTION
           , decode(GAU.C_ADMIN_DOMAIN, '1', SUP.CRE_DATA_EXPORT, '2', CUS.CUS_DATA_EXPORT, CUS.CUS_DATA_EXPORT) PAC_EDI_EXPORT_METHOD
           , decode(GAU.C_ADMIN_DOMAIN, '1', SUP.C_TYPE_EDI, '2', CUS.C_TYPE_EDI, CUS.C_TYPE_EDI) PAC_C_TYPE_EDI
           , CUS.CUS_RATE_FOR_VALUE
           , DMT.PC_CNTRY_ID
           , GAS.C_GAUGE_TITLE
           , DMT.PAC_EBPP_REFERENCE_ID
           , DMT.PC_EXCHANGE_SYSTEM_ID
           , DMT.PAC_PAYMENT_CONDITION_ID
           , ECS.C_ECS_BSP
           , FOO.DOC_FOOT_ID
           , nvl(PCO.C_DIRECT_PAY, '0') C_DIRECT_PAY
        from DOC_DOCUMENT DMT
           , DOC_FOOT FOO
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PAYMENT_CONDITION PCO
           , PCS.PC_EXCHANGE_SYSTEM ECS
       where GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DMT.DOC_DOCUMENT_ID = cDocumentId
         and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and DMT.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+)
         and DMT.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID(+)
         and DMT.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID;

    returnCharId            GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    protection              DOC_DOCUMENT.DMT_PROTECTED%type;
    partnerType             varchar2(1);
    tplDocument             crDOCUMENT%rowtype;
    customError             varchar2(100);
    weightDone              number(1);
    amountMatOk             number(1);
    amountAlloyOk           number(1);
    advanceOk               number(1);
    stockOK                 number(1);
    errorTitle              varchar2(100);
    errorMsg                varchar2(4000);
    confirmFail             varchar2(100);
    ctrlOK                  integer;
    vDmtProtected           integer;
    vContinueConfirm        integer;
    vErrorText              varchar2(4000);
    vErrorCode              varchar2(30);
    vPaymentDateCount       integer;
    vPAD_BVR_REFERENCE_NUM  DOC_PAYMENT_DATE.PAD_BVR_REFERENCE_NUM%type;
    cDocumentStatus         DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    gapMvtCount             integer;
    vUnknownException       integer;
    dcbProcessing           DOC_CONFIRMATION_BUFFER.DCB_PROCESSING%type;
    dmtFinancialCharging    DOC_DOCUMENT.DMT_FINANCIAL_CHARGING%type;
    vCheckFinancialCharging number;
    vPositionCount          integer;
    vFootChargeCount        integer;
    vErrMess                DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    vBackTrace              DOC_DOCUMENT.DMT_ERROR_MESSAGE%type;
    idTrans                 varchar2(100);
    inGauRefPartner         DOC_GAUGE.GAU_REF_PARTNER%type;
    lbReceiptSubcontractO   boolean;
    lbReceiptSubcontractP   boolean;
  begin
    vUnknownException  := 1;
    savepoint beforeconfirm;

    -- charge les infos relatives au document
    open crDOCUMENT(aDocumentId);

    fetch crDOCUMENT
     into tplDocument;

    if crDocument%notfound then
      aErrorCode         := '000';   -- Code inexistant qui indique juste que le document n'existe pas
      vUnknownException  := 0;

      close crDOCUMENT;

      raise_application_error(-20000, 'PCS - document does not exist');
    end if;

    close crDOCUMENT;

    -- Vérifie que le document est bien à confirmer pour autant que la confirmation soit bien demandé par l'utilisateur
    if    (tplDocument.C_DOCUMENT_STATUS = '01')
       or (aUserConfirmation = 0) then
      -- teste si le document est protégé avant la confirmation
      if tplDocument.DMT_PROTECTED = 1 then
        aErrorCode         := '001';
        vUnknownException  := 0;
        raise_application_error(-20000, aErrorCode);
      end if;

      -- protection de document
      update DOC_DOCUMENT
         set DMT_PROTECTED = 1
       where DOC_DOCUMENT_ID = aDocumentID;

      -- remise à 0 des contrôles de rupture de stock
      DOC_I_PRC_POSITION.ClearPositionsError(aDocumentId);

      -- call before confirm external procedure
      if     (tplDocument.DMT_CONFIRMED = 0)
         and (tplDocument.GAS_STORED_PROC_CONFIRM is not null) then
        -- Récupère l'ID de la transaction pour savoir si un commit a été effectué dans les procédures externes
        idTrans  := DBMS_TRANSACTION.local_transaction_id;
        DOC_FUNCTIONS.ExecuteExternProc(aDocumentId, tplDocument.GAS_STORED_PROC_CONFIRM, aErrorText);

        if nvl(idTrans, '0') <> nvl(DBMS_TRANSACTION.local_transaction_id, '0') then
          -- Déplace le savepoint pour pouvoir annuler la partie confirmation après l'execution des procédures externes. C'est dans le cas
          -- ou par "malheur" un commit serait effectué dans les procédures externes.
          savepoint beforeconfirm;
        end if;

        -- Arreter la confirmation si le contrôle utilisateur a échoué
        if instr(upper(aErrorText), '[ABORT]') > 0 then
          aErrorCode         := '900';
          aErrorText         := aErrorText || ' - Before confirm';
          vUnknownException  := 0;
          raise_application_error(-20000, aErrorCode);
        end if;
      end if;

      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId, null, tplDocument.DMT_NUMBER, 'PL/SQL', 'START CONFIRM DOCUMENT', null, null, null);

      -- contrôle de validité de la date du document
      if tplDocument.C_START_CONTROL_DATE in('2', '3') then
        ValidateDocumentDate(tplDocument.DMT_DATE_DOCUMENT, tplDocument.C_CONTROLE_DATE_DOCUM, errorTitle, errorMsg, confirmFail, ctrlOK);

        if ctrlOk = 0 then
          aErrorCode         := confirmFail;

          if errorTitle is not null then
            aErrorText  := errorTitle || ' - ' || errorMsg;
          else
            aErrorText  := errorMsg;
          end if;

          vUnknownException  := 0;
          raise_application_error(-20000, aErrorCode);
        end if;
      end if;

      -- Controle de la présence de détail de position
      if controlDetailPosition(aDocumentID) = 0 then
        aErrorCode  := '128';
        vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Document sans détail de position! (Chaque position doit avoir au moins un détail)');
        raise_application_error(-20000, aErrorCode);
      end if;

      -- Vérifie que les emplacements de stock soient initialisés sur les détails
      -- si la position génére un mvt de stock
      if ControlDetailStock(aDocumentID) = 0 then
        aErrorCode  := '129';
        vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('L''emplacement de stock manque sur un détail de position qui génère un mouvement!');
        raise_application_error(-20000, aErrorCode);
      end if;

      -- Contrôle de la limite de crédit
      begin
        if     tplDocument.C_CREDIT_LIMIT = '2'
           and tplDocument.C_CREDIT_LIMIT_CHECK != '01'
           and tplDocument.C_DOCUMENT_STATUS not in('03', '04') then
          if controlCreditLimit(aDocumentId
                              , tplDocument.C_ADMIN_DOMAIN
                              , tplDocument.C_CREDIT_LIMIT
                              , tplDocument.PAC_THIRD_ID
                              , tplDocument.ACS_FINANCIAL_CURRENCY_ID
                              , tplDocument.DMT_DATE_DOCUMENT
                               ) = 0 then
            aErrorCode         := '102';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '306';
          end if;

          raise;
      end;

      /* Si la config budget est activée             ET
          le gabarit gére le contrôle de budget     ET
          Consommation de budget                    ET
          Document non soldé partiellement          ET
          Document non liquidé                      Alors
        Contrôler le dépassement de budget           */
      begin
        if     (PCS.PC_CONFIG.GetConfig('DOC_ENABLE_BUDGET') = '1')
           and (tplDocument.C_BUDGET_CONTROL <> '0')
           and (tplDocument.C_BUDGET_CALCULATION_MODE = 'REMOVE')
           and (tplDocument.C_DOCUMENT_STATUS not in('03', '04') ) then
          -- Contrôle du dépassement de budget
          if ControlBudgetExceeding(aDocumentId        => aDocumentId
                                  , aConsumptionType   => tplDocument.C_BUDGET_CONSUMPTION_TYPE
                                  , aNatureCode        => tplDocument.DIC_GAU_NATURE_CODE_ID
                                  , aDateValue         => tplDocument.DMT_DATE_VALUE
                                  , aBudgetControl     => tplDocument.C_BUDGET_CONTROL
                                  , aConfirmStatus     => tplDocument.GAU_CONFIRM_STATUS
                                  , aBalanceStatus     => tplDocument.GAS_BALANCE_STATUS
                                  , aDocStatus         => tplDocument.C_DOCUMENT_STATUS
                                  , aContinueConfirm   => vContinueConfirm
                                   ) = 0 then
            aErrorCode  := '115';

            if tplDocument.C_BUDGET_CONTROL = '2' then
              vErrorText  :=
                PCS.PC_FUNCTIONS.TranslateWord('Dépassement de budget bloquant !') || ' '
                || PCS.PC_FUNCTIONS.TranslateWord('Veuillez contrôler les positions.');
              addText(aErrorText, vErrorText);
            end if;

            if vContinueConfirm = 0 then
              vUnknownException  := 0;
              raise_application_error(-20000, aErrorCode);
            else
              update DOC_DOCUMENT
                 set C_CONFIRM_FAIL_REASON = aErrorCode
                   , DMT_ERROR_MESSAGE = aErrorText
               where DOC_DOCUMENT_ID = aDocumentID;
            end if;
          end if;
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '315';
          end if;

          raise;
      end;

      -- Contrôle des installations sur les détails
      if     (tplDocument.GAS_INSTALLATION_MGM = 1)
         and (tplDocument.GAS_INSTALLATION_REQUIRED = 1) then
        begin
          -- Contrõle des installations sur les détails
          DOC_FUNCTIONS.CheckDetailInstallation(aDocumentId, returnCharId);

          if nvl(returnCharId, 0) <> 0 then
            aErrorCode         := '114';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '314';
            end if;

            raise;
        end;
      end if;

      -- Control des caratérisations
      begin
        DOC_FUNCTIONS.CheckCharacterizationParity(aDocumentId, returnCharId);

        if nvl(returnCharId, 0) <> 0 then
          aErrorCode         := '111';
          vUnknownException  := 0;
          raise_application_error(-20000, aErrorCode);
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '308';
          end if;

          raise;
      end;

      -- contrôle de l'existance du tiers si celui-ci est obligatoire
      if tplDocument.C_ADMIN_DOMAIN in('1', '2', '5', '7') then   /* => Achat, Vente, Sous-traitance, SAV => Tiers possible */
        select GAU_REF_PARTNER
          into inGauRefPartner
          from DOC_GAUGE
         where DOC_GAUGE_ID = tplDocument.DOC_GAUGE_ID;

        if (inGauRefPartner = 1) then   /* => Tier obligatoire */
          if PAC_FUNCTIONS.ControlThirdExist(tplDocument.PAC_THIRD_ID, tplDocument.C_ADMIN_DOMAIN) = 0 then
            aErrorCode         := '101';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      end if;

      -- contrôle des colis
      if not DOC_PACKING.PackingValidate(aDocumentId) then
        aErrorCode         := '104';
        vUnknownException  := 0;
        raise_application_error(-20000, aErrorCode);
      end if;

      -- controle de parité de la présaisie (Contrôle du montant logistique et comptable)
      if ctrlAmountLogisticFinancial(tplDocument.ACT_DOCUMENT_ID
                                   , tplDocument.C_DOC_PRE_ENTRY
                                   , tplDocument.FOO_DOCUMENT_TOTAL_AMOUNT
                                   , tplDocument.ACS_FINANCIAL_CURRENCY_ID
                                   , ACI_LOGISTIC_DOCUMENT.GetFinancialCompany(tplDocument.DOC_GAUGE_ID, tplDocument.PAC_THIRD_ID)
                                    ) = 0 then
        aErrorCode         := '103';
        vUnknownException  := 0;
        raise_application_error(-20000, aErrorCode);
      end if;

      -- Contrôle des références BVR
      begin
        if ctrlPaymentsBvr(aDocumentId) = 0 then
          aErrorCode         := '113';
          vUnknownException  := 0;
          raise_application_error(-20000, aErrorCode);
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '313';
          end if;

          raise;
      end;

      --
      -- Contrôle de cohérence relatif aux données EBPP
      --
      begin
        -- Vérifie l'existance d'au moins une position ou une remise/taxe/frais de pied.
        if     tplDocument.PAC_EBPP_REFERENCE_ID is not null
           and tplDocument.PC_EXCHANGE_SYSTEM_ID is not null
           and tplDocument.C_ECS_BSP in('00', '01')
           and tplDocument.C_GAUGE_TITLE in('8', '9', '30') then
          select (select count(POS.DOC_POSITION_ID)
                    from DOC_POSITION POS
                   where POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID) POS_COUNT
               , (select count(FCH.DOC_FOOT_CHARGE_ID)
                    from DOC_FOOT_CHARGE FCH
                   where FCH.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID) FCH_COUNT
            into vPositionCount
               , vFootChargeCount
            from DOC_DOCUMENT DMT
           where DMT.DOC_DOCUMENT_ID = aDocumentId;

          if     nvl(vPositionCount, 0) = 0
             and nvl(vFootChargeCount, 0) = 0 then
            vErrorText         :=
              PCS.PC_FUNCTIONS.TranslateWord('Contrôle de cohérence relatif aux données EBPP') ||
              co.cLineBreak ||
              PCS.PC_FUNCTIONS.TranslateWord('Données manquantes - Un document électronique doit avoir au moins une position ou une remise/taxe de pied.');
            addText(aErrorText, vErrorText);
            aErrorCode         := '117';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;

        -- Contrôle de la condition de paiement (échéances mono-tranche)
        if tplDocument.C_ECS_BSP in('00', '01') then
          select count(*)
            into vPaymentDateCount
            from (select   PAD_BAND_NUMBER
                      from DOC_PAYMENT_DATE
                     where DOC_FOOT_ID = tplDocument.DOC_FOOT_ID
                  group by PAD_BAND_NUMBER);

          if vPaymentDateCount > 1 then
            aErrorCode         := '124';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;

        -- Contrôle de la référence BVR (si échéance mono-tranche )
        if     tplDocument.C_GAUGE_TITLE in('8', '30')
           and tplDocument.PAC_EBPP_REFERENCE_ID is not null
           and tplDocument.PC_EXCHANGE_SYSTEM_ID is not null then
          select max(PAD_BVR_REFERENCE_NUM)
            into vPAD_BVR_REFERENCE_NUM
            from DOC_PAYMENT_DATE PAD
           where DOC_FOOT_ID = tplDocument.DOC_FOOT_ID
             and PAD.PAD_NET = 1;

          if vPAD_BVR_REFERENCE_NUM is null then
            aErrorCode         := '113';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '324';
          end if;

          raise;
      end;

      -- Contrôle de l'encaissement pour les transactions multiples
      begin
        if (tplDocument.GAS_CASH_MULTIPLE_TRANSACTION = 1) then
          DOC_FOOT_PAYMENT_FUNCTIONS.CtrlFootPayment(aFootID => tplDocument.DOC_FOOT_ID, aDirectPay => tplDocument.C_DIRECT_PAY, aErrorCode => aErrorCode);

          if aErrorCode is not null then
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '326';
          end if;

          raise;
      end;

      -- contrôle qu'il n'y ait pas de position de stock en cours d'inventaire
      begin
        if DOC_FUNCTIONS.IsStockInventoring(null, aDocumentId) = 1 then
          aErrorCode         := '112';
          vUnknownException  := 0;
          raise_application_error(-20000, aErrorCode);
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '312';
          end if;

          raise;
      end;

      --
      -- Réception OF sous-traitance Achat à la confirmation si :
      --    - Le gabarit est un gabarit de sous-traitance achat (C_DOC_LOT_TYPE = '001' sur DOC_GAUGE_POSITION)
      --    - Le document provoque des réceptions d'OF (MOK_BATCH_RECEIPT = 1 sur type de mouvement lié à au moins un position)
      --    - Aucun parent du document ne provoque des réceptions d'OF
      --    - Le document est un Bulletin de réception STA (BRAST) ou une Facture Fournisseur STA (FFAST). }
      lbReceiptSubcontractP  :=(DOC_LIB_SUBCONTRACTP.doReceive(iDocumentId => aDocumentId) = 1);
      --
      -- Indique si le document demande le transfert des composants du stock sous-traitant en atelier
      --
      -- 1. position de type bien (exclu les positions outils)
      -- 2. opération de sous-traitance lié
      -- 3. initialisation de la quantité du mouvement demandé par le flux
      -- 4. exclu les opérations de sous-traitance d'achat
      -- 5. genre de mouvement spécifié sur la position (BRCST, BRST ou FFST)
      -- 6. demande de mise à jour de l'opération par le genre de mouvement (en principe BRST et FFST)
      --
      lbReceiptSubcontractO  := DOC_LIB_SUBCONTRACTO.DoDocumentComponentsMvt(aDocumentId) = 1;

      if lbReceiptSubcontractP then
        -- Sous-traitance d'achat - Contrôle de l'appairage si réception OF
        begin
          if DOC_LIB_SUBCONTRACTP.isDocumentAlignementMissing(iDocumentID => aDocumentId) = 1 then
            vErrorText         := PCS.PC_FUNCTIONS.TranslateWord('Des appairages sont manquants !');
            addText(aErrorText, vErrorText);
            aErrorCode         := '141';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Erreur lors du contrôle de l''appairage !');
              addText(aErrorText, vErrorText);
              aErrorCode  := '341';
            end if;

            raise;
        end;
      end if;

      if lbReceiptSubcontractO then
        -- Sous-traitance opératoire - Contrôle des quantités disponibles en stock sous-traitant
        begin
          if DOC_LIB_SUBCONTRACTO.IsBatchCptStkOutage(iDocumentID => aDocumentId) = 1 then
            aErrorCode         := '150';   -- Des composants de sous-traitances sont manquants
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '350';   -- Erreur lors du contrôle des cpsants sous-traitance
            end if;

            raise;
        end;

        -- Sous-traitance opératoire - Contrôle que les lots associés aux positions d'un BST ou FST soient lancés pour permettre la réception du lot
        begin
          vErrorText  := '';
          DOC_LIB_SUBCONTRACTO.checkBatchesLaunch(iDocumentID => aDocumentId, oError => vErrorText);

          if vErrorText is not null then
            addText(aErrorText, vErrorText);
            aErrorCode         := '152';   -- Contrôle du statut du lot avant la réception
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '352';   -- Erreur au contrôle du statut du lot à la réception
            end if;

            raise;
        end;

        -- Sous-traitance opératoire - Contrôle des quantités disponibles au suivi d'avancement
        begin
          if DOC_LIB_SUBCONTRACTO.canConfirmBST(iDocumentID => aDocumentId) <> 1 then
            vErrorText         := PCS.PC_FUNCTIONS.TranslateWord('Pas assez de qté réalisée sur l op. préc. pour effectuer le suivi !');
            addText(aErrorText, vErrorText);
            aErrorCode         := '151';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              vErrorText  := PCS.PC_FUNCTIONS.TranslateWord('Erreur lors du contrôle des quantités disponibles au suivi d avancement');
              addText(aErrorText, vErrorText);
              aErrorCode  := '351';
            end if;

            raise;
        end;
      end if;

      -- contrôle que le document n'ait pas de position en manco
      if isStockOutage(aDocumentId) = 1 then
        aErrorCode         := '100';
        vUnknownException  := 0;
        raise_application_error(-20000, aErrorCode);
      end if;

      -- contrôle les données relatives aux matières précieuses
      if tplDocument.GAS_WEIGHT_MAT = 1 then
        begin
          DOC_FOOT_ALLOY_FUNCTIONS.TestDocumentFoot(aDocumentID, weightDone, amountMatOk, amountAlloyOk, advanceOk, stockOk);

          -- saisie de montant à facturer pour les matières de base
          if amountMatOk = 0 then
            aErrorCode         := '120';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;

          -- saisie de montants à facturer pour les alliages
          if amountAlloyOk = 0 then
            aErrorCode         := '121';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;

          -- avances à décompter
          if advanceOk = 0 then
            aErrorCode         := '122';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;

          -- pesées manquantes
          if weightDone = 0 then
            aErrorCode         := '123';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;

          -- rupture de stock matières précieuses
          if stockOk = 0 then
            aErrorCode         := '125';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '320';
            end if;

            raise;
        end;
      end if;

      -- Contrôle du risque de change
      if     (PCS.PC_CONFIG.GetConfig('COM_CURRENCY_RISK_MANAGE') = '1')
         and (tplDocument.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId) then
        begin
          -- Contrôles sur le document par rapport au risque de change
          DOC_PRC_DOCUMENT.CtrlDocumentCurrencyRisk(iDocumentID => aDocumentId, oErrorCode => aErrorCode);

          if aErrorCode is not null then
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          else
            -- Màj de totaux au cas ou l'utilisateur n'a pas lancé un FinalizeDocument avant
            -- d'appeler cette méthode de confirmation
            DOC_FUNCTIONS.UpdateBalanceTotal(aDocumentID);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '345';
            end if;

            raise;
        end;
      end if;

      -- Contrôle des tarifs douaniers
      vErrorText             := '';

      if     tplDocument.DIC_TYPE_DOC_CUSTOM_ID is not null
         and CtrlCustomData(aDocumentID, vErrorText) = 0 then
        if vErrorText is not null then
          addText(aErrorText, vErrorText);
        end if;

        aErrorCode         := '201';
        vUnknownException  := 0;
        raise_application_error(-20000, aErrorCode);
      end if;

      -- Recherche s'il y des gabarits positions avec un mvt lié
      select count(DOC_GAUGE_POSITION_ID)
        into gapMvtCount
        from DOC_GAUGE_POSITION
       where DOC_GAUGE_ID = tplDocument.DOC_GAUGE_ID
         and STM_MOVEMENT_KIND_ID is not null;

      -- Mise à jour des statuts qualité
      begin
        DOC_PRC_POSITION.SyncPositionQualityStatus(aDocumentId);
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '360';   -- Erreur lors de la mise à jour du statut qualité
          end if;

          raise;
      end;

      -- Faire la la MAJ des prix de mvt seulement si au moins 1 des gabarits positions possède un mvt lié
      if nvl(gapMvtCount, 0) > 0 then
        -- mise à jour des prix unitaires (POS_UNIT_COST_PRICE)
        begin
          DOC_FUNCTIONS.DocUpdateDetailMovementPrice(aDocumentId);
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '320';
            end if;

            raise;
        end;

        -- Génération des mouvements de stock
        -- et mise à jour des opérations de sous-traitance par trigger
        begin
          vErrorText  := '';
          DOC_INIT_MOVEMENT.GenerateDocMovements(aDocumentId => aDocumentId, aSubCtError => vErrorText);

          -- Erreur gérée par la procédure
          if vErrorText is not null then
            addText(aErrorText, vErrorText);
            aErrorCode         := '309';   -- Mise à jour des opérations de sous-traitance impossible
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '304';   -- Génération des mouvements de stock impossible
            end if;

            raise;
        end;
      end if;

      -- Sous-traitance d'achat
      if DOC_LIB_SUBCONTRACTP.IsGaugeSubcontractP(tplDocument.DOC_GAUGE_ID) = 1 then
        if DOC_LIB_SUBCONTRACTP.IsSUPOGauge(tplDocument.DOC_GAUGE_ID) = 1 then
          -- lancement de l'OF lié
          vErrorText  := '';
          DOC_PRC_DOCUMENT.LaunchSubContractPBatches(aDocumentId, vErrorText);

          if vErrorText is not null then
            addText(aErrorText, vErrorText);
            aErrorCode  := '330';
          end if;
        elsif lbReceiptSubcontractP then
          -- réception de l'OF lié
          vErrorText  := '';
          DOC_PRC_DOCUMENT.ReceiptSubContractPBatches(aDocumentId, vErrorText);

          if vErrorText is not null then
            addText(aErrorText, vErrorText);
            aErrorCode  := '340';
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      end if;

      -- Sous-traitance opératoire - génération des mouvements de composants (transfert en atelier)
      if     lbReceiptSubcontractO
         and DOC_LIB_SUBCONTRACTO.DocMovementsGenerated(aDocumentId) = 0 then
        -- préparation des mouvements
        FAL_COMPONENT_MVT_SORTIE.ComponentAndLinkGenForOutput(aDOC_DOCUMENT_ID     => aDocumentId
                                                            , aFCL_SESSION_ID      => DBMS_SESSION.unique_session_id
                                                            , aComponentWithNeed   => 0
                                                            , aBalanceNeed         => 1
                                                            , aContext             => FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubCOComponentOutput
                                                             );
        -- génération des mouvements
        vErrorText  := '';
        FAL_COMPONENT_MVT_SORTIE.ApplyOutputMovements(aDOC_DOCUMENT_ID   => aDocumentId
                                                    , aLOM_SESSION       => DBMS_SESSION.unique_session_id
                                                    , aOutPutDate        => tplDocument.DMT_DATE_DOCUMENT
                                                    , aErrorCode         => aErrorCode
                                                    , aErrorMsg          => vErrorText
                                                     );

        -- si pas d'erreur et que tous les mouvements ont bien été générés
        if    vErrorText is not null
           or DOC_LIB_SUBCONTRACTO.DocMovementsGenerated(aDocumentId) = 0 then
          addText(aErrorText, vErrorText);
          aErrorCode  := '370';   -- Erreur lors des mvts des cpsants sous-traitance
          raise_application_error(-20000, aErrorCode);
        else
          -- mise à jour du flag indiquant que les mouvements composants STO ont étés faits (Déclenche la création du
          -- suivi opératoire via trigger )
          DOC_PRC_SUBCONTRACTO.FlagMovementsGenerated(aDocumentId);
        end if;
      end if;

      -- Mise à jour du statut du document uniquement à la confirmation utilisateur du document
      if (aUserConfirmation = 1) then
        begin
          DOC_PRC_DOCUMENT.ConfirmStatus(aDocumentId
                                       , tplDocument.GAS_BALANCE_STATUS
                                       , tplDocument.GAS_CHECK_INVOICE_EXPIRY_LINK
                                       , tplDocument.DMT_ONLY_AMOUNT_BILL_BOOK
                                        );
        -- Mise à jour du status des positions du document
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '310';
            end if;

            raise;
        end;
      end if;

      -- Initialisation des propriétés d'échange de données
      if     tplDocument.PAC_EBPP_REFERENCE_ID is not null
         and tplDocument.PC_EXCHANGE_SYSTEM_ID is not null
         and tplDocument.C_ECS_BSP in('00', '01')
         and tplDocument.C_GAUGE_TITLE in('8', '9', '30') then
        begin
          genCOM_EBANKING(aDocumentId);
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '325';
            end if;

            raise;
        end;
      end if;

      -- création de l'interface comptable
      begin
        if     (   tplDocument.GAS_FINANCIAL_CHARGE = 1
                or tplDocument.GAS_ANAL_CHARGE = 1)
           and PCS.PC_CONFIG.GetConfigUpper('DOC_FINANCIAL_IMPUTATION') = 'TRUE' then
          if (GenerateAciDocument(aDocumentId) = 0) then
            -- L'intégration n'a pas été effectué correctement
            aErrorCode         := '303';
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        end if;
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '303';
          end if;

          raise;
      end;

      -- dénormalisation de l'interface comptable sur les données EBPP
      update COM_EBANKING
         set ACI_DOCUMENT_ID = (select max(ACI_DOCUMENT_ID)
                                  from ACI_DOCUMENT
                                 where DOC_DOCUMENT_ID = aDocumentId)
       where DOC_DOCUMENT_ID = aDocumentId;

      -- génération du document d'export
      if    (    tplDocument.GAS_C_TYPE_EDI != '0'
             and tplDocument.GAS_EDI_EXPORT_METHOD is not null)
         or (    tplDocument.PAC_C_TYPE_EDI != '0'
             and tplDocument.PAC_EDI_EXPORT_METHOD is not null) then
        begin
          vErrorCode  := '';
          vErrorText  := '';
          generateEdiDocument(aDocumentId, vErrorCode, vErrorText);

          if vErrorText is not null then
            aErrorCode         := '302';   -- Création du fichier d'exportation impossible
            aErrorText         := vErrorText;
            vUnknownException  := 0;
            raise_application_error(-20000, aErrorCode);
          end if;
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '302';
            end if;

            raise;
        end;
      end if;

      -- Mise à jour des attribs automatiques document uniquement à la confirmation utilisateur du document
      if (aUserConfirmation = 1) then
        -- génération des attributions
        begin
          generateAutoAttrib(aDocumentId, tplDocument.C_GAUGE_TYPE, tplDocument.GAU_CONFIRM_STATUS, tplDocument.GAS_AUTO_ATTRIBUTION);
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '300';
            end if;

            raise;
        end;
      end if;

      -- Génération de la note de débit des litiges
      declare
        vID number(12);
      begin
        vID  := DOC_LITIG_FUNCTIONS.GenerateDebitNoteDoc(aDocumentID);
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '318';
          end if;

          raise;
      end;

      -- Génération des évènements dans les avenants du contrat
      begin
        genCML_Events(aDocumentId);
      exception
        when others then
          if aErrorCode is null then
            aErrorCode  := '307';
          end if;

          raise;
      end;

      -- Document issu de la facturation des contrats, màj des compteurs de facturation sur le contrat
      if tplDocument.C_DOC_CREATE_MODE = '160' then
        begin
          -- màj des compteurs de facturation sur le contrat
          UpdateContractAmounts(aDocumentID);
        exception
          when others then
            if aErrorCode is null then
              aErrorCode  := '327';
            end if;

            raise;
        end;
      end if;

      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                           , null
                                           , tplDocument.DMT_NUMBER
                                           , 'PL/SQL'
                                           , 'DOCUMENT CONFIRMATION END SUCCESSFULLY PROCESSED'
                                           , null
                                           , null
                                           , null
                                            );

      -- Réception automatique du lot de fabrication (sous-traitance)
      begin
        vErrorText  := '';
        AutoReceptSubContracting(aDocumentId, vErrorText);

        -- Réception automatique impossible mais non bloquante
        if vErrorText is not null then
          addText(aErrorText
                , PCS.PC_FUNCTIONS.TranslateWord('Erreur lors de la réception automatique des opérations de sous-traitance') ||
                  co.cLineBreak ||
                  co.cLineBreak ||
                  vErrorText
                 );
        end if;
      exception
        when others then
          vErrorText  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          -- Réception automatique impossible mais non bloquante
          addText(aErrorText
                , PCS.PC_FUNCTIONS.TranslateWord('Erreur lors de la réception automatique des opérations de sous-traitance') ||
                  co.cLineBreak ||
                  co.cLineBreak ||
                  vErrorText
                 );
      end;

      -- call after confirm external procedure
      if     (tplDocument.DMT_CONFIRMED = 0)
         and (tplDocument.GAS_STORED_PROC_AFTER_CONFIRM is not null) then
        vErrorText  := '';
        -- Récupère l'ID de la transaction pour savoir si un commit a été effectué dans les procédures externes
        idTrans     := DBMS_TRANSACTION.local_transaction_id;
        DOC_FUNCTIONS.ExecuteExternProc(aDocumentId, tplDocument.GAS_STORED_PROC_AFTER_CONFIRM, vErrorText);

        if nvl(idTrans, '0') <> nvl(DBMS_TRANSACTION.local_transaction_id, '0') then
          -- Déplace le savepoint pour pouvoir annuler la partie confirmation après l'execution des procédures externes. C'est dans le cas
          -- ou par "malheur" un commit serait effectué dans les procédures externes.
          savepoint beforeconfirm;
        end if;

        addText(aErrorText, vErrorText);
      end if;

      -- Déprotection de document et initialisation des champs d'erreur de confirmation.
      update DOC_DOCUMENT
         set DMT_PROTECTED = 0
           , DMT_CONFIRMED = 1
           , C_CONFIRM_FAIL_REASON = ''
           , DMT_ERROR_MESSAGE = aErrorText
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where DOC_DOCUMENT_ID = aDocumentID;

      -- Suppression du document de la liste des confirmations différées.
      begin
        select     nvl(DCB_PROCESSING, 0)
              into dcbProcessing
              from DOC_CONFIRMATION_BUFFER
             where DOC_DOCUMENT_ID = aDocumentId
        for update;

        if dcbProcessing = 0 then
          delete from DOC_CONFIRMATION_BUFFER
                where DOC_DOCUMENT_ID = aDocumentId;
        end if;
      exception
        when others then
          null;
      end;
    end if;
  exception
    when others then
      -- Sauvegarde les informations de l'exception principale.
      vErrMess    := sqlerrm;
      vBackTrace  := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      rollback to savepoint beforeconfirm;

      -- Garantit la mise à jour des flags de rupture si la confirmation n'aboutit pas à cause des mancos.
      if (aErrorCode = '100') then
        DOC_FUNCTIONS.FLAGPOSITIONMANCO(null, aDocumentId);
      end if;

      -- Déprotection de document si la limite de crédit n'est pas bloquante et dépassée
      if (aErrorCode = '102') then
        vDmtProtected  := 1;
      -- Gestion risque de change
      elsif(aErrorCode in('130', '131', '132', '133', '134') ) then
        vDmtProtected  := 1;
      else
        vDmtProtected  := 0;
      end if;

      -- Construit le texte d'erreur uniquement si c'est une erreur inconnue. Sinon on obtient toujours
      -- le code d'erreur Oracle -20000 suivi du code d'erreur PCS.
      if (vUnknownException = 1) then
        addText(aErrorText, vErrMess || co.cLineBreak || vBackTrace);
      end if;

      -- Effectue la mise à jour des champs du document uniquement si le document existe et qu'il n'était pas
      -- protégé avant la confirmation.
      if not(    (nvl(aErrorCode, 'null') = '000')
             or (nvl(aErrorCode, 'null') = '001') ) then
        update DOC_DOCUMENT
           set DMT_PROTECTED = vDmtProtected
             , C_CONFIRM_FAIL_REASON = aErrorCode
             , DMT_ERROR_MESSAGE = aErrorText
         where DOC_DOCUMENT_ID = aDocumentID;
      end if;

      -- Inscription de l'événement dans l'historique des modifications
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                           , null
                                           , null
                                           , 'PL/SQL'
                                           , 'DOCUMENT CONFIRMATION END WITH ERRORS'
                                           , 'Error Code : ' || aErrorCode || co.cLineBreak || vErrMess || chr(13) || vBackTrace
                                           , null
                                           , null
                                            );
  end ConfirmDocument;

  /**
  * Description
  *   controle la limite de crédit d'un document
  */
  function controlCreditLimit(
    aDocumentId     in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAdminDomain    in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aGaugeLimitType in DOC_GAUGE_STRUCTURED.C_CREDIT_LIMIT%type
  , aThirdId        in DOC_DOCUMENT.PAC_THIRD_ID%type
  , aCurrencyId     in DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocumentDate   in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  )
    return number
  is
    vPartnerType         varchar2(1);
    vPartnerCategory     PAC_CUSTOM_PARTNER.C_PARTNER_CATEGORY%type;
    vPartnerLimitType    PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    vPartnerLimitAmount  PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type;
    vPartnerLimitDate    PAC_CREDIT_LIMIT.CRE_LIMIT_DATE%type;
    vPartnerAuxAccount   number;
    vPartnerDocAmount    number;
    vGroupLimitType      PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type;
    vGroupLimitAmount    PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type;
    vGroupLimitDate      PAC_CREDIT_LIMIT.CRE_LIMIT_DATE%type;
    vGroupAuxAccount     number;
    vGroupDocAmount      number;
    vAuxBalanceAmount    ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    vOpenDocumentsAmount DOC_FOOT.FOO_GOOD_TOTAL_AMOUNT%type;
  begin
    -- blocage possible uniquement si au minimum le type de limite logistique est bloquant
    if aGaugeLimitType = '2' then
      -- recherche du type de partenaire
      if aAdminDomain = cAdminDomainPurchase then
        vPartnerType  := 'S';

        select nvl(C_PARTNER_CATEGORY, '0')
          into vPartnerCategory
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = aThirdId;
      else
        vPartnerType  := 'C';

        select nvl(C_PARTNER_CATEGORY, '0')
          into vPartnerCategory
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aThirdId;
      end if;

      GetCreditLimit(vPartnerType
                   , aThirdID
                   , aCurrencyId
                   , aDocumentDate
                   , vPartnerCategory
                   , vPartnerLimitType
                   , vPartnerLimitAmount
                   , vGroupLimitType
                   , vGroupLimitAmount
                    );

      -- S'il existe un contrôle sur la limite
      if    (vPartnerLimitType in('2', '3') )
         or (vGroupLimitType in('2', '3') ) then
        -- Recherche du Solde du compte auxiliaire en MB et
        -- Recherche du montant total des documents (montant ouvert)
        GetCreditLimitAmounts(aThirdID, vPartnerCategory, vPartnerType, aDocumentID, vPartnerAuxAccount, vPartnerDocAmount, vGroupAuxAccount, vGroupDocAmount);

        -- Limite individuelle
        if vPartnerCategory in('1', '4') then
          vGroupLimitType    := 0;
          vGroupLimitAmount  := 0;
          vGroupDocAmount    := 0;
          vGroupAuxAccount   := 0;
        end if;

        -- Contrôle du dépassement de la limite partenaire
        if     vPartnerLimitType in('2', '3')
           and ( (vPartnerAuxAccount + vPartnerDocAmount) > vPartnerLimitAmount) then
          return 0;
        end if;

        -- Contrôle du dépassement de la limite groupe
        if     vGroupLimitType in('2', '3')
           and ( (vGroupAuxAccount + vGroupDocAmount) > vGroupLimitAmount) then
          return 0;
        end if;
      end if;
    end if;

    return 1;
  end controlCreditLimit;

  /**
   * Description
   *   Recherche les limites de crédit pour le tiers et son groupe
   */
  procedure GetCreditLimit(
    aPartnerType        in     varchar2
  , aThirdID            in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aCurrencyId         in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aDocumentDate       in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aPartnerCategory    in     PAC_CUSTOM_PARTNER.C_PARTNER_CATEGORY%type
  , aPartnerLimitType   out    PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type
  , aPartnerLimitAmount out    PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type
  , aGroupLimitType     out    PAC_CREDIT_LIMIT.C_LIMIT_TYPE%type
  , aGroupLimitAmount   out    PAC_CREDIT_LIMIT.CRE_AMOUNT_LIMIT%type
  )
  is
    vCreditDate date;
  begin
    -- recherche des infos sur la limite de crédit comptable individuelle
    PAC_PARTNER_MANAGEMENT.GetCreditLimit(aPartnerType
                                        , aThirdId
                                        , aCurrencyId
                                        , aDocumentDate
                                        , 0   -- Limite individuelle
                                        , aPartnerLimitAmount
                                        , aPartnerLimitType
                                        , vCreditDate
                                         );

    -- pas de limite trouvée en monnaie document alors on recherche en monnaie de base
    if     aPartnerLimitAmount is null
       and aCurrencyId <> ACS_FUNCTION.GetLocalCurrencyId then
      PAC_PARTNER_MANAGEMENT.GetCreditLimit(aPartnerType
                                          , aThirdId
                                          , ACS_FUNCTION.GetLocalCurrencyId
                                          , aDocumentDate
                                          , 0   -- Limite individuelle
                                          , aPartnerLimitAmount
                                          , aPartnerLimitType
                                          , vCreditDate
                                           );
    end if;

    if aPartnerCategory in('2', '3') then
      -- recherche des infos sur la limite de crédit comptable de groupe
      PAC_PARTNER_MANAGEMENT.GetCreditLimit(aPartnerType
                                          , aThirdId
                                          , aCurrencyId
                                          , aDocumentDate
                                          , 1   -- Limite de groupe
                                          , aGroupLimitAmount
                                          , aGroupLimitType
                                          , vCreditDate
                                           );

      -- pas de limite trouvée en monnaie document alors on recherche en monnaie de base
      if     aGroupLimitAmount is null
         and aCurrencyId <> ACS_FUNCTION.GetLocalCurrencyId then
        PAC_PARTNER_MANAGEMENT.GetCreditLimit(aPartnerType
                                            , aThirdId
                                            , ACS_FUNCTION.GetLocalCurrencyId
                                            , aDocumentDate
                                            , 1   -- Limite de groupe
                                            , aGroupLimitAmount
                                            , aGroupLimitType
                                            , vCreditDate
                                             );
      end if;
    end if;
  end GetCreditLimit;

  /**
   * Description
   *   Recherche des montants pour le contrôle de limite de crédit
   */
  procedure GetCreditLimitAmounts(
    aThirdId           in     DOC_DOCUMENT.PAC_THIRD_ID%type
  , aPartnerCategory   in     PAC_SUPPLIER_PARTNER.C_PARTNER_CATEGORY%type
  , aPartnerType       in     varchar2
  , aDocumentId        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPartnerAuxAccount out    number
  , aPartnerDocAmount  out    number
  , aGroupAuxAccount   out    number
  , aGroupDocAmount    out    number
  )
  is
    vAuxAccountID    PAC_SUPPLIER_PARTNER.ACS_AUXILIARY_ACCOUNT_ID%type;
    vPartnerCategory PAC_SUPPLIER_PARTNER.C_PARTNER_CATEGORY%type;
  begin
    aPartnerAuxAccount  := 0;
    aPartnerDocAmount   := 0;
    aGroupAuxAccount    := 0;
    aGroupDocAmount     := 0;
    vPartnerCategory    := 0;

    -- Recherche de la catégorie du partenaire si pas passée en paramètre
    if    aPartnerCategory is null
       or aPartnerCategory = '0' then
      select C_PARTNER_CATEGORY
        into vPartnerCategory
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aThirdID;
    else
      vPartnerCategory  := aPartnerCategory;
    end if;

    -- Limite individuelle partenaire
    if vPartnerCategory in('1', '4') then
      -- Recherche du Solde du compte auxiliaire en MB (postes ouverts)
      if aPartnerType = 'S' then   -- Fournisseur
        select nvl( (ACS_FUNCTION.SOLDEAUXACCOUNT(0, ACS_AUXILIARY_ACCOUNT_ID) * -1), 0)
          into aPartnerAuxAccount
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = aThirdID;
      else   -- Client
        select nvl(ACS_FUNCTION.SOLDEAUXACCOUNT(0, ACS_AUXILIARY_ACCOUNT_ID), 0)
          into aPartnerAuxAccount
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aThirdID;
      end if;

      -- Recherche du montant total des documents (montant ouvert)
      aPartnerDocAmount  := DOC_FUNCTIONS.GetTotAmountForCreditLimit(aThirdID, aDocumentID, aPartnerType);
    -- Limite partenaire "Groupe" ou "Membre de groupe"
    else
      -- Recherche le compte auxiliaire du client/fournisseur
      if aPartnerType = 'S' then   -- Fournisseur
        select ACS_AUXILIARY_ACCOUNT_ID
          into vAuxAccountID
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = aThirdID;
      else   -- Client
        select ACS_AUXILIARY_ACCOUNT_ID
          into vAuxAccountID
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aThirdID;
      end if;

      -- Recherche du Solde du compte auxiliaire en MB (postes ouverts)
      -- 1. Montants Niveau "Partenaire"
      aPartnerAuxAccount  :=
        PAC_PARTNER_MANAGEMENT.GetSumOfExpiries(pAuxAccountId        => vAuxAccountID
                                              , pLocalCurrency       => 1
                                              , pPersonId            => aThirdID
                                              , pFinCurrencyId       => null
                                              , pForceInitAccounts   => 1
                                               );
      -- 2. Montants Niveau "Groupe"
      aGroupAuxAccount    :=
        PAC_PARTNER_MANAGEMENT.GetSumOfExpiries(pAuxAccountId        => vAuxAccountID
                                              , pLocalCurrency       => 1
                                              , pPersonId            => null
                                              , pFinCurrencyId       => null
                                              , pForceInitAccounts   => 1
                                               );
      -- Recherche du montant total des documents (montant ouvert)
      -- 1. Montants Niveau "Partenaire"
      aPartnerDocAmount   := DOC_FUNCTIONS.GetTotAmountForCreditLimit(aThirdID, aDocumentID, aPartnerType);
      -- 2. Montants Niveau "Groupe"
      aGroupDocAmount     := DOC_FUNCTIONS.GetAmountCreditLimitGroup(vAuxAccountID, aDocumentID, aPartnerType);
    end if;
  end GetCreditLimitAmounts;

  /**
  * function ControlBudgetExceeding
  * Description
  *   Contrôle le dépassement de budget d'un document
  */
  function ControlBudgetExceeding(
    aDocumentId      in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aConsumptionType in     DOC_GAUGE_STRUCTURED.C_BUDGET_CONSUMPTION_TYPE%type
  , aNatureCode      in     DIC_GAU_NATURE_CODE.DIC_GAU_NATURE_CODE_ID%type
  , aDateValue       in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , aBudgetControl   in     DOC_GAUGE_STRUCTURED.C_BUDGET_CONTROL%type
  , aConfirmStatus   in     DOC_GAUGE.GAU_CONFIRM_STATUS%type
  , aBalanceStatus   in     DOC_GAUGE_STRUCTURED.GAS_BALANCE_STATUS%type
  , aDocStatus       in     DOC_DOCUMENT.C_DOCUMENT_STATUS%type
  , aContinueConfirm out    integer
  )
    return number
  is
  begin
    if DOC_BUDGET_FUNCTIONS.ControlBudget(aDocumentId        => aDocumentId
                                        , aConsumptionType   => aConsumptionType
                                        , aNatureCode        => aNatureCode
                                        , aDateValue         => aDateValue
                                         ) = 0 then
      -- Arrêter la confirmation en fonction du type de limite
      if aBudgetControl = '1' then
        -- Si gabarit Status A solder = OUI -> Continuer la confirmation
        -- Si gabarit Status A solder = NON -> Arreter la confirmation
        aContinueConfirm  := aBalanceStatus;

        -- Si on continue la confirmation => on accepte tous les dépassements de budget des positions
        if aContinueConfirm = 1 then
          -- Mise à jour de l'utilisateur et de la date
          DOC_BUDGET_FUNCTIONS.AcceptAllExceeding(aDocumentId);
        end if;
      elsif aBudgetControl = '2' then
        /* On arrête la confirmation
           si le gabarit gère le statut 'A confirmer'
           et si le document a le statut 'A confirmer'
              ou s'il génère des mvts de stock.
                (=> il a le statut 'A confirmer' car un doc 'A solder' qui génère
                    des mvts de stock ne peut pas être modifié)
              ou si le gabarit ne gère pas le statut 'A solder'
                (=> il a le statut 'A confirmer' car sinon il n'aurait pas pu être modifié) */
        if     (aConfirmStatus = 1)
           and (aDocStatus = '01') then
          aContinueConfirm  := 0;
        else
          aContinueConfirm  := 1;
        end if;
      /* On spécifie l'erreur de dépassement de budget que l'on continue ou non
        la confirmation. */
      end if;

      return 0;
    elsif aBudgetControl = '2' then
      DOC_BUDGET_FUNCTIONS.AcceptAllExceeding(aDocumentId, 1);
    end if;

    return 1;
  end ControlBudgetExceeding;

  /**
   * Description
   *   controle de parité de la présaisie (Contrôle du montant logistique et comptable)
   */
  function ctrlAmountLogisticFinancial(
    aActDocumentId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDocPreEntry   in DOC_GAUGE_STRUCTURED.C_DOC_PRE_ENTRY%type
  , aLogAmount     in DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type
  , aLogCurrencyId in DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , aAciCompany    in DOC_DOCUMENT.COM_NAME_ACI%type
  )
    return number
  is
    finAmount     ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type;
    finCurrencyId ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type;
    vResult       number(1)                                                 := 1;
  begin
    if aActDocumentId is not null then
      if aAciCompany is null then
        if aDocPreEntry in('2', '4') then
          -- recherche du montant du document finance et de sa monnaie
          select decode(aLogCurrencyId
                      , ACS_FUNCTION.GetLocalCurrencyiD, decode(CAT.C_TYPE_CATALOGUE
                                                              , '2', IMF_AMOUNT_LC_C - IMF_AMOUNT_LC_D
                                                              , IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C
                                                               )
                      , decode(CAT.C_TYPE_CATALOGUE, '2', IMF_AMOUNT_FC_C - IMF_AMOUNT_FC_D, IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                       )
               , decode(aLogCurrencyId, ACS_FUNCTION.GetLocalCurrencyiD, IMF.ACS_ACS_FINANCIAL_CURRENCY_ID, IMF.ACS_FINANCIAL_CURRENCY_ID)
            into finAmount
               , finCurrencyId
            from ACJ_CATALOGUE_DOCUMENT CAT
               , ACT_FINANCIAL_IMPUTATION IMF
               , ACT_DOCUMENT DOC
           where DOC.ACT_DOCUMENT_ID = aActDocumentId
             and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
             and IMF.IMF_PRIMARY + 0 = 1;

          if finAmount = aLogAmount then
            vResult  := 1;
          else
            vResult  := 0;
          end if;
        else
          vResult  := 1;
        end if;
      else
        declare
          vLogCurrname PCS.PC_CURR.CURRNAME%type;
          vScrOwner    PCS.PC_SCRIP.SCRDBOWNER%type;
          vScrDbLink   PCS.PC_SCRIP.SCRDB_LINK%type;
          vProcName    varchar2(62);
          vSql         varchar2(20000);
        begin
          -- recherche du nom de la monnaie
          select CURRNAME
            into vLogCurrName
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR CUR
           where FIN.PC_CURR_ID = CUR.PC_CURR_ID
             and FIN.ACS_FINANCIAL_CURRENCY_ID = aLogCurrencyId;

          -- recherche des infos technique société
          select SCRDBOWNER
               , SCRDB_LINK
            into vScrOwner
               , vScrDbLink
            from PCS.PC_COMP COM
               , PCS.PC_SCRIP SCR
           where COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID
             and COM_NAME = aAciCompany;

          -- construction de la requête de recherche
          if vScrDbLink is null then
            vProcname  := '.DOC_DOCUMENT_FUNCTIONS.ctrlAmountLogisticFinancial';
          else
            vProcname  := '.DOC_DOCUMENT_FUNCTIONS.ctrlAmountLogisticFinancial@' || vScrDbLink;
          end if;

          vSql  := 'SELECT ' || vScrOwner || vProcName || '(:aActDocumentID' || ', :aDocPreEntry' || ', :aLogAmount' || ', :aLogCurrName) from DUAL';

          execute immediate vSql
                       into vResult
                      using in aActDocumentId, in aDocPreEntry, in aLogAmount, in vLogCurrName;
        end;
      end if;
    end if;

    return vResult;
  end ctrlAmountLogisticFinancial;

  /**
   * Description
   *   controle de parité de la présaisie (Contrôle du montant logistique et comptable)
   */
  function ctrlAmountLogisticFinancial(
    aActDocumentId in ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDocPreEntry   in DOC_GAUGE_STRUCTURED.C_DOC_PRE_ENTRY%type
  , aLogAmount     in DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type
  , aLogCurrName   in PCS.PC_CURR.CURRNAME%type
  )
    return number
  is
    vLogCurrencyId DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- recherche de l'ID de la monnaie
    select ACS_FINANCIAL_CURRENCY_ID
      into vLogCurrencyId
      from ACS_FINANCIAL_CURRENCY FIN
         , PCS.PC_CURR CUR
     where FIN.PC_CURR_ID = CUR.PC_CURR_ID
       and CUR.CURRNAME = aLogCurrName;

    -- appel de la fonction standard
    return ctrlAmountLogisticFinancial(aActDocumentId, aDocPreEntry, aLogAmount, vLogCurrencyId, null);
  end ctrlAmountLogisticFinancial;

  /**
  * Description
  *    contrôle que le document n'ait pas de position en manco
  */
  function isStockOutage(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    result DOC_POSITION.POS_STOCK_OUTAGE%type;
  begin
    -- Mise à jour des flags avant de contrôler
    DOC_FUNCTIONS.FLAGPOSITIONMANCO(null, aDocumentId);

    -- Recherche si au moins une position est en rupture de stock
    select nvl(max(POS_STOCK_OUTAGE), 0)
      into result
      from DOC_POSITION
     where DOC_DOCUMENT_ID = aDocumentId
       and POS_STOCK_OUTAGE = 1;

    return result;
  end isStockOutage;

  /**
  * function InternalCtrlCustomData
  * Description
  *   Contrôle des tarifs douaniers (méthode standard PCS)
  * @created NGV FEB.2010
  * @lastUpdate
  * @public
  * @API
  * @param aDocumentID : id du document à contrôler
  * @param aErrorCode  : Code d'erreur utilisateur
  * @return 1 si OK, 0 si problème
  */
  function InternalCtrlCustomData(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorCode out varchar2)
    return number
  is
    vCount  integer;
    vResult number(1) := 1;
  begin
    -- Vérifier que tous les biens des positions (1,7,8,9,10)
    -- possèdent au moins un tarif douanier pour les conditions suivantes
    --   1. tarif douanier pour le pays de livraison/facturation du document
    --   2. tarif douanier sans pays défini
    for tplGood in (select   nvl(DMT.PC__PC_CNTRY_ID, DMT.PC_2_PC_CNTRY_ID) PC_CNTRY_ID
                           , POS.GCO_GOOD_ID
                        from DOC_DOCUMENT DMT
                           , DOC_FOOT FOO
                           , DOC_POSITION POS
                       where DMT.DOC_DOCUMENT_ID = aDocumentID
                         and DMT.DOC_DOCUMENT_ID = FOO.DOC_FOOT_ID
                         and FOO.DIC_TYPE_DOC_CUSTOM_ID is not null
                         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                         and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '9', '10')
                    group by nvl(DMT.PC__PC_CNTRY_ID, DMT.PC_2_PC_CNTRY_ID)
                           , POS.GCO_GOOD_ID) loop
      select count(*)
        into vCount
        from GCO_CUSTOMS_ELEMENT
       where GCO_GOOD_ID = tplGood.GCO_GOOD_ID
         and CUS_CUSTONS_POSITION is not null
         and nvl(PC_CNTRY_ID, tplGood.PC_CNTRY_ID) = tplGood.PC_CNTRY_ID;

      if vCount = 0 then
        vResult  := 0;
      end if;
    end loop;

    return vResult;
  end InternalCtrlCustomData;

  /**
  * function CtrlCustomData
  * Description
  *   Contrôle des tarifs douaniers (méthode d'aiguillage entre le standard PCS et l'indiv)
  */
  function CtrlCustomData(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorCode out varchar2)
    return number
  is
    vResult number(1)       := 1;
    vSqlCmd varchar2(32000);
  begin
    aErrorCode  := null;
    vSqlCmd     := PCS.PC_FUNCTIONS.GetSql(aTableName => 'DOC_DOCUMENT', aGroup => 'DOC_DOCUMENT_FUNCTIONS', aSqlId => 'CtrlCustomData', aHeader => false);

    -- Si pas d'indiv pour la cmd de contrôle des tarifs
    if PCS.PC_LIB_SQL.IsSqlEmpty(vSqlCmd) = 1 then
      -- Executer le contrôle standard
      vResult  := DOC_DOCUMENT_FUNCTIONS.InternalCtrlCustomData(aDocumentID, aErrorCode);
    else
      vSqlCmd  := replace(upper(vSqlCmd), '[COMPANY_OWNER' || '].', '');
      vSqlCmd  := replace(upper(vSqlCmd), '[CO' || '].', '');

      execute immediate vSqlCmd
                  using out vResult, in aDocumentID, out aErrorCode;
    end if;

    return vResult;
  end CtrlCustomData;

  /**
  * procedure CtrlCustomData
  * Description
  *   Contrôle des tarifs douaniers (pour l'appel depuis DELPHI)
  */
  procedure CtrlCustomData(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aResult out number, aErrorCode out varchar2)
  is
  begin
    aResult  := CtrlCustomData(aDocumentID, aErrorCode);
  end CtrlCustomData;

  /**
  * Description
  *   Mise à jour des opérations de sous-traitance
  */
  procedure AutoReceptSubContracting(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorText out varchar2)
  is
    cursor crDetailInfos(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select PDE.FAL_SCHEDULE_STEP_ID
           , PDE.PDE_MOVEMENT_QUANTITY
           , POS.POS_NUMBER
           , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY_PARENT * POS.POS_CONVERT_FACTOR, 1 / power(10, nvl(GOO.GOO_NUMBER_OF_DECIMAL, 0) ), 0)
                                                                                                                                    PDE_BALANCE_QUANTITY_PARENT
           , CMA.CMA_AUTO_RECEPT
           , LOT.LOT_REFCOMPL
           , TAL.SCS_STEP_NUMBER
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , FAL_TASK_LINK TAL
           , FAL_LOT LOT
           , STM_MOVEMENT_KIND MOK
           , GCO_GOOD GOO
           , GCO_COMPL_DATA_MANUFACTURE CMA
       where PDE.DOC_DOCUMENT_ID = cDocumentId
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and GOO.GCO_GOOD_ID = PDE.GCO_GOOD_ID
         and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
         and nvl(MOK.MOK_UPDATE_OP, 0) = 1
         and TAL.FAL_SCHEDULE_STEP_ID = PDE.FAL_SCHEDULE_STEP_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and CMA.GCO_GOOD_ID = LOT.GCO_GOOD_ID
         and (    (    CMA.DIC_FAB_CONDITION_ID is null
                   and LOT.DIC_FAB_CONDITION_ID is null)
              or CMA.DIC_FAB_CONDITION_ID = LOT.DIC_FAB_CONDITION_ID)
         and POS.C_GAUGE_TYPE_POS <> '3'
         and LOT.C_FAB_TYPE <> FAL_BATCH_FUNCTIONS.btSubcontract;

    intResult  integer;
    vErrorText varchar2(4000);
  begin
    aErrorText  := '';

    for tplDetailInfo in crDetailInfos(aDocumentId) loop
      vErrorText  := '';

      -- Traitement de la réception automatique du lot de fabrication.
      if     (tplDetailInfo.CMA_AUTO_RECEPT = 1)
         and (   tplDetailInfo.PDE_MOVEMENT_QUANTITY > 0
              or tplDetailInfo.PDE_BALANCE_QUANTITY_PARENT > 0) then
        FAL_BATCH_FUNCTIONS.AutoRecept(aFalTaskLinkId   => tplDetailInfo.FAL_SCHEDULE_STEP_ID
                                     , aQty             => tplDetailInfo.PDE_MOVEMENT_QUANTITY
                                     , aResult          => intResult
                                     , aMsgResult       => vErrorText
                                      );

        -- Ajout du message d'erreur
        if intResult <> FAL_BATCH_FUNCTIONS.arReceptionOK then
          addText(aErrorText
                , tplDetailInfo.POS_NUMBER || ' ( ' || tplDetailInfo.LOT_REFCOMPL || ' / ' || tplDetailInfo.SCS_STEP_NUMBER || ') : ' || vErrorText);
        end if;
      end if;
    end loop;

    -- Libération des lots réservés
    FAL_BATCH_RESERVATION.ReleaseReservedBatches;
  end AutoReceptSubContracting;

  /**
  * Description
  *   Appel de la fonction de génération de l'interface comptable
  */
  function GenerateAciDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    result number(1);
  begin
    -- création de document dans l'interface comptable
    ACI_LOGISTIC_DOCUMENT.WRITE_DOCUMENT_INTERFACE(aDocumentId);

    -- vérifie si le document a été créé
    select nvl(DMT_FINANCIAL_CHARGING, 0)
      into result
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    return result;
  end GenerateAciDocument;

  /**
  * Description
  *   génération des documents EDI
  */
  procedure generateEdiDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aErrorCode out varchar2, aErrorText out varchar2)
  is
  begin
    aErrorCode  := null;
    aErrorText  := null;
  /*  Pas encore géré en plsql, en attente pour dév
  if PCS.PC_CONFIG.GetConfig('DOC_EDI_ACTIVATE') = '1' then
    aErrorText := PCS.PC_FUNCTIONS.TranslateWord('PCS - La génération de documents EDI n''est pas possible en confirmation plsql');
  end if;
  */
  end generateEdiDocument;

  /**
  * Description
  *   génération automatique des attributions
  */
  procedure generateAutoAttrib(
    aDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeType     in DOC_GAUGE.C_GAUGE_TYPE%type
  , aConfirmStatus in DOC_GAUGE.GAU_CONFIRM_STATUS%type
  , aAutoAttrib    in DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type
  )
  is
  begin
    if     aAutoAttrib = 1
       and aGaugeType = '1'
       and aConfirmStatus = 1 then
      FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(aDocumentId, null);
    end if;
  end generateAutoAttrib;

  /**
  * procedure genCML_Events
  * Description
  *    Génération des évènements dans les contrats
  * @created fp  01.12.2003
  * @lastUpdate
  * @public
  * @param aDocumentId : id document à traiter
  */
  procedure genCML_Events(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crCmlPositions(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select doc_document.doc_document_id
           , doc_document.dmt_date_document
           , doc_position.doc_position_id
           , doc_position.gco_good_id
           , doc_position.pos_basis_quantity
           , cml_document.cml_document_id
           , cml_document.pac_custom_partner_id
           , cml_document.doc_record_id
           , cml_position.cml_position_id
           , cml_position.acs_financial_currency_id
           , cml_position.dic_tariff_id
           , doc_position.pac_third_id
        from doc_document
           , doc_position
           , cml_document
           , cml_position
       where doc_document.doc_document_id = cDocumentId
         and doc_position.doc_document_id = doc_document.doc_document_id
         and doc_position.pos_gen_cml_events = 1
         and cml_position.cml_position_id = doc_document.cml_position_id
         and cml_document.cml_document_id = cml_position.cml_document_id;

    cevSequence      CML_EVENTS.CEV_SEQUENCE%type;
    roundType        PTC_TARIFF.C_ROUND_TYPE%type;
    roundAmount      PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    posNetTariff     PTC_TARIFF.TRF_NET_TARIFF%type;
    posSpecialTariff PTC_TARIFF.TRF_SPECIAL_TARIFF%type;
    posFlatRate      DOC_POSITION.POS_FLAT_RATE%type;
    posTariffUnit    PTC_TARIFF.TRF_UNIT%type;
    salePrice        CML_EVENTS.CEV_UNIT_SALE_PRICE%type;
    unitCostPrice    CML_EVENTS.CEV_COST_PRICE%type;
  begin
    for tplCmlPositions in crCmlPositions(aDocumentId) loop
      if cevSequence is null then
        select nvl(max(CEV_SEQUENCE), 1)
          into cevSequence
          from CML_EVENTS
         where CML_POSITION_ID = tplCmlPositions.CML_POSITION_ID;
      else
        cevSequence  := cevSequence + 1;
      end if;

      unitCostPrice  := GCO_FUNCTIONS.GetCostPriceWithManagementMode(tplCmlPositions.gco_good_id);
      salePrice      :=
        GCO_LIB_PRICE.GetGoodPrice(iGoodId              => tplCmlPositions.gco_good_id
                                 , iTypePrice           => '2'
                                 , iThirdId             => tplCmlPositions.PAC_THIRD_ID
                                 , iRecordId            => tplCmlPositions.DOC_RECORD_ID
                                 , iFalScheduleStepId   => null
                                 , ioDicTariff          => tplCmlPositions.DIC_TARIFF_ID
                                 , iQuantity            => tplCmlPositions.POS_BASIS_QUANTITY
                                 , iDateRef             => sysdate
                                 , ioRoundType          => roundtype
                                 , ioRoundAmount        => roundAmount
                                 , ioCurrencyId         => tplCmlPositions.ACS_FINANCIAL_CURRENCY_ID
                                 , oNet                 => PosNetTariff
                                 , oSpecial             => PosSpecialTariff
                                 , oFlatRate            => PosFlatRate
                                 , oTariffUnit          => PosTariffUnit
                                 , iDicTariff2          => ''
                                  );

      insert into cml_events
                  (cml_events_id
                 , cev_sequence
                 , cml_document_id
                 , cml_position_id
                 , c_cml_event_type
                 , gco_good_id
                 , acs_financial_currency_id
                 , cev_date
                 , cev_qty
                 , cev_unit_sale_price
                 , cev_amount
                 , cev_use_indice
                 , cev_unit_cost_price
                 , doc_position_origin_id
                 , cev_cost_price
                 --, cev_text
      ,            c_cml_event_doc_gen
                 , a_datecre
                 , a_idcre
                  )
           values (init_id_seq.nextval
                 , cevSequence
                 , tplCmlPositions.cml_document_id
                 , tplCmlPositions.cml_position_id
                 , '1'   -- c_cml_event_type
                 , tplCmlPositions.gco_good_id
                 , tplCmlPositions.acs_financial_currency_id
                 , tplCmlPositions.DMT_DATE_DOCUMENT
                 , tplCmlPositions.POS_BASIS_QUANTITY
                 , salePrice
                 , salePrice * tplCmlPositions.POS_BASIS_QUANTITY
                 , decode(PCS.PC_CONFIG.GetConfigUpper('CML_DEFAULT_EVENTS_INDICE_CODE'), 'TRUE', 1, 0)   -- :cev_use_indice
                 , unitCostPrice
                 , tplCmlPositions.cml_position_id
                 , unitCostPrice * tplCmlPositions.POS_BASIS_QUANTITY
                 --, :cev_text
      ,            '2'   -- :c_cml_event_doc_gen
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    --Si le document est généré par l'extraction des factures périodiques (CML_DOCUMENT / CML_POSITION),
    --alors il est possible d'effacer les données de sauvegarde (CMP_POSITION_BACK, CML_EVENTS_BACK)
    --en attente de confirmation du document logistique généré
    delete from cml_position_back
          where cml_position_id in(select distinct cml_position_id
                                              from doc_position
                                             where doc_document_id = aDocumentId);

    delete from cml_events_back
          where cml_position_id in(select distinct cml_position_id
                                              from doc_position
                                             where doc_document_id = aDocumentId);

    update cml_position
       set doc_prov_document_id = null
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where doc_prov_document_id = aDocumentId;
  end genCML_Events;

  procedure UpdateContractAmounts(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Balayer la liste de positions issues de la facturation des contrats
    for tplPos in (select   POS.CML_POSITION_ID
                          , POS.CML_EVENTS_ID
                          , POS.POS_NET_VALUE_EXCL_B
                          , case
                              when GAS.C_GAUGE_TITLE = '8' then 1
                              else -1
                            end MULTIPLY_FACTOR
                          , CEV.C_CML_EVENT_TYPE
                       from DOC_POSITION POS
                          , DOC_DOCUMENT DMT
                          , DOC_GAUGE_STRUCTURED GAS
                          , CML_EVENTS CEV
                      where DMT.DOC_DOCUMENT_ID = aDocumentID
                        and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                        and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                        and POS.CML_POSITION_ID is not null
                        and POS.CML_EVENTS_ID = CEV.CML_EVENTS_ID(+)
                   order by POS.POS_NUMBER) loop
      -- Intitulé gabarit -> 8 : Facture client
      --   Le facteur de multiplication = 1
      -- Intitulé gabarit -> 9 : Note de crédit (client)
      --   Le facteur de multiplication = -1

      -- Position de type "Forfait"
      if tplPos.CML_EVENTS_ID is null then
        -- Màj du montant facturé
        update CML_POSITION
           set CPO_POSITION_AMOUNT = nvl(CPO_POSITION_AMOUNT, 0) +(tplPos.POS_NET_VALUE_EXCL_B * tplPos.MULTIPLY_FACTOR)
         where CML_POSITION_ID = tplPos.CML_POSITION_ID;
      -- Position de type "Evénement"
      else
        -- 1 : Facturation complémentaire
        -- 3 : Note de crédit / montant facturé
        if tplPos.C_CML_EVENT_TYPE in('1', '3') then
          -- Màj du montant facturé
          update CML_POSITION
             set CPO_POSITION_AMOUNT = nvl(CPO_POSITION_AMOUNT, 0) +(tplPos.POS_NET_VALUE_EXCL_B * tplPos.MULTIPLY_FACTOR)
           where CML_POSITION_ID = tplPos.CML_POSITION_ID;
        -- 2 : Montant supplémentaire facturé
        -- 5 : Excédents de consommation
        elsif tplPos.C_CML_EVENT_TYPE in('2', '5') then
          -- Màj du montant supplémentaire position
          update CML_POSITION
             set CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) +(tplPos.POS_NET_VALUE_EXCL_B * tplPos.MULTIPLY_FACTOR)
           where CML_POSITION_ID = tplPos.CML_POSITION_ID;
        -- 4 : Note de crédit / perte
        elsif tplPos.C_CML_EVENT_TYPE = '4' then
          -- Màj de la perte position
          update CML_POSITION
             set CPO_POSITION_LOSS = nvl(CPO_POSITION_LOSS, 0) +(tplPos.POS_NET_VALUE_EXCL_B * tplPos.MULTIPLY_FACTOR)
           where CML_POSITION_ID = tplPos.CML_POSITION_ID;
        end if;
      end if;
    end loop;
  end UpdateContractAmounts;

  function ctrlPaymentsBvr(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    tempId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    select dmt.DOC_DOCUMENT_ID
      into tempId
      from DOC_PAYMENT_DATE pad
         , DOC_DOCUMENT dmt
         , DOC_FOOT foo
         , DOC_GAUGE gau
         , ACS_FIN_ACC_S_PAYMENT PMM
         , ACS_PAYMENT_METHOD PME
     where PAD_BVR_REFERENCE_NUM is null
       and pad.DOC_FOOT_ID = aDocumentId
       and dmt.DOC_DOCUMENT_ID = pad.DOC_FOOT_ID
       and foo.DOC_FOOT_ID = pad.DOC_FOOT_ID
       and gau.DOC_GAUGE_ID = dmt.DOC_GAUGE_ID
       and DMT.PAC_PAYMENT_CONDITION_ID is not null
       and PMM.ACS_FIN_ACC_S_PAYMENT_ID = DMT.ACS_FIN_ACC_S_PAYMENT_ID
       and PME.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID
       and PME.C_TYPE_SUPPORT in('33', '34', '35', '50', '51', '56')
       and DMT.ACS_FIN_ACC_S_PAYMENT_ID is not null
       and (    (    GAU.C_ADMIN_DOMAIN = '2'
                 and FOO.C_BVR_GENERATION_METHOD in('02', '03') )
            or (    GAU.C_ADMIN_DOMAIN = '1'
                and FOO.FOO_REF_BVR_NUMBER is not null) )
       and DMT.C_DOCUMENT_STATUS <> '04'
       and acs_function.getcurrencyname(dmt.ACS_FINANCIAL_CURRENCY_ID) in(DOC_PAYMENT_DATE_FCT.cSwissFrancCode, DOC_PAYMENT_DATE_FCT.cEuroCode)
       and foo.FOO_DOCUMENT_TOTAL_AMOUNT <> 0;

    return 0;
  exception
    when no_data_found then
      return 1;
    when too_many_rows then
      return 0;
  end ctrlPaymentsBvr;

  /* Protection ou déprotection du document */
  procedure DocumentProtect(
    aDocumentID number
  , aProtect    number
  , aSessionID  varchar2 default null
  , aListDescr  COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , aManageVat  number default 0
  )
  is
  begin
    DOC_PRC_DOCUMENT.DocumentProtect(iDocumentID   => aDocumentID
                                   , iProtect      => aProtect
                                   , iSessionID    => aSessionID
                                   , iListDescr    => aListDescr
                                   , iManageVat    => aManageVat
                                    );
  end DocumentProtect;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtect_AutoTrans(
    aDocumentID     number
  , aProtect        number
  , aSessionID      varchar2 default null
  , aListDescr      COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , aShowError      number default 1
  , aManageVat      number default 0
  , aUpdated    out number
  )
  is
  begin
    DOC_PRC_DOCUMENT.DocumentProtect_AutoTrans(iDocumentId   => aDocumentID
                                             , iProtect      => aProtect
                                             , iSessionID    => aSessionID
                                             , iListDescr    => aListDescr
                                             , iShowError    => aShowError
                                             , iManageVat    => aManageVat
                                             , oUpdated      => aUpdated
                                              );
  end DocumentProtect_AutoTrans;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  */
  procedure DocumentProtect_AutoTrans(
    aDocumentID number
  , aProtect    number
  , aSessionID  varchar2 default null
  , aListDescr  COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null
  , aShowError  number default 1
  )
  is
    vUpdated number(1);
  begin
    DocumentProtect_AutoTrans(aDocumentID, aProtect, aSessionID, aListDescr, aShowError, 0, vUpdated);
  end DocumentProtect_AutoTrans;

  /* Ajoute le document courant dans la liste des documents protègés */
  procedure AddProtectedDocument(aDocumentID number, aListDescr COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null)
  is
  begin
    DOC_PRC_DOCUMENT.AddProtectedDocument(iDocumentID => aDocumentID, iListDescr => aListDescr);
  end AddProtectedDocument;

  /* Retire le document courant dans la liste des documents protègés */
  procedure DelProtectedDocument(aDocumentID number, aListDescr COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type default null)
  is
  begin
    DOC_PRC_DOCUMENT.DelProtectedDocument(iDocumentID => aDocumentID, iListDescr => aListDescr);
  end DelProtectedDocument;

  /**
  * Description
  *   Réévaluation des montants en monnaie de base du document
  */
  procedure revaluateDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    dmtRevaluationDate     DOC_DOCUMENT.DMT_REVALUATION_DATE%type;
    dmtRevaluationRate     DOC_DOCUMENT.DMT_REVALUATION_RATE%type;
    dmtDateDocument        DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    dmtRateOfExchange      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    acsFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vReturn                number(1);
    vRateExchange          number;
    vBasePrice             number;
    vBaseChange            number;
    vRateExchangeEUR_ME    number;
    vFixedRateEUR_ME       number;
    vRateExchangeEUR_MB    number;
    vFixedRateEUR_MB       number;
    vID                    number;
  begin
    select DMT.DMT_REVALUATION_DATE
         , nvl(DMT.DMT_REVALUATION_RATE, 0)
         , DMT.DMT_DATE_DOCUMENT
         , DMT.DMT_RATE_OF_EXCHANGE
         , DMT.ACS_FINANCIAL_CURRENCY_ID
      into dmtRevaluationDate
         , dmtRevaluationRate
         , dmtDateDocument
         , dmtRateOfExchange
         , acsFinancialCurrencyID
      from DOC_DOCUMENT DMT
     where DMT.DOC_DOCUMENT_ID = aDocumentId;

    if dmtRevaluationRate = 1 then
      -- If date is null, uses document date instead
      if dmtRevaluationDate is null then
        dmtRevaluationDate  := dmtDateDocument;
      end if;

      -- mise à jour du taux de la TVA pour chaque position
      update DOC_POSITION
         set POS_VAT_RATE = Acs_Function.GetVatRate(ACS_TAX_CODE_ID, to_char(dmtRevaluationDate, 'yyyymmdd') )
           , POS_MODIFY_RATE = 1
       where DOC_DOCUMENT_ID = aDocumentId;

      -- Document currency change search
      -- Recherche du cours de la monnaie Document
      vReturn  :=
        Acs_Function.GetRateOfExchangeEUR(aCurrencyID           => acsFinancialCurrencyID
                                        , aSortRate             => 1   -- 1 -> ask for PCU_DAYLY_PRICE
                                        , aDate                 => dmtRevaluationDate
                                        , aRateExchange         => vRateExchange
                                        , aBasePrice            => vBasePrice
                                        , aBaseChange           => vBaseChange
                                        , aRateExchangeEUR_ME   => vRateExchangeEUR_ME
                                        , aFixedRateEUR_ME      => vFixedRateEUR_ME
                                        , aRateExchangeEUR_MB   => vRateExchangeEUR_MB
                                        , aFixedRateEUR_MB      => vFixedRateEUR_MB
                                        , aLogistic             => 1
                                         );

      -- If change is in foreign currency, then converts it to base currency
      -- Si le cours est en monnaie étrangère, alors on le convertit en monnaie base
      if vBaseChange = 0 then
        vRateExchange  :=( (vBasePrice * vBasePrice) / vRateExchange);
      end if;

      /* If new value of rate differs from old one, sets XXX_MODIFY_RATE fields
         to 1 to cause revaluation by triggers */
      /* Si la nouvelle valeur du taux diffère de l'ancienne, on met les champs
         XXX_MODIFY_RATE à 1 pour provoquer la réévaluation par les triggers */
      update DOC_DOCUMENT DMT
         set DMT.DMT_RATE_OF_EXCHANGE = vRateExchange
           , DMT.DMT_BASE_PRICE = vBasePrice
       where DMT.DOC_DOCUMENT_ID = aDocumentId;

      DOC_PRC_DOCUMENT.SetFlagsRateModified(iDocumentID => aDocumentID, iDocRevaluationRate => 0);
    end if;
  end revaluateDocument;

  /**
  * Description
  *   Teste si un document peut être soldé
  */
  function canBalanceDocument(aDocumentId doc_document.doc_document_id%type, aBalanceMvt number default 0)
    return number
  is
    vDocId    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNbBadPos pls_integer;
  begin
    -- regarde si le statut du document ainsi que les flag du gabarit autorise le solde manuel
    select DOC_DOCUMENT_ID
      into vDocId
      from DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
     where DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and DMT.DOC_DOCUMENT_ID = aDocumentID
       and (    (    aBalanceMvt = 0
                 and GAS_AUTH_BALANCE_NO_RETURN = 1)
            or (    aBalanceMvt = 1
                and GAS_AUTH_BALANCE_RETURN = 1) )
       and DMT.C_DOCUMENT_STATUS in('02', '03')
       and (   DMT.DMT_FINANCIAL_CHARGING = 0
            or aBalanceMvt = 0);

    -- Si pas d'exception, c'est que le premier test est OK
    -- Recherche de positions empêchant le solde
    select count(*)
      into vNbBadPos
      from DOC_POSITION
         , DOC_POSITION_DETAIL
         , STM_MOVEMENT_KIND
     where DOC_POSITION.STM_MOVEMENT_KIND_ID = STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID
       and MOK_UPDATE_OP = 0
       and DOC_POSITION_DETAIL.DOC_POSITION_ID = DOC_POSITION.DOC_POSITION_ID
       and DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID is not null
       and DOC_POSITION.DOC_DOCUMENT_ID = aDocumentId;

    if vNbBadPos > 0 then
      return 0;
    else
      return 1;
    end if;
  exception
    when no_data_found then
      return 0;
  end canBalanceDocument;

  /**
  * Description
  *   solder un document
  */
  procedure balanceDocument(aDocumentId doc_document.doc_document_id%type, aBalanceMvt number default 0, aWasteTransfert number default 0)
  is
    lvKindBalanced varchar2(10);
  begin
    -- création des informations d'historique des modifications
    DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId
                                         , null   -- DOC_POSITION_ID
                                         , null   -- no de document
                                         , 'PLSQL'   -- DUH_TYPE
                                         , 'Balance document'
                                         , 'Cancel movements : ' || aBalanceMvt   -- description libre
                                         , null   -- status document
                                         , null   -- status position
                                          );

    -- Descode définissant le type de solde avec/sans extourne
    if aBalanceMvt = 0 then
      lvKindBalanced  := '1';
    else
      lvKindBalanced  := '2';
    end if;

    -- Si il s'agit d'un solde avec extourne
    if aBalanceMvt = 1 then
      DOC_INIT_MOVEMENT.SoldeDocExtourneMovements(aDocumentId);
    end if;

    for tplPositions in (select DOC_POSITION_ID
                           from DOC_POSITION
                          where DOC_DOCUMENT_ID = aDocumentId
                            and POS_BALANCE_QUANTITY <> 0
                            and C_DOC_POS_STATUS not in('04', '05')
                            and C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21') ) loop
      DOC_POSITION_FUNCTIONS.balancePosition(aPositionId        => tplPositions.DOC_POSITION_ID
                                           , aBalanceMvt        => 0
                                           , aUpdateDocStatus   => 0
                                           , aWasteTransfert    => aWasteTransfert
                                           , aKindBalanced      => lvKindBalanced
                                            );
    end loop;

    -- maj Echéancier
    update DOC_INVOICE_EXPIRY
       set INX_INVOICE_GENERATED = 1
         , INX_INVOICE_BALANCED = 1
     where DOC_DOCUMENT_ID = aDocumentId;

    -- maj document
    update DOC_DOCUMENT
       set DMT_BALANCED = 1
         , DMT_DATE_BALANCED = nvl(DMT_DATE_BALANCED, sysdate)
         , C_DOCUMENT_STATUS = '04'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , C_KIND_BALANCED = lvKindBalanced
     where DOC_DOCUMENT_ID = aDocumentId;

    -- maj soldes liés au risque de change
    DOC_FUNCTIONS.UpdateBalanceTotal(aDocumentId);
  end balanceDocument;

  /**
  * Description
  *   Annule un document
  */
  procedure CancelDocumentStatus(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Effacer toutes les positions BIEN avec le statut "à confirmer"
    for tplPosition in (select DOC_POSITION_ID
                          from DOC_POSITION
                         where DOC_DOCUMENT_ID = aDocumentID
                           and C_DOC_POS_STATUS = '01'
                           and C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21') ) loop
      DOC_DELETE.deletePosition(tplPosition.DOC_POSITION_ID, false, false);
    end loop;

    -- Annule les positions du document
    for tplPosition in (select DOC_POSITION_ID
                          from DOC_POSITION
                         where DOC_DOCUMENT_ID = aDocumentID) loop
      DOC_POSITION_FUNCTIONS.CancelPositionStatus(tplPosition.DOC_POSITION_ID);
    end loop;

    -- Mise à jour du statut du document en phase d'annulation du document.
    DOC_PRC_DOCUMENT.UpdateDocumentStatus(aDocumentID, 1);
    -- Mise à jour du total du solde des montant net HT
    DOC_FUNCTIONS.UpdateBalanceTotal(aDocumentID);
  end CancelDocumentStatus;

  /**
  * Description
  *   Mise à jour des totaux de document, des remises/taxes de pieds,
  *   de l'arrondi TVA et des échéances avant la libération (fin d'édition) du document
  */
  procedure FinalizeDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDeprotected number default 1, aExecExternProc number default 1)
  is
    amountModified     number(1);

    cursor docInfo_cursor(cDocumentId in number)
    is
      select DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_TARIFF_DATE
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , DMT.PC_LANG_ID
           , nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
           , nvl(GAS.GAS_CASH_MULTIPLE_TRANSACTION, 0) GAS_CASH_MULTIPLE_TRANSACTION
           , nvl(GAS.GAS_COST, 0) GAS_COST
           , GAS.GAS_STORED_PROC_AFTER_VALIDATE
           , GAL_CURRENCY_RISK_VIRTUAL_ID
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
       where DMT.DOC_DOCUMENT_ID = cDocumentId
         and GAS.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID;

    docInfo_tuple      docInfo_cursor%rowtype;
    chargeCreated      number(1);
    totalModified      number(1);
    ZeroAmountModified number(1);
    firstWrongDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vFootId            DOC_FOOT.DOC_FOOT_ID%type;
    tmpErrorMsg        varchar2(4000);
    lRiskVirtualId     DOC_DOCUMENT.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lvErrorCode        varchar2(10);
  begin
    select max(DOC_FOOT_ID)
      into vFootId
      from DOC_FOOT
     where DOC_FOOT_ID = aDocumentId;

    -- Reset les messages d'erreur
    DOC_PRC_DOCUMENT.ResetConfirmError(aDocumentId);

    -- si pas de pied de document on en crée un
    if vFootId is null then
      DOC_DOCUMENT_GENERATE.GenerateMinimalFoot(aDocumentId);
      vFootId  := aDocumentId;
    end if;

    -- retrait de l'arrondi TVA (il faut enlever la correction TVA car les remises
    -- de groupe peuvent modifier le montant TVA de la position)
    DOC_PRC_VAT.RemoveVatCorrectionAmount(aDocumentId, 1, 1, amountModified);
    -- contrôle de l'intégrité des caractérisations du document (maj du flag dmt_characterization_missing)
    DOC_FUNCTIONS.CheckCharacterizationParity(aDocumentId, firstWrongDetailId);
    -- mise à jour des tarifs par assortiment
    DOC_TARIFF_SET.DocUpdatePriceForTariffSet(aDocumentId);
    -- recalcul des totaux du document
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, totalModified);
    -- calcul des remises/taxes de groupe (calcul des totaux de pied automatiques)
    DOC_DOCUMENT_FUNCTIONS.CreateGroupChargeAndUpdatePos(aDocumentId);

    -- calcul ou création des remises/taxes
    open docInfo_cursor(aDocumentId);

    fetch docInfo_cursor
     into docInfo_tuple;

    -- Gestion des poids matières précieuses
    if (docInfo_tuple.GAS_WEIGHT_MAT = 1) then
      ----
      -- Génération des matières précieuses du pied. Voir graphe Fin Positions
      -- figurant dans l'analyse Facturation des matières précieuses. }
      --
      DOC_FOOT_ALLOY_FUNCTIONS.GenerateFootMat(aDocumentId);
      -- Création des taxes matières précieuses sur position
      DOC_POSITION_ALLOY_FUNCTIONS.generatePreciousMatCharge(aDocumentId, amountModified);
      -- recalcul des montants des positions sur les positions touchées par les taxes matières précieuses
      DOC_DOCUMENT_FUNCTIONS.RecalcModifPosChargeAndAmount(aDocumentId);
      -- Création des remises matières précieuses sur pied
      DOC_FOOT_ALLOY_FUNCTIONS.generatePreciousMatDiscount(aDocumentId, amountModified);
    end if;

    -- recalcul des remises/taxes de pied
    DOC_DISCOUNT_CHARGE.AutomaticFootCharge(aDocumentId
                                          , docInfo_tuple.DMT_DATE_DOCUMENT
                                          , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                          , docInfo_tuple.DMT_RATE_OF_EXCHANGE
                                          , docInfo_tuple.DMT_BASE_PRICE
                                          , docInfo_tuple.PC_LANG_ID
                                          , chargeCreated
                                           );

    -- Ventilation des autres coûts sur les positions
    if     (docInfo_tuple.GAS_COST = 1)
       and (DOC_OTHER_COST_FUNCTIONS.generateOtherCostCharge(aDocumentId, amountModified) = 1) then
      -- recalcul des montants des positions sur les positions touchées par les taxes matières précieuses
      DOC_DOCUMENT_FUNCTIONS.RecalcModifPosChargeAndAmount(aDocumentId, true);
    end if;

    close docInfo_cursor;

    -- réévaluation du document (au cas où le taux de change soit différent)
    DOC_DOCUMENT_FUNCTIONS.revaluateDocument(aDocumentId);
    -- Check des décompte TVA (création si manquant)
    DOC_PRC_VAT.CheckVatDetAccount(aDocumentId);
    -- Création des détails à 0
    DOC_PRC_VAT.AppendZeroTaxCode(aDocumentId);
    -- mise en place de l'arondi TVA
    DOC_PRC_VAT.AppendVatCorrectionAmount(aDocumentId, 1, 1, amountModified);
    -- recalcul des totaux du document (car possible modification suite à l'arrondi TVA)
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, totalModified);
    -- éventuel "arrondi Swisscom"
    DOC_DISCOUNT_CHARGE.roundDocumentAmount(aDocumentId
                                          , nvl(docInfo_tuple.DMT_TARIFF_DATE, docInfo_tuple.DMT_DATE_DOCUMENT)
                                          , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                          , docInfo_tuple.PC_LANG_ID
                                           );
    -- Si le montant en monnaie du document = 0, il faut garantir que le montant en monnaie de base soit aussi = 0
    DOC_FUNCTIONS.AppendZeroAmmountCorrection(aDocumentId, ZeroAmountModified);
    -- recalcul des totaux du document car modification possible dans le processus de
    -- correction montant monnaie doc = 0 Et montant monnaie de base <> 0
    DOC_FUNCTIONS.UpdateFootTotals(aDocumentId, totalModified);
    -- calcul des positions de récapitulation
    DOC_POSITION_FUNCTIONS.CalcRecapPos(aDocumentId);
    -- Vérifie l'exactitude des montants des éventuelles imputations position par rapport aux montants des positions.
    DOC_IMPUTATION_FUNCTIONS.CheckImputations(aDocumentId);

    -- gestion des risques de change, doit être fait après le calcul des totaux du document
    if     (PCS.PC_CONFIG.GetConfig('COM_CURRENCY_RISK_MANAGE') = '1')
       and (docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId) then
      -- Contrôles liés au risque de change
      DOC_PRC_DOCUMENT.CtrlDocumentCurrencyRisk(iDocumentID => aDocumentId, oErrorCode => lvErrorCode);

      if lvErrorCode is not null then
        update DOC_DOCUMENT
           set C_CONFIRM_FAIL_REASON = lvErrorCode
         where DOC_DOCUMENT_ID = aDocumentId;
      else
        -- mise à jour des montants soldes du document
        DOC_FUNCTIONS.UpdateBalanceTotal(iFootId => aDocumentId);
        -- mise à jour des montants soldes des documents parents
        DOC_PRC_DOCUMENT.ProcessListParent;
      end if;
    else
      -- mise à jour des montants soldes des documents parents
      DOC_PRC_DOCUMENT.ProcessListParent;
    end if;

    -- mise à jour du flag de recalcul de remises/taxes de pied à 0
    -- car l'éventuelle corrections de montant ne doivent pas provoquer un recalcul des
    -- remises/taxes de pied
    update DOC_DOCUMENT
       set DMT_RECALC_FOOT_CHARGE = 0
     where DOC_DOCUMENT_ID = aDocumentId;

    -- recalcul des échéances
    DOC_PAYMENT_DATE_FCT.UpdatePaymentDate(aDocumentId, 0,   -- travail avec le flag sur doc_document
                                           '00',   -- reprend la méthode de génération BVR du document
                                           1);
    -- génération de l'échéancier
    DOC_INVOICE_EXPIRY_FUNCTIONS.createBillBook(aDocumentId);

    -- Génération éventuel d'une transaction de payment lors la gestion de la vente au comptant avec transaction multiple
    if (docInfo_tuple.GAS_CASH_MULTIPLE_TRANSACTION = 1) then
      DOC_FOOT_PAYMENT_FUNCTIONS.GenerateFootPayment(aDocumentId);
    end if;

    -- Appel de la procédure externe document après validation document
    if     (aExecExternProc = 1)
       and (docInfo_tuple.GAS_STORED_PROC_AFTER_VALIDATE is not null) then
      -- Remarque : Les exceptions ont déjà été traitées dans la méthode ExecuteExternProc
      DOC_FUNCTIONS.ExecuteExternProc(aDocumentId, docInfo_tuple.GAS_STORED_PROC_AFTER_VALIDATE, tmpErrorMsg);

      if tmpErrorMsg is not null then
        -- Màj du document logistique avec l'erreur obtenue lors de la finalisation du document
        update DOC_DOCUMENT
           set DMT_ERROR_MESSAGE = tmpErrorMsg
         where DOC_DOCUMENT_ID = aDocumentId;
      end if;
    end if;

    -- Maj du dernier numéro de position utilisé
    -- formattage des adresses
    update DOC_DOCUMENT
       set DMT_LAST_USED_POS_NUMBER = (select max(POS_NUMBER)
                                         from DOC_POSITION
                                        where DOC_POSITION.DOC_DOCUMENT_ID = DOC_DOCUMENT.DOC_DOCUMENT_ID)
         , DMT_FORMAT_CITY1 = PAC_PARTNER_MANAGEMENT.FormatingAddress(DMT_POSTCODE1, DMT_TOWN1, DMT_STATE1, DMT_COUNTY1, PC_CNTRY_ID)
         , DMT_FORMAT_CITY2 = PAC_PARTNER_MANAGEMENT.FormatingAddress(DMT_POSTCODE2, DMT_TOWN2, DMT_STATE2, DMT_COUNTY2, PC__PC_CNTRY_ID)
         , DMT_FORMAT_CITY3 = PAC_PARTNER_MANAGEMENT.FormatingAddress(DMT_POSTCODE3, DMT_TOWN3, DMT_STATE3, DMT_COUNTY3, PC_2_PC_CNTRY_ID)
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Erreur gestion du risque de change
    if lvErrorCode in('130', '131', '132', '133', '134') then
      -- Pour la protection du document on passe un ID de session bidon ( 000000000000 )
      --  Ceci pour éviter un problème de session vivante si on ne quitte pas l'objet et que qqun essaye de traiter le doc dans l'objet de déblocage
      -- Màj du flag de protection du document SANS passer par la méthode DocumentProtect parce que celle-ci ne change pas
      --   le flag de protection ainsi que la session si le document est déjà protégé
      update DOC_DOCUMENT
         set DMT_PROTECTED = 1
           , DMT_SESSION_ID = lpad('0', 12, '0')
       where DOC_DOCUMENT_ID = aDocumentId;
    elsif nvl(aDeprotected, 1) = 1 then
      -- mise à jour du flag de protection du document à 0
      DOC_PRC_DOCUMENT.DocumentProtect(aDocumentId, 0);
    end if;

    -- Mise à jour du flag d'impression
    update DOC_DOCUMENT
       set DMT_MAIN_PRINTING = 0
     where DOC_DOCUMENT_ID = aDocumentId;

    -- Màj du flag de la màj des attribs sur la position
    update DOC_POSITION
       set POS_UPDATE_ATTRIB = 0
     where DOC_DOCUMENT_ID = aDocumentId;
  end FinalizeDocument;

  /**
  * Description
  *   Renvoie le numéro du prochain avenant
  */
  function GetAddendumNumber(aGaugeNumberingId in DOC_GAUGE_STRUCTURED.GAS_ADDENDUM_NUMBERING_ID%type, aAddendumIndex DOC_DOCUMENT.DMT_ADDENDUM_INDEX%type)
    return DOC_DOCUMENT.DMT_NUMBER%type
  is
    vNumber DOC_DOCUMENT.DMT_NUMBER%type;
  begin
    -- construction du N° d'avenant avec l'index du dernier avenant du document
    select GAN.GAN_PREFIX || lpad(aAddendumIndex + 1, greatest(1, GAN.GAN_NUMBER), '0') || GAN.GAN_SUFFIX
      into vNumber
      from DOC_GAUGE_NUMBERING GAN
     where GAN.DOC_GAUGE_NUMBERING_ID = aGaugeNumberingId;

    return vNumber;
  exception
    when no_data_found then
      return '';
  end GetAddendumNumber;

  /**
  * procedure p_BalanceAddendumDocument
  * Description
  *   solder un document dans le cadre des avenants
  * @created NGV 05.11.2013
  * @lastUpdate
  * @public
  * @API
  * @param iDocumentID : id du document à solder
  */
  procedure p_BalanceAddendumDocument(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lvPosStatus DOC_POSITION.C_DOC_POS_STATUS%type;
    lChanged    number;
  begin
    for ltplPositions in (select   POS.DOC_POSITION_ID
                                 , POS.POS_NUMBER
                                 , case
                                     when POS_SRC.C_DOC_POS_STATUS = '05' then '05'
                                     else '04'
                                   end as NEW_POS_STATUS
                              from DOC_POSITION POS
                                 , DOC_POSITION POS_SRC
                             where POS.DOC_DOCUMENT_ID = iDocumentID
                               and POS.POS_BALANCE_QUANTITY <> 0
                               and POS.C_DOC_POS_STATUS not in('04', '05')
                               and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '7', '8', '9', '10', '21')
                               and POS_SRC.POS_ADDENDUM_SRC_POS_ID = POS.DOC_POSITION_ID
                          order by POS.POS_NUMBER) loop
      -- maj détails de la position
      update DOC_POSITION_DETAIL
         set PDE_BALANCE_QUANTITY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID;

      -- maj de la position
      update DOC_POSITION
         set POS_BALANCE_QUANTITY = 0
           , POS_BALANCE_QTY_VALUE = 0
           , POS_BALANCED = 1
           , C_DOC_POS_STATUS = ltplPositions.NEW_POS_STATUS
           , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, sysdate)
           , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID;

      -- Traitement éventuel des positions composants, uniquement pour le solde
      -- d'une position (le solde du document les a déjà pris en compte).
      update DOC_POSITION_DETAIL
         set PDE_BALANCE_QUANTITY = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID in(select DOC_POSITION_ID
                                  from DOC_POSITION
                                 where DOC_DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID);

      update DOC_POSITION
         set POS_BALANCE_QUANTITY = 0
           , POS_BALANCE_QTY_VALUE = 0
           , POS_BALANCED = 1
           , C_DOC_POS_STATUS = ltplPositions.NEW_POS_STATUS
           , POS_DATE_BALANCED = nvl(POS_DATE_BALANCED, sysdate)
           , POS_QUANTITY_BALANCED = POS_BALANCE_QUANTITY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID in(select DOC_POSITION_ID
                                  from DOC_POSITION
                                 where DOC_DOC_POSITION_ID = ltplPositions.DOC_POSITION_ID);
    end loop;

    -- maj Echéancier
    update DOC_INVOICE_EXPIRY
       set INX_INVOICE_GENERATED = 1
         , INX_INVOICE_BALANCED = 1
     where DOC_DOCUMENT_ID = iDocumentID;

    -- maj document
    update DOC_DOCUMENT
       set DMT_BALANCED = 1
         , DMT_DATE_BALANCED = nvl(DMT_DATE_BALANCED, sysdate)
         , C_DOCUMENT_STATUS = '04'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOCUMENT_ID = iDocumentID;

    -- maj soldes liés au risque de change
    DOC_FUNCTIONS.UpdateBalanceTotal(iDocumentID);
    -- recalcul des totaux du document
    DOC_FUNCTIONS.UpdateFootTotals(iDocumentID, lChanged);
  end p_BalanceAddendumDocument;

  /**
  * Description
  *   Procédure de création des positions et mise à jour des documents avec avenant
  */
  procedure UpdateAddendumDocs(
    aSrcDocID      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAddendumDocID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aNumber        in DOC_DOCUMENT.DMT_ADDENDUM_NUMBER%type
  , aComment       in DOC_DOCUMENT.DMT_ADDENDUM_COMMENT%type
  , aDate          in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  )
  is
    vPositionID DOC_POSITION.DOC_POSITION_ID%type;
    vPosSrcID   DOC_POSITION.DOC_POSITION_ID%type   default -1;
    aErrorMsg   varchar2(2000);
    vOldNumber  DOC_DOCUMENT.DMT_NUMBER%type;
    ltFootAlloy FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    savepoint UpdateAddendumDocs;

    -- copier les positions du document source vers l'avenant
    for tplPosition in (select   DOC_POSITION_ID
                               , C_GAUGE_TYPE_POS
                            from DOC_POSITION
                           where DOC_DOCUMENT_ID = aSrcDocID
                             and DOC_DOC_POSITION_ID is null
                             and C_POS_CREATE_MODE <> '205'   -- Ne pas reprendre ce type de position, car générées dans le finalize
                             and C_GAUGE_TYPE_POS <> '6'
                        order by POS_NUMBER) loop
      vPositionID  := null;
      -- copie position et enregistrement des quantités soldées
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => vPositionID
                                           , aDocumentID      => aAddendumDocID
                                           , aPosCreateMode   => '215'
                                           , aSrcPositionID   => tplPosition.DOC_POSITION_ID
                                           , aErrorMsg        => aErrorMsg
                                            );

      if aErrorMsg is null then
        -- Màj de la position parente avec le lien sur la position courante
        update DOC_POSITION
           set POS_ADDENDUM_SRC_POS_ID = vPositionID
         where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;

        -- Màj des détails de position parente avec le lien sur les détails de position courante
        update DOC_POSITION_DETAIL PDE
           set PDE_ADDENDUM_SRC_PDE_ID = (select DOC_POSITION_DETAIL_ID
                                            from DOC_POSITION_DETAIL
                                           where DOC_POSITION_ID = vPositionID
                                             and DOC2_DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID)
         where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;

        -- Traitement de màj des liens pour les positions CPT si on a copié une position PT
        if tplPosition.C_GAUGE_TYPE_POS in('7', '8', '9', '10') then
          -- Liste des détails des positions CPT de la position PT courante
          for tplPdeSrc in (select   POS_TGT.DOC_POSITION_ID TGT_POS_ID
                                   , PDE_TGT.DOC_POSITION_DETAIL_ID TGT_PDE_ID
                                   , POS_TGT.POS_NUMBER TGT_POS_NUMBER
                                   , POS_SRC.DOC_POSITION_ID SRC_POS_ID
                                   , PDE_SRC.DOC_POSITION_DETAIL_ID SRC_PDE_ID
                                   , POS_SRC.POS_NUMBER SRC_POS_NUMBER
                                from DOC_POSITION POS_TGT
                                   , DOC_POSITION_DETAIL PDE_TGT
                                   , DOC_POSITION POS_SRC
                                   , DOC_POSITION_DETAIL PDE_SRC
                               where POS_TGT.DOC_DOCUMENT_ID = aAddendumDocID
                                 and POS_TGT.DOC_POSITION_ID = PDE_TGT.DOC_POSITION_ID
                                 and POS_TGT.DOC_DOC_POSITION_ID = vPositionID
                                 and POS_SRC.DOC_DOCUMENT_ID = aSrcDocID
                                 and POS_SRC.DOC_POSITION_ID = PDE_SRC.DOC_POSITION_ID
                                 and PDE_TGT.DOC2_DOC_POSITION_DETAIL_ID = PDE_SRC.DOC_POSITION_DETAIL_ID
                            order by 1
                                   , 2) loop
            -- Màj de la position CPT parente avec le lien sur la position CPT courante
            if vPosSrcID <> tplPdeSrc.SRC_POS_ID then
              vPosSrcID  := tplPdeSrc.SRC_POS_ID;

              update DOC_POSITION
                 set POS_ADDENDUM_SRC_POS_ID = tplPdeSrc.TGT_POS_ID
               where DOC_POSITION_ID = tplPdeSrc.SRC_POS_ID;
            end if;

            -- Màj du détail de position CPT parente avec le lien sur le détail de position CPT courante
            update DOC_POSITION_DETAIL PDE
               set PDE_ADDENDUM_SRC_PDE_ID = tplPdeSrc.TGT_PDE_ID
             where DOC_POSITION_DETAIL_ID = tplPdeSrc.SRC_PDE_ID;
          end loop;
        end if;
      else
        raise_application_error(-20100, aErrorMsg);
      end if;
    end loop;

    -- Copier les informations pour la générations des taxes liées aux coûts à répartir
    for ltplCosts in (select DOC_FOOT_ALLOY_ID
                        from DOC_FOOT_ALLOY
                       where DOC_FOOT_ID = aSrcDocID
                         and C_MUST_ADVANCE = '03'
                         and DFA_WEIGHT is null) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocFootAlloy, ltFootAlloy);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltFootAlloy, true, ltplCosts.DOC_FOOT_ALLOY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFootAlloy, 'DOC_FOOT_ID', aAddendumDocID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltFootAlloy);
      FWK_I_MGT_ENTITY.Release(ltFootAlloy);
    end loop;

    -- Mise à jour des totaux de document
    DOC_FINALIZE.FinalizeDocument(aAddendumDocId, 1, 1, 1);
    -- solde sans extourne du document cible (qui devient le document d'origine de l'avenant)
    p_BalanceAddendumDocument(aAddendumDocId);

    -- mise à jour du document source (qui devient l'avenant)
    update DOC_DOCUMENT
       set DMT_ADDENDUM_INDEX = nvl(DMT_ADDENDUM_INDEX, 0) + 1
         , DMT_ADDENDUM_OF_DOC_ID = nvl(DMT_ADDENDUM_OF_DOC_ID, aAddendumDocID)
         , DMT_ADDENDUM_SRC_DOC_ID = aAddendumDocId
         , DMT_ADDENDUM_NUMBER = aNumber
         , DMT_ADDENDUM_COMMENT = aComment
         , DMT_DATE_DOCUMENT = aDate
         , DMT_DATE_VALUE = aDate
         , A_DATEMOD = sysdate
         , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOCUMENT_ID = aSrcDocID;

    commit;
  exception
    -- retrouver l'état initial avant la génération de l'avenant
    when others then
      rollback to savepoint UpdateAddendumDocs;

      -- Récupération du numéro d'origine du document source
      select DMT_NUMBER
        into vOldNumber
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aAddendumDocId;

      -- Déprotéger le nouveau document avant l'effacement
      update DOC_DOCUMENT
         set DMT_PROTECTED = 0
           , DMT_ADDENDUM_INDEX = null
       where DOC_DOCUMENT_ID = aAddendumDocId;

      -- Effacer le nouveau document logistique
      DOC_DELETE.DeleteDocument(aAddendumDocId, 0);

      -- Rollback sur le numéro du document source
      update DOC_DOCUMENT
         set DMT_NUMBER = vOldNumber
       where DOC_DOCUMENT_ID = aSrcDocId;

      commit;
      -- message d'erreur
      raise;
  end UpdateAddendumDocs;

  /**
  * Description
  *    Initialisation des propriétés d'échange de données
  */
  procedure genCOM_EBANKING(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, ibDoStorePDF in boolean default true)
  is
    lv_check           varchar2(10);
    ln_ebanking_id     com_ebanking.com_ebanking_id%type;
    lv_billPresentment varchar2(10);
  begin
    -- Règle métier:
    --
    --   (A) le document n'existe pas dans COM_EBANKING
    --     * insertion dans com_ebanking
    --     * envoi de l'ordre au PrintServer
    --
    --   (B) le document existe dans COM_EBANKING avec le statut 'En préparation (000)'
    --     * envoi de l'ordre au PrintServer
    select op_check
      into lv_check
      from (select 'INS' op_check   -- (A)
              from dual
             where not exists(select 1
                                from COM_EBANKING
                               where DOC_DOCUMENT_ID = aDocumentId)
            union
            select 'UPD' op_check   -- (B)
              from dual
             where exists(select 1
                            from COM_EBANKING
                           where DOC_DOCUMENT_ID = aDocumentId
                             and C_CEB_EBANKING_STATUS = '000') );

    if (lv_check = 'INS') then   -- (A)
      ln_ebanking_id  := init_id_seq.nextval;

      insert into COM_EBANKING
                  (COM_EBANKING_ID
                 , ACT_DOCUMENT_ID
                 , ACI_DOCUMENT_ID
                 , C_ECS_SENDING_MODE
                 , C_ECS_VALIDATION
                 , C_CEB_EBANKING_STATUS
                 , C_CEB_DOCUMENT_ORIGIN
                 , PAC_EBPP_REFERENCE_ID
                 , C_ECS_ROLE
                 , PC_EXCHANGE_SYSTEM_ID
                 , DOC_DOCUMENT_ID
                 , CEB_XML_DOCUMENT
                 , CEB_PDF_FILE
                 , CEB_TRANSACTION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select ln_ebanking_id COM_EBANKING_ID
             , null   -- ACT_DOCUMENT_ID
             , null   -- ACI_DOCUMENT_ID
             , ECS.C_ECS_SENDING_MODE
             , ECS.C_ECS_VALIDATION
             , '000'   -- C_CEB_EBANKING_STATUS
             , '01'   -- C_CEB_DOCUMENT_ORIGIN
             , DMT.PAC_EBPP_REFERENCE_ID
             , ECS.C_ECS_ROLE
             , DMT.PC_EXCHANGE_SYSTEM_ID
             , DMT.DOC_DOCUMENT_ID
             , null   -- CEB_XML_DOCUMENT
             , null   -- CEB_PDF_FILE
             , com_lib_ebanking.NextEBankingTransactionId   -- CEB_TRANSACTION_ID
             , sysdate   -- A_DATECRE
             , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from DOC_DOCUMENT DMT
             , PCS.PC_EXCHANGE_SYSTEM ECS
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DMT.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

      -- Mise à jour du journal des transactions EBPP
      COM_PRC_EBANKING_DET.InsertEBPPDetail(in_ebanking_id => ln_ebanking_id, iv_ebanking_status => '000');
    end if;

    if (lv_check in('INS', 'UPD') ) then
      -- (A) ou (B)
      -- Envoi d'un fichier XML d'impression au serveur d'impression
      -- uniquement si mode de présentation = 01 (Avec Bill Presentment, PDF intégré dans le XML.)
      select ecs.c_ecs_bill_presentment
        into lv_billPresentment
        from pcs.pc_exchange_system ecs
           , doc_document dmt
       where ecs.pc_exchange_system_id = dmt.pc_exchange_system_id
         and dmt.doc_document_id = aDocumentId;

      if     ibDoStorePDF
         and lv_billPresentment = '01' then
        COM_PRC_EBANKING.StorePDFDocInEBPP(in_document_id => aDocumentId);
      end if;
    end if;
  end genCOM_EBANKING;

  /**
  * Description
  *    Contrôle la présence de détail des positions
  */
  function controlDetailPosition(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNumber number(1);
  begin
    -- Retourne le nbr de position sans détail de position
    -- Si la requête retourne 0 position, c'est OK donc on renvoit 1 (true)
    -- sinon 0(false).
    select case
             when count(POS.DOC_POSITION_ID) = 0 then 1
             else 0
           end
      into vNumber
      from DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = aDocumentId
       and POS.C_GAUGE_TYPE_POS in('1', '7', '71', '8', '81', '9', '91', '10', '101', '21')
       and (select count(PDE.DOC_POSITION_ID)
              from DOC_POSITION_DETAIL PDE
             where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID) = 0;

    return vNumber;
  end controlDetailPosition;

  /**
  * Description
  *    Contrôle la présence de l'emplacement de stock sur le détail
  *    si la position génére un mvt
  */
  function ControlDetailStock(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    vNumber number(1);
  begin
    -- Retourne le nbr de position qui générent un mvt de stock et dont le
    -- détail n'a pas d'emplacement
    -- Si la requête retourne 0 détail, c'est OK donc on renvoit 1 (true)
    -- sinon 0(false).
    select case
             when nvl(max(PDE.DOC_POSITION_DETAIL_ID), 0) = 0 then 1
             else 0
           end
      into vNumber
      from DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
         , STM_MOVEMENT_KIND MOK
     where POS.DOC_DOCUMENT_ID = aDocumentID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.C_GAUGE_TYPE_POS in('1', '7', '71', '8', '81', '9', '91', '10', '101', '21')
       and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
       and (    (   POS.STM_STOCK_ID is null
                 or (    PDE.STM_LOCATION_ID is null
                     and (STM_FUNCTIONS.IsVirtualStock(POS.STM_STOCK_ID) = 0) ) )
            or (    nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0) <> 0
                and ( (   POS.STM_STM_STOCK_ID is null
                       or (    PDE.STM_STM_LOCATION_ID is null
                           and (STM_FUNCTIONS.IsVirtualStock(POS.STM_STM_STOCK_ID) = 0) ) ) )
               )
           );

    return vNumber;
  end ControlDetailStock;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Recherche des références EBPP du partenaire facturation du document
  */
  procedure getEBPPReferences(
    aPAC_THIRD_ACI_ID      in     DOC_DOCUMENT.PAC_THIRD_ACI_ID%type
  , aCOM_NAME_ACI          in     DOC_DOCUMENT.COM_NAME_ACI%type
  , aPC_EXCHANGE_SYSTEM_ID out    DOC_DOCUMENT.PC_EXCHANGE_SYSTEM_ID%type
  , aPAC_EBPP_REFERENCE_ID out    DOC_DOCUMENT.PAC_EBPP_REFERENCE_ID%type
  )
  is
    function pGetExchangeSystemId(ivCOM_NAME_ACI in DOC_DOCUMENT.COM_NAME_ACI%type, ivEcsBsP in PAC_EBPP_REFERENCE.C_EBPP_BSP%type)
      return PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type
    is
      lnExchangeSystemId PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type;
    begin
      for tplECSKey in (select   ECS.PC_EXCHANGE_SYSTEM_ID
                            from PCS.PC_EXCHANGE_SYSTEM ECS
                               , PCS.PC_COMP COM
                           where ECS.C_ECS_BSP = ivEcsBsp
                             and ECS.PC_COMP_ID = COM.PC_COMP_ID
                             and COM.COM_NAME = nvl(ivCom_name_aci, PCS.PC_I_LIB_SESSION.GetComName)
                             and ECS.C_ECS_ROLE = '01'
                        order by ECS.ECS_DEFAULT desc
                               , ECS.ECS_KEY) loop
        lnExchangeSystemId  := tplECSKey.PC_EXCHANGE_SYSTEM_ID;
        exit;
      end loop;

      return lnExchangeSystemId;
    end;
  begin
    -- Recherche des références EBPP du partenaire facturation du document
    -- règle de gestion :
    -- * statut = active
    -- * mode d'intégration = logistique, logistique et finance
    -- * ayant une date valide
    -- * lié à un système d'échange de données actif ou  sans lien avec un système d'échange de données
    for tplEBPPRef in (select   EBP.C_EBPP_RELATION
                              , EBP.C_EBPP_BSP
                              , EBP.PAC_EBPP_REFERENCE_ID
                              , EBP.PC_EXCHANGE_SYSTEM_ID
                           from PAC_EBPP_REFERENCE EBP
                          where EBP.PAC_CUSTOM_PARTNER_ID = aPac_third_aci_id
                            and EBP.C_EBPP_STATUS = '1'
                            and EBP.C_EBP_INTEGRATION_MODE in('02', '03')
                            and trunc(sysdate) between trunc(EBP.EBP_VALID_FROM) and trunc(EBP.EBP_VALID_TO)
                            and (    (EBP.PC_EXCHANGE_SYSTEM_ID is null)
                                 or exists(select 1
                                             from PCS.PC_EXCHANGE_SYSTEM ECS
                                            where ECS.PC_EXCHANGE_SYSTEM_ID = EBP.PC_EXCHANGE_SYSTEM_ID
                                              and ECS.C_ECS_STATUS = '01')
                                )
                       order by EBP.EBP_DEFAULT desc
                              , EBP.EBP_VALID_FROM asc
                              , EBP.C_EBPP_BSP) loop
      aPAC_EBPP_REFERENCE_ID  := tplEBPPRef.PAC_EBPP_REFERENCE_ID;

      if tplEBPPRef.PC_EXCHANGE_SYSTEM_ID is not null then
        aPC_EXCHANGE_SYSTEM_ID  := tplEBPPRef.PC_EXCHANGE_SYSTEM_ID;
        exit;
      else
        aPC_EXCHANGE_SYSTEM_ID  := pGetExchangeSystemId(aCOM_NAME_ACI, tplEBPPRef.C_EBPP_BSP);

        if aPC_EXCHANGE_SYSTEM_ID is null then
          aPAC_EBPP_REFERENCE_ID  := null;
          exit;
        end if;
      end if;
    end loop;
  end getEBPPReferences;

  function CheckDocument(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return varchar2
  is
  begin
    return '';
--    return '[ABORT] Check confirm document';
  end CheckDocument;

  /**
  * Description
  *    Procedure de correction du taux de change d'un document (recalcul des
  *    montants en monnaie de base)
  * @created fp 26.09.2007
  * @lastUpdate
  * @public
  * @param aDocumentId : Id du document à traiter
  * @param aNewCurrRate : nouveaux taux de change
  * @param aNewBasePrice : nouveau diviseur
  * @param aAllowFinished : autorise de traiter un document liquidé (par défaut à False)
  *                         cela a pour effet de supprimer les documents financiers
  * @param aRateType : 0 : le taux des 2 monnaies ,  1 : taux monnaie étrangère , 2 : taux monnaie TVA
  */
  procedure changeDocumentCurrRate(
    aDocumentId    in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aNewCurrRate   in DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type
  , aNewBasePrice  in DOC_DOCUMENT.DMT_BASE_PRICE%type
  , aAllowFinished in boolean default false
  , aRateType      in varchar2 default 1
  , aFinalizeDoc   in boolean default true
  )
  is
    vDocStatus    DOC_DOCUMENT.C_DOCUMENT_STATUS%type;
    vDmtProtected DOC_DOCUMENT.DMT_PROTECTED%type;
    vDmtNumber    DOC_DOCUMENT.DMT_NUMBER%type;
    vDmtSessionId DOC_DOCUMENT.DMT_SESSION_ID%type;
  begin
    -- recherche status et vérification protection
    select C_DOCUMENT_STATUS
         , DMT_PROTECTED
         , DMT_SESSION_ID
         , DMT_NUMBER
      into vDocStatus
         , vDmtProtected
         , vDmtSessionId
         , vDmtNumber
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    DOC_DOCUMENT_FUNCTIONS.pChangeDocumentCurrRate(aDocumentID
                                                 , vDmtNumber
                                                 , vDocStatus
                                                 , vDmtProtected
                                                 , vDmtSessionId
                                                 , aNewCurrRate
                                                 , aNewBasePrice
                                                 , aAllowFinished
                                                 , aRateType
                                                  );

    -- Finalisation du document, Attention il faudra éventuellement reconfirmer le document
    if aFinalizeDoc then
      DOC_DOCUMENT_FUNCTIONS.FinalizeDocument(aDocumentId);
    end if;
  end changeDocumentCurrRate;
end DOC_DOCUMENT_FUNCTIONS;
