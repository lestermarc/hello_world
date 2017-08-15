--------------------------------------------------------
--  DDL for Package Body IND_WEB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_WEB" 
is

 gUseIni varchar2(5) := nvl(pcs.pc_init_session.GetUserIni,'PROC');
 gMsgError varchar2(2000);
 -- Jours de tolérence après la sortie
 DeltaDays number := 90;

 FUNCTION getPassword1(LENGTH IN NUMBER) RETURN VARCHAR2
  IS
  tmpChr VARCHAR2(1);
  tmpLoop integer(1);
  tmpPswd VARCHAR2(32767);
  BEGIN
  --Number of loops equal to the length specified
  FOR i IN 1 .. LENGTH
  LOOP
  --1. Generate a random integer between 48 and 122 because to generate string that
  --has alphanumeric charaters and few special characters availbale on key board
  --2. Get the caharacter whose ascii is equal to the generated ascii code
  SELECT CHR(ROUND(dbms_random.value(48,122),0)) INTO tmpChr FROM dual;
  
  -- if tmpChr is special -> try again
  tmpLoop :=1;
  while tmpLoop=1
  loop
    --if tmpChr in ('''','~','^','`','{','}','[',']','¨','<','>','£','/','\',',','.',':',';','@','#','&','+','"','*','ç','%','(',')','¦','¬','|','¢','?','-','_','¨','!','=')
    if tmpChr in ('''','~','^','`','{','}','[',']','¨','£','#','&','"','*','ç','%','¦','¬','|','¢','¨',';',':','=')
    then tmpLoop := 1;
         SELECT CHR(ROUND(dbms_random.value(48,122),0)) INTO tmpChr FROM dual;
    else tmpLoop := 0;     
    end if;
  end loop;  
  
  --Appending each randomly generated character
  tmpPswd:=tmpPswd||tmpChr;
  END LOOP;
  --returning the final created random password
  RETURN tmpPswd;
  END getPassword1;
  
  FUNCTION getPassword2(LENGTH IN NUMBER) RETURN VARCHAR2
  IS
  tmpChr VARCHAR2(1);
  tmpPswd VARCHAR2(32767);
  BEGIN
  --Number of loops equal to the length specified
  FOR i IN 1 .. LENGTH
  LOOP
  --1. Generate a random integer between 48 and 122 because to generate string that
  --has alphanumeric charaters and few special characters availbale on key board
  --2. Get the caharacter whose ascii is equal to the generated ascii code
  SELECT CHR(ROUND(dbms_random.value(48,122),0)) INTO tmpChr FROM dual;
  --Appending each randomly generated character
  tmpPswd:=tmpPswd||tmpChr;
  END LOOP;
  tmpPswd:=tmpPswd || '+';
  --returning the final created random password
  RETURN tmpPswd;
  END getPassword2;
  
  FUNCTION getPassword3(i_chars_chr_min PLS_INTEGER DEFAULT 5,i_chars_chr_cap PLS_INTEGER DEFAULT 1, i_chars_num PLS_INTEGER DEFAULT 1, i_chars_spc PLS_INTEGER DEFAULT 1) RETURN VARCHAR2 IS
  l_chr_min VARCHAR2(60) := 'abcdefhijkmnoprstuvwxyz';
  l_chr_cap VARCHAR2(60) := 'ABCDEFGHIJKLMNPQRSTUVWXYZ';
  l_num VARCHAR2(60) := '0123456789';
  l_spc VARCHAR2(60) := '!$/()?+*-@';
  --
  l_pwd VARCHAR2(60) := '';
  l_sel VARCHAR2(60) := '';
BEGIN
  --
  -- Remonte un erreur si la valeur est en dehors des limites
  --
  IF (i_chars_chr_cap NOT BETWEEN 0 AND 20) OR
     (i_chars_chr_min NOT BETWEEN 0 AND 20) OR
     (i_chars_num NOT BETWEEN 0 AND 20) OR
     (i_chars_spc NOT BETWEEN 0 AND 20) THEN
    RAISE value_error;
  END IF;
  --
  l_sel := l_sel||rpad('m', i_chars_chr_min, 'm');
  l_sel := l_sel||rpad('c', i_chars_chr_cap, 'c');
  l_sel := l_sel||rpad('n', i_chars_num, 'n');
  l_sel := l_sel||rpad('s', i_chars_spc, 's');
  --
  -- Faire la Loop sur le sélecteur dans un ordre aléatoire et contruire un mot de passe en
  -- choisissant des caractères aléatoire from the class denoted by the
  -- selector.
  --
  FOR rec IN (SELECT level
                FROM dual
             CONNECT BY level <= length(l_sel)
               ORDER BY DBMS_RANDOM.value())
  LOOP
    CASE substr(l_sel, rec.level, 1)
      WHEN 'm' THEN
        l_pwd := l_pwd||substr(l_chr_min, DBMS_RANDOM.value(1, length(l_chr_min)), 1);
      WHEN 'c' THEN
        l_pwd := l_pwd||substr(l_chr_cap, DBMS_RANDOM.value(1, length(l_chr_cap)), 1);  
      WHEN 'n' THEN
        l_pwd := l_pwd||substr(l_num, DBMS_RANDOM.value(1, length(l_num)), 1);
      WHEN 's' THEN
        l_pwd := l_pwd||substr(l_spc, DBMS_RANDOM.value(1, length(l_spc)), 1);
      ELSE
        NULL;
    END CASE;
  END LOOP;
  --
  RETURN l_pwd;
  END getPassword3;
  
  PROCEDURE GenerateWebUser
  is
   cursor CurEmp is
    select 
    hrm_person_id,
    per_last_name,
    per_first_name,
    per_search_name,
    emp_number,
    per_email,
    pc_lang_id
    from
    hrm_person p
    where
    not exists (select 1
            from pcs.pc_user_link l
            where p.hrm_person_id=l.uli_link_record_id
            and l.uli_link_code='HRM_PERSON'
            and l.pc_comp_id=COM_CURRENTCOMPID)
    and (p.emp_status='ACT')
    and not exists (select 1
                    from com_vfields_record vfi
                    where vfi.vfi_rec_id=p.hrm_person_id
                    and vfi.vfi_tabname='HRM_PERSON'
                    and vfi.VFI_BOOLEAN_01=1)
    ;
    
    UserId pcs.pc_user.pc_user_id%type;
    --UserIdExists pcs.pc_user.pc_user_id%type;
    NewPassword pcs.pc_user.use_password%type;
    PswdAlreadyExists number;
    
  begin
  
   for RowEmp in CurEmp
   loop
    
    -- Définition mot de passe
    PswdAlreadyExists := 1;
    While PswdAlreadyExists<>0
    loop
    
      -- génération nouveau mot de passe    
      select getPassword3 into NewPassword
      from dual;
    
        -- recherche si le mot de passe existe déjà
        select nvl(count(*),0) into PswdAlreadyExists
        from pcs.pc_user
        where use_password=NewPassword;
     
     end loop;    
     
                select pcs.init_id_seq.nextval into UserId
                from dual;
                
                -- insert PC_USER
    insert into PCS.PC_USER
                (PC_USER_ID
               , PC_LANG_ID
               , USE_WEB
               , USE_NAME
               , USE_ACCOUNT_NAME
               , USE_PASSWORD
               , USE_FIRST_NAME
               , USE_LAST_NAME
               , USE_DESCR
               , USE_INI
               , A_DATECRE
               , A_IDCRE
               , USE_CREATE_REP
               , USE_MODIF_REP
                )
         values (UserId
               , RowEmp.pc_lang_id
               , 1
               , UserId
               , UserId
               , NewPassword
               , RowEmp.per_first_name
               , RowEmp.per_last_name
               , RowEmp.per_search_name
               , nvl(substr(RowEmp.per_first_name, 1, 1) || substr(RowEmp.per_first_name, 1, 2), substr(RowEmp.per_last_name, 1, 5) )
               , sysdate
               , gUseIni
               , 0
               , 0
                );
                     
    -- Field PC_COMP_ID is materialized in table PC_USER_LINK
    -- and determine that this user is active in the company
    insert into PCS.PC_USER_LINK
                (PC_USER_LINK_ID
               , PC_USER_ID
               , PC_COMP_ID
               , ULI_LINK_CODE
               , ULI_LINK_RECORD_ID
               , ULI_DESC
               , A_DATECRE
               , A_IDCRE
                )
         values (pcs.init_id_seq.nextval
               , UserId
               , COM_CURRENTCOMPID
               , 'WEB_USER'
               , UserId
               , 'Created by IND_WEB_PACKAGE'
               , sysdate
               , gUseIni
                );
                
    -- Field WEU_DISABLED is materialized in table PC_USER_LINK
    insert into PCS.PC_USER_LINK
                (PC_USER_LINK_ID
               , PC_USER_ID
               , PC_COMP_ID
               , ULI_LINK_CODE
               , ULI_LINK_RECORD_ID
               , ULI_DESC
               , A_DATECRE
               , A_IDCRE
                )
         values (pcs.init_id_seq.nextval
               , UserId
               , COM_CURRENTCOMPID
               , 'WEB_USER.WEU_DISABLED'
               , 0
               , 'Created by IND_WEB_PACKAGE'
               , sysdate
               , gUseIni
                );
                
    -- Field HRM_PERSON_ID is materialized in table PC_USER_LINK
      insert into PCS.PC_USER_LINK
                  (PC_USER_LINK_ID
                 , PC_USER_ID
                 , PC_COMP_ID
                 , ULI_LINK_CODE
                 , ULI_LINK_RECORD_ID
                 , ULI_DESC
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (pcs.init_id_seq.nextval
                 , UserId
                 , COM_CURRENTCOMPID
                 , 'HRM_PERSON'
                 , RowEmp.hrm_person_id
                 , 'Created by IND_WEB_PACKAGE'
                 , sysdate
                 , gUseIni
                  );

   end loop;
   
   -- mise à jour status
   --UpdateStatus; 
   
  end GenerateWebUser;
  
  PROCEDURE UpdateStatus 
  -- Active/Désactive les utilisateurs web en fonction du statut de l'employé
  is
   Cursor CurToActive (DeltaDays number)
   is
    select
    pc_user_link_id
    from
    pcs.pc_user_link l
    where 
    l.uli_link_record_id=1
    and l.uli_link_code='WEB_USER.WEU_DISABLED'
    and l.pc_comp_id=COM_CURRENTCOMPID
    and exists (select 1
                from pcs.pc_user_link l2, hrm_in_out io
                where l2.pc_user_id=l.pc_user_id
                and l2.pc_comp_id=l.pc_comp_id
                and l2.uli_link_code='HRM_PERSON'
                and l.pc_comp_id=COM_CURRENTCOMPID
                and l2.uli_link_record_id=io.hrm_employee_id
                            and ino_in<=last_day(trunc(sysdate))
                            and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null))
                            ;
       
    Cursor CurToInactive (DeltaDays number)
    is
    select
    pc_user_link_id
    from
    pcs.pc_user_link l
    where 
    l.uli_link_record_id=0
    and l.uli_link_code='WEB_USER.WEU_DISABLED'
    and l.pc_comp_id=COM_CURRENTCOMPID
    and exists (select 1
                from pcs.pc_user_link l2
                where l2.pc_user_id=l.pc_user_id
                and l2.pc_comp_id=l.pc_comp_id
                and l2.uli_link_code='HRM_PERSON'
                and l.pc_comp_id=COM_CURRENTCOMPID
                and not exists (select 1
                            from hrm_in_out io
                            where l2.uli_link_record_id=io.hrm_employee_id
                            and ino_in<=last_day(trunc(sysdate))
                            and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)));
                
   
  begin
  
  -- Activation
  for RowToActive in CurToActive (DeltaDays)
  loop
  
   update pcs.pc_user_link
   set uli_link_record_id=0
   where pc_user_link_id=RowToActive.pc_user_link_id;
  
  end loop;
  
  -- Désctivation
  for RowToInactive in CurToInactive (DeltaDays)
  loop
  
   update pcs.pc_user_link
   set uli_link_record_id=1
   where pc_user_link_id=RowToInactive.pc_user_link_id;
  
  end loop;
  
  end UpdateStatus;
  
  PROCEDURE ExportWeb (vPeriod varchar2, vPayProcess varchar2, vUserType varchar2, vCheckLaunched number default 0,  vForceCtrl number default 0)
  is 
  cursor CurPDF(vPeriod varchar2, vPayProcess varchar2) is
  -- contrôle PDF généré
  select
  p.emp_number,
  p.per_search_name,
  a.hit_pay_num,
  p.per_web_page
  from
  hrm_history a,
  hrm_person p
  where
  p.hrm_person_id=a.hrm_employee_id
  and p.emp_number like 'E%'
  and to_char(hit_pay_period,'YYYYMM')=vPeriod
  and not exists (select 1
                  from hrm_payslip b
                  where a.hrm_employee_id=b.hrm_person_id
                  and a.hit_pay_num=b.hps_pay_num)
  and exists (select 1
              from IND_WEB_EXTRACT_PAYSLIP_P_DET c
              where c_payroll_process=vPayProcess)
  and exists (select 1
              from hrm_history d
              where a.hrm_employee_id=d.hrm_employee_id
              and a.hit_pay_num=d.hit_pay_num
              and d.hit_definitive=1);
              
  cursor CurProv(vPeriod varchar2, vPayProcess varchar2)  is
  -- contrôle provisoire
  select
  p.emp_number,
  p.per_search_name,
  a.hit_pay_num,
  p.per_web_page
  from
  hrm_history a,
  hrm_person p
  where
  p.hrm_person_id=a.hrm_employee_id
  and to_char(hit_pay_period,'YYYYMM')=vPeriod
  and exists (select 1
              from IND_WEB_EXTRACT_PAYSLIP_P_DET c
              where c_payroll_process=vPayProcess)
  and exists (select 1
              from hrm_history d
              where a.hrm_employee_id=d.hrm_employee_id
              and a.hit_pay_num=d.hit_pay_num
              and d.hit_definitive=0);
  
   NewExtractId number(12);
   ExtractExists number;
   vCountPDF number;
   msgPDF varchar2(32767);
  
  begin
  
  -- condition de lancement de tous les contrôles
  if nvl(vForceCtrl,0)=0
  then
  
   -- Contrôle si l'extraction a déjà été lancée
   if vCheckLaunched=1 and nvl(vForceCtrl,0)=0
   then
      select max(IND_WEB_EXTRACTION_ID) into ExtractExists
      from IND_WEB_EXTRACTION
      where WEX_PERIOD=vPeriod
      and C_PAYROLL_PROCESS=vPayProcess;
      
        if ExtractExists is not null
        then raise_application_error(-20001,chr(10)||'--------------------------------------------------'||chr(10)||chr(10)||
                                            'Extraction déjà réalisée pour la période "'||vPeriod||'" et le traitement "'||vPayProcess||'" (Extraction ID: '||ExtractExists||')'
                                            ||chr(10)||chr(10)||
                                            '--------------------------------------------------'||chr(10)
                                    );
        end if;
   end if; -- vCheckLaunched
   
   vCountPDF:=0;
   msgPDF:='';
   -- contrôe PDF
   for RowPDF in CurPDF(vPeriod, vPayProcess)
   loop
     vCountPDF:=vCountPDF+1;
       if vCountPDF=1
        then msgPDF:='Employés avec bulletin calcul en définitif, mais sans PDF généré'||chr(10)||chr(10);
       end if;
     msgPDF:=msgPDF||chr(10)||RowPDF.emp_number||' '||RowPDF.per_search_name||' - N° décompte '||RowPDF.hit_pay_num||' (Gestionnaire '||RowPDF.per_web_page||')';
   
   end loop;
   
    if vCountPDF <> 0 and nvl(vForceCtrl,0)=0
      then raise_application_error(-20001,chr(10)||'--------------------------------------------------'||chr(10)||chr(10)||
                                          msgPDF||chr(10)||chr(10)||
                                            '--------------------------------------------------'||chr(10)
                                          );
    end if;  
   
  end if;  -- tous les contrôles
   
   -- Id
   select nvl(max(IND_WEB_EXTRACTION_ID),0)+1 into NewExtractId
   from IND_WEB_EXTRACTION;
   
   insert into ind_web_extraction (IND_WEB_EXTRACTION_ID,WEX_DESCR,WEX_PERIOD,C_PAYROLL_PROCESS, C_USER_TYPE, FORCE_CONTROL, A_DATECRE,A_IDCRE)
   select NewExtractId, 'Extraction '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS'), vPeriod, vPayProcess, vUserType, vForceCtrl, sysdate, gUseIni from dual;
   
   -- Lancement de la création des utilisateurs
   GenerateWebUser;
   
   -- Lancement de l'extraction des utilisateurs
   ExportWebUser(NewExtractId);
   
   -- Lancement de l'extraction des bulletins de salaire
   -- UNIQUEMENT SI PERIODE SAISIE
   if vPeriod is not null
   then
      ExportPayslip(NewExtractId);
   end if;   
  
  end;
  
  PROCEDURE ExportWebUser(ExtractId number)
  is
   Cursor CurUser
   is
    select
    w.weu_login_name,
    w.weu_first_name,
    w.weu_last_name,
    p.emp_number,
    p.per_email,
    w.WEU_PASSWORD_VALUE,
    (select lanid
     from pcs.pc_lang l
     where p.pc_lang_id=l.pc_lang_id) lanid,
    w.WEU_DISABLED
    from
    web_user w,
    hrm_person p
    where
    w.hrm_person_id=p.hrm_person_id
    order by w.WEB_USER_ID;
    
    vCount number;
    NewExtractUserId number(12);
    
    vOU varchar2(400);
    vUserType varchar2(10);
    vCompCode ind_web_extract_user_param.comp_code%type;

  
  begin
   
   vCount := 0;
   
   -- recherche des paramètres
   select max(a.weu_ou), max(b.c_user_type), max(comp_code)
          into vOU, vUserType, vCompCode
   from ind_web_extract_user_param a, ind_web_extraction b
   where a.c_user_type=b.c_user_type
   and b.ind_web_extraction_id=ExtractId;    
  
   
   for RowUser in CurUser
   loop
    vCount := vCount + 1;
    
    select init_id_seq.nextval into NewExtractUserId
    from dual;
    
    insert into ind_web_extract_user (IND_WEB_EXTRACT_USER_ID,IND_WEB_EXTRACTION_ID,A_DATECRE,A_IDCRE,WEU_LOGIN_NAME,WEU_FIRST_NAME,WEU_LAST_NAME,EMP_NUMBER,WEU_OU,PER_EMAIL,WEU_PASSWORD_VALUE,LANID,WEU_DISABLED,COMP_CODE)
    values (NewExtractUserId,
            ExtractId,
            sysdate,
            gUseIni,
            RowUser.weu_login_name,
            RowUser.weu_first_name,
            RowUser.weu_last_name,
            RowUser.emp_number,
            vOU,
            RowUser.per_email,
            RowUser.WEU_PASSWORD_VALUE,
            RowUser.lanid,
            RowUser.WEU_DISABLED,
            vCompCode);
    
    
   end loop;
  
  -- Lignes formatées
  if vUserType='Portail'
  then
      update ind_web_extract_user
      set ind_line = weu_login_name||';'||weu_first_name||';'||weu_last_name||';'||emp_number||';'||weu_OU||';'||per_email||';'||WEU_PASSWORD_VALUE||';'||lanid||';'||WEU_DISABLED||';'
      where ind_web_extraction_id=ExtractId;
  
  elsif vUserType='Remu'   
  then 
      update ind_web_extract_user
      set ind_line = weu_login_name||';'||emp_number||';'||comp_code||';'||WEU_DISABLED||';'
      where ind_web_extraction_id=ExtractId;
  end if;   
      
   -- Mise à jour des donéées d'extraction dans l'en-tête
  update IND_WEB_EXTRACTION
  set wex_extract_1 = to_char(vCount)||' utilisateurs présents dans l''extraction'||chr(10)||
      'Extraction des utilisateurs - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')              
  where IND_WEB_EXTRACTION_ID = ExtractId;
  
  -- Lancement de la génération du fichier des utilisateurs
  FileWebUser(ExtractId);
  
  EXCEPTION
   WHEN OTHERS
   THEN
   --raise_application_error(-20001,SQLERRM);
   gMsgError := SQLERRM;
   
   update IND_WEB_EXTRACTION
   set wex_extract_1 = 'Erreur lors de l''extraction - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')||chr(10)||
                        gMsgError
   where IND_WEB_EXTRACTION_ID = ExtractId;
   
   UTL_FILE.FCLOSE_ALL;
  
  end ExportWebUser;
  
  PROCEDURE FileWebUser(ExtractId number)
  is
    cursor CurUser
    is 
    select
    ind_line 
    from 
    ind_web_extract_user
    where ind_web_extraction_id=ExtractId;
  
    f_file_id UTL_FILE.FILE_TYPE;
    v_file_location VARCHAR2(256);
    v_file_name VARCHAR2(256);
    v_line VARCHAR2(4000);
    v_header varchar2(500);
  
  begin
  
   -- recherche des paramètres
   select max(IMF_FILE), max(IMD_PATH_FILES), max(OBJ_HEADERFIELDS)
          into v_file_name, v_file_location, v_header
   from ind_web_extract_user_param a, ind_web_extraction b
   where b.ind_web_extraction_id=ExtractId
   and a.c_user_type=b.c_user_type;       
  
   -- Ouverture du fichier
   f_file_id := UTL_FILE.FOPEN(v_file_location,v_file_name,'w');
   DBMS_OUTPUT.PUT_LINE('File location: '||v_file_location);
   
   -- Header
   UTL_FILE.PUT_LINE(f_file_id, v_header); 
   
   for RowUser in CurUser
   loop
   
    UTL_FILE.PUT_LINE(f_file_id, RowUser.ind_line); 
   
   end loop;
   
     -- Clôture du fichier 
    UTL_FILE.FCLOSE (f_file_id); 
    
    -- Mise à jour nom du fichier dans l'en-tête
  update IND_WEB_EXTRACTION
  set wex_file_1 =  v_file_location||v_file_name||chr(10)||
      'Fichier généré - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')             
  where IND_WEB_EXTRACTION_ID = ExtractId;
  
  EXCEPTION
   WHEN OTHERS
   THEN
   --raise_application_error(-20001,SQLERRM);
   gMsgError := SQLERRM;
    update IND_WEB_EXTRACTION
    set wex_file_1 = 'Erreur lors de la génération du fichier - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')||chr(10)||
                     gMsgError
  where IND_WEB_EXTRACTION_ID = ExtractId;
   
   UTL_FILE.FCLOSE_ALL;
  
  end FileWebUser;
  
  PROCEDURE ExportPayslip(ExtractId number)
  is
   Cursor CurPay (vPeriod varchar2)
   is
    select
    b.weu_login_name,
    b.weu_first_name,
    b.weu_last_name,
    a.hrm_person_id,
    a.hps_pay_num,
    a.hrm_payslip_id,
    (select max(COMP_CODE) from IND_WEB_EXTRACT_PAYSLIP_P_DET det ) com_name,
    (select nvl(max(comp_code),'00001') from IND_WEB_EXTRACT_PAYSLIP_P_DET det )||'_'||b.weu_login_name||'_'||vPeriod||'_'||lpad(a.hps_pay_num,4,'0')||'.PDF' IMF_FILE
    --(select max(COMP_CODE) from IND_WEB_EXTRACT_PAYSLIP_PARAM) com_name,
    --(select nvl(max(comp_code),'00001') from IND_WEB_EXTRACT_PAYSLIP_PARAM)||'_'||b.weu_login_name||'_'||vPeriod||'_'||lpad(a.hps_pay_num,4,'0')||'.PDF' IMF_FILE
    from
    hrm_payslip a,
    web_user b,
    hrm_history c
    where
    a.hrm_person_id=b.hrm_person_id
    and a.hrm_person_id = c.hrm_employee_id 
    and a.hps_pay_num = c.hit_pay_num 
    and to_char(a.hps_pay_period,'YYYYMM')=vPeriod
    and exists (select 1
                from IND_WEB_EXTRACTION ext, IND_WEB_EXTRACT_PAYSLIP_P_DET det
                where IND_WEB_EXTRACTION_ID=ExtractId
                and ext.c_payroll_process=det.c_payroll_process)
    and not exists (select 1
                    from com_vfields_record vfi
                    where a.hrm_person_id=vfi.vfi_rec_id
                    and vfi.vfi_tabname='HRM_PERSON'
                    and nvl(vfi.VFI_BOOLEAN_02,0)=1)
    order by 1,6;
    
    vCount number;
    NewExtractPayslipId number(12);
    
    vPeriod varchar2(6);

  begin
  
   -- recherche période
   select max(wex_period) into vPeriod
   from ind_web_extraction
   where ind_web_extraction_id=ExtractId;
   
   vCount:=0;
   
   for RowPay in CurPay (vPeriod)
   loop
    
    vCount := vCount+1;
    
    -- Recherche id du record
    select init_id_seq.nextval into NewExtractPayslipId
    from dual;
    
    -- insert positions dans la table
    insert into IND_WEB_EXTRACT_PAYSLIP (IND_WEB_EXTRACT_PAYSLIP_ID,IND_WEB_EXTRACTION_ID,A_DATECRE,A_IDCRE,HRM_PERSON_ID,WEU_LOGIN_NAME,WEU_FIRST_NAME,WEU_LAST_NAME,HIT_PAY_NUM,HRM_PAYSLIP_ID, COM_NAME,IMF_FILE)
    values (NewExtractPayslipId,
            ExtractId,
            sysdate,
            gUseIni,
            RowPay.hrm_person_id,
            RowPay.weu_login_name,
            RowPay.weu_first_name,
            RowPay.weu_last_name,
            RowPay.hps_pay_num,
            RowPay.hrm_payslip_id,
            RowPay.com_name,
            RowPay.IMF_FILE);
    
   end loop;
   
    -- Mise à jour des donéées d'extraction dans l'en-tête
  update IND_WEB_EXTRACTION
  set wex_extract_2 = to_char(vCount)||' bulletins présents dans l''extraction'||chr(10)||
                      'Extraction des bulletins de salaire - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')
  where IND_WEB_EXTRACTION_ID = ExtractId;
  
  -- Création des fichiers
  FilePayslip(ExtractId);
  
   EXCEPTION
   WHEN OTHERS
   THEN
   --raise_application_error(-20001,SQLERRM);
   gMsgError := SQLERRM;
   
   update IND_WEB_EXTRACTION
   set wex_extract_2 = 'Erreur lors de l''extraction - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')||chr(10)||
                        gMsgError
   where IND_WEB_EXTRACTION_ID = ExtractId;
  
  end ExportPayslip;
  
  PROCEDURE FilePayslip(ExtractId number)
  is
    cursor CurPay
    is 
    select
    a.IMF_FILE,
    a.c_salary_sheet,
    dbms_lob.getlength(b.HPS_PAYSLIP) v_len,
    b.HPS_PAYSLIP v_blob
    from 
    ind_web_extract_payslip a,
    hrm_payslip b
    where ind_web_extraction_id=ExtractId
    and a.hrm_payslip_id=b.hrm_payslip_id
    --and a.com_name='PCGI'
    ;
  
    f_file_id UTL_FILE.FILE_TYPE;
    v_file_location VARCHAR2(256);
    v_file_name VARCHAR2(256);
    
    l_clob BLOB;
    l_pos NUMBER := 1;
    l_amount BINARY_INTEGER := 32760;
    --v_lelen NUMBER;
    v_raw RAW(32760);
    v_x NUMBER;
    v_bytelen NUMBER;
    v_start NUMBER;
    v_output utl_file.file_type;
  
  begin
     
   for RowPay in CurPay
   loop
   
   -- recherche des paramètres
   select max(c.IMD_PATH_FILES)
          into v_file_location 
   from ind_web_extract_payslip_param a, IND_WEB_EXTRACTION b, ind_web_extract_payslip_p_det c
   where b.IND_WEB_EXTRACTION_ID=ExtractId
   and b.c_payroll_process=a.c_payroll_process
   and b.c_payroll_process=c.c_payroll_process;     
   
   v_file_name := RowPay.IMF_FILE;
   
   -- define output directory
    v_output := utl_file.fopen(v_file_location, v_file_name,'wb', 32760);
    
    v_x := RowPay.v_len;
    v_start := 1;
    v_bytelen := 2000;
    
    WHILE v_start < RowPay.v_len AND v_bytelen > 0
          LOOP
             -- Lecture du contenu du BLOB par fragments
    
             DBMS_LOB.READ (RowPay.v_blob, v_bytelen, v_start, v_raw);
             -- Ecriture partielle du fichier sur le disque
    
             UTL_FILE.put_raw (v_output, v_raw);
             UTL_FILE.fflush (v_output);
             v_start := v_start + v_bytelen;
             v_x := v_x - v_bytelen;
    
             IF v_x < 2000
             THEN
                v_bytelen := v_x;
             END IF;
          END LOOP;

      UTL_FILE.fclose (v_output);

      -- Fin Curseur Payslip
      end loop;
   
     -- Clôture du fichier 
    UTL_FILE.FCLOSE (f_file_id); 
    
    -- Mise à jour nom du fichier dans l'en-tête
  update IND_WEB_EXTRACTION
  set wex_file_2 = v_file_location||chr(10)||
                   'Fichiers générés - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS') 
  where IND_WEB_EXTRACTION_ID = ExtractId;
  
  EXCEPTION
   WHEN OTHERS
   THEN
   --raise_application_error(-20001,SQLERRM);
   gMsgError := SQLERRM;
    update IND_WEB_EXTRACTION
    set wex_file_2 = 'Erreur lors de la génération du fichier - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')||chr(10)||
                     gMsgError
  where IND_WEB_EXTRACTION_ID = ExtractId;
   
   UTL_FILE.FCLOSE_ALL;
  
  end FilePayslip;
  
  PROCEDURE ExportPayslipFromTo(ExtractId number)
  is
   Cursor CurPeriod(ExtractId number) is
   select
   to_char(b.per_begin,'YYYYMM') period
   from 
   ind_web_extraction a,
   hrm_period b
   where
   a.ind_web_extraction_id=ExtractId
   and b.per_begin<=last_day(to_date(a.vex_period_to,'YYYYMM'))
   and b.per_end>=to_date(a.wex_period,'YYYYMM')
   order by b.per_begin;
   
   Cursor CurPay (vPeriod varchar2)
   is
    select
    b.weu_login_name,
    b.weu_first_name,
    b.weu_last_name,
    a.hrm_person_id,
    a.hps_pay_num,
    a.hrm_payslip_id,
    (select max(COMP_CODE) from IND_WEB_EXTRACT_PAYSLIP_P_DET det ) com_name,
    (select nvl(max(comp_code),'00001') from IND_WEB_EXTRACT_PAYSLIP_P_DET det )||'_'||b.weu_login_name||'_'||vPeriod||'_'||lpad(a.hps_pay_num,4,'0')||'.PDF' IMF_FILE
    --(select max(COMP_CODE) from IND_WEB_EXTRACT_PAYSLIP_PARAM) com_name,
    --(select nvl(max(comp_code),'00001') from IND_WEB_EXTRACT_PAYSLIP_PARAM)||'_'||b.weu_login_name||'_'||vPeriod||'_'||lpad(a.hps_pay_num,4,'0')||'.PDF' IMF_FILE
    from
    hrm_payslip a,
    web_user b,
    hrm_history c
    where
    a.hrm_person_id=b.hrm_person_id
    and a.hrm_person_id = c.hrm_employee_id 
    and a.hrm_person_id = 4123860
    and a.hps_pay_num = c.hit_pay_num 
    and to_char(a.hps_pay_period,'YYYYMM')=vPeriod
    and exists (select 1
                from IND_WEB_EXTRACTION ext, IND_WEB_EXTRACT_PAYSLIP_P_DET det
                where IND_WEB_EXTRACTION_ID=ExtractId
                and ext.c_payroll_process=det.c_payroll_process)
    and not exists (select 1
                    from com_vfields_record vfi
                    where a.hrm_person_id=vfi.vfi_rec_id
                    and vfi.vfi_tabname='HRM_PERSON'
                    and nvl(vfi.VFI_BOOLEAN_02,0)=1)
    order by 1,6;
    
    vCount number;
    NewExtractPayslipId number(12);
    
    vPeriod varchar2(6);

  begin
  
   vCount:= 0;
   
   -- Période  
   for RowPeriod in CurPeriod (ExtractId)
   loop  
   
   vPeriod := RowPeriod.period;
   
   for RowPay in CurPay (vPeriod)
   loop
    
    vCount := vCount+1;
    
    -- Recherche id du record
    select init_id_seq.nextval into NewExtractPayslipId
    from dual;
    
    -- insert positions dans la table
    insert into IND_WEB_EXTRACT_PAYSLIP (IND_WEB_EXTRACT_PAYSLIP_ID,IND_WEB_EXTRACTION_ID,A_DATECRE,A_IDCRE,HRM_PERSON_ID,WEU_LOGIN_NAME,WEU_FIRST_NAME,WEU_LAST_NAME,HIT_PAY_NUM,HRM_PAYSLIP_ID, COM_NAME,IMF_FILE)
    values (NewExtractPayslipId,
            ExtractId,
            sysdate,
            gUseIni,
            RowPay.hrm_person_id,
            RowPay.weu_login_name,
            RowPay.weu_first_name,
            RowPay.weu_last_name,
            RowPay.hps_pay_num,
            RowPay.hrm_payslip_id,
            RowPay.com_name,
            RowPay.IMF_FILE);
    
   end loop;
   
   end loop; -- Période
   
    -- Mise à jour des donéées d'extraction dans l'en-tête
  update IND_WEB_EXTRACTION
  set wex_extract_2 = to_char(vCount)||' bulletins présents dans l''extraction'||chr(10)||
                      'Extraction des bulletins de salaire - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')
  where IND_WEB_EXTRACTION_ID = ExtractId;
  
  -- Création des fichiers
  FilePayslip(ExtractId);
  
   EXCEPTION
   WHEN OTHERS
   THEN
   --raise_application_error(-20001,SQLERRM);
   gMsgError := SQLERRM;
   
   update IND_WEB_EXTRACTION
   set wex_extract_2 = 'Erreur lors de l''extraction - '||to_char(sysdate,'DD.MM.YYYY HH24:MI:SS')||chr(10)||
                        gMsgError
   where IND_WEB_EXTRACTION_ID = ExtractId;
  
  end ExportPayslipFromTo;
  
  PROCEDURE ExtractUserStatus
  -- alimentation de la table des comptes à activer ou désactiver
  is
  begin
  
  delete from PCS.IND_PC_WEB_USER_DISABLE;
  
  -- A activer
  insert into PCS.IND_PC_WEB_USER_DISABLE (IND_PC_WEB_USER_DISABLE_ID,PC_USER_LINK_ID,PC_USER_ID,HRM_PERSON_ID, EMC_ACTIVE, CODE_STATUS, WEU_LOGIN_NAME,WEU_DISABLED,PER_SEARCH_NAME,PER_LAST_NAME,PER_FIRST_NAME,EMP_NUMBER,EMP_SECONDARY_KEY,EMP_STATUS,PER_WEB_PAGE,INO_IN,INO_OUT,FIN_TO_INACTIVE,A_DATECRE,A_IDCRE)
  select
    init_id_seq.nextval,
    l.pc_user_link_id,
    l.pc_user_id,
    p.hrm_person_id,
    1,
    '1',
    (select weu_login_name from web_user u where u.pc_user_id=l.pc_user_id) weu_login_name,
    l.uli_link_record_id WEU_DISABLED,
    p.per_search_name,
    p.per_last_name,
    p.per_first_name,
    p.emp_number,
    p.emp_secondary_key,
    p.emp_status,
    p.per_web_page,
    (select min(ino_in)
     from hrm_in_out i
     where i.hrm_employee_id=p.hrm_person_id
     and ino_in<=last_day(trunc(sysdate))
     and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)) ino_in,
    (select max(ino_out)
     from hrm_in_out i
     where i.hrm_employee_id=p.hrm_person_id
     and ino_in<=last_day(trunc(sysdate))
     and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)) ino_out,
    0 FIN_TO_INACTIVE,
    sysdate,
    gUseIni
    from
    pcs.pc_user_link l,
    pcs.pc_user_link lp,
    hrm_person p
    where 
    l.pc_user_id=lp.pc_user_id
    and l.pc_comp_id=lp.pc_comp_id
    and lp.uli_link_record_id=p.hrm_person_id(+)
    and l.uli_link_record_id=1
    and l.uli_link_code='WEB_USER.WEU_DISABLED'
    and lp.uli_link_code='HRM_PERSON'
    and l.pc_comp_id=COM_CURRENTCOMPID
    and exists (select 1
                from pcs.pc_user_link l2, hrm_in_out io
                where l2.pc_user_id=l.pc_user_id
                and l2.pc_comp_id=l.pc_comp_id
                and l2.uli_link_code='HRM_PERSON'
                and l.pc_comp_id=COM_CURRENTCOMPID
                and l2.uli_link_record_id=io.hrm_employee_id
                            and ino_in<=last_day(trunc(sysdate))
                            and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null));
                            
    -- A désactiver
    insert into PCS.IND_PC_WEB_USER_DISABLE (IND_PC_WEB_USER_DISABLE_ID,PC_USER_LINK_ID,PC_USER_ID,HRM_PERSON_ID, EMC_ACTIVE, CODE_STATUS, WEU_LOGIN_NAME,WEU_DISABLED,PER_SEARCH_NAME,PER_LAST_NAME,PER_FIRST_NAME,EMP_NUMBER,EMP_SECONDARY_KEY,EMP_STATUS,PER_WEB_PAGE,INO_IN,INO_OUT,FIN_TO_INACTIVE,A_DATECRE,A_IDCRE)
    select
    init_id_seq.nextval,
    l.pc_user_link_id,
    l.pc_user_id,
    p.hrm_person_id,
    1,
    '2',
    (select weu_login_name from web_user u where u.pc_user_id=l.pc_user_id) weu_login_name,
    l.uli_link_record_id WEU_DISABLED,
    p.per_search_name,
    p.per_last_name,
    p.per_first_name,
    p.emp_number,
    p.emp_secondary_key,
    p.emp_status,
    p.per_web_page,
    (select min(ino_in)
     from hrm_in_out i
     where i.hrm_employee_id=p.hrm_person_id
     and ino_in<=last_day(trunc(sysdate))
     and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)) ino_in,
    (select max(ino_out)
     from hrm_in_out i
     where i.hrm_employee_id=p.hrm_person_id
     and ino_in<=last_day(trunc(sysdate))
     and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)) ino_out,
    1 FIN_TO_INACTIVE,
    sysdate,
    gUseIni
    from
    pcs.pc_user_link l,
    pcs.pc_user_link lp,
    hrm_person p
    where 
    l.pc_user_id=lp.pc_user_id
    and l.pc_comp_id=lp.pc_comp_id
    and lp.uli_link_record_id=p.hrm_person_id(+)
    and l.uli_link_record_id=0
    and l.uli_link_code='WEB_USER.WEU_DISABLED'
    and lp.uli_link_code='HRM_PERSON'
    and l.pc_comp_id=COM_CURRENTCOMPID
    and exists (select 1
                from pcs.pc_user_link l2
                where l2.pc_user_id=l.pc_user_id
                and l2.pc_comp_id=l.pc_comp_id
                and l2.uli_link_code='HRM_PERSON'
                and l.pc_comp_id=COM_CURRENTCOMPID
                and not exists (select 1
                            from hrm_in_out io
                            where l2.uli_link_record_id=io.hrm_employee_id
                            and ino_in<=last_day(trunc(sysdate))
                            and (ino_out + DeltaDays >=trunc(sysdate,'MM') or ino_out is null)));                        
  
  end ExtractUserStatus;
  
  PROCEDURE UpdateUserStatus
  -- mise à jour du statut des utilisateurs web selon sélections faites dans l'extraction de la procédure ExtractUserStatus
  is
  
   Cursor CurUser is
    select
    pc_user_link_id,
    FIN_TO_INACTIVE
    from PCS.IND_PC_WEB_USER_DISABLE
    where emc_active=1;
  
  begin
  
   for RowUser in CurUser
   loop 
   
    update pcs.pc_user_link a
    set uli_link_record_id=nvl(RowUser.FIN_TO_INACTIVE,0),
        a_datemod=sysdate,
        a_idmod=gUseIni
    where pc_user_link_id=RowUser.pc_user_link_id;
    
   end loop;
   
   -- suppression des records après traitement
   delete from PCS.IND_PC_WEB_USER_DISABLE;
   
  end UpdateUserStatus;
  
  PROCEDURE ExtractEMail(vType varchar2)
  -- Extraction des utilisateurs pour envoi du mail informant des données de connexion
  -- Paramètre = "LOGIN" ou "PASSWORD"
  is
   NewId number;
   RepName varchar2(100);
  begin
  
  -- recherche nouvel id d'extraction (en-tête)
  select nvl(max(ind_web_mail_header_id),0)+1 into NewId
  from ind_web_mail_header;
  
  -- varibale Rapport
  if vType='PASSWORD'
     then RepName:='PORTAL_PASSWORD';
     else RepName:='PORTAL_LOGIN';
  end if;
  
  -- En-tête
  insert into ind_web_mail_header (IND_WEB_MAIL_HEADER_ID,IMD_MAIL_CONTENT,REP_REPNAME,A_DATECRE,A_IDCRE)
  values (NewId, vType, RepName, sysdate, gUseIni);
  
  -- Positions
  insert into ind_web_mail_position (
              IND_WEB_MAIL_HEADER_ID,
              IND_WEB_MAIL_POSITION_ID,
              IML_TRANSFERRED,
              WEU_LOGIN_NAME,
              PER_SEARCH_NAME,
              EMP_NUMBER,
              PER_EMAIL,
              PER_WEB_PAGE,
              EVE_SUBJECT,
              EVE_TEXT,
              A_DATECRE,
              A_IDCRE)
  select NewId,
         init_id_seq.nextval,  
         0,
         U.WEU_LOGIN_NAME,
         PER_SEARCH_NAME,
         EMP_NUMBER,
         PER_EMAIL,
         PER_WEB_PAGE,
         (Select Max(M.EVE_SUBJECT) from IND_MAIL_MESSAGE M Where M.PC_LANG_ID = P.PC_LANG_ID AND IMD_CONTENT = vType) EVE_SUBJECT,
         (Select Max(replace(replace(M.EVE_TEXT,'[NAME]',P.PER_FIRST_NAME), '[SENDER]', (SELECT X.USE_DESCR FROM PCS.PC_USER X WHERE X.PC_USER_ID = PCS.PC_INIT_SESSION.GetUserId) ))
          from IND_MAIL_MESSAGE M
          Where M.PC_LANG_ID = P.PC_LANG_ID AND IMD_CONTENT = vType) EVE_TEXT,
          sysdate,
          gUseIni
  FROM WEB_USER U, HRM_PERSON P
  WHERE U.HRM_PERSON_ID = P.HRM_PERSON_ID;
  
  
  end ExtractEMail;
  
  PROCEDURE UpdateSentEMail(vPosId number)
  -- mise à jour flag transmis
  is
  
  begin
  
   update ind_web_mail_position
   set  IML_TRANSFERRED   =   1,
        IML_TRANSFER_DATE =   sysdate
   where ind_web_mail_position_id=vPosId;
   
  end UpdateSentEMail;
  
  -- ################################################
  
end ind_web;
