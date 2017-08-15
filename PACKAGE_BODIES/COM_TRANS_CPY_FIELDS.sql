--------------------------------------------------------
--  DDL for Package Body COM_TRANS_CPY_FIELDS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_TRANS_CPY_FIELDS" 
is
  procedure reenableTriggers
  is
    cursor cr_userTriggers
    is
      select   trigger_name
          from user_triggers
         where status = 'DISABLED'
      order by trigger_name;

    v_sqlStmnt varchar2(4000);
  begin
    for tpl_userTriggers in cr_userTriggers loop
      v_sqlStmnt  := 'Alter trigger ' || tpl_userTriggers.trigger_name || ' enable';

      execute immediate v_sqlStmnt;
    end loop;
  end;

  procedure insert_error_msg(p_sqlStmnt varchar2, p_sqlerrm varchar2)
  is
    pragma autonomous_transaction;
  begin
    insert into com_trans_errors
                (err_sql_statement
               , err_error_message
                )
         values (p_sqlStmnt
               , p_sqlerrm
                );

    commit;
  end;

  procedure transform_cpy(p_lanId pcs.pc_lang.lanid%type, p_reenableTriggers number default 0)
  is
    cursor cr_pacPerson
    is
      select per.pac_person_id
           , per.per_name
           , per.per_forename
        from pac_person per;

    cursor cr_userTriggers
    is
      select   trigger_name
          from user_triggers
         where status = 'ENABLED'
      order by trigger_name;

    cursor cr_comTransFields
    is
      select   *
          from com_trans_fields
      order by ctf_tablename
             , ctf_searchfield
             , ctf_searchvalue;

    cursor cr_comTransFieldsSpec
    is
      select   *
          from com_trans_fields_spec
      order by ctf_tablename
             , ctf_searchfield
             , ctf_searchvalue;

    cursor cr_comTransDicInsert(c_lanId pcs.pc_lang.lanid%type)
    is
      select distinct d1.dit_table
                    , d1.dit_code
                    , d1.ctd_column_name_4_id
                    , d1.ctd_column_name_4_descr
                    , (select d2.dit_descr
                         from com_trans_dic d2
                        where d2.dit_table = d1.dit_table
                          and d2.dit_code = d1.dit_code
                          and d2.c_ctd_mode = 'INSERT'
                          and d2.lanid = c_lanid
                          and d2.ctd_cpy_lanid = c_lanid) dit_descr
                 from com_trans_dic d1
                where c_ctd_mode = 'INSERT'
                  and ctd_cpy_lanid = c_lanId
             order by dit_table
                    , dit_code;

    cursor cr_comTransDicDelete(c_lanId pcs.pc_lang.lanid%type)
    is
      select distinct d1.dit_table
                    , d1.dit_code
                    , d1.ctd_column_name_4_id
                    , d1.ctd_column_name_4_descr
                    , (select d2.dit_descr
                         from com_trans_dic d2
                        where d2.dit_table = d1.dit_table
                          and d2.dit_code = d1.dit_code
                          and d2.c_ctd_mode = 'DELETE'
                          and d2.lanid = c_lanid
                          and d2.ctd_cpy_lanid = c_lanid) dit_descr
                 from com_trans_dic d1
                where c_ctd_mode = 'DELETE'
                  and ctd_cpy_lanid = c_lanId
             order by dit_table
                    , dit_code;

    v_sqlStmnt          varchar2(4000);
    v_ctfReplacingValue com_trans_fields.ctf_replacingValue_ge%type;
  begin
    if user = 'MAS_F' then
      raise_application_error(-20000, 'Il est impossible d''exécuter cette procédure sur MAS_F !!!');
      goto abort_proc;
    end if;

    for tpl_userTriggers in cr_userTriggers loop
      v_sqlStmnt  := 'Alter trigger ' || tpl_userTriggers.trigger_name || ' disable';

      execute immediate v_sqlStmnt;
    end loop;

    delete from com_trans_errors;

    commit;

    if cr_comTransFields%isopen then
      close cr_comTransFields;
    end if;

    for tpl_comTransDicInsert in cr_comTransDicInsert(p_lanId) loop
      begin
        -- insertion dans le dico
        v_sqlStmnt  :=
          'Insert into ' ||
          tpl_comTransDicInsert.dit_table ||
          ' ' ||
          '       (' ||
          tpl_comTransDicInsert.ctd_column_name_4_id ||
          ',' ||
          tpl_comTransDicInsert.ctd_column_name_4_descr ||
          ',' ||
          'a_datecre, a_idcre) ' ||
          'values (' ||
          '''' ||
          tpl_comTransDicInsert.dit_code ||
          '''' ||
          ',' ||
          '''' ||
          replace(tpl_comTransDicInsert.dit_descr, '''', '''''') ||
          '''' ||
          ',' ||
          'sysdate, ''PCS'')';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;

      begin
        -- insertion dans dico_description
        v_sqlStmnt  :=
          'Insert into dico_description ' ||
          '       (dit_table, dit_code, pc_lang_id, dit_descr, a_datecre, a_idcre) ' ||
          'select dit_table, dit_code, lan.pc_lang_id, dit_descr, sysdate, ''PCS''' ||
          '  from pcs.pc_lang lan ' ||
          '      ,com_trans_dic dic ' ||
          ' where dic.lanid = lan.lanid ' ||
          '   and dic.ctd_cpy_lanid = ' ||
          '''' ||
          p_lanid ||
          '''' ||
          '   and dic.dit_table = ' ||
          '''' ||
          tpl_comTransDicInsert.dit_table ||
          '''' ||
          '   and dic.dit_code = ' ||
          '''' ||
          tpl_comTransDicInsert.dit_code ||
          '''';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;
    end loop;

    for tpl_comTransFields in cr_comTransFields loop
      begin
        if upper(p_lanId) = 'GE' then
          v_ctfReplacingValue  := tpl_comTransFields.ctf_replacingValue_ge;
        elsif upper(p_lanId) = 'EN' then
          v_ctfReplacingValue  := tpl_comTransFields.ctf_replacingValue_en;
        else
          goto abort_proc;
        end if;

        v_sqlStmnt  :=
          'Update ' ||
          tpl_comTransFields.ctf_tableName ||
          ' ' ||
          '   set ' ||
          tpl_comTransFields.ctf_replacedField ||
          ' = ' ||
          '''' ||
          replace(v_ctfReplacingValue, '''', '''''') ||
          '''' ||
          ' ' ||
          ' where ' ||
          tpl_comTransFields.ctf_searchField ||
          ' = ' ||
          '''' ||
          replace(tpl_comTransFields.ctf_searchValue, '''', '''''') ||
          '''';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;
    end loop;

    for tpl_comTransFieldsSpec in cr_comTransFieldsSpec loop
      begin
        if p_lanId = 'GE' then
          v_ctfReplacingValue  := tpl_comTransFieldsSpec.ctf_replacingValue_ge;
        elsif p_lanId = 'EN' then
          v_ctfReplacingValue  := tpl_comTransFieldsSpec.ctf_replacingValue_en;
        end if;

        v_sqlStmnt  :=
          'Update ' ||
          tpl_comTransFieldsSpec.ctf_tableName ||
          ' ' ||
          '   set ' ||
          tpl_comTransFieldsSpec.ctf_replacedField ||
          ' = Replace (' ||
          tpl_comTransFieldsSpec.ctf_replacedField ||
          ',' ||
          '''' ||
          replace(tpl_comTransFieldsSpec.ctf_replacedValue, '''', '''''') ||
          '''' ||
          ',' ||
          '''' ||
          replace(v_ctfReplacingValue, '''', '''''') ||
          '''' ||
          ')';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;
    end loop;

    for tpl_comTransDicDelete in cr_comTransDicDelete(p_lanId) loop
      begin
        -- supprimerdans dico_description
        v_sqlStmnt  :=
          'Delete from dico_description d  ' ||
          ' where exists ( select 1 from com_trans_dic t ' ||
          '   where d.dit_table=t.dit_table ' ||
          '	  and d.dit_code=t.dit_code ' ||
          '   and t.ctd_cpy_lanid = ' ||
          '''' ||
          p_lanid ||
          '''' ||
          '   and t.c_ctd_mode = ' ||
          '''' ||
          'DELETE' ||
          '''' ||
          ')';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;

      begin
        -- supprimer dans le dico
        v_sqlStmnt  :=
          'delete from  ' ||
          tpl_comTransDicDelete.dit_table ||
          '       where ' ||
          tpl_comTransDicDelete.CTD_COLUMN_NAME_4_ID ||
          '       = ' ||
          '	  (select ' ||
          '''' ||
          tpl_comTransDicDelete.dit_code ||
          '''' ||
          '       from com_trans_dic d' ||
          '       where d.dit_table = ' ||
          '''' ||
          tpl_comTransDicDelete.dit_table ||
          '''' ||
          '       and d.dit_code= ' ||
          '''' ||
          tpl_comTransDicDelete.dit_code ||
          '''' ||
          '       and d.c_ctd_mode= ' ||
          '''' ||
          'DELETE' ||
          '''' ||
          '       and d.ctd_cpy_lanid = ' ||
          '''' ||
          p_lanid ||
          '''' ||
          ')';

        execute immediate v_sqlStmnt;
      exception
        when others then
          insert_error_msg(v_sqlStmnt, sqlerrm);
      end;
    end loop;

    /* == travaux finaux == */

    /* == mise à jour du champ des_description_summary via la procédure standard == */
    for tpl_pacPerson in cr_pacPerson loop
      pac_partner_management.update_account_descr(tpl_pacPerson.pac_person_id
                                                , tpl_pacPerson.per_name
                                                , tpl_pacPerson.per_forename
                                                 );
    end loop;

    /* == inversion des langues des utilisateurs == */
    update hrm_person per
       set per.pc_lang_id =
             case
               when p_lanid = 'GE' then decode(per.pc_lang_id, 1, 2, 2, 1, per.pc_lang_id)
               when p_lanid = 'EN' then per.pc_lang_id
             end;

    /* == organigramme == */
    delete from hrm_orgchart;

    insert into hrm_orgchart
                (hrm_orgchart_id
               , org_descr
               , org_chart
               , a_datecre
               , a_idcre
               , a_datemod
               , a_idmod
                )
      select hrm_orgchart_id
           , org_descr
           , org_chart
           , a_datecre
           , a_idcre
           , a_datemod
           , a_idmod
        from com_trans_hrm_orgchart
       where lanid = p_lanid;

