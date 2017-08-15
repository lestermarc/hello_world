--------------------------------------------------------
--  DDL for Procedure RPT_GAL_AVANCE_MATERIAL_FOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GAL_AVANCE_MATERIAL_FOR" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report GAL_PROJECT_AVANCEMENT_MAT.
 * Replace the procedure GAL_AVANCE_MATERIAL_FOR_RPT
 * @lastUpdate VHA 17 September 2013
 * @public
* @param parameter_0  GAL_TASK_ID
*/
  s_sql_gal_project varchar2(32762);
  a_aff_id          gal_project.gal_project_id%type;
  a_session_id      gal_project.gal_project_id%type   default 1;
  vpc_lang_id       PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id       PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id       PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id      PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if (parameter_0 is not null) then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
      vpc_lang_id   := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id   := PCS.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id   := PCS.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id  := PCS.PC_I_LIB_SESSION.getConliId;
   end if;

  if parameter_0 is not null then
    select gal_task.gal_project_id
      into a_aff_id
      from gal_task
     where gal_task.gal_task_id = parameter_0;
  end if;

    gal_project_calculation.suivi_materiel(a_aff_id, parameter_0, a_session_id, 'N');
    -- GENERATION DU CURSEUR POUR CRYSTAL --
    s_sql_gal_project  :=
      'select
                       GAL_TASK.GAL_TASK_ID
                     ,GAL_TASK.TAS_CODE
                     ,GAL_TASK.TAS_WORDING
                     ,GAL_PROJECT.PRJ_CODE
                     ,GAL_PROJECT.PRJ_WORDING
                     ,GAL_TASK.TAS_VERSION
                     ,GAL_NEED_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID
                     ,GAL_NEED_FOLLOW_UP.NFU_NOMENCLATURE_LEVEL
                     ,GAL_NEED_FOLLOW_UP.NFU_PLAN_MARK
                     ,GAL_NEED_FOLLOW_UP.NFU_MAJOR_REFERENCE
                     ,GAL_NEED_FOLLOW_UP.NFU_SHORT_DESCRIPTION
                     ,GAL_NEED_FOLLOW_UP.NFU_PLAN_NUMBER
                     ,GAL_NEED_FOLLOW_UP.NFU_SUPPLY_TYPE AS TYPEAPPRO
                     ,GAL_NEED_FOLLOW_UP.NFU_NET_QUANTITY_NEED
                     ,GAL_NEED_FOLLOW_UP.NFU_UNIT_OF_MEASURE
                     ,GAL_NEED_FOLLOW_UP.NFU_NEED_DATE
                     ,GAL_NEED_FOLLOW_UP.NFU_INFO_SUPPLY
                     ,GAL_NEED_FOLLOW_UP.NFU_AVAILABLE_QUANTITY
                     ,GAL_NEED_FOLLOW_UP.NFU_SUPPLY_QUANTITY
                     ,GAL_NEED_FOLLOW_UP.NFU_TO_LAUNCH_QUANTITY
                     ,GAL_NEED_FOLLOW_UP.NFU_INFO_COLOR_SUPPLY
                     ,GAL_RESOURCE_FOLLOW_UP.GAL_RESOURCE_FOLLOW_UP_ID
                     ,(case when
                      GAL_RESOURCE_FOLLOW_UP.RFU_TYPE = ' ||
      chr(39) ||
      '6DF' ||
      chr(39) ||
      ' then (select sss.TAS_CODE from GAL_TASK sss WHERE sss.GAL_TASK_ID = GAL_RESOURCE_FOLLOW_UP.GAL_MANUFACTURE_TASK_ID) else GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_NUMBER end) RFU_SUPPLY_NUMBER
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_COMMENT RFU_SUPPLIER
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_STATE
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_ENVISAGED_DATE
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_AVAILABLE_QUANTITY
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_QUANTITY
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_AVAILABLE_DATE
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_TYPE
                     ,GAL_RESOURCE_FOLLOW_UP.RFU_TYPE_NEED_OR_SUPPLY
                     from
                      GAL_TASK
                     ,GAL_TASK_CATEGORY
                     ,GAL_PROJECT
                     ,GAL_NEED_FOLLOW_UP
                     ,GAL_RESOURCE_FOLLOW_UP
                     where
                       GAL_TASK_CATEGORY.C_TCA_TASK_TYPE=1
                        and nvl(GAL_RESOURCE_FOLLOW_UP.RFU_TYPE_NEED_OR_SUPPLY,''X'')|| nvl(GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_MODE,''X'')||nvl(GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_TYPE,''X'') <> ' ||
      chr(39) ||
      'NAA' ||
      chr(39) ||
      '  and nvl(GAL_RESOURCE_FOLLOW_UP.RFU_TYPE_NEED_OR_SUPPLY,''X'')|| nvl(GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_MODE,''X'')||nvl(GAL_RESOURCE_FOLLOW_UP.RFU_SUPPLY_TYPE,''X'') <> ' ||
      chr(39) ||
      'NFA' ||
      chr(39) ||
      '  and GAL_TASK.GAL_TASK_CATEGORY_ID      = GAL_TASK_CATEGORY.GAL_TASK_CATEGORY_ID
                     and GAL_TASK.GAL_PROJECT_ID               = GAL_PROJECT.GAL_PROJECT_ID
                     and GAL_TASK.GAL_TASK_ID = GAL_NEED_FOLLOW_UP.GAL_TASK_ID
                     and GAL_NEED_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID =
                          GAL_RESOURCE_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID(+)
                     and GAL_NEED_FOLLOW_UP.NFU_NOMENCLATURE_LEVEL <> 0
                     order by
                          GAL_PROJECT.PRJ_CODE
                        ,GAL_TASK.TAS_CODE
                        ,GAL_NEED_FOLLOW_UP.GAL_NEED_FOLLOW_UP_ID
                        ,GAL_RESOURCE_FOLLOW_UP.GAL_RESOURCE_FOLLOW_UP_ID';
    commit;

    open arefcursor for s_sql_gal_project;

end RPT_GAL_AVANCE_MATERIAL_FOR;
