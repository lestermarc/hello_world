--------------------------------------------------------
--  DDL for Package Body ACT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_FUNCTIONS" 
is
-------------------------
  procedure SetIntervalDates(aFrom varchar2, aTo varchar2)
  is
  begin
    DATE_FROM  := to_date(aFrom, 'yyyymmdd');
    DATE_TO    := to_date(aTo, 'yyyymmdd');
  end SetIntervalDates;

------------------------
  function GetDateFrom
    return date
  is
  begin
    return DATE_FROM;
  end GetDateFrom;

------------------------
  function GetDateTo
    return date
  is
  begin
    return DATE_TO;
  end GetDateTo;

-------------------------
  function GetVatDetAccountId
    return ACT_VAT_DET_ACCOUNT.ACT_VAT_DET_ACCOUNT_ID%type
  is
  begin
    return to_number(VAT_DET_ACC_ID);
  end;

-------------------------
  procedure SetAnalyse_Date(aDate varchar2)
  is
  begin
    ANALYSE_DATE  := to_date(aDate, 'yyyymmdd');
  end SetAnalyse_Date;

------------------------
  function GetAnalyse_Date
    return date
  is
  begin
    return ANALYSE_DATE;
  end GetAnalyse_Date;

------------------------------
  procedure SetAnalyse_Auxiliary(aACC_NUMBER varchar2, aFirst number)
  is
  begin
    if aFirst = 1 then
      ANALYSE_AUXILIARY1  := aACC_NUMBER;
    else
      ANALYSE_AUXILIARY2  := aACC_NUMBER;
    end if;
  end SetAnalyse_Auxiliary;

-----------------------------
  function GetAnalyse_Auxiliary(aFirst number)
    return varchar2
  is
  begin
    if aFirst = 1 then
      return ANALYSE_AUXILIARY1;
    else
      return ANALYSE_AUXILIARY2;
    end if;
  end GetAnalyse_Auxiliary;

----------------
  procedure SetBRO(aBRO number)
  is
  begin
    BRO  := aBRO;
  end SetBRO;

---------------
  function GetBRO
    return number
  is
  begin
    return BRO;
  end GetBRO;

-------------------------------
  procedure SetAnalyse_Parameters(aDate varchar2, aACC_NUMBER_From varchar2, aACC_NUMBER_To varchar2, aBRO varchar2)
  is
  begin
    ANALYSE_DATE        := to_date(aDate, 'yyyymmdd');
    ANALYSE_AUXILIARY1  := aACC_NUMBER_From;
    ANALYSE_AUXILIARY2  := aACC_NUMBER_To;

    if aBRO = '1' then
      BRO  := 1;
    else
      BRO  := 0;
    end if;
  end SetAnalyse_Parameters;

--------------------
  function GetBROState(aACT_JOURNAL_ID ACT_JOURNAL.ACT_JOURNAL_ID%type, aC_SUB_SET ACS_SUB_SET.C_SUB_SET%type)
    return number
  is
    State ACT_ETAT_JOURNAL.C_ETAT_JOURNAL%type;
  begin
    select C_ETAT_JOURNAL
      into State
      from ACT_ETAT_JOURNAL
     where ACT_JOURNAL_ID = aACT_JOURNAL_ID
       and C_SUB_SET = aC_SUB_SET;

    if State = 'BRO' then
      return 1;
    else
      return 0;
    end if;
  end GetBROState;

-----------------------
  procedure SetPartner_Id(aPAC_PERSON_ID PAC_PERSON.PAC_PERSON_ID%type)
  is
  begin
    PERSON_ID  := aPAC_PERSON_ID;
  end SetPartner_Id;

----------------------
  function GetPartner_Id
    return PAC_PERSON.PAC_PERSON_ID%type
  is
  begin
    return PERSON_ID;
  end GetPartner_Id;

------------------------
  procedure SetDocument_Id(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
  is
  begin
    DOCUMENT_ID  := aACT_DOCUMENT_ID;
  end SetDocument_Id;

-----------------------
  function GetDocument_Id
    return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  is
  begin
    return DOCUMENT_ID;
  end GetDocument_Id;

-----------------------
  function GetEtatEvent_Id
    return ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID%type
  is
  begin
    return ETATEVENT_ID;
  end GetEtatEvent_Id;

--------------------
  function GetEndFinYearDate
    return ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  is
  begin
    return END_FINYEAR_DATE;
  end GetEndFinYearDate;

--------------------
  procedure SetPayDate(aDATE date)
  is
  begin
    PAY_DATE  := aDATE;
  end SetPayDate;

-------------------
  function GetPayDate
    return date
  is
  begin
    return PAY_DATE;
  end GetPayDate;

-------------------------------
  procedure SetPayment_Parameters(
    aPAYMENT_AUXILIARY_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , aACT_DOCUMENT_ID      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDATE                 date
  , aACT_ETAT_EVENT_ID    ACT_EXPIRY_SELECTION.ACT_ETAT_EVENT_ID%type default 0
  , aBRO                  varchar2 default '0'
  , aFYE_END_DATE         ACS_FINANCIAL_YEAR.FYE_END_DATE%type default sysdate
  )
  is
  begin
    PAYMENT_AUXILIARY_ID  := aPAYMENT_AUXILIARY_ID;
    DOCUMENT_ID           := aACT_DOCUMENT_ID;
    PAY_DATE              := aDATE;
    ETATEVENT_ID          := aACT_ETAT_EVENT_ID;

    if aBRO = '1' then
      BRO  := 1;
    else
      BRO  := 0;
    end if;

    END_FINYEAR_DATE      := aFYE_END_DATE;
  end SetPayment_Parameters;

-----------------------
  function GetAuxiliary_Id
    return ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  is
  begin
    return PAYMENT_AUXILIARY_ID;
  end GetAuxiliary_Id;

-----------------------
  procedure TotalPaymentAt(aACT_EXPIRY_ID number, aDate date, aAmountLC out number, aAmountFC out number)
  is
  begin
    select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
         , sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
      into aAmountLC
         , aAmountFC
      from ACT_ETAT_JOURNAL JOU
         , ACT_DOCUMENT DOC
         , ACT_FINANCIAL_IMPUTATION IMP
         , ACT_DET_PAYMENT PAY
     where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
       and IMP.C_GENRE_TRANSACTION = '1'
       and IMP.IMF_TRANSACTION_DATE <= aDate
       and IMP.ACT_PART_IMPUTATION_ID is not null
       and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                 and JOU.C_SUB_SET = 'REC')
            or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                and JOU.C_SUB_SET = 'PAY')
           )
       and (   JOU.C_ETAT_JOURNAL <> 'BRO'
            or (    ACT_FUNCTIONS.GetBRO = 1
                and JOU.C_ETAT_JOURNAL = 'BRO') );

    if aAmountLC is null then
      aAmountLC  := 0;
    end if;

    if aAmountFC is null then
      aAmountFC  := 0;
    end if;

  end TotalPaymentAt;

-----------------------
  function TotalPaymentAt(aACT_EXPIRY_ID number, aDate date, aLC number)
    return number
  is
    TOTAL_PAYMENT ACT_DET_PAYMENT.DET_PAIED_LC%type;
  begin
    if aLC = 1 then   -- LC
      select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
        into TOTAL_PAYMENT
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and IMP.IMF_TRANSACTION_DATE <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    elsif aLC = 0 then   -- FC
      select sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
        into TOTAL_PAYMENT
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and IMP.IMF_TRANSACTION_DATE <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    elsif aLC = 2 then   -- EURO
      select sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) )
        into TOTAL_PAYMENT
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and IMP.IMF_TRANSACTION_DATE <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    end if;

    if TOTAL_PAYMENT is null then
      TOTAL_PAYMENT  := 0;
    end if;

    return TOTAL_PAYMENT;
  end TotalPaymentAt;

---------------------------
  function GetCoverExpiryDate(
    aACT_DET_PAYMENT_ID   ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  )
    return date
  is
    ExpiryDate ACT_COVER_INFORMATION.COV_EXPIRY_DATE%type;
  begin
    begin
      select COV.COV_EXPIRY_DATE
        into ExpiryDate
        from ACT_COVER_INFORMATION COV
           , ACT_PART_IMPUTATION PAR
           , ACT_DET_PAYMENT PAY
       where ACT_DET_PAYMENT_ID = aACT_DET_PAYMENT_ID
         and PAR.ACT_PART_IMPUTATION_ID = PAY.ACT_PART_IMPUTATION_ID
         and PAR.ACT_COVER_INFORMATION_ID = COV.ACT_COVER_INFORMATION_ID;
    exception
      when no_data_found then
        ExpiryDate  := aIMF_TRANSACTION_DATE;
    end;

    return ExpiryDate;
  end GetCoverExpiryDate;

----------------------------
  function TotalCoverPaymentAt(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type, aDate date, aLC number)
    return ACT_DET_PAYMENT.DET_PAIED_LC%type
  is
    TotalPayment ACT_DET_PAYMENT.DET_PAIED_LC%type;
  begin
    if aLC = 1 then   -- LC
      select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
        into TotalPayment
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and ACT_FUNCTIONS.GetCoverExpiryDate(PAY.ACT_DET_PAYMENT_ID, IMP.IMF_TRANSACTION_DATE) <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    elsif aLC = 0 then   -- FC
      select sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
        into TotalPayment
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and ACT_FUNCTIONS.GetCoverExpiryDate(PAY.ACT_DET_PAYMENT_ID, IMP.IMF_TRANSACTION_DATE) <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    elsif aLC = 2 then   -- EURO
      select sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) )
        into TotalPayment
        from ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_PAYMENT PAY
       where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and ACT_FUNCTIONS.GetCoverExpiryDate(PAY.ACT_DET_PAYMENT_ID, IMP.IMF_TRANSACTION_DATE) <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL <> 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );
    end if;

    if TotalPayment is null then
      TotalPayment  := 0;
    end if;

    return TotalPayment;
  end TotalCoverPaymentAt;

---------------------
  function TotalPayment(aACT_EXPIRY_ID number, aLC number)
    return number
  is
    TOTAL_PAYMENT ACT_DET_PAYMENT.DET_PAIED_LC%type;
  begin
    select case
             when aLC = 1 then sum(nvl(DET_PAIED_LC, 0) +
                                   nvl(DET_DISCOUNT_LC, 0) +
                                   nvl(DET_DEDUCTION_LC, 0) +
                                   nvl(DET_DIFF_EXCHANGE, 0)
                                  )   -- LC
             when aLC = 0 then sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )   -- FC
             when aLC = 2 then sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) )   -- EURO
             else 0
           end TOTAL
      into TOTAL_PAYMENT
      from ACT_ETAT_JOURNAL JOU
         , ACT_DOCUMENT DOC
         , ACT_DET_PAYMENT PAY
         , ACT_EXPIRY exp
     where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID
       and PAY.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and (    (    exp.EXP_PAC_CUSTOM_PARTNER_ID is not null
                 and JOU.C_SUB_SET = 'REC')
            or (    exp.EXP_PAC_SUPPLIER_PARTNER_ID is not null
                and JOU.C_SUB_SET = 'PAY')
           )
       and (   JOU.C_ETAT_JOURNAL <> 'BRO'
            or (    ACT_FUNCTIONS.GetBRO = 1
                and JOU.C_ETAT_JOURNAL = 'BRO') );

    if TOTAL_PAYMENT is null then
      TOTAL_PAYMENT  := 0;
    end if;

    return TOTAL_PAYMENT;
  end TotalPayment;

------------------------
  function LastPaymentDate(aACT_EXPIRY_ID ACT_EXPIRY.ACT_EXPIRY_ID%type)
    return date
  is
    PaymentDate date;
  begin
    select max(IMP.IMF_TRANSACTION_DATE)
      into PaymentDate
      from ACT_FINANCIAL_IMPUTATION IMP
         , ACT_DET_PAYMENT PAY
     where PAY.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and PAY.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID;

    return PaymentDate;
  end LastPaymentDate;

------------------------------------
  function TotalPaymentWithoutDocument(aACT_EXPIRY_ID number, aLC number, aACT_DOCUMENT_ID number)
    return number
  is
    TOTAL_PAYMENT ACT_DET_PAYMENT.DET_PAIED_LC%type;
  begin
    if aLC = 1 then   -- LC
      select sum(nvl(DET_PAIED_LC, 0) + nvl(DET_DISCOUNT_LC, 0) + nvl(DET_DEDUCTION_LC, 0) + nvl(DET_DIFF_EXCHANGE, 0) )
        into TOTAL_PAYMENT
        from ACT_DET_PAYMENT
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID;
    elsif aLC = 0 then   -- FC
      select sum(nvl(DET_PAIED_FC, 0) + nvl(DET_DISCOUNT_FC, 0) + nvl(DET_DEDUCTION_FC, 0) )
        into TOTAL_PAYMENT
        from ACT_DET_PAYMENT
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID;
    elsif aLC = 2 then   -- EURO
      select sum(nvl(DET_PAIED_EUR, 0) + nvl(DET_DISCOUNT_EUR, 0) + nvl(DET_DEDUCTION_EUR, 0) )
        into TOTAL_PAYMENT
        from ACT_DET_PAYMENT
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID;
    end if;

    if TOTAL_PAYMENT is null then
      TOTAL_PAYMENT  := 0;
    end if;

    return TOTAL_PAYMENT;
  end TotalPaymentWithoutDocument;

--------------------------
  function DiscountToleranceDateAfter(aACT_DOCUMENT_ID number, aEXP_SLICE number, aEXP_ADAPTED date)
    return date
  is
    dTolDate date;
  begin
    dTolDate := aEXP_ADAPTED - ACT_FUNCTIONS.GetPayCondTolerance(aACT_DOCUMENT_ID);
    return ACT_FUNCTIONS.DiscountDateAfter(aACT_DOCUMENT_ID, aEXP_SLICE, dTolDate);
  end DiscountToleranceDateAfter;

--------------------------
  function DiscountDateAfter(aACT_DOCUMENT_ID number, aEXP_SLICE number, aEXP_ADAPTED date)
    return date
  is
    ADAPTED date;
  begin
    select min(EXP_ADAPTED)
      into ADAPTED
      from ACT_EXPIRY
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and EXP_SLICE = aEXP_SLICE
       and EXP_CALC_NET = 0
       and EXP_ADAPTED >= aEXP_ADAPTED;

    return ADAPTED;
  end DiscountDateAfter;

----------------------------
  function DiscountToleranceAmountAfter(aACT_DOCUMENT_ID number, aEXP_SLICE number, aEXP_ADAPTED date, aLC number)
    return number
  is
    dTolDate date;
  begin
    dTolDate := aEXP_ADAPTED - ACT_FUNCTIONS.GetPayCondTolerance(aACT_DOCUMENT_ID);
    return DiscountAmountAfter(aACT_DOCUMENT_ID, aEXP_SLICE, dTolDate, aLC);
  end DiscountToleranceAmountAfter;

----------------------------
  function DiscountAmountAfter(aACT_DOCUMENT_ID number, aEXP_SLICE number, aEXP_ADAPTED date, aLC number)
    return number
  is
    DISCOUNT_AMOUNT ACT_EXPIRY.EXP_DISCOUNT_LC%type;
  begin
    if aLC = 1 then   -- LC
      select max(EXP_DISCOUNT_LC)
        into DISCOUNT_AMOUNT
        from ACT_EXPIRY
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and EXP_SLICE = aEXP_SLICE
         and EXP_CALC_NET = 0
         and EXP_ADAPTED = ACT_FUNCTIONS.DiscountDateAfter(aACT_DOCUMENT_ID, aEXP_SLICE, aEXP_ADAPTED);
    elsif aLC = 0 then   -- FC
      select max(EXP_DISCOUNT_FC)
        into DISCOUNT_AMOUNT
        from ACT_EXPIRY
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and EXP_SLICE = aEXP_SLICE
         and EXP_CALC_NET = 0
         and EXP_ADAPTED = ACT_FUNCTIONS.DiscountDateAfter(aACT_DOCUMENT_ID, aEXP_SLICE, aEXP_ADAPTED);
    elsif aLC = 2 then   -- EURO
      select max(EXP_DISCOUNT_EUR)
        into DISCOUNT_AMOUNT
        from ACT_EXPIRY
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and EXP_SLICE = aEXP_SLICE
         and EXP_CALC_NET = 0
         and EXP_ADAPTED = ACT_FUNCTIONS.DiscountDateAfter(aACT_DOCUMENT_ID, aEXP_SLICE, aEXP_ADAPTED);
    end if;

    if DISCOUNT_AMOUNT is null then
      DISCOUNT_AMOUNT  := 0;
    end if;

    return DISCOUNT_AMOUNT;
  end DiscountAmountAfter;

-------------------------
  function LastClaimsNumber(aACT_EXPIRY_ID number)
    return number
  is
    LASTNUMBER ACT_REMINDER.REM_NUMBER%type;
  begin
    select max(REM_NUMBER)
      into LASTNUMBER
      from ACT_REMINDER
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID;

    if lASTNUMBER is null then
      LASTNUMBER  := 0;
    end if;

    return LASTNUMBER;
  end LastClaimsNumber;

-----------------------
  function LastClaimsDate(aACT_EXPIRY_ID number)
    return date
  is
    LASTCLAIMS date;
  begin
    select max(DOC_DOCUMENT_DATE)
      into LASTCLAIMS
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
         , ACT_REMINDER rem
     where rem.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
       and CAT.C_REMINDER_METHOD <> '01';

    return LASTCLAIMS;
  end LastClaimsDate;

---------------------------
  function LastClaimsDocument(aACT_EXPIRY_ID number)
    return number
  is
    LASTDOCUMENT ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
  begin
    select max(rem.ACT_DOCUMENT_ID)
      into LASTDOCUMENT
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
         , ACT_REMINDER rem
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
       and CAT.C_REMINDER_METHOD <> '01';

    return LASTDOCUMENT;
  end LastClaimsDocument;

---------------------------------
  function LastClaimsDateWithoutDoc(
    aACT_EXPIRY_ID   ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  )
    return date
  is
    LastClaimsDate date;
  begin
    select max(DOC_DOCUMENT_DATE)
      into LastClaimsDate
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_REMINDER rem
         , ACT_DOCUMENT DOC
     where rem.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and rem.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and rem.ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
       and CAT.C_REMINDER_METHOD <> '01';

    return LastClaimsDate;
  end LastClaimsDateWithoutDoc;

-------------------------------
  function LastClaimsNoWithoutDoc(
    aACT_EXPIRY_ID   ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  )
    return ACT_REMINDER.REM_NUMBER%type
  is
    LastClaimsNumber ACT_REMINDER.REM_NUMBER%type;
  begin
    select max(REM_NUMBER)
      into LastClaimsNumber
      from ACT_REMINDER rem
     where rem.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and rem.ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID;

    return LastClaimsNumber;
  end LastClaimsNoWithoutDoc;

