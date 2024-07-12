@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ValueHelp Atp'

@Search.searchable: true
@ObjectModel:{

  resultSet.sizeCategory: #XS // smal size for dropdow helpvalue
}
define view entity z_vh_atp
  as select from    dd07l as FixedValue
    left outer join dd07t as ValueText on  FixedValue.domname    = ValueText.domname
                                       and FixedValue.domvalue_l = ValueText.domvalue_l
                                       and FixedValue.as4local   = ValueText.as4local
{


       @Search.defaultSearchElement: true
       @Search.fuzzinessThreshold: 0.8
       @ObjectModel.text.element: ['ATPstatus']
  key  FixedValue.domvalue_l as Atp,
       @Semantics.text: true -- identifies the text field
       ValueText.ddtext      as ATPstatus
}

where
      FixedValue.domname    =  'D_SO_I_ATP'
  and FixedValue.as4local   =  'A' --Active
  and FixedValue.domvalue_l <> ' '
  and ValueText.ddlanguage  = $session.system_language
