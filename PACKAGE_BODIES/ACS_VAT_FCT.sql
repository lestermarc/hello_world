--------------------------------------------------------
--  DDL for Package Body ACS_VAT_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_VAT_FCT" 
is
  /**
  * Détermine les informations liés à la TVA en fonction d'un contexte
  */
  procedure GetVATInformations(
    aContext     in     number
  , aGaugeID     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aThirdID     in     PAC_THIRD.PAC_THIRD_ID%type
  , aGoodID      in     GCO_GOOD.GCO_GOOD_ID%type
  , aDiscountID  in     PTC_DISCOUNT.PTC_DISCOUNT_ID%type
  , aChargeID    in     PTC_CHARGE.PTC_CHARGE_ID%type
  , aIncludedVat in     varchar2
  , aDate        in     date default sysdate
  , aTaxCodeID   in out ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  , aAmount      in out number
  , aVatAmount   in out number
  )
  is
    gasVAT          DOC_GAUGE_STRUCTURED.GAS_VAT%type;
    dicTypeMovement DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    cAdminDomain    DOC_GAUGE.C_ADMIN_DOMAIN%type;
  begin
    aVatAmount  := 0;

    -- Détermine si le gabarit gère la TVA.
    begin
      select nvl(GAS.GAS_VAT, 0)
           , GAS.DIC_TYPE_MOVEMENT_ID
           , GAU.C_ADMIN_DOMAIN
        into gasVAT
           , dicTypeMovement
           , cAdminDomain
        from DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = aGaugeID
         and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;
    exception
      when no_data_found then
        gasVAT  := 0;
    end;

    if (gasVAT = 1) then
      -- Recherche le code Taxe
      aTaxCodeID  :=
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(aContext
                                              , aThirdID
                                              , aGoodID
                                              , aDiscountID
                                              , aChargeID
                                              , cAdminDomain
                                              , null
                                              , dicTypeMovement
                                              , null
                                               );

      if aTaxCodeID is not null then
        aVatAmount  :=
          ACS_FUNCTION.CalcVatAmount(aLiabledAmount   => aAmount
                                   , aTaxCodeId       => aTaxCodeID
                                   , aIE              => aIncludedVat
                                   , aDateRef         => nvl(aDate, sysdate)
                                   , aRound           => 2   -- Arrondi logistique dans ce contexte
                                    );
      end if;
    else   -- (gasVAT = 0)
      aTaxCodeID  := null;
    end if;
  end GetVATInformations;
end ACS_VAT_FCT;
