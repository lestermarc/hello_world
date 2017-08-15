--------------------------------------------------------
--  DDL for Package Body DOC_XML_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_XML_FUNCTIONS" 
as
  /**
  * procedure GenDocXmlExchSystem
  * Description
  *   Méthode pour générer un xml avec les données du document selon
  *   le système d'échange définit sur le document
  */
  procedure GenDocXmlExchSystem(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aClob out clob)
  is
    -- Informations sur le système d'échange des données
    cursor crExchSystemInfo
    is
      select ECS.C_ECS_BSP
           , ECS.C_ECS_VERSION
           , ECS.C_ECS_BILL_PRESENTMENT
        from DOC_DOCUMENT DMT
           , COM_EBANKING CEB
           , PCS.PC_EXCHANGE_SYSTEM ECS
       where DMT.DOC_DOCUMENT_ID = aDocumentID
         and DMT.DOC_DOCUMENT_ID = CEB.DOC_DOCUMENT_ID
         and CEB.C_CEB_EBANKING_STATUS in('002', '003')
         and DMT.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

    tplExchSystemInfo crExchSystemInfo%rowtype;
  begin
    begin
      open crExchSystemInfo;

      fetch crExchSystemInfo
       into tplExchSystemInfo;

      if crExchSystemInfo%found then
        -- Prestataire : 00 -> EBPP YellowBill (YB)
        if tplExchSystemInfo.C_ECS_BSP = '00' then
          -- EBPP YellowBill - Version 1.2
          if tplExchSystemInfo.C_ECS_VERSION = '001' then
            aClob  := DOC_XML_YELLOWBILL_FUNCTIONS.GetYB12_Clob(aDocumentID);
          end if;
        -- Prestataire : 01 -> EBPP PayNet (PN)
        elsif tplExchSystemInfo.C_ECS_BSP = '01' then
          aClob  := DOC_XML_PAYNET_FUNCTIONS.GetPayNet2003A_Clob(aDocumentID);
        end if;

        -- XML généré correctement
        if aClob is not null then
          update COM_EBANKING
             set CEB_XML_DOCUMENT = aClob
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , A_DATEMOD = sysdate
           where DOC_DOCUMENT_ID = aDocumentID;
        end if;
      end if;

      close crExchSystemInfo;
    exception
      when others then
        aClob  := null;
    end;
  end GenDocXmlExchSystem;
end DOC_XML_FUNCTIONS;
