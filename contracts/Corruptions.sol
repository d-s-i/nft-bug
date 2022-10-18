pragma solidity ^0.8.0;

import "./ERC721/ERC721Enumerable.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./CorruptionsMetadata.sol";

contract Corruptions is ERC721Enumerable,  ReentrancyGuard, Ownable {
    event Claimed(uint256 index, address account, uint256 amount);

    address public metadataAddress;

    bool public tradable;
    bool public claimable;

    uint256 private maxMultiplier;

    struct XP {
        uint256 savedXP;
        uint256 lastSaveBlock;
    }

    mapping (uint256 => XP) public insightMap;

    uint256 private balance;

    modifier onlyWhenTradable() {
        require(tradable, "Corruptions: cannot trade");
        _;
    }

    constructor() ERC721("Corruptions", "CORRUPT") Ownable() {
        tradable = true;
        maxMultiplier = 24;
    }

    function setMetadataAddress(address addr) public onlyOwner {
        metadataAddress = addr;
    }

    function setTradability(bool tradability) public onlyOwner {
        tradable = tradability;
    }

    function setClaimability(bool claimability) public onlyOwner {
        claimable = claimability;
    }

    function setMaxMultiplier(uint256 multiplier) public onlyOwner {
        maxMultiplier = multiplier;
    }

    function insight(uint256 tokenID) public view returns (uint256) { 
        uint256 lastBlock = insightMap[tokenID].lastSaveBlock;
        if (lastBlock == 0) {
            return 0;
        }
        uint256 delta = block.number - lastBlock;
        uint256 multiplier = delta / 200000;
        if (multiplier > maxMultiplier) {
            multiplier = maxMultiplier;
        }
        uint256 total = insightMap[tokenID].savedXP + (delta * (multiplier + 1) / 10000);
        if (total < 1) total = 1;

        return total;
    }

    function save(uint256 tokenID) private {
        insightMap[tokenID].savedXP = insight(tokenID);
        insightMap[tokenID].lastSaveBlock = block.number;
    }

    function tokenURI(uint256 tokenID) override public view returns (string memory) {
        require(metadataAddress != address(0), "Corruptions: no metadata address");
        require(tokenID < totalSupply(), "Corruptions: token doesn't exist");
        return ICorruptionsMetadata(metadataAddress).tokenURI(tokenID, insight(tokenID));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyWhenTradable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyWhenTradable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721) onlyWhenTradable {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override(ERC721) onlyWhenTradable {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) onlyWhenTradable {
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        save(tokenId);
    }

    function EXPERIMENTAL_UNAUDITED_NO_ROADMAP_ABSOLUTELY_NO_PROMISES_BUT_I_ACKNOWLEDGE_AND_WANT_TO_MINT_ANYWAY() payable public nonReentrant {
        require(msg.value == 0.08 ether, "Corruptions: 0.08 ETH to mint");
        require(claimable || _msgSender() == owner(), "Corruptions: cannot claim");
        require(totalSupply() < 4196, "Corruptions: all claimed");
        _mint(_msgSender(), totalSupply());

        balance += 0.08 ether;
    }

    function withdrawAvailableBalance() public nonReentrant onlyOwner {
        uint256 b = balance;
        balance = 0;
        payable(msg.sender).transfer(b);
    }
}