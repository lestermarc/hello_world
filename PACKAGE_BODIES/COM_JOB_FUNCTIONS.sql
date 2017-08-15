--------------------------------------------------------
--  DDL for Package Body COM_JOB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_JOB_FUNCTIONS" 
is
/**
*________________________________________________________________________________
*
* This package and all subprograms are deprecated.
* use PC_PRC_JOB or PC_LIB_JOB instead.
*
* Note:
* SolvAxis recommends that you do not use deprecated procedures in new applications.
* Support for deprecated features is for backward compatibility only.
*
*________________________________________________________________________________
*
*/

  /*************** InsertHistorique ******************************************/
  procedure InsertHistorique(
    aPcJobId        in PCS.PC_JOB.PC_JOB_ID%type
  , aPcCompId       in PCS.PC_COMP.PC_COMP_ID%type
  , aUpdateMode     in number
  , aUpdateDay      in varchar2
  , aTime           in float
  , aJobNumber      in number
  , aException      in number
  , aRunManual      in number
  , aCustomInterval in date default null
  , aErrMessage     in varchar2 default null
  )
  is
    pragma autonomous_transaction;

    --curseurs pour suppression historique individualisé
    cursor crJobHisto(aJobId PCS.PC_JOB.PC_JOB_ID%type)
    is
      select   JOH_LAST_EXECUTION
          from PCS.PC_JOB_HISTO
         where PC_JOB_ID = aJobId
      order by JOH_LAST_EXECUTION desc;

    --curseur pour récupération information user_jobs
    cursor crUserJobs(aJobNum number)
    is
      select THIS_DATE
           , NEXT_DATE
           , LAST_DATE
           , BROKEN
           , FAILURES
        from USER_JOBS
       where JOB = aJobNum;

    tplJobHisto   crJobHisto%rowtype;   --Elément pour garder l'information sur l'historique
    tplUserJobs   crUserJobs%rowtype;   --Date d'exécution
    oNextExec     date;   --prochaine date d'exécution ou intervalle
    oDatehisto    date                                            default null;   --date de suppression de l'historique
    nCntRec       pls_integer;   --Compteur pour les éléments d'historique
    cJobStatus    PCS.PC_JOB.C_PC_JOB_STATUS%type;   --status du job
    nJobDelay     PCS.PC_JOB.JOB_LOG_RETENTION_DELAY%type;
    cJobDelayType PCS.PC_JOB.C_PC_JOB_RETENTION_DELAY_UNIT%type;
  begin
    --ouverture du curseur pour récupération des infos de user_jobs
    open crUserJobs(aJobNumber);

    fetch crUserJobs
     into tplUserJobs;

    --si exception alors prochaine date calcuée comme suit this_date +2**(Failures+1)min
    if     (aException = 1)
       and (tplUserJobs.FAILURES < 15) then
    --  oNextExec  := greatest(tplUserJobs.THIS_DATE +(power(2, tplUserJobs.FAILURES + 1) / 1440), tplUserJobs.NEXT_DATE);
      oNextExec  := tplUserJobs.NEXT_DATE + (tplUserJobs.NEXT_DATE - tplUserJobs.LAST_DATE);
    elsif(aException = 1) then
      oNextExec  := to_date('01.01.4000', 'DD.MM.YYYY');
    elsif aUpdateMode = 0 then   --journalier
      oNextExec  := GetDateDaily(aTime);
    elsif aUpdateMode = 1 then   --hebdomadaire
      oNextExec  := GetDateWeekly(aTime, aUpdateDay);
    elsif aUpdateMode = 2 then   --mensuel
      oNextExec  := GetDateMonthly(aTime);
    elsif aUpdateMode = 3 then   --Fin de mois
      oNextExec  := GetDateEndOfMonth(aTime);
    elsif aUpdateMode = 4 then   --Une seule fois la prochaine date d'execution est égale à la date actuelle
      oNextExec  := tplUserJobs.THIS_DATE;
    elsif aUpdateMode = 5 then   --Individualisation
      oNextExec  := aCustomInterval;
    end if;

    --caclul du status du job
    if (tplUserJobs.BROKEN = 'Y') then
      cJobStatus  := 'BROKEN';
    elsif     (aException = 1)
          and (tplUserJobs.FAILURES < 15) then
      cJobStatus  := 'ERROR';
    elsif(aException = 1) then
      cJobStatus  := 'BROKEN';
    elsif(aUpdateMode = 4) then
      cJobStatus  := 'INACTIVE';
    else
      cJobStatus  := 'ACTIVE';
    end if;

    --suppression historique du job, vérifier le type et le délai de conservation
    --  types de délais : 99 -> 100 dernières exécutions gardées
    --                    01 -> Délai donné en minutes
    --                    02 -> Délai donné en heures
    --                    03 -> Délai donné en jours
    --                    04 -> Délai donné en mois
    select JOB.C_PC_JOB_RETENTION_DELAY_UNIT
         , JOB.JOB_LOG_RETENTION_DELAY
      into cJobDelayType
         , nJobDelay
      from PCS.PC_JOB JOB
     where PC_JOB_ID = aPcJobId;

    if cJobDelayType = '01' then
      --minutes
      delete from PCS.PC_JOB_HISTO
            where PC_JOB_ID = aPcJobId
              and JOH_LAST_EXECUTION <(sysdate -(nJobDelay /(24 * 60) ) );
    elsif cJobDelayType = '02' then
      --heures
      delete from PCS.PC_JOB_HISTO
            where PC_JOB_ID = aPcJobId
              and JOH_LAST_EXECUTION <(sysdate -(nJobDelay / 24) );
    elsif cJobDelayType = '03' then
      --jours
      delete from PCS.PC_JOB_HISTO
            where PC_JOB_ID = aPcJobId
              and JOH_LAST_EXECUTION <(sysdate - nJobDelay);
    elsif cJobDelayType = '04' then
      --mois
      delete from PCS.PC_JOB_HISTO
            where PC_JOB_ID = aPcJobId
              and JOH_LAST_EXECUTION < add_months(sysdate, -nJobDelay);
    else
      --99 dernières exécutions gardées
      nCntRec  := 0;

      open crJobHisto(aPcJobId);

      fetch crJobHisto
       into tplJobHisto;

      if crJobHisto%found then
        while(crJobHisto%found)
         and (nCntRec < nJobDelay) loop
          oDateHisto  := tplJobHisto.JOH_LAST_EXECUTION;
          nCntRec     := nCntRec + 1;

          fetch crJobHisto
           into tplJobHisto;
        end loop;

        --si il y a plus de nJobDelay records, suppression
        if     (nCntRec = nJobDelay)
           and (oDateHisto is not null) then
          delete from PCS.PC_JOB_HISTO
                where PC_JOB_ID = aPcJobId
                  and JOH_LAST_EXECUTION <= oDateHisto;
        elsif(nCntRec = 0) then
          --supprimer l'historique complet, car on ne doit garder que la dernière exécution
          delete from PCS.PC_JOB_HISTO
                where PC_JOB_ID = aPcJobId;
        end if;
      end if;

      close crJobHisto;
    end if;

    --insertion du nouvel élément d'historique
    if    not(aPcCompId > 0)
       or (aPcCompId is null) then
      insert into PCS.PC_JOB_HISTO
                  (PC_JOB_HISTO_ID
                 , PC_JOB_ID
                 , JOH_LAST_EXECUTION
                 , JOH_LAST_ELAP_TIME
                 , JOH_NEXT_EXECUTION
                 , JOH_LAUNCH_ERROR
                 , JOH_ERROR_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (PCS.INIT_ID_SEQ.nextval
                 , aPcJobId
                 , tplUserJobs.THIS_DATE
                 , (sysdate - tplUserJobs.THIS_DATE) *(24 * 60 * 60)
                 , oNextExec
                 , aException
                 , aErrMessage
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI2
                  );
    else
      insert into PCS.PC_JOB_HISTO
                  (PC_JOB_HISTO_ID
                 , PC_COMP_ID
                 , PC_JOB_ID
                 , JOH_LAST_EXECUTION
                 , JOH_LAST_ELAP_TIME
                 , JOH_NEXT_EXECUTION
                 , JOH_LAUNCH_ERROR
                 , JOH_ERROR_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (PCS.INIT_ID_SEQ.nextval
                 , aPcCompId
                 , aPcJobId
                 , tplUserJobs.THIS_DATE
                 , (sysdate - tplUserJobs.THIS_DATE) *(24 * 60 * 60)
                 , oNextExec
                 , aException
                 , aErrMessage
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI2
                  );
    end if;

    --mise à jour de la prochaine date d'exécution, du status et du numéro du job (cas d'un intervalle nul)
    update PCS.PC_JOB JOB1
       set JOB1.JOB_NEXT_EXECUTION = oNextExec
         , JOB1.JOB_NUMBER = decode(aException, 0, decode(aUpdateMode, 4, null, aJobNumber), aJobNumber)
         , JOB1.C_PC_JOB_STATUS = cJobStatus
     where JOB1.PC_JOB_ID = aPcJobId;

    --**ajouter ici le code pour l'envoie d'e-mail, appel à une fonction ...
    close crUserJobs;

    commit;   --commit pour valider la transaction autonome
  end InsertHistorique;

/*************** GetDateDaily **********************************************/
  function GetDateDaily(aHour in number, aDateReference in date default sysdate)
    return date
  is
    result date;
    lnHours number;
    lDate date;
  begin
    if aDateReference < sysdate then
      lDate := sysdate;
    else
      lDate := aDateReference;
    end if;
    --on teste si l'heure est passée sinon, exécution même jour
    lnHours  := (trunc(lDate) +(aHour / 24) ) - lDate;

    if lnHours > 0 then
      result  := trunc(lDate) +(aHour / 24);
    else
      result  := trunc(lDate + 1) +(aHour / 24);
    end if;

    return result;
  end GetDateDaily;

/*************** GetDateWeekly *********************************************/
  function GetDateWeekly(aHour in number, aupdateDay in varchar2, aDateReference in date default sysdate)
    return date
  is
    result date;
    lnDays  number;
    lDate date;
  begin
    if aDateReference < sysdate then
      lDate := sysdate;
    else
      lDate := aDateReference;
    end if;

    lnDays  := (next_day(trunc(lDate), aupdateDay) +(aHour / 24) ) - lDate;

    if lnDays > 7 then
      result  := next_day(trunc(lDate - 1), aupdateDay) +(aHour / 24);
    else
      result  := next_day(trunc(lDate), aupdateDay) +(aHour / 24);
    end if;

    return result;
  end GetDateWeekly;

  /*************** GetDateMonthly ********************************************/
  function GetDateMonthly(aHour in number, aDateReference in date default sysdate)
    return date
  is
    lcorrectedDate date;
    result date;
  begin

    lcorrectedDate := trunc(aDateReference) +(aHour / 24);

    while lcorrectedDate <= sysdate loop
      lcorrectedDate := add_months(lcorrectedDate, 1);
    end loop;
    result := lcorrectedDate;


    return result;
  end GetDateMonthly;

  /*************** GetDateEndOfMonth *****************************************/
  function GetDateEndOfMonth(aHour in number, aDateReference in date default sysdate)
    return date
  is
    result date;
    lnDays  number;
    lDate date;
  begin
    if aDateReference < sysdate then
      lDate := sysdate;
    else
      lDate := aDateReference;
    end if;

    lnDays  := (last_day(trunc(lDate) ) +(aHour / 24) ) - lDate;

    if lnDays > 0 then
      result  := last_day(trunc(lDate) ) +(aHour / 24);
    else
      result  := last_day(add_months(trunc(lDate), 1) ) +(aHour / 24);
    end if;

    return result;
  end GetDateEndOfMonth;

/*************** GetDateHours **********************************************/
  function GetDateHours(
    aHour1         in number
  , aHour2         in number default 100
  , aHour3         in number default 100
  , aHour4         in number default 100
  , aHour5         in number default 100
  , aHour6         in number default 100
  , aHour7         in number default 100
  , aHour8         in number default 100
  , aHour9         in number default 100
  , aHour10        in number default 100
  , aDateReference in date default sysdate
  )
    return date
  is
    result   date;   --résultat
    lDate    date;
    oHourNow number;   --heure actuellle
    oHourMin number;   --Heure minimale
    bStop    boolean;   --Indique que le résultat à été trouvé
    nBreak   number;   --Nombre de boucles avant de stopper
    nHour1   number;   --1ère heure d'exécution pour modif
    nHour2   number;   --2ème heure d'exécution pour modif
    nHour3   number;   --3ème heure d'exécution pour modif
    nHour4   number;   --4ème heure d'exécution pour modif
    nHour5   number;   --5ème heure d'exécution pour modif
    nHour6   number;   --6ème heure d'exécution pour modif
    nHour7   number;   --7ème heure d'exécution pour modif
    nHour8   number;   --8ème heure d'exécution pour modif
    nHour9   number;   --9ème heure d'exécution pour modif
    nHour10  number;   --10ème heure d'exécution pour modif
  begin
    if aDateReference < sysdate then
      lDate := sysdate;
    else
      lDate := aDateReference;
    end if;

    --indique qu'il faut stopper la boucle
    bStop     := false;
    nBreak    := 0;
    --récupération des heures d'exécution dans des variables pour pouvoir les modifier
    nHour1    := aHour1;
    nHour2    := aHour2;
    nHour3    := aHour3;
    nHour4    := aHour4;
    nHour5    := aHour5;
    nHour6    := aHour6;
    nHour7    := aHour7;
    nHour8    := aHour8;
    nHour9    := aHour9;
    nHour10   := aHour10;
    --récupération de l'heure actuelle et initialisation heure minimale
    --on ajoute 1 seconde pour garantir dans le cas de la simulation que (oHourMin / 24) > oHourNow soit faux pour oHourMin = oHourNow
    oHourNow  := lDate - trunc(lDate) + 1/(60*60*24);
    oHourMin  := 0;

    --on boucle tant que l'on ne trouve pas l'heure la plus petite ou que toutes sont égales à 100
    while(oHourMin <> 100)
     and not bStop
     and (nBreak < 15) loop
      --recherche de l'heure minimale
      oHourMin  := least(nHour1, nHour2, nHour3, nHour4, nHour5, nHour6, nHour7, nHour8, nHour9, nHour10);

      --on teste si il s'agit d'une heure valide
      if     ( (oHourMin / 24) > oHourNow)
         and (oHourMin >= 0)
         and (oHourMin <= 24) then
        result  := trunc(lDate) +(oHourMin / 24);
        bStop   := true;
      else
        --mettre la date minimale à 100
        if oHourMin = nHour1 then
          nHour1  := 100;
        elsif oHourMin = nHour2 then
          nHour2  := 100;
        elsif oHourMin = nHour3 then
          nHour3  := 100;
        elsif oHourMin = nHour4 then
          nHour4  := 100;
        elsif oHourMin = nHour5 then
          nHour5  := 100;
        elsif oHourMin = nHour6 then
          nHour6  := 100;
        elsif oHourMin = nHour7 then
          nHour7  := 100;
        elsif oHourMin = nHour8 then
          nHour8  := 100;
        elsif oHourMin = nHour9 then
          nHour9  := 100;
        elsif oHourMin = nHour10 then
          nHour10  := 100;
        end if;

        --on prend la plus petite date pour le lendemain si le minimum vaut 100
        if oHourMin = 100 then
          oHourMin  := least(aHour1, aHour2, aHour3, aHour4, aHour5, aHour6, aHour7, aHour8, aHour9, aHour10);

          if     (oHourMin >= 0)
             and (oHourMin <= 24)
             and not bStop then
            result  := trunc(lDate) + 1 +(oHourMin / 24);
            bStop   := true;
          end if;
        end if;
      end if;

      nBreak    := nBreak + 1;
    end loop;

    --si sortie normale de la boucle alors resultat ok, sinon null
    if bStop then
      return result;
    else
      return null;
    end if;
  end GetDateHours;

  /*************** GetDateDayHour ********************************************/
  function GetDateDayHour(
    aDay1          in varchar2
  , aHour1         in number
  , aDay2          in varchar2
  , aHour2         in number
  , aDay3          in varchar2 default null
  , aHour3         in number default null
  , aDay4          in varchar2 default null
  , aHour4         in number default null
  , aDay5          in varchar2 default null
  , aHour5         in number default null
  , aDay6          in varchar2 default null
  , aHour6         in number default null
  , aDay7          in varchar2 default null
  , aHour7         in number default null
  , aDateReference in date default sysdate
  )
    return date
  is
    --variable qui contient le resultat
    result        date;

    --temps avant les prochaines exécutions
    oDate1        date;
    oDate2        date;
    oDate3        date;
    oDate4        date;
    oDate5        date;
    oDate6        date;
    oDate7        date;
    --meilleur intervalle pour calcul de date
    nBestInterval number;
    --Jours en anglais, ensuite n'accepter que les jours dans ce format
    cDay1         varchar2(15);
    cDay2         varchar2(15);
    cDay3         varchar2(15);
    cDay4         varchar2(15);
    cDay5         varchar2(15);
    cDay6         varchar2(15);
    cDay7         varchar2(15);
    --indique si les dates sont correctes
    nDayOk1       number(1);
    nDayOk2       number(1);
    nDayOk3       number(1);
    nDayOk4       number(1);
    nDayOk5       number(1);
    nDayOk6       number(1);
    nDayOk7       number(1);
  begin
    --conversion des jours
    select decode(upper(aDay1)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay1)
                 )
      into cDay1
      from dual;

    select decode(upper(aDay2)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay2)
                 )
      into cDay2
      from dual;

    select decode(upper(aDay3)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay3)
                 )
      into cDay3
      from dual;

    select decode(upper(aDay4)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay4)
                 )
      into cDay4
      from dual;

    select decode(upper(aDay5)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay5)
                 )
      into cDay5
      from dual;

    select decode(upper(aDay6)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay6)
                 )
      into cDay6
      from dual;

    select decode(upper(aDay7)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay7)
                 )
      into cDay7
      from dual;

    --testes des jours
    if     cDay1 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour1 >= 0)
       and (aHour1 <= 24) then
      nDayOk1  := 1;
    else
      nDayOk1  := 0;
    end if;

    if     cDay2 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour2 >= 0)
       and (aHour2 <= 24) then
      nDayOk2  := 1;
    else
      nDayOk2  := 0;
    end if;

    if     cDay3 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour3 >= 0)
       and (aHour3 <= 24) then
      nDayOk3  := 1;
    else
      nDayOk3  := 0;
    end if;

    if     cDay4 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour4 >= 0)
       and (aHour4 <= 24) then
      nDayOk4  := 1;
    else
      nDayOk4  := 0;
    end if;

    if     cDay5 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour5 >= 0)
       and (aHour5 <= 24) then
      nDayOk5  := 1;
    else
      nDayOk5  := 0;
    end if;

    if     cDay6 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour6 >= 0)
       and (aHour6 <= 24) then
      nDayOk6  := 1;
    else
      nDayOk6  := 0;
    end if;

    if     cDay7 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
       and (aHour7 >= 0)
       and (aHour7 <= 24) then
      nDayOk7  := 1;
    else
      nDayOk7  := 0;
    end if;

    --si les 2 premières dates sont fausses retourner null
    if     (nDayOk1 = 1)
       and (nDayOk2 = 1) then
      --recherche de la prochaine date d'exécution avec getdateweekly
      oDate1  := GetDateWeekly(aHour1, cDay1, aDateReference);
      oDate2  := GetDateWeekly(aHour2, cDay2, aDateReference);

      --définition des dates d'exécution
      if nDayOk3 = 0 then
        oDate3  := null;
      else
        oDate3  := GetDateWeekly(aHour3, cDay3, aDateReference);
      end if;

      if nDayOk4 = 0 then
        oDate4  := null;
      else
        oDate4  := GetDateWeekly(aHour4, cDay4, aDateReference);
      end if;

      if nDayOk5 = 0 then
        oDate5  := null;
      else
        oDate5  := GetDateWeekly(aHour5, cDay5, aDateReference);
      end if;

      if nDayOk6 = 0 then
        oDate6  := null;
      else
        oDate6  := GetDateWeekly(aHour6, cDay6, aDateReference);
      end if;

      if nDayOk7 = 0 then
        oDate7  := null;
      else
        oDate7  := GetDateWeekly(aHour7, cDay7, aDateReference);
      end if;

      --on sélectionne la date la plus petite
      select least(nvl(oDate1, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate2, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate3, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate4, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate5, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate6, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate7, to_date('01.01.4000', 'DD.MM.YYYY') )
                  )
        into result
        from dual;

      --on teste si la date est différente du 1.1.4000, si non retourne null
      if result <> to_date('01.01.4000', 'DD.MM.YYYY') then
        return result;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end GetDateDayHour;

  /*************** GetDateWeekDays *******************************************/
  function GetDateWeekDays(
    aHour          in number
  , aDay1          in varchar2
  , aDay2          in varchar2 default null
  , aDay3          in varchar2 default null
  , aDay4          in varchar2 default null
  , aDay5          in varchar2 default null
  , aDay6          in varchar2 default null
  , aDay7          in varchar2 default null
  , aDateReference in date default sysdate
  )
    return date
  is
    --variable qui contient le resultat
    result  date;
    --jours en string
    cDay1   varchar2(15);
    cDay2   varchar2(15);
    cDay3   varchar2(15);
    cDay4   varchar2(15);
    cDay5   varchar2(15);
    cDay6   varchar2(15);
    cDay7   varchar2(15);
    --indique si les jours sont ok
    nDayOk1 number(1);
    nDayOk2 number(1);
    nDayOk3 number(1);
    nDayOk4 number(1);
    nDayOk5 number(1);
    nDayOk6 number(1);
    nDayOk7 number(1);
    --indique si l'heure est en ordre
    nHourOk number(1);
    --temps avant les prochaines exécutions
    oDate1  date;
    oDate2  date;
    oDate3  date;
    oDate4  date;
    oDate5  date;
    oDate6  date;
    oDate7  date;
  begin
    --conversion des jours
    select decode(upper(aDay1)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay1)
                 )
      into cDay1
      from dual;

    select decode(upper(aDay2)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay2)
                 )
      into cDay2
      from dual;

    select decode(upper(aDay3)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay3)
                 )
      into cDay3
      from dual;

    select decode(upper(aDay4)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay4)
                 )
      into cDay4
      from dual;

    select decode(upper(aDay5)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay5)
                 )
      into cDay5
      from dual;

    select decode(upper(aDay6)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay6)
                 )
      into cDay6
      from dual;

    select decode(upper(aDay7)
                , 'LUNDI', 'MONDAY'
                , 'MONTAG', 'MONDAY'
                , 'MARDI', 'TUESDAY'
                , 'DIENSTAG', 'TUESDAY'
                , 'MERCREDI', 'WEDNESDAY'
                , 'MITTWOCH', 'WEDNESDAY'
                , 'JEUDI', 'THURSDAY'
                , 'DONNERSTAG', 'THURSDAY'
                , 'VENDREDI', 'FRIDAY'
                , 'FREITAG', 'FRIDAY'
                , 'SAMEDI', 'SATURDAY'
                , 'SAMSTAG', 'SATURDAY'
                , 'DIMANCHE', 'SUNDAY'
                , 'SONTAG', 'SUNDAY'
                , upper(aDay7)
                 )
      into cDay7
      from dual;

    --test des heures
    if     (aHour >= 0)
       and (aHour <= 24) then
      nHourOk  := 1;
    else
      nHourOk  := 0;
    end if;

    --test des jours
    if cDay1 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk1  := 1;
    else
      nDayOk1  := 0;
    end if;

    if cDay2 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk2  := 1;
    else
      nDayOk2  := 0;
    end if;

    if cDay3 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk3  := 1;
    else
      nDayOk3  := 0;
    end if;

    if cDay4 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk4  := 1;
    else
      nDayOk4  := 0;
    end if;

    if cDay5 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk5  := 1;
    else
      nDayOk5  := 0;
    end if;

    if cDay6 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk6  := 1;
    else
      nDayOk6  := 0;
    end if;

    if cDay7 in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
      nDayOk7  := 1;
    else
      nDayOk7  := 0;
    end if;


    --si les 2 premières dates sont fausses retourner null
    if     (nDayOk1 = 1)
       and (nHourOk = 1) then
      --recherche de la prochaine date d'exécution avec getdateweekly
      oDate1  := GetDateWeekly(aHour, cDay1, aDateReference);

      --définition des dates d'exécution
      if nDayOk2 = 0 then
        oDate2  := null;
      else
        oDate2  := GetDateWeekly(aHour, cDay2, aDateReference);
      end if;

      if nDayOk3 = 0 then
        oDate3  := null;
      else
        oDate3  := GetDateWeekly(aHour, cDay3, aDateReference);
      end if;

      if nDayOk4 = 0 then
        oDate4  := null;
      else
        oDate4  := GetDateWeekly(aHour, cDay4, aDateReference);
      end if;

      if nDayOk5 = 0 then
        oDate5  := null;
      else
        oDate5  := GetDateWeekly(aHour, cDay5, aDateReference);
      end if;

      if nDayOk6 = 0 then
        oDate6  := null;
      else
        oDate6  := GetDateWeekly(aHour, cDay6, aDateReference);
      end if;

      if nDayOk7 = 0 then
        oDate7  := null;
      else
        oDate7  := GetDateWeekly(aHour, cDay7, aDateReference);
      end if;

      --on sélectionne la date la plus petite
      select least(nvl(oDate1, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate2, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate3, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate4, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate5, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate6, to_date('01.01.4000', 'DD.MM.YYYY') )
                 , nvl(oDate7, to_date('01.01.4000', 'DD.MM.YYYY') )
                  )
        into result
        from dual;

      --on teste si la date est différente du 1.1.4000, si non retourne null
      if result <> to_date('01.01.4000', 'DD.MM.YYYY') then
        return result;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end GetDateWeekDays;

  /*************** GetDateInterval *******************************************/
  function GetDateInterval(
    aHourBegin     in number
  , aHourEnd       in number
  , aInterval      in number
  , aDayBegin      in varchar2 default null
  , aDayEnd        in varchar2 default null
  , aDateReference in date default sysdate
  )
    return date
  is
    --variable qui contient le resultat
    result        date;
    --variable de date de référence
    lDate         date;
    --jours en varchar2
    cDayBegin     varchar2(15);
    cDayEnd       varchar2(15);
    --heures pour modifs, si heure de départ égal heure d'arrivée, alors intervalle égal toute la journée
    nHourBegin    number;
    nHourEnd      number;
    --Flags qui indiquent si les jour et les heures sont correctes
    nDayBeginOk   number(1);
    nDayEndOk     number(1);
    --arrêt de la boucle
    bStop         boolean;
    nBreak        number;
    --indique si les heures sont correctes
    nHourBeginOk  number(1);
    nHourEndOk    number(1);
    --indique le cas auquel on a à faire, 1 -> jour début,fin définis, 2->jours début,fin indéfinis, 3-> jour début = fin
    nCase         number(1);
    --indique que l'intervalle est correcte
    nIntervalOk   number(1);
    --calcul de la prochaine date
    nMultInterval integer;   --facteur qui multiplie l'intervalle
    nNextHour     number;   --prochaine heure calculée
    nTmpHour      number;   --variable temporaire pour calcul heure
    nDaysInterv   number;   --nombre de jours séparant le début et fin d'intervalle
    nIncDays      integer;   --incrément en jours
    oDateBegin    date;   --date de début d'exécution pour calcul prochaine date
    oDateEnd      date;   --date de fin d'exécution pour le calcul de la prochaine date
    oDateExec     date;   --pour le cas ou la date de début est égale à la date de fin
  begin
    result         := null;
    --initialisation
    nDayBeginOK    := 0;
    nDayEndOK      := 0;
    bStop          := false;
    nBreak         := 0;
    --reprise des éléments dans des variables locales
    cDayBegin      := aDayBegin;
    cDayEnd        := aDayEnd;
    nHourBegin     := aHourBegin;
    nHourEnd       := aHourEnd;

    --si les deux heures sont identiques alors, on définit l'intervalle pour toute la journée
    if nHourEnd = nHourBegin then
      nHourBegin  := 0;
      nHourEnd    := 24;
    end if;

    --recherche si les heures sont valides
    select decode(least(nHourBegin, 0), 0, 1, 0) * decode(greatest(24, nHourBegin), 24, 1, 0)
      into nHourBeginOk
      from dual;

    select decode(least(nHourEnd, 0), 0, 1, 0) * decode(greatest(24, nHourEnd), 24, 1, 0)
      into nHourEndOk
      from dual;

    if     not(aDateReference is null)
       and (nHourBeginOk = 1)
       and (nHourEndOk = 1)
       and (aInterval > 0) then
      if (nHourEnd >= nHourBegin) then
        if     not(cDayBegin is null)
           and not(cDayEnd is null) then
          select decode(upper(aDayBegin)
                      , 'LUNDI', 'MONDAY'
                      , 'MONTAG', 'MONDAY'
                      , 'MARDI', 'TUESDAY'
                      , 'DIENSTAG', 'TUESDAY'
                      , 'MERCREDI', 'WEDNESDAY'
                      , 'MITTWOCH', 'WEDNESDAY'
                      , 'JEUDI', 'THURSDAY'
                      , 'DONNERSTAG', 'THURSDAY'
                      , 'VENDREDI', 'FRIDAY'
                      , 'FREITAG', 'FRIDAY'
                      , 'SAMEDI', 'SATURDAY'
                      , 'SAMSTAG', 'SATURDAY'
                      , 'DIMANCHE', 'SUNDAY'
                      , 'SONTAG', 'SUNDAY'
                      , upper(aDayBegin)
                       )
            into cDayBegin
            from dual;

          select decode(upper(aDayEnd)
                      , 'LUNDI', 'MONDAY'
                      , 'MONTAG', 'MONDAY'
                      , 'MARDI', 'TUESDAY'
                      , 'DIENSTAG', 'TUESDAY'
                      , 'MERCREDI', 'WEDNESDAY'
                      , 'MITTWOCH', 'WEDNESDAY'
                      , 'JEUDI', 'THURSDAY'
                      , 'DONNERSTAG', 'THURSDAY'
                      , 'VENDREDI', 'FRIDAY'
                      , 'FREITAG', 'FRIDAY'
                      , 'SAMEDI', 'SATURDAY'
                      , 'SAMSTAG', 'SATURDAY'
                      , 'DIMANCHE', 'SUNDAY'
                      , 'SONTAG', 'SUNDAY'
                      , upper(aDayEnd)
                       )
            into cDayEnd
            from dual;

          if     cDayBegin in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')
             and cDayEnd in('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') then
            nCase  := 1;
          else
            nCase  := 0;
          end if;
        else
          --on définit les jours de début et fin égaux a null
          cDayBegin  := null;
          cDayEnd    := null;
          nCase      := 2;
        end if;

        if     (cDayBegin = cDayEnd)
           and not(cDayBegin is null) then
          --cas spécial ou on veut que l'intervalle soit pour une seule journée
          nCase  := 3;
        end if;
      else
        --heure de début > heure de fin, exple de 22h à 6h
        nCase  := 4;
      end if;
    end if;

    --on teste si l'intervalle est correct
    if nCase in(1, 2, 3, 4) then
      nIntervalOk  := 1;
    else
      nIntervalOk  := 0;
    end if;

    --initialiation de la prochaine heure et du multiplicateur d'intervalle
    nNextHour      := 0;
    nMultInterval  := 0;
    nIncDays       := 0;

    if aDateReference < sysdate then
      lDate := sysdate;
    else
      lDate := aDateReference;
    end if;

    if nIntervalOK = 1 then
      if nCase = 1 then
        --jours de début et fin définis 2 jours différents
        nDaysInterv  := next_day(trunc(lDate), cDayEnd) +( (nHourEnd / 24) - aInterval) - lDate;

        if     (nDaysInterv > 0)
           and (nDaysInterv <= 7) then
          oDateEnd  := next_day(trunc(lDate), cDayEnd);
        elsif nDaysInterv > 7 then
          oDateEnd  := trunc(lDate);
        else
          nDaysInterv  := -1;
        end if;

        if nDaysInterv <> -1 then
          if next_day(trunc(lDate), cDayBegin) - trunc(lDate) = 7 then
            oDateBegin  := trunc(lDate);
          else
            oDateBegin  := next_day(trunc(lDate), cDayBegin);
          end if;

          --on teste si la date est valable
          nDaysInterv  := oDateEnd - oDateBegin;

          if nDaysInterv < 0 then
            oDateBegin   := oDateBegin - 7;
            nDaysInterv  := oDateEnd - oDateBegin;
          end if;

          if nDaysInterv >= 0 then
            while(nNextHour <= 24)
             and (nBreak < 20000)
             and not bStop loop
              nTmpHour  := oDateBegin + nIncDays +(nHourBegin / 24) +(nMultInterval * aInterval) - lDate;

              if nTmpHour > 0 then
                nNextHour  := (nHourBegin / 24) +(nMultInterval * aInterval);
                nTmpHour   := (nHourEnd / 24) - nNextHour;

                if nTmpHour > 0 then
                  result  := oDateBegin + nIncDays + nNextHour;
                  bStop   := true;
                else
                  nMultInterval  := nMultInterval + 1;

                  if ( (nHourBegin / 24) +(nMultInterval * aInterval) ) >(nHourEnd / 24) then
                    nIncDays       := nIncDays + 1;
                    nMultInterval  := 0;

                    if nIncDays > nDaysInterv then
                      bStop  := true;
                    end if;
                  end if;
                end if;
              else
                bStop          := false;
                nMultInterval  := nMultInterval + 1;

                if ( (nHourBegin / 24) +(nMultInterval * aInterval) ) >(nHourEnd / 24) then
                  nIncDays       := nIncDays + 1;
                  nMultInterval  := 0;

                  if nIncDays > nDaysInterv then
                    bStop  := true;
                  end if;
                end if;
              end if;

              nBreak    := nBreak + 1;
            end loop;
          end if;
        end if;
      elsif nCase = 2 then
        --jour de début et jour de fin non définis, intervalle pour tous les jours
        while(nNextHour <= 24)
         and (nBreak < 20000)
         and not bStop loop
          nTmpHour  := trunc(lDate) +(nHourBegin / 24) +(nMultInterval * aInterval) - lDate;

          if nTmpHour > 0 then
            nNextHour  := (nHourBegin / 24) +(nMultInterval * aInterval);
            nTmpHour   := (nHourEnd / 24) - nNextHour;

            if nTmpHour > 0 then
              result  := trunc(lDate) + nNextHour;
              bStop   := true;
            else
              --cas ou on est arrivé à la fin de l'intervalle, prochaine exécution doit avoir lieu le jour suivant
              result  := trunc(lDate) + 1 +(nHourBegin / 24);
              bStop   := true;
            end if;
          else
            nMultInterval  := nMultInterval + 1;
            bStop          := false;
          end if;

          nBreak    := nBreak + 1;
        end loop;
      elsif nCase = 3 then
        --même jour de début et de fin
        nDaysInterv  := next_day(trunc(lDate), cDayEnd) +( (nHourEnd / 24) - aInterval) - lDate;

        if nDaysInterv > 7 then
          oDateExec  := trunc(lDate);
        else
          oDateExec  := next_day(trunc(lDate), cDayEnd);
        end if;

        --parcours normal comme si les jours n'étaient pas définis
        while(nNextHour <= 24)
         and (nBreak < 20000)
         and not bStop loop
          nTmpHour  := trunc(oDateExec) +(nHourBegin / 24) +(nMultInterval * aInterval) - lDate;

          if nTmpHour > 0 then
            nNextHour  := (nHourBegin / 24) +(nMultInterval * aInterval);
            --calcul pour savoir si l'heure est comprise dans l'intervalle
            nTmpHour   := (nHourEnd / 24) - nNextHour;

            if nTmpHour > 0 then
              result  := trunc(oDateExec) + nNextHour;
            else
              result  := trunc(oDateExec) + 7 +(nHourBegin / 24);
            end if;

            bStop      := true;
          else
            nMultInterval  := nMultInterval + 1;
            bStop          := false;
          end if;

          nBreak    := nBreak + 1;
        end loop;
      elsif nCase = 4 then
        --on prend le résultat en testant entre l'heure de début et minuit et entre minuit et l'heure de fin
        result  :=
          least(COM_JOB_FUNCTIONS.GetDateInterval(aHourBegin       => aHourBegin
                                                , aHourEnd         => 24
                                                , aInterval        => aInterval
                                                , aDayBegin        => aDayBegin
                                                , aDayEnd          => aDayEnd
                                                , aDateReference   => lDate
                                                 )
              , COM_JOB_FUNCTIONS.GetDateInterval(aHourBegin       => 0
                                                , aHourEnd         => aHourEnd
                                                , aInterval        => aInterval
                                                , aDayBegin        => aDayBegin
                                                , aDayEnd          => aDayEnd
                                                , aDateReference   => lDate
                                                 )
               );
      end if;
    end if;

    return result;
  end GetDateInterval;

  /*************** GetDateDayInterval ****************************************/
  function GetDateDayInterval(
    aHourBegin     in number
  , aHourEnd       in number
  , aInterval      in number
  , aDay1          in varchar2
  , aDay2          in varchar2 default null
  , aDay3          in varchar2 default null
  , aDay4          in varchar2 default null
  , aDay5          in varchar2 default null
  , aDay6          in varchar2 default null
  , aDay7          in varchar2 default null
  , aDateReference in date default sysdate
  )
    return date
  is
    result     date;   --résultat
    oNextDate1 date;   --prochaine date d'exécution pour le jour aDay1
    oNextDate2 date;   --prochaine date d'exécution pour le jour aDay2
    oNextDate3 date;   --prochaine date d'exécution pour le jour aDay3
    oNextDate4 date;   --prochaine date d'exécution pour le jour aDay4
    oNextDate5 date;   --prochaine date d'exécution pour le jour aDay5
    oNextDate6 date;   --prochaine date d'exécution pour le jour aDay4
    oNextDate7 date;   --prochaine date d'exécution pour le jour aDay5
  begin

    --on récupère les porchaines date d'exécution en utilisant le getdateinterval
    if not(aDay1 is null) then
      oNextDate1  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay1, aDay1, aDateReference);
    else
      oNextDate1  := null;
    end if;

    if not(aDay2 is null) then
      oNextDate2  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay2, aDay2, aDateReference);
    else
      oNextDate2  := null;
    end if;

    if not(aDay3 is null) then
      oNextDate3  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay3, aDay3, aDateReference);
    else
      oNextDate3  := null;
    end if;

    if not(aDay4 is null) then
      oNextDate4  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay4, aDay4, aDateReference);
    else
      oNextDate4  := null;
    end if;

    if not(aDay5 is null) then
      oNextDate5  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay5, aDay5, aDateReference);
    else
      oNextDate5  := null;
    end if;

    if not(aDay6 is null) then
      oNextDate6  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay6, aDay6, aDateReference);
    else
      oNextDate6  := null;
    end if;

    if not(aDay7 is null) then
      oNextDate7  := GetDateInterval(aHourBegin, aHourEnd, aInterval, aDay7, aDay7, aDateReference);
    else
      oNextDate7  := null;
    end if;

    --recherche de la date minimum
    select least(nvl(oNextDate1, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate2, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate3, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate4, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate5, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate6, to_date('01.01.4000', 'DD.MM.YYYY') )
               , nvl(oNextDate7, to_date('01.01.4000', 'DD.MM.YYYY') )
                )
      into result
      from dual;

    --on teste si la date est différente du 1.1.4000, si non retourne null
    if result <> to_date('01.01.4000', 'DD.MM.YYYY') then
      return result;
    else
      return null;
    end if;
  end GetDateDayInterval;

