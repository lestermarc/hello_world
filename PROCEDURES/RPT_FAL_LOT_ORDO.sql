--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_ORDO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_ORDO" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     number
, parameter_1    in     date
, parameter_2    in     varchar2
)
is
/**Description - used for report FAL_LOT_ORDO

* @author AWU 26 MAR 2009
* @lastUpdate
* @public
* @param parameter_0:  choice between begin and end date used to filter record 0/begin  1/end
* @param parameter_1: LOT_DATE
* @param parameter_2: Group by 0:day, 1:week, 2:month
*/
  param_begin date;
  param_end   date;
begin
  if parameter_0 = 0 then
    param_begin  := parameter_1;
  elsif parameter_0 = 1 then
    param_end  := parameter_1;
  end if;

  open arefcursor for
    select case
             when (select min(afln.fln_margin)
                     from fal_lot alot
                        , fal_network_link afln
                        , fal_network_supply afns
                    where alot.fal_lot_id = afns.fal_lot_id
                      and afns.fal_network_supply_id = afln.fal_network_supply_id
                      and alot.fal_lot_id = lot.fal_lot_id) < 0 then (select min(afln.fln_margin)
                                                                        from fal_lot alot
                                                                           , fal_network_link afln
                                                                           , fal_network_supply afns
                                                                       where alot.fal_lot_id = afns.fal_lot_id
                                                                         and afns.fal_network_supply_id = afln.fal_network_supply_id
                                                                         and alot.fal_lot_id = lot.fal_lot_id)
             else (select max(afln.fln_margin)
                     from fal_lot alot
                        , fal_network_link afln
                        , fal_network_supply afns
                    where alot.fal_lot_id = afns.fal_lot_id
                      and afns.fal_network_supply_id = afln.fal_network_supply_id
                      and alot.fal_lot_id = lot.fal_lot_id)
           end margin
         , decode( (select count(fpg.fal_lot_progress_id)
                      from fal_lot_progress fpg
                     where fpg.fal_lot_id = lot.fal_lot_id
                       and fpg.flp_reversal = 0), 0, '0', '1') tracking_indication
         , lot.fal_lot_id
         , lot.lot_plan_begin_dte
         , to_char(lot.lot_plan_end_dte, 'iw/yyyy') lot_plan_end_date
         , decode(parameter_2
                , '0', to_char(lot.lot_plan_end_dte, 'YYYYMMDD')
                , '1', to_char(lot.lot_plan_end_dte, 'YYYYIW')
                , '2', to_char(lot.lot_plan_end_dte, 'YYYYMM')
                , to_char(lot.lot_plan_end_dte, 'YYYYIW')
                 ) due_date
         , lot.lot_plan_lead_time
         , fln.fln_margin
         , lot.lot_refcompl
         , (select goo1.goo_major_reference
              from gco_good goo1
             where goo1.gco_good_id = lot.gco_good_id) goo_major_reference
         , gco_functions.getdescription(lot.gco_good_id, procuser_lanid, 1, '01') short_description
         , lot.lot_inprod_qty
         , (select per.per_name
              from pac_person per
             where per.pac_person_id = fnn.pac_third_id) per_name
         , fnn.fan_description
         , decode(nvl(fnn.doc_position_detail_id, 0), 0, fln.fln_need_delay, pde.pde_basis_delay) order_delay
         , fln.fln_qty
         , gco_functions.getcostpricewithmanagementmode(lot.gco_good_id) cost_price
         , (select decode(DOC_I_LIB_GAUGE.isGaugeTTC(dmt.doc_gauge_id), 1, pos.pos_gross_unit_value_incl, pos.pos_gross_unit_value)
              from doc_document dmt
             where pos.doc_document_id = dmt.doc_document_id) pos_gross_unit_value
      from fal_lot lot
         , fal_network_link fln
         , fal_network_supply fns
         , fal_network_need fnn
         , doc_position_detail pde
         , doc_position pos
         , fal_doc_prop fdp
         , fal_lot flt
         , fal_lot_prop flp
     where lot.c_lot_status in('1', '2')
       and lot.fal_lot_id = fns.fal_lot_id(+)
       and fns.fal_network_supply_id = fln.fal_network_supply_id(+)
       and fln.fal_network_need_id = fnn.fal_network_need_id(+)
       and fnn.doc_position_detail_id = pde.doc_position_detail_id(+)
       and pde.doc_position_id = pos.doc_position_id(+)
       and fnn.fal_doc_prop_id = fdp.fal_doc_prop_id(+)
       and fnn.fal_lot_id = flt.fal_lot_id(+)
       and fnn.fal_lot_prop_id = flp.fal_lot_prop_id(+)
       and (   lot.lot_plan_begin_dte <= param_begin
            or param_begin is null)
       and (   lot.lot_plan_end_dte <= param_end
            or param_end is null);
end rpt_fal_lot_ordo;
