
pragma solidity >=0.4.21 <0.6.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract AnimalToken is Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping (uint => address) private tokenOwner;
    mapping (uint => address) private tokenApprovals;
    mapping (address => Counters.Counter) private ownedTokensCount;
    mapping (address => mapping (address => bool)) private operatorApprovals;

    function balanceOf(address owner) public view returns (uint) {
        require(owner != address(0), "address 0x0");
        return ownedTokensCount[owner].current();
    }

    function ownerOf(uint tokenId) public view returns (address) {
        address owner = tokenOwner[tokenId];
        require(owner != address(0), "address 0x0");
        return owner;
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "");
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public {
        transferFrom(from, to, tokenId);
    }

    function _exists(uint tokenId) internal view returns (bool) {
        address owner = tokenOwner[tokenId];
        return owner != address(0);
    }

    function mint(uint tokenId) public {
        _mint(msg.sender, tokenId);
    }

    function mintNewToken(uint tokenId1, uint tokenId2, uint new_tokenId) public {
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "not owner of both tokens");
        _mint(msg.sender, new_tokenId);
    }

    function burn(uint tokenId) public {
        _burn(tokenId);
    }

    function _mint(address to, uint tokenId) internal {
        require(to != address(0), "address 0x0");
        require(!_exists(tokenId), "token already exists");
        tokenOwner[tokenId] = to;
        ownedTokensCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "not owner of token");
        clearApproval(tokenId);
        ownedTokensCount[msg.sender].decrement();
        tokenOwner[tokenId] = address(0);
        emit Transfer(msg.sender, address(0), tokenId);
    }

    function _transferFrom(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "not owner of token");
        require(to != address(0), "address 0x0");
        clearApproval(tokenId);
        ownedTokensCount[from].decrement();
        ownedTokensCount[to].increment();
        tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "you approve for the owner of the token");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "");
        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function tokenApproved(address to, uint tokenId) public view returns (bool) {
        return isApprovedOrOwner(to, tokenId);
    }

    function getApproved(uint tokenId) public view returns (address) {
        require(_exists(tokenId), "token doesn't exist");
        return tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "you approve for yourself");
        operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function isApprovedOrOwner(address spender, uint tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function clearApproval(uint tokenId) private {
        if (tokenApprovals[tokenId] != address(0)) {
            tokenApprovals[tokenId] = address(0);
        }
    }
}