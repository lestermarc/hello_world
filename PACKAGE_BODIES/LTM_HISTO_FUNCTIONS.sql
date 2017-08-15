--------------------------------------------------------
--  DDL for Package Body LTM_HISTO_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_HISTO_FUNCTIONS" 
/**
 * Package de génération des différences entre les versions d'une entité.
 *
 * @version 1.0
 * @date 05/2008
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  --
  -- Internal déclaration
  --

  -- Suivi
  gb_log BOOLEAN := FALSE;
  gtt_log_data_set LOG_DATA_SET;
  gn_log_position INTEGER := 0;

  -- Sélection
  gd_from TIMESTAMP;
  gd_to TIMESTAMP;
  gn_entity_id ltm_entity_log.elo_rec_id%TYPE;
  gv_user_name VARCHAR2(30);

  /** Collection des entités à évaluer. */
  TYPE t_entitylog_list IS TABLE OF ltm_entity_log%ROWTYPE INDEX BY BINARY_INTEGER;
  gtt_entity_log T_ENTITYLOG_LIST;

  /** Collection des différences trouvées. */
  TYPE t_histodata_list IS TABLE OF ltm_histo_data%ROWTYPE INDEX BY BINARY_INTEGER;
  gtt_histo_data T_HISTODATA_LIST;

  /** Données de base pour remplissage de la collection des différences. */
  TYPE t_fill_data IS RECORD (
    author VARCHAR2(30),
    creation TIMESTAMP,
    id NUMBER,
    count_diffs BINARY_INTEGER
  );
  gt_fill_data T_FILL_DATA;


/**
 * Libération des ressources internes.
 */
procedure p_InternalClear is
begin
  gtt_entity_log.DELETE;
  gtt_histo_data.DELETE;
  pc_xml_diffgen.Clear;
end;

/**
 * Ecriture d'information dans le suivi.
 */
procedure p_WriteLog(iv_msg IN VARCHAR2)
is
  lt_log_data LOG_DATA_TYPE;
begin
  gn_log_position := gn_log_position +1;
  lt_log_data.log_position := gn_log_position;
  lt_log_data.log_info := iv_msg;
  gtt_log_data_set(gtt_log_data_set.COUNT+1) := lt_log_data;
end;

/**
 * Validation du retour de l'exécution d'une méthode du générateur de différences.
 */
function p_CheckError(in_diff_error IN NUMBER) return BOOLEAN is
begin
  -- Pas d'erreur, cas le plus fréquent
  if (in_diff_error = pc_xml_diffgen.ERROR_NONE) then
    return TRUE;
  end if;

  -- Log de l'erreur si nécessaire
  if (gb_log) then
    p_WriteLog(pc_xml_diffgen.GetErrorMessage(in_diff_error)||':'||pc_xml_diffgen.GetErrors);
  end if;
  return FALSE;
end;

/**
 * Validation du chargement d'un document par le générateur de différences.
 */
function p_CheckLoading(in_doc_num IN INTEGER, in_is_loaded IN NUMBER) return BOOLEAN is
begin
  if (in_is_loaded > 0) then
    return TRUE;
  end if;

  if (gb_log) then
    p_WriteLog(
      case in_doc_num
        when 1 then 'Error loading first document'
        when 2 then 'Error loading second document'
      end||
      ':'||pc_xml_diffgen.GetErrors);
  end if;
  return FALSE;
end;


--
-- Public déclaration
--

procedure DisableLog is
begin
  gb_log := False;
  ltm_histo_functions.ClearLog;
end;
procedure EnableLog is
begin
  gb_log := True;
end;

function GetLogPosition return INTEGER is
begin
  return gn_log_position;
end;

function GetLogData return LOG_DATA_SET is
begin
  return gtt_log_data_set;
end;

procedure ClearLog is
begin
  gtt_log_data_set.DELETE;
  gn_log_position := 0;
end;


function GetFrom return TIMESTAMP is
begin
  return gd_from;
end;
procedure SetFrom(DateFrom IN TIMESTAMP) is
begin
  gd_from := DateFrom;
end;

function GetTo return TIMESTAMP is
begin
  return gd_to;
end;
procedure SetTo(DateTo IN TIMESTAMP) is
begin
  gd_to := DateTo;
end;

function GetEntity return ltm_entity_log.elo_rec_id%TYPE is
begin
  return gn_entity_id;
