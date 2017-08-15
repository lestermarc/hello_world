--------------------------------------------------------
--  DDL for Function FAL_GETPROCESSTRACK_SAMPLE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_GETPROCESSTRACK_SAMPLE" (ivInLine varchar2)
  return FAL_PFG_ENTRY_SYSTEMS.tProcessTrackTable pipelined
is
/**
   * Description
   *   Fonction d'exemple de conversion d'une ligne venant d'un barcode
   *   en données pour insertion dans le brouillard de suivi d'avancement
   *   (utilisé avec le nouveau système d'échange de données pour effectuer
   *   le travail fait auparavant par le fichier de contrôle du SQL Loader)
   * @version 2003
   * @author CLG 17.10.2011
   * @lastUpdate
   * @public
   * @param ivInLine          : Ligne à convertir
   * @return  le record à insérer dans le brouillard
*/
  ltRecProcessTrack FAL_PFG_ENTRY_SYSTEMS.tProcessTrackRecord;
begin
  ltRecProcessTrack.PFG_SELECTION        := 0;
  ltRecProcessTrack.PFG_LOT_REFCOMPL     := trim(substr(ivInLine, 1, 14) );
  ltRecProcessTrack.PFG_SEQ              := trim(substr(ivInLine, 15, 14) );
  ltRecProcessTrack.PFG_DIC_OPERATOR_ID  := trim(substr(ivInLine, 29, 10) );
  ltRecProcessTrack.PFG_DATE             := to_date(trim(substr(ivInLine, 39, 16) ), 'DD.MM.YYYY HH24:MI');
  ltRecProcessTrack.PFG_PRODUCT_QTY      := to_number(trim(substr(ivInLine, 55, 10) ) );
  ltRecProcessTrack.PFG_PT_REFECT_QTY    := to_number(trim(substr(ivInLine, 65, 15) ) );
  ltRecProcessTrack.PFG_CPT_REJECT_QFY   := to_number(trim(substr(ivInLine, 80, 15) ) );
  ltRecProcessTrack.PFG_DIC_REBUT_ID     := trim(substr(ivInLine, 95, 10) );
  pipe row(ltRecProcessTrack);
end;
