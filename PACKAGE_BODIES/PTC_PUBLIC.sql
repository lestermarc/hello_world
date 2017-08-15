--------------------------------------------------------
--  DDL for Package Body PTC_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_PUBLIC" 
is

  function GetTariff(good_id IN number,
                     third_id IN number,
                     dic_id IN varchar2,
                     tariff_type IN varchar2,
                     currency_id IN varchar2,
                     refqty IN number,
                     refdate IN date) return varchar2
  is
  begin

    return PTC_FUNCTIONS.GetTariff(good_id, third_id, dic_id, tariff_type, currency_id, refqty, refdate);

  end;

  function GetTariffCrystal(good_id IN number,
                            third_id IN number,
                            dic_id IN varchar2,
                            tariff_type IN varchar2,
                            currency_id IN varchar2,
                            refqty IN number,
                            refdate IN varchar2) return varchar2
  is
  begin

    return PTC_FUNCTIONS.GetTariffCrystal(good_id, third_id, dic_id, tariff_type, currency_id, refqty, refdate);

  end;

end PTC_PUBLIC;