end;
procedure SetEntity(Id IN ltm_entity_log.elo_rec_id%TYPE) is
begin
  gn_entity_id := Id;
end;

function GetUser return VARCHAR2 is
begin
  return gv_user_name;
end;
procedure SetUser(Name IN VARCHAR2) is
begin
  gv_user_name := Name;
end;


procedure SetSelection(
  Id IN ltm_entity_log.elo_rec_id%TYPE,
  DateFrom IN TIMESTAMP default null,
  DateTo IN TIMESTAMP default null,
  UserName IN VARCHAR2 default null) is
begin
  gn_entity_id := Id;
  gd_from := DateFrom;
  gd_to := DateTo;
  gv_user_name := UserName;
end;


procedure Clear is
begin
  gd_from := null;
  gd_to := null;
  gn_entity_id := null;
  gv_user_name := null;
  ClearLog;
  p_InternalClear;
end;

function LastError return VARCHAR2 is
begin
  return pc_xml_diffgen.GetErrors;
end;

function RemoveDiff(Id IN ltm_entity_log.elo_rec_id%TYPE) return INTEGER
is
  ln_result INTEGER;
begin
  if (Id is null) then
    delete LTM_HISTO_DATA;
    ln_result := SQL%ROWCOUNT;
  else
    delete LTM_HISTO_DATA where LHD_REC_ID = Id;
    ln_result := SQL%ROWCOUNT;
  end if;
  commit;
  return ln_result;
end;

/**
 * Génération des différences.
 * Collecte les différences dans une collection globale privée.
 */
procedure p_FillDifferences
is
  ln_parent_index NUMBER;
  ln_index NUMBER;
  ln_table_id NUMBER;
  lv_table VARCHAR2(4000);
  lv_field VARCHAR2(4000);
  lv_value VARCHAR2(4000);
  lv_mode VARCHAR2(4000);
  lv_type VARCHAR2(4000);
  lt_histo_data ltm_histo_data%ROWTYPE;
  ln_count BINARY_INTEGER;
begin
  -- Génération des différences
  if (not p_CheckError(pc_xml_diffgen.GenerateDifferences)) then
    return;
  end if;

  -- Collecte les différences dans la collection de différences
  if (pc_xml_diffgen.FindFirstDiff(ln_parent_index, ln_index, ln_table_id, lv_table, lv_field, lv_value, lv_mode, lv_type) > 0) then
    ln_count := gt_fill_data.count_diffs;
    loop
      select init_id_seq.nextval
      into lt_histo_data.ltm_histo_data_id
      from DUAL;
      --
      lt_histo_data.lhd_parent_index := case when ln_parent_index >= 0 then ln_parent_index end;
      lt_histo_data.lhd_index := case when ln_index >= 0 then ln_index end;
      lt_histo_data.lhd_date := gt_fill_data.creation;
      lt_histo_data.lhd_user := gt_fill_data.author;
      lt_histo_data.lhd_rec_id := gt_fill_data.id;
      lt_histo_data.lhd_table_id := ln_table_id;
      lt_histo_data.lhd_table := lv_table;
      lt_histo_data.lhd_field := lv_field;
      lt_histo_data.lhd_value := lv_value;
      lt_histo_data.lhd_mode := lv_mode;
      lt_histo_data.lhd_type := lv_type;
      -- Ajout de l'élément dans la collection
      ln_count := ln_count + 1;
      gtt_histo_data(ln_count) := lt_histo_data;
      exit when pc_xml_diffgen.FindNextDiff(ln_parent_index, ln_index, ln_table_id, lv_table, lv_field, lv_value, lv_mode, lv_type) = 0;
    end loop;
    p_WriteLog('.. find '||to_char(ln_count - gt_fill_data.count_diffs)||' differences');
    gt_fill_data.count_diffs := ln_count;
  elsif (gb_log) then
    p_WriteLog('.. no difference inserted');
  end if;
end;

function p_new_entity(Id IN NUMBER, SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE)
  return XMLType
is
  lx_result XMLType;
  lv_old_date_format VARCHAR2(64);
begin
  lv_old_date_format := ltm_track_utils.SetDateFormat(ltm_track_utils.GetDefaultDateFormat);
  begin
    lx_result := ltm_track.Get_New_Entity_XMLType(Id, SysLogType);
    exception
      when OTHERS then null;
  end;
  lv_old_date_format := ltm_track_utils.SetDateFormat(lv_old_date_format);
  return lx_result;
