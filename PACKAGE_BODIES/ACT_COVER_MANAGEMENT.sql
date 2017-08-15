--------------------------------------------------------
--  DDL for Package Body ACT_COVER_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_COVER_MANAGEMENT" 
is
  type TtblPartImputationId is table of ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
    index by binary_integer;

--------------
  function GetDefFinRef(
    aPAC_CUSTOM_PARTNER_ID   PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
    return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  is
    cursor csrCustRef(CustPartId PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    is
      select   fref.PAC_FINANCIAL_REFERENCE_ID
             , fref.FRE_DEFAULT
          from pac_financial_reference fref
         where fref.PAC_CUSTOM_PARTNER_ID = CustPartId
      order by fref.FRE_DEFAULT desc;

    tplCustRef csrCustRef%rowtype;

    cursor csrSuppRef(SuppPartId PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    is
      select   fref.PAC_FINANCIAL_REFERENCE_ID
             , fref.FRE_DEFAULT
          from pac_financial_reference fref
         where fref.PAC_SUPPLIER_PARTNER_ID = SuppPartId
      order by fref.FRE_DEFAULT desc;

    tplSuppRef csrSuppRef%rowtype;
    result     PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type   := null;
  begin
    if aPAC_CUSTOM_PARTNER_ID is not null then
      open csrCustRef(aPAC_CUSTOM_PARTNER_ID);

      fetch csrCustRef
       into tplCustRef;

      if csrCustRef%found then
        result  := tplCustRef.PAC_FINANCIAL_REFERENCE_ID;

        if tplCustRef.FRE_DEFAULT != 1 then
          fetch csrCustRef
           into tplCustRef;

          if csrCustRef%found then
            result  := null;
          end if;
        end if;
      end if;

      close csrCustRef;
    elsif aPAC_SUPPLIER_PARTNER_ID is not null then
      open csrSuppRef(aPAC_SUPPLIER_PARTNER_ID);

      fetch csrSuppRef
       into tplSuppRef;

      if csrSuppRef%found then
        result  := tplSuppRef.PAC_FINANCIAL_REFERENCE_ID;

        if tplSuppRef.FRE_DEFAULT != 1 then
          fetch csrSuppRef
           into tplSuppRef;

          if csrSuppRef%found then
            result  := null;
          end if;
        end if;
      end if;

      close csrSuppRef;
    end if;

    return result;
  end GetDefFinRef;

--------------
  procedure CreateCoversFromPartImp(
    aACT_PART_IMPUTATION_ID     ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID   ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aC_STATUS_SETTLEMENT        ACT_COVER_INFORMATION.C_STATUS_SETTLEMENT%type
  , aCOV_DRAWN_REF              ACT_COVER_INFORMATION.COV_DRAWN_REF%type
  , aCOV_DRAWER_REF             ACT_COVER_INFORMATION.COV_DRAWER_REF%type
  , aCOV_PLACE                  ACT_COVER_INFORMATION.COV_PLACE%type
  , aPAC_FINANCIAL_REFERENCE_ID ACT_COVER_INFORMATION.PAC_FINANCIAL_REFERENCE_ID%type default null
  , aACJ_NUMBER_METHOD_ID       ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type default null
  , aExcludeExisting            integer default 1
  , aUseLastExpiryDate          integer default 0
  )
  is
    cursor cursPart(PartImpId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type, aExcludeExisting integer)
    is
      select part.ACS_FINANCIAL_CURRENCY_ID
           , part.ACS_ACS_FINANCIAL_CURRENCY_ID
           , part.PAC_CUSTOM_PARTNER_ID
           , part.PAC_SUPPLIER_PARTNER_ID
           , part.PAC_FINANCIAL_REFERENCE_ID
        from act_document doc
           , act_part_imputation part
       where part.ACT_PART_IMPUTATION_ID = PartImpId
         and doc.ACT_DOCUMENT_ID = part.ACT_DOCUMENT_ID
         and (    (aExcludeExisting = 0)
              or (doc.ACT_COVER_INFORMATION_ID is null) );

    cursor cursPartExp(PartImpId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type, aExcludeExisting integer)
    is
      select   part.ACS_FINANCIAL_CURRENCY_ID
             , part.ACS_ACS_FINANCIAL_CURRENCY_ID
             , part.PAC_CUSTOM_PARTNER_ID
             , part.PAC_SUPPLIER_PARTNER_ID
             , part.PAC_FINANCIAL_REFERENCE_ID
             , exp.EXP_ADAPTED
             , exp.EXP_AMOUNT_LC
             , decode(part.ACS_FINANCIAL_CURRENCY_ID
                    , part.ACS_ACS_FINANCIAL_CURRENCY_ID, exp.EXP_AMOUNT_LC
                    , exp.EXP_AMOUNT_FC
                     ) EXP_AMOUNT_FC
             , exp.EXP_AMOUNT_EUR
             , exp.ACT_EXPIRY_ID
             , exp.EXP_SLICE
          from act_expiry exp
             , act_part_imputation part
         where part.ACT_PART_IMPUTATION_ID = PartImpId
           and exp.ACT_PART_IMPUTATION_ID = part.ACT_PART_IMPUTATION_ID
           and exp.EXP_CALC_NET + 0 = 1
           and (    (aExcludeExisting = 0)
                or (not exists(select 0
                                 from act_cover_s_expiry covexp
                                where covexp.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID) ) )
      order by exp.EXP_SLICE asc;

    TypeCat          ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    DocId            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
    DocNum           ACT_DOCUMENT.DOC_NUMBER%type;
    CovNum           ACT_COVER_INFORMATION.COV_NUMBER%type;
    DocDate          ACT_DOCUMENT.DOC_DOCUMENT_DATE%type;
    CovExpDate       ACT_EXPIRY.EXP_ADAPTED%type;
    TypeSup          ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
    CovInfId         ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type;
    FinRefId         ACT_COVER_INFORMATION.PAC_FINANCIAL_REFERENCE_ID%type   := 0;
    AmountLC         ACT_COVER_INFORMATION.COV_AMOUNT_LC%type;
    AmountFC         ACT_COVER_INFORMATION.COV_AMOUNT_FC%type;
    AmountEUR        ACT_COVER_INFORMATION.COV_AMOUNT_FC%type;
    StatusSettlement ACS_PAYMENT_METHOD.C_STATUS_SETTLEMENT%type;
  begin
    select cat.C_TYPE_CATALOGUE
         , substr(doc.DOC_NUMBER, 1, 24) DOC_NUMBER
         , doc.DOC_DOCUMENT_DATE
         , doc.ACT_DOCUMENT_ID
      into TypeCat
         , DocNum
         , DocDate
         , DocId
      from act_part_imputation part
         , act_document doc
         , acj_catalogue_document cat
     where part.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
       and doc.ACT_DOCUMENT_ID = part.ACT_DOCUMENT_ID
       and doc.ACJ_CATALOGUE_DOCUMENT_ID = cat.ACJ_CATALOGUE_DOCUMENT_ID;

    CovNum  := DocNum;

    select met.C_TYPE_SUPPORT
         , met.C_STATUS_SETTLEMENT
      into TypeSup
         , StatusSettlement
      from acs_payment_method met
         , acs_fin_acc_s_payment finpay
     where finpay.ACS_FIN_ACC_S_PAYMENT_ID = aACS_FIN_ACC_S_PAYMENT_ID
       and finpay.ACS_PAYMENT_METHOD_ID = met.ACS_PAYMENT_METHOD_ID;

    if TypeCat in('2', '8') then
      --Si facture ou relance -> curseur avec échéances
      for tplPartExp in cursPartExp(aACT_PART_IMPUTATION_ID, aExcludeExisting) loop
        --Recherche du num.
        if aACJ_NUMBER_METHOD_ID is not null then
          ACT_FUNCTIONS.GetDocNumberForCover(aACJ_NUMBER_METHOD_ID, CovNum);
        elsif     (tplPartExp.EXP_SLICE > 1)
              and (DocNum is not null) then
          CovNum  := substr(DocNum || '.' || tplPartExp.EXP_SLICE, 1, 24);
        end if;

        --Recherche ref. fin.
        if FinRefId = 0 then
          if (TypeSup != '40') then
            FinRefId  := nvl(aPAC_FINANCIAL_REFERENCE_ID, tplPartExp.PAC_FINANCIAL_REFERENCE_ID);

            if FinRefId is null then
              FinRefId  := GetDefFinRef(tplPartExp.pac_custom_partner_id, tplPartExp.pac_supplier_partner_id);
            end if;
          else
            FinRefId  := null;
          end if;
        end if;

        select init_id_seq.nextval
          into CovInfId
          from dual;

        -- Insertion dans la table "Couverture"
        insert into ACT_COVER_INFORMATION
                    (ACT_COVER_INFORMATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FIN_ACC_S_PAYMENT_ID
                   , C_STATUS_SETTLEMENT
                   , PAC_FINANCIAL_REFERENCE_ID
                   , COV_AMOUNT_LC
                   , COV_AMOUNT_FC
                   , COV_AMOUNT_EUR
                   , COV_NUMBER
                   , COV_DRAWN_REF
                   , COV_DRAWER_REF
                   , COV_PLACE
                   , COV_DATE
                   , COV_EXPIRY_DATE
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , COV_DIRECT
                   , C_COVER_STATUS
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (CovInfId
                   , tplPartExp.ACS_FINANCIAL_CURRENCY_ID
                   , tplPartExp.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , aACS_FIN_ACC_S_PAYMENT_ID
                   , nvl(nvl(aC_STATUS_SETTLEMENT, StatusSettlement), '0')
                   , FinRefId
                   , tplPartExp.EXP_AMOUNT_LC
                   , tplPartExp.EXP_AMOUNT_FC
                   , tplPartExp.EXP_AMOUNT_EUR
                   , CovNum
                   , aCOV_DRAWN_REF
                   , aCOV_DRAWER_REF
                   , aCOV_PLACE
                   , DocDate
                   , tplPartExp.exp_adapted
                   , tplPartExp.pac_custom_partner_id
                   , tplPartExp.pac_supplier_partner_id
                   , 1
                   , '1'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni2
                    );

        -- Insertion dans la table "Couvre échéance"
        insert into ACT_COVER_S_EXPIRY
                    (ACT_COVER_INFORMATION_ID
                   , ACT_EXPIRY_ID
                    )
             values (CovInfId
                   , tplPartExp.ACT_EXPIRY_ID
                    );
      end loop;
    elsif TypeCat in('3', '4') then
      --Si paiements -> curseur sans échéances
      for tplPart in cursPart(aACT_PART_IMPUTATION_ID, aExcludeExisting) loop
        if aUseLastExpiryDate = 1 then
          --Recherche de la date la plus éloignée des POs payées
          select max(exp.EXP_ADAPTED)
            into CovExpDate
            from ACT_EXPIRY exp
               , ACT_DET_PAYMENT PAY
           where PAY.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
             and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID;
        else
          --Date document
          CovExpDate  := DocDate;
        end if;

        --Recherche du num.
        if aACJ_NUMBER_METHOD_ID is not null then
          ACT_FUNCTIONS.GetDocNumberForCover(aACJ_NUMBER_METHOD_ID, CovNum);
        end if;

        --Recherche ref. fin.
        if FinRefId = 0 then
          if (TypeSup != '40') then
            FinRefId  := nvl(aPAC_FINANCIAL_REFERENCE_ID, tplPart.PAC_FINANCIAL_REFERENCE_ID);

            if FinRefId is null then
              FinRefId  := GetDefFinRef(tplPart.pac_custom_partner_id, tplPart.pac_supplier_partner_id);
            end if;
          else
            FinRefId  := null;
          end if;
        end if;

        --Recherche du montant
        select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
             , sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
             , sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) )
          into AmountLC
             , AmountFC
             , AmountEUR
          from ACT_DET_PAYMENT
         where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID;

        --Si couverture en MB, alors FC = LC
        if tplPart.ACS_FINANCIAL_CURRENCY_ID = tplPart.ACS_ACS_FINANCIAL_CURRENCY_ID then
          AmountFC  := AmountLC;
        end if;

        select init_id_seq.nextval
          into CovInfId
          from dual;

        -- Insertion dans la table "Couverture"
        insert into ACT_COVER_INFORMATION
                    (ACT_COVER_INFORMATION_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , ACS_FIN_ACC_S_PAYMENT_ID
                   , C_STATUS_SETTLEMENT
                   , PAC_FINANCIAL_REFERENCE_ID
                   , COV_AMOUNT_LC
                   , COV_AMOUNT_FC
                   , COV_AMOUNT_EUR
                   , COV_NUMBER
                   , COV_DRAWN_REF
                   , COV_DRAWER_REF
                   , COV_PLACE
                   , COV_DATE
                   , COV_EXPIRY_DATE
                   , PAC_CUSTOM_PARTNER_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , COV_DIRECT
                   , C_COVER_STATUS
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (CovInfId
                   , tplPart.ACS_FINANCIAL_CURRENCY_ID
                   , tplPart.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , aACS_FIN_ACC_S_PAYMENT_ID
                   , nvl(nvl(aC_STATUS_SETTLEMENT, StatusSettlement), '0')
                   , FinRefId
                   , AmountLC
                   , AmountFC
                   , AmountEUR
                   , CovNum
                   , aCOV_DRAWN_REF
                   , aCOV_DRAWER_REF
                   , aCOV_PLACE
                   , DocDate
                   , CovExpDate
                   , tplPart.pac_custom_partner_id
                   , tplPart.pac_supplier_partner_id
                   , 1
                   , '1'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni2
                    );

        --Màj du lien entre le doc. et la cover
        update ACT_DOCUMENT
           set ACT_COVER_INFORMATION_ID = CovInfId
         where ACT_DOCUMENT_ID = DocId;
      end loop;
    end if;
  end CreateCoversFromPartImp;

-------------------------
  procedure CreateCoversFromJob(
    aACT_JOB_ID               ACT_JOB.ACT_JOB_ID%type
  , aACS_FIN_ACC_S_PAYMENT_ID ACS_FIN_ACC_S_PAYMENT.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aC_STATUS_SETTLEMENT      ACT_COVER_INFORMATION.C_STATUS_SETTLEMENT%type
  , aCOV_DRAWN_REF            ACT_COVER_INFORMATION.COV_DRAWN_REF%type
  , aCOV_DRAWER_REF           ACT_COVER_INFORMATION.COV_DRAWER_REF%type
  , aCOV_PLACE                ACT_COVER_INFORMATION.COV_PLACE%type
  , aACJ_NUMBER_METHOD_ID     ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type default null
  , aExcludeExisting          integer default 1
  , aUseLastExpiryDate        integer default 0
  )
  is
    sqlStatement        varchar2(10000);
    tblPartImputationId TtblPartImputationId;
  begin
    -- recherche de la commande SQL
    sqlStatement  := PCS.PC_FUNCTIONS.GetSql('ACT_COVER_INFORMATION', 'ACT_COVER_MANAGEMENT', 'CreateCoversFromJob');

    -- si pas de commande SQL dans la BD, on prend celle par défaut
    if sqlStatement is null then
      sqlStatement  :=
        'select PART.ACT_PART_IMPUTATION_ID ' ||
        'from ACT_PART_IMPUTATION PART ' ||
        ',ACT_DOCUMENT DOC ' ||
        'where DOC.ACT_JOB_ID = :ACT_JOB_ID ' ||
        'and DOC.ACT_DOCUMENT_ID = PART.ACT_DOCUMENT_ID ' ||
        'order by DOC.DOC_NUMBER asc, PART.ACT_PART_IMPUTATION_ID asc';
    end if;

    -- remplacement du paramètre ACT_JOB_ID
    sqlStatement  := replace(sqlStatement, ':ACT_JOB_ID', aACT_JOB_ID);

    -- execution de la commande
    execute immediate sqlStatement
    bulk collect into tblPartImputationId;

    if tblPartImputationId.count > 0 then
      for i in tblPartImputationId.first .. tblPartImputationId.last loop
        CreateCoversFromPartImp(tblPartImputationId(i)
                              , aACS_FIN_ACC_S_PAYMENT_ID
                              , aC_STATUS_SETTLEMENT
                              , aCOV_DRAWN_REF
                              , aCOV_DRAWER_REF
                              , aCOV_PLACE
                              , null
                              , aACJ_NUMBER_METHOD_ID
                              , aExcludeExisting
                              , aUseLastExpiryDate
                               );
      end loop;
    end if;
  end CreateCoversFromJob;
end ACT_COVER_MANAGEMENT;
