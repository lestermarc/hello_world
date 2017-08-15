--------------------------------------------------------
--  DDL for Package Body DOC_EXTRACT_COMMISSION_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EXTRACT_COMMISSION_FCT" 
is
  procedure GenerateCommissionDocuments(
    aGaugeID      in DOC_GAUGE.DOC_GAUGE_ID%type
  , aReprFrom     in varchar2
  , aReprTo       in varchar2
  , aBonus        in integer
  , aDocDate      in date
  , aValueDate    in date
  , aDeliveryDate in date
  )
  is
    -- Liste des commissions à traiter
    cursor crExtractCommissionList
    is
      select   DEX.DEC_REP_CUSTOMER_ID
             , DEX.DEC_FINANCIAL_CURRENCY_ID
             , DEX.DOC_EXTRACT_COMMISSION_ID
             , DEX.DEC_GOOD_ID
             , DEX.DEC_COM_VALUE
             , DEX.DEC_TAX_CODE_ID
             , decode(nvl(DEX.DEC_GOOD_ID, -1), -1, '5', '1') C_GAUGE_TYPE_POS
             , DEX.DMT_NUMBER || decode(DEX.POS_NUMBER, null, null, '/') || DEX.POS_NUMBER POS_LONG_DESCRIPTION
          from DOC_EXTRACT_COMMISSION DEX
             , PAC_REPRESENTATIVE REP
             , PAC_CUSTOM_PARTNER CUS
         where DEX.DEC_DOC_GENERATED = 0
           and (    (    DEX.DOC_BONUS_ORIGIN_ID is null
                     and aBonus = 0)
                or (    DEX.DOC_BONUS_ORIGIN_ID is not null
                    and aBonus = 1) )
           and DEX.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID
           and REP.C_PARTNER_STATUS = '1'
           and REP.REP_DESCR >= aReprFrom
           and REP.REP_DESCR <= aReprTo
           and CUS.PAC_CUSTOM_PARTNER_ID = DEX.DEC_REP_CUSTOMER_ID
           and CUS.C_PARTNER_STATUS = '1'
      order by DEX.DEC_REP_CUSTOMER_ID asc
             , DEX.DEC_FINANCIAL_CURRENCY_ID asc
             , DEX.DMT_NUMBER asc
             , DEX.POS_NUMBER asc;

    Old_DEC_REP_CUSTOMER_ID       DOC_EXTRACT_COMMISSION.DEC_REP_CUSTOMER_ID%type;
    Old_DEC_FINANCIAL_CURRENCY_ID DOC_EXTRACT_COMMISSION.DEC_FINANCIAL_CURRENCY_ID%type;
    newDOC_DOCUMENT_ID            DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    Old_DEC_REP_CUSTOMER_ID        := -1;
    Old_DEC_FINANCIAL_CURRENCY_ID  := -1;

    for tplExtractCommissionList in crExtractCommissionList loop
      -- Changement dans la clé de regroupement de document, création d'un nouveau document
      if    (Old_DEC_REP_CUSTOMER_ID <> tplExtractCommissionList.DEC_REP_CUSTOMER_ID)
         or (Old_DEC_FINANCIAL_CURRENCY_ID <> tplExtractCommissionList.DEC_FINANCIAL_CURRENCY_ID) then
        -- Finalisation du document avant de passer à la création du suivant
        if newDOC_DOCUMENT_ID is not null then
          DOC_FINALIZE.FinalizeDocument(newDOC_DOCUMENT_ID);
          commit;
        end if;

        newDOC_DOCUMENT_ID                                              := null;
        -- Effacer les données de la variable
        DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
        -- La variable ne doit pas être réinitialisée dans la méthode de création
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO        := 0;
        -- Monnaie du document
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DOC_CURRENCY           := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.ACS_FINANCIAL_CURRENCY_ID  := tplExtractCommissionList.DEC_FINANCIAL_CURRENCY_ID;
        -- Date valeur
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE         := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE             := trunc(aValueDate);
        -- Date de livraison
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY      := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY          := trunc(aDeliveryDate);
        -- Création du document
        DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => newDOC_DOCUMENT_ID
                                             , aMode            => '180'
                                             , aGaugeID         => aGaugeID
                                             , aThirdID         => tplExtractCommissionList.DEC_REP_CUSTOMER_ID
                                             , aDocDate         => trunc(aDocDate)
                                              );
        commit;
        -- Sauvegarde des variables de changement de document
        Old_DEC_REP_CUSTOMER_ID                                         := tplExtractCommissionList.DEC_REP_CUSTOMER_ID;
        Old_DEC_FINANCIAL_CURRENCY_ID                                   := tplExtractCommissionList.DEC_FINANCIAL_CURRENCY_ID;
      end if;

      declare
        newDOC_POSITION_ID DOC_POSITION.DOC_POSITION_ID%type;
      begin
        -- Effacer les données de la variable
        DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
        -- La variable ne doit pas être réinitialisée dans la méthode de création
        DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO            := 0;
        -- ID de l'extraction de commission
        DOC_POSITION_INITIALIZE.PositionInfo.USE_DOC_EXTRACT_COMMISSION_ID  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.DOC_EXTRACT_COMMISSION_ID      := tplExtractCommissionList.DOC_EXTRACT_COMMISSION_ID;

        -- Code TVA de la position
        if tplExtractCommissionList.DEC_TAX_CODE_ID is not null then
          DOC_POSITION_INITIALIZE.PositionInfo.USE_ACS_TAX_CODE_ID  := 1;
          DOC_POSITION_INITIALIZE.PositionInfo.ACS_TAX_CODE_ID      := tplExtractCommissionList.DEC_TAX_CODE_ID;
        end if;

        -- Description longue de la position
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION       := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION           := tplExtractCommissionList.POS_LONG_DESCRIPTION;
        -- Création de la position
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => newDOC_POSITION_ID
                                             , aDocumentID       => newDOC_DOCUMENT_ID
                                             , aPosCreateMode    => '180'
                                             , aTypePos          => tplExtractCommissionList.C_GAUGE_TYPE_POS
                                             , aGoodID           => tplExtractCommissionList.DEC_GOOD_ID
                                             , aBasisQuantity    => 1
                                             , aGoodPrice        => tplExtractCommissionList.DEC_COM_VALUE
                                             , aGenerateDetail   => 1
                                              );

        -- Màj de la ligne d'extraction traitée
        update DOC_EXTRACT_COMMISSION
           set DEC_DOC_GENERATED = 1
             , DEC_DOCUMENT_ID = newDOC_DOCUMENT_ID
             , DEC_POSITION_ID = newDOC_POSITION_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_EXTRACT_COMMISSION_ID = tplExtractCommissionList.DOC_EXTRACT_COMMISSION_ID;

        commit;
      end;
    end loop;

    -- Finalisation du document
    if newDOC_DOCUMENT_ID is not null then
      DOC_FINALIZE.FinalizeDocument(newDOC_DOCUMENT_ID);
      commit;
    end if;
  end GenerateCommissionDocuments;
end DOC_EXTRACT_COMMISSION_FCT;
