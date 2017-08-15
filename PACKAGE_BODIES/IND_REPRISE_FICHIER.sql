--------------------------------------------------------
--  DDL for Package Body IND_REPRISE_FICHIER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_REPRISE_FICHIER" is


procedure get_line_plus (file_in in UTL_FILE.FILE_TYPE,
                         line_out out varchar2,
       eof_out  out BOOLEAN) is
begin
UTL_FILE.GET_LINE(file_in,line_out);
eof_out := false;
Exception
 when OTHERS THEN
     line_out := null;
  eof_out := TRUE;
end get_line_plus;


procedure lecture_fichier (FileDirectory varchar2, FileName varchar2, ImportName varchar2) is

NewDocId number;
par_repertoire varchar2(300):= FileDirectory;
par_nom_fichier varchar2(200) := FileName;
inc_err_vide EXCEPTION;
inc_err_fichier EXCEPTION;
vl_import_file UTL_FILE.FILE_TYPE;
vl_import_record varchar2(4000);
vl_eof BOOLEAN;
v_line varchar2(4000);
Error varchar2(100);


begin

delete from ind_fichier
where import_name=ImportName;

Error:='Ouverture du fichier';
vl_import_file := UTL_FILE.FOPEN(par_repertoire,par_nom_fichier,'R',32767);


loop
Error:='get_line_plus';
 get_line_plus(vl_import_file,vl_import_record,vl_eof);

 if vl_eof = TRUE then exit;
   else

   v_line:=vl_import_record;

Error:='Insert dans la table';
   insert into ind_fichier (
                    IND_LINE,
               IMPORT_NAME,
               A_DATECRE)
   values (v_line,
             ImportName,
             sysdate);

  end if;
end loop;

Error:='Fermeture du fichier';
UTL_FILE.FCLOSE(vl_import_file);


Exception
  when others then
   UTL_FILE.FCLOSE(vl_import_file);
   raise_application_error(-20001,'Erreur: '||Error);




end lecture_fichier;

end ind_reprise_fichier;
