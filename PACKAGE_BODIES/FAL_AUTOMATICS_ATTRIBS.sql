--------------------------------------------------------
--  DDL for Package Body FAL_AUTOMATICS_ATTRIBS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_AUTOMATICS_ATTRIBS" 
is

-- Procédure de génération des attributions pour une position donnée.
-- Paramètres entrants: PrmDOC_POSITION_ID  = Id de la position
--                      PrmC_RESERVATION_TYP= NULL (ce paramètre est obsolète)
PROCEDURE Genere_Attrib_Auto(PrmDOC_POSITION_ID  DOC_POSITION.DOC_POSITION_ID%TYPE, PrmC_RESERVATION_TYP PAC_CUSTOM_PARTNER.C_RESERVATION_TYP%TYPE) is -- DJ20000106-0287
begin
 FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(NULL, PrmDOC_POSITION_ID);
end;


END;
