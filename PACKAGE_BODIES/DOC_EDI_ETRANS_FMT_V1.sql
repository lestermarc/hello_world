--------------------------------------------------------
--  DDL for Package Body DOC_EDI_ETRANS_FMT_V1
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_ETRANS_FMT_V1" 
is
  /**
  * function PcsLpad
  * Description
  *   Redirigé sur DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad
  */
  function PcsRpad(aText in varchar2, aLength in number, aChar in varchar2 default '')
    return varchar2
  is
  begin
    return DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsRpad(aText, aLength, aChar);
  end PcsRpad;

  /**
  * function PcsLpad
  * Description
  *   Redirigé sur DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad
  */
  function PcsLpad(aNumber in number, aFormat varchar2, aLength in number)
    return varchar2
  is
  begin
    return DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aNumber, aFormat, aLength);
  end PcsLpad;

  /**
  * function PcsLpad
  * Description
  *   Redirigé sur DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad
  */
  function PcsLpad(aDate in date, aFormat varchar2, aLength in number)
    return varchar2
  is
  begin
    return DOC_EDI_EXPORT_JOB_FUNCTIONS.PcsLpad(aDate, aFormat, aLength);
  end PcsLpad;

  /**
  * function GetFormatedMasterData
  * Description
  *    Renvoi les données de l'élément Master Data concaténées et formatées
  *      selon l'analyse
  */
  function GetFormatedMasterData(aMasterData in tMasterData)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := '100';
    --1
    vResult  := vResult || PcsRpad(aMasterData.Torder.Order_Number, 50);
    --2
    vResult  := vResult || PcsLpad(aMasterData.Torder.Order_Date, 'DD.MM.YYYY', 11);
    --3
    vResult  := vResult || PcsLpad(aMasterData.Torder.Order_Type, 'FM0', 1);
    --4
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Abbreviation, 8);
    --5
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Abbreviation, 8);
    --6
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Abbreviation, 8);
    --7
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Abbreviation, 8);
    --8
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Line1, 35);
    --9
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Line1, 35);
    --10
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Line1, 35);
    --11
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Line1, 35);
    --12
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Line2, 35);
    --13
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Line2, 35);
    --14
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Line2, 35);
    --15
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Line2, 35);
    --16
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Country_Code, 50);
    --17
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Country_Code, 50);
    --18
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Country_Code, 50);
    --19
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Country_Code, 50);
    --20
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Customer_Number, 35);
    --21
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Customer_Number, 35);
    --22
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Customer_Number, 35);
    --23
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Customer_Number, 35);
    --24
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Email, 100);
    --25
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Email, 100);
    --26
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Email, 100);
    --27
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Email, 100);
    --28
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Number_Fax, 20);
    --29
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Number_Fax, 20);
    --30
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Number_Fax, 20);
    --31
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Number_Fax, 20);
    --32
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Address_Type, 50);
    --33
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Address_Type, 50);
    --34
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Address_Type, 50);
    --35
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Address_Type, 50);
    --36
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Invoice_Language, 20);
    --37
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Invoice_Language, 20);
    --38
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Invoice_Language, 20);
    --39
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Invoice_Language, 20);
    --40
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.name, 50);
    --41
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.name, 50);
    --42
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.name, 50);
    --43
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.name, 50);
    --44
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Place, 35);
    --45
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Place, 35);
    --46
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Place, 35);
    --47
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Place, 35);
    --48
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Region, 35);
    --49
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Region, 35);
    --50
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Region, 35);
    --51
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Region, 35);
    --52
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Street, 35);
    --53
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Street, 35);
    --54
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Street, 35);
    --55
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Street, 35);
    --56
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Tax_Number, 20);
    --57
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Tax_Number, 20);
    --58
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Tax_Number, 20);
    --59
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Tax_Number, 20);
    --60
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Telephone_Number, 35);
    --61
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Telephone_Number, 35);
    --62
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Telephone_Number, 35);
    --63
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Telephone_Number, 35);
    --64
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Zip_Code, 10);
    --65
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Zip_Code, 10);
    --66
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Zip_Code, 10);
    --67
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Zip_Code, 10);
    --68
    vResult  := vResult || PcsRpad(aMasterData.Consignee_Address.Contact_Person, 35);
    --69
    vResult  := vResult || PcsRpad(aMasterData.Pickup_Address.Contact_Person, 35);
    --70
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_1.Contact_Person, 35);
    --71
    vResult  := vResult || PcsRpad(aMasterData.Additional_Address_2.Contact_Person, 35);
    --72
    vResult  := vResult || PcsRpad(aMasterData.Torder.Forwarder_Abbrevation, 8);
    --73
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Line1, 35);
    --74
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Line2, 35);
    --75
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Country_Code, 50);
    --76
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Customer_Number, 35);
    --77
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Email, 100);
    --78
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Number_Fax, 20);
    --79
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Address_Type, 50);
    --80
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Invoice_Language, 20);
    --81
    vResult  := vResult || PcsRpad(aMasterData.Torder.Forwarder_Name, 50);
    --82
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Place, 35);
    --83
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Region, 35);
    --84
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Street, 35);
    --85
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Tax_Number, 20);
    --86
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Telephone_Number, 35);
    --87
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Zip_Code, 10);
    --88
    vResult  := vResult || PcsRpad(aMasterData.Forwarder_Address.Contact_Person, 35);
    --89
    vResult  := vResult || PcsRpad(aMasterData.Border_Crossing.Country_Code, 50);
    --90
    vResult  := vResult || PcsRpad(aMasterData.Border_Crossing.Mode_of_Transport, 50);
    --91
    vResult  := vResult || PcsLpad(aMasterData.Torder.Pickup_Date, 'DD.MM.YYYY', 11);
    --92
    vResult  := vResult || PcsLpad(aMasterData.Torder.Delivery_Status_Date, 'DD.MM.YYYY', 11);
    --93
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice.Address_Type, 50);
    --94
    vResult  := vResult || PcsRpad(aMasterData.Torder.Dispatch_Advice_Type, 50);
    --95
    vResult  := vResult || PcsLpad(aMasterData.Dispatch_Advice.Arrival_Date, 'DD.MM.YYYY', 11);
    --96
    vResult  := vResult || PcsLpad(aMasterData.Torder.Dispatch_Arrival_Time, 'DD.MM.YYYY', 11);
    --97
    vResult  := vResult || PcsRpad(aMasterData.Torder.Dispatch_BL_AWB_FCR, 25);
    --98
    vResult  := vResult || PcsLpad(aMasterData.Torder.Customer_Order_Date, 'DD.MM.YYYY', 11);
    --99
    vResult  := vResult || PcsRpad(aMasterData.Torder.Customer_Order_Number, 50);
    --100
    vResult  := vResult || PcsLpad(aMasterData.Dispatch_Advice.Departure_Date, 'DD.MM.YYYY', 11);
    --101
    vResult  := vResult || PcsLpad(aMasterData.Torder.Departure_Time, 'DD.MM.YYYY', 11);
    --102
    vResult  := vResult || PcsRpad(aMasterData.Torder.Dispatch_Master_AWB_Number, 25);
    --103
    vResult  := vResult || PcsLpad(aMasterData.Torder.Number_of_Pages, 'FM99', 2);
    --104
    vResult  := vResult || PcsRpad(aMasterData.Torder.Flight_Ship, 25);
    --105
    vResult  := vResult || PcsRpad(aMasterData.Torder.Shipper_Reference_, 30);
    --106
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_1, 'FM99999990.00', 11);
    --107
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_2, 'FM99999990.00', 11);
    --108
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_3, 'FM99999990.00', 11);
    --109
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_4, 'FM99999990.00', 11);
    --110
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_5, 'FM99999990.00', 11);
    --111
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Amount_6, 'FM99999990.00', 11);
    --112
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Percentage_1, 'FM0.00', 4);
    --113
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Percentage_2, 'FM0.00', 4);
    --114
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Percentage_3, 'FM0.00', 4);
    --115
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Percentage_4, 'FM0.00', 4);
    --116
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Percentage_5, 'FM0.00', 4);
    --117
    vResult  := vResult || PcsLpad(aMasterData.Invoice.Percentage_6, 'FM0.00', 4);
    --118
    vResult  := vResult || PcsRpad(aMasterData.Torder.Invoice_Consignee_Reference, 35);
    --119
    vResult  := vResult || PcsRpad(aMasterData.Torder.Invoice_Address_Type, 50);
    --120
    vResult  := vResult || PcsRpad(aMasterData.Torder.Cost_Center_Number, 50);
    --121
    vResult  := vResult || PcsRpad(aMasterData.Torder.Invoice_Currency_Code, 50);
    --122
    vResult  := vResult || PcsRpad(aMasterData.Torder.Customer_Number, 20);
    --123
    vResult  := vResult || PcsLpad(aMasterData.Torder.Delivery_Note_Date, 'DD.MM.YYYY', 11);
    --124
    vResult  := vResult || PcsRpad(aMasterData.Torder.Delivery_Note_Number, 15);
    --125
    vResult  := vResult || PcsLpad(aMasterData.Torder.EU_Clearance, 'FM0', 1);
    --126
    vResult  := vResult || PcsLpad(aMasterData.Torder.Internal_Order_Date, 'DD.MM.YYYY', 11);
    --127
    vResult  := vResult || PcsRpad(aMasterData.Torder.Invoice_Number, 15);
    --128
    vResult  := vResult || PcsRpad(aMasterData.Torder.Project_Number, 50);
    --129
    vResult  := vResult || PcsRpad(aMasterData.Torder.Shipper_Name, 35);
    --130
    vResult  := vResult || PcsRpad(aMasterData.Torder.Tax_Number, 15);
    --131
    vResult  := vResult || PcsRpad(aMasterData.Torder.Terms_Of_Payment, 100);
    --132
    vResult  := vResult || PcsLpad(aMasterData.Torder.Additional_Charges, 'FM9990.00', 7);
    --133
    vResult  := vResult || PcsLpad(aMasterData.Torder.Cash_On_Delivery_Amount, 'FM9990.00', 7);
    --134
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Cash_On_Delivery_Currency, 50);
    --135
    vResult  := vResult || PcsLpad(aMasterData.Torder.Delivery_Date, 'DD.MM.YYYY', 11);
    --136
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Delivery_Time, 'HH24MI', 10);
    --137
    vResult  := vResult || PcsRpad(aMasterData.Torder.Cash_On_Delivery_Instruction_1, 20);
    --138
    vResult  := vResult || PcsRpad(aMasterData.Torder.Cash_On_Delivery_Instruction_2, 20);
    --139
    vResult  := vResult || PcsRpad(aMasterData.Torder.Cash_On_Delivery_Instruction_3, 20);
    --140
    vResult  := vResult || PcsLpad(aMasterData.Torder.Post_Shipment_Charges, 'FM9990.00', 7);
    --141
    vResult  := vResult || PcsLpad(aMasterData.Torder.Pre_Shipment_Charges, 'FM9990.00', 7);
    --142
    vResult  := vResult || PcsLpad(aMasterData.Torder.Main_Transport_Charges, 'FM9990.00', 7);
    --143
    vResult  := vResult || PcsLpad(aMasterData.Torder.Total_Charges, 'FM99990.00', 8);
    --144
    vResult  := vResult || PcsRpad(aMasterData.Torder.Requested_Documents_Comments_1, 25);
    --145
    vResult  := vResult || PcsRpad(aMasterData.Torder.Requested_Documents_Comments_2, 25);
    --146
    vResult  := vResult || PcsLpad(aMasterData.Torder.Requested_Document_Copy, 'FM90', 2);
    --147
    vResult  := vResult || PcsLpad(aMasterData.Torder.Credit_Letter_Document_Copy, 'FM90', 2);
    --148
    vResult  := vResult || PcsRpad(aMasterData.Torder.Credit_Letter_Document_Mode, 20);
    --149
    vResult  := vResult || PcsLpad(aMasterData.Torder.Export_License_Copy, 'FM90', 2);
    --150
    vResult  := vResult || PcsRpad(aMasterData.Torder.Export_License_Mode, 20);
    --151
    vResult  := vResult || PcsLpad(aMasterData.Torder.Invoice_Document_Copy, 'FM90', 2);
    --152
    vResult  := vResult || PcsRpad(aMasterData.Torder.Invoice_Document_mode, 20);
    --153
    vResult  := vResult || PcsLpad(aMasterData.Torder.Certificate_of_Origin_copy, 'FM90', 2);
    --154
    vResult  := vResult || PcsRpad(aMasterData.Torder.Certificate_of_Origin_Mode, 20);
    --155
    vResult  := vResult || PcsLpad(aMasterData.Torder.Requested_Document_Original, 'FM90', 2);
    --156
    vResult  := vResult || PcsLpad(aMasterData.Torder.Document_Others_Copy1, 'FM90', 2);
    --157
    vResult  := vResult || PcsLpad(aMasterData.Torder.Document_Others_Copy2, 'FM90', 2);
    --158
    vResult  := vResult || PcsLpad(aMasterData.Torder.Document_Others_Copy3, 'FM90', 2);
    --159
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Label1, 20);
    --160
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Label2, 20);
    --161
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Label3, 20);
    --162
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Mode1, 20);
    --163
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Mode2, 20);
    --164
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Others_Mode3, 20);
    --165
    vResult  := vResult || PcsLpad(aMasterData.Torder.Document_Packing_List, 'FM90', 2);
    --166
    vResult  := vResult || PcsRpad(aMasterData.Torder.Document_Packing_List_Mode, 20);
    --167
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Dangerous_Goods_Type, 4);
    --168
    vResult  := vResult || PcsRpad(aMasterData.Torder.collect, 20);
    --169
    vResult  := vResult || PcsRpad(aMasterData.Torder.Country_of_Destination, 50);
    --170
    vResult  := vResult || PcsRpad(aMasterData.Torder.Customs_Cleared, 1);
    --171
    vResult  := vResult || PcsLpad(aMasterData.Torder.Mode_of_Delivery_Date, 'DD.MM.YYYY', 12);
    --172
    vResult  := vResult || PcsRpad(aMasterData.Torder.Mode_of_Delivery, 50);
    --173
    vResult  := vResult || PcsRpad(aMasterData.Torder.Place_of_Destination, 25);
    --174
    vResult  := vResult || PcsLpad(aMasterData.Torder.Dangerous_Goods, 'FM0', 1);
    --175
    vResult  := vResult || PcsRpad(aMasterData.Torder.Mode_of_Dispatch, 50);
    --176
    vResult  := vResult || PcsRpad(aMasterData.Torder.Incoterm, 50);
    --177
    vResult  := vResult || PcsRpad(aMasterData.Torder.Place_of_Incoterm, 20);
    --178
    vResult  := vResult || PcsRpad(aMasterData.Torder.Internal_Order_Number, 50);
    --179
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Incoterm_VAT, 1);
    --180
    vResult  := vResult || PcsLpad(aMasterData.Torder.Insurance_Amount, 'FM9990.00', 7);
    --181
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Insure_the_Consignment, 'FM0', 1);
    --182
    vResult  := vResult || PcsRpad(aMasterData.Torder.Insurance_Currency, 50);
    --183
    vResult  := vResult || PcsLpad(aMasterData.Torder.Number_of_Pallets, 'FM990', 3);
    --184
    vResult  := vResult || PcsRpad(aMasterData.Torder.Insurance_Paid_By, 1);
    --185
    vResult  := vResult || PcsLpad(aMasterData.Torder.Tour_Number, 'FM99990', 5);
    --186
    vResult  := vResult || PcsRpad(aMasterData.Torder.Insurance_Type, 1);
    --187
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Account_Number, 10);
    --188
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Taxes_Paid_By, 'FM0', 1);
    --189
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Master_AWB_Number, 50);
    --190
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Shipment_Destination_Code, 3);
    --191
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_Way_Bill, 'FM9999999', 7);
    --192
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.DDP, 'FM0', 1);
    --193
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Start_Day_Dutiable_Parcel, 'FM0', 1);
    --194
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Mid_Day_Dutiable_Parcel, 'FM0', 1);
    --195
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_EU_Options, 'FM0', 1);
    --196
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_Hazardous_Goods, 'FM0', 1);
    --197
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.ITLL, 'FM0', 1);
    --198
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.NDS, 'FM0', 1);
    --199
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_Priority, 'FM0', 1);
    --200
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_Receiver_Pays, 'FM0', 1);
    --201
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Shipment_Type, 'FM0', 1);
    --202
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Type_of_Export, 'FM0', 1);
    --203
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Additional_Items_Swiss_Post, 'FM0', 1);
    --204
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Swiss_Post_Contents, 'FM0', 1);
    --205
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Swiss_Post_Standard_Invoice, 'FM0', 1);
    --206
    vResult  := vResult || PcsRpad(aMasterData.Master_Data.Order_Customs_Code, 3);
    --207
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Export, 'FM0', 1);
    --208
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Packing_Status, 'FM0', 1);
    --209
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Print_Status, 'FM0', 1);
    --210
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Sent_Status, 'FM0', 1);
    --211
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Status, 'FM0', 1);
    --212
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.Order_Delivery_Status, 'FM0', 1);
    --213
    vResult  := vResult || PcsLpad(aMasterData.Master_Data.VAR_Date, 'DD.MM.YYYY', 11);
    --214
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line1, 35);
    --215
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line2, 35);
    --216
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line3, 35);
    --217
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line4, 35);
    --218
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line5, 35);
    --219
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line6, 35);
    --220
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line7, 35);
    --221
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line8, 35);
    --222
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line9, 35);
    --223
    vResult  := vResult || PcsRpad(aMasterData.Address_Notes.Line10, 35);
    --224
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line1, 35);
    --225
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line2, 35);
    --226
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line3, 35);
    --227
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line4, 35);
    --228
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line5, 35);
    --229
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line6, 35);
    --230
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line7, 35);
    --231
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line8, 35);
    --232
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line9, 35);
    --233
    vResult  := vResult || PcsRpad(aMasterData.Invoice_Notes.Line10, 35);
    --234
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line1, 35);
    --235
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line2, 35);
    --236
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line3, 35);
    --237
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line4, 35);
    --238
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line5, 35);
    --239
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line6, 35);
    --240
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line7, 35);
    --241
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line8, 35);
    --242
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line9, 35);
    --243
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_1.Line10, 35);
    --244
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line1, 35);
    --245
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line2, 35);
    --246
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line3, 35);
    --247
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line4, 35);
    --248
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line5, 35);
    --249
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line6, 35);
    --250
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line7, 35);
    --251
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line8, 35);
    --252
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line9, 35);
    --253
    vResult  := vResult || PcsRpad(aMasterData.Dispatch_Advice_Notes_2.Line10, 35);
    --254
    vResult  := vResult || PcsRpad(aMasterData.Edec.Pdt_Doc_Additional_Info, 70);
    --255
    vResult  := vResult || PcsLpad(aMasterData.Edec.Pdt_Doc_Issue_Date, 'DD.MM.YYYY', 11);
    --256
    vResult  := vResult || PcsRpad(aMasterData.Edec.Pdt_Doc_Reference_Number, 20);
    --257
    vResult  := vResult || PcsRpad(aMasterData.Edec.Pdt_Doc_Type, 50);
    --258
    vResult  := vResult || PcsRpad(aMasterData.Edec.Declarant_Number, 50);
    --259
    vResult  := vResult || PcsRpad(aMasterData.Edec.Container_Number, 17);
    --260
    vResult  := vResult || PcsLpad(aMasterData.Edec.Container_Status, 'FM0', 1);
    --261
    vResult  := vResult || PcsRpad(aMasterData.Edec.Trader_Identification_Number, 17);
    --262
    vResult  := vResult || PcsLpad(aMasterData.Edec.Information_Already_Advised, 'FM0', 1);
    -- nécessaire pour le format de fichier
    vresult  := vresult || PcsRpad(' ', 8000 - length(vresult) );
    return vresult;
  end GetFormatedMasterData;

  /**
  * function GetFormatedLineItem
  * Description
  *    Renvoi les données de l'élément Line Item concaténées et formatées
  *      selon l'analyse
  */
  function GetFormatedLineItem(aLineItem in tLineItem)
    return varchar2
  is
    vResult varchar2(32000);
  begin
    vResult  := '200';
    --1
    vResult  := vResult || PcsRpad(aLineItem.Article.Order_Number, 50);
    --2
    vResult  := vResult || PcsRpad(aLineItem.Article.Article_Number, 35);
    --3
    vResult  := vResult || PcsRpad(aLineItem.Article.Article_Description, 500);
    --4
    vResult  := vResult || PcsRpad(aLineItem.Article.Country_of_Destination, 50);
    --5
    vResult  := vResult || PcsRpad(aLineItem.Article.Country_of_Origin, 50);
    --6
    vResult  := vResult || PcsRpad(aLineItem.Article.Customs_Description, 100);
    --7
    vResult  := vResult || PcsRpad(aLineItem.Article.Customs_Tariff_Number, 9);
    --8
    vResult  := vResult || PcsRpad(aLineItem.Article.EU_Tariff_Number, 20);
    --9
    vResult  := vResult || PcsLpad(aLineItem.Article.Gross_Weight, 'FM999990.000', 10);
    --10
    vResult  := vResult || PcsRpad(aLineItem.Article.packing_Code, 50);
    --11
    vResult  := vResult || PcsRpad(aLineItem.Article.Packing_Type, 50);

    --12
    if aLineItem.Article.value_in_chf > 999999 then
      vResult  := vResult || pcsLpad(trunc(aLineItem.Article.value_in_chf), 'FM999999990', 9);   -- FM est suivi de 9 chiffres
    else
      vResult  := vResult || PcsLpad(aLineItem.Article.Value_In_CHF, 'FM999990.00', 9);
    end if;

    --13
    vResult  := vResult || PcsRpad(aLineItem.Article.key, 3);
    --14
    vResult  := vResult || PcsRpad(aLineItem.Article.Article_Abbreviation, 12);
    --15
    vResult  := vResult || PcsLpad(aLineItem.Article.Additional_Pieces, 'FM99999990', 8);
    --16
    vResult  := vResult || PcsLpad(aLineItem.Article.Change_Pallette, 'FM0', 1);
    --17
    vResult  := vResult || PcsLpad(aLineItem.Article.Customs_Statistics, 'FM0', 1);
    --18
    vResult  := vResult || PcsRpad(aLineItem.Article.License_Requirement, 50);
    --19
    vResult  := vResult || PcsRpad(aLineItem.Article.License_Requirement_Text, 35);
    --20
    vResult  := vResult || PcsLpad(aLineItem.Article.Net_Weight, 'FM9999990.000', 11);
    --21
    vResult  := vResult || PcsLpad(aLineItem.Article.Number_of_Pieces, 'FM9990', 4);
    --22
    vResult  := vResult || PcsLpad(aLineItem.Article.Packing_Unit, 'FM9990', 4);
    --23
    vResult  := vResult || PcsLpad(aLineItem.Article.Number_of_Packages, 'FM99990', 5);
    --24
    vResult  := vResult || PcsLpad(aLineItem.Article.Price_per_Piece, 'FM99999990.00', 11);
    --25
    vResult  := vResult || PcsLpad(aLineItem.Article.Supress_Invoice_Print, 'FM0', 1);
    --26
    vResult  := vResult || PcsLpad(aLineItem.Article.Supress_TO_Print, 'FM0', 1);
    --27
    vResult  := vResult || PcsRpad(aLineItem.Article.Unit_of_Pieces, 5);
    --28
    vResult  := vResult || PcsLpad(aLineItem.Article.VOC, 'FM9990.000', 8);
    --29
    vResult  := vResult || PcsRpad(aLineItem.Article.Marks_And_Numbers, 500);
    --30
    vResult  := vResult || PcsRpad(aLineItem.Article.Processing, 50);
    --31
    vResult  := vResult || PcsRpad(aLineItem.Article.Reimbursement, 50);
    --32
    vResult  := vResult || PcsRpad(aLineItem.Article.Traffic_Direction, 50);
    --33
    vResult  := vResult || PcsRpad(aLineItem.Article.Article_Status, 10);
    --34
    vResult  := vResult || PcsLpad(aLineItem.Article.Volume, 'FM990.000', 7);
    --35
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_1, 'FM990.00', 6);
    --36
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_2, 'FM990.00', 6);
    --37
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_3, 'FM990.00', 6);
    --38
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_4, 'FM990.00', 6);
    --39
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_5, 'FM990.00', 6);
    --40
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_6, 'FM990.00', 6);
    --41
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_7, 'FM990.00', 6);
    --42
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_8, 'FM990.00', 6);
    --43
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_9, 'FM990.00', 6);
    --44
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Height_10, 'FM990.00', 6);
    --45
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_1, 'FM990.00', 6);
    --46
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_2, 'FM990.00', 6);
    --47
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_3, 'FM990.00', 6);
    --48
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_4, 'FM990.00', 6);
    --49
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_5, 'FM990.00', 6);
    --50
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_6, 'FM990.00', 6);
    --51
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_7, 'FM990.00', 6);
    --52
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_8, 'FM990.00', 6);
    --53
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_9, 'FM990.00', 6);
    --54
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Length_10, 'FM990.00', 6);
    --55
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_1, 'FM99990', 5);
    --56
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_2, 'FM99990', 5);
    --57
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_3, 'FM99990', 5);
    --58
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_4, 'FM99990', 5);
    --59
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_5, 'FM99990', 5);
    --60
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_6, 'FM99990', 5);
    --61
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_7, 'FM99990', 5);
    --62
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_8, 'FM99990', 5);
    --63
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_9, 'FM99990', 5);
    --64
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Pieces_10, 'FM99990', 5);
    --65
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_1, 'FM990.00', 6);
    --66
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_2, 'FM990.00', 6);
    --67
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_3, 'FM990.00', 6);
    --68
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_4, 'FM990.00', 6);
    --69
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_5, 'FM990.00', 6);
    --70
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_6, 'FM990.00', 6);
    --71
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_7, 'FM990.00', 6);
    --72
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_8, 'FM990.00', 6);
    --73
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_9, 'FM990.00', 6);
    --74
    vResult  := vResult || PcsLpad(aLineItem.Article_Volumetric_Detail.Volume_Width_10, 'FM990.00', 6);
    --75
    vResult  := vResult || PcsRpad(aLineItem.Edec.eDec_Billing_Type, 50);
    --76
    vResult  := vResult || PcsRpad(aLineItem.Edec.eDec_Permit_Obligation, 50);
    --77
    vResult  := vResult || PcsRpad(aLineItem.Edec.eDec_Non_Customs_Law, 50);
    --78
    vResult  := vResult || PcsRpad(aLineItem.Edec.eDec_Commercial_Goods, 50);
    --79
    vResult  := vResult || PcsRpad(aLineItem.Edec.eDec_Customs_Clearence_Type, 50);
    --80
    vResult  := vResult || PcsRpad(aLineItem.Edec.Composition_Name, 50);
    --81
    vResult  := vResult || PcsRpad(aLineItem.Edec.Composition_Parent, 2);
    --82
    vResult  := vResult || PcsRpad(aLineItem.Edec.Composition_Value, 50);
    --83
    vResult  := vResult || PcsRpad(aLineItem.Edec.Conf_Code_Add_Unit, 50);
    --84
    vResult  := vResult || PcsRpad(aLineItem.Edec.Conf_Code_Gross_Mass, 50);
    --85
    vResult  := vResult || PcsRpad(aLineItem.Edec.Conf_Code_Net_Mass, 50);
    --86
    vResult  := vResult || PcsRpad(aLineItem.Edec.Conf_Code_Parent, 2);
    --87
    vResult  := vResult || PcsRpad(aLineItem.Edec.Conf_Code_Statistical_Value, 50);
    --88
    vResult  := vResult || PcsRpad(aLineItem.Edec.Non_Customs_Law_Type, 250);
    --89
    vResult  := vResult || PcsRpad(aLineItem.Edec.Non_Customs_Parent, 2);
    --90
    vResult  := vResult || PcsRpad(aLineItem.Edec.Note_Code, 50);
    --91
    vResult  := vResult || PcsRpad(aLineItem.Edec.Note_Parent, 2);
    --92
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Additional_Info, 70);
    --93
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Authority, 50);
    --94
    vResult  := vResult || PcsLpad(aLineItem.Edec.Permission_Issue_Date, 'DD.MM.YYYY', 11);
    --95
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Number, 17);
    --96
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Parent, 2);
    --97
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Tobacco_Type, 30);
    --98
    vResult  := vResult || PcsRpad(aLineItem.Edec.Permission_Type, 50);
    --99
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Bill_Type, 50);
    --100
    vResult  := vResult || PcsLpad(aLineItem.Edec.Refinement_Export_Value, 'FM9999999999999999990', 19);
    --101
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Parent, 2);
    --102
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Position_Type, 50);
    --103
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_ProcessType, 50);
    --104
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Type, 50);
    --105
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Temp_Admission, 50);
    --106
    vResult  := vResult || PcsRpad(aLineItem.Edec.Refinement_Traffic_Direction, 50);
    --107
    vResult  := vResult || PcsRpad(aLineItem.Edec.Sensible_GoodsType, 50);
    --108
    vResult  := vResult || PcsRpad(aLineItem.Edec.Sensible_Goods_Parent, 2);
    --109
    vResult  := vResult || PcsLpad(aLineItem.Edec.Sensible_Goods_Weight, 'FM9999999999990.00', 16);
    --110
    vResult  := vResult || PcsLpad(aLineItem.Edec.Packing_Detail_Bar_Code, 'FM99999999', 8);
    --111
    vResult  := vResult || PcsLpad(aLineItem.Article.Article_Dangerous_Goods_Status, 'FM0', 1);
    --112
    vResult  := vResult || PcsLpad(aLineItem.Article.Exchange_Rate, 'FM999999990.000000', 16);
    --113
    vResult  := vResult || PcsRpad(aLineItem.Article.Argricultural_Formula, 18);
    --114
    vResult  := vResult || PcsRpad(aLineItem.Article.Quota_Abbreviation, 30);
    -- nécessaire pour le format de fichier
    vresult  := vresult || PcsRpad(' ', 4000 - length(vresult) );
    return vresult;
  end GetFormatedLineItem;

  /**
  * procedure Write_tMasterData
  * Description
  *    Insertion dans la table des données d'export de l'élément Master Data
  */
  procedure Write_tMasterData(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aMasterData in tMasterData)
  is
    vFormattedText varchar2(32000);
  begin
    -- Récuperer les données formatées de l'élément Master Data
    vFormattedText  := GetFormatedMasterData(aMasterData);
    -- Insertion dans la table des données d'export des lignes correspondant au texte formaté
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID => aExportJobID, aFormattedText => vFormattedText);
  end Write_tMasterData;

  /**
  * procedure Write_ttblLineItem
  * Description
  *    Insertion dans la table des données d'export de plusieurs éléments Line Item
  */
  procedure Write_ttblLineItem(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aTblLineItem in ttblLineItem)
  is
    vLineItem tLineItem;
    vCpt      integer;
  begin
    if (aTblLineItem.count > 0) then
      vCpt  := 1;

      -- Balayer la liste des line item
      while vCpt <= aTblLineItem.count loop
        Write_tLineItem(aExportJobID => aExportJobID, aLineItem => aTblLineItem(vCpt) );
        vCpt  := vCpt + 1;
      end loop;
    end if;
  end Write_ttblLineItem;

  /**
  * procedure Write_tLineItem
  * Description
  *    Insertion dans la table des données d'export de l'élément Line Item
  */
  procedure Write_tLineItem(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aLineItem in tLineItem)
  is
    vFormattedText varchar2(32000);
  begin
    -- Récuperer les données formatées de l'élément Line Item
    vFormattedText  := GetFormatedLineItem(aLineItem);
    -- Insertion dans la table des données d'export des lignes correspondant au texte formaté
    DOC_EDI_EXPORT_JOB_FUNCTIONS.WriteLineToJobData(aExportJobID => aExportJobID, aFormattedText => vFormattedText);
  end Write_tLineItem;
end DOC_EDI_ETRANS_FMT_V1;