/*************** IsJobBroken ***********************************************/
  function IsJobBroken(aJobNumber in number, aNextExec in out date)
    return boolean
  is
    pragma autonomous_transaction;
    bBroken number(1);
  begin
    select decode(BROKEN, 'Y', 1, 0)
      into bBroken
      from USER_JOBS
     where JOB = aJobNumber;

    if bBroken = 1 then
      --date du broken -> mise à 01.01.4000
      aNextExec  := to_date('01.01.4000', 'DD.MM.YYYY');

      --mise à jour de la date dans la table pcs.pc_job
      update PCS.PC_JOB
         set JOB_NEXT_EXECUTION = to_date('01.01.4000', 'DD.MM.YYYY')
       where JOB_NUMBER = aJobNumber;

      commit;
      return true;
    else
      return false;
    end if;
  end IsJobBroken;

/*************** JobInitSession ********************************************/
  procedure JobInitSession(aJobId in PCS.PC_JOB.PC_JOB_ID%type)
  is
    bInitSession PCS.PC_JOB.JOB_INIT_SESSION%type;
    cSessionType PCS.PC_JOB.C_PC_JOB_SESSION_TYPE%type;
    cCom_Name    PCS.PC_COMP.COM_NAME%type;
    nCompId      PCS.PC_COMP.PC_COMP_ID%type;
    cUse_Name    PCS.PC_USER.USE_NAME%type;
    nUserId      PCS.PC_USER.PC_USER_ID%type;
    cObj_name    PCS.PC_OBJECT.OBJ_NAME%type             default null;
    nObjId       PCS.PC_OBJECT.PC_OBJECT_ID%type;
    cConName     PCS.PC_CONLI.CONNAME%type               default null;
    nConliId     PCS.PC_CONLI.PC_CONLI_ID%type;
    cErrorMsg    varchar2(4000);
  begin
    --récupération des informations relatives au job
    select JOB.JOB_INIT_SESSION
         , CPY.COM_NAME
         , JOB.JOB_USE_NAME
         , JOB.C_PC_JOB_SESSION_TYPE
         , JOB.JOB_OBJ_NAME
         , JOB.JOB_CONNAME
      into bInitSession
         , cCom_Name
         , cUse_Name
         , cSessionType
         , cObj_Name
         , cConName
      from PCS.PC_JOB JOB
         , PCS.PC_COMP CPY
     where JOB.PC_JOB_ID = aJobId
       and CPY.PC_COMP_ID(+) = JOB.PC_COMP_ID;

    if bInitSession = 1 then
      --initialisation de la session
      PCS.PC_I_LIB_SESSION.ClearSession;

      if cCom_Name is not null then
        -- Company
        begin
          select COM.PC_COMP_ID
            into nCompId
            from PCS.PC_COMP COM
           where COM.COM_NAME = cCom_Name;

          PCS.PC_I_LIB_SESSION.SetCompanyId(nCompId);
        exception
          when no_data_found then
            cErrorMsg  := cErrorMsg || 'unknown Company (' || cCom_Name || ')';
        end;
      end if;

      -- User (assign only USER_ID global variable)
      begin
        select use.PC_USER_ID
          into nUserId
          from PCS.PC_USER use
         where use.USE_NAME = cUse_Name;

        PCS.PC_I_LIB_SESSION.SetUserId(nUserId);
      exception
        when no_data_found then
          cErrorMsg  := cErrorMsg || ' unknown User (' || cUse_Name || ')';
      end;

      if cErrorMsg is null then
        -- Assigne toutes le variables globales qui touche l'utilisateur courant
        --
        --   USER_LANG_ID
        --   USER_NAME
        --   USERINI
        --   USERFREE1
        --   USERFREE2
        --
        PCS.PC_I_LIB_SESSION.SetUserId(PCS.PC_I_LIB_SESSION.GetUserId);
      end if;

      -- Object / Configuration's group
      /*
       Following cascade is done

       1 -> object (automatically sets configuration's group)
       2 -> when no object is passed as parameter, use configuration's group
       3 -> when no configuration's group is passed as parameter, use default configuration's group
       */
      if (upper(cSessionType) = 'OBJECT') then
        begin
          select OBJ.PC_OBJECT_ID
               , OBJ.PC_CONLI_ID
            into nObjId
               , nConliId
            from PCS.PC_OBJECT OBJ
           where OBJ.OBJ_NAME = cObj_Name;

          PCS.PC_I_LIB_SESSION.SetObjectId(nObjId);
          PCS.PC_I_LIB_SESSION.SetConliId(nConliId);
        exception
          when no_data_found then
            cErrorMsg  := cErrorMsg || ' unknown Object (' || cObj_Name || ')';
        end;
      elsif(upper(cSessionType) = 'CONLI') then
        begin
          -- 2. Configuration's group
          select CON.PC_CONLI_ID
            into nConliId
            from PCS.PC_CONLI CON
           where CON.CONNAME = cConName;

          PCS.PC_I_LIB_SESSION.SetConliId(nConliId);
        exception
          when no_data_found then
            cErrorMsg  := cErrorMsg || ' unknown Configuration''s group (' || cConName || ')';
        end;
      else
        -- 3. Default configuration's group
        PCS.PC_I_LIB_SESSION.SetConliId(PCS.PC_I_LIB_SESSION.GetDefaultConliId);

        if PCS.PC_I_LIB_SESSION.CONLI_ID is null then
          cErrorMsg  := cErrorMsg || ' no default Configuration''s group found';
        end if;
      end if;

      if cErrorMsg is not null then
        PCS.PC_I_LIB_SESSION.ClearSession;
        raise_application_error(-20000, 'Error ! Please check parameters, ' || trim(cErrorMsg) );
      end if;
    end if;
  end JobInitSession;

  /**
  * procedure createOneShotJob
  * Description
  *    Procedure de création d'un job à utilisation unique
  *    Pour création automatique depuis une application Pro-Concept
  * @created fp 06.03.2008
  * @lastUpdate
  * @public
  * @param in out aJobId : id du job à créer, si vide initialisé dans la procédure
  * @param out aJobNumber : numéro du job (donné par Oracle)
  * @param aDicjobType : type de job (dico libre)
  * @param aJobName : nom du job
  * @param aExecutionTime : heure d'exécution
  * @param aSqlCommand : bloc PLSQL à exécuter par le job
  * @param aCompId : ID de la société propriétaire du job
  * @param aDescription : description (facultatif)
  * @param aComment : commentaire (facultatif)
  * @param aJobKind : genre de job (Cpy,Env,EnvJava,EnvKma)
  * @param aJobRetentionDelayUnit : type de délai
  * @param aJobLogRetentionDelay : Délai conservation
  * @param aOwner : schéma
  * @param aPassword : mot de passe
  * @param aJobSessionType :
  * @param aInitSession : Initialisation automatique de la session
  * @param aUsername : Utilisateur
  * @param aConliName : Groupe de configuration
  * @param aObjName : Objet de gestion
  */
  procedure createOneShotJob(
    aJobId                 in out PCS.PC_JOB.PC_JOB_ID%type
  , aJobNumber             out    PCS.PC_JOB.JOB_NUMBER%type
  , aCompId                in     PCS.PC_JOB.PC_COMP_ID%type
  , aJobName               in     PCS.PC_JOB.JOB_NAME%type
  , aDicjobType            in     PCS.PC_JOB.DIC_PC_JOB_TYPE_ID%type
  , aExecutionTime         in     PCS.PC_JOB.JOB_NEXT_EXECUTION%type default sysdate
  , aSqlCommand            in     clob --PCS.PC_JOB.JOB_SQL%type
  , aSqlFormattedCommand   in     clob --PCS.PC_JOB.JOB_SQL%type default null
  , aDescription           in     PCS.PC_JOB.JOB_DESC%type default null
  , aComment               in     PCS.PC_JOB.JOB_COMMENT%type default null
  , aJobKind               in     PCS.PC_JOB.C_PC_JOB_KIND%type default 'Cpy'
  , aJobRetentionDelayUnit in     PCS.PC_JOB.C_PC_JOB_RETENTION_DELAY_UNIT%type default '99'
  , aJobLogRetentionDelay  in     PCS.PC_JOB.JOB_LOG_RETENTION_DELAY%type default '100'
  , aOwner                 in     PCS.PC_JOB.JOB_SCHEMA_OWNER%type default null
  , aPassword              in     PCS.PC_JOB.JOB_PASSWORD%type default null
  , aJobSessionType        in     PCS.PC_JOB.C_PC_JOB_SESSION_TYPE%type default null
  , aInitSession           in     PCS.PC_JOB.JOB_INIT_SESSION%type default 0
  , aUserName              in     PCS.PC_JOB.JOB_USE_NAME%type default null
  , aConliName             in     PCS.PC_JOB.JOB_CONNAME%type default null
  , aObjName               in     PCS.PC_JOB.JOB_OBJ_NAME%type default null
  )
  is
    pragma autonomous_transaction;
    vSql varchar2(32000);
  begin
    select nvl(aJobId, INIT_ID_SEQ.nextval)
      into aJobId
      from dual;
    vSql := aSqlFormattedCommand;
    insert into PCS.PC_JOB
                (PC_JOB_ID
               , JOB_NUMBER
               , PC_COMP_ID
               , JOB_NAME
               , DIC_PC_JOB_TYPE_ID
               , JOB_NEXT_EXECUTION
               , JOB_SQL
               , JOB_SQL_FORMATTED
               , JOB_DESC
               , JOB_COMMENT
               , C_PC_JOB_KIND
               , C_PC_JOB_RETENTION_DELAY_UNIT
               , C_PC_JOB_TYPE
               , C_PC_UPDATE_MODE
               , C_PC_JOB_STATUS
               , JOB_LOG_RETENTION_DELAY
               , JOB_SCHEMA_OWNER
               , JOB_PASSWORD
               , C_PC_JOB_SESSION_TYPE
               , JOB_INIT_SESSION
               , JOB_USE_NAME
               , JOB_CONNAME
               , JOB_OBJ_NAME
               , A_DATECRE
               , A_IDCRE
                )
         values (aJobId
               , aJobNumber
               , aCompId
               , aJobName
               , aDicjobType
               , aExecutionTime
               , aSqlCommand
               , nvl(aSqlFormattedCommand, aSqlCommand)
               , aDescription
               , aComment
               , aJobKind
               , aJobRetentionDelayUnit
               , 'AUTO'
               , 4
               , 'ACTIVE'
               , aJobLogRetentionDelay
               , aOwner
               , aPassword
               , aJobSessionType
               , aInitSession
               , aUserName
               , aConliName
               , aObjName
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
               commit;
    DBMS_JOB.SUBMIT(aJobNumber, vSql, greatest(aExecutionTime, sysdate) );
    update PCS.PC_JOB
      set JOB_NUMBER = aJobNumber
      where PC_JOB_ID = aJobId;
    commit;
  end createOneShotJob;

 procedure get_JobConnectionSettings( aJobId           in PCS.PC_JOB.PC_JOB_ID%type,
                                      aSchemaOwner    out PCS.PC_JOB.JOB_SCHEMA_OWNER%type,
                                      aSchemaPassword out PCS.PC_JOB.JOB_PASSWORD%type,
                                      aJobError       out varchar
 )
 is
  cJobSchemaOwner    PCS.PC_JOB.JOB_SCHEMA_OWNER%type;
  cJobPassword       PCS.PC_JOB.JOB_PASSWORD%type;
  cError             varchar2(30);
  cnNoDataFoundError constant varchar2(12) := 'DATANOTFOUND';
  cnUnkownError      constant varchar2(7) := 'UNKNOWN';
  cnSchemaNotExist   constant varchar2(15) := 'SCHEMANOTEXISTS';
  nRowCount          number;
 begin
  begin
    select (decode(upper(JOB.C_PC_JOB_KIND)
            , 'CPY', (select SCRDBOWNER
                      from PCS.PC_SCRIP SCR
                         , PCS.PC_COMP CPY
                     where CPY.PC_SCRIP_ID = SCR.PC_SCRIP_ID
                       and CPY.PC_COMP_ID = JOB.PC_COMP_ID)
            , JOB.JOB_SCHEMA_OWNER
                   )
            ) JOB_OWNER
         , (decode(upper(JOB.C_PC_JOB_KIND)
            , 'CPY', (select SCRDBOWNERPASSW
                        from PCS.PC_SCRIP SCR
                           , PCS.PC_COMP CPY
                       where CPY.PC_SCRIP_ID = SCR.PC_SCRIP_ID
                         and CPY.PC_COMP_ID = JOB.PC_COMP_ID)
           , JOB.JOB_PASSWORD
                   )
           ) JOB_PASSWORD
    into cJobSchemaOwner,
         cJobPassword
    from PCS.PC_JOB JOB
    where JOB.PC_JOB_ID = aJobId;
  exception
    when no_data_found then
    begin
      cJobSchemaOwner := '';
      cJobPassword := '';
      cError := cnNoDataFoundError;
    end;
    when others then
    begin
      cJobSchemaOwner := '';
      cJobPassword := '';
      cError := cnUnkownError;
    end;

  end;

  nRowCount := 0;
  begin
    SELECT Count(*)
    into nRowCount
    from all_users
    where username = cJobSchemaOwner;

    exception
    when no_data_found then
    begin
      nRowCount := 0;
    end;
  end;

  if (nRowCount = 0) then
    cError := cnSchemaNotExist;
  end if;

  aSchemaOwner := cJobSchemaOwner;
  aSchemaPassword := cJobPassword;
  aJobError := cError;

 end get_JobConnectionSettings;

end COM_JOB_FUNCTIONS;
