--------------------------------------------------------
--  DDL for Package Body DOC_LIB_DISCOUNT_CHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_DISCOUNT_CHARGE" 
is
  /**
  * Description
  *    Retourne la valeur nette HT de la position sans les taxes de position de
  *    type matière précieuse. Si iCurrencyType est null, le montant est retourné
  *    dans la monnaie du document. si "B", dans la monnaie de base.
  */
  function getPosValueWithoutPMCharge(iPositionID in DOC_POSITION_CHARGE.DOC_POSITION_ID%type, iCurrencyType in varchar2 default null)
    return number
  as
    lPosPMChargeAmount          DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    lPosNetValueIncl            DOC_POSITION.POS_NET_VALUE_INCL%type;
    lPosNetValueExcl            DOC_POSITION.POS_NET_VALUE_EXCL%type;
    lPosValueWithoutPMChargeTTC DOC_POSITION.POS_NET_VALUE_INCL%type;
    lDateRef                    DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    lTaxCodeID                  DOC_POSITION.ACS_TAX_CODE_ID%type;
    lIncludeTaxTariff           DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type;
    lVatAmount                  DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    lreturnValue                number(20, 6);
  begin
    /* Recherche de la somme des taxes type matière précieuse */
    select case iCurrencyType
             when 'B' then nvl(sum(PCH_AMOUNT_B), 0)
             else nvl(sum(PCH_AMOUNT), 0)
           end PCH_AMOUNT
      into lPosPMChargeAmount
      from DOC_POSITION_CHARGE
     where DOC_POSITION_ID = iPositionID
       and C_CHARGE_ORIGIN in('PM', 'PMM')
       and PTC_CHARGE_ID is not null;

    /* Recherche infos positions */
    select pos.POS_INCLUDE_TAX_TARIFF
         , case iCurrencyType
             when 'B' then pos.POS_NET_VALUE_INCL_B
             else pos.POS_NET_VALUE_INCL
           end POS_NET_VALUE_INCL
         , case iCurrencyType
             when 'B' then pos.POS_NET_VALUE_EXCL_B
             else pos.POS_NET_VALUE_EXCL
           end POS_NET_VALUE_EXCL
         , pos.ACS_TAX_CODE_ID
         , nvl(pos.POS_DATE_DELIVERY, nvl(doc.DMT_DATE_DELIVERY, nvl(doc.DMT_REVALUATION_DATE, doc.DMT_DATE_VALUE) ) ) REF_DATE
      into lIncludeTaxTariff
         , lPosNetValueIncl
         , lPosNetValueExcl
         , lTaxCodeID
         , lDateRef
      from DOC_POSITION POS
         , DOC_DOCUMENT doc
     where DOC_POSITION_ID = iPositionID
       and doc.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID;

    /* Si la position est TTC et qu'il existe des taxes de position type matière précieuse */
    if     lIncludeTaxTariff = 1
       and lPosPMChargeAmount > 0 then
      /* 1. On prend la valeur TTC de la position et on lui soustrait les taxes MP ainsi que l'éventuel arrondi TVA du document */
      lPosValueWithoutPMChargeTTC  := lPosNetValueIncl - lPosPMChargeAmount - DOC_LIB_VAT.getVatPosRoundAmount(iPositionID => iPositionID);
      /* 3. On lui soustrait la TVA */
      ACS_FUNCTION.CalcVatAmount(aTaxCodeId       => lTaxCodeID
                               , aRefDate         => lDateRef
                               , aIncludedVat     => 'I'
                               , aRoundAmount     => 0
                               , aNetAmountExcl   => lreturnValue
                               , aNetAmountIncl   => lPosValueWithoutPMChargeTTC
                               , aVatAmount       => lVatAmount
                                );
    else
      /*  On retourne le montant HT sans les taxes type matière précieuse. */
      lreturnValue  := lPosNetValueExcl - lPosPMChargeAmount;
    end if;

    return lreturnValue;
  end getPosValueWithoutPMCharge;

  /**
  * Description
  *    Retourne la valeur unitaire nette HT de la position sans les taxes de position
  *    de type matière précieuse. Si iCurrencyType est null, le montant est retourné
  *    dans la monnaie du document. si "B", dans la monnaie de base.
  */
  function getUnitPosValueWithoutPMCharge(iPositionID in DOC_POSITION_CHARGE.DOC_POSITION_ID%type, iCurrencyType in varchar2 default null)
    return number
  as
    lPosFinalQty DOC_POSITION.POS_FINAL_QUANTITY%type;
  begin
    /* Recherche de la quantité finale de la position */
    lPosFinalQty  := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_POSITION', 'POS_FINAL_QUANTITY', iPositionID);
    /* Calcul de la valeur unitaire nette HT sans taxe de position type MP = valeur unitaire / quantité finale. */
    return getPosValueWithoutPMCharge(iPositionID => iPositionID, iCurrencyType => iCurrencyType) / greatest(nvl(lPosFinalQty, 1), 1);
  end getUnitPosValueWithoutPMCharge;

  /**
  * Description
  *    Retourne 1 si le pied du document logistique contient des remise de type matière précieuse.
  */
  function existFootPMDiscount(iDocumentID in DOC_FOOT.DOC_DOCUMENT_ID%type)
    return number
  as
    lExistFootPMDiscount number;
  begin
    select sign(count(fch.DOC_FOOT_CHARGE_ID) )
      into lExistFootPMDiscount
      from DOC_FOOT_CHARGE fch
         , DOC_FOOT foo
     where foo.DOC_DOCUMENT_ID = iDocumentID
       and foo.DOC_FOOT_ID = fch.DOC_FOOT_ID
       and fch.C_CHARGE_ORIGIN = 'PM'
       and fch.PTC_DISCOUNT_ID is not null;

    return lExistFootPMDiscount;
  end existFootPMDiscount;
end DOC_LIB_DISCOUNT_CHARGE;
