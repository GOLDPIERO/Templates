// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@paperxyz/contracts/verification/PaperVerification.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721A.sol";

contract TestTransferV2 is ERC721A, Ownable { // PaperVerification

    using Strings for uint;

    string public baseURI;
    address public currency;

    uint public price = 0.01 ether;
    uint256 public MAX_SUPPLY = 1000;
    uint private constant MAX_MINT_AMOUNT = 100;

    mapping(address => uint) public amountNFTsperWallet;

    // Default allow transfer
    bool private transferable = false;

    constructor(
    ) ERC721A("Dems", "DEMS") {
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

    function claimTo(
        address _recipient,
        uint256 _quantity
    ) external payable mintCompliant(_recipient, _quantity) {
        amountNFTsperWallet[_recipient] += _quantity;
        _safeMint(_recipient, _quantity);
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

    function isTransferable() public view returns (bool) {
        return transferable;
    }

    function setTransferable(bool _transferable) external onlyOwner {
        transferable = _transferable;
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        bool success = transferCompliant(from);
        require(success, "Cannot transfer - currently locked");
    }

    function transferCompliant(address from) public view returns (bool) {
        if ( transferable == false ) { 
            if ( from != address(0) ) {
                return false;
            } else {
            return true;
            }
        } else {
            return true;
        }
    }
}