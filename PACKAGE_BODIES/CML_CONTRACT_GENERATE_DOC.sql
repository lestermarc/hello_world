--------------------------------------------------------
--  DDL for Package Body CML_CONTRACT_GENERATE_DOC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CML_CONTRACT_GENERATE_DOC" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de génération des documents à partir du module CML
  */
  procedure GenerateDocumentCML(
    aPositionId   in     CML_POSITION.CML_POSITION_ID%type
  , aDocumentId   in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aDocGaugeId   in     DOC_DOCUMENT.DOC_GAUGE_ID%type
  , aDocumentDate in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aDateValue    in     DOC_DOCUMENT.DMT_DATE_VALUE%type
  , aDateDelivery in     DOC_DOCUMENT.DMT_DATE_DELIVERY%type
  )
  is
  begin
    Doc_Document_Generate.ResetDocumentInfo(Doc_Document_Initialize.DocumentInfo);
    Doc_Document_Initialize.DocumentInfo.CLEAR_DOCUMENT_INFO    := 0;
    Doc_Document_Initialize.DocumentInfo.USE_CML_POSITION_ID    := 1;
    Doc_Document_Initialize.DocumentInfo.CML_POSITION_ID        := aPositionId;
    Doc_Document_Initialize.DocumentInfo.USE_DMT_DATE_VALUE     := 1;
    Doc_Document_Initialize.DocumentInfo.DMT_DATE_VALUE         := trunc(aDateValue);
    Doc_Document_Initialize.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
    Doc_Document_Initialize.DocumentInfo.DMT_DATE_DELIVERY      := trunc(aDateDelivery);
    Doc_Document_Generate.GenerateDocument(aNewDocumentID => aDocumentId, aMode => '160', aGaugeID => aDocGaugeId, aDocDate => trunc(aDocumentDate) );
  end GenerateDocumentCML;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de génération des positions à partir du module CML
  */
  procedure GeneratePositionCML(
    aPositionId        in out DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentId        in     DOC_POSITION.DOC_DOCUMENT_ID%type
  , aGgeTypPos         in     DOC_POSITION.C_GAUGE_TYPE_POS%type
  , aGoodId            in     DOC_POSITION.GCO_GOOD_ID%type
  , aPosBodyText       in     DOC_POSITION.POS_BODY_TEXT%type
  , aContractId        in     DOC_POSITION.CML_POSITION_ID%type
  , aQuantity          in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , aGrossUnitVal      in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , aCostPrice         in     DOC_POSITION.POS_UNIT_COST_PRICE%type
  , aDelay             in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aCML_EVENTS_ID     in     CML_EVENTS.CML_EVENTS_ID%type
  , aExtractionType    in     number
  , aDateFrom          in     date
  , aDateTo            in     date
  , FMultiply          in     number
  , FNewIndiceDate     in     date
  , FNewIndiceVariable in     number
  )
  is
    vGoodId  GCO_GOOD.GCO_GOOD_ID%type;
    vDateDoc DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vCurrId  DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    aPositionId                                               := null;
    Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
    Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO  := 0;

    -- Position CML
    if aContractId is not null then
      Doc_Position_Initialize.PositionInfo.USE_CML_POSITION_ID  := 1;
      Doc_Position_Initialize.PositionInfo.CML_POSITION_ID      := aContractId;
    end if;

    -- Evénement
    if nvl(aCML_EVENTS_ID, 0) <> 0 then
      Doc_Position_Initialize.PositionInfo.USE_CML_EVENTS_ID  := 1;
      Doc_Position_Initialize.PositionInfo.CML_EVENTS_ID      := aCML_EVENTS_ID;
    end if;

    if aGoodId = 0 then
      vGoodId  := null;
    else
      vGoodId  := aGoodId;
    end if;

    Doc_Position_Generate.GeneratePosition(aPositionID       => aPositionId
                                         , aDocumentID       => aDocumentId
                                         , aPosCreateMode    => '160'
                                         , aTypePos          => aGgeTypPos
                                         , aGoodID           => vGoodId
                                         , aPosBodyText      => aPosBodyText
                                         , aBasisQuantity    => aQuantity
                                         , aUnitCostPrice    => aCostPrice
                                         , aGoodPrice        => aGrossUnitVal * FMultiply
                                         , aGenerateDetail   => 1
                                         , aBasisDelay       => trunc(aDelay)
                                         , aInterDelay       => trunc(aDelay)
                                         , aFinalDelay       => trunc(aDelay)
                                          );

    if aGgeTypPos <> '4' then
      -- Mise à jour de la table CML_GEN_DOC
      select DMT_DATE_DOCUMENT
           , ACS_FINANCIAL_CURRENCY_ID
        into vDateDoc
           , vCurrId
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentId;

      UpdateCML_GEN_DOC(aContractId
                      , aCML_EVENTS_ID
                      , aPositionId
                      , vDateDoc
                      , aExtractionType
                      , aGrossUnitVal
                      , vCurrId
                      , aDateFrom
                      , aDateTo
                      , FMultiply
                      , FNewIndiceDate
                      , FNewIndiceVariable
                       );
    end if;
  end GeneratePositionCML;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de mise à jour de la table CML_GEN_DOC
  */
  procedure UpdateCML_GEN_DOC(
    aCML_POSITION_ID           in CML_POSITION.CML_POSITION_ID%type
  , aCML_EVENTS_ID             in CML_EVENTS.CML_EVENTS_ID%type
  , aDOC_POSITION_ID           in DOC_POSITION.DOC_POSITION_ID%type
  , aDateDoc                   in CML_GEN_DOC.CGD_DATEDOC%type
  , aExtractionType            in number
  , aValue                     in CML_GEN_DOC.CGD_VALUE%type
  , aACS_FINANCIAL_CURRENCY_ID in CML_GEN_DOC.ACS_FINANCIAL_CURRENCY_ID%type
  , aDateDe                    in CML_GEN_DOC.CGD_DATEBEGIN%type
  , aDateA                     in CML_GEN_DOC.CGD_DATEEND%type
  , FMultiply                  in number
  , FNewIndiceDate             in date
  , FNewIndiceVariable         in number
  )
  is
    intSeq        CML_GEN_DOC.CGD_SEQUENCE%type;
    bUpdateIndice number(1);

    cursor crIndice
    is
      select CEV.CEV_USE_INDICE
           , CPO.CPO_INDICE
           , CPO.CPO_INDICE_VARIABLE
           , CPO.CPO_INDICE_V_DATE
        from CML_POSITION CPO
           , CML_EVENTS CEV
       where CPO.CML_POSITION_ID = aCML_POSITION_ID
         and CEV.CML_EVENTS_ID = aCML_EVENTS_ID;

    tplIndice     crIndice%rowtype;
  begin
    if aExtractionType in(3, 4) then
      bUpdateIndice  := 1;
    else
      bUpdateIndice  := 0;
    end if;

    if (aCML_EVENTS_ID > 0) then
      open crIndice;

      fetch crIndice
       into tplIndice;

      if crIndice%found then
        if (tplIndice.CEV_USE_INDICE = 1) then
          bUpdateIndice  := 1;
        else
          bUpdateIndice  := 0;
        end if;

        if bUpdateIndice = 1 then
          update CML_EVENTS
             set DOC_POSITION_ID = aDOC_POSITION_ID
               , CEV_AMOUNT_DOC = aValue
               , CEV_INDICE = tplIndice.CPO_INDICE
               , CEV_INDICE_VARIABLE = FNewIndiceVariable
               , CEV_INDICE_V_DATE = FNewIndiceDate
               , A_DATEMOD = sysdate
               , A_IDMOD = pcs.PC_I_LIB_SESSION.getUserIni
           where CML_EVENTS_ID = aCML_EVENTS_ID;
        else
          update CML_EVENTS
             set DOC_POSITION_ID = aDOC_POSITION_ID
               , CEV_AMOUNT_DOC = aValue
               , A_DATEMOD = sysdate
               , A_IDMOD = pcs.PC_I_LIB_SESSION.getUserIni
           where CML_EVENTS_ID = aCML_EVENTS_ID;
        end if;
      end if;

      close crIndice;
    end if;

    select nvl(max(CGD_SEQUENCE), 0) + 1
      into intSeq
      from CML_GEN_DOC
     where CML_POSITION_ID = aCML_POSITION_ID;

    insert into CML_GEN_DOC
                (CML_POSITION_ID
               , CML_EVENTS_ID
               , DOC_POSITION_ID
               , CGD_SEQUENCE
               , CGD_DESCR
               , CGD_VALUE
               , CGD_MULTIPLY
               , ACS_FINANCIAL_CURRENCY_ID
               , CGD_DATEDOC
               , CGD_DATEBEGIN
               , CGD_DATEEND
               , CGD_INDICE
               , CGD_INDICE_VARIABLE
               , CGD_INDICE_V_DATE
               , CGD_EXTRACTION_TYPE
               , A_DATECRE
               , A_IDCRE
                )
      select aCML_POSITION_ID
           , decode(aCML_EVENTS_ID, 0, null, aCML_EVENTS_ID)
           , aDOC_POSITION_ID
           , intSEQ
           , decode(FMultiply, 1, pcs.pc_functions.TranslateWord('Facture'), pcs.pc_functions.TranslateWord('Note de crédit') ) ||
             ' : ' ||
             decode(aExtractionType
                  , 1, pcs.pc_functions.TranslateWord('dépot')
                  , 2, pcs.pc_functions.TranslateWord('solde (pénalité - dépot)')
                  , 3, pcs.pc_functions.TranslateWord('périodique')
                   ) ||
             case
               when aCML_EVENTS_ID > 0 then ' / ' || pcs.pc_functions.TranslateWord('Evénement N°') || ' : ' || (select to_char(CEV_SEQUENCE)
                                                                                                                   from CML_EVENTS
                                                                                                                  where CML_EVENTS_ID = aCML_EVENTS_ID)
               else ''
             end
           , aValue
           , FMultiply
           , aACS_FINANCIAL_CURRENCY_ID
           , aDateDoc
           , aDateDe
           , aDateA
           , decode(bUpdateIndice, 1, CPO.CPO_INDICE, null)
           , decode(bUpdateIndice, 1, decode(FNewIndiceVariable, 0, null, FNewIndiceVariable), null)
           , decode(bUpdateIndice, 1, FNewIndiceDate, null)
           , aExtractionType
           , sysdate
           , pcs.PC_I_LIB_SESSION.getUserIni
        from CML_POSITION CPO
       where CPO.CML_POSITION_ID = aCML_POSITION_ID;

    if     (bUpdateIndice = 1)
       and (nvl(aCML_EVENTS_ID, 0) = 0) then
      update CML_POSITION
         set CPO_INDICE_VARIABLE = FNewIndiceVariable
           , CPO_INDICE_V_DATE = FNewIndiceDate
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.getUserIni
       where CML_POSITION_ID = aCML_POSITION_ID;
    end if;
  end UpdateCML_GEN_DOC;
end Cml_Contract_Generate_Doc;
