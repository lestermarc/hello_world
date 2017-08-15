--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOCUMENT_EXAMPLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOCUMENT_EXAMPLE" (
   arefcursor       in out   crystal_cursor_types.dualcursortyp,
   parameter_4   in         varchar2,
   user_lanid      in          varchar2
)
is
/**
*Description - used for report ACT_DOCUMENT_EXAMPLE
* @author MZHU
* @Published VHA 20 sept 2011
* @lastupdate VHA 26 october 2012
* @public
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;
begin
  pcs.PC_I_LIB_SESSION.setlanid(user_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select doc.act_document_id
         , doc.doc_number
         , doc.doc_total_amount_dc
         , doc.doc_document_date
         , doc.acs_financial_year_id
         , doc.doc_comment
         , doc.dic_doc_source_id
         , doc.dic_doc_destination_id
         , doc.a_datecre
         , doc.a_datemod
         , doc.a_idcre
         , doc.a_idmod
         , nvl(tra.tra_text, cat.cat_description) cat_description
         , cur.currency
      from act_document doc
         , acj_catalogue_document cat
         , acs_financial_currency acs
         , pcs.pc_curr cur
         , (select acj_catalogue_document_id
                 , tra_text
              from acj_traduction
             where pc_lang_id = vpc_lang_id) tra
     where doc.acj_catalogue_document_id = cat.acj_catalogue_document_id
       and doc.acs_financial_currency_id = acs.acs_financial_currency_id
       and acs.pc_curr_id = cur.pc_curr_id
       and doc.acj_catalogue_document_id = tra.acj_catalogue_document_id
       and doc.act_document_id = to_number(parameter_4);
end rpt_act_document_example;