----------------------------
  function DescriptionOfExpiry(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
    return ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  is
    Description ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type;
  begin
    begin
      select IMF_DESCRIPTION
        into Description
        from ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.FIN_COLLECTIVE = 1;
    exception
      when no_data_found then
        Description  := null;
      when too_many_rows then
        select max(IMF_DESCRIPTION)
          into Description
          from ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1;
    end;

    return Description;
  end DescriptionOfExpiry;

-----------------
  function Currency(aACS_FINANCIAL_CURRENCY_ID number)
    return PCS.PC_CURR.CURRENCY%type
  is
    strCURRENCY PCS.PC_CURR.CURRENCY%type;
  begin
    select CURRENCY
      into strCURRENCY
      from ACS_FINANCIAL_CURRENCY ACURR
         , PCS.PC_CURR PCURR
     where ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
       and ACURR.PC_CURR_ID = PCURR.PC_CURR_ID;

    return strCURRENCY;
  end Currency;

-----------------
  function GetPayCondTolerance(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return PAC_PAYMENT_CONDITION.PCO_CUST_TOLERANCE%type
  is
    vTolerance PAC_PAYMENT_CONDITION.PCO_CUST_TOLERANCE%type;
  begin
    if nvl(aACT_DOCUMENT_ID, 0) = 0 then
      return 0;
    end if;

    --Pour les clients, contrôler la tolérance de date des conditions de paiement
    select
      nvl(max(case when PAR.PAC_CUSTOM_PARTNER_ID is not null then
        (select nvl(max(PCO_CUST_TOLERANCE), 0)
           from PAC_PAYMENT_CONDITION PCO
          where PAC_PAYMENT_CONDITION_ID = PAR.PAC_PAYMENT_CONDITION_ID)
      else 0 end), 0)
     into vTolerance
     from ACT_DOCUMENT DOC
        , ACT_PART_IMPUTATION PAR
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID;

     return vTolerance;
  end GetPayCondTolerance;

--------------------------
  function GetExpiryIdOfToleranceDateOnly(aACT_DOCUMENT_ID number, aEXP_SLICE number, aDate date)
    return ACT_EXPIRY.ACT_EXPIRY_ID%type
  is
    Expiry_id ACT_EXPIRY.ACT_EXPIRY_ID%type;
    dTolDate date;
  begin
    dTolDate := aDate - ACT_FUNCTIONS.GetPayCondTolerance(aACT_DOCUMENT_ID);
    return GetExpiryIdOfDateOnly(aACT_DOCUMENT_ID, aEXP_SLICE, dTolDate);
  end GetExpiryIdOfToleranceDateOnly;

  function GetExpiryIdOfToleranceDate(aACT_DOCUMENT_ID number, aEXP_SLICE number, aDate date)
    return ACT_EXPIRY.ACT_EXPIRY_ID%type
  is
    Expiry_id ACT_EXPIRY.ACT_EXPIRY_ID%type;
    dTolDate date;
  begin
    dTolDate := aDate - ACT_FUNCTIONS.GetPayCondTolerance(aACT_DOCUMENT_ID);
    return GetExpiryIdOfDate(aACT_DOCUMENT_ID, aEXP_SLICE, dTolDate);
  end GetExpiryIdOfToleranceDate;

--------------------------
  function GetExpiryIdOfDateOnly(aACT_DOCUMENT_ID number, aEXP_SLICE number, aDate date)
    return ACT_EXPIRY.ACT_EXPIRY_ID%type
  is
    Expiry_id ACT_EXPIRY.ACT_EXPIRY_ID%type;
  begin
    begin
      select min(ACT_EXPIRY_ID)
        into Expiry_id
        from ACT_EXPIRY
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and EXP_SLICE = aEXP_SLICE
         and EXP_ADAPTED =
                          (select min(EXP_ADAPTED)
                             from ACT_EXPIRY
                            where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                              and EXP_SLICE = aEXP_SLICE
                              and EXP_ADAPTED >= aDate);
    exception
      when no_data_found then
        Expiry_id  := null;
    end;

    return Expiry_id;
  end GetExpiryIdOfDateOnly;

--------------------------
  function GetExpiryIdOfDate(aACT_DOCUMENT_ID number, aEXP_SLICE number, aDate date)
    return ACT_EXPIRY.ACT_EXPIRY_ID%type
  is
    Expiry_id ACT_EXPIRY.ACT_EXPIRY_ID%type;
  begin
    Expiry_id := GetExpiryIdOfDateOnly(aACT_DOCUMENT_ID, aEXP_SLICE, aDate);

    if Expiry_id is null then
      select min(ACT_EXPIRY_ID)
        into Expiry_id
        from ACT_EXPIRY
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and EXP_SLICE = aEXP_SLICE
         and EXP_CALC_NET = 1;
    end if;

    return Expiry_id;
  end GetExpiryIdOfDate;

--------------------------
  function GetAmountOfExpiry(aACT_EXPIRY_ID number, aLC number)
    return number
  is
    Exp_Amount ACT_EXPIRY.EXP_AMOUNT_LC%type;
  begin
    if aLC = 1 then   -- LC
      select min(EXP_AMOUNT_LC)
        into Exp_Amount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    elsif aLC = 0 then   -- FC
      select min(EXP_AMOUNT_FC)
        into Exp_Amount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    elsif aLC = 2 then   -- EURO
      select min(EXP_AMOUNT_EUR)
        into Exp_Amount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    end if;

    if Exp_Amount is null then
      Exp_Amount  := 0;
    end if;

    return Exp_Amount;
  end GetAmountOfExpiry;

--------------------------
  function GetAmountOfPartImputation(
    aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aLC                     number
  )
    return number
  is
    Exp_Amount ACT_EXPIRY.EXP_AMOUNT_LC%type;
  begin
    if aLC = 1 then   -- LC
      select   sum(EXP_AMOUNT_LC)
          into Exp_Amount
          from ACT_EXPIRY
         where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and EXP_CALC_NET = 1
      group by ACT_PART_IMPUTATION_ID;
    elsif aLC = 0 then   -- FC
      select   sum(EXP_AMOUNT_FC)
          into Exp_Amount
          from ACT_EXPIRY
         where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and EXP_CALC_NET = 1
      group by ACT_PART_IMPUTATION_ID;
    elsif aLC = 2 then   -- EURO
      select   sum(EXP_AMOUNT_EUR)
          into Exp_Amount
          from ACT_EXPIRY
         where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and EXP_CALC_NET = 1
      group by ACT_PART_IMPUTATION_ID;
    end if;

    if Exp_Amount is null then
      Exp_Amount  := 0;
    end if;

    return Exp_Amount;
  end GetAmountOfPartImputation;

--------------------------
  function GetTotalAmountOfPartImputation(
    aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aLC                     number
  )
    return number
  is
    Exp_Amount ACT_EXPIRY.EXP_AMOUNT_LC%type;
    Expiry_id  ACT_EXPIRY.ACT_EXPIRY_ID%type;

    cursor EXPIRY(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type)
    is
      select ACT_EXPIRY_ID
        from ACT_EXPIRY
       where ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and EXP_CALC_NET = 1;
  begin
    Exp_Amount  := 0;

    open EXPIRY(aACT_PART_IMPUTATION_ID);

    fetch EXPIRY
     into Expiry_id;

    while EXPIRY%found loop
      Exp_Amount  := Exp_Amount + TotalPayment(Expiry_id, aLC);

      fetch EXPIRY
       into Expiry_id;
    end loop;

    close Expiry;

    return Exp_Amount;
  end GetTotalAmountOfPartImputation;

----------------------------
  function GetDiscountOfExpiry(aACT_EXPIRY_ID number, aLC number)
    return number
  is
    Exp_Discount ACT_EXPIRY.EXP_DISCOUNT_LC%type;
  begin
    if aLC = 1 then   -- LC
      select min(EXP_DISCOUNT_LC)
        into Exp_Discount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    elsif aLC = 0 then   -- FC
      select min(EXP_DISCOUNT_FC)
        into Exp_Discount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    elsif aLC = 2 then   -- EURO
      select min(EXP_DISCOUNT_EUR)
        into Exp_Discount
        from ACT_EXPIRY
       where ACT_EXPIRY_ID = aACT_EXPIRY_ID;
    end if;

    if Exp_Discount is null then
      Exp_Discount  := 0;
    end if;

    return Exp_Discount;
  end GetDiscountOfExpiry;

  procedure GetFreeLastNumber(
    pC_NUMBER_TYPE         in     ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type
  , pACJ_NUMBER_METHOD_ID  in     ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  , pACS_FINANCIAL_YEAR_ID in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pDNM_INCREMENT         in     ACJ_NUMBER_METHOD.DNM_INCREMENT%type
  , pACJ_FREE_NUMBER_ID    out    ACJ_FREE_NUMBER.ACJ_FREE_NUMBER_ID%type
  , pACJ_LAST_NUMBER_ID    out    ACJ_LAST_NUMBER.ACJ_LAST_NUMBER_ID%type
  , pFNU_NUMBER            out    ACJ_FREE_NUMBER.FNU_NUMBER%type
  , pNAP_LAST_NUMBER       in out ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type
  )
  is
  begin
    if pC_NUMBER_TYPE = '3' then
      -- Récupération d'un numéro libre pour le type '3' uniquement et bloquage de la table
      -- Récupération systématique pour les numéros 'annulés'
      begin
        select     ACJ_FREE_NUMBER_ID
                 , FNU_NUMBER
              into pACJ_FREE_NUMBER_ID
                 , pFNU_NUMBER
              from ACJ_FREE_NUMBER
             where ACJ_NUMBER_METHOD_ID = pACJ_NUMBER_METHOD_ID
               and (   ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
                    or (    ACS_FINANCIAL_YEAR_ID is null
                        and pACS_FINANCIAL_YEAR_ID is null)
                   )
               and FNU_NUMBER =
                     (select min(FNU_NUMBER)
                        from ACJ_FREE_NUMBER
                       where ACJ_NUMBER_METHOD_ID = pACJ_NUMBER_METHOD_ID
                         and (   ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
                              or (    ACS_FINANCIAL_YEAR_ID is null
                                  and pACS_FINANCIAL_YEAR_ID is null)
                             ) )
        for update wait 2;
      exception
        when no_data_found then
          pACJ_FREE_NUMBER_ID  := null;
          pFNU_NUMBER          := null;
      end;
    end if;

    -- Récupération du dernier numéro si ncessaire et bloquage de la table
    if    pC_NUMBER_TYPE = '2'
       or (    pC_NUMBER_TYPE = '3'
           and pFNU_NUMBER is null) then
      begin
        select     NAP_LAST_NUMBER
                 , ACJ_LAST_NUMBER_ID
              into pNAP_LAST_NUMBER
                 , pACJ_LAST_NUMBER_ID
              from ACJ_LAST_NUMBER
             where ACJ_NUMBER_METHOD_ID = pACJ_NUMBER_METHOD_ID
               and (   ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
                    or (    ACS_FINANCIAL_YEAR_ID is null
                        and pACS_FINANCIAL_YEAR_ID is null)
                   )
        for update wait 1;
      exception
        when no_data_found then
          pNAP_LAST_NUMBER     := 0;
          pACJ_LAST_NUMBER_ID  := null;

          insert into ACJ_LAST_NUMBER
                      (ACJ_LAST_NUMBER_ID
                     , ACJ_NUMBER_METHOD_ID
                     , ACS_FINANCIAL_YEAR_ID
                     , NAP_LAST_NUMBER
                      )
               values (INIT_ID_SEQ.nextval
                     , pACJ_NUMBER_METHOD_ID
                     , pACS_FINANCIAL_YEAR_ID
                     , pDNM_INCREMENT
                      );
      end;
    elsif pC_NUMBER_TYPE = '4' then
      if pNAP_LAST_NUMBER is null then
        pNAP_LAST_NUMBER  := -1;
      end if;
    end if;
  end GetFreeLastNumber;

----------------------------
  procedure GetDocNumberInternal(
    NumberMethodInfo       in     NumberMethodInfoRecType
  , aACS_FINANCIAL_YEAR_ID in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aDocNumber             in out ACT_DOCUMENT.DOC_NUMBER%type
  , pLastNumber            in     ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type default null
  , aFinAccountId          in     ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aFAM                   in     boolean
  , aLET                   in     boolean
  , aReconciliation        in     boolean
  )
  is
    pragma autonomous_transaction;
    vACJ_FREE_NUMBER_ID ACJ_FREE_NUMBER.ACJ_FREE_NUMBER_ID%type;
    vFreeNumber         ACJ_FREE_NUMBER.FNU_NUMBER%type;
    vACJ_LAST_NUMBER_ID ACJ_LAST_NUMBER.ACJ_LAST_NUMBER_ID%type;
    vLastNumber         ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
    vFound              number(1);
    vCptExistNumber     number                                    := -1;
  begin
    vLastNumber  := pLastNumber;

    if NumberMethodInfo.id is not null then
      --Recherche dernier numéro libre ou attribué
      GetFreeLastNumber(NumberMethodInfo.NumberType
                      , NumberMethodInfo.id
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.increment
                      , vACJ_FREE_NUMBER_ID
                      , vACJ_LAST_NUMBER_ID
                      , vFreeNumber
                      , vLastNumber
                       );
      aDocNumber  :=
        DocNumber(aACS_FINANCIAL_YEAR_ID
                , vLastNumber
                , NumberMethodInfo.NumberType
                , NumberMethodInfo.Prefix
                , NumberMethodInfo.Suffix
                , NumberMethodInfo.increment
                , NumberMethodInfo.FreeManagement
                , vFreeNumber
                , NumberMethodInfo.PicPrefix
                , NumberMethodInfo.PicNumber
                , NumberMethodInfo.PicSuffix
                 );

      if (aDocNumber is not null) then
        -- Contrôle que le numéro retourné (aDocNumber) ne soit pas déjà attribué
        -- Si c'est le cas, il faut
          -- prendre le numéro libre suivant ou
          -- le dernier numéro et ajouter l'incrément (autant de fois que nécessaire)
        -- Appliquer cette règle jusqu'à ce que le numéro construit ne soit effectivement pas attribué
        vFound  := 1;

        while vFound > 0 loop
          -- valeurs possibles de vFound:
            -- 0: le numéro n'est pas attribué
            -- > 0: le numéro a DEJA été attribué
          if (aReconciliation) then
            select nvl(max(1), 0)
              into vFound
              from ACT_FINANCIAL_IMPUTATION IMF
                 , (select FYE_START_DATE
                         , FYE_END_DATE
                      from ACS_FINANCIAL_YEAR
                     where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID) FYE
             where IMF_COMPARE_TEXT = aDocNumber
               and IMF_COMPARE_DATE between FYE.FYE_START_DATE and FYE.FYE_END_DATE;
--         elsif aFAM then
          elsif aLET then
            select nvl(max(1), 0)
              into vFound
              from ACT_LETTERING LET
                 , ACT_LETTERING_DETAIL DET
                 , ACT_FINANCIAL_IMPUTATION IMP
             where IMP.ACS_FINANCIAL_ACCOUNT_ID = aFinAccountId
               and IMP.IMF_ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
               and LET.LET_IDENTIFICATION = aDocNumber
               and DET.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
               and LET.ACT_LETTERING_ID = DET.ACT_LETTERING_ID;
          else
            select nvl(max(1), 0)
              into vFound
              from ACT_DOCUMENT
             where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
               and DOC_NUMBER = aDocNumber;
          end if;

          if vFound > 0 then
            if vACJ_FREE_NUMBER_ID is not null then
              -- Elimination numéro libre DEJA utilisé
              delete from ACJ_FREE_NUMBER
                    where ACJ_FREE_NUMBER_ID = vACJ_FREE_NUMBER_ID;

              vACJ_FREE_NUMBER_ID  := null;
              vFreeNumber          := null;
            end if;

            GetFreeLastNumber(NumberMethodInfo.NumberType
                            , NumberMethodInfo.id
                            , NumberMethodInfo.FinancialYearID
                            , NumberMethodInfo.increment
                            , vACJ_FREE_NUMBER_ID
                            , vACJ_LAST_NUMBER_ID
                            , vFreeNumber
                            , vLastNumber
                             );

            -- Recherche d'un nouveau numéro en l'incrémentant si c'est le dernier numéro utilisé
            -- Ex: dernier numéro utilisé = 313. Numéros existants: 313, 314, 315, incrément de 1. le numéro retourné devra être le 316
            if vLastNumber is not null then
              vCptExistNumber  := vCptExistNumber + 1;
              vLastNumber      := vLastNumber +(vCptExistNumber * NumberMethodInfo.increment);
            end if;

            aDocNumber  :=
              DocNumber(aACS_FINANCIAL_YEAR_ID
                      , vLastNumber
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , vFreeNumber
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                       );
          end if;
        end loop;

        if vACJ_FREE_NUMBER_ID is not null then
          -- Elimination numéro libre réutilisé
          delete from ACJ_FREE_NUMBER
                where ACJ_FREE_NUMBER_ID = vACJ_FREE_NUMBER_ID;
        elsif vACJ_LAST_NUMBER_ID is not null then
          -- Mise à jour dernier numéro utilisé
          update ACJ_LAST_NUMBER
             set NAP_LAST_NUMBER = vLastNumber + NumberMethodInfo.increment
           where ACJ_LAST_NUMBER_ID = vACJ_LAST_NUMBER_ID;
        end if;
      end if;
    else
      aDocNumber  := null;
    end if;

    commit;
  end GetDocNumberInternal;

----------------------
  procedure GetDocNumber(
    aACJ_CATALOGUE_DOCUMENT_ID in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aDocNumber                 in out ACT_DOCUMENT.DOC_NUMBER%type
  )
  is
    NumberMethodInfo NumberMethodInfoRecType;
  begin
    GetNumberMethodInfo(aACJ_CATALOGUE_DOCUMENT_ID
                      , aACS_FINANCIAL_YEAR_ID
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , false
                      , false
                       );
    GetDocNumberInternal(NumberMethodInfo, aACS_FINANCIAL_YEAR_ID, aDocNumber, null, null, false, false, false);
  end GetDocNumber;
------------------
  function GetDocNumberEditMask(
    aACJ_CATALOGUE_DOCUMENT_ID in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  ) return varchar2
  is
    NumberMethodInfo NumberMethodInfoRecType;
  begin
    GetNumberMethodInfo(aACJ_CATALOGUE_DOCUMENT_ID
                      , aACS_FINANCIAL_YEAR_ID
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , false
                      , false
                       );

    return NumberMethodInfo.PicPrefix || NumberMethodInfo.PicNumber || NumberMethodInfo.PicSuffix;

  end GetDocNumberEditMask;

------------------
  function GetDocNumberReadOnly(
    aACJ_CATALOGUE_DOCUMENT_ID in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  ) return number
  is
    NumberMethodInfo NumberMethodInfoRecType;
  begin
    GetNumberMethodInfo(aACJ_CATALOGUE_DOCUMENT_ID
                      , aACS_FINANCIAL_YEAR_ID
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , false
                      , false
                       );

    if NumberMethodInfo.NumberType = '3' then
      return 1;
    else
      return 0;
    end if;

  end GetDocNumberReadOnly;

------------------
  function GetDocNumberMethodId(
    aACJ_CATALOGUE_DOCUMENT_ID in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  ) return ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  is
    NumberMethodInfo NumberMethodInfoRecType;
  begin
    GetNumberMethodInfo(aACJ_CATALOGUE_DOCUMENT_ID
                      , aACS_FINANCIAL_YEAR_ID
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , false
                      , false
                       );

    return NumberMethodInfo.id;

  end GetDocNumberMethodId;

------------------

  /**
  * procedure GetNumMethodImfCompareText
  * Description
  *   Retourne le prochain numéro du numéroteur suivant le catalogue et l'exercice
  * @lastUpdate
  * @public
  * @param pFinancialYearId     Exercice courant
  *        pImfCompareText      Texte de rapprochement de retour
  */
  procedure GetNumMethodImfCompareText(
    pFinancialYearId in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pImfCompareText  out    ACT_FINANCIAL_IMPUTATION.IMF_COMPARE_TEXT%type
  )
  is
    NumberMethodInfo NumberMethodInfoRecType;
    vImfCompareText  ACT_FINANCIAL_IMPUTATION.IMF_COMPARE_TEXT%type;
  begin
    GetNumberMethodInfo(0
                      , pFinancialYearId
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , false
                      , true
                       );

    /* Réception du dernier n° utilisé dans les rapprochements */
    if NumberMethodInfo.NumberType = '4' then
      begin
        select max(IMP.IMF_COMPARE_TEXT)
          into vImfCompareText
          from ACT_FINANCIAL_IMPUTATION IMP
         where IMP.IMF_ACS_FINANCIAL_YEAR_ID = pFinancialYearId;
      exception
        when no_data_found then
          null;
      end;
    end if;

    GetDocNumberInternal(NumberMethodInfo
                       , pFinancialYearId
                       , pImfCompareText
                       , AlphaToSequence(vImfCompareText)
                       , null
                       , false
                       , false
                       , true
                        );
  end GetNumMethodImfCompareText;

  procedure GetDocNumberForLettring(
    pFinancialYearId in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFinAccountId    in     ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pIdentification  in out ACT_LETTERING.LET_IDENTIFICATION%type
  )
  is
    NumberMethodInfo NumberMethodInfoRecType;
    vIdentification  ACT_LETTERING.LET_IDENTIFICATION%type;
  begin
    GetNumberMethodInfo(0
                      , pFinancialYearId
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , false
                      , true
                      , false
                       );

    /* Réception du dernier n° utilisé dans les lettrages pour le compte donné */
    if NumberMethodInfo.NumberType = '4' then
      begin
        select max(LET.LET_IDENTIFICATION)
          into vIdentification
          from ACT_LETTERING LET
             , ACT_LETTERING_DETAIL DET
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACS_FINANCIAL_ACCOUNT_ID = pFinAccountId
           and IMP.IMF_ACS_FINANCIAL_YEAR_ID = pFinancialYearId
           and DET.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
           and LET.ACT_LETTERING_ID = DET.ACT_LETTERING_ID;
      exception
        when no_data_found then
          null;
      end;
    end if;

    GetDocNumberInternal(NumberMethodInfo
                       , pFinancialYearId
                       , pIdentification
                       , AlphaToSequence(vIdentification)
                       , pFinAccountId
                       , false
                       , true
                       , false
                        );
  end GetDocNumberForLettring;

------------------
  procedure GetDocNumberForCover(
    aACJ_NUMBER_METHOD_ID in     ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  , aDocNumber            in out ACT_DOCUMENT.DOC_NUMBER%type
  )
  is
    NumberMethodInfo NumberMethodInfoRecType;
  begin
    select NUM.ACJ_NUMBER_METHOD_ID
         , null
         , NUM.C_NUMBER_TYPE
         , NUM.DNM_PREFIX
         , NUM.DNM_SUFFIX
         , NUM.DNM_INCREMENT
         , NUM.DNM_FREE_MANAGEMENT
         , PPI.PIC_PICTURE
         , NPI.PIC_PICTURE
         , SPI.PIC_PICTURE
      into NumberMethodInfo
      from ACS_PICTURE PPI
         , ACS_PICTURE NPI
         , ACS_PICTURE SPI
         , ACJ_NUMBER_METHOD NUM
     where NUM.ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
       and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
       and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
       and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+);

    GetDocNumberInternal(NumberMethodInfo, null, aDocNumber, null, null, false, false, false);
  end GetDocNumberForCover;

------------------
  function DocNumber(
    aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aLastNumber            ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type
  , aNumberType            ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type
  , aPrefix                ACJ_NUMBER_METHOD.DNM_PREFIX%type
  , aSuffix                ACJ_NUMBER_METHOD.DNM_SUFFIX%type
  , aIncrement             ACJ_NUMBER_METHOD.DNM_INCREMENT%type
  , aFreeManagement        ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type
  , aFreeNumber            ACJ_FREE_NUMBER.FNU_NUMBER%type
  , aPicPrefix             ACS_PICTURE.PIC_PICTURE%type
  , aPicNumber             ACS_PICTURE.PIC_PICTURE%type
  , aPicSuffix             ACS_PICTURE.PIC_PICTURE%type
  )
    return ACT_DOCUMENT.DOC_NUMBER%type
  is
    strDocNumber ACT_DOCUMENT.DOC_NUMBER%type;
    strPrefix    ACS_PICTURE.PIC_PICTURE%type;
    strSuffix    ACS_PICTURE.PIC_PICTURE%type;
  begin
    strPrefix  := aPrefix;
    strSuffix  := aSuffix;
    strPrefix  := AddYear(aACS_FINANCIAL_YEAR_ID, strPrefix);
    strSuffix  := AddYear(aACS_FINANCIAL_YEAR_ID, strSuffix);

    if aNumberType = '1' then   -- Saisie manuelle du numéro
      strDocNumber  := null;
    elsif aNumberType = '2' then   -- Numérotation automatique, changement autorisé
      if length(to_char(aLastNumber + aIncrement)) > length(aPicNumber) then
        raise_application_error(-20301, 'PCS - Counter overflow the definition of the number method');
      end if;
      strDocNumber  := strPrefix || lpad(to_char(aLastNumber + aIncrement), length(aPicNumber), '0') || strSuffix;
    elsif aNumberType = '3' then   -- Numérotation automatique, changement non autorisé
      if aFreeNumber is not null then
        strDocNumber  := strPrefix || lpad(to_char(aFreeNumber), length(aPicNumber), '0') || strSuffix;
      else
        if length(to_char(aLastNumber + aIncrement)) > length(aPicNumber) then
          raise_application_error(-20301, 'PCS - Counter overflow the definition of the number method');
        end if;
        strDocNumber  := strPrefix || lpad(to_char(aLastNumber + aIncrement), length(aPicNumber), '0') || strSuffix;
      end if;
    elsif aNumberType = '4' then   -- Numérotation automatique alphabétique
      strDocNumber  := strPrefix || SequenceToAlpha(aLastNumber + aIncrement, length(aPicNumber) ) || strSuffix;
    end if;

    return strDocNumber;
  end DocNumber;

----------------
  function AddYear(
    aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aPrefixSuffix          ACS_PICTURE.PIC_PICTURE%type
  )
    return ACS_PICTURE.PIC_PICTURE%type
  is
    strResult     ACS_PICTURE.PIC_PICTURE%type;
    StartYearDate date;
    EndYearDate   date;
  begin
    strResult  := aPrefixSuffix;

    if (instr(upper(aPrefixSuffix), 'DD') > 0) then
      strResult  := DayMonthYear(strResult, sysdate, 'DD');
    end if;

    if (instr(upper(aPrefixSuffix), 'MM') > 0) then
      strResult  := DayMonthYear(strResult, sysdate, 'MM');
    end if;

    if    (instr(upper(aPrefixSuffix), 'YY') > 0)
       or (instr(upper(aPrefixSuffix), 'ZZ') > 0) then
      select nvl(min(FYE_START_DATE), sysdate)
           , nvl(min(FYE_END_DATE), sysdate)
        into StartYearDate
           , EndYearDate
        from ACS_FINANCIAL_YEAR
       where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;

      if (instr(upper(aPrefixSuffix), 'YY') > 0) then
        if instr(upper(strResult), 'YYYY') > 0 then
          strResult  := DayMonthYear(strResult, StartYearDate, 'YYYY');
        else
          strResult  := DayMonthYear(strResult, StartYearDate, 'YY');
        end if;
      end if;

      if (instr(upper(aPrefixSuffix), 'ZZ') > 0) then
        if instr(upper(strResult), 'ZZZZ') > 0 then
          strResult  := DayMonthYear(replace(strResult, 'ZZZZ', 'YYYY'), EndYearDate, 'YYYY');
        else
          strResult  := DayMonthYear(replace(strResult, 'ZZ', 'YY'), EndYearDate, 'YY');
        end if;
      end if;
    end if;

    return strResult;
  end AddYear;

---------------------
  function DayMonthYear(aPrefixSuffix ACS_PICTURE.PIC_PICTURE%type, aBeginDate date, strFind varchar2)
    return ACS_PICTURE.PIC_PICTURE%type
  is
    strResult ACS_PICTURE.PIC_PICTURE%type;
    strBegin  varchar2(10);
    strEnd    varchar2(10);
    strMiddle varchar2(10);
    intPos    number(2);
  begin
    strResult  := aPrefixSuffix;
    intPos     := instr(upper(strResult), strFind, 1, 1);

    if intPos > 0 then
      strBegin   := substr(strResult, 1, intPos - 1);
      strEnd     := substr(strResult, intPos + length(strFind) );
      strMiddle  := to_char(aBeginDate, strFind);
      strResult  := strBegin || strMiddle || strEnd;
    end if;

    return strResult;
  end DayMonthYear;

-----------------------
  procedure AddFreeNumber(
    aACJ_CATALOGUE_DOCUMENT_ID in ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aDocNumber                 in ACT_DOCUMENT.DOC_NUMBER%type
  , aRollback                  in number default 0
  , aFinAccountId              in ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  , aFAM                       in boolean default false
  , aLET                       in boolean default false
  , aReconciliation            in boolean default false
  )
  is
    pragma autonomous_transaction;
    LastNumber            ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
    CurrentNumber         ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
    intACJ_LAST_NUMBER_ID ACJ_LAST_NUMBER.ACJ_LAST_NUMBER_ID%type;
    NumberMethodInfo      NumberMethodInfoRecType;
    vDocNumber            ACT_DOCUMENT.DOC_NUMBER%type;
    vCountDocNumber       number                                    default 0;
  begin
    -- Recherche d'un numéro de document déjà existant. Si déjà existant, ne pas l'ajouter
    if aReconciliation then
      --Le rapprochement attribue le même numéro à plusieurs documents. S'assurer que le numéro n'a pas été attribué à un autre rapprochement (date + numéro)
      select count(0)
        into vCountDocNumber
        from (select   1
                  from ACT_FINANCIAL_IMPUTATION IMF
                     , (select FYE_START_DATE
                             , FYE_END_DATE
                          from ACS_FINANCIAL_YEAR
                         where ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID) FYE
                 where IMF_COMPARE_TEXT = aDocNumber
                   and IMF_COMPARE_DATE between FYE.FYE_START_DATE and FYE.FYE_END_DATE
              group by IMF_COMPARE_DATE
                     , IMF_COMPARE_TEXT);
    elsif aLet then
      --Le lettrage attribue le même numéro à plusieurs documents. S'assurer que le numéro n'a pas été attribué à un autre lettrage (identification lettrage, exercice, compte financier)
      select count(0)
        into vCountDocNumber
        from (select   1
                  from ACT_LETTERING LET
                     , ACT_LETTERING_DETAIL DET
                     , ACT_FINANCIAL_IMPUTATION IMP
                 where IMP.ACS_FINANCIAL_ACCOUNT_ID = aFinAccountId
                   and IMP.IMF_ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and LET.LET_IDENTIFICATION = aDocNumber
                   and DET.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
                   and LET.ACT_LETTERING_ID = DET.ACT_LETTERING_ID
              group by LET.LET_IDENTIFICATION
                     , IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.IMF_ACS_FINANCIAL_YEAR_ID);
    else
      select count(0)
        into vCountDocNumber
        from ACT_DOCUMENT
       where DOC_NUMBER = aDocNumber
         and ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID;
    end if;

    GetNumberMethodInfo(aACJ_CATALOGUE_DOCUMENT_ID
                      , aACS_FINANCIAL_YEAR_ID
                      , NumberMethodInfo.FinancialYearID
                      , NumberMethodInfo.id
                      , NumberMethodInfo.NumberType
                      , NumberMethodInfo.Prefix
                      , NumberMethodInfo.Suffix
                      , NumberMethodInfo.increment
                      , NumberMethodInfo.FreeManagement
                      , NumberMethodInfo.PicPrefix
                      , NumberMethodInfo.PicNumber
                      , NumberMethodInfo.PicSuffix
                      , aFAM
                      , aLET
                      , aReconciliation
                       );

    /* Pas de  gestion n° libres pour les types 4 ( alphabétique automatique )  */
    if     (NumberMethodInfo.id is not null)
       and (NumberMethodInfo.NumberType <> '4') then
      begin
        LastNumber  :=
          to_number(substr(aDocNumber, nvl(length(NumberMethodInfo.Prefix), 0) + 1, length(NumberMethodInfo.PicNumber) ) );
      exception
        when value_error then
          LastNumber  := null;
      end;

      -- Conséquences d' autonomous transaction:
        -- si aRollback (insertion annulée), le numéro n'existe pas encore ici
        -- si suppression de document, le numéro libre est ajouté après la suppression, mais autonomous_transaction fait qu'il existe toujours => vCountDocNumber >= 1
      if     (   nvl(aRollback, 0) != 0
              or NumberMethodInfo.FreeManagement = 1)
         and (vCountDocNumber <= 1)
         and (LastNumber is not null) then
        begin
          insert into ACJ_FREE_NUMBER
                      (ACJ_FREE_NUMBER_ID
                     , ACJ_NUMBER_METHOD_ID
                     , ACS_FINANCIAL_YEAR_ID
                     , FNU_NUMBER
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , NumberMethodInfo.id
                     , NumberMethodInfo.FinancialYearID
                     , LastNumber
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        exception
          when dup_val_on_index then
            null;
        end;
      end if;
    end if;

    commit;
  end AddFreeNumber;

  /*
  * Recherche de la méthode de numéotation appliquée au catalogue document
  */
  function GetNumberMethodId(
    pCatalogueId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , pFinYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pSearchStep  number
  )
    return ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  is
    vNumberMethodId ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
  begin
    if pSearchStep >= 1 then
      begin
        /*Recherche méthode avec type de transaction et exercice comptable*/
        select APP.ACJ_NUMBER_METHOD_ID
          into vNumberMethodId
          from ACJ_NUMBER_APPLICATION APP
         where APP.ACS_FINANCIAL_YEAR_ID = pFinYearId
           and APP.ACJ_CATALOGUE_DOCUMENT_ID = pCatalogueId
           and not exists(select FAM_CATALOGUE_ID
                            from FAM_CATALOGUE
                           where ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID);
      exception
        when no_data_found then
          if pSearchStep >= 2 then
            begin
              /*Recherche méthode avec type de transaction */
              select APP.ACJ_NUMBER_METHOD_ID
                into vNumberMethodId
                from ACJ_NUMBER_APPLICATION APP
               where APP.ACS_FINANCIAL_YEAR_ID is null
                 and APP.ACJ_CATALOGUE_DOCUMENT_ID = pCatalogueId
                 and not exists(select FAM_CATALOGUE_ID
                                  from FAM_CATALOGUE
                                 where ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID);
            exception
              when no_data_found then
                if pSearchStep >= 3 then
                  begin
                    /*Recherche méthode avec exercice comptable*/
                    select APP.ACJ_NUMBER_METHOD_ID
                      into vNumberMethodId
                      from ACJ_NUMBER_APPLICATION APP
                     where APP.ACS_FINANCIAL_YEAR_ID = pFinYearId
                       and APP.ACJ_CATALOGUE_DOCUMENT_ID is null
                       and not exists(select FAM_CATALOGUE_ID
                                        from FAM_CATALOGUE
                                       where ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID);
                  exception
                    when no_data_found then
                      if pSearchStep >= 3 then
                        begin
                          /*Recherche méthode indépendamment du type transaction et exercice comptable*/
                          select APP.ACJ_NUMBER_METHOD_ID
                            into vNumberMethodId
                            from ACJ_NUMBER_APPLICATION APP
                           where APP.ACS_FINANCIAL_YEAR_ID is null
                             and APP.ACJ_CATALOGUE_DOCUMENT_ID is null
                             and not exists(select FAM_CATALOGUE_ID
                                              from FAM_CATALOGUE
                                             where ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID);
                        exception
                          when no_data_found then
                            vNumberMethodId  := -1;
                        end;
                      else
                        vNumberMethodId  := -1;
                      end if;
                  end;
                else
                  vNumberMethodId  := -1;
                end if;
            end;
          else
            vNumberMethodId  := -1;
          end if;
      end;
    else
      vNumberMethodId  := -1;
    end if;

    return vNumberMethodId;
  end GetNumberMethodId;

-----------------------------
  procedure GetNumberMethodInfo(
    aACJ_CATALOGUE_DOCUMENT_ID in     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID     in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aYearId                    in out ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aACJ_NUMBER_METHOD_ID      in out ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  , aC_NUMBER_TYPE             in out ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type
  , aDNM_PREFIX                in out ACJ_NUMBER_METHOD.DNM_PREFIX%type
  , aDNM_SUFFIX                in out ACJ_NUMBER_METHOD.DNM_SUFFIX%type
  , aDNM_INCREMENT             in out ACJ_NUMBER_METHOD.DNM_INCREMENT%type
  , aDNM_FREE_MANAGEMENT       in out ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type
  , aPicPrefix                 in out ACS_PICTURE.PIC_PICTURE%type
  , aPicNumber                 in out ACS_PICTURE.PIC_PICTURE%type
  , aPicSuffix                 in out ACS_PICTURE.PIC_PICTURE%type
  , aFAM                       in     boolean default false
  , aLET                       in     boolean default false
  , aReconciliation            in     boolean default false
  )
  is
  begin
    --Méthode de numérotation pour lettrage
    if aLET then
      begin
        -- Recherche numéroteur pour lettrage avec exercice comptable
        select APP.ACS_FINANCIAL_YEAR_ID
             , NUM.ACJ_NUMBER_METHOD_ID
             , NUM.C_NUMBER_TYPE
             , NUM.DNM_PREFIX
             , NUM.DNM_SUFFIX
             , NUM.DNM_INCREMENT
             , NUM.DNM_FREE_MANAGEMENT
             , PPI.PIC_PICTURE
             , NPI.PIC_PICTURE
             , SPI.PIC_PICTURE
          into aYearId
             , aACJ_NUMBER_METHOD_ID
             , aC_NUMBER_TYPE
             , aDNM_PREFIX
             , aDNM_SUFFIX
             , aDNM_INCREMENT
             , aDNM_FREE_MANAGEMENT
             , aPicPrefix
             , aPicNumber
             , aPicSuffix
          from ACS_PICTURE PPI
             , ACS_PICTURE NPI
             , ACS_PICTURE SPI
             , ACJ_NUMBER_APPLICATION APP
             , ACJ_NUMBER_METHOD NUM
         where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
           and NUM.DNM_ACT_LETTERING = 1
           and APP.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
           and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
           and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
           and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
           and not exists(select FAM_CATALOGUE_ID
                            from FAM_CATALOGUE
                           where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
      exception
        when no_data_found then
          begin
            -- Recherche numéroteur pour lettrage
            select null ACS_FINANCIAL_YEAR_ID
                 , NUM.ACJ_NUMBER_METHOD_ID
                 , NUM.C_NUMBER_TYPE
                 , NUM.DNM_PREFIX
                 , NUM.DNM_SUFFIX
                 , NUM.DNM_INCREMENT
                 , NUM.DNM_FREE_MANAGEMENT
                 , PPI.PIC_PICTURE
                 , NPI.PIC_PICTURE
                 , SPI.PIC_PICTURE
              into aYearId
                 , aACJ_NUMBER_METHOD_ID
                 , aC_NUMBER_TYPE
                 , aDNM_PREFIX
                 , aDNM_SUFFIX
                 , aDNM_INCREMENT
                 , aDNM_FREE_MANAGEMENT
                 , aPicPrefix
                 , aPicNumber
                 , aPicSuffix
              from ACS_PICTURE PPI
                 , ACS_PICTURE NPI
                 , ACS_PICTURE SPI
                 , ACJ_NUMBER_METHOD NUM
             where NUM.DNM_ACT_LETTERING = 1
               and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
               and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
               and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
               and not exists(select FAM_CATALOGUE_ID
                                from FAM_CATALOGUE
                               where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
          exception
            when no_data_found then
              aACJ_NUMBER_METHOD_ID  := null;
            when too_many_rows then
              raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
          end;
        when too_many_rows then
          raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
      end;
    -- Méthodes de numérotation pour rapprochement
    elsif aReconciliation then
      begin
        -- Recherche numéroteur pour rapprochement avec exercice comptable
        select APP.ACS_FINANCIAL_YEAR_ID
             , NUM.ACJ_NUMBER_METHOD_ID
             , NUM.C_NUMBER_TYPE
             , NUM.DNM_PREFIX
             , NUM.DNM_SUFFIX
             , NUM.DNM_INCREMENT
             , NUM.DNM_FREE_MANAGEMENT
             , PPI.PIC_PICTURE
             , NPI.PIC_PICTURE
             , SPI.PIC_PICTURE
          into aYearId
             , aACJ_NUMBER_METHOD_ID
             , aC_NUMBER_TYPE
             , aDNM_PREFIX
             , aDNM_SUFFIX
             , aDNM_INCREMENT
             , aDNM_FREE_MANAGEMENT
             , aPicPrefix
             , aPicNumber
             , aPicSuffix
          from ACS_PICTURE PPI
             , ACS_PICTURE NPI
             , ACS_PICTURE SPI
             , ACJ_NUMBER_APPLICATION APP
             , ACJ_NUMBER_METHOD NUM
         where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
           and NUM.DNM_ACT_RECONCILIATION = 1
           and APP.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
           and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
           and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
           and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
           and not exists(select FAM_CATALOGUE_ID
                            from FAM_CATALOGUE
                           where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
      exception
        when no_data_found then
          begin
            -- Recherche numéroteur pour rapprochement
            select null ACS_FINANCIAL_YEAR_ID
                 , NUM.ACJ_NUMBER_METHOD_ID
                 , NUM.C_NUMBER_TYPE
                 , NUM.DNM_PREFIX
                 , NUM.DNM_SUFFIX
                 , NUM.DNM_INCREMENT
                 , NUM.DNM_FREE_MANAGEMENT
                 , PPI.PIC_PICTURE
                 , NPI.PIC_PICTURE
                 , SPI.PIC_PICTURE
              into aYearId
                 , aACJ_NUMBER_METHOD_ID
                 , aC_NUMBER_TYPE
                 , aDNM_PREFIX
                 , aDNM_SUFFIX
                 , aDNM_INCREMENT
                 , aDNM_FREE_MANAGEMENT
                 , aPicPrefix
                 , aPicNumber
                 , aPicSuffix
              from ACS_PICTURE PPI
                 , ACS_PICTURE NPI
                 , ACS_PICTURE SPI
                 , ACJ_NUMBER_METHOD NUM
             where NUM.DNM_ACT_RECONCILIATION = 1
               and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
               and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
               and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
               and not exists(select FAM_CATALOGUE_ID
                                from FAM_CATALOGUE
                               where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
          exception
            when no_data_found then
              aACJ_NUMBER_METHOD_ID  := null;
            when too_many_rows then
              raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
          end;
        when too_many_rows then
          raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
      end;
    -- Méthodes de numérotation ACJ pour documents FAM
    elsif aFAM then
      begin
        select ACJ_NUMBER_METHOD_ID
          into aACJ_NUMBER_METHOD_ID
          from FAM_CATALOGUE
         where FAM_CATALOGUE_ID = aACJ_CATALOGUE_DOCUMENT_ID;
      exception
        when no_data_found then
          aACJ_NUMBER_METHOD_ID  := null;
      end;

      if aACJ_NUMBER_METHOD_ID is not null then
        begin
          -- Recherche Application méthode avec exercice comptable
          select distinct APP.ACS_FINANCIAL_YEAR_ID
                        , NUM.C_NUMBER_TYPE
                        , NUM.DNM_PREFIX
                        , NUM.DNM_SUFFIX
                        , NUM.DNM_INCREMENT
                        , NUM.DNM_FREE_MANAGEMENT
                        , PPI.PIC_PICTURE
                        , NPI.PIC_PICTURE
                        , SPI.PIC_PICTURE
                     into aYearId
                        , aC_NUMBER_TYPE
                        , aDNM_PREFIX
                        , aDNM_SUFFIX
                        , aDNM_INCREMENT
                        , aDNM_FREE_MANAGEMENT
                        , aPicPrefix
                        , aPicNumber
                        , aPicSuffix
                     from ACS_PICTURE PPI
                        , ACS_PICTURE NPI
                        , ACS_PICTURE SPI
                        , ACJ_NUMBER_APPLICATION APP
                        , ACJ_NUMBER_METHOD NUM
                    where NUM.ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
                      and NUM.ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID
                      and APP.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                      and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
                      and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
                      and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
                      and NUM.DNM_FAM_FIXED_ASSETS = 1
                      and NUM.DNM_ACT_LETTERING = 0
                      and NUM.DNM_ACS_PAYMENT_METHOD = 0
                      and NUM.DNM_PAC_EVENT = 0;
        exception
          when no_data_found then
            begin
              -- Recherche Application méthode indépendamment de l'exercice comptable
              select distinct APP.ACS_FINANCIAL_YEAR_ID
                            , NUM.C_NUMBER_TYPE
                            , NUM.DNM_PREFIX
                            , NUM.DNM_SUFFIX
                            , NUM.DNM_INCREMENT
                            , NUM.DNM_FREE_MANAGEMENT
                            , PPI.PIC_PICTURE
                            , NPI.PIC_PICTURE
                            , SPI.PIC_PICTURE
                         into aYearId
                            , aC_NUMBER_TYPE
                            , aDNM_PREFIX
                            , aDNM_SUFFIX
                            , aDNM_INCREMENT
                            , aDNM_FREE_MANAGEMENT
                            , aPicPrefix
                            , aPicNumber
                            , aPicSuffix
                         from ACS_PICTURE PPI
                            , ACS_PICTURE NPI
                            , ACS_PICTURE SPI
                            , ACJ_NUMBER_APPLICATION APP
                            , ACJ_NUMBER_METHOD NUM
                        where NUM.ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
                          and NUM.ACJ_NUMBER_METHOD_ID = APP.ACJ_NUMBER_METHOD_ID(+)
                          and APP.ACS_FINANCIAL_YEAR_ID is null
                          and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
                          and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
                          and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
                          and NUM.DNM_FAM_FIXED_ASSETS = 1
                          and NUM.DNM_ACT_LETTERING = 0
                          and NUM.DNM_ACS_PAYMENT_METHOD = 0
                          and NUM.DNM_PAC_EVENT = 0;
            exception
              when no_data_found then
                aACJ_NUMBER_METHOD_ID  := null;
              when too_many_rows then
                raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
            end;
          when too_many_rows then
            raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
        end;
      end if;
    else
      begin
        -- Recherche méthode avec type de transaction et exercice comptable
        select APP.ACS_FINANCIAL_YEAR_ID
             , NUM.ACJ_NUMBER_METHOD_ID
             , NUM.C_NUMBER_TYPE
             , NUM.DNM_PREFIX
             , NUM.DNM_SUFFIX
             , NUM.DNM_INCREMENT
             , NUM.DNM_FREE_MANAGEMENT
             , PPI.PIC_PICTURE
             , NPI.PIC_PICTURE
             , SPI.PIC_PICTURE
          into aYearId
             , aACJ_NUMBER_METHOD_ID
             , aC_NUMBER_TYPE
             , aDNM_PREFIX
             , aDNM_SUFFIX
             , aDNM_INCREMENT
             , aDNM_FREE_MANAGEMENT
             , aPicPrefix
             , aPicNumber
             , aPicSuffix
          from ACS_PICTURE PPI
             , ACS_PICTURE NPI
             , ACS_PICTURE SPI
             , ACJ_NUMBER_APPLICATION APP
             , ACJ_NUMBER_METHOD NUM
         where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
           and APP.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
           and APP.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
           and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
           and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
           and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
           and NUM.DNM_FAM_FIXED_ASSETS = 0
           and NUM.DNM_ACT_LETTERING = 0
           and NUM.DNM_ACS_PAYMENT_METHOD = 0
           and NUM.DNM_PAC_EVENT = 0
           and not exists(select FAM_CATALOGUE_ID
                            from FAM_CATALOGUE
                           where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
      exception
        when no_data_found then
          begin
            -- Recherche méthode avec type de transaction
            select APP.ACS_FINANCIAL_YEAR_ID
                 , NUM.ACJ_NUMBER_METHOD_ID
                 , NUM.C_NUMBER_TYPE
                 , NUM.DNM_PREFIX
                 , NUM.DNM_SUFFIX
                 , NUM.DNM_INCREMENT
                 , NUM.DNM_FREE_MANAGEMENT
                 , PPI.PIC_PICTURE
                 , NPI.PIC_PICTURE
                 , SPI.PIC_PICTURE
              into aYearId
                 , aACJ_NUMBER_METHOD_ID
                 , aC_NUMBER_TYPE
                 , aDNM_PREFIX
                 , aDNM_SUFFIX
                 , aDNM_INCREMENT
                 , aDNM_FREE_MANAGEMENT
                 , aPicPrefix
                 , aPicNumber
                 , aPicSuffix
              from ACS_PICTURE PPI
                 , ACS_PICTURE NPI
                 , ACS_PICTURE SPI
                 , ACJ_NUMBER_APPLICATION APP
                 , ACJ_NUMBER_METHOD NUM
             where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
               and APP.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
               and APP.ACS_FINANCIAL_YEAR_ID is null
               and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
               and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
               and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
               and NUM.DNM_FAM_FIXED_ASSETS = 0
               and NUM.DNM_ACT_LETTERING = 0
               and NUM.DNM_ACS_PAYMENT_METHOD = 0
               and NUM.DNM_PAC_EVENT = 0
               and not exists(select FAM_CATALOGUE_ID
                                from FAM_CATALOGUE
                               where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
          exception
            when no_data_found then
              begin
                -- Recherche méthode avec exercice comptable
                select APP.ACS_FINANCIAL_YEAR_ID
                     , NUM.ACJ_NUMBER_METHOD_ID
                     , NUM.C_NUMBER_TYPE
                     , NUM.DNM_PREFIX
                     , NUM.DNM_SUFFIX
                     , NUM.DNM_INCREMENT
                     , NUM.DNM_FREE_MANAGEMENT
                     , PPI.PIC_PICTURE
                     , NPI.PIC_PICTURE
                     , SPI.PIC_PICTURE
                  into aYearId
                     , aACJ_NUMBER_METHOD_ID
                     , aC_NUMBER_TYPE
                     , aDNM_PREFIX
                     , aDNM_SUFFIX
                     , aDNM_INCREMENT
                     , aDNM_FREE_MANAGEMENT
                     , aPicPrefix
                     , aPicNumber
                     , aPicSuffix
                  from ACS_PICTURE PPI
                     , ACS_PICTURE NPI
                     , ACS_PICTURE SPI
                     , ACJ_NUMBER_APPLICATION APP
                     , ACJ_NUMBER_METHOD NUM
                 where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
                   and APP.ACS_FINANCIAL_YEAR_ID = aACS_FINANCIAL_YEAR_ID
                   and APP.ACJ_CATALOGUE_DOCUMENT_ID is null
                   and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
                   and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
                   and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
                   and NUM.DNM_FAM_FIXED_ASSETS = 0
                   and NUM.DNM_ACT_LETTERING = 0
                   and NUM.DNM_ACS_PAYMENT_METHOD = 0
                   and NUM.DNM_PAC_EVENT = 0
                   and not exists(select FAM_CATALOGUE_ID
                                    from FAM_CATALOGUE
                                   where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
              exception
                when no_data_found then
                  begin
                    -- Recherche méthode indépendamment du type transaction et exercice comptable
                    select APP.ACS_FINANCIAL_YEAR_ID
                         , NUM.ACJ_NUMBER_METHOD_ID
                         , NUM.C_NUMBER_TYPE
                         , NUM.DNM_PREFIX
                         , NUM.DNM_SUFFIX
                         , NUM.DNM_INCREMENT
                         , NUM.DNM_FREE_MANAGEMENT
                         , PPI.PIC_PICTURE
                         , NPI.PIC_PICTURE
                         , SPI.PIC_PICTURE
                      into aYearId
                         , aACJ_NUMBER_METHOD_ID
                         , aC_NUMBER_TYPE
                         , aDNM_PREFIX
                         , aDNM_SUFFIX
                         , aDNM_INCREMENT
                         , aDNM_FREE_MANAGEMENT
                         , aPicPrefix
                         , aPicNumber
                         , aPicSuffix
                      from ACS_PICTURE PPI
                         , ACS_PICTURE NPI
                         , ACS_PICTURE SPI
                         , ACJ_NUMBER_APPLICATION APP
                         , ACJ_NUMBER_METHOD NUM
                     where APP.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
                       and APP.ACS_FINANCIAL_YEAR_ID is null
                       and APP.ACJ_CATALOGUE_DOCUMENT_ID is null
                       and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
                       and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
                       and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
                       and NUM.DNM_FAM_FIXED_ASSETS = 0
                       and NUM.DNM_ACT_LETTERING = 0
                       and NUM.DNM_ACS_PAYMENT_METHOD = 0
                       and NUM.DNM_PAC_EVENT = 0
                       and not exists(select FAM_CATALOGUE_ID
                                        from FAM_CATALOGUE
                                       where ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID);
                  exception
                    when no_data_found then
                      aACJ_NUMBER_METHOD_ID  := null;
                    when too_many_rows then
                      raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
                  end;
                when too_many_rows then
                  raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
              end;
            when too_many_rows then
              raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
          end;
        when too_many_rows then
          raise_application_error(-20300, 'PCS - More than one number method defined for the transaction');
      end;
    end if;
  end GetNumberMethodInfo;

--------------------
  function GetCoverUsed(aACT_COVER_INFORMATION_ID ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type)
    return number
  is
    State ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type;
  begin
    select max(ACT_COVER_INFORMATION_ID)
      into State
      from ACT_COVER_INFORMATION
     where ACT_COVER_INFORMATION_ID = aACT_COVER_INFORMATION_ID;

    if State is null then
      return 0;
    else
      return 1;
    end if;
  end GetCoverUsed;

-----------------------
  function GetAddressForPaiement(
    aPAC_PERSON_ID              in PAC_PERSON.PAC_PERSON_ID%type
  , aPAC_FINANCIAL_REFERENCE_ID in PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  , aField                      in number
  , aRefAdd                     in number default 1
  )
    return varchar2
  is
    AddressId PAC_ADDRESS.PAC_ADDRESS_ID%type;
    Address1  PAC_ADDRESS.ADD_ADDRESS1%type;
    ZipCode   PAC_ADDRESS.ADD_ZIPCODE%type;
    City      PAC_ADDRESS.ADD_CITY%type;
    Addformat PAC_ADDRESS.ADD_FORMAT%type;
    Cntry     PCS.PC_CNTRY.CNTID%type;
    CntryId   PCS.PC_CNTRY.PC_CNTRY_ID%type;
    State     PAC_ADDRESS.ADD_STATE%type;
    CareOf    PAC_ADDRESS.ADD_CARE_OF%type;
    PoBox     PAC_ADDRESS.ADD_PO_BOX%type;
    PoBoxNbr  PAC_ADDRESS.ADD_PO_BOX_NBR%type;
    County    PAC_ADDRESS.ADD_COUNTY%type;
  begin
    AddressId  := null;

    if     (    (aPAC_FINANCIAL_REFERENCE_ID is not null)
            or (aPAC_FINANCIAL_REFERENCE_ID <> 0) )
       and (aRefAdd = 1) then
      select min(PAC_ADDRESS.PAC_ADDRESS_ID)
        into AddressId
        from PAC_ADDRESS
           , PAC_FINANCIAL_REFERENCE
       where PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID = aPAC_FINANCIAL_REFERENCE_ID
         and PAC_FINANCIAL_REFERENCE.PAC_ADDRESS_ID = PAC_ADDRESS.PAC_ADDRESS_ID;
    end if;

    if AddressId is null then
      select min(PAC_ADDRESS_ID)
        into AddressId
        from PAC_ADDRESS
       where PAC_PERSON_ID = aPAC_PERSON_ID
         and ADD_PRINCIPAL = 1;
    end if;

    if AddressId is null then
      select min(PAC_ADDRESS_ID)
        into AddressId
        from PAC_ADDRESS
           , DIC_ADDRESS_TYPE
       where PAC_ADDRESS.PAC_PERSON_ID = aPAC_PERSON_ID
         and PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID
         and DIC_ADDRESS_TYPE.DAD_DEFAULT = 1;
    end if;

    if AddressId is null then
      select min(PAC_ADDRESS_ID)
        into AddressId
        from PAC_ADDRESS
       where PAC_PERSON_ID = aPAC_PERSON_ID;
    end if;

    if AddressId is not null then
      select PAC_ADDRESS.ADD_ADDRESS1
           , PAC_ADDRESS.ADD_ZIPCODE
           , PAC_ADDRESS.ADD_CITY
           , PAC_ADDRESS.ADD_FORMAT
           , PC_CNTRY.CNTID
           , PC_CNTRY.PC_CNTRY_ID
           , PAC_ADDRESS.ADD_STATE
           , PAC_ADDRESS.ADD_PO_BOX
           , PAC_ADDRESS.ADD_PO_BOX_NBR
           , PAC_ADDRESS.ADD_COUNTY
           , PAC_ADDRESS.ADD_CARE_OF
        into Address1
           , ZipCode
           , City
           , Addformat
           , Cntry
           , CntryId
           , State
           , PoBox
           , PoBoxNbr
           , County
           , CareOf
        from PAC_ADDRESS
           , PCS.PC_CNTRY
       where PAC_ADDRESS.PAC_ADDRESS_ID = AddressId
         and PC_CNTRY.PC_CNTRY_ID = PAC_ADDRESS.PC_CNTRY_ID;
    else
      Address1   := '';
      ZipCode    := '';
      City       := '';
      AddFormat  := '';
      Cntry      := '';
      CntryId    := null;
      State      := '';
      PoBox      := '';
      PoBoxNbr   := '';
      County     := '';
      CareOf     := '';
    end if;

    if aField = 0 then
      return Address1;
    elsif aField = 1 then
      return ZipCode;
    elsif aField = 2 then
      return City;
    elsif aField = 3 then
      return Addformat;
    elsif aField = 4 then
      return Cntry;
    elsif aField = 5 then
      return CntryId;
    elsif aField = 6 then
      return State;
    elsif aField = 7 then
      return PoBox;
    elsif aField = 8 then
      return PoBoxNbr;
    elsif aField = 9 then
      return County;
    elsif aField = 10 then
      return CareOf;
    else
      return null;
    end if;
  end GetAddressForPaiement;

-----------------------
  function GetCoverSExpiryUsed(
    aACT_COVER_INFORMATION_ID ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type
  , aACT_EXPIRY_ID            ACT_EXPIRY.ACT_EXPIRY_ID%type
  )
    return number
  is
    State ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type;
  begin
    select max(ACT_COVER_INFORMATION_ID)
      into State
      from ACT_COVER_S_EXPIRY
     where ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and ACT_COVER_INFORMATION_ID = aACT_COVER_INFORMATION_ID;

    if State is null then
      return 0;
    else
      return 1;
    end if;
  end GetCoverSExpiryUsed;

-----------------------
-- Renvoie si l'info couverture est associé à un document
  function GetCoverInDoc(aACT_COVER_INFORMATION_ID ACT_COVER_INFORMATION.ACT_COVER_INFORMATION_ID%type)
    return number
  is
    State ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
  begin
    select max(ACT_DOCUMENT_ID)
      into State
      from ACT_COV_INFO_S_DOCUMENT
     where ACT_COVER_INFORMATION_ID = aACT_COVER_INFORMATION_ID;

    if State is null then
      return 0;
    else
      return 1;
    end if;
  end GetCoverInDoc;

  /**
  * Test si l'utilisateur aPC_USER_ID est autorisé à utilisée les type de travaux aACJ_JOB_TYPE
  * 0 -> faux  1 -> vrai
  */
  function IsUserAutorizedForJobType(aPC_USER_ID number, aACJ_JOB_TYPE_ID number)
    return number
  is
    UseId ACJ_AUTORIZED_JOB_TYPE.PC_USER_ID%type;
  begin
    select max(ACJ_AUTORIZED_JOB_TYPE.PC_USER_ID)
      into UseId
      from ACJ_AUTORIZED_JOB_TYPE
     where ACJ_AUTORIZED_JOB_TYPE.ACJ_JOB_TYPE_ID = aACJ_JOB_TYPE_ID
       and (   ACJ_AUTORIZED_JOB_TYPE.PC_USER_ID = aPC_USER_ID
            or exists(select USE_GROUP_ID
                        from PCS.PC_USER_GROUP
                       where PC_USER_ID = aPC_USER_ID
                         and USE_GROUP_ID = ACJ_AUTORIZED_JOB_TYPE.PC_USER_ID)
           )
       and rownum = 1;

    if UseId is not null then
      return 1;
    else
      return 0;
    end if;
  end IsUserAutorizedForJobType;

------------------------
  function GetPreDataEntry(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return ACJ_JOB_TYPE.TYP_SUPPLIER_PERMANENT%type
  is
    TypSupplierPermanent ACJ_JOB_TYPE.TYP_SUPPLIER_PERMANENT%type;
  begin
    begin
      select max(TYP_SUPPLIER_PERMANENT)
        into TypSupplierPermanent
        from ACJ_JOB_TYPE TYP
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID;
    exception
      when no_data_found then
        TypSupplierPermanent  := null;
    end;

    if TypSupplierPermanent is null then
      TypSupplierPermanent  := 0;
    end if;

    return TypSupplierPermanent;
  end GetPreDataEntry;

--------------------------------
  function NormalizeAdherentNumber(aNumAdh PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type)
    return PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type
  is
    Temp   PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type;
    result PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%type;
  begin
    Temp    := aNumAdh;
    Temp    := replace(Temp, ' ', '');
    result  := Temp;

    if instr(Temp, '-') <> 0 then
      result  := lpad(substr(Temp, 1, instr(Temp, '-') - 1), 2, '0');
      Temp    := substr(Temp, instr(Temp, '-') + 1);
      result  := result || lpad(substr(Temp, 1, instr(Temp, '-') - 1), 6, '0');
      Temp    := substr(Temp, instr(Temp, '-') + 1);
      result  := result || Temp;
    end if;

    return result;
  end NormalizeAdherentNumber;

--------------------
  function GetCumulTyp(
    aACJ_CATALOGUE_DOCUMENT_ID ACJ_SUB_SET_CAT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aC_SUB_SET                 ACJ_SUB_SET_CAT.C_SUB_SET%type
  )
    return ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  is
    CumulTyp ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type;
  begin
    select max(C_TYPE_CUMUL)
      into CumulTyp
      from ACJ_SUB_SET_CAT
     where ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
       and C_SUB_SET = aC_SUB_SET;

    return CumulTyp;
  end GetCumulTyp;

---------------------------------
  function AuxAccountFromImputation(
    aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  )
    return ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  is
    AuxAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    begin
      select nvl(IMP.IMF_ACS_AUX_ACCOUNT_CUST_ID, IMP.IMF_ACS_AUX_ACCOUNT_SUPP_ID)
        into AuxAccountId
        from ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;
    exception
      when no_data_found then
        AuxAccountId  := null;
    end;

    return AuxAccountId;
  end AuxAccountFromImputation;

---------------------------------
  function FirstMGMImputation(aACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type)
    return ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  is
    MGMImputationId ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin
    begin
      select ACT_MGM_IMPUTATION_ID
        into MGMImputationId
        from ACT_MGM_IMPUTATION
       where ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
         and rownum = 1;
    exception
      when no_data_found then
        MGMImputationId  := null;
    end;

    return MGMImputationId;
  end FirstMGMImputation;

---------------------------------
  function FirstMGMDistribution(aACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type)
    return ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type
  is
    MGMDistributionId ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
  begin
    if aACT_MGM_IMPUTATION_ID is not null then
      begin
        select ACT_MGM_DISTRIBUTION_ID
          into MGMDistributionId
          from ACT_MGM_DISTRIBUTION
         where ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID = aACT_MGM_IMPUTATION_ID
           and rownum = 1;
      exception
        when no_data_found then
          MGMDistributionId  := null;
      end;
    else
      MGMDistributionId  := null;
    end if;

    return MGMDistributionId;
  end FirstMGMDistribution;

-----------------------
  function GetDocCharCode(
    aACT_DOCUMENT_ID          ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDIC_CHAR_DOC_CODE_TYP_ID DIC_CHAR_DOC_CODE_TYP.DIC_CHAR_DOC_CODE_TYP_ID%type
  )
    return ACT_DOC_CHAR_CODE.DCH_CODE%type
  is
    Code ACT_DOC_CHAR_CODE.DCH_CODE%type   default null;
  begin
    begin
      select DCH_CODE
        into Code
        from ACT_DOC_CHAR_CODE
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DIC_CHAR_DOC_CODE_TYP_ID = aDIC_CHAR_DOC_CODE_TYP_ID;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDocCharCode;

--------------------------
  function GetDocBooleanCode(
    aACT_DOCUMENT_ID          ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDIC_BOOL_DOC_CODE_TYP_ID DIC_BOOL_DOC_CODE_TYP.DIC_BOOL_DOC_CODE_TYP_ID%type
  )
    return ACT_DOC_BOOLEAN_CODE.DBO_CODE%type
  is
    Code ACT_DOC_BOOLEAN_CODE.DBO_CODE%type   default null;
  begin
    begin
      select DBO_CODE
        into Code
        from ACT_DOC_BOOLEAN_CODE
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DIC_BOOL_DOC_CODE_TYP_ID = aDIC_BOOL_DOC_CODE_TYP_ID;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDocBooleanCode;

-------------------------
  function GetDocNumberCode(
    aACT_DOCUMENT_ID         ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDIC_NUM_DOC_CODE_TYP_ID DIC_NUM_DOC_CODE_TYP.DIC_NUM_DOC_CODE_TYP_ID%type
  )
    return ACT_DOC_NUMBER_CODE.DNU_CODE%type
  is
    Code ACT_DOC_NUMBER_CODE.DNU_CODE%type   default null;
  begin
    begin
      select DNU_CODE
        into Code
        from ACT_DOC_NUMBER_CODE
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DIC_NUM_DOC_CODE_TYP_ID = aDIC_NUM_DOC_CODE_TYP_ID;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDocNumberCode;

-----------------------
  function GetDocDateCode(
    aACT_DOCUMENT_ID          ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDIC_DATE_DOC_CODE_TYP_ID DIC_DATE_DOC_CODE_TYP.DIC_DATE_DOC_CODE_TYP_ID%type
  )
    return TChardate
  is
    Code TChardate(8) default null;
  begin
    begin
      select to_char(DDA_CODE, 'yyyymmdd')
        into Code
        from ACT_DOC_DATE_CODE
       where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DIC_DATE_DOC_CODE_TYP_ID = aDIC_DATE_DOC_CODE_TYP_ID;
    exception
      when others then
        Code  := null;
    end;

    return Code;
  end GetDocDateCode;

--------------------------------
  function GetDuplicateParDocument(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  is
    More        boolean                                            default true;
    CustomerId  ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
    SupplierId  ACT_PART_IMPUTATION.PAC_SUPPLIER_PARTNER_ID%type;
    ParDocument ACT_PART_IMPUTATION.PAR_DOCUMENT%type;
    YearId      ACT_DOCUMENT.ACS_FINANCIAL_YEAR_ID%type;
    DocumentId  ACT_DOCUMENT.ACT_DOCUMENT_ID%type                  default null;
  begin
    begin
      select PAC_CUSTOM_PARTNER_ID
           , PAC_SUPPLIER_PARTNER_ID
           , PAR_DOCUMENT
           , ACS_FINANCIAL_YEAR_ID
        into CustomerId
           , SupplierId
           , ParDocument
           , YearId
        from ACT_PART_IMPUTATION PAR
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID;
    exception
      when others then
        More  := false;
    end;

    if More then
      begin
        if CustomerId is not null then
          select max(PAR.ACT_DOCUMENT_ID)
            into DocumentId
            from ACT_DOCUMENT DOC
               , ACT_PART_IMPUTATION PAR
           where nvl(PAR.PAR_DOCUMENT, ' ') = nvl(ParDocument, ' ')
             and PAR.PAC_CUSTOM_PARTNER_ID = CustomerId
             and PAR.ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID
             and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACS_FINANCIAL_YEAR_ID = YearId;
        else
          select max(PAR.ACT_DOCUMENT_ID)
            into DocumentId
            from ACT_DOCUMENT DOC
               , ACT_PART_IMPUTATION PAR
           where nvl(PAR.PAR_DOCUMENT, ' ') = nvl(ParDocument, ' ')
             and PAR.PAC_SUPPLIER_PARTNER_ID = SupplierId
             and PAR.ACT_DOCUMENT_ID <> aACT_DOCUMENT_ID
             and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
             and DOC.ACS_FINANCIAL_YEAR_ID = YearId;
        end if;
      exception
        when others then
          DocumentId  := null;
      end;
    end if;

    return DocumentId;
  end GetDuplicateParDocument;

---------------------------
---------------------------
  function GetTransactionDate(
    aACT_DOCUMENT_ID       ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , aACS_PERIOD_ID         ACS_PERIOD.ACS_PERIOD_ID%type
  )
    return ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  is
    TransactionDate ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
    result          ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type;
  begin
    select max(IMF_TRANSACTION_DATE)
      into TransactionDate
      from ACT_FINANCIAL_IMPUTATION
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and IMF_PRIMARY = 1;

    -- Période restrictive pour le travail comptable
    if     aACS_PERIOD_ID is not null
       and aACS_PERIOD_ID > 0 then
      select max(TransactionDate)
        into result
        from acs_period per
           , acs_financial_year year
           , acj_catalogue_document cat
           , act_document doc
       where cat.c_type_period = per.c_type_period
         and doc.act_document_id = aact_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and year.acs_financial_year_id = per.acs_financial_year_id
         and per.c_state_period = 'ACT'
         and year.acs_financial_year_id = aacs_financial_year_id
         and TransactionDate between per.per_start_date and per.per_end_date
         and per.acs_period_id = aacs_period_id;
    else
      select max(TransactionDate)
        into result
        from acs_period per
           , acs_financial_year year
           , acj_catalogue_document cat
           , act_document doc
       where cat.c_type_period = per.c_type_period
         and doc.act_document_id = aact_document_id
         and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and year.acs_financial_year_id = per.acs_financial_year_id
         and per.c_state_period = 'ACT'
         and year.acs_financial_year_id = aacs_financial_year_id
         and TransactionDate between per.per_start_date and per.per_end_date;
    end if;

    if result is null then
      -- Période restrictive pour le travail comptable
      if     aACS_PERIOD_ID is not null
         and aACS_PERIOD_ID > 0 then
        select min(per.per_start_date)
          into result
          from acs_period per
             , acs_financial_year year
             , acj_catalogue_document cat
             , act_document doc
         where cat.c_type_period = per.c_type_period
           and doc.act_document_id = aact_document_id
           and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
           and year.acs_financial_year_id = per.acs_financial_year_id
           and per.c_state_period = 'ACT'
           and year.acs_financial_year_id = aacs_financial_year_id
           and per.per_start_date >= TransactionDate
           and per.acs_period_id = aacs_period_id;
      else
        select min(per.per_start_date)
          into result
          from acs_period per
             , acs_financial_year year
             , acj_catalogue_document cat
             , act_document doc
         where cat.c_type_period = per.c_type_period
           and doc.act_document_id = aact_document_id
           and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
           and year.acs_financial_year_id = per.acs_financial_year_id
           and per.c_state_period = 'ACT'
           and year.acs_financial_year_id = aacs_financial_year_id
           and per.per_start_date >= TransactionDate;
      end if;

      if result is null then
        if     aACS_PERIOD_ID is not null
           and aACS_PERIOD_ID > 0 then
          select max(per.per_end_date)
            into result
            from acs_period per
               , acs_financial_year year
               , acj_catalogue_document cat
               , act_document doc
           where cat.c_type_period = per.c_type_period
             and doc.act_document_id = aact_document_id
             and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
             and year.acs_financial_year_id = per.acs_financial_year_id
             and per.c_state_period = 'ACT'
             and year.acs_financial_year_id = aacs_financial_year_id
             and per.per_end_date <= TransactionDate
             and per.acs_period_id = aacs_period_id;
        else
          select max(per.per_end_date)
            into result
            from acs_period per
               , acs_financial_year year
               , acj_catalogue_document cat
               , act_document doc
           where cat.c_type_period = per.c_type_period
             and doc.act_document_id = aact_document_id
             and doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
             and year.acs_financial_year_id = per.acs_financial_year_id
             and per.c_state_period = 'ACT'
             and year.acs_financial_year_id = aacs_financial_year_id
             and per.per_end_date <= TransactionDate;
        end if;
      end if;
    end if;

    return result;
  end GetTransactionDate;

---------------------------
  function GetValueDate(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  is
    result ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
  begin
    select max(IMF_VALUE_DATE)
      into result
      from ACT_FINANCIAL_IMPUTATION
     where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
       and IMF_PRIMARY = 1;

    return result;
  end GetValueDate;

-----------------------
  function ExpiriesAmount(
    aACS_AUXILIARY_ACCOUNT_ID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , aC_TYPE_CUMUL              ACJ_SUB_SET_CAT.C_TYPE_CUMUL%type
  , aDateStr                   varchar2
  )
    return ACT_EXPIRY.EXP_AMOUNT_LC%type
  is
    LocalCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    CurrencyId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    ExpAdapted      ACT_EXPIRY.EXP_ADAPTED%type;
    AmountLC        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    AmountFC        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    Amount          ACT_EXPIRY.EXP_AMOUNT_LC%type;
    Typ1            varchar2(3)                                             default 'EXT';
    Typ2            varchar2(3)                                             default 'INT';
    Typ3            varchar2(3)                                             default '';
    Typ4            varchar2(3)                                             default '';
-----
  begin
    -- La variable package 'BRO' est utilisée par les fonctions TotalPayment(...) et TotalPaymentAt(...)
    ACT_FUNCTIONS.SetBRO(1);
    LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;

    if aACS_FINANCIAL_CURRENCY_ID is not null then
      CurrencyId  := aACS_FINANCIAL_CURRENCY_ID;
    else
      CurrencyId  := LocalCurrencyId;
    end if;

    begin
      ExpAdapted  := to_date(aDateStr, 'yyyymmdd');
    exception
      when others then
        ExpAdapted  := null;
    end;

    if aC_TYPE_CUMUL is not null then
      Typ1  := aC_TYPE_CUMUL;
      Typ2  := '';
      Typ3  := '';
      Typ4  := '';
    end if;

    if ExpAdapted is not null then
      if ACS_FUNCTION.GetSubSetOfAccount(aACS_AUXILIARY_ACCOUNT_ID) = 'REC' then
        select nvl(sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, ExpAdapted, 1) ), 0)
             , nvl(sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, ExpAdapted, 0) ), 0)
          into AmountLC
             , AmountFC
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
             , PAC_CUSTOM_PARTNER CUS
         where CUS.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
           and (   PAR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                or aACS_FINANCIAL_CURRENCY_ID is null)
           and PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.EXP_CALC_NET = 1
           and EXP_ADAPTED <= ExpAdapted
           and exists(
                 select DOC.rowid
                   from ACJ_CATALOGUE_DOCUMENT CAT
                      , ACJ_SUB_SET_CAT SCA
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'REC'
                    and SCA.C_TYPE_CUMUL in(Typ1, Typ2, Typ3, Typ4)
                    and CAT.C_TYPE_CATALOGUE <> '8');
      else
        select nvl(sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, ExpAdapted, 1) ), 0)
             , nvl(sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, ExpAdapted, 0) ), 0)
          into AmountLC
             , AmountFC
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
             , PAC_SUPPLIER_PARTNER SUP
         where SUP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
           and (   PAR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                or aACS_FINANCIAL_CURRENCY_ID is null)
           and PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.EXP_CALC_NET = 1
           and EXP_ADAPTED <= ExpAdapted
           and exists(
                 select DOC.rowid
                   from ACJ_CATALOGUE_DOCUMENT CAT
                      , ACJ_SUB_SET_CAT SCA
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'PAY'
                    and SCA.C_TYPE_CUMUL in(Typ1, Typ2, Typ3, Typ4)
                    and CAT.C_TYPE_CATALOGUE <> '8');
      end if;
    else
      if ACS_FUNCTION.GetSubSetOfAccount(aACS_AUXILIARY_ACCOUNT_ID) = 'REC' then
        select nvl(sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPayment(exp.ACT_EXPIRY_ID, 1) ), 0)
             , nvl(sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPayment(exp.ACT_EXPIRY_ID, 0) ), 0)
          into AmountLC
             , AmountFC
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
             , PAC_CUSTOM_PARTNER CUS
         where CUS.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
           and (   PAR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                or aACS_FINANCIAL_CURRENCY_ID is null)
           and PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.EXP_CALC_NET = 1
           and to_number(exp.C_STATUS_EXPIRY) = 0
           and exists(
                 select DOC.rowid
                   from ACJ_CATALOGUE_DOCUMENT CAT
                      , ACJ_SUB_SET_CAT SCA
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'REC'
                    and SCA.C_TYPE_CUMUL in(Typ1, Typ2, Typ3, Typ4)
                    and CAT.C_TYPE_CATALOGUE <> '8');
      else
        select nvl(sum(EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPayment(exp.ACT_EXPIRY_ID, 1) ), 0)
             , nvl(sum(EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPayment(exp.ACT_EXPIRY_ID, 0) ), 0)
          into AmountLC
             , AmountFC
          from ACT_EXPIRY exp
             , ACT_PART_IMPUTATION PAR
             , PAC_SUPPLIER_PARTNER SUP
         where SUP.ACS_AUXILIARY_ACCOUNT_ID = aACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
           and (   PAR.ACS_FINANCIAL_CURRENCY_ID = aACS_FINANCIAL_CURRENCY_ID
                or aACS_FINANCIAL_CURRENCY_ID is null)
           and PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and exp.EXP_CALC_NET = 1
           and to_number(exp.C_STATUS_EXPIRY) = 0
           and exists(
                 select DOC.rowid
                   from ACJ_CATALOGUE_DOCUMENT CAT
                      , ACJ_SUB_SET_CAT SCA
                      , ACT_DOCUMENT DOC
                  where DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                    and SCA.C_SUB_SET = 'PAY'
                    and SCA.C_TYPE_CUMUL in(Typ1, Typ2, Typ3, Typ4)
                    and CAT.C_TYPE_CATALOGUE <> '8');
      end if;
    end if;

    if CurrencyId = LocalCurrencyId then
      Amount  := AmountLC;
    else
      Amount  := AmountFC;
    end if;

    return Amount;
  end ExpiriesAmount;

  /**
  * Concaténation de aStart et aEnd avec coupure de aStart si total plus grand que aSize
  */
  function FormatDescription(aStart varchar2, aEnd varchar2, aSize numeric)
    return varchar2
  is
    StartSize numeric;
  begin
    StartSize  := aSize - length(aEnd);

    if length(aStart) <= StartSize then
      return aStart || aEnd;
    elsif StartSize - 3 <= 0 then
      return substr(aStart, 1, StartSize) || aEnd;
    else
      return substr(aStart, 1, StartSize - 3) || '...' || aEnd;
    end if;
  end FormatDescription;

-----------------------
  function GetAlternateFinRef(
    aPAC_SUPPLIER_PARTNER_ID    in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_FINANCIAL_REFERENCE_ID in PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  )
    return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  is
    cursor TYPE_REF(SuppPart PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    is
      select   PAC_FINANCIAL_REFERENCE_ID
             , C_TYPE_REFERENCE
          from PAC_FINANCIAL_REFERENCE
         where PAC_SUPPLIER_PARTNER_ID = SuppPart
           and C_PARTNER_STATUS <> '0'
      order by C_TYPE_REFERENCE asc;

    TYPE_REF_tuple TYPE_REF%rowtype;
    TypeRef        PAC_FINANCIAL_REFERENCE.C_TYPE_REFERENCE%type;
  begin
    if aPAC_FINANCIAL_REFERENCE_ID is null then
      return aPAC_FINANCIAL_REFERENCE_ID;
    else
      select max(C_TYPE_REFERENCE)
        into TypeRef
        from PAC_FINANCIAL_REFERENCE
       where PAC_FINANCIAL_REFERENCE_ID = aPAC_FINANCIAL_REFERENCE_ID;

      if     (TypeRef is not null)
         and (TypeRef != '3') then
        return aPAC_FINANCIAL_REFERENCE_ID;
      end if;
    end if;

    open TYPE_REF(aPAC_SUPPLIER_PARTNER_ID);

    fetch TYPE_REF
     into TYPE_REF_tuple;

    close TYPE_REF;

    return nvl(TYPE_REF_tuple.PAC_FINANCIAL_REFERENCE_ID, aPAC_FINANCIAL_REFERENCE_ID);
  end GetAlternateFinRef;

-----------------------
  function GetDefaultFinRef(aPAC_CUSTOM_PARTNER_ID in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  is
    cursor TYPE_REF(CustPart PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    is
      select   PAC_FINANCIAL_REFERENCE_ID
          from PAC_FINANCIAL_REFERENCE
         where PAC_CUSTOM_PARTNER_ID = CustPart
           and C_PARTNER_STATUS <> '0'
      order by FRE_DEFAULT desc
             , C_TYPE_REFERENCE asc;

    TYPE_REF_tuple TYPE_REF%rowtype;
  begin
    open TYPE_REF(aPAC_CUSTOM_PARTNER_ID);

    fetch TYPE_REF
     into TYPE_REF_tuple;

    close TYPE_REF;

    return TYPE_REF_tuple.PAC_FINANCIAL_REFERENCE_ID;
  end GetDefaultFinRef;

  function GetCollDivisionId(
    aACT_EXPIRY_ID   in ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aACT_DOCUMENT_ID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type default null
  , aPAC_PARTNER_ID  in PAC_PERSON.PAC_PERSON_ID%type default null
  )
    return ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  is
    result ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    if    (aACT_DOCUMENT_ID is null)
       or (aACT_DOCUMENT_ID = 0) then
      select min(imp.IMF_ACS_DIVISION_ACCOUNT_ID)
        into result
        from acs_financial_account fin
           , act_financial_imputation imp
           , act_expiry exp
       where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
         and imp.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
         and imp.ACT_PART_IMPUTATION_ID(+) = exp.ACT_PART_IMPUTATION_ID
         and imp.ACS_FINANCIAL_ACCOUNT_ID = fin.ACS_FINANCIAL_ACCOUNT_ID
         and imp.ACT_DET_PAYMENT_ID is null
         and fin.FIN_COLLECTIVE = 1;

      if result is null then
        select min(imp.IMF_ACS_DIVISION_ACCOUNT_ID)
          into result
          from acs_financial_account fin
             , act_financial_imputation imp
             , act_expiry exp2
             , act_reminder rem
             , act_expiry exp
         where exp.ACT_EXPIRY_ID = aACT_EXPIRY_ID
           and exp.ACT_PART_IMPUTATION_ID = rem.ACT_PART_IMPUTATION_ID
           and rem.ACT_EXPIRY_ID = exp2.ACT_EXPIRY_ID
           and imp.ACT_DOCUMENT_ID = exp2.ACT_DOCUMENT_ID
           and imp.ACT_PART_IMPUTATION_ID(+) = exp2.ACT_PART_IMPUTATION_ID
           and imp.ACS_FINANCIAL_ACCOUNT_ID = fin.ACS_FINANCIAL_ACCOUNT_ID
           and to_number(exp.C_STATUS_EXPIRY) + 0 = 9
           and imp.ACT_DET_PAYMENT_ID is null
           and fin.FIN_COLLECTIVE = 1;
      end if;
    else
      select min(imp.IMF_ACS_DIVISION_ACCOUNT_ID)
        into result
        from acs_financial_account fin
           , act_financial_imputation imp
       where imp.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and imp.ACT_PART_IMPUTATION_ID is not null
         and nvl(IMP.IMF_PAC_SUPPLIER_PARTNER_ID, IMP.IMF_PAC_CUSTOM_PARTNER_ID) = aPAC_PARTNER_ID
         and imp.ACS_FINANCIAL_ACCOUNT_ID = fin.ACS_FINANCIAL_ACCOUNT_ID
         and fin.FIN_COLLECTIVE = 1;

      if result is null then
        select min(imp.IMF_ACS_DIVISION_ACCOUNT_ID)
          into result
          from acs_financial_account fin
             , act_financial_imputation imp
         where imp.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
           and imp.ACS_FINANCIAL_ACCOUNT_ID = fin.ACS_FINANCIAL_ACCOUNT_ID
           and fin.FIN_COLLECTIVE = 1;
      end if;
    end if;

    return result;
  end;

  /**
  * Description
  *    Retour du document logistique à l'origine du document comptable
  **/
  function GET_DOC_DOCUMENT_ID(pDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  is
    cursor FinancialDocumentCursor
    is
      select DOC.DOC_DOCUMENT_ID
        from ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = pDocumentId;

    cursor LogisticDocumentCursor
    is
      select LDOC.DOC_DOCUMENT_ID
        from ACJ_JOB_TYPE TYP
           , ACT_JOB JOB
           , DOC_DOCUMENT LDOC
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = pDocumentId
         and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and TYP.C_ACI_FINANCIAL_LINK <> '1'
         and DOC.DOC_NUMBER = LDOC.DMT_NUMBER;

    vResult DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    /*Recherche du document logistique dans le document financier*/
    open FinancialDocumentCursor;

    fetch FinancialDocumentCursor
     into vResult;

    if vResult is null then
      /*Recherche du document logistique par le n° document*/
      open LogisticDocumentCursor;

      fetch LogisticDocumentCursor
       into vResult;

      close LogisticDocumentCursor;
    end if;

    close FinancialDocumentCursor;

    return vResult;
  end GET_DOC_DOCUMENT_ID;

  /**
  * Description
  *    Retour du document logistique à l'origine du document comptable
  **/
  procedure GET_DOC_DOCUMENT_ID(
    aACT_DOCUMENT_ID     ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aDOC_DOCUMENT_ID out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aCOM_NAME_DOC    out ACT_DOCUMENT.COM_NAME_DOC%type
  )
  is
    vDocNumber  ACT_DOCUMENT.DOC_NUMBER%type;
    vComNameDOC ACT_DOCUMENT.COM_NAME_DOC%type;
    vComNameACT ACT_DOCUMENT.COM_NAME_ACT%type;
    vSql_code   varchar2(200);
    vDBOwner    PCS.PC_SCRIP.SCRDBOWNER%type     := null;
    vDBLink     PCS.PC_SCRIP.SCRDB_LINK%type     := null;
  begin
    aCOM_NAME_DOC     := null;
    aDOC_DOCUMENT_ID  := 0;

    /*Recherche du document logistique dans le document financier*/
    select min(DOC.DOC_DOCUMENT_ID)
         , min(DOC.COM_NAME_DOC)
      into aDOC_DOCUMENT_ID
         , vComNameDOC
      from ACT_DOCUMENT DOC
     where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;

    --Recherche société courante
    select COM_NAME
      into vComNameACT
      from PCS.PC_COMP
     where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

    --Recherche des info de connexion si document sur une autre société
    if not(    (vComNameDOC = vComNameACT)
           or vComNameDOC is null) then
      select PC_SCRIP.SCRDBOWNER
           , PC_SCRIP.SCRDB_LINK
        into vDBOwner
           , vDBLink
        from PCS.PC_SCRIP
           , PCS.PC_COMP
       where PC_SCRIP.PC_SCRIP_ID = PC_COMP.PC_SCRIP_ID
         and PC_COMP.COM_NAME = vComNameDOC;

      aCOM_NAME_DOC  := vDBOwner;

      if vDBLink is not null then
        vDBLink  := '@' || vDBLink;
      end if;

      if vDBOwner is not null then
        vDBOwner  := vDBOwner || '.';
      end if;
    end if;

    -- Si pas d'id recherche du document en fonction de son numéro
    if aDOC_DOCUMENT_ID is null then
      --Recherche numéro document
      select min(DOC.DOC_NUMBER)
        into vDocNumber
        from ACJ_JOB_TYPE TYP
           , ACT_JOB JOB
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and TYP.C_ACI_FINANCIAL_LINK != '1';

      --Si pas de num document on quitte
      if vDocNumber is null then
        return;
      end if;

      /*Recherche du document logistique par le n° document*/
      vSql_code  :=
        'select min(DOC_DOCUMENT_ID) ' ||
        '  from [COMPANY_OWNER_2]DOC_DOCUMENT[COMPANY_DBLINK_2] ' ||
        ' where DMT_NUMBER = :DocNumber';
      vSql_code  := replace(vSql_code, '[COMPANY_OWNER_2]', vDBOwner);
      vSql_code  := replace(vSql_code, '[COMPANY_DBLINK_2]', vDBLink);

      execute immediate vSql_code
                   into aDOC_DOCUMENT_ID
                  using in vDocNumber;
    end if;
  end GET_DOC_DOCUMENT_ID;

  /**
  * Description
  *    Indique si le document donné contient des imputations partenair (True) ou non(False)
  **/
  function DocumentHasPartImputation(pDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return boolean
  is
    vResult           boolean                                           default false;
    vPartImputationId ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
  begin
    select max(ACT_PART_IMPUTATION_ID)
      into vPartImputationId
      from ACT_PART_IMPUTATION
     where ACT_DOCUMENT_ID = pDocumentId;

    vResult  :=(vPartImputationId is not null);
    return vResult;
  end DocumentHasPartImputation;

  /**
  * Description
  *    Retour du type de période géré dans le catalogue transaction donné
  **/
  function GetCatalogueTypePeriod(pCatalogueId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
    return ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type
  is
    vResult ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
  begin
    begin
      select C_TYPE_PERIOD
        into vResult
        from ACJ_CATALOGUE_DOCUMENT
       where ACJ_CATALOGUE_DOCUMENT_ID = pCatalogueId;
    exception
      when others then
        vResult  := null;
    end;

    return vResult;
  end GetCatalogueTypePeriod;

  /**
  * Description
  *   Initialisation de l'exercice comptable pour la vue V_ACT_TOT_BY_PER_ALL
  */
  procedure SetV_TOT_PER_ALL_ACS_YEAR_ID(pACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin
    V_TOT_PER_ALL_ACS_YEAR_ID  := pACS_FINANCIAL_YEAR_ID;
  end SetV_TOT_PER_ALL_ACS_YEAR_ID;

  /**
  * Description
  *    Retour de l'exercice comptable pour la vue V_ACT_TOT_BY_PER_ALL
  **/
  function GetV_TOT_PER_ALL_ACS_YEAR_ID
    return ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  is
  begin
    return V_TOT_PER_ALL_ACS_YEAR_ID;
  end GetV_TOT_PER_ALL_ACS_YEAR_ID;

  /**
  * Description
  *    Retourne l'état du flag 'date valeur = date document' pour le type de travail.
  **/
  function GetValDateIsDocDate(aACJ_JOB_TYPE_ID ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type)
    return ACJ_EVENT.EVE_VAL_DATE_BY_DOC_DATE%type
  is
    vResult ACJ_EVENT.EVE_VAL_DATE_BY_DOC_DATE%type;
  begin
    select nvl(max(EVE_VAL_DATE_BY_DOC_DATE), 0)
      into vResult
      from ACJ_EVENT EVE
     where EVE.ACJ_JOB_TYPE_ID = aACJ_JOB_TYPE_ID
       and EVE.C_TYPE_EVENT = '1';

    return vResult;
  end GetValDateIsDocDate;

  /**
  * Description
  *    Retour du montant encore provisionné pour document et date donné
  **/
  function GetProvTaxAmountDoc(pDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type, pDate varchar2)
    return ACT_EXPIRY.EXP_AMOUNT_PROV_LC%type
  is
    vTaxProvAmount  ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vTaxPaiedAmount ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vResult         ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
  begin
    vTaxProvAmount   := 0;
    vTaxPaiedAmount  := 0;

    /*Réception du montant Tva provision */
    begin
      select nvl(sum(nvl(VAT.TAX_VAT_AMOUNT_LC, 0) ), 0)
        into vTaxProvAmount
        from ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_TAX VAT
       where IMP.ACT_DOCUMENT_ID = pDocumentId
         and IMP.ACT_FINANCIAL_IMPUTATION_ID = VAT.ACT_FINANCIAL_IMPUTATION_ID
         and VAT.TAX_TMP_VAT_ENCASHMENT = 1;
    exception
      when no_data_found then
        vTaxProvAmount  := 0;
    end;

    /*Réception du montant Tva encaissé selon document */
    begin
      select nvl(sum(nvl(VAT.TAX_VAT_AMOUNT_LC, 0) ), 0)
        into vTaxPaiedAmount
        from ACT_FINANCIAL_IMPUTATION IMF
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_DET_TAX DET
           , ACT_DET_TAX VAT
       where IMP.ACT_DOCUMENT_ID = pDocumentId
         and to_char(IMF.IMF_VALUE_DATE, 'YYYYMMDD') <= pDate
         and VAT.ACT2_DET_TAX_ID(+) = DET.ACT_DET_TAX_ID
         and VAT.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID(+)
         and DET.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
         and nvl(VAT.TAX_TMP_VAT_ENCASHMENT, 0) = 1;
    exception
      when no_data_found then
        vTaxPaiedAmount  := 0;
    end;

    vResult          := sign(vTaxProvAmount) *(abs(vTaxProvAmount) - abs(vTaxPaiedAmount) );
    return vResult;
  end GetProvTaxAmountDoc;

  /**
  * Description
  *    Retour du montant encore provisionné pour détail taxe et date donnés
  **/
  function GetProvTaxAmountDet(pDetTaxId ACT_DET_TAX.ACT_DET_TAX_ID%type, pDate varchar2)
    return ACT_EXPIRY.EXP_AMOUNT_PROV_LC%type
  is
    vResult ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
  begin
    select sign(PROV.TAX_VAT_AMOUNT_LC) *
           (abs(nvl(PROV.TAX_VAT_AMOUNT_LC, 0) ) -
            (select nvl(abs(sum(DEF.TAX_VAT_AMOUNT_LC) ), 0)
               from ACT_DET_TAX DET
                  , ACT_DET_TAX DEF
                  , ACT_FINANCIAL_IMPUTATION IMF
              where DEF.ACT2_DET_TAX_ID = DET.ACT_DET_TAX_ID
                and PROV.ACT_FINANCIAL_IMPUTATION_ID = DET.ACT_FINANCIAL_IMPUTATION_ID
                and DEF.ACT_FINANCIAL_IMPUTATION_ID = IMF.ACT_FINANCIAL_IMPUTATION_ID
                and DEF.TAX_TMP_VAT_ENCASHMENT = '1'
                and to_char(IMF.IMF_VALUE_DATE, 'YYYYMMDD') <= pDate)
           )
      into vResult
      from ACT_DET_TAX PROV
     where PROV.ACT_DET_TAX_ID = pDetTaxId
       and PROV.TAX_TMP_VAT_ENCASHMENT = 1;

    return vResult;
  end GetProvTaxAmountDet;

  /**
  * Description
  *    Retour de la date à laquelle la provision a été totalement 'extournée'
  **/
  function GetProvTaxDateImp(pDetTaxId ACT_DET_TAX.ACT_DET_TAX_ID%type)
    return ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  is
    vTaxProvAmount  ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vTaxPaiedAmount ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
    vResult         ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type;
  begin
    select decode(nvl(sum(PROV.TAX_VAT_AMOUNT_LC), 0) + nvl(sum(DEF.TAX_VAT_AMOUNT_LC), 0)
                , 0, max(to_char(DEF.IMF_VALUE_DATE, 'YYYYMMDD') )
                 )
      into vResult
      from V_ACT_DET_TAX PROV
         , V_ACT_DET_TAX DEF
     where PROV.ACT_FINANCIAL_IMPUTATION_ID = DEF.ACT_FIN_IMPUT_ORIGIN_ID(+)
       and PROV.ACT_DET_TAX_ID = pDetTaxId
       and PROV.TAX_TMP_VAT_ENCASHMENT = 1
       and nvl(DEF.TAX_TMP_VAT_ENCASHMENT, 0) = 1;

    return vResult;
  end GetProvTaxDateImp;

  /**
  * Description
  *    Retour du montant des cumuls MGM selon une paire (CPN-CDA, CPN-PF, CPN-PJ) + Quantité pour un exercice comptable
       avec filtre sur les périodes + type de cumuls
  **/
  function GetMGMAmount(
    pACS_ACCOUNT_ID1       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_ACCOUNT_ID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_QTY_UNIT_ID       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , pACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPeriodFrom            ACS_PERIOD.PER_NO_PERIOD%type
  , pPeriodTo              ACS_PERIOD.PER_NO_PERIOD%type
  , pPri                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSec                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSim                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pPre                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pEng                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pGetAmount             varchar2
  )
    return ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  is
    vCPN_ID ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    vCDA_ID ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type;
    vPF_ID  ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type;
    vPJ_ID  ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type;
    vQTY_ID ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    vAmount ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type;

    function SetAccountID(aACS_ACCOUNT_ID ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
      return boolean
    is
      vResult boolean                      default true;
      vSubSet ACS_SUB_SET.C_SUB_SET%type;
    begin
      if aACS_ACCOUNT_ID is not null then
        vSubSet  := ACS_FUNCTION.GetSubSetOfAccount(aACS_ACCOUNT_ID);

        if vSubSet = 'CPN' then
          vCPN_ID  := aACS_ACCOUNT_ID;
        elsif vSubSet = 'CDA' then
          vCDA_ID  := aACS_ACCOUNT_ID;
        elsif vSubSet = 'COS' then
          vPF_ID  := aACS_ACCOUNT_ID;
        elsif vSubSet = 'PRO' then
          vPJ_ID  := aACS_ACCOUNT_ID;
        elsif vSubSet = 'QTU' then
          vQTY_ID  := aACS_ACCOUNT_ID;
        else
          vResult  := false;
        end if;
      end if;

      return vResult;
    end SetAccountID;
  begin
    vCPN_ID  := -1;
    vCDA_ID  := -1;
    vPF_ID   := -1;
    vPJ_ID   := -1;
    vQTY_ID  := -1;
    vAmount  := 0;

    if     SetAccountID(pACS_ACCOUNT_ID1)
       and SetAccountID(pACS_ACCOUNT_ID2)
       and SetAccountID(pACS_QTY_UNIT_ID) then
      select decode(pGetAmount
                  , 1, nvl(sum(TOT.MTO_DEBIT_LC - TOT.MTO_CREDIT_LC), 0)
                  , 2, nvl(sum(TOT.MTO_QUANTITY_D - TOT.MTO_QUANTITY_C), 0)
                  , 0
                   ) AMOUNT
        into vAmount
        from ACT_MGM_TOT_BY_PERIOD TOT
           , ACS_PERIOD PER
       where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
         and PER.PER_NO_PERIOD >= pPeriodFrom
         and PER.PER_NO_PERIOD <= pPeriodTo
         and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
         and TOT.C_TYPE_CUMUL in(pPri, pSec, pSim, pPre, pEng)
         and TOT.ACS_CPN_ACCOUNT_ID = vCPN_ID
         and nvl(TOT.ACS_CDA_ACCOUNT_ID, 0) = decode(vCDA_ID, -1, nvl(TOT.ACS_CDA_ACCOUNT_ID, 0), vCDA_ID)
         and nvl(TOT.ACS_PF_ACCOUNT_ID, 0) = decode(vPF_ID, -1, nvl(TOT.ACS_PF_ACCOUNT_ID, 0), vPF_ID)
         and nvl(TOT.ACS_PJ_ACCOUNT_ID, 0) = decode(vPJ_ID, -1, nvl(TOT.ACS_PJ_ACCOUNT_ID, 0), vPJ_ID)
         and nvl(TOT.ACS_QTY_UNIT_ID, 0) = decode(vQTY_ID, -1, 0, vQTY_ID);
    end if;

    return vAmount;
  end GetMgmAmount;

  /**
  * function GetImpAmount
  * Description
  *   Calcul du montant des imputations à afficher selon le côté du montant le plus élevé => une colonne =0 et l'autre est diminuée du petit montant
  */
  function GetImpAmount(pACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type, pPartnerTyp varchar2, pAmountTyp varchar2)
    return ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  is
    vResult ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
  begin
    begin
      if pPartnerTyp = 'REC' then
        select decode(pAmountTyp
                    , 'D_MB', decode(sign(sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C)
                                    )
                    , 'C_MB', decode(sign(sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D)
                                    )
                    , 'D_ME', decode(sign(sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C)
                                    )
                    , 'C_ME', decode(sign(sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D)
                                    )
                    , 0
                     )
          into vResult
          from V_ACT_REC_IMP_REPORT V
             , ACT_ETAT_JOURNAL ETA
         where V.ACT_DOCUMENT_ID = pACT_DOCUMENT_ID
           and V.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID(+)
           and nvl(ETA.C_SUB_SET, 'ACC') = 'ACC';
      elsif pPartnerTyp = 'PAY' then
        select decode(pAmountTyp
                    , 'D_MB', decode(sign(sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C)
                                    )
                    , 'C_MB', decode(sign(sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D)
                                    )
                    , 'D_ME', decode(sign(sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C)
                                    )
                    , 'C_ME', decode(sign(sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D)
                                    )
                    , 0
                     )
          into vResult
          from V_ACT_PAY_IMP_REPORT V
             , ACT_ETAT_JOURNAL ETA
         where V.ACT_DOCUMENT_ID = pACT_DOCUMENT_ID
           and V.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID(+)
           and nvl(ETA.C_SUB_SET, 'ACC') = 'ACC';
      elsif pPartnerTyp = 'THIRD' then
        select decode(pAmountTyp
                    , 'D_MB', decode(sign(sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_D - V.IMF_AMOUNT_LC_C)
                                    )
                    , 'C_MB', decode(sign(sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_LC_C - V.IMF_AMOUNT_LC_D)
                                    )
                    , 'D_ME', decode(sign(sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_D - V.IMF_AMOUNT_FC_C)
                                    )
                    , 'C_ME', decode(sign(sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D) )
                                   , -1, 0
                                   , sum(V.IMF_AMOUNT_FC_C - V.IMF_AMOUNT_FC_D)
                                    )
                    , 0
                     )
          into vResult
          from V_ACT_THIRD_IMP_REPORT V
         where V.ACT_DOCUMENT_ID = pACT_DOCUMENT_ID;
      end if;
    exception
      when others then
        vResult  := 0;
    end;

    return vResult;
  end GetImpAmount;

  /**
  * function SequenceToAlpha
  * Description
  *   Conversion d'un nombre dans un format alphabétique selon le nombre de position spécifiée:
  *   ex: si aPosition = 1 : 0 -> A, 1 -> B, 25 -> Z, 26 -> BA, 27 -> BB
  *       si aPosition = 4 : 0 -> AAAA, 1 -> AAAB, 25 -> AAAZ, 26 -> AABA, 27 -> AABB
  */
  function SequenceToAlpha(aValue in number, aPosition in integer)
    return varchar2
  is
    tmpVal number;
    caract integer;
    result varchar2(30);
  begin
    if aPosition < 1 then
      return null;
    end if;

    tmpVal  := aValue;

    begin
      while tmpVal > 0 loop
        caract  := mod(tmpVal, 26) + 65;
        tmpVal  := floor(tmpVal / 26);
        result  := chr(caract) || result;
      end loop;
    exception
      when value_error then   --lorsque le résultat dépasse 30 caractères. Pour s'en rendre compte, tester avec 30x'Z'
        return null;
    end;

    if nvl(length(result), 0) > aPosition then
      result  := null;
    elsif nvl(length(result), 0) < aPosition then
      result  := lpad(nvl(result, 'A'), aPosition, 'A');
    end if;

    return result;
  end SequenceToAlpha;

  /**
  * function AlphaToSequence
  * Description
  *   Conversion d'une sequence alphabétique en nombre :
  *   ex: A -> 0, B -> 1, Z -> 25, BA -> 26, BB -> 27
  *  ATTENTION: Z = AZ = AAAAZ -> 25, A = AA = AAAA... -> 0
  */
  function AlphaToSequence(aValue in varchar2)
    return number
  is
    mul    number;
    result number := 0;
  begin
    if aValue is null then
      return null;
    end if;

    mul  := 0;

    while mul < length(aValue) loop
      result  := result + (ascii(substr(aValue, -mul - 1, 1) ) - 65) *(26 ** mul);
      mul     := mul + 1;
    end loop;

    return result;
  end AlphaToSequence;

  /**
  * function UpdateLetteringNumber
  * Description
  *   Màj des numéro de lettrage des imputations partenaire
  */
  procedure UpdateLetteringNumber(
    aACT_DOCUMENT_ID      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACJ_NUMBER_METHOD_ID ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type
  )
  is
    NumberMethodInfo NumberMethodInfoRecType;
    LastNumber       ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
    strLastNumber    ACT_PART_IMPUTATION.PAR_LETTERING%type;
    strDocNumber     ACT_PART_IMPUTATION.PAR_LETTERING%type;
  begin
    -- recherche des infos sur la méthode de numérotation et blocquage de celle-ci
    -- pour empêcher des doublons
    select        NUM.ACJ_NUMBER_METHOD_ID
                , null
                , NUM.C_NUMBER_TYPE
                , NUM.DNM_PREFIX
                , NUM.DNM_SUFFIX
                , NUM.DNM_INCREMENT
                , NUM.DNM_FREE_MANAGEMENT
                , PPI.PIC_PICTURE
                , NPI.PIC_PICTURE
                , SPI.PIC_PICTURE
             into NumberMethodInfo
             from ACS_PICTURE PPI
                , ACS_PICTURE NPI
                , ACS_PICTURE SPI
                , ACJ_NUMBER_METHOD NUM
            where NUM.ACJ_NUMBER_METHOD_ID = aACJ_NUMBER_METHOD_ID
              and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
              and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
              and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+)
    for update of NUM.C_NUMBER_TYPE wait 3;

    for tpl_PartImput in (select distinct nvl(SUPP.ACS_AUXILIARY_ACCOUNT_ID, CUST.ACS_AUXILIARY_ACCOUNT_ID)
                                                                                               ACS_AUXILIARY_ACCOUNT_ID
                                        , PART.ACT_PART_IMPUTATION_ID
                                        , DOC.ACS_FINANCIAL_YEAR_ID
                                     from ACJ_CATALOGUE_DOCUMENT CAT
                                        , ACT_DOCUMENT DOC
                                        , ACT_PART_IMPUTATION PART
                                        , PAC_SUPPLIER_PARTNER SUPP
                                        , PAC_CUSTOM_PARTNER CUST
                                    where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
                                      and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                                      and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
                                      and PART.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                      and PART.PAR_LETTERING is null
                                      and SUPP.PAC_SUPPLIER_PARTNER_ID(+) = PART.PAC_SUPPLIER_PARTNER_ID
                                      and CUST.PAC_CUSTOM_PARTNER_ID(+) = PART.PAC_CUSTOM_PARTNER_ID
                                      and exists(
                                               select act_det_payment_id
                                                 from act_det_payment
                                                where act_part_imputation_id = PART.ACT_PART_IMPUTATION_ID
                                                  and rownum = 1)
                                 order by PART.ACT_PART_IMPUTATION_ID) loop
      -- Recherche du dernier numéro
      select max(PART.PAR_LETTERING)
        into strLastNumber
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PART
           , PAC_SUPPLIER_PARTNER SUPP
           , PAC_CUSTOM_PARTNER CUST
       where DOC.ACS_FINANCIAL_YEAR_ID = tpl_PartImput.ACS_FINANCIAL_YEAR_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE in('3', '4', '9')
         and PART.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and SUPP.PAC_SUPPLIER_PARTNER_ID(+) = PART.PAC_SUPPLIER_PARTNER_ID
         and CUST.PAC_CUSTOM_PARTNER_ID(+) = PART.PAC_CUSTOM_PARTNER_ID
         and nvl(SUPP.ACS_AUXILIARY_ACCOUNT_ID, CUST.ACS_AUXILIARY_ACCOUNT_ID) = tpl_PartImput.ACS_AUXILIARY_ACCOUNT_ID;

      -- Extraction du dernier numéro
      if strLastNumber is not null then
        begin
          LastNumber  :=
            AlphaToSequence(substr(strLastNumber
                                 , nvl(length(NumberMethodInfo.Prefix), 0) + 1
                                 , length(NumberMethodInfo.PicNumber)
                                  )
                           );
        exception
          when value_error then
            LastNumber  := -1;
        end;
      else
        LastNumber  := -1;
      end if;

      -- Calcul du prochain numéro
      GetDocNumberInternal(NumberMethodInfo
                         , tpl_PartImput.ACS_FINANCIAL_YEAR_ID
                         , strDocNumber
                         , LastNumber
                         , null
                         , false
                         , true
                         , false
                          );

      -- Màj de l'imput. partenaire
      update ACT_PART_IMPUTATION
         set PAR_LETTERING = strDocNumber
       where ACT_PART_IMPUTATION_ID = tpl_PartImput.ACT_PART_IMPUTATION_ID;
    end loop;
  end UpdateLetteringNumber;

  /**
  * function GetLetteringNumbers
  * Description
  *   Retourne la liste des numéro de lettrage de l'imputation partenaire
  */
  function GetLetteringNumbers(
    aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aIsPayment              ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type default null
  , aSeparator              varchar2 default ' '
  )
    return varchar2
  is
    result       varchar2(4000);
    PartImpId    ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    ParLettering ACT_PART_IMPUTATION.PAR_LETTERING%type;
  begin
    if nvl(aIsPayment, 0) != 0 then
      select min(PART.ACT_PART_IMPUTATION_ID)
           , max(PART.PAR_LETTERING)
        into PartImpId
           , ParLettering
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PART
       where PART.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
         and DOC.ACT_DOCUMENT_ID = PART.ACT_DOCUMENT_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE in('3', '4', '9');

      if PartImpId is not null then
        -- Document lettrage
        result  := ParLettering;
      end if;
    else
      -- Document facture
      for tpl_PartNumber in (select   PART.PAR_LETTERING
                                 from ACT_PART_IMPUTATION PART
                                    , ACT_EXPIRY exp
                                    , ACT_DET_PAYMENT DET
                                where exp.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
                                  and DET.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                  and PART.ACT_PART_IMPUTATION_ID = DET.ACT_PART_IMPUTATION_ID
                             order by PART.PAR_LETTERING) loop
        if result is null then
          result  := tpl_PartNumber.PAR_LETTERING;
        else
          result  := result || aSeparator || tpl_PartNumber.PAR_LETTERING;
        end if;
      end loop;
    end if;

    return result;
  end GetLetteringNumbers;

-----------------------
  function TotalPaymentTypAt(aACT_EXPIRY_ID number, aDate date, aLC number, aDocType varchar2, aAmountType varchar2)
    return number
  is
    cursor csr_Document(aExpiryId number, aDateLimit date, aNC1 varchar2, aNC2 varchar2, aPAY1 varchar2, aPAY2 varchar2)
    is
      select distinct DET.ACT_PART_IMPUTATION_ID
                    , CAT.C_TYPE_CATALOGUE
                    , DET.DET_PAIED_LC
                    , DET.DET_DISCOUNT_LC
                    , DET.DET_DEDUCTION_LC
                    , DET.DET_DIFF_EXCHANGE
                    , DET.DET_PAIED_FC
                    , DET.DET_DISCOUNT_FC
                    , DET.DET_DEDUCTION_FC
                    , DET.DET_PAIED_EUR
                    , DET.DET_DISCOUNT_EUR
                    , DET.DET_DEDUCTION_EUR
                 from ACJ_CATALOGUE_DOCUMENT CAT2
                    , ACT_DOCUMENT DOC2
                    , ACJ_CATALOGUE_DOCUMENT CAT
                    , ACT_DOCUMENT DOC
                    , ACT_ETAT_JOURNAL JOU
                    , ACT_DOCUMENT DOC3
                    , ACT_FINANCIAL_IMPUTATION IMP
                    , ACT_EXPIRY exp
                    , ACT_DET_PAYMENT DET2
                    , ACT_DET_PAYMENT DET
                where DET.ACT_EXPIRY_ID = aExpiryId
                  and DET2.ACT_PART_IMPUTATION_ID = DET.ACT_PART_IMPUTATION_ID
                  and exp.ACT_EXPIRY_ID = DET2.ACT_EXPIRY_ID
                  and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
                  and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                  and DOC2.ACT_DOCUMENT_ID = DET.ACT_DOCUMENT_ID
                  and CAT2.ACJ_CATALOGUE_DOCUMENT_ID = DOC2.ACJ_CATALOGUE_DOCUMENT_ID
                  and (   CAT.C_TYPE_CATALOGUE in(aNC1, aNC2)
                       or (    CAT.C_TYPE_CATALOGUE = '2'
                           and CAT2.C_TYPE_CATALOGUE in(aPAY1, aPAY2, '9') )
                      )
                  and DET2.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
                  and IMP.C_GENRE_TRANSACTION = '1'
                  and IMP.IMF_TRANSACTION_DATE <= aDateLimit
                  and IMP.ACT_PART_IMPUTATION_ID is not null
                  and DET2.ACT_DOCUMENT_ID = DOC3.ACT_DOCUMENT_ID
                  and DOC3.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                  and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                            and JOU.C_SUB_SET = 'REC')
                       or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                           and JOU.C_SUB_SET = 'PAY')
                      )
                  and (   JOU.C_ETAT_JOURNAL != 'BRO'
                       or (    ACT_FUNCTIONS.GetBRO = 1
                           and JOU.C_ETAT_JOURNAL = 'BRO') )
             order by DET.ACT_PART_IMPUTATION_ID;

    PAY1                     varchar(1)                          := null;
    PAY2                     varchar(1)                          := null;
    NC1                      varchar(1)                          := null;
    NC2                      varchar(1)                          := null;
    tmpNC1                   varchar(1)                          := null;
    tmpNC2                   varchar(1)                          := null;
    sum_tot_part             ACT_DET_PAYMENT%rowtype             := null;
    sum_nc                   ACT_DET_PAYMENT%rowtype             := null;
    sum_tot_paied_lc         number(20, 6);
    sum_tot_discount_lc      number(20, 6);
    sum_tot_deduction_lc     number(20, 6);
    sum_tot_diff_exchange_lc number(20, 6);
    sum_tot_paied_fc         number(20, 6);
    sum_tot_discount_fc      number(20, 6);
    sum_tot_deduction_fc     number(20, 6);
    sum_tot_paied_eur        number(20, 6);
    sum_tot_discount_eur     number(20, 6);
    sum_tot_deduction_eur    number(20, 6);
    result_paied             number(20, 6);
    result_discount          number(20, 6);
    result_deduction         number(20, 6);
    result_diff_exchange     number(20, 6);
    result_total             number(20, 6);
    result                   ACT_DET_PAYMENT.DET_PAIED_LC%type;
    skip                     boolean;
    ratio                    number;
  begin
    -- Assignation des variables en fonction de la liste des documents
    if instr(aDocType, '3') > 0 then
      PAY1  := '3';
    end if;

    if instr(aDocType, '4') > 0 then
      PAY2  := '4';
    end if;

    if instr(aDocType, '5') > 0 then
      NC1  := '5';
    end if;

    if instr(aDocType, '6') > 0 then
      NC2  := '6';
    end if;

    -- Mise à zéro des compteurs
    sum_tot_paied_lc          := 0;
    sum_tot_discount_lc       := 0;
    sum_tot_deduction_lc      := 0;
    sum_tot_diff_exchange_lc  := 0;
    sum_tot_paied_fc          := 0;
    sum_tot_discount_fc       := 0;
    sum_tot_deduction_fc      := 0;
    sum_tot_paied_eur         := 0;
    sum_tot_discount_eur      := 0;
    sum_tot_deduction_eur     := 0;

    -- Ouverture du curseur sur les documents partenaire à traiter
    for tpl_Document in csr_Document(aACT_EXPIRY_ID, aDate, NC1, NC2, PAY1, PAY2) loop
      -- Recherche de la somme des paiements sur le document partenaire
      select nvl(sum(nvl(DET2.DET_PAIED_LC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DISCOUNT_LC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DEDUCTION_LC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DIFF_EXCHANGE, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_PAIED_FC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DISCOUNT_FC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DEDUCTION_FC, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_PAIED_EUR, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DISCOUNT_EUR, 0) ), 0)
           , nvl(sum(nvl(DET2.DET_DEDUCTION_EUR, 0) ), 0)
        into sum_tot_part.DET_PAIED_LC
           , sum_tot_part.DET_DISCOUNT_LC
           , sum_tot_part.DET_DEDUCTION_LC
           , sum_tot_part.DET_DIFF_EXCHANGE
           , sum_tot_part.DET_PAIED_FC
           , sum_tot_part.DET_DISCOUNT_FC
           , sum_tot_part.DET_DEDUCTION_FC
           , sum_tot_part.DET_PAIED_EUR
           , sum_tot_part.DET_DISCOUNT_EUR
           , sum_tot_part.DET_DEDUCTION_EUR
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_ETAT_JOURNAL JOU
           , ACT_DOCUMENT DOC3
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_EXPIRY exp
           , ACT_DET_PAYMENT DET2
       where DET2.ACT_PART_IMPUTATION_ID = tpl_Document.ACT_PART_IMPUTATION_ID
         and exp.ACT_EXPIRY_ID = DET2.ACT_EXPIRY_ID
         and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
         and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE = '2'
         and DET2.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
         and IMP.C_GENRE_TRANSACTION = '1'
         and IMP.IMF_TRANSACTION_DATE <= aDate
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and DET2.ACT_DOCUMENT_ID = DOC3.ACT_DOCUMENT_ID
         and DOC3.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                   and JOU.C_SUB_SET = 'REC')
              or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                  and JOU.C_SUB_SET = 'PAY')
             )
         and (   JOU.C_ETAT_JOURNAL != 'BRO'
              or (    ACT_FUNCTIONS.GetBRO = 1
                  and JOU.C_ETAT_JOURNAL = 'BRO') );

      skip  := false;

      if tpl_Document.C_TYPE_CATALOGUE = '2' then   -- Si paiement
        if sum_tot_part.DET_PAIED_LC != 0 then
          -- Si paiement et somme des paiements différent de 0 -> recherche de la somme des NC
          tmpNC1  := '5';
          tmpNC2  := '6';
        else
          -- Si somme des paiements = 0 -> on ne traite pas ce document partenaire
          skip  := true;
        end if;
      elsif     NC1 is null
            and NC2 is null then   -- Si NC
        -- Si on ne tiens pas compte des NC -> on ne traite pas ce document partenaire
        skip  := true;
      else   -- Si NC
        -- Recherche de la somme des NC
        tmpNC1  := NC1;
        tmpNC2  := NC2;
      end if;

      -- Si on traite le document partenaire
      if not skip then
        -- Recherche de la somme des NC sur le document partenaire
        select nvl(sum(nvl(DET2.DET_PAIED_LC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DISCOUNT_LC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DEDUCTION_LC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DIFF_EXCHANGE, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_PAIED_FC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DISCOUNT_FC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DEDUCTION_FC, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_PAIED_EUR, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DISCOUNT_EUR, 0) ), 0)
             , nvl(sum(nvl(DET2.DET_DEDUCTION_EUR, 0) ), 0)
          into sum_nc.DET_PAIED_LC
             , sum_nc.DET_DISCOUNT_LC
             , sum_nc.DET_DEDUCTION_LC
             , sum_nc.DET_DIFF_EXCHANGE
             , sum_nc.DET_PAIED_FC
             , sum_nc.DET_DISCOUNT_FC
             , sum_nc.DET_DEDUCTION_FC
             , sum_nc.DET_PAIED_EUR
             , sum_nc.DET_DISCOUNT_EUR
             , sum_nc.DET_DEDUCTION_EUR
          from ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_ETAT_JOURNAL JOU
             , ACT_DOCUMENT DOC3
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_EXPIRY exp
             , ACT_DET_PAYMENT DET2
         where DET2.ACT_PART_IMPUTATION_ID = tpl_Document.ACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = DET2.ACT_EXPIRY_ID
           and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
           and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE in(tmpNC1, tmpNC2)
           and DET2.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
           and IMP.C_GENRE_TRANSACTION = '1'
           and IMP.IMF_TRANSACTION_DATE <= aDate
           and IMP.ACT_PART_IMPUTATION_ID is not null
           and DET2.ACT_DOCUMENT_ID = DOC3.ACT_DOCUMENT_ID
           and DOC3.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                     and JOU.C_SUB_SET = 'REC')
                or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                    and JOU.C_SUB_SET = 'PAY')
               )
           and (   JOU.C_ETAT_JOURNAL != 'BRO'
                or (    ACT_FUNCTIONS.GetBRO = 1
                    and JOU.C_ETAT_JOURNAL = 'BRO') );

        if sum_tot_part.DET_PAIED_LC = 0 then
          sum_tot_part.DET_PAIED_LC  := 1;
        end if;

        -- Calcule de la proportion
        if tpl_Document.C_TYPE_CATALOGUE = '2' then
          -- Proportion sur paiement
          ratio  := (sum_tot_part.DET_PAIED_LC + sum_nc.DET_PAIED_LC) / sum_tot_part.DET_PAIED_LC;
        else
          if sum_nc.DET_PAIED_LC = 0 then
            sum_nc.DET_PAIED_LC  := -1;
          end if;

          -- Proportion sur NC
          ratio  := -sum_nc.DET_PAIED_LC / sum_tot_part.DET_PAIED_LC;
        end if;

        -- Cumuls des montants
        sum_tot_paied_lc          := sum_tot_paied_lc + ratio * tpl_Document.DET_PAIED_LC;
        sum_tot_discount_lc       := sum_tot_discount_lc + ratio * tpl_Document.DET_DISCOUNT_LC;
        sum_tot_deduction_lc      := sum_tot_deduction_lc + ratio * tpl_Document.DET_DEDUCTION_LC;
        sum_tot_diff_exchange_lc  := sum_tot_diff_exchange_lc + ratio * tpl_Document.DET_DIFF_EXCHANGE;
        sum_tot_paied_fc          := sum_tot_paied_fc + ratio * tpl_Document.DET_PAIED_FC;
        sum_tot_discount_fc       := sum_tot_discount_fc + ratio * tpl_Document.DET_DISCOUNT_FC;
        sum_tot_deduction_fc      := sum_tot_deduction_fc + ratio * tpl_Document.DET_DEDUCTION_FC;
        sum_tot_paied_eur         := sum_tot_paied_eur + ratio * tpl_Document.DET_PAIED_EUR;
        sum_tot_discount_eur      := sum_tot_discount_eur + ratio * tpl_Document.DET_DISCOUNT_EUR;
        sum_tot_deduction_eur     := sum_tot_deduction_eur + ratio * tpl_Document.DET_DEDUCTION_EUR;
      end if;
    end loop;

    -- Assignationdu résultat en fonction de la monnaie demandée
    if aLC = 0 then
      result_paied          := sum_tot_paied_fc;
      result_deduction      := sum_tot_deduction_fc;
      result_discount       := sum_tot_discount_fc;
      result_diff_exchange  := 0;
    elsif aLC = 2 then
      result_paied          := sum_tot_paied_eur;
      result_deduction      := sum_tot_deduction_eur;
      result_discount       := sum_tot_discount_eur;
      result_diff_exchange  := 0;
    else
      result_paied          := sum_tot_paied_lc;
      result_deduction      := sum_tot_deduction_lc;
      result_discount       := sum_tot_discount_lc;
      result_diff_exchange  := sum_tot_diff_exchange_lc;
    end if;

    -- Cumul des montants souhaité dans le résultat
    result_total              := 0;

    if instr(aAmountType, '1') > 0 then
      result_total  := result_total + result_paied;
    end if;

    if instr(aAmountType, '2') > 0 then
      result_total  := result_total + result_discount;
    end if;

    if instr(aAmountType, '3') > 0 then
      result_total  := result_total + result_deduction;
    end if;

    if instr(aAmountType, '4') > 0 then
      result_total  := result_total + result_diff_exchange;
    end if;

    -- Arrondi selon champ ACT_DET_PAYMENT.DET_PAIED_LC
    result                    := result_total;
    return result;
  end TotalPaymentTypAt;

