--------------------------------------------------------
--  DDL for Package Body PPS_NOM_HIST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_NOM_HIST" 
is
/************************************************
  procédure UpdateHistory_NOM_AI
*************************************************/
  procedure UpdateHistory_NOM_AI(NewValue PPS_NOMENCLATURE%rowtype)
  is
    aTyp_nom varchar2(10);
  begin
    -- 01, insertion d'une nouvelle nomenclature
    -- si la nomenclature est de type 4 (produit configuré) le statut est égal à 33
    -- sinon le statut est égal à 01
    insert into PPS_NOM_HISTORY
                (PPS_NOM_HISTORY_ID
               , PPS_NOMENCLATURE_ID
               , NOM_VERSION
               , NOM_SEQ
               , NOM_POS
               , NOM_OLD_VALUE
               , NOM_NEW_VALUE
               , NOM_COMP
               , C_STATUS_NOM_HISTORY
               , NOM_SESSION_ID
               , NOM_SCHEDULE_STEP
               , A_IDCRE
               , A_DATECRE
                )
      select init_id_seq.nextval
           , NewValue.pps_nomenclature_id
           , NewValue.Nom_version
           , 0
           , null
           , null
           , null
           , null
           , decode(NewValue.c_type_nom, '4', '33', '01')
           , SessionValue
           , null
           , NewValue.a_idcre
           , sysdate
        from dual;
  end;

