--------------------------------------------------------
--  DDL for Package Body HRM_IND_SPEC_FACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_SPEC_FACT" is

 procedure GenerateDataFact(vMandat varchar2)
 -- Stock les données de facturation dans la table pour l'interface
 is

  begin
   delete from c_fact.IND_FACTURATION
   where (mandat= vMandat
          or vMandat is null);

   insert into c_fact.IND_FACTURATION
   select
   *
   from
   c_fact.V_IND_FACTURATION
   where emc_value_from <= last_day(trunc(sysdate))
   and emc_value_to >= add_months(trunc(sysdate,'MM'),-13)
   and (mandat= vMandat
       or vMandat is null);

 end GenerateDataFact;

end hrm_ind_spec_fact;
