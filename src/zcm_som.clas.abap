CLASS zcm_som DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_abap_behv_message .
    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

    CONSTANTS:
      BEGIN OF prodid_unknown,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'PRODID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF prodid_unknown ,
      BEGIN OF partner_unknown,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'PARTNER',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF partner_unknown ,
      BEGIN OF delivery_date,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'DELIVERYDATE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF delivery_date,
      BEGIN OF valid_quantity,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'QUANTITY',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF valid_quantity ,
      BEGIN OF set_delivered,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'ORDERID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF set_delivered ,
       BEGIN OF set_paid,
        msgid TYPE symsgid VALUE 'ZMS_SOM',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE 'ORDERID',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF set_paid .


    DATA : prodid       TYPE snwd_product_id,
           partner      TYPE snwd_partner_id,
           deliverydate TYPE snwd_delivery_timestampl,
           quantity     TYPE snwd_quantity,
           orderid      TYPE snwd_so_id.
    METHODS constructor
      IMPORTING
        severity     TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
        textid       LIKE if_t100_message=>t100key OPTIONAL
        previous     TYPE REF TO cx_root OPTIONAL
        prodid       TYPE snwd_product_id OPTIONAL
        partner      TYPE snwd_partner_id OPTIONAL
        deliverydate TYPE snwd_delivery_timestampl OPTIONAL
        quantity     TYPE snwd_quantity OPTIONAL
        salesorderid TYPE snwd_so_id OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcm_som IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    me->if_abap_behv_message~m_severity = severity.

    me->prodid = prodid.
    me->partner = partner.
    me->deliverydate = deliverydate.
    me->quantity = quantity.
    me->orderid = salesorderid.
  ENDMETHOD.



ENDCLASS.
