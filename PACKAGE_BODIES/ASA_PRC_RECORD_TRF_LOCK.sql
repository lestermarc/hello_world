--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TRF_LOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TRF_LOCK" 
/**
 * Gestion de la circulation de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

/**
 * Création/mise à jour d'un verrou.
 * @param in_record_id  Identifiant du dossier SAV.
 * @parma in_mode  Mode de mise à jour.
 */
procedure p_add_lock(
  in_record_id IN asa_record.asa_record_id%TYPE,
  in_mode IN INTEGER)
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordLock,
    iot_crud_definition => lt_crud_def);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ASA_RECORD_ID', in_record_id);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARL_SESSION_ID', dbms_session.unique_session_id);

  if (in_mode = 0) then
    fwk_i_mgt_entity.InsertEntity(lt_crud_def);
  else
    fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  end if;
  fwk_i_mgt_entity.Release(lt_crud_def);

  commit;

  exception
    when OTHERS then
      rollback;
      raise;
end;

/**
 * Suppression d'un verrou.
 * @param in_record_lock_id  Identifiant du verrou.
 */
procedure p_remove_lock(
  in_record_lock_id in asa_record_lock.asa_record_lock_id%TYPE)
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordLock,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_lock_id);
  fwk_i_mgt_entity.DeleteEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);

  commit;

  exception
    when OTHERS then
      rollback;
end;

/**
 * Suppression d'un collection de verrous.
 * @param itt_id  Collection de verrous.
 */
procedure p_remove_lock(
  itt_id IN asa_typ_record_trf_def.TT_ID)
is
begin
  for cpt in itt_id.FIRST..itt_id.LAST loop
    p_remove_lock(itt_id(cpt));
  end loop;
end;

/**
 * Suppression des verrous existants pour des sessions inexistantes, avec
 * possibilité de spécfier un dossier SAV en paticulier.
 * @param in_record_id  Identifiant du dossier.
 */
procedure p_remove_dead_session(
  in_record_id IN asa_record.asa_record_id%TYPE default null)
is
  ltt_id asa_typ_record_trf_def.TT_ID;
begin
  if (in_record_id is not null and in_record_id > 0.0) then
    select ASA_RECORD_LOCK_ID
    bulk collect into ltt_id
    from ASA_RECORD_LOCK
    where ASA_RECORD_ID = in_record_id and is_session_alive(ARL_SESSION_ID)=0;
  else
    select ASA_RECORD_LOCK_ID
    bulk collect into ltt_id
    from ASA_RECORD_LOCK
    where is_session_alive(ARL_SESSION_ID)=0;
  end if;

  if (ltt_id is not null and ltt_id.COUNT > 0) then
    p_remove_lock(ltt_id);
  end if;
end;

/**
 * Vérification de la présence du verrou d'un dossier SAV pour la session.
 * @param in_record_id  Identifiant du dossier.
 * @return 1 s'il y a un verrou, sinon 0.
 */
function p_already_locked(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
is
  ln_result INTEGER;
begin
  select Count(*)
  into ln_result
  from DUAL
  where Exists(select 1 from ASA_RECORD_LOCK
               where ASA_RECORD_ID = in_record_id and
                     ARL_SESSION_ID = dbms_session.unique_session_id);
  return ln_result;

  exception
    when NO_DATA_FOUND then
      return 0;
end;



--
-- Public methods
--

function is_locked(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
is
  ln_result INTEGER;
begin
  -- suppression des verrous obsolètes du dossier
  p_remove_dead_session(in_record_id);

  -- sélection du nombre de session conervant un verrou sur le dossier
  select Count(*)
  into ln_result
  from DUAL
  where Exists(select 1 from ASA_RECORD_LOCK
               where ASA_RECORD_ID = in_record_id and
                     is_session_alive(ARL_SESSION_ID)=1);
  return ln_result;
end;

procedure protect(
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  ln_id fwk_i_typ_definition.T_CRUD_DEF;
begin
  -- suppression des verrous obsolètes du dossier
  p_remove_dead_session(in_record_id);

  -- ajout du verrou sur le dossier
  p_add_lock(in_record_id, p_already_locked(in_record_id));
end;

procedure unprotect(
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_id asa_typ_record_trf_def.TT_ID;
begin
  -- suppression des verrous obsolètes
  p_remove_dead_session;

  -- recherche des verrous du dossier pour la session
  select ASA_RECORD_LOCK_ID
  bulk collect into ltt_id
  from ASA_RECORD_LOCK
  where ASA_RECORD_ID = in_record_id and
        ARL_SESSION_ID = dbms_session.unique_session_id;
  if (ltt_id is not null and ltt_id.COUNT > 0) then
    p_remove_lock(ltt_id);
  end if;
end;

END ASA_PRC_RECORD_TRF_LOCK;
