// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";

contract TestTransferV3 is ERC721A, Ownable, Pausable {

    using Strings for uint;

    string public baseURI;
    address public currency;

    uint public price = 0.01 ether;
    uint256 public MAX_SUPPLY = 1000;
    uint private constant MAX_MINT_AMOUNT = 100;

    bool private _paused = true;

    mapping(address => uint) public amountNFTsperWallet;

    constructor(
        // address _currency // string memory _baseURI
    ) ERC721A("Dems", "DEMS") { // address _tokenAddress, 
       _paused = true;
    }

    // requirement for mint
    modifier mintCompliant(
        address _recipient, 
        uint256 _quantity
    ) {
        require(_quantity > 0 && _quantity <= MAX_MINT_AMOUNT, "Invalid mint amount, you can only mint 1 token!");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded, contact support!");
        require(amountNFTsperWallet[_recipient] + _quantity <= MAX_MINT_AMOUNT, "You already minted this NFT!");
        _;
    }

    // requirement for price
    modifier priceCompliant(
        address _recipient,
        uint256 _quantity
    ) {
        uint256 priceAmount = price * _quantity;
        require(msg.value >= priceAmount, "Insufficient funds for purchase");
        IERC20(currency).transferFrom(
            _recipient,
            address(this),
            priceAmount
        );
        _;
    }

    function claimTo(
        address _recipient,
        uint256 _quantity
    ) external payable mintCompliant(_recipient, _quantity) { //priceCompliant(_recipient, _quantity)
        amountNFTsperWallet[_recipient] += _quantity;
        if ( totalSupply() + _quantity == MAX_SUPPLY) {
            _unpause();
        }
        _safeMint(_recipient, _quantity);
    }

    function getClaimIneligibilityReason(
        address _recipient,
        uint256 _quantity
    ) public view returns (string memory) {
        if (
            totalSupply() + _quantity > MAX_SUPPLY
        ) {
            return "Max supply exceeded, contact support";
        } else if (_quantity > MAX_MINT_AMOUNT) {
            return "Invalid mint amount, you can only mint 1 token";
        }
        else if (amountNFTsperWallet[_recipient] + _quantity > MAX_MINT_AMOUNT) {
            return "You already minted this NFT!";
        }
        return "";
    }


    function unclaimedSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function setBaseUri(
        string memory _baseURI
    ) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os, "Withdrawal failed!");
    }

    function withdrawCurrency() external onlyOwner {
        uint256 balance = IERC20(currency).balanceOf(address(this));
        bool success = IERC20(currency).transfer(msg.sender, balance);
        require(success, "withdraw failed");
    }

    ///////////////////////////////// ADD TRANSFERT COMPLIANT SYSTEM /////////////////////////////////

    /**
     * @dev See {ERC721A-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused() {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {ERC721A-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override whenNotPaused() {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused() {
        super.transferFrom(from, to, tokenId);
    }
}