-----------------------
  function LastDatePaymentTyp(aACT_EXPIRY_ID number, aDocType varchar2, aDateType integer)
    return date
  is
    PAY1            varchar(1) := null;
    PAY2            varchar(1) := null;
    NC1             varchar(1) := null;
    NC2             varchar(1) := null;
    DocumentDate    date;
    TransactionDate date;
    ValueDate       date;
  begin
    -- Assignation des variables en fonction de la liste des documents
    if instr(aDocType, '3') > 0 then
      PAY1  := '3';
    end if;

    if instr(aDocType, '4') > 0 then
      PAY2  := '4';
    end if;

    if instr(aDocType, '5') > 0 then
      NC1  := '5';
    end if;

    if instr(aDocType, '6') > 0 then
      NC2  := '6';
    end if;

    select max(DOC2.DOC_DOCUMENT_DATE) DOC_DOCUMENT_DATE
         , max(IMP.IMF_TRANSACTION_DATE) IMF_TRANSACTION_DATE
         , max(IMF_VALUE_DATE) IMF_VALUE_DATE
      into DocumentDate
         , TransactionDate
         , ValueDate
      from ACJ_CATALOGUE_DOCUMENT CAT2
         , ACT_DOCUMENT DOC2
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_DOCUMENT DOC
         , ACT_ETAT_JOURNAL JOU
         , ACT_DOCUMENT DOC3
         , ACT_FINANCIAL_IMPUTATION IMP
         , ACT_EXPIRY exp
         , ACT_DET_PAYMENT DET2
         , ACT_DET_PAYMENT DET
     where DET.ACT_EXPIRY_ID = aACT_EXPIRY_ID
       and DET2.ACT_PART_IMPUTATION_ID = DET.ACT_PART_IMPUTATION_ID
       and exp.ACT_EXPIRY_ID = DET2.ACT_EXPIRY_ID
       and DOC.ACT_DOCUMENT_ID = exp.ACT_DOCUMENT_ID
       and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
       and DOC2.ACT_DOCUMENT_ID = DET.ACT_DOCUMENT_ID
       and CAT2.ACJ_CATALOGUE_DOCUMENT_ID = DOC2.ACJ_CATALOGUE_DOCUMENT_ID
       and (   CAT.C_TYPE_CATALOGUE in(NC1, NC2)
            or (    CAT.C_TYPE_CATALOGUE = '2'
                and CAT2.C_TYPE_CATALOGUE in(PAY1, PAY2, '9') )
           )
       and DET2.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
       and IMP.C_GENRE_TRANSACTION = '1'
       and IMP.ACT_PART_IMPUTATION_ID is not null
       and DET2.ACT_DOCUMENT_ID = DOC3.ACT_DOCUMENT_ID
       and DOC3.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and (    (    IMP.IMF_PAC_CUSTOM_PARTNER_ID is not null
                 and JOU.C_SUB_SET = 'REC')
            or (    IMP.IMF_PAC_SUPPLIER_PARTNER_ID is not null
                and JOU.C_SUB_SET = 'PAY')
           )
       and (   JOU.C_ETAT_JOURNAL != 'BRO'
            or (    ACT_FUNCTIONS.GetBRO = 1
                and JOU.C_ETAT_JOURNAL = 'BRO') );

    -- retourne la date demandé
    if aDateType = 1 then
      return DocumentDate;
    elsif aDateType = 2 then
      return TransactionDate;
    else
      return ValueDate;
    end if;
  end LastDatePaymentTyp;

  /**
  * function ReminderMECurrencyTotal
  * Description
  *   Retourne le total de monnaies étrangères gérées sur les relances débiteurs/créanciers du partenaire
  */
  function ReminderMECurrencyTotal(
    pACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pPartnerTyp               varchar2
  )
    return number
  is
    vResult number;
  begin
    vResult  := 0;

    if pPartnerTyp = 'REC' then
      select count(*)
         into vResult
         from (select   PAR.ACS_FINANCIAL_CURRENCY_ID
                   from ACT_REMINDER DER
                      , ACT_PART_IMPUTATION PAR
                     , PAC_CUSTOM_PARTNER CUS
                  where
                    DER.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                    and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
                    and CUS.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
               group by PAR.ACS_FINANCIAL_CURRENCY_ID);
    else
      select count(*)
          into vResult
          from (select   PAR.ACS_FINANCIAL_CURRENCY_ID
                    from ACT_REMINDER DER
                       , ACT_PART_IMPUTATION PAR
                      , PAC_SUPPLIER_PARTNER SUP
                   where
                     DER.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID
                     and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                     and SUP.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
                group by PAR.ACS_FINANCIAL_CURRENCY_ID);
    end if;

    return vResult;
  end ReminderMECurrencyTotal;

  /**
  * function ThirdImpMECurrencyTotal
  * Description
  *   retourne le total de monnaies étrangère du tiers
  */
  function ThirdImpMECurrencyTotal(
    pACS_AUX_ACCOUNT_ID_CUST ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pACS_AUX_ACCOUNT_ID_SUPP ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , pDOC_GROUP_BY            number
  )
    return number
  is
    vResult number;
  begin
    vResult  := 0;

    if pDOC_GROUP_BY = 0 then
      select count(*)
        into vResult
        from (select ACS_FINANCIAL_CURRENCY_ID
                from V_ACT_THIRD_IMP_REPORT V
                   , ACS_PERIOD PER
               where V.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                 and V.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUX_ACCOUNT_ID_CUST
              union
              select ACS_FINANCIAL_CURRENCY_ID
                from V_ACT_THIRD_IMP_REPORT V
                   , ACS_PERIOD PER
               where V.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                 and V.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUX_ACCOUNT_ID_SUPP);
    else
      select count(*)
        into vResult
        from (select   ACS_FINANCIAL_CURRENCY_ID
                  from V_ACT_THIRD_IMP_REPORT V
                     , ACS_PERIOD PER
                 where V.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and V.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUX_ACCOUNT_ID_CUST
              group by V.ACS_FINANCIAL_CURRENCY_ID
              union
              select   ACS_FINANCIAL_CURRENCY_ID
                  from V_ACT_THIRD_IMP_REPORT V
                     , ACS_PERIOD PER
                 where V.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and V.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUX_ACCOUNT_ID_SUPP
              group by V.ACS_FINANCIAL_CURRENCY_ID);
    end if;

    return vResult;
  end ThirdImpMECurrencyTotal;

