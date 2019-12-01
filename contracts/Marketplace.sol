pragma solidity >=0.4.21 <0.6.0;

import "./AnimalToken.sol";

/// @title Escrow contract
contract Marketplace is Ownable {

    AnimalToken public animal;

    constructor(address _animal) public {
        animal = AnimalToken(_animal);
    }

    struct Sale {
        uint animalId;
        uint price;
        address payable owner;
    }

    struct Auction {
        address payable seller;
        address payable lastBidder;
        uint startDate;
        uint initialPrice;
        uint bestOffer;
    }

    struct Fighter {
        address payable owner;
        uint reward;
        bool canFight;
    }

    mapping (uint => bool) private auctionedAnimals; // AnimalId => True
    mapping (uint => bool) private forSaleAnimals; // AnimalId => True
    mapping (uint => bool) private fightersAnimals; // AnimalId =§ True

    mapping (uint => address) public animalOwner; // AnimaldId => OwnerAddress

    mapping (uint => Auction) private auctions;
    mapping (uint => Sale) private sales;
    mapping (uint => Fighter) private fighters;


    // Listing Animal in the Marketplace
    function deposit(uint _animalId) public {
        require(animal.ownerOf(_animalId) == msg.sender, "not owner of this animal");
        animalOwner[_animalId] = msg.sender;
        animal.transferFrom(msg.sender, address(this), _animalId);
    }

    // Remove Animal from listing
    function withdraw(uint _animalId) public {
        require(animalOwner[_animalId] == msg.sender, "not owner of this animal");
        delete animalOwner[_animalId];
        animal.transferFrom(address(this), msg.sender, _animalId);
    }

    // SALE
    // ----------------------------------------------------------------------------------------------------------------------------------------------------
    // Create Sale of an animal
    function createSale(uint _animalId, uint _price) public {
        require(animalOwner[_animalId] == msg.sender, "not owner of this animal");
        require(!forSaleAnimals[_animalId], "already on sale");
        forSaleAnimals[_animalId] = true;
        sales[_animalId] = Sale(_animalId, _price, msg.sender);
    }

    // Buy animal
    function buyAnimal(uint _saleId) public payable {
        Sale storage s = sales[_saleId];

        // Avoid the owner buying his own tokens
        require(s.owner != msg.sender, "can't buy own tokens");
        require(msg.value >= s.price, "price is not enough");

        uint refund = msg.value - s.price;
        if(refund > 0)
            msg.sender.transfer(refund);

        s.owner.transfer(s.price);

        // Transfer the token (approve the buyer then allow him to transfer the token)
        animal.approve(msg.sender, s.animalId);
        animal.transferFrom(address(this), msg.sender, s.animalId);

        // Delete sale
        delete forSaleAnimals[s.animalId];
        delete sales[s.animalId];
    }

    // AUCTION
    // ----------------------------------------------------------------------------------------------------------------------------------------------------
    // Create Auction of an animal
    function createAuction(uint _animalId, uint initialPrice) public {
        require(!auctionedAnimals[_animalId], "already auctioned");
        require(animalOwner[_animalId] == msg.sender, "not owner of this animal");
        auctionedAnimals[_animalId] = true;
        auctions[_animalId] = Auction(msg.sender, address(0), now, initialPrice, 0);
    }

    // Bid on an Auction, need to do a better offer
    function bidOnAuction(uint _animalId) public payable {
        require(msg.sender != auctions[_animalId].seller, "You bid on your own auction");
        require(auctionedAnimals[_animalId], "not an auctioned animal");
        require(msg.value >= auctions[_animalId].bestOffer, "not enough money");
        _transferBid(_animalId, msg.value);
        _updateAuction(msg.sender, _animalId, msg.value);
    }

    // Transfer Bid
    function _transferBid(uint _animalId, uint value) private {
        Auction memory auction = auctions[_animalId];
        if (auction.lastBidder != address(0)) {
            // Give back money to lastBidder
            auction.lastBidder.transfer(auction.bestOffer);
        } else {
            // Transfer money to the seller (initially)
            auction.seller.transfer(value);
        }
    }

    // Update Auction with new bidder
    function _updateAuction(address payable newBidder, uint _animalId, uint value) private {
        auctions[_animalId].lastBidder = newBidder;
        auctions[_animalId].bestOffer = value;
    }

    // Allow last bidder to claim for the animal after 2 days
    function claimAuction(uint _animalId) public {
        require(auctionedAnimals[_animalId], "not auctioned animal");
        require(auctions[_animalId].lastBidder == msg.sender, "you are not the last bidder");
        require(auctions[_animalId].startDate + 2 days <= now, "2 days have not yet passed");
        auctionedAnimals[_animalId] = false;
        _processRetrieveAuction(_animalId);
    }

    // Transfer animal to last bidder
    function _processRetrieveAuction(uint _animalId) private {
        Auction storage auction = auctions[_animalId];
        if (auction.lastBidder != address(0)) {
            _transferAnimal(auction.seller, auction.lastBidder, _animalId);
            delete auctions[_animalId];
        }
    }

    // Auctioned Animal are locked
    function _transferAnimal(address sender, address receiver, uint _animalId) private {
        require(!auctionedAnimals[_animalId], "auctioned animal");
        animal.approve(receiver, _animalId);
        animal.transferFrom(sender, receiver, _animalId);
        animalOwner[_animalId] = receiver;
    }

    // ----------------------------------------------------------------------------------------------------------------------------------------------------
    // BREEDING
    // Breeding two animals to create a new one
    function breeding(uint _animal1Id, uint _animal2Id, uint _animal3Id) public {
        animal.mintNewToken(_animal1Id, _animal2Id, _animal3Id);
    }

    function deadAnimal(uint _animalId) public {
        animal.burn(_animalId);
        delete animalOwner[_animalId];
    }

    // ----------------------------------------------------------------------------------------------------------------------------------------------------
    // FIGHT
    function registerFighter(uint _animalId) public returns (bool) {
        require(animalOwner[_animalId] == msg.sender, "not owner of this animal");
        require(!fightersAnimals[_animalId], "already a fighter");
        fightersAnimals[_animalId] = true;
        fighters[_animalId] = Fighter(msg.sender, 0, false);
        return true;
    }

    function proposeToFight(uint _animalId, uint reward) public returns (bool) {
        require(animalOwner[_animalId] == msg.sender, "not owner of this animal");
        require(fightersAnimals[_animalId], "not a fighter");
        fighters[_animalId].reward = reward;
        fighters[_animalId].canFight = true;
        return true;
    }

    function agreeToFight(uint challenger, uint foe, uint value) public
    returns (bool) {
        require(animalOwner[challenger] == msg.sender, "not owner of this animal");
        require(fightersAnimals[foe], "not a fighter");
        require(fightersAnimals[challenger], "not a fighter");
        require(value == fighters[foe].reward, "not right amount");
        require(fighters[foe].canFight, "not available");
        Fighter storage fighter = fighters[foe];
        if (foe % 2 == 0) {
            deadAnimal(challenger);
            fighter.owner.transfer(value);
        } else {
            deadAnimal(foe);
            msg.sender.transfer(value);
        }
        return true;
    }


}