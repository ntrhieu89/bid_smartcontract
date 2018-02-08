pragma solidity ^0.4.15;

contract Bid {
  // A listing for an item listed by the seller
  struct Listing {
    address seller;	// address of the seller
    uint id;		// listing id
    string title;	// listing title

    address[] addrs;
    mapping(address => BidItem) bids;
    string link;
    address winner;

    uint minBidStep;	// the minimum increment value of the price
    uint maxPrice;	// max price up till now

    uint startTime;
    uint endTime;
  }

  address[] addrs;
  
  // A bid item of a specific user for a listing
  struct BidItem {
    uint price;		// bid price (in wei)
    uint count;		// the number of time this user bids on this item
    uint lastBidTime;	// the most recent time this user makes the bid
  }

  mapping(uint => Listing) listings;	// list of listings

  address public owner;	// owner of this contract
  uint public currListingId = 0;

  // configuration
  uint waitTime = 300;	// 5 minutes 
  uint listingFee = 100;	// 0.01 Ether

  // Constructor. 
  // Init the contract with default configuration.
  // The contract owner may change the configuration later.
  function Bid() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // A Seller calls this method to create a new listing.
  // He must pay the listing fee immediately.
  function createAListing(string _title, string _link, uint _startPrice, uint _minBidStep) payable public returns (uint id) {
    // the value paid must be equal the listing fee
    require(msg.value == listingFee);
    this.transfer(msg.value);

    // create a new listing
    Listing memory listing = Listing({
      seller: msg.sender,
      title: _title,
      link: _link,
      addrs: new address[](0),
      maxPrice: _startPrice,
      minBidStep: _minBidStep,
      startTime: now,
      endTime: 0,
      id: currListingId,
      winner: 0x0
    });

    listings[currListingId] = listing;
    return currListingId++;
  }

  // Return a specific listing
  function getListing(uint id) public constant returns (address seller, string title, string link, 
							uint maxPrice, uint minBidStep, uint startTime, uint endTime, address winner) {
    Listing memory listing = listings[id];
    return (listing.seller, listing.title, listing.link, listing.maxPrice, listing.minBidStep, listing.startTime, listing.endTime, listing.winner);
  }

  // A Buyer calls this method to bid a listing.
  // For simplicity, the system just remembers the value the bidder bids.
  // The winner pays when the listing ends. If the winner doesn't pay within one day, the listing is reset and becomes active again.
  function bidAListing(uint listingId, uint callPrice) payable public returns (bool success) {
    var listing = listings[listingId];
    var value = msg.value;
    require(callPrice >= listing.maxPrice + listing.minBidStep);

    // update listing
    address sender = msg.sender;
    var bid = listing.bids[sender];
    if (bid.count == 0) {
    	listing.addrs.push(sender);
    }
    require(callPrice - bid.price <= value);
    value = callPrice - bid.price;	// only get enough

    listing.maxPrice = callPrice;

    bid.price = callPrice;
    bid.count++;
    bid.lastBidTime = now;
    this.transfer(value);	// transfer the value.
    return true;
  }

  // End a listing.
  // Announce the winner and the maxPrice.
  // The winnter pays the full price.
  // Others get their money back.
  // Seller gets 70% of the bid price.
  // 30% belongs to the contract.
  function endListing(uint id) public payable {
    var listing = listings[id];
    require(listing.startTime != 0 && listing.endTime == 0);	// listing exists and hasn't ended yet.

    listing.endTime = now;

    // finding the winner
    for (uint i = 0; i < listing.addrs.length; i++) {
      var bid = listing.bids[listing.addrs[i]];
      require(bid.count != 0);
      if (bid.price == listing.maxPrice) {
	listing.winner = listing.addrs[i];
      } else {
      	// payback
	msg.sender.transfer(bid.price);
      }
    }

    // payback to seller
    msg.sender.transfer(listing.maxPrice * 70 / 100);
  }

  function getBalance() public constant returns (uint balance) {
    return this.balance;
  }

  function() public payable {
    
  }
}
