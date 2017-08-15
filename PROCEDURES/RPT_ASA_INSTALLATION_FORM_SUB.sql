--------------------------------------------------------
--  DDL for Procedure RPT_ASA_INSTALLATION_FORM_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_INSTALLATION_FORM_SUB" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, ANYTHING       in varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
/* description used for report ASA_INSTALLATION_FORM

* @AUTHOR SMA
* @LASTUPDATE Oktober 2013
* @PUBLIC
* @param PROCPARAM_0: Numero d'insallation DOC_RECORD_ID
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select RCL.DOC_RECORD_LINK_ID
         , rco_father.rco_title rco_father
         , dcl.rlt_upward_semantic
         , rco_son.rco_title rco_son
         , (select goo_major_reference
              from gco_good goo
             where goo.gco_good_id = rco_son.rco_machine_good_id) goo_major_reference
         , rco_son.rco_machine_long_descr
         , rco_son.rco_machine_free_descr
         , rcl_comment
         , rco_father.rco_title
      from doc_record rco_father
         , doc_record_link rcl
         , doc_record rco_son
         , doc_record_category_link rlt
         , doc_record_cat_link_type dcl
     where rco_father.doc_record_id = rcl.doc_record_father_id
       and rcl.doc_record_son_id = rco_son.doc_record_id
       and rcl.doc_record_category_link_id = rlt.doc_record_category_link_id
       and rlt.doc_record_cat_link_type_id = dcl.doc_record_cat_link_type_id
       and rco_father.rco_title = ANYTHING;
end RPT_ASA_INSTALLATION_FORM_SUB;