/* == profile == */
/*
    delete from com_profile;

    insert into com_profile
                (com_profile_id
               , pc_object_id
               , pc_user_id
               , pfl_name
               , pfl_description
               , pfl_xml_options
               , pfl_variant
               , pfl_default
               , pfl_default_id
               , a_datecre
               , a_datemod
               , a_idcre
               , a_idmod
               , a_reclevel
               , a_recstatus
               , a_confirm
                )
      select pro.com_profile_id
           , obj.pc_object_id
           , pro.pc_user_id
           , pro.pfl_name
           , pro.pfl_description
           , pro.pfl_xml_options
           , pro.pfl_variant
           , pro.pfl_default
           , pro.pfl_default_id
           , pro.a_datecre
           , pro.a_datemod
           , pro.a_idcre
           , pro.a_idmod
           , pro.a_reclevel
           , pro.a_recstatus
           , pro.a_confirm
        from com_trans_profile pro
           , pcs.pc_object obj
       where lanid = p_lanid
         and pro.pc_object_name = obj.obj_name;
*/
    if p_reenableTriggers = 1 then
      reenableTriggers;
    end if;

    /* == en cas de problèmes == */
    <<abort_proc>>
    null;
  end transform_cpy;
end COM_TRANS_CPY_FIELDS;
