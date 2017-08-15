--------------------------------------------------------
--  DDL for Package Body IND_DOCUMENT_REVALUATION_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_DOCUMENT_REVALUATION_FCT" 
is
  /**
   * procedure SelectGauge
   * Description
   *   Insert dans la base de données (table COM_LIST_ID_TEMP) les gabarits récupérés depuis le profil
   */
  procedure SelectGauge(aGaugeList in varchar2)
  is
    -- curseur servant à l'extraction des valeurs séparées par un point virgule
    cursor crTab(aStr in varchar2)
    is
      select extractvalue(column_value, '/x') as val
        from (select aStr c
                from dual)
           , table(xmlsequence(extract(xmltype('<list><x>' || replace(c, ';', '</x><x>') || '</x></list>'), '/list/x') ) );
  begin
    -- suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_GAUGE_ID';

    for cur in crTab(aGaugeList) loop
      -- ajout de chacun des gabarits sélectionnés
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (cur.val
                 , 'DOC_GAUGE_ID'
                  );
    end loop;
  end SelectGauge;

  /**
   * procedure SelectCurrency
   * Description
   *   Insert dans la base de données (table COM_LIST_ID_TEMP) les monnaies récupérées depuis le profil
   */
  procedure SelectCurrency(aCurrencyList in varchar2)
  is
    -- curseur servant à l'extraction des valeurs séparées par un point virgule
    cursor crTab(aStr in varchar2)
    is
      select extractvalue(column_value, '/x') as val
        from (select aStr c
                from dual)
           , table(xmlsequence(extract(xmltype('<list><x>' || replace(c, ';', '</x><x>') || '</x></list>'), '/list/x') ) );
  begin
    -- suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'CURRENCY_ID';

    for cur in crTab(aCurrencyList) loop
      -- ajout de chacune des monnaies sélectionnées
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (cur.val
                 , 'CURRENCY_ID'
                  );
    end loop;
  end SelectCurrency;

  /**
   * procedure SelectDocument
   * Description
   *   Sélectionne un document à réévaluer
  *
  */
  procedure SelectDocument(aDOC_DOCUMENT_ID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_DOCUMENT_ID';

    -- ajout de l'id du document à réévaluer
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aDOC_DOCUMENT_ID
               , 'DOC_DOCUMENT_ID'
                );
  end SelectDocument;

  /**
   * procedure SelectDocuments
   * Description
   *   Sélectionne les documents à réévaluer selon les filtres
   */
  procedure SelectDocuments(
    aDRE_THIRD_FROM          in PAC_PERSON.PER_NAME%type
  , aDRE_THIRD_TO            in PAC_PERSON.PER_NAME%type
  , aDRE_THIRD_DELIVERY_FROM in PAC_PERSON.PER_NAME%type
  , aDRE_THIRD_DELIVERY_TO   in PAC_PERSON.PER_NAME%type
  , aDRE_THIRD_ACI_FROM      in PAC_PERSON.PER_NAME%type
  , aDRE_THIRD_ACI_TO        in PAC_PERSON.PER_NAME%type
  , aDRE_DATE_FROM           in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDRE_DATE_TO             in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  )
  is
    type TDocIdCur is ref cursor;

    crDocId      TDocIdCur;
    vSqlCommand  varchar2(32000);
    vWhereClause varchar2(32000);
    vDocId       DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vNbGauge     number;
    vNbCurrency  number;
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_DOCUMENT_ID';

    -- recherche le nombre de gabarits sélectionnés
    select count(*)
      into vNbGauge
      from COM_LIST_ID_TEMP CLI
     where CLI.LID_CODE = 'DOC_GAUGE_ID';

    -- recherche le nombre de monnaies sélectionnées
    select count(*)
      into vNbCurrency
      from COM_LIST_ID_TEMP CLI
     where CLI.LID_CODE = 'CURRENCY_ID';

    vSqlCommand   := 'select distinct DMT.DOC_DOCUMENT_ID' || '  from DOC_DOCUMENT DMT             ';
    -- création de la clause whrere
    vWhereClause  := '';

    -- filtre sur les partenaires preneurs d'ordre
    if (    aDRE_THIRD_FROM is not null
        and aDRE_THIRD_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                                                             ' ||
        '                             from PAC_PERSON PER                                                                                ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_FROM ||
        ''' and PER.PER_NAME <= ''' ||
        aDRE_THIRD_TO ||
        ''')';
    elsif(aDRE_THIRD_FROM is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                             ' ||
        '                             from PAC_PERSON PER                                ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_FROM ||
        ''')';
    elsif(aDRE_THIRD_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                          ' ||
        '                            from PAC_PERSON PER                              ' ||
        '                           where PER.PER_NAME <= ''' ||
        aDRE_THIRD_TO ||
        ''')';
    end if;

    -- filtre sur les partenaires de livraison
    if (    aDRE_THIRD_DELIVERY_FROM is not null
        and aDRE_THIRD_DELIVERY_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                                                                               ' ||
        '                             from PAC_PERSON PER                                                                                                  ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_DELIVERY_FROM ||
        ''' and PER.PER_NAME <= ''' ||
        aDRE_THIRD_DELIVERY_TO ||
        ''')';
    elsif(aDRE_THIRD_DELIVERY_FROM is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                      ' ||
        '                             from PAC_PERSON PER                                         ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_DELIVERY_FROM ||
        ''')';
    elsif(aDRE_THIRD_DELIVERY_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                    ' ||
        '                             from PAC_PERSON PER                                       ' ||
        '                            where PER.PER_NAME <= ''' ||
        aDRE_THIRD_DELIVERY_TO ||
        ''')';
    end if;

    -- filtre sur les partenaires de facturation
    if (    aDRE_THIRD_ACI_FROM is not null
        and aDRE_THIRD_ACI_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                                                                     ' ||
        '                             from PAC_PERSON PER                                                                                        ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_ACI_FROM ||
        ''' and PER.PER_NAME <= ''' ||
        aDRE_THIRD_ACI_TO ||
        ''')';
    elsif(aDRE_THIRD_ACI_FROM is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                                 ' ||
        '                             from PAC_PERSON PER                                    ' ||
        '                            where PER.PER_NAME >= ''' ||
        aDRE_THIRD_ACI_FROM ||
        ''')';
    elsif(aDRE_THIRD_ACI_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.PAC_THIRD_ID in (select PER.PAC_PERSON_ID                               ' ||
        '                             from PAC_PERSON PER                                  ' ||
        '                            where PER.PER_NAME <= ''' ||
        aDRE_THIRD_ACI_TO ||
        ''')';
    end if;

    -- filtre sur les gabarits
    if (vNbGauge > 0) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.DOC_GAUGE_ID in (select CLI.COM_LIST_ID_TEMP_ID         ' ||
        '                             from COM_LIST_ID_TEMP CLI            ' ||
        '                            where CLI.LID_CODE = ''DOC_GAUGE_ID'')';
    end if;

    -- filtre sur les monnaies
    if (vNbCurrency > 0) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        '      DMT.ACS_FINANCIAL_CURRENCY_ID in (select CLI.COM_LIST_ID_TEMP_ID        ' ||
        '                                          from COM_LIST_ID_TEMP CLI           ' ||
        '                                         where CLI.LID_CODE = ''CURRENCY_ID'')';
    end if;

    -- filtre sur les dates
    if (    aDRE_DATE_FROM is not null
        and aDRE_DATE_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  :=
        vWhereClause ||
        ' DMT.DMT_DATE_DOCUMENT >= to_date(''' ||
        aDRE_DATE_FROM ||
        ''') and DMT.DMT_DATE_DOCUMENT <= to_date(''' ||
        aDRE_DATE_TO ||
        ''')';
    elsif(aDRE_DATE_FROM is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  := vWhereClause || ' DMT.DMT_DATE_DOCUMENT >= to_date(''' || aDRE_DATE_FROM || ''')';
    elsif(aDRE_DATE_TO is not null) then
      if (vWhereClause is not null) then
        vWhereClause  := vWhereClause || ' and ';
      end if;

      vWhereClause  := vWhereClause || ' DMT.DMT_DATE_DOCUMENT >= to_date(''' || aDRE_DATE_TO || ''')';
    end if;

    if (vWhereClause is not null) then
      vSqlCommand  := vSqlCommand || ' where ' || vWhereClause;
    end if;

    -- parcourt des documents trouvés
    open crDocId for vSqlCommand;

    loop
      fetch crDocId
       into vDocId;

      exit when crDocId%notfound;

      -- ajout de l'id de chaque document à réévaluer
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (vDocId
                 , 'DOC_DOCUMENT_ID'
                  );
    end loop;

    close crDocId;
  end SelectDocuments;

  /**
   * procedure RevaluateDocument
   * Description
   *   Met à jour la date de réévaluation du document (= aRevaluationDate) dont l'id est passé en paramètre (aDocumentId)
   */
  procedure RevaluateDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aRevaluationDate in date)
  is
    vReturn                number(1);
    vRateExchange          number;
    vBasePrice             number;
    vBaseChange            number;
    vRateExchangeEUR_ME    number;
    vFixedRateEUR_ME       number;
    vRateExchangeEUR_MB    number;
    vFixedRateEUR_MB       number;
    acsFinancialCurrencyID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if (aRevaluationDate is not null) then
      update DOC_DOCUMENT
         set DMT_REVALUATION_DATE = aRevaluationDate
       where DOC_DOCUMENT_ID = aDocumentId;
    end if;

    -- récupération de la monnaie du document
    select ACS_FINANCIAL_CURRENCY_ID
      into acsFinancialCurrencyID
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    -- mise à jour du taux de la TVA pour chaque position
    update DOC_POSITION
       set POS_VAT_RATE = Acs_Function.GetVatRate(ACS_TAX_CODE_ID, to_char(aRevaluationDate, 'yyyymmdd') )
         , POS_MODIFY_RATE = 1
     where DOC_DOCUMENT_ID = aDocumentId;

    if (acsFinancialCurrencyID is not null) then
      -- Recherche du cours de la monnaie Document
      vReturn  :=
        Acs_Function.GetRateOfExchangeEUR(aCurrencyID           => acsFinancialCurrencyID
                                        , aSortRate             => 1   -- 1 -> ask for PCU_DAYLY_PRICE
                                        , aDate                 => aRevaluationDate
                                        , aRateExchange         => vRateExchange
                                        , aBasePrice            => vBasePrice
                                        , aBaseChange           => vBaseChange
                                        , aRateExchangeEUR_ME   => vRateExchangeEUR_ME
                                        , aFixedRateEUR_ME      => vFixedRateEUR_ME
                                        , aRateExchangeEUR_MB   => vRateExchangeEUR_MB
                                        , aFixedRateEUR_MB      => vFixedRateEUR_MB
                                        , aLogistic             => 1
                                         );

      -- Si le cours est en monnaie étrangère, alors on le convertit en monnaie base
      if vBaseChange = 0 then
        vRateExchange  :=( (vBasePrice * vBasePrice) / vRateExchange);
      end if;

      -- mise à jour du taux de change du document et mise à jour des différents montants
      IND_DOC_FUNCTIONS.changeDocumentCurrRate(aDocumentId, vRateExchange, vBasePrice);
    end if;
  end RevaluateDocument;

  /**
   * procedure GetNewRate
   * Description
   *   Recherche le taux de change d'une monnaie passée en paramètre à la date passée également en paramètre
   */
  function GetNewRate(
    acsFinancialCurrencyID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aRevaluationDate       in date
  )
    return number
  is
    vReturn             number(1);
    vRateExchange       number;
    vBasePrice          number;
    vBaseChange         number;
    vRateExchangeEUR_ME number;
    vFixedRateEUR_ME    number;
    vRateExchangeEUR_MB number;
    vFixedRateEUR_MB    number;
  begin
    if (    acsFinancialCurrencyID is not null
        and aRevaluationDate is not null) then
      -- Recherche du cours de la monnaie Document
      vReturn  :=
        Acs_Function.GetRateOfExchangeEUR(aCurrencyID           => acsFinancialCurrencyID
                                        , aSortRate             => 1   -- 1 -> ask for PCU_DAYLY_PRICE
                                        , aDate                 => aRevaluationDate
                                        , aRateExchange         => vRateExchange
                                        , aBasePrice            => vBasePrice
                                        , aBaseChange           => vBaseChange
                                        , aRateExchangeEUR_ME   => vRateExchangeEUR_ME
                                        , aFixedRateEUR_ME      => vFixedRateEUR_ME
                                        , aRateExchangeEUR_MB   => vRateExchangeEUR_MB
                                        , aFixedRateEUR_MB      => vFixedRateEUR_MB
                                        , aLogistic             => 1
                                         );

      -- Si le cours est en monnaie étrangère, alors on le convertit en monnaie base
      if vBaseChange = 0 then
        vRateExchange  :=( (vBasePrice * vBasePrice) / vRateExchange);
      end if;

      return vRateExchange;
    else
      return null;
    end if;
  end GetNewRate;

  /**
   * procedure GetBasePrice
   * Description
   *   Recherche la valeur "par rapport à" du taux de change d'une monnaie passée en paramètre
   *   à la date passée également en paramètre
   */
  function GetBasePrice(
    acsFinancialCurrencyID in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aRevaluationDate       in date
  )
    return number
  is
    vReturn             number(1);
    vRateExchange       number;
    vBasePrice          number;
    vBaseChange         number;
    vRateExchangeEUR_ME number;
    vFixedRateEUR_ME    number;
    vRateExchangeEUR_MB number;
    vFixedRateEUR_MB    number;
  begin
    if (    acsFinancialCurrencyID is not null
        and aRevaluationDate is not null) then
      -- Recherche du cours de la monnaie Document
      vReturn  :=
        Acs_Function.GetRateOfExchangeEUR(aCurrencyID           => acsFinancialCurrencyID
                                        , aSortRate             => 1   -- 1 -> ask for PCU_DAYLY_PRICE
                                        , aDate                 => aRevaluationDate
                                        , aRateExchange         => vRateExchange
                                        , aBasePrice            => vBasePrice
                                        , aBaseChange           => vBaseChange
                                        , aRateExchangeEUR_ME   => vRateExchangeEUR_ME
                                        , aFixedRateEUR_ME      => vFixedRateEUR_ME
                                        , aRateExchangeEUR_MB   => vRateExchangeEUR_MB
                                        , aFixedRateEUR_MB      => vFixedRateEUR_MB
                                        , aLogistic             => 1
                                         );
      return vBasePrice;
    else
      return null;
    end if;
  end GetBasePrice;

  procedure DocReevalDate(DocFrom doc_document.dmt_number%type, DocTo doc_document.dmt_number%type, vDateReeval date)
  -- Réévaluation des documents à une date donnée
  is
   cursor CurCheck is
    select
    dmt_number
    from
    doc_document
    where
    C_DOCUMENT_STATUS<>'01'
    and dmt_number>=DocFrom
    and dmt_number<=DocTo
    and ACS_FINANCIAL_CURRENCY_ID<>acs_function.GetLocalCurrencyId;

    cursor CurDoc is
    select
    doc_document_id, dmt_date_document
    from
    doc_document
    where
    dmt_number>=DocFrom
    and dmt_number<=DocTo
    and ACS_FINANCIAL_CURRENCY_ID<>acs_function.GetLocalCurrencyId;

   vCount integer;
   Msg varchar2(4000);

  begin
   vCount:=0;
   Msg:='';

   -- *** ETAPE 1 *** Test si les documents ne sont pas en status "A confirmer"
   for RowCheck in CurCheck
   loop
    Msg:=Msg||RowCheck.dmt_number||chr(10);
    vCount:=vCount+1;
   end loop;

   if vCount>0
   then raise_application_error(-20001,'>>>>>>>>>>>>>>>>'||chr(10)||chr(10)||
                                       'Les documents doivent être en statut "A confirmer" : '||chr(10)||
                                       Msg||chr(10)||
                                       '>>>>>>>>>>>>>>>>');
   end if;

   -- *** ETAPE 2 *** Réévaluation
   for RowDoc in CurDoc
   loop

   update doc_document
   set DMT_REVALUATION_DATE=null,
        DMT_DATE_DELIVERY=null
   where doc_document_id=RowDoc.doc_document_id;

   update doc_document
   set DMT_REVALUATION_DATE=vDateReeval,
        DMT_DATE_DELIVERY=vDateReeval,
        a_datemod=sysdate,
        a_idmod=pcs.pc_init_session.GetUserIni
   where doc_document_id=RowDoc.doc_document_id;

  DOC_FINALIZE.FINALIZEDOCUMENT(aDocumentId => RowDoc.doc_document_id
                              , aExecExternProc => 0);

   end loop;

  end DocReevalDate;

  procedure DocReval(DocFrom doc_document.dmt_number%type, DocTo doc_document.dmt_number%type, vDateReeval date)
  -- Réévaluation des documents à une date donnée
  is
   cursor CurCheck is
    select
    dmt_number
    from
    doc_document
    where
    C_DOCUMENT_STATUS<>'01'
    and dmt_number>=DocFrom
    and dmt_number<=DocTo
    and ACS_FINANCIAL_CURRENCY_ID<>acs_function.GetLocalCurrencyId;

    cursor CurDoc is
    select
    doc_document_id,
    dmt_date_document,
    acs_financial_currency_id
    from
    doc_document
    where
    dmt_number>=DocFrom
    and dmt_number<=DocTo
    and ACS_FINANCIAL_CURRENCY_ID<>acs_function.GetLocalCurrencyId;

   vCount integer;
   Msg varchar2(4000);
   vNewRate number;
   vBasePrice number;

  begin
   vCount:=0;
   Msg:='';

   -- *** ETAPE 1 *** Test si les documents ne sont pas en status "A confirmer"
   for RowCheck in CurCheck
   loop
    Msg:=Msg||RowCheck.dmt_number||chr(10);
    vCount:=vCount+1;
   end loop;

   if vCount>0
   then raise_application_error(-20001,'>>>>>>>>>>>>>>>>'||chr(10)||chr(10)||
                                       'Les documents doivent être en statut "A confirmer" : '||chr(10)||
                                       Msg||chr(10)||
                                       '>>>>>>>>>>>>>>>>');
   end if;

   -- *** ETAPE 2 *** Réévaluation
   for RowDoc in CurDoc
   loop

   select GetNewRate(RowDoc.acs_financial_currency_id,vDateReeval) into vNewRate
   from dual;

   select GetBasePrice(RowDoc.acs_financial_currency_id,vDateReeval) into vBasePrice
   from dual;

   RevaluateDocument(RowDoc.doc_document_id,vDateReeval);

   end loop;

  end DocReval;

end IND_DOCUMENT_REVALUATION_FCT;