end;

/**
 * Evaluation des documents.
 *
 * L'évaluation des différence ne peut se faire qu'entre deux documents.
 * Comme chaque enregistrement n'en contient qu'un seul, c'est celui
 * de l'enregistrement suivant qui est utilisé.
 * Ce qui donne:
 *    SetFirstDocument #1
 *      fetch next document
 *    SetSecondDocument #2
 *      Evaluation #1 => #2
 *    SetFirstDocument #2
 *      fetch next document
 *    SetSecondDocument #3
 *      Evaluation #2 => #3
 *    etc...
 * Afin d'améliorer les performance, plusieurs traitement sont exécutés en fin
 * de traitement:
 *   o Insertion des différence en une seule fois.
 *   o Mise à jour des liens père-fils entre les enregitrements du même lot
 *     de différences.
 */
procedure p_ProcessEntities
is
  lt_entity_log ltm_entity_log%ROWTYPE;
  ln_pos BINARY_INTEGER;
  ln_count BINARY_INTEGER;
  lx_new_entity XMLType;
begin
  gt_fill_data.count_diffs := 0;
  -- Le traitement des entités doit se faire dans l'ordre inverse de la collection,
  -- car une entité supplémentaire à été ajoutée à la fin de la liste pour permettre
  -- de trouver les premières différences
  ln_pos := gtt_entity_log.LAST;
  ln_count := gtt_entity_log.FIRST;
  lt_entity_log := gtt_entity_log(ln_pos);
  loop
    if (gb_log) then
      p_WriteLog('.. set first ('||to_char(lt_entity_log.ltm_entity_log_id)||')');
    end if;
    exit when not p_CheckLoading(1, pc_xml_diffgen.SetFirstDocument(lt_entity_log.elo_entity.getClobVal()));

    -- Record suivant
    ln_pos := ln_pos - 1;
    if (ln_pos >= ln_count) then
      -- Affecte le second document
      lt_entity_log := gtt_entity_log(ln_pos);
      if (gb_log) then
        p_WriteLog('.. set second ('||to_char(lt_entity_log.ltm_entity_log_id)||')');
      end if;
      -- Validation du chargement du deuxième document
      exit when not p_CheckLoading(2, pc_xml_diffgen.SetSecondDocument(lt_entity_log.elo_entity.getClobVal()));
    else
      -- Sortie anticipée si la date de fin est spécifiée
      exit when gd_to is not null;
      -- Affecte le second document avec les données de l'entité courante
      lx_new_entity := p_new_entity(lt_entity_log.elo_rec_id, lt_entity_log.c_ltm_sys_log);
      exit when lx_new_entity is null;
      if (gb_log) then
        p_WriteLog('.. set second (current)');
      end if;
      -- Validation du chargement du deuxième document
      exit when not p_CheckLoading(2, pc_xml_diffgen.SetSecondDocument(lx_new_entity.getClobVal()));
    end if;

    -- Evaluation des différences
    if (gb_log) then
      p_WriteLog('compute differences ...');
    end if;

    exit when not p_CheckError(pc_xml_diffgen.Execute);
    if (pc_xml_diffgen.HasDifferences > 0) then
      -- Insertion des différences
      if (lx_new_entity is null) then
        gt_fill_data.author := lt_entity_log.elo_author;
        gt_fill_data.creation := lt_entity_log.elo_create;
      else
        gt_fill_data.author := pcs.PC_I_LIB_SESSION.GetUserIni;
        gt_fill_data.creation := SysTimestamp;
      end if;
      gt_fill_data.id := lt_entity_log.elo_rec_id;
      -- Chargement de la liste des différences avec mise à jour
      -- du nombre de différence
      p_FillDifferences;
    elsif (gb_log) then
      p_WriteLog('... no difference');
    end if;

    exit when ln_pos < ln_count;
  end loop;

  if (gt_fill_data.count_diffs > 0) then
    if (gb_log) then
      p_WriteLog('inserting '||to_char(gt_fill_data.count_diffs)||' differences');
    end if;
    -- Si la collection des différences n'est pas vide,
    -- insertion massive dans la table des différences
    forall cpt in 1..gtt_histo_data.COUNT
      insert /*+ APPEND NOLOGGING PARALLEL */ into LTM_HISTO_DATA
      values gtt_histo_data(cpt);
    commit;

    -- Mise à jour de l'identifiant du record parents pour les records enfants.
    if (gb_log) then
      p_WriteLog('Updating hierarchic links');
    end if;
    -- Ne pas tenir compte du lien PARENT.LHD_VALUE = CHILDREN.LHD_TABLE_ID car si
    -- la table n'a pas son propre champ identifiant (<TABLE_NAME>_ID), la valeur
    -- contenue dans LHD_TABLE_ID sera vide
    update LTM_HISTO_DATA CHILDREN
    set LTM_HISTO_DATA_PARENT_ID = (select LTM_HISTO_DATA_ID from LTM_HISTO_DATA
                                    where LHD_TYPE = 'TABLE' and
                                          LHD_INDEX = CHILDREN.lhd_parent_index and
                                          /*LHD_VALUE = CHILDREN.LHD_TABLE_ID and */LHD_FIELD = CHILDREN.LHD_TABLE and
                                          LHD_DATE = CHILDREN.LHD_DATE and
                                          lhd_user = CHILDREN.LHD_USER and
                                          LHD_REC_ID = CHILDREN.LHD_REC_ID)
    where LTM_HISTO_DATA_PARENT_ID is null and --LHD_TABLE_ID != 0 AND
      Exists(select 1 from LTM_HISTO_DATA
             where LHD_TYPE = 'TABLE' and
                   LHD_INDEX = CHILDREN.LHD_PARENT_INDEX and
                   /*LHD_VALUE = CHILDREN.LHD_TABLE_ID and */LHD_FIELD = CHILDREN.LHD_TABLE and
                   LHD_DATE = CHILDREN.LHD_DATE and
                   LHD_USER = CHILDREN.LHD_USER and
                   LHD_REC_ID = CHILDREN.LHD_REC_ID);
    commit;
  end if;

  if (gb_log) then
    p_WriteLog('Processing ended ('||to_char(gtt_entity_log.COUNT)||')');
  end if;
