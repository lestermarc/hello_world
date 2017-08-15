--------------------------------------------------------
--  DDL for Procedure RPT_HRM_HEADCOUNT_CONTRACT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_HEADCOUNT_CONTRACT" (
  aRefCursor IN OUT crystal_cursor_types.DualCursorTyp,
  PROCPARAM_0 IN VARCHAR2,
  PR_PC_USELANG_ID IN pcs.pc_lang.pc_lang_id%TYPE)
/**
 * Utilisé par le rapport HRM_HEADCOUNT
 * @param PROCPARAM_0  Période (YYYYMM).
 * @param PR_PC_USELANG_ID  Identifiant de la langue.
 *
 * @date 04/2008
 * @author ireber
 * @author spfister
 * @update VHA 26 JUNE 2013
 *
 * Modifications:
 * spfister 29.09.2010: Ajout d'une condition sur le type d'entrée/sortie lors de recherches sur la table HRM_IN_OUT.
 *   01.09.2011: Procedure renamed  from HRM_HEADCOUNT_CONTRACT_RPT to RPT_HRM_HEADCOUNT_CONTRACT
 *   26.06.2013: DEVRPT-10670 WEBERP - Correction des procédures PL/SQL pour autoriser les valeurs de paramètres à null
 */

IS
  ln_lang_id pcs.pc_lang.pc_lang_id%TYPE;
  ld_ref_date DATE;
  ld_ref_begin_date DATE;
  ld_end_date DATE;
  lv_unknown pcs.pc_dico.dictrans%TYPE;
BEGIN
  ln_lang_id := PR_PC_USELANG_ID;

  -- Dates
  ld_end_date := to_date('31.12.2022', 'dd.mm.yyyy');
  if (PROCPARAM_0 is not null) then
    ld_ref_date := to_date(PROCPARAM_0||'01', 'yyyymmdd');
  end if;
  ld_ref_begin_date := Trunc(ld_ref_date - 330, 'month');
  lv_unknown := pcs.pc_public.TranslateWord('<Indéfini>', ln_lang_id);

  -- (calcul de l'effectif total et des taux dans crystal)..
  -- CNT_IN / EFFECTIF_TOTAL * 100
  -- CNT_OUT / EFFECTIF_TOTAL * 100
  open aRefCursor for
  select
    PER_BEGIN PERIOD,
    nvl(pcs.pc_public.GetDescodeDescr('C_CONTRACT_TYPE', C_CONTRACT_TYPE, ln_lang_id), C_CONTRACT_TYPE) IN_GRP,
    case when DIC_OUT_TYPE_ID is not null then
      Nvl(com_dic_functions.getDicoDescr('DIC_OUT_TYPE', DIC_OUT_TYPE_ID, ln_lang_id), DIC_OUT_TYPE_ID) else lv_unknown
    end OUT_GRP,
    Sum(case when IO.INO_IN < PER.PER_BEGIN then 1 else 0 end) EFFECTIF,-- Effectif au début du mois
    Sum(case when IO.INO_IN >= PER.PER_BEGIN then 1 else 0 end) CNT_IN, -- Entrée ds le mois
    Sum(case when IO.INO_OUT <= PER.PER_END then 1 else 0 end) CNT_OUT -- Sorties ds le mois
  from
    (select DIC_OUT_TYPE_ID, C_CONTRACT_TYPE, INO_IN, Nvl(INO_OUT, ld_end_date) INO_OUT
     from HRM_IN_OUT I, HRM_CONTRACT C
     where C.HRM_IN_OUT_ID = I.HRM_IN_OUT_ID and
       I.C_IN_OUT_CATEGORY = '3' and
       -- Données du dernier contrat pour l'entrée/sortie
       C.CON_BEGIN = (select Max(CON_BEGIN) from HRM_CONTRACT where HRM_IN_OUT_ID = C.HRM_IN_OUT_ID)
    ) IO,
    HRM_PERIOD PER
  where
    -- Employés présent, entrés ou sortis dans la période
    IO.INO_IN <= PER.PER_END and IO.INO_OUT >= PER.PER_BEGIN and
    -- Filtre périodes selon date de référence
    PER.PER_BEGIN between ld_ref_begin_date and ld_ref_date
  group by
    PER.PER_BEGIN, IO.DIC_OUT_TYPE_ID, IO.C_CONTRACT_TYPE;
END RPT_HRM_HEADCOUNT_CONTRACT;