/************************************************
  procédure UpdateHistory_NOM_AU
*************************************************/
  procedure UpdateHistory_NOM_AU(OldValue PPS_NOMENCLATURE%rowtype, NewValue PPS_NOMENCLATURE%rowtype)
  is
    aSch_ref_new varchar2(30);
    aSch_ref_old varchar2(30);
    a_idmod      varchar2(5);
  begin
    -- initialisation des variables
    aSch_ref_new  := '';
    aSch_ref_old  := '';

    -- récupération de la désignation de la gamme opératoire
    if nvl(NewValue.fal_schedule_plan_id, -10000) <> nvl(OldValue.fal_schedule_plan_id, -10000) then
      if NewValue.fal_schedule_plan_id is not null then
        select sch.sch_ref
          into aSch_ref_new
          from fal_schedule_plan sch
         where sch.fal_schedule_plan_id = NewValue.fal_schedule_plan_id;
      end if;

      if OldValue.fal_schedule_plan_id is not null then
        select sch.sch_ref
          into aSch_ref_old
          from fal_schedule_plan sch
         where sch.fal_schedule_plan_id = OldValue.fal_schedule_plan_id;
      end if;
    end if;

    -- récupération des initiales de la personne qui a modifié le composant
    -- attention : lors de modification en direct de la base, il se peut
    -- que le champs pps_nom_bond.a_idmod ne soit pas renseigné
    -- dans ce cas les initiales seront ORA_U (Oracle Update)
    a_idmod       := NewValue.a_idmod;

    if a_idmod is null then
      a_idmod  := 'ORA_U';
    end if;

    -- 02, modification champs mémo
    if nvl(NewValue.nom_text, ' ') <> nvl(OldValue.nom_text, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.nom_text
             , NewValue.nom_text
             , null
             , SessionValue
             , '02'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 03, quantité référence nomenclature
    if NewValue.nom_ref_qty <> OldValue.nom_ref_qty then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.nom_ref_qty
             , NewValue.nom_ref_qty
             , null
             , SessionValue
             , '03'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 28, N° version nomenclature
    if nvl(NewValue.nom_version, ' ') <> nvl(OldValue.nom_version, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.nom_version
             , NewValue.nom_version
             , null
             , SessionValue
             , '28'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 37, modification nomenclature par défaut
    if NewValue.nom_default <> OldValue.nom_default then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.nom_default
             , NewValue.nom_default
             , null
             , SessionValue
             , '37'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 38, modification de la gamme opératoire
    if nvl(NewValue.fal_schedule_plan_id, -10000) <> nvl(OldValue.fal_schedule_plan_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , aSch_ref_old
             , aSch_ref_new
             , null
             , SessionValue
             , '38'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 39, modification code condition remplacement
    if NewValue.c_remplacement_nom <> OldValue.c_remplacement_nom then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.c_remplacement_nom
             , NewValue.c_remplacement_nom
             , null
             , SessionValue
             , '39'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 40, modification date début de validité
    if nvl(to_char(NewValue.nom_beg_valid, 'DD/MM/YYYY'), ' ') <> nvl(to_char(OldValue.nom_beg_valid, 'DD/MM/YYYY'), ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , to_char(OldValue.nom_beg_valid, 'DD/MM/YYYY')
             , to_char(NewValue.nom_beg_valid, 'DD/MM/YYYY')
             , null
             , SessionValue
             , '40'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 41, modification date texte nomenclature
    if nvl(NewValue.nom_text, ' ') <> nvl(OldValue.nom_text, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , NewValue.Nom_version
             , 0
             , null
             , OldValue.nom_text
             , NewValue.nom_text
             , null
             , SessionValue
             , '41'
             , null
             , a_idmod
             , sysdate
          from dual;
    end if;
  end;   -- procédure Update_history_NOM_AU

/************************************************
  procédure UpdateHistory_BOND_AU
*************************************************/
  procedure UpdateHistory_BOND_AU(OldValue PPS_NOM_BOND%rowtype, NewValue PPS_NOM_BOND%rowtype)
  is
    aNom_version             varchar2(20);
    aNom_version_Comp_new    varchar2(20);
    aNom_version_Comp_old    varchar2(20);
    aLoc_description_new     varchar2(10);
    aLoc_description_old     varchar2(10);
    aSto_description_new     varchar2(10);
    aSto_description_old     varchar2(10);
    aScs_step_number_new     number(9);
    aScs_step_number_old     number(9);
    aGoo_major_reference_new varchar2(30);
    aGoo_major_reference_old varchar2(30);
    aFal_schedule_step_new   varchar(20);
    aFal_schedule_step_old   varchar(20);
    a_idmod                  varchar2(5);
  begin
    -- initialisation des variables
    aNom_version            := '';
    aNom_version_Comp_new   := '';
    aNom_version_Comp_old   := '';
    aLoc_description_new    := '';
    aLoc_description_old    := '';
    aSto_description_new    := '';
    aSto_description_old    := '';
    aScs_step_number_new    := null;
    aScs_step_number_old    := null;
    aFal_schedule_step_new  := null;
    aFal_schedule_step_old  := null;
    -- récupération du numéro de version de la nomenclature dont
    -- les composants sont modifiés
    aNom_Version            := NewValue.com_nom_version;

    -- récupération de la description de l'emplacement de stock
    if nvl(NewValue.stm_location_id, -10000) <> nvl(OldValue.stm_location_id, -10000) then
      if NewValue.stm_location_id is not null then
        select loc.loc_description
          into aLoc_description_new
          from stm_location loc
         where loc.stm_location_id = NewValue.stm_location_id;
      end if;

      if OldValue.stm_location_id is not null then
        select loc.loc_description
          into aLoc_description_old
          from stm_location loc
         where loc.stm_location_id = OldValue.stm_location_id;
      end if;
    end if;

    -- récupération de la description du stock
    if nvl(NewValue.stm_stock_id, -10000) <> nvl(OldValue.stm_stock_id, -10000) then
      if NewValue.stm_stock_id is not null then
        select sto.sto_description
          into aSto_description_new
          from stm_stock sto
         where sto.stm_stock_id = NewValue.stm_stock_id;
      end if;

      if OldValue.stm_stock_id is not null then
        select sto.sto_description
          into aSto_description_old
          from stm_stock sto
         where sto.stm_stock_id = OldValue.stm_stock_id;
      end if;
    end if;

    -- récupération des numéros d'opération
    if nvl(NewValue.fal_schedule_step_id, -10000) <> nvl(OldValue.fal_schedule_step_id, -10000) then
      if NewValue.fal_schedule_step_id is not null then
        select scs.scs_step_number
          into aScs_step_number_new
          from fal_list_step_link scs
         where scs.fal_schedule_step_id = NewValue.fal_schedule_step_id;
      end if;

      if OldValue.fal_schedule_step_id is not null then
        select scs.scs_step_number
          into aScs_step_number_old
          from fal_list_step_link scs
         where scs.fal_schedule_step_id = OldValue.fal_schedule_step_id;
      end if;
    end if;

    -- récupération de la référence du bien
    if nvl(NewValue.gco_good_id, -10000) <> nvl(OldValue.gco_good_id, -10000) then
      if NewValue.gco_good_id is not null then
        select gco.goo_major_reference
          into aGoo_major_reference_new
          from gco_good gco
         where gco.gco_good_id = NewValue.gco_good_id;
      end if;

      if OldValue.gco_good_id is not null then
        select gco.goo_major_reference
          into aGoo_major_reference_old
          from gco_good gco
         where gco.gco_good_id = OldValue.gco_good_id;
      end if;
    end if;

    -- récupération de la version du composant uniquement si
    -- le bien n'a pas changé et que la version a changé
    -- récupération de la référence du bien puisque nous ne sommes pas passés
    -- dans le test précédent
    if     NewValue.gco_good_id = OldValue.gco_good_id
       and nvl(NewValue.pps_pps_nomenclature_id, -10000) <> nvl(OldValue.pps_pps_nomenclature_id, -10000) then
      if NewValue.pps_pps_nomenclature_id is not null then
        select pps.nom_version
          into aNom_version_Comp_new
          from pps_nomenclature pps
         where pps.pps_nomenclature_id = NewValue.pps_pps_nomenclature_id;
      end if;

      if OldValue.pps_pps_nomenclature_id is not null then
        select pps.nom_version
          into aNom_version_Comp_old
          from pps_nomenclature pps
         where pps.pps_nomenclature_id = OldValue.pps_pps_nomenclature_id;
      end if;

      if NewValue.gco_good_id is not null then
        select gco.goo_major_reference
          into aGoo_major_reference_new
          from gco_good gco
         where gco.gco_good_id = NewValue.gco_good_id;
      end if;
    end if;

    -- récupération des initiales de la personne qui a modifié le composant
    -- attention : lors de modification en direct de la base, il se peut
    -- que le champs pps_nom_bond.a_idmod ne soit pas renseigné
    -- dans ce cas les initiales seront ORA_U (Oracle Update)
    a_idmod                 := NewValue.a_idmod;

    if a_idmod is null then
      a_idmod  := 'ORA_U';
    end if;

    -- 06, modification n° séquence.
    -- Dans le cadre de la renumérotation des composants de la nomenclature et afin d'éviter une éventuelle violation
    -- de contrainte unique sur la séquence, celle-ci est passée en négatif (7 -> -7) avant de démarrer le traitement.
    -- On ne doit donc pas historiser ce changement. Lors du traitement de renumérotation, la modification en revanche
    -- doit être historiée. On prend Donc toujours la valeur absolue de l'ancienne valeur. (7 -> 10).
    if     NewValue.com_seq > 0
       and NewValue.com_seq <> abs(OldValue.com_seq) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(abs(OldValue.com_seq) )
             , to_char(NewValue.com_seq)
             , NewValue.gco_good_id
             , SessionValue
             , '06'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 07, modification type de lien
    if NewValue.c_type_com <> OldValue.c_type_com then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.c_type_com
             , NewValue.c_type_com
             , NewValue.gco_good_id
             , SessionValue
             , decode(TagValue, 2, '43', 4, '44', '07')
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 08, modification code calcul des besoins
      /* le code calcul des besoins n'existe pas */

    -- 09, modification code valorisation
    if NewValue.com_val <> OldValue.com_val then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_val)
             , to_char(NewValue.com_val)
             , NewValue.gco_good_id
             , SessionValue
             , '09'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 10, modification code substitution
    if NewValue.com_substitut <> OldValue.com_substitut then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_substitut)
             , to_char(NewValue.com_substitut)
             , NewValue.gco_good_id
             , SessionValue
             , '10'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 11, modification code remplacement
    if NewValue.com_remplacement <> OldValue.com_remplacement then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_remplacement)
             , to_char(NewValue.com_remplacement)
             , NewValue.gco_good_id
             , SessionValue
             , '11'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 12, modification code condition de remplacement
    if NewValue.c_remplacement_nom <> OldValue.c_remplacement_nom then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.c_remplacement_nom
             , NewValue.c_remplacement_nom
             , NewValue.gco_good_id
             , SessionValue
             , '12'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 13, modification date fin de validité
    if nvl(to_char(NewValue.com_end_valid, 'DD/MM/YYYY'), ' ') <> nvl(to_char(OldValue.com_end_valid, 'DD/MM/YYYY'), ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_end_valid, 'DD/MM/YYYY')
             , to_char(NewValue.com_end_valid, 'DD/MM/YYYY')
             , NewValue.gco_good_id
             , SessionValue
             , '13'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 14, modification date début de validité
    if nvl(to_char(NewValue.com_beg_valid, 'DD/MM/YYYY'), ' ') <> nvl(to_char(OldValue.com_beg_valid, 'DD/MM/YYYY'), ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_beg_valid, 'DD/MM/YYYY')
             , to_char(NewValue.com_beg_valid, 'DD/MM/YYYY')
             , NewValue.gco_good_id
             , SessionValue
             , '14'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 15, modification position
    if nvl(NewValue.com_pos, ' ') <> nvl(OldValue.com_pos, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_pos
             , NewValue.com_pos
             , NewValue.gco_good_id
             , SessionValue
             , '15'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 16, modification texte
    if nvl(NewValue.com_text, ' ') <> nvl(OldValue.com_text, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_text
             , NewValue.com_text
             , NewValue.gco_good_id
             , SessionValue
             , '16'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 17, modification coefficient d'utilisation
    if NewValue.com_util_coeff <> OldValue.com_util_coeff then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_util_coeff)
             , to_char(NewValue.com_util_coeff)
             , NewValue.gco_good_id
             , SessionValue
             , decode(TagValue, 6, '49', '17')
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 18, modification coefficient plan directeur
    if NewValue.com_pdir_coeff <> OldValue.com_pdir_coeff then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_pdir_coeff)
             , to_char(NewValue.com_pdir_coeff)
             , NewValue.gco_good_id
             , SessionValue
             , decode(TagValue, 6, '50', '18')
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 19, modification genre de lien
    if NewValue.c_kind_com <> OldValue.c_kind_com then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.c_kind_com
             , NewValue.c_kind_com
             , NewValue.gco_good_id
             , SessionValue
             , '19'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 20, modification emplacement de stock
    if nvl(NewValue.stm_location_id, -10000) <> nvl(OldValue.stm_location_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , aLoc_description_old
             , aLoc_description_new
             , NewValue.gco_good_id
             , SessionValue
             , '20'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 21, modification du code décharge
    if NewValue.c_discharge_com <> OldValue.c_discharge_com then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.c_discharge_com
             , NewValue.c_discharge_com
             , NewValue.gco_good_id
             , SessionValue
             , '21'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 22, modification du numéro d'opération
    if nvl(NewValue.fal_schedule_step_id, -10000) <> nvl(OldValue.fal_schedule_step_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(aScs_step_number_old)
             , to_char(aScs_step_number_new)
             , NewValue.gco_good_id
             , SessionValue
             , '22'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 23, modification du décalage
    if NewValue.com_interval <> OldValue.com_interval then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_interval)
             , to_char(NewValue.com_interval)
             , NewValue.gco_good_id
             , SessionValue
             , '23'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 24, remplacement composant
    if nvl(NewValue.gco_good_id, -10000) <> nvl(OldValue.gco_good_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , aGoo_major_reference_old
             , aGoo_major_reference_new
             , NewValue.gco_good_id
             , SessionValue
             , '24'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 29, modification du stock
    if nvl(NewValue.stm_stock_id, -10000) <> nvl(OldValue.stm_stock_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , aSto_Description_old
             , aSto_description_new
             , NewValue.gco_good_id
             , SessionValue
             , '29'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 30, modification du coefficient % recette
    if NewValue.com_rec_pcent <> OldValue.com_rec_pcent then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , to_char(OldValue.com_rec_pcent)
             , to_char(NewValue.com_rec_pcent)
             , NewValue.gco_good_id
             , SessionValue
             , '30'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 35, modification réverve texte
    if nvl(NewValue.com_res_text, ' ') <> nvl(OldValue.com_res_text, ' ') then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_res_text
             , NewValue.com_res_text
             , NewValue.gco_good_id
             , SessionValue
             , '35'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 36, modification réserve numérique
    if NewValue.com_res_num <> OldValue.com_res_num then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_res_num
             , NewValue.com_res_num
             , NewValue.gco_good_id
             , SessionValue
             , '36'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 42, modification version composant
    if     NewValue.gco_good_id = OldValue.gco_good_id
       and nvl(NewValue.pps_pps_nomenclature_id, -10000) <> nvl(OldValue.pps_pps_nomenclature_id, -10000) then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , aGoo_major_reference_new || ' / ' || nvl(aNom_version_comp_old, ' ')
             , aGoo_major_reference_new || ' / ' || nvl(aNom_version_comp_new, ' ')
             , NewValue.gco_good_id
             , SessionValue
             , '42'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 45, Modification pourcentage déchet
    if NewValue.com_percent_waste <> OldValue.com_percent_waste then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_percent_waste
             , NewValue.com_percent_waste
             , NewValue.gco_good_id
             , SessionValue
             , '45'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 46, Modification quantité fixe déchet
    if NewValue.com_fixed_quantity_waste <> OldValue.com_fixed_quantity_waste then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_fixed_quantity_waste
             , NewValue.com_fixed_quantity_waste
             , NewValue.gco_good_id
             , SessionValue
             , '46'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;

    -- 47, Modification quantité référence perte
    if NewValue.com_qty_reference_loss <> OldValue.com_qty_reference_loss then
      insert into PPS_NOM_HISTORY
                  (PPS_NOM_HISTORY_ID
                 , PPS_NOMENCLATURE_ID
                 , NOM_VERSION
                 , NOM_SEQ
                 , NOM_POS
                 , NOM_OLD_VALUE
                 , NOM_NEW_VALUE
                 , NOM_COMP
                 , NOM_SESSION_ID
                 , C_STATUS_NOM_HISTORY
                 , NOM_SCHEDULE_STEP
                 , A_IDCRE
                 , A_DATECRE
                  )
        select init_id_seq.nextval
             , NewValue.pps_nomenclature_id
             , aNom_version
             , NewValue.com_seq
             , NewValue.com_pos
             , OldValue.com_qty_reference_loss
             , NewValue.com_qty_reference_loss
             , NewValue.gco_good_id
             , SessionValue
             , '47'
             , NewValue.fal_schedule_step_id
             , a_idmod
             , sysdate
          from dual;
    end if;
  end;   -- UpdateHistory_BOND_AU

/************************************************
   procédure UpdateHistory_BOND_AI
*************************************************/
  procedure UpdateHistory_BOND_AI(NewValue PPS_NOM_BOND%rowtype)
  is
    aNom_version             varchar2(20);
    aGoo_major_reference_new varchar2(30);
  begin
    -- initialisation des variables
    aNom_version              := '';
    aGoo_major_reference_new  := '';
    -- récupération du numéro de version de la nomenclature à laquelle
    -- les composants sont ajoutés
    aNom_Version              := NewValue.com_nom_version;

    -- récupération de la référence du bien
    if NewValue.gco_good_id is not null then
      select gco.goo_major_reference
        into aGoo_major_reference_new
        from gco_good gco
       where gco.gco_good_id = NewValue.gco_good_id;
    end if;

    -- 04, ajout de composant
    insert into PPS_NOM_HISTORY
                (PPS_NOM_HISTORY_ID
               , PPS_NOMENCLATURE_ID
               , NOM_VERSION
               , NOM_SEQ
               , NOM_POS
               , NOM_OLD_VALUE
               , NOM_NEW_VALUE
               , NOM_COMP
               , NOM_SESSION_ID
               , C_STATUS_NOM_HISTORY
               , NOM_SCHEDULE_STEP
               , A_IDCRE
               , A_DATECRE
                )
      select init_id_seq.nextval
           , NewValue.pps_nomenclature_id
           , aNom_version
           , NewValue.com_seq
           , NewValue.com_pos
           , null
           , aGoo_major_reference_new
           , NewValue.gco_good_id
           , SessionValue
           , decode(TagValue, 3, '26', 4, '26', 5, '48', 6, '51', '04')
           , NewValue.fal_schedule_step_id
           , NewValue.a_idcre
           , sysdate
        from dual;
  end;   -- procédure UpdateHistory_BOND_AI

/************************************************
   procédure UpdateHistory_BOND_AD
*************************************************/
  procedure UpdateHistory_BOND_AD(OldValue PPS_NOM_BOND%rowtype)
  is
    aNom_version             varchar2(20);
    aGoo_major_reference_old varchar2(30);
  begin
    -- initialisation des variables
    aNom_version              := '';
    aGoo_major_reference_old  := '';
    -- récupération du numéro de version de la nomenclature de laquelle
    -- les composants sont supprimés.
    -- cette requête peut déclencher l'exception Table_mutating lors
    -- de la suppression de la nomenclature
    aNom_Version              := oldValue.com_nom_version;

    -- récupération de la référence du bien
    if OldValue.gco_good_id is not null then
      select gco.goo_major_reference
        into aGoo_major_reference_old
        from gco_good gco
       where gco.gco_good_id = OldValue.gco_good_id;
    end if;

    -- 05, suppression de composant
    insert into PPS_NOM_HISTORY
                (PPS_NOM_HISTORY_ID
               , PPS_NOMENCLATURE_ID
               , NOM_VERSION
               , NOM_SEQ
               , NOM_POS
               , NOM_OLD_VALUE
               , NOM_NEW_VALUE
               , NOM_COMP
               , NOM_SESSION_ID
               , C_STATUS_NOM_HISTORY
               , NOM_SCHEDULE_STEP
               , A_IDCRE
               , A_DATECRE
                )
      select init_id_seq.nextval
           , OldValue.pps_nomenclature_id
           , aNom_version
           , OldValue.com_seq
           , OldValue.com_pos
           , aGoo_major_reference_old
           , null
           , OldValue.gco_good_id
           , SessionValue
           , decode(TagValue, 1, '31', 3, '25', 6, '52', '05')
           , OldValue.fal_schedule_step_id
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , sysdate
        from dual;
  -- déclenché lors de la suppression de la nomenclature
  exception
    when ex.TABLE_MUTATING then
      null;
  end;   -- procédure UpdateHistory_BOND_AD

  /************************************************
  * procédure SetTagValue
  *************************************************/
  procedure SetTagValue(aTagValue number)
  is
  begin
    TagValue  := aTagValue;
  end;

  procedure SetSessionValue(pSessionId out PPS_NOM_HISTORY.NOM_SESSION_ID%type)
  is
  begin
    select to_number(to_char(sysdate, 'YYYYMMDDHH24MISS') )
      into pSessionId
      from dual;

    SessionValue  := pSessionId;
  end;
begin
  -- initialisation de la variable globale
  TagValue  := 0;
  PPS_NOM_HIST.SetSessionValue(SessionValue);
end PPS_NOM_HIST;
