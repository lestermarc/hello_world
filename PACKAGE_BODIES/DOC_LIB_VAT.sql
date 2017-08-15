--------------------------------------------------------
--  DDL for Package Body DOC_LIB_VAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_VAT" 
is
  /**
  * Description
  *    Retourne le montant de l'arrondi TVA ajouté sur la position.
  */
  function getVatPosRoundAmount(iPositionID in DOC_VAT_DET_ACCOUNT.DOC_POSITION_ID%type)
    return DOC_VAT_DET_ACCOUNT.VDA_ROUND_AMOUNT%type
  as
    lVatRoundAmount DOC_VAT_DET_ACCOUNT.VDA_ROUND_AMOUNT%type;
  begin
    select nvl(VDA_ROUND_AMOUNT, 0)
      into lVatRoundAmount
      from DOC_VAT_DET_ACCOUNT
     where DOC_POSITION_ID = iPositionID;
    return lVatRoundAmount;
  exception
    when no_data_found then
      return 0;
  end getVatPosRoundAmount;
end DOC_LIB_VAT;
