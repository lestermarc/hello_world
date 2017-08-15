--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_FCT" 
is
  /* Retourne la monnaie du tiers passé en param ou la monnaie de base*/
  function GetFinancialCurrency(
    pThirdId          DOC_INTERFACE.PAC_THIRD_ID%type
  , c_admin_domain in doc_gauge.c_admin_domain%type default '2'
  )
    return DOC_INTERFACE.ACS_FINANCIAL_CURRENCY_ID%type
  is
    cursor CUSTOMER_CURR(pThirdId DOC_INTERFACE.PAC_THIRD_ID%type)
    is
      select   AUX.ACS_FINANCIAL_CURRENCY_ID
          from ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , ACS_FINANCIAL_CURRENCY CUR
             , PAC_CUSTOM_PARTNER CUS
         where CUS.PAC_CUSTOM_PARTNER_ID = pThirdId
           and CUS.C_PARTNER_STATUS = '1'
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
           and CUR.ACS_FINANCIAL_CURRENCY_ID = AUX.ACS_FINANCIAL_CURRENCY_ID
      order by AUX.ASC_DEFAULT desc
             , CUR.FIN_LOCAL_CURRENCY desc;

    cursor supplier_curr(pThirdId doc_interface.pac_third_id%type)
    is
      select   aux.acs_financial_currency_id
          from acs_aux_account_s_fin_curr aux
             , acs_financial_currency cur
             , pac_supplier_partner sup
         where sup.pac_supplier_partner_id = pthirdid
           and sup.c_partner_status = '1'
           and aux.acs_auxiliary_account_id = sup.acs_auxiliary_account_id
           and cur.acs_financial_currency_id = aux.acs_financial_currency_id
      order by aux.asc_default desc
             , cur.fin_local_currency desc;

    vCurrencyId DOC_INTERFACE.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    if c_admin_domain = '2' then
      open CUSTOMER_CURR(pThirdId);

      fetch CUSTOMER_CURR
       into vCurrencyId;

      close CUSTOMER_CURR;
    elsif c_admin_domain = '1' then
      open supplier_CURR(pThirdId);

      fetch supplier_CURR
       into vCurrencyId;

      close supplier_CURR;
    end if;

    if vCurrencyId = 0 then
      vCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
    end if;

    return vCurrencyId;
  end GetFinancialCurrency;

  /**
  * Description
  *   Vérifie si la monnaie passée en paramètre est autorisée pour le tiers
  */
  function get_acs_financial_currency(
    aThirdId in DOC_INTERFACE.PAC_THIRD_ID%type
  , aCurrency in DOC_INTERFACE.DOI_CURRENCY%type
  , aAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type
  )
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    p_currencyId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    p_testCurrId    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    p_found         boolean;

    cursor customer_curr(pThirdId DOC_INTERFACE.PAC_THIRD_ID%type)
    is
      select   AUX.ACS_FINANCIAL_CURRENCY_ID
          from ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , ACS_FINANCIAL_CURRENCY CUR
             , PAC_CUSTOM_PARTNER CUS
         where CUS.PAC_CUSTOM_PARTNER_ID = pThirdId
           and CUS.C_PARTNER_STATUS = '1'
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
           and CUR.ACS_FINANCIAL_CURRENCY_ID = AUX.ACS_FINANCIAL_CURRENCY_ID
      order by AUX.ASC_DEFAULT desc
             , CUR.FIN_LOCAL_CURRENCY desc;

    cursor supplier_curr(pThirdId DOC_INTERFACE.PAC_THIRD_ID%type)
    is
      select   AUX.ACS_FINANCIAL_CURRENCY_ID
          from ACS_AUX_ACCOUNT_S_FIN_CURR AUX
             , ACS_FINANCIAL_CURRENCY CUR
             , PAC_SUPPLIER_PARTNER SUP
         where SUP.PAC_SUPPLIER_PARTNER_ID = pThirdId
           and SUP.C_PARTNER_STATUS = '1'
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
           and CUR.ACS_FINANCIAL_CURRENCY_ID = AUX.ACS_FINANCIAL_CURRENCY_ID
      order by AUX.ASC_DEFAULT desc
             , CUR.FIN_LOCAL_CURRENCY desc;
  begin
    -- Recherche de l'id correspondant à la monnaire passée en param
    select FIN.ACS_FINANCIAL_CURRENCY_ID
      into p_currencyId
      from ACS_FINANCIAL_CURRENCY FIN
         , PCS.PC_CURR CUR
     where FIN.PC_CURR_ID = CUR.PC_CURR_ID
       and CUR.CURRENCY = aCurrency;

    if p_currencyId is null then
      return null;
    end if;

    -- Vérifie si la monnaie est autorisée pour le tiers
    p_found := false;

    if aAdminDomain = '2' then
      open customer_curr(aThirdId);
      loop
        fetch customer_curr into p_testCurrId;
        p_found := p_testCurrId = p_currencyId;

        exit when customer_curr%notfound or p_found;
      end loop;
      close customer_curr;

    elsif aAdminDomain = '1' then
      open supplier_curr(aThirdId);
      loop
        fetch supplier_curr into p_testCurrId;
        p_found := p_testCurrId = p_currencyId;

        exit when supplier_curr%notfound or p_found;
      end loop;
      close supplier_curr;
    end if;

    if p_found then
      return p_currencyId;
    else
      return null;
    end if;
  end Get_acs_financial_currency;

  /*
  * Description
  *   Retourne l'id du correspondant à la description du gabarit passé en paramètre
  */
  function GetDefltGaugeId(pThirdId DOC_INTERFACE.PAC_THIRD_ID%type)
    return DOC_GAUGE.DOC_GAUGE_ID%type
  is
    vGaugeId     DOC_GAUGE.DOC_GAUGE_ID%type;
    vDfltGaugeId DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    vDfltGaugeId  := GetGaugeId(PCS.PC_CONFIG.GETCONFIG('DOC_CART_DEFAULT_GAUGE') );

    select GAU.DOC_GAUGE_ID
      into vGaugeId
      from DOC_GAUGE GAU
         , DOC_GAUGE_POSITION GAP
         , DOC_GAUGE_STRUCTURED GAS
     where GAU.DOC_GAUGE_ID = (select nvl(max(CUS.DOC_GAUGE_ID), vDfltGaugeId)
                                 from PAC_CUSTOM_PARTNER CUS
                                where PAC_CUSTOM_PARTNER_ID = pThirdId)
       and GAP.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
       and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
       and GAP.C_GAUGE_TYPE_POS(+) = PCS.PC_CONFIG.GETCONFIG('DOC_CART_TYP_POS')
       and GAP.GAP_DEFAULT(+) = 1;

    return vGaugeId;
  exception
    when no_data_found then
      return vDfltGaugeId;
  end GetDefltGaugeId;

  /*
  * Description
  *   Retourne l'id du correspondant à la description du gabarit passé en paramètre
  */
  function GetGaugeId(pGaugeDescr DOC_GAUGE.GAU_DESCRIBE%type)
    return DOC_GAUGE.DOC_GAUGE_ID%type
  is
    vGaugeId DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    select nvl(max(GAU.DOC_GAUGE_ID), 0)
      into vGaugeId
      from DOC_GAUGE GAU
     where GAU.GAU_DESCRIBE = pGaugeDescr;

    return vGaugeId;
  end GetGaugeId;

  /*
  * Description
  *   Génération d'un n° d'interface selon la numérotation définie dans le
  *   gabarit passé en paramètre
  */
  procedure SetNewInterfaceNumber(pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
  is
    vIncr        DOC_GAUGE_NUMBERING.GAN_RANGE_NUMBER%type;   /*Incrément de numérotation*/
    vLastNumber  DOC_GAUGE_NUMBERING.GAN_LAST_NUMBER%type;   /*Dernier numéro utilisé*/
    vNumberingId DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    /* Recherche dernier n° utilisé et incrément*/
    select GAN.DOC_GAUGE_NUMBERING_ID
         , GAN.GAN_LAST_NUMBER
         , GAN.GAN_RANGE_NUMBER
      into vNumberingId
         , vLastNumber
         , vIncr
      from DOC_GAUGE_NUMBERING GAN
         , DOC_GAUGE GAU
     where GAN.DOC_GAUGE_NUMBERING_ID = GAU.DOC_GAUGE_NUMBERING_ID
       and GAU.DOC_GAUGE_ID = pGaugeId;

    /*Mise à jour du denier n°*/
    update DOC_GAUGE_NUMBERING
       set GAN_LAST_NUMBER = vLastNumber + vIncr
     where DOC_GAUGE_NUMBERING_ID = vNumberingId;
  end SetNewInterfaceNumber;

  /*
  * Récupération du n° d'interface selon la numérotation définie dans le
  * gabarit passé en paramètre
  */
  function GetNewInterfaceNumber(pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
    return DOC_INTERFACE.DOI_NUMBER%type
  is
    vFormat     varchar2(20);   /*Variable pour le formatage du n°*/
    vI          integer;   /*Compteur*/
    vPrefix     DOC_GAUGE_NUMBERING.GAN_PREFIX%type;   /*Prefixe du numérotation*/
    vSuffix     DOC_GAUGE_NUMBERING.GAN_SUFFIX%type;   /*Sufixe de numératation*/
    vLength     DOC_GAUGE_NUMBERING.GAN_NUMBER%type;   /*Longueur de la chaine*/
    vLastNumber DOC_GAUGE_NUMBERING.GAN_LAST_NUMBER%type;   /*Dernier numéro utilisé*/
  begin
    /*Recherche données de numérotation pour retour du n° formaté*/
    select GAN.GAN_PREFIX
         , GAN.GAN_SUFFIX
         , GAN.GAN_LAST_NUMBER
         , GAN.GAN_NUMBER
      into vPrefix
         , vSuffix
         , vLastNumber
         , vLength
      from DOC_GAUGE_NUMBERING GAN
         , DOC_GAUGE GAU
     where GAN.DOC_GAUGE_NUMBERING_ID = GAU.DOC_GAUGE_NUMBERING_ID
       and GAU.DOC_GAUGE_ID = pGaugeId;

    vFormat  := '';
    vI       := 0;

    while(vI < vLength) loop
      vFormat  := vFormat || '0';
      vI       := vI + 1;
    end loop;

    if vLength = 0 then
      return vPrefix || to_char(vLastNumber) || vSuffix;
    else
      return vPrefix || ltrim(to_char( (vLastNumber), vFormat) ) || vSuffix;
    end if;
  end GetNewInterfaceNumber;

  /*
  * Description
  *   Retourne les champs du gabarit correspondant au gabarit passé en paramètre
  */
  procedure GetGaugeInfo(
    pGaugeId               in     DOC_GAUGE.DOC_GAUGE_ID%type
  , pGaugeDicTariffId      in out DOC_INTERFACE.DIC_TARIFF_ID%type
  , pGaugePacPaymentCondId in out DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
  , pGaugeFinPayment       in out DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
  )
  is
    /*Déclaration du curseur sur le gabarit*/
    cursor GaugeInfo(pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAP.DIC_TARIFF_ID
           , GAS.PAC_PAYMENT_CONDITION_ID
           , GAS.ACS_FIN_ACC_S_PAYMENT_ID
        from DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = pGaugeId
         and GAP.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    /* Déclaration de réception des données du curseur*/
    Gauge GaugeInfo%rowtype;
  begin
    /*Ouverture et réception des données du curseur*/
    open GaugeInfo(pGaugeId);

    fetch GaugeInfo
     into Gauge;

    pGaugeDicTariffId       := Gauge.DIC_TARIFF_ID;
    pGaugepacpaymentCondId  := Gauge.PAC_PAYMENT_CONDITION_ID;
    pGaugeFinPayment        := Gauge.ACS_FIN_ACC_S_PAYMENT_ID;

    close GaugeInfo;
  end GetGaugeInfo;

  /**
  * Description
  *   Retourne les champs du gabarit correspondant au gabarit passé en paramètre
  */
  procedure GetGaugeInfo(
    pGaugeId               in     DOC_GAUGE.DOC_GAUGE_ID%type
  , pGaugeDicTariffId      in out DOC_INTERFACE.DIC_TARIFF_ID%type
  , pGaugePacPaymentCondId in out DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
  , pGaugeFinPayment       in out DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
  , pAddressTypeId         in out DOC_GAUGE.DIC_ADDRESS_TYPE_ID%type
  , pAddressType1Id        in out DOC_GAUGE.DIC_ADDRESS_TYPE1_ID%type
  , pAddressType2Id        in out DOC_GAUGE.DIC_ADDRESS_TYPE2_ID%type
  , pAdminDomain           in out DOC_GAUGE.C_ADMIN_DOMAIN%type
  )
  is
    /*Déclaration du curseur sur le gabarit*/
    cursor GaugeInfo(pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select GAP.DIC_TARIFF_ID
           , GAS.PAC_PAYMENT_CONDITION_ID
           , GAS.ACS_FIN_ACC_S_PAYMENT_ID
           , GAU.DIC_ADDRESS_TYPE_ID
           , GAU.DIC_ADDRESS_TYPE1_ID
           , GAU.DIC_ADDRESS_TYPE2_ID
           , GAU.C_ADMIN_DOMAIN
        from DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = pGaugeId
         and GAP.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID(+) = GAU.DOC_GAUGE_ID;

    /* Déclaration de réception des données du curseur*/
    Gauge GaugeInfo%rowtype;
  begin
    /*Ouverture et réception des données du curseur*/
    open GaugeInfo(pGaugeId);

    fetch GaugeInfo
     into Gauge;

    pGaugeDicTariffId       := Gauge.DIC_TARIFF_ID;
    pGaugepacpaymentCondId  := Gauge.PAC_PAYMENT_CONDITION_ID;
    pGaugeFinPayment        := Gauge.ACS_FIN_ACC_S_PAYMENT_ID;
    pAddressTypeId          := Gauge.DIC_ADDRESS_TYPE_ID;
    pAddressType1Id         := Gauge.DIC_ADDRESS_TYPE1_ID;
    pAddressType2Id         := Gauge.DIC_ADDRESS_TYPE2_ID;
    pAdminDomain            := Gauge.C_ADMIN_DOMAIN;

    close GaugeInfo;
  end GetGaugeInfo;

  /*
  * Description
  *   Retourne les champs du tiers passé en paramètre
  */
  procedure GetCustomInfo(
    aThirdID                in     DOC_INTERFACE.PAC_THIRD_ID%type
  , aPerName                in out DOC_INTERFACE.DOI_PER_NAME%type
  , aPerShortName           in out DOC_INTERFACE.DOI_PER_SHORT_NAME%type
  , aPerKey1                in out DOC_INTERFACE.DOI_PER_KEY1%type
  , aPerKey2                in out DOC_INTERFACE.DOI_PER_KEY2%type
  , aDicTariffId            in out DOC_INTERFACE.DIC_TARIFF_ID%type
  , aPacPaymentConditionId  in out DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
  , aPacSendingConditionId  in out DOC_INTERFACE.PAC_SENDING_CONDITION_ID%type
  , aDicTypeSubmissionId    in out DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID%type
  , aAcsVatDetAccountId     in out DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID%type
  , aAcsFinAccSPaymentId    in out DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aPacAdressId            in out DOC_INTERFACE.PAC_ADDRESS_ID%type
  , aPacRepresentativeId    in out DOC_INTERFACE.PAC_REPRESENTATIVE_ID%type
  , aCTarificationMode      in out PAC_CUSTOM_PARTNER.C_TARIFFICATION_MODE%type
  , aDicComplementaryDataId in out PAC_CUSTOM_PARTNER.DIC_COMPLEMENTARY_DATA_ID%type
  , aCDeliveryTyp           in out PAC_CUSTOM_PARTNER.C_DELIVERY_TYP%type
  )
  is
    /*Déclaration du curseur sur le gabarit*/
    cursor CustomInfo(aThirdId number)
    is
      select PAC_PERSON2.PER_NAME
           , PAC_PERSON2.PER_SHORT_NAME
           , PAC_PERSON2.PER_KEY1
           , PAC_PERSON2.PER_KEY2
           , PAC_CUSTOM_PARTNER1.DIC_TARIFF_ID
           , PAC_CUSTOM_PARTNER1.PAC_PAYMENT_CONDITION_ID
           , PAC_CUSTOM_PARTNER1.C_TARIFFICATION_MODE
           , PAC_CUSTOM_PARTNER1.PAC_SENDING_CONDITION_ID
           , PAC_CUSTOM_PARTNER1.DIC_TYPE_SUBMISSION_ID
           , PAC_CUSTOM_PARTNER1.ACS_VAT_DET_ACCOUNT_ID
           , PAC_CUSTOM_PARTNER1.ACS_FIN_ACC_S_PAYMENT_ID
           , PAC_CUSTOM_PARTNER1.PAC_ADDRESS_ID
           , PAC_CUSTOM_PARTNER1.PAC_REPRESENTATIVE_ID
           , PAC_CUSTOM_PARTNER1.DIC_COMPLEMENTARY_DATA_ID
           , PAC_CUSTOM_PARTNER1.C_DELIVERY_TYP
        from PAC_CUSTOM_PARTNER PAC_CUSTOM_PARTNER1
           , PAC_PERSON PAC_PERSON2
           , PAC_ADDRESS PAC_ADDRESS5
           , PCS.PC_CNTRY PC_CNTRY6
       where PAC_PERSON2.PAC_PERSON_ID = aThirdId
         and PAC_CUSTOM_PARTNER1.PAC_CUSTOM_PARTNER_ID = PAC_PERSON2.PAC_PERSON_ID
         and PAC_PERSON2.PAC_PERSON_ID = PAC_ADDRESS5.PAC_PERSON_ID(+)
         and PAC_ADDRESS5.PC_CNTRY_ID = PC_CNTRY6.PC_CNTRY_ID(+);

    /* Déclaration de réception des données du curseur*/
    Custom CustomInfo%rowtype;
  begin
    /*Ouverture et réception des données du curseur*/
    open CustomInfo(aThirdID);

    fetch CustomInfo
     into Custom;

    aPerName                 := Custom.PER_NAME;
    aPerShortName            := Custom.PER_SHORT_NAME;
    aPerKey1                 := Custom.PER_KEY1;
    aPerKey2                 := Custom.PER_KEY2;
    aDicTariffId             := Custom.DIC_TARIFF_ID;
    aPacPaymentConditionId   := Custom.PAC_PAYMENT_CONDITION_ID;
    aCTarificationMode       := Custom.C_TARIFFICATION_MODE;
    aPacSendingConditionId   := Custom.PAC_SENDING_CONDITION_ID;
    aDicTypeSubmissionId     := Custom.DIC_TYPE_SUBMISSION_ID;
    aAcsVatDetAccountId      := Custom.ACS_VAT_DET_ACCOUNT_ID;
    aAcsFinAccSPaymentId     := Custom.ACS_FIN_ACC_S_PAYMENT_ID;
    aPacAdressId             := Custom.PAC_ADDRESS_ID;
    aPacRepresentativeId     := Custom.PAC_REPRESENTATIVE_ID;
    aDicComplementaryDataId  := Custom.DIC_COMPLEMENTARY_DATA_ID;
    aCDeliveryTyp            := Custom.C_DELIVERY_TYP;

    close CustomInfo;
  end GetCustomInfo;

  /*
  * Description
  *   Retourne les champs du tiers passé en paramètre
  */
  procedure GetSupplierInfo(
    aThirdID                in     DOC_INTERFACE.PAC_THIRD_ID%type
  , aPerName                in out DOC_INTERFACE.DOI_PER_NAME%type
  , aPerShortName           in out DOC_INTERFACE.DOI_PER_SHORT_NAME%type
  , aPerKey1                in out DOC_INTERFACE.DOI_PER_KEY1%type
  , aPerKey2                in out DOC_INTERFACE.DOI_PER_KEY2%type
  , aDicTariffId            in out DOC_INTERFACE.DIC_TARIFF_ID%type
  , aPacPaymentConditionId  in out DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type
  , aPacSendingConditionId  in out DOC_INTERFACE.PAC_SENDING_CONDITION_ID%type
  , aDicTypeSubmissionId    in out DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID%type
  , aAcsVatDetAccountId     in out DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID%type
  , aAcsFinAccSPaymentId    in out DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type
  , aPacAdressId            in out DOC_INTERFACE.PAC_ADDRESS_ID%type
  , aCTarificationMode      in out PAC_CUSTOM_PARTNER.C_TARIFFICATION_MODE%type
  , aDicComplementaryDataId in out PAC_CUSTOM_PARTNER.DIC_COMPLEMENTARY_DATA_ID%type
  , aCDeliveryTyp           in out PAC_CUSTOM_PARTNER.C_DELIVERY_TYP%type
  )
  is
    /*Déclaration du curseur sur le gabarit*/
    cursor SupplierInfo(aThirdId number)
    is
      select PER.PER_NAME
           , PER.PER_SHORT_NAME
           , PER.PER_KEY1
           , PER.PER_KEY2
           , SUP.DIC_TARIFF_ID
           , SUP.PAC_PAYMENT_CONDITION_ID
           , SUP.C_TARIFFICATION_MODE
           , SUP.PAC_SENDING_CONDITION_ID
           , SUP.DIC_TYPE_SUBMISSION_ID
           , SUP.ACS_VAT_DET_ACCOUNT_ID
           , SUP.ACS_FIN_ACC_S_PAYMENT_ID
           , SUP.PAC_ADDRESS_ID
           , SUP.DIC_COMPLEMENTARY_DATA_ID
           , SUP.C_DELIVERY_TYP
        from PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
           , PAC_ADDRESS ADR
           , PCS.PC_CNTRY CNT
       where PER.PAC_PERSON_ID = aThirdId
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID(+)
         and ADR.PC_CNTRY_ID = CNT.PC_CNTRY_ID(+);

    /* Déclaration de réception des données du curseur*/
    Supplier SupplierInfo%rowtype;
  begin
    /*Ouverture et réception des données du curseur*/
    open SupplierInfo(aThirdID);

    fetch SupplierInfo
     into Supplier;

    aPerName                 := Supplier.PER_NAME;
    aPerShortName            := Supplier.PER_SHORT_NAME;
    aPerKey1                 := Supplier.PER_KEY1;
    aPerKey2                 := Supplier.PER_KEY2;
    aDicTariffId             := Supplier.DIC_TARIFF_ID;
    aPacPaymentConditionId   := Supplier.PAC_PAYMENT_CONDITION_ID;
    aCTarificationMode       := Supplier.C_TARIFFICATION_MODE;
    aPacSendingConditionId   := Supplier.PAC_SENDING_CONDITION_ID;
    aDicTypeSubmissionId     := Supplier.DIC_TYPE_SUBMISSION_ID;
    aAcsVatDetAccountId      := Supplier.ACS_VAT_DET_ACCOUNT_ID;
    aAcsFinAccSPaymentId     := Supplier.ACS_FIN_ACC_S_PAYMENT_ID;
    aPacAdressId             := Supplier.PAC_ADDRESS_ID;
    aDicComplementaryDataId  := Supplier.DIC_COMPLEMENTARY_DATA_ID;
    aCDeliveryTyp            := Supplier.C_DELIVERY_TYP;

    close SupplierInfo;
  end GetSupplierInfo;

  /*
  * Description
  *   Retourne les adresses du tiers passé en paramètre selon les adresses gérés par le gabarit
  *   passé en paramètre
  */
  procedure GetThirdAddress(
    pThirdId     in     DOC_INTERFACE.PAC_THIRD_ID%type
  , pGaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , pAddressId1  in out DOC_INTERFACE.PAC_ADDRESS_ID%type
  , pDoiAddress1 in out DOC_INTERFACE.DOI_ADDRESS1%type
  , pDoiZipCode1 in out DOC_INTERFACE.DOI_ZIPCODE1%type
  , pDoiTown1    in out DOC_INTERFACE.DOI_TOWN1%type
  , pDoiState1   in out DOC_INTERFACE.DOI_STATE1%type
  , pCntryId1    in out DOC_INTERFACE.PC_CNTRY_ID%type
  , pLangId1     in out DOC_INTERFACE.PC_LANG_ID%type
  , pAddressId2  in out DOC_INTERFACE.PAC_PAC_ADDRESS_ID%type
  , pDoiAddress2 in out DOC_INTERFACE.DOI_ADDRESS2%type
  , pDoiZipCode2 in out DOC_INTERFACE.DOI_ZIPCODE2%type
  , pDoiTown2    in out DOC_INTERFACE.DOI_TOWN2%type
  , pDoiState2   in out DOC_INTERFACE.DOI_STATE2%type
  , pCntryId2    in out DOC_INTERFACE.PC__PC_CNTRY_ID%type
  , pAddressId3  in out DOC_INTERFACE.PAC2_PAC_ADDRESS_ID%type
  , pDoiAddress3 in out DOC_INTERFACE.DOI_ADDRESS3%type
  , pDoiZipCode3 in out DOC_INTERFACE.DOI_ZIPCODE3%type
  , pDoiTown3    in out DOC_INTERFACE.DOI_TOWN3%type
  , pDoiState3   in out DOC_INTERFACE.DOI_STATE3%type
  , pCntryId3    in out DOC_INTERFACE.PC_2_PC_CNTRY_ID%type
  )
  is
    /*Déclaration du curseur sur le s adresses*/
    cursor ThirdAddress(pThirdId DOC_INTERFACE.PAC_THIRD_ID%type, pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select 1 AD_LEVEL
           , PAC_ADDRESS_ID
           , PAC_ADDRESS.DIC_ADDRESS_TYPE_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , PC_CNTRY_ID
           , PC_LANG_ID
        from PAC_ADDRESS
           , DOC_GAUGE
       where PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = DOC_GAUGE.DIC_ADDRESS_TYPE_ID
         and DOC_GAUGE.DOC_GAUGE_ID = pGaugeId
         and PAC_ADDRESS.PAC_PERSON_ID = pThirdId
      union
      select 2 AD_LEVEL
           , PAC_ADDRESS_ID
           , PAC_ADDRESS.DIC_ADDRESS_TYPE_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , PC_CNTRY_ID
           , PC_LANG_ID
        from PAC_ADDRESS
           , DOC_GAUGE
       where PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = DOC_GAUGE.DIC_ADDRESS_TYPE1_ID
         and DOC_GAUGE.DOC_GAUGE_ID = pGaugeId
         and PAC_ADDRESS.PAC_PERSON_ID = pThirdId
      union
      select 3 AD_LEVEL
           , PAC_ADDRESS_ID
           , PAC_ADDRESS.DIC_ADDRESS_TYPE_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , PC_CNTRY_ID
           , PC_LANG_ID
        from PAC_ADDRESS
           , DOC_GAUGE
       where PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = DOC_GAUGE.DIC_ADDRESS_TYPE2_ID
         and DOC_GAUGE.DOC_GAUGE_ID = pGaugeId
         and PAC_ADDRESS.PAC_PERSON_ID = pThirdId
      union
      select 4 AD_LEVEL
           , PAC_ADDRESS_ID
           , PAC_ADDRESS.DIC_ADDRESS_TYPE_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , PC_CNTRY_ID
           , PC_LANG_ID
        from PAC_ADDRESS
           , DOC_GAUGE
       where PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = (select DIC_ADDRESS_TYPE_ID
                                                  from DIC_ADDRESS_TYPE
                                                 where DAD_DEFAULT = 1)
         and PAC_ADDRESS.PAC_PERSON_ID = pThirdId;

    /* Déclaration de réception des données du curseur*/
    Address ThirdAddress%rowtype;
  begin
    /*ouverture du curseur sur les adresses*/
    open ThirdAddress(pThirdId, pGaugeId);

    fetch ThirdAddress
     into Address;

    while ThirdAddress%found loop
      if Address.AD_LEVEL = 1 then
        pAddressId1   := Address.PAC_ADDRESS_ID;
        pDoiAddress1  := Address.ADD_ADDRESS1;
        pDoiZipCode1  := Address.ADD_ZIPCODE;
        pDoiTown1     := Address.ADD_CITY;
        pDoiState1    := Address.ADD_STATE;
        pCntryId1     := Address.PC_CNTRY_ID;
        pLangId1      := Address.PC_LANG_ID;
      end if;

      if Address.AD_LEVEL = 2 then
        pAddressId2   := Address.PAC_ADDRESS_ID;
        pDoiAddress2  := Address.ADD_ADDRESS1;
        pDoiZipCode2  := Address.ADD_ZIPCODE;
        pDoiTown2     := Address.ADD_CITY;
        pDoiState2    := Address.ADD_STATE;
        pCntryId2     := Address.PC_CNTRY_ID;
      end if;

      if Address.AD_LEVEL = 3 then
        pAddressId3   := Address.PAC_ADDRESS_ID;
        pDoiAddress3  := Address.ADD_ADDRESS1;
        pDoiZipCode3  := Address.ADD_ZIPCODE;
        pDoiTown3     := Address.ADD_CITY;
        pDoiState3    := Address.ADD_STATE;
        pCntryId3     := Address.PC_CNTRY_ID;
      end if;

      /*Si pas d'adresse principale on récupère l'adresse par défaut*/
      if     (pAddressId1 is null)
         and (Address.AD_LEVEL = 4) then
        pAddressId1   := Address.PAC_ADDRESS_ID;
        pDoiAddress1  := Address.ADD_ADDRESS1;
        pDoiZipCode1  := Address.ADD_ZIPCODE;
        pDoiTown1     := Address.ADD_CITY;
        pDoiState1    := Address.ADD_STATE;
        pCntryId1     := Address.PC_CNTRY_ID;
        pLangId1      := Address.PC_LANG_ID;
      end if;

      fetch ThirdAddress
       into Address;
    end loop;

    close ThirdAddress;
  end GetThirdAddress;

end DOC_INTERFACE_FCT;
