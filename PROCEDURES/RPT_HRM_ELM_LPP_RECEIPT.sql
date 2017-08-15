--------------------------------------------------------
--  DDL for Procedure RPT_HRM_ELM_LPP_RECEIPT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_ELM_LPP_RECEIPT" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     number
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* Description - used for the report HRM_ELM_LPP_RECEIPT

* @author
* @lastUpdate VHA 25 February 2013
* public
* @parameter_0: hrm_elm_recipient_id
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
  l_xmlns2    varchar2(255)                 := 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"';
  l_xmlns3    varchar2(255)                 := 'xmlns:ns3="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer"';
  l_xmlns23   varchar2(255)
    := 'xmlns:ns3="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer" xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"';
begin
  PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select INF.HRM_ELM_RECIPIENT_ID
         , INF.SEQ
         , INF.INFO1
         , INF.INFO2
         , INF.INFO3
         , INF.INFO4
         , INF.INFO5
         , INF.INFO6
         , INF.INFO7
         , INF.INFO8
         , INF.INFO9
         , INF.INFO10
         , INF.INFO11
         , INF.INFO12
         , INF.INFO13
         , INF.INFO14
         , INF.INFO15
         , INF.INFO16
         , INF.INFO17
         , INF.INFO18
         , INF.INFO19
         , INF.INFO20
         , TRS.ELM_YEAR
         , TRS.ELM_ORDER
         , INS.INS_NAME
         , INS.INS_CONTRACT_NR
         , decode(INF.INFO3
                , 'married', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Mar', vpc_lang_id)
                , 'single', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Cel', vpc_lang_id)
                , 'unknown', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Inconnu', vpc_lang_id)
                , 'widowed', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Veu', vpc_lang_id)
                , 'divorced', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Div', vpc_lang_id)
                , 'separated', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Sep', vpc_lang_id)
                , 'registeredPartnership', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Pen', vpc_lang_id)
                , 'partnershipDissolvedByLaw', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Pdi', vpc_lang_id)
                , 'partnershipDissolvedByDeath', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Pde', vpc_lang_id)
                , 'partnershipDissolvedByDeclarationOfLost', PCS.PC_FUNCTIONS.GetDescodeDescr('C_CIVIL_STATUS', 'Pab', vpc_lang_id)
                 , INF.INFO3) MARITAL_STATUS
         , decode(INF.INFO4
                , 'Identified', PCS.PC_FUNCTIONS.translateword('Identifié', vpc_lang_id)
                , 'Missing', PCS.PC_FUNCTIONS.translateword('Manquant', vpc_lang_id)
                , 'Unknown', PCS.PC_FUNCTIONS.translateword('Inconnu', vpc_lang_id)
                 ) STATUS
      from (
            /* Données globales */
            select cast(HRM_ELM_RECIPIENT_ID as number(12) ) HRM_ELM_RECIPIENT_ID
                 , 0 seq
                 , cast(null as varchar2(4000) ) INFO1
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:GeneralValidAsOf', l_xmlns2) INFO2
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns3:ChangesConsideredUpTo', l_xmlns3) INFO3
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Identified/ns2:Total', l_xmlns2) INFO4
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Identified/ns2:DetailsAvailable', l_xmlns2) INFO5
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Unknown/ns2:Total', l_xmlns2) INFO6
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Unknown/ns2:DetailsAvailable', l_xmlns2) INFO7
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Missing/ns2:Total', l_xmlns2) INFO8
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Persons/ns2:Missing/ns2:DetailsAvailable', l_xmlns2) INFO9
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:Identical', l_xmlns2) INFO10
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:ManualMutationRequiredFrom', l_xmlns2) INFO11
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:AutomaticMutationPossibleFrom', l_xmlns2) INFO12
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:AutomaticMutationProcessedFrom', l_xmlns2) INFO13
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:MappedFrom', l_xmlns2) INFO14
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:Missing', l_xmlns2) INFO15
                 , extractvalue(xmltype(elm_lpp_response_xml), '//ns2:Contributions-BVG-LPP-Code/ns2:Unknown', l_xmlns2) INFO16
                 , cast(null as varchar2(4000) ) INFO17
                 , cast(null as varchar2(4000) ) INFO18
                 , cast(null as varchar2(4000) ) INFO19
                 , cast(null as varchar2(4000) ) INFO20
              from hrm_elm_recipient
             where length(elm_lpp_response_xml) > 0
               and hrm_elm_recipient_id = parameter_0
            union all
            /* Warning global */
            select hrm_elm_recipient_id
                 , 1
                 , extractvalue(column_value, '//ns3:Description', l_xmlns3)
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
              from hrm_elm_recipient
                 , table(xmlsequence(extract(xmltype(elm_lpp_response_xml), '//ns3:BVG-LPP/ns3:Warning/ns3:Notification', l_xmlns3) ) )
             where length(elm_lpp_response_xml) > 0
               and hrm_elm_recipient_id = parameter_0
            union all
            /* Info générale */
            select hrm_elm_recipient_id
                 , 1
                 , extractvalue(column_value, '//ns3:Description', l_xmlns3)
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
              from hrm_elm_recipient
                 , table(xmlsequence(extract(xmltype(elm_lpp_response_xml), '//ns3:BVG-LPP/ns3:Info/ns3:Notification', l_xmlns3 || ' ' || l_xmlns2) ) )
             where length(elm_lpp_response_xml) > 0
               and hrm_elm_recipient_id = parameter_0
            union all
            /* Codes LPP disponibles */
            select hrm_elm_recipient_id
                 , 2 seq
                 , extractvalue(column_value, '//ns2:BVG-LPP-Code', l_xmlns2) info1
                 , extractvalue(column_value, '//ns2:Description', l_xmlns2) info2
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null
                 , null INFO16
                 , null INFO17
                 , null INFO18
                 , null INFO19
                 , NULL INFO20
              from hrm_elm_recipient
                 , table(xmlsequence(extract(xmltype(elm_lpp_response_xml), '//ns3:CodeDescriptions/ns2:CodeDescription', l_xmlns23) ) )
             where length(elm_lpp_response_xml) > 0
               and hrm_elm_recipient_id = parameter_0
            union all
            /* employés manquants */
            select hrm_elm_recipient_id
                 , 3
                 , ssid
                 , fullname
                 , c_civil_status
                 , code
                 , code1 ||
                   ' ' ||
                   case
                     when autoproc1 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc1 || ')'
                     when manual1 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual1 || ')'
                     when autopos1 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos1 || ')'
                     when conv1 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') || case when manual1 is not null then ' (' || manual1 || ')' else '' end
                     when unknown1 =1 then pcs.pc_public.translateword('Code inconnu')
                     when missing1 =1 then pcs.pc_public.translateword('Code manquant')
                   end code1
                 , code2 ||
                   ' ' ||
                   case
                     when autoproc2 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc2 || ')'
                     when manual2 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual2 || ')'
                     when autopos2 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos2 || ')'
                     when conv2 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') || case when manual2 is not null then ' (' || manual2 || ')' else '' end
                     when unknown2 =1 then pcs.pc_public.translateword('Code inconnu')
                     when missing2 =1 then pcs.pc_public.translateword('Code manquant')
                   end code2
                 , validasof1
                 , validasof2
                 , to_char(EmployeeContribution / 12,'FM999999999.00')
                 , to_char(EmployeeContribution2 / 12,'FM999999999.00')
                 , to_char(EmployerContribution / 12,'FM999999999.00')
                 , to_char(EmployerContribution2 / 12,'FM999999999.00')
                 , warning
                 , info
                 , warning2
                 , info2
                 , warning3
                 , info3
                 , to_char(ThirdPartyContribution / 12,'FM999999999.00')
                 , to_char(ThirdPartyContribution2 / 12,'FM999999999.00')
              from (select hrm_elm_recipient_id
                         , extractvalue(column_value, '//ns2:SV-AS-Number', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ssid
                         , extractvalue(column_value, '//ns2:Lastname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ||
                           ' ' ||
                           extractvalue(column_value, '//ns2:Firstname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') fullname
                         , extractvalue(column_value, '//ns2:CivilStatus/ns2:Status', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"')
                                                                                                                                                 c_civil_status
                         , 'Missing' code
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning2
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning3
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info3
                      from hrm_elm_recipient
                         , table(xmlsequence(extract(xmltype(elm_lpp_response_xml)
                                                   , '//ns2:Missing/ns2:Person'
                                                   , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                                    )
                                            )
                                )
                     where length(elm_lpp_response_xml) > 0
                       and hrm_elm_recipient_id = parameter_0)
            union all
            /* Employés identifiés */
            select hrm_elm_recipient_id
                 , 3
                 , ssid
                 , fullname
                 , c_civil_status
                 , code
                 , code1 ||
                   ' ' ||
                   case
                     when autoproc1 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc1 || ')'
                     when manual1 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual1 || ')'
                     when autopos1 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos1 || ')'
                     when conv1 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') || case when manual1 is not null then ' (' || manual1 || ')' else '' end
                     when unknown1 =1 then pcs.pc_public.translateword('Code inconnu')
                     when missing1 =1 then pcs.pc_public.translateword('Code manquant')
                   end code1
                 , code2 ||
                   ' ' ||
                   case
                     when autoproc2 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc2 || ')'
                     when manual2 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual2 || ')'
                     when autopos2 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos2 || ')'
                     when conv2 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') || case when manual2 is not null then ' (' || manual2 || ')' else '' end
                     when unknown2 =1 then pcs.pc_public.translateword('Code inconnu')
                     when missing2 =1 then pcs.pc_public.translateword('Code manquant')
                   end code2
                 , validasof1
                 , validasof2
                 , to_char(EmployeeContribution / 12,'FM999999999.00')
                 , to_char(EmployeeContribution2 / 12,'FM999999999.00')
                 , to_char(EmployerContribution / 12,'FM999999999.00')
                 , to_char(EmployerContribution2 / 12,'FM999999999.00')
                 , warning
                 , info
                 , warning2
                 , info2
                 , warning3
                 , info3
                 , to_char(ThirdPartyContribution / 12,'FM999999999.00')
                 , to_char(ThirdPartyContribution2 / 12,'FM999999999.00')
              from (select hrm_elm_recipient_id
                         , extractvalue(column_value, '//ns2:SV-AS-Number', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ssid
                         , extractvalue(column_value, '//ns2:Lastname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ||
                           ' ' ||
                           extractvalue(column_value, '//ns2:Firstname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') fullname
                         , extractvalue(column_value, '//ns2:CivilStatus/ns2:Status', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"')
                                                                                                                                                 c_civil_status
                         , 'Identified' code
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning2
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning3
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info3
                      from hrm_elm_recipient
                         , table(xmlsequence(extract(xmltype(elm_lpp_response_xml)
                                                   , '//ns2:Identified/ns2:Person'
                                                   , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                                    )
                                            )
                                )
                     where length(elm_lpp_response_xml) > 0
                       and hrm_elm_recipient_id = parameter_0)
            union all
            /* employés inconnus */
            select hrm_elm_recipient_id
                 , 3
                 , ssid
                 , fullname
                 , c_civil_status
                 , code
                 , code1 ||
                   ' ' ||
                   case
                     when autoproc1 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc1 || ')'
                     when manual1 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual1 || ')'
                     when autopos1 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos1 || ')'
                     when conv1 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') || case when manual1 is not null then ' (' || manual1 || ')' else '' end
                     when unknown1 = 1 then pcs.pc_public.translateword('Code inconnu')
                     when missing1 =1  then pcs.pc_public.translateword('Code manquant')
                   end code1
                 , code2 ||
                   ' ' ||
                   case
                     when autoproc2 is not null then pcs.pc_public.translateword('Mutation automatique effectuée') || ' (' || autoproc2 || ')'
                     when manual2 is not null then pcs.pc_public.translateword('Mutation manuelle nécessaire') || ' (' || manual2 || ')'
                     when autopos2 is not null then pcs.pc_public.translateword('Mutation automatique possible') || ' (' || autopos2 || ')'
                     when conv2 is not null then pcs.pc_public.translateword('Conversion automatique effectuée') ||case when manual2 is not null then ' (' || manual2 || ')' else '' end
                     when unknown2 =1 then pcs.pc_public.translateword('Code inconnu')
                     when missing2 = 1 then pcs.pc_public.translateword('Code manquant')
                   end code2
                 , validasof1
                 , validasof2
                 , to_char(EmployeeContribution / 12,'FM999999999.00')
                 , to_char(EmployeeContribution2 / 12,'FM999999999.00')
                 , to_char(EmployerContribution / 12,'FM999999999.00')
                 , to_char(EmployerContribution2 / 12,'FM999999999.00')
                 , warning
                 , info
                 , warning2
                 , info2
                 , warning3
                 , info3
                 , to_char(ThirdPartyContribution / 12,'FM999999999.00')
                 , to_char(ThirdPartyContribution2 / 12,'FM999999999.00')
              from (select hrm_elm_recipient_id
                         , extractvalue(column_value, '//ns2:SV-AS-Number', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ssid
                         , extractvalue(column_value, '//ns2:Lastname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') ||
                           ' ' ||
                           extractvalue(column_value, '//ns2:Firstname', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') fullname
                         , extractvalue(column_value, '//ns2:CivilStatus/Status', 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"')
                                                                                                                                                 c_civil_status
                         , 'Unknown' code
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv1
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationProcessedFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) autoproc2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                              case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@manualMutationRequiredFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) manual2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@automaticMutationPossibleFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                              ) autoPos2
                         , nvl(extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ),
                               case when existsnode( column_value,'//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code/@mappingFrom'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"') = 1 then '-' end
                               ) conv2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Missing'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) missing2
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown1
                         , existsnode(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:Unknown'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) unknown2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:BVG-LPP-Code'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) code2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof1
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ValidAsOf'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) validasof2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployeeContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployeeContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:EmployerContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) EmployerContribution2
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[1]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution
                         , extractvalue(column_value
                                      , '//ns2:Contributions/ns2:Contribution[2]/ns2:ThirdPartyContribution'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) ThirdPartyContribution2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[1]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning2
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[2]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info2
                         , extractvalue(column_value
                                      , '//ns2:Warning/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) warning3
                         , extractvalue(column_value
                                      , '//ns2:Info/ns2:Notification[3]/ns2:Description'
                                      , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                       ) info3
                      from hrm_elm_recipient
                         , table(xmlsequence(extract(xmltype(elm_lpp_response_xml)
                                                   , '//ns2:Unknown/ns2:Person'
                                                   , 'xmlns:ns2="http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration"'
                                                    )
                                            )
                                )
                     where length(elm_lpp_response_xml) > 0
                       and hrm_elm_recipient_id = parameter_0) ) INF
         , HRM_ELM_RECIPIENT RCP
         , HRM_ELM_TRANSMISSION TRS
         , HRM_INSURANCE INS
     where RCP.HRM_ELM_RECIPIENT_ID = INF.HRM_ELM_RECIPIENT_ID
       and TRS.HRM_ELM_TRANSMISSION_ID = RCP.HRM_ELM_TRANSMISSION_ID
       and INS.HRM_INSURANCE_ID = RCP.HRM_INSURANCE_ID;
end RPT_HRM_ELM_LPP_RECEIPT;
