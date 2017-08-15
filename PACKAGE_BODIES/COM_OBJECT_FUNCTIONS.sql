--------------------------------------------------------
--  DDL for Package Body COM_OBJECT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_OBJECT_FUNCTIONS" 
/**
 * Package spécialisé pour l'effacement de modules, avec prise en charge
 * de la suppression des liaisons des tables de la société sur ces modules.
 *
 * @version 1.1
 * @date 21.03.2008
 * @author mdesboeufs
 * @author spfister
 */
AS

--
-- Internal declarations
--

  /**
   * Déclaration d'un sous-type pour l'origine d'un source.
   */
  SUBTYPE SOURCE_T IS BINARY_INTEGER RANGE 0..2 NOT NULL;

  /** La source concerne un objet COM */
  SOURCE_COM_OBJECT CONSTANT SOURCE_T := 0;
  /** La source concerne un objet de base */
  SOURCE_BASIC_OBJECT CONSTANT SOURCE_T := 1;
  /** La source concerne un objet de gestion */
  SOURCE_OBJECT CONSTANT SOURCE_T := 2;


/**
 * Effacement des références d'un objet de gestion dans la thème WFL.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_wfl(
  ObjectId IN pcs.pc_object.pc_object_id%TYPE)
is
begin
  DELETE wfl_object_processes WHERE pc_object_id = ObjectId;
  DELETE wfl_process_instances WHERE pc_object_id = ObjectId;
  DELETE wfl_process_inst_log WHERE pc_object_id = ObjectId;

  exception
    when others then
      null;
end;

/**
 * Effacement des références d'un objet de gestion dans la thème PAC.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_pac(
  ObjectId IN pcs.pc_object.pc_object_id%TYPE)
is
begin
  DELETE pac_crm_config WHERE pc_object_id = ObjectId;

  exception
    when others then
      null;
end;

/**
 * Effacement des références d'un champ dans le thème LOG, STM.
 * @param FieldId Identifiant du champ.
 */
