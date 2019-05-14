pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";


contract BicycleRegistry is ERC721Enumerable, ERC721Metadata, Ownable {

    /*** EVENTS ***/
    event BicycleRegisterd(address indexed owner, uint256 tokenId);
    event BicycleStateChanged(uint256 tokenId);

    /// Price set by contract owner for each token in Wei.
    uint256 currentRegistrationPrice = 3000000000000000;

    struct Bicycle {
        //allowed states are 
        // 0 - ok
        // 1 - stolen
        // 2 - lost
        uint8 state;
        string ipfsImageHash;

        string vendor;
        string serialNumber;
        string frameNumber;
    }
    mapping (uint256 => Bicycle) bicycles;

    constructor() ERC721Metadata("KETTE Bicycle Registry", "KET") public {}

    /// @notice registers a bicycle token with the given parameters for the caller of the function
    /// and requires the caller to send currentRegistrationPrice (ETH) along with the transaction
    /// @dev there are intentionally no checks for validity of the string parameters.
    /// there is no advantages to register a bike token with invalid value. 
    /// @param _vendor the vendor of the bicycle. e.g.: Hercules or Carver
    /// @param _serialNumber the serial number of the bicycle
    /// @param _frameNumber the frame number of the bicycle
    /// @param _ipfsImageHash multihash of an image of the bicycle on the ipfs
    function registerBicycle (
        string calldata _vendor,
        string calldata _serialNumber,
        string calldata _frameNumber,
        string calldata _ipfsImageHash
  ) external payable {
        registerBicycleFor(_vendor,_serialNumber,_frameNumber,_ipfsImageHash, msg.sender);
    }

   /**
   * @dev Returns all of the token Ids that the user owns
   * @param _tokenOwner The address of the owner of interest
   * @return An array of token indices
   */
    function getTokenIds(address _tokenOwner) public view returns (uint256[] memory) {
        return _tokensOfOwner(_tokenOwner);
    }

    /// @notice registers a bicycle token with the given parameters for a specified account
    /// and requires the caller to send currentRegistrationPrice (ETH) along with the transaction
    /// @dev there are intentionally no checks for validity of the string parameters.
    /// there is no advantages to register a bike token with invalid value. 
    /// @param _vendor the vendor of the bicycle. e.g.: Hercules or Carver
    /// @param _serialNumber the serial number of the bicycle
    /// @param _frameNumber the frame number of the bicycle
    /// @param _ipfsImageHash multihash of an image of the bicycle on the ipfs
    /// @param _for address of the account the bicycle token should be registered for
    function registerBicycleFor (
        string memory _vendor,
        string memory _serialNumber,
        string memory _frameNumber,
        string memory _ipfsImageHash,
        address _for
  ) public payable {
        require(msg.value >= currentRegistrationPrice, "Amount of Ether sent too small");
        uint256 uniqueId = computeUniqueId(_vendor,_serialNumber,_frameNumber);
        _mint(_for, uniqueId);

        Bicycle memory bicycle = Bicycle({
            state: 0,
            ipfsImageHash: _ipfsImageHash,
            vendor: _vendor,
            serialNumber: _serialNumber,
            frameNumber: _frameNumber
        });

        bicycles[uniqueId] = bicycle;
        emit BicycleRegisterd(_for, uniqueId);
    }

    /// @notice computes a unique ID given the three parameters
    /// @param _vendor the vendor of the bicycle. e.g.: Hercules or Carver
    /// @param _serialNumber the serial number of the bicycle
    /// @param _frameNumber the frame number of the bicycle
    function computeUniqueId(string memory _vendor,string memory _serialNumber,string memory _frameNumber) public pure returns (uint256) {
        bytes memory packed = abi.encodePacked(_vendor,_serialNumber,_frameNumber);
        bytes32 hashed = keccak256(packed);
        uint256 uniqueId = uint256(hashed);
        return uniqueId;
    }

    /// @notice Returns all bicycle information
    /// @param _vendor the vendor of the bicycle. e.g.: Hercules or Carver
    /// @param _serialNumber the serial number of the bicycle
    /// @param _frameNumber the frame number of the bicycle
    function lookUpBicycle(string calldata _vendor,string calldata _serialNumber,string calldata _frameNumber) 
    external view 
    returns (string memory vendor_, string memory serialNumber_, string memory frameNumber_, int state_, string memory ipfsImageHash_, uint256 uniqueId_) {
        uint256 uniqueId = computeUniqueId(_vendor,_serialNumber,_frameNumber);
        return getBicycle(uniqueId);
    }

    /// @notice Returns all bicycle information
    /// @param _uniqueId the ID of the token that represents the bicycle
    function getBicycle(uint256 _uniqueId) public view 
    returns (string memory vendor_, string memory serialNumber_, string memory frameNumber_, int state_, string memory ipfsImageHash_, uint256 uniqueId_) {
        Bicycle storage bike = bicycles[_uniqueId];
        return (bike.vendor, bike.serialNumber, bike.frameNumber, bike.state, bike.ipfsImageHash, _uniqueId);
    }

    /// @notice Allows the owner of this contract to set the currentRegistrationPrice for each token
    function setCurrentRegistrationPrice(uint256 newPrice) public onlyOwner {
        currentRegistrationPrice = newPrice;
    }

    /// @notice Returns the currentRegistrationPrice for each token
    function getCurrentRegistrationPrice() external view returns (uint256) {
        return currentRegistrationPrice;
    }

    /// @notice Let´s you withdraw all the contracts funds
    /// @param _to account the withdraw should go to
    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
    
    /// @notice Updates the state of a registerd bicycle.
    /// valid states are: 0 = ok, 1 = stolen, 2 = lost
    /// @param uniqueId the id of the bicycle to update
    /// @param newState the new state to set (range(0,2))
    function updateState(uint256 uniqueId, uint8 newState) public {
        _updateState(msg.sender, uniqueId, newState);
    }

    /// @notice Updates the state of a registerd bicycle.
    /// valid states are: 0 = ok, 1 = stolen, 2 = lost
    /// @param owner the owner of the bike updating the state
    /// @param uniqueId the id of the bicycle to update
    /// @param newState the new state to set (range(0,2))
    function _updateState(address owner, uint256 uniqueId, uint8 newState) private {
        require(newState < 3, "only states 0,1,2 allowed");
        require(_exists(uniqueId), "token does not exist");
        require(ownerOf(uniqueId) == owner, "not the owner");
        Bicycle storage bicycle = bicycles[uniqueId];
        bicycle.state = newState;
        emit BicycleStateChanged(uniqueId);
    }

    mapping (address => uint256) public replayNonce;
    
    /// @notice Updates the state of a registerd bicycle.
    /// valid states are: 0 = ok, 1 = stolen, 2 = lost
    /// @param signature signature of the bike owner
    /// @param uniqueId the id of the bicycle to update
    /// @param newState the new state to set (range(0,2))
    function metaUpdateState(bytes memory signature, uint256 uniqueId, uint8 newState, uint256 nonce) public {
        bytes32 metaHash = metaUpdateStateHash(uniqueId, newState, nonce);
        address signer = getSigner(metaHash,signature);
        require(nonce == replayNonce[signer], "nonce mismatch");
        replayNonce[signer]++;
        _updateState(signer, uniqueId, newState);
    }

    /// @notice Returns a hash for a function call of metaUpdateState with the given parameters
    function metaUpdateStateHash(uint256 uniqueId, uint8 newState, uint256 nonce) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this),"metaUpdateState", uniqueId, newState, nonce));
    }

    /// @dev will return a different address then the signers when _hash and _signature do not match
    function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s);
        }
    }
}
