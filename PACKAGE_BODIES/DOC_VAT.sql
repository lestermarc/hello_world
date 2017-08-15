--------------------------------------------------------
--  DDL for Package Body DOC_VAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_VAT" 
is
  -- Procedure declanchee par trigger sur la table des positions
  procedure UPDATE_POSITION_VAT(
    FOOT_ID            number
  , GAUGE_TYPE_POS     varchar2
  , TAX_CODE_ID        number
  , NET_VALUE_EXCL     number
  , NET_VALUE_EXCL_B   number
  , NET_VALUE_EXCL_V   number
  , VAT_RATE           number
  , VAT_TOTAL_AMOUNT   number
  , VAT_TOTAL_AMOUNT_B number
  , VAT_TOTAL_AMOUNT_V number
  , VAT_AMOUNT         number
  , VAT_BASE_AMOUNT    number
  , VAT_AMOUNT_V       number
  , sign               number
  )
  is
  begin
    DOC_PRC_VAT.UpdatePositionVat(
      iFootId          => FOOT_ID
    , iGaugeTypePos    => GAUGE_TYPE_POS
    , iTaxCodeId       => TAX_CODE_ID
    , iNetValueExcl    => NET_VALUE_EXCL
    , iNetValueExclb   => NET_VALUE_EXCL_B
    , iNetValueExclv   => NET_VALUE_EXCL_V
    , iVatRate         => VAT_RATE
    , iVatTotalAmount  => VAT_TOTAL_AMOUNT
    , iVatTotalAmountb => VAT_TOTAL_AMOUNT_B
    , iVatTotalAmountv => VAT_TOTAL_AMOUNT_V
    , iVatAmount       => VAT_AMOUNT
    , iVatBaseAmount   => VAT_BASE_AMOUNT
    , iVatAmountv      => VAT_AMOUNT_V
    , iSign            => sign);
  end UPDATE_POSITION_VAT;

  -- Procedure de mise à jour des recapitulations TVA
  procedure UPDATE_VAT_ACCOUNT(
    FOOT_ID            number
  , TAX_CODE_ID        number
  , NET_AMOUNT_EXCL    number
  , NET_AMOUNT_EXCL_B  number
  , NET_AMOUNT_EXCL_V  number
  , VAT_RATE           number
  , VAT_TOTAL_AMOUNT   number
  , VAT_TOTAL_AMOUNT_B number
  , VAT_TOTAL_AMOUNT_V number
  , VAT_AMOUNT         number
  , VAT_BASE_AMOUNT    number
  , VAT_AMOUNT_V       number
  , sign               number
  )
  is
  begin
    DOC_PRC_VAT.UpdateVatAccount(
      iFootId           => FOOT_ID
    , iTaxCodeId        => TAX_CODE_ID
    , iNetAmountExcl    => NET_AMOUNT_EXCL
    , iNetAmountExclb   => NET_AMOUNT_EXCL_B
    , iNetAmountExclv   => NET_AMOUNT_EXCL_V
    , iVatRate          => VAT_RATE
    , iVatTotalAmount   => VAT_TOTAL_AMOUNT
    , iVatTotalAmountb  => VAT_TOTAL_AMOUNT_B
    , iVatTotalAmountv  => VAT_TOTAL_AMOUNT_V
    , iVatAmount        => VAT_AMOUNT
    , iVatBaseAmount    => VAT_BASE_AMOUNT
    , iVatAmountv       => VAT_AMOUNT_V
    , iSign             => sign
    );
  end UPDATE_VAT_ACCOUNT;

  /**
  * Description
  *     Procedure de génération de la correction d'arrondi TVA
  */
  procedure AppendVatCorrectionAmount(
    aDocumentId  in     number
  , aAppendRound in     number default 1
  , aAppendCorr  in     number default 1
  , aModified    out    number
  )
  is
  begin
    DOC_PRC_VAT.AppendVatCorrectionAmount(
      iDocumentId  => aDocumentId
    , iAppendRound => aAppendRound
    , iAppendCorr  => aAppendCorr
    , oModified    => aModified
    );
  end AppendVatCorrectionAmount;

  /**
  * procedure RemoveCorrectionAmount
  * Description
  *     Procedure de suppression des montants de corrections contenus dans DOC_VAT_DET_ACCOUNT
  *     (VDA_CORR_AMOUNT... et VDA_ROUND_AMOUNT)
  */
  procedure RemoveVatCorrectionAmount(
    aDocumentId  in     number
  , aRemoveRound in     number default 1
  , aRemoveCorr  in     number default 1
  , aModified    out    number
  )
  is
  begin
    DOC_PRC_VAT.RemoveVatCorrectionAmount(
      iDocumentId  => aDocumentId
    , iRemoveRound => aRemoveRound
    , iRemoveCorr  => aRemoveCorr
    , oModified    => aModified
    );
  end RemoveVatCorrectionAmount;
end DOC_VAT;
