--------------------------------------------------------
--  DDL for Package Body PPS_INIT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_INIT" 
is

  -- Status des produits / Composants pris en compte
  procedure SetSuspended(iSuspended in integer)
  is
  begin
    SuspendedPdt  := iSuspended;
  end;

  function GetSuspended return integer
  is
  begin
    return SuspendedPdt;
  end;

  procedure SetInactive(iInactive in integer)
  is
  begin
    InactivePdt := iInactive;
  end;

  function GetInactive return integer
  is
  begin
    return InactivePdt;
  end;

  -- Nomenclature
  procedure SetNomID(aNom_ID in number)
  is
  begin
    PPS_NOMENCLATURE_ID  := aNom_ID;
  end;

  function GetNomId
    return number
  is
  begin
    return PPS_NOMENCLATURE_ID;
  end;

  -- Bien
  procedure SetGoodID(aGood_ID in number)
  is
  begin
    GCO_GOOD_ID  := aGood_ID;
  end;

  function GetGoodId
    return number
  is
  begin
    return GCO_GOOD_ID;
  end;

  function GetSeqNextval
    return number
  is
    TempSeq number;
  begin
    select PPS_NOM_QUERY_SEQ.nextval
      into TempSeq
      from dual;

    return TempSeq;
  end;
end PPS_INIT;
