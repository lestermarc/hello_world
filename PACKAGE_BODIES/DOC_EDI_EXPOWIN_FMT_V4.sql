--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EXPOWIN_FMT_V4
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EXPOWIN_FMT_V4" 
as
  /**
  * function Get_Formatted_H1
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_H1(aItem in tH1)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'H1';
    vResult  := /* offset =    3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1MANR, 3);
    vResult  := /* offset =    6 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ARNR, 35);
    -- fichier de définition reçu de FineSolution est faux, cette colonne n'existe pas !
    -- vResult  := /* offset = 16 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRSTR1, 35);
    vResult  := /* offset =   41 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1ARDA, 'DD.MM.YYYY', 10);
    vResult  := /* offset =   51 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KOMNR, 35);
    vResult  := /* offset =   86 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1AUFNR, 35);
    vResult  := /* offset =  121 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LSNR, 35);
    vResult  := /* offset =  156 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KDNR, 17);
    vResult  := /* offset =  173 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KDUI, 15);
    vResult  := /* offset =  188 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KNAME1, 35);
    vResult  := /* offset =  223 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KNAME2, 35);
    vResult  := /* offset =  258 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KNAME3, 35);
    vResult  := /* offset =  293 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KNAME4, 35);
    vResult  := /* offset =  328 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KSTR1, 35);
    vResult  := /* offset =  363 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KSTR2, 35);
    vResult  := /* offset =  398 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KPLZ, 9);
    vResult  := /* offset =  407 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORT, 35);
    vResult  := /* offset =  442 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KLANDISO, 2);
    vResult  := /* offset =  444 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KTEL, 25);
    vResult  := /* offset =  469 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KFAX, 25);
    vResult  := /* offset =  494 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KMAIL, 80);
    vResult  := /* offset =  574 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset =  604 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KZOLLNUMMER, 10);
    vResult  := /* offset =  614 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LRNR, 17);
    vResult  := /* offset =  631 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 17);
    vResult  := /* offset =  648 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LRUI, 15);
    vResult  := /* offset =  663 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LNAME1, 35);
    vResult  := /* offset =  698 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LNAME2, 35);
    vResult  := /* offset =  733 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LNAME3, 35);
    vResult  := /* offset =  768 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LNAME4, 35);
    vResult  := /* offset =  803 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LSTR1, 35);
    vResult  := /* offset =  838 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LSTR2, 35);
    vResult  := /* offset =  873 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LPLZ, 9);
    vResult  := /* offset =  882 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LORT, 35);
    vResult  := /* offset =  917 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LLANDISO, 2);
    vResult  := /* offset =  919 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LTEL, 25);
    vResult  := /* offset =  944 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LFAX, 25);
    vResult  := /* offset =  969 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LMAIL, 80);
    vResult  := /* offset = 1049 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset = 1079 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1BSLDISO, 2);
    vResult  := /* offset = 1081 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECVERSENDERREFERENZ, 35);
    vResult  := /* offset = 1116 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECSPEDDOSSIERNR, 35);
    vResult  :=   /* offset = 1151 */
                                vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EDECANMELDZEITPUNKT, 'FM90', 2);
    vResult  := /* offset = 1153 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EDECANMELDTYP, 'FM90', 2);
    vResult  :=   /* offset = 1155 */
                                vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EDECBERICHTIGUNGCODE, 'FM0', 1);
    vResult  := /* offset = 1156 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECSPRACHE, 2);
    vResult  := /* offset = 1158 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECERZEUGUNGSLANDISO, 2);
    vResult  := /* offset = 1160 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LAGERORT, 17);
    vResult  := /* offset = 1177 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECBEGRUENDUNG, 5);
    vResult  := /* offset = 1182 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ICCD, 3);
    vResult  := /* offset = 1185 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ICOR, 80);
    vResult  := /* offset = 1265 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1INCOTEXT, 50);
    vResult  := /* offset = 1315 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SPRACHCODE, 2);
    vResult  := /* offset = 1317 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1VSAART, 15);
    vResult  := /* offset = 1332 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1VAIN, 5);
    vResult  := /* offset = 1337 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1VATXT, 35);
    vResult  := /* offset = 1372 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EDECVERKEHRSWEIG, 'FM0', 1);
    vResult  := /* offset = 1373 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECBEFMITTELLANDISO, 2);
    vResult  := /* offset = 1375 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECBEFMITTELKENNZ, 27);
    vResult  := /* offset = 1402 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ZBED, 150);
    vResult  := /* offset = 1552 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ZEICH, 10);
    vResult  := /* offset = 1562 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SACHBEARBEITER, 50);
    vResult  :=   /* offset = 1612 */
                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1RECHBETRAG_FW, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 1632 */
                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1RECHBETRAG_LW, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 1652 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1WACD, 3);
    vResult  :=   /* offset = 1655 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1KURS, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 1675 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1KUDI, 'FM999990', 6);
    vResult  :=   /* offset = 1681 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1GWNE, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 1701 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1GWBR, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 1721 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SPED, 17);
    vResult  := /* offset = 1738 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 17);
    vResult  := /* offset = 1755 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SNAME1, 35);
    vResult  := /* offset = 1790 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SNAME2, 35);
    vResult  := /* offset = 1825 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SNAME3, 35);
    vResult  := /* offset = 1860 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SNAME4, 35);
    vResult  := /* offset = 1895 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SSTR1, 35);
    vResult  := /* offset = 1930 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SSTR2, 35);
    vResult  := /* offset = 1965 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SPLZ, 9);
    vResult  := /* offset = 1974 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SORT, 35);
    vResult  := /* offset = 2009 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SLANDISO, 2);
    vResult  := /* offset = 2011 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1STEL, 25);
    vResult  := /* offset = 2036 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SFAX, 25);
    vResult  := /* offset = 2061 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SMAIL, 80);
    vResult  := /* offset = 2141 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset = 2171 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SZOLLNUMMER, 10);
    vResult  :=   /* offset = 2181 */
                     vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1FRACHT_KOST, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2201 */
                    vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1FRACHT_KOST1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2221 */
                    vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1VERPACK_KOST, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2241 */
                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1VERPACK_KOST1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2261 */
                    vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1VERSICH_KOST, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2281 */
                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1VERSICH_KOST1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2301 */
                       vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1ZOLL_KOST, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2321 */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1ZOLL_KOST1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2341 */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1SONST_KOST, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2361 */
                     vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1SONST_KOST1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2381 */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1MWSTBETRAG, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 2401 */
                     vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1MWSTPROZENT, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 2421 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1GESBERID, 10);
    vResult  := /* offset = 2431 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1AUFARTID, 3);
    vResult  := /* offset = 2434 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1MUSTIDNR, 15);
    vResult  := /* offset = 2449 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1DGESCH, 'FM0', 1);
    vResult  := /* offset = 2450 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1IS_USTEUERNR, 11);
    vResult  := /* offset = 2461 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1IS_USTEUERZUSATZ, 3);
    vResult  := /* offset = 2464 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ISGA_GSART_CODE, 5);
    vResult  := /* offset = 2469 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ISV_VERF_CODE, 7);
    vResult  := /* offset = 2476 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_KDNR, 17);
    vResult  := /* offset = 2493 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_NAME1, 35);
    vResult  := /* offset = 2528 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_NAME2, 35);
    vResult  := /* offset = 2563 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_NAME3, 35);
    vResult  := /* offset = 2598 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_NAME4, 35);
    vResult  := /* offset = 2633 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_STR1, 35);
    vResult  := /* offset = 2668 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_STR2, 35);
    vResult  := /* offset = 2703 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_PLZ, 9);
    vResult  := /* offset = 2712 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_ORT, 35);
    vResult  := /* offset = 2747 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_LANDISO, 2);
    vResult  := /* offset = 2749 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_TEL, 25);
    vResult  := /* offset = 2774 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_FAX, 25);
    vResult  := /* offset = 2799 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1N_MAIL, 80);
    vResult  := /* offset = 2879 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset = 2909 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1BSLT, 30);
    vResult  := /* offset = 2939 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1ABL1, 30);
    vResult  := /* offset = 2969 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRKDNR, 17);
    vResult  := /* offset = 2986 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRNAME1, 35);
    vResult  := /* offset = 3021 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRNAME2, 35);
    vResult  := /* offset = 3056 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRNAME3, 35);
    vResult  := /* offset = 3091 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRNAME4, 35);
    vResult  := /* offset = 3126 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRSTR1, 35);
    vResult  := /* offset = 3161 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRSTR2, 35);
    vResult  := /* offset = 3196 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRPLZ, 9);
    vResult  := /* offset = 3205 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRORT, 35);
    vResult  := /* offset = 3240 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRLANDISO, 2);
    vResult  := /* offset = 3242 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRTEL, 25);
    vResult  := /* offset = 3267 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRFAX, 25);
    vResult  := /* offset = 3292 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KORRMAIL, 80);
    vResult  := /* offset = 3372 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset = 3402 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1LAGERORT, 35);
    vResult  := /* offset = 3437 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_ABGANGSSTATION, 150);
    vResult  := /* offset = 3587 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_BEMERKUNG, 500);
    vResult  := /* offset = 4087 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_BESTIMSTATION, 45);
    vResult  := /* offset = 4132 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_BESVORSCHRIFT, 500);
    vResult  :=   /* offset = 4632 */
                             vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_EINTREFFDATUM, 'dd.mm.yyyy', 10);
    vResult  := /* offset = 4642 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_FLUGDATEN, 150);
    vResult  := /* offset = 4792 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_GFKL, 500);
    vResult  := /* offset = 5292 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_GFTX, 500);
    vResult  := /* offset = 5792 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_INFORMATFRACHT, 250);
    vResult  :=   /* offset = 6042 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG1, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 6062 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG2, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 6082 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG3, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 6102 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG4, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 6122 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG5, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset = 6142 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_KOST_BETRAG6, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 6162 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_ADRNR, 17);
    vResult  := /* offset = 6179 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_NAME1, 35);
    vResult  := /* offset = 6214 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_NAME2, 35);
    vResult  := /* offset = 6249 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_NAME3, 35);
    vResult  := /* offset = 6284 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_NAME4, 35);
    vResult  := /* offset = 6319 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_STRASSE1, 35);
    vResult  := /* offset = 6354 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_STRASSE2, 35);
    vResult  := /* offset = 6389 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_PLZ, 10);
    vResult  := /* offset = 6399 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_ORT, 35);
    vResult  := /* offset = 6434 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_LANDISO, 2);
    vResult  := /* offset = 6436 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_TELNR, 25);
    vResult  := /* offset = 6461 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_FAXNR, 25);
    vResult  := /* offset = 6486 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_MAIL, 80);
    vResult  := /* offset = 6566 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 30);
    vResult  := /* offset = 6596 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LADE_BEMERKUNG, 150);
    vResult  :=   /* offset = 6746 */
                              vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_VERLADEDATUM, 'dd.mm.yyyy', 10);
    vResult  := /* offset = 6756 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_VERSENDERDOKU, 250);
    vResult  :=   /* offset = 7006 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_ABHOLDATUM_VON, 'dd.mm.yyyy', 10);
    vResult  :=   /* offset = 7016 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_ABHOLDATUM_BIS, 'dd.mm.yyyy', 10);
    vResult  := /* offset = 7026 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_ABHOLZEIT_VON, 5);
    vResult  := /* offset = 7031 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_ABHOLZEIT_BIS, 5);
    vResult  :=   /* offset = 7036 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_ANKUNFTDAT_VON, 'dd.mm.yyyy', 10);
    vResult  :=   /* offset = 7046 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1S_ANKUNFTDAT_BIS, 'dd.mm.yyyy', 10);
    vResult  := /* offset = 7056 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_ANKUNFZEIT_VON, 5);
    vResult  := /* offset = 7061 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_ANKUNFZEIT_BIS, 5);
    vResult  := /* offset = 7066 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LDLREKONTAKTNAME, 50);
    vResult  := /* offset = 7116 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LDLREKONTONR, 30);
    vResult  := /* offset = 7146 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LDLWEKONTAKTNAME, 50);
    vResult  := /* offset = 7196 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1S_LDLWEKONTONR, 30);
    vResult  := /* offset = 7226 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 17);
    vResult  :=   /* offset = 7243 */
                              vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EDECBERICHTIGUNGGRUND, 'FM90', 2);
    vResult  := /* offset = 7245 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECBESVERMERKE, 100);
    vResult  := /* offset = 7345 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECZUSATZINFOTITEL, 20);
    vResult  := /* offset = 7365 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECZUSATZINFOBESCHR, 100);
    vResult  := /* offset = 7465 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.H1EUDEZOLLANTRAG, 'FM90', 2);
    vResult  := /* offset = 7467 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1SZOLLNUMMER, 10);
    vResult  := /* offset = 7477 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1KZOLLNUMMER, 10);
    vResult  := /* offset = 7487 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECANMELDUNGSNR, 22);
    vResult  := /* offset = 7509 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 1);
    return trim(vResult);
  end Get_Formatted_H1;

  /**
  * function Get_Formatted_HM
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HM(aItem in tHM)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HM';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1MARKIERUNG, 500, '$£');
    return trim(vResult);
  end Get_Formatted_HM;

  /**
  * function Get_Formatted_HZ
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HZ(aItem in tHZ_text)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HZ';
    --vResult := /* offset = 5 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad (aItem.H1MARKIERUNG, 500, '$£');
    return trim(vResult);
  end Get_Formatted_HZ;

  /**
  * function Get_Formatted_HK
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HK(aItem in tHK)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HK';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1HEADERTEXT, 500, '$£');
    return trim(vResult);
  end Get_Formatted_HK;

  /**
  * function Get_Formatted_HF
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HF(aItem in tHF)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HF';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1FOOTERTEXT, 500, '$£');
    return trim(vResult);
  end Get_Formatted_HF;

  /**
  * function Get_Formatted_HA
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HA(aItem in tHA)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HA';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1AKKREDITIVTXT, 1000, '$£');
    return trim(vResult);
  end Get_Formatted_HA;

  /**
  * function Get_Formatted_HI
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HI(aItem in tHI)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HI';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EHI_EBENE, 1);
    vResult  := /* offset = 4 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EHI_INSTRUKTIONEN, 500, '$£');
    return trim(vResult);
  end Get_Formatted_HI;

  /**
  * function Get_Formatted_HV
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_HV(aItem in tHV)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'HV';
    vResult  := /* offset = 3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.H1EDECBESCHWERDE, 6900, '$£');
    return trim(vResult);
  end Get_Formatted_HV;

  /**
  * function Get_Formatted_P1
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_P1(aItem in tP1)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'P1';
    vResult  := /* offset =    3 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1RENR, 35);
    vResult  := /* offset =   38 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1REPOK, 'FM9999999990', 10);
    vResult  := /* offset =   48 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1ATNR, 35);
    vResult  := /* offset =   83 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1BEZ1, 35);
    vResult  := /* offset =  118 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1BEZ2, 35);
    vResult  := /* offset =  153 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1BEZ3, 35);
    vResult  := /* offset =  188 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1BEZ4, 35);
    vResult  := /* offset =  223 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1BEZ5, 35);
    vResult  := /* offset =  258 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1ZUSP, 2);
    vResult  :=   /* offset =  260 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1MEAF, 'FM99999999999999990.00', 20);
    vResult  := /* offset =  280 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1MHAF, 10);
    vResult  :=   /* offset =  290 */
                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1MENGENEINHEIT, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset =  310 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1GWEN, 'FM999999999999990.0000', 20);
    vResult  :=   /* offset =  330 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1GWPN, 'FM999999999999990.0000', 20);
    vResult  :=   /* offset =  350 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EPLW, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset =  370 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1PWLW, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset =  390 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EPFW, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset =  410 */
                            vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1PWFW, 'FM99999999999999990.00', 20);
    vResult  := /* offset =  430 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECVERANLAGUNGTYP, 2);
    vResult  := /* offset =  432 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECHANDELSWARE, 'FM0', 1);
    vResult  := /* offset =  433 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRUECKERSTTYP, 1);
    vResult  := /* offset =  434 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECBEWILLIGTYP, 2);
    vResult  :=   /* offset =  436 */
                                vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECBEWILLIGPFLICHT, 'FM90', 2);
    vResult  :=   /* offset =  438 */
                                 vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECBEWILLIGSTELLE, 'FM90', 2);
    vResult  := /* offset =  440 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECBEWILLIGNUMMER, 17);
    vResult  :=   /* offset =  457 */
                              vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECBEWILLIGDATUM, 'YYYYMMDD', 8);
    vResult  := /* offset =  465 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECBEWILLIGZUSATZ, 70);
    vResult  := /* offset =  535 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1WNR1, 10);
    vResult  := /* offset =  545 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1SCHLUESSEL, 'FM990', 3);
    vResult  :=   /* offset =  548 */
                                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECNZEPFLICHTCODE, 'FM0', 1);
    vResult  := /* offset =  549 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECNZEARTENCODE, 3);
    vResult  :=   /* offset =  552 */
                 vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECZUSATZMENGE, 'FM999999999999999990.0', 20);
    vResult  := /* offset =  572 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1WBZ1, 42);
    vResult  := /* offset =  614 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1WBZ2, 42);
    vResult  := /* offset =  656 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1WBZ3, 42);
    vResult  :=   /* offset =  698 */
           vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EDECRUECKERSTVOCMENGE, 'FM999999999999999990.0', 20);
    vResult  := /* offset =  718 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 8);
    vResult  := /* offset =  726 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1SRENR, 35);
    vResult  := /* offset =  761 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1GENR, 35);
    vResult  := /* offset =  796 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1CHARGENNR, 35);
    vResult  := /* offset =  831 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_GEFAHRNR, 11);
    vResult  := /* offset =  842 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_KLASSE, 7);
    vResult  := /* offset =  849 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_UNNR, 4);
    vResult  := /* offset =  853 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_BEZEICH, 254);
    vResult  := /* offset = 1107 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_SEITENNR, 28);
    vResult  := /* offset = 1135 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_VGRUPPE, 32);
    vResult  := /* offset = 1167 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_KENNZ, 20);
    vResult  := /* offset = 1187 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_MERKU, 40);
    vResult  := /* offset = 1227 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_MERKE, 36);
    vResult  := /* offset = 1263 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1IMO_FLAMM, 84);
    vResult  := /* offset = 1347 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 2);
    vResult  := /* offset = 1349 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1PRODUKTGRP, 10);
    vResult  := /* offset = 1359 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1PRODUKTDSC, 35);
    vResult  := /* offset = 1394 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1ECCNNR, 35);
    vResult  := /* offset = 1429 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EKNNR, 35);
    vResult  :=   /* offset = 1464 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1OZL_TOTALMENGE, 'FM99999999999999990.00', 20);
    vResult  := /* offset = 1484 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1PRAEFBERECHTIGT, 'FM0', 1);
    vResult  := /* offset = 1485 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 20);
    vResult  := /* offset = 1505 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1REPO, 'FM9999999990', 10);
    vResult  := /* offset = 1515 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EU_USREGION_CODE, 2);
    vResult  :=   /* offset = 1517 */
                               vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EU_ZOLLTARIFNR, 'FM99999990', 8);
    vResult  :=   /* offset = 1525 */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1EU_ZUSATZME_OK, 'FM99999999999999999990', 20);
    vResult  := /* offset = 1545 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVVERKEHRSRICHTUNG, 1);
    vResult  := /* offset = 1546 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVVEREDELUNGSTYP, 1);
    vResult  := /* offset = 1547 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVVERFAHRENSTYP, 1);
    vResult  := /* offset = 1548 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVABRECHNUNGSTYP, 1);
    vResult  := /* offset = 1549 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVTEMPVERWENDUNG, 1);
    vResult  := /* offset = 1550 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECRVPOSITIONSTYP, 1);
    vResult  := /* offset = 1551 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 70);
    vResult  := /* offset = 1621 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 2);
    vResult  := /* offset = 1623 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(' ', 2);
    vResult  := /* offset = 1625 */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1EDECBESVERMERKE, 999);
    return trim(vresult);
  end Get_Formatted_P1;

  /**
  * function Get_Formatted_PZ
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_PZ(aItem in tPz)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'PZ';
    vResult  :=   /* offset =    3  */
                  vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.OZL_BESTMENGE, 'FM9999999999999999990.00', ' ');
    vResult  := /* offset =   23  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.OZL_T2NUMMER, 20);
    vResult  := /* offset =   43  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.P1RENR, 35);
    vResult  := /* offset =   78  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1REPOK, 'FM9999999990', 10);
    return trim(vResult);
  end Get_Formatted_PZ;

  /**
  * function Get_Formatted_T1
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_T1(aItem in tt1)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'T1';
    vResult  := /* offset =    3  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.PTUPOS, 'FM9999999990', 10);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.PTTEXT, 80);
    return trim(vResult);
  end Get_Formatted_T1;

  /**
  * function Get_Formatted_PD
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_PD(aItem in tpd)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'PD';
    vResult  := /* offset =    3  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EPED_EDECUNTERLAGEN, 3);
    return trim(vResult);
  end Get_Formatted_PD;

  /**
  * function Get_Formatted_V1
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_V1(aItem in tv1)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'V1';
    vResult  :=   /* offset =    3  */
                                vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_IMPORTKEY, 'FM9999999990', 10);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_VERPACKKEY, 20);
    vResult  :=   /* offset =   33  */
                                   vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_ANZAHL, 'FM9999999990', 10);
    vResult  := /* offset =    3  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_LAENGE, 'FM99990', 5);
    vResult  := /* offset =    3  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_BREITE, 'FM99990', 5);
    vResult  := /* offset =    3  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_HOEHE, 'FM99990', 5);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_MASSEINHEIT, 2);
    vResult  :=   /* offset =    3  */
                           vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_TARA, 'FM99999999999999990.00', 20);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_MARKIERUNG, 250);
    vResult  :=   /* offset =    3  */
                        vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_PACKSTNR_VON, 'FM999999999999990', 15);
    vResult  :=   /* offset =    3  */
                        vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_PACKSTNR_BIS, 'FM999999999999990', 15);
    vResult  :=   /* offset =    3  */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_BRUTTOGEW, 'FM99999999999999990.00', 20);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_VERPACKBEZ, 55);
    vResult  :=   /* offset =    3  */
                        vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_VOLUMEN, 'FM99999999999999990.00', 20);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_KATEGORIE, 15);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_VERPACKNR, 30);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_VERPACKTYP, 3);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aItem.EV_EDECCONTAINERNR, 11);
    vResult  :=   /* offset =    3  */
                           vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_IMPORTKEY_HIGH, 'FM9999999990', 10);
    return trim(vResult);
  end Get_Formatted_V1;

  /**
  * function Get_Formatted_VP
  * Description
  *    Renvoi les données de l'élément concaténées et formatées
  */
  function Get_Formatted_VP(aItem in tvp)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := 'VP';
    vResult  :=   /* offset =    3  */
                                vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EV_IMPORTKEY, 'FM9999999990', 10);
    vResult  := /* offset =   13  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1REPOK, 'FM9999999990', 10);
    vResult  :=   /* offset =   23  */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EVP_POSMENGE, 'FM99999999999999990.00', 20);
    vResult  :=   /* offset =   43  */
                      vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.EVP_POSNETTO, 'FM99999999999999990.00', 20);
    vResult  := /* offset =   63  */ vResult || DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aItem.P1REPO, 'FM9999999990', 10);
    return trim(vResult);
  end Get_Formatted_VP;

  /**
  * procedure Write_H1
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_H1(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tH1)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_H1(aItem);

    if vFormatedText is not null then
      DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
    end if;
  end Write_H1;

  /**
  * procedure Write_HM
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HM(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblHM)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.count > 0 then
      for cpt in aList.first .. aList.last loop
        vFormatedText  := Get_Formatted_HM(aList(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HM;

  /**
  * procedure Write_HZ
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HZ(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in thz)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.hz01.count > 0 then
      for cpt in aList.hz01.first .. aList.hz01.last loop
        vFormatedText  := Get_Formatted_HZ(aList.hz01(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HZ;

  /**
  * procedure Write_HK
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HK(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblHK)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.count > 0 then
      for cpt in aList.first .. aList.last loop
        vFormatedText  := Get_Formatted_HK(aList(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HK;

  /**
  * procedure Write_HF
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HF(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblHF)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.count > 0 then
      for cpt in aList.first .. aList.last loop
        vFormatedText  := Get_Formatted_HF(aList(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HF;

  /**
  * procedure Write_HA
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HA(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblHA)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.count > 0 then
      for cpt in aList.first .. aList.last loop
        vFormatedText  := Get_Formatted_HA(aList(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HA;

  /**
  * procedure Write_HI
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HI(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblHi)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    if aList.count > 0 then
      for cpt in aList.first .. aList.last loop
        vFormatedText  := Get_Formatted_HI(aList(cpt) );
        DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
      end loop;
    end if;
  end Write_HI;

  /**
  * procedure Write_HV
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_HV(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tHV)
  is
    vFormatedText varchar2(32000);
    cpt           integer;
  begin
    vFormatedText  := Get_Formatted_HV(aItem);

    if length(vFormatedText) > 2 then
      DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
    end if;
  end Write_HV;

  /**
  * procedure Write_Header
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_Header(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in theader)
  is
  begin
    Write_H1(aExportJobID, aItem.h1);
    Write_HM(aExportJobID, aItem.hm);
    Write_HZ(aExportJobID, aItem.hz);
    Write_HK(aExportJobID, aItem.hk);
    Write_HF(aExportJobID, aItem.hf);
    Write_HA(aExportJobID, aItem.ha);
    Write_HI(aExportJobID, aItem.hi);
    Write_HV(aExportJobID, aItem.hv);
  end Write_Header;

  /**
  * procedure Write_P1
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_P1(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tp1)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_P1(aItem);
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
  end Write_P1;

  /**
  * procedure Write_PZ
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_PZ(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tpz)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_PZ(aItem);
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
  end Write_PZ;

  /**
  * procedure Write_T1
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_T1(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tt1)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_T1(aItem);
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
  end Write_T1;

  /**
  * procedure Write_PD
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_PD(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tpd)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_PD(aItem);

    if length(vFormatedText) > 2 then
      DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
    end if;
  end Write_PD;

  /**
  * procedure Write_V1
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_V1(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tv1)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_V1(aItem);
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
  end Write_V1;

  /**
  * procedure Write_VP
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_VP(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aItem in tvp)
  is
    vFormatedText varchar2(32000);
  begin
    vFormatedText  := Get_Formatted_VP(aItem);
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID, vFormatedText);
  end Write_VP;

  /**
  * procedure Write_Positions
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_Positions(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblPosition)
  is
    cpt1 integer;
    cpt2 integer;
  begin
    if aList.count > 0 then
      for cpt1 in aList.first .. aList.last loop
        -- p1
        Write_P1(aExportJobID, aList(cpt1).p1);

        -- pz
        if aList(cpt1).pz.count > 0 then
          for cpt2 in aList(cpt1).pz.first .. aList(cpt1).pz.last loop
            Write_PZ(aExportJobID, aList(cpt1).pz(cpt2) );
          end loop;
        end if;

        -- t1
        if aList(cpt1).t1.count > 0 then
          for cpt2 in aList(cpt1).t1.first .. aList(cpt1).t1.last loop
            Write_T1(aExportJobID, aList(cpt1).t1(cpt2) );
          end loop;
        end if;

        --pd
        Write_PD(aExportJobID, aList(cpt1).pd);
      end loop;
    end if;
  end Write_Positions;

  /**
  * procedure Write_Packing
  * Description
  *    Insertion dans la table des données d'export
  */
  procedure Write_Packing(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aList in ttblPacking)
  is
    cpt1 integer;
    cpt2 integer;
  begin
    if aList.count > 0 then
      for cpt1 in aList.first .. aList.last loop
        -- v1
        Write_V1(aExportJobID, aList(cpt1).v1);

        if aList(cpt1).vp.count > 0 then
          for cpt2 in aList(cpt1).vp.first .. aList(cpt1).vp.last loop
            Write_VP(aExportJobID, aList(cpt1).vp(cpt2) );
          end loop;
        end if;
      end loop;
    end if;
  end Write_Packing;
end DOC_EDI_EXPOWIN_FMT_V4;
