// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract EarthSoldiers is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;

  mapping(address => bool) public charityAddresses;

  AggregatorV3Interface internal priceFeed;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    priceFeed = AggregatorV3Interface(
          0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
      );
  }

  // Returns the latest price 
  function getLatestPrice() public view returns (int256){ 
   (, int256 price, , , ) = priceFeed.latestRoundData();
    return (price / 100000000); 
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    // > 98% to prevent failure due to slippage
    require(msg.value * uint256(getLatestPrice()) >= (cost * _mintAmount) * 98 * 1000000000000000000 / 100 , 'Insufficient funds!');
    _;
  }

  // Management of charity addresses
  function addCharityAddress (address _charityAddress) public onlyOwner {
    charityAddresses[_charityAddress] = true;
  }

  // Management of charity addresses
  function removeCharityAddress (address _charityAddress) public onlyOwner {
    charityAddresses[_charityAddress] = false;
  }

  // Send charity funds to the determined address
  function afterTokenTransfers(
    address _charityAddress
  ) internal {

    (bool bs, ) = payable(_charityAddress).call{value: msg.value * 75 / 100}('');
    require(bs);  
  }

  // Mint verifies compliances and triggers afterTokenTransfer for sending charity funds to the determined address
  function mint(uint256 _mintAmount, address _charityAddress) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(charityAddresses[_charityAddress],  'The charity address is invalid');

    _safeMint(_msgSender(), _mintAmount);

    afterTokenTransfers(_charityAddress); 
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // Transfers the remaining contract balance to the owner.
  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
