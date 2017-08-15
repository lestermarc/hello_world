--------------------------------------------------------
--  DDL for Package Body REP_GAL_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_GAL_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Intégration GALEi (GAL)
 *
 * @version 1.0
 * @date 01/2005
 * @author vjeanfavre
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_gal_cost_center_link(
  Id in gal_cost_center.gal_cost_center_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GAL_COST_CENTER,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'GCC_CODE' as TABLE_KEY,
        gal_cost_center_id,
        gcc_code)
    ) into lx_data
  from gal_cost_center
  where gal_cost_center_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_GAL_FUNCTIONS_LINK;
