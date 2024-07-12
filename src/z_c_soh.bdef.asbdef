projection;
//strict ( 2 ); //Uncomment this line in order to enable strict mode 1. The strict mode is prerequisite to be future proof regarding syntax and to be able to release your BO.
use draft;

define behavior for z_c_soh alias SalesOrder
{
  use create;
  use update;
  use delete;

  use association _Item { create; with draft; }

  use action createSoByTemplate;
  use action SetDelivered;
  use action SetPaid;


}

define behavior for z_c_soi alias Item
{
  use update;
  use delete;

  use association _SalesOrder { with draft; }
}