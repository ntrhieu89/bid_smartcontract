pragma solidity ^0.4.15;

contract Bid {
  enum State {
    Started, Ended
  }

  // A listing for an item listed by the seller
  struct Listing {
    address seller;	// address of the seller
    uint id;		// listing id
    string title;	// listing title
    mapping(address => BidItem) bids; // list of bids for this listing
    string link;

    uint minBidStep;	// the minimum increment value of the price
    State state;		// state could be either Started or Ended

    uint startTime;
    uint endTime;
  }
  
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
  uint listingFee = 10000000000000000;	// 0.01 Ether

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
  function createAListing(string _title, string _link, uint _minBidStep) public returns (uint id) {
    // the value paid must be equal the listing fee
    //require(msg.value == listingFee);

    // create a new listing
    Listing memory listing = Listing({
      seller: msg.sender,
      title: _title,
      link: _link,
      minBidStep: _minBidStep,
      state: State.Started,
      startTime: now,
      endTime: 0,
      id: currListingId
    });

    listings[currListingId] = listing;
    return currListingId++;
  }

  // Return a specific listing
  function getListing(uint id) public constant returns (address seller, string title, string link, uint minBidStep, uint state, uint startTime, uint endTime) {
    Listing memory listing = listings[id];
    return (listing.seller, listing.title, listing.link, listing.minBidStep, uint(listing.state), listing.startTime, listing.endTime);
  }

  // A Buyer calls this method to bid a listing.
  // For simplicity, the system just remembers the value the bidder bids.
  // The winner pays when the listing ends. If the winner doesn't pay within one day, the listing is reset and becomes active again.
//  function bidAListing(uint listingId, uint price) payable public {
//    var listing = listings[listingId];
//  }
}
