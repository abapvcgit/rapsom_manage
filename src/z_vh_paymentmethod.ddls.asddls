@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ValueHelp Payment Method'
@Search.searchable: true
@ObjectModel:{
  resultSet.sizeCategory: #XS // smal size for dropdow helpvalue
}
define view entity z_vh_paymentMethod
  as select from    dd07l as FixedValue
    left outer join dd07t as ValueText on  FixedValue.domname    = ValueText.domname
                                       and FixedValue.domvalue_l = ValueText.domvalue_l
                                       and FixedValue.as4local   = ValueText.as4local
{
       @Search.defaultSearchElement: true
       @Search.fuzzinessThreshold: 0.8
       @ObjectModel.text.element: ['PaymentMethod']
  key  FixedValue.domvalue_l as PaymentMethodID,
       @Semantics.text: true -- identifies the text field
       ValueText.ddtext      as PaymentMethod
}

where
      FixedValue.domname   = 'D_PM'
  and FixedValue.as4local  = 'A' --Active
  and ValueText.ddlanguage = $session.system_language
