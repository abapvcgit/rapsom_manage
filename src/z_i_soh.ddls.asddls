@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface - SalesOrder Header'


/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define root view entity z_i_soh
  as select from znwd_so_header as SalesOrder
  composition [0..*] of z_i_soi             as _Item

  association [1] to SEPM_I_BusinessPartner as _Partner     on $projection.Businesspartner = _Partner.BusinessPartner
  association [1] to I_Currency             as _Currency    on $projection.Currencycode = _Currency.Currency
  association [1] to z_vh_overallstatus     as _OvStatus    on $projection.Overallstatus = _OvStatus.OvStatusID
  association [1] to z_vh_billingstatus     as _BillStatus  on $projection.Billingstatus = _BillStatus.BillStatusID
  association [1] to z_vh_deliveryStatus    as _DelivStatus on $projection.Deliverystatus = _DelivStatus.DeliveryStatusID
  association [1] to z_vh_paymentMethod     as _PayMethod   on $projection.Paymentmethod = _PayMethod.PaymentMethodID
  association [1] to z_vh_paymentTerms      as _PayTerms    on $projection.Paymentterms = _PayTerms.PaymentTermsID
{ 
  key orderuuid       as Orderuuid,
      salesorderid    as Salesorderid,
      @Consumption.valueHelpDefinition: [{ association: '_Partner' }]
      businesspartner as Businesspartner,
      currencycode    as Currencycode,
      @Semantics.amount.currencyCode: 'Currencycode'
      grossamount     as Grossamount,
      @Semantics.amount.currencyCode: 'Currencycode'
      netamount       as Netamount,
      overallstatus   as Overallstatus,
      billingstatus   as Billingstatus,
      deliverystatus  as Deliverystatus,
      @Consumption.valueHelpDefinition: [{ association: '_PayMethod' }]
      paymentmethod   as Paymentmethod,
      @Consumption.valueHelpDefinition: [{ association: '_PayTerms' }]
      paymentterms    as Paymentterms,
      deliverydate    as Deliverydate,
      @Semantics.user.createdBy: true
      createdby       as Createdby,
      @Semantics.systemDateTime.createdAt: true
      createdat       as Createdat,
      @Semantics.user.lastChangedBy: true
      lastchangedby   as Lastchangedby,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchangedat   as Lastchangedat,
      locallastchangedat as Locallastchangedat,
      // Make association public
      _Item,
      _Partner,
      _Currency,
      _OvStatus,
      _BillStatus,
      _DelivStatus,
      _PayMethod,
      _PayTerms

}
