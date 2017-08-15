--------------------------------------------------------
--  DDL for Package Body COM_VDOC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_VDOC" 
IS
   /* Constante correspondant au user vdoc dans l'ERP */
   c_vdoc_user   CONSTANT pcs.pc_user.use_name%TYPE   := 'VDOC';

   /****************************************************************
   **  Fonction retournant l'url du serveur vdoc
   **
   *****************************************************************/
   FUNCTION vdoc_url (p_controller IN VARCHAR2)
      RETURN VARCHAR2
   IS
      srvreference   VARCHAR2 (64);
   BEGIN
      SELECT pcs.pc_public.getconfig ('WEB_VDOC_SERVER')
        INTO srvreference
        FROM DUAL;

      RETURN srvreference || '/vdoc/navigation/sdk?Controller='
             || p_controller;
   END vdoc_url;

   /****************************************************************
   **  Fonction de communication avec vdoc
   **
   *****************************************************************/
   FUNCTION vdoc_communicate (p_data IN VARCHAR2, p_controller IN VARCHAR2)
      RETURN XMLTYPE
   IS
      DATA        VARCHAR2 (32767) := '...';
      data_clob   CLOB;
      req         UTL_HTTP.req;
      resp        UTL_HTTP.resp;
   BEGIN
      DATA := p_data;
      req := UTL_HTTP.begin_request (vdoc_url (p_controller), 'POST');
      UTL_HTTP.set_header (req, 'Content-Length', LENGTH (DATA));
      UTL_HTTP.write_text (req, DATA);
      resp := UTL_HTTP.get_response (req);

      BEGIN
         LOOP
            UTL_HTTP.read_text (resp, DATA);
            data_clob := data_clob || DATA;
         END LOOP;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body
         THEN
            NULL;
      END;

      UTL_HTTP.end_response (resp);
      RETURN XMLTYPE (data_clob);
   --exception when others then dbms_output.put_line(data);
   END vdoc_communicate;

   /****************************************************************
   **  Liste des tâches en suspens dans vdoc pour l'utilisateur
   **
   ****************************************************************/
   FUNCTION vdoc_todo_list (username IN VARCHAR2)
      RETURN XMLTYPE
   AS
      DATA   VARCHAR2 (32767) := '...';
   BEGIN
      DATA :=
            '<view xmlns:vw1="http://www.axemble.com/process/view">
                 <header name="ASSIGNED_TASKS" login="'
         || username
         || '">
                 <column name="sys_Reference"/>
                 <column name="sys_Title"/>
                 <column name="sys_Creator"/>
                 <column name="sys_CreationDate"/>
                 <column name="sys_CurrentSteps"/>
                 <column name="DocumentState"/>
                 </header> </view>';
      RETURN vdoc_communicate (DATA, 'xml');
   END vdoc_todo_list;

   /****************************************************************
   **  Exporte les données d'un document
   **
   ****************************************************************/
   FUNCTION vdoc_view_document (p_reference IN VARCHAR2, p_module IN VARCHAR2)
      RETURN XMLTYPE
   IS
      DATA   VARCHAR2 (32767) := '...';
   BEGIN
      DATA :=
            '<?xml version="1.0" encoding="windows-1252"?>
            <export xmlns:d1="http://www.axemble.com/process/document">
              <resource class="com.axemble.vdoc.sdk.interfaces.IWorkflowInstance">
              <header reference="'
         || p_reference
         || '">
              <resource-definition name="'
         || p_module
         || '" />
              </header> </resource> </export>';
      RETURN vdoc_communicate (DATA, 'export');
   END vdoc_view_document;

   /****************************************************************
   **  Crée un document dans vdoc
   **
   ****************************************************************/
   FUNCTION vdoc_create_document (p_document IN VARCHAR2)
      RETURN XMLTYPE
   IS
   BEGIN
      RETURN vdoc_communicate (p_document, 'import');
   END vdoc_create_document;

   /****************************************************************
   **  Liste des tâches à prendre en charge dans vdoc
   **
   ****************************************************************
   function wfl_activities_to_start return tt_documents_to_start pipelined
   is
   begin
       for refcursor in (
       select pri_tabname, pri_rec_id, pro_name, act_name, nvl(att_initial_value, ' ') att_initial_value,
              (select pc_user_id from pcs.pc_wfl_participants pp where p.PC_WFL_PARTICIPANTS_ID=pp.PC_WFL_PARTICIPANTS_ID ) PC_USERS_ID
       from wfl_process_instances p, wfl_activity_instances ai , wfl_processes pr, wfl_activities a,
            (select att_initial_value, wfl_processes_id from wfl_attributes att
             where att.att_name = 'VDOC_PROCESS' ) att
       where ai.wfl_process_instances_id = p.wfl_process_instances_id
       and p.wfl_processes_id = pr.wfl_processes_id
       and p.wfl_processes_id = att.wfl_processes_id (+)
       and ai.wfl_activities_id = a.wfl_activities_id
       and c_wfl_process_state = 'RUNNING'
       and c_wfl_activity_state = 'NOTRUNNING'
       and exists(select 1 from wfl_performers ai, pcs.pc_wfl_participants p
                 where ai.pc_wfl_participants_id= p.pc_wfl_participants_id
                 and ai.wfl_activity_instances_id = ai.wfl_activity_instances_id
                 and wpa_name = c_vdoc_user)
       ) loop
         pipe row (refcursor);
       end loop;
   end wfl_activities_to_start;
   */
   FUNCTION wfl_activities_to_start
      RETURN tt_documents_to_start PIPELINED
   IS
   BEGIN
      FOR refcursor IN
         (SELECT pri_tabname, pri_rec_id, pro_name, pro_tabname, act_name,
                 NVL (att_initial_value, ' ') att_initial_value,
                 (SELECT pc_user_id
                    FROM pcs.pc_wfl_participants pp
                   WHERE p.pc_wfl_participants_id =
                                        pp.pc_wfl_participants_id)
                                                                 pc_users_id
            FROM wfl_process_instances p,
                 wfl_activity_instances ai,
                 wfl_processes pr,
                 wfl_activities a,
                 (SELECT att_initial_value, wfl_processes_id
                    FROM wfl_attributes att
                   WHERE att.att_name = 'PARAM_VDOC_PROCESS') att
           WHERE ai.wfl_process_instances_id = p.wfl_process_instances_id
             AND p.wfl_processes_id = pr.wfl_processes_id
             AND p.wfl_processes_id = att.wfl_processes_id(+)
             AND ai.wfl_activities_id = a.wfl_activities_id
             --and c_wfl_process_state = 'RUNNING'
             AND c_wfl_activity_state = 'NOTRUNNING'
             AND EXISTS (
                    SELECT 1
                      FROM wfl_performers ap, pcs.pc_wfl_participants p
                     WHERE ap.pc_wfl_participants_id =
                                                      p.pc_wfl_participants_id
                       AND ai.wfl_activity_instances_id =
                                                  ap.wfl_activity_instances_id
                       AND wpa_name = c_vdoc_user))
      LOOP
         PIPE ROW (refcursor);
      END LOOP;
   END wfl_activities_to_start;

   /****************************************************************
   **  Retourne un rowtype de l'instance du process
   **
   ****************************************************************/
   FUNCTION wfl_process_instance (
      p_tabname   IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id    IN   wfl_process_instances.pri_rec_id%TYPE
   )
      RETURN wfl_process_instances%ROWTYPE
   IS
      RESULT   wfl_process_instances%ROWTYPE;
   BEGIN
      SELECT *
        INTO RESULT
        FROM wfl_process_instances w
       WHERE pri_tabname = p_tabname AND pri_rec_id = p_rec_id;

      RETURN RESULT;
   END wfl_process_instance;

   /****************************************************************
   **  Retourne l'instance de l'activité affectée à VDOC pour le record indiqué
   **
   ****************************************************************/
   FUNCTION wfl_not_running_activity (
      p_tabname   IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id    IN   wfl_process_instances.pri_rec_id%TYPE
   )
      RETURN wfl_activity_instances.wfl_activity_instances_id%TYPE
   IS
      l_activity   wfl_activity_instances.wfl_activity_instances_id%TYPE;
      l_proc_ins   wfl_process_instances.wfl_process_instances_id%TYPE;
   BEGIN
      l_proc_ins :=
          wfl_process_instance (p_tabname, p_rec_id).wfl_process_instances_id;

      SELECT wfl_activity_instances_id
        INTO l_activity
        FROM wfl_activity_instances w
       WHERE wfl_process_instances_id = l_proc_ins
         AND c_wfl_activity_state = 'NOTRUNNING'
         AND EXISTS (
                SELECT 1
                  FROM wfl_performers ai, pcs.pc_wfl_participants p
                 WHERE ai.pc_wfl_participants_id = p.pc_wfl_participants_id
                   AND ai.wfl_activity_instances_id =
                                                   w.wfl_activity_instances_id
                   AND wpa_name = c_vdoc_user);

      RETURN l_activity;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END wfl_not_running_activity;

   /****************************************************************
   **  Retourne l'instance de l'activité affectée à VDOC pour le record indiqué
   **
   ****************************************************************/
   FUNCTION wfl_running_activity (
      p_tabname   IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id    IN   wfl_process_instances.pri_rec_id%TYPE
   )
      RETURN wfl_activity_instances.wfl_activity_instances_id%TYPE
   IS
      l_activity   wfl_activity_instances.wfl_activity_instances_id%TYPE;
      l_proc_ins   wfl_process_instances.wfl_process_instances_id%TYPE;
   BEGIN
      l_proc_ins :=
          wfl_process_instance (p_tabname, p_rec_id).wfl_process_instances_id;

      SELECT wfl_activity_instances_id
        INTO l_activity
        FROM wfl_activity_instances w
       WHERE wfl_process_instances_id = l_proc_ins
         AND c_wfl_activity_state = 'RUNNING'
         AND EXISTS (
                SELECT 1
                  FROM wfl_performers ai, pcs.pc_wfl_participants p
                 WHERE ai.pc_wfl_participants_id = p.pc_wfl_participants_id
                   AND ai.wfl_activity_instances_id =
                                                   w.wfl_activity_instances_id
                   AND wpa_name = c_vdoc_user);

      RETURN l_activity;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
   END wfl_running_activity;

   /****************************************************************
   **  Prend en charge l'activité dans VDOC
   **
   ****************************************************************/
   PROCEDURE wfl_start_activity (
      p_tabname   IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id    IN   wfl_process_instances.pri_rec_id%TYPE
   )
   IS
      l_lock   NUMBER;
      userid   pcs.pc_user.pc_user_id%TYPE;
   BEGIN
      /*
      select
        pc_user_id into userid
      from
        pcs.pc_wfl_participants pp, wfl_process_instances w
      where
        pp.pc_wfl_participants_id=w.pc_wfl_participants_id and pri_tabname = p_tabname and pri_rec_id = p_rec_id;
      */
      userid := get_pc_user_vdoc_id;
      pcs.PC_I_LIB_SESSION.setuserid (userid);
      --fal_put_debug('com_vdoc start '||p_tabname||' '||p_rec_id||' userid='||userid);
      wfl_workflow_utils.startactivity (wfl_not_running_activity (p_tabname,
                                                                  p_rec_id
                                                                 ),
                                        userid,
                                        l_lock
                                       );
      COMMIT;
   END wfl_start_activity;

   /****************************************************************
    **  Affecte une valeur à un attribut de l'instance du processus
    **
    ****************************************************************/
   PROCEDURE wfl_attribute_by_name (
      p_tabname           IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id            IN   wfl_process_instances.pri_rec_id%TYPE,
      p_attribute         IN   wfl_attributes.att_name%TYPE,
      p_attribute_value   IN   wfl_attribute_instances.ati_value%TYPE
   )
   IS
      l_attributes    wfl_attributes.wfl_attributes_id%TYPE;
      l_proc_ins_id   wfl_process_instances.wfl_process_instances_id%TYPE;
      l_process       wfl_process_instances.wfl_processes_id%TYPE;
   BEGIN
      l_proc_ins_id :=
          wfl_process_instance (p_tabname, p_rec_id).wfl_process_instances_id;
      l_process :=
                  wfl_process_instance (p_tabname, p_rec_id).wfl_processes_id;

      SELECT wfl_attributes_id
        INTO l_attributes
        FROM wfl_attributes
       WHERE wfl_processes_id = l_process AND att_name = p_attribute;

      wfl_runtime_utils.setprocessattributevalue (l_attributes,
                                                  l_proc_ins_id,
                                                  p_attribute_value
                                                 );
   END wfl_attribute_by_name;

   /****************************************************************
   **  Termine l'activité dans VDOC
   **
   ****************************************************************/
   PROCEDURE wfl_complete_activity (
      p_tabname   IN   wfl_process_instances.pri_tabname%TYPE,
      p_rec_id    IN   wfl_process_instances.pri_rec_id%TYPE
   )
   IS
      l_lock   NUMBER;
   BEGIN
      IF pcs.PC_I_LIB_SESSION.getuserid IS NULL
      THEN
         pcs.PC_I_LIB_SESSION.setuser (c_vdoc_user);
      END IF;

      wfl_workflow_utils.completeactivity (wfl_running_activity (p_tabname,
                                                                 p_rec_id
                                                                ),
                                           pcs.PC_I_LIB_SESSION.getuserid,
                                           l_lock
                                          );
      COMMIT;
   END;

   /**
    * select com_vdoc.GET_PROCESS_ID('Présaisie') from dual
    */
   FUNCTION get_process_id (p_process_name wfl_processes.pro_name%TYPE)
      RETURN wfl_processes.wfl_processes_id%TYPE
   IS
      l_proc_id   wfl_processes.wfl_processes_id%TYPE;
   BEGIN
      SELECT wfl_processes_id
        INTO l_proc_id
        FROM (SELECT   wfl_processes_id
                  FROM wfl_processes p
                 WHERE pro_name = p_process_name
              ORDER BY DECODE (c_wfl_proc_status,
                               'ACTIVATED', 1,
                               'IN_PREPARE', 2,
                               3
                              ),
                       wfl_processes_id DESC)
       WHERE ROWNUM = 1;

      RETURN l_proc_id;
   END;

   /****************************************************************
   **  récupère une valeur initiale d'un attribut de processus
   **
   *
   ****************************************************************/
   FUNCTION wfl_initval_att_by_name_va (
      process_name     wfl_processes.pro_name%TYPE,
      attribute_name   wfl_attributes.att_name%TYPE
   )
      RETURN VARCHAR2
   IS
      l_value   wfl_attributes.att_initial_value%TYPE;
   BEGIN
      SELECT att_initial_value
        INTO l_value
        FROM wfl_attributes AT
       WHERE att_name = attribute_name
         AND AT.wfl_processes_id = get_process_id (process_name);

      RETURN l_value;
   END wfl_initval_att_by_name_va;

   /**
    * retouirne l'id du participant (workflow) du user vDoc
    */
   FUNCTION get_wfl_participant_vdoc_id
      RETURN pcs.pc_wfl_participants.pc_wfl_participants_id%TYPE
   IS
      l_vdoc_participant_id   pcs.pc_wfl_participants.pc_wfl_participants_id%TYPE;
   BEGIN
      SELECT pc_wfl_participants_id
        INTO l_vdoc_participant_id
        FROM pcs.pc_wfl_participants
       WHERE wpa_name = c_vdoc_user;

      RETURN l_vdoc_participant_id;
   END get_wfl_participant_vdoc_id;

   /**
    * retouirne l'id du user (pcs) du user vDoc
    */
   FUNCTION get_pc_user_vdoc_id
      RETURN pcs.pc_user.pc_user_id%TYPE
   IS
      l_pc_user_id   pcs.pc_user.pc_user_id%TYPE;
   BEGIN
      SELECT pc_user_id
        INTO l_pc_user_id
        FROM pcs.pc_user
       WHERE use_name = c_vdoc_user;

      RETURN l_pc_user_id;
   END get_pc_user_vdoc_id;

   /**
    *retourne le username vDoc (donc econcept) en fonction du PC_USER_ID
    */
   FUNCTION get_vdoc_username (p_user_id pcs.pc_user.pc_user_id%TYPE)
      RETURN VARCHAR2
   IS
      vdoc_username   VARCHAR2 (256);
   BEGIN
      --FIX ME : use : econcept.eco_users_mgm.getFirstLink(,1,'PC_USER_ID');
      SELECT LOWER (use_name)
        INTO vdoc_username
        FROM pcs.pc_user
       WHERE pc_user_id = p_user_id;

      RETURN vdoc_username;
   END;

   /**
    *  retourne la liste des vdocusername pour un groupe pcs si l'id passé est un groupe,
    *  sinon on retourne le username de l'id transmis
    *
    * select use_name, com_vdoc.GET_USERNAMES_FROM_GROUP(pc_user_id) from pcs.pc_user where use_group=1
    */
   FUNCTION get_usernames_from_group (p_group_id pcs.pc_user.pc_user_id%TYPE)
      RETURN VARCHAR2
   IS
      returnlist   VARCHAR2 (4000);
      isgroup      NUMBER (1);

      CURSOR listuser (pcgroupid pcs.pc_user.pc_user_id%TYPE)
      IS
         SELECT com_vdoc.get_vdoc_username (pc_user_id) use_name
           FROM pcs.pc_user_group
          WHERE use_group_id = pcgroupid;
   BEGIN
      SELECT use_group
        INTO isgroup
        FROM pcs.pc_user
       WHERE pc_user_id = p_group_id;

      IF (isgroup = 1)
      THEN
         FOR tpllistuser IN listuser (p_group_id)
         LOOP
            returnlist := returnlist || tpllistuser.use_name || ',';
         END LOOP;
      ELSE
         returnlist := com_vdoc.get_vdoc_username (p_group_id);
      END IF;

      RETURN returnlist;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END;
END;
