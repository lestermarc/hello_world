--------------------------------------------------------
--  DDL for Package Body COM_PRC_EBANKING_FILES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_EBANKING_FILES" 
/**
 * Package de gestion des fichiers de traitement des documents e-factures.
 *
 * @version 1.0
 * @date 2012
 * @author agentet
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
as
  /**
  * Description
  *    Cette fonction va supprimer les fichiers de traitement du document e-facture
  *    dont la clef primaires est transmise en paramètre.
  */
  procedure DeleteEBPPFile(inComEbankingID in COM_EBANKING.COM_EBANKING_ID%type)
  as
  begin
    delete from COM_EBANKING_FILES
          where COM_EBANKING_ID = inComEbankingID;
  end DeleteEBPPFile;
end COM_PRC_EBANKING_FILES;
