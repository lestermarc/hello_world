--------------------------------------------------------
--  DDL for Package Body HRM_TASK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_TASK" 
AS

procedure employee_leaving(action_date date := to_date(sysdate),
    action_re number, action_cc number)
is
  cursor action_links(id number) is
    select hrm_action_link_id, hrm_object_id, act_automatic
    from hrm_action_link where hrm_action_type_id = id;
  action_link action_links%RowType;
  action_type number;
  action_descr hrm_action_type.act_descr%type := 'Départ d''un employé';
  action_subject hrm_actioncost.act_subject%type;
--  action_subject hrm_actioncost.act_subject%type := 'Départ de l''employé:';
  action_note hrm_actioncost.act_note%type;
--  action_note hrm_actioncost.act_note%type := 'Démarches à entreprendre: Faire signer une décharge par le secétariat, Vérifier le matériel.';
  action_reName  hrm_person.per_fullname%type;
  action_Id number;
  action_User number;
begin
  -- defines hrm_actioncost id
  select init_id_seq.nextval into action_Id from dual;
  -- defines action_type suing description
  select hrm_action_type_id, act_default_subject, act_default_note
         into action_type, action_subject, action_note
  from hrm_action_type a
  where act_descr = action_descr;
  -- search employee full name
  select per_fullname into action_reName
  from hrm_person
  where hrm_person_id = action_re;
  -- Dbms_Output.Put_Line ( 'action_reName: '|| action_reName );
  -- insert action
  insert into hrm_actioncost
   (hrm_actioncost_id,
    hrm_action_type_id,
    act_subject,
    act_note,
    act_close,
    act_scheduled_date,
    act_later_date,
    a_datecre,
    a_idcre )
  values
   (action_Id,
    action_type,
    action_subject||action_reName,
    action_note,
    0,
    to_date(sysdate),
    action_date,
    to_date(sysdate),
    'AUTO');
  open action_links(action_type);
  loop
    FETCH action_links INTO action_link;
    EXIT WHEN action_links%NOTFOUND;
      if action_link.act_automatic = 1 then
        action_User := action_re;
      else
        action_User := action_cc;
      end if;
      insert into hrm_associated_obj
       (hrm_associated_obj_id,
        hrm_actioncost_id,
        hrm_object_id,
        ass_object_link_id,
        hrm_action_link_id,
        a_datecre,
        a_idcre)
      values
       (init_id_seq.nextval,
        action_id,
        action_link.hrm_object_id,
        action_user,
        action_link.hrm_action_link_id,
        to_date(sysdate),
        'AUTO');
  end loop;
 end;

end hrm_task;
