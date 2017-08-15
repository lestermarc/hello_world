--------------------------------------------------------
--  DDL for Package Body COM_UPDATE_SCHEMA_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_UPDATE_SCHEMA_FCT" 
is

  coLf varchar2(1) := chr (10);

  type t_refCur is ref cursor;
  
  cursor cr_dummy
      is 
  select 1 id
    from dual;

  /* ===========================================================================
  ============================================================================*/
  function QuotedString (p_stringToQuote varchar2,
                         p_quoteChar varchar2)
                         return varchar2
                         is
                         
  begin
  
  return p_quoteChar || p_stringToQuote || p_quoteChar;
  
  end;                         
                         
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcApplTxtId_sql (p_tableName varchar2,
                                      p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);

    v_cTextType     pcs.pc_appltxt.c_text_type%type; 
    v_dicPcThemeId  pcs.pc_appltxt.dic_pc_theme_id%type;
    v_aphCode       pcs.pc_appltxt.aph_code%type;

    begin
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select aph.c_text_type,
                   aph.dic_pc_theme_id,
                   aph.aph_code 
              into v_cTextType, 
                   v_dicPcThemeId,  
                   v_aphCode       
              from pcs.pc_appltxt aph
             where aph.pc_appltxt_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then
                      v_cTextType := null; 
                      v_dicPcThemeId := null;
                      v_aphCode := null;      
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (Select aph.pc_appltxt_id ' || 
                       '                          from pcs.pc_appltxt aph ' || 
                       '                         where aph.c_text_type = [c_text_type] ' ||
                       '                           and aph.dic_pc_theme_id = [dic_pc_theme_id] ' ||
                       '                           and aph.aph_code = [aph_code])' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select aph.pc_appltxt_id ' || 
                       '                 from pcs.pc_appltxt aph ' || 
                       '                where aph.c_text_type = [c_text_type] ' ||
                       '                  and aph.dic_pc_theme_id = [dic_pc_theme_id] ' ||
                       '                  and aph.aph_code = [aph_code])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[c_text_type]', QuotedString (v_cTextType, ''''));
          v_sql_upd := replace (v_sql_upd, '[dic_pc_theme_id]', QuotedString (v_dicPcThemeId, ''''));
          v_sql_upd := replace (v_sql_upd, '[aph_code]', QuotedString (v_aphCode, ''''));                                         
                       
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
    
    
    end generate_pcApplTxtId_sql;
    
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcCompId_sql (p_tableName varchar2,
                                   p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_comName pcs.pc_comp.com_name%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select com.com_name
              into v_comName
              from pcs.pc_comp com
             where com.pc_comp_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_comName := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (Select com.pc_comp_id from pcs.pc_comp com where com.com_name = [comName]) ' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select com.pc_comp_id from pcs.pc_comp com where com.com_name = [comName])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[comName]', quotedString (v_comName,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;

    end generate_pcCompId_sql;

  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcSqlStId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    
    v_tabName pcs.pc_table.tabname%type;
    v_cSqgType pcs.pc_sqlst.c_sqgtype%type;
    v_sqlId    pcs.pc_sqlst.sqlid%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 

            select tab.tabname,
                   sql.c_sqgType,
                   sql.sqlid
              into v_tabName,
                   v_cSqgType,
                   v_sqlId          
              from pcs.pc_sqlst sql,
                   pcs.pc_table tab
             where tab.pc_table_id = sql.pc_table_id
               and sql.pc_sqlst_id = tpl_dummy.id;  
             
            exception 
                 when no_data_found then 
                      v_tabName := null;
                      v_cSqgType := null;
                      v_sqlId := null;          
                      
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (Select sql.pc_sqlst_id ' ||
                       '                          from pcs.pc_sqlst sql, ' ||
                       '                               pcs.pc_table tab ' ||
                       '                         where tab.pc_table_id = sql.pc_table_id ' ||
                       '                           and tab.tabname = [tabname] ' ||
                       '                           and sql.sqlid = [sqlid] ' ||
                       '                           and sql.c_sqgtype = [c_sqgtype]) ' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select sql.pc_sqlst_id ' ||
                       '                 from pcs.pc_sqlst sql, ' ||
                       '                      pcs.pc_table tab ' ||
                       '                where tab.pc_table_id = sql.pc_table_id ' ||
                       '                 and tab.tabname = [tabname] ' ||
                       '                 and sql.sqlid = [sqlid] ' ||
                       '                 and sql.c_sqgtype = [c_sqgtype]) ';

                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[tabname]', quotedString (v_tabName,''''));
          v_sql_upd := replace (v_sql_upd, '[sqlid]', quotedString (v_sqlid,''''));
          v_sql_upd := replace (v_sql_upd, '[c_sqgtype]', quotedString (v_cSqgType,''''));                                                     
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;

    end generate_pcSqlStId_sql;
    
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcYearWeekId_sql (p_tableName varchar2,
                                       p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_pywYear pcs.pc_year_week.pyw_year%type;
    v_pywWeek pcs.pc_year_week.pyw_week%type;
    
    begin
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select pyw.pyw_year,
                   pyw.pyw_week
              into v_pywYear,
                   v_pywWeek
              from pcs.pc_year_week pyw
             where pyw.pc_year_week_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_pywYear := null;
                      v_pywWeek := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] =  (Select pyw.pc_year_week_id ' || 
                       '                           from pcs.pc_year_week pyw ' || 
                       '                          where pyw.pyw_year = [pyw_year] ' ||
                       '                            and pyw.pyw_week = [pyw_week]) ' ||                       
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select pyw.pc_year_week_id ' || 
                       '                 from pcs.pc_year_week pyw ' || 
                       '                where pyw.pyw_year = [pyw_year] ' ||
                       '                  and pyw.pyw_week = [pyw_week]) ';                       


          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[pyw_year]', v_pywYear);
          v_sql_upd := replace (v_sql_upd, '[pyw_week]', v_pywWeek);                                           
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
    
    end generate_pcYearWeekId_sql;             
             
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcYearmonthId_sql (p_tableName varchar2,
                                       p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_pymYear pcs.pc_year_month.pym_year%type;
    v_pymmonth pcs.pc_year_month.pym_month%type;
    
    begin
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select pym.pym_year,
                   pym.pym_month
              into v_pymYear,
                   v_pymmonth
              from pcs.pc_year_month pym
             where pym.pc_year_month_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_pymYear := null;
                      v_pymmonth := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] =  (Select pym.pc_year_month_id ' || 
                       '                           from pcs.pc_year_month pym ' || 
                       '                          where pym.pym_year = [pym_year] ' ||
                       '                            and pym.pym_month = [pym_month]) ' ||                       
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select pym.pc_year_month_id ' || 
                       '                 from pcs.pc_year_month pym ' || 
                       '                where pym.pym_year = [pym_year] ' ||
                       '                  and pym.pym_month = [pym_month]) ';                       


          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[pym_year]', v_pymYear);
          v_sql_upd := replace (v_sql_upd, '[pym_month]', v_pymmonth);                                           
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
    
    end generate_pcYearmonthId_sql;             

  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcCntryId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_cntId pcs.pc_cntry.cntId%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select cnt.cntid
              into v_cntId
              from pcs.pc_cntry cnt
             where cnt.pc_cntry_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_cntId := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (Select cnt.pc_cntry_id from pcs.pc_cntry cnt where cnt.cntId = [cntid]) ' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select cnt.pc_cntry_id from pcs.pc_cntry cnt where cnt.cntId = [cntid])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[cntid]', quotedString (v_cntId,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcCntryId_sql;
            
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcFldscId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_fldName pcs.pc_fldsc.fldname%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select fld.fldname
              into v_fldName
              from pcs.pc_fldsc fld
             where fld.pc_fldsc_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_fldName := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (Select fld.pc_fldsc_id from pcs.pc_fldsc fld where fld.fldname = [fldname]) ' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select fld.pc_fldsc_id from pcs.pc_fldsc fld where fld.fldname = [fldname])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[fldname]', quotedString (v_fldName,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcFldscId_sql;


  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcBankId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_banKey pcs.pc_bank.ban_key%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select ban.ban_key
              into v_banKey
              from pcs.pc_bank ban
             where ban.pc_bank_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_banKey := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (select ban.pc_bank_id from pcs.pc_bank ban where ban.ban_key = [bankey])' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (select ban.pc_bank_id from pcs.pc_bank ban where ban.ban_key = [bankey])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[bankey]', quotedString (v_banKey,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcBankId_sql;

  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcImportDataId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
            
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_imdImportName pcs.pc_import_data.imd_import_name%type;
              
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select imd.imd_import_name
              into v_imdImportName
              from pcs.pc_import_data imd
             where imd.pc_import_data_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_imdImportName := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] = (select ban.pc_bank_id from pcs.pc_bank ban where ban.ban_key = [bankey])' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (select ban.pc_bank_id from pcs.pc_bank ban where ban.ban_key = [bankey])';
                       
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[imdimportname]', quotedString (v_imdImportName,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcImportDataId_sql;
  
  
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcUserId_sql (p_tableName varchar2,
                                   p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_useName pcs.pc_user.use_name%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select use.use_name
              into v_useName
              from pcs.pc_user use
             where use.pc_user_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_useName := null;
          end;
           
          v_sql_upd := 'update [table_name]' ||
                       '   set [column_name] =  (Select use.pc_user_id from pcs.pc_user use where use.use_name = [use_name]) ' ||
                       ' where [column_name] = [id] ' || 
                       '   and exists (Select use.pc_user_id from pcs.pc_user use where use.use_name = [use_name])';

          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[use_name]', quotedString (v_useName,''''));                                 
  
          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
           
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcUserId_sql;
  
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcLangId_sql (p_tableName varchar2,
                                   p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_lanId pcs.pc_lang.lanid%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select lan.lanid
              into v_lanId
              from pcs.pc_lang lan
             where lan.pc_lang_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_lanId := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select lan.pc_lang_id from pcs.pc_lang lan where lan.lanId = [lanid])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select lan.pc_lang_id from pcs.pc_lang lan where lan.lanId = [lanid])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[lanid]', quotedString (v_lanId,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcLangId_sql;
  
  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcTableId_sql (p_tableName varchar2,
                                    p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_tabName pcs.pc_table.tabname%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select tab.tabname
              into v_tabName
              from pcs.pc_table tab
             where tab.pc_table_id = tpl_dummy.id;

             
            exception 
                 when no_data_found then 
                      v_tabName := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select tab.pc_table_id from pcs.pc_table tab where tab.tabname = [tabname])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select tab.pc_table_id from pcs.pc_table tab where tab.tabname = [tabname])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[tabname]', quotedString (v_tabName,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcTableId_sql;


  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcReportId_sql (p_tableName varchar2,
                                     p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_repRepName pcs.pc_report.rep_repname%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select rep.rep_repname
              into v_repRepName
              from pcs.pc_report rep
             where rep.pc_report_id = tpl_dummy.id;

             
            exception 
                 when no_data_found then 
                      v_repRepName := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select rep.pc_report_id from pcs.pc_report rep where rep.rep_repname = [reprepname])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select rep.pc_report_id from pcs.pc_report rep where rep.rep_repname = [reprepname])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[reprepname]', quotedString (v_repRepName,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcReportId_sql;


  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcObjectId_sql (p_tableName varchar2,
                                     p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_objName pcs.pc_object.obj_name%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select obj.obj_name
              into v_objName
              from pcs.pc_object obj
             where obj.pc_object_id = tpl_dummy.id;

             
            exception 
                 when no_data_found then 
                      v_objName := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select obj.pc_object_id from pcs.pc_object obj where obj.obj_name = [objname])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select obj.pc_object_id from pcs.pc_object obj where obj.obj_name = [objname])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[objname]', quotedString (v_objName,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcObjectId_sql;

  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcBasicObjectId_sql (p_tableName varchar2,
                                     p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_objName pcs.pc_basic_object.obj_name%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select obj.obj_name
              into v_objName
              from pcs.pc_basic_object obj
             where obj.pc_basic_object_id = tpl_dummy.id;

             
            exception 
                 when no_data_found then 
                      v_objName := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select obj.pc_basic_object_id from pcs.pc_basic_object obj where obj.obj_name = [objname])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select obj.pc_basic_object_id from pcs.pc_basic_object obj where obj.obj_name = [objname])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[objname]', quotedString (v_objName,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcBasicObjectId_sql;
  

  /* ===========================================================================
  ============================================================================*/
  procedure generate_pcCurrId_sql (p_tableName varchar2,
                                   p_columnName varchar2)
            is
  
    cr_refCur t_refCur;          
    tpl_dummy cr_dummy%rowtype;
              
    v_sql varchar2(1000);
    v_sql_upd varchar2(1000);
    v_currency pcs.pc_curr.currency%type;          
              
    begin
    
    
    v_sql := 'select distinct ' || p_columnName || ' id' ||
             '  from ' || p_tableName ||
             ' where ' || p_columnName || ' is not null' ;
             
    open cr_refCur for v_sql;
    fetch cr_refCur into tpl_dummy;
    while cr_refCur%found loop
    
          begin 
  
            select pcu.currency
              into v_currency
              from pcs.pc_curr pcu
             where pcu.pc_curr_id = tpl_dummy.id;
             
            exception 
                 when no_data_found then 
                      v_currency := null;
          end;
           
          v_sql_upd := 'update [table_name] ' ||
                       '   set [column_name] =  (Select pcu.pc_curr_id from pcs.pc_curr pcu where pcu.currency = [currency])' ||
                       ' where [column_name] = [id] ' ||
                       '   and exists (Select pcu.pc_curr_id from pcs.pc_curr pcu where pcu.currency = [currency])';
  
          v_sql_upd := replace (v_sql_upd, '[table_name]', p_tableName);
          v_sql_upd := replace (v_sql_upd, '[column_name]', p_columnName);
          v_sql_upd := replace (v_sql_upd, '[id]', to_char (tpl_dummy.id, 'FM99999999999'));
          v_sql_upd := replace (v_sql_upd, '[currency]', quotedString (v_currency,''''));                                 

          insert 
            into com_trans_pc_update_sql
                (com_trans_pc_update_sql_id
                ,tpu_sql
                )
          values
                (init_id_seq.nextval
                ,v_sql_upd
                );
                          
    
          fetch cr_refCur into tpl_dummy;
    
    end loop;
    
    close cr_refCur;
             
  end generate_pcCurrId_sql;

             
  /* ===========================================================================
  ============================================================================*/
  procedure generate_all_pc_update_sql
            is
            
            
    /* == types == */
    type t_comTransPcColumnsTable is table of com_trans_pc_columns%rowtype index by varchar2(30);
  
    /* == curseurs == */
    cursor cr_comTransPcColumns
        is
    select tpc.* 
      from com_trans_pc_columns tpc;

              
    cursor cr_userTabColumns
           is
    select table_name, column_name
      from user_tab_columns
     where column_name like 'PC\_%' escape '\' 
       and table_name not like 'V%'
     order
        by column_name,
           table_name;
           
           
    /* == variables ==*/
    tab_comTransPcColumns t_comTransPcColumnsTable;
    tpl_userTabColumns    cr_userTabColumns%rowtype;
    
    v_sql varchar2(1000);
    
    begin
    
    
    /* == TODO LIST ==
    
       - insérer les colonnes PC% qui n'auraient pas encore été insérées
    */
    
    
    insert
      into com_trans_pc_columns tpc 
          (com_trans_pc_columns_id, 
           tpc_column_name, 
           a_idcre, 
           a_datecre 
          )
    select init_id_seq.nextval
          ,v.column_name
          ,'PCS'
          ,sysdate
      from (select distinct col1.column_name
              from user_tab_columns col1
             where not exists (select 1
                                 from com_trans_pc_columns col2
                                where col1.column_name = col2.tpc_column_name)
               and col1.column_name like 'PC\_%' escape '\' 
               and col1.table_name not like 'V%') v;
      
    
    delete 
      from com_trans_pc_update_sql;
    
    /* == charge l'ensemble des définitions 
          de colonnes dans une table mémoire == */ 
    for tpl_comTransPcColumns in cr_comTransPcColumns loop
        tab_comTransPcColumns (tpl_comTransPcColumns.tpc_column_name):= tpl_comTransPcColumns;                            
    end loop;
  
    if cr_comTransPcColumns%isopen then
       close cr_comTransPcColumns;
    end if;  
    
    
    open cr_userTabColumns;
    fetch cr_userTabColumns into tpl_userTabColumns;
    while cr_userTabColumns%found loop
    
          if tab_comTransPcColumns (tpl_userTabColumns.column_name).tpc_update_proc is not null then 
              
             v_sql := 'Begin ' ||
                      'com_update_schema_fct.' || tab_comTransPcColumns (tpl_userTabColumns.column_name).tpc_update_proc || 
                      '(' || '''' || tpl_userTabColumns.table_name || '''' || ',' || '''' || tpl_userTabColumns.column_name || '''' ||');' ||
                      'End;';
                      
             execute immediate v_sql;
             
          end if;                 
    
          fetch cr_userTabColumns into tpl_userTabColumns;
    
    end loop;
    close cr_userTabColumns;
    
  end generate_all_pc_update_sql;

  /* ===========================================================================
  ============================================================================*/
  procedure update_all_pc_columns
            is
            
    cursor cr_comTransPcUpdateSql
           is
    select * 
      from com_trans_pc_update_sql
     order
        by com_trans_pc_update_sql_id;
      
    tpl_comTransPcUpdateSql cr_comTransPcUpdateSql%rowtype;                
            
  begin
  
  update com_trans_pc_update_sql tpu
     set tpu.tpu_update_ok = 0;
  
  
  open cr_comTransPcUpdateSql;
  fetch cr_comTransPcUpdateSql into tpl_comTransPcUpdateSql;
  while cr_comTransPcUpdateSql%found loop
        
        begin
        
        execute immediate tpl_comTransPcUpdateSql.tpu_sql;
       
        if sql%found then
           commit;
           update com_trans_pc_update_sql tpu
              set tpu.tpu_update_ok = 1
            where tpu.com_trans_pc_update_sql_id = tpl_comTransPcUpdateSql.com_trans_pc_update_sql_id;
        end if;
  
        fetch cr_comTransPcUpdateSql into tpl_comTransPcUpdateSql;
        
        exception 
             when others then
                  -- pas optimal, mais évitera une erreur oracle, de toute façon
                  -- chaque ligne ayant tpu_update_ok = 1 indiquera que la requête
                  -- a été exécutée sans ereur
                  fetch cr_comTransPcUpdateSql into tpl_comTransPcUpdateSql; 
        end;
        
  end loop;
  close cr_comTransPcUpdateSql;
  
  
  end;                     



end com_update_schema_fct;
