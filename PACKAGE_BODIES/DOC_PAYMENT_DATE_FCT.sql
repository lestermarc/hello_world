--------------------------------------------------------
--  DDL for Package Body DOC_PAYMENT_DATE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PAYMENT_DATE_FCT" 
is
  /**
  * Description
  *   procedure principale de création des échéances d'un document logistique
  *   supprime les anciennes échéances eventuelles
  */
  procedure GeneratePaymentDate(
    aDocumentId          in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aInitBvr             in number
  , aBvrGenerationMethod in varchar2
  , aWithBvrNum          in number
  , aForceGeneration     in number
  )
  is
    cursor docInfo_cursor(cDocumentId in number)
    is
      select DMT.DMT_DATE_VALUE
           , DMT.PAC_PAYMENT_CONDITION_ID
           , DMT.PAC_FINANCIAL_REFERENCE_ID
           , DMT.ACS_FIN_ACC_S_PAYMENT_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , GAU.C_ADMIN_DOMAIN
           , GAU.C_GAUGE_FORM_TYPE
           , GAU.GAUGE_FORM_TYPE1
           , GAU.GAUGE_FORM_TYPE2
           , GAU.GAUGE_FORM_TYPE3
           , GAU.GAUGE_FORM_TYPE4
           , GAU.GAUGE_FORM_TYPE5
           , FOO.DOC_FOOT_ID
           , FOO.FOO_DOCUMENT_TOTAL_AMOUNT
           , FOO.FOO_DOCUMENT_TOT_AMOUNT_B
           , FOO.FOO_DOCUMENT_TOT_AMOUNT_E
           , FOO.C_BVR_GENERATION_METHOD
           , FOO.FOO_REF_BVR_NUMBER
           , CUR.CURRENCY
           , PCO.C_PAYMENT_CONDITION_KIND
        from DOC_DOCUMENT DMT
           , DOC_FOOT FOO
           , DOC_GAUGE GAU
           , V_ACS_FINANCIAL_CURRENCY CUR
           , PAC_PAYMENT_CONDITION PCO
       where FOO.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUR.ACS_FINANCIAL_CURRENCY_ID = DMT.ACS_FINANCIAL_CURRENCY_ID
         and DMT.DOC_DOCUMENT_ID = cDocumentId
         and PCO.PAC_PAYMENT_CONDITION_ID = DMT.PAC_PAYMENT_CONDITION_ID;

    docInfo_tuple        docInfo_cursor%rowtype;
    bvrGenerationMethod  varchar2(10);
    generateBvr          boolean;

    cursor oldBvr_cursor(cFootId number)
    is
      select distinct rtrim(PAD_BVR_REFERENCE_NUM) PAD_BVR_REFERENCE_NUM
                 from DOC_PAYMENT_DATE
                where DOC_FOOT_ID = cFootId
                  and PAD_BVR_REFERENCE_NUM is not null
             order by PAD_BVR_REFERENCE_NUM asc;

    cursor crCurrentPaymentDate(cFootId number)
    is
      select   DOC_PAYMENT_DATE_ID
             , rtrim(PAD_BVR_REFERENCE_NUM) PAD_BVR_REFERENCE_NUM
             , PAD_BVR_CODING_LINE
             , PAD_NET_DATE_AMOUNT
             , PAD_NET_DATE_AMOUNT_B
             , PAD_BAND_NUMBER
             , PAD_MODIFY
          from DOC_PAYMENT_DATE
         where DOC_FOOT_ID = cFootId
      order by PAD_BAND_NUMBER asc
             , PAD_NET desc;

    bvrRefNum            DOC_PAYMENT_DATE.PAD_BVR_REFERENCE_NUM%type;
    totalRepart          PAC_CONDITION_DETAIL.CDE_ACCOUNT%type;
    nbSlice              PAC_CONDITION_DETAIL.CDE_PART%type;
    bvrReferenceNum      varchar2(30);
    bvrCodingLine        DOC_PAYMENT_DATE.PAD_BVR_CODING_LINE%type;
    partNumber           integer                                         default 0;
    redoPaymentDate      number(1);
    redoPaymentBvr       number(1);
    InfoExpiries         ACT_EXPIRY_MANAGEMENT.TInfoExpiriesRecType;
    tblCalculateExpiries ACT_EXPIRY_MANAGEMENT.TtblCalculateExpiriesType;
    rec                  ACT_EXPIRY_MANAGEMENT.TCalculateExpiriesRecType;
    vAdminDomain         DOC_GAUGE.C_ADMIN_DOMAIN%type;
  begin
    select DMT.DMT_REDO_PAYMENT_DATE
         , DMT.DMT_REDO_PAYMENT_BVR
         , GAU.C_ADMIN_DOMAIN
      into redoPaymentDate
         , redoPaymentBvr
         , vAdminDomain
      from DOC_DOCUMENT DMT
         , DOC_GAUGE GAU
     where DMT.DOC_DOCUMENT_ID = aDocumentId
       and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;

    open docInfo_cursor(aDocumentId);

    fetch docInfo_cursor
     into docInfo_tuple;

    close docInfo_cursor;

    if     docInfo_tuple.PAC_PAYMENT_CONDITION_ID is not null
       and docInfo_tuple.C_PAYMENT_CONDITION_KIND = '01' then
      -- recherche de la méthode de génération de bvr
      if aBvrGenerationMethod = '00' then
        bvrGenerationMethod  := docInfo_tuple.C_BVR_GENERATION_METHOD;
      else
        bvrGenerationMethod  := aBvrGenerationMethod;
      end if;

      -- Flag de génération de BVR
      generateBvr  :=
            (aWithBvrNum = 1)
        and docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID is not null
        and (    (     (   docInfo_tuple.C_ADMIN_DOMAIN = cAdminDomainPurchase
                        or docInfo_tuple.C_ADMIN_DOMAIN = cAdminDomainSubContract)
                  and docInfo_tuple.FOO_REF_BVR_NUMBER is not null
                 )
             or (    docInfo_tuple.C_ADMIN_DOMAIN = cAdminDomainSale
                 and bvrGenerationMethod in('02', '03') )
            );

      if    redoPaymentDate = 1
         or aForceGeneration = 1 then
        -- si le total du document est égale à 0 -> on force la regénération des nums BVR
        if nvl(docInfo_tuple.FOO_DOCUMENT_TOTAL_AMOUNT, 0) = 0 then
          redoPaymentBvr  := 1;
        end if;

        -- si on ne réinitialise pas les no BVR, on stocke les anciens numéros
        if (redoPaymentBvr = 0) then
          open oldBvr_cursor(aDocumentId);
        end if;

        -- suppression des éventuelles anciennes valeurs
        delete from DOC_PAYMENT_DATE
              where DOC_FOOT_ID = aDocumentId;

        if nvl(docInfo_tuple.FOO_DOCUMENT_TOTAL_AMOUNT, 0) <> 0 then
          -- si le total du document est différent de 0 -> Calcule des échéances selon la méthode de paiement
          ACT_EXPIRY_MANAGEMENT.GetInfoExpiries(InfoExpiries, docInfo_tuple.PAC_PAYMENT_CONDITION_ID);
        else
          -- sinon création d'une seul échéance a la date du document
          ACT_EXPIRY_MANAGEMENT.GetInfoExpiries(InfoExpiries, 0);
        end if;

        ACT_EXPIRY_MANAGEMENT.CalculateExpiries(InfoExpiries
                                              , tblCalculateExpiries
                                              , docInfo_tuple.FOO_DOCUMENT_TOT_AMOUNT_B
                                              , docInfo_tuple.FOO_DOCUMENT_TOTAL_AMOUNT
                                              , docInfo_tuple.FOO_DOCUMENT_TOT_AMOUNT_E
                                              , trunc(docInfo_tuple.DMT_DATE_VALUE)
                                              , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                              , 2
                                               );

        for pos in tblCalculateExpiries.first .. tblCalculateExpiries.last loop
          -- Charge valeurs de l'échéance dans rec
          rec  := tblCalculateExpiries(pos);

          -- Teste si les données BVR doivent être remplies
          if     generateBvr
             and docInfo_tuple.CURRENCY in(cSwissFrancCode, cEuroCode) then
            if     (rec.Slice <> partNumber)
               and (bvrGenerationMethod <> '01') then
              partNumber       := rec.Slice;
              bvrReferenceNum  := null;
              bvrCodingLine    := null;
            end if;

            if bvrReferenceNum is null then
              if docInfo_tuple.FOO_REF_BVR_NUMBER is not null then
                bvrReferenceNum  := docInfo_tuple.FOO_REF_BVR_NUMBER;
              else
                if (redoPaymentBvr = 0) then
                  -- recherche dans le curseur des anciennes références BVR
                  fetch oldBvr_cursor
                   into bvrReferenceNum;

                  if not oldBvr_cursor%found then
                    --Fonction de calcul de numéro BVR
                    ACS_FUNCTION.SET_BVR_REF(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID, '1', aDocumentId, bvrReferenceNum);
                  end if;
                else
                  --Fonction de calcul de numéro BVR
                  ACS_FUNCTION.SET_BVR_REF(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID, '1', aDocumentId, bvrReferenceNum);
                end if;
              end if;
            end if;

            -- Fonction de calcul de la ligne de codage BVR
            if bvrGenerationMethod not in('01', '02') then
              --Avec montant
              bvrCodingLine  :=
                ACS_FUNCTION.Get_Bvr_Coding_Line(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                               , bvrReferenceNum
                                               , rec.Amount_LC
                                               , ACS_FUNCTION.GetLocalCurrencyID
                                               , rec.Amount_FC
                                               , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                                );
            else
              --Sans montant
              bvrCodingLine  :=
                ACS_FUNCTION.Get_Bvr_Coding_Line(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                               , bvrReferenceNum
                                               , 0
                                               , ACS_FUNCTION.GetLocalCurrencyID
                                               , 0
                                               , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                                );
            end if;
          end if;

          -- insertion de l'échéance
          insert into DOC_PAYMENT_DATE
                      (DOC_PAYMENT_DATE_ID
                     , DOC_FOOT_ID
                     , PAD_BAND_NUMBER
                     , PAD_PAYMENT_DATE
                     , PAD_NET
                     , PAD_DATE_AMOUNT
                     , PAD_DATE_AMOUNT_B
                     , PAD_DATE_AMOUNT_E
                     , PAD_DISCOUNT_AMOUNT
                     , PAD_DISCOUNT_AMOUNT_B
                     , PAD_DISCOUNT_AMOUNT_E
                     , PAD_NET_DATE_AMOUNT
                     , PAD_NET_DATE_AMOUNT_B
                     , PAD_NET_DATE_AMOUNT_E
                     , PAD_BVR_REFERENCE_NUM
                     , PAD_BVR_CODING_LINE
                     , PAD_AMOUNT_PROV_LC
                     , PAD_AMOUNT_PROV_FC
                     , A_IDCRE
                     , A_DATECRE
                      )
               values (init_id_seq.nextval
                     , aDocumentId
                     , rec.Slice
                     , rec.DateCalculated
                     , rec.CalcNet
                     , rec.Amount_FC + rec.Discount_FC
                     , rec.Amount_LC + rec.Discount_LC
                     , rec.Amount_EUR + rec.Discount_FC
                     , rec.Discount_FC
                     , rec.Discount_LC
                     , rec.Discount_EUR
                     , rec.Amount_FC
                     , rec.Amount_LC
                     , rec.Amount_EUR
                     , bvrReferenceNum
                     , bvrCodingLine
                     , 0
                     , 0
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , sysdate
                      );
        end loop;

        if (redoPaymentBvr = 0) then
          close oldBvr_cursor;
        end if;

        update DOC_DOCUMENT
           set DMT_REDO_PAYMENT_DATE = 0
             , DMT_REDO_PAYMENT_BVR = 0
         where DOC_DOCUMENT_ID = aDocumentId;
      -- Regénération des numéros de bvr et des lignes de codage
      elsif redoPaymentBvr = 1 then
        for tplCurrentPaymentDate in crCurrentPaymentDate(aDocumentId) loop
          -- Teste si les données BVR doivent être remplies
          if     generateBvr
             and docInfo_tuple.CURRENCY in(cSwissFrancCode, cEuroCode) then
            if     (tplCurrentPaymentDate.PAD_BAND_NUMBER <> partNumber)
               and (bvrGenerationMethod <> '01') then
              partNumber     := tplCurrentPaymentDate.PAD_BAND_NUMBER;

              if    vAdminDomain = cAdminDomainPurchase
                 or vAdminDomain = cAdminDomainSubContract then
                bvrReferenceNum  := nvl(docInfo_tuple.FOO_REF_BVR_NUMBER, tplCurrentPaymentDate.PAD_BVR_REFERENCE_NUM);
              else
                bvrReferenceNum  := tplCurrentPaymentDate.PAD_BVR_REFERENCE_NUM;
              end if;

              bvrCodingLine  := null;
            end if;

            if bvrReferenceNum is null then
              if docInfo_tuple.FOO_REF_BVR_NUMBER is not null then
                bvrReferenceNum  := docInfo_tuple.FOO_REF_BVR_NUMBER;
              else
                ACS_FUNCTION.SET_BVR_REF(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID, '1', aDocumentId, bvrReferenceNum);
              end if;
            end if;

            -- Fonction de calcul de la ligne de codage BVR
            if tplCurrentPaymentDate.PAD_BVR_CODING_LINE is null then
              if bvrGenerationMethod not in('01', '02') then
                --Avec montant
                bvrCodingLine  :=
                  ACS_FUNCTION.Get_Bvr_Coding_Line(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                                 , bvrReferenceNum
                                                 , tplCurrentPaymentDate.PAD_NET_DATE_AMOUNT_B
                                                 , ACS_FUNCTION.GetLocalCurrencyID
                                                 , tplCurrentPaymentDate.PAD_NET_DATE_AMOUNT
                                                 , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                                  );
              else
                --Sans montant
                bvrCodingLine  :=
                  ACS_FUNCTION.Get_Bvr_Coding_Line(docInfo_tuple.ACS_FIN_ACC_S_PAYMENT_ID
                                                 , bvrReferenceNum
                                                 , 0
                                                 , ACS_FUNCTION.GetLocalCurrencyID
                                                 , 0
                                                 , docInfo_tuple.ACS_FINANCIAL_CURRENCY_ID
                                                  );
              end if;
            elsif tplCurrentPaymentDate.PAD_BVR_CODING_LINE is not null then
              bvrCodingLine  := tplCurrentPaymentDate.PAD_BVR_CODING_LINE;
            end if;
          end if;

          -- insertion de l'échéance
          update DOC_PAYMENT_DATE
             set PAD_BVR_REFERENCE_NUM = bvrReferenceNum
               , PAD_BVR_CODING_LINE = bvrCodingLine
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , A_DATEMOD = sysdate
           where DOC_PAYMENT_DATE_ID = tplCurrentPaymentDate.DOC_PAYMENT_DATE_ID;
        end loop;
      end if;
    -- si on a pas de conditions de paiement on efface les échéances
    else
      -- suppression des éventuelles anciennes valeurs
      delete from DOC_PAYMENT_DATE
            where DOC_FOOT_ID = aDocumentId;
    end if;
  end GeneratePaymentDate;

  /**
  * Description
  *   Cette fonction renvoie True si il faut recalculer les échéances
  */
  procedure MustRecalcPaymentDate(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aResultFlag out number)
  is
    padTotDateAmount   DOC_PAYMENT_DATE.PAD_DATE_AMOUNT%type;
    padTotDateAmountB  DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_B%type;
    padTotDateAmountE  DOC_PAYMENT_DATE.PAD_DATE_AMOUNT_E%type;
    maxBandNumber      DOC_PAYMENT_DATE.PAD_BAND_NUMBER%type;
    fooTotAmount       DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    fooTotAmountB      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type;
    fooTotAmountE      DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_E%type;
    deltaTotAmount     DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    deltaTotAmountB    DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_B%type;
    deltaTotAmountE    DOC_FOOT.FOO_DOCUMENT_TOT_AMOUNT_E%type;
    generationMethod   DOC_FOOT.C_BVR_GENERATION_METHOD%type;
    manualModification number(1);
    redoPaymentDate    number(1);
    redoPaymentBvr     number(1);
    finAccSPaymentId   DOC_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID%type;
  begin
    aResultFlag  := 0;

    select DMT_REDO_PAYMENT_DATE
         , ACS_FIN_ACC_S_PAYMENT_ID
      into redoPaymentDate
         , finAccSPaymentId
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;

    if redoPaymentDate = 1 then
      -- recherche du total des montant des échéances nettes
      select nvl(sum(PAD.PAD_DATE_AMOUNT), 0)
           , nvl(sum(PAD.PAD_DATE_AMOUNT_B), 0)
           , nvl(sum(PAD.PAD_DATE_AMOUNT_E), 0)
           , max(PAD.PAD_BAND_NUMBER)
        into padTotDateAmount
           , padTotDateAmountB
           , padTotDateAmountE
           , maxBandNumber
        from DOC_PAYMENT_DATE PAD
       where PAD.DOC_FOOT_ID = aDocumentId
         and PAD_DISCOUNT_AMOUNT = 0;

      -- recherche des montants totaux du document
      begin
        select FOO.FOO_DOCUMENT_TOTAL_AMOUNT
             , FOO.FOO_DOCUMENT_TOT_AMOUNT_B
             , FOO.FOO_DOCUMENT_TOT_AMOUNT_E
             , C_BVR_GENERATION_METHOD
          into fooTotAmount
             , fooTotAmountB
             , fooTotAmountE
             , generationMethod
          from DOC_FOOT FOO
         where FOO.DOC_FOOT_ID = aDocumentId;
      exception
        when no_data_found then
          raise_application_error(-20036, 'PCS - Document has no foot');
      end;

      -- comparaison des montants de document et d'échéances
      deltaTotAmount   := fooTotAmount - padTotDateAmount;
      deltaTotAmountB  := fooTotAmountB - padTotDateAmountB;
      deltaTotAmountE  := fooTotAmountE - padTotDateAmountE;

      -- recherche si on a des modifications manuelles
      select sign(sum(PAD.PAD_MODIFY) )
        into manualModification
        from DOC_PAYMENT_DATE PAD
           , DOC_FOOT FOO
       where PAD.DOC_FOOT_ID(+) = FOO.DOC_FOOT_ID
         and FOO.DOC_DOCUMENT_ID = aDocumentId;

      -- si les montants sont différents et que l'on a effectué une correction manuelle des échéances et que le document ne soit pas à 0
      if (manualModification = 1) then
        if     (   deltaTotAmount <> 0
                or deltaTotAmountB <> 0
                or deltaTotAmountE <> 0)
           and (fooTotAmount <> 0) then
          -- Mise à jour du montant des dernières échéances
          update DOC_PAYMENT_DATE
             set PAD_DATE_AMOUNT = PAD_DATE_AMOUNT + deltaTotAmount
               , PAD_DATE_AMOUNT_B = PAD_DATE_AMOUNT_B + deltaTotAmountB
               , PAD_DATE_AMOUNT_E = PAD_DATE_AMOUNT_E + deltaTotAmountE
               , PAD_NET_DATE_AMOUNT = PAD_DATE_AMOUNT + deltaTotAmount - PAD_DISCOUNT_AMOUNT
               , PAD_NET_DATE_AMOUNT_B = PAD_DATE_AMOUNT_B + deltaTotAmountB - PAD_DISCOUNT_AMOUNT_B
               , PAD_NET_DATE_AMOUNT_E = PAD_DATE_AMOUNT_E + deltaTotAmountE - PAD_DISCOUNT_AMOUNT_E
               , PAD_BVR_CODING_LINE =
                   decode(generationMethod
                        , '03', ACS_FUNCTION.Get_Bvr_Coding_Line(finAccSPaymentId, PAD_BVR_REFERENCE_NUM
                                                               , PAD_DATE_AMOUNT + deltaTotAmount - PAD_DISCOUNT_AMOUNT)
                        , PAD_BVR_CODING_LINE
                         )
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_FOOT_ID = aDocumentId
             and PAD_BAND_NUMBER = maxBandNumber;
        end if;

        update DOC_DOCUMENT
           set DMT_REDO_PAYMENT_DATE = 0
         where DOC_DOCUMENT_ID = aDocumentId;
      end if;
    end if;

    select sign(DMT_REDO_PAYMENT_BVR + DMT_REDO_PAYMENT_DATE)
      into aResultFlag
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentId;
  end MustRecalcPaymentDate;

  /**
  * Description
  *   procedure faisant la synthèse entre MustRecalcPaymentDate et GeneratePaymentDate
  */
  procedure UpdatePaymentDate(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aInitBvr in number, aBvrGenerationMethod in varchar2, aWithBvrNum in number)
  is
    recalcPayment number(1);
  begin
    -- recalcul des échéances
    MustRecalcPaymentDate(aDocumentId, recalcPayment);

    if recalcPayment = 1 then
      GeneratePaymentDate(aDocumentId, 0,   -- travail avec le flag sur doc_document
                          '00',   -- reprend la méthode de génération BVR du document
                          1, 0);   -- force la génération
    end if;
  end UpdatePaymentDate;
end DOC_PAYMENT_DATE_FCT;
