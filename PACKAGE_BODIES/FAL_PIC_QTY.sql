--------------------------------------------------------
--  DDL for Package Body FAL_PIC_QTY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PIC_QTY" 
is
  function SumQtyPerWeekWithPartner(
    PYW_ID  PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type
  , Partner FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , Product GCO_GOOD.GCO_GOOD_ID%type
  )
    return number
  is
    -- Déclaration des curseurs
    cursor SUM_QTY_PER_WEEK_WITH_PARTNER1(
      Week_Id PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type
    , Partner FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
    , Product GCO_GOOD.GCO_GOOD_ID%type
    )
    is
      select sum(PAC_QUANTITY_WEEK) SUM_QTY
        from DOC_POSI_ACCUMULATOR
       where PC_YEAR_WEEK_ID = Week_Id
         and PAC_THIRD_ID = Partner
         and GCO_GOOD_ID = Product
         and (    (DIC_GAUGE_TYPE_DOC_ID = 'V-FA')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FC')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FCONS')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FD')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FP')
             );

    cursor SUM_QTY_PER_WEEK_WITH_PARTNER2(
      Week_Id PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type
    , Partner FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
    , Product GCO_GOOD.GCO_GOOD_ID%type
    )
    is
      select sum(PAC_QUANTITY_WEEK) SUM_QTY
        from DOC_POSI_ACCUMULATOR
       where PC_YEAR_WEEK_ID = Week_Id
         and PAC_THIRD_ID = Partner
         and GCO_GOOD_ID = Product
         and DIC_GAUGE_TYPE_DOC_ID = 'V-NC';

    -- Déclaration des variables
    result number;
    Qty    number;
  begin
    Qty  := 0;

    open SUM_QTY_PER_WEEK_WITH_PARTNER1(PYW_ID, Partner, Product);

    fetch SUM_QTY_PER_WEEK_WITH_PARTNER1
     into result;

    if SUM_QTY_PER_WEEK_WITH_PARTNER1%found then
      Qty  := Qty + nvl(result, 0);
    end if;

    close SUM_QTY_PER_WEEK_WITH_PARTNER1;

    open SUM_QTY_PER_WEEK_WITH_PARTNER2(PYW_ID, Partner, Product);

    fetch SUM_QTY_PER_WEEK_WITH_PARTNER2
     into result;

    if SUM_QTY_PER_WEEK_WITH_PARTNER2%found then
      Qty  := Qty - nvl(result, 0);
    end if;

    close SUM_QTY_PER_WEEK_WITH_PARTNER2;

    return Qty;
  end;

  procedure Init_Qty(
    Product               GCO_GOOD.GCO_GOOD_ID%type
  , Representative        PAC_REPRESENTATIVE.PAC_REPRESENTATIVE_ID%type
  , Partner               FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , PilDate               date
  , Qty            in out number
  )
  is
    cursor SELECT_WEEK(Begin_Date date, End_Date date)
    is
      select PYW_WEEK
           , PYW_YEAR
        from PCS.PC_YEAR_WEEK
       where PYW_BEGIN_WEEK >= Begin_Date
         and PYW_BEGIN_WEEK <= End_Date;

    cursor SELECT_YEAR_WEEK(Week PCS.PC_YEAR_WEEK.PYW_WEEK%type, year PCS.PC_YEAR_WEEK.PYW_YEAR%type)
    is
      select PC_YEAR_WEEK_ID
        from PCS.PC_YEAR_WEEK
       where PYW_WEEK = Week
         and PYW_YEAR = year;

    cursor SUM_QTY_PER_WEEK1(Week_Id PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type, Product GCO_GOOD.GCO_GOOD_ID%type)
    is
      select sum(PAC_QUANTITY_WEEK) SUM_QTY
        from DOC_POSI_ACCUMULATOR
       where PC_YEAR_WEEK_ID = Week_Id
         and GCO_GOOD_ID = Product
         and (    (DIC_GAUGE_TYPE_DOC_ID = 'V-FA')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FC')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FCONS')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FD')
              or (DIC_GAUGE_TYPE_DOC_ID = 'V-FP')
             );

    cursor SUM_QTY_PER_WEEK2(Week_Id PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type, Product GCO_GOOD.GCO_GOOD_ID%type)
    is
      select sum(PAC_QUANTITY_WEEK) SUM_QTY
        from DOC_POSI_ACCUMULATOR
       where PC_YEAR_WEEK_ID = Week_Id
         and GCO_GOOD_ID = Product
         and DIC_GAUGE_TYPE_DOC_ID = 'V-NC';

    cursor PARTNER_FROM_GROUP(GroupId DIC_PIC_GROUP.DIC_PIC_GROUP_ID%type)
    is
      select PAC_CUSTOM_PARTNER_ID
        from PAC_CUSTOM_PARTNER
       where DIC_PIC_GROUP_ID = GroupId;

    -- Variable
    Week             PCS.PC_YEAR_WEEK.PYW_WEEK%type;
    PywYear          PCS.PC_YEAR_WEEK.PYW_YEAR%type;
    PYW_ID           PCS.PC_YEAR_WEEK.PC_YEAR_WEEK_ID%type;
    result           number;
    DatePreviousYear date;
    LastDayPrevYear  date;
    PartnerId        FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
  begin
    Qty  := 0;

    if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
      -- Sélection des semaines correspondant au mois de l'année précédente
      DatePreviousYear  := to_date('01/' || to_char(PilDate, 'MM') || '/' ||(to_char(PilDate, 'YYYY') - 1)
                                 , 'DD/MM/YYYY');
      LastDayPrevYear   := last_day(DatePreviousYear);
    else
      -- Sélection de la semaine de l'année précédente
      DatePreviousYear  := to_date(to_char(PilDate, 'DD/MM') || '/' ||(to_char(PilDate, 'YYYY') - 1), 'DD/MM/YYYY');
      LastDayPrevYear   := DatePreviousYear + 6;
    end if;

    open SELECT_WEEK(DatePreviousYear, LastDayPrevYear);

    loop
      fetch SELECT_WEEK
       into Week
          , PywYear;

      exit when SELECT_WEEK%notfound;

      open SELECT_YEAR_WEEK(Week, PywYear);

      fetch SELECT_YEAR_WEEK
       into PYW_ID;

      if SELECT_YEAR_WEEK%found then
        if nvl(Partner, '0') = '0' then
          open SUM_QTY_PER_WEEK1(PYW_ID, Product);

          fetch SUM_QTY_PER_WEEK1
           into result;

          if SUM_QTY_PER_WEEK1%found then
            Qty  := Qty + nvl(result, 0);
          end if;

          close SUM_QTY_PER_WEEK1;

          open SUM_QTY_PER_WEEK2(PYW_ID, Product);

          fetch SUM_QTY_PER_WEEK2
           into result;

          if SUM_QTY_PER_WEEK2%found then
            Qty  := Qty - nvl(result, 0);
          end if;

          close SUM_QTY_PER_WEEK2;
        else
          if FAL_PLAN_DIRECTEUR.PartnerIsAGroup(Partner) = 1 then
            open PARTNER_FROM_GROUP(Partner);

            loop
              fetch PARTNER_FROM_GROUP
               into PartnerId;

              exit when PARTNER_FROM_GROUP%notfound;
              Qty  := Qty + SumQtyPerWeekWithPartner(PYW_ID, PartnerId, Product);
            end loop;

            close PARTNER_FROM_GROUP;
          else
            Qty  := Qty + SumQtyPerWeekWithPartner(PYW_ID, Partner, Product);
          end if;
        end if;
      end if;

      close SELECT_YEAR_WEEK;
    end loop;

    close SELECT_WEEK;
  end;
end;
