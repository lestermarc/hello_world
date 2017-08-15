--------------------------------------------------------
--  DDL for Package Body DOC_E_PRC_DOCUMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_E_PRC_DOCUMENT" 
is
  /**
  * procedure UpdatePositionQtyUnitPrice
  * Description
  *   Méthode permettant la modification de la quantité et/ou du prix d'une position
  */
  procedure UpdatePositionQtyUnitPrice(
    inDmtNumber  in     DOC_DOCUMENT.DMT_NUMBER%type
  , inPosNumber  in     DOC_POSITION.POS_NUMBER%type
  , inQuantity   in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , inUnitPrice  in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , outErrorCode in out DOC_DOCUMENT.C_CONFIRM_FAIL_REASON%type
  , outErrorText in out DOC_DOCUMENT.DMT_ERROR_MESSAGE%type
  )
  is
    docPositionID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    begin
      select POS.DOC_POSITION_ID
        into docPositionID
        from DOC_POSITION POS
           , DOC_DOCUMENT DMT
       where DMT.DMT_NUMBER = inDmtNumber
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.POS_NUMBER = inPosNumber;
    exception
      when no_data_found then
        outErrorCode  := '000';   -- Document ou position inexistant
        raise_application_error(-20000, 'PCS - no position or document');
    end;

    DOC_I_PRC_DOCUMENT.UpdatePositionQtyUnitPrice(inPositionID   => docPositionID
                                                , inQuantity     => inQuantity
                                                , inUnitPrice    => inUnitPrice
                                                , outErrorCode   => outErrorCode
                                                , outErrorText   => outErrorText
                                                 );
  end UpdatePositionQtyUnitPrice;

  /**
  * procedure DocumentConfirmation
  * Description
  *   Confirmation d'un document
  *
  */
  procedure DocumentConfirmation(iv_DMT_NUMBER in DOC_DOCUMENT.DMT_NUMBER%type)
  is
    lnId    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnError integer;
    lcError varchar2(2000);
  begin
    lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;

    -- traitement PK2 -> recherche de l'ID
    begin
      select DOC_DOCUMENT_ID
        into lnId
        from DOC_DOCUMENT
       where DMT_NUMBER = iv_DMT_NUMBER;
    exception
      when no_data_found then
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.ERROR;
        lcError  := 'Document number does not exist';
    end;

    -- Confirmation du document
    if lnError = PCS.PC_E_LIB_STANDARD_ERROR.OK then
      DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(lnId, lnError, lcError, 1);

      if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
        lcError  := lnError || ' ' || lcError;
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.ERROR;
      end if;
    end if;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DocumentConfirmation'
                                         );
    end if;
  end DocumentConfirmation;

  /**
  * procedure BalanceDocument
  * Description
  *   Solder un document
  */
  procedure BalanceDocument(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lnCanBalance number;
    lvDocNumber  DOC_DOCUMENT.DMT_NUMBER%type;
    lvMessage    varchar2(4000);
  begin
    -- Vérifier si l'on peut solder le document
    lnCanBalance  := DOC_DOCUMENT_FUNCTIONS.canBalanceDocument(iDocumentID);

    if lnCanBalance = 1 then
      -- Solde le document
      DOC_DOCUMENT_FUNCTIONS.BalanceDocument(iDocumentID);
    else
      -- Remonter un message d'erreur indiquant que le document en question ne peut pas être soldé
      select DMT_NUMBER
        into lvDocNumber
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentID;

      lvMessage  := replace(PCS.PC_FUNCTIONS.TranslateWord('Le document %s ne peut pas être soldé !'), '%s', lvDocNumber);
      RA(aMessage => lvMessage, aErrNo => -20000);
    end if;
  end BalanceDocument;
end DOC_E_PRC_DOCUMENT;
