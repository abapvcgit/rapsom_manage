@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ValueHelp Billing Status'

@Search.searchable: true
@ObjectModel:{
  resultSet.sizeCategory: #XS // smal size for dropdow helpvalue
}
define view entity z_vh_billingstatus
  as select from    dd07l as FixedValue
    left outer join dd07t as ValueText on  FixedValue.domname    = ValueText.domname
                                       and FixedValue.domvalue_l = ValueText.domvalue_l
                                       and FixedValue.as4local   = ValueText.as4local
{

       @Search.defaultSearchElement: true
       @Search.fuzzinessThreshold: 0.8
       @ObjectModel.text.element: ['BillStatus']
  key  FixedValue.domvalue_l as BillStatusID,
       case FixedValue.domvalue_l
           when ' ' then 'Not Paid'
           else
             ValueText.ddtext
            end              as BillStatus,
       case FixedValue.domvalue_l
       when ' ' then 2
       else 3
       end                   as PaidCriticaly
}

where
      FixedValue.domname   = 'D_SO_CF'
  and FixedValue.as4local  = 'A' --Active
  and ValueText.ddlanguage = $session.system_language
