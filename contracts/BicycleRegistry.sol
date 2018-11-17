pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./MyERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";

contract BicycleRegistry is MyERC721Enumerable, ERC721Metadata, Ownable {

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
        string _vendor,
        string _serialNumber,
        string _frameNumber,
        string _ipfsImageHash
  ) external payable {
        registerBicycleFor(_vendor,_serialNumber,_frameNumber,_ipfsImageHash, msg.sender);
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
        string _vendor,
        string _serialNumber,
        string _frameNumber,
        string _ipfsImageHash,
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
    function computeUniqueId(string _vendor,string _serialNumber,string _frameNumber) public pure returns (uint256) {
        bytes memory packed = abi.encodePacked(_vendor,_serialNumber,_frameNumber);
        bytes32 hashed = keccak256(packed);
        uint256 uniqueId = uint256(hashed);
        return uniqueId;
    }

    /// @notice Returns state, imageHash and uniqueId of a bicycle
    /// @param _vendor the vendor of the bicycle. e.g.: Hercules or Carver
    /// @param _serialNumber the serial number of the bicycle
    /// @param _frameNumber the frame number of the bicycle
    function getBicycle(string _vendor,string _serialNumber,string _frameNumber) external view returns (int, string, uint256) {
        uint256 uniqueId = computeUniqueId(_vendor,_serialNumber,_frameNumber);
        Bicycle storage bike = bicycles[uniqueId];
        return (bike.state, bike.ipfsImageHash, uniqueId);
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
    function withdraw(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /// @notice Updates the state of a registerd bicycle.
    /// valid states are: 0 = ok, 1 = stolen, 2 = lost
    /// @param uniqueId the id of the bicycle to update
    /// @param newState the new state to set (range(0,2))
    function updateState(uint256 uniqueId, uint8 newState) public {
        require(newState < 3, "only states 0,1,2 allowed");
        require(ownerOf(uniqueId) == msg.sender, "not owner or token does not exist");
        Bicycle storage bicycle = bicycles[uniqueId];
        bicycle.state = newState;
        emit BicycleStateChanged(uniqueId);
    }
}
