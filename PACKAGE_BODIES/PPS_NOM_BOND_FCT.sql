--------------------------------------------------------
--  DDL for Package Body PPS_NOM_BOND_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_NOM_BOND_FCT" 
is
/* =============================================================================
   Procedure generate_bond_delta

   Param : pSourceNomId -> id de la nomenclature source
           pTargetNomId -> id de la nomenclature cible
           pNomRefQty ->   quantité référence permettant une comparaison
                           cohérente des 2 nomenclatures

   But : trouver, pour chaque composant, la quantité à ajouter / soustraire
         de la nomenclature source pour obtenir la nomenclature cible

============================================================================= */
  procedure GENERATE_BOND_DELTA(
    pSourceNomId pps_nomenclature.pps_nomenclature_id%type
  , pTargetNomId pps_nomenclature.pps_nomenclature_id%type
  , pNomRefQty   pps_nomenclature.nom_ref_qty%type
  )
  is
/* curseurs */
    cursor crPpsNomBondSumCoeff(
      cPpsNomId  pps_nomenclature.pps_nomenclature_id%type
    , cNomRefQty pps_nomenclature.nom_ref_qty%type
    )
    is
      select   cPpsNomId
             , com.gco_good_id
             , sum(fal_tools.ArrondiSuperieur(cNomRefQty * com.com_util_coeff / com.com_ref_qty, com.gco_good_id) )
                                                                                                         com_util_coeff
             , com.pps_pps_nomenclature_id
          from pps_nom_bond com
         where com.pps_nomenclature_id = cPpsNomId
           and com.gco_good_id is not null
           and com.c_type_com in('1')   -- lien actif
           and com.c_kind_com in('1', '3')   -- composant ou pseudo
      group by gco_good_id
             , pps_pps_nomenclature_id;

/* types et variables */
    type tabPpsNomBondSumType is table of crPpsNomBondSumCoeff%rowtype
      index by varchar2(24);

    tplPpsNomBondSumCoeff crPpsNomBondSumCoeff%rowtype;
    tabPpsNomBondSource   tabPpsNomBondSumType;
    tabPpsNomBondTarget   tabPpsNomBondSumType;
    vCpt                  varchar2(24);
    vTabIndex             varchar2(24);
  begin
-- effacement contenu de la table temporaire
    delete from pps_nom_bond_delta;

-- calcul des coefficients cumulés par article de la nomenclature source
    open crPpsNomBondSumCoeff(pSourceNomId, pNomRefQty);

    fetch crPpsNomBondSumCoeff
     into tplPpsNomBondSumCoeff;

    while crPpsNomBondSumCoeff%found loop
      vTabIndex                       :=
        to_char(tplPpsNomBondSumCoeff.gco_good_id, 'FM000000000000') ||
        to_char(nvl(tplPpsNomBondSumCoeff.pps_pps_nomenclature_id, 0), 'FM000000000000');
      tabPpsNomBondSource(vTabIndex)  := tplPpsNomBondSumCoeff;

      fetch crPpsNomBondSumCoeff
       into tplPpsNomBondSumCoeff;
    end loop;

    close crPpsNomBondSumCoeff;

-- calcul des coefficients cumulés par article de la nomenclature cible
    open crPpsNomBondSumCoeff(pTargetNomId, pNomRefQty);

    fetch crPpsNomBondSumCoeff
     into tplPpsNomBondSumCoeff;

    while crPpsNomBondSumCoeff%found loop
      vTabIndex                       :=
        to_char(tplPpsNomBondSumCoeff.gco_good_id, 'FM000000000000') ||
        to_char(nvl(tplPpsNomBondSumCoeff.pps_pps_nomenclature_id, 0), 'FM000000000000');
      tabPpsNomBondTarget(vTabIndex)  := tplPpsNomBondSumCoeff;

      fetch crPpsNomBondSumCoeff
       into tplPpsNomBondSumCoeff;
    end loop;

    close crPpsNomBondSumCoeff;

