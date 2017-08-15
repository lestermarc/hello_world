--------------------------------------------------------
--  DDL for Package Body DOC_PRC_SAFT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_SAFT" 
as
  /**
   * Description :
   *    Met à jour la signature du document dont l'ID est transmis en paramètre
   */
  procedure SetSAFTKey(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  as
    lSAFTKey   DOC_DOCUMENT.DMT_SAFT_KEY%type;
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lDateMod   DOC_DOCUMENT.A_DATEMOD%type;
  begin
    /* Génération de la signature */
    lSAFTKey  :=
      DOC_LIB_SAFT.generateSAFTKey(iInvoiceDate       => DOC_LIB_SAFT.getInvoiceDate(iDocumentID)
                                 , iSysTemEntryDate   => DOC_LIB_SAFT.getSysTemEntryDate(iDocumentID)
                                 , iInvoiceNo         => DOC_LIB_SAFT.getInvoiceNo(iDocumentID)
                                 , iGrossTotal        => DOC_LIB_SAFT.getGrossTotal(iDocumentID)
                                 , iPreviousHash      => DOC_LIB_SAFT.getPreviousHash(iDocumentID)
                                  );

    select A_DATEMOD
      into lDateMod
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = iDocumentID;

    /* Mise à jour du document */
    if lSAFTKey is not null then
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocDocument, ltCRUD_DEF, false, iDocumentID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', lDateMod);   -- DSA - 28.02.2013 : la date de modification du document ne doit pas être mise à jour
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DMT_SAFT_KEY', lSAFTKey);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end if;
  end SetSAFTKey;
end DOC_PRC_SAFT;
