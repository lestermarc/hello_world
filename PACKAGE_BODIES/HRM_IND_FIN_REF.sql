--------------------------------------------------------
--  DDL for Package Body HRM_IND_FIN_REF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_FIN_REF" is

 procedure init_tables
 -- Initialisation des tables permettant la sélectioner des Références à sélectionner et déslectionner
 is

 begin
  -- ** Références à DESACTIVER **
  -- Suppression
  delete from ind_hrm_fin_ref_inactive;

  -- Insert
  insert into ind_hrm_fin_ref_inactive
  select
  0,
  hrm_financial_ref_id
  from
  hrm_financial_ref;
  --where
  --hrm_employee_id=EmpId;

  -- ** Références à ACTIVER **
  -- Suppression
  delete from ind_hrm_fin_ref_active;

  -- Insert
  insert into ind_hrm_fin_ref_active
  select
  0,
  hrm_financial_ref_id
  from
  ind_hrm_fin_ref_histo;
  --where
  --hrm_employee_id=EmpId;

 end init_tables;

 procedure inactive_fin
 -- Stocke les Références financières sélectionnées dans la table historique
 is

 cursor CurFin is
 select
 a.*
 from
 hrm_financial_ref a
 where exists (select 1
  			   from ind_hrm_fin_ref_inactive b, hrm_financial_ref c
			     where b.hrm_financial_ref_id=c.hrm_financial_ref_id
			     and a.hrm_employee_id=c.hrm_employee_id
			     and a.ACS_FINANCIAL_CURRENCY_ID=c.ACS_FINANCIAL_CURRENCY_ID
			     and fin_to_inactive=1)
  and not exists (select 1
                  from ind_hrm_fin_ref_inactive d
                  where a.hrm_financial_ref_id=d.hrm_financial_ref_id
                  and fin_to_inactive=1);

 Compteur number;

 begin

  dbms_output.put_line('Archivage');
  -- Archivage
  insert into ind_hrm_fin_ref_histo
  select
  b.*
  from
  ind_hrm_fin_ref_inactive a,
  hrm_financial_ref b
  where
  a.hrm_financial_ref_id=b.hrm_financial_ref_id
  and fin_to_inactive=1;

  Compteur:=20;

  dbms_output.put_line('Ouverture du curseur');
  -- ouverture du curseur pour mettre à jour les séquences des références des employés à qui on désactive une référence financière
  for RowFin in CurFin
  loop

    dbms_output.put_line('Début de boucle - valeur du compteur: '||to_char(Compteur));

    update hrm_financial_ref
    set fin_sequence=Compteur
    where
    hrm_financial_ref_id=RowFin.hrm_financial_ref_id;

    compteur:=compteur+1;

    dbms_output.put_line('Fin de boucle - valeur du compteur: '||to_char(Compteur));

  end loop;

  dbms_output.put_line('Sortie du curseur');

  dbms_output.put_line('Suppression dans la table principale');
  -- Suppression dans la table principale
  delete from hrm_financial_ref a
  where exists (select 1
               from ind_hrm_fin_ref_inactive b
			   where
               a.hrm_financial_ref_id=b.hrm_financial_ref_id
               and fin_to_inactive=1);

  dbms_output.put_line('Procédure de Mise à jour des séquences');
   -- Mise à jour des séquences
    init_fin_seq;

 end inactive_fin;

 procedure active_fin
 -- Reprend les Références financières archivées et les active
 is

 cursor CurFin is
 select
 *
 from
 hrm_financial_ref a
 where exists (select 1
  			   from ind_hrm_fin_ref_active b,ind_hrm_fin_ref_histo c
			   where b.hrm_financial_ref_id=c.hrm_financial_ref_id
			   and a.hrm_employee_id=c.hrm_employee_id
			   and a.ACS_FINANCIAL_CURRENCY_ID=c.ACS_FINANCIAL_CURRENCY_ID
			   and fin_to_active=1);

  cursor CurIns is
  select
  b.HRM_FINANCIAL_REF_ID,
  HRM_EMPLOYEE_ID,
  PC_BANK_ID,
  PC_CNTRY_ID,
  C_FINANCIAL_REF_TYPE,
  FIN_NAME,
  FIN_ADDRESS,
  FIN_AMOUNT,
  FIN_LAST_CONTROL,
  FIN_OK,
  FIN_COMMENTS,
  FIN_ACCOUNT_CONTROL,
  FIN_ACCOUNT_NUMBER,
  --FIN_SEQUENCE
  A_DATECRE,
  SYSDATE A_DATEMOD,
  A_IDCRE,
  'HISTO' A_IDMOD,
  A_RECLEVEL,
  A_RECSTATUS,
  FIN_CITY,
  ACS_FINANCIAL_CURRENCY_ID,
  FIN_BAN_ETAB,
  FIN_BAN_GUICH,
  FIN_BAN_NAME,
  FIN_BAN_CITY,
  null HRM_ELEMENTS_ID,
  FIN_SWIFT,
  nvl(C_CHARGES_MANAGEMENT,0) C_CHARGES_MANAGEMENT,
  FIN_START_DATE,
  FIN_END_DATE  
  from
  ind_hrm_fin_ref_active a,
  ind_hrm_fin_ref_histo  b
  where
  a.hrm_financial_ref_id=b.hrm_financial_ref_id
  and fin_to_active=1;

 Compteur number;
 Seq number;

 begin

