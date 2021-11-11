// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
  address public owner;
  uint public skuCount;
  enum State { ForSale, Sold, Shipped, Received }
  mapping(uint => Item) public items;

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */

  event LogForSale(uint skuCount);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  modifier isOwner{
    require(msg.sender == owner);
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier isSeller(uint _sku) {
    require(msg.sender == items[_sku].seller);
    _;
  }

  modifier isBuyer(uint _sku) {
    require(msg.sender == items[_sku].buyer);
    _;
  }

  modifier forSale(uint _sku) {
    require(
      items[_sku].state == State.ForSale &&
      bytes(items[_sku].name).length > 0
    );
    _;
  }
  
  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller: payable(msg.sender), 
     buyer: payable(address(0))
    });
    
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku){
    (bool sent, ) = items[_sku].seller.call{value: items[_sku].price}("");
    require(sent, "Failed to send Ether");

    items[_sku].buyer = payable(msg.sender);
    items[_sku].state = State.Sold;

    emit LogSold(_sku);
  }

  function shipItem(uint _sku) public sold(_sku) isSeller(_sku) {
    items[_sku].state = State.Shipped;
    emit LogShipped(_sku);
  }

  function receiveItem(uint _sku) public shipped(_sku) isBuyer(_sku) {
    items[_sku].state = State.Received;
    emit LogReceived(_sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view 
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) 
    { 
      name = items[_sku].name; 
      sku = items[_sku].sku; 
      price = items[_sku].price; 
      state = uint(items[_sku].state); 
      seller = items[_sku].seller; 
      buyer = items[_sku].buyer; 
      return (name, sku, price, state, seller, buyer); 
    } 
  }
