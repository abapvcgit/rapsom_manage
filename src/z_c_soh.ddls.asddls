@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption - SalesOrder Heder'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Salesorderid']
define root view entity z_c_soh
  provider contract transactional_query
  as projection on z_i_soh
{
  key Orderuuid,
      Salesorderid,

      @ObjectModel.text.element: ['PartnerName']
      Businesspartner,
      _Partner.CompanyName        as PartnerName,
      Currencycode,
      @Semantics.amount.currencyCode: 'Currencycode'
      Grossamount,
      @Semantics.amount.currencyCode: 'Currencycode'
      Netamount,
      @ObjectModel.text.element: ['StatusTxt']
      Overallstatus,
      _OvStatus.OvStatus          as StatusTxt,
      @ObjectModel.text.element: ['BillTxT']
      Billingstatus,
      _BillStatus.BillStatus      as BillTxT,
      @ObjectModel.text.element: ['DelStatusTxT']
      Deliverystatus,
      _DelivStatus.DeliveryStatus as DelStatusTxT,
      @ObjectModel.text.element: ['PaymentTxt']
      Paymentmethod,
      _PayMethod.PaymentMethod    as PaymentTxt,
      @ObjectModel.text.element: ['PaymentTermTxt']
      Paymentterms,
      _PayTerms.PaymentTerms      as PaymentTermTxt,
      Deliverydate,
      Createdby,
      Createdat,
      Lastchangedby,
      Lastchangedat,
      /* Associations */
      _BillStatus,
      _Currency,
      _DelivStatus,
      _Item : redirected to composition child z_c_soi,
      _OvStatus,
      _Partner,
      _PayMethod,
      _PayTerms
}
