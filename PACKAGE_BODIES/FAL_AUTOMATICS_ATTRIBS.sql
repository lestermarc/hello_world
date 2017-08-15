--------------------------------------------------------
--  DDL for Package Body FAL_AUTOMATICS_ATTRIBS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_AUTOMATICS_ATTRIBS" 
is

-- Proc�dure de g�n�ration des attributions pour une position donn�e.
-- Param�tres entrants: PrmDOC_POSITION_ID  = Id de la position
--                      PrmC_RESERVATION_TYP= NULL (ce param�tre est obsol�te)
PROCEDURE Genere_Attrib_Auto(PrmDOC_POSITION_ID  DOC_POSITION.DOC_POSITION_ID%TYPE, PrmC_RESERVATION_TYP PAC_CUSTOM_PARTNER.C_RESERVATION_TYP%TYPE) is -- DJ20000106-0287
begin
 FAL_REDO_ATTRIBS.ReDoAttribsByDocOrPOS(NULL, PrmDOC_POSITION_ID);
end;


END;
