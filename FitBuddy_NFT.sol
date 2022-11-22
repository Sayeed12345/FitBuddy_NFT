// SPDX-License-Identifier: MIT


pragma solidity ^0.8.12;

// File: contracts\open-zeppelin-contracts\INarratorsHut.sol

struct MintInput {
    uint256 totalCost;
    uint256 expiresAt;
    TokenData[] tokenDataArray;
    bytes mintSignature;
}

struct TokenData {   
    uint48 witchId;
    uint48 artifactId;
}

interface INarratorsHut {

    function mint(MintInput calldata mintInput) external payable;

    function getArtifactForToken(uint256 tokenId) external view returns(ArtifactManifestation memory);

    function getTokenIdForArtifact(address addr, uint48 artifactId, uint48 witchId) external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function setIsSaleActive(bool _status) external;

    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive) external;

    function setMetadataContractAddress(address _metadataContractAddress) external;

    function setNarratorAddress(address _narratorAddress) external;

    function setBaseURI(string calldata _baseURI) external;

    function withdraw() external;

    function withdrawToken(IERC20 token) external;

}


// File: contracts\open-zeppelin-contracts\Context.sol

abstract contract Context {

    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }

}


// File: contracts\open-zeppelin-contracts\IERC165.sol

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns(bool);

}


// File: contracts\open-zeppelin-contracts\ERC165.sol

abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}


// File: contracts\open-zeppelin-contracts\IERC721.sol

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
   
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns(uint256 balance);
   
    function ownerOf(uint256 tokenId) external view returns(address owner);
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
  
    function transferFrom(address from, address to, uint256 tokenId) external;
 
    function approve(address to, uint256 tokenId) external;
 
    function getApproved(uint256 tokenId) external view returns(address operator);
  
    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns(bool);
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}


// File: contracts\open-zeppelin-contracts\IERC721Metadata.sol

interface IERC721Metadata is IERC721 {
    
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);
  
    function tokenURI(uint256 tokenId) external view returns(string memory);

}


// File: contracts\open-zeppelin-contracts\ERC721Hut.sol

struct TokenDataStorage {
    uint48 artifactId;
    uint48 witchId;
    address owner; // 160 bits
}

contract ERC721Hut is Context, ERC165, IERC721, IERC721Metadata {
    
    using Address for address;

    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => TokenDataStorage) private _tokenDataStorage;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
   
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function balanceOf(address owner) public view virtual override returns(uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _tokenDataStorage[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function name() public view virtual override returns(string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
   
    function _baseURI() internal view virtual returns(string memory) {
        return "";
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Hut.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require( _msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
   
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
   
    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }
   
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
   
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
   
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
  
    function _exists(uint256 tokenId) internal view virtual returns(bool) {
        return _tokenDataStorage[tokenId].owner != address(0);
    }
   
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
        address owner = ERC721Hut.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
  
    function _safeMint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId) internal virtual {
        _safeMint(to, tokenId, artifactId, witchId, "");
    }
   
    function _safeMint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId, bytes memory _data) internal virtual {
        _mint(to, tokenId, artifactId, witchId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
   
    function _mint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _tokenDataStorage[tokenId].owner = to;
        _tokenDataStorage[tokenId].artifactId = artifactId;
        _tokenDataStorage[tokenId].witchId = witchId;
        emit Transfer(address(0), to, tokenId);
    }
   
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Hut.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _tokenDataStorage[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
  
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Hut.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokenDataStorage[tokenId].owner = to;
        emit Transfer(from, to, tokenId);
    }
   
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Hut.ownerOf(tokenId), to, tokenId);
    }
   
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer" );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _getDataForToken(uint256 tokenId) internal view returns(uint48, uint48) {
        uint48 artifactId = _tokenDataStorage[tokenId].artifactId;
        uint48 witchId = _tokenDataStorage[tokenId].witchId;
        return (artifactId, witchId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

}


// File: contracts\open-zeppelin-contracts\IERC2981.sol

interface IERC2981 is IERC165 {
   
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns(address receiver, uint256 royaltyAmount);

}


// File: contracts\open-zeppelin-contracts\Ownable.sol

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _setOwner(_msgSender());
    }
   
    function owner() public view virtual returns(address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}


// File: contracts\open-zeppelin-contracts\NarratorsHut.sol

