# TD6_Monnaie_Numerique

### AnimalToken 
It is an ERC721 Token just with some additional functions 

**Mint**

    function _mint(address to, uint tokenId) internal {
        require(to != address(0), "address 0x0");
        require(!_exists(tokenId), "token already exists");
        tokenOwner[tokenId] = to;
        ownedTokensCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }
    
    function mint(uint tokenId) public {
        _mint(msg.sender, tokenId);
    }
    
**MintNewToken (from two others)**

    function mintNewToken(uint tokenId1, uint tokenId2, uint new_tokenId) public {
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "not owner of both tokens");
        _mint(msg.sender, new_tokenId);
    }
    
**Burn**

    function _burn(uint tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "not owner of token");
        clearApproval(tokenId);
        ownedTokensCount[msg.sender].decrement();
        tokenOwner[tokenId] = address(0);
        emit Transfer(msg.sender, address(0), tokenId);
    }
    
    function burn(uint tokenId) public {
        _burn(tokenId);
    }
    
### Marketplace (see Marketplace.sol)

**Deposit/Withdraw Animal**
Allow user to list his animal on the marketplace contract. Marketplace owns the contracts until animal is saled.

**Sale**
Allow user to sale his animal.

**Auction**
Allow user to put his animal on auction.

**Breeding**
Allow user to breed two of his animals.

**Fight**
Allow two user to agree on a fight and a reward.
