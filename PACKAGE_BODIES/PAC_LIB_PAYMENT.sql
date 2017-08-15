--------------------------------------------------------
--  DDL for Package Body PAC_LIB_PAYMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_LIB_PAYMENT" 
is
  /**
  * Description
  *   Indique si une condition de paiement échéancier est de type sans décharge
  */
  function IsOnlyAmountBillBook(iPaymentConditionId in PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    return number
  is
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk('PAC_PAYMENT_CONDITION', 'PCO_ONLY_AMOUNT_BILL_BOOK', iPaymentConditionId);
  end IsOnlyAmountBillBook;

  /**
  * Description
  *   Indique si une condition de paiement est de type échéancier
  */
  function IsBillBookPaymentCondition(iPaymentConditionId in PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    return boolean
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('PAC_PAYMENT_CONDITION', 'C_INVOICE_EXPIRY_INPUT_TYPE', iPaymentConditionId) = '02';
  end IsBillBookPaymentCondition;
end PAC_LIB_PAYMENT;
