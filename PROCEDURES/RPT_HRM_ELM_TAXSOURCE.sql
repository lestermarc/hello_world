--------------------------------------------------------
--  DDL for Procedure RPT_HRM_ELM_TAXSOURCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_HRM_ELM_TAXSOURCE" (
   parameter_0         IN     hrm_elm_transmission.hrm_elm_transmission_id%TYPE,
   aRefCursor          IN OUT crystal_cursor_types.dualcursortyp) IS
BEGIN
   OPEN aRefCursor FOR
               SELECT 'NORMAL' TYP,
                      elm_order,
                      ELM_VALID_AS_OF,
                      elm_month,
                      emp_social_securityno2,
                      emp_number,
                      per_last_name,
                      per_first_name,
                      ino_in,
                      ino_out,
                      ino_mod,
                      c_hrm_canton,
                      elm_taxable_earning,
                      elm_ascertained_earning,
                      elm_taxsource,
                      elm_taxcode
                 FROM (SELECT elm_order, ELM_VALID_AS_OF, XMLTYPE (ELM_CONTENT) O
                         FROM HRM_ELM_TRANSMISSION
                        WHERE hrm_elm_transmission_id = parameter_0),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:Staff/sd:Person'
                         PASSING o
                         COLUMNS emp_social_securityno2 VARCHAR2 (50)
                                       PATH '/sd:Person/sd:Particulars/sd:Social-InsuranceIdentification/sd:SV-AS-Number',
                                 emp_number VARCHAR2 (20) PATH '/sd:Person/sd:Particulars/sd:EmployeeNumber',
                                 per_last_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Lastname',
                                 per_First_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Firstname',
                                 --ino_in VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:EntryDate',
                                 --ino_out VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:WithdrawalDate',
                                 taxsource XMLTYPE PATH '/sd:Person/sd:TaxAtSourceSalaries'),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:TaxAtSourceSalaries/sd:TaxAtSourceSalary[exists(sd:Current/sd:TaxableEarning)]'
                         PASSING taxsource
                         COLUMNS c_hrm_canton   VARCHAR2 (50)
                                       PATH '/sd:TaxAtSourceSalary/sd:TaxAtSourceCanton',
                                 elm_month VARCHAR2 (10) PATH '/sd:TaxAtSourceSalary/sd:CurrentMonth',
                                 elm_taxable_earning NUMBER
                                       PATH '/sd:TaxAtSourceSalary/sd:Current/sd:TaxableEarning',
                                 elm_ascertained_earning NUMBER
                                       PATH '/sd:TaxAtSourceSalary/sd:Current/sd:AscertainedTaxableEarning',
                                 elm_taxsource NUMBER PATH '/sd:TaxAtSourceSalary/sd:Current/sd:TaxAtSource',
                                 elm_taxcode    VARCHAR2 (10)
                                       PATH '/sd:TaxAtSourceSalary/sd:Current/sd:TaxAtSourceCategory/sd:TaxAtSourceCode',
                                 elm_corrections XMLTYPE PATH '/sd:TaxAtSourceSalary/sd:Correction',
                                 ino_in path '/sd:TaxAtSourceSalary/sd:Current/sd:DeclarationCategory/sd:Entry[1]/sd:ValidAsOf'

                                 ,ino_out path '/sd:TaxAtSourceSalary/sd:Current/sd:DeclarationCategory/sd:Withdrawal[1]/sd:ValidAsOf'
                                 ,ino_mod path '/sd:TaxAtSourceSalary/sd:Current/sd:DeclarationCategory/sd:Mutation[1]/sd:ValidAsOf')
      UNION ALL
               SELECT 'CORRECTION' TYP,
                      elm_order,
                      ELM_VALID_AS_OF,
                      elm_cor_month,
                      emp_social_securityno2,
                      emp_number,
                      per_last_name,
                      per_first_name,
                      ino_in,
                      ino_out,
                      ino_mod,
                      c_hrm_canton,
                      new_taxable + old_taxable,
                      NULL,
                      new_taxsource + old_taxsource,
                      new_taxcode
                 FROM (SELECT elm_order, ELM_VALID_AS_OF, XMLTYPE (ELM_CONTENT) O
                         FROM HRM_ELM_TRANSMISSION
                        WHERE hrm_elm_transmission_id = parameter_0),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:Staff/sd:Person'
                         PASSING o
                         COLUMNS emp_social_securityno2 VARCHAR2 (50)
                                       PATH '/sd:Person/sd:Particulars/sd:Social-InsuranceIdentification/sd:SV-AS-Number',
                                 emp_number VARCHAR2 (20) PATH '/sd:Person/sd:Particulars/sd:EmployeeNumber',
                                 per_last_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Lastname',
                                 per_First_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Firstname',