contract NarratorsHut is INarratorsHut, ERC721Hut, IERC2981, Ownable {

    uint256 private tokenCounter;

    string private baseURI;

    bool public isSaleActive = false;
    
    mapping(bytes32 => uint256) private _tokenIdsByMintKey;

    address public metadataContractAddress;
    address public narratorAddress;

    bool private isOpenSeaConduitActive = true;
   
    bytes32 private immutable domainSeparator;

    constructor(address _metadataContractAddress, address _narratorAddress, string memory _baseURI) ERC721Hut("The Narrator's Hut", "HUT") {
        domainSeparator = keccak256(abi.encode(Signatures.DOMAIN_TYPEHASH,keccak256(bytes("MintToken")),keccak256(bytes("1")),block.chainid,address(this)));
        metadataContractAddress = _metadataContractAddress;
        narratorAddress = _narratorAddress;
        baseURI = _baseURI;
    }

    modifier saleIsActive() {
        if (!isSaleActive) revert SaleIsNotActive();
        _;
    }

    modifier isCorrectPayment(uint256 totalCost) {
        if (totalCost != msg.value) revert IncorrectPaymentReceived();
        _;
    }

    modifier isValidMintSignature(bytes calldata mintSignature, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) {
        if (narratorAddress == address(0)) {
            revert InvalidNarratorAddress();
        }
        if (block.timestamp >= expiresAt) {
            revert MintSignatureHasExpired();
        }
        
        bytes32 recreatedHash = Signatures.recreateMintHash(domainSeparator,msg.sender,totalCost,expiresAt,tokenDataArray);

        if (!SignatureChecker.isValidSignatureNow(narratorAddress,recreatedHash,mintSignature)) {
            revert InvalidMintSignature();
        }
        _;
    }

    modifier canMintArtifact(TokenData calldata tokenData) {
        if (getTokenIdForArtifact(msg.sender, tokenData.artifactId, tokenData.witchId) > 0) {
            revert ArtifactCapReached();
        }

        INarratorsHutMetadata metadataContract = INarratorsHutMetadata(metadataContractAddress);
        if (!metadataContract.canMintArtifact(tokenData.artifactId)) {
            revert ArtifactIsNotMintable();
        }
        _;
    }

    function mint(MintInput calldata mintInput) external payable saleIsActive isValidMintSignature(mintInput.mintSignature, mintInput.totalCost, mintInput.expiresAt, mintInput.tokenDataArray) isCorrectPayment(mintInput.totalCost) {
        for (uint256 i; i < mintInput.tokenDataArray.length;) {
            mintArtifact(mintInput.tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getArtifactForToken(uint256 tokenId) external view returns(ArtifactManifestation memory) {
        (uint256 artifactId, uint256 witchId) = _getDataForToken(tokenId);
        return INarratorsHutMetadata(metadataContractAddress).getArtifactForToken(artifactId, tokenId, witchId);
    }

    function getTokenIdForArtifact(address addr, uint48 artifactId, uint48 witchId) public view returns(uint256) {
        bytes32 mintKey = getMintKey(addr, artifactId, witchId);
        return _tokenIdsByMintKey[mintKey];
    }

    function getBaseURI() external view returns(string memory) {
        return baseURI;
    }

    function totalSupply() external view returns(uint256) {
        return tokenCounter;
    }

    function setIsSaleActive(bool _status) external onlyOwner {
        isSaleActive = _status;
    }
    
    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive) external onlyOwner {
        isOpenSeaConduitActive = _isOpenSeaConduitActive;
    }

    function setMetadataContractAddress(address _metadataContractAddress) external onlyOwner {
        metadataContractAddress = _metadataContractAddress;
    }

    function setNarratorAddress(address _narratorAddress) external onlyOwner {
        narratorAddress = _narratorAddress;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert PaymentBalanceZero();
        }
        (bool success, bytes memory result) = owner().call {
            value: balance
        }("");
        if (!success) {
            revert PaymentUnsuccessful(result);
        }
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert PaymentBalanceZero();
        }
        token.transfer(msg.sender, balance);
    }

    function nextTokenId() private returns(uint256) {
        unchecked {
            ++tokenCounter;
        }
        return tokenCounter;
    }

    function getMintKey(address addr, uint48 artifactId, uint48 witchId) private pure returns(bytes32) {        
        if (witchId != 0) {           
            return bytes32(abi.encodePacked(witchId, artifactId));
        } else {            
            return bytes32(abi.encodePacked(addr, artifactId));
        }
    }

    function mintArtifact(TokenData calldata tokenData) private canMintArtifact(tokenData) {
        uint256 tokenId = nextTokenId();      
        bytes32 mintKey = getMintKey(msg.sender, tokenData.artifactId, tokenData.witchId);
        _tokenIdsByMintKey[mintKey] = tokenId;
        _mint(msg.sender, tokenId, tokenData.artifactId, tokenData.witchId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Hut, IERC165) returns(bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function isApprovedForAll(address owner, address operator) public view override returns(bool) {
        if (isOpenSeaConduitActive && operator == 0x1E0049783F008A0085193E00003D00cd54003c71) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        if (!_exists(tokenId)) revert TokenURIQueryForNonexistentToken();
        string memory url = string.concat(baseURI,"/",Strings.toString(tokenId));
        return url;
    }
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns(address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId)) revert RoyaltiesQueryForNonexistentToken();
        return (owner(), (salePrice * 5) / 100);
    }

    error SaleIsNotActive();
    error IncorrectPaymentReceived();
    error ArtifactCapReached();
    error ArtifactIsNotMintable();
    error RoyaltiesQueryForNonexistentToken();
    error TokenURIQueryForNonexistentToken();
    error MintSignatureHasExpired();
    error InvalidNarratorAddress();
    error InvalidMintSignature();
    error PaymentBalanceZero();
    error PaymentUnsuccessful(bytes result);
}


