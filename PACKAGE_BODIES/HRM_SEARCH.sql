--------------------------------------------------------
--  DDL for Package Body HRM_SEARCH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_SEARCH" 
AS

function score_profile(vEmpId IN hrm_person.hrm_person_id%TYPE,
  vProfileId IN hrm_profile.hrm_profile_id%TYPE,
  method IN varchar2 default 'weighting') return number
is
  score number;
begin
  score := 0;
  if method = 'weighting' then
    select sum(nvl(b.c_comp_level_scale,0) * nvl(a.c_comp_interest_scale,0)) into score
    from
      (select a.hrm_person_id, b.hrm_competence_id, b.c_comp_level_scale,
         b.c_comp_interest_scale
       from
         hrm_person a,
         (select a.hrm_competence_id, a.c_comp_level_scale, a.c_comp_interest_scale
          from hrm_competence_link a
          where a.hrm_profile_id = vProfileId) b) a,
      hrm_competence_link b
    where
      a.hrm_person_id = vEmpid and
      (b.hrm_competence_id(+) = a.hrm_competence_id and
      b.hrm_person_id(+) = a.hrm_person_id)
    group by
      a.hrm_person_id;
  elsif method = 'sum' then
    select sum(nvl(b.c_comp_level_scale,0)) into score
    from
      (select a.hrm_person_id, b.hrm_competence_id, b.c_comp_level_scale,
         b.c_comp_interest_scale
       from
         hrm_person a,
         (select a.hrm_competence_id, a.c_comp_level_scale, a.c_comp_interest_scale
          from hrm_competence_link a
          where a.hrm_profile_id = vProfileId) b) a,
      hrm_competence_link b
    where
      a.hrm_person_id = vEmpId and
      (b.hrm_competence_id(+) = a.hrm_competence_id and
      b.hrm_person_id(+) = a.hrm_person_id)
    group by
      a.hrm_person_id;
  end if;
  return score;
  exception
    when others then return 0;
end;

function rate_profile(vProfileId IN hrm_profile.hrm_profile_id%TYPE,
  method IN varchar2 default 'weighting') return number
is
  score number;
begin
  score := 0;
  if method = 'weighting' then
    select
      Sum(nvl(a.c_comp_level_scale,0) * nvl(a.c_comp_interest_scale,0)) into Score
    from
      hrm_competence_link a
    where
      a.hrm_profile_id = vProfileId
    group by
      hrm_profile_id;
  elsif method = 'sum' then
    select
      Sum(nvl(a.c_comp_level_scale,0)) into Score
    from
      hrm_competence_link a
    where
      a.hrm_profile_id = vProfileId
    group by
      hrm_profile_id;
  end if;
  return score;
  exception
    when others then return 0;
end;

function score_job(vEmpId IN hrm_person.hrm_person_id%TYPE,
  vJobId IN hrm_job.hrm_job_id%TYPE,
  method IN varchar2 default 'weighting') return number
is
  score number;
begin
  score := 0;
  if method = 'weighting' then
    select sum(nvl(b.c_comp_level_scale,0) * nvl(a.c_comp_interest_scale,0)) into score
    from
      (select a.hrm_person_id, b.hrm_competence_id, b.c_comp_level_scale,
         b.c_comp_interest_scale
       from
         hrm_person a,
         (select a.hrm_competence_id, a.c_comp_level_scale, a.c_comp_interest_scale
          from hrm_competence_link a
          where a.hrm_job_id = vJobId) b) a,
      hrm_competence_link b
    where
      a.hrm_person_id = vEmpid and
      (b.hrm_competence_id(+) = a.hrm_competence_id and
      b.hrm_person_id(+) = a.hrm_person_id)
    group by
      a.hrm_person_id;
  elsif method = 'sum' then
    select sum(nvl(b.c_comp_level_scale,0)) into score
    from
      (select a.hrm_person_id, b.hrm_competence_id, b.c_comp_level_scale,
         b.c_comp_interest_scale
       from
         hrm_person a,
         (select a.hrm_competence_id, a.c_comp_level_scale, a.c_comp_interest_scale
          from hrm_competence_link a
          where a.hrm_job_id = vJobId) b) a,
      hrm_competence_link b
    where
      a.hrm_person_id = vEmpId and
      (b.hrm_competence_id(+) = a.hrm_competence_id and
      b.hrm_person_id(+) = a.hrm_person_id)
    group by
      a.hrm_person_id;
  end if;
  return score;
  exception
    when others then return 0;
end;

function rate_job(vJobId IN hrm_job.hrm_job_id%TYPE,
  method IN varchar2 default 'weighting') return number
is
  score number;
begin
  score := 0;
  if method = 'weighting' then
    select
      Sum(nvl(a.c_comp_level_scale,0) * nvl(a.c_comp_interest_scale,0)) into Score
    from
      hrm_competence_link a
    where
      a.hrm_job_id = vJobId
    group by
      hrm_job_id;
  elsif method = 'sum' then
    select
      Sum(nvl(a.c_comp_level_scale,0)) into Score
    from
      hrm_competence_link a
    where
      a.hrm_job_id = vJobId
    group by
      hrm_job_id;
  end if;
  return score;
  exception
    when others then return 0;
end;

function get_Training_Job(pPersonId IN hrm_person.hrm_person_id%TYPE,
  pJobId IN hrm_job.hrm_job_id%TYPE) return varchar2
is
  Result varchar2(32767);
begin

  for tplTraining in (
    select distinct(nvl(t.tra_title, t.tra_code)) tra_title
    from
      hrm_training t,
      hrm_competence_link taqu,
      (select hrm_competence_id, c_comp_level_scale
       from hrm_competence_link cj
       where hrm_job_id = pJobId and
         c_comp_interest_scale >= '3' and -- (3) nécessaire
         not exists(select 1 from hrm_competence_link cp
    	              where cp.hrm_person_id = pPersonId and
    				          cp.hrm_competence_id = cj.hrm_competence_id and
    				          cp.c_comp_level_scale >= cj.c_comp_level_scale)) jreq
    where
      t.hrm_training_id = taqu.hrm_aqu_training_id and
      taqu.hrm_competence_id = jreq.hrm_competence_id and
      taqu.c_comp_level_scale = jreq.c_comp_level_scale
    order by 1)
  loop
    Result := Result||tplTraining.tra_title||', ';
  end loop;

  -- Suppression dernière virgule
  if Result is not null then
    Result := Substr(Result, 1, length(Result) - 2);
  end if;

  return Result;

  exception
    when others then return null;

end;

end hrm_search;
