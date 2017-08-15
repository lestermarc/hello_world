--------------------------------------------------------
--  DDL for Package Body VDOC_HRM_OEM_ABSENCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_HRM_OEM_ABSENCE" 
IS
    type r_color is record(dsp_icon_name DIC_SCH_PERIOD_1.DSP_ICON_NAME%type);
    type t_colors is table of r_color index by dic_sch_period_1.dic_sch_period_1_id%type;
    type r_absence is  record(dic_sch_period_1_id dic_sch_period_1.dic_sch_period_1_id%type, dit_descr dico_description.dit_descr%type, duration number(5,2), scp_comment pac_schedule_period.scp_comment%type,
                         scp_date pac_schedule_period.scp_date%type, scp_from pac_schedule_period.scp_date%type, scp_to pac_schedule_period.scp_date%type);
    type t_absences is table of r_absence index by binary_integer;
    type t_ref is ref cursor;

    procedure insert_absence(user_in in varchar2, absence_type_in in varchar2, date_from_in in timestamp, date_to_in in timestamp, comment_in in varchar2)
    is
    l_begin date;
    l_end date;
    begin
     l_begin := cast(date_from_in as date);
     l_end := cast(date_to_in as date);
     for x in 1..(trunc(l_end)-trunc(l_begin)+1) loop
         insert into pac_schedule_period(PAC_SCHEDULE_PERIOD_ID, PAC_SCHEDULE_ID, HRM_PERSON_ID, DIC_SCH_PERIOD_1_ID, SCP_OPEN_TIME, SCP_CLOSE_TIME, scp_nonworking_day, SCP_DATE, SCP_COMMENT, A_DATECRE, A_IDCRE)
         select init_id_seq.nextval,
         pac_schedule_id,
         to_number(user_in),
         trim(absence_type_in),
         case when trunc(l_begin+x-1)=trunc(l_begin) then l_begin-trunc(l_begin) else null end,
         case when trunc(l_begin+x-1)=trunc(l_end) then l_end-trunc(l_end) else null end,
         case when trunc(l_begin+x-1)<>trunc(l_end) and trunc(l_begin+x-1)<>trunc(l_begin) then 1 else 0 end,
         trunc(l_begin+x-1),
         trim(comment_in),
         trunc(sysdate),
         pcs.PC_I_LIB_SESSION.getuserini
         from
         pac_schedule
         where sce_default=1;
     end loop;
    end;



    function colors return t_colors
    is
     l_result t_colors;
     type tref is ref cursor;
     type t_color is record(dsp_icon_name DIC_SCH_PERIOD_1.DSP_ICON_NAME%type, dic_sch_period_1_id dic_sch_period_1.dic_sch_period_1_id%type);
     c_colors tref;
     csr_color t_color;
     l_stmnt clob;
    begin
     select PCS.PC_LIB_SQL.GETSQLFORSQL('VDOC','HRM_OEM_ABSENCE','AGENDA_HTML_COLORS') into l_stmnt from dual;
        open c_colors for l_stmnt;
        fetch c_colors into csr_color;
        while c_colors%found
            loop
                if csr_color.dic_sch_period_1_id is not null then
                l_result(csr_color.dic_sch_period_1_id).dsp_icon_name:=csr_color.dsp_icon_name;
                end if;
                fetch c_colors into csr_color;
        end loop;
        close c_colors;
        return l_result;
    end;

    /* couleurs de la cellule du jour pour l'employé */
    function cell(empid in hrm_person.hrm_person_id%type, period in varchar2, day_in in pls_integer, absences t_absences, l_colors t_colors) return varchar2
    is
    l_result      varchar2(4000);
    l_tr          varchar2(4000);
    l_iteration   pls_integer;
    l_last_period date;
    i_absence   pls_integer;
    begin
        l_iteration := 0;
        i_absence := 1;
        while i_absence < absences.count loop
          if absences(i_absence).scp_date = to_date(period||lpad(day_in,2,'0'),'yyyymmdd') then
            if absences(i_absence).dic_sch_period_1_id is not null then
                l_iteration := l_iteration +1;
                if l_iteration = 1 then
                    l_result := '<TABLE class="inner" width=100%><TR class="sql">';

                    if absences(i_absence).scp_from >= absences(i_absence).scp_date+0.5 then
                        /* ajout matin en blanc */
                        l_result:=l_result||' <td width=50%/> ';
                    end if;

                end if;

                l_tr    := ' <TD class="abs_typ_'||absences(i_absence).dic_sch_period_1_id||'"; width="'||trunc(absences(i_absence).duration)||'%" border:none title="'||absences(i_absence).dit_descr||
                           ';'||to_char(absences(i_absence).scp_date,'dd.mm.yyyy')||' '||to_char(absences(i_absence).scp_from,'hh24:mi')||' - '||to_char(absences(i_absence).scp_to,'hh24:mi')||
                           ';'||';'||absences(i_absence).scp_comment||'">';
                l_result := l_result||l_tr||';;'||'</TD>';

            end if;

            l_last_period := absences(i_absence).scp_to;
          end if;
          i_absence := absences.next(i_absence);
        end loop;


        if to_char(l_last_period,'HH24')<='12' then
            l_result:=l_result||' <td width=50%/>';
        end if;

        l_result:=l_result||case when l_iteration>0 then '</TR></TABLE>' else '' end;

        return l_result;
    end;



    /* Couleurs des cellules du mois pour l'employé */
    function absence_html(empid in hrm_person.hrm_person_id%type, period varchar2, l_colors t_colors) return varchar2
    is
    l_day       pls_integer:=1;
    l_code      varchar2(32000);
    l_stmnt     clob;
    l_iterator pls_integer:=1;
    l_absences  t_absences;
    c_absence   t_ref;
    csr_absence r_absence;
    l_result      varchar2(4000);
    l_tr          varchar2(4000);
    l_iteration   pls_integer;
    l_last_period date;
    i_absence   pls_integer;

    begin
        select replace(replace(pcs.pc_lib_sql.getsqlforsql('VDOC','HRM_OEM_ABSENCE','ABSENCES_BY_EMP_AND_DAY'),':HRM_PERSON_ID',empid),':SCP_MONTH','to_date('''||period||'01'',''yyyymmdd'')') into l_stmnt from dual;


        open c_absence for l_stmnt ;
        fetch c_absence into  csr_absence;
        l_absences(l_iterator) := csr_absence;
        while c_absence%found loop
         fetch c_absence into csr_absence;
         l_iterator := l_iterator + 1;
         l_absences(l_iterator) := csr_absence;
        end loop;
        close c_absence;



        l_day:=1;
        while l_day <= 31 loop
            l_code := l_code||'<TD class="sql">'||cell(empid, period, l_day, l_absences, l_colors )||'</TD>';
            l_day := l_day+1;
        end loop;
        return l_code;
    end;




    function agenda_html(period in varchar2, rec_id in varchar2)
    return clob
    is  l_day       pls_integer:=1;
        l_code      clob;
        l_day_code  varchar2(255);
        l_day_abs   varchar2(50);
        l_stmnt     clob;
        type tref is ref cursor;
        l_colors t_colors;
        c_employees tref;
        type t_employee is record(hrm_person_id hrm_person.hrm_person_id%type, per_fullname hrm_person.per_fullname%type);
        csr_employee t_employee;
        cur_color varchar2(20);
        l_style varchar2(4000);
        l_legend varchar2(4000);
    begin
        l_colors := colors;

        /* Labels des couleurs dans un tableau */
        l_legend := '<TABLE class="sql" cellspacing=10 align=center><TR class="sql">';
        l_code := '<HTML><BODY align="center"><br/>';
        l_style := '<style type="text/css">table.sql, td.sql, tr.sql, th.sql {font-size:12px;border:1px solid; border-collapse:collapse;valign:center;align:center;};
                                           table.inner {font-size:12px;border:none; border-collapse:collapse;halign:middle;valign:middle;} ';
        cur_color := l_colors.first;
        loop
             l_style := l_style || ' td.abs_typ_'|| cur_color||' {background-color:'||l_colors(cur_color).dsp_icon_name||'; font-size:12px;}';
             l_legend:=l_legend||'<TD valign="middle" border="1" class="abs_typ_'||cur_color||'">'||com_dic_functions.getdicodescr('DIC_SCH_PERIOD_1',cur_color)||'</TD>';
             cur_color := l_colors.next(cur_color);
             exit when cur_color = l_colors.last;
        end loop;
        l_style := l_style||'</style>';

        /* Initialisation du tableau des absences */
        l_legend := l_legend||'</TR></TABLE>';
        l_code := l_code||l_style||'<TABLE class="sql"><TR class="sql">';
        l_code := l_code||'<TH class="sql">Employee name</TH>';

        /* Insertion de la ligne des jours */
        while l_day <= 31 loop
            l_day_code := '<TD class="sql" width="25" align="center"'||case when to_char(to_date(period||lpad(l_day,2,'0'),'yyyymmdd'),'D', 'NLS_DATE_LANGUAGE=AMERICAN') ='7' then 'bgcolor="gray"' else '' end||'>'||l_day||'</TD>';
            l_code := l_code||l_day_code;
            l_day := l_day+1;
        end loop;
        l_code:=l_code||'</TR>';

        /* Insertion de la ligne par employé */
        select replace(PCS.PC_LIB_SQL.GETSQLFORSQL('VDOC','HRM_OEM_ABSENCE','AGENDA_HTML_EMPLOYEES'),':HRM_IN_CHARGE_ID',REC_ID) into l_stmnt from dual;
        open c_employees for l_stmnt;
        fetch c_employees into csr_employee;
        while c_employees%found loop
            l_code:=l_code||'<TR class="sql"><TD class="sql">'||csr_employee.per_fullname||'</TD>';
            l_code := l_code||absence_html(csr_employee.hrm_person_id,period, l_colors);
            l_code:= l_code||'</TR>';
            fetch c_employees into csr_employee;
        end loop;
        close c_employees;
        l_code := l_code||'</TR></TABLE><br/>'||l_legend||'</BODY></HTML>';
        return l_code;
    end;


    function absence_history(user_in in varchar2, date_since in date) return clob
    is
     l_result clob;
     l_style varchar2(4000);
    begin
      l_style := '<style type="text/css">table.sql, td.sql, tr.sql, th.sql {font-size:12px;border:1px solid; border-collapse:collapse;valign:center;align:center;};
                  </style>';

     l_result := '<HTML><BODY>'||l_style||'<TABLE class="sql"><TR class="sql"><TH class="sql" width="100">Date</TH><TH class="sql" width=150>Heures</TH><TH class="sql" width=500>Type</TH>';
     for x in ( select to_char(scp_date,'DD.MM.YYYY') scp_date,
                 to_char(scp_date+nvl(scp_open_time,0),'HH24:MI')||' - '|| to_char(scp_date+nvl(scp_close_time,0),'HH24:MI') scp_time,
                 com_dic_functions.getdicodescr('DIC_SCH_PERIOD_1',dic_sch_period_1_id, pcs.PC_I_LIB_SESSION.getuserlangid) descr
                from pac_schedule_period
                where hrm_person_id = user_in
                and scp_date >= date_since
                order by scp_date desc ) loop
        l_result := l_result||'<TR class="sql"><TD class="sql">'|| x.scp_date||'</TD><TD class="sql">'||X.SCP_TIME||'</TD><TD class="sql">'||X.DESCR||'</TD></TR>';
     end loop;

     return l_result;
    end;

end;