// File: contracts\open-zeppelin-contracts\ERC721.sol

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;

    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
   
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function balanceOf(address owner) public view virtual override returns(uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function name() public view virtual override returns(string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function _baseURI() internal view virtual returns(string memory) {
        return "";
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
   
    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
   
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
   
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
   
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
   
    function _exists(uint256 tokenId) internal view virtual returns(bool) {
        return _owners[tokenId] != address(0);
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
  
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
   
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
   
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
   
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File: contracts\open-zeppelin-contracts\MerkleProof.sol

library MerkleProof {
  
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns(bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

}


// File: contracts\open-zeppelin-contracts\Strings.sol

library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
   
    function toString(uint256 value) internal pure returns(string memory) {      
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
   
    function toHexString(uint256 value) internal pure returns(string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    
    function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File: contracts\open-zeppelin-contracts\SignatureChecker.sol

library SignatureChecker {

    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns(bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }

}


// File: contracts\open-zeppelin-contracts\Signatures.sol

library Signatures {
    
    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes constant TOKEN_DATA_TYPE_DEF = "TokenData(uint32 artifactId,uint32 witchId)";
    bytes32 constant MINT_TYPEHASH = keccak256(abi.encodePacked("Mint(address minterAddress,uint256 totalCost,uint256 expiresAt,TokenData[] tokenDataArray)",TOKEN_DATA_TYPE_DEF));
    bytes32 constant TOKEN_DATA_TYPEHASH = keccak256(TOKEN_DATA_TYPE_DEF);
   
    function recreateMintHash(bytes32 domainSeparator, address minterAddress, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) internal pure returns(bytes32) {
        bytes32 mintHash = _hashMint(minterAddress, totalCost, expiresAt, tokenDataArray);
        return _eip712Message(domainSeparator, mintHash);
    }

    function _hashMint(address minterAddress, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) private pure returns(bytes32) {
        bytes32[] memory tokenDataHashes = new bytes32[](tokenDataArray.length);
        for (uint256 i; i < tokenDataArray.length;) {
            tokenDataHashes[i] = _hashTokenData(tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encode(MINT_TYPEHASH, minterAddress, totalCost, expiresAt, keccak256(abi.encodePacked(tokenDataHashes))));
    }

    function _hashTokenData(TokenData calldata tokenData) private pure returns(bytes32) {
        return keccak256(abi.encode(TOKEN_DATA_TYPEHASH,tokenData.artifactId,tokenData.witchId));
    }

    function _eip712Message(bytes32 domainSeparator, bytes32 dataHash) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(uint16(0x1901), domainSeparator, dataHash));
    }

}


// File: contracts\open-zeppelin-contracts\IERC721Receiver.sol

interface IERC721Receiver {
  
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);

}


// File: contracts\open-zeppelin-contracts\Address.sol

library Address {
   
    function isContract(address account) internal view returns(bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call {
            value: amount
        }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
   
    function functionCall(address target, bytes memory data) internal returns(bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
   
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
  
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call {
            value: value
        }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
   
    function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
   
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

}


// File: contracts\open-zeppelin-contracts\IERC20.sol

interface IERC20 {
   
    function totalSupply() external view returns(uint256);
   
    function balanceOf(address account) external view returns(uint256);
   
    function transfer(address recipient, uint256 amount) external returns(bool);
  
    function allowance(address owner, address spender) external view returns(uint256);
    
    function approve(address spender, uint256 amount) external returns(bool);
   
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


// File: contracts\open-zeppelin-contracts\ECDSA.sol

library ECDSA {

    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }
    
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns(address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
             assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
             assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }
   
    function recover(bytes32 hash, bytes memory signature) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }
   
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns(address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }
   
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }
    
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address, RecoverError) {       
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }
        return (signer, RecoverError.NoError);
    }
   
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }
  
    function toEthSignedMessageHash(bytes32 hash) internal pure returns(bytes32) {
         return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

}


// File: contracts\open-zeppelin-contracts\IERC1271.sol

interface IERC1271 {
   
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns(bytes4 magicValue);

}


// File: contracts\open-zeppelin-contracts\INarratorsHutMetadata.sol

struct CraftArtifactData {
    uint256 id;
    string name;
    string description;
    string[] attunements;
}

struct Artifact {
    bool mintable;
    string name;
    string description;
    string[] attunements;
}

struct ArtifactManifestation {
    string name;
    string description;
    uint256 witchId;
    uint256 artifactId;
    AttunementManifestation[] attunements;
}

struct AttunementManifestation {
    string name;
    int256 value;
}

interface INarratorsHutMetadata {

    function getArtifactForToken(uint256 artifactId, uint256 tokenId, uint256 witchId) external view returns(ArtifactManifestation memory);

    function canMintArtifact(uint256 artifactId) external view returns(bool);

    function craftArtifact(CraftArtifactData calldata data) external;

    function getArtifact(uint256 artifactId) external view returns(Artifact memory);

    function lockArtifacts(uint256[] calldata artifactIds) external;

}