end;

/**
 * Création d'une document xml contenant uniquement le tag principal d'une entité.
 * @param iv_root_name Nom du tag principal.
 * @return un document xml.
 */
function p_new_empty_entity(iv_root_name IN VARCHAR2) return XMLType
is
  lx_result XMLType;
begin
  select XMLElement(MAIN_ENTITY, '')
  into lx_result
  from DUAL;
  return ltm_xml_utils.transform_root_ref('MAIN_ENTITY', iv_root_name, lx_result);
end;

/**
 * Recherche du record de l'entité précédant la première entité de la sélection,
 * afin d'obtenir une référence correcte pour démarrer l'évaluation des différences.
 * S'il n'y a pas d'entité, une entité virtuelle sera créée.
 * Cette entité de référence permet d'obtenir des différences même s'il n'y a
 * qu'une seul record dans le suivi de modification.
 * @param irec_min_log Record de la première entité de la sélection.
 * @return le record de l'entité précédant la première entité, ou un record virtuel.
 */
function p_get_prev_entity(it_min_log IN ltm_entity_log%ROWTYPE)
  return ltm_entity_log%ROWTYPE
is
  lt_result ltm_entity_log%ROWTYPE;
begin
  if (gv_user_name is null) then
    select * into lt_result
    from LTM_ENTITY_LOG
    where ELO_REC_ID = gn_entity_id and ELO_CREATE = (
      select Max(ELO_CREATE)
      from LTM_ENTITY_LOG
      where ELO_REC_ID = gn_entity_id and ELO_CREATE < it_min_log.ELO_CREATE
    );
  else
    select * into lt_result
    from LTM_ENTITY_LOG
    where ELO_REC_ID = gn_entity_id and ELO_CREATE = (
      select Max(elo_create)
      from LTM_ENTITY_LOG
      where ELO_REC_ID = gn_entity_id and ELO_CREATE < it_min_log.ELO_CREATE and
        ELO_AUTHOR = gv_user_name
    );
  end if;
  return lt_result;

  exception
    when NO_DATA_FOUND then
      lt_result.LTM_ENTITY_LOG_ID := -1.0;
      lt_result.C_LTM_SYS_LOG := it_min_log.C_LTM_SYS_LOG;
      lt_result.ELO_ENTITY := p_new_empty_entity(it_min_log.ELO_ENTITY.getRootElement());
      lt_result.ELO_CREATE := it_min_log.ELO_CREATE - 1;
      lt_result.ELO_AUTHOR := it_min_log.ELO_AUTHOR;
      lt_result.ELO_REC_ID := it_min_log.ELO_REC_ID;
      return lt_result;
