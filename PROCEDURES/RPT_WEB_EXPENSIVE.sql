--------------------------------------------------------
--  DDL for Procedure RPT_WEB_EXPENSIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_WEB_EXPENSIVE" (
   arefcursor                       in out   crystal_cursor_types.dualcursortyp,
   eco_users_id                   in       varchar2,
   web_expensive_head_id   in       number
)
/**
 * @created
 * @author ire
 * @update VHA 26 JUNE 2013
 *
 * Utilisé actuellement dans aucun rapport
 * @param eco_users_id
 * @param web_expensive_head_id
 *
 * Modifications:
 *   23.07.2013: DEVRPT-10597 Unifier procédure: utiliser toujours rpt_...
 *   26.06.2013: DEVRPT-10670 WEBERP - Correction des procédures PL/SQL pour autoriser les valeurs de paramètres à null
 */
IS
 vTeteSql varchar2(4000);
 vHead_id number := null;

begin
    if (web_expensive_head_id is not null) then
        vHead_id := web_expensive_head_id;
    end if;

  open aRefCursor for
    select
     HEA.WEB_EXPENSIVE_HEAD_ID,
     HEA.WEH_NUMBER,
     HEA.C_WEB_EXPENSIVE_STATE WEH_STATUS,
     WEH_NAME_TO PER_NAME,
    to_char(HEA.WEH_DATE1,'yyyy') WEH_YEAR,
    SCO.SCO_COMMENT2 WEH_LEG,
    WEH_COMMENT1 WEH_COMMENTS,
    WEB_EXPENSIVE_ID WED_SEQUENCE,
    SCO.SCO_DATE,
    SCO_WHO,
    RCO_TITLE,
    SCO.DIC_WEB_EXPENSIVE_TYPE_ID,
    COM_DIC_FUNCTIONS.getdicodescr('DIC_WEB_EXPENSIVE_TYPE', SCO.DIC_WEB_EXPENSIVE_TYPE_ID,3) DIC_WEB_EXPENSIVE_TYPE,
    SCO_QTE,
    SCO_TO_BILL,
    (select CURRENCY from PCS.PC_CURR where PC_CURR_ID = (select PC_CURR_ID from ACS_FINANCIAL_CURRENCY where ACS_FINANCIAL_CURRENCY_ID = SCO.ACS_FINANCIAL_CURRENCY_ID)) CURRENCY,
    SCO_AMOUNT,
    SCO_COMMENT,
    HEA.C_WEB_EXPENSIVE_STATE,
    SCO.SCO_COMMENT2
    from
    WEB_EXPENSIVE_HEAD HEA,
    WEB_EXPENSIVE SCO ,
    DOC_RECORD REC
    where HEA.WEB_EXPENSIVE_HEAD_ID = SCO.WEB_EXPENSIVE_HEAD_ID
    and REC.DOC_RECORD_ID = SCO.SCO_PROJECT_ID
    and HEA.WEB_EXPENSIVE_HEAD_ID = VHEAD_ID;
end RPT_WEB_EXPENSIVE;