/*
   Partie 1
   --------
   pour chaque article de la nomenclature source,
        si l'article n'existe pas dans la nomenclature cible
           -> insérer un record pour cet article, coeff_delta = -coeff_original_source

        si l'article existe dans la seconde nomenclature et que les coefficients diffèrent
           -> insérer un record pour cet article, coeff_delta = coeff_original_cible - coeff_original_source
           -> supprimer l'article de la nomenclature cible

   Partie 2
   --------

   pour chaque article de la nomenclature cible
        insérer l'article, coeff_delta = coeff_original_cible
*/

    /*  Partie 1 */
    vCpt  := tabPpsNomBondSource.first;

    while vCpt is not null loop
      if not tabPpsNomBondTarget.exists(vCpt) then
        insert into pps_nom_bond_delta
                    (pps_nom_bond_delta_id
                   , pps_nomenclature_id
                   , gco_good_id
                   , nbd_util_coeff
                   , pps_pps_nomenclature_id
                    )
             values (init_id_seq.nextval
                   , pSourceNomId
                   , tabPpsNomBondSource(vCpt).gco_good_id
                   , -tabPpsNomBondSource(vCpt).com_util_coeff
                   , tabPpsNomBondSource(vCpt).pps_pps_nomenclature_id
                    );
      elsif tabPpsNomBondSource(vCpt).com_util_coeff <> tabPpsNomBondTarget(vCpt).com_util_coeff then
        insert into pps_nom_bond_delta
                    (pps_nom_bond_delta_id
                   , pps_nomenclature_id
                   , gco_good_id
                   , nbd_util_coeff
                   , pps_pps_nomenclature_id
                    )
             values (init_id_seq.nextval
                   , pSourceNomId
                   , tabPpsNomBondSource(vCpt).gco_good_id
                   , tabPpsNomBondTarget(vCpt).com_util_coeff - tabPpsNomBondSource(vCpt).com_util_coeff
                   , tabPpsNomBondSource(vCpt).pps_pps_nomenclature_id
                    );

        tabPpsNomBondTarget.delete(vCpt);
      else
        tabPpsNomBondTarget.delete(vCpt);
      end if;

      vCpt  := tabPpsNomBondSource.next(vCpt);
    end loop;

