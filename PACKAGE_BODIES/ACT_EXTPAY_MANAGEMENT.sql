--------------------------------------------------------
--  DDL for Package Body ACT_EXTPAY_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_EXTPAY_MANAGEMENT" 
is

  function GetAlternateFinRef(aPAC_SUPPLIER_PARTNER_ID   in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%Type,
                              aPAC_CUSTOM_PARTNER_ID     in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%Type,
                              aExcludedTypeReference     in varchar2) return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%Type
  is
    cursor csr_TYPE_REF(SuppPart number, CustPart number, aExcludedTypeReference varchar2) is
      select PAC_FINANCIAL_REFERENCE_ID
        from PAC_FINANCIAL_REFERENCE
       where ((SuppPart is not null and PAC_SUPPLIER_PARTNER_ID = SuppPart) or
              (CustPart is not null and PAC_CUSTOM_PARTNER_ID = CustPart))
         and C_PARTNER_STATUS <> '0'
         and instr(nvl(','||aExcludedTypeReference||',', 'NULL')
                  , ',' || PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE
                    || ','
                    ) = 0
      order by FRE_DEFAULT desc, decode(C_TYPE_REFERENCE, 5, 0, C_TYPE_REFERENCE), PAC_FINANCIAL_REFERENCE_ID;

    TypeRef PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
  begin
    open csr_TYPE_REF(aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aExcludedTypeReference);
    fetch csr_TYPE_REF into TypeRef;
    close csr_TYPE_REF;

    return TypeRef;

  end GetAlternateFinRef;

  function GetDefaultFinRef(aPAC_SUPPLIER_PARTNER_ID   in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%Type,
                              aPAC_CUSTOM_PARTNER_ID     in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%Type,
                              aExcludedTypeReference     in varchar2) return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%Type
  is
    cursor csr_TYPE_REF(SuppPart number, CustPart number, aExcludedTypeReference varchar2) is
      select PAC_FINANCIAL_REFERENCE_ID
        from PAC_FINANCIAL_REFERENCE
       where ((SuppPart is not null and PAC_SUPPLIER_PARTNER_ID = SuppPart) or
              (CustPart is not null and PAC_CUSTOM_PARTNER_ID = CustPart))
         and C_PARTNER_STATUS <> '0'
         and instr(nvl(','||aExcludedTypeReference||',', 'NULL')
                  , ',' || PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE
                    || ','
                    ) = 0
      order by FRE_DEFAULT desc, decode(C_TYPE_REFERENCE, 5, 0, C_TYPE_REFERENCE) asc, PAC_FINANCIAL_REFERENCE_ID asc;

    TypeRef PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
  begin
    open csr_TYPE_REF(aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID, aExcludedTypeReference);
    fetch csr_TYPE_REF into TypeRef;
    close csr_TYPE_REF;

    return TypeRef;

  end GetDefaultFinRef;

  procedure UpdateExtPaymentDefFinRef(aACT_EXTERNAL_GROUP_ID  in ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type,
                                      aExcludedTypeReference  in varchar2)
  is
  begin
    -- Màj des réf. fin. par défaut si pas définie pour la facture
    update (select ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID
                , ACT_EXTPAY_MANAGEMENT.GetDefaultFinRef(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID
                                                        , ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID
                                                        , aExcludedTypeReference) DEF_PAC_FINANCIAL_REFERENCE_ID
              from ACT_EXPIRY
                , ACT_PART_IMPUTATION
                , ACT_DET_PAYMENT
                , ACT_EXTERNAL_PAYMENT
            where ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID = aACT_EXTERNAL_GROUP_ID
              and ACT_EXTERNAL_PAYMENT.ACT_DET_PAYMENT_ID = ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
              and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
              and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
              and ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID is null
              and ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID is null) EXTPAYNULL
      set EXTPAYNULL.EXT_PAC_FINANCIAL_REFERENCE_ID = EXTPAYNULL.DEF_PAC_FINANCIAL_REFERENCE_ID;

  end UpdateExtPaymentDefFinRef;

  function LoadExtPaymentData(aACT_DOCUMENT_ID      in ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                              aACT_JOB_ID           in ACT_JOB.ACT_JOB_ID%type,
                              aSign                 in integer) return ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type
  is
    ExtGroupId ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into ExtGroupId
      from dual;

    insert into ACT_EXTERNAL_PAYMENT EXTPAY
              (ACT_JOB_ID
            , ACT_DOCUMENT_ID
            , ACT_DET_PAYMENT_ID
            , ACT_EXTERNAL_GROUP_ID
            , EXT_AMOUNT_LEFT_LC
            , EXT_AMOUNT_LEFT_FC
            , EXT_GROUP_NUMBER
            , EXT_DETAIL
              )
    (select ACT_DOCUMENT.ACT_JOB_ID
          , ACT_DOCUMENT.ACT_DOCUMENT_ID
          , ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
          , ExtGroupId
          , ACT_DET_PAYMENT.DET_PAIED_LC
          , ACT_DET_PAYMENT.DET_PAIED_FC
          , rownum
          , 1
      from ACT_EXPIRY
          , ACT_DET_PAYMENT
          , ACT_DOCUMENT
      where (   ACT_DOCUMENT.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
            or aACT_DOCUMENT_ID is null)
        and (   ACT_DOCUMENT.ACT_JOB_ID = aACT_JOB_ID
            or aACT_JOB_ID is null)
        and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_DET_PAYMENT.ACT_DOCUMENT_ID
        and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
        and (   sign(ACT_DET_PAYMENT.DET_PAIED_LC) = sign(aSign)
            or sign(ACT_DET_PAYMENT.DET_PAIED_FC) = sign(aSign) ));

    return ExtGroupId;

  end LoadExtPaymentData;

  procedure CreateSummaryExtPayment(aACT_EXTERNAL_GROUP_ID  in ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type,
                                    aSign                   in integer)
  is
  begin
    -- Création des enregistrements totaux avec le flag EXT_DETAIL à 0
    insert into ACT_EXTERNAL_PAYMENT
    (EXT_GROUP_NUMBER, ACT_EXTERNAL_GROUP_ID, ACT_JOB_ID, EXT_PAC_FINANCIAL_REFERENCE_ID, EXT_AMOUNT_LEFT_LC, EXT_AMOUNT_LEFT_FC, ACT_DET_PAYMENT_ID, EXT_DETAIL, ACT_DOCUMENT_ID)
    (
    select   EXT.EXT_GROUP_NUMBER
          , EXT.ACT_EXTERNAL_GROUP_ID
          , EXT.ACT_JOB_ID
          , nvl(EXT.EXT_PAC_FINANCIAL_REFERENCE_ID, PART.PAC_FINANCIAL_REFERENCE_ID) PAC_FINANCIAL_REFERENCE_ID
          , sum(EXT.EXT_AMOUNT_LEFT_LC) EXT_AMOUNT_LEFT_LC
          , sum(EXT.EXT_AMOUNT_LEFT_FC) EXT_AMOUNT_LEFT_FC
          , HOOKPAY.ACT_DET_PAYMENT_ID
          , 0
          , (select ACT_DOCUMENT_ID
                from ACT_DET_PAYMENT
              where ACT_DET_PAYMENT_ID = HOOKPAY.ACT_DET_PAYMENT_ID) ACT_DOCUMENT_ID
        from (select   min(ACT_DET_PAYMENT_ID) ACT_DET_PAYMENT_ID
                    , EXT_GROUP_NUMBER
                  from ACT_EXTERNAL_PAYMENT
                where ACT_EXTERNAL_GROUP_ID = aACT_EXTERNAL_GROUP_ID
                  and (   sign(EXT_AMOUNT_LEFT_LC) = sign(aSign)
                        or sign(EXT_AMOUNT_LEFT_FC) = sign(aSign) )
              group by EXT_GROUP_NUMBER) HOOKPAY
          , ACT_PART_IMPUTATION PART
          , ACT_EXPIRY exp
          , ACT_DET_PAYMENT DET
          , ACT_EXTERNAL_PAYMENT EXT
      where EXT.ACT_EXTERNAL_GROUP_ID = aACT_EXTERNAL_GROUP_ID
        and HOOKPAY.EXT_GROUP_NUMBER = EXT.EXT_GROUP_NUMBER
        and DET.ACT_DET_PAYMENT_ID = EXT.ACT_DET_PAYMENT_ID
        and DET.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
        and exp.ACT_PART_IMPUTATION_ID = PART.ACT_PART_IMPUTATION_ID
    group by EXT.ACT_EXTERNAL_GROUP_ID
          , EXT.ACT_JOB_ID
          , EXT.EXT_GROUP_NUMBER
          , PART.PAC_SUPPLIER_PARTNER_ID
          , PART.PAC_CUSTOM_PARTNER_ID
          , nvl(EXT.EXT_PAC_FINANCIAL_REFERENCE_ID, PART.PAC_FINANCIAL_REFERENCE_ID)
          , HOOKPAY.ACT_DET_PAYMENT_ID
      having sum(EXT.EXT_AMOUNT_LEFT_LC) != 0
    );

  end CreateSummaryExtPayment;

  function PrepareExtPayForFileGeneration(aACT_DOCUMENT_ID        in ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                                          aACT_JOB_ID             in ACT_JOB.ACT_JOB_ID%type,
                                          aSign                   in integer,
                                          aGetDefaultFinRef       in boolean,
                                          aPartnerGroup           in boolean,
                                          aExcludedTypeReference  in varchar2 default '3') return ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type
  is
    cursor csr_PartnerGroup(aExtGroupId number, aExcludedTypeReference varchar2) is
      select   nvl(PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID, PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID) PAC_FINANCIAL_REFERENCE_ID
            , PAC_PERSON.PAC_PERSON_ID
            , nvl(PAC_FINANCIAL_REFERENCE2.C_TYPE_REFERENCE, PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE) C_TYPE_REFERENCE
            , ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER
            , ACT_EXTERNAL_PAYMENT.EXT_DETAIL
            , ACT_EXTERNAL_PAYMENT.rowid EXTPAY_ROWID
          from ACT_EXPIRY
            , PAC_FINANCIAL_REFERENCE PAC_FINANCIAL_REFERENCE2
            , PAC_FINANCIAL_REFERENCE
            , ACT_PART_IMPUTATION
            , PAC_PERSON
            , ACT_DET_PAYMENT
            , ACT_EXTERNAL_PAYMENT
        where ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID = aExtGroupId
          and ACT_EXTERNAL_PAYMENT.ACT_DET_PAYMENT_ID = ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
          and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
          and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
          and PAC_PERSON.PAC_PERSON_ID =
                                  nvl(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID, ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID)
          and PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID
          and PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID
      order by PAC_PERSON.PAC_PERSON_ID
            , nvl(PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID, PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID);

    type TtblPartnerGroup is table of csr_PartnerGroup%rowtype;
    tblPartnerGroup TtblPartnerGroup;
    lasttpl_PartnerGroup csr_PartnerGroup%rowtype;

    cursor csr_Lettering(aExtGroupId number, aExcludedTypeReference varchar2) is
      select  min(nvl(PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID, PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID)) PAC_FINANCIAL_REFERENCE_ID
            , min(PAC_PERSON.PAC_PERSON_ID) PAC_PERSON_ID
            , min(ACT_EXTERNAL_PAYMENT.ACT_JOB_ID) ACT_JOB_ID
            , min(ACT_EXTERNAL_PAYMENT.ACT_DOCUMENT_ID) ACT_DOCUMENT_ID
            , sum(ACT_EXTERNAL_PAYMENT.EXT_AMOUNT_LEFT_LC) TOT_EXT_AMOUNT_LEFT_LC
            , sum(ACT_EXTERNAL_PAYMENT.EXT_AMOUNT_LEFT_FC) TOT_EXT_AMOUNT_LEFT_FC
            , ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER
            , min(ACT_EXTERNAL_PAYMENT.rowid) EXT_ROWID
          from ACT_EXPIRY
            , PAC_FINANCIAL_REFERENCE PAC_FINANCIAL_REFERENCE2
            , PAC_FINANCIAL_REFERENCE
            , ACT_PART_IMPUTATION
            , PAC_PERSON
            , ACT_DET_PAYMENT
            , ACT_EXTERNAL_PAYMENT
        where ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID = aExtGroupId
          and ACT_EXTERNAL_PAYMENT.ACT_DET_PAYMENT_ID = ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
          and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
          and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
          and PAC_PERSON.PAC_PERSON_ID =
                                  nvl(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID, ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID)
          and PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID
          and PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID
          and instr(nvl(','||aExcludedTypeReference||',', 'NULL')
                  , ',' || nvl(PAC_FINANCIAL_REFERENCE2.C_TYPE_REFERENCE, PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE)
                    || ','
                    ) = 0
      group by ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER
      order by min(PAC_PERSON.PAC_PERSON_ID)
            , min(nvl(PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID, PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID))
            , ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER;

    cursor csr_LetteringExcluded(aExtGroupId number, aExcludedTypeReference varchar2) is
      select  min(nvl(ACT_EXTPAY_MANAGEMENT.GetAlternateFinRef(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID
                                                              , ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID
                                                              , aExcludedTypeReference), nvl(ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID, ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID))) PAC_FINANCIAL_REFERENCE_ID
            , min(PAC_PERSON.PAC_PERSON_ID) PAC_PERSON_ID
            , min(ACT_EXTERNAL_PAYMENT.ACT_JOB_ID) ACT_JOB_ID
            , min(ACT_EXTERNAL_PAYMENT.ACT_DOCUMENT_ID) ACT_DOCUMENT_ID
            , sum(ACT_EXTERNAL_PAYMENT.EXT_AMOUNT_LEFT_LC) TOT_EXT_AMOUNT_LEFT_LC
            , sum(ACT_EXTERNAL_PAYMENT.EXT_AMOUNT_LEFT_FC) TOT_EXT_AMOUNT_LEFT_FC
            , ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER
            , min(ACT_EXTERNAL_PAYMENT.ROWID) EXT_ROWID
          from ACT_EXPIRY
            , PAC_FINANCIAL_REFERENCE PAC_FINANCIAL_REFERENCE2
            , PAC_FINANCIAL_REFERENCE
            , ACT_PART_IMPUTATION
            , PAC_PERSON
            , ACT_DET_PAYMENT
            , ACT_EXTERNAL_PAYMENT
        where ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID = aExtGroupId
          and ACT_EXTERNAL_PAYMENT.ACT_DET_PAYMENT_ID = ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
          and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
          and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
          and PAC_PERSON.PAC_PERSON_ID =
                                  nvl(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID, ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID)
          and PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID
          and PAC_FINANCIAL_REFERENCE2.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_EXTERNAL_PAYMENT.EXT_PAC_FINANCIAL_REFERENCE_ID
          and instr(nvl(','||aExcludedTypeReference||',', 'NULL')
                  , ',' || nvl(PAC_FINANCIAL_REFERENCE2.C_TYPE_REFERENCE, PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE)
                    || ','
                    ) > 0
      group by ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER
      order by min(PAC_PERSON.PAC_PERSON_ID)
            , ACT_EXTERNAL_PAYMENT.EXT_GROUP_NUMBER;

    cursor csr_DetPayLettering(DocumentId number, JobId number, aSign integer) is
      select  ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID
            , PAC_PERSON.PAC_PERSON_ID
            , PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID
            , PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE
            , ACT_DET_PAYMENT.DET_PAIED_LC
            , ACT_DET_PAYMENT.DET_PAIED_FC
        from ACT_EXPIRY
            , PAC_FINANCIAL_REFERENCE
            , ACT_PART_IMPUTATION
            , PAC_PERSON
            , ACT_DET_PAYMENT
            , ACT_DOCUMENT
        where (   ACT_DOCUMENT.ACT_DOCUMENT_ID = DocumentId
              or DocumentId is null)
          and (   ACT_DOCUMENT.ACT_JOB_ID = JobId
              or JobId is null)
          and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_DET_PAYMENT.ACT_DOCUMENT_ID
          and ACT_DET_PAYMENT.ACT_EXPIRY_ID = ACT_EXPIRY.ACT_EXPIRY_ID
          and ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID = ACT_EXPIRY.ACT_PART_IMPUTATION_ID
          and PAC_PERSON.PAC_PERSON_ID =
                                  nvl(ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID, ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID)
          and PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID(+) = ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID
          and (   sign(ACT_DET_PAYMENT.DET_PAIED_LC) = decode(sign(aSign), 1, -1, -1, 1, 0)
              or sign(ACT_DET_PAYMENT.DET_PAIED_FC) = decode(sign(aSign), 1, -1, -1, 1, 0) )
       order by PAC_PERSON.PAC_PERSON_ID
              , ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID;

    type TtblDetPayLettering is table of csr_DetPayLettering%rowtype;
    tblDetPayLettering TtblDetPayLettering;

    GroupNum integer;
    ExtGroupId ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type;
    i integer;

    ----
    function Lettering(atblDetPayLettering in out csr_DetPayLettering%rowtype,
                        atpl_Lettering in out csr_Lettering%rowtype) return boolean
    is
    begin
      if sign(atblDetPayLettering.DET_PAIED_LC + atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC) = sign(atblDetPayLettering.DET_PAIED_LC) then
        if atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC != 0 then -- Création de la ligne uniquement si il reste qqchose à paier
          -- Si paiement à déduire plus grand que montant des paiements -> création d'une ligne avec montant partiel
          insert into ACT_EXTERNAL_PAYMENT
            (ACT_JOB_ID, ACT_DOCUMENT_ID, ACT_DET_PAYMENT_ID, EXT_AMOUNT_LEFT_LC, EXT_AMOUNT_LEFT_FC, EXT_GROUP_NUMBER, EXT_PAC_FINANCIAL_REFERENCE_ID, ACT_EXTERNAL_GROUP_ID, EXT_DETAIL)
          values
            (atpl_Lettering.ACT_JOB_ID, atpl_Lettering.ACT_DOCUMENT_ID, atblDetPayLettering.ACT_DET_PAYMENT_ID, -atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC, -atpl_Lettering.TOT_EXT_AMOUNT_LEFT_FC,
              atpl_Lettering.EXT_GROUP_NUMBER, atpl_Lettering.PAC_FINANCIAL_REFERENCE_ID, ExtGroupId, 1);
          -- Suppression du montant lettré
          atblDetPayLettering.DET_PAIED_LC := atblDetPayLettering.DET_PAIED_LC + atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC;
          atblDetPayLettering.DET_PAIED_FC := atblDetPayLettering.DET_PAIED_FC + atpl_Lettering.TOT_EXT_AMOUNT_LEFT_FC;
        end if;
        return True;
      else
        -- Si paiement à déduire plus grand que montant des paiements -> création d'une ligne avec montant partiel
        insert into ACT_EXTERNAL_PAYMENT
          (ACT_JOB_ID, ACT_DOCUMENT_ID, ACT_DET_PAYMENT_ID, EXT_AMOUNT_LEFT_LC, EXT_AMOUNT_LEFT_FC, EXT_GROUP_NUMBER, EXT_PAC_FINANCIAL_REFERENCE_ID, ACT_EXTERNAL_GROUP_ID, EXT_DETAIL)
        values
          (atpl_Lettering.ACT_JOB_ID, atpl_Lettering.ACT_DOCUMENT_ID, atblDetPayLettering.ACT_DET_PAYMENT_ID, atblDetPayLettering.DET_PAIED_LC, atblDetPayLettering.DET_PAIED_FC,
            atpl_Lettering.EXT_GROUP_NUMBER, atpl_Lettering.PAC_FINANCIAL_REFERENCE_ID, ExtGroupId, 1);
        -- Màj du montant restant du groupe
        atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC := atpl_Lettering.TOT_EXT_AMOUNT_LEFT_LC + atblDetPayLettering.DET_PAIED_LC;
        atpl_Lettering.TOT_EXT_AMOUNT_LEFT_FC := atpl_Lettering.TOT_EXT_AMOUNT_LEFT_FC + atblDetPayLettering.DET_PAIED_FC;
        -- Suppression du paiement à déduire
        --atblDetPayLettering.delete;
        return False;
      end if;
     end Lettering;
     ----
  begin
    -- Chargement de la table de traitement
    ExtGroupId := LoadExtPaymentData(aACT_DOCUMENT_ID, aACT_JOB_ID, aSign);

    -- Si aSign = -1 -> Fichier paiement 'inversé' (sur les NC à la place des factures) et on va màj la ref. fin. par défaut dans les det. payment.
    if aGetDefaultFinRef then
      UpdateExtPaymentDefFinRef(ExtGroupId, aExcludedTypeReference);
    end if;

    -- Regroupement par partenaire / réf. financière
    if aPartnerGroup then
      -- Chargement de la table des regroupement
      open csr_PartnerGroup(ExtGroupId, aExcludedTypeReference);
      fetch csr_PartnerGroup bulk collect into tblPartnerGroup;
      close csr_PartnerGroup;

      -- Renumérotation des groupes, les groupes sont déjà numéroté (un num. par paiement)
      i := tblPartnerGroup.first;
      if i is not null then
        GroupNum := 1;
        lasttpl_PartnerGroup := tblPartnerGroup(i);
        tblPartnerGroup(i).EXT_GROUP_NUMBER := GroupNum;
        i := tblPartnerGroup.next(i);
        while (i is not null) loop
          if instr(nvl(','||aExcludedTypeReference||',', 'NULL')
                    , ',' || tblPartnerGroup(i).C_TYPE_REFERENCE || ',') = 0 then
            if lasttpl_PartnerGroup.PAC_PERSON_ID != tblPartnerGroup(i).PAC_PERSON_ID or
              nvl(lasttpl_PartnerGroup.PAC_FINANCIAL_REFERENCE_ID, 0) != nvl(tblPartnerGroup(i).PAC_FINANCIAL_REFERENCE_ID, 0) then
              lasttpl_PartnerGroup := tblPartnerGroup(i);
              GroupNum := GroupNum + 1;
            end if;
          else
            lasttpl_PartnerGroup := tblPartnerGroup(i);
            GroupNum := GroupNum + 1;
          end if;
          tblPartnerGroup(i).EXT_GROUP_NUMBER := GroupNum;
          i := tblPartnerGroup.next(i);
        end loop;
        -- Màj des enregistrements
        for i in tblPartnerGroup.first .. tblPartnerGroup.last loop
          update ACT_EXTERNAL_PAYMENT EXTPAY
             set EXTPAY.EXT_GROUP_NUMBER = tblPartnerGroup(i).EXT_GROUP_NUMBER
           where EXTPAY.rowid = tblPartnerGroup(i).EXTPAY_ROWID;
        end loop;
      end if;
    end if;

    -- Chargement de la table des paiements à déduire
    open csr_DetPayLettering(aACT_DOCUMENT_ID, aACT_JOB_ID, aSign);
    fetch csr_DetPayLettering bulk collect into tblDetPayLettering;
    close csr_DetPayLettering;

    -- Lettrage paiements avec paiement à déduire selon partenaire / réf. financière
    for tpl_Lettering in csr_Lettering(ExtGroupId, aExcludedTypeReference) loop
      i := tblDetPayLettering.first;
      while (i is not null) loop
        -- Si même partenaire et même réf. fin.
        if tblDetPayLettering(i).PAC_PERSON_ID = tpl_Lettering.PAC_PERSON_ID and
            tblDetPayLettering(i).PAC_FINANCIAL_REFERENCE_ID = tpl_Lettering.PAC_FINANCIAL_REFERENCE_ID then
          if Lettering(tblDetPayLettering(i), tpl_Lettering) then
            exit;
          else
            tblDetPayLettering.delete(i);
          end if;
        end if;
        i := tblDetPayLettering.next(i);
      end loop;
    end loop;

    -- Lettrage paiements avec paiement à déduire selon partenaire
    for tpl_Lettering in csr_Lettering(ExtGroupId, aExcludedTypeReference) loop
      i := tblDetPayLettering.first;
      while (i is not null) loop
        -- Si même partenaire et même réf. fin.
        if tblDetPayLettering(i).PAC_PERSON_ID = tpl_Lettering.PAC_PERSON_ID then
          if Lettering(tblDetPayLettering(i), tpl_Lettering) then
            exit;
          else
            tblDetPayLettering.delete(i);
          end if;
        end if;
        i := tblDetPayLettering.next(i);
      end loop;
    end loop;

    if tblDetPayLettering.count > 0 then

      for tpl_Lettering in csr_LetteringExcluded(ExtGroupId, aExcludedTypeReference) loop
        i := tblDetPayLettering.first;
        while (i is not null) loop
          -- Si même partenaire et même réf. fin.
          if tblDetPayLettering(i).PAC_PERSON_ID = tpl_Lettering.PAC_PERSON_ID then

            -- Màj du paiement avec la nouvelle réf. financière
            update ACT_EXTERNAL_PAYMENT
               set EXT_PAC_FINANCIAL_REFERENCE_ID = tpl_Lettering.PAC_FINANCIAL_REFERENCE_ID
             where rowid = tpl_Lettering.EXT_ROWID;

            if Lettering(tblDetPayLettering(i), tpl_Lettering) then
              exit;
            else
              tblDetPayLettering.delete(i);
            end if;
          end if;
          i := tblDetPayLettering.next(i);
        end loop;
      end loop;

    end if;

    -- Création des enregistrement totaux (EXT_DETAIL = 0)
    CreateSummaryExtPayment(ExtGroupId, aSign);

    return ExtGroupId;

  end PrepareExtPayForFileGeneration;

  procedure PrepareExtPayForFileGeneration(aACT_EXTERNAL_GROUP_ID in out ACT_EXTERNAL_PAYMENT.ACT_EXTERNAL_GROUP_ID%type,
                                          aACT_DOCUMENT_ID        in ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                                          aACT_JOB_ID             in ACT_JOB.ACT_JOB_ID%type,
                                          aSign                   in integer,
                                          aGetDefaultFinRef       in integer,
                                          aPartnerGroup           in integer,
                                          aExcludedTypeReference  in varchar2 default '3')
  is
  begin
    aACT_EXTERNAL_GROUP_ID := PrepareExtPayForFileGeneration(aACT_DOCUMENT_ID, aACT_JOB_ID, aSign, aGetDefaultFinRef != 0, aPartnerGroup != 0, aExcludedTypeReference);
  end PrepareExtPayForFileGeneration;

  procedure DeleteExtPayRecords(aACT_DOCUMENT_ID        in ACT_DOCUMENT.ACT_DOCUMENT_ID%type,
                                aACT_JOB_ID             in ACT_JOB.ACT_JOB_ID%type)
  is
  begin
    if aACT_DOCUMENT_ID is not null then
      -- Effacement des enregistrements relatif à un document de paiements
      delete from ACT_EXTERNAL_PAYMENT
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
    elsif aACT_JOB_ID is not null then
      -- Effacement des enregistrements relatif à un travail de paiements
      delete from ACT_EXTERNAL_PAYMENT
       where ACT_JOB_ID = aACT_JOB_ID;
    end if;
  end DeleteExtPayRecords;

end ACT_EXTPAY_MANAGEMENT;