--- ** BLOQUE MISE A JOUR FIN REF EXISTANTE

   Compteur:=20;

  -- ouverture du curseur pour mettre à jour les séquences des références des employés à qui on active une référence financière
  for RowFin in CurFin
  loop

    update hrm_financial_ref
    set fin_sequence=Compteur
    where
    hrm_financial_ref_id=RowFin.hrm_financial_ref_id;

    compteur:=compteur+1;

  end loop;

--- ** BLOQUE INSERT

  Seq:=99;

  for RowIns in CurIns
  loop

  -- Insert dans la table principale
  insert into hrm_financial_ref
  values(
  RowIns.HRM_FINANCIAL_REF_ID,
  RowIns.HRM_EMPLOYEE_ID,
  RowIns.PC_BANK_ID,
  RowIns.PC_CNTRY_ID,
  RowIns.C_FINANCIAL_REF_TYPE,
  RowIns.FIN_NAME,
  RowIns.FIN_ADDRESS,
  RowIns.FIN_AMOUNT,
  RowIns.FIN_LAST_CONTROL,
  RowIns.FIN_OK,
  RowIns.FIN_COMMENTS,
  RowIns.FIN_ACCOUNT_CONTROL,
  RowIns.FIN_ACCOUNT_NUMBER,
  Seq,--FIN_SEQUENCE
  RowIns.A_DATECRE,
  RowIns.A_DATEMOD,
  RowIns.A_IDCRE,
  RowIns.A_IDMOD,
  RowIns.A_RECLEVEL,
  RowIns.A_RECSTATUS,
  RowIns.FIN_CITY,
  RowIns.ACS_FINANCIAL_CURRENCY_ID,
  RowIns.FIN_BAN_ETAB,
  RowIns.FIN_BAN_GUICH,
  RowIns.FIN_BAN_NAME,
  RowIns.FIN_BAN_CITY,
  RowIns.HRM_ELEMENTS_ID,
  RowIns.FIN_SWIFT,
  RowIns.C_CHARGES_MANAGEMENT,
  RowIns.FIN_START_DATE,
  RowIns.FIN_END_DATE
  );

  Seq:=Seq-1;

  end loop;

-- **** BLOQUE SUPPRESSION

  -- Suppression dans la table historique
  delete from ind_hrm_fin_ref_histo a
  where exists (select 1
               from ind_hrm_fin_ref_active b
			   where
               a.hrm_financial_ref_id=b.hrm_financial_ref_id
               and fin_to_active=1);

-- **** BLOQUE SUPPRESSION MISE A JOUR DE TOUTES LES SEQUENCES

  -- Mise à jour des séquences
    init_fin_seq;

 end active_fin;

 procedure init_fin_seq
 -- Mise à jour des séquences pour les Références financières activées
 is
 -- Curseur par employé
 cursor CurEmp is
  select
  distinct hrm_employee_id,acs_financial_currency_id
  from
  hrm_financial_ref
  where
  fin_sequence>=20;

 -- Curseur par employé et par monnaie
 cursor CurCur(EmpId number, CurId number) is
  select
  *
  from
  hrm_financial_ref a
  where
  a.hrm_employee_id=EmpId
  and a.acs_financial_currency_id=CurId
  order by nvl(hrm_elements_id,0);

 Compteur number;
 FinSeq number;

 begin

 for RowEmp in CurEmp
 loop

  Compteur:=0;

  for RowCur in CurCur(RowEmp.hrm_employee_id,RowEmp.acs_financial_currency_id)
  loop

   update hrm_financial_ref
   set fin_sequence=Compteur
   where hrm_financial_ref_id=RowCur.hrm_financial_ref_id;

   -- recherche s'il existe un GS lié sur la séquence 0
   if Compteur = 0 and RowCur.hrm_elements_id is not null
   then
      -- constantes
      delete from hrm_employee_const a
      where hrm_employee_id=RowCur.hrm_employee_id
      and exists (select 1
                  from hrm_elements_family b, hrm_elements_root c, hrm_elements_family d
                  where a.hrm_constants_id=b.hrm_elements_id
                  and b.hrm_elements_root_id=d.hrm_elements_root_id
                  and d.hrm_elements_id=RowCur.hrm_elements_id);

      -- variables
      delete from hrm_employee_elements a
      where hrm_employee_id=RowCur.hrm_employee_id
      and exists (select 1
                  from hrm_elements_family b, hrm_elements_root c, hrm_elements_family d
                  where a.hrm_elements_id=b.hrm_elements_id
                  and b.hrm_elements_root_id=d.hrm_elements_root_id
                  and d.hrm_elements_id=RowCur.hrm_elements_id);

      -- suppression du lien
      update hrm_financial_ref
      set hrm_elements_id=null
      where hrm_financial_ref_id=RowCur.hrm_financial_ref_id;
    end if;

   Compteur:=Compteur+1;

  end loop;
 end loop;

 end init_fin_seq;

end hrm_ind_fin_ref;