--                                 ino_in VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:EntryDate',
--                                 ino_out VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:WithdrawalDate',
                                 taxsource XMLTYPE PATH '/sd:Person/sd:TaxAtSourceSalaries'),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:TaxAtSourceSalaries/sd:TaxAtSourceSalary'
                         PASSING taxsource
                         COLUMNS c_hrm_canton   VARCHAR2 (50)
                                       PATH '/sd:TaxAtSourceSalary/sd:TaxAtSourceCanton',
                                 elm_corrections XMLTYPE PATH '/sd:TaxAtSourceSalary/sd:Correction'
                                ),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '/sd:Correction'
                         PASSING elm_corrections
                         COLUMNS elm_cor_month VARCHAR2 (10) PATH '/sd:Correction/sd:Month',
                                 old_taxable NUMBER PATH '/sd:Correction/sd:Old/sd:TaxableEarning',
                                 old_taxsource NUMBER PATH '/sd:Correction/sd:Old/sd:TaxAtSource',
                                 new_taxable NUMBER PATH '/sd:Correction/sd:New/sd:TaxableEarning',
                                 new_taxsource NUMBER PATH '/sd:Correction/sd:New/sd:TaxAtSource',
                                 old_taxcode    VARCHAR2 (20)
                                       PATH '/sd:Correction/sd:Old/sd:TaxAtSourceCategory/sd:TaxAtSourceCode',
                                 new_taxcode    VARCHAR2 (20)
                                       PATH '/sd:Correction/sd:New/sd:TaxAtSourceCategory/sd:TaxAtSourceCode',
                                 ino_in path '/sd:Correction/sd:New/sd:DeclarationCategory/sd:Entry[1]/sd:ValidAsOf'
                                 ,ino_out path '/sd:Correction/sd:New/sd:DeclarationCategory/sd:Withdrawal[1]/sd:ValidAsOf'
                                 ,ino_mod path '/sd:Correction/sd:New/sd:DeclarationCategory/sd:Mutation[1]/sd:ValidAsOf')
      UNION ALL
               SELECT 'CONFIRMATION' TYP,
                      elm_order,
                      ELM_VALID_AS_OF,
                      elm_cor_month,
                      emp_social_securityno2,
                      emp_number,
                      per_last_name,
                      per_first_name,
                      ino_in,
                      ino_out,
                      null ino_mod,
                      c_hrm_canton,
                      conf_taxable,
                      NULL,
                      conf_taxsource,
                      NULL
                 FROM (SELECT elm_order, ELM_VALID_AS_OF, XMLTYPE (ELM_CONTENT) O
                         FROM HRM_ELM_TRANSMISSION
                        WHERE  hrm_elm_transmission_id = parameter_0),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:Staff/sd:Person'
                         PASSING o
                         COLUMNS emp_social_securityno2 VARCHAR2 (50)
                                       PATH '/sd:Person/sd:Particulars/sd:Social-InsuranceIdentification/sd:SV-AS-Number',
                                 emp_number VARCHAR2 (20) PATH '/sd:Person/sd:Particulars/sd:EmployeeNumber',
                                 per_last_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Lastname',
                                 per_First_name VARCHAR2 (50) PATH '/sd:Person/sd:Particulars/sd:Firstname',
                                 ino_in VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:EntryDate',
                                 ino_out VARCHAR2 (10) PATH '/sd:Person/sd:Work/sd:WithdrawalDate',
                                 taxsource XMLTYPE PATH '/sd:Person/sd:TaxAtSourceSalaries'),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:TaxAtSourceSalaries/sd:TaxAtSourceSalary'
                         PASSING taxsource
                         COLUMNS c_hrm_canton   VARCHAR2 (50)
                                       PATH '/sd:TaxAtSourceSalary/sd:TaxAtSourceCanton',
                                 elm_corrections XMLTYPE PATH '/sd:TaxAtSourceSalary/sd:CorrectionConfirmed'),
                      XMLTABLE (
                         XMLNAMESPACES (
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclaration' AS "sd",
                            'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationContainer' AS "sdc",
                            DEFAULT 'http://www.swissdec.ch/schema/sd/20130514/SalaryDeclarationServiceTypes'),
                         '//sd:CorrectionConfirmed'
                         PASSING taxsource
                         COLUMNS elm_cor_month VARCHAR2 (10) PATH '/sd:CorrectionConfirmed/sd:Month',
                                 conf_taxable NUMBER PATH '/sd:CorrectionConfirmed/sd:TaxableEarning',
                                 conf_taxsource NUMBER PATH '/sd:CorrectionConfirmed/sd:TaxAtSource');
END;