------------------------------
  function GetCatalogDescription(aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
    return ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type
  is
    CatDescription ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION%type;
  begin
    select nvl(max(ACJ_DESCRIPTION_TYPE.DES_DESCR), max(ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION) )
      into CatDescription
      from ACJ_DESCRIPTION_TYPE
         , ACJ_CATALOGUE_DOCUMENT
     where ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
       and ACJ_CATALOGUE_DOCUMENT.ACJ_DESCRIPTION_TYPE_ID = ACJ_DESCRIPTION_TYPE.ACJ_DESCRIPTION_TYPE_ID(+);

    return CatDescription;
  end GetCatalogDescription;

  /**
  * function GetMGMAmountRco
  * Description
  *    Retour du montant des cumuls MGM selon une paire (RCO-CPN, RCO-CDA, RCO-PF, RCO-PJ) + Quantité pour un exercice comptable
       avec filtre sur les périodes + type de cumuls
  **/
  function GetMGMAmountRco(
    pDOC_RECORD_ID         DOC_RECORD.DOC_RECORD_ID%type
  , pC_SUB_SET             ACS_SUB_SET.C_SUB_SET%type
  , pACS_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_QTY_UNIT_ID       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , pACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPeriodFrom            ACS_PERIOD.PER_NO_PERIOD%type
  , pPeriodTo              ACS_PERIOD.PER_NO_PERIOD%type
  , pPri                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSec                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSim                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pPre                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pEng                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pGetAmount             varchar2
  , pLevelSubRCO           number default -1
  )
    return ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  is
    vAmount ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type   default 0;
  begin
    if     (pACS_ACCOUNT_ID is not null)
       and (pC_SUB_SET is not null)
       and (    (pC_SUB_SET = 'CPN')
            or (pC_SUB_SET = 'CDA')
            or (pC_SUB_SET = 'COS')
            or (pC_SUB_SET = 'PRO') ) then
      if pLevelSubRCO > -1 then
        select decode(pGetAmount
                    , 1, nvl(sum(TOT.MTO_DEBIT_LC - TOT.MTO_CREDIT_LC), 0)
                    , 2, nvl(sum(TOT.MTO_QUANTITY_D - TOT.MTO_QUANTITY_C), 0)
                    , 0
                     ) AMOUNT
          into vAmount
          from table(ACR_FUNCTIONS.GetChildrenLinkedDocRecord(pDOC_RECORD_ID, pLevelSubRCO) ) ChildrenDoc
             , ACT_MGM_TOT_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPeriodFrom
           and PER.PER_NO_PERIOD <= pPeriodTo
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and TOT.C_TYPE_CUMUL in(pPri, pSec, pSim, pPre, pEng)
           and TOT.DOC_RECORD_ID = ChildrenDoc.COLUMN_VALUE
           and decode(pC_SUB_SET
                    , 'CPN', TOT.ACS_CPN_ACCOUNT_ID
                    , 'CDA', TOT.ACS_CDA_ACCOUNT_ID
                    , 'COS', TOT.ACS_PF_ACCOUNT_ID
                    , 'PRO', TOT.ACS_PJ_ACCOUNT_ID
                     ) = pACS_ACCOUNT_ID
           and nvl(TOT.ACS_QTY_UNIT_ID, 0) = nvl(pACS_QTY_UNIT_ID, 0);
      else
        select decode(pGetAmount
                    , 1, nvl(sum(TOT.MTO_DEBIT_LC - TOT.MTO_CREDIT_LC), 0)
                    , 2, nvl(sum(TOT.MTO_QUANTITY_D - TOT.MTO_QUANTITY_C), 0)
                    , 0
                     ) AMOUNT
          into vAmount
          from ACT_MGM_TOT_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.PER_NO_PERIOD >= pPeriodFrom
           and PER.PER_NO_PERIOD <= pPeriodTo
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and TOT.C_TYPE_CUMUL in(pPri, pSec, pSim, pPre, pEng)
           and TOT.DOC_RECORD_ID = pDOC_RECORD_ID
           and decode(pC_SUB_SET
                    , 'CPN', TOT.ACS_CPN_ACCOUNT_ID
                    , 'CDA', TOT.ACS_CDA_ACCOUNT_ID
                    , 'COS', TOT.ACS_PF_ACCOUNT_ID
                    , 'PRO', TOT.ACS_PJ_ACCOUNT_ID
                     ) = pACS_ACCOUNT_ID
           and nvl(TOT.ACS_QTY_UNIT_ID, 0) = nvl(pACS_QTY_UNIT_ID, 0);
      end if;
    end if;

    return vAmount;
  end GetMGMAmountRco;

  /**
  * function GetMGMAmountRcoList
  * Description
  *    Retour du montant des cumuls MGM selon une paire (RCO-CPN, RCO-CDA, RCO-PF, RCO-PJ) + Quantité pour un exercice comptable
       avec filtre sur les périodes + type de cumuls
  **/
  function GetMGMAmountRcoList(
    pC_SUB_SET             ACS_SUB_SET.C_SUB_SET%type
  , pACS_ACCOUNT_ID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pACS_QTY_UNIT_ID       ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , pACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPeriodFrom            ACS_PERIOD.PER_NO_PERIOD%type
  , pPeriodTo              ACS_PERIOD.PER_NO_PERIOD%type
  , pPri                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSec                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pSim                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pPre                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pEng                   ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , pGetAmount             varchar2
  , pLevelSubRCO           number default -1
  )
    return ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  is
    vAmount        ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type   default 0;
    tblDocRecordID ID_TABLE_TYPE;
  begin
    tblDocRecordID  := ID_TABLE_TYPE();

    if ACR_FUNCTIONS.FillInTbl(tblDocRecordID) then
      for cpt in tblDocRecordID.first .. tblDocRecordID.last loop
        vAmount  :=
          vAmount +
          ACT_FUNCTIONS.GetMgmAmountRco(tblDocRecordID(cpt)
                                      , pC_SUB_SET
                                      , pACS_ACCOUNT_ID
                                      , pACS_QTY_UNIT_ID
                                      , pACS_FINANCIAL_YEAR_ID
                                      , pPeriodFrom
                                      , pPeriodTo
                                      , pPri
                                      , pSec
                                      , pSim
                                      , pPre
                                      , pEng
                                      , pGetAmount
                                      , pLevelSubRCO
                                       );
      end loop;
    end if;

    return vAMount;
  end GetMGMAmountRcoList;

  /**
  * Description
  *   Retourne la valeur pour l'ordre de création des imputations partenaires (procédure paiement)
  *     selon valeur descode C_IMPUTATION_CREATE_ORDER passée en paramètre.
  */
  function GetPartImputCreateOrderValue(
    aC_IMPUTATION_CREATE_ORDER ACS_FIN_ACC_S_PAYMENT.C_IMPUTATION_CREATE_ORDER%type
  , aPAC_SUPPLIER_PARTNER_ID   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  )
    return varchar2
  is
    vPER_NAME       PAC_PERSON.PER_NAME%type;
    vPER_SHORT_NAME PAC_PERSON.PER_SHORT_NAME%type;
    vPER_KEY1       PAC_PERSON.PER_KEY1%type;
    vACC_NUMBER     ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    if aC_IMPUTATION_CREATE_ORDER in('1', '2', '3') then
      select min(PER_NAME)
           , min(PER_SHORT_NAME)
           , min(PER_KEY1)
        into vPER_NAME
           , vPER_SHORT_NAME
           , vPER_KEY1
        from PAC_PERSON
       where PAC_PERSON_ID = nvl(aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID);

      if aC_IMPUTATION_CREATE_ORDER = '1' then
        return vPER_SHORT_NAME;
      elsif aC_IMPUTATION_CREATE_ORDER = '2' then
        return vPER_NAME;
      elsif aC_IMPUTATION_CREATE_ORDER = '3' then
        return vPER_KEY1;
      end if;
    else
      if aPAC_SUPPLIER_PARTNER_ID is not null then
        select min(ACC_NUMBER)
          into vACC_NUMBER
          from ACS_ACCOUNT
             , PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID
           and ACS_ACCOUNT_ID = ACS_AUXILIARY_ACCOUNT_ID;
      elsif aPAC_CUSTOM_PARTNER_ID is not null then
        select min(ACC_NUMBER)
          into vACC_NUMBER
          from ACS_ACCOUNT
             , PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
           and ACS_ACCOUNT_ID = ACS_AUXILIARY_ACCOUNT_ID;
      else
        vACC_NUMBER  := null;
      end if;

      return vACC_NUMBER;
    end if;
  end GetPartImputCreateOrderValue;

  function BestMatch(aSource varchar2, aTest varchar2, aMinChar integer default 1)
    return number
  is
    result     integer;
    bestresult integer;
    strstart   integer;
    strend     integer;
  begin
    bestresult  := 0;
    strstart    := 1;
    strend      := length(aSource) + 1;

    while(strend - aMinChar) >= strstart
     and bestresult < strend - strstart loop
      result    := 0;

      while result = 0
       and (strend - aMinChar) >= strstart loop
        if instr(aTest, substr(aSource, strstart, strend - strstart) ) > 0 then
          result  := strend - strstart;
        end if;

        strend  := strend - 1;
      end loop;

      if result > bestresult then
        bestresult  := result;
      end if;

      strstart  := strstart + 1;
      strend    := length(aSource) + 1;
    end loop;

    return bestresult;
  end BestMatch;



  function HedgeManagement (ln_AcjCatalogueDocumentId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
    return number
  is
    ln_Result number(1);
  begin
    ln_Result  := 0;

    --Gestion couverture de change activée pour la société
    if (PCS.PC_CONFIG.GetConfig('COM_CURRENCY_RISK_MANAGE') = '1') then
      select CAT_CURR_RISK_MGT
        into ln_Result
        from ACJ_CATALOGUE_DOCUMENT
       where ACJ_CATALOGUE_DOCUMENT_ID = ln_AcjCatalogueDocumentId;
    end if;

    return ln_Result;
  end HedgeManagement;

  function GetCatalogueType (ln_AcjCatalogueDocumentId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type)
    return ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  is
    lv_Result ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
  begin
    select C_TYPE_CATALOGUE
      into lv_Result
      from ACJ_CATALOGUE_DOCUMENT
     where ACJ_CATALOGUE_DOCUMENT_ID = ln_AcjCatalogueDocumentId;
    return lv_Result;
  end GetCatalogueType;

  /**
  * function IsDocumentIntegrationType
  * Description
  *    Analyse le type d'intégration d'un document finance
  **/
  function IsDocumentIntegrationType (inDocumentId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return number
    is
      vResult number default 0;
    begin
      select case
               when TYP.C_ACI_FINANCIAL_LINK in('2', '3', '4', '5') then 1
               else 0
             end vResult
        into vResult
        from act_document doc
           , act_job job
           , acj_job_type typ
       where doc.act_job_id = job.act_job_id
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and doc.act_Document_id = inDocumentId;
      return vResult;
  end IsDocumentIntegrationType;


end ACT_FUNCTIONS;
