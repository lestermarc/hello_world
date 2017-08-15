--------------------------------------------------------
--  DDL for Package Body DOC_LIB_GAUGE_WARNINGS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_GAUGE_WARNINGS" 
is
  /**
  * Description
  *   Recherche l'existente d'avertissement au niveau du flux
  *
  */
  function GetGaugeWarnings(iGaugeFlowId in DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type)
    return number
  is
    ln_Warnings number;
  begin
    select nvl(max(1), 0)
      into ln_Warnings
      from DOC_GAUGE_FLOW_WARNINGS GAW
     where GAW.DOC_GAUGE_FLOW_ID = iGaugeFlowId;

    return ln_warnings;
  end GetGaugeWarnings;

  /**
  * Description
  *   Recherche l'existente d'avertissement au niveau du flux de document dans le contexte de la copie
  *
  */
  function GetGaugeCopyWarnings(iGaugeFlowDocumId in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type)
    return number
  is
    ln_Warnings number(1);
  begin
    select nvl(max(1), 0)
      into ln_Warnings
      from DOC_GAUGE_FLOW_WARNINGS GAW
     where GAW.DOC_GAUGE_FLOW_DOCUM_ID = iGaugeFlowDocumId
       and GAW.DOC_GAUGE_COPY_ID is not null;

    return ln_warnings;
  end GetGaugeCopyWarnings;

  /**
  * Description
  *   Recherche l'existente d'avertissement au niveau du flux de document dans le contexte de la décharge
  *
  */
  function GetGaugeReceiptWarnings(iGaugeFlowDocumId in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type)
    return number
  is
    ln_Warnings number;
  begin
    select nvl(max(1), 0)
      into ln_Warnings
      from DOC_GAUGE_FLOW_WARNINGS GAW
     where GAW.DOC_GAUGE_FLOW_DOCUM_ID = iGaugeFlowDocumId
       and GAW.DOC_GAUGE_RECEIPT_ID is not null;

    return ln_warnings;
  end GetGaugeReceiptWarnings;

  /**
  * Description
  *   Défini le contexte de l'avertissement
  *
  */
  function GetGaugeWarningContext(
    iGaugeFlowDocumId in DOC_GAUGE_FLOW_DOCUM.DOC_GAUGE_FLOW_DOCUM_ID%type
  , iGaugeCopyId      in DOC_GAUGE_COPY.DOC_GAUGE_COPY_ID%type
  , iGaugeReceiptId   in DOC_GAUGE_RECEIPT.DOC_GAUGE_RECEIPT_ID%type
  , iContext          in varchar2
  , iMeaningContext   in number
  )
    return varchar2
  is
    lv_GaugeDescribe       DOC_GAUGE.GAU_DESCRIBE%type;
    lv_GaugeDescribeTarget DOC_GAUGE.GAU_DESCRIBE%type;
    lv_Context             varchar2(150);
  begin
    select max(GAU_DESCRIBE)
      into lv_GaugeDescribe
      from DOC_GAUGE GAU
         , DOC_GAUGE_FLOW_DOCUM GAD
     where GAD.DOC_GAUGE_FLOW_DOCUM_ID = iGaugeFlowDocumId
       and GAD.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    if iGaugeCopyId <> 0 then
      select max(GAU_DESCRIBE)
        into lv_GaugeDescribeTarget
        from DOC_GAUGE GAU
           , DOC_GAUGE_COPY GAC
       where GAC.DOC_GAUGE_COPY_ID = iGaugeCopyId
         and GAU.DOC_GAUGE_ID = GAC.DOC_DOC_GAUGE_ID;
    else
      select max(GAU_DESCRIBE)
        into lv_GaugeDescribeTarget
        from DOC_GAUGE GAU
           , DOC_GAUGE_RECEIPT GAR
       where GAR.DOC_GAUGE_RECEIPT_ID = iGaugeReceiptId
         and GAU.DOC_GAUGE_ID = GAR.DOC_DOC_GAUGE_ID;
    end if;

    if iMeaningContext = 0 then
      lv_Context  := lv_GaugeDescribe || ' ' || iContext || ' ' || lv_GaugeDescribeTarget;
    else
      lv_Context  := lv_GaugeDescribeTarget || ' ' || iContext || ' ' || lv_GaugeDescribe;
    end if;

    return lv_context;
  exception
    when no_data_found then
      return null;
  end GetGaugeWarningContext;
end DOC_LIB_GAUGE_WARNINGS;