end;

/**
 * Evaluation des différences entre documents.
 *
 * La seule sélection obligatoire est l'identifiant de l'entité afin de
 * garantir la comparaison de documents de type identique.
 *
 * En cas de null pour la sélection des dates de début et de fin, une
 * variable locale est initialisée avec une valeur suffisament éloignée
 * pour éviter toutes collisions. La variable de package correspondante
 * ne doit pas être modifiée, pour éviter une confusion par l'utilisateur.
 */
procedure GenerateDiff
is
  ld_from TIMESTAMP;
  ld_to TIMESTAMP;
begin
  -- Libération des ressources
  ltm_histo_functions.ClearLog;
  p_InternalClear;

  -- L'id de l'entité ne peut pas être null, car
  -- l'évaluation des différences ne peut se faire qu'entre
  -- des documents de même type
  if (gn_entity_id is null) then
    raise_application_error(-20000, 'Entity id is not specified.');
    return;
  end if;
  -- Date de début, en cas de null,
  -- prend une date suffisament éloignée dans la passé
  ld_from := Coalesce(gd_from, to_timestamp('01011900', 'DDMMYYYY'));
  -- Date de fin, en cas de null,
  -- prend une date très éloignée dans le futur
  ld_to := Coalesce(gd_to, to_timestamp('01014000', 'DDMMYYYY'));

  if (gb_log) then
    p_WriteLog(
      'Entities selection :'||
      ' dates between '||to_char(ld_from,'dd.mm.yyyy hh24:mi:ss.FF9')||' and '||to_char(ld_to,'dd.mm.yyyy hh24:mi:ss.FF9')||
      ' for entity id '||to_char(gn_entity_id)||
      case when gv_user_name is not null then ' and user name is '||gv_user_name end
    );
  end if;
  -- Il est très important que la recherche des enregistrements soit faite
  -- dans l'ordre décroissants pour la suite des opérations
  if (gv_user_name is null) then
    select * bulk collect into gtt_entity_log
    from LTM_ENTITY_LOG
    where ELO_CREATE between ld_from and ld_to and ELO_REC_ID = gn_entity_id
    order by ELO_CREATE desc;
  else
    select * bulk collect into gtt_entity_log
    from LTM_ENTITY_LOG
    where ELO_CREATE between ld_from and ld_to and ELO_REC_ID = gn_entity_id and
      ELO_AUTHOR = gv_user_name
    order by ELO_CREATE desc;
  end if;

  if (gtt_entity_log.COUNT > 0) then
    -- Ajout de l'élément de référence qui précède la première entité
    -- qui se trouve être la dernière de la collection
    gtt_entity_log(gtt_entity_log.COUNT+1) := p_get_prev_entity(gtt_entity_log(gtt_entity_log.COUNT));
  end if;

  if (gtt_entity_log.COUNT = 0) then
    if (gb_log) then
      p_WriteLog('No entity to process');
    end if;
    return;
  elsif (gb_log) then
    p_WriteLog('Processing entities');
  end if;

  -- Génération des différences
  p_ProcessEntities;

  p_InternalClear;

  exception
    when OTHERS then
      p_InternalClear;
      if (gb_log) then
        p_WriteLog(dbms_utility.format_error_stack);
      end if;
      raise_application_error(-20001,
        'Error during differences generation :'||
        ' dates between '||to_char(ld_from,'dd.mm.yyyy hh24:mi:ss.FF9')||' and '||to_char(ld_to,'dd.mm.yyyy hh24:mi:ss.FF9')||
        ', entity id is "'||to_char(gn_entity_id)||'"'||Chr(10)||
        case when gv_user_name is not null then 'for user "'||gv_user_name||'"' end||Chr(10)||
        sqlerrm||Chr(10)||dbms_utility.format_error_stack);
end;

/**
 * Evaluation des différences entre documents.
 * @see GenerateDiff
 */
procedure GenerateDiff(EntityId IN ltm_entity_log.elo_rec_id%TYPE,
  DateFrom IN TIMESTAMP default null,
  DateTo IN TIMESTAMP default null,
  UserName IN VARCHAR2 default null) is
begin
  ltm_histo_functions.SetSelection(EntityId, DateFrom, DateTo, UserName);
  ltm_histo_functions.GenerateDiff;
end;

END LTM_HISTO_FUNCTIONS;