/*  Partie 2 */
    vCpt  := tabPpsNomBondTarget.first;

    while vCpt is not null loop
      insert into pps_nom_bond_delta
                  (pps_nom_bond_delta_id
                 , pps_nomenclature_id
                 , gco_good_id
                 , nbd_util_coeff
                 , pps_pps_nomenclature_id
                  )
           values (init_id_seq.nextval
                 , pSourceNomId
                 , tabPpsNomBondTarget(vCpt).gco_good_id
                 , tabPpsNomBondTarget(vCpt).com_util_coeff
                 , tabPpsNomBondTarget(vCpt).pps_pps_nomenclature_id
                  );

      vCpt  := tabPpsNomBondTarget.next(vCpt);
    end loop;
  end GENERATE_BOND_DELTA;

  procedure prepare_nom_4_prnt(
    aRefCursor  in out crystal_cursor_types.DualCursorTyp
  , procparam_0        pps_nomenclature.pps_nomenclature_id%type
  )
  is
  begin
    open aRefCursor for
      select     PPS_INIT.GetSeqNextval query_id_seq
               , procparam_0 query_nom_id
               , level Level_nom
               , PPS_NOM_BOND_ID
               , PPS_NOMENCLATURE_ID
               , PPS_RANGE_OPERATION_ID
               , STM_LOCATION_ID
               , GCO_GOOD_ID
               , C_REMPLACEMENT_NOM
               , C_TYPE_COM
               , C_DISCHARGE_COM
               , C_KIND_COM
               , COM_SEQ
               , COM_TEXT
               , COM_RES_TEXT
               , COM_RES_NUM
               , COM_VAL
               , COM_SUBSTITUT
               , COM_POS
               , COM_UTIL_COEFF
               , COM_PDIR_COEFF
               , COM_REC_PCENT
               , COM_INTERVAL
               , COM_BEG_VALID
               , COM_END_VALID
               , COM_REMPLACEMENT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , STM_STOCK_ID
               , FAL_SCHEDULE_STEP_ID
               , PPS_PPS_NOMENCLATURE_ID
            from pps_nom_bond
      start with pps_nomenclature_id = procparam_0
      connect by prior pps_pps_nomenclature_id = pps_nomenclature_id
        order by pps_nomenclature_id
               , com_seq;
  end prepare_nom_4_prnt;

  procedure GENERATE_BOND_DIFF(
    aSrcNomID  PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , aTgtNomID  PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , aNomRefQty PPS_NOMENCLATURE.NOM_REF_QTY%type
  , aDiffCols  varchar2
  )
  is
    type t_ppsDiffCols is table of varchar2(30)
      index by varchar2(1);

    tbl_ppsDiffCols  t_ppsDiffCols;
    SQL_Command      varchar2(32000);
    InsertFieldsList varchar2(1000);
    SelectFieldsList varchar2(1000);
    v_diffTag        varchar2(1);
    v_diffTagPos     number(3);
  begin
    -- Effacer les données de la table de comparaison
    delete from PPS_NOM_BOND_DIFF;

    for tplViewDiffCols in (select *
                              from V_PPS_NOM_BOND_DIFF_COLS) loop
      tbl_ppsDiffCols(tplViewDiffCols.DIFF_TAG)  := tplViewDiffCols.DIFF_COL;
    end loop;

    v_diffTagPos      := 1;
    v_diffTag         := ExtractLine(aDiffCols, v_diffTagPos, ';');

    while v_diffTag is not null loop
      InsertFieldsList  := InsertFieldsList || tbl_ppsDiffCols(v_diffTag) || ',';

      if tbl_ppsDiffCols(v_diffTag) = 'COM_UTIL_COEFF' then
        SelectFieldsList  :=
          SelectFieldsList ||
          'FAL_TOOLS.ArrondiSuperieur(' ||
          to_char(aNomRefQty, 'FM999999999') ||
          ' * COM_UTIL_COEFF / COM_REF_QTY, GCO_GOOD_ID) COM_UTIL_COEFF' ||
          ',';
      else
        SelectFieldsList  := SelectFieldsList || tbl_ppsDiffCols(v_diffTag) || ',';
      end if;

      v_diffTagPos      := v_diffTagPos + 1;
      v_diffTag         := extractline(aDiffCols, v_diffTagPos, ';');
    end loop;

    InsertFieldsList  := rtrim(InsertFieldsList, ',');
    SelectFieldsList  := rtrim(SelectFieldsList, ',');
    -- contruction de la commande d'insertion des données de comparaison
    SQL_Command       :=
      'insert into PPS_NOM_BOND_DIFF ( DIFF_TYPE, [INSERT_SQL_FIELDS] ) ' ||
      'select DIFF_TYPE ' ||
      '     , [INSERT_SQL_FIELDS] ' ||
      '  from ' ||
      '  ( ' ||
      '    (select ''SOURCE'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :SRC_ID ' ||
      '     minus ' ||
      '     select ''SOURCE'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :TGT_ID ' ||
      '    ) ' ||
      '    union all ' ||
      '    (select ''TARGET'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :TGT_ID ' ||
      '     minus  ' ||
      '     select ''TARGET'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :SRC_ID ' ||
      '    ) ' ||
      '    union all ' ||
      '    (select ''COMMON'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :TGT_ID' ||
      '     intersect ' ||
      '     select ''COMMON'' DIFF_TYPE, [SELECT_SQL_FIELDS] from PPS_NOM_BOND where PPS_NOMENCLATURE_ID = :SRC_ID' ||
      '    )' ||
      '  )';
    -- remplacer la liste des champs de l'insert et du select
    SQL_Command       := replace(SQL_Command, '[INSERT_SQL_FIELDS]', InsertFieldsList);
    SQL_Command       := replace(SQL_Command, '[SELECT_SQL_FIELDS]', SelectFieldsList);

    -- insertion des données pour la comparaison
    execute immediate SQL_Command
                using aSrcNomID, aTgtNomID, aTgtNomID, aSrcNomID, aTgtNomID, aSrcNomID;

    -- Màj de l'id de la nomenclature qui a une difference
    update PPS_NOM_BOND_DIFF DIFF
       set DIFF.PPS_NOMENCLATURE_ID = decode(DIFF.DIFF_TYPE, 'SOURCE', aSrcNomID, aTgtNomID)
     where DIFF.DIFF_TYPE in('SOURCE', 'TARGET');
  end GENERATE_BOND_DIFF;
end pps_nom_bond_fct;