procedure p_delete_log(
  FieldId IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
is
begin
  DELETE gco_attribute_fields WHERE pc_fldsc_id = FieldId;
  DELETE gco_text_formula_sequence WHERE pc_fldsc_id = FieldId;
  DELETE gco_transfer_list WHERE pc_fldsc_id = FieldId;
  DELETE sqm_attribute_fields WHERE pc_fldsc_id = FieldId;

  exception
    when OTHERS then
      null;
end;


/**
 * Effacement des références des paramètres liés à un champ.
 * @param FieldId Identifiant du champ.
 */
procedure p_delete_sql_parameters(
  FieldId IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
is
  ltt_param_list ID_TABLE_TYPE;
begin
  -- Garnissage de la liste des identifiants des paramètres
  SELECT pc_sqpar_id BULK COLLECT INTO ltt_param_list
  FROM pcs.pc_sqpar
  WHERE pc_fldsc_id = FieldId AND pc_sqpar_id IS NOT NULL;
  if (ltt_param_list.COUNT > 0) then
    -- Suppression DML and pc_sqstp et pc_stored_proc_params

    forall cpt in 1..ltt_param_list.LAST
      DELETE pcs.pc_sqstp WHERE pc_sqpar_id = ltt_param_list(cpt);

    forall cpt in 1..ltt_param_list.LAST
      DELETE pcs.pc_stored_proc_params WHERE pc_sqpar_id = ltt_param_list(cpt);
  end if;

  DELETE pcs.pc_sqpar WHERE pc_fldsc_id = FieldId;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement des références d'un objet de gestion dans les classifications.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_classification(
  ObjectId IN classification.pc_object_id%TYPE)
is
begin
  DELETE classification WHERE pc_object_id = ObjectId;

  exception
    when OTHERS then
      null;
end;


/**
 * Effacement des références d'un objet de gestion dans la table de copie
 * des lookups.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_patch_fklups(
  ObjectId IN pcs.pc_patch_fklup.pc_object_id%TYPE)
is
begin
  DELETE pcs.pc_patch_fklup WHERE pc_object_id = ObjectId;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement des références d'un objet de base ou de gestion dans la table
 * des validations.
 * @param ObjectId Identifiant de l'objet de base ou de gestion.
 */
procedure p_delete_validations(
  ObjectId IN pcs.pc_validation.pc_object_id%TYPE)
is
begin
  DELETE pcs.pc_validation WHERE pc_object_id = ObjectId;

  exception
    when OTHERS then
      null;
end;


/**
 * Effacement des références d'un objet de base dans la table des déclencheurs
 * du workflow pour des objets de base.
 * @param ObjectId Identifiant de l'objet de base.
 */
procedure p_delete_basic_object_wfl(
  BasicObjectId IN pcs.pc_basic_object.pc_basic_object_id%TYPE)
is
begin
  DELETE pcs.pc_basic_object_wfl_event WHERE pc_basic_object_id = BasicObjectId;

  exception
    when OTHERS then
      null;
end;


/**
 * Effacement des références d'un objet de gestion dans la tables des éléments
 * individualisés.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_indiv_items(
  ObjectId IN pcs.pc_item_indiv.pc_object_id%TYPE)
is
begin
  DELETE pcs.pc_item_indiv WHERE pc_object_id = ObjectId;

  exception
    when OTHERS then
      null;
end;


/**
 * Effacement des références d'un objet de base ou de gestion dans les
 * commandes de recherche.
 * @param Source Type de source
 * @param ObjectId Identifiant de l'object de base ou de gestion.
 * @exception Une exception est levée si le type de source spécifie un object COM.
 */
procedure p_delete_search_commands(
  Source IN SOURCE_T, ObjectId IN NUMBER)
is
begin
  case Source
    when SOURCE_BASIC_OBJECT then
      DELETE pcs.pc_search_command WHERE pc_basic_object_id = ObjectId;

    when SOURCE_OBJECT then
      DELETE pcs.pc_search_command WHERE pc_object_id = ObjectId;

    else
      ra('COM Object source not allowed here');
  end case;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement des références d'un objet de base ou de gestion dans les
 * commandes de recherche.
 * @param Source Type de source
 * @param ObjectId Identifiant de l'object de base ou de gestion.
 * @exception Une exception est levée si le type de source spécifie un object COM.
 */
procedure p_delete_portal(
  ObjectId IN NUMBER)
is
  ltCRUD_DEF            FWK_I_TYP_DEFINITION.t_crud_def;
begin
  for ltplPortalModule in (select pc_portal_module_id from pcs.pc_portal_module where pc_object_id = ObjectId) loop
    PCS.PC_PRC_PORTAL_TOOLS.DeleteModule(ltplPortalModule.pc_portal_module_id);
  end loop;
exception
  when OTHERS then
    null;
end;

/**
 * Effacement des références d'un objet de base ou de gestion dans la table
 * des données disponibles pour les commandes de recherche.
 * @param Source Type de source.
 * @param ObjectId Identifiant de l'objet de base ou de gestion.
 * @exception Une exception est levée si le type de source spécifie un object COM.
 */
procedure p_delete_search_views(
  Source IN SOURCE_T, ObjectId IN NUMBER)
is
  ltt_search_view_list ID_TABLE_TYPE;
begin
  case Source
    when SOURCE_BASIC_OBJECT then
      SELECT pc_search_view_id BULK COLLECT INTO ltt_search_view_list
      FROM pcs.pc_search_view
      WHERE pc_basic_object_id = ObjectId;

    when SOURCE_OBJECT then
      SELECT pc_search_view_id BULK COLLECT INTO ltt_search_view_list
      FROM pcs.pc_search_view
      WHERE pc_object_id = ObjectId;

    else
      ra('COM Object source not allowed here');
  end case;
  if (ltt_search_view_list.COUNT > 0) then
    -- Suppression DML des commandes liées
    forall cpt in 1..ltt_search_view_list.LAST
      DELETE pcs.pc_search_command WHERE pc_search_view_id = ltt_search_view_list(cpt);
    -- Suppression DML des search view
    forall cpt in 1..ltt_search_view_list.LAST
      DELETE pcs.pc_search_view WHERE pc_search_view_id = ltt_search_view_list(cpt);
  end if;

  exception
    when others then
      null;
end;

/**
 * Effacement des références d'un champ virtuel.
 * @param FieldId Identifiant du champ.
 */
procedure p_delete_virtual_fields(
  FieldId IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
is
  ltt_vfield_list ID_TABLE_TYPE;
begin
  SELECT pc_fldsc_id BULK COLLECT INTO ltt_vfield_list
  FROM pcs.pc_fldsc
  WHERE pc_vfield_value_id = FieldId;
  if (ltt_vfield_list.COUNT > 0) then
    for cpt in 1..ltt_vfield_list.LAST loop
      --p_delete_virtual_fields(ltt_vfield_list(cpt));
      p_delete_sql_parameters(ltt_vfield_list(cpt));
      p_delete_log(ltt_vfield_list(cpt));
    end loop;

    forall cpt in 1..ltt_vfield_list.LAST
      DELETE pcs.pc_fldsc WHERE pc_fldsc_id = ltt_vfield_list(cpt);
  end if;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement des références d'un objet de gestion dans les champs.
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_fields(
  ObjectId IN pcs.pc_fldsc.pc_object_id%TYPE)
is
  ltt_field_list ID_TABLE_TYPE;
begin
  SELECT pc_fldsc_id BULK COLLECT INTO ltt_field_list
  FROM pcs.pc_fldsc
  WHERE pc_object_id = ObjectId;
  if (ltt_field_list.COUNT > 0) then
    for cpt in 1..ltt_field_list.LAST loop
      p_delete_virtual_fields(ltt_field_list(cpt));
      p_delete_sql_parameters(ltt_field_list(cpt));
      p_delete_log(ltt_field_list(cpt));
    end loop;

    forall cpt in 1..ltt_field_list.LAST
      DELETE pcs.pc_fldsc WHERE pc_fldsc_id = ltt_field_list(cpt);
  end if;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement des références d'un objet de gestion dans les champs de type "tunnel".
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_tunnel(
  ObjectId IN pcs.pc_fldsc.pc_object_id%TYPE)
is
  ltt_field_list ID_TABLE_TYPE;
begin
  update pcs.pc_fldsc
  set pc_call_object_id = null
  where pc_call_object_id = ObjectId;
end;

/**
 * Effacement des références d'un objet de gestion dans les champs de type "tunnel".
 * @param ObjectId Identifiant de l'objet de gestion.
 */
procedure p_delete_basic_tunnel(
  ObjectId IN pcs.pc_fldsc.pc_object_id%TYPE)
is
  ltt_field_list ID_TABLE_TYPE;
begin
  update pcs.pc_fldsc
  set pc_basic_object_id = null
  where pc_basic_object_id = ObjectId;
end;

/**
 * Effacement d'un object COM.
 * @param ObjectId Identifiant de l'objet COM.
 * @param StatusModule Statut de l'effacement.
 */
procedure p_delete_pc_com_object(
  ObjectId IN pcs.pc_com_objects.pc_com_objects_id%TYPE,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
begin
  DELETE pcs.pc_com_objects WHERE pc_com_objects_id = ObjectId;
  if (SQL%FOUND) then
    StatusModule.is_com_object_deleted := TRUE;
  end if;

  exception
    when OTHERS then
      null;
end;

/**
 * Effacement d'un object de base.
 * @param Source Type de source.
 * @param ObjectId Identifiant de l'objet COM ou de base.
 * @param StatusModule Statut de l'effacement.
 * @exception Une exception est levée si le type de source spécifie un objet de gestion.
 */
procedure p_delete_pc_basic_object(
  Source IN SOURCE_T, ObjectId IN NUMBER,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
  ltt_basic_object_list ID_TABLE_TYPE;
begin
  case Source
    when SOURCE_COM_OBJECT then
      SELECT pc_basic_object_id BULK COLLECT INTO ltt_basic_object_list
      FROM pcs.pc_basic_object
      WHERE pc_com_objects_id = ObjectId;

    when SOURCE_BASIC_OBJECT then
      SELECT pc_basic_object_id BULK COLLECT INTO ltt_basic_object_list
      FROM pcs.pc_basic_object
      WHERE pc_basic_object_id = ObjectId;

    else
      ra('Object source not allowed here');
  end case;
  if (ltt_basic_object_list.COUNT > 0) then
    for cpt in 1..ltt_basic_object_list.LAST loop
      p_delete_basic_object_wfl(ltt_basic_object_list(cpt));
      p_delete_validations(ltt_basic_object_list(cpt));
      p_delete_search_commands(SOURCE_BASIC_OBJECT, ltt_basic_object_list(cpt));
      p_delete_search_views(SOURCE_BASIC_OBJECT, ltt_basic_object_list(cpt));
      p_delete_basic_tunnel(ltt_basic_object_list(cpt));
    end loop;

    forall cpt in 1..ltt_basic_object_list.LAST
      DELETE pcs.pc_basic_object WHERE pc_basic_object_id = ltt_basic_object_list(cpt);

    StatusModule.is_basic_object_deleted := TRUE;
  else
    -- si l'objet est déjà effacé on renvoie true
    StatusModule.is_basic_object_deleted := TRUE;
    StatusModule.is_object_deleted := TRUE;
  end if;

  exception
    when others then
      null;
end;


--
-- General removing methods declaration
--

/**
 * Effacement d'un objet de gestion.
 * @param Source Type de source.
 * @param ObjectId Identifiant d'un objet COM, de base ou de gestion.
 * @param StatusModule Statut de l'effacement.
 */
procedure p_delete_pc_object(
  Source IN SOURCE_T, ObjectId IN NUMBER,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
  ltt_object_list ID_TABLE_TYPE;
begin
  case Source
    when SOURCE_COM_OBJECT then
      SELECT pc_object_id BULK COLLECT INTO ltt_object_list
      FROM pcs.pc_object
      WHERE pc_basic_object_id = (SELECT pc_basic_object_id FROM pcs.pc_basic_object
                                  WHERE pc_com_objects_id = ObjectId);

    when SOURCE_BASIC_OBJECT then
      SELECT pc_object_id BULK COLLECT INTO ltt_object_list
      FROM pcs.pc_object
      WHERE pc_basic_object_id = ObjectId;

    when SOURCE_OBJECT then
      SELECT pc_object_id BULK COLLECT INTO ltt_object_list
      FROM pcs.pc_object
      WHERE pc_object_id = ObjectId;
  end case;
  if (ltt_object_list.COUNT > 0) then
    for cpt IN 1..ltt_object_list.LAST loop
      p_delete_indiv_items(ltt_object_list(cpt));
      p_delete_patch_fklups(ltt_object_list(cpt));
      p_delete_validations(ltt_object_list(cpt));
      p_delete_fields(ltt_object_list(cpt));
      p_delete_search_views(SOURCE_OBJECT, ltt_object_list(cpt));
      p_delete_classification(ltt_object_list(cpt));
      p_delete_search_commands(SOURCE_OBJECT, ltt_object_list(cpt));
      p_delete_portal(ltt_object_list(cpt));
      p_delete_wfl(ltt_object_list(cpt));
      p_delete_pac(ltt_object_list(cpt));
      p_delete_tunnel(ltt_object_list(cpt));
    end loop;

    -- DML to remove objects
    forall cpt IN 1..ltt_object_list.LAST
      DELETE pcs.pc_object WHERE pc_object_id = ltt_object_list(cpt);

    StatusModule.is_object_deleted := TRUE;
  else
    -- si l'objet est déjà effacé on renvoie true
    StatusModule.is_object_deleted := TRUE;
  end if;

   exception
     when OTHERS then
       raise;
end;


--
-- Public methods declaration
--

procedure delete_pc_com_object(
  ObjectName IN pcs.pc_com_objects.coo_name%TYPE,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
  ln_com_object_id pcs.pc_com_objects.pc_com_objects_id%TYPE;
begin
  StatusModule.is_com_object_deleted := FALSE;
  StatusModule.is_basic_object_deleted := FALSE;
  StatusModule.is_object_deleted := FALSE;

  -- Recherche de l'identifiant de l'objet COM
  begin
    SELECT pc_com_objects_id INTO ln_com_object_id
    FROM pcs.pc_com_objects
    WHERE coo_name = ObjectName;

    exception
      when NO_DATA_FOUND then
        -- si non existant, pas d'erreur de suppression
        StatusModule.is_com_object_deleted := TRUE;
        StatusModule.is_basic_object_deleted := TRUE;
        StatusModule.is_object_deleted := TRUE;
        return;
  end;

  p_delete_pc_object(SOURCE_COM_OBJECT, ln_com_object_id, StatusModule);
  p_delete_pc_basic_object(SOURCE_COM_OBJECT, ln_com_object_id, StatusModule);
  p_delete_pc_com_object(ln_com_object_id, StatusModule);
end;


procedure delete_pc_basic_object(
  ObjectName IN pcs.pc_basic_object.obj_name%TYPE,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
  ln_basic_object_id pcs.pc_basic_object.pc_basic_object_id%TYPE;
begin
  StatusModule.is_com_object_deleted := FALSE;
  StatusModule.is_basic_object_deleted := FALSE;
  StatusModule.is_object_deleted := FALSE;

  -- Recherche de l'identifiant de l'objet de base
  begin
    SELECT pc_basic_object_id INTO ln_basic_object_id
    FROM pcs.pc_basic_object
    WHERE obj_name = ObjectName;

    exception
      when NO_DATA_FOUND then
        -- si non existant, pas d'erreur de suppression
        StatusModule.is_basic_object_deleted := TRUE;
        StatusModule.is_object_deleted := TRUE;
        return;
  end;

  p_delete_pc_object(SOURCE_BASIC_OBJECT, ln_basic_object_id, StatusModule);
  p_delete_pc_basic_object(SOURCE_BASIC_OBJECT, ln_basic_object_id, StatusModule);
end;


procedure delete_pc_object(
  ObjectName IN pcs.pc_object.obj_name%TYPE,
  StatusModule IN OUT NOCOPY STATUS_MODULE_T)
is
  ln_object_id pcs.pc_object.pc_object_id%TYPE;
begin
  StatusModule.is_com_object_deleted := FALSE;
  StatusModule.is_basic_object_deleted := FALSE;
  StatusModule.is_object_deleted := FALSE;

  -- Recherche de l'identifiant de l'objet de gestion
  -- Les objets individualisés ne doivent PAS être supprimés
  begin
    SELECT pc_object_id INTO ln_object_id
    FROM pcs.pc_object
    WHERE obj_name = ObjectName
      and obj_cdcust = 0;

    exception
      when NO_DATA_FOUND then
        -- si non existant, pas d'erreur de suppression
        StatusModule.is_object_deleted := TRUE;
        return;
  end;

  p_delete_pc_object(SOURCE_OBJECT, ln_object_id, StatusModule);
end;

END COM_OBJECT_FUNCTIONS;
