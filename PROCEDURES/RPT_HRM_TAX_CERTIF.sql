--------------------------------------------------------
--  DDL for Procedure RPT_HRM_TAX_CERTIF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_TAX_CERTIF" (
  aRefCursor in out crystal_cursor_types.DualCursorTyp,
  PROCPARAM_0 IN number, -- ListId [8]
  PROCPARAM_1 IN number, -- Year [0]]
  PROCPARAM_2 IN number, -- Langue [9]
  PROCPARAM_3 IN varchar2 default 'A',    -- De l'employé [6]
  PROCPARAM_4 IN varchar2 default 'zzzz',
  PROCPARAM_5 IN varchar2 default null, -- De la période (YYYYMM)
  PROCPARAM_6 IN varchar2 default null, -- A la période (YYYYMM)
  PROCPARAM_7 IN number default 1, -- Type de description (0,1,2)

  PROCPC_USER_ID IN PCS.PC_USER.PC_USER_ID%TYPE, -- Id utilisateur
  PROCPC_COMP_ID IN PCS.PC_COMP.PC_COMP_ID%TYPE -- Id Société
)
/**
 * @created 07/2007
 * @author rhe, ire
 * @update VHA 26 JUNE 2013
 *
 * Utilisé par le rapport HRM_TAX_CERTIF_2005.rpt
 * @param PROCPARAM_0  Id List
 * @param PROCPARAM_1  Année
 * @param PROCPARAM_2  LangType (0: User; 1: Company; 2: Employee)
 * @param PROCPARAM 3  FromEmp
 * @param PROCPARAM 4  ToEmp
 * @param PROCPARAM 5  FromPeriod (YYYYMM) pour une impression intermédiaire
 * @param PROCPARAM 6  ToPeriod (YYYYMM) pour une impression intermédiaire
 * @param PROCPARAM 7  DescrType (0:RootCode, 1:Descr, 2:SubstCode)
 *
 * Modifications:
 *   04.05.2009: Ajout DescrType (correction recherche textes concaténés 15.1)
 *   08.05.2008: Intégration liste intérmédiaire (parmètres période)
 *   05.12.2013: Procedure renamed from HRM_CERTIF_RPT TO RPT_HRM_TAX_CERTIF
 */
is
  vPeriodFrom Date;
  vPeriodTo Date;
begin
  -- Initialiser
  if PROCPC_USER_ID is not null then
    pcs.PC_I_LIB_SESSION.SetUserId(PROCPC_USER_ID);
  end if;
  if PROCPC_COMP_ID is not null then
    pcs.PC_I_LIB_SESSION.SetCompanyId(PROCPC_COMP_ID);
  end if;

  -- Annuel
  if (PROCPARAM_5 is null) then
    hrm_rep_list.CertifList(aRefCursor, PROCPARAM_0, PROCPARAM_1, PROCPARAM_2, PROCPARAM_3, PROCPARAM_4, PROCPARAM_7);
  -- Intermédiaire
  else
    vPeriodFrom := To_Date(PROCPARAM_5||'01', 'YYYYMMDD');
    vPeriodTo := Last_Day(To_Date(PROCPARAM_6||'01', 'YYYYMMDD'));
    hrm_rep_list.CertifPeriodList(aRefCursor, PROCPARAM_0, PROCPARAM_1,
        vPeriodFrom, vPeriodTo, PROCPARAM_2, PROCPARAM_3, PROCPARAM_4, PROCPARAM_7);
  end if;

end;